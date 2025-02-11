| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2023-12月-18 | 2023-12月-18  |
| ... | ... | ... |
---
# MySQL 5.7新特性之动态修改innodb_buffer_pool大小

[toc]

[MySQL 5.7 动态修改 innodb_buffer_pool_size - 方东信 - 博客园](https://www.cnblogs.com/cfas/p/17824513.html#autoid-1-5-0) 

 ```
#查看当前大小
SHOW VARIABLES LIKE 'innodb_buffer_pool%';

#设置为1G 单位是字节  
set global innodb_buffer_pool_size=1073741824
```

同样的buffer pool动态调整大小由后台线程 buf_resize_thread,set命令会立即返回。通过 InnoDB_buffer_pool_resize_status可以查看调整的运行状态。

```bash
----------------------  
BUFFER POOL AND MEMORY  
---------------------- 
Total large memory allocated 26826768384  
Dictionary memory allocated 156608199  
Internal hash tables (constant factor + variable factor)  
Adaptive hash index 1038461120 (407954752 + 630506368)  
Page hash 3187928 (buffer pool 0 only)  
Dictionary cache 258596887 (101988688 + 156608199)  
File system 9986392 (812272 + 9174120)  
Lock system 63778552 (63750152 + 28400)  
Recovery system 0 (0 + 0)  
Buffer pool size 1572672  
Buffer pool size, bytes 25766658048  
Free buffers 32768  
Database pages 1501423  
Old database pages 554072  
Modified db pages 0  
Pending reads 0  
Pending writes: LRU 0, flush list 0, single page 0  
Pages made young 509913737, not young 16908464306  
0.00 youngs/s, 0.00 non-youngs/s  
Pages read 834246715, created 30683415, written 249886514  
0.00 reads/s, 0.00 creates/s, 0.75 writes/s  
Buffer pool hit rate 1000 / 1000, young-making rate 0 / 1000 not 0 / 1000  
Pages read ahead 0.00/s, evicted without access 0.00/s, Random read ahead 0.00/s  
LRU len: 1501423, unzip_LRU len: 0  
I/O sum[72]:cur[0], unzip sum[0]:cur[0]  
----------------------
```
参数 描述  
```
Total large memory allocated BufferPool向操作系统申请的连续内存空间大小 ，包括全部控制块、缓存页、以及碎片的大小  
Dictionary memory allocated 数据字典的内存空间大小（和BufferPool没有关系）  
Buffer pool size BufferPool可以容纳多少缓冲页  
Free buffers BufferPool还有多少空闲缓冲页（free链表还有多少个节点）  
Database pages LRU链表中页的数量，包含young和old两个区域的节点数量  
Old database pages LRU链表old区域的节点数量  
Modified db pages 脏页数量（flush链表中节点的数量）  
Pending reads 等待从磁盘加载到BufferPool中的页面数量  
Pending writes 等待从BufferPool刷新到磁盘中的页面数量  
LRU：从LUR链表中刷新到磁盘中的页面数量  
flush list：从flush链表中刷新到磁盘中的页面数量  
single page：以单个页面的形式刷新到磁盘中的页面数量  
Pages made young LRU链表中曾经从old区域移动到young区域头部的节点数量  
Pages made not young 在将innodb_old_blocks_time设置的值大于0时，首次访问或者后续访问某个处在old区域的节点时由于不符合时间间隔的限制而不能将其移动到young区域头部时，Page made not young的值会加1  
youngs/s 每秒从old区域移动到young区域头部的节点数量  
non-youngs/s 每秒由于时间不满足时间限制而不能从old区域移动到young区域头部的节点数量  
Pages read 读取页数  
Pages created 创建页数  
Pages written 写入页数  
Buffer pool hit rate 表示在过去某段时间内，平均访问1000次页面时，该页面有多少次已经被缓存到BufferPool中  
young-making rate 表示在过去某段时间内，平均访问1000次页面时，有多少次访问使页面移动到young区域的头部  
not（young-making rate） 表示在过去某段时间内，平均访问1000次页面时，有多少次访问没有使页面移动到young区域的头部  
LRU len LRU链表中节点的数量  
unzip_LRU len unzip_LRU链表中节点的数量  
I/O sum 最近50s读取磁盘页的总数  
I/O cur 现在正在读取的磁盘页的数量  
I/O unzip sum 最近50s解压的页面数量  
I/O unzip cur 现在正在解压的数量
```

## 背景
--

从MySQL 5.7.5版本开始，可以在线动态调整innodb_buffer_pool_size的大小，这个新特性同时也引入了参数innodb_buffer_pool_chunk_size。因为buffer pool的大小受innodb_buffer_pool_chunk_size和innodb_buffer_pool_instances两个参数影响，所以，实际innodb_buffer_pool_size的大小可能与DBA设置的并不一样，有时区别甚至还挺大。

本篇文章，主要从两个方面来解释这一新特性：

1.  怎么在线动态调整，在线调整对服务会有什么影响，适用场景有哪些。
2.  innodb_buffer_pool_chunk_size和innodb_buffer_pool_instances是怎么影响buffer pool的。

## 问题现象
----

在对MySQL 5.7.21版本的数据库做性能压测时，选择的是2G内存的虚机，并按内存的60%（2G* 60%=1228MB）设置innodb_buffer_pool_size。压测开始没多久，数据库就OOM了。

排查发现，my.cnf设置的buffer pool大小和从内存查出的完全不同：

*   my.cnf的值：innodb_buffer_pool_size = 1228MB。
*   select @@ innodb_buffer_pool_size;的值：2147483648 (2048MB)。

我只是按照内存的60%（1228MB）设置，而内存中实际的buffer pool竟然占用了整个虚拟所有的内存。my.cnf静态文件竟然不能控制buffer pool大小了？这种行为足以让DBA感到怀疑人生。

## 原因分析
----

### 名词解释

*   innodb_buffer_pool_size：该参数控制innodb缓冲池大小，用来存储innodb表和索引的数据。以下简称buffer pool。
*   innodb_buffer_pool_instances：该参数控制innodb缓冲池被划分的区域数。如果innodb_buffer_pool_size<1G，则instance为1，否则默认为8。该参数最小值为1，最大值为64。以下简称instance。
*   innodb_buffer_pool_chunk_size：该参数控制innodb缓冲池调整大小调整操作的块大小。该参数默认是128MB，最小值为1MB（可按1MB调整其大小），最大值为innodb_buffer_pool_size / innodb_buffer_pool_instances。以下简称chunk。

### 详细分析

1.  先来看看innodb_buffer_pool_size、innodb_buffer_pool_instances、innodb_buffer_pool_chunk_size这三个参数的关系 buffer pool可以存放多个instance，每个instance由多个chunk组成。instance的数量范围和chunk的总数量范围分别为1-64、1-1000。 比如，一个内存为4G的服务器，chunk是128MB。设置buffer pool为2G，instance设置为4个，那么每个instance为512MB即4个chunk。展示如下图：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-14%2014-30-21/6709977a-5e09-444a-b1ee-0acfd21d9167.png?raw=true)

