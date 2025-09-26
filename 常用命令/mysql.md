| operator | createtime  | updatetime  |
| -------- | ----------- | ----------- |
| shenx    | 2024-10月-17 | 2024-10月-17 |

---
# mysql

## 实时运行的SQL查询

```sql
SELECT CONCAT('kill ',id,';' ) ,db,info,time,host  FROM information_schema.`PROCESSLIST`WHERE  command<>'Sleep' AND    (info  is not null  and   info not LIKE '% kill %' )   ORDER BY TIME;

Select CONCAT('kill ',id,';' ) ,info from  information_schema.`PROCESSLIST` where db='tcbiz_ins_config';

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

----------------------

## 用户及权限导出

```sql
SELECT CONCAT('CREATE USER \'',  user,  '\'@\'', host,  '\' IDENTIFIED BY \'your_password\';')  FROM mysql.user  INTO  OUTFILE  '/path/to/users.sql'; 

SELECT CONCAT('GRANT ',  PRIVILEGE_TYPE, ' ON ', TABLE_SCHEMA, '.', TABLE_NAME, ' TO \'', GRANTEE ,'\';') AS stmt FROM information_schema.TABLE_PRIVILEGES  INTO  OUTFILE  '/path/to/privileges.sql'; 
```


---------------------

```bash
/usr/local/data/mysql/bin/mysqldump  -S /usr/local/data/mysql_data/ 2025-02-10_0010_2025-02-09/dbmysql/run/mysql3406.sock  
--set-gtid-purged=OFF 
--single-transaction  
--routines 
--triggers 
--events 
--databases algorithm 
--tables tcm_rag wm_embedding_data 
--net_buffer_length=16777216 
--max_allowed_packet=134217728 
--master-data=1 
--extended-insert > algorithm_2_table.sql
```

导出指定库
```sql
   SELECT GROUP_CONCAT(schema_name) FROM information_schema.`SCHEMATA` WHERE schema_name NOT IN ('mysql','information_schema','sys','performance_schema')  AND   schema_name NOT LIKE '%old_%' 

```
```bash
/usr/local/data/mysql/bin/mysqldump  -S /usr/local/data/mysql_data/2025-02-10_0010_2025-02-09/dbmysql/run/mysql3406.sock  
--set-gtid-purged=OFF 
--single-transaction  
--routines 
--triggers 
--events 
--databases user_data table_backup storage shop settlement sensitive_data search research recommend questionnaire pv product_data product_application_data payment org_data open_gpt_data oa meta_data meta message_data live_video inquiry influence ims import hosec hers_data health_action_data export equity dzjetl disease_data digitalize_exam cuss credit content_data content confs_data conference city_health_data_docking case_data basic_data auth algorithm acts  
-d 
--net_buffer_length=16777216 
--max_allowed_packet=134217728 
--master-data=1 
--extended-insert > table_schema.sql
```

## change master


涉及主库状态探测心跳包的配置

```sql
change master to master_host='192.168.163.131',master_port=3307,master_user='rep',master_password='rep',master_auto_position=1,MASTER_HEARTBEAT_PERIOD=2,MASTER_CONNECT_RETRY=1, MASTER_RETRY_COUNT=86400;
set global slave_net_timeout=8;
```


非gtid
```sql
CHANGE MASTER TO MASTER_HOST = '10.10.0.142',  MASTER_USER = 'mhaadmin', MASTER_PASSWORD = 'mhapass', MASTER_PORT = 3306, MASTER_LOG_FILE='mysql-bin.000051',MASTER_LOG_POS=87047215
```

## mysqlbinlog

```bash
mysqlbinlog --database=db --base64-output=decode-rows -v --start-datetime='2019-04-11 00:00:00' --stop-datetime='2019-04-11 15:00:00'
```

--no-defaults   不使用no default可能会报错  
--base64-output=decode-rows -v   解析语句部分的内容


## pt-osc

```bash
pt-online-schema-change --host=172.16.1.7 --port=3306  --user=root --ask-pass --no-check-replication-filters --recursion-method --alter "ADD COLUMN deleted tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0:否 1:是'" D=tcbiz_airtkt_policy,t=tk_discount_code —execute
```

## Mysqldump

```bash
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD --single-transaction --routines --triggers --events --databases $DB_NAME --net_buffer_length=16777216 --max_allowed_packet=134217728 --master-data=1 --extended-insert > dump.sql
```
* --no-create-db：不包括 CREATE DATABASE 语句。
* --no-create-info：不包括 CREATE TABLE 语句。
* --no-data：只备份表结构，不包括数据。
* --skip-lock-tables：在备份期间不锁定表，允许其他会话对表进行读写操作。
* --ignore-table：忽略备份中的特定表。可以同时指定多个表，以逗号分隔。
* --where：指定一个 WHERE 条件来选择要备份的数据记录。

## LOAD DATA INFILE

```sql
LOAD DATA INFILE '/path/to/file.csv'
INTO TABLE your_table
CHARACTER SET gbk  -- 文件为 GBK 编码
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n';
```

对于 secure_file_priv =''的mysql 服务

```sql
LOAD DATA LOCAL INFILE '/root/新-联合用药信息-提交.csv'
INTO TABLE shangdongqilu.新_联合用药信息_提交_csv
CHARACTER SET utf8
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;  -- 忽略表头
```

## 索引合规探测

1. 基础探测：CARDINALITY 与总行数对比

```sql
SELECT 
  s.TABLE_NAME,
  s.INDEX_NAME,
  s.COLUMN_NAME,
  s.CARDINALITY,
  t.TABLE_ROWS,
  ROUND(s.CARDINALITY / t.TABLE_ROWS, 4) AS selectivity_ratio
FROM 
  INFORMATION_SCHEMA.STATISTICS s
JOIN 
  INFORMATION_SCHEMA.TABLES t 
  ON s.TABLE_SCHEMA = t.TABLE_SCHEMA 
  AND s.TABLE_NAME = t.TABLE_NAME
WHERE 
  s.TABLE_SCHEMA = 'your_database'
  AND t.TABLE_ROWS > 0  -- 过滤空表
ORDER BY 
  selectivity_ratio ASC;  -- 选择性低的索引优先
```

2. 深度探测：具体列值分布

```sql
SELECT 
  column_name,
  value,
  count_value,
  total_rows,
  ROUND(count_value / total_rows, 4) AS value_ratio
FROM (
  SELECT 
    'column_name' AS column_name,  -- 替换为实际列名
    column_name AS value,
    COUNT(*) AS count_value,
    (SELECT COUNT(*) FROM your_table) AS total_rows
  FROM 
    your_table
  GROUP BY 
    column_name
) t
ORDER BY 
  value_ratio DESC
LIMIT 10;  -- 查看最频繁出现的值
```

```sql
-- 重复索引
SELECT * FROM sys.schema_redundant_indexes;
-- 未使用索引
SELECT * FROM sys.schema_unused_indexes;
```

## 数据文件校验 mysqlcheck

 mysqlcheck --all-databases   -S /usr/local/data/mysql_data/db3106/run/mysql3106.sock -u root -p