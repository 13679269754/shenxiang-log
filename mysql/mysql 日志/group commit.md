| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-09 | 2024-10月-09  |
| ... | ... | ... |
---
# group commit

[toc]

## 源文件

[MySQL Group Commit](https://cubox.pro/my/card?id=7243618756331570198&internal=1)  -- 写的很好

**一、背景**

在关系型数据库中，为了满足 ACID 中的D（持久性）属性，也就是说事务提交并且成功返回给客户端之后，必须保证该事务的所有修改都持久化了，无论是在数据库程序崩溃的情况下或者是数据库所在的服务器发生宕机或者断电的情况下，都必须保证数据不能丢失。这就要求数据库在事务提交过程中调用 fsync 或 fdatasync 系统调用将数据持久化到磁盘，现代数据库都是通过 WAL 机制保证数据持久性的，MySQL 中是通过 redo log 来保证数据安全性，事务提交时保证 redo log 刷盘就可以保证数据的安全性了，但同样也需要调用 fsync 或 fdatasync 系统调用持久化。

> NOTE
> 
> fsync 是一个昂贵的系统调用，对于机械磁盘，每秒只能完成几百次的 fsync 操作。很明显，fsync 将会限制每秒钟提交的事务数，成为关系型数据库的瓶颈。
> 
> 在 binlog 的刷盘过程中，MySQL 根据不同操作系统的特性，会尽量的去调用 fdatasync 而不是 fsync，但是对于追加式的日志写入来讲，fdatasync 并不会比 fsync 的效率高太多。

对于 MySQL 而言，这种情况变得更加糟糕。在开启 binlog 的情况下，为了保证主从之间数据的一致性，MySQL 使用了事务的两阶段提交协议。在这种情况下，为了满足数据的持久化需求，一个完整事务的提交最多会导致 3 次 fsync 操作。为了提高 MySQL 在开启 binlog 的情况下单位时间内的事务提交数，就必须减少每个事务提交过程中导致的 fsync 的调用次数。所以，从 MySQL 5.6 版本开始加入了 group commit 技术（MariaDB 5.3 版本开始引入）。

组提交（group commit）是 MySQL 处理日志的一种优化方式，主要为了解决写日志时频繁刷磁盘的问题。组提交核心思想是多个并发的需要提交的事务之间共享一个 fsync 操作来进行数据持久化，将 fsync 操作的开销平摊到多个并发的事务上去。例如，有 10 个并发的事务需要提交，我们可以通过让这 10 个事务共享一个 fsync 操作进行持久化，这相比于每个事务需要自己执行一次 fsync 来进行持久化，性能上得到了明显提升。

组提交伴随着 MySQL 的发展不断优化，从最初只支持 redo log 组提交，到 MySQL 5.6 版本又支持了binlog组提交，但是却出现了在binlog组提交下无法对redo log进行组提交的尴尬情况。当然，最终也是完美支持了 redo log 和 binlog 同时实现组提交。

**二、事务两阶段提交**

MySQL在开启binlog的情况下，因为MySQL是通过binlog进行复制的，为了保证数据在主库和从库之间的一致性，会使用事务的两阶段提交协议。同时，为了保证数据的安全性，我们还需要设置参数innodb_flush_logs_at_trx_commit=1以及参数sync_binlog=1，前者保证了事务在InnoDB存储引擎内的修改持久化到了磁盘（对于InnoDB来说是重做日志的持久化），后者保证了该事务在binlog中的修改持久化到了磁盘。下面来看一下MySQL内部的两阶段提交过程。

– 自动为每个事务分配一个唯一的ID（XID）。

– COMMIT会被分成Prepare和Commit两个阶段。

– Binlog会被当做事务协调者(Transaction Coordinator)，Binlog Event会被当做协调者日志。

想了解2PC，可以参考文档：[https://en.wikipedia.org/wiki/Two-phase_commit_protocol](https://en.wikipedia.org/wiki/Two-phase_commit_protocol)

Binlog在2PC中充当了事务的协调者（Transaction Coordinator）。由Binlog来通知InnoDB引擎来执行prepare，commit或者rollback的步骤。事务提交的整个过程如下图（[http://mysqlmusings.blogspot.com/2012/06/binary-log-group-commit-in-mysql-56.html](http://mysqlmusings.blogspot.com/2012/06/binary-log-group-commit-in-mysql-56.html)）：

[![](http://www.ywnds.com/wp-content/uploads/2016/08/2016082210501810.png)
](http://www.ywnds.com/wp-content/uploads/2016/08/2016082210501810.png)

以上的图片中可以看到，事务的提交主要分为两个主要步骤：

1. 准备阶段（Storage Engine（InnoDB） Transaction Prepare Phase）

此时SQL已经成功执行，并生成xid信息及redo和undo的内存日志。然后调用prepare方法完成第一阶段，papare方法实际上什么也没做，将事务状态设为TRX_PREPARED，并将redo log刷磁盘。

2. 提交阶段（Storage Engine（InnoDB）Commit Phase）

2.1 记录协调者日志，即Binlog日志。

如果事务涉及的所有存储引擎的prepare都执行成功，则调用TC_LOG_BINLOG::log_xid方法将SQL语句写到binlog（先调用write()将binary log内存日志数据写入文件系统缓存，然后调用fsync()将binary log文件系统缓存日志数据永久写入磁盘）。此时，事务已经铁定要提交了。否则，调用ha_rollback_trans方法回滚事务，而SQL语句实际上也不会写到binlog。

2.2 告诉引擎做commit。

最后，调用引擎的commit完成事务的提交。并且会对事务的undo log从prepare状态设置为提交状态（可清理状态），刷redo日志，将事务设为TRX_NOT_STARTED状态。

> Note
> 
> 记录 binlog 是在 InnoDB 引擎 Prepare（即 Redo Log 写入磁盘）之后，这点至关重要。

由上面的二阶段提交流程可以看出，通过两阶段提交方式保证了无论在任何情况下，事务要么同时存在于存储引擎和binlog中，要么两个里面都不存在，可以保证事务的binlog和redo log顺序一致性。一旦阶段2中持久化Binlog完成，就确保了事务的提交。此外需要注意的是，每个阶段都需要进行一次fsync操作才能保证上下两层数据的一致性。阶段1的fsync由参数innodb_flush_log_at_trx_commit=1控制，阶段2的fsync由参数sync_binlog=1控制，俗称“双1”，是保证CrashSafe的根本。

比如当崩溃发生在持久化binlog之前时，明显处于prepare状态的事务还没来得及写入到binlog中；当崩溃发生在binlog持久化之后时，处于prepare状态的事务存在于binlog中。故障恢复时，mysql_binlog作为协调者，各个存储引擎和mysql_binlog作为参与者。扫描最后一个binlog文件（进行rotate binlog文件时，确保老的binlog文件对应的事务已经提交），提取其中的xid；重做检查点以后的redo日志，读取事务的undo段信息，搜集处于prepare阶段的事务链表，将事务的xid与binlog中的xid对比，若存在，则提交，否则就回滚。

为了保证数据的安全性，在早版本MySQL中，prepare和commit会分别将redo log落盘，binlog提交也需要落盘，所以一次事务提交包括三次fsync调用。在MySQL 5.6中，这部分代码做了优化，根据recovery逻辑，事务的提交成功与否由binlog决定，由于在引擎内部prepare好的事务可以通过binlog恢复，只要将binlog落盘了commit阶段是不需要fsync的，所以一次事务提交只需要两次fsync调用。但由于第三个fsync省略就会造成xtrabackup这类物理备份产生问题，因为物理备份需要依靠redo来恢复数据，具体可以看xtrabackup工作原理，但目前此bug已经修复。

另外，在MySQL 5.7中对两阶段提交实现上也做了一些优化，prepare日志只需要保证在写入binlog之前fsync到磁盘即可，所以可以在binlog组提交里flush阶段开始时将所有的prepare日志落盘。这样做的好处是可以批量fsync多个事务的prepare日志，即redo log的组提交实现。

> MySQL内部两阶段提交需要开启innodb_support_xa，默认开启。这个参数就是支持分布式事务两段式事务提交。redo和binlog数据一致性就是靠这个两段式提交来完成的，如果关闭会造成事务数据的丢失。

**三、Redo Log Group Commit**

WAL（Write-Ahead-Logging）是实现事务持久性的一个常用技术，基本原理是在提交事务时，为了避免磁盘页面的随机写，只需要保证事务的redo log写入磁盘即可，这样可以通过redo log的顺序写代替页面的随机写，并且可以保证事务的持久性，提高了数据库系统的性能。虽然WAL使用顺序写替代了随机写，但是，每次事务提交，仍然需要有一次日志刷盘动作，受限于磁盘IO，这个操作仍然是事务并发的瓶颈。

**未开启Binary log的情况？**

若事务为非只读事务，则每次事务提交时需要进行一次fsync操作，以此确保重做日志都已经写入磁盘。当数据库发生宕机时，可以通过重做日志进行恢复。InnoDB存储引擎通过redo和undo日志可以safe crash recovery数据库，当数据库crash recovery时，通过redo日志将所有**已经在存储引擎内部提交的事务应用重做日志****恢复**，所有已经prepare但是**没有****commit****的事务**将会应用**undo log****做****rollback**。然后客户端连接时就能看到已经提交的数据存在数据库内，未提交被回滚地数据需要重新执行。

虽然固态硬盘的出现提高了磁盘的性能，然而磁盘的fsync性能是有限的，为了提高磁盘fsync的效率，当前数据库都提供了group commit的功能，即一次fsync可以刷新确保多个事务日志被写入磁盘文件，对于Innodb存储引擎来说，事务提交时会进行两个阶段的操作：

1）修改内存中事务对应的值，并且将日志写入重做日志缓冲。

2）调用fsync将确保日志都从重做日志缓冲写入到了磁盘。

步骤2相对于步骤1是一个较慢的过程，这是因为存储引擎需要与磁盘打交道。但当有事务进行这个过程时，其他事务可以进行步骤1的操作，正在提交的事务完成提交操作后，再次进行步骤2时，可以将多个事务的重做日志通过一次fsync刷新到磁盘，这样就大大地减少了磁盘的压力，从而提高了数据库的整体性能。对于写入或更新较为频繁的操作，group commit的效果尤为明显。

**redo log组提交**

组提交思想是，将多个事务redo log的刷盘动作合并，减少磁盘顺序写。Innodb的日志系统里面，每条redo log都有一个LSN（Log Sequence Number），LSN是单调递增的。每个事务执行更新操作都会包含一条或多条redo log，各个事务将日志拷贝到log_sys_buffer时（log_sys_buffer通过log_mutex保护），都会获取当前最大的LSN，因此可以保证不同事务的LSN不会重复。那么假设三个事务Trx1，Trx2和Trx3的日志的最大LSN分别为LSN1，LSN2，LSN3（LSN1<LSN2<LSN3），它们同时进行提交，那么如果Trx3日志先获取到log_mutex进行落盘，它就可以顺便把[LSN1—LSN3]这段日志也刷了，这样Trx1和Trx2就不用再次请求磁盘IO。组提交的基本流程如下：

1）获取log_mutex；

2）若flushed_to_disk_lsn>=lsn，表示日志已经被刷盘，跳转到5；

3）若current_flush_lsn>=lsn，表示日志正在刷盘中，跳转5后进入等待状态；

4）将小于LSN的日志刷盘(flush and sync)；

5）退出log_mutex；

备注：lsn表示事务的lsn，flushed_to_disk_lsn和current_flush_lsn分别表示已刷盘的LSN和正在刷盘的LSN。

**redo log组提交优化**

我们知道，在开启binlog的情况下，prepare阶段，会对redo log进行一次刷盘操作（innodb_flush_log_at_trx_commit=1），确保对data页和undo页的更新已经刷新到磁盘；commit阶段，会进行刷binlog操作（sync_binlog=1），并且会对事务的undo log从prepare状态设置为提交状态（可清理状态）。通过两阶段提交方式（innodb_support_xa=1），可以保证事务的binlog和redo log顺序一致。二阶段提交过程中，mysql_binlog作为协调者，各个存储引擎和mysql_binlog作为参与者。故障恢复时，扫描最后一个binlog文件（进行rotate binlog文件时，确保老的binlog文件对应的事务已经提交），提取其中的xid；重做检查点以后的redo日志，读取事务的undo段信息，搜集处于prepare阶段的事务链表，将事务的xid与binlog中的xid对比，若存在，则提交，否则就回滚。

通过上述的描述可知，每个事务提交时，都会触发一次redo flush动作，由于磁盘读写比较慢，因此很影响系统的吞吐量。淘宝童鞋做了一个优化，将prepare阶段的刷redo动作移到了commit（flush-sync-commit）的flush阶段之前，保证刷binlog之前，一定会刷redo。这样就不会违背原有的故障恢复逻辑。移到commit阶段的好处是，可以不用每个事务都刷盘，而是leader线程帮助刷一批redo，这也是redo组提交的实现。如何实现，很简单，因为log_sys->lsn始终保持了当前最大的lsn，只要我们刷redo刷到当前的log_sys->lsn，就一定能保证，将要刷binlog的事务redo日志一定已经落盘。通过延迟刷新redo的方式，实现了redo log组提交的目的，而且减少了log_sys->mutex的竞争。目前这种策略已经被官方MySQL 5.7.6引入。

**开启Binary log的情况下？**

在单机情况下，redo log组提交很好地解决了日志落盘问题，那么开启binlog后，binlog能否和redo log一样也开启组提交？首先开启binlog后，我们要解决的一个问题是，如何保证binlog和redo log的顺序一致性？这个顺序一致要求来源于xtrabackup和ibbackup这类物理备份工具的实现，他们依赖这个假设来保证主备数据的一致。另外binlog是Master-Slave的桥梁，如果不一致，意味着Master-Slave可能不一致。MySQL通过两阶段提交很好地解决了这一问题。Prepare阶段，InnoDB刷redo log，并将回滚段设置为Prepared状态，binlog不作任何操作；commit阶段，innodb释放锁，释放回滚段，设置提交状态，binlog刷binlog日志。出现异常，需要故障恢复时，若发现事务处于Prepare阶段，并且binlog存在则提交，否则回滚。通过两阶段提交，保证了redo log和binlog在任何情况下的一致性。

开启binlog后，如何在保证redo log-binlog一致的基础上，实现组提交。为了解决这个问题，在早期的MySQL 5.6版本之前，在开启了二进制日志后，为了保证这MySQL数据库上层二进制日志的写入顺序和InnoDB层事务提交顺序一致性，MySQL数据库内部在prepare redo阶段是通过一个prepare_commit_mutex锁来实现的，一次只能有一个事务可获取该mutex。通过这个臭名昭著prepare_commit_mutex锁，将redo log和binlog刷盘串行化，串行化的目的也仅仅是为了保证redo log和Binlog一致，但会导致InnoDB存储引擎的group commit功能会失效，从而导致性能的下降。并且线上环境多使用复制环境，因此二进制日志的选项基本都是开着的，因此这个问题尤为显著。

这个问题早在2010年的MySQL数据库大会中提出，Facebook MySQL技术组，Percona公司都提出过解决方案，最后由MariaDB数据库的开发人员Kristian Nielsen完成了最终的”完美”解决方案。在这种情况下，不但MySQL数据库上层二进制日志写入是group commit的，InnoDB存储引擎层也是group commit的。此外还移除了原先的锁prepare_commit_mutex，从而大大提高了数据库的整体性。MySQL 5.6采用了类似的实现方式，并将其称为BLGC（Binary Log Group Commit），把事务提交过程分成三个阶段，分别是：Flush stage、Sync stage、Commit stage。

**四、Binary Log Group Commit**

MySQL 5.6 BLGC技术出现后，在这种情况下，不但MySQL数据库上层二进制日志写入是group commit的，InnoDB存储引擎层也是group commit的。此外还移除了原先的锁prepare_commit_mutex，从而大大提高了数据库的整体性。binlog组提交的基本思想是，引入队列机制保证innodb commit顺序与binlog落盘顺序一致，并将事务分组，组内的binlog刷盘动作交给一个事务进行，实现组提交目的。其事务的提交（commit）过程分成三个阶段：Flush stage、Sync stage、Commit stage。这些阶段完全是二进制日志内部提交过程，不会影响其他任何内容。每个阶段都有一个队列，每个队列有一个mutex保护，约定进入队列第一个线程为leader，其他线程为follower，所有事情交由leader去做，leader做完所有动作后，通知follower我已经刷盘结束，然后follower去做自己剩下的事情。

binlog组提交基本流程如下：

![](http://www.ywnds.com/wp-content/uploads/2017/01/201701170728489.png)

*   **Flush Stage**

将每个事务的二进制日志写入内存中。

1) 持有Lock_log mutex [leader持有，follower等待]。

2) 获取队列中的一组binlog（队列中的所有事务）。

3) 将binlog buffer到I/O cache。

4) 通知dump线程dump binlog。

*   **Sync Stage**

将内存中的二进制日志刷新到磁盘，若队列中有多个事务，那么仅一次fsync操作就完成了二进制日志的写入，这就是BLGC。

1) 释放Lock_log mutex，持有Lock_sync mutex[leader持有，follower等待]。

2) 将一组binlog落盘(sync动作，最耗时，假设sync_binlog为1)。

