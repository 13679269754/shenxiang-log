| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-5月-15 | 2025-5月-15  |
| ... | ... | ... |
---

# mysql 小版本升级.md

[toc]

## 资料

[Upgrading MySQL](https://dev.mysql.com/doc/refman/8.0/en/upgrade-binary-package.html)

## 情况说明

此次升级需要升级到8.0.29 以上，原版本为8.0.23。  

升级实例为IDC-备用环境的后端库,大数据算法库 和 航天云后端库,大数据算法库  
本次升级顺序为  
1. IDC数据算法库72.22, 2.198
2. IDC后端数据70.41-70.45 ，72.21
3. HTY算法数据库10.159.65.126-127 
4. HTY算法数据库10.159.65.152-156

## 切换脚本

```bash
/usr/local/data/mysql/bin/mysql -S /usr/local/data/mysql_data/db3106/run/mysql3106.sock -e "set global innodb_fast_shutdown=0; show variables like 'innodb_fast_shutdown';"
/usr/local/data/mysql/bin/mysql -S /usr/local/data/mysql_data/db3106/run/mysql3106.sock -e "shutdown;"

# tar -xvf /root/soft/mysql-8.0.34-linux-glibc2.17-x86_64.tar  && rm -f  /root/soft/mysql-8.0.34-linux-glibc2.17-x86_64.tar
tar -zxvf /root/soft/mysql-8.0.34-linux-glibc2.17-x86_64.tar.gz -C /usr/local/data/
chown  -R mysql.  /usr/local/data/mysql-8.0.34-linux-glibc2.17-x86_64
mv /usr/local/data/mysql /usr/local/data/mysql_8.0.23
mv /usr/local/data/mysql-8.0.34-linux-glibc2.17-x86_64 /usr/local/data/mysql_8.0.34
ln -s /usr/local/data/mysql_8.0.34 /usr/local/data/mysql

su - mysql -c "/bin/bash /home/mysql/3106-start.sh"


/usr/local/data/mysql/bin/mysql -S /usr/local/data/mysql_data/db3106/run/mysql3106.sock -e "select @@version ;show slave status ;"
/usr/local/data/mysql/bin/mysql -S /usr/local/data/mysql_data/db3106/run/mysql3106.sock -e "start slave ;show slave status ;"

/usr/local/data/mysql/bin/mysql -S /usr/local/data/mysql_data/db3106/run/mysql3106.sock -e "show slave status ;"
```

## 说明

mysql 8.0.19开始不需要再执行

```sql
mysql_upgrade
```

## 其他需要注意

1. orchestrator 是否需要关闭。高可用组件可能会在主库重启的时候切换。
2. proxysql 是否需要手动踢出节点
```sql
update mysql_servers set status='SHUNNED' WHERE hostname='10.159.65.155';
load mysql servers to runtime;
SAVE MYSQL servers to disk ;


update mysql_servers set status='ONLINE' WHERE hostname='10.159.65.155';
update mysql_servers set status='SHUNNED' WHERE hostname='10.159.65.154';
load mysql servers to runtime;
SAVE MYSQL servers to disk ;



update mysql_servers set status='ONLINE' WHERE hostname='10.159.65.154';
update mysql_servers set status='SHUNNED' WHERE hostname='10.159.65.153';
load mysql servers to runtime;
SAVE MYSQL servers to disk ;



update mysql_servers set status='ONLINE' WHERE hostname='10.159.65.154';
update mysql_servers set status='SHUNNED' WHERE hostname='10.159.65.153';
load mysql servers to runtime;
SAVE MYSQL servers to disk ;



update mysql_servers set status='ONLINE' WHERE hostname='10.159.65.153';
update mysql_servers set status='SHUNNED' WHERE hostname='10.159.65.152';
load mysql servers to runtime;
SAVE MYSQL servers to disk ;
```

3. 数据库重启后只读读状态是否会被重置，需要确认状态;
4. innodb_fast_shutdown 是否需要修改回默认值0;
5. 滚动升级完成后，需要确认主从复制状态，尤其是需要确认没有事务丢失（即gtid一致）。

insert into mysql_servers()