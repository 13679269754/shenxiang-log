| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-2月-13 | 2025-2月-13  |
| ... | ... | ... |
---
# mysql 函数索引的实现方式

[toc]

## generated column
```sql
-- 创建包含虚拟列的表
CREATE TABLE products (
    price DECIMAL(10, 2),
    -- 定义虚拟列，计算含税价格
    tax_rate DECIMAL(4, 2),
    total_price DECIMAL(10, 2) GENERATED ALWAYS AS (price * (1 + tax_rate)) VIRTUAL
);

-- 在虚拟列上创建函数索引
CREATE INDEX idx_total_price ON products(total_price);
```

**注意**：The tools ignores MySQL 5.7+ GENERATED columns since the value for those columns is generated according to the expression used to compute column values.  
**该工具会忽略 MySQL 5.7 GENERATED 中的列，因为这些列的值是根据用于计算列值的表达式生成的**。

## function index
```sql
-- 创建表
CREATE TABLE users (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    birth_date DATE
);

-- 创建函数索引
CREATE INDEX idx_birth_year ON users((YEAR(birth_date)));


-- 使用函数索引的查询
SELECT * FROM users WHERE YEAR(birth_date) = 1990;
```

**tip**: **注意函数内容需要用一个括号括起来。**  
本例中就是user((YEAR(birth_date)))才行， users(YEAR(birth_date))会报错。