## innodb RR隔离级别下是否解决了幻读


**InnoDB 存储引擎的 RR（Repeatable Read，可重复读）隔离级别确实能解决幻读问题**，但这并非所有数据库 RR 级别的通用行为 —— 它是 InnoDB 通过 **Next-Key Lock（临键锁）** 机制实现的 “超纲” 特性。

### 特殊场景：是否存在 “伪幻读”？
#### 1.  基于非唯一索引的查询
例如：表 `t` 中 `num` 是非唯一索引，已有数据 `num=20`（两行），事务 A 执行：

```sql
SELECT * FROM t WHERE num=20 FOR UPDATE;
```

InnoDB 会锁定所有 `num=20` 的行，以及 `num` 字段的间隙（如 `(10,20)`、`(20,30)`），但允许其他事务插 `num=20` 的（因为非唯一索引的间隙锁不阻止新行重复值插入）。此时事务 A 再次查询会看到新行，但这是 “非唯一索引的特殊处理”，而非入标准幻读。

仅是理论情况，实际上我们创建的表都带有非空主键，主键的是唯一的。
**注意**
MYSQL 版本8.0.34 上测试
当mysql未命中任何索引时，会在**主键索引上全部上X锁**（有间隙锁）。
当命中二级索引时，在二级索引上加锁的情况为，二级索引添加x锁（有间隙锁），主键索引添加记录锁。
```bash
RECORD LOCKS space id 29 page no 5 n bits 80 index idx_val of table `test`.`kv` trx id 11162 lock_mode X
Record lock, heap no 1 PHYSICAL RECORD: n_fields 1; compact format; info bits 0
 0: len 8; hex 73757072656d756d; asc supremum;;

Record lock, heap no 5 PHYSICAL RECORD: n_fields 2; compact format; info bits 0
 0: len 1; hex 7a; asc z;;
 1: len 3; hex 313030; asc 100;;

Record lock, heap no 8 PHYSICAL RECORD: n_fields 2; compact format; info bits 0
 0: len 1; hex 7a; asc z;;
 1: len 2; hex 3939; asc 99;;

```

注：没有主键的情况待测试，MGR(innodb cluster） 插件开启后不允许创建没有主键的表。

#### 2. 事务内先快照读、后锁定读

若事务内先执行普通快照读（无锁），再执行锁定读，可能出现结果不一致，但这是 “快照读与锁定读的可见性差异”，而非幻读：

- 事务 A 先执行 `SELECT * FROM t WHERE num=20`（快照读，返回 1 行）；
- 事务 B 插入 `num=20` 的新行并提交；
- 事务 A 再执行 `SELECT * FROM t WHERE num=20 FOR UPDATE`（锁定读，返回 2 行）。

这种情况的本质是：锁定读会读取 “当前数据”（而非快照），但这并非幻读 —— 幻读的定义是 “同一锁定读的结果不一致”，而此处是 “不同读类型的结果差异”。