| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-28 | 2024-10月-28  |
| ... | ... | ... |
---
# mysql information_schema statistic.md

[toc]

## 官方文档

[10.2.3 Optimizing INFORMATION_SCHEMA Queries](https://dev.mysql.com/doc/refman/8.0/en/information-schema-optimization.html)


[28.3.34 The INFORMATION_SCHEMA STATISTICS Table](https://dev.mysql.com/doc/refman/8.0/en/information-schema-statistics-table.html)

## 关键记录

### 更新周期设置

Columns in STATISTICS that represent table statistics hold cached values. The information_schema_stats_expiry system variable defines the period of time before cached table statistics expire. The default is 86400 seconds (24 hours). If there are no cached statistics or statistics have expired, statistics are retrieved from storage engines when querying table statistics columns. To update cached values at any time for a given table, use ANALYZE TABLE. To always retrieve the latest statistics directly from storage engines, set information_schema_stats_expiry=0. For more information, see Section 10.2.3, “Optimizing INFORMATION_SCHEMA Queries”.

 STATISTICS 中的列表示 表统计信息保存缓存的值。的  **`information_schema_stats_expiry`**  系统变量定义缓存表之前的时间段 统计到期。**默认值是86400秒（24小时）**。如果 没有缓存的统计数据或统计数据已经过期， 查询表时，从存储引擎检索统计信息 统计数据列。对象的缓存值随时更新 给定表，使用 ANALYZE TABLE 。来 始终直接从存储中检索最新的统计信息 引擎,集  information_schema_stats_expiry=0 。 有关更多信息，请参见 10.2.3节，“优化INFORMATION_SCHEMA查询”。


### 不更新原因

 Querying statistics columns does not store or update statistics in the mysql.index_stats and mysql.innodb_table_stats dictionary tables under these circumstances:
查询统计信息列不会存储或更新统计信息 在 mysql.index_stats 和  mysql.innodb_table_stats 字典表 在这些情况下：

* When cached statistics have not expired.
当缓存的统计信息没有过期时。

* When information_schema_stats_expiry is set to 0.
当  information_schema_stats_expiry  设置为0。

* When the server is in read_only, super_read_only, transaction_read_only, or innodb_read_only mode.
**当服务器在时  read_only ,  super_read_only ,  transaction_read_only ,或者  innodb_read_only 模式**。

* When the query also fetches Performance Schema data.
**当查询还获取Performance Schema数据时**。