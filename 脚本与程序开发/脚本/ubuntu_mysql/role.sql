
-- 1. 创建角色组（Role）
-- 1.1 创建 DBA 角色（全库全权限，含授权能力）
CREATE ROLE IF NOT EXISTS `dba`;

-- 1.2 创建 Group Replication 管理角色（仅组复制相关权限）
CREATE ROLE IF NOT EXISTS `group_replication_manager`;

-- 1.3 创建普通复制用户角色（主从同步用，非组复制）
CREATE ROLE IF NOT EXISTS `replication_user`;

-- 1.4 创建全库只读角色（仅查询权限）
CREATE ROLE IF NOT EXISTS `reader`;

-- 1.5 创建全库读写角色（查询+增改，无删除/结构修改）
CREATE ROLE IF NOT EXISTS `writer`;

-------------------------------------------------------------------------

-- 2. 分配权限到角色组
-- dba
GRANT ALL PRIVILEGES ON *.* TO `dba` WITH GRANT OPTION;
-- 说明：ALL PRIVILEGES 包含所有权限，WITH GRANT OPTION 允许该角色将权限授予其他用户

--------------------------------------------------------
-- group_replication_manager
-- 1. 创建角色（角色名通常不含主机名，可全局应用）
CREATE ROLE `group_replication_manager`;

-- 2. 授予角色核心集群管理权限（含授权能力）
GRANT CLUSTER_ADMIN, GROUP_REPLICATION_ADMIN,
      CONNECTION_ADMIN, PERSIST_RO_VARIABLES_ADMIN,
      SYSTEM_VARIABLES_ADMIN, ROLE_ADMIN
ON *.* TO `group_replication_manager` WITH GRANT OPTION;

-- 3. 授予数据同步与恢复权限
GRANT CLONE_ADMIN, REPLICATION_SLAVE_ADMIN, REPLICATION_APPLIER, GTID_ADMIN
ON *.* TO `group_replication_manager` WITH GRANT OPTION;

-- 4. 授予元数据管理权限（集群元数据存储所需）
GRANT INSERT, UPDATE, DELETE, CREATE, DROP, REFERENCES, INDEX, ALTER,
      CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, CREATE VIEW, SHOW VIEW,
      CREATE ROUTINE, ALTER ROUTINE, EVENT, TRIGGER
ON `mysql_innodb_cluster_metadata`.* TO `group_replication_manager` WITH GRANT OPTION;

GRANT INSERT, UPDATE, DELETE, CREATE, DROP, REFERENCES, INDEX, ALTER,
      CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, CREATE VIEW, SHOW VIEW,
      CREATE ROUTINE, ALTER ROUTINE, EVENT, TRIGGER
ON `mysql_innodb_cluster_metadata_bkp`.* TO `group_replication_manager` WITH GRANT OPTION;

GRANT INSERT, UPDATE, DELETE, CREATE, DROP, REFERENCES, INDEX, ALTER,
      CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, CREATE VIEW, SHOW VIEW,
      CREATE ROUTINE, ALTER ROUTINE, EVENT, TRIGGER
ON `mysql_innodb_cluster_metadata_previous`.* TO `group_replication_manager` WITH GRANT OPTION;

-- 5. 授予系统表访问权限
GRANT SELECT ON `mysql`.* TO `group_replication_manager` WITH GRANT OPTION;
GRANT SELECT ON `performance_schema`.* TO `group_replication_manager` WITH GRANT OPTION;
GRANT PROCESS, REPLICATION CLIENT ON *.* TO `group_replication_manager` WITH GRANT OPTION;

--------------------------------------------------------
-- replication_user
-- 主从同步核心权限（从库拉取binlog、应用事务）
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO `replication_user`;

--------------------------------------------------------
-- reader
-- 全库查询权限（所有库表的 SELECT）
GRANT SELECT ON *.* TO `reader`;

-- 允许查看库列表（避免连库后看不到任何数据库）
GRANT SHOW DATABASES ON *.* TO `reader`;

--------------------------------------------------------
-- writer
-- 基础读写权限（查询+插入+更新）
GRANT SELECT, INSERT, UPDATE ON *.* TO `writer`;

-- 允许查看库列表、表结构
GRANT SHOW DATABASES, SHOW VIEW ON *.* TO `writer`;

-------------------------------------------------------------------------
-- 默认角色设置
SET GLOBAL mandatory_roles = 'reader';