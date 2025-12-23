基于之前的 IO 性能测试基础，这里提供 **生产环境常用的 FIO 测试脚本集合**（覆盖数据库、存储备份、小文件等核心场景），包含详细参数说明、结果解读和运维实践，可直接复制执行并归档测试报告。


## 一、FIO 核心测试脚本（按场景分类）
### 场景 1：数据库场景（MySQL/Neo4j 等，随机读写为主）
模拟数据库的 4K 小块随机读写（事务日志、数据页读写），重点关注 IOPS 和延迟。
```bash
#!/bin/bash
# 数据库场景 FIO 测试脚本（随机读写+顺序日志写入）
TEST_DIR="/data/io_test"  # 目标测试磁盘目录（需提前创建）
TEST_SIZE="20G"           # 测试文件大小（建议 ≥ 内存大小，避免缓存干扰）
RUNTIME="600"             # 测试时长（10分钟，确保稳定）
IO_DEPTH="32"             # IO 队列深度（高并发场景，默认 32）
THREADS="4"               # 并发线程数（对应数据库连接数）
REPORT_FILE="/var/log/fio_db_test_$(date +%Y%m%d).log"

# 创建测试目录（若不存在）
mkdir -p $TEST_DIR
cd $TEST_DIR || exit 1

# 1. 随机读测试（模拟数据库查询，4K 块）
fio --name=db_randread \
    --directory=$TEST_DIR \
    --size=$TEST_SIZE \
    --rw=randread \
    --bs=4k \
    --iodepth=$IO_DEPTH \
    --runtime=$RUNTIME \
    --group_reporting \
    --direct=1 \
    --ioengine=libaio \
    --iodepth_batch_submit=$IO_DEPTH \
    --iodepth_batch_complete_max=$IO_DEPTH \
    --numjobs=$THREADS \
    --output=$REPORT_FILE \
    --append=1

# 2. 随机写测试（模拟数据库更新/插入，4K 块）
fio --name=db_randwrite \
    --directory=$TEST_DIR \
    --size=$TEST_SIZE \
    --rw=randwrite \
    --bs=4k \
    --iodepth=$IO_DEPTH \
    --runtime=$RUNTIME \
    --group_reporting \
    --direct=1 \
    --ioengine=libaio \
    --iodepth_batch_submit=$IO_DEPTH \
    --iodepth_batch_complete_max=$IO_DEPTH \
    --numjobs=$THREADS \
    --output=$REPORT_FILE \
    --append=1

# 3. 顺序写测试（模拟数据库事务日志，16K 块）
fio --name=db_seqwrite_log \
    --directory=$TEST_DIR \
    --size=$TEST_SIZE \
    --rw=write \
    --bs=16k \
    --iodepth=8 \
    --runtime=$RUNTIME \
    --group_reporting \
    --direct=1 \
    --ioengine=libaio \
    --numjobs=2 \
    --output=$REPORT_FILE \
    --append=1

# 清理测试文件
rm -rf $TEST_DIR/*
echo "测试完成，报告文件：$REPORT_FILE"
```


### 场景 2：存储备份/恢复场景（顺序读写为主）
模拟大文件传输（如 MySQL 物理备份、Neo4j dump 文件复制），重点关注顺序读写带宽。
```bash
#!/bin/bash
# 备份恢复场景 FIO 测试脚本（大文件顺序读写）
TEST_DIR="/data/io_test"
TEST_SIZE="100G"  # 大文件测试（模拟备份文件）
RUNTIME="300"     # 5分钟
REPORT_FILE="/var/log/fio_backup_test_$(date +%Y%m%d).log"

mkdir -p $TEST_DIR
cd $TEST_DIR || exit 1

# 1. 顺序写测试（模拟备份写入，1G 块大小）
fio --name=backup_seqwrite \
    --directory=$TEST_DIR \
    --size=$TEST_SIZE \
    --rw=write \
    --bs=1G \
    --iodepth=4 \
    --runtime=$RUNTIME \
    --group_reporting \
    --direct=1 \
    --ioengine=libaio \
    --output=$REPORT_FILE \
    --append=1

# 2. 顺序读测试（模拟备份恢复，1G 块大小）
fio --name=restore_seqread \
    --directory=$TEST_DIR \
    --size=$TEST_SIZE \
    --rw=read \
    --bs=1G \
    --iodepth=4 \
    --runtime=$RUNTIME \
    --group_reporting \
    --direct=1 \
    --ioengine=libaio \
    --output=$REPORT_FILE \
    --append=1

rm -rf $TEST_DIR/*
echo "测试完成，报告文件：$REPORT_FILE"
```


