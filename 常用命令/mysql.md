| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-17 | 2024-10月-17  |
| ... | ... | ... |
---
# mysql

[toc]

## 实时运行的SQL查询

```sql
SELECT CONCAT('kill ',id,';' ) ,db,info,time,host  FROM information_schema.`PROCESSLIST`WHERE  command<>'Sleep' AND    (info  is not null  and   info not LIKE '% kill %' )   ORDER BY TIME;Select CONCAT('kill ',id,';' ) ,info from  information_schema.`PROCESSLIST` where db='tcbiz_ins_config';

SELECT * FROM information_schema.`PROCESSLIST` where DB='tcbiz_rcs_kunpeng';

SELECT * FROM information_schema.INNODB_LOCKS;

SELECT * FROM information_schema.INNODB_LOCK_WAITS ;

-- 查询是否有事务

select * from information_schema.INNODB_TRX \G;
SELECT DISTINCT CONCAT('User: ''',user,'''@''',host,''';') AS query FROM mysql.user;

show grants for xxx;

-- 设置主键自增值
alter table tablename auto_increment=10000;
```

---
## 权限

```sql
-- 查看用户权限
Show grants  for user@‘host’;

-- 授予用户function 权限
GRANT EXECUTE, ALTER ROUTINE ON FUNCTION `tcbiz_ins_settle`.`getjsonvalue` TO 'tcbiz_ins_read'@'10.%';

-- 创建 过程 ,函数
delimiter $$
…
delimiter ;
```

---

## 找到指定表的锁（元数据锁）

```sql
SELECT concat( 'kill ' ,thread_id ,';') from performance_schema.metadata_locks   ml    join performance_schema.threads t    on ml.owner_thread_id = t.thread_id    WHERE object_name ='sample_export_temp' ;
```

---

## 数据库状态查询

```sql
SELECT sum(data_length+index_length)/1024/1024 AS total_mb FROM information_schema.tables WHERE table_type = "base table" AND table_schema IN <list of schema names>
```

---

## 连表更新分批处理

```sql
CREATE TABLE table_backup.update_cons_popular_science_id(
`max_id` BIGINT NOT NULL COMMENT '最大主键',
`min_id` BIGINT NOT NULL COMMENT '最小主键'
)ENGINE=INNODB COMMENT='cons_popular_science_id' ;


DELIMITER //
CREATE PROCEDURE content_data.update_cons_popular_science()
BEGIN
SELECT
    MAX(t1.id),
    MIN(t1.id) INTO @max_id ,@min_id
FROM
    content_data.cons_popular_science t1
JOIN content_data.cons_content t2 ON t1.content_code = t2.code;  

SET @_item_id_old=0;
SET @_item_id_new=0;
SET @_item_id_old=@min_id;

WHILE (@_item_id_new<@max_id) DO

SELECT
    MAX(id) INTO @_item_id_new
FROM
    (
        SELECT
            id
        FROM
            content_data.cons_popular_science
        WHERE
            id >=@_item_id_old
        ORDER BY
            id
        LIMIT 1000
    ) ss;

INSERT INTO table_backup.update_cons_popular_science_id(max_id,min_id) VALUES (@_item_id_new,@_item_id_old);

UPDATE content_data.cons_popular_science t1
JOIN content_data.cons_content t2
ON t1.content_code = t2.code
SET t1.modify_time = t2.modify_time
WHERE
    t1.id >=@_item_id_old
AND t1.id <=@_item_id_new ;  
SET @_item_id_old =@_item_id_new ;
END WHILE;
END
//
```

---

## 过程,函数

```sql
-- 查看
select `name` from mysql.proc where db = 'xx' and `type` = 'PROCEDURE';   //
-- 存储过程
select * from mysql.proc where db = 'xx' and `type` = 'PROCEDURE' and name='xx';
-- 函数
select `name` from mysql.proc where db = 'xx' and `type` = 'FUNCTION'   //

show procedure status;
show function status;

-- 查看存储过程或函数的创建代码
　　show create procedure proc_name;
　　show create function func_name;

-- 查看视图
　　SELECT * from information_schema.VIEWS ;  //视图
　　SELECT * from information_schema.TABLES ;  //表

-- 查看触发器
　　SHOW TRIGGERS [FROM db_name] [LIKE expr];
　　SELECT * FROM triggers T WHERE trigger_name=”mytrigger” \G;

-- 查看定时任务
SET GLOBAL event_scheduler = ON;
SELECT * from information_schema.events;

select * from information_schema.events;

```

---

## 查看库大小

```sql
select TABLE_SCHEMA ,TABLE_NAME ,concat(sum(DATA_LENGTH/1024/1024/1024),"G") FROM information_schema.TABLES  group by TABLE_SCHEMA having  TABLE_SCHEMA = 'tcbiz_ins_bgw_platform';
查看表大小
select table_schema,table_name,
       (data_length + index_length) / 1024 / 1024 /1024 as total_GB
  from information_schema.tables order by total_GB desc limit 10;
```

```sql
-- 查看mysql 各库大小
select TABLE_SCHEMA,concat(round(sum(DATA_LENGTH/1024/1024),2),'MB') as data from information_schema.tables where TABLE_SCHEMA not in ('information_schema','mysql','performance_schema','sys')  group by TABLE_SCHEMA

-- 查看全库大小
select   'all_databases',concat(round(sum(data),2),'MB') from ( select TABLE_SCHEMA,round(sum(DATA_LENGTH/1024/1024),2) as data from information_schema.tables where TABLE_SCHEMA not in ('information_schema','mysql','performance_schema','sys')  group by TABLE_SCHEMA )a;
```
---

## 只复制部分表

```sql
mysql只复制部分表
SET GLOBAL REPLICATE_WILD_DO_TABLE=('tcbiz_ins_cash_interface_plateform.%');
```

---

## 数据库日志量

```sql
-- 首先即算每分钟产生的日志量：
pager grep -i 'Log sequence number'
show engine innodb status\G select sleep(60);
show engine innodb status\G;

-- 把后边一次结果减去前边一次结果，进行运算，得出的结果就是每分钟产生的日志量，然后
乘以 60 就是一小时的日志量：
select round((2029338537-2029338537) /1024/1024/@@innodb_log_files_in_group)
as MB;

-- 查询每分钟的日志量也可以通过查询 information_schema.global_status 表：
select @a1 := variable_value as a1 from information_schema.global_status where variable_name = 'innodb_os_log_written' union all select sleep(60) 
union all
select @a2 := variable_value as a2 from information_schema.global_status where variable_name = 'innodb_os_log_written';

-- 把后边一次结果减去前边一次结果并进行即算，得出的结果就是每分钟的日志量：
select round((@a2-@a1) /1024/1024/@@innodb_log_files_in_group) as MB;
```