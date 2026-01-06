
## 报错

### 报错提示1

```bash
2025-12-04 14:08:27 23937 [Note] Plugin 'FEDERATED' is disabled.
2025-12-04 14:08:27 23937 [Warning] option 'innodb-thread-concurrency': unsigned value 1024 adjusted to 1000
2025-12-04 14:08:27 23937 [Note] InnoDB: Using atomics to ref count buffer pool pages
2025-12-04 14:08:27 23937 [Note] InnoDB: The InnoDB memory heap is disabled
2025-12-04 14:08:27 23937 [Note] InnoDB: Mutexes and rw_locks use GCC atomic builtins
2025-12-04 14:08:27 23937 [Note] InnoDB: Memory barrier is not used
2025-12-04 14:08:27 23937 [Note] InnoDB: Compressed tables use zlib 1.2.11
2025-12-04 14:08:27 23937 [Note] InnoDB: Using Linux native AIO
2025-12-04 14:08:27 23937 [Note] InnoDB: Using CPU crc32 instructions
2025-12-04 14:08:27 23937 [Note] InnoDB: Initializing buffer pool, size = 32.0G
2025-12-04 14:08:28 23937 [Note] InnoDB: Completed initialization of buffer pool
InnoDB: Error: ib_logfiles are too small for innodb_thread_concurrency 1000.

```

### 报错提示2
```bash
2025-12-04 14:21:13 5114 [Note] Plugin 'FEDERATED' is disabled.
2025-12-04 14:21:13 5114 [Note] InnoDB: Using atomics to ref count buffer pool pages
2025-12-04 14:21:13 5114 [Note] InnoDB: The InnoDB memory heap is disabled
2025-12-04 14:21:13 5114 [Note] InnoDB: Mutexes and rw_locks use GCC atomic builtins
2025-12-04 14:21:13 5114 [Note] InnoDB: Memory barrier is not used
2025-12-04 14:21:13 5114 [Note] InnoDB: Compressed tables use zlib 1.2.11
2025-12-04 14:21:13 5114 [Note] InnoDB: Using Linux native AIO
2025-12-04 14:21:13 5114 [Note] InnoDB: Using CPU crc32 instructions
2025-12-04 14:21:13 5114 [Note] InnoDB: Initializing buffer pool, size = 32.0G
2025-12-04 14:21:15 5114 [Note] InnoDB: Completed initialization of buffer pool
2025-12-04 14:21:15 5114 [Note] InnoDB: Highest supported file format is Barracuda.
2025-12-04 14:21:18 5114 [Note] InnoDB: 128 rollback segment(s) are active.
2025-12-04 14:21:18 5114 [Note] InnoDB: Waiting for purge to start
2025-12-04 14:21:18 5114 [Note] InnoDB: 5.6.50 started; log sequence number 5448372171495
/home/localssd_2025_12_4/3306/bin/mysqld: File '/home/localssd/3306/logs/bin_log.012758' not found (Errcode: 2 - No such file or directory)
2025-12-04 14:21:18 5114 [ERROR] Failed to open log (file '/home/localssd/3306/logs/bin_log.012758', errno 2)
2025-12-04 14:21:18 5114 [ERROR] Could not open log file
2025-12-04 14:21:18 5114 [ERROR] Can't init tc log
2025-12-04 14:21:18 5114 [ERROR] Aborting

```
## 迁移数据目录流程

1. 数据目录迁移
```
rsync -av --progress --bwlimit=100M --remove-source-files /home/localssd/ /home/localssd_2025_12_4/
```

2. 修改配置文件
MySQL 启动时会按以下顺序加载配置文件（先加载的配置会被后加载的覆盖）

| 路径                          | 优先级 | 适用场景                     |
|-------------------------------|--------|------------------------------|
| `/etc/my.cnf`                 | 最高   | CentOS/RHEL 系统默认（yum 安装） |
| `/etc/mysql/my.cnf`           | 次之   | Ubuntu/Debian 系统默认（apt 安装） |
| `/usr/local/mysql/my.cnf`     | 次之   | 源码编译安装的 MySQL（默认路径） |
| `~/.my.cnf`（/root/.my.cnf）  | 次之   | 用户级配置（仅对当前用户生效） |
| `/usr/my.cnf`                 | 最低   | 兼容旧版本的备用路径         |


```bash
sed -i 's#/home/localssd/#/home/localssd_2025_12_4/#g' /home/localssd_2025_12_4/3306/my.cnf

```

3. 修改管理脚本（若采用systemctl管理）
```bash
sed -i 's#/home/localssd/#/home/localssd_2025_12_4/#g' /home/localssd_2025_12_4/3306/support-files/mysql.server
```

4. 启动mysql
```bash
systemctl start mysqld
```

### 报错问题处理

### 问题一
#### 问题处理：
将配置文件中的 innodb_thread_concurrency的设置为0,或者直接注释掉
```
innodb-thread-concurrency=0
```

#### 处理原因

你的核心报错是：`ib_logfiles are too small for innodb_thread_concurrency 1000`（日志文件太小，匹配不上 1000 的并发数）。InnoDB 有个内置校验规则：`ib_logfiles 总大小 > 200KB * innodb_thread_concurrency`

- 当你设为 `1000` 时，要求日志文件总大小 > 200KB_1000=200MB，若你的日志文件总大小不足（比如默认的 5MB_2=10MB），就会报错；
- 当你设为 `0` 时，InnoDB 会**跳过这个校验规则**（因为无需固定并发数），同时引擎会自动适配线程数，既解决了报错，又能最优利用服务器资源。

### 问题二

#### 问题处理
```bash
sed -i 's#/home/localssd/#/home/localssd_2025_12_4/#g' /home/localssd_2025_12_4/3306/logs/mysql-bin.index
```

#### 处理原因

虽然改了配置文件，但 MySQL 启动时仍读取**二进制日志（binlog）的历史记录 / 残留配置**，指向旧路径。