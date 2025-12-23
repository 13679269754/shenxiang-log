| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-2月-21 | 2025-2月-21  |
| ... | ... | ... |
---
# proxysql 日常运维

[toc]

## 参考

https://proxysql.com/documentation/ProxySQL-Configuration/
https://proxysql.com/documentation/proxysql-read-write-split-howto/
https://proxysql.com/documentation/how-to-setup-proxysql-sharding/

说明:查看库中的表(use database 没啥用)
SHOW TABLES FROM monitor;


## 一.查看主要表信息

### 用户表 mysql_users

mysql-组件集\proxysql\proxysql 用户管理.md
```sql
INSERT INTO mysql_users(username,password,default_hostgroup) VALUES ('stnduser','stnduser',1);

LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;

select * from mysql_users;
```

重要参数:   
* transaction_persistent 
* fast_forward
* backend 和frontend


### 服务器表mysql_servers

```sql
INSERT INTO mysql_servers(hostgroup_id,hostname,port) VALUES (1,'10.0.0.2',3306);

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

select * from mysql_servers;
```

### SQL分发规则表 mysql_query_rules

```sql
INSERT INTO mysql_query_rules (rule_id,active,match_digest,destination_hostgroup,apply)VALUES
(1,1,'^SELECT.*FOR UPDATE$',1,1),
(2,1,'^SELECT',2,1);
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;

select * from mysql_query_rules\G;
```

参数信息global_variables

```sql
UPDATE global_variables SET variable_value='2000' WHERE variable_name IN ('mysql-monitor_connect_interval','mysql-monitor_ping_interval','mysql-monitor_read_only_interval');
SELECT * FROM global_variables WHERE variable_name LIKE 'mysql-monitor_%';

LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
```

## 二.monitor 相关表使用
monitor 用户配置

UPDATE global_variables SET variable_value='monitor' WHERE variable_name='mysql-monitor_username';

UPDATE global_variables SET variable_value='monitor' WHERE variable_name='mysql-monitor_password';

connec
t-error

select * from monitor.mysql_server_connect_log;
心跳信息的监控

select * from monitor.mysql_server_ping_log;
read_only的日志监控

SELECT * FROM monitor.mysql_server_read_only_log ORDER BY time_start_us DESC LIMIT 3;


## 三.replication 关系查看
根据read_only的探测结果 来自动区分读写，（读写组会自动切换）

```sql
INSERT INTO mysql_replication_hostgroups (writer_hostgroup,reader_hostgroup,comment) VALUES (1,2,'cluster1');

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

select * from mysql_replication_hostgroups;
```

## 四.查询统计
连接池
```sql
SELECT * FROM stats.stats_mysql_connection_pool;
查询类型统计

SELECT * FROM stats.stats_mysql_commands_counters WHERE Total_cnt;
sql语句统计

SELECT hostgroup hg, sum_time, count_star, digest_text FROM stats_mysql_query_digest ORDER BY sum_time DESC;

SELECT * FROM stats_mysql_query_digest ORDER BY sum_time DESC;
五.详细qurey统计
top 5 queries based on total execution time

SELECT digest,SUBSTR(digest_text,0,25),count_star,sum_time FROM stats_mysql_query_digest WHERE digest_text LIKE 'SELECT%' ORDER BY sum_time DESC LIMIT 5;
 top 5 queries based on count

SELECT digest,SUBSTR(digest_text,0,25),count_star,sum_time FROM stats_mysql_query_digest WHERE digest_text LIKE 'SELECT%' ORDER BY count_star DESC LIMIT 5;
top 5 queries based on maximum execution time

SELECT digest,SUBSTR(digest_text,0,25),count_star,sum_time,sum_time/count_star avg_time, min_time, max_time FROM stats_mysql_query_digest WHERE digest_text LIKE 'SELECT%' ORDER BY max_time DESC LIMIT 5;
top 5 queries ordered by total execution time,and with a minimum execution time of at least 1 millisecond with percentage

SELECT digest,SUBSTR(digest_text,0,25),count_star,sum_time,sum_time/count_star avg_time, ROUND(sum_time*100.00/(SELECT SUM(sum_time) FROM stats_mysql_query_digest),3) pct FROM stats_mysql_query_digest WHERE digest_text LIKE 'SELECT%' AND sum_time/count_star > 1000000 ORDER BY sum_time DESC LIMIT 5;