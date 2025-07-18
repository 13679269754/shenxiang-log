机器：
磁盘容量：剩余百分比，期望天数，使用量，磁盘平均iops，磁盘峰值流量，对应时间，最小流量，对应时间；
内存:内存使用量，剩余量,相关百分比，最大内存使用量及其时间节点；
网络:使用量，剩余量,相关百分比，最大内存使用量及其时间节点；

mysql:
表：表大小，增涨量,平均值;没有主键的表，表索引数量；字符集，排序规则；
列：字符集，排序规则；
引擎：存储引擎非innodb；
索引：未使用的索引，重复索引；
页：页分裂页合并发生的次数；
session 内存：%sort_merge%，%cache_disk%；
buffer_pool:
死锁记录：
阻塞记录：
慢查询：




mysql参数巡检：
show globle status like '%sort%';
sort_merge_passes 多大; sort_buffer_size 是不是需要调整

show globle status like '%log%';
Binlog_cache_disk_use 多大; Binlog_cache_size 是不是需要调整

其他磁盘状态需要关注的:
mysql> show global status like '%tmp%';
+-------------------------+---------+
| Variable_name           | Value   |
+-------------------------+---------+
| Created_tmp_disk_tables | 1459930 |
| Created_tmp_files       | 11336   |
| Created_tmp_tables      | 8636851 |
+-------------------------+---------+

mysql> show global status like '%disk%';
+----------------------------+---------+
| Variable_name              | Value   |
+----------------------------+---------+
| Binlog_cache_disk_use      | 1       |
| Binlog_stmt_cache_disk_use | 0       |
| Created_tmp_disk_tables    | 1459997 |
+----------------------------+---------+

