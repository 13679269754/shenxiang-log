| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2025-2月-19 | 2025-2月-19 |
| ... | ... | ... |
---
# mysql ssd 系统参数调优


## ssd 盘的调优
磁盘调度方式 : deadline 或者noop
innodb设置：innodb_flush_neighbors=0
                   innodb_log_flie_size = 4G

## innodb_io_capacity

[mysql 参数调优(6)之磁盘IO性能相关的innodb_io_capacity_max 和innodb_io_capacity](https://www.jianshu.com/p/47201b681ed0)

该参数影响两个方面，规则如下:  
1、合并插入缓冲时,每秒合并插入缓冲的数量为 innodb_io_capacity值的5%，默认就是 200*5%=10  
2、在从缓冲区刷新脏页时（checkpoint）,每秒刷新脏页的数量就等于innodb_io_capacity的值，默认200  

这是一个更加高级的调优，只有当你在频繁写操作的时候才有意义（它不适用于读操作）。若你真的需要对它进行调整，最好的方法是要了解系统可以支持多大的 IOPS。譬如，假设服务器有一块 SSD 硬盘，我们可以设置 innodb_io_capacity_max=6000 和 innodb_io_capacity=3000（最大值的一半,即iops 的一半）

innodb_io_capacity 它会直接决定mysql的tps（吞吐性能），这边给出参考：  
sata/sas硬盘这个值在200  
sas raid10: 2000  
ssd硬盘：8000  
fusion-io（闪存卡）：25,000-50,000  


