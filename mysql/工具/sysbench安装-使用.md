| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-7月-27 | 2024-7月-27  |
| ... | ... | ... |
---
# sysbench安装-使用

[toc]

## 安装

```bash
curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.rpm.sh |  bash
yum -y install sysbench
```

## 用户创建，赋权
需要测试的数据库添加用户并赋权

```sql
grant select,create ,insert,update,delete,index on *.* to sysbench@'loaclhost' identified by '123456'  with grant option;
```


## 使用

```bash
sysbench  /usr/share/sysbench/oltp_insert.lua \
--threads=50 \
--table-size=500000 \
--tables=30 \
--mysql-db=sx_test \
--mysql-user=sysbench\
--mysql-password=123456 \
--mysql-port=3306 \
--mysql-host=10.10.?.? \
--time=120 \
--report-interval=10 \
prepare

run

cleanup
```