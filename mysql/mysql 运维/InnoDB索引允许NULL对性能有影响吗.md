| operator | createtime  | updatetime  |
| -------- | ----------- | ----------- |
| shenx    | 2023-12月-13 | 2023-12月-13 |

---

**阅读目录**
--------

**0\. 初始化测试表、数据**

**1\. 问题1：** 索引列允许为NULL，对性能影响有多少

**结论1，**存储大量的NULL值，除了计算更复杂之外，数据扫描的代价也会更高一些

**2\. 问题2：** 辅助索引需要MVCC多版本读的时候，为什么需要依赖聚集索引

**结论2，**辅助索引中不存储DB\_TRX\_ID，需要依托聚集索引实现MVCC

**3\. 问题3：** 为什么查找数据时，一定要读取叶子节点，只读非叶子节点不行吗

**结论3，**在索引树中查找数据时，最终一定是要读取叶子节点才行

**4\. 问题4：** 索引列允许为NULL，会额外存储更多字节吗

**结论4，**定义列值允许为NULL并不会增加物理存储代价，但对索引效率的影响要另外考虑

**5\. 几点总结**

**6\. 延伸阅读**

本文开始之前，有几篇文章建议先复习一下

*   InnoDB表聚集索引层高什么时候发生变化
*   浅析InnoDB索引结构
*   Innodb页合并和页分裂
*   innblock | InnoDB page观察利器

接下来，我们一起测试验证关于辅助索引的几个特点。

**0\. 初始化测试表、数据**
-----------------

测试表结构如下：

```
[root@yejr.run]> CREATE TABLE `t_sk` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `c1` int(10) unsigned NOT NULL,
  `c2` int(10) unsigned NOT NULL,
  `c3` int(10) unsigned NOT NULL,
  `c4` int(10) unsigned NOT NULL,
  `c5` datetime NOT NULL,
  `c6` char(20) NOT NULL,
  `c7` varchar(30) NOT NULL,
  `c8` varchar(30) NOT NULL,
  `c9` varchar(30) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `k1` (`c1`)
) ENGINE=InnoDB; 
```

除了主键索引外，还有个 `c1` 列上的辅助索引。

用 `mysql_random_data_load` 灌入50万测试数据。

```
[root@yejr.run]# mysql_random_data_load -hXX -uXX -pXX test t_sk 500000 
```

**1\. 问题1：索引列允许为NULL，对性能影响有多少**
-------------------------------

把辅助索引列 `c1` 修改为允许NULL，并且随机更新5万条数据，将 c1 列设置为NULL

```
[root@yejr.run]> alter table t_sk modify c1 int unsigned;

[root@yejr.run]> update t_sk set c1 = NULL order by rand() limit 50000;
Query OK, 50000 rows affected (2.83 sec)
Rows matched: 50000  Changed: 50000  Warnings: 0

#随机1/10为null
[root@yejr.run]> select count(*) from t_sk where c1 is null;
+----------+
| count(*) |
+----------+
|    50000 |
+----------+ 
```

好，现在观察辅助索引的索引数据页结构。

```
[root@yejr.run]# innblock test/t_sk.ibd scan 16
...
Datafile Total Size:100663296
===INDEX_ID:46   --聚集索引(主键索引)
level2 total block is (1)  --根节点,层高2(共3层),共1个page
block_no:         3,level:   2|*|
level1 total block is (5)  --中间节点,层高1,共5个page
block_no:       261,level:   1|*|block_no:       262,level:   1|*|block_no:       263,level:   1|*|
block_no:       264,level:   1|*|block_no:       265,level:   1|*|
level0 total block is (5020)  --叶子节点,层高0,共5020个page
block_no:         5,level:   0|*|block_no:         6,level:   0|*|block_no:         7,level:   0|*|
...
===INDEX_ID:47   --辅助索引
level1 total block is (1)  --根节点,层高1(共2层),共1个page
block_no:         4,level:   1|*|
level0 total block is (509)  --叶子节点,层高0,共509个page
block_no:        18,level:   0|*|block_no:        19,level:   0|*|block_no:        31,level:   0|*|
... 
```

观察辅助索引的根节点里的数据

