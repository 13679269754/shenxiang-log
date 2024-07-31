MySQL 优化（四）
===========

[imysql.cn](https://imysql.cn/node/37)

### 7.2.9 MySQL 如何优化 `ORDER BY`

在一些情况下，MySQL可以直接使用索引来满足一个 `ORDER BY` 或 `GROUP BY` 子句而无需做额外的排序。

尽管 `ORDER BY` 不是和索引的顺序准确匹配，索引还是可以被用到，只要不用的索引部分和所有的额外的 `ORDER BY` 字段在 `WHERE` 子句中都被包括了。下列的几个查询都会使用索引来解决 `ORDER BY` 或 `GROUP BY` 部分：

```
SELECT * FROM t1 ORDER BY key_part1,key_part2,... ;
SELECT * FROM t1 WHERE key_part1=constant ORDER BY key_part2;
SELECT * FROM t1 WHERE key_part1=constant GROUP BY key_part2;
SELECT * FROM t1 ORDER BY key_part1 DESC, key_part2 DESC;
SELECT * FROM t1
	WHERE key_part1=1 ORDER BY key_part1 DESC, key_part2 DESC;
```

在另一些情况下，MySQL无法使用索引来满足 `ORDER BY`，尽管它会使用索引来找到记录来匹配 `WHERE` 子句。这些情况如下：  

<br />

* 对不同的索引键做 `ORDER BY` ：

  ```
  SELECT * FROM t1 ORDER BY key1, key2;
  ```

* 在非连续的索引键部分上做 `ORDER BY`：

  ```
  SELECT * FROM t1 WHERE key2=constant ORDER BY key_part2;
  ```

* 同时使用了 `ASC` 和 `DESC`：

  ```
  SELECT * FROM t1 ORDER BY key_part1 DESC, key_part2 ASC;
  ```

* 用于搜索记录的索引键和做 `ORDER BY` 的不是同一个：

  ```
  SELECT * FROM t1 WHERE key2=constant ORDER BY key1;
  ```

* 有很多表一起做连接，而且读取的记录中在 `ORDER BY` 中的字段都不全是来自第一个非常数的表中（也就是说，在 `EXPLAIN` 分析的结果中的第一个表的连接类型不是 `const`）。
* 使用了不同的 `ORDER BY` 和 `GROUP BY` 表达式。
* 表索引中的记录不是按序存储。例如，`HASH` 和 `HEAP` 表就是这样。  

通过执行 `EXPLAIN SELECT ... ORDER BY`，就知道MySQL是否在查询中使用了索引。如果 `Extra` 字段的值是 `Using filesort`，则说明MySQL无法使用索引。详情请看"[7.2.1 `EXPLAIN` Syntax (Get Information About a `SELECT`)](https://imysql.cn/?q=node/35#EXPLAIN)"。

当必须对结果进行排序时，MySQL 4.1 以前它使用了以下 `filesort` 算法：  

<br />

1. 根据索引键读取记录，或者扫描数据表。那些无法匹配 `WHERE` 分句的记录都会被略过。
2. 在缓冲中每条记录都用一个'对'存储了2个值（索引键及记录指针）。缓冲的大小依据系统变量 `sort_buffer_size` 的值而定。
3. 当缓冲慢了时，就运行 qsort（快速排序）并将结果存储在临时文件中。将存储的块指针保存起来（如果所有的'对'值都能保存在缓冲中，就无需创建临时文件了）。
4. 执行上面的操作，直到所有的记录都读取出来了。
5. 做一次多重合并，将多达 `MERGEBUFF`（7）个区域的块保存在另一个临时文件中。重复这个操作，直到所有在第一个文件的块都放到第二个文件了。
6. 重复以上操作，直到剩余的块数量小于 `MERGEBUFF2` (15)。
7. 在最后一次多重合并时，只有记录的指针（排序索引键的最后部分）写到结果文件中去。
8. 通过读取结果文件中的记录指针来按序读取记录。想要优化这个操作，MySQL将记录指针读取放到一个大的块里，并且使用它来按序读取记录，将记录放到缓冲中。缓冲的大小由系统变量 `read_rnd_buffer_size` 的值而定。这个步骤的代码在源文件 \`sql/records.cc' 中。  

这个逼近算法的一个问题是，数据库读取了2次记录：一次是估算 `WHERE` 分句时，第二次是排序时。尽管第一次都成功读取记录了（例如，做了一次全表扫描），第二次是随机的读取（索引键已经排好序了，但是记录并没有）。

在MySQL 4.1 及更新版本中，`filesort` 优化算法用于记录中不只包括索引键值和记录的位置，还包括查询中要求的字段。这么做避免了需要2次读取记录。改进的 `filesort` 算法做法大致如下：  

1. 跟以前一样，读取匹配 `WHERE` 分句的记录。
2. 相对于每个记录，都记录了一个对应的；'元组'信息信息，包括索引键值、记录位置、以及查询中所需要的所有字段。
3. 根据索引键对'元组'信息进行排序。
4. 按序读取记录，不过是从已经排序过的'元组'列表中读取记录，而非从数据表中再读取一次。  

使用改进后的 `filesort` 算法相比原来的，'元组'比'对'需要占用更长的空间，它们很少正好适合放在排序缓冲中（缓冲的大小是由 `sort_buffer_size` 的值决定的）。因此，这就可能需要有更多的I/O操作，导致改进的算法更慢。为了避免使之变慢，这种优化方法只用于排序'元组'中额外的字段的大小总和超过系统变量 `max_length_for_sort_data` 的情况（这个变量的值设置太高的一个表象就是高磁盘负载低CPU负载）。

想要提高 `ORDER BY` 的速度，首先要看MySQL能否使用索引而非额外的排序过程。如果不能使用索引，可以试着遵循以下策略：  

<br />

* 增加 `sort_buffer_size` 的值。
* 增加 `read_rnd_buffer_size` 的值。
* 修改 `tmpdir`，让它指向一个有很多剩余空间的专用文件系统。如果使用MySQL 4.1或更新，这个选项允许有多个路径用循环的格式。各个路径之间在 Unix 上用冒号（':'）分隔开来，在 Windows，NetWare以及OS/2 上用分号（';'）。可以利用这个特性将负载平均分摊给几个目录。注意：这些路径必须是分布在不同物理磁盘上的目录，而非在同一个物理磁盘上的不同目录。  

默认情况下，MySQL也会对所有的 `GROUP BY `<var>col1</var>`, `<var>col2</var>`, ...` 查询做排序，跟 `ORDER BY `<var>col1</var>`, `<var>col2</var>`, ...` 查询一样。如果显式地包含一个有同样字段列表的 `ORDER BY` 分句，MySQL优化它的时候并不会损失速度，因为排序总是会发生。如果一个查询中包括 `GROUP BY`，但是想要避免对结果排序的开销，可以通过使用 `ORDER BY NULL` 来取消排序。例如：

```
INSERT INTO foo
SELECT a, COUNT(*) FROM bar GROUP BY a ORDER BY NULL;
```

### 7.2.10 MySQL 如何优化 `LIMIT`

在一些情况下，MySQL在碰到一个使用 `LIMIT `<var>row_count</var> 但没使用 `HAVING`  
的查询时会做不同的处理：

* 如果只是用 `LIMIT` 来取得很少的一些记录， MySQL 有时会使用索引，但是更通常的情况是做一个全表扫描。
* 如果 `LIMIT `<var>row_count</var> 和 `ORDER BY` 一起使用，则MySQL在找到 <var>row_count</var> 条记录后就会停止排序了，而非对整个表进行排序。
* 当 `LIMIT `<var>row_count</var> 和 `DISTINCT` 一起联合起来时，MySQL在找到 <var>row_count</var> 条唯一记录后就不再搜索了。
* 在某些情况下， `GROUP BY` 可以通过按照顺序读取索引键来实现（或者在索引键上做排序）并且计算累计信息直到索引键改变了。在这种情况下，`LIMIT `<var>row_count</var> 不会计算任何非必须的 `GROUP BY` 值。
* 一旦MySQL将请求的记录全数发送给客户端后，它就中止查询除非使用了 `SQL_CALC_FOUND_ROWS`。
* `LIMIT 0 ` 总是返回一个空的结果集。这对于检查查询或者取得结果字段的类型非常有用。
* 当服务器使用临时表来处理查询，则 `LIMIT `<var>row_count</var> 可以用来计算需要多少空间。  

<br />

### 7.2.11 如何避免全表扫描

如果MySQL需要做一次全表扫描来处理查询时，在 `EXPLAIN` 的结果中 `type` 字段的值是 `ALL`。在以下几种条件下，MySQL就会做全表扫描：

* 数据表是在太小了，做一次全表扫描比做索引键的查找来得快多了。当表的记录总数小于10且记录长度比较短时通常这么做。
* 没有合适用于 `ON` 或 `WHERE` 分句的索引字段。
* 让索引字段和常量值比较，MySQL已经计算（基于索引树）到常量覆盖了数据表的很大部分，因此做全表扫描应该会来得更快。详情请看"[7.2.4 How MySQL Optimizes `WHERE` Clauses](https://imysql.cn/?q=node/36#Where_optimizations)"。
* 通过其他字段使用了一个基数很小（很多记录匹配索引键值）的索引键。这种情况下，MySQL认为使用索引键需要大量查找，还不如全表扫描来得更快。  

对于小表来说，全表扫描通常更合适。但是对大表来说，尝试使用以下技术来避免让优化程序错误地选择全表扫描：

* 执行 `ANALYZE TABLE `<var>tbl_name</var> 更新要扫描的表的索引键分布。详情请看"14.5.2.1 `ANALYZE TABLE` Syntax"。
* 使用 `FORCE INDEX` 告诉MySQL，做全表扫描的话会比利用给定的索引更浪费资源。详情请看"14.1.7 `SELECT` Syntax"。

  ```
  SELECT * FROM t1, t2 FORCE INDEX (index_for_column)
  WHERE t1.col_name=t2.col_name;
  ```

* 启动 `mysqld` 时使用参数 `--max-seeks-for-key=1000` 或者执行 `SET max_seeks_for_key=1000` 来告诉优化程序，所有的索引都不会导致超过1000次的索引搜索。请查看章节"5.2.3 Server System Variables"。  

<br />

### 7.2.12 加速 `INSERT`

插入一条记录花费的时间由以下几个因素决定，后面的数字大致表示影响的比例：

* 连接：（3）
* 发送查询给服务器：（2）
* 解析查询：（2）
* 插入记录：（1 x 记录大小）
* 插入索引：（1 x 索引数量）
* 关闭：（1）  

这里并没有考虑初始化时打开数据表的开销，因为每次运行查询只会做这么一次。

如果是 B-tree 索引的话，随着索引数量的增加，插入记录的速度以 log N 的比例下降。

可以使用以下几种方法来提高插入速度：  

* 如果要在同一个客户端在同一时间内插入很多记录，可以使用 `INSERT` 语句附带有多个 `VALUES` 值。这种做法比使用单一值的 `INSERT` 语句快多了（在一些情况下比较快）。如果是往一个非空的数据表里增加记录，可以调整变量 `bulk_insert_buffer_size` 的值使之更快。详情请看"5.2.3 Server System Variables"。
* 如果要从不同的客户端中插入大量记录，使用 `INSERT DELAYED` 语句也可以提高速度。详情请看"14.1.4 `INSERT` Syntax"。
* 对 `MyISAM` 而言，可以在 `SELECT` 语句正在运行时插入记录，只要这时候没有正在删除记录。
* 想要将一个文本文件加载到数据表中，可以使用 `LOAD DATA INFILE`。这通常是使用大量 `INSERT` 语句的20倍。详情请看"14.1.5 `LOAD DATA INFILE` Syntax"。
* 通过一些额外的工作，就可能让 `LOAD DATA INFILE` 在数据表有大量索引的情况下运行的更快。步骤如下：  
  1. 用 `CREATE TABLE` 随便创建一个表。
  2. 执行 `FLUSH TABLES` 语句或 `mysqladmin flush-tables` 命令。
  3. 执行 `myisamchk --keys-used=0 -rq `<var>/path/to/db/tbl_name</var> 命令，删掉数据表的所有索引。
  4. 执行 `LOAD DATA INFILE`，数据插入到表中，由于无需更新表索引，因此这将非常快。
  5. 如果将来只是读取改表，运行 `myisampack` 让数据表变得更小点。详情查看"15.1.3.3 Compressed Table Characteristics"。
  6. 运行 `myisamchk -r -q `<var>/path/to/db/tbl_name</var> 重建索引。创建的索引树在写入磁盘前先保存在内存中，这省去了磁盘搜索，因此速度快多了。重建后的索引树分布非常均衡。  
  7. 执行 `FLUSH TABLES` 语句或 `mysqladmin flush-tables` 命令。  

  <br />

  注意，`LOAD DATA INFILE` 将数据插入一个空表时，也会做前接优化；主要的不同在于：运行 `myisamchk` 会分配更多的临时内存用于创建索引，而执行 `LOAD DATA INFILE` 命令则是让数据库服务器分配内存用于重建索引。从 MySQL 4.0 起，可以运行 `ALTER TABLE `<var>tbl_name</var>` DISABLE KEYS` 来代替 `myisamchk --keys-used=0 -rq `<var>/path/to/db/tbl_name</var>，运行 `ALTER TABLE `<var>tbl_name</var>` ENABLE KEYS` 代替 `myisamchk -r -q `<var>/path/to/db/tbl_name</var>。这么做就可以省去 `FLUSH TABLES` 步骤。
* 可以在锁表后，一起执行几个语句来加速 `INSERT` 操作：

  ```
  LOCK TABLES a WRITE;
  INSERT INTO a VALUES (1,23),(2,34),(4,33);
  INSERT INTO a VALUES (8,26),(6,29);
  UNLOCK TABLES;
  ```

  这对性能提高的好处在于：直到所有的 `INSERT` 语句都完成之后，索引缓存一次性刷新到磁盘中。通常情况是，多有少次 `INSERT` 语句就会有多数次索引缓存刷新到磁盘中的开销。如果能在一个语句中一次性插入多个值的话，显示的锁表操作也就没必要了。对事务表而言，用 `BEGIN/COMMIT` 代替 `LOCK TABLES` 来提高速度。锁表也回降低多次连接测试的总时间，尽管每个独立连接为了等待锁的最大等待时间也会增加。例如：

  ```
  Connection 1 does 1000 inserts
  Connections 2, 3, and 4 do 1 insert
  Connection 5 does 1000 inserts
  ```

  如果没有锁表，则连接2，3，4会在1，5之前就做完了。如果锁表了，则连接2，3，4可能在1，5之后才能完成，但是总时间可能只需要40%。MySQL的 `INSERT`, `UPDATE`, `DELETE` 操作都非常快，不过在一个语句中如果有超过5个插入或者更新时最好加锁以得到更好的性能。如果要一次性做很多个插入，最好是在每个循环（大约1000次）的前后加上 `LOCK TABLES` 和 `UNLOCK TABLES`，从而让其他进程也能访问数据表;这么做性能依然不错。`INSERT` 总是比 `LOAD DATA INFILE` 插入数据来得慢，因为二者的实现策略有着分明的不同。  
* 想要让 `MyISAM` 表更快，在 `LOAD DATA`  
  ` INFILE` 和 `INSERT` 时都可以增加系统变量 `key_buffer_size` 的值，详情请看"[7.5.2 Tuning Server Parameters](https://imysql.cn/?q=node/49#Server_parameters)"。  

<br />

### 7.2.13 加速 `UPDATE`

`UPDATE` 语句的优化和 `SELECT` 一样，只不过它多了额外的写入开销。写入的开销取决于要更新的记录数以及索引数。如果索引没有发生变化，则就无需更新。

另一个提高更新速度的办法是推迟更新并且把很多次更新放在后面一起做。如果锁表了，那么同时做很多次更新比分别做更新来得快多了。

注意，如果是在 `MyISAM` 表中使用了动态的记录格式，那么记录被更新为更长之后就可能会被拆分。如果经常做这个，那么偶尔做一次 `OPTIMIZE TABLE` 就显得非常重要了。详情请看"14.5.2.5 OPTIMIZE TABLE Syntax"。

### 7.2.14 加速 `DELETE`

删除单个记录的时间和它的索引个数几乎成正比。想更快地删除记录，可以增加索引键的缓存。详情请看"[7.5.2 Tuning Server Parameters](https://imysql.cn/?q=node/49#Server_parameters)"。

如果想要删除数据表的所有记录，请使用 `TRUNCATE TABLE `*tbl_name* 而不是 `DELETE FROM `*tbl_name*。详情请看"14.1.9 TRUNCATE Syntax"。

### 7.2.15 其他优化点子

本章节列出了一些改善查询处理速度的其他点子：  

<br />

* 使用永久连接到数据库，避免连接的开销。如果需要初始化很多连接，而又不能用永久连接，那么可以修改变量 `thread_cache_size` 的值，详情请看"[7.5.2 Tuning Server Parameters](https://imysql.cn/?q=node/49#Server_parameters)"。
* 总是检查查询是否利用了表中已有的索引。在MySQL中，可以用 `EXPLAIN` 语句来分析。详情请看"[7.2.1 EXPLAIN Syntax (Get Information About a SELECT)](https://imysql.cn/?q=node/35#EXPLAIN)"。
* 尽量不要在经常需要更新的 `MyISAM` 表上用太过复杂的 `SELECT` 语句，这是为了避免在读和写之间争夺锁。
* 在 `MyISAM` 表中，如果没有正在删除记录，则可以在其他查询正在读取数据的同时插入记录。如果这种情况十分重要，那么就要尽量在表没有删除记录时才使用表。另一个可能的办法就是在删除一大堆记录之后执行 `OPTIMIZE TABLE` 语句。
* 如果总是需要按照 `expr1, expr2, ...` 的顺序取得记录，那么请使用 `ALTER TABLE ... ORDER BY expr1, expr2, ...` 修改表。通过这种方法扩充修改表之后，就可能获得更高的性能表现。
* 在一些情况下，让一个字段类型是 \`\`hashed\`\` ，它基于其他字段信息。如果这个字段比较短而且基本上都是唯一值的话，那么就可能会比在几个字段上使用一个大索引来得更快，很简单的就能使用这样的额外字段，如下：

  ```
  SELECT * FROM tbl_name WHERE hash_col=MD5(CONCAT(col1,col2))
  		AND col1='constant' AND col2='constant';
  ```

* 如果 `MyISAM` 表经常大量修改，那么要尽量避免修改所有的变长字段（`VARCHAR, BLOB，TEXT`）。尽管表中只有一个变长字段，它也会采用动态记录格式的。详情请看"15 MySQL Storage Engines and Table Types"。
* 通常情况下，当数据表记录变 \`\`大\`\` 之后，将表拆分成几个不同的表并没有多大用处。访问一条记录是最大的性能点在于磁盘搜索时找到记录的第一个字节上。只要找到记录的位置后，现在的大部分磁盘对于大部分的应用程序来说都能很快的读取到记录。将 `MyISAM` 表拆分成多个唯一有关系的情况是，数据表中动态格式的字段（见上）就可以被修改成固定大小的记录，或者需要频繁的扫描表，但是却不需要读取出大部分的字段。详情请看"15 MySQL Storage Engines and Table Types"。
* 如果需要频繁的对一个表做基于很多字段信息的统计信息的话，那么可能新建一个表来存储这些实时更新的统计结果会更好。类似下面的更新就会非常快了：

  ```
  UPDATE tbl_name SET count_col=count_col+1 WHERE key_col=constant;
  ```

  如果只需要表级锁（多个读/一个写），那么采用 `MyISAM` 存储引擎就非常重要了，例如 `MyISAM` 和 `ISAM` 表。这在很多的数据库中也会有不错的性能表现，因为行级锁管理程序在这种情况下也基本上没什么用。
* 如果需要从很大的日志表中搜集统计信息的话，可以用摘要表来代替扫描整个日志表。维护摘要表比保持 \`\`实时\`\` 的统计信息来得更快。当事情发生变化时（比如商业决策），重新建里摘要表比修改运营中的应用程序快多了。
* 如果可能，最好是分类报告 \`\`实时\`\` 还是 \`\`统计\`\` 的，报告所需要的数据只需要来自摘要表，摘要表的信息则是周期的从实时数据中产生。
* 应该认识到一个优点就是字段有默认值。当要插入的值和默认值不一致时才需要明确指定。这就省去了MySQL需要来提高插入速度这步了。
* 在一些情况下，将数据组装存储在 `BLOB` 类型字段中更方便。那么在应用程序中就需要增加额外的命令来组装和拆开 `BLOB` 字段中的值，不过这么做在一些时候就可以节省很多存储开销。这在数据无需遵从 `记录-和-字段` 格式的表结构是很实用。
* 通常地，应该保存所有的冗余数据（在数据库原理中叫做"第三范式"）。然而，为了能取得更高的效率复制一些信息或者创建摘要表也是划算的。
* 存储过程或者 `UDFs`（用户定义函数） 的方式在执行一些任务时可能性能更高。尽管如此，当数据库不支持这些特性时，还是有其他的替代方法可以达到目的，即使它们有点慢。
* 可以从查询缓存或应答中取得结果，然后将很多次的插入及更新操作放在一起做。如果数据库支持表锁（如MySQL和ORACLE），那么这就可以确保索引缓存在所有的更新操作之后只需要刷新一次。
* 当不需要直到数据什么时候写入表中时，可以用 `INSERT DELAYED`。这就会提高速度，因为多条记录同时在一起做一次磁盘写入操作。  
* 当想让 `SELECT` 语句的优先级比插入操作还高时，用 `INSERT LOW_PRIORITY`。
* 用 `SELECT HIGH_PRIORITY` 来使检索记录跳过队列，也就是说即使有其他客户端正要写入数据，也会先让 `SELECT` 执行完。
* 在一条 `INSERT` 语句中采用多重记录插入格式（很多数据库都支持）。
* 用 `LOAD DATA INFILE` 来导入大量数据，这比 `INSERT` 快。
* 用 `AUTO_INCREMENT` 字段来生成唯一值。
* 定期执行 `OPTIMIZE TABLE` 防止使用动态记录格式的 `MyISAM` 表产生碎片。详情请看"15.1.3 `MyISAM` Table Storage Formats"。
* 采用 `HEAP` 表，它可能会提高速度。详情请看"15.1.3 `MyISAM` Table Storage Formats"。
* 正常的WEB服务器配置中，图片文件最好以文件方式存储，只在数据库中保存文件的索引信息。这么做的原因是，通常情况下WEB服务器对于文件的缓存总是做的比数据库来得好，因此使用文件存储会让系统更容易变得更快。
* 对于频繁访问的不是很重要的数据，可以保存在内存表中，例如对那些web客户端不能保存cookies时用于保存最后一次显示的标题等信息。
* 在不同表中值相同的字段应该将它们声明为一样的类型。在 MySQL 3.23 之前，不这么做的话在表连接时就会比较慢。让字段名尽可能简单，例如，在一个叫做 `customer` 的表中，用 `name` 来代替 `customer_name` 作为字段名。为了让字段名在其他数据库系统中也能移植，应该保持在18个字符长度以内。
* 如果需要真正的高速，建议看看各种数据库服务器支持的底层数据存储接口之间的区别。例如，通过直接访问MySQL的 `MyISAM` 存储引擎，会比通过其他的SQL接口快2-5倍。这要求数据必须和应用程序在同一个服务器上，并且它通常只被一个进程访问（因为外部文件锁确实慢）。只用一个进程就可以消除在MySQL服务器上引入底层的 `MyISAM` 指令引发的问题了（这容易获得更高性能，如果需要的话）。由于数据库接口设计的比较细心，就很容易支持这种优化方式了。
* 如果使用数字型数据的话，在很多情况下想要访问数据库（使用在线连接）的信息会比采用文本文件来得快。由于数字型信息相比文本文件在数据库中存储的更加紧凑，因此访问时只需要更少的磁盘搜索。而且在应用程序中也可以节省代码，因为无需解析文本文件以找到对应的行和字段。
* 数据库复制对一些操作会有性能上的益处。可以将客户端从多个复制服务器上取得数据，这就能将负载分摊了。为了避免备份数据时会让主服务器变慢，还可以将备份放在从服务器上。详情请看"6 Replication in MySQL"。
* 定义 `MyISAM` 表时增加选项 `DELAY_KEY_WRITE=1`，这样的话就会另索引更新更快，因为只有等到数据表关闭了才会刷新磁盘。不过缺点是可能会在数据表还打开时服务器被杀死，可以使用参数 `--myisam-recover` 来保证数据的安全，或者在数据库重启前运行 `myisamchk` 命令（尽管如此，在这种情况下，使用 `DELAY_KEY_WRITE` 的话也不会丢失任何东西，因为索引总是可以从数据中重新生成）。  

<br />

<br />

[跳转到 Cubox 查看](https://cubox.pro/my/card?id=7164614891540580088)
