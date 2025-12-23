| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-7月-29 | 2025-7月-29  |
| ... | ... | ... |
---
# 对mysql engine innodb status 的解析

[toc]

## show engine innodb status


```

=====================================
2025-07-29 15:39:17 140525222442752 INNODB MONITOR OUTPUT
=====================================
Per second averages calculated from the last 41 seconds
-----------------
BACKGROUND THREAD
-----------------
srv_master_thread loops: 2714 srv_active, 0 srv_shutdown, 103588 srv_idle
srv_master_thread log flush and writes: 0
----------
SEMAPHORES
----------
OS WAIT ARRAY INFO: reservation count 127524
OS WAIT ARRAY INFO: signal count 122652
RW-shared spins 0, rounds 0, OS waits 0
RW-excl spins 0, rounds 0, OS waits 0
RW-sx spins 0, rounds 0, OS waits 0
Spin rounds per wait: 0.00 RW-shared, 0.00 RW-excl, 0.00 RW-sx
------------
TRANSACTIONS
------------
Trx id counter 2442327581
Purge done for trx's n:o < 2442327580 undo n:o < 0 state: running but idle
History list length 2
LIST OF TRANSACTIONS FOR EACH SESSION:
---TRANSACTION 422081287872512, not started
0 lock struct(s), heap size 1128, 0 row lock(s)
---TRANSACTION 422081287874128, not started
0 lock struct(s), heap size 1128, 0 row lock(s)
---TRANSACTION 422081287873320, not started
0 lock struct(s), heap size 1128, 0 row lock(s)
---TRANSACTION 422081287876552, not started
0 lock struct(s), heap size 1128, 0 row lock(s)
---TRANSACTION 422081287874936, not started
0 lock struct(s), heap size 1128, 0 row lock(s)
---TRANSACTION 422081287871704, not started
0 lock struct(s), heap size 1128, 0 row lock(s)
---TRANSACTION 422081287870896, not started
0 lock struct(s), heap size 1128, 0 row lock(s)
---TRANSACTION 422081287870088, not started
0 lock struct(s), heap size 1128, 0 row lock(s)
--------
FILE I/O
--------
I/O thread 0 state: waiting for i/o request ((null))
I/O thread 1 state: waiting for i/o request (insert buffer thread)
I/O thread 2 state: waiting for i/o request (read thread)
I/O thread 3 state: waiting for i/o request (read thread)
I/O thread 4 state: waiting for i/o request (read thread)
I/O thread 5 state: waiting for i/o request (read thread)
I/O thread 6 state: waiting for i/o request (read thread)
I/O thread 7 state: waiting for i/o request (read thread)
I/O thread 8 state: waiting for i/o request (read thread)
I/O thread 9 state: waiting for i/o request (read thread)
I/O thread 10 state: waiting for i/o request (read thread)
I/O thread 11 state: waiting for i/o request (read thread)
I/O thread 12 state: waiting for i/o request (read thread)
I/O thread 13 state: waiting for i/o request (read thread)
I/O thread 14 state: waiting for i/o request (read thread)
I/O thread 15 state: waiting for i/o request (read thread)
I/O thread 16 state: waiting for i/o request (read thread)
I/O thread 17 state: waiting for i/o request (read thread)
I/O thread 18 state: waiting for i/o request (write thread)
I/O thread 19 state: waiting for i/o request (write thread)
I/O thread 20 state: waiting for i/o request (write thread)
I/O thread 21 state: waiting for i/o request (write thread)
I/O thread 22 state: waiting for i/o request (write thread)
I/O thread 23 state: waiting for i/o request (write thread)
I/O thread 24 state: waiting for i/o request (write thread)
I/O thread 25 state: waiting for i/o request (write thread)
I/O thread 26 state: waiting for i/o request (write thread)
I/O thread 27 state: waiting for i/o request (write thread)
I/O thread 28 state: waiting for i/o request (write thread)
I/O thread 29 state: waiting for i/o request (write thread)
I/O thread 30 state: waiting for i/o request (write thread)
I/O thread 31 state: waiting for i/o request (write thread)
I/O thread 32 state: waiting for i/o request (write thread)
Pending normal aio reads: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] , aio writes: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] ,
 ibuf aio reads:
Pending flushes (fsync) log: 0; buffer pool: 0
2173041 OS file reads, 114336 OS file writes, 49823 OS fsyncs
0.00 reads/s, 0 avg bytes/read, 0.46 writes/s, 0.32 fsyncs/s
-------------------------------------
INSERT BUFFER AND ADAPTIVE HASH INDEX
-------------------------------------
Ibuf: size 1, free list len 1271, seg size 1273, 99 merges
merged operations:
 insert 162, delete mark 0, delete 0
discarded operations:
 insert 0, delete mark 0, delete 0
Hash table size 10624987, node heap has 3243 buffer(s)
Hash table size 10624987, node heap has 75 buffer(s)
Hash table size 10624987, node heap has 3008 buffer(s)
Hash table size 10624987, node heap has 378 buffer(s)
Hash table size 10624987, node heap has 2953 buffer(s)
Hash table size 10624987, node heap has 17802 buffer(s)
Hash table size 10624987, node heap has 86 buffer(s)
Hash table size 10624987, node heap has 81 buffer(s)
4.49 hash searches/s, 2.90 non-hash searches/s
---
LOG
---
Log sequence number          3412430470625
Log buffer assigned up to    3412430470625
Log buffer completed up to   3412430470625
Log written up to            3412430470625
Log flushed up to            3412430470625
Added dirty pages up to      3412430470625
Pages flushed up to          3412430470625
Last checkpoint at           3412430470625
Log minimum file id is       13
Log maximum file id is       13
68244 log i/o's done, 0.15 log i/o's/second
----------------------
BUFFER POOL AND MEMORY
----------------------
Total large memory allocated 0
Dictionary memory allocated 4701186
Buffer pool size   2621210
Free buffers       420668
Database pages     2172916
Old database pages 802189
Modified db pages  0
Pending reads      0
Pending writes: LRU 0, flush list 0, single page 0
Pages made young 12, not young 0
0.00 youngs/s, 0.00 non-youngs/s
Pages read 2172233, created 683, written 32681
0.00 reads/s, 0.00 creates/s, 0.22 writes/s
Buffer pool hit rate 1000 / 1000, young-making rate 0 / 1000 not 0 / 1000
Pages read ahead 0.00/s, evicted without access 0.00/s, Random read ahead 0.00/s
LRU len: 2172916, unzip_LRU len: 0
I/O sum[0]:cur[0], unzip sum[0]:cur[0]
----------------------
INDIVIDUAL BUFFER POOL INFO
----------------------
---BUFFER POOL 0
Buffer pool size   655317
Free buffers       102946
Database pages     545457
Old database pages 201369
Modified db pages  0
Pending reads      0
Pending writes: LRU 0, flush list 0, single page 0
Pages made young 3, not young 0
0.00 youngs/s, 0.00 non-youngs/s
Pages read 545324, created 133, written 10181
0.00 reads/s, 0.00 creates/s, 0.02 writes/s
Buffer pool hit rate 1000 / 1000, young-making rate 0 / 1000 not 0 / 1000
Pages read ahead 0.00/s, evicted without access 0.00/s, Random read ahead 0.00/s
LRU len: 545457, unzip_LRU len: 0
I/O sum[0]:cur[0], unzip sum[0]:cur[0]
---BUFFER POOL 1
Buffer pool size   655297
Free buffers       100624
Database pages     547748
Old database pages 202216
Modified db pages  0
Pending reads      0
Pending writes: LRU 0, flush list 0, single page 0
Pages made young 5, not young 0
0.00 youngs/s, 0.00 non-youngs/s
Pages read 547532, created 216, written 2033
0.00 reads/s, 0.00 creates/s, 0.00 writes/s
Buffer pool hit rate 1000 / 1000, young-making rate 0 / 1000 not 0 / 1000
Pages read ahead 0.00/s, evicted without access 0.00/s, Random read ahead 0.00/s
LRU len: 547748, unzip_LRU len: 0
I/O sum[0]:cur[0], unzip sum[0]:cur[0]
---BUFFER POOL 2
Buffer pool size   655289
Free buffers       109461
Database pages     538919
Old database pages 198956
Modified db pages  0
Pending reads      0
Pending writes: LRU 0, flush list 0, single page 0
Pages made young 2, not young 0
0.00 youngs/s, 0.00 non-youngs/s
Pages read 538720, created 199, written 10015
0.00 reads/s, 0.00 creates/s, 0.10 writes/s
Buffer pool hit rate 1000 / 1000, young-making rate 0 / 1000 not 0 / 1000
Pages read ahead 0.00/s, evicted without access 0.00/s, Random read ahead 0.00/s
LRU len: 538919, unzip_LRU len: 0
I/O sum[0]:cur[0], unzip sum[0]:cur[0]
---BUFFER POOL 3
Buffer pool size   655307
Free buffers       107637
Database pages     540792
Old database pages 199648
Modified db pages  0
Pending reads      0
Pending writes: LRU 0, flush list 0, single page 0
Pages made young 2, not young 0
0.00 youngs/s, 0.00 non-youngs/s
Pages read 540657, created 135, written 10452
0.00 reads/s, 0.00 creates/s, 0.10 writes/s
Buffer pool hit rate 1000 / 1000, young-making rate 0 / 1000 not 0 / 1000
Pages read ahead 0.00/s, evicted without access 0.00/s, Random read ahead 0.00/s
LRU len: 540792, unzip_LRU len: 0
I/O sum[0]:cur[0], unzip sum[0]:cur[0]
--------------
ROW OPERATIONS
--------------
0 queries inside InnoDB, 0 queries in queue
0 read views open inside InnoDB
Process ID=14225, Main thread ID=140583663425280 , state=sleeping
Number of rows inserted 11911, updated 83718, deleted 0, read 4716617455
0.00 inserts/s, 1.12 updates/s, 0.00 deletes/s, 52785.44 reads/s
Number of system rows inserted 2547, updated 530, deleted 2413, read 51680
0.02 inserts/s, 0.00 updates/s, 0.00 deletes/s, 0.00 reads/s
----------------------------
END OF INNODB MONITOR OUTPUT
============================

```