### 场景 3：小文件场景（日志/缓存文件，大量小 IO）
模拟大量小文件读写（如应用日志写入、Redis 缓存更新），重点关注小块 IO 性能。
```bash
#!/bin/bash
# 小文件场景 FIO 测试脚本（1K 块随机读写）
TEST_DIR="/data/io_test"
TEST_SIZE="10G"    # 总数据量
RUNTIME="600"      # 10分钟
IO_DEPTH="64"      # 高队列深度（小文件 IO 并发高）
THREADS="8"        # 多线程
REPORT_FILE="/var/log/fio_smallfile_test_$(date +%Y%m%d).log"

mkdir -p $TEST_DIR
cd $TEST_DIR || exit 1

fio --name=smallfile_randrw \
    --directory=$TEST_DIR \
    --size=$TEST_SIZE \
    --rw=randrw \
    --rwmixread=70 \  # 70% 读，30% 写（读多写少）
    --bs=1k \
    --iodepth=$IO_DEPTH \
    --runtime=$RUNTIME \
    --group_reporting \
    --direct=1 \
    --ioengine=libaio \
    --numjobs=$THREADS \
    --nrfiles=10000 \  # 生成 10000 个小文件
    --output=$REPORT_FILE \
    --append=1

rm -rf $TEST_DIR/*
echo "测试完成，报告文件：$REPORT_FILE"
```


## 二、FIO 关键参数说明（必懂）
| 参数                | 作用                                                                 |
|---------------------|----------------------------------------------------------------------|
| `--name`            | 测试任务名称（用于区分不同测试）                                     |
| `--directory`       | 测试文件存放目录（必须在目标磁盘上，避免 tmpfs 内存文件系统）         |
| `--size`            | 单个测试文件大小（总大小=size×numjobs）                              |
| `--rw`              | IO 模式：`randread`（随机读）、`randwrite`（随机写）、`randrw`（混合）、`read`（顺序读）、`write`（顺序写） |
| `--rwmixread`       | 混合模式下读比例（如 70 表示 70% 读，30% 写）                        |
| `--bs`              | IO 块大小：数据库常用 4k/8k，备份常用 1G/2G，小文件常用 1k           |
| `--iodepth`         | IO 队列深度（并发 IO 请求数，高并发场景设 32-64，普通场景设 4-8）     |
| `--direct=1`        | 直接 IO（跳过操作系统缓存，模拟数据库/存储的真实场景）                |
| `--ioengine=libaio` | IO 引擎（Linux 推荐 libaio，支持异步 IO）                            |
| `--numjobs`         | 并发线程数（模拟多进程/多连接场景）                                  |
| `--runtime`         | 测试时长（秒，避免测试过久，建议 300-600 秒）                        |
| `--group_reporting` | 按组汇总结果（多个线程合并为一个报告，简洁易读）                     |
| `--nrfiles`         | 小文件场景专用：生成的小文件数量                                     |


