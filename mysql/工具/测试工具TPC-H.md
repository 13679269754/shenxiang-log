| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-2月-26 | 2024-2月-26  |
| ... | ... | ... |
---
# 测试工具TCP-H.md

[toc]

[MySQL TPCH测试工具简要手册](https://imysql.com/2012/12/21/tpch-for-mysql-manual.html)

表间的关联关系
```sql
 desc select count(*)
 from
    customer,
    orders,
    lineitem,
    supplier,
    nation,
    region
where
    c_custkey = o_custkey
    and l_orderkey = o_orderkey
    and l_suppkey = s_suppkey
    and c_nationkey = s_nationkey
    and s_nationkey = n_nationkey
    and n_regionkey = r_regionkey
    and r_name = 'AMERICA'
    and o_orderdate >= date '1993-01-01'
    and o_orderdate < date '1993-01-01' + interval '1' year;
```

## 测试脚本生成

[测试脚本生成](https://greatsql.cn/docs/8032-25/user-manual/10-optimze/3-2-benchmark-tpch.html)