```
[root@yejr.run]# innodb_space -s ibdata1 -T test/t_sk -p 4 page-dump
...
records:
{:format=>:compact,
 :offset=>126,    --第一条记录
 :header=>
  {:next=>428,
   :type=>:node_pointer,
   :heap_number=>2,
   :n_owned=>0,
   :min_rec=>true,    --min_rec表示最小记录
   :deleted=>false,
   :nulls=>["c1"],
   :lengths=>{},
   :externs=>[],
   :length=>6},
 :next=>428,
 :type=>:secondary,
 :key=>[{:name=>"c1", :type=>"INT UNSIGNED", :value=>:NULL}],    --对应c1列值为NULL
 :row=>[{:name=>"id", :type=>"INT UNSIGNED", :value=>9}],    --对应id=9
 :sys=>[],
 :child_page_number=>18,    --指向叶子节点 pageno = 18
 :length=>8}
...
{:format=>:compact,
 :offset=>6246,    --最后一条记录(next=>112,指向supremum)
 :header=>
  {:next=>112,
   :type=>:node_pointer,
   :heap_number=>346,
   :n_owned=>0,
   :min_rec=>false,
   :deleted=>false,
   :nulls=>[],
   :lengths=>{},
   :externs=>[],
   :length=>6},
 :next=>112,
 :type=>:secondary,
 :key=>[{:name=>"c1", :type=>"INT UNSIGNED", :value=>2142714688}],    --对应c1=2142714688
 :row=>[{:name=>"id", :type=>"INT UNSIGNED", :value=>73652}],    --对应id=73652
 :sys=>[],
 :child_page_number=>2935,    --指向叶子节点2935
 :length=>12} 
```

经过统计，根节点中c1列值为NULL的记录共有33条，其余476条是c1列值为非NULL，共509条记录。

叶子节点中，每个page大约可以存储1547条记录，共有5万条记录值为NULL，因此需要至少33个page来保存（ceiling(50000/1547) = 33)。

看下这个SQL的查询计划

```
[root@yejr.run]> desc select count(*) from t_sk where c1 is null\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_sk
   partitions: NULL
         type: ref
possible_keys: k1
          key: k1
      key_len: 5
          ref: const
         rows: 99112
     filtered: 100.00
        Extra: Using where; Using index 
```

从上面的输出中，我们能看到，当索引列设置允许为NULL时，是会对其纳入索引统计信息，并且值为NULL的记录，都是存储在索引树的最左边。

接下来，跑几个SQL查询。

**SQL1，统计所有NULL值数量**

```
[root@yejr.run]> select count(*) from t_sk where c1 is null;
+----------+
| count(*) |
+----------+
|    50000 |
+----------+ 
```

查看slow log

```
InnoDB_pages_distinct: 34
...
select count(*) from t_sk where c1 is null; 
```

共需要扫描34个page，根节点(1)+叶子节点(33)，正好34个page。

备注：需要用Percona版本才能在slow query log中有**InnoDB\_pages\_distinct**信息。

**SQL2, 查询 c1 is null**

```
[root@yejr.run]> select id,c1 from t_sk where c1 is null limit 1;
+------+------+
| id   | c1   |
+------+------+
| 9607 | NULL |
+------+------+ 
```

查看slow log

```
InnoDB_pages_distinct: 12
...
select id,c1 from t_sk where c1 is null limit 1; 
```

这次的查询需要扫描12个page，除去1个根节点外，还需要扫描12个叶子节点，只是为了返回一条数据而已，这代价有点大。

如果把SQL微调改成下面这样

```
[root@yejr.run]> select id,c1 from t_sk where c1 is null limit 10000,1;
+-------+------+
| id    | c1   |
+-------+------+
| 99671 | NULL |
+-------+------+ 
```

可以看到还是需要扫描12个page。

```
InnoDB_pages_distinct: 12
...
select id,c1 from t_sk where c1 is null limit 10000,1; 
```

**SQL3, 查询 c1 任意非NULL值** 如果把 c1列条件改成正常的int值，结果就不太一样了

```
[root@yejr.run]> select id, c1 from t_sk where c1  = 907299016;
+--------+-----------+
| id     | c1        |
+--------+-----------+
| 365115 | 907299016 |
+--------+-----------+
1 row in set (0.00 sec) 
```

slow log是这样的

```
InnoDB_pages_distinct: 2
...
select id, c1 from t_sk where c1  = 907299016; 
```

可以看到，只需要扫描2个page，这个看起来就正常了。

### **结论1，存储大量的NULL值，除了计算更复杂之外，数据扫描的代价也会更高一些**

另外，如果要查询的c1值正好介于两个page的临界位置，那么需要多读取一个page。

扫描第31号page，确认该数据页中的最小和最大物理记录

