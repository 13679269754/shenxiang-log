| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-1月-07 | 2025-1月-07  |
| ... | ... | ... |
---
# doris-模型

[toc]

## 模型类型综述

Doris 支持三种类型的表模型：

* Detail Model （Duplicate Key Model）：允许对指定的 Key 列进行复制，Doris 的存储层保留所有写入的数据。此模型适用于必须保留所有原始数据记录的情况。

* 主键模型（唯一键模型）：确保每行都有唯一的 Key 值，并保证给定的 Key 列没有重复的行。Doris 存储层只保留每个 key 的最新写入数据，适用于涉及数据更新的场景。

* 聚合模型 （Aggregate Key Model）：允许根据 Key 列聚合数据。Doris 存储层保留聚合数据，减少存储空间，提高查询性能。此模型通常用于需要汇总或聚合信息（如总计或平均值）的情况。

**创建表后，表模型属性将被确认，并且无法修改。根据业务需求选择合适的模型至关重要**：

* Aggregate 模型可以显著减少聚合查询期间需要扫描的数据量和计算负载，使其成为具有固定模式的报告场景的理想选择。但是，此模型对查询不是很友好。此外，由于聚合在 Value 列上是固定的，因此其他类型的聚合查询需要仔细考虑语义的正确性。count(*)

* Unique 模型适用于需要唯一主键约束的场景...

### Table Model 比较

| |详图模型 |主键模型	| 聚合模型 |
| -- | -- | -- | -- |
|键列唯一性	| 不支持，键列可以复制 | 支持	| 支持|
|同步物化视图	|支持	|支持	|支持|
|异步具体化视图	|支持	|支持	|支持|
|UPDATE 语句	|不支持	|支持	|不支持|
|DELETE 语句	|部分支持	|支持	|不支持|
|导入时更新整行	|不支持	|支持	|不支持|
|导入时部分列更新	|不支持	|支持	|部分支持|


## detail Model

