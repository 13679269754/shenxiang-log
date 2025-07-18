[社区投稿 | gh-ost 原理剖析](https://opensource.actionsky.com/20190918-mysql/) 

 **作者简介**

杨奇龙，网名“北在南方”，7年DBA老兵，目前任职于杭州有赞科技DBA，主要负责数据库架构设计和运维平台开发工作，擅长数据库性能调优、故障诊断。

**一、简介**  

 上一篇文章 [](http://mp.weixin.qq.com/s?__biz=MzU2NzgwMTg0MA==&mid=2247485621&idx=1&sn=ffd373ec9a22619c529f4b47c7d474fb&chksm=fc96ea2acbe1633ca1e6194166c155a3fa661c0341cfe86bdf1ea53e91fc03e22e408e765b75&scene=21#wechat_redirect) [（gh-ost 在线 ddl 变更工具）](https://opensource.actionsky.com/20190917-mysql/)介绍 gh-ost 参数和具体的使用方法、核心特性（可动态调整暂停）、动态修改参数等等。本文分几部分从源码方面解释 gh-ost 的执行过程、数据迁移、切换细节设计。

**二、原理**

**2.1 执行过程**

本例基于在主库上执行 DDL 记录的核心过程。核心代码在 github.com/github/gh-ost/go/logic/migrator.go 的 Migrate()

1.  `func (this *Migrator) Migrate() //Migrate executes the complete migration logic. This is the major gh-ost function.`
    

1. 检查数据库实例的基础信息

1.  `a 测试db是否可连通,`
    
2.  `b 权限验证`
    
3.   `show grants for current_user()`
    
4.  `c 获取binlog相关信息,包括row格式和修改binlog格式后的重启replicate`
    
5.   `select @@global.log_bin, @@global.binlog_format`
    
6.   `select @@global.binlog_row_image`
    
7.  `d 原表存储引擎是否是innodb,检查表相关的外键,是否有触发器,行数预估等操作，需要注意的是行数预估有两种方式  一个是通过explain 读执行计划 另外一个是select count(*) from table ,遇到几百G的大表，后者一定非常慢。`
    
8.  ``explain select /* gh-ost */ * from `test`.`b` where 1=1``
    

2\. 模拟 slave，获取当前的位点信息，创建 binlog streamer 监听 binlog

1.  `2019-09-08T22:01:20.944172+08:00    17760 Query show /* gh-ost readCurrentBinlogCoordinates */ master status`
    
2.  `2019-09-08T22:01:20.947238+08:00    17762 Connect   root@127.0.0.1 on  using TCP/IP`
    
3.  `2019-09-08T22:01:20.947349+08:00    17762 Query SHOW GLOBAL VARIABLES LIKE 'BINLOG_CHECKSUM'`
    
4.  `2019-09-08T22:01:20.947909+08:00    17762 Query SET @master_binlog_checksum='NONE'`
    
5.  `2019-09-08T22:01:20.948065+08:00    17762 Binlog Dump   Log: 'mysql-bin.000005'  Pos: 795282`
    

3\. 创建 日志记录表 `xx_ghc` 和影子表 `xx_gho` 并且执行 alter 语句将影子表变更为目标表结构。如下日志记录了该过程，gh-ost 会将核心步骤记录到 \_b\_ghc 中。

1.  ``2019-09-08T22:01:20.954866+08:00    17760 Query create /* gh-ost */ table `test`.`_b_ghc` (``
    
2.   `id bigint auto_increment,`
    
3.   `last_update timestamp not null DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,`
    
4.   `hint varchar(64) charset ascii not null,`
    
5.   `value varchar(4096) charset ascii not null,`
    
6.   `primary key(id),`
    
7.   `unique key hint_uidx(hint)`
    
8.   `) auto_increment=256`
    
9.  ``2019-09-08T22:01:20.957550+08:00    17760 Query create /* gh-ost */ table `test`.`_b_gho` like `test`.`b` ``
    
10.  ``2019-09-08T22:01:20.960110+08:00    17760 Query alter /* gh-ost */ table `test`.`_b_gho` engine=innodb``
    
11.  `2019-09-08T22:01:20.966740+08:00    17760 Query`
    
12.   ``insert /* gh-ost */ into `test`.`_b_ghc`(id, hint, value)values (NULLIF(2, 0), 'state', 'GhostTableMigrated') on duplicate key update last_update=NOW(),value=VALUES(value)``
    

4\. insert into `xx_gho` select \* from xx 拷贝数据

获取当前的最大主键和最小主键，然后根据命令行传参 chunk 获取数据 insert 到影子表里面

1.  ``获取最小主键 select `id` from `test`.`b` order by `id` asc limit 1;``
    
2.  ``获取最大主键 soelect `id` from `test`.`b` order by `id` desc limit 1;``
    
3.  `获取第一个 chunk:`
    
4.  ``select  /* gh-ost `test`.`b` iteration:0 */ `id` from `test`.`b` where ((`id` > _binary'1') or ((`id` = _binary'1'))) and ((`id` < _binary'21') or ((`id` = _binary'21'))) order by `id` asc limit 1 offset 999;``
    

6.  `循环插入到目标表:`
    
7.  ``insert /* gh-ost `test`.`b` */ ignore into `test`.`_b_gho` (`id`, `sid`, `name`, `score`, `x`) (select `id`, `sid`, `name`, `score`, `x` from `test`.`b` force index (`PRIMARY`)  where (((`id` > _binary'1') or ((`id` = _binary'1'))) and ((`id` < _binary'21') or ((`id` = _binary'21')))) lock in share mode;``
    

9.  `循环到最大的id，之后依赖binlog 增量同步`
    

需要注意的是

> rowcopy 过程中是对原表加上 **lock in share mode**，防止数据在 copy 的过程中被修改。这点对后续理解整体的数据迁移非常重要。因为 gh-ost 在 copy 的过程中不会修改这部分数据记录。对于解析 binlog 获得的 INSERT，UPDATE，DELETE 事件我们只需要分析 copy 数据之前 log before copy 和 copy 数据之后 log after copy。整体的数据迁移会在后面做详细分析。

5\. 增量应用 binlog 迁移数据

> 核心代码在 gh-ost/go/sql/builder.go 中，这里主要做 DML 转换的解释，当然还有其他函数做辅助工作，比如数据库，表名校验 以及语法完整性校验。

**解析到 delete 语句对应转换为 delete 语句**

1.  `func BuildDMLDeleteQuery(databaseName, tableName string, tableColumns, uniqueKeyColumns *ColumnList, args []interface{}) (result string, uniqueKeyArgs []interface{}, err error) {`
    
2.   `....省略代码...`
    
3.   ``result = fmt.Sprintf(` ``
    
4.   `delete /* gh-ost %s.%s */`
    
5.   `from`
    
6.   `%s.%s`
    
7.   `where`
    
8.   `%s`
    
9.   `` `, databaseName, tableName,``
    
10.   `databaseName, tableName,`
    
11.   `equalsComparison,`
    
12.   `)`
    
13.   `return result, uniqueKeyArgs, nil`
    
14.  `}`
    

**解析到 insert 语句对应转换为 replace into 语句**

1.  `func BuildDMLInsertQuery(databaseName, tableName string, tableColumns, sharedColumns, mappedSharedColumns *ColumnList, args []interface{}) (result string, sharedArgs []interface{}, err error) {`
    
2.   `....省略代码...`
    
3.   ``result = fmt.Sprintf(` ``
    
4.   `replace /* gh-ost %s.%s */ into`
    
5.   `%s.%s`
    
6.   `(%s)`
    
7.   `values`
    
8.   `(%s)`
    
9.   `` `, databaseName, tableName,``
    
10.   `databaseName, tableName,`
    
11.   `strings.Join(mappedSharedColumnNames, ", "),`
    
12.   `strings.Join(preparedValues, ", "),`
    
13.   `)`
    
14.   `return result, sharedArgs, nil`
    
15.  `}`
    

**解析到 update 语句 对应转换为语句**

1.  `func BuildDMLUpdateQuery(databaseName, tableName string, tableColumns, sharedColumns, mappedSharedColumns, uniqueKeyColumns *ColumnList, valueArgs, whereArgs []interface{}) (result string, sharedArgs, uniqueKeyArgs []interface{}, err error) {`
    
2.   `....省略代码...`
    
3.   ``result = fmt.Sprintf(` ``
    
4.   `update /* gh-ost %s.%s */`
    
5.   `%s.%s`
    
6.   `set`
    
7.   `%s`
    
8.   `where`
    
9.   `%s`
    
10.   `` `, databaseName, tableName,``
    
11.   `databaseName, tableName,`
    
12.   `setClause,`
    
13.   `equalsComparison,`
    
14.   `)`
    
15.   `return result, sharedArgs, uniqueKeyArgs, nil`
    
16.  `}`
    

**数据迁移的数据一致性分析**

gh-ost 做 DDL 变更期间对原表和影子表的操作有三种：对原表的 row copy （我们用 A 操作代替），业务对原表的 DML 操作(B)，对影子表的 apply binlog(C)。而且 binlog 是基于 DML 操作产生的，因此对影子表的 apply binlog 一定在 对原表的 DML 之后，共有如下几种顺序：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-2-11%2017-42-23/8f3f7f92-cff8-4c68-9194-e435f591506c.png?raw=true)

通过上面的几种组合操作的分析，我们可以看到数据最终是一致的。尤其是当copy 结束之后，只剩下apply binlog，情况更简单。  

6\. copy 完数据之后进行原始表和影子表 cut-over 切换

gh-ost 的切换是原子性切换，基本是通过两个会话的操作来完成。作者写了三篇文章解释 cut-over 操作的思路和切换算法。详细的思路请移步到下面的链接。

> http://code.openark.org/blog/mysql/solving-the-non-atomic-table-swap-take-iii-making-it-atomic
> 
> http://code.openark.org/blog/mysql/solving-the-facebook-osc-non-atomic-table-swap-problem

这里将第三篇文章描述核心切换逻辑摘录出来。其原理是基于 MySQL 内部机制：被 lock table 阻塞之后，执行 rename 的优先级高于 DML，也即先执行 rename table ，然后执行 DML。假设 gh-ost 操作的会话是 c10 和 c20，其他业务的 DML 请求的会话是 c1-c9，c11-c19，c21-c29。

1.  `1 会话 c1..c9: 对b表正常执行DML操作。`
    
2.  `2 会话 c10 : 创建_b_del 防止提前rename 表，导致数据丢失。`
    
3.   ``create /* gh-ost */ table `test`.`_b_del` (``
    
4.   `id int auto_increment primary key`
    
5.   `) engine=InnoDB comment='ghost-cut-over-sentry'`
    

7.  ``3 会话 c10 执行LOCK TABLES b WRITE, `_b_del` WRITE。``
    
8.  `4 会话c11-c19 新进来的dml或者select请求，但是会因为表b上有锁而等待。`
    
9.  `5 会话c20:设置锁等待时间并执行rename`
    
10.   `set session lock_wait_timeout:=1`
    
11.   ``rename /* gh-ost */ table `test`.`b` to `test`.`_b_20190908220120_del`, `test`.`_b_gho` to `test`.`b` ``
    
12.   `c20 的操作因为c10锁表而等待。`
    

14.  `6 c21-c29 对于表 b 新进来的请求因为lock table和rename table 而等待。`
    
15.  `7 会话c10 通过sql 检查会话c20 在执行rename操作并且在等待mdl锁。`
    
16.  `select id`
    
17.   `from information_schema.processlist`
    
18.   `where`
    
19.   `id != connection_id()`
    
20.   `and 17765 in (0, id)`
    
21.   `and state like concat('%', 'metadata lock', '%')`
    
22.   `and info  like concat('%', 'rename', '%')`
    

24.  ``8 c10 基于步骤7 执行drop table `_b_del` ,删除命令执行完，b表依然不能写。所有的dml请求都被阻塞。``
    

26.  `9 c10 执行UNLOCK TABLES; 此时c20的rename命令第一个被执行。而其他会话c1-c9,c11-c19,c21-c29的请求可以操作新的表b。`
    

**划重点（敲黑板）**

> 1\. 创建 `_b_del` 表是为了防止 cut-over 提前执行，导致数据丢失。
> 
> 2\. 同一个会话先执行 write lock 之后还是可以 drop 表的。
> 
> 3\. 无论 rename table 和 DML 操作谁先执行，被阻塞后 rename table 总是优先于 DML 被执行。大家可以一边自己执行 gh-ost ，一边开启 general log 查看具体的操作过程。

1.  ``2019-09-08T22:01:24.086734    17765   create /* gh-ost */ table `test`.`_b_20190908220120_del` (``
    
2.   `id int auto_increment primary key`
    
3.   `) engine=InnoDB comment='ghost-cut-over-sentry'`
    
4.  ``2019-09-08T22:01:24.091869    17760 Query lock /* gh-ost */ tables `test`.`b` write, `test`.`_b_20190908220120_del` write``
    
5.  `2019-09-08T22:01:24.188687    17765   START TRANSACTION`
    
6.  `2019-09-08T22:01:24.188817    17765   select connection_id()`
    
7.  `2019-09-08T22:01:24.188931    17765   set session lock_wait_timeout:=1`
    
8.  ``2019-09-08T22:01:24.189046    17765   rename /* gh-ost */ table `test`.`b` to `test`.`_b_20190908220120_del`, `test`.`_b_gho` to `test`.`b` ``
    
9.  `2019-09-08T22:01:24.192293+08:00    17766 Connect   root@127.0.0.1 on test using TCP/IP`
    
10.  `2019-09-08T22:01:24.192409    17766   SELECT @@max_allowed_packet`
    
11.  `2019-09-08T22:01:24.192487    17766   SET autocommit=true`
    
12.  `2019-09-08T22:01:24.192578    17766   SET NAMES utf8mb4`
    
13.  `2019-09-08T22:01:24.192693    17766   select id`
    
14.   `from information_schema.processlist`
    
15.   `where`
    
16.   `id != connection_id()`
    
17.   `and 17765 in (0, id)`
    
18.   `and state like concat('%', 'metadata lock', '%')`
    
19.   `and info  like concat('%', 'rename', '%')`
    
20.  `2019-09-08T22:01:24.193050    17766 Query select is_used_lock('gh-ost.17760.lock')`
    
21.  ``2019-09-08T22:01:24.193194    17760 Query drop /* gh-ost */ table if exists `test`.`_b_20190908220120_del` ``
    
22.  `2019-09-08T22:01:24.194858    17760 Query unlock tables`
    
23.  `2019-09-08T22:01:24.194965    17760 Query ROLLBACK`
    
24.  `2019-09-08T22:01:24.197563    17765 Query ROLLBACK`
    
25.  ``2019-09-08T22:01:24.197594    17766 Query show /* gh-ost */ table status from `test` like '_b_20190908220120_del'``
    
26.  `2019-09-08T22:01:24.198082    17766 Quit`
    
27.  ``2019-09-08T22:01:24.298382    17760 Query drop /* gh-ost */ table if exists `test`.`_b_ghc` ``
    

**如果 cut-over 过程的各个环节执行失败会发生什么？**

其实除了安全，什么都不会发生。

1.  ``如果c10的create `_b_del` 失败，gh-ost 程序退出。``
    
2.  `如果c10的加锁语句失败，gh-ost 程序退出，因为表还未被锁定，dml请求可以正常进行。`
    
3.  `如果c10在c20执行rename之前出现异常`
    
4.   `A. c10持有的锁被释放，查询c1-c9，c11-c19的请求可以立即在b执行。`
    
5.   ``B. 因为`_b_del`表存在,c20的rename table b to  `_b_del`会失败。``
    
6.   `C. 整个操作都失败了，但没有什么可怕的事情发生，有些查询被阻止了一段时间，我们需要重试。`
    
7.  `如果c10在c20执行rename被阻塞时失败退出,与上述类似，锁释放，则c20执行rename操作因为——b_old表存在而失败，所有请求恢复正常。`
    
8.  `如果c20异常失败，gh-ost会捕获不到rename，会话c10继续运行，释放lock，所有请求恢复正常。`
    
9.  `如果c10和c20都失败了，没问题：lock被清除，rename锁被清除。c1-c9，c11-c19，c21-c29可以在b上正常执行。`
    

**整个过程对应用程序的影响**

应用程序对表的写操作被阻止，直到交换影子表成功或直到操作失败。如果成功，则应用程序继续在新表上进行操作。如果切换失败，应用程序继续继续在原表上进行操作。

**对复制的影响**

slave 因为 binlog 文件中不会复制 lock 语句，只能应用 rename 语句进行原子操作，对复制无损。

7\. 处理收尾工作

最后一部分操作其实和具体参数有一定关系。最重要必不可少的是

> 关闭 binlogsyncer 连接 至于中间表，其实和参数有关 `--initially-drop-ghost-table` `--initially-drop-old-table`

**三、小结**

纵观 gh-ost 的执行过程，查看源码算法设计，尤其是 cut-over 设计思路之精妙，原子操作，任何异常都不会对业务有严重影响。欢迎已经使用过的朋友分享各自遇到的问题，也欢迎还未使用过该工具的朋友大胆尝试。
