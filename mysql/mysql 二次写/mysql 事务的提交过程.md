| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-04 | 2024-10月-04  |
| ... | ... | ... |
---
# mysql 事务的提交过程

[toc]

## 来源

[MySQL中Redo与Binlog顺序一致性问题？](http://www.ywnds.com/?p=7892)
[MySQL 中Redo与Binlog顺序一致性问题 【转】](https://www.cnblogs.com/mao3714/p/8734838.html)
[mysql 二阶段提及](https://note.youdao.com/ynoteshare/index.html?id=32b48a64c7a4a6464eb1abed6ed8c7a8&type=note&_time=1727231292743) -- 来自相州的有道云笔记，连接可能会失效，所以，我对自己想要的部分做了再记录。

## 提出疑问

1. mysql 是先写redo log 还是 binlog 呢，是先写binlog ,还是先提交？

2. 写binlog和redolog 的顺序对数据库持久性和主从复制会不会产生影响？

3. mysql 如何保证binlog 和redolog 的一致性的？


## 为什么需要两阶段提交

可以将这个问题分为两部分，为什么要将变更写入日志，写入redolog，保证了数据库的D（持久化），写入binlog,用作 replication。

提交写入日志分两阶段可以保证数据库C(一致性)。

### 两阶段提交简述 

mysql 执行事务时，即开始写入redolog ，此时写入的redo log 被标记为prepare，当事务发起提交时。事务的开始写入binlog。写完binlog 后。数据库层开始写入redo log 的commit标记。

只有当事务写入binlog完成后才视作真正的提交完成。

### 简述binlog个redolog 的落盘时间点和过程

redo log 在事务执行时就开始写入，并可以开始落盘，通过 innodb_flush_log_at_trx_commit 参数来控制落盘时机。
```
innodb_flush_log_at_trx_commit = 0|1|2

0 - 每N秒将Redo Log Buffer的记录写入Redo Log文件，并且将文件刷入硬件存储1次。N由innodb_flush_log_at_timeout控制。

1 - 每个事务提交时(此处根据应该是prepare的时候，commit时是否触发fsync根据版本的不同，)，将记录从Redo Log Buffer写入Redo Log文件，并且将文件刷入硬件存储。

2 – 每个事务提交时(此处根据应该是prepare的时候)，仅将记录从Redo Log Buffer写入Redo Log文件,不进行fsync 仅仅进行write 。Redo Log何时刷入硬件存储由操作系统和innodb_flush_log_at_timeout决定。这个选项可以保证在MySQL宕机，而操作系统正常工作时，数据的完整性。
```
binlog 在事务发起提交时才开始写入，并开始落盘。通过 sync_binlog 参数来控制。  binlog的写入也分为两个过程write() 与 fsync();write() 代表将binlog cache写入文件系统缓存，fsync()代表落盘。


对于innodb_flush_log_at_trx_commit  起作用的时机，可以通过这一段话来理解
> 为了保证数据的安全性，在早版本MySQL中，prepare和commit会分别将redo log落盘，binlog提交也需要落盘，所以一次事务提交包括三次fsync调用。**在MySQL 5.6中**，这部分代码做了优化，根据recovery逻辑，事务的提交成功与否由binlog决定，由于在引擎内部prepare好的事务可以通过binlog恢复，只要将binlog落盘了**commit阶段是不需要fsync的**，**所以一次事务提交只需要两次fsync调用**。但由于第三个fsync省略就会造成xtrabackup这类物理备份产生问题，因为物理备份需要依靠redo来恢复数据，具体可以看xtrabackup工作原理，但目前此bug已经修复。

> 另外，在MySQL 5.7中对两阶段提交实现上也做了一些优化，prepare日志只需要保证在写入binlog之前fsync到磁盘即可，所以可以在binlog组提交里flush阶段开始时将所有的prepare日志落盘。这样做的好处是可以批量fsync多个事务的prepare日志，即redo log的组提交实现。


```
sync_binlog :
0 binlog在提交后只进行write(),将落盘操作交给文件系统，等待文件系统落盘。
1 在事务提交时，binlog被固化直接到disk 中（落盘），write()操作跳过文件系统缓存直接落盘。
N N>1,binlog cache 中有N个事务时才开始落盘。可能丢失N-1 个事务。
```
## 二阶段提交的崩溃恢复 

binlog 的写入是事务提交成功与否的标志，当mysql crash recovery 时，只有记录了binlog，才会根据redo log 来进行回滚与前滚。

### crash recovery 的过程  

1. 先扫最后一个Binlog文件（进行rotate binlog文件时，确保老的binlog文件对应的事务已经提交） ,提取出xid。
2. 比较redolog 总的checkpoint后的xid，如果binlog存在就提交，反之回滚。

二阶段提交依赖内部xa机制，因此mysql的innodb_support_xa 必须设置为1，默认1。 5.7.10 后弃用。

## 当落盘参数sync_binlog 与 innodb_flush_at_trx_commit 不为双一时对主从的影响

在主从复制的情况下，
sync_binlog不为1，可能出现redo_log 已经提交并落盘，binlog也已经提交，但是没有落盘，此时crash会导致，主库丢失这个事务的xid,redolog 无法判断这个事务的状态，此时这个事务的状态是否提交的状态是未知。。
innodb_flush_at_trx_commit 不为1 ，可能出现binlog已写，但是redolog 落盘失败，mysql crash。mysql 无法前滚。主库丢失数据。

 
## redolog 和binlog 的事务顺序有没有必要保持一致

具体理解可以参考

[Peronca Xtrabackup 8.0近日踩坑总结xtrabackup 2.4和8.0区别.md](<../../mysql-组件集/xtrabackup/Peronca Xtrabackup 8.0近日踩坑总结xtrabackup 2.4和8.0区别.md>)  
[MySQL中Redo与Binlog顺序一致性问题](<../mysql 日志/MySQL中Redo与Binlog顺序一致性问题？.md>)  
[group commit.md](<../mysql 日志/group commit.md>)  

总结一下就是，xtrabackup 2.4 是不备份最后一个binlog 的，仅仅依靠redolog 来实现回滚和前滚，由于添加了FWRL锁，记录了当时的binlog gtid 和pos 所以mysql 启动时，类似crash recovery ，仅仅恢复到对应的位点，那么恢复后的库就可以从对应的位点继续往后恢复。但是会导致此时主库的T1其实已经提交（redo log 和binlog 顺序不一样导致的，redo log commit是没有落盘。）。这样会导致恢复的从库丢失一个事务。



### redolog 和binlog 的事务顺序是如何保持一致的

我们知道MySQL目前的基于binlog组提交方式解决了一致性和性能的问题。通过二阶段提交解决一致性，通过redo log和binlog的组提交解决磁盘IO的性能

具体来说：

一致性问题，通过组提交中的各个阶段的加锁（Lock_log mutex，Lock_sync mutex，Lock_commit mutex）

> tip:binlog_max_flush_queue_time默认值为0，用来控制MySQL 5.6新增的BLGC（binary log group commit），就是二进制日志组提交中Flush阶段中等待的时间，即使之前的一组事务完成提交，当前一组的事务也不马上进入Sync阶段，而是至少需要等待一段时间，这样做的好处是group commit的事务数量更多，然而这也可能会导致事务的响应时间变慢。

> 参数binlog_max_flush_queue_time在MySQL的5.7.9及之后版本不再生效，MySQL等待binlog_group_commit_sync_delay毫秒直到达到binlog_group_commit_sync_no_delay_count事务个数时，将进行一次组提交。所以，在这两个参数触发之前，当queue中注册执行commit操作的线程数越多，那么在sync stage执行fsync()的效率就越高。

### 组提交如何保证binlog 的顺序与提交顺序保持一致
> binlog_order_commits
在复制主服务器上启用此变量（这是默认设置）时，发布到存储引擎的事务提交指令将在单个线程上序列化，以便事务始终以与写入二进制日志相同的顺序提交。  

### 组提交+并行复制如何让从库提交顺序也与主库一致呢
如果要确保主服务器和多线程复制从服务器上的事务历史记录保持相同，请在复制从服务器上设置slave_preserve_commit_order=1 or replica_preserve_commit_order 。

