

## mysql 用户安全

### mysql ssl

经过测试使用
新的mysq认证插件caching_sha2_password需要开启ssl: /root/opt/mysql/8.0.33/bin/mysql_ssl_rsa_setup

创建用户指定使用ssl
-- 需要客户端指定sert和key文件
`create user 'user_name'@'%' identified by 'password'  require x509 ;`

--需要使用ssl但是不需要指定key文件

`create user 'user_name'@'%' identified by 'password'  require ssl;` 

### 强密码插件

[mysql 强密码插件](<mysql 强密码插件.md>)

### 基于角色的权限管理

1. 创建角色

```sql
create role senior dba, app dev;
grant all on *,* to senior dba with grant option;
grant select,insert,update,delete on wp.* to app dev;
```

2. 用户与角色绑定

```sql
create user tom@'192.168.1.%'identfied by '123';
grant senior dba to tom@'192.168.1.%';
```

3. 显示用户权限

```sql
show grants for 'tom'@'192.168.1.%';
show grants for 'tom'@'192.168.1.%'using senior dba;
```

4. 删除角色

```sql
drop role senior dba;
```