```
[root@yejr.run]# innodb_space -s ibdata1 -T test/t_sk -p 31 page-dump
...
records:
{:format=>:compact,
 :offset=>126,
 :header=>
  {:next=>9996,
   :type=>:conventional,
   :heap_number=>2,
   :n_owned=>0,
   :min_rec=>false,
   :deleted=>false,
   :nulls=>[],
   :lengths=>{},
   :externs=>[],
   :length=>6},
 :next=>9996,
 :type=>:secondary,
 :key=>[{:name=>"c1", :type=>"INT UNSIGNED", :value=>1531865685}],
 :row=>[{:name=>"id", :type=>"INT UNSIGNED", :value=>1507}],
 :sys=>[],
 :length=>8}
 ...
{:format=>:compact,
 :offset=>5810,
 :header=>
  {:next=>112,
   :type=>:conventional,
   :heap_number=>408,
   :n_owned=>0,
   :min_rec=>false,
   :deleted=>false,
   :nulls=>[],
   :lengths=>{},
   :externs=>[],
   :length=>6},
 :next=>112,
 :type=>:secondary,
 :key=>[{:name=>"c1", :type=>"INT UNSIGNED", :value=>1536700825}],
 :row=>[{:name=>"id", :type=>"INT UNSIGNED", :value=>361382}],
 :sys=>[],
 :length=>8} 
```

指定c1的值为 1531865685、1536700825 执行查询，查看slow log，确认都需要扫描3个page，而如果换成介于这两个值之间的数据，则只需要扫描2个page。

```
InnoDB_pages_distinct: 3
...
select id, c1 from t_sk where c1  = 1531865685;

InnoDB_pages_distinct: 3
...
select id, c1 from t_sk where c1  = 1536700825;

InnoDB_pages_distinct: 2
...
select id, c1 from t_sk where c1  = 1536630003;

InnoDB_pages_distinct: 2
...
select id, c1 from t_sk where c1  = 1536575377; 
```

这是因为辅助索引是非唯一的，即便是在等值查询时，也需要再读取下一条记录，以确认已获取所有符合条件的数据。

还有，当利用辅助索引读取数据时，如果要读取整行数据，则需要回表。

也就是说，除了扫描辅助索引数据页之外，还需要扫描聚集索引数据页。

来个例子看看就知道了。

```
#无需回表时
InnoDB_pages_distinct: 2
...
select id, c1 from tnull where c1  = 1536630003;

#需要回表时
InnoDB_pages_distinct: 5
...
select * from t_sk where c1  = 1536630003; 
```

需要回表时，除了扫描辅助索引页2个page外，还需要回表扫描聚集索引页，而聚集索引是个3层树，因此总共需要扫描5个page。

**2\. 问题2：辅助索引需要MVCC多版本读的时候，为什么需要依赖聚集索引**
-----------------------------------------

InnoDB的MVCC是通过在聚集索引页中同时存储了DB\_TRX\_ID和DB\_ROLL\_PTR来实现的。

但是我们从上面page dump出来的结果也很明显能看到，附注索引页是不存储DB\_TRX\_ID信息的。

所以说，辅助索引上如果想要实现MVCC，需要通过回表读聚集索引来实现。

### **结论2，辅助索引中不存储DB\_TRX\_ID，需要依托聚集索引实现MVCC**

**3\. 问题3：为什么查找数据时，一定要读取叶子节点，只读非叶子节点不行吗**
-----------------------------------------

在辅助索引的根节点这个页面中(pageno=4)，我们注意到它记录的最小记录(min\_rec)对应的是(c1=NULL, id=9)这条记录。

在它指向的叶子节点页面中(pageno=18)也确认了这个情况。

现在把id=9的记录删掉，看看辅助索引数据页会发生什么变化。

```
[root@yejr.run]> delete from t_sk where id = 9 and c1 is null;
Query OK, 1 row affected (0.01 sec) 
```

先检查第4号数据页。

```
[root@yejr.run]# innodb_space -s ibdata1 -T test/t_sk -p 4 page-dump
...
records:
{:format=>:compact,
 :offset=>126,
 :header=>
  {:next=>428,
   :type=>:node_pointer,
   :heap_number=>2,
   :n_owned=>0,
   :min_rec=>true,
   :deleted=>false,
   :nulls=>["c1"],
   :lengths=>{},
   :externs=>[],
   :length=>6},
 :next=>428,
 :type=>:secondary,
 :key=>[{:name=>"c1", :type=>"INT UNSIGNED", :value=>:NULL}],
 :row=>[{:name=>"id", :type=>"INT UNSIGNED", :value=>9}],
 :sys=>[],
 :child_page_number=>18,
 :length=>8}
... 
```

看到第四号数据页中，最小记录还是 id=9，没有更新。

再查看第18号数据页。

