
# postgresql权限管理

[toc]

## 1. 修改角色

```sql
ALTER ROLE new_role WITH SUPERUSER;
```
将new_role提升为超级用户。
删除角色
```sql
DROP ROLE new_role;
```

## 2. 数据库级别的权限

连接数据库
只有被授予CONNECT权限的角色才能连接到特定的数据库。
```sql
GRANT CONNECT ON DATABASE your_database TO new_role;
```
创建模式
可以授予角色在数据库中创建模式的权限。
```sql
GRANT CREATE ON DATABASE your_database TO new_role;
```
## 3. 模式级别的权限

访问模式
要访问模式中的对象，角色需要有USAGE权限。  
```sql
GRANT USAGE ON SCHEMA your_schema TO new_role;
```
在模式中创建对象  
授予角色在特定模式中创建对象的权限。  
```sql
GRANT CREATE ON SCHEMA your_schema TO new_role;
```

## 4. 表级别的权限

表级权限可以细化到具体的操作，如SELECT、INSERT、UPDATE、DELETE等。
授予表权限
```sql
GRANT SELECT, INSERT ON your_table TO new_role;
```

授予new_role对your_table的SELECT和INSERT权限。
撤销表权限
```sql
REVOKE INSERT ON your_table FROM new_role;
```
撤销new_role对your_table的INSERT权限。

## 5. 列级别的权限
可以对表中的特定列授予或撤销权限。
```sql
GRANT SELECT (column1, column2) ON your_table TO new_role;
```
授予new_role对your_table中column1和column2的SELECT权限。

## 6. 默认权限
当创建新的数据库对象时，可以设置默认权限。
```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA your_schema
GRANT SELECT ON TABLES TO new_role;
```
之后在your_schema中创建的所有表，new_role都将自动获得SELECT权限。

## 7. 权限继承

可以将角色添加到另一个角色中，实现权限的继承。
```sql
GRANT parent_role TO child_role;
child_role将继承parent_role的所有权限。
```

## 8. 查看权限

查看角色权限
```sql
SELECT * FROM pg_roles WHERE rolname = 'new_role';
```

查看表权限
```sql
SELECT grantee, privilege_type
FROM information_schema.table_privileges
WHERE table_name = 'your_table';
```
通过合理地使用这些权限管理功能，你可以确保只有授权的用户能够访问和操作数据库中的敏感信息。