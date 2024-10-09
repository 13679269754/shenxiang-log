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

innodb_flush_log_at_trx_commit = 0|1|2

0 - 每N秒将Redo Log Buffer的记录写入Redo Log文件，并且将文件刷入硬件存储1次。N由innodb_flush_log_at_timeout控制。

1 - 每个事务提交时，将记录从Redo Log Buffer写入Redo Log文件，并且将文件刷入硬件存储。

2 – 每个事务提交时，仅将记录从Redo Log Buffer写入Redo Log文件。Redo Log何时刷入硬件存储由操作系统和innodb_flush_log_at_timeout决定。这个选项可以保证在MySQL宕机，而操作系统正常工作时，数据的完整性。

binlog 在事务发起提交时才开始写入，并开始落盘。通过 sync_binlog 参数来控制。  binlog的写入也分为两个过程write() 与 fsync();write() 代表将binlog cache写入文件系统缓存，fsync()代表落盘。

sync_binlog :
0 binlog在提交后只进行write(),将落盘操作交给文件系统，等待文件系统落盘。
1 在事务提交时，binlog被固化直接到disk 中（落盘），write()操作跳过文件系统缓存直接落盘。
N N>1,binlog cache 中有N个事务时才开始落盘。可能丢失N-1 个事务。

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

### 相关阅读


