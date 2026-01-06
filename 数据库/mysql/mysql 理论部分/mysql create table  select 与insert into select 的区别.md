| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-17 | 2024-10月-17  |
| ... | ... | ... |
---
# mysql create table  select 与insert into select 的区别

[toc]

## 原文

[MySQL中 insert into select和create table的区别 已经复制表的方法](https://blog.csdn.net/yudianxiaoxiao/article/details/105981755)

MySQL中 [insert](https://so.csdn.net/so/search?q=insert&spm=1001.2101.3001.7020) into select和create table的区别
-----------------------------------------------------------------------------------------------------------

MySQL一般我们在生产上备份数据通常会用到 这两种方法：

1.  INSERT INTO SELECT
2.  CREATE TABLE AS SELECT

本文仅针对MySQL innodb引擎，事务是可重复读RR

### 1.INSERT INTO SELECT

```sql
insert into Table2(field1,field2,...) select value1,value2,... from Table1;
```

注意

（1）要求目标表Table2必须存在，并且字段field,field2…也必须存在

（2）注意Table2的主键约束，如果Table2有主键而且不为空，则 field1， field2…中必须包括主键

在执行语句的时候，MySQL是逐行加锁的（扫描一个锁一个）。，直至锁住所有符合条件的数据，执行完毕才释放锁。所以当业务在进行的时候，切忌使用这种方法。

在RR隔离级别下，还会加行锁和间隙锁

```sql
CREATE TABLE `t` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `c` int(11) DEFAULT NULL,
  `d` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `c` (`c`)
) ENGINE=InnoDB;

insert into t values(null, 1,1);
insert into t values(null, 2,2);
insert into t values(null, 3,3);
insert into t values(null, 4,4);

create table t2 like t

```

执行

```sql
insert into t2(c,d) select c,d from t;
```

这个语句对表 t 主键索引加了 (-∞,1\] 这个 next-key lock

此时执行下面这句sql就需要等待

```sql
insert into t values(-1,-1,-1);
```

如果实在要使用 INSERT INTO SELECT 这种方法，可以使用下面的方法进行优化：

1.  加条件，强制走索引，不要全表扫描，例如

```sql
INSERT INTO Table2 SELECT  * FROM  Table1 FORCE INDEX (create_time) WHERE update_time <= '2020-03-08 00:00:00';
```

2.  加上limit 100,100 这种，限制数量

### 2.CREATE TABLE AS SELECT

```sql
1. create table table1 as select * from table2 where 1=2;

2.create table table1 as select * from table2 ;

3.create table table1(columns1,columns2) as select columns1,columns2 from table2;

```

后面两种格式，如果后面跟上合适的查询条件，可以只复制符合条件的数据到新的表中。比如：

```sql
create  table table1  as  select * from table2  where columns1>=1;
```

针对大表多字段的表复制，考虑是否每一个字段都是必需的，如果不是必需的，可以自定义选择字段吗，这样复制的时间会大大提升。

```sql
CREATE table table1 as SELECT id FROM table2;
```

注意此建表过程全程锁表。语句执行完毕，才释放元数据锁。

> MDL全称为metadata lock，即元数据锁。MDL锁主要作用是维护表元数据的数据一致性，在表上有活动事务（显式或隐式）的时候，不可以对元数据进行写入操作。因此从MySQL5.5版本开始引入了MDL锁，来保护表的元数据信息，用于解决或者保证DDL操作与DML操作之间的一致性。

注意：

1.  新表不会自动创建创建和原表相同的索引。
2.  不能将原表中的default value也一同迁移过来

### 3 .区别

*   首先，最大的区别是二者属于不同类型的语句，INSERT INTO SELECT 是DML语句（数据操作语言，SQL中处理数据等操作统称为数据操纵语言），完成后需要提交才能生效，CREATE TABLE AS SELECT 是DDL语句（数据定义语言，用于定义和管理 SQL 数据库中的所有对象的语言 ），执行完直接生效，不提供回滚，效率比较高。
    
*   其次，功能不同，INSERT INTO SELECT只是插入数据，必须先建表；CREATE TABLE AS SELECT 则建表和插入数据一块完成。
    
*   当有大量数据的时候不推荐使用Insert into as，因为该语句的插入的效率很慢。
    

### 4.总结

以上对复制表来说，都不是很好的选择，分享几种平时常用的方法：

1.  导出成excel，然后拼sql 成 insert into values(),(),()的形式。
    
2.  定时任务，任务的逻辑是查询100条记录，然后多个线程分到几个任务执行，比如是个线程，每个线程10条记录，插入后，在查询新的100条记录处理。
    
3.  mysqldumb方法，例如
    
```sql
mysqldump -h$host -P$port -u$user
```
    
4.  导出 CSV 文件
    

```sql
select * from db1.t where a>900 into outfile '/server_tmp/t.csv';
```

第3、4两种方法适合整个表导出。