
# postgresql

[toc]

## 导出导入

```bash
pg_dump -U pmm-managed -d pmm-managed -F c -f pmm_managed_output_file.dump

pg_restore -U pmm-managed -d pmm_managed pmm_managed_output_file.dump

## 导入并覆盖
 pg_restore -U pmm-managed -d pmm_managed  --clean --if-exists pmm_managed_output_file.dump

```

## 创建用户

```sql
    create user "pmm-managed" with password '1uQHlmXSmIuir9Kc';

    ALTER USER "pmm-managed" WITH CREATEDB; 
    ALTER USER "pmm-managed" WITH LOGIN;
```

## psql

```bash
psql -h host_address -p port_number -U username -d database_name

\? 
\l 查看库
\c 切换库
\dn 查看schema
\dt 查看当前库的所有表
\d table_name  查看表结构
```

## 权限

[postgresql权限管理](../../postgresql/postgresql%E6%9D%83%E9%99%90%E7%AE%A1%E7%90%86.md)

常用查看：
```sql
    SELECT * FROM pg_roles WHERE rolname = 'new_role';

    SELECT grantee, privilege_type
    FROM information_schema.table_privileges
    WHERE table_name = 'your_table';
```

## 仅导出数据到文件

```sql
-- 导出
\copy (SELECT * FROM <table_name>) TO '<output_file.sql>' WITH (FORMAT CSV, HEADER);
-- 导入
\copy <table_name> FROM '<input_file.sql>' WITH (FORMAT CSV, HEADER);

```
