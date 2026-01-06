| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-12 | 2024-10月-12  |
| ... | ... | ... |
---
# mysql 段区页的那些事

[toc]

## 几个问题

### mysql 创建一个空的新表占用多大的空间？

> 在 MySQL 中，当你创建一个空的新表时，InnoDB 存储引擎会为该表分配一个最小的空间量，即 1 个页（16KB）。

> 这是因为 InnoDB 需要为表的元数据（如表名、列名、索引等）分配空间，即使表中没有任何数据。这个最小的空间量被称为 "minimum record size"。

> 具体来说，当你创建一个空的新表时，InnoDB 会为该表分配以下空间：

1 个页（16KB）用于存储表的元数据
1 个 extent（64 个页，共 1MB）用于存储表的数据（即使表中没有任何数据）
因此，创建一个空的新表在磁盘上占用的空间大约为 1MB（1 个 extent）。

> 注意：如果你使用的是 MySQL 5.7 或更高版本，InnoDB 的默认行为是使用 "compact" 行格式，这意味着表的元数据会被存储在表空间中，而不是在单独的文件中。这可能会导致表的空间占用略有不同。


### mysql 一次性分配几个段

在 MySQL 中，InnoDB 存储引擎会一次性分配多个 extent 来满足表的空间需求。当你创建一个新表或向现有表插入数据时，InnoDB 会根据表的空间需求来分配空间。

默认情况下，InnoDB 存储引擎会一次性分配 8 个 extent 来满足表的空间需求。如果表的空间需求超过了这个数量，InnoDB 会继续分配更多的 extent。

每个 extent 由 64 个连续的页组成，每个页的大小为 16KB。因此，每次分配 8 个 extent，InnoDB 将会分配 512KB 的空间。

你可以使用以下命令来查看表的空间使用情况：

SHOW TABLE STATUS LIKE 'your_table_name';
这个命令会显示表的空间使用情况，包括 data_length、index_length 等信息。

如果你想更改 InnoDB 的默认分配策略，可以通过修改配置文件 my.cnf 来进行设置。例如，你可以使用 innodb_autoextend_increment 参数来指定 InnoDB 在空间不足时一次性分配的 extent 数量。

### mysql 一个段多大？

[17.11.2 File Space Management](https://dev.mysql.com/doc/refman/8.0/en/innodb-file-space.html)

这些页面被分组为 页的区段大小为1MB 大小不超过16KB（64个连续的16KB页面，或128个8KB页面）， 或256个4KB页面)。对于大小为32KB的页面，区段大小为2MB。 对于页面大小为64KB的情况，区段大小为4MB。的 表空间内的“文件”被调用 段在  InnoDB 。(这些片段不同于 回滚 段，它实际上包含许多表空间 段。)  **页的大小通过innodb_page_size 控制**。

### 如何查看一个表有多少段

```sql
SELECT * FROM  information_schema.FILES ORDER BY total_extents DESC 
```

这个表我发现，很多表的total_extents是0，猜测是没有分配新的段就不会记录段的数量。这个后续可以再查查资料。目前任然有一些疑惑。