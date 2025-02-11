mysql 强密码插件`validate_password`

查看mysql 插件目录
`show variables like '%plugin_dir%';`
可以进入plugin目录查看是否有 `validate_password.so` 插件，5.5+版本应该都有引入强密码验证插件

```sql
mysql > INSTALL PLUGIN validate_password SONAME 'validate_password.so';
```

查看是否引入成功

```sql
show plugins;
-- 或者 
select * from information_schema.plugins where plugin_name ='validate_password';
-- 修改密码插件相关配置
set global validate_password_policy=STRONG;set global validate_password_length=8;
set global validate_password_mixed_case_count=1;
set global validate_password_number_count=1;
set global validate_password_special_char_count=1;
set global password_lifetime=90
```

修改mysql 配置文件使得mysql重启后配置依然生效
```bash
[mysqld]
plugin-load=validate_password.so
validate-password=FORCE_PLUS_PERMANENT
validate_password_policy=MEDIUMvalidate_password_length=8
validate_password_mixed_case_count=1
validate_password_number_count=1
validate_password_special_char_count=1
password_lifetime=90
```

## 用户密码过期时间配置

1. password_lifetime 设置的为用户默认使用的过期时间，从mysql启动之日起对所有用户生效
2. 单独指定过期时间ALTER USER '用户名'@'ip'  PASSWORD EXPIRE INTERVAL 30 DAY; （表示30天过期）
3. 永不过期
ALTER USER '用户名'@'ip' PASSWORD EXPIRE NEVER;

## 字典文件设置

`validate_password.dictionary_file`可以在运行时设置，并且赋值会导致读取指定的文件，而无需重新启动服务器。

默认情况下，此变量为空值，不会执行字典检查。若要进行字典检查，变量值必须非空。如果文件名是相对路径，则相对于服务器数据目录进行解释。文件内容应为小写，每行一个单词。内容被视为具有字符集  utf8mb3 。允许的最大文件大小为 1MB。

在进行密码检查时要使用字典文件，密码策略必须设置为 2（ STRONG ）；请参阅  validate_password.policy  系统变量的描述。假设条件成立，密码中长度为 4 至 100 的每个子串都会与字典文件中的单词进行比较。任何匹配都会导致密码被拒绝。比较不区分大小写。

## 用户名校验

validate_password.check_user_name               | ON     |

用户名不允许出现在密码中