以下是针对 **MySQL 8.0.34** 的权限初始化 SQL 脚本，严格遵循 8.0 版本的角色管理特性（支持角色创建、权限继承），包含你需要的 5 个角色组（`dba`、`group_replication_manager`、`replication_user`、`reader`、`writer`），并附带用户创建示例和权限验证方法：


### 一、核心前提：关闭SQL安全模式（避免赋权限制）
MySQL 8.0 默认可能开启 `sql_safe_updates`，先临时关闭（会话级，不影响全局），确保赋权语句正常执行：
```sql
-- 临时关闭SQL安全模式（当前会话生效）
SET sql_safe_updates = 0;
```


### 二、权限初始化脚本（分角色创建+赋权）
#### 1. 创建角色组（Role）
MySQL 8.0 推荐通过「角色」管理权限，后续用户直接「继承角色」，无需重复赋权：
```sql
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
```


#### 2. 为角色分配权限（按需求精准赋权）
##### 2.1 DBA 角色：全库全权限（含授权能力）
```sql
GRANT ALL PRIVILEGES ON *.* TO `dba` WITH GRANT OPTION;
-- 说明：ALL PRIVILEGES 包含所有权限，WITH GRANT OPTION 允许该角色将权限授予其他用户
```


##### 2.2 Group Replication 管理角色：仅组复制操作权限
```sql
-- 核心组复制管理权限（创建/启停集群、增减节点）
GRANT CLUSTER_ADMIN, GROUP_REPLICATION_ADMIN ON *.* TO `group_replication_manager`;

-- 节点恢复权限（克隆/增量同步数据）
GRANT CLONE_ADMIN, REPLICATION_SLAVE_ADMIN ON *.* TO `group_replication_manager`;

-- GTID 同步权限（组复制依赖 GTID，确保事务一致性）
GRANT GTID_ADMIN ON *.* TO `group_replication_manager`;

-- 状态查看权限（查看集群状态、性能数据）
GRANT SELECT ON performance_schema.* TO `group_replication_manager`;
GRANT SELECT ON mysql.* TO `group_replication_manager`;
GRANT PROCESS, REPLICATION CLIENT ON *.* TO `group_replication_manager`;
```


##### 2.3 普通复制用户角色：主从同步专用（非组复制）
```sql
-- 主从同步核心权限（从库拉取binlog、应用事务）
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO `replication_user`;

-- 说明：仅用于传统主从复制（如一主一从），无集群管理权限，安全性更高
```


##### 2.4 全库只读角色：仅查询权限
```sql
-- 全库查询权限（所有库表的 SELECT）
GRANT SELECT ON *.* TO `reader`;

-- 允许查看库列表（避免连库后看不到任何数据库）
GRANT SHOW DATABASES ON *.* TO `reader`;
```


##### 2.5 全库读写角色：查询+增改（无删除/结构修改）
```sql
-- 基础读写权限（查询+插入+更新）
GRANT SELECT, INSERT, UPDATE ON *.* TO `writer`;

-- 允许查看库列表、表结构
GRANT SHOW DATABASES, SHOW VIEW ON *.* TO `writer`;

-- 禁止删除/结构修改（确保数据安全，如需删除需额外赋权）
-- 注意：未授予 DELETE、DROP、ALTER 权限，避免误操作
```


#### 3. 创建示例用户并绑定角色
创建实际使用的用户，并直接继承对应角色（无需重复赋权）：
```sql
-- 3.1 创建 DBA 用户（如 admin_dba）
CREATE USER IF NOT EXISTS `admin_dba`@`%` IDENTIFIED BY 'DBA@StrongPass123!';
-- 绑定 DBA 角色
GRANT `dba` TO `admin_dba`@`%`;
-- 激活角色（MySQL 8.0 需手动激活，或设置全局自动激活）
SET DEFAULT ROLE `dba` FOR `admin_dba`@`%`;

-- 3.2 创建 Group Replication 管理员（如 gr_manager）
CREATE USER IF NOT EXISTS `gr_manager`@`%` IDENTIFIED BY 'GR@StrongPass123!';
GRANT `group_replication_manager` TO `gr_manager`@`%`;
SET DEFAULT ROLE `group_replication_manager` FOR `gr_manager`@`%`;

-- 3.3 创建普通复制用户（如 slave_user，用于传统主从）
CREATE USER IF NOT EXISTS `slave_user`@`%` IDENTIFIED BY 'Repl@StrongPass123!';
GRANT `replication_user` TO `slave_user`@`%`;
SET DEFAULT ROLE `replication_user` FOR `slave_user`@`%`;

-- 3.4 创建只读用户（如 app_reader）
CREATE USER IF NOT EXISTS `app_reader`@`%` IDENTIFIED BY 'Read@StrongPass123!';
GRANT `reader` TO `app_reader`@`%`;
SET DEFAULT ROLE `reader` FOR `app_reader`@`%`;

-- 3.5 创建读写用户（如 app_writer）
CREATE USER IF NOT EXISTS `app_writer`@`%` IDENTIFIED BY 'Write@StrongPass123!';
GRANT `writer` TO `app_writer`@`%`;
SET DEFAULT ROLE `writer` FOR `app_writer`@`%`;
```


#### 4. 全局配置：新用户默认激活角色（可选）
为避免后续创建用户时需手动执行 `SET DEFAULT ROLE`，可设置全局参数自动激活角色：
```sql
-- 全局开启角色自动激活（重启后生效，需持久化）
SET PERSIST default_role_all = ON;
-- 说明：PERSIST 会将参数写入 mysqld-auto.cnf，重启后保留
```


#### 5. 刷新权限（确保所有配置生效）
```sql
FLUSH PRIVILEGES;
```


### 三、权限验证方法（确保配置正确）
可通过以下 SQL 验证角色和用户的权限是否生效：

#### 1. 查看角色的权限
```sql
-- 查看 dba 角色的权限
SHOW GRANTS FOR `dba`;

-- 查看 group_replication_manager 角色的权限
SHOW GRANTS FOR `group_replication_manager`;
```


#### 2. 查看用户的角色和权限
```sql
-- 查看 admin_dba 用户的角色
SHOW GRANTS FOR `admin_dba`@`%`;

-- 查看 app_reader 用户的实际权限（继承自 reader 角色）
SHOW GRANTS FOR `app_reader`@`%` USING `reader`;
```

### 四、关键注意事项（MySQL 8.0 特性）
1. **角色激活**：MySQL 8.0 创建用户绑定角色后，需通过 `SET DEFAULT ROLE` 激活，否则用户登录后无法使用角色权限（全局 `default_role_all = ON` 可省略此步骤）。
2. **密码策略**：8.0 默认开启 `validate_password` 插件，用户密码需满足复杂度（如长度≥8、含大小写+数字+特殊字符），示例中的密码已符合要求。
3. **权限回收**：若需调整权限，直接修改角色即可，所有绑定该角色的用户会自动继承新权限（无需逐个修改用户），例如：
   ```sql
   -- 给 writer 角色新增 DELETE 权限（所有绑定 writer 的用户都会获得）
   GRANT DELETE ON *.* TO `writer`;
   ```
4. **传统复制 vs 组复制**：`replication_user` 角色仅用于传统主从同步，`group_replication_manager` 用于组复制管理，两者权限隔离，避免混淆。
5. **roles 相关参数**
- **`activate_all_roles_on_login`**：控制用户登录时是否自动激活所有已授予的角色（默认 OFF）
- **`mandatory_roles`**：设置强制授予给所有用户的角色（默认空

## 五、sql脚本
```sql

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
```