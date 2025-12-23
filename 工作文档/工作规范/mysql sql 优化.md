# MySQL SQL优化

SQL 的花费主要来自物理 IO 和逻辑 IO，优化 SQL 核心目标是**减少 IO 开销**。

## 一、SQL 执行顺序
优化前需明确 SQL 执行流程，每一步会生成中间结果集，后续操作基于该结果集。应尽可能早地减少中间结果集数据量，以最大化提升效率：

1. FROM <left_table>
2. ON <join_condition>
3. <join_type> JOIN <right_table>
4. WHERE <where_condition>
5. GROUP BY <group_by_list>
6. WITH CUBE|RULLUP
7. HAVING <having_condition>
8. SELECT
9. DISTINCT <select_list>
10. ORDER BY <order_by_condition>
11. LIMIT <limit_number>

### 关键优化关注点
以下步骤直接影响中间结果集大小，是优化核心：
- (1) FROM <left_table>
- (2) ON <join_condition>
- (4) WHERE <where_condition>

## 二、SQL 优化思考方向
### 1. 合理的表结构设计
- 划分业务实体，避免关联查询中两张表数据量均过大的情况；
- 选择合适的字段类型（如用 INT 代替 VARCHAR 存储数字，用 DATETIME 代替 VARCHAR 存储时间）；
- 避免冗余字段，遵循三大范式（适当反范式可提升查询效率，需权衡）。

### 2. 减少数据访问
- 通过索引访问数据，避免全表扫描；
- 避免不必要的列查询（不用 `SELECT *`），减少磁盘 IO；
- 利用分区表，将数据按时间/范围拆分，减少扫描范围。

### 3. 返回更少的数据
- 只返回需要的字段，避免冗余列；
- 分页处理（LIMIT），减少单次返回数据量，降低磁盘 IO 和网络 IO。

### 4. 减少交互次数
- 批量执行 DML 操作（如批量 INSERT/UPDATE）；
- 利用存储过程/函数，将多步逻辑合并为单次数据库调用，减少连接开销。

### 5. 减少服务器 CPU 开销
- 避免全表查询和大量排序操作；
- 减少函数运算（如 WHERE 条件中避免对字段使用函数）；
- 避免复杂的 JOIN 和子查询，必要时拆分查询。

### 6. 利用更多资源
- 使用表分区，支持并行操作，充分利用 CPU 资源；
- 合理配置缓存（如 MySQL 缓存、应用层缓存），减少重复查询。

## 三、MySQL 查看 SQL 执行计划
使用 `EXPLAIN` 或 `EXPLAIN EXTENDED` 命令分析 SQL 执行计划，重点关注以下字段：

| 字段        | 说明                                                                 |
|-------------|----------------------------------------------------------------------|
| select_type | 查询类型（如 SIMPLE、SUBQUERY、DERIVED 等）                           |
| type        | 连接类型，直接反映查询效率（性能从好到差排序）                       |
| key         | 实际使用的索引名（NULL 表示未使用索引）                               |
| rows        | MySQL 估算的扫描行数（数值越小越好）                                 |
| filtered    | 符合查询条件的数据百分比（最大 100，`rows × filtered` 为关联表实际行数） |
| Extra       | 附加信息（如索引使用情况、排序方式等）                               |

### 1. type 字段性能排序
```
system → const → eq_ref → ref → fulltext → ref_or_null → index_merge → unique_subquery → index_subquery → index → all
```
- **const**：主键/唯一索引的等值查询，仅返回 1 行，速度极快；
- **eq_ref**：主键索引或非空唯一索引的等值连接，每行匹配 1 个结果；
- **ref**：普通二级索引或复合索引最左前缀匹配，返回多行；
- **index**：索引全扫描（比 all 快，因为索引文件更小）；
- **all**：全表扫描（需避免）。

### 2. Extra 字段常见值说明
| Extra 取值          | 说明                                                                 |
|---------------------|----------------------------------------------------------------------|
| Using index condition | 索引下推优化，WHERE 条件在索引扫描阶段过滤，减少回表次数             |
| Using index          | 覆盖索引，查询所需字段均在索引中，无需回表（最优情况）               |
| Using where          | 使用二级索引，但需回表获取额外字段                                   |
| Using filesort       | 需额外排序（内存/磁盘），由 ORDER BY 导致，未使用索引排序             |
| Using temporary      | 使用临时表，由 GROUP BY/ORDER BY 导致，未使用索引                     |

