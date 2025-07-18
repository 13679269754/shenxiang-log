## 《实测在 after_sync 中使用 gh-ost是如何丢数据的》原理探究

**文章1**:  
[技术分享 | 实测在 after_sync 中使用 gh-ost是如何丢数据的 - 墨天轮行业大佬的分享..](https://www.modb.pro/db/162906)
-- 半同步after-sync导致最后一个事务未被ghost 感知到，但是当半同步降级以后事务任旧会被提交。但是binlog 记录是在之前，导致ghost 就没有了这一组事务。

**问**：**为什么加入了一个s锁，以及重试获取的过程就能就能解决以上gh-ost的问题**

**答**：以上文章1中导致事务丢失的原因是
在ghost读取目标表的目前数据上下界限之前(快照读)，binlog中已经落盘了一个update事务，但是由于等待从库ack，没有结束，在after_sync半同步下，等待ack的事务并没有commit；RU隔离级别以外的事务隔离级别下，gh-ost均不能读取到当前目标表中有这条数据，且由于事务在gh-ost获取binlog pos之前，也没有办法在binlog应用阶段被重放。
而在显式的添加一个s锁以后，采用当前读，发现一个目标表上有个x锁，所以ghost获取添加s锁的读会等待(失败)。


[gh-ost 丢失数据的深层原理](<GH -ost 丢失数据的深层原理.md>)
-- ghost ranem 的机制， 以及一个cut-over 来控制两种rename 方式。

**文章2**:  
[最全的select加锁分析(Mysql)](https://zhuanlan.zhihu.com/p/530275892)

**文章3**:  
[社区投稿 | gh-ost 原理剖析 - 爱可生开源社区社区投稿 | gh-ost 原理剖析](https://opensource.actionsky.com/20190918-mysql/)
