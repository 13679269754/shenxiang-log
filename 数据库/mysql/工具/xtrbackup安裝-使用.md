| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2025-3月-19 | 2025-3月-19 |
| ... | ... | ... |
---
# xtrbackup 安裝

[toc]


## xtrabackup
```bash
    wget https://www.percona.com/downloads/Percona-XtraBackup-innovative-release/Percona-XtraBackup-8.3.0-1/binary/redhat/7/x86_64/percona-xtrabackup-83-8.3.0-1.1.el7.x86_64.rpm
    yum localinstall percona-xtrabackup-83-8.3.0-1.1.el7.x86_64.rpm -y
```

## qpress
``` bash
    yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
    yum -y install qpress
```

## 全量压缩备份
```bash
    ts '%Y-%m-%d %H:%M:%S'  |xtrabackup --use-memory=64G --host=10.159.65.152 --user=dzjbackup --password=PiZg0yT7IhnohSde --backup --target-dir=/usr/local/data/mysql_backup/20250115_02_00_05/2025_01_15_02_00_05  --datadir=/usr/local/data/mysql_data/db3106/data --socket=/usr/local/data/mysql_data/db3106/run/mysql3106.sock --port=3106 --compress-threads=10 --compress 
```

## 恢复全量压缩备份

解压缩
```bash 
    xtrabackup --decompress --parallel=5 --target-dir=/root/20250225_02_00_05/2025_02_25_02_00_05 --remove-original
```
--remove-original 不保留压缩文件

prepare
```bash
    xtrabackup --prepare --use-memory=64G --target-dir=./ 
```

将prepare后的文件作为mysql数据目录即可
```bash
    xtrabackup --defaults-file=/path/to/my.cnf --copy-back --target-dir=/path/to/backup 
```


## 安装8.0.34版本时提示依赖zstd

CENTOS 7 已经没有zstd 包处理方法：
[xtrabackup8.0.34 安装依赖zstd .md](<xtrabackup8.0.34 安装依赖zstd .md>)