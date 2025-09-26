MySQL 提供了多个参数用于限制或控制 I/O 操作，以避免数据库对系统磁盘 I/O 资源的过度占用，保障系统稳定性和其他进程的资源需求。这些参数主要通过 `my.cnf`（或 `my.ini`）配置，以下是核心参数分类及说明：


### 一、InnoDB 存储引擎 I/O 限制参数
InnoDB 是 MySQL 最常用的存储引擎，其 I/O 控制参数最为丰富，主要针对日志写入、数据刷盘等操作。

#### 1. 日志文件 I/O 限制
- **`innodb_flush_log_at_trx_commit`**  
  控制事务日志（redo log）的刷盘策略，平衡 I/O 性能与数据安全性：  
  - `1`（默认）：每次事务提交时立即将日志刷到磁盘（最安全，I/O 开销最大）；  
  - `0`：每秒批量刷日志到磁盘（性能好，崩溃可能丢失 1 秒内数据）；  
  - `2`：事务提交时仅写入操作系统缓存，由 OS 每秒刷盘（折中方案）。  

- **`innodb_log_buffer_size`**  
  定义日志缓冲区大小（默认 16M），缓冲区满时会自动刷盘。调大此值可减少刷盘频率（适合写密集场景），但需避免占用过多内存。

- **`innodb_log_file_size`**  
  单个 redo log 文件大小（默认 48M），日志文件总大小由 `innodb_log_files_in_group`（默认 2）决定。增大此值可减少日志切换频率（降低 I/O），但会增加崩溃恢复时间。


#### 2. 数据刷盘 I/O 限制
- **`innodb_flush_method`**  
  控制 InnoDB 数据文件和日志文件的刷盘方式，影响 I/O 效率：  
  - `O_DIRECT`（推荐 Linux）：绕过操作系统缓存，直接写入磁盘，减少 double buffer 开销；  
  - `fsync`（默认）：通过 OS 缓存刷盘，适合 I/O 压力小的场景。  

- **`innodb_max_dirty_pages_pct`**  
  控制 InnoDB 缓冲池中脏页（已修改未刷盘）的最大比例（默认 90%），达到阈值后会触发后台刷盘。降低此值（如 70%）可减少突发 I/O 压力，但会增加频繁刷盘的开销。

- **`innodb_max_dirty_pages_pct_lwm`**  
  脏页刷盘的低水位阈值（默认 10%），低于此值时停止后台刷盘，避免不必要的 I/O。

- **`innodb_io_capacity` 和 `innodb_io_capacity_max`**  
  - `innodb_io_capacity`：定义 InnoDB 后台任务（如刷脏页、合并插入缓冲）的 I/O 吞吐量上限（默认 200，单位为 IOPs），需根据磁盘实际性能（如 SSD 可设 10000+）调整；  
  - `innodb_io_capacity_max`：紧急情况下（如脏页比例过高）的最大 I/O 吞吐量（默认 2000），通常设为 `innodb_io_capacity` 的 2~4 倍。


#### 3. 并发 I/O 限制
- **`innodb_read_io_threads` 和 `innodb_write_io_threads`**  
  控制 InnoDB 读写 I/O 的线程数（默认各 4 个），SSD 或高并发场景可适当增加（如 8~16），但需避免线程过多导致调度开销。

- **`innodb_thread_concurrency`**  
  限制 InnoDB 并发线程数（默认 0，即不限制），当 I/O 压力过大时，可设置阈值（如 32）防止线程阻塞。


### 二、MySQL 服务器级 I/O 限制参数
#### 1. 全局 I/O 吞吐量限制
- **`max_write_lock_count`**  
  当写锁累积到指定次数（默认无限制）时，会暂时允许读请求优先执行，避免读操作长期被写锁阻塞导致的 I/O 队列积压。

- **`sync_binlog`**  
  控制二进制日志（binlog）的刷盘策略：  
  - `1`（推荐）：每次事务提交时刷 binlog 到磁盘（安全，I/O 开销大）；  
  - `N`（如 100）：每 N 个事务刷一次盘（性能好，崩溃可能丢失 N 个事务的 binlog）。


#### 2. 连接与查询的 I/O 限制
- **`net_read_timeout` 和 `net_write_timeout`**  
  控制 MySQL 服务器与客户端之间读写数据的超时时间（默认分别为 30 秒和 60 秒），避免慢连接占用 I/O 资源。

- **`max_allowed_packet`**  
  限制单条 SQL 语句或数据行的大小（默认 64M），防止超大请求导致 I/O 峰值。


### 三、操作系统级 I/O 限制（间接影响）
MySQL 的 I/O 行为还受操作系统限制，需配合调整：
1. **文件描述符限制**：通过 `ulimit -n` 增加可用文件描述符（MySQL 会打开大量数据文件、日志文件）；  
2. **磁盘 I/O 调度算法**：Linux 下可将 SSD 磁盘调度算法设为 `noop` 或 `deadline`，机械硬盘设为 `cfq`；  
3. **I/O 优先级**：通过 `ionice` 命令降低 MySQL 进程的 I/O 优先级（如 `ionice -c 2 -n 7 -p $(pidof mysqld)`），避免抢占关键进程资源。


### 四、配置建议
1. **读多写少场景**：  
   调大 `innodb_buffer_pool_size`（占系统内存 50%~70%），减少磁盘读 I/O；设置 `innodb_flush_log_at_trx_commit=2` 降低写日志 I/O。

2. **写密集场景**：  
   增大 `innodb_log_buffer_size`（如 64M）和 `innodb_log_file_size`（如 1G），调整 `innodb_io_capacity` 匹配磁盘性能（SSD 设 10000+）。

3. **I/O 资源紧张的服务器**：  
   降低 `innodb_max_dirty_pages_pct`（如 60%），设置 `sync_binlog=100`，通过 `innodb_io_capacity` 限制后台 I/O 吞吐量。

配置后需重启 MySQL 生效，建议通过 `iostat`、`iotop` 等工具监控 I/O 使用率（如 `%util` 指标应低于 80%），避免磁盘过载。