2.  再来看看innodb_buffer_pool_instances和innodb_buffer_pool_chunk_size是怎么影响innodb_buffer_pool_size的：
    
    *   在初始化缓冲池时，如果innodb_buffer_pool_size小于innodb_buffer_pool_chunk_size * innodb_buffer_pool_instances的大小，那么innodb_buffer_pool_chunk_size将会被截断为innodb_buffer_pool_size / innodb_buffer_pool_instances。
        
        举例，如下图为初始状态：
        
        ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-14%2014-30-21/bc55ef62-2b35-4d71-bbb0-52d0dcad20d7.png?raw=true)
        
        在my.cnf设置innodb_buffer_pool_chunk_size=1073741824，重启实例：
        
        ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-14%2014-30-21/8f6c4606-5eb9-4e00-b82b-bc35f7fcdc9c.png?raw=true)
        
        以上，innodb_buffer_pool_chunk_size由默认的134217728调整为了 innodb_buffer_pool_size/innodb_buffer_pool_instances= 2147483648/8=268435456。
        
    *   缓冲池大小必须始终等于innodb_buffer_pool_chunk_size _innodb_buffer_pool_instances的整数倍。修改任何一个参数， MySQL都自动将innodb_buffer_pool_size调整为innodb_buffer_pool_chunk_size _innodb_buffer_pool_instances的整数倍。
        
        因为innodb_buffer_pool_chunk_size 或 innodb_buffer_pool_instances会影响innodb_buffer_pool_size的大小，所以修改时一定要特别小心。
        