在 Doris 中，**Detail Model 详细的模型** 是默认的表模型，可以用来存储每一条原始数据记录。在表创建期间指定 确定数据排序和存储所依据的列，可用于优化常见查询。通常建议选择不超过 3 列作为排序键。有关更具体的选择准则，请参阅 [Sort Key 排序关键字](https://doris.apache.org/docs/table-design/index/prefix-index)。详图模型具有以下特征：在Doris中，Detail Model是默认的表模型，它可以用来存储每个单独的原始数据记录。表创建过程中指定的字段决定了对数据进行排序和存储的列，这些列可用于优化常见查询。通常建议选择不超过三列作为排序键。有关更具体的选择准则，请参阅排序键。Detail模型具有以下特点：`Duplicate Key`在Doris中，Detail Model是默认的表模型，它可以用来存储每个单独的原始数据记录。在表创建过程中指定的  决定了对数据进行排序和存储的列，这可以用于优化常见查询。通常建议选择不超过三列作为排序键。有关更具体的选择准则，请参阅排序键。Detail模型具有以下特点：`Duplicate Key`

*   **保留原始数据 保存原始数据**：细节模型保留所有原始数据，使其适合存储和查询原始数据。对于后期需要详细数据分析的使用案例，建议使用 Detail Model 以避免数据丢失的风险。保留原始数据：细节模型保留所有原始数据，使其适合存储和查询原始数据。对于以后需要详细数据分析的用例，建议使用 Detail Model来避免数据丢失的风险。保留原始数据：细节模型保留所有原始数据，使其适合存储和查询原始数据。对于以后需要详细数据分析的用例，建议使用 Detail Model来避免数据丢失的风险。
    
*   **无重复数据删除或聚合无重复数据删除和聚合**：与聚合和主键模型不同，详细信息模型不执行重复数据删除或聚合。即使两条记录相同，每次数据插入也将被完全保留。不重复数据删除和聚合：与聚合和主键模型不同，详细模型不进行重复数据删除和聚合。每个数据插入，即使两个记录相同，也将被完全保留。不重复数据删除和聚合：与聚合和主键模型不同，详细模型不进行重复数据删除和聚合。每个数据插入，即使两个记录相同，也将被完全保留。
    
*   **灵活的数据查询 数据查询灵活**：Detail Model 保留了完整的原始数据，可以从完整的数据集中进行详细提取。这样就可以对整个数据集上的任何维度进行聚合操作，从而实现元数据审计和精细分析。灵活的数据查询：细节模型保留完整的原始数据，允许从完整的数据集中提取细节。这允许在完整数据集的任何维度上进行聚合操作，从而允许元数据审计和细粒度分析。灵活的数据查询：细节模型保留完整的原始数据，允许从完整的数据集中提取细节。这允许在完整数据集的任何维度上进行聚合操作，从而允许元数据审计和细粒度分析。
    

### 使用案例
---------------------------------------------------

在 Detail Model 中，通常只附加数据，不更新旧数据。Detail Model 通常用于需要完整原始数据的场景：在Detail Model中，通常只追加数据，不更新旧数据。详细模型通常用于需要完整原始数据的场景：在Detail Model中，通常只追加数据，不更新旧数据。详细模型通常用于需要完整原始数据的场景：

*   **日志存储**：用于存储各种类型的应用日志，如访问日志、错误日志等。每条数据都需要详细说明，以便将来进行审计和分析。日志存储：用于存储各种类型的应用日志，如访问日志、错误日志等。每个数据都需要详细说明，以便将来进行审计和分析。日志存储：用于存储各种类型的应用日志，如访问日志、错误日志等。每个数据都需要详细说明，以便将来进行审计和分析。
    
*   **用户行为数据**：在分析用户行为时，例如点击数据或用户访问路径，需要保留详细的用户操作。这有助于构建用户档案并对行为模式进行详细分析。用户行为数据：在分析用户点击数据、用户访问路径等用户行为时，需要保留详细的用户行为。这有助于构建用户配置文件并对行为模式进行详细分析。用户行为数据：在分析用户点击数据、用户访问路径等用户行为时，需要保留详细的用户行为。这有助于构建用户配置文件并对行为模式进行详细分析。
    
*   **交易数据**：对于存储交易或订单数据，一旦交易完成，通常就不需要更改数据......事务数据：对于存储事务或订单数据，一旦事务完成，通常不需要更改数据……事务数据：对于存储事务或订单数据，一旦事务完成，通常不需要更改数据……
    

### 建表说明
-------------------------------------------------------------------------------------------

创建表时，可以使用 **DUPLICATE KEY** 关键字来指定 Detail Model。Detail 表必须指定 Key columns，这些列用于在存储期间对数据进行排序。在以下示例中，Detail 表存储日志信息并根据 、 和 列对数据进行排序：`log_time``log_type``error_code`在创建表时，DUPLICATE KEY关键字可用于指定详细模型。Detail表必须指定Key列，这些列用于在存储期间对数据进行排序。下面以“Detail”表为例，表中存储日志信息，按照  、  、  列进行排序。`log_time``log_type``error_code`

![](https://cdnd.selectdb.com/assets/images/columnar-storage-9c19f70f5cc5f4aae736d93b960a0d5d.png)

```
CREATE  TABLE  IF  NOT  EXISTS example_tbl_duplicate  
(  
 log_time DATETIME  NOT  NULL,
 log_type INT  NOT  NULL, 
 error_code INT, error_msg VARCHAR(1024), 
 op_id BIGINT, 
 op_time DATETIME)  
DUPLICATE  KEY(log_time, log_type, error_code)  
DISTRIBUTED  BY  HASH(log_type) BUCKETS 10;  

```

### 数据插入和存储
-----------------------------------------------------------------------------------------

在 Detail 表中，数据不会进行重复数据删除或聚合;插入数据会直接存储它。Detail Model （详细信息模型） 中的 Key （键） 列用于排序。在Detail表中，数据不重复数据删除或聚合；直接插入数据存储数据。Detail Model中的Key列用于排序。

![](https://cdnd.selectdb.com/assets/images/duplicate-table-insert-663b9ee1dbe7b93b28123e2eeb1c435d.png)

在上面的示例中，表中最初有 4 行数据。插入 2 行后，数据将追加 （APPEND） 到表中，从而在 Detail 表中总共存储 6 行。在上面的示例中，表中最初有4行数据。在插入2行之后，数据被追加（APPEND）到表中，结果在Detail表中总共存储了6行。

```
  
INSERT  INTO example_tbl_duplicate VALUES  
('2024-11-01 00:00:00',  2,  2,  'timeout',  12,  '2024-11-01 01:00:00'),  
('2024-11-02 00:00:00',  1,  2,  'success',  13,  '2024-11-02 01:00:00'),  
('2024-11-03 00:00:00',  2,  2,  'unknown',  13,  '2024-11-03 01:00:00'),  
('2024-11-04 00:00:00',  2,  2,  'unknown',  12,  '2024-11-04 01:00:00');  
  
  
INSERT  INTO example_tbl_duplicate VALUES  
('2024-11-01 00:00:00',  2,  2,  'timeout',  12,  '2024-11-01 01:00:00'),  
('2024-11-01 00:00:00',  2,  2,  'unknown',  13,  '2024-11-01 01:00:00');  
  
  
SELECT  *  FROM example_tbl_duplicate;  
+  
| log_time | log_type | error_code | error_msg | op_id | op_time |  
+  
|  2024-11-02  00:00:00  |  1  |  2  | success |  13  |  2024-11-02  01:00:00  |  
|  2024-11-01  00:00:00  |  2  |  2  | timeout |  12  |  2024-11-01  01:00:00  |  
|  2024-11-03  00:00:00  |  2  |  2  | unknown |  13  |  2024-11-03  01:00:00  |  
|  2024-11-04  00:00:00  |  2  |  2  | unknown |  12  |  2024-11-04  01:00:00  |  
|  2024-11-01  00:00:00  |  2  |  2  | unknown |  13  |  2024-11-01  01:00:00  |  
|  2024-11-01  00:00:00  |  2  |  2  | timeout |  12  |  2024-11-01  01:00:00  |  
+  

```

## Primary Key Model

当需要更新数据时，您可以选择使用 **Unique Key Model**。Unique Key Model 确保 Key 列的唯一性。当用户插入或更新数据时，新写入的数据将使用相同的 Key 列覆盖旧数据，从而保持最新的记录。相较于其他数据模型，Unique Key Model 适用于数据更新场景，允许在插入过程中在主键级别进行更新和覆盖。

唯一键模型具有以下特征：

*   **基于主键的 UPSERT**：插入数据时，会更新有重复主键的记录，而没有主键的记录会插入。
    
*   **基于主键的去重**：唯一键模型中的 Key 列是唯一的，并且数据根据主键列进行去重。
    
*   **支持高频数据更新**：支持高频数据更新场景，同时平衡数据更新性能和查询性能。
    

### 使用案例
---------------------------------------------

*   **数据更新频率**高：在维度表更新频繁的上游 OLTP 数据库中，主键模型可以高效同步上游更新的记录，并执行高效的 UPSERT 操作。
    
*   **高效去重**：在广告活动、客户关系管理系统等场景下，需要根据 User ID 进行去重，主键模型可以保证高效的去重。
    
*   **部分记录更新**：在某些业务场景下，只需要更新某些列，例如动态标签变化频繁的用户画像，或者需要更新事务状态的订单消费场景。主键模型的部分列更新功能允许更改特定列。
    

实现方法[](#implementation-methods "Direct link to Implementation Methods")
-----------------------------------------------------------------------

在 Doris 中，Unique Key Model 有两种实现方式：

*   **Merge-on-write**：从 1.2 版本开始，Doris 中唯一键模型的默认实现是 merge-on-write 模式。该模式下，同一个 Key 在写入时会立即合并数据，保证每次写入后的数据存储状态是唯一 Key 的最终合并结果，只存储最新的结果。Merge-on-write 在查询和写入性能之间提供了良好的平衡，避免了在查询期间合并多个版本的数据，并确保谓词下推到存储层。在大多数情况下，建议使用 merge-on-write 模型。
    
*   **读时合并**：在 1.2 版本之前，Doris 的 Unique Key Model 默认为读时合并模式。这种模式下，数据在写入时不会合并，而是增量追加，在 Doris 中保留多个版本。在查询或 Compaction 期间，数据将按相同的 Key 版本合并。读时合并适用于写量大、读量少的场景，但在查询时，必须合并多个版本，并且谓词不能下推，这可能会影响查询速度。
    

在 Doris 中，Unique Key Model 有两种类型的更新语义：

*   唯一键模型的默认更新语义是**整行 UPSERT**，即 UPDATE 或 INSERT。如果该行的 Key 存在，则将对其进行更新;如果不存在，则将插入新数据。在整行 UPSERT 语义中，即使用户使用数据插入到特定的列中，Doris 也会在 planner 阶段用 NULL 值或默认值来填充缺失的列。`INSERT INTO`
    
*   **部分列更新**。如果用户想要更新特定字段，他们需要使用 merge-on-write 实现，并通过特定参数启用部分列更新支持。请参阅有关[部分列更新](https://doris.apache.org/docs/data-operate/update/update-of-unique-model)的文档。
    
### 读取[](#merge-on-read "Direct link to Merge-on-read")时合并
------------------------------------------------------

创建 Merge-on-read 表

在创建表时，可以使用 **UNIQUE KEY** 关键字来指定 Unique Key 表。可以通过显式禁用该属性来启用 merge-on-read 模式。在 Doris 2.1 版本之前，默认开启了 merge-on-read 模式：`enable_unique_key_merge_on_write`

```
CREATE  TABLE  IF  NOT  EXISTS example_tbl_unique  
(  
 user_id  LARGEINT NOT  NULL, 
 username VARCHAR(50)  NOT  NULL, 
 city VARCHAR(20), 
 age SMALLINT, 
 sex TINYINT)  
UNIQUE  KEY(user_id, username)  
DISTRIBUTED  BY  HASH(user_id) BUCKETS 10  
PROPERTIES (  
 "enable_unique_key_merge_on_write"  =  "false");  

```

### 数据插入和存储
----------------------------------------------------------------------------------

在 Unique Key 表中，Key 列不仅用于排序，还用于重复数据删除。数据插入后，新数据将覆盖具有相同 Key 值的记录。

![](https://cdnd.selectdb.com/assets/images/unique-key-model-insert-9efad210cd22c8c80098b55f0a4f5d8f.png)

如示例中所示，原始表中有 4 行数据。插入 2 个新行后，新插入的行将根据主键进行更新：

```
-- insert into raw data  
INSERT  INTO example_tbl_unique VALUES  
(101,  'Tom',  'BJ',  26,  1),  
(102,  'Jason',  'BJ',  27,  1),  
(103,  'Juice',  'SH',  20,  2),  
(104,  'Olivia',  'SZ',  22,  2);  
  
-- insert into data to update by key  
INSERT  INTO example_tbl_unique VALUES  
(101,  'Tom',  'BJ',  27,  1),  
(102,  'Jason',  'SH',  28,  1);  
  
-- check updated data  
SELECT  *  FROM example_tbl_unique;  
+---------+----------+------+------+------+  
| user_id | username | city | age | sex |  
+---------+----------+------+------+------+  
|  101  | Tom | BJ |  27  |  1  |  
|  102  | Jason | SH |  28  |  1  |  
|  104  | Olivia | SZ |  22  |  2  |  
|  103  | Juice | SH |  20  |  2  |  
+---------+----------+------+------+------+  

```

### 笔记
-----------------------------------

*   建议使用 Doris 1.2.4 之后的 merge-on-write 模式。在版本 1.2 中，启用 merge-on-write 需要在文件中添加配置。不启用此选项可能会显著影响导入性能。默认情况下，此功能在版本 2.0 及更高版本中处于启用状态。`disable_storage_page_cache=false``be.conf`
    
*   Unique 表的实现方式只能在建表时确定，不能通过变更 Schema 来改变。
    
*   在整行语义中，即使用户使用 插入到特定的列，Doris 也会在 planner 阶段用 NULL 值或默认值填充缺失的列。`UPSERT``INSERT INTO`
    
*   **部分列更新**：如果用户想要更新特定字段，他们需要使用 merge-on-write 实现，并通过特定参数启用部分列更新。有关相关使用建议，请参阅有关[部分列更新](/docs/data-operate/update/update-of-unique-model)的文档。
  

---

## Aggregate Model

---

多丽丝的聚合模型旨在高效处理大规模数据查询中的聚合操作。该聚合模型通过在数据上执行预聚合来减少计算冗余，从而提高查询性能。该模型支持常见的聚合函数，并允许在不同粒度级别上执行聚合操作。在聚合模型中，仅存储聚合后的数据，而不保留原始数据，这减少了存储空间并提高了查询性能。

### 用例
--

*   汇总详细数据：在诸如电子商务平台需要评估月度销售业绩、金融风险控制需要客户交易总额，或者广告活动分析总广告点击量等业务场景中，聚合模型用于对详细数据进行多维汇总。
    
*   无需查询原始详细数据：对于诸如仪表板报告或用户交易行为分析之类的用例，原始数据存储在数据湖中，无需保留在数据库中，仅存储聚合数据。
    

### 原则
--

每次数据导入都会在聚合模型中创建一个版本，在压缩阶段，版本会被合并。在查询时，数据会按照主键进行聚合：

*   **数据导入阶段**
    
    *   数据以批处理的方式导入聚合表，每批数据导入都会生成一个新的版本。
        
    *   在每个版本中，具有相同聚合键的数据都已预先聚合（例如求和、计数等）。
        
*   **后台文件合并阶段（压缩）**
    
    *   多个批次生成多个版本文件，这些文件会定期合并成一个更大的版本文件。
        
    *   在合并过程中，具有相同聚合键的数据会被重新聚合，以减少冗余并优化存储。
        
*   **查询阶段**
    
    *   在查询期间，系统会将所有版本中具有相同聚合键的数据进行汇总，以确保结果的准确性。
        
    *   通过这一过程，系统能够确保聚合操作高效执行，即便是在处理大量数据时也是如此。聚合后的结果已准备好进行快速查询，与查询原始数据相比，性能有了显著提升。
        

### 表格创建说明
------

在创建表时，可以使用“AGGREGATE KEY”关键字来指定聚合模型。聚合模型必须指定键列，这些键列用于在存储期间基于键列对值列进行聚合。

```
CREATE  TABLE  IF  NOT  EXISTS example_tbl_agg  
(  
 user_id             LARGEINT NOT  NULL, 
 load_dt DATE  NOT  NULL, 
 city VARCHAR(20), 
 last_visit_dt DATETIME  REPLACE  DEFAULT  "1970-01-01 00:00:00", 
 cost BIGINT SUM DEFAULT  "0", max_dwell INT MAX DEFAULT  "0",)  
AGGREGATE KEY(user_id,  date, city)  
DISTRIBUTED  BY  HASH(user_id) BUCKETS 10;  

```

在上述示例中，定义了一个用户信息和访问行为的事实表，其中 `user_id`、`load_date`、`city` 和 `age` 被用作聚合的键列。在数据导入期间，键列会被聚合为一行，值列则根据指定的聚合类型进行聚合。在聚合模型中支持以下类型的维度聚合：

*   SUM：求和，将多行的值相加。
    
*   替换：替换，下一批数据中的值将替换先前导入行中的值。
    
*   MAX：保留最大值。
    
*   MIN：保留最小值。
    
*   REPLACE\_IF\_NOT\_NULL：非空替换。与 REPLACE 的区别在于空值不会被替换。
    
*   HLL\_UNION：HLL（HyperLogLog）类型列的聚合方法，使用 HyperLogLog 算法进行聚合。
    
*   BITMAP\_UNION：用于 BITMAP 类型列的聚合方法，通过位图的并集进行聚合。
    

提示:

如果上述聚合方法无法满足业务需求，您可以选择使用 `agg_state` 类型。

数据插入与存储
-------

在“聚合”表中，数据是基于主键进行聚合的。数据插入后，聚合操作即完成。

![](https://cdnd.selectdb.com/assets/images/aggrate-key-model-insert-da52f9903218567c94814e1f793743b8.png)

在上述示例中，表中原本有 4 行数据。插入 2 行后，基于键列对维度列执行聚合操作：

```
  
INSERT  INTO example_tbl_agg VALUES  
(101,  '2024-11-01',  'BJ',  '2024-10-29',  10,  20),  
(102,  '2024-10-30',  'BJ',  '2024-10-29',  20,  20),  
(101,  '2024-10-30',  'BJ',  '2024-10-28',  5,  40),  
(101,  '2024-10-30',  'SH',  '2024-10-29',  10,  20);  
  
  
INSERT  INTO example_tbl_agg VALUES  
(101,  '2024-11-01',  'BJ',  '2024-10-30',  20,  10),  
(102,  '2024-11-01',  'BJ',  '2024-10-30',  10,  30);  
  
  
SELECT  *  FROM example_tbl_agg;  
+  
| user_id | load_date | city | last_visit_date | cost | max_dwell_time |  
+  
|  102  |  2024-10-30  | BJ |  2024-10-29  00:00:00  |  20  |  20  |  
|  102  |  2024-11-01  | BJ |  2024-10-30  00:00:00  |  10  |  30  |  
|  101  |  2024-10-30  | BJ |  2024-10-28  00:00:00  |  5  |  40  |  
|  101  |  2024-10-30  | SH |  2024-10-29  00:00:00  |  10  |  20  |  
|  101  |  2024-11-01  | BJ |  2024-10-30  00:00:00  |  30  |  20  |  
+  

```

AGG\_STATE
----------

：：： 信息提示： AGG\_STATE 是一个实验性功能，建议在开发和测试环境中使用。:::

AGG\_STATE 不能用作键列。创建表时，还必须声明聚合函数的签名。用户无需指定长度或默认值。数据的实际存储大小取决于函数的实现。

```
set enable_agg_state =  true;  
CREATE  TABLE aggstate(  
 k1 int  NULL, v1 int SUM, v2   agg_state<group_concat(string)> generic)  
AGGREGATE KEY(k1)  
DISTRIBUTED  BY  HASH(k1) BUCKETS 3;  

```

在这种情况下，`agg_state` 用于声明数据类型为 `agg_state`，而 `sum/group_concat` 是聚合函数的签名。请注意，`agg_state` 是一种数据类型，就像 `int`、`array` 或 `string` 一样。`agg_state` 只能与诸如状态、合并或联合之类的组合器一起使用。`agg_state` 表示聚合函数的中间结果。例如，对于聚合函数 `group_concat`，`agg_state` 可以表示 `group_concat('a', 'b', 'c')` 的中间状态，而不是最终结果。

`agg_state` 类型需要使用 `state` 函数生成。对于此表，您需要使用 `group_concat_state` ：

```
insert  into aggstate values(1,  1, group_concat_state('a'));  
insert  into aggstate values(1,  2, group_concat_state('b'));  
insert  into aggstate values(1,  3, group_concat_state('c'));  
insert  into aggstate values(2,  4, group_concat_state('d'));  

```

表中的计算方法如下图所示：

![](https://cdnd.selectdb.com/assets/images/state-func-group-concat-state-result-1-ce42d97ce583b45f53f7007dc9f877fc.png)

在查询表时，可以使用合并操作来合并多个 `state` 值并返回最终的聚合结果。由于 `group_concat` 需要排序，结果可能会不稳定。

```
select group_concat_merge(v2)  from aggstate;  
+  
| group_concat_merge(v2)  |  
+  
| d,c,b,a |  
+  

```

如果您不需要最终的聚合结果，可以使用 `union` 来合并多个中间聚合结果并生成一个新的中间结果。

```
insert  into aggstate select  3,sum_union(k2),group_concat_union(k3)  from aggstate;  

```

表中的计算方法如下：

![](https://cdnd.selectdb.com/assets/images/state-func-group-concat-state-result-2-522093a6d2ff018cab756c022e1dbb18.png)

查询结果如下：

```
mysql>  select sum_merge(k2)  , group_concat_merge(k3)from aggstate;  
+  
| sum_merge(k2)  | group_concat_merge(k3)  |  
+  
|  20  | c,b,a,d,c,b,a,d |  
+  
  
mysql>  select sum_merge(k2)  , group_concat_merge(k3)from aggstate where k1 !=  2;  
+  
| sum_merge(k2)  | group_concat_merge(k3)  |  
+  
|  16  | c,b,a,d,c,b,a |  
+  

```


## **使用笔记**

源网页:[使用笔记](https://doris.apache.org/docs/table-design/data-model/tips)
