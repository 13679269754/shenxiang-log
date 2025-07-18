| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-2月-18 | 2025-2月-18  |
| ... | ... | ... |
---
# mysql explain

[toc]

## type


| type | 含义 | 
| -- | -- |
| system | 只有一行记录的系统表 |
| const | 最多只有一条记录返回的主键查询 |
| eq_ref | 通过唯一键 |
| ref | 通过普通索引 |
| fulltext | 通过全文索引 |
| ref_or_null | 类似ref,但是要查询null值 |
| index_merge | 使用到多个索引的话，对索引出来的结果集求集合操作，or 用的比较多 |
| unique_subquery | 子查询列是唯一索引 |
| index_subquery | 子查询列是普通索引 |
| range | 范围扫描 |
| index | 索引扫描 |
| ALL | 全表扫 |

**由上至下性能变差**

## extra
| extra | 含义 |
| -- | -- |
| using filesort |  |
| using index | 使用索引就能得到结果，索引覆盖 |
| using index condition | 使用index condition pushdown 优化 |
| using index for group by | 使用索引就能处理 group by 或distinct |
| using join buffer | |
| using mrr | |
| using temporary | |
| using where | 使用where 过滤 |