| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-14 | 2024-10月-14  |
| ... | ... | ... |
---
# mysql mvcc 小计

[toc]

## 知识点小计

**mvcc 何时起作用**  
mvcc 与快照读当前读,事务隔离级别(快照读)有分不开的联系，可以综合考虑
[快照读与加锁读 - MySQL 8.0官方文档笔记（三）](https://www.cnblogs.com/notayeser/p/14086211.html)  

**何时当前读**  
1. se(序列化隔离级别)，或者ru事务隔离级别
2. DML：不读取readview,使用当前读和锁机制控制事务隔离

一个需要记住的例子
>数据库快照机制会应用在事务中的SELECT语句，但不会应用于DML语句。如果你插入或修改了某些行然后提交，同时另一个可重复读事务发起的DELETE或UPDATE语句，可以影响到这些刚刚提交的行，即使不能查询到它们。如果一个事务对另一个事务提交的行做更新或删除操作，这些本来不可见的变更将对前者可见。例如，你可能会遇到如下场景：

```sql
SELECT COUNT(c1) FROM t1 WHERE c1 = 'xyz';
-- 返回 0：没有匹配记录。
DELETE FROM t1 WHERE c1 = 'xyz';
-- 将删除其它事务最近提交的若干行。

SELECT COUNT(c2) FROM t1 WHERE c2 = 'abc';
-- 返回 0：没有匹配记录。
UPDATE t1 SET c2 = 'cba' WHERE c2 = 'abc';
-- 影响 10 行：另一个事务刚刚提交了10条值为‘abc’的记录。
SELECT COUNT(c2) FROM t1 WHERE c2 = 'cba';
-- 返回 10: 这个事务现在可以看到它刚刚修改的行。
```
>你可以通过提交事务并执行SELECT或START TRANSACTION WITH CONSISTENT SNAPSHOT语句来刷新快照时间点。


3. 部分DDL:  删除表，copy(OLDDL)方式修改结构的表(提示: 表定义已改变，请重试事务),可以考虑
4. 对于SELECT语句的变种，如未明确FOR UPDATE或FOR SHARE的INSERT INTO ... SELECT，UPDATE ... (SELECT) 和 CREATE TABLE ... SELECT语句：

默认情况下，InnoDB对这些语句使用更强的锁，而SELECT部分则表现得像读已提交级别，即每一次快照读都会设置最新的快照，即使在同一事务内。
若要在这种情况下进行无锁读，须将事务设置为读未提交或读已提交，以避免读行时上锁。


**undo——log**  
关键词： innodb_类型  
innodb_insert_log : commit以后就可以释放了,因为insert 的数据进改事务自己可见;  
innodb_update_log : commit以后方式history list,等待purge操作，因为其他事务可能有读取改版本数据的权限;

**Readview**
作为mvcc 事务id比对标的，在事务开始时创建。
min_id   now_id[arry]  max_id

**事务隔离**  
ru：mvcc不起作用，不需要readview，直接读取最新数据。  
rc:  readview每次都读取都会更新  
rr:  readview事务创建时更新  
se(序列化) ： mvcc不起作用(所有读为加锁读(当前读))  

## 事务隔离级别

![事务隔离级别](image/事务隔离级别.png)

1. 读未提交隔离级别并没有对行数据的可见性做任何限制，所有事务之间的改动都是互相可见的，所以存在很多问题，不推荐使用；
2. 串行化隔离级别因为通过锁机制对记录的访问进行限制，所以安全性最高，但并发访问退化成串行访问，性能较低；

## 核心机制：undo 版本链

undo 版本链就是指undo log的存储在逻辑上的表现形式，它被用于事务当中的回滚操作以及实现MVCC，这里介绍一下undo log之所以能实现回滚记录的原理。

对于每一行记录，会有两个隐藏字段：row_trx_id和roll_pointer，**row_trx_id表示更新（改动）本条记录的全局事务id** （每个事务创建都会分配id，全局递增，因此事务id区别对某条记录的修改是由哪个事务作出的） ，**roll_pointer是回滚指针**，指向当前记录的前一个undo log版本，如果是第一个版本则roll_pointer指向nil，这样如果有多个事务对同一条记录进行了多次改动，则会在undo log中以链的形式存储改动过程。

假如有两个事务AB，数据表中有一行id为1的记录，其字段a初始值为0，事务A对id=1的行的a修改为1，事务B对id=1的行的a字段修改为2，则undo log版本链记录如下：

![undo 版本链](<image/undo 版本链.png>)

在上图中，最下方的undo log中记录了当前行的最新版本，而该条记录之前的版本则以版本链的形式可追溯，这也是事务回滚所做的事。那undo log版本链和事务的隔离性有什么关系呢？

## 核心机制：read view

read view表示快照读，这个快照读会记录四个关键的属性：

1. create_trx_id: 当前事务的id
2. m_idx: 当前正在活跃的所有事务id（id数组），没有提交的事务的   id
3. min_trx_id: 当前系统中活跃的事务的id最小值
4. max_trx_id: 当前系统中已经创建过的最新事务（id最大）的id+1的值

> **当一个事务读取某条记录时会追溯undo log版本链，找到第一个可以访问的版本，而该记录的某一个版本是否能被这个事务读取到遵循如下规则：（这个规则永远成立，这个需要好好理解，对后面讲解可重复读和读已提交两个级别的实现密切相关）**   

>1. 如果当前记录行的row_trx_id小于min_trx_id，表示该版本的记录在当前事务开启之前创建，因此可以访问到
>2. 如果当前记录行的row_trx_id大于等于max_trx_id，表示该版本的记录创建晚于当前活跃的事务，因此不能访问到
>3. 如果当前记录行的row_trx_id大于等于min_trx_id且小于max_trx_id，则要分两种情况：  

>* 当前记录行的row_trx_id在m_idx数组中，则当前事务无法访问到这个版本的记录 **（除非这个版本的row_trx_id等于当前事务本身的trx_id，本事务当然能访问自己修改的记录）** ，在m_idx数组中又不是当前事务自己创建的undo版本，表示是并发访问的其他事务对这条记录的修改的结果，则不能访问到。

>* 当前记录行的row_trx_id不在m_idx数组中，则表示这个版本是当前事务开启之前，**其他事务已经提交了的undo版本**，当前事务可访问到。


### 使用NOWAIT和SKIP LOCKED调整加锁读并发性
如果事务锁住一行数据，其它事务对同一行发起SELECT ... FOR UPDATE或SELECT ... FOR SHARE查询将必须等待锁被释放。这一特性防止了那些查询出来并将被更新的行被其它事务更新或者删除。然而有时你想要查询行被上锁时语句立即返回，或者可以接受结果集中不包含被上锁的行时，就没有必要等待行锁被释放。

通过在SELECT ... FOR UPDATE或SELECT ... FOR SHARE中设置NOWAIT与SKIP LOCKED选项，可以避免不必要的锁等待。

**NOWAIT**
使用了`NOWAIT`的加锁读将不会等待获取行锁。查询立即执行，在行被上锁时返回一个错误。
**SKIP LOCKED**
使用了SKIP LOCKED的加锁读也不会等待获取行锁。查询立即执行，从结果集中剔除被上锁的行。

注意
跳过加锁行的查询将返回一个非一致性的数据视图。因此SKIP LOCKED不适合常规事务场景。但可以用于在多个事务访问队列类型的表时避免锁竞争。

NOWAIT和SKIP LOCKED只能用于行级锁。

在复制语句中使用NOWAIT和SKIP LOCKED是不安全的。

下面演示NOWAIT和SKIP LOCKED如何使用。会话1开启了一个事务并获取了一行行锁。会话2在同一行发起附带NOWAIT选项的加锁读，因为请求行被会话1锁住，加锁读立刻返回了错误。会话3发起附带SKIP LOCKED的加锁读，则返回了不包含会话1锁住行的结果集。

** 会话 1:**
```sql
mysql> CREATE TABLE t (i INT, PRIMARY KEY (i)) ENGINE = InnoDB;

mysql> INSERT INTO t (i) VALUES(1),(2),(3);

mysql> START TRANSACTION;

mysql> SELECT * FROM t WHERE i = 2 FOR UPDATE;
+---+
| i |
+---+
| 2 |
+---+
```

** 会话 2:**
```sql
mysql> START TRANSACTION;

mysql> SELECT * FROM t WHERE i = 2 FOR UPDATE NOWAIT;
ERROR 3572 (HY000): Do not wait for lock.
```

** 会话 3:**

```sql
mysql> START TRANSACTION;

mysql> SELECT * FROM t FOR UPDATE SKIP LOCKED;
+---+
| i |
+---+
| 1 |
| 3 |
+---+
```