以下是InnoDB监控输出中各主要项目的含义及关键关注指标的详细解释：


## 解析

### **一、BACKGROUND THREAD（后台线程）**
- **含义**：记录InnoDB主线程（srv_master_thread）的运行状态，该线程负责协调InnoDB的核心后台任务（如刷新缓冲池、合并插入缓冲、清理undo日志等）。
- **关键指标**：
  - `srv_master_thread loops`：主线程的循环状态统计，包括`active`（活跃，处理任务）、`shutdown`（关闭）、`idle`（空闲）。  
    示例中：`2714 srv_active`（活跃2714次）、`103588 srv_idle`（空闲103588次）、`0 srv_shutdown`（未关闭）。  
    说明：主线程大部分时间处于空闲状态，符合低负载场景（活跃次数远小于空闲次数）。
  - `srv_master_thread log flush and writes`：主线程执行日志刷新和写入的次数，此处为0，说明近期无主线程触发的日志刷新（可能由其他线程处理）。


### **二、SEMAPHORES（信号量）**
- **含义**：监控InnoDB内部锁（如行锁、表锁）的竞争情况，信号量是协调多线程访问共享资源的机制，锁竞争会直接影响性能。
- **关键指标**：
  - `OS WAIT ARRAY INFO`：OS等待数组的`reservation count`（预约数，127524）和`signal count`（信号数，122652），反映历史上的锁预约和唤醒次数，绝对值无明确阈值，需结合趋势判断。
  - `RW-shared`/`RW-excl`/`RW-sx`：共享锁、排他锁、意向排他锁的自旋（spins）、轮次（rounds）、OS等待（OS waits）次数。  
    示例中均为0，说明**无锁竞争导致的等待**，是理想状态（锁竞争会导致线程阻塞，降低并发性能）。
  - `Spin rounds per wait`：每次等待的平均自旋轮次，此处为0，进一步说明无锁竞争。