## 四、常见问题优化策略
### 1. Using filesort 优化
**原因**：ORDER BY 字段无合适索引，导致排序操作。
**优化方案**：
- 减少返回数据量（如 LIMIT 分页），降低排序开销；
- 创建包含 ORDER BY 字段的索引：
  - 若查询有 WHERE 条件，创建 `WHERE 字段 + ORDER BY 字段` 的联合索引；
  - 若仅 ORDER BY，直接创建 ORDER BY 字段的索引。

### 2. Using temporary 优化
**原因**：GROUP BY/ORDER BY 未使用索引，导致创建临时表存储中间结果。
**优化方案**：
- 为 GROUP BY 字段创建索引（联合索引需遵循最左前缀原则）；
- 缩小 JOIN 前后表的数据量（如 WHERE 条件过滤无效数据）；
- 避免 GROUP BY 和 ORDER BY 同时使用不同字段，尽量复用索引。

### 3. 索引失效场景及规避
以下情况会导致 MySQL 放弃索引，走全表扫描，需避免：
#### （1）字段开头模糊查询
```sql
-- 索引失效（开头%）
SELECT * FROM user WHERE name LIKE '%张三';
-- 索引有效（结尾%）
SELECT * FROM user WHERE name LIKE '张三%';
```

#### （2）返回大量结果的查询
- 避免使用 `NOT IN`、`!=`、`<>`、`NOT LIKE` 等操作符（易导致全表扫描）；
- 若需使用，可改为 `LEFT JOIN + IS NULL` 或子查询优化。

#### （3）NULL 值匹配
```sql
-- 索引失效（NULL 匹配）
SELECT * FROM user WHERE age IS NULL;
-- 优化：用默认值（如 0）代替 NULL，查询时用 = 0
```

#### （4）对字段进行函数/计算操作
```sql
-- 索引失效（字段运算）
SELECT * FROM user WHERE age + 1 = 30;
-- 优化：将运算移到右边
SELECT * FROM user WHERE age = 30 - 1;

-- 索引失效（函数操作）
SELECT * FROM user WHERE DATE(create_time) = '2025-01-01';
-- 优化：用范围查询（需 create_time 有索引）
SELECT * FROM user WHERE create_time BETWEEN '2025-01-01 00:00:00' AND '2025-01-01 23:59:59';
```

#### （5）复合索引非前置列查询
复合索引遵循**最左前缀原则**，需按索引创建顺序使用字段：
```sql
-- 索引：CREATE INDEX idx_a_b_c ON user(a, b, c);
-- 有效（使用 a）
SELECT * FROM user WHERE a = 1;
-- 有效（使用 a, b）
SELECT * FROM user WHERE a = 1 AND b = 2;
-- 有效（使用 a, b, c）
SELECT * FROM user WHERE a = 1 AND b = 2 AND c = 3;
-- 无效（未使用前置列 a）
SELECT * FROM user WHERE b = 2 AND c = 3;
```
**建议**：创建复合索引时，将选择度高（区分度大）的字段放在前面。

#### （6）ORDER BY 与 WHERE 条件不一致
```sql
-- 索引：idx_name_age (name, age)
-- 有效（WHERE 和 ORDER BY 字段一致，复用索引）
SELECT * FROM user WHERE name = '张三' ORDER BY age;
-- 无效（ORDER BY 字段与 WHERE 不一致，无法复用索引）
SELECT * FROM user WHERE name = '张三' ORDER BY create_time;
```

## 五、多表 JOIN 查询优化
### 优化思路
1. **关联条件添加索引**：在 JOIN 的 ON 条件字段上创建索引（优先在小表的关联字段上创建）；
2. **减少关联表数据量**：通过子查询过滤关联表的无效数据（如 `WHERE 字段 IS NOT NULL`、`LIMIT` 等）；
3. **使用中间表**：将复杂 JOIN 的中间结果存入临时表，并创建索引，加速后续操作；
4. **避免 SELECT * **：明确需要返回的字段，减少数据传输，且更容易触发覆盖索引；
5. **选择合适的 JOIN 类型**：
   - INNER JOIN：只返回匹配数据，效率较高；
   - LEFT JOIN：左表全扫，需确保右表关联字段有索引；
   - 避免 RIGHT JOIN（可改为 LEFT JOIN 优化）。

### 示例优化
```sql
-- 优化前（大表关联，无索引）
SELECT * FROM order o JOIN user u ON o.user_id = u.id WHERE u.status = 1;

-- 优化后
-- 1. 在 user.id（主键默认有索引）和 order.user_id 上创建索引
CREATE INDEX idx_order_user_id ON order(user_id);
-- 2. 过滤 user 表数据，减少关联量
SELECT o.id, o.order_no, u.name FROM order o JOIN (
  SELECT id, name FROM user WHERE status = 1
) u ON o.user_id = u.id;
```