## 三、测试结果解读（重点关注 5 个指标）
以数据库场景的随机读测试结果为例：
```
db_randread: (g=0): rw=randread, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=32
...
READ: bw=128.5MB/s (134.7MB/s), 128.5MB/s-128.5MB/s (134.7MB/s-134.7MB/s), io=77100MB (80846MB), run=600001-600001msec
slat (usec): min=2, max=123, avg= 4.28, stdev= 2.15
clat (usec): min=10, max=289, avg=98.76, stdev=15.32
lat (usec): min=15, max=295, avg=103.04, stdev=15.45
iops=32120, bw=128.5MB/s
```

### 核心指标解读：
1. **iops**：每秒 IO 操作数（数据库场景核心指标）
   - 含义：每秒完成的 IO 请求次数，越高越好；
   - 基准：SATA SSD ≥ 10000，NVMe SSD ≥ 50000，HDD ≥ 200。

2. **bw**：IO 带宽（顺序读写场景核心指标）
   - 含义：每秒传输的数据量（MB/s）；
   - 基准：SATA SSD ≥ 500MB/s，NVMe SSD ≥ 1GB/s，HDD ≥ 100MB/s。

3. **clat**：完成延迟（关键延迟指标）
   - 含义：IO 请求从提交到完成的时间（单位 usec/ms）；
   - 基准：avg（平均延迟）< 1ms（优秀），< 10ms（良好），> 50ms（存在瓶颈）。

4. **lat**：总延迟（包含提交延迟+完成延迟）
   - 含义：从发起 IO 请求到最终完成的总时间，需 < 100ms。

5. **%util**：磁盘利用率（隐含指标，需结合 `iostat` 查看）
   - 含义：测试期间磁盘的繁忙程度；
   - 基准：< 80%（正常），≥ 90%（磁盘满负荷，IO 瓶颈）。


## 四、运维实践建议（避坑+优化）
### 1. 测试前必做准备
- 「目录校验」：确保 `TEST_DIR` 在目标磁盘（如 `/data` 挂载在 `/dev/vdb1`），执行 `df -h $TEST_DIR` 验证；
- 「服务停止」：停止测试磁盘上的业务服务（数据库、备份脚本），避免 IO 干扰；
- 「内存规避」：测试文件大小 ≥ 内存大小（如 16GB 内存用 20GB 测试文件），避免缓存导致结果失真。

### 2. 常见问题排查
- 「IOPS 低但 %util 100%」：磁盘性能达到上限，需升级存储（HDD→SSD）；
- 「延迟高但 IOPS/带宽低」：可能是 IO 队列深度设置过小，调整 `--iodepth=64` 重试；
- 「测试结果波动大」：延长测试时长（如 `--runtime=1200`），或关闭系统 swap（`swapoff -a`）。

### 3. 自动化巡检（定期验证 IO 性能）
将测试脚本添加到 crontab，每月执行一次，对比历史数据：
```bash
# 编辑定时任务
crontab -e

# 添加：每月 1 号凌晨 2 点执行数据库场景测试
0 2 1 * * /root/scripts/fio_db_test.sh >> /var/log/fio_cron.log 2>&1
```


## 五、快速执行命令（无需脚本，直接测试）
若只需快速验证某类性能，可直接执行单条 FIO 命令：
```bash
# 快速测试随机读 IOPS（4K 块，32 队列，10G 大小，5分钟）
fio --name=quick_randread --directory=/data/io_test --size=10G --rw=randread --bs=4k --iodepth=32 --runtime=300 --group_reporting --direct=1 --ioengine=libaio

# 快速测试顺序写带宽（1G 块，100G 大小，5分钟）
fio --name=quick_seqwrite --directory=/data/io_test --size=100G --rw=write --bs=1G --iodepth=4 --runtime=300 --group_reporting --direct=1 --ioengine=libaio
```

通过以上脚本和解读，可全面覆盖运维工作中常见的 IO 性能测试场景，快速定位存储瓶颈，为数据库调优、存储升级提供数据支撑。测试报告建议按日期归档，便于后续性能对比分析。