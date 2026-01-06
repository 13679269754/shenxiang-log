在 MySQL 的 `sys` 系统库中，这些表主要用于监控、诊断数据库性能和状态，方便管理员快速定位问题。以下是其中比较重要的表及其作用：


### **1. 性能监控与瓶颈分析类**
这类表用于追踪数据库的 I/O、 latency（延迟）、资源占用等，是性能调优的核心工具。

- **`host_summary_by_statement_latency` / `x$host_summary_by_statement_latency`**  
  按主机（host）统计 SQL 语句的执行延迟，可快速定位哪个主机的语句耗时最长，便于排查特定来源的性能问题。  
  - 区别：带 `x$` 前缀的表以原始数值（无格式化）存储，适合计算。

- **`io_global_by_file_by_latency` / `x$io_global_by_file_by_latency`**  
  按文件类型统计全局 I/O 延迟，例如数据文件、日志文件的读写耗时，能快速发现 I/O 瓶颈（如是否是日志文件写入过慢）。

- **`statements_with_full_table_scans` / `x$statements_with_full_table_scans`**  
  记录执行了全表扫描的 SQL 语句，全表扫描通常是性能杀手，通过此表可定位需要优化索引的语句。

- **`statements_with_runtimes_in_95th_percentile` / `x$statements_with_runtimes_in_95th_percentile`**  
  统计延迟处于 95 百分位的 SQL 语句，即“少数但耗时极长”的语句，是优化的优先级目标。

- **`wait_classes_global_by_latency` / `x$wait_classes_global_by_latency`**  
  按等待类型（如锁等待、I/O 等待）统计总延迟，帮助判断数据库的主要等待瓶颈（例如是否频繁锁等待）。


### **2. 索引与表结构优化类**
用于发现冗余索引、缺失索引或不合理的表结构，提升查询效率。

- **`schema_redundant_indexes`**  
  识别冗余索引（如与其他索引前缀重复的索引），删除冗余索引可减少写入开销和存储空间。

- **`schema_unused_indexes`**  
  记录未被使用的索引，这些索引不仅占用空间，还会拖慢 INSERT/UPDATE/DELETE 性能，可考虑删除。

- **`schema_index_statistics` / `x$schema_index_statistics`**  
  统计索引的使用频率和效率（如扫描行数、命中次数），帮助判断索引是否合理（例如某索引几乎未被使用，可能需要删除）。

- **`schema_tables_with_full_table_scans`**  
  记录频繁发生全表扫描的表，提示需要为这些表添加合适的索引。


### **3. InnoDB 存储引擎相关**
针对 InnoDB 引擎的缓冲池、锁等待等核心特性的监控。

- **`innodb_buffer_stats_by_table` / `x$innodb_buffer_stats_by_table`**  
  统计每个表在 InnoDB 缓冲池中的占用情况（如数据页、索引页数量），判断缓冲池是否合理利用（例如大表是否被频繁缓存）。

- **`innodb_lock_waits` / `x$innodb_lock_waits`**  
  记录 InnoDB 锁等待事件，包括等待的锁类型、涉及的表和语句，用于排查死锁或长时间锁等待问题。

- **`schema_table_lock_waits`**  
  统计表级锁的等待情况，例如 MyISAM 表的读写锁冲突，或 InnoDB 的表级锁（如 ALTER TABLE 时的锁）。


### **4. 资源占用监控类**
追踪内存、线程、用户/主机的资源消耗，避免资源耗尽。

- **`memory_global_by_current_bytes` / `x$memory_global_by_current_bytes`**  
  按内存分配类型（如连接缓存、排序缓存）统计当前内存占用，判断是否存在内存泄漏或配置不合理（如缓存设置过大）。

- **`memory_by_thread_by_current_bytes` / `x$memory_by_thread_by_current_bytes`**  
  按线程统计内存占用，可定位内存消耗异常的线程（如某个连接占用过多内存）。

- **`host_summary` / `user_summary`**  
  分别按主机和用户统计 SQL 执行次数、错误数、警告数等，便于追踪异常访问（如某主机频繁执行错误语句）。


### **5. 会话与进程监控类**
实时查看数据库当前的连接和进程状态，排查阻塞或异常会话。

- **`processlist` / `x$processlist`**  
  类似 `SHOW PROCESSLIST`，但提供更详细的会话信息（如当前语句、执行时间），可快速发现长时间运行的阻塞进程。

- **`session` / `x$session`**  
  展示当前会话的详细信息，包括事务状态、锁持有情况等，用于诊断会话级别的问题。


### **6. 系统配置与元数据类**
- **`sys_config`**  
  存储 `sys` 库自身的配置参数（如默认单位、监控阈值），可通过修改此表调整 `sys` 库的行为。

- **`version`**  
  记录数据库版本信息，便于确认环境兼容性。


### 总结
使用时可根据需求选择：  
- 性能调优优先看 **`statements_with_*`、`wait_classes_*`、`io_global_*`**；  
- 索引优化优先看 **`schema_redundant_indexes`、`schema_unused_indexes`**；  
- 实时问题排查优先看 **`processlist`、`innodb_lock_waits`**。  
带 `x$` 前缀的表适合直接用于计算（数值未格式化），不带前缀的表则更适合人类阅读（如延迟单位为秒/毫秒）。