| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-09 | 2024-10月-09  |
| ... | ... | ... |
---
# MySQL中Redo与Binlog顺序一致性问题？

[toc]

## 源文档

[MySQL中Redo与Binlog顺序一致性问题？](https://cubox.pro/my/card?id=7242901016121708462&internal=1)  

首先，我们知道在MySQL中，二进制日志是server层的，主要用来做主从复制和即时点恢复时使用的。而事务日志（redo log）是InnoDB存储引擎层的，用来保证事务安全的。现在我们来讨论一下MySQL主从复制过程中的一些细节问题，有关于主从复制可以看具体的章节。

在了解了以上基础的内容后，我们可以带着以下的几个问题去学习复制到底是怎样工作的。

*   为什么MySQL有binlog，还有redo log？
*   事务是如何提交的？事务提交先写binlog还是redo log？如何保证这两部分的日志做到顺序一致性？
*   为了保障主从复制安全，故障恢复是如何做的？
*   为什么需要保证二进制日志的写入顺序和InnoDB层事务提交顺序一致性呢？

## 为什么MySQL有binlog，还有redo log?

这个是因为MySQL体系结构的原因，MySQL是多存储引擎的，不管使用那种存储引擎，都会有binlog，而不一定有redo log，简单的说，binlog是MySQL Server层的，redo log是InnoDB层的。

## 事务是如何提交的？事务提交先写binlog还是redo log？如何保证这两部分的日志做到顺序一致性？

MySQL Binary log在MySQL 5.1版本后推出主要用于主备复制的搭建，我们回顾下MySQL在开启/关闭Binary Log功能时是如何工作的。

## MySQL没有开启Binary log的情况下？

首先看一下什么是CrashSafe？CrashSafe指MySQL服务器宕机重启后，能够保证：

– 所有已经提交的事务的数据仍然存在。

– 所有没有提交的事务的数据自动回滚。

Innodb通过Redo Log和Undo Log可以保证以上两点。为了保证严格的CrashSafe，必须要在每个事务提交的时候，将Redo Log写入硬件存储。这样做会牺牲一些性能，但是可靠性最好。为了平衡两者，InnoDB提供了一个innodb_flush_log_at_trx_commit系统变量，用户可以根据应用的需求自行调整。

通过redo日志将所有已经在存储引擎内部提交的事务应用redo log恢复，所有已经prepare但是没有commit的事务将会应用undo log做rollback。然后客户端连接时就能看到已经提交的数据存在数据库内，未提交的事务被回滚。

## MySQL开启Binary log的情况下？

MySQL为了保证master和slave的数据一致性，就必须保证binlog和InnoDB redo日志的一致性（因为备库通过二进制日志重放主库提交的事务，而主库binlog写入在commit之前，如果写完binlog主库crash，再次启动时会回滚事务。但此时从库已经执行，则会造成主备数据不一致）。所以在开启Binlog后，如何保证binlog和InnoDB redo日志的一致性呢？为此，MySQL引入二阶段提交（two phase commit or 2pc），MySQL内部会自动将普通事务当做一个XA事务（内部分布式事务）来处理：

– 自动为每个事务分配一个唯一的ID（XID）。

– COMMIT会被自动的分成Prepare和Commit两个阶段。

– Binlog会被当做事务协调者（Transaction Coordinator），Binlog Event会被当做协调者日志。

想了解2PC，可以参考文档：[https://en.wikipedia.org/wiki/Two-phase_commit_protocol](https://en.wikipedia.org/wiki/Two-phase_commit_protocol)

Binlog在2PC中充当了事务的协调者（Transaction Coordinator）。由Binlog来通知InnoDB引擎来执行prepare，commit或者rollback的步骤。事务提交的整个过程如下：

[![](http://www.ywnds.com/wp-content/uploads/2016/08/2016082210501810.png)
](http://www.ywnds.com/wp-content/uploads/2016/08/2016082210501810.png)

分解此图，当事务提交时（执行commit语句），分别对应以下几个阶段：

### 1. 协调者准备阶段（Prepare Phase）

此时SQL已经成功执行了，已经产生了语句的redo和undo内存日志，已经进入了事务commit步骤。然后告诉引擎做Prepare完成第一阶段，Prepare阶段就是写Prepare Log（Prepare Log也是Redo Log），将事务状态设为TRX_PREPARED，写Prepare XID（事务ID号）到Redo Log。写XID到Redo Log的时候会一并把Redo Log刷新到磁盘，这个时候Redo Log的日志量大小取决于执行SQL语句时产生的Redo是否被刷盘，这个刷盘是随机的，后台Master线程每秒钟都会刷新一次。

### 2. 协调者提交阶段（Commit Phase）

#### 2.1 记录协调者日志，即Binlog日志

如果事务涉及的所有存储引擎的Prepare都执行成功，则调用TC_LOG_BINLOG::log_xid方法将SQL语句写到Binlog（write()将binary log内存日志数据写入文件系统缓存，fsync()将binary log文件系统缓存日志数据永久写入磁盘），同时也会把XID写入到Binlog。此时，事务已经铁定要提交了。否则，调用ha_rollback_trans方法回滚事务，而SQL语句实际上也不会写到binlog。

#### 2.2 告诉引擎做Commit

最后，调用引擎的Commit完成事务的提交。并且会对事务的undo log从prepare状态设置为提交状态（可清理状态），刷新Commit Log到Redo Log，释放锁，释放mvcc相关的read view等等；将事务设为TRX_NOT_STARTED状态。

> PS：记录Binlog是在InnoDB引擎Prepare（即Redo Log写入磁盘）之后，这点至关重要。另外需要注意的一点就是，SQL语句产生的Redo日志会一直刷新到磁盘（master thread每秒fsync redo log），而Binlog是事务commit时才刷新到磁盘，如果binlog太大则commit时会慢。

由上面的二阶段提交流程可以看出，通过两阶段提交方式保证了无论在任何情况下，事务要么同时存在于存储引擎和binlog中，要么两个里面都不存在，可以保证事务的binlog和redo log顺序一致性。一旦阶段2中持久化Binlog完成，就确保了事务的提交。此外需要注意的是，每个阶段都需要进行一次fsync操作才能保证上下两层数据的一致性。阶段1的fsync由参数innodb_flush_log_at_trx_commit=1控制，阶段2的fsync由参数sync_binlog=1控制，俗称“双1”，是保证CrashSafe的根本。

参数说明如下：
```
innodb_flush_log_at_trx_commit（redo）

0 – 每N秒将Redo Log Buffer的记录写入Redo Log文件，并且将文件刷入硬件存储1次。N由innodb_flush_log_at_timeout控制。

1 – 每个事务提交时，将记录从Redo Log Buffer写入Redo Log文件，并且将文件刷入硬件存储。

2 – 每个事务提交时，仅将记录从Redo Log Buffer写入Redo Log文件。Redo Log何时刷入硬件存储由操作系统和innodb_flush_log_at_timeout决定。这个选项可以保证在MySQL宕机，而操作系统正常工作时，数据的完整性。
```

```
sync_binlog （binlog）

0：二进制日志从不进行二进制日志FSYNC（同步）到磁盘上，而是依赖操作系统刷盘机制来刷新二进制日志到磁盘。如果存在主从复制，那么主库dump线程会在flush阶段后进行binlog传输到从库。

1：当sync_binlog=1时，在没有组提交特性之前，每个事务在commit时都必须要FSYNC二进制日志到磁盘；有了组提交特性后，就成了每次组提交时进行FSYNC刷盘。如果存在主从复制，主库dump线程会在sync阶段后进行binlog传输。

N：binlog将在指定次数组提交后进行FSYNC刷盘。如果存在主从复制，主库dump线程会在flush阶段后进行binlog传输。
```

比如，当崩溃发生在持久化binlog之前时，明显处于prepare状态的事务还没来得及写入到binlog中；当崩溃发生在binlog持久化之后时，处于prepare状态的事务存在于binlog中。故障恢复时，mysql_binlog作为协调者，各个存储引擎和mysql_binlog作为参与者。扫描最后一个binlog文件（进行rotate binlog文件时，确保老的binlog文件对应的事务已经提交），提取其中的xid；重做检查点以后的redo日志，读取事务的undo段信息，搜集处于prepare阶段的事务链表，将事务的xid与binlog中的xid对比，若存在，则提交，否则就回滚。

为了保证数据的安全性，在早版本MySQL中，prepare和commit会分别将redo log落盘，binlog提交也需要落盘，所以一次事务提交包括三次fsync调用。在MySQL 5.6中，这部分代码做了优化，根据recovery逻辑，事务的提交成功与否由binlog决定，由于在引擎内部prepare好的事务可以通过binlog恢复，只要将binlog落盘了commit阶段是不需要fsync的，所以一次事务提交只需要两次fsync调用。但由于第三个fsync省略就会造成xtrabackup这类物理备份产生问题，因为物理备份需要依靠redo来恢复数据，具体可以看xtrabackup工作原理，但目前此bug已经修复。

另外，MySQL内部两阶段提交需要开启innodb_support_xa=true，默认开启。这个参数就是支持分布式事务两段式事务提交。redo和binlog数据一致性就是靠这个两段式提交来完成的，如果关闭会造成事务数据的丢失。

## 为了保障主从复制安全，故障恢复是如何做的？

开启Binary log的MySQL在crash recovery时：MySQL在prepare阶段会生成xid，然后会在commit阶段写入到binlog中。在进行恢复时事务要提交还是回滚，是由Binlog来决定的。

– 事务的Xid_log_event存在，就要提交。

– 事务的Xid_log_event不存在，就要回滚。

恢复的过程非常简单：

– 扫描最后一个Binlog文件（进行rotate binlog文件时，确保老的binlog文件对应的事务已经提交），提取其中的Xid_log_event

– 重做检查点以后的redo日志，读取事务的undo段信息，搜集处于prepare阶段的事务链表，将事务的xid与binlog中的xid对比，若存在，则提交，否则就回滚

总结一下，基本顶多会出现下面是几种情况：

*   当事务在prepare阶段crash，数据库recovery的时候该事务未写入Binary log并且存储引擎未提交，将该事务rollback。
*   当事务在binlog阶段crash，此时日志还没有成功写入到磁盘中，启动时会rollback此事务。
*   当事务在binlog日志已经fsync()到磁盘后crash，但是InnoDB没有来得及commit，此时MySQL数据库recovery的时候将会读出二进制日志的Xid_log_event，然后告诉InnoDB提交这些XID的事务，InnoDB提交完这些事务后会回滚其它的事务，使存储引擎和二进制日志始终保持一致。

总结起来说就是如果一个事务在prepare阶段中落盘成功，并在MySQL Server层中的binlog也写入成功，那这个事务必定commit成功。

## 为什么需要保证二进制日志的写入顺序和InnoDB层事务提交顺序一致性呢？

上面提到单个事务的二阶段提交过程，能够保证存储引擎和binary log日志保持一致，但是在并发的情况下怎么保证InnoDB层事务日志和MySQL数据库二进制日志的提交的顺序一致？当多个事务并发提交的情况，如果Binary Log和存储引擎顺序不一致会造成什么影响？

这是因为备份及恢复需要，例如通过xtrabackup或ibbackup这种物理备份工具进行备份时，并使用备份来建立复制，如下图：

[![](http://www.ywnds.com/wp-content/uploads/2016/08/201608221053511.png)
](http://www.ywnds.com/wp-content/uploads/2016/08/201608221053511.png)

如上图，事务按照**T1**、**T2**、**T3**顺序开始执行，将二进制日志（按照T1、T2、T3顺序）写入日志文件系统缓冲，调用fsync()进行一次group commit将日志文件永久写入磁盘，但是**存储引擎**提交的顺序为T2、T3、**T1**。 当T2、T3提交事务之后，若通过在线物理备份进行数据库恢复来建立复制时，因为在InnoDB存储引擎层会检测事务T3在上下两层都完成了事务提交(这里表达有些不知所谓，xtrabackup 的 恢复过程与mysql crash recovery 类似，会将最后一个binlog 文件的xid 与 redo log 中的xid 进行对比)，不需要在进行恢复了，此时主备数据不一致（搭建Slave时，change master to的日志偏移量记录T3在事务位置之后）。

对于上述描述我觉得这个段话是比较好理解写
>为了保证数据的安全性，在早版本MySQL中，prepare和commit会分别将redo log落盘，binlog提交也需要落盘，所以一次事务提交包括三次fsync调用。在MySQL 5.6中，这部分代码做了优化，根据recovery逻辑，事务的提交成功与否由binlog决定，由于在引擎内部prepare好的事务可以通过binlog恢复，只要将binlog落盘了commit阶段是不需要fsync的，所以一次事务提交只需要两次fsync调用。但由于第三个fsync省略就会造成xtrabackup这类物理备份产生问题，因为物理备份需要依靠redo来恢复数据，具体可以看xtrabackup工作原理，但目前此bug已经修复。

对于xtrabackup 是如何修复这个问题的可以参看[xtrabackup 2.4和8.0区别](<../../mysql-组件集/xtrabackup/Peronca Xtrabackup 8.0近日踩坑总结xtrabackup 2.4和8.0区别.md>)

为了解决以上问题，在早期的MySQL 5.6版本之前，通过prepare_commit_mutex锁以串行的方式来保证MySQL数据库上层二进制日志和Innodb存储引擎层的事务提交顺序一致，然后会导致组提交（group commit）特性无法生效。为了满足数据的持久化需求，一个完整事务的提交最多会导致3次fsync操作。为了提高MySQL在开启binlog的情况下单位时间内的事务提交数，就必须减少每个事务提交过程中导致的fsync的调用次数。所以，MySQL从5.6版本开始加入了binlog group commit技术（MariaDB 5.3版本开始引入）。

MySQL数据库内部在prepare redo阶段获取prepare_commit_mutex锁，一次只能有一个事务可获取该mutex。通过这个臭名昭著prepare_commit_mutex锁，将redo log和binlog刷盘串行化，串行化的目的也仅仅是为了保证redo log和Binlog一致，继而无法实现group commit，牺牲了性能。整个过程如下图：

[![](http://www.ywnds.com/wp-content/uploads/2016/08/2016082210562699.png)
](http://www.ywnds.com/wp-content/uploads/2016/08/2016082210562699.png)

上图可以看出在prepare_commit_mutex，只有当上一个事务commit后释放锁，下一个事务才可以进行prepare操作，并且在每个事务过程中Binary log没有fsync()的调用。由于内存数据写入磁盘的开销很大，如果频繁fsync()把日志数据永久写入磁盘数据库的性能将会急剧下降。此时MySQL数据库提供sync_binlog参数来设置多少个binlog日志产生的时候调用一次fsync()把二进制日志刷入磁盘来提高整体性能。

上图所示MySQL开启Binary log时使用prepare_commit_mutex和sync_log保证二进制日志和存储引擎顺序保持一致，prepare_commit_mutex的锁机制造成高并发提交事务的时候性能非常差而且二进制日志也无法group commit。

这个问题早在2010年的MySQL数据库大会中提出，Facebook MySQL技术组，Percona公司都提出过解决方案，最后由MariaDB数据库的开发人员Kristian Nielsen完成了最终的”完美”解决方案。在这种情况下，不但MySQL数据库上层二进制日志写入是group commit的，InnoDB存储引擎层也是group commit的。此外还移除了原先的锁prepare_commit_mutex，从而大大提高了数据库的整体性。MySQL 5.6采用了类似的实现方式，并将其称为BLGC（Binary Log Group Commit），并把事务提交过程分成三个阶段，Flush stage、Sync stage、Commit stage。具体看：[MySQL Group Commit](http://www.ywnds.com/?p=5798)。
