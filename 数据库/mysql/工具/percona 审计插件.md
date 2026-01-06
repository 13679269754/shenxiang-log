[percona 审计插件](https://www.cnblogs.com/abclife/p/17879307.html)


MySQL 8 社区版安装Percona的审计插件

**1.下载插件**

```
# tar -xvf Percona-Server-8.0.32-24-Linux.x86_64.glibc2.17-minimal.tar.gz
# cd Percona-Server-8.0.32-24-Linux.x86_64.glibc2.17-minimal/lib/plugin
# cp audit_log.so /usr/local/mysql/lib/plugin/
```

**2.查看插件位置**

```
root@localhost (none)>show variables like '%plugin_dir%';
+---------------+------------------------------+
| Variable_name | Value                        |
+---------------+------------------------------+
| plugin_dir    | /usr/local/mysql/lib/plugin/ |
+---------------+------------------------------+
1 row in set (0.01 sec)
```

**3.查看是否已经安装过审计插件**

```
root@localhost mysql>SELECT * FROM information_schema.PLUGINS WHERE PLUGIN_NAME LIKE '%audit%';
Empty set (0.01 sec)
 
root@localhost mysql>SHOW variables LIKE 'audit%';
Empty set (0.00 sec)
 
root@localhost mysql>
```

**4.安装插件**

```
root@localhost (none)> INSTALL PLUGIN audit_log SONAME 'audit_log.so';
Query OK, 0 rows affected (0.00 sec)
```

**5.查看是否安装成功**

```
root@localhost (none)> SELECT * FROM information_schema.PLUGINS WHERE PLUGIN_NAME LIKE '%audit%'\G
*************************** 1. row ***************************
           PLUGIN_NAME: audit_log
        PLUGIN_VERSION: 0.2
         PLUGIN_STATUS: ACTIVE
           PLUGIN_TYPE: AUDIT
   PLUGIN_TYPE_VERSION: 4.1
        PLUGIN_LIBRARY: audit_log.so
PLUGIN_LIBRARY_VERSION: 1.11
         PLUGIN_AUTHOR: Percona LLC and/or its affiliates.
    PLUGIN_DESCRIPTION: Audit log
        PLUGIN_LICENSE: GPL
           LOAD_OPTION: ON
1 row in set (0.00 sec)
 
root@localhost (none)>SHOW variables LIKE 'audit%';
+-----------------------------+-----------------------------+
| Variable_name               | Value                       |
+-----------------------------+-----------------------------+
| audit_log_buffer_size       | 1048576                     |
| audit_log_exclude_accounts  |                             |
| audit_log_exclude_commands  |                             |
| audit_log_exclude_databases |                             |
| audit_log_file              | /test/mysql_audit/audit.log |
| audit_log_flush             | OFF                         |
| audit_log_format            | CSV                         |
| audit_log_handler           | FILE                        |
| audit_log_include_accounts  |                             |
| audit_log_include_commands  |                             |
| audit_log_include_databases |                             |
| audit_log_policy            | LOGINS                      |
| audit_log_rotate_on_size    | 0                           |
| audit_log_rotations         | 0                           |
| audit_log_strategy          | ASYNCHRONOUS                |
| audit_log_syslog_facility   | LOG_USER                    |
| audit_log_syslog_ident      | percona-audit               |
| audit_log_syslog_priority   | LOG_INFO                    |
+-----------------------------+-----------------------------+
18 rows in set (0.00 sec)
```

**6.添加配置**

在配置文件中添加审计配置

```
plugin-load = audit_log.so
audit_log_file = /test/mysql_audit/audit.log
audit_log_format = CSV
audit_log_policy = LOGINS 
audit_log_handler = FILE
audit_log_rotate_on_size = 1048576
```

其中 audit\_log\_policy 的取值有：

```
·ALL - all events will be logged
·LOGINS - only logins will be logged
·QUERIES - only queries will be logged
·NONE - no events will be logged
```

创建审计日志目录闭并重启mysql

```
mkdir -p /test/mysql_audit
chown -R mysql:mysql /test/mysql_audit
```

**7.重启后查看**

安装后，Performance Schema会启用一些instruments

```
root@localhost mysql>SELECT PLUGIN_NAME, PLUGIN_STATUS FROM INFORMATION_SCHEMA.PLUGINS WHERE PLUGIN_NAME LIKE 'audit%';
+-------------+---------------+
| PLUGIN_NAME | PLUGIN_STATUS |
+-------------+---------------+
| audit_log   | ACTIVE        |
+-------------+---------------+
1 row in set (0.00 sec)
 
root@localhost (none)>SELECT NAME FROM performance_schema.setup_instruments WHERE NAME LIKE '%audit%';
+-------------------------------------------------------------+
| NAME                                                        |
+-------------------------------------------------------------+
| wait/synch/mutex/sql/LOCK_audit_mask                        |
| wait/synch/mutex/audit_log/file_logger::lock                |
| wait/synch/mutex/audit_log/audit_log_buffer::mutex          |
| wait/synch/rwlock/audit_log/audit_log_filter::account_list  |
| wait/synch/rwlock/audit_log/audit_log_filter::database_list |
| wait/synch/rwlock/audit_log/audit_log_filter::command_list  |
| wait/synch/cond/audit_log/audit_log_buffer::written_cond    |
| wait/synch/cond/audit_log/audit_log_buffer::flushed_cond    |
| memory/audit_log/audit_log_logger_handle                    |
| memory/audit_log/audit_log_handler                          |
| memory/audit_log/audit_log_buffer                           |
| memory/audit_log/audit_log_accounts                         |
| memory/audit_log/audit_log_databases                        |
| memory/audit_log/audit_log_commands                         |
+-------------------------------------------------------------+
14 rows in set (0.00 sec)
```

**8.审计事件分析**

以下面的登录记录为例

```
<AUDIT_RECORD
  NAME="Connect"
  RECORD="2_2023-12-06T03:11:01"
  TIMESTAMP="2023-12-06T03:11:13Z"
  CONNECTION_ID="8"
  STATUS="0"                                --0表示登录成功；非0表示登录失败
  USER="root"
  PRIV_USER="root"
  OS_LOGIN=""
  PROXY_USER=""
  HOST="localhost"
  IP=""
  DB=""
/>
```

**9.日志格式**

支持OLD, NEW, JSON, 和 CSV 格式。其中old和new是基于xml格式的。由变量 audit\_log\_format  控制。

更多使用方法可以参考：

https://planet.mysql.com/entry/?id=5992239

https://docs.percona.com/percona-server/5.7/management/audit\_log\_plugin.html

https://cybersecthreat.com/2021/12/09/mysql-community-edition-audit-logging/

https://blog.51cto.com/u\_16213454/7738338

https://medium.com/@larrie.loi/mysql-8-0-x-audit-solution-ee0d16d2d332

https://www.percona.com/blog/how-to-store-mysql-audit-logs-in-mongodb-in-a-maintenance-free-setup/
