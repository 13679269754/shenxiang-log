在 Linux 中复制文件时，若需限制传输速率（避免占用过多带宽/IO 资源），可通过 **工具自带参数** 或 **第三方工具** 实现。以下是 3 种最常用的限速方案，按易用性和功能完整性排序：


## 一、核心方案：`cp` 结合 `pv` 限速（推荐，无需修改原有习惯）
`pv`（Pipe Viewer）是 Linux 管道流量控制工具，可限制数据传输速率，配合 `cp` 使用时无需改变复制逻辑，仅需在管道中添加限速参数。

### 1. 安装 `pv`
```bash
# CentOS/RHEL
yum install -y pv

# Ubuntu/Debian
apt install -y pv

# 源码安装（若系统无包管理器）
wget https://www.ivarch.com/programs/pv/download/pv-1.6.20.tar.bz2
tar -jxvf pv-1.6.20.tar.bz2 && cd pv-1.6.20
./configure && make && make install
```

### 2. 限速复制用法
#### （1）复制单个文件（限速 100MB/s）
```bash
# 格式：pv -L 限速值 < 源文件 > 目标文件
pv -L 100M < /path/to/source/file.dump > /path/to/target/file.dump
```
- `(-L/--rate-limit)`：指定限速值，支持单位 `K`（KB/s）、`M`（MB/s）、`G`（GB/s），默认单位是字节/秒。
- 示例：备份 Neo4j 数据文件，限速 50MB/s：
  ```bash
  pv -L 50M < /usr/local/data/neo4j-backup/dzj_backup_2025_12_01.dump > /backup/neo4j_backup_copy.dump
  ```

#### （2）复制目录（递归复制，限速 20MB/s）
`cp` 复制目录时需结合 `tar` 打包传输（避免单个文件限速失效），同时保留目录结构和权限：
```bash
# 格式：tar 打包 → pv 限速 → 目标目录解压
tar -cf - /path/to/source/dir | pv -L 20M | tar -xf - -C /path/to/target/dir
```
- 示例：复制 Neo4j 整个数据目录，限速 30MB/s：
  ```bash
  tar -cf - /usr/local/data/neo4j-server | pv -L 30M | tar -xf - -C /data/neo4j-backup/
  ```

#### （3）额外功能：显示复制进度
`pv` 自带进度条、传输速率、剩余时间显示，无需额外参数：
```bash
pv -L 100M -p -t -e < source.dump > target.dump
```
- `-p`：显示进度条；
- `-t`：显示已用时间；
- `-e`：显示剩余时间。


## 二、替代方案：`rsync` 限速复制（支持增量复制，适合大文件/目录）
`rsync` 是 Linux 常用的文件同步工具，自带 `--bwlimit` 参数限速，且支持增量复制（仅复制变化的文件），适合频繁复制或大目录场景。

### 1. 基本用法（限速 50MB/s）
```bash
# 格式：rsync --bwlimit=限速值 源路径 目标路径
rsync -av --bwlimit=50000 /path/to/source/ /path/to/target/
```
- 关键参数：
  - `-a`：归档模式（保留权限、时间戳、递归复制）；
  - `-v`：显示详细信息；
  - `--bwlimit`：限速值（单位：KB/s），需注意与 `pv` 的单位区别！  
    例：限速 50MB/s = 50×1024 = 51200 KB/s，因此参数设为 `--bwlimit=51200`。

### 2. 示例：复制 Neo4j 备份文件（限速 100MB/s）
```bash
rsync -av --bwlimit=102400 /usr/local/data/neo4j-backup/dzj_backup_2025_12_01.dump /backup/
```

### 3. 优势：增量复制
若后续需更新目标文件（仅复制源文件变化的部分），再次执行相同命令即可，无需重新复制整个文件，效率更高。


## 三、原生方案：`cp` 结合 `dd` 限速（无需安装第三方工具）
若系统无法安装 `pv`/`rsync`，可通过 `dd` 命令的 `bs`（块大小）和 `count`（块数）+ 循环实现限速，但操作较繁琐，适合简单场景。

### 原理
通过 `dd` 控制每秒读取/写入的块数，间接限制传输速率：
- `bs=1M`：每次读取 1MB；
- `count=100`：每次读取 100 块（共 100MB）；
- `sleep 1`：每传输 100MB 暂停 1 秒，实现约 100MB/s 限速。

### 用法：复制单个文件（限速 50MB/s）
```bash
# 格式：dd if=源文件 of=目标文件 bs=块大小 count=块数 && sleep 1，循环执行
while true; do
  dd if=/path/to/source/file.dump of=/path/to/target/file.dump bs=1M count=50 oflag=append conv=notrunc
  if [ $? -ne 0 ]; then
    break  # 复制完成或出错时退出循环
  fi
  sleep 1  # 每传输 50MB 暂停 1 秒，限速 ~50MB/s
done
```
- 说明：
  - `oflag=append`：追加写入（避免覆盖已复制内容）；
  - `conv=notrunc`：不截断目标文件；
  - 若需调整速率，修改 `count`（块数）或 `sleep`（暂停时间），例如 `count=20 sleep 1` 对应 ~20MB/s。

### 缺点
- 仅支持单个文件，不支持目录；
- 无进度显示，需通过 `du -sh 目标文件` 手动查看复制进度；
- 速率控制精度较低（受系统 IO 影响）。


## 四、方案对比与选择
| 方案                | 优点                                  | 缺点                                  | 适用场景                          |
|---------------------|---------------------------------------|---------------------------------------|-----------------------------------|
| `cp + pv`           | 易用、支持文件/目录、带进度显示、速率精准 | 需安装 `pv`                           | 大多数场景（推荐首选）            |
| `rsync --bwlimit`   | 支持增量复制、保留权限、无需额外工具（多数系统自带） | 限速单位为 KB/s（需换算）、目录复制无进度条 | 大文件/目录、频繁同步场景         |
| `cp + dd`           | 无需安装第三方工具、原生支持          | 仅支持单个文件、无进度、速率精度低    | 无 `pv`/`rsync` 的受限环境        |


## 五、关键注意事项
1. **单位统一**：
   - `pv -L` 支持 `M`（MB/s）、`K`（KB/s）；
   - `rsync --bwlimit` 单位是 `KB/s`（需换算，例：100MB/s = 102400 KB/s）。
2. **IO 资源占用**：
   - 限速不仅限制网络带宽，还会限制磁盘 IO，适合在生产环境（如数据库服务器）中使用，避免复制操作影响业务。
3. **大文件推荐**：
   - 复制超过 10GB 的大文件（如 Neo4j 备份 dump 文件），优先用 `rsync` 或 `pv`，支持断点续传（`rsync` 再次执行即可续传，`pv` 需结合 `--continue` 参数）。

### 断点续传示例（`pv`）
若复制中断，可通过 `--continue` 恢复：
```bash
pv -L 100M --continue < /path/to/source/file.dump > /path/to/target/file.dump
```