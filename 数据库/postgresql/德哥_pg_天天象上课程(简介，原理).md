
# pg学习笔记

[toc]

## 第一章 pg的前世今生
pg的发展前景

1.去o 来说pg是不错的，毕竟很多国产数据都是base pg 的。
2.pg 功能相对比较全面，能够在要求不高的情况下，相对不错的实现多种目标，能有效减少数据库系统的复杂性。
3.兼容度相对好。

## 第二章 原理
###  用户认证

### 数据库可靠性
![数据库可靠性](数据库可靠性.png)

pg os write函数 
wal_sync_method

### 时间点恢复
1. 还原点
2. 时间点恢复
3. lsn
4. xid

### 时间线-主备切换
pg_control_data 查看

recovery_target_timeline = 执行恢复到时间线

### 异步流复制 + 同步流复制

### 多副本 -- 针对同步流复制 
frist模式
any模式

![多副本介绍](多副本介绍.png)


![多副本HA切换流程](多副本HA切换流程.png)


### 逻辑订阅流程
![逻辑订阅流程](逻辑订阅流程.png)

### 数据文件结构

### 页结构
select pg_relaion_filepath("table_name")
![数据页结构layout](数据页结构layout.png)
1. item 是數據行的偏移量
2. 可以通過pg_relaion_filepath("table_name") 函數获取表在表空间中的位置，即上图中的66326，其中20699 是表空间的编号
`select oid，datname from pg_database;` 可以查看表空间的oid 和 表空间名称。

### 行结构
tuple的layout
OID 
xmin
xmax
cmin
cmax
ctid


### 切片存储 TOAST介绍
* 当变长字段压缩后超过1/4个page  
* 转存到TOAST,tuple中存储地址  
* 通过TOAST macro 访问toast内的数据  
* 一个变长字段可以存储**1GB**,例如 字符串，数组，bytea,varbit等  
  

### 大对象介绍
![大对象介绍](大对象介绍.png)  

### 索引结构

#### btree索引

![btree索引介绍](btree索引介绍.png)  
1. pg的btree 索引的根节点和branch 节点是可以存储数据的。与mysql 是不同的。  
2. 一个8k 的页大约能存储285个item (item 是数据行的偏移量，可以看做一行数据)  
3. 三层结构（只需要经过一层branch 节点）最多存储 285^3 条数据 （2000多万）条记录。  
4.二级索引，包括一个root page 1个或多个branch page ，多个leafpage。 与mysql 不同**branch page 是双向链表**  
![二级索引](二级索引.png)

#### gin索引（倒排索引）
![索引结构](gin索引结构.png)
1. 类似的btree,但是不是保存的item ，而是保存的key 和point   
2. point 会指向posting list 和 posting tree。 这时候就可以找到对应的item了  
3. 为了避免大量的更新，以及实时的数据写入，不能及时的被更新到gin 索引中的问题，引入了**pending list**。可以类比写入缓冲区。每次搜索的时候的，pending list 和tree 一样要被扫描。

