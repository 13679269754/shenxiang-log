[mysql导出用户和权限|极客教程](https://geek-docs.com/mysql/mysql-ask-answer/9_hk_1709763246.html) 

| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-1月-16 | 2025-1月-16  |
| ... | ... | ... |
---
# mysql 用户及权限导出

[toc]


在日常管理数据库中，数据库用户的管理以及权限的控制是非常重要的事情。有时候我们需要备份数据库中所有用户以及他们的权限，以便在需要的时候重新导入数据库。本文将详细介绍如何使用MySQL命令行工具来导出用户和权限的方法。

### 步骤1：登录MySQL数据库

首先，使用如下命令登录MySQL数据库：

```
mysql -u root -p
```

输入密码后成功登录。

### 步骤2：导出用户

要导出数据库中所有用户，可以使用如下SQL语句：

```sql
SELECT CONCAT('CREATE USER \'',  user,'\'@\'', host,  '\' IDENTIFIED BY \'your_password\';')  FROM mysql.user; 
```

以上语句会生成一系列CREATE USER语句，格式如下所示：

```sql
CREATE  USER  'user'@'host' IDENTIFIED BY  'password'; 
```

其中，`user`是用户的名称，`host`是允许登录的主机，`password`是该用户的密码。

### 步骤3：导出权限

要导出用户的权限，需要使用如下SQL语句：

```sql
SELECT CONCAT('GRANT ',  PRIVILEGE_TYPE, ' ON ', TABLE_SCHEMA, '.', TABLE_NAME, ' TO \'', GRANTEE ,'\';') AS stmt FROM information_schema.TABLE_PRIVILEGES;
```

以上语句会生成一系列GRANT语句，格式如下所示：

```sql
GRANT  ALL  ON  database.table  TO  'user'@'host'; 
```


其中，`database`是数据库的名称，`table`是表的名称，`user`是用户的名称，`host`是允许登录的主机。

### 步骤4：将结果导出至文件

要将生成的SQL语句导出至文件，可以使用如下命令：

``` sql
SELECT CONCAT('CREATE USER \'',  user,  '\'@\'', host,  '\' IDENTIFIED BY \'your_password\';')  FROM mysql.user  INTO  OUTFILE  '/path/to/users.sql'; 

SELECT CONCAT('GRANT ',  PRIVILEGE_TYPE, ' ON ', TABLE_SCHEMA, '.', TABLE_NAME, ' TO \'', GRANTEE ,'\';') AS stmt FROM information_schema.TABLE_PRIVILEGES  INTO  OUTFILE  '/path/to/privileges.sql'; 
```

将生成的用户和权限信息分别导出到`users.sql`和`privileges.sql`文件中。

### 步骤5：恢复用户和权限

要恢复导出的用户和权限，可以使用如下命令：

```bash
mysql -u root -p <  /path/to/users.sql
mysql -u root -p <  /path/to/privileges.sql
```


这样就可以将之前导出的用户和权限信息重新导入到数据库中。请注意，在恢复权限时需要保证导出和恢复的数据库结构一致，否则可能会导致权限错误。

通过以上步骤，您可以轻松地导出和恢复MySQL数据库中的用户和权限信息，确保数据安全和权限控制。