### **三、TRANSACTIONS（事务）**
- **含义**：记录事务相关的全局状态和当前活跃事务信息，反映事务处理和undo日志清理情况。
- **关键指标**：
  - `Trx id counter`：当前事务ID计数器（2442327581），反映累计处理的事务总量（数值越大说明历史事务越多）。
  - `Purge done`：已清理的事务范围（`trx's n:o < 2442327580`），说明undo日志清理正常（清理进度接近当前事务ID）。
  - `History list length`：未清理的undo日志历史链表长度（此处为2），**需重点关注**：若数值过大（如超过1000），说明undo日志清理缓慢，可能导致存储空间占用增加，甚至拖慢新事务。
  - `LIST OF TRANSACTIONS`：当前会话的事务状态，示例中所有事务均为`not started`（未启动），且`0 lock struct(s)`（无锁结构）、`0 row lock(s)`（无行锁），说明**无活跃事务或锁等待**，是健康状态（长时间未提交的事务会持有锁，导致锁阻塞）。


### **四、FILE I/O（文件I/O）**
- **含义**：监控InnoDB的I/O线程状态和文件读写性能，I/O是数据库性能的核心瓶颈之一。
- **关键指标**：
  - `I/O thread state`：所有I/O线程（读线程、写线程、插入缓冲线程等）状态均为`waiting for i/o request`，说明**无 pending 的I/O请求**，I/O线程空闲（低负载特征）。
  - `Pending aio reads/writes`：异步I/O的待处理读/写请求数（均为0），`Pending flushes`：待刷新（fsync）的日志和缓冲池页数（均为0），说明**I/O系统无积压**，性能良好。
  - `OS file reads/writes/fsyncs`：累计OS文件读（2173041）、写（114336）、fsync（49823）次数，及每秒速率（0.00 reads/s、0.46 writes/s、0.32 fsyncs/s），**需重点关注每秒读写/fsync速率**：若数值突增（如writes/s超过1000），可能说明I/O压力过大（需检查是否有大量写操作或刷脏页）。