*   **Commit Stage**

leader根据顺序调用存储引擎层事务的提交，Innodb本身就支持group commit，因此修复了原先由于锁prepare_commit_mutex导致group commit失效的问题。

1) 释放Lock_sync mutex，持有Lock_commit mutex[leader持有，follower等待]。

2) 遍历队列中的事务，逐一进行innodb commit。

3) 释放Lock_commit mutex。

4) 唤醒队列中等待的线程。

由于每个阶段有一个队列，每个队列各自有mutex保护，队列之间是顺序的，约定进入队列的一个线程为leader，因此FLUSH阶段的leader可能是SYNC阶段的follower，但是follower永远是follower。也就是，第一个进入队列的事务（即队列为空时）会作为当前阶段的leader，其他的作为follower，leader确认自己身份后把当前队列中的followers摘出来，并代表他们和自己做当前阶段需要做的工作，再进入到下一个阶段的队列中，如果下一个队列为空，它会继续作为leader，如果不为空，则它和它的followers会变为新阶段的follower，一旦成为follower，就只需要等待别的线程通知事务提交完成，否则做当前阶段工作。顺序的一致通过队列顺序得到保证。

通过上文分析，我们知道MySQL目前的基于binlog组提交方式解决了一致性和性能的问题。通过二阶段提交解决一致性，通过redo log和binlog的组提交解决磁盘IO的性能。当有一组事务在进行commit阶段时，其他新事务可以进行Flush阶段，从而使group commit不断生效。当然group commit的效果由队列中事务的数量决定，若每次队列中仅有一个事务，那么可能效果和之前差不多，甚至会更差。但当提交的事务越多时，group commit的效果越明显，数据库性能的提升也就越大。

