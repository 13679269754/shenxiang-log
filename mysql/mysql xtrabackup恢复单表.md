| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2023-10月-23 | 2023-10月-23  |
| ... | ... | ... |
---
# mysql xtrabackup恢复单表

[toc]

[mysql xtrabackup恢复单表](https://cloud.tencent.com/developer/article/1970574)

卸载新表表空间和挂载表空间的操作可以学习一下
```sql
ALTER table t_user discard tablespace;
ALTER TABLE t_user import tablespace;
```