### **五、INSERT BUFFER AND ADAPTIVE HASH INDEX（插入缓冲与自适应哈希索引）**
- **含义**：监控InnoDB的插入缓冲（加速非聚集索引插入）和自适应哈希索引（AHI，加速等值查询）的状态。
- **关键指标**：
  - `Ibuf`（插入缓冲）：`size 1`（当前大小）、`free list len 1271`（空闲列表长度）、`seg size 1273`（段大小），说明插入缓冲使用率低（空闲空间充足）。`99 merges`（合并次数）及`insert 162`（合并的插入操作），无丢弃操作，说明插入缓冲工作正常（插入缓冲故障会导致非聚集索引插入性能下降）。
  - `Adaptive Hash Index`：哈希表大小（10624987）和节点堆缓冲数，及`4.49 hash searches/s`（哈希查询速率）、`2.90 non-hash searches/s`（非哈希查询速率），说明AHI有效减少了B+树的查询开销（哈希查询比B+树遍历更快）。


### **六、LOG（日志）**
- **含义**：监控InnoDB redo日志的写入和刷新状态，关系到数据安全性（崩溃恢复能力）。
- **关键指标**：
  - 日志序列号相关：`Log sequence number`（当前日志序列号，3412430470625）、`Log flushed up to`（已刷新到磁盘的日志序列号）等数值**完全一致**，说明**所有日志已同步到磁盘**，无未刷新的内存日志（崩溃时不会丢失数据），是理想的安全状态。
  - `Log i/o's done`：累计日志I/O次数（68244），每秒0.15次，频率低，符合低负载场景。