[《PostgreSQL pageinspect 诊断与优化GIN (倒排) 索引合并延迟导致的查询性能下降问题》](https://github.com/13679269754/digoal_pg_blog/blob/master/201809/20180919_02.md)

#### rum索引结构
![rum索引结构](rum索引结构.png)
索引中存储额外信息，能够实现排序等等需求

#### hash索引
![hash索引结构](hash索引结构.png)

#### gist索引
空间索引

#### brin索引结构 （block_range_index）
有点类似于mysql histogram，但是用处不同，mysql的histogram 一般用于表连接的优化器质性路径选择方面。（在优化器失效（错误的选择质性计划）时，就它上手的时候）。
![brin索引结构](brin索引结构.png)

1. pg 表数据的相关性（有序性）
` select correlation from pg_stats where attname='id' and table_name = 'table_name '` 1 为完全相关 ， 0 完全不相关

#### bloom索引结构
![bloom索引结构](bloom索引结构.png)


### 聚簇存储

![聚簇存储](聚簇存储.png)

1. 可以看到pg的聚簇存储(cluster)并不是基于索引的，它无法通过索引来维持数据的顺序性。

### io放大与消除实践
**此处针对数据分布分散不集中导致的io放大**，  
**消除方法：聚簇存储 或者 pg 11 以后的index include**  
pg 创造数据并插入
```sql
create table t_cluster {order int ,pos point ,crt_time timestamp};

insert into t_cluster select random()*10000 ,point(random()*100,random()*100),clock_timestamp() from genetate_series(1,1000000);

create index idx_t_cluster on t_cluster (orderid,crt_time);
```

```sql
select pos from t_cluster where orderid=2 order by crt_time;
-- 查看数据块
explain (analyze,verbose,timing,costs,buffers) select pos from t_cluster where orderid=2 order by crt_time;
……
    buffers：shared hit=967
……
-- 根据索引idx_t_cluster构建cluster
cluster t_cluster USING idx_t_cluster;  -- DDL
```

#### index include （pg的 索引组织表） 
```sql
-- 语法 
create index idx_t_cluster on t_cluster (orderid crt_time) include(pos);
```

### AOI 优化
AOI优化（SPLIT）  
![AOI优化](AOI优化（SPLIT）.png)

GIST 索引面优化收敛  
[multipolygon 空间索引查询过滤精简优化 - IO，CPU放大优化](https://github.com/13679269754/digoal_pg_blog/blob/master/201711/20171122_03.md)


### 回收机制
多版本 时 会起作用产生

#### 多版本数据时对索引的更新优化
HOT 原理
[Heap Only Tuple - HOT (降低UPDATE引入的索引写IO放大)](https://github.com/13679269754/digoal_pg_blog/blob/master/201809/20180925_02.md)
![HOT原理](HOT原理1.png)

![HOT原理2](HOT原理2.png)

1. 当新的版本数据与旧版本数据在同一个页才能起作用；
2. 可以减少更新数据时对索引的更新；
3. 需要注意的是，如果更新的是索引字段,则也无法起作用。

#### page的回收，reuse机制
![page的回收，reuse机制](page的回收，reuse机制.png)
1. **heap page **的垃圾回收语句
```sql
vacuum VERBOSE table_name;
```

![水位问题](水位问题.png)

2. **index page** 如何释放空间
```sql
reindex | concurrently | index_name
```

#### FSM结构
free space map 一个附加文件
![FSM结构](FSM结构.png)

#### VM结构
visibilitymap
![VM结构](VM结构.png)
1. index only scan 时判断数据页是否可见，减少回表操作，当 flag for bit map 是 0x01（VISIBILITYMAP_ALL_VISIBLE）时，可以不回表就能确定index 中存储就是最新版本数据，而不需要回表
   * index scan 操作是无法进行多版本控制的，因为数据的多版本存放在具体的数据页内，通过index page 是无法得知数据的版本的。 index scan 是必须回表的；而index only scan 就可以通过vm 结构来减少回表。
2. 同理 vacuum 跳过 VISIBILITYMAP_ALL_VISIBLE，和 VISIBILITYMAP_ALL_FROZEN也很容易理解。


#### 垃圾回收机制
![垃圾回收](垃圾回收.png)

1. 查看表是否需要垃圾回收
```sql 
\d pg_stat_all_tables;

select * from pg_stat_all_tables; 
postgres=# \x
扩展显示已打开.
postgres=# select * from pg_stat_all_tables;
-[ RECORD 1 ]-------+------------------------
relid               | 3541
schemaname          | pg_catalog
relname             | pg_range
seq_scan            | 0
seq_tup_read        | 0
idx_scan            | 0
idx_tup_fetch       | 0
n_tup_ins           | 0
n_tup_upd           | 0
n_tup_del           | 0          
n_tup_hot_upd       | 0
n_live_tup          | 0          -- 有效记录
n_dead_tup          | 0          -- 需要做垃圾回收的tuple
n_mod_since_analyze | 0
n_ins_since_vacuum  | 0
last_vacuum         |
last_autovacuum     |
last_analyze        |
last_autoanalyze    |
vacuum_count        | 0
autovacuum_count    | 0
analyze_count       | 0
autoanalyze_count   | 0
```

2. track_count 是垃圾回收标记，默认打开，关闭则不执行垃圾回收
3. 为了防止垃圾回收占用过多资源，pg 采用了回收worker process 休息机制
    * vacuum_cost_delay=0ms : 休息时间  1-100ms
    * vacuum_cost_limit=200 ：回收的代价消耗  1-10000
    * vacuum_page_hit = 1 : buffer 中命中的垃圾数据块的cost
    * vacuum_page_miss = 10 : 不是在buffer 中命中而是从磁盘读取的数据块命中的cost
    * vacuum_page_dirty = 20 : 垃圾回收使一个不是脏页变成了脏页的cost
4. 有哪些页会被扫描，看VM
5. 哪些tuple被回收：比 GetOldest xmin （当前数据库正在运行的最老的事务号）更老的事务号产生的tuple。 

#### 索引的垃圾回收
![索引的垃圾回收](索引垃圾回收.png)
1. 当autovocuum_work_mem 过小时，可能会导致，需要清理autovacuum_work_mem（一次装不下全部的dead tuple），导致索引需要重复扫描。

#### 数据文件膨胀总结
![数据文件膨胀](数据文件膨胀.png)

#### 事务号的冻结
![事务号的冻结](事务号的冻结.png)

表的年龄: pg_class  **refrozenxid**字段
数据库的年龄 ： pg_database **refrozenxid**

1. 由于pg 的事务号是有限个的，使用事务号来推进版本，终究有天事务号会用尽，所需事务号需要循环使用。  
2. 事务号会被分为两部分，**正在使用的**，和**未来可用的**。  
3. vacuum_freeze_min_age, 当vacuum 时，发现记录的年龄大于 vacuum_freeze_min_age 则会被标记freeze (对所有人可见)。
4. vacuum_freeze_table_age ,当vacuum时发现表的年龄大于vacuum_freeze_table_age，则扫描表，将大于vacuum_freeze_min_age 的 tuple 标记为freeze ,最终会将表的年龄 降到 等于 vacuum_freeze_min_age

[单用户模式修复Repair Database ](https://github.com/digoal/blog/blob/master/201012/20101210_01.md)

#### freeze风暴，追溯
![freeze风暴](freeze风暴.png)

[如何预测Freeze IO风暴](https://github.com/digoal/blog/blob/master/201606/20160612_01.md)
[freeze 风暴导致的IOPS飙升 - 事后追溯](https://github.com/digoal/blog/blob/master/201801/20180117_03.md)


#### zheap存储引擎
![zheap存储引擎](zheap存储引擎.png)


### 数据扫描方法

#### seq_scan
![seq_scan](./image/seq_scan.png)
1. 当时seq_scan数据写入shared_buffer时，当表的大小超过shared_buffer 的1/4，则会打上TAG:BAS_BULKREAD 标记，被优先淘汰。


![并发seq_scan](并发seq_scan.png)
2. 多会话并行扫描单表的优化，尽量步调一致，一个block 只占用一次io(尽量做到)


#### index only scan
![index_only_scan](index_only_scan.png)

1. visibilitymap 对覆盖索引的意义：减少回表操作，当VM标记为 VISIBILITYMAP_ALL_VISIBLE 01 即可不回表。

#### index scan
![index_scan](index_scan.png)

1. 需要回表的查询，即index 不是覆盖索引。

#### index skip scan
![index_skip_scan](index_skip_scan.png)


#### bitmap scan
![bitmap_scan](bitmap_scan.png)

1. 被用来处理大量的离散读取
2. 注意排序的是block id  
3. 需要recheck index cond


#### ctid scan
![ctid_scan](ctid_scan.png)
[在PostgreSQL中实现update | delete limit - CTID扫描实践 (高效阅后即焚)](https://github.com/digoal/blog/blob/master/201608/20160827_01.md)

### 数据的join的方法
![join1](join1.png)

join方法
![join方法](join方法.png)
1. merge join 与hash join 都只支持等值查询
2. nestloop join 可以分为 data page join 与 index page join
3. merge join 
   ![merge_join](<merge_join .png>)
   有点类似于mrr 
   [《PostgreSQL merge join 扫描方法实例细说，以及SQL写法注意 或 内核优化建议 - query rewrite》](https://github.com/digoal/blog/blob/master/201907/20190713_01.md)
4. hash join
    ![hash_join](hash_join.png)
    pg 11 后对**并行hash join** 有很大提升 10亿级别的join 可以做到10s 左右
    ![并行hash_join](并行hash_join.png)

### 并行计算
思考和问题
* 半夜跑分析sql 很慢怎么办
* 业务高峰，如果有很耗资源的sql怎么办

![并行计算](并行计算.png)
1. PG 会对并行任务自动计算并行度：代价(分析并行代价，与普通查询代价的区别)，会结合数据库的配置，例如最大并行度，表的并行配置等等
2. 并行计算资源控制
![并行计算资源控制](并行计算资源控制.png)

[PostgreSQL 11 并行计算算法，参数，强制并行度设置](https://github.com/digoal/blog/blob/master/201812/20181218_01.md)  
[PostgreSQL 9.6 引领开源数据库攻克多核并行计算难题](https://github.com/digoal/blog/blob/master/201610/20161001_01.md)  
3. 强制并行度控制 
![强制并行度控制](强制并行度控制.png)


### 优化器设置
![执行计划](执行计划1.png)  

![执行计划2](执行计划2.png)

#### **EXPLAIN参数说明**
![explain参数说明](explain参数说明.png)
1. 注意analyze 的说明: 这个选项时真实的会去执行查询。
可以采用
```sql
begin;
explain analyze [query] ;
rollback;
```

2. buffers 选项讲解
![xplain_buffers_选项](explain_buffers_选项.png)

#### 优化器成本开关

![优化器成本相关参数](优化器成本相关参数.png)

[优化器成本因子校对 - PostgreSQL explain cost constants alignment to timestamp](https://github.com/digoal/blog/blob/master/201311/20131126_03.md)

#### 统计信息
![列统计信息](列统计信息.png)

```sql 
\d pg_stats
\d pg_class
```

#### join 的优化
![固定join顺序](固定join顺序.png)

![GEQO遗传算法](GEQO遗传算法.png)

![sql_hint](sql_hint.png)

![sr_plan](sr_plan.png)

自适应查询优化  
[AQO](https://github.com/postgrespro/aqo)