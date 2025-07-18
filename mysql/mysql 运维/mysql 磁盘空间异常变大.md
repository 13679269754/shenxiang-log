| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2023-12月-18 | 2023-12月-18  |
| ... | ... | ... |
---
# mysql 磁盘空间异常变大

[toc]

### 01 / 急症突发：

### 谁动了我的存储空间？

这天，晨钟刚刚敲过，数据库侍卫的急报声就响彻了寒霜城整座城池：“报，云数据库RDS MySQL监控触发报警，**数据库实例磁盘满，即将被锁定**！”

“奇怪，我们明明刚检查过实例存储空间，剩余空间较多，理论上不应该这么快被写满啊。”上一班的侍卫挠头不解道。

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-14%2010-52-29/39522423-3479-405e-ac41-50061ae87789.png?raw=true)

危急之时，寒霜城向瑶池派发出求助信号，妙手神医瑶池即刻现身，经过一番探查，发现是数据库中**「临时文件数据量**(temp\_file\_size)**」在一段时间内快速增长**，占用了较多空间，耗尽剩余存储。

“你们看，其实是刚刚在数据库实例上执行了类似这样的SQL，才导致了大量磁盘临时表空间占用。”

```sql
/* 问题SQL简化示例 */ select * from table_name_1 t1 join table_name_2 t2 where t1.id > 5000 order by t2.id desc;
```

“我们都知道，MySQL临时表可以临时存储数据，辅助复杂查询的执行，提高查询效率。

>TIPS：

>MySQL在执行包含UNION、UNION ALL + ORDER BY、ORDER BY、GROUP BY、GROUP BY x AND ORDER BY z、DISTINCT + ORDER BY、INSERT...SELECT相同的表、多表更新、GROUP\_CONCAT()、COUNT(DISTINCT)、使用SQL\_BIG\_RESULT修饰符、使用了派生表的查询时，以及执行OPTIMIZE TABLE或其他DDL时，可能会使用内部临时表。

在创建内部临时表时，MySQL首先在内存中创建Memory引擎临时表，当临时表的尺寸过大时，会自动转换为磁盘上的MyISAM引擎临时表，当查询涉及到Blob或Text类型字段，MySQL会直接使用磁盘临时表。

**若该类查询语句大量执行且没有及时处理，临时文件数据量将快速增长，有较大风险打满磁盘，导致实例锁定从而影响业务**。”

### 02 / 常见病因：

### 哪些场景会导致存储空间快速增长？

这次数据库存储空间的突发急症，让寒霜城众人不禁深感后怕，待“临时文件切除术”操作完毕后，大家连忙问道：“除了临时文件，还有哪些场景可能导致数据库存储空间被快速占用呢？”

“还有这两个常见病因。”说着，妙手神医瑶池拿出了一张「急症防范要点」——

#### 2.1 Binlog

Binlog即二进制文件，记录了数据库发生的变化，如库表增删、表中数据变化等。

Binlog主要用于主从复制和数据恢复，但在部分情况下，Binlog文件生成速度会大于清理速度，如大事务、涉及大字段的DML操作等，可能会导致上传Binlog文件到备份空间且从实例空间中删除的处理速度跟不上实例生成Binlog文件的速度，这就有可能导致实例空间满影响业务。

不过你们可以根据城中业务情况，通过“本地日志保留策略”，合理设置Binlog保留时长以及存储空间占用限制。

#### 2.2 Undo Log

另一个需要注意的是Undo Log。Undo表空间包含Undo日志，记录了如何回滚事务（增删改操作）的信息。Undo日志的不合理增长与大事务、长事务有关，比如：未提交的大事务会快速撑大undo。

在MySQL 5.7中，把innodb\_undo\_log\_truncate设置为ON，即可开启undo表空间的自动截断（Automated Truncation）。需要注意的是，当线上purge相关参数配置不合理时，如每秒产生的事务数大于purge速度，undo空间也会持续膨胀。这种情况下，可以临时调整purge相关参数加快Undo空间的回收：

