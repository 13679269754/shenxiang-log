
## 事故表现

mysql 意外重启

**mysql 日志**
```bash
/usr/local/data/mysql/bin/mysqld() [0x27bc345]
/lib64/libpthread.so.0(+0x7ea5) [0x7f5ff64f4ea5]
/lib64/libc.so.6(clone+0x6d) [0x7f5ff490cb0d]

Trying to get some variables.
Some pointers may be invalid and cause the dump to abort.
Query (0): Connection ID (thread ID): 100133
Status: NOT_KILLED

The manual page at http://dev.mysql.com/doc/mysql/en/crashing.html contains
information that should help you find out what is causing the crash.
2025-08-09T23:27:54.262459Z mysqld_safe Number of processes running now: 0
2025-08-09T23:27:54.285414Z mysqld_safe mysqld restarted

```

**系统日志**
```bash
[    5.074372] EXT4-fs (dm-2): warning: mounting fs with errors, running e2fsck is recommended
[  306.144018] EXT4-fs (dm-2): error count since last fsck: 1
[  306.144022] EXT4-fs (dm-2): initial error at time 1683223205: ext4_mb_generate_buddy:758
[  306.144024] EXT4-fs (dm-2): last error at time 1683223205: ext4_mb_generate_buddy:758
[  689.089124] mysql[22433]: segfault at 0 ip 00000000004452c1 sp 00007ffc2720b330 error 6 in mysql[400000+3f8000]
[  784.300958] mysqld[2544]: segfault at 10b623528 ip 00007fbac8a07d6d sp 00007ffdae3a79b0 error 4 in ld-2.17.so[7fbac89fe000+22000]
[  928.096388] mysqld[21719]: segfault at 10b623528 ip 00007f4838f55d6d sp 00007ffeda050cd0 error 4 in ld-2.17.so[7f4838f4c000+22000]
[ 1001.170470] mysqld[32196]: segfault at 10b623528 ip 00007fb62624ad6d sp 00007ffef6a3c2f0 error 4 in ld-2.17.so[7fb626241000+22000]
[ 1134.198911] mysql[16173]: segfault at 0 ip 00000000004452c1 sp 00007ffe9153ba10 error 6 in mysql[400000+3f8000]
[ 1137.782842] mysql[16258]: segfault at 0 ip 00000000004452c1 sp 00007ffcde5a59d0 error 6 in mysql[400000+3f8000]
[ 1139.288338] mysql[16524]: segfault at 0 ip 00000000004452c1 sp 00007ffef7da71c0 error 6 in mysql[400000+3f8000]
[ 1139.906962] mysql[16822]: segfault at 0 ip 00000000004452c1 sp 00007ffdc4da8dd0 error 6 in mysql[400000+3f8000]
……

```

## 问题处理

经过查询，发现是文件系统的问题，由于不是在线库，于是决定对文件系统进行修复

```bash
# 解除文件占用
fuser -m /dev/vdb1 
# kill 对应进程或者其他安全方式关闭
kill -9 %

# 卸载lv
umount  /usr/local/data

# 修复
e2fsck -f -y /dev/vdb
e2fsck 1.42.9 (28-Dec-2013) /dev/vdb1 is in use. e2fsck: 无法继续, 中止.

# 修正处理
e2fsck -f /dev/mapper/data-lv--data # 此处指定lv

# 磁盘挂载
mount /dev/mapper/data-lv--data /usr/local/data

```

![[mysql#数据文件校验 mysqlcheck]]