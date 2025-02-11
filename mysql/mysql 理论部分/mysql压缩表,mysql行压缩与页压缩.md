| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-6月-03 | 2024-6月-03  |
| ... | ... | ... |
---
# mysql压缩表,mysql行压缩与页压缩

[toc]

* * *

本文转自：[https://www.cnblogs.com/gered/p/15251301.html](https://www.cnblogs.com/gered/p/15251301.html)

一、概念
----

压缩表从名字上来看，简单理解为压缩后的表，也就是把原始表根据一定的压缩算法按照一定的压缩比率压缩后生成的表。

### 1.1 压缩能力强的产品

表压缩后从磁盘占用上看要比原始表要小很多。如果你熟悉列式数据库，那对这个概念一定不陌生。比如，基于 PostgreSQL 的列式数据库 Greenplum；早期基于 MySQL 的列式数据库 inforbright；或者 Percona 的产品 tokudb 等，都是有压缩能力非常强的数据库产品。

### 1.2 为什么要用压缩表？

情景一：磁盘大小为 1T，不算其他的空间占用，只能存放 10 张 100G 大小的表。如果这些表以一定的比率压缩后，比如每张表从 100G 压缩到 10G，那同样的磁盘可以存放 100 张表，表的容量是原来的 10 倍。

情景二：默认 MySQL 页大小 16K，而 OS 文件系统一般块大小为 4K，所以在 MySQL 在刷脏页的过程中，有一定的概率出现页没写全而导致数据坏掉的情形。

　　比如 16K 的页写了 12K，剩下 4K 没写成功，导致 MySQL 页数据损坏。

　　这个时候就算通过 Redo Log 也恢复不了，因为几乎有所有的关系数据库采用的 Redo Log 都记录了数据页的偏移量，此时就算通过 Redo Log 恢复后，数据也是错误的。

　　所以 MySQL 在刷脏数据之前，会把这部分数据先写入共享表空间里的 DOUBLE WRITE BUFFER 区域来避免这种异常。

　　此时如果 MySQL 采用压缩表，并且每张表页大小和磁盘块大小一致，比如也是 4K，那 DOUBLE WRITE BUFFER 就可以不需要，这部分开销就可以规避掉了。

查看文件系统的块大小：

root@ytt-pc:/home/ytt# tune2fs -l /dev/mapper/ytt--pc--vg-root | grep -i 'block size'Block size: 4096

### 1.3 压缩表的优势

压缩表的优点非常明显，占用磁盘空间小！由于占用空间小，从磁盘置换到内存以及之后经过网络传输都非常节省资源。

简单来讲：节省磁盘 IO，减少网络 IO。

### 1.4 压缩表的缺陷

当然压缩表也有缺点，压缩表的写入（INSERT,UPDATE,DELETE）比普通表要消耗更多的 CPU 资源。

压缩表的写入涉及到解压数据，更新数据，再压缩数据，比普通表多了解压和再压缩两个步骤，压缩和解压缩需要消耗一定的 CPU 资源。所以需要选择一个比较优化的压缩算法。

### 1.5 MySQL 支持的压缩算法

这块是 MySQL 所有涉及到压缩的基础，不仅仅用于压缩表，也用于其它地方。比如客户端请求到 MySQL 服务端的数据压缩；主从之间的压缩传输；利用克隆插件来复制数据库操作的压缩传输等等。

从下面结果可以看到 MySQL 支持的压缩算法为 zlib 和 zstd，MySQL 默认压缩算法为 zlib，当然你也可以选择非 zlib 算法，比如 zstd。至于哪种压缩算法最优，暂时没办法简单量化，依赖表中的数据分布或者业务请求。

mysql> select @@protocol\_compression\_algorithms;+-----------------------------------+| @@protocol\_compression\_algorithms |+-----------------------------------+| zlib,zstd,uncompressed |+-----------------------------------+1 row in set (0.00 sec)

可以查看 MySQL 支持的 zlib 版本：

mysql> select @@version\_compile\_zlib;+------------------------+| @@version\_compile\_zlib |+------------------------+| 1.2.11 |+------------------------+1 row in set (0.00 sec)

二、如何在 MySQL 表引擎中使用压缩表
---------------------

MySQL 单机版支持压缩表的有两个引擎：MyISAM 和 InnoDB。

### 2.1 基于 MyISAM 引擎，以表字段为单位的压缩表

举个简单例子，创建一个 MyISAM 引擎表 n1。这是 MySQL 一直以来最常用的压缩表方式。

mysql> create table n1(id int,r1 text,r2 text,key idx\_id(id),key idx\_r1(r1(10))) engine myisam;Query OK, 0 rows affected (0.01 sec)

插入 10W 行记录，此处省略。

未压缩时数据大小为 116M，索引大小为 1.4M

　　root@ytt-pc:/var/lib/mysql/3304/ytt# ls -sihl n1.{MYD,MYI}3539537 116M -rw-r----- 1 mysql mysql 116M 3月 31 11:46 n1.MYD3539536 1.4M -rw-r----- 1 mysql mysql 1.4M 3月 31 11:48 n1.MYI

对 MyISAM 表的压缩，MySQL 通过自带程序 myisampack 来压缩，仅仅压缩表数据，不对索引进行压缩。

　　root@ytt-pc:/var/lib/mysql/3304/ytt# myisampack n1 -vCompressing n1.MYD: (100000 records)- Calculating statistics

normal: 1 empty-space: 0 empty-zero: 0 empty-fill: 1pre-space: 0 end-space: 0 intervall-fields: 0 zero: 0Original trees: 4 After join: 4- Compressing fileMin record length: 310 Max length: 311 Mean total length: 31673.93%Remember to run myisamchk -rq on compressed tables

User time 0.93, System time 0.30Maximum resident set size 6572, Integral resident set size 0Non-physical pagefaults 499, Physical pagefaults 2, Swaps 0Blocks in 48 out 61928, Messages in 0 out 0, Signals 0Voluntary context switches 2, Involuntary context switches 560

压缩完后，需要重建索引。

　　root@ytt-pc:/var/lib/mysql/3304/ytt# myisamchk -rq n1- check record delete-chain- recovering (with sort) MyISAM-table 'n1'Data records: 100000- Fixing index 1- Fixing index 2

压缩后数据大小为 31M，索引大小为 1.4M，数据比原始表小了 4 倍。

　　root@ytt-pc:/var/lib/mysql/3304/ytt# ls -sihl n1.{MYD,MYI}3539542 31M -rw-r----- 1 mysql mysql 31M 3月 31 11:46 n1.MYD3539536 1.4M -rw-r----- 1 mysql mysql 1.4M 3月 31 11:48 n1.MYI

MyISAM 压缩表非常适合只读的场景！

### 2.2 基于 InnoDB 引擎的以页为单位的压缩表

这也是 MySQL 现在主推的方式。后期所有的压缩表如果没有特别说明，都指的是 InnoDB 的压缩表。

InnoDB 压缩表和 MyISAM 压缩表不同是针对页的压缩。InnoDB 不仅压缩了数据，也压缩了索引。InnoDB 页大小分别为 1K、2K、4K、8K、16K、32K、64K，默认为 16K，32K 和 64K 不支持压缩。

以上规律也就是说表压缩是针对默认 16K 大小的页的倍数递减，通过指定 key\_block\_size 来设置压缩表的页大小。比如 8K 的页，key\_block\_size=8，默认 row\_format 为 compressed，或者把 row\_format 设置为 compressed，即代表 key\_block\_size=8。

在默认单表空间下，建立一张表 t1，默认为 InnoDB 引擎，默认页大小为 8K。

模拟点数据

　　mysql> create table t1(id int primary key, r1 varchar(200),r2 text);Query OK, 0 rows affected (0.07 sec)

此处模拟 1W 行记录，数据文件大小为 22M。省略过程

　　root@ytt-pc:/var/lib/mysql/3304/ytt# ls -sihl总用量 22M3539514 22M -rw-r----- 1 mysql mysql 21M 3月 30 22:26 t1.ibd

更改表行格式为 compressed

　　mysql> alter table t1 row_format=compressed;Query OK, 0 rows affected (3.99 sec)Records: 0 Duplicates: 0 Warnings: 0

数据文件大小为 10M。压缩率大约为 50%

　　root@ytt-pc:/var/lib/mysql/3304/ytt# ls -sihl总用量 11M3539513 11M -rw-r----- 1 mysql mysql 10M 3月 30 22:27 t1.ibd

单表空间的优点是可以管理多个基于不同页磁盘表。刚才表 t1 基于页大小为 8K，在当前数据库下可以并存页大小为 4K 的表 t2，指定 key\_block\_size=4

　　mysql> create table t2(id int primary key, r1 varchar(200),r2 text) key\_block\_size=4;Query OK, 0 rows affected (0.07 sec)

通用表空间只支持和表空间文件块大小一致的压缩表。

比如通用表空间 ytt\_ts1 文件块大小为 4K，key\_block_size 必须等于 4。也就是说只支持页大小和文件块大小一样的压缩表。

　　mysql> create tablespace ytt\_ts1 add datafile 'ytt\_ts1.ibd' file\_block\_size=4K;Query OK, 0 rows affected (0.05 sec)

　　mysql> create table t3 like t2;Query OK, 0 rows affected (0.06 sec)

　　mysql> alter table t3 tablespace ytt_ts1;Query OK, 0 rows affected (0.09 sec)Records: 0 Duplicates: 0 Warnings: 0

对于和表空间文件块大小不一致的表，则报错。表 t4 页面大小为 8K，和4K 不匹配。

　　mysql> create table t4 like t2;Query OK, 0 rows affected (0.05 sec)

　　mysql> alter table t4 key\_block\_size=8;Query OK, 0 rows affected (0.15 sec)Records: 0 Duplicates: 0 Warnings: 0

　　mysql> alter table t4 tablespace ytt\_ts1;ERROR 1478 (HY000): InnoDB: Tablespace \`ytt\_ts1\` uses block size 4096 and cannot contain a table with physical page size 8192

　　mysql> drop table t4;Query OK, 0 rows affected (0.05 sec)

三、压缩表对 B-tree 页面和 InnoDB Buffer Pool 的影响
----------------------------------------

### 3.1 对 B-tree 页面的压缩

1）每个 B-tree 页压缩表至少保存一条记录

　　这一点相比普通表页来说，相对灵活些，比如普通表每个页至少保留两条记录。

2）更改日志（modification log）

　　MySQL 为每个压缩页里设置一个 16K 大小的更改日志，用来解决对压缩表进行写入时的一系列问题。比如，页分裂或者不必要的解压和重新压缩等。

　　每个页面会预留空一部分空余空间来保存压缩页需要修改的行。这样做的好处是不用每次都对整个页进行解压、再更新、再压缩等步骤，节省开销。那这些行的更新放在更改日志里，当更改日志满了，就进行一次数据压缩。对应参数为：i　　　　nnodb\_compression\_pad\_pct\_max（默认 50，代表 50%）。如果重新压缩时失败了，那就需要进行相关页的分裂与合并，直到重新压缩成功。

　　举个例子：假设压缩页 1 里保存了 10 条记录，可能每分钟要轮流更新一行记录，那如果每分钟都对整个页进行解压，更新，再压缩，对 CPU 开销很大，此时可以把这些更新的行放到更改日志里，等更改日志满了，再一次性重新压缩这些记录。

### 3.2 压缩表和 InnoDB Buffer Pool

每个压缩页在 InnoDB Buffer Pool 里存放的是压缩页和非压缩并存的形式。

比如说，读取一张压缩表的一行记录，如果 Buffer Pool 里没有，就需要回表找到包含这行记录的压缩页（1k,2k,4k,8k)，放入 Buffer Pool，同时放入包含这行的非压缩页（16K）

这么做的目的减少不必要的页解压。如果 Buffer Pool 满了，把原始页面踢出，保留压缩页；极端情形，Buffer Pool 里两者都不包含。

四、压缩表的限制
--------

1）系统表空间不支持；

2）通用表空间不能混合存储压缩表以及原始表；

3）row_format=compressed，这种方式容易混淆成针对行的压缩，其实是针对表和相关索引的压缩。这点和其他列式存储引擎的表完全不一样；

4）临时表不支持。
```sql
mysql> create temporary table tmp_t1(id int,r1 text,r2 text) row_format=compressed;ERROR 3500 (HY000): CREATE TEMPORARY TABLE is not allowed with ROW_FORMAT=COMPRESSED or KEY_BLOCK_SIZE.

mysql> show errors
1. row Level: ErrorCode: 3500
Message: CREATE TEMPORARY TABLE is not allowed with ROW\_FORMAT=COMPRESSED or KEY\_BLOCK\_SIZE.
2. row ***************************Level: ErrorCode: 1031
Message: Table storage engine for 'tmp_t1' doesn't have this option2 rows in set (0.00 sec)
```

【最佳实践】
------

### （1）innodb

在线 alter table tab key\_block\_size=8; 启用页压缩，这个要没有varchar等字段才行，否则会失败；

　　不影响DML，但有元数据锁

在线 alter table table row_format=compressed，可以直接运行；

　　不影响DML，但有元数据锁