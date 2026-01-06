| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-6月-12 | 2024-6月-12  |
| ... | ... | ... |
---
# innodb 三大特性

[toc]

* * *

**[innodb insert buffer 插入缓冲区的理解](https://www.cnblogs.com/zuoxingyu/p/3761461.html)**

## Innodb的三大特性
-----------

插入缓冲（change buffer）、两次写（double write）、自适应哈希索引（adaptive hash index）

## 聚集索引的插入
--------

首先我们知道在InnoDB存储引擎中，主键是行唯一的标识符（也就是我们常叨叨的聚集索引）。我们平时插入数据一般都是按照主键递增插入，因此聚集索引都是顺序的，不需要磁盘的随机读取。

比如表：

`CREATE TABLE test(
	id INT AUTO_INCREMENT,
	name VARCHAR(30),
	PRIMARY KEY(id)
);` 

如上我创建了一个主键 id,它有以下的特性：

*   Id列是自增长的
*   Id列插入NULL值时，由于AUTO_INCREMENT的原因，其值会递增
*   同时数据页中的行记录按id的值进行顺序存放

一般情况下由于聚集索引的有序性，不需要随机读取页中的数据，因为此类的顺序插入速度是非常快的。

但如果你把列 Id 插入UUID这种数据，那你插入就是和非聚集索引一样都是随机的了。会导致你的B+ tree结构不停地变化，那性能必然会受到影响。

## **非聚集索引的插入**
------------

很多时候我们的表还会有很多非聚集索引，比如我按照b字段查询，且b字段不是唯一的。如下表：

`CREATE TABLE test(
	id INT AUTO_INCREMENT,
	name VARCHAR(30),
	PRIMARY KEY(id),
	KEY(name)
);` 

这里我创建了一个x表，它有以下特点：

*   有一个聚集索引 id
*   有一个不唯一的非聚集索引 name
*   在插入数据时数据页是按照主键id进行顺序存放
*   辅助索引 name的数据插入不是顺序的

非聚集索引也是一颗B+树，只是叶子节点存的是聚集索引的主键和name 的值。

因为不能保证name列的数据是顺序的，所以非聚集索引这棵树的插入必然也不是顺序的了。

## ****Insert Buffer是什么****
------------------------

InnoDB 缓冲池包含了Insert Buffer的信息

但Insert Buffer 其实和数据页一样，也是物理存在的（以B+树的形式存在共享表空间中）。

**工作原理**

![](https://oscimg.oschina.net/oscnet/up-85bb7b2189f6e85282f26f1dadc1ce01411.JPEG)

把普通索引上的DML操作从随机IO变成顺序IO。

判断插入的普通索引页是否在缓冲池中，如果在直接插入，如果不在就要先放到change buffer中，然后进行change buffer

和普通索引的合并操作，可以将多个插入合并到一个操作中，提高普通索引的插入性能。

**使用要求**：

*   索引是非聚集索引
*   索引不是唯一（unique）的

只有满足上面两个必要条件时，InnoDB存储引擎才会使用Insert Buffer来提高插入性能。

## **自适应哈希索引（adaptive hash index）**
--------------------------------

innodb存储引擎有一个机制，可以监控索引的搜索，如果innodb注意到查询可以通过建立哈希索引得到优化，那么就可以自动完成这件事。可以通过innodb\_adaptive\_hash_index参数来控制。默认情况下是开启的。

[InnoDB双写缓冲](https://blog.csdn.net/zhaotiemaomao/article/details/51645991)

[InnoDB的双写缓冲](https://blog.csdn.net/bahao4612/article/details/102160698?utm_medium=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-1.control&depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-1.control)

## **两次写（double write）**
---------------------

[Innodb三大特性之两次写（double write)--说的比较清楚](https://blog.csdn.net/MortShi/article/details/122525895)


InnoDB使用了一种叫做double write的特殊文件flush技术

1）在把pages写到data files之前，InnoDB先把它们写到一个叫_**doublewrite buffe**_r的连续区域内

2）在写doublewrite buffer完成后，InnoDB才会把pages写到data file的适当的位置。

如果在写page的过程中发生意外崩溃，InnoDB在稍后的恢复过程中在doublewrite buffer中找到完好的page副本用于恢复。

### **partial page write问题**
------------------------

由于InnoDB和操作系统的页大小不一致，InnoDB页大小一般为16k,操作系统页大小为4k，导致InnoDB回写dirty数据到操作

系统中，一个页面需要写4次，写入过程出现问题无法保持原子性。写的过程如果崩溃或者断电，可能导致只有一部分写回

到操作系统文件系统中，整个数据只是部分成功，其实数据是损坏的。

### **redolog 不能解决**

redolog记录的是数据页的物理操作：对 XXX表空间中的XXX数据页XXX偏移量的地方做了XXX更新。如果页都损坏了，是

无法进行任何恢复操作的。所以我们需要页的一个副本，如果服务器宕机了，可以通过副本把原来的数据页还原回来。这就

是doublewrite的作用。

### doublewrite buffer
------------------

双写缓冲位于系统表空间上，128个页（2个区）大小是2MB。

1）将脏数据复制到**内存**中的doublewrite buffer，之后通过doublewrite buffer再分2次，每次写入1MB到**共享表空间**，然后马

上调用fsync函数，同步到磁盘上，避免缓冲带来的问题，在这个过程中，doublewrite是顺序写，开销并不大

2）在完成doublewrite写入后，再将double write buffer写入各表空间文件，这时是离散写入。

所以在正常的情况下, MySQL写数据page时，会写两遍到磁盘上，第一遍是写到doublewrite buffer，第二遍是从doublewrite

buffer写到真正的数据文件中。

如果发生了极端情况（断电），InnoDB再次启动后，发现了一个page数据已经损坏，那么此时就可以从doublewrite buffer中进行数据恢复了。

### doublewrite的缺点
--------------

位于共享表空间上的doublewrite buffer实际上也是一个文件，写共享表空间会导致系统有更多的fsync操作, 而硬盘的fsync性能因素会降低

MySQL的整体性能，但是并不会降低到原来的50%。这主要是因为：

1.  doublewrite是在一个连续的存储空间, 所以硬盘在写数据的时候是顺序写，而不是随机写，这样性能更高。
2.  将数据从doublewrite buffer写到真正的segment中的时候，系统会自动合并连接空间刷新的方式，每次可以刷新多个pages。

### 是否一定需要doublewrite
-----------------

在一些情况下可以关闭doublewrite以获取更高的性能。比如在slave上可以关闭，因为即使出现了partial page write问题，数据还是可以从中继日志中恢复。设置`InnoDB_doublewrite=0`即可关闭doublewrite buffer。

### MyISAM与InnoDB 的区别
-----------------

1\. InnoDB支持事务，MyISAM不支持 

2\. InnoDB支持外键，而MyISAM不支持。

3\. InnoDB是聚集索引，使用B+Tree作为索引结构，数据文件是和（主键）索引绑在一起的（表数据文件本身就是按B+Tree组织的一个索引结构），必须要有主键，通过主键索引效率很高。但是辅助索引需要两次查询，先查询到主键，然后再通过主键查询到数据。因此，主键不应该过大，因为主键太大，其他索引也都会很大。

4\. InnoDB不保存表的具体行数，执行select count(*) from table时需要全表扫描。

而MyISAM用一个变量保存了整个表的行数，执行上述语句时只需要读出该变量即可，速度很快（注意不能加有任何WHERE条件）；

5\. Innodb不支持全文索引，而MyISAM支持全文索引，在涉及全文索引领域的查询效率上MyISAM速度更快高；PS：5.7以后的InnoDB支持全文索引了

7\. InnoDB支持表、行(默认)级锁，而MyISAM支持表级锁

8、InnoDB表必须有唯一索引（如主键）（用户没有指定的话会自己找/生产一个隐藏列Row_id来充当默认主键），而Myisam可以没有