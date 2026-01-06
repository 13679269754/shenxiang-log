[如何批量删数据和调整系统表空间](https://cloud.tencent.com/developer/article/1970572)
[MySQL8.0快速回收膨胀的UNDO表空间](https://blog.csdn.net/n88Lpo/article/details/123725059)

| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2023-10月-23 | 2023-10月-23  |
| ... | ... | ... |
---
# undo 回收.md

1. 添加新的undo表空间文件
`create undo tablespace undo003 add datafile '/app/dbdata/datanode3307/logundo003.ibu';`

2. alter undo tablespace innodb_undo_002 set inactive;
set global innodb_undo_log_truncate=on;
触发制动回收
查看表空间文件大小

3. alter undo tablespace innodb_undo_002 set active;

4. 原有undo表空间文件释放后可以手动释放新添加的表空间
alter undo tablespace undo003 set inactive;
drop undo tablespace undo003;