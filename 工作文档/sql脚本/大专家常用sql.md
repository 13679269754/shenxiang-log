
# 查询sql

## 数据资产统计  

```sql
SELECT '关系型数据',/*table_schema,table_name,*/ SUM(table_rows),SUM((data_length + data_free + index_length)/1024/1024/1024/1000) data_total FROM information_schema.tables WHERE table_schema NOT IN ('information_schema','performance_schema','sys','mysql','table_backup') AND table_schema NOT LIKE 'old%' AND  table_name NOT IN ('sample','sample_context')
UNION
SELECT '非关系型数据',/*table_schema,table_name,*/ SUM(table_rows),SUM((data_length + data_free + index_length)/1024/1024/1024/1000) data_total FROM information_schema.tables WHERE table_schema NOT IN ('information_schema','performance_schema','sys','mysql','table_backup') AND table_schema NOT LIKE 'old%' AND table_name IN ('sample','sample_context')
```