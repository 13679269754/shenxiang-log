

| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-2月-12 | 2025-2月-12  |
| ... | ... | ... |
---
# mysql 实现递归-CTE方式

[toc]

## CTE 递归示例

tips:注意终止条件，以及最后一条记录要如何显示

```sql

-- 创建示例表
CREATE TABLE data (
    id INT,
    values_str VARCHAR(255)
);
INSERT INTO data VALUES (1, 'apple,banana,orange');
-- 使用递归 CTE 拆分数据

WITH RECURSIVE split_values AS (
    SELECT 
        id,
        SUBSTRING_INDEX(values_str, ',', 1) AS value,
        SUBSTRING(values_str, LOCATE(',', values_str) + 1) AS remaining
    FROM 
        data
    UNION ALL
    SELECT 
        id,
        SUBSTRING_INDEX(remaining, ',', 1) AS value,
        CASE when LOCATE(',', remaining) != 0 THEN SUBSTRING(remaining, LOCATE(',', remaining) + 1) 
        	 WHEN LOCATE(',', remaining) = 0 THEN '' END 
        AS remaining
    FROM 
        split_values
    WHERE 
        -- 增加更严格的终止条件
         remaining !=''
)
SELECT 
    id,
    value
FROM 
    split_values;

```

## 递归深度过大或者无限递归

一旦误实现了无限循环或者循环次数过多，会提示
```bash
ERROR 3636 (HY000): Recursive query aborted after 1001 iterations. Try increasing @@cte_max_recursion_depth to a larger value.
```