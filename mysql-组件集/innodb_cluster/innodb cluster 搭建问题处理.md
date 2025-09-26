## 一、未清除innodb cluster 信息

报错：

```bash
 MySQL  172.29.105.240:33060+  JS >  var cluster = dba.createCluster('my_innodb_cluster')
Dba.createCluster: dba.createCluster: Unable to create cluster. The instance '172.29.105.240:3306' has a populated Metadata schema and belongs to that Metadata. Use either dba.dropMetadataSchema() to drop the schema, or dba.rebootClusterFromCompleteOutage() to reboot the cluster from complete outage. (RuntimeError)
```

处理：

1. 清理innodb cluster 系统表信息
```bash
 dba.dropMetadataSchema(user@ip:port)
```
  2.清理数据库配置信息
  ```sql
  STOP GROUP_REPLICATION;

-- 1. 重置组名称（核心标识，必须清空）
SET GLOBAL group_replication_group_name = '00000000-0000-0000-0000-000000000000';

-- 2. 重置种子节点列表（清除集群关联）
SET GLOBAL group_replication_group_seeds = '';

-- 3. 重置本地通信地址（断开节点自身的组复制通信）
SET GLOBAL group_replication_local_address = '';

-- 4. 关闭自动重启（避免重启 MySQL 后重新加入集群）
SET GLOBAL group_replication_start_on_boot = OFF;

-- 5. 重置自动重连次数（清除重试逻辑）
SET GLOBAL group_replication_autorejoin_tries = 0;

-- 6. 重置 IP 白名单（可选，若需完全解除限制）
SET GLOBAL group_replication_ip_allowlist = 'AUTOMATIC'; -- 恢复默认自动模式，也可设为 '' 清空

-- 7. 重置其他非必要参数（若需彻底清理，可选）
SET GLOBAL group_replication_force_members = ''; -- 清除强制指定的成员列表
SET GLOBAL group_replication_recovery_ssl_ca = ''; -- 清空 SSL 相关配置（若之前配置过）
SET GLOBAL group_replication_recovery_ssl_cert = '';
SET GLOBAL group_replication_recovery_ssl_key = '';
  ```


## 二、用户权限不足

报错：

```bash
* Waiting for distributed recovery to finish...
WARNING: Error in applier for group_replication_recovery: Worker 1 failed executing transaction '6564736e-819d-11f0-9a73-0050569c21f0:16' at source log binlog.000003, end_log_pos 782; Error 'You are not allowed to create a user with GRANT' on query. Default database: ''. Query: 'GRANT REPLICATION SLAVE, BACKUP_ADMIN ON *.* TO 'mysql_innodb_cluster_20199'@'%'' (1410) at 2025-09-02 10:58:12.979408
NOTE: '172.29.105.242:3306' is being recovered from '172.29.105.240:3306'
```

处理：
搭建innodb cluster 集群需要创建用户并赋权，所以管理用户需要有with grants option
```sql
GRANT APPLICATION_PASSWORD_ADMIN,AUDIT_ABORT_EXEMPT,AUDIT_ADMIN,AUTHENTICATION_POLICY_ADMIN,BACKUP_ADMIN,BINLOG_ADMIN,BINLOG_ENCRYPTION_ADMIN,ENCRYPTION_KEY_ADMIN,FIREWALL_EXEMPT,FLUSH_OPTIMIZER_COSTS,FLUSH_STATUS,FLUSH_TABLES,FLUSH_USER_RESOURCES,GROUP_REPLICATION_STREAM,INNODB_REDO_LOG_ARCHIVE,INNODB_REDO_LOG_ENABLE,PASSWORDLESS_USER_ADMIN,RESOURCE_GROUP_ADMIN,RESOURCE_GROUP_USER,SENSITIVE_VARIABLES_OBSERVER,SERVICE_CONNECTION_ADMIN,SESSION_VARIABLES_ADMIN,SET_USER_ID,SHOW_ROUTINE,SYSTEM_USER,TABLE_ENCRYPTION_ADMIN,TELEMETRY_LOG_ADMIN,XA_RECOVER_ADMIN ON *.* TO `dzjroot`@`%` WITH GRANT OPTION;
```