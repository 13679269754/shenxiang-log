| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2024-1月-16 | 2024-1月-16 |
| ... | ... | ... |
---
# mysql_初始化失败

[toc]

**问题**

```bash
 /usr/local/data/mysql/server/mysql8035/bin/mysqld --initialize-insecure --user=mysql --basedir=/usr/local/data/mysql/server/mysql8035 --datadir=/usr/local/data/mysql/data/mysqldata8035/db3306/data --innodb-undo-tablespaces=4 --lower-case-table-names=1 --innodb-data-file-path=ibdata1:16m

2024-01-16T03:04:23.361715Z 0 [ERROR] [MY-010187] [Server] Could not open file '/var/log/mysqld.log' for error logging: Permission denied
2024-01-16T03:04:23.361771Z 0 [ERROR] [MY-013236] [Server] The designated data directory /usr/local/data/mysql/data/db3306/data/ is unusable. You can remove all files that the server added to it.
2024-01-16T03:04:23.361782Z 0 [ERROR] [MY-010119] [Server] Aborting

```

删除自建的 /usr/local/data/mysql/data/db3306/data/ ,再次执行报错

```bash
2024-01-16T03:09:43.896734Z 0 [ERROR] [MY-010187] [Server] Could not open file '/var/log/mysqld.log' for error logging: Permission denied
2024-01-16T03:09:43.896783Z 0 [ERROR] [MY-013455] [Server] The newly created data directory /usr/local/data/mysql/data/db3306/data/ by --initialize is unusable. You can remove it.
2024-01-16T03:09:43.896799Z 0 [ERROR] [MY-010119] [Server] Aborting

```

目录权限给777都没用,属主也是 mysql mysql 。依然不行

**问题解决**
删除mysql 用户，重新创建

**问题出现原因(推测)**
第一次执行mysql 创建的脚本时，发现创建的mysql 用户默认shell 不是/bin/bash ,家目录/home/mysql也没有创建 导致了脚本报错。

仔细查看了之后发现创建的用户的默认值，是
```bash
[root@sx-db mysql]# cat /etc/default/useradd
# useradd defaults file
GROUP=100
HOME=/home
INACTIVE=-1
EXPIRE=
SHELL=/bin/bash
SKEL=/etc/skel
CREATE_MAIL_SPOOL=yes
```
是我想要的默认值。

删除用户，重新创建`useradd mysql`。然后就出现了上述问题。




