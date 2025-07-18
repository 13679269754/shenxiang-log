| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-6月-03 | 2025-6月-03  |
| ... | ... | ... |
---
# crontab 调用命令会报错，手动执行可以

[toc]

## 描述

**报错：**
```bash
2025-06-02 00:11:49 - mysql_auto_restore.py[line:282] - ERROR: Function restore_decompress_db executed failed
2025-06-02 00:11:49 - mysql_auto_restore.py[line:283] - ERROR: 执行 decompress 脚本错误：xtrabackup --decompress --parallel=4 --target-dir=/usr/local/data/mysql_backup/20250601_02_00_01/20250601_02_00_01 --decompress_cmd=/usr/local/bin/zstd -d -q -f --threads=4 2> /usr/local/data/mysql_backup/20250601_02_00_01/20250601_02_00_01/backup_decompress.log
2025-06-02 00:11:49 - connectionpool.py[line:822] - DEBUG: Starting new HTTPS connection (1): qyapi.weixin.qq.com:443
2025-06-02 00:11:49 - connectionpool.py[line:391] - DEBUG: https://qyapi.weixin.qq.com:443 "POST /cgi-bin/webhook/send?key=f1ae1bb0-c7c6-4a58-93c8-1d33d1ffbe3c HTTP/1.1" 200 27
[root@localhost auto_restore_log]# tail -f /usr/local/data/mysql_backup/20250601_02_00_01/20250601_02_00_01/backup_decompress.log
cat: 写入错误: 断开的管道
cat: 写入错误: 断开的管道
sh: zstd: 未找到命令

```

**手动执行：**

```bash
[root@localhost auto_restore_log]# xtrabackup --decompress --parallel=4 --target-dir=/usr/local/data/mysql_backup/20250601_02_00_01/20250601_02_00_01 --decompress_cmd=/usr/local/bin/zstd -d -q -f --threads=4
2025-06-03T11:21:52.243825+08:00 0 [Note] [MY-011825] [Xtrabackup] recognized server arguments: --datadir=/var/lib/mysql
2025-06-03T11:21:52.244305+08:00 0 [Note] [MY-011825] [Xtrabackup] recognized client arguments: --decompress=1 --parallel=4 --target-dir=/usr/local/data/mysql_backup/20250601_02_00_01/20250601_02_00_01
xtrabackup version 8.0.34-29 based on MySQL server 8.0.34 Linux (x86_64) (revision id: 5ba706ee)
2025-06-03T11:21:52.245447+08:00 0 [Note] [MY-011825] [Xtrabackup] decompressing ./xtrabackup_info.zst
2025-06-03T11:21:52.246141+08:00 0 [Note] [MY-011825] [Xtrabackup] decompressing ./mysql.ibd.zst
2025-06-03T11:21:52.247776+08:00 0 [Note] [MY-011825] [Xtrabackup] decompressing ./undo_001.zst
2025-06-03T11:21:52.247790+08:00 0 [Note] [MY-011825] [Xtrabackup] decompressing ./algorithm/microbial_zh_rag.MYI.zst
2025-06-03T11:21:52.251053+08:00 0 [Note] [MY-011825] [Xtrabackup] decompressing ./algorithm/microbial_en_rag.MYD.zst
2025-06-03T11:21:52.264324+08:00 0 [Note] [MY-011825] [Xtrabackup] decompressing ./algorithm/tcm_rag.MYD.zst

```

**问题处理：**  
修改selinux

>SELinux 或 AppArmor 限制
检查 SELinux 状态并临时禁用（测试环境）：
```bash
getenforce  # 若返回 Enforcing，执行以下命令
setenforce 0
```

>或添加 SELinux 规则允许脚本访问 zstd：
```bash
chcon -t bin_t /usr/local/bin/zstd
```