## 解决方案
----

设置buffer pool时，参考计算公式：ceil(设置的buffer pool大小/chunk大小/instance个数)_chunk大小_instance个数，这个值计算出的结果要符合你想设置的预期。

## 案例复现
----

### 在线动态修改buffer pool

1.  在线调大buffer pool。加大buffer pool的过程大致如下：
    
    （1）以innodb_buffer_pool_chunk_size为单位，分配新的内存pages。  
    （2） 扩展buffer pool的AHI(adaptive hash index)链表，将新分配的pages包含进来。 （3）将新分配的pages添加到free list中。
    
    测试结果：
    
    ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-14%2014-30-21/73eb3054-ec28-4d83-ae0f-71e79134e4e9.png?raw=true)
    
2.  在线调小buffer pool。缩小buffer pool的过程大致如下：
    
    （1）重整buffer pool，准备回收pages。  
    （2）以innodb_buffer_pool_chunk_size为单位，释放删除这些pages（可能会有一些耗时）。  
    （3）调整AHI链表，使用新的内存地址。
    
    测试结果如下：
    
    ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-14%2014-30-21/88b79481-4b6a-490b-9151-f45e6f60aa86.png?raw=true)
    
    可以看到，buffer pool通过在线修改，已经从480MB调整到了256MB。
    

### MySQL 5.7.5后对buffer pool的影响因素

通过官网介绍，我们已经知道MySQL 5.7.5的buffer pool大小必须是innodb_buffer_pool_chunk_size* innodb_buffer_pool_instance的整数倍。那么这两个参数具体怎么影响buffer pool的设置的呢？

举例：系统内存4G，chunk大小为128MB，instance个数为8。

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-14%2014-30-21/97efc223-2088-4f26-912a-2638a73375c7.png?raw=true)

可以看到，在线修改时只是将buffer pool设置的比原来1073741824（1G）多 1byte， 但innodb_buffer_pool_size却自动向上调整到了2147483648（2G）。为什么会调整到2G？

计算方法：ceil(设置的buffer pool大小/chunk大小/instance个数) ∗ chunk大小 ∗ instance个数= ceil(1073741825/134217728/8) ∗ 134217728 ∗ 8= 2147483648byte=2G。

结论建议
----

### 动态调整方便快速，实测影响并不明显

实际测试，增大buffer pool对线上没有影响，缩小对线上影响也并不明显。 缩小buffer pool测试场景一：

（1）session 1：大事务正在运行，预计用内存6G。  
（2）session 2：设置buffer pool大小调整到1G。  
（3）观察到设置buffer pool大小的SQL瞬间完成，实际会等待session 1事务结束，设置才生效 。  
（4）生效过程中，系统并没有任何锁信息，对其他库表的增删改查也没有任何影响。

缩小buffer pool 测试场景二：

（1）系统中有100个并发正在执行增删改查操作。  
（2） session 2：设置buffer pool由5G到1G。  
（3）观察到设置buffer pool大小的SQL瞬间完成，但是并没有立即生效，大概过了5秒后生效。  
（4） buffer pool生效过程中，系统并没有任何锁信息，对其他库表的增删改查也没有任何影响。

### 5.7.5后设置buffer pool一定要小心

从MySQL 5.7.5开始，innodb buffer pool的大小受chunk和instance影响，所以，一定要提前计算好设置的buffer pool，否则可能会因为MySQL自动调整的buffer pool设置过大，导致实例很容易OOM。

参考计算公式：ceil(设置的buffer pool大小/chunk大小/instance个数) ∗ chunk大小 ∗ instance个数，这个值计算出的结果要符合你想设置的预期。

例如，MySQL所在虚机内存为8G，chunk为128MB，instance为8个。

*   innodb_buffer_pool只能设置为chunk大小 ∗ instance个数=1G的整数倍，也就是只能设置nG（n为整数）。
*   如果就是想设置为n.5G怎么办？可以这样处理：将chunk大小 ∗ instance个数调整为512MB的整数倍即可。如将chunk调整为64MB，instance为8，那么buffer pool你就可以设置n.5G（n为整数）啦。
*   sadasd

