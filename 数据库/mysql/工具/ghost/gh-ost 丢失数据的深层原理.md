| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-7月-02 | 2025-7月-02  |
| ... | ... | ... |
---
# GH -ost 丢失数据的深层原理

[toc]

[Gh-ost改表P0级BUG：可能导致数据丢失-腾讯云开发者社区-腾讯云](https://cloud.tencent.com/developer/article/2303777) 

 | 导语Gh-ost改表工具是MySQL主流的2种开源改表工具之一，因为可限速，入侵小而在业界广泛使用，然而Gh-ost存在1个P0级的未修复BUG，可能导致数据丢失，本文对这个问题进行了分析，并给出了解决方案。

1\. MySQL 3种改表方式对比
------------------

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-7-2%2014-43-29/11194ca2-eec3-42f4-9c9c-071232279f54.jpeg?raw=true)

1\. MySQL改表结构，目前主要有3种方式：onlineDDL、pt-osc、gh-ost

2\. Online DDL问题：

1）改大表会复制延迟，业务读取不到最新数据

2   无法限速也可能导致主机负载过高，业务读写产生抖动

3\. pt-osc改表问题：

1) 不可暂停

2) 交换表名的时候会有短时间的表不存在报错

3) 要在表上建触发器，是侵入式的，可能产生未知问题

所以改表一般选择Gh-ost工具。

Gh-ost是一个由原GitHub 工程师开发的 MySQL 在线表结构更改工具，它的名字是 "GitHub's Online Schema Transmogrifier" 的缩写。这个工具是为了解决在 GitHub 上线时，对 [MySQL 数据库](https://cloud.tencent.com/product/cdb?from_column=20065&from=20065)进行表结构更改时的一些问题而开发的。

"ghost" 这个单词在英语中的意思是 "鬼魂"，这也暗示了这个工具的工作方式：它在更改表结构时，会创建一个新的 "影子" 表，然后将原表的数据复制到新表中，最后在适当的时候切换到新表，从而实现无缝的、在线的表结构更改。这种方式可以避免直接在原表上进行更改时可能产生的长时间锁表等问题。

2\. Gh-ost改表原理
--------------

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-7-2%2014-43-29/c4a0a0ab-4e4f-4580-85f3-efbd15882e63.jpeg?raw=true)

如上图所示，具体的改表原理为：

1.  在主机上创建“影子表”：\_tb\_gho
2.  更改影子表结构
3.  建立复制连接，记录binlog事件到文件
4.  在影子表上复制原始表的行数据
5.  在影子表上应用记录的binlog文件
6.  引入临时表\_tb\_del，交换影子表与原始表表名 tb -> \_tb\_del, \_tb\_gho -> tb
7.  删除\_tb\_del表

3\. 问题描述
--------

使用gh-ost给表tb加索引：

ALTER TABLE tb ADD INDEX \`idx\_1\` ();

执行完成后，对账发现tb表有一条记录缺失，解析binlog，发现该记录有写入记录，但主备机上查询均找不到这条记录!

4\. 原因分析：Gh-ost改表正常流程（原子换表模式）
-----------------------------

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-7-2%2014-43-29/e4e59034-531b-405a-85de-ca9e3e24a1e3.jpeg?raw=true)

表功能说明：

tb：原始表

\_tb\_del：临时表（空表），交换表名用

\_tb\_gho：影子表（替代tb）

原理：

session1, session3是Gh-ost线程，session2是业务进程。

在交换表名这一步，因为session1已经锁定了tb，\_tb\_del，session2写入数据和session3请求元数据锁都被阻塞。删除\_tb\_del和解锁tb后，获取元数据锁成功，此时RENAME操作优先级高于DML，所以是先执行rename，再执行业务的insert，这样的情况下数据没有问题。

下面我们看下异常流程：

5\. 原因分析：改表异常流程（原子换表模式）
-----------------------

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-7-2%2014-43-29/4a5d2a7b-5503-4e5b-ad0b-956283ffe4ed.jpeg?raw=true)

如上图所示，在删除\_tb\_del后，按顺序，应该拿到\_tb\_gho的元数据锁，然后等待获取tb的元数据锁。如果这个时候\_tb\_gho表恰好有查询，则获取\_tb\_gho的元数据锁被阻塞，此时解锁tb，业务的insert请求会先成功，此时再获得\_tb\_gho的元数据锁成功，完成交换表名操作。业务写入的4这条记录实际上在交换表名后的\_tb\_del表，最后步骤删除\_tb\_del表，这条记录也就被删除了！

至于\_tb\_gho为什么会有访问，分析业务是不可能访问这个表，因为他们不知道这个表的存在。但[数据库管理](https://cloud.tencent.com/product/dmc?from_column=20065&from=20065)系统和MySQL会不会某种情况下扫描这个表，分析是有可能的，比如库表信息采集系统。

那么针对这种情况，有什么解决方案呢？

6\. 解决方案1：修改Gh-ost改表流程为2阶段换表模式
------------------------------

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-7-2%2014-43-29/6e31e22c-86da-456a-acf5-27c7b1502e06.jpeg?raw=true)

原理： Gh-ost实际还支持另外一种换表方式2阶段换表：如上图所示，先将原始表重命名为临时表，再将影子表重命名为原始表

具体是使用cut-over参数：

```
--cut-over: 这个参数用来指定换表名的方式，可以是atomic或者two-step。atomic方式会在一个原子操作中完成换表名，而two-step方式会先将原始表重命名为一个临时的名字，然后再将"影子"表重命名为原始表的名字。
```

优点： 数据一致性强 缺点：

1.  高并发下，会有瞬间写入/查询报错：表不存在
2.  服务执行事务的时候，遇到单个语句报错需要回滚事务（[数据库](https://cloud.tencent.com/product/tencentdb-catalog?from_column=20065&from=20065)不会自动回滚）

7\. 解决方案2：加入检查机制
----------------

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-7-2%2014-43-29/b43857dc-2f84-43d5-b045-4059c5e153f5.jpeg?raw=true)

原理：

1.  加入检查机制，确认获取tb表的元数据锁处于pending状态，意味着\_tb\_del和\_tb\_gho的元数据锁已经拿到，此时再解锁tb。
2.  如果多次检查失败，整个切换流程会超时重试。

缺点：

1.  5.7要打开performance\_schema.metadata\_locks视图。
2.  需要修改源码（见  https://github.com/wangzihuacool/gh-ost/commit/ad01488a3149d91319948910abe1860b61871396）

关键代码如下：

```
 func (this *Applier) ExpectMetadataLock(sessionId int64) error {
	found := false
	query := ` select /*+ gh-ost */ m.owner_thread_id
			from performance_schema.metadata_locks m join performance_schema.threads t 
			on m.owner_thread_id=t.thread_id
			where m.object_type = 'TABLE' and m.object_schema = ? and m.object_name = ? 
			and m.lock_type = 'EXCLUSIVE' and m.lock_status = 'PENDING' 
			and t.processlist_id = ? `
	err := sqlutils.QueryRowsMap(this.db, query, func(m sqlutils.RowMap) error {
		found = true
		return nil
	}, this.migrationContext.DatabaseName, this.migrationContext.OriginalTableName, sessionId)
	if err != nil {
		return err
	}
	if !found {
		return fmt.Errorf("cannot find PENDING metadata lock on original table: `%s`.`%s`", this.migrationContext.DatabaseName, this.migrationContext.OriginalTableName)
	}
	return nil
}
```

8\. 兜底机制
--------

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-7-2%2014-43-29/813e306a-7a59-4a2b-ae15-73aa228fd6ab.jpeg?raw=true)

原理：

加入数据核对：增量核对改表前5分钟到改表完成时间段\_tb\_del表中的主键，必须在tb表中全部存在

核平后再清理\_tb\_del表

缺点：

1.  tb表必须有主键
2.  tb表必须没有delete操作
3.  因为tb表有业务写入，而\_tb\_del数据不再变化，所以对于update操作，2张表核对会不一致，也即只能核对主键一致，其它字段无法保证

