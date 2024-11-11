| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-19 | 2024-10月-19  |
| ... | ... | ... |
---
# proxysql 连接池的相关配置

[toc]

## 参数文档

[Proxysql Variables MySQL变量](https://proxysql.com/documentation/global-variables/mysql-variables/#mysql-mirror_max_concurrency)   

[Multiplexing 多路复用](https://proxysql.com/documentation/multiplexing/)
关键的几个问题：

1. 什么是多路复用； 连接池连接复用
2. 何时禁用多路复用；
3. 如何控制多路复用；`mysql-auto_increment_delay_multiplex` , `mysql-auto_increment_delay_multiplex_timeout_ms` , `mysql-multiplexing`
4. 如何跟踪多路复用的状态；


## 相关问题

[mysql长连接问题](../../问题记录/mysql长连接问题长时间不释放导致临时表空间过大.md)

## 有意思的参数

### 多路复用

`mysql-auto_increment_delay_multiplex` , `mysql-auto_increment_delay_multiplex_timeout_ms` , `mysql-multiplexing`

### sql 注入检查参数
**mysql-automatic_detect_sqli**
当设置为 true 时，启用SQL注入自动检测。更多参考，请参见SQL注入引擎。 [SQL Injection Engine](https://proxysql.com/documentation/sql-injection-engine/)


### 安全更新
mysql-default_sql_safe_updates
If this variable is enabled, UPDATE and DELETE statements that do not use a key in the WHERE clause or a LIMIT clause produce an error. 

### mysql-default_session_track_gtids

`mysql-default_session_track_gtids`
在执行每个事务结束时，跟踪器将捕获服务器GTID。如果需要，GTID值也会返回给客户端。

### 行控制

`mysql-default_sql_select_limit` 

### 事务隔离级别

`mysql-default_tx_isolation`

### 长连接相关

`mysql-free_connections_pct`  保留最大的连接数
但是，**并非所有未使用的连接都保留在连接池中**。

`mysql-max_transaction_idle_time`  **在终止客户端连接之前**，连接将事务检测为idle的最长等待时间

`mysql-max_transaction_time` **活动事务**运行时间超过此超时的会话将被终止。

`mysql-ping_interval_server_msec` 代理应**ping后端连接**以使其保持活动状态（即使没有传出流量）的**时间间隔**  `mysql-ping_timeout_server` **ping 超时时间**

[MySQL的交互式与非交互式数据库交互方式](https://cloud.baidu.com/article/3147598) 

可以明确长连接并不等价与交互式连接

对于解决[mysql长连接问题](../../问题记录/mysql长连接问题长时间不释放导致临时表空间过大.md)  
我的方案

方案一：不需要动服务的配置，而是调整 mysql-ping_interval_server_msec 大于 mysql server端的wait_timeout。让mysql 主动断开proxysql 的连接,从而释放临时表空间。

优点:
1. wait_timeout 可控，可以当连接长时间空闲才杀掉连接。
2. 不影响服务的连接，服务不会报错。

缺点： 
1. proxysql 不再能ping mysql server 维持连接常驻。会频繁创建连接，会消耗proxysql 服务器的性能。

### 后端告警跟踪

`mysql-handle_warnings`

### 慢查询统计

`mysql-long_query_time`

```sql
select * from stats_mysql_global where Variable_Name like '%slow%';
```

### 并发队列

`mysql-mirror_max_concurrency`  
`mysql-mirror_max_queue_length`  

### 查询缓存

```sql
Admin> show variables like '%query_cache%';
+---------------------------------------+-------+
| Variable_name                         | Value |
+---------------------------------------+-------+
| admin-stats_mysql_query_cache         | 60    |
| mysql-query_cache_size_MB             | 256   |
| mysql-query_cache_stores_empty_result | true  |
+---------------------------------------+-------+
```

### 客户端(前端探活)

`mysql-use_tcp_keepalive`  ProxySQL将在客户端打开会话期间发送KeepAlive信号。  
`mysql-tcp_keepalive_time`

### proxysql透传（我是这么理解的）

`mysql-threshold_query_length`   
[聊聊 MySQL 网络缓冲区、net_buffer_length、max_allowed_packet 那些事](https://cloud.tencent.com/developer/article/2093859)  
当查询大于mysql-threshold_query_length时将强制开启新的连接

`mysql-threshold_resultset_size`


[聊聊 MySQL 网络缓冲区、net_buffer_length、max_allowed_packet 那些事](https://cloud.tencent.com/developer/article/2093859) 

### proxysql 客户端连接内存消耗限制

processed_bytes > (`throttle_max_bytes_per_second_to_client`/(10 * `throttle_ratio_server_to_client`))

这提供了一种方法来控制当对**客户端连接施加限制时ProxySQL保留的内存量**

### 错误日志额外信息

`mysql-verbose_query_error`

### 客户端连接空闲超时

`mysql-wait_timeout`