```
[root@yejr.run]# innodb_space -s ibdata1 -T test/t_sk -p 18 page-dump
...
records:
{:format=>:compact,
 :offset=>136,
 :header=>
  {:next=>146,
   :type=>:conventional,
   :heap_number=>3,
   :n_owned=>0,
   :min_rec=>false,
   :deleted=>false,
   :nulls=>["c1"],
   :lengths=>{},
   :externs=>[],
   :length=>6},
 :next=>146,
 :type=>:secondary,
 :key=>[{:name=>"c1", :type=>"INT UNSIGNED", :value=>:NULL}],
 :row=>[{:name=>"id", :type=>"INT UNSIGNED", :value=>30}],
 :sys=>[],
 :length=>4}
... 
```

在这个数据页（叶子节点）中，最小记录已经被更新成 id=30 这条数据了。

可见，索引树中的非叶子节点数据不是实时更新的，只有叶子节点的数据才是最准确的。

### **结论3，在索引树中查找数据时，最终一定是要读取叶子节点才行**

**4\. 问题4：索引列允许为NULL，会额外存储更多字节吗**
---------------------------------

之前流传有一种说法，不允许设置列值允许NULL，是因为会额外多存储一个字节，事实是这样吗？

我们先把c1列改成NOT NULL DEFAULT 0，当然了，改之前要先把所有NULL值更新成0。

```
[root@yejr.run]> update t_sk set c1=0 where c1 is null;
[root@yejr.run]> alter table t_sk modify c1 int unsigned not null default 0; 
```

在修改之前，每条索引记录长度都是10字节，更新之后却变成了13个字节。 直接对比索引页中的数据，发现不同之处

```
#允许为NULL，且默认值为NULL时
{:format=>:compact,
 :offset=>136,
 :header=>
  {:next=>146,
   :type=>:conventional,
   :heap_number=>3,
   :n_owned=>0,
   :min_rec=>false,
   :deleted=>false,
   :nulls=>["c1"],
   :lengths=>{},
   :externs=>[],
   :length=>6},
 :next=>146,
 :type=>:secondary,
 :key=>[{:name=>"c1", :type=>"INT UNSIGNED", :value=>:NULL}],
 :row=>[{:name=>"id", :type=>"INT UNSIGNED", :value=>48}],
 :sys=>[],
 :length=>4}

#不允许为NULL，默认值为0时
{:format=>:compact,
 :offset=>138,
 :header=>
  {:next=>151,
   :type=>:conventional,
   :heap_number=>3,
   :n_owned=>0,
   :min_rec=>false,
   :deleted=>false,
   :nulls=>[],
   :lengths=>{},
   :externs=>[],
   :length=>5},
 :next=>151,
 :type=>:secondary,
 :key=>[{:name=>"c1", :type=>"INT UNSIGNED", :value=>0}],
 :row=>[{:name=>"id", :type=>"INT UNSIGNED", :value=>48}],
 :sys=>[],
 :length=>8} 
```

可以看到，原先允许为NULL时，record header需要多一个字节（共6字节），但实际物理存储中无需存储NULL值。

而当设置为NOT NULL DEFAULT 0时，record header只需要5字节，但实际物理存储却多了4字节，总共多了3字节，所以索引记录以前是10字节，更新后变成了13字节，实际上代价反倒变大了。

列值允许为NULL更多的是计算代价变大了，以及索引对索引效率的影响，反倒可以说是节省了物理存储开销。

### **结论4，定义列值允许为NULL并不会增加物理存储代价，但对索引效率的影响要另外考虑**

最后，本文使用的[MySQL](https://cloud.tencent.com/product/cdb?from_column=20065&from=20065)版本Percona-Server-5.7.22，下载源码后自编译的。

```
Server version:        5.7.22-22-log Source distribution 
```

**5\. 几点总结**
------------

最后针对InnoDB辅助索引，总结几条建议吧。 a) 索引列最好不要设置允许NULL。 b) 如果是非索引列，设置允许为NULL基本上无所谓。 c) 辅助索引需要依托聚集索引实现MVCC。 d) 叶子节点总是存储最新数据，而非叶子节点则不一定。 e) 尽可能不SELECT \*，尽量利用覆盖索引完成查询，能不回表就不回表。

**6\. 延伸阅读**
------------

*   InnoDB表聚集索引层高什么时候发生变化
*   浅析InnoDB索引结构
*   Innodb页合并和页分裂
*   innblock | InnoDB page观察利器
*   jcole.us：The physical structure of InnoDB index pages
*   jcole.us：B+Tree index structures in InnoDB

Enjoy MySQL :)

全文完。

本文参与 [腾讯云自媒体同步曝光计划](https://cloud.tencent.com/developer/support-plan)，分享自微信公众号。

原始发表：2020-07-05，如有侵权请联系 [cloudcommunity@tencent.com](mailto:cloudcommunity@tencent.com) 删除
