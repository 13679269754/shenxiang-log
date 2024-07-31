[面试官问我MySQL如何保证数据不丢失，被虐的体无完肤](https://zhuanlan.zhihu.com/p/394388285)

**「MySQL如何保证数据不丢失？」**
---------------------

只要 redo log 和 binlog 保证持久化到磁盘，就能确保 MySQL 异常重启后，数据可以恢复。

**「binlog 的写入机制」**

*   事务执行过程中，先把日志写到 _binlog cache_，
*   事务提交的时候，再把 binlog cache 写到 binlog 文件中

一个事务的 binlog 是不能被拆开的，因此不论这个事务多大，也要确保一次性写入。

系统给每个线程分配一片内存供 binlog cache 使用，参数 _binlog\_cache\_size 用于控制单个线程内 binlog cache 所占内存的大小_。

如果超过了这个参数规定的大小，就要暂存到磁盘。

事务提交的时候，执行器把 binlog cache 里的_完整事务_写入到 binlog 中，并清空 binlog cache。

每个线程有自己 binlog cache，但是共用同一份 binlog 文件。

**「事务提交时binlog 就落盘吗」**

binlog写文件分write和fsync两个步骤

*   write，指的就是指把日志写入到文件系统的 page cache，并没有把数据持久化到磁盘，所以速度比较快。  
    
*   fsync，才是将数据持久化到磁盘的操作。  
    

write 和 fsync 的时机，是由参数 _sync_binlog_ 控制的：

*   sync_binlog=0 的时候，表示每次提交事务都只 write，不 fsync。
*   sync_binlog=1 的时候，表示每次提交事务都会执行 fsync。
*   sync_binlog=N(N>1) 的时候，表示每次提交事务都 write，但累积 N 个事务后才 fsync。

在出现 IO 瓶颈的场景里，将 sync_binlog 设置成一个比较大的值，可以提升性能。

在实际的业务场景中，一般不建议将这个参数设成 0，比较常见的是将其设置为 100~1000 中的某个数值。

但是，将 sync_binlog 设置为 N，对应的风险是：如果主机发生异常重启，会丢失最近 N 个事务的 binlog 日志。

**「redo log 的写入机制」**

事务在执行过程中，生成的 redo log 是要先写到 redo log buffer 的

**「redo log 的三种状态」**

*   存在 redo log buffer 中，物理上是在 MySQL 进程内存中。
*   写到磁盘 (write)，但是没有持久化（fsync)，物理上是在文件系统的 page cache 里面。
*   持久化到磁盘，对应的是 hard disk。

日志写到 redo log buffer 是很快的，wirte 到 page cache 也很快，但是持久化到磁盘的速度就慢多了。

为了控制 redo log 的写入策略，InnoDB 提供了 _innodb\_flush\_log\_at\_trx_commit_ 参数，它有三种可能取值：

*   设置为 0 的时候，表示每次事务提交时都只是把 redo log 留在 redo log buffer 中 ;
*   设置为 1 的时候，表示每次事务提交时都将 redo log 直接持久化到磁盘；
*   设置为 2 的时候，表示每次事务提交时都只是把 redo log 写到 page cache。

InnoDB 有一个后台线程，每隔 1 秒，就会把 redo log buffer 中的日志，调用 write 写到文件系统的 page cache，然后调用 fsync 持久化到磁盘。

**「redo log buffer 里面的内容，是不是每次生成后都要直接持久化到磁盘呢？」**

不需要。

如果事务执行期间 MySQL 发生异常重启，那这部分日志就丢了。

由于事务并没有提交，所以这时日志丢了也不会有损失。

**「事务还没提交的时候，redo log buffer 中的部分日志有没有可能被持久化到磁盘呢？」**

会有。

事务执行中间过程的 redo log 也是直接写在 redo log buffer 中的，这些 redo log 也会被后台线程一起持久化到磁盘。

也就是说，一个没有提交的事务的 redo log，也是可能已经持久化到磁盘的。

**「有没有其他场景也会让一个没有提交的事务的 redo log 写入到磁盘中？」**

*   redo log buffer 占用的空间即将达到 innodb\_log\_buffer_size 一半的时候，后台线程会主动写盘。_注意，由于这个事务并没有提交，所以这个写盘动作只是 write，而没有调用 fsync，也就是只留在了文件系统的 page cache_
*   并行执行的事务提交的时候，顺带将这个事务的 redo log buffer 持久化到磁盘。

**「MySQL 的“双 1”配置指什么？」**

MySQL 的“双 1”配置，指的就是 sync\_binlog 和 innodb\_flush\_log\_at\_trx\_commit 都设置成 1。

**「两阶段提交」**

redo log 先 prepare， 再写 binlog，最后再把 redo log commit。

_一个事务完整提交前，需要等待两次刷盘，一次是 redo log（prepare 阶段），一次是 binlog。_

_崩溃恢复逻辑是要依赖于 prepare 的 redo log，再加上 binlog 来恢复的。_

每秒一次后台轮询刷盘，再加上崩溃恢复的逻辑，InnoDB 就认为 redo log 在 commit 的时候就不需要 fsync 了，只会 write 到文件系统的 page cache 中就够了。

**「WAL 机制是减少磁盘写，可是每次提交事务都要写 redo log 和 binlog，这磁盘读写次数也没变少？」**

1.  redo log 和 binlog 都是顺序写，磁盘的顺序写比随机写速度要快；
2.  组提交机制，可以大幅度降低磁盘的 IOPS 消耗。

**「执行一个 update 语句以后，执行 hexdump 命令直接查看 ibd 文件内容，为什么没有看到数据有改变呢？」**

update 语句执行完成后，InnoDB 只保证写完了 redo log、内存，可能还没来得及将数据写到磁盘。

**「为什么 binlog cache 是每个线程自己维护的，而 redo log buffer 是全局共用的？」**

MySQL 这么设计的主要原因是，binlog 是不能“被打断的”。

一个事务的 binlog 必须连续写，因此要整个事务完成后，再一起写到文件里。

而 redo log 并没有这个要求，中间有生成的日志可以写到 redo log buffer 中。

redo log buffer 中的内容还能“搭便车”，其他事务提交的时候可以被一起写到磁盘中。

同时，binlog存储是以statement或者row格式存储的，而redo log是以page页格式存储的。

page格式，天生就是共有的，而row格式，只跟当前事务相关

**「事务执行期间，还没到提交阶段，如果发生 crash 的话，redo log 肯定丢了，这会不会导致主备不一致呢？」**

不会。因为这时候 binlog 也还在 binlog cache 里，没发给备库。

crash 以后 redo log 和 binlog 都没有了，从业务角度看这个事务也没有提交，所以数据是一致的。