### **七、BUFFER POOL AND MEMORY（缓冲池与内存）**
- **含义**：监控InnoDB缓冲池（核心缓存，存储数据页、索引页）的使用状态，缓冲池命中率是性能关键指标。
- **关键指标**：
  - `Buffer pool size`：总缓冲池大小（2621210页），`Free buffers`：空闲缓冲页数（420668），`Database pages`：缓存的数据库页数（2172916），说明缓冲池利用率约83%（2172916/2621210），空闲空间充足。
  - `Modified db pages`：脏页数（0），**需重点关注**：脏页是已修改但未写入磁盘的页，若数值过大（如超过缓冲池大小的20%），可能导致checkpoint时I/O压力激增。此处为0，说明无待刷脏页。
  - `Buffer pool hit rate`：缓冲池命中率（1000/1000，即100%），**核心关注指标**：命中率反映查询从内存获取数据的比例，一般需保持在95%以上（低于90%说明内存不足，需频繁读磁盘，性能下降）。此处100%，性能优异。
  - `Pages read/written`：累计读/写页数及每秒速率（0 reads/s、0.22 writes/s），读速率为0，结合100%命中率，说明查询均命中缓冲池，无需读磁盘。


### **八、INDIVIDUAL BUFFER POOL INFO（单个缓冲池实例信息）**
- **含义**：若InnoDB配置了多个缓冲池实例（`innodb_buffer_pool_instances`），此处展示每个实例的状态，用于判断负载是否均衡。
- **关键指标**：各实例的`Free buffers`、`Database pages`、`Modified db pages`、`hit rate`等应大致均衡（示例中4个实例的命中率均为100%，无脏页，负载均衡）。若某实例空闲页极少或命中率显著低，可能存在实例间负载不均。


### **九、ROW OPERATIONS（行操作）**
- **含义**：记录行级操作的统计（插入、更新、删除、读取），反映业务访问模式。
- **关键指标**：
  - `Number of rows read`：累计读取行数（4716617455），每秒52785.44次，**读操作频率极高**，但结合100%缓冲池命中率，说明高读负载由内存缓存支撑，无性能瓶颈。
  - `Number of rows updated`：每秒1.12次，更新频率低；插入、删除为0，符合读多写少的业务特征。
  - `Process ID/Main thread state`：主线程状态为`sleeping`，说明当前无活跃任务处理。


### **重点关注内容总结**
1. **锁竞争（SEMAPHORES）**：若`RW-xxx OS waits`非0且增长快，说明存在锁竞争，需排查慢事务或不合理锁使用。
2. **事务历史列表（TRANSACTIONS）**：`History list length`若持续增大（如超过1000），需检查undo日志清理是否正常（可能`innodb_purge_threads`配置不足）。
3. **I/O压力（FILE I/O）**：`Pending aio reads/writes`或`fsyncs/s`突增，需排查是否有大量写操作、全表扫描或脏页刷新。
4. **缓冲池命中率（BUFFER POOL）**：低于95%需考虑增大`innodb_buffer_pool_size`，避免频繁磁盘I/O。
5. **脏页数（Modified db pages）**：持续增长需检查`innodb_max_dirty_pages_pct`配置，或是否有写操作峰值。
6. **日志刷新（LOG）**：确保`Log flushed up to`与`Log sequence number`差距小（避免崩溃数据丢失）。


总体来看，该监控输出反映InnoDB处于**低负载、高性能、无明显瓶颈**的健康状态，读负载高但由缓冲池支撑，无锁竞争、I/O积压或事务异常。