1. innodb\_purge\_threads，后台执行的purge线程数量；

2. innodb\_purge\_batch\_size，控制从历史列表中批量清除undo日志的页数；

3. 将innodb\_purge\_rseg\_truncate\_frequency值调小，提高purge线程释放回滚段的频率。

MySQL 8.0新增Manual Truncation，可以使用SQL语句来管理Undo表空间。**Manual Truncation需要至少3个活跃的Undo表空间。首先将需要处理的undo表空间状态设置为inactive**：

```sql
ALTER UNDO TABLESPACE tablespace_name SET INACTIVE;
```

设置为inactive后，undo表空间被标记为截断，purge线程会增加返回频率，快速清空并截断undo表空间，该undo表空间状态变为empty（empty状态的undo表空间也可以被删除），此时可以重新激活使用该undo表空间。
```
ALTER UNDO TABLESPACE tablespace_name SET ACTIVE;
```
[mysql undo log 手动释放](<mysql undo log 手动释放.md>)

### 03 / 防微杜渐：

### 常见占用存储空间但不易被感知的场景

为了让寒霜城能够尽量避免再患“存储空间急症”，本着“未病先防”的观念，急诊术处理完毕后，妙手神医瑶池特意在城中开了一场“存储空间急症根因交流会”，和大家**揭秘了更多在数据库中占用存储空间的可能病因**。

#### 3.1 information\_schema.tables统计数据问题

“瑶池大夫，我有一个问题。”交流会前排的一名数据侍卫拿出一张急诊纪录单——

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-14%2010-52-29/196debe2-37ca-42e7-a730-45e2b227627b.png?raw=true)

“如上图中的第一行，information\_schema.tables中统计数据该表占用空间179.36GB，但单独查看每张表物理文件大小后，发现实际该表物理文件占用481.88GB存储空间，即真实大小为481.88GB，与统计数据相差约300GB。

不仅如此，其实在日常工作中，我们也发现了很多次，空间占用趋势图中‘用户数据库数据量’和从information\_schema.tables中查询到的库表数据量加和有比较大的差异，请问这是为什么？”

“该类情况最常见的原因是**information\_schema.tables中数据统计更新机制**问题。”

对于MySQL 8.0，information\_schema.tables中保存的是缓存值，缓存值过期时间由参数information\_schema\_stats\_expiry控制，该参数默认值为86400(秒)，即24小时。如果没有缓存的统计信息或者统计信息已过期，在information\_schema.tables查询表的信息时将从存储引擎重新拉取相关统计数据。

当information\_schema.tables中统计数据与物理文件大小差异较大时，如有需要，可在业务低峰时期执行ANALYZE TABLE更新统计数据。如果业务上始终需要最新的统计数据，也可以考虑将参数information\_schema\_stats\_expiry设置为0。

对于MySQL 5.7，没有参数直接控制information\_schema.tables中数据的失效时间，但如果表使用的是Innodb引擎，则底层可以通过参数innodb\_stats\_auto\_recalc控制是否自动更新表相关的统计信息，该参数值为ON的时候，表中数据有变化的行数超过10%时，则会异步触发数据变化超过阈值的表的统计数据更新，MySQL 5.7的information\_schema.tables何时再读取InnoDB更新后的数据不能直接控制。MySQL 8.0也同样有innodb\_stats\_auto\_recalc参数。

#### 3.2 DDL残留文件

##### 3.2.1 Orphan Intermediate Tables

**MySQL 5.7中**，如果在使用ALGORITHM=INPLACE的方式执行ALTER TABLE操作的中间过程中出现了异常，则相关的中间表文件（Orphan Intermediate Tables）可能不会被清理，遗留在系统中占用着存储空间。另外，如果空的通用表空间中遗留有类似的中间表文件，则会导致无法删除该通用表空间。**那要如何识别并删除异常情况遗留的中间表文件呢？**

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-14%2010-52-29/b07cdf98-9065-43cb-ba68-fb1adcade5f6.png?raw=true)

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-14%2010-52-29/28837f59-bf53-4ba2-ae7b-02cd74409c03.png?raw=true)

遗留的中间表名字以#sql-ib为前缀，如：#sql-ib6754-742530817.ibd，与之相关的frm文件以#sql-为前缀，如：#sql-19184-a6.frm。

**可以通过查询information\_schema.innodb\_sys\_tables确认是否有遗留的中间表文件**：

如果有遗留的中间表，则可以通过如下步骤进行删除：

1. 重命名frm文件，使其与ibd文件的名字相同。

2. 通过DROP TABLE命令删除遗留的中间表，但需要在表名前增加前缀#mysql50#，并用反单引号将增加了前缀后的整个字符串包起来。

##### 3.2.2 Orphan Temporary Tables

MySQL 5.7中，与Orphan Intermediate Tables类似的，还存在Orphan Temporary Tables，当使用ALGORITHM=COPY的方式执行ALTER TABLE操作时出现异常，则可能会遗留一个Orphan temporary table，预期外的占用存储空间，与Orphan Intermediate Table不同的是，该类情况遗留的表的ibd、frm文件名是一样的，都是以#sql-为前缀，如：#sql-540\_3.ibd，#sql-540\_3.frm，查看是否有Orphan temporary table和查看Orphan Intermediate Table的语句是一样的，删除时不需要更改frm文件的名字，直接执行命令即可：

#### 3.3 全文索引

“此外，我们平时会**用全文索引来加速对文本数据的查询和DML操作，但需要注意的是，它会额外占用较多存储空间**。”

瑶池神医拿出另一张记录单，上面显示：information\_schema.tables中该表表空间大小为39GB，但实际上该表相关的全文索引文件额外占用了53GB空间。

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-14%2010-52-29/ff151926-799d-4828-b567-dd55989399af.png?raw=true)

这是由于在创建全文索引时，会同时创建一组索引表，如下示例将在空的full\_text\_index\_test库中创建opening\_lines表，并在opening\_line字段上设置全文索引：

可以从information\_schema.innodb\_tables中看到除了opening\_lines表，还额外生成了11个相关的表：

在information\_schema.tables中只能看到opening\_lines表：

如果只通过information\_schema.tables查询，可能会与“用户数据库数据量”存在差异，让人疑惑部分存储空间去哪里了。

#### 3.4 碎片空间

相比于上述场景，碎片空间更容易被发现。

如下示例中，数据空间加索引空间大约445GB，但整个表空间约604GB，相当于有159GB左右的碎片空间。

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-14%2010-52-29/d53ca074-f7f8-4a36-83e9-d3c6181c08ac.png?raw=true)

**频繁的删改、事务回滚或者可能导致页分裂的插入操作等，都可能导致较大的碎片空间。** 例如，历史数据清理，相关的数据库记录只是被标记为删除，但空间不会自动回收。可在业务低峰时期通过OPTIMIZE TABLE等命令回收碎片空间。

#### 3.5 无流量表、索引以及重复和冗余索引

其实，还有一类主要是业务变化后导致的空间浪费。例如：由于业务变化部分索引不再使用、甚至部分表直接不再有流量；新增加的索引导致原有索引成为冗余索引；在某些列创建了完全重复的索引。其中，**无流量表、无流量索引主要是浪费了存储空间，冗余索引、重复索引不仅浪费存储空间，还会增加数据写入时的性能消耗**。

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-14%2010-52-29/b66e6916-a437-48dc-9956-b73e09c911d4.png?raw=true)

“对于这一问题，我派的数据库自治服务DAS推出的新版性能洞察可以帮助识别发现无流量表和索引，能够有效提升数据库的稳定性。关于上述的数据库存储空间急症诱因，在日后一定要多加注意哦～”

倏尔，一阵鹤唳响起，众人望向寒霜城外，隐约在暮色之中的琅风山方向烽烟渐起，妙手神医瑶池来不及和大家一一告别，便迅速腾云离开，向着数据纷争中心疾驰而去。

文章转载自公众号：阿里云瑶池数据库