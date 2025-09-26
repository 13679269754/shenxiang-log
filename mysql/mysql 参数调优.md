| operator | createtime  | updatetime  |
| -------- | ----------- | ----------- |
| shenx    | 2023-10月-30 | 2023-10月-30 |
| ... | ... | ... |
---
# mysql 参数调优

[toc]

## 刷新

innodb_flush_method o_direct
[innodb_flush_method](https://www.cnblogs.com/JennyYu/p/16563168.html)

## io

innodb_io_capacity = 1000/2000/4000  磁盘write的iops  
innodb_page_cleaners = cpu/4 or cpu/2  
innodb_fast_shutdown = 0/1  
innodb_flush_neighbers = 0/1/2 SSD建议为0  

## 重做日志

innodb_log_file_size = 4G 
innodb_log_buffer_size 
innodb_log_files_in_group

## undo

innodb_purge_thread = 4

## 线程池

thread_handing = pool-of-threads
thread_pool_size = 32
extra_port = 3333

## 内存
NUMA cpu 架构内存使用策略
numactl --interleave=all mysqld……
或者直接关闭numa

mysql 8.0 可以直接修改这个参数
```sql
show variables like '%numa%';  
+------------------------+-------+  
| Variable_name          | Value |  
+------------------------+-------+  
| innodb_numa_interleave | OFF   |  
+------------------------+-------+  
```
5.6版本以后的需要编译安装

关闭swap
echo "vm.swappiness = 0" >> /etc/sysctl.conf

## 网卡软中断

## 磁盘优化
磁盘调度 deadline /  noop  
innodb_flush_neighbors = 0  
innodb_log_file_size = 4G   

## raid 卡的写缓存

## 文件系统
xfs/ext4
noatime
nobarrier -- 建议有磁盘缓存再开启

##  主从参数优化
主:
binlog-do-db   
binlog-ignore-db  
max_binlog_size   
binlog_format=ROW  
transaction-isolation=READ-COMMITTED  
expire_logs_days= 7   
server_id=  
binlog_cache_size=  
sync_binlog=1  
innodb_flush_log_at_trx_commit=1  
innodb_support_xa=1  

从库
log_slave_update 联级复制  
replicate-do-db   
replicate-ignore-db  
replicate-do-table  
replicate-ignore-table  
server_id  
**relay-log-recovery**=1 #io_thread safe  
**relay_log_info_repository**=table #sql_thread safe  
master_info_repository = table   
read_only=1  
sync_relay_log                         10000   
sync_relay_log_info                    1000    


> 关于 relay_log_info_repository = table 会将event 的执行与log_info的记录作为一个原子操作 所以不会出现sync_relay_log_info 记录不正常的情况  
> relay-log-recovery 宕机后不使用已经拉取的日志，以sql线程的回放点，重新拉取日志

[延迟从库加上MASTER_DELAY，主库宕机后如何快速恢复服务](https://cloud.tencent.com/developer/article/1844950)

## 并行复制
slave_parallel_workers =16  
slave_parallel_type = LOGICAL_CLOCK  
binlog_group_commit_sync_delay   
binlog_group_commit_sync_no_delay_count   

## 半同步复制 
rpl_semi_sync_master_enabled=1  
rpl_semi_sync_slave_enabled=1  
rpl_semi_sync_master_timeout=1000  

rpl_semi_sync_master_point=AFTER_SYNC  
rpl_semi_sync_master_wait_for_slave_count=1  

## MGR关键参数
group_replication_flow_control_mode  -- MGR流控参数  
group_replication_compression_threshold = 100 -- 流控对当write_set大于100字节时 对数据进行压缩  
binlog_checksum=none  
transaction_write_set_extraction=XXHASH64  