MySQL提供了一个参数binlog_max_flush_queue_time（MySQL 5.7.9版本失效），默认值为0，用来控制MySQL 5.6新增的BLGC（binary log group commit），就是二进制日志组提交中Flush阶段中等待的时间，即使之前的一组事务完成提交，当前一组的事务也不马上进入Sync阶段，而是至少需要等待一段时间，这样做的好处是group commit的事务数量更多，然而这也可能会导致事务的响应时间变慢。该参数默认为0表示不等待，且推荐设置依然为0。除非用户的MySQL数据库系统中有大量的连接（如100个连接），并且不断地在进行事务的写入或更新操作。

MySQL 5.7 Parallel replication实现主备多线程复制基于主库BLGC（Binary Log Group Commit）机制，并在Binary log日志中标识同一组事务的last_commited=N和该组事务内所有的事务提交顺序。为了增加一组事务内的事务数量提高备库组提交时的并发量引入了binlog_group_commit_sync_delay=N和binlog_group_commit_sync_no_delay_count=N

> Note
> 
> 参数binlog_max_flush_queue_time在MySQL的5.7.9及之后版本不再生效，MySQL等待binlog_group_commit_sync_delay毫秒直到达到binlog_group_commit_sync_no_delay_count事务个数时，将进行一次组提交。所以，在这两个参数触发之前，当queue中注册执行commit操作的线程数越多，那么在sync stage执行fsync()的效率就越高。

下面是提供测试组提交的一张图，可以看到组提交的TPS高不少。

[![](http://www.ywnds.com/wp-content/uploads/2017/01/2017011707295724.png)
](http://www.ywnds.com/wp-content/uploads/2017/01/2017011707295724.png)

binlog_order_commits

在复制主服务器上启用此变量（这是默认设置）时，发布到存储引擎的事务提交指令将在单个线程上序列化，以便事务始终以与写入二进制日志相同的顺序提交。禁用此变量允许使用多个线程发出事务提交指令。与二进制日志组提交结合使用，可以防止单个事务的提交率成为吞吐量的瓶颈，因此可能会产生性能提升。

当涉及的所有存储引擎都已确认事务已准备好提交时，事务将写入二进制日志。然后，二进制日志组提交逻辑在其二进制日志写入发生后提交一组事务。禁用binlog_order_commits时，由于多个线程用于此进程，因此提交组中的事务可能会以与二进制日志中的顺序不同的顺序提交。 （来自单个客户端的事务总是按时间顺序提交。）在许多情况下，这无关紧要，因为在单独的事务中执行的操作应该产生一致的结果，如果不是这种情况，则应该使用单个事务。

如果要确保主服务器和多线程复制从服务器上的事务历史记录保持相同，请在复制从服务器上设置slave_preserve_commit_order=1。

源码

binlog 的组提交是通过 Stage_manager 管理，其中比较核心内容如下。

```

class  Stage_manager  {
public:
enum  StageID  { //  binlog的组提交包括了三个阶段
FLUSH_STAGE,
SYNC_STAGE,
COMMIT_STAGE,
STAGE_COUNTER
};

private:
Mutex_queue m_queue[STAGE_COUNTER];
};

```

组提交 (Group Commit) 三阶段流程，详细实现如下。

```
MYSQL_BIN_LOG::ordered_commit() ←  执行事务顺序提交，binlog group commit的主流程
|
|-#########>>>>>>>>>                     ← 进入Stage_manager::FLUSH_STAGE阶段
|-change_stage(...,  &LOCK_log)
|  |-stage_manager.enroll_for() ←  将当前线程加入到m_queue[FLUSH_STAGE]中
|  |
|  |←  (follower)返回true
|  |-mysql_mutex_lock() ←  (leader)对LOCK_log加锁，并返回false
|
|-finish_commit()←  (follower)对于follower则直接返回
|  |-ha_commit_low()
|
|-process_flush_stage_queue()←  (leader)对于follower则直接返回
|  |-fetch_queue_for()←  通过stage_manager获取队列中的成员
|  |  |-fetch_and_empty()←  获取元素并清空队列
|  |-ha_flush_log()
|  |-flush_thread_caches()←  对于每个线程做该操作
|  |-my_b_tell()←  判断是否超过了max_bin_log_size，如果是则切换binlog文件
|
|-flush_cache_to_file()←  (follower)将I/O  Cache中的内容写到文件中
|-RUN_HOOK() ←  调用HOOK函数，也就是binlog_storage->after_flush()
|
|-#########>>>>>>>>>                     ← 进入Stage_manager::SYNC_STAGE阶段
|-change_stage()
|-sync_binlog_file()
|  |-mysql_file_sync()
| |-my_sync()
| |-fdatasync()←  调用系统API写入磁盘，也可以是fsync()
|
|-#########>>>>>>>>>                     ← 进入Stage_manager::COMMIT_STAGE阶段
|-change_stage() ←  该阶段会受到binlog_order_commits参数限制
|-process_commit_stage_queue() ←  会遍厉所有线程，然后调用如下存储引擎接口
|  |-ha_commit_low()
| |-ht->commit() ←  调用存储引擎handlerton->commit()
| |←  ### 注意，实际调用如下的两个函数
| |-binlog_commit()
| |-innobase_commit()
|-process_after_commit_stage_queue() ←  提交之后的后续处理，例如semisync
|  |-RUN_HOOK() ←  调用transaction->after_commit
|
|-stage_manager.signal_done()←  通知其它线程事务已经提交
|
|-finish_commit()

```



在 enroll_for() 函数中，刚添加的线程如果是队列的第一个线程，就将其设置为 leader 线程；否则就是 follower 线程，此时线程会睡眠，直到被 leader 唤醒 (m_cond_done) 。

如上所述，commit 阶段会受到参数 binlog_order_commits 的影响，当该参数关闭时，会直接释放 LOCK_sync ，各个 session 自行进入 InnoDB commit 阶段，这样不会保证 binlog 和事务 commit 的顺序一致。

当然，如果你不关注两者的一致性，那么可以关闭这个选项来稍微提高点性能；当打开了上述的参数，才会进入 commit stage。