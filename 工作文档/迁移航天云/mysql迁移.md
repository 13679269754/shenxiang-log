| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-2月-27 | 2025-2月-27  |
| ... | ... | ... |
---
# mysql迁移

[toc]

## 数据库架构

### 数据源实例架构

| ip | port | 服务类型 | 
| -- | -- | -- | 
| 172.30.70.41 | 3106 | mysql-master |
| 172.30.70.42 | 3106 | mysql-slave |
| 172.30.70.43 | 3106 | mysql-slave |
| 172.30.70.44 | 3106 | mysql-slave |
| 172.30.70.45 | 3106 | mysql-slave-backup |
| 172.30.70.31 | 6032-3000 | proxysql-orch |
| 172.30.70.32 | 6032-3000| proxysql-orch |
| 172.30.70.33 | 6032 | proxysql |
| 172.30.70.34 | 3000 | orch |

### 迁移后架构

| ip | port | 服务类型 | 
| -- | -- | -- | 
| 10.159.65.152 | 3106 | mysql-master |
| 10.159.65.153 | 3106 | mysql-slave-read |
| 10.159.65.154 | 3106 | mysql-slave-read |
| 10.159.65.155 | 3106 | mysql-slave-read |
| 10.159.65.156 | 3106 | mysql-slave-backup |
| 172.30.70.157 | 3000 | orch |
| 172.30.70.158 | 3000 | orch |
| 172.30.70.159 | 3000 | orch |
| 172.30.70.160 | 6032 | proxysql |
| 172.30.70.161 | 6032 | proxysql |
| 172.30.70.163 | 6032 | proxysql |


## 新数据库服务器环境准备

### 初始化新服务器

[初始化脚本](%E8%84%9A%E6%9C%AC/dbnode_init.sh)

### 安装mysql

```
[root@mysql1 script]# ./mysql_install.sh  --help

Usage:
   --package_dir:      输入Mysql安装包目录
   --package_file:     输入Mysql安装包文件名称（注意使用Mysql官方安装包）
   --port|-p:          输入需要安装的Mysql的端口
   --data_path:        输入需要安装的Mysql的数据保存目录
   --base_path:        输入需要安装的Mysql的软件安装目录
   --version_control:  目录版本控制开关: 0 不开启 1 全部开启 2 开启basedir 3 开启datadir 默认0 不开启
   --run_step:         运行步骤: 0 linux系统配置 和 安装Mysql server 和 Mysql instance 和 初始化Mysql配置 1 安装Mysql server 和 Mysql instance 和 初始化Mysql配置 2 Mysql instance 和 初始化Mysql配置 11 linux系统配置 12 安装Mysql server 13 创建Mysql instance 14 初始化Mysql配置 默认0
```

```bash
./mysql_install.sh  --package_dir /root/soft --package_file mysql-8.0.23-el7-x86_64.tar.gz --port 3106 --data_path /usr/local/data/mysql_data/ --base_path /usr/local/data/mysql
```

[mysql 安装脚本](../../脚本与程序开发/脚本/mysql_script/mysql_install.sh)

## 恢复数据到新集群

### 获取源集群数据备份

源集群备份语句
```bash
 ts '%Y-%m-%d %H:%M:%S'  |xtrabackup --use-memory=64G --host=172.30.70.45 --user=dzjbackup --password=* --backup --target-dir=/usr/local/data/mysql_backup/20250115_02_00_05/2025_01_15_02_00_05  --datadir=/usr/local/data/mysql_data/db3106/data --socket=/usr/local/data/mysql_data/db3106/run/mysql3106.sock --port=3106 --compress-threads=10 --compress 
```

### 恢复备份

将备份文件`/usr/local/data/mysql_backup/20250115_02_00_05/2025_01_15_02_00_05` 传输到新数据库集群的主库

```bash
scp -r -l 20000 /usr/local/data/mysql_backup/20250115_02_00_05/2025_01_15_02_00_05 10.159.65.152:/root/
```
**自此操作都在新集群**

备份解压缩(xtrabackup ,qpress需要预先安装)
```bash
xtrabackup --decompress --parallel=32 --target-dir=/root/20250225_02_00_05/2025_02_25_02_00_05 --remove-original
```
需要在解压缩时删除压缩文件 --remove-original ，否则磁盘空间可能不足

备份文件准备
```bash
xtrabackup --prepare --use-memory=64G --target-dir=./
```

```

```

~~直接将文件mv到新库的数据目录(需要预先在新的集群中安装mysql数据库)~~
```bash
# 清除新mysql服务的数据目录(为初始化数据，可以清除)
#rm -rf /usr/local/data/mysql_data/data
#rm -rf /usr/local/data/mysql_data/log

# 将备份分发到全部的5台新集群机器上
#scp /root/20250225_02_00_05/2025_02_25_02_00_05 10.159.65.153/usr/local/data/mysql_data/data
#scp /root/20250225_02_00_05/2025_02_25_02_00_05 10.159.65.154/usr/local/data/mysql_data/data
#scp /root/20250225_02_00_05/2025_02_25_02_00_05 10.159.65.155/usr/local/data/mysql_data/data
#scp /root/20250225_02_00_05/2025_02_25_02_00_05 10.159.65.156/usr/local/data/mysql_data/data

# 恢复备份(5台都执行)
# mv /root/20250225_02_00_05/2025_02_25_02_00_05 /usr/local/data/mysql_data/data

# chown -R mysql. /usr/local/data/mysql_data/

# 启动mysql(5台都执行)
#/home/mysql/3106-start.sh 
```

```bash
 xtrabackup --defaults-file=/usr/local/data/mysql_data/db3106/conf/my3106.cnf --copy-back --target-dir=./
 ```

### 启动主从复制

**主库**
```sql
  show slave status;

  CHANGE MASTER TO MASTER_HOST = '172.30.70.41', MASTER_USER = 'hty_dzjrep', MASTER_PASSWORD = 'Pw6nhngeKYf6tu5a', MASTER_PORT = 3106, MASTER_AUTO_POSITION = 1, MASTER_RETRY_COUNT = 10, MASTER_HEARTBEAT_PERIOD = 1000000; 

  start slave；

  show slave status;
```


**从库**
```sql
  show slave status;

  CHANGE MASTER TO MASTER_HOST = '10.159.65.152', MASTER_USER = 'hty_dzjrep', MASTER_PASSWORD = 'Pw6nhngeKYf6tu5a', MASTER_PORT = 3106, MASTER_AUTO_POSITION = 1, MASTER_RETRY_COUNT = 10, MASTER_HEARTBEAT_PERIOD = 1000000; 

  
  start slave；

  show slave status;
```
 

## orchestrator 安装搭建

### 安装包获取
```bash
wget https://github.com/openark/orchestrator/releases/download/v3.2.6/orchestrator-3.2.6-linux-amd64.tar.gz

scp orchestrator-3.2.6-linux-amd64.tar.gz 10.159.65.158:/root/soft/
scp orchestrator-3.2.6-linux-amd64.tar.gz 10.159.65.159:/root/soft/

```

### 解压安装
```bash
mkdir -p /usr/local/data/orchestrator

# orchestrator 默认安装到系统路径下
tar -zxvf orchestrator-3.2.6-linux-amd64.tar.gz  -C /usr/local/data/orchestrator

# 解压后`/usr/local/data/orchestrator` 有多个路径

# 将`/usr/local/data/orchestrator/usr/local/orchestrator`的文件 放到`/usr/local/data/orchestrator/`下即可

# 参考路径处理
mv  /usr/local/data/orchestrator/usr/local/orchestrator/* /usr/local/data/orchestrator/

rm -rf /usr/local/data/orchestrator/usr

rm -rf /usr/local/data/orchestrator/etc
```

### 修改配置文件

vim [/usr/local/data/orchestrator/orchestrator.json](%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6/orchestrator.json)

RaftNodes: 集群节点
RaftBind：当前节点

### 添加hook脚本

将 [script](%E8%84%9A%E6%9C%AC/orchestrator.script/script) 放在 `/usr/local/data/orchestrator/script`

**python3环境安装**(见dbnode_init.sh)

安装依赖
```bash
cd /usr/local/data/orchestrator/script

cat << EOF > requirements.txt
PyMySQL~=1.0.3
requests~=2.28.2
urllib3~=1.26.15
EOF

pip3 install -r requirements.txt

ln -s  /usr/bin/python3 /usr/local/bin/python3
```

### 创建管理脚本

```bash
cat << EOF > /usr/local/data/orchestrator/start.sh
nohup ./orchestrator --config=/usr/local/data/orchestrator/orchestrator.json http >> orchestrator.log &
EOF

cat << EOF > /usr/local/data/orchestrator/checkprocess.sh
#!/bin/sh

CheckProcess()
{
  # 检查输入的参数是否有效
  if [ "$1" = "" ];
  then
    return 1
  fi

  #$PROCESS_NUM获取指定进程名的数目，为1返回0，表示正常，不为1返回1，表示有错误，需要重新启动
  PROCESS_NUM=`ps -ef | grep -i "$1" | grep -v "grep" | wc -l`
  if [ $PROCESS_NUM -eq 1 ];
  then
    return 0
  else
    return 1
  fi
}

host=`/usr/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`

CheckProcess "Orchestrator.json"
Check_RET=$?

File=/usr/local/data/orchestrator/last_check_time.txt
if [ ! -f $File ];then
  touch $File
fi

last_run=`stat -c %Y $File`

if [ $Check_RET -eq 1 ];
then
   echo "服务不正常"
   current_time=`date +%s`
   if [ $((current_time - last_run)) -ge $((3600)) ];then
     echo $current_time > $File
     /usr/bin/python3 /usr/local/data/orchestrator/script/qywechat_notify.py "$host Orchestrator Down" "$host Orchestrator Down" "$host Orchestrator Down"
   fi
else
   echo "服务正常"
fi
EOF
```

### 定时任务创建

```bash
crontab -e
*/5 * * * * /usr/local/data/orchestrator/checkprocess.sh
```

选主排除配置 



需要排除的被选为主的实例:10.159.56.156



10.159.65.156 执行
```bash

# 此段内容可以在全部集群都执行，以备不时之需
scp 10.159.65.157:/usr/local/data/orchestrator/resources/bin/orchestrator-client /usr/local/bin/

cat << EOF > /root/.bash_profile
export ORCHESTRATOR_API="http://10.159.65.157:3000/api http://10.159.65.158:3000/api http://10.159.65.159:3000/api"
EOF

crontab -e
*/2 * * * * source /etc/bashrc && source /root/.bash_profile && /usr/bin/perl -le 'sleep rand 10' && /usr/local/bin/orchestrator-client -c register-candidate -i 10.159.65.156:3106 --promotion-rule must_not >/dev/null 2>&1
```

## proxysql 集群搭建

### 安装
```bash
wget https://github.com/sysown/proxysql/releases/download/v2.4.5/proxysql-2.4.5-1-centos7.x86_64.rpm

yum localinstall proxysql-2.4.5-1-centos7.x86_64.rpm

mkdir  -p /usr/local/data/proxysql/
mkdir /usr/local/data/proxysql/conf
mkdir /usr/local/data/proxysql/data
mkdir /usr/local/data/proxysql/log
mkdir /usr/local/data/proxysql/script
```

### 创建配置文件

[proxysql.cnf](%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6/proxysql.cnf)

### 创建管理脚本

```bash
echo "/usr/local/data/mysql/bin/mysql -uadmin -p -h127.0.0.1 -P6032 --prompt='Admin> ' --default-auth=mysql_native_password" > /usr/local/data/proxysql/script/proxysql_login
echo "/usr/bin/proxysql --idle-threads -c /usr/local/data/proxysql/conf/proxysql.cnf" > /usr/local/data/proxysql/script/proxysql_start
cat <<  EOF > /usr/local/data/proxysql/script/proxysql_stop
ps -ef | grep proxysql
killall proxysql
EOF

chmod 755 /usr/local/data/proxysql/script/*
```

启动服务: /usr/local/data/proxysql/script/proxysql_start

### proxysql集群配置

```bash
mysql -u admin -p******  -h localhost  -P 6032 # mysql命令行工具自行安装
```

```sql
-- 集群中每一台都需要执行
insert into proxysql_servers(hostname,port,weight,comment) values ('10.159.65.160','6032','1','ProxySQL-node1');
insert into proxysql_servers(hostname,port,weight,comment) values ('10.159.65.161','6032','1','ProxySQL-node2');
insert into proxysql_servers(hostname,port,weight,comment) values ('10.159.65.162','6032','1','ProxySQL-node3');

LOAD proxysql servers TO RUNTIME;
SAVE proxysql servers TO DISK;

-- 查看集群同步状态
select * from stats_proxysql_servers_checksums;

```

集群正常后任选一台添加mysql集群信息和用户信息
```sql
-- 服务器
insert into mysql_servers(hostgroup_id, hostname, port, gtid_port, status, weight, compression, max_connections, max_replication_lag, use_ssl, max_latency_ms)
    values(10, '10.159.65.152', 3106, 0, 'ONLINE', 1, 0, 3000, 0, 0, 0),
    (30, '10.159.65.152', 3106, 0, 'ONLINE', 1, 0, 3000, 0, 0, 0),
    (30, '10.159.65.153', 3106, 0, 'ONLINE', 1, 0, 3000, 0, 0, 0),
    (30, '10.159.65.154', 3106, 0, 'ONLINE', 1, 0, 3000, 0, 0, 0),
    (30, '10.159.65.155', 3106, 0, 'ONLINE', 1, 0, 3000, 0, 0, 0);

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;


-- 用户
insert into mysql_users(username, password, active, use_ssl, default_hostgroup, default_schema, schema_locked, transaction_persistent, fast_forward, backend, frontend ,max_connections) values
('hty_app_dzj_rw','RUbwlPq7Gpzxm6lw43Xx',1, 0, 30,'' ,0 ,1 , 0 ,1 ,1,3000);
-- ('hty_app_dzj_rw','FGJDbrnOlO',1, 0, 10,'' ,0 ,1 , 0 ,1 ,1,3000); 不再被使用
LOAD MYSQL users TO RUNTIME;
SAVE MYSQL users to MEMORY;
SAVE MYSQL users TO DISK;

```

添加sql路由规则
```sql
# route rule
insert into mysql_query_rules(rule_id,username,active,destination_hostgroup,apply,flagOUT,flagIN) values(1,'app_dzj_rw',1,10,0,1001,0);
insert into mysql_query_rules(rule_id,username,active,destination_hostgroup,apply,flagOUT,flagIN) values(2,'app_dzj_read',1,30,0,1002,0);

insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN) values(100,'',1,'^SELECT.*FOR UPDATE$',10,1,'',1001);
insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN) values(101,'',1,'^SHOW',30,1,'',1001);
insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN) values(102,'',1,'^SELECT',30,1,'',1001);
insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN,error_msg) values(103,'',1,'^ALTER|^CREATE|^DROP|^TRUNCATE|^LOCK|^FLUSH|^KILL',30,1,'',1001,'ProxySql User Not Allowed This Option.');

insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN,error_msg) values(200,'',1,'^SELECT.*FOR UPDATE$',30,1,'',1002,'ProxySql User Not Allowed Select For Update On Slave.');
insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN) values(201,'',1,'^SELECT',30,1,'',1002);
insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN) values(202,'',1,'^SHOW',30,1,'',1002);
insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN) values(203,'',1,'^SET',30,1,'',1002);
insert into mysql_query_rules(rule_id,username,active,match_digest,negate_match_pattern,destination_hostgroup,apply,flagOUT,flagIN,error_msg) values(204,'',1,'^SELECT|^SHOW|^SET',1,30,1,'',1002,'ProxySql User Not Allowed This Option.');

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

### proxysql monitor 用户添加

```sql
set mysql-monitor_username='hty_proxysql_monitor';
set mysql-monitor_password='******';

LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
```

## 航天云数据库用户创建

查询目前在使用且host绑定idc的用户
```sql
-- 获取需要迁移的用户
SELECT CONCAT('create user ','''',`user`,'''','@','''','10.159.65.%','''',' identified by *******;') FROM mysql.user WHERE HOST LIKE '%172%' and HOST not like '%172.30.2%' AND  account_locked = 'N' ORDER BY  HOST 
create user 'hty_dzj_algorithm_read'@'10.159.65.%' identified by *******;                          
create user 'hty_app_dzj_rwuser'@'10.159.65.%' identified by *******;                              
create user 'hty_dzj_bigdata_rep'@'10.159.65.%' identified by *******;                             
create user 'hty_dzj_bigdata_repl'@'10.159.65.%' identified by *******;                            
create user 'hty_dzjbackup'@'10.159.65.%' identified by *******;                                   
create user 'hty_orchestrator'@'10.159.65.%' identified by *******;                                
create user 'hty_proxysql_monitor'@'10.159.65.%' identified by *******;                            
create user 'hty_archery_user'@'10.159.65.%' identified by *******;                                
create user 'hty_dzj_reporter'@'10.159.65.%' identified by *******;          

-- 判断需要迁移的用户 有以下用户需要迁移，保持密码不变
create user 'hty_app_dzj_rwuser'@'10.159.65.%' identified by '******';                              
create user 'hty_dzj_bigdata_rep'@'10.159.65.%' identified by '******';                             
create user 'hty_dzj_bigdata_repl'@'10.159.65.%' identified by '******';                            
create user 'hty_dzjbackup'@'10.159.65.%' identified by '******';                                   
create user 'hty_orchestrator'@'10.159.65.%' identified by '******';                                
create user 'hty_proxysql_monitor'@'10.159.65.%' identified by '******';                            
create user 'hty_dzj_reporter'@'10.159.65.%' identified by '******';      

-- 获取需要迁移账户的权限          
show grants for 'app_dzj_rwuser'@'172.30.%';                        
show grants for 'dzj_bigdata_rep'@'172.30.%';                       
show grants for 'dzj_bigdata_repl'@'172.30.%';                      
show grants for 'dzjbackup'@'172.30.%';                             
show grants for 'orchestrator'@'172.30.%';                          
show grants for 'proxysql_monitor'@'172.30.%';                                      
show grants for 'dzj_reporter'@'172.30.70.11';       

-- 修改用户的host和user_name 后赋权
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE ON *.* TO `hty_app_dzj_rwuser`@`10.159.65.%`;
GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO `hty_dzj_bigdata_rep`@`10.159.65.%`;
GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO `hty_dzj_bigdata_repl`@`10.159.65.%`;
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO `hty_dzjbackup`@`10.159.65.%`;
GRANT BACKUP_ADMIN ON *.* TO `hty_dzjbackup`@`10.159.65.%`;
GRANT SELECT ON `performance_schema`.`log_status` TO `hty_dzjbackup`@`10.159.65.%`;
GRANT RELOAD, PROCESS, SUPER, REPLICATION SLAVE ON *.* TO `hty_orchestrator`@`10.159.65.%`;
GRANT SELECT ON `meta`.* TO `hty_orchestrator`@`10.159.65.%`;
GRANT SELECT ON `mysql`.`slave_master_info` TO `hty_orchestrator`@`10.159.65.%`;
GRANT REPLICATION CLIENT ON *.* TO `hty_proxysql_monitor`@`10.159.65.%`;


GRANT PROCESS, EXECUTE, REPLICATION CLIENT ON *.* TO `hty_dzj_reporter`@`10.159.65.%`;
GRANT SELECT ON `mysql`.* TO `hty_dzj_reporter`@`10.159.65.%`;
GRANT SELECT ON `sys`.* TO `hty_dzj_reporter`@`10.159.65.%`;
GRANT SELECT ON `performance_schema`.* TO `hty_dzj_reporter`@`10.159.65.%`;

```

迁移前运行稳定后执行用户锁定
```sql
alter user 'dzj_algorithm_read'@'172.16.%' ACCOUNT LOCK;                        
alter user 'dzj_algorithm_read_user'@'172.16.%' ACCOUNT LOCK;                   
alter user 'app_dzj_rwuser'@'172.30.%' ACCOUNT LOCK;                            
alter user 'dzj_bigdata_rep'@'172.30.%' ACCOUNT LOCK;                           
alter user 'dzj_bigdata_repl'@'172.30.%' ACCOUNT LOCK;                          
alter user 'dzjbackup'@'172.30.%' ACCOUNT LOCK;                                 
alter user 'hty_app_dzj_rwuser'@'172.30.%' ACCOUNT LOCK;                        
alter user 'orchestrator'@'172.30.%' ACCOUNT LOCK;                              
alter user 'proxysql_monitor'@'172.30.%' ACCOUNT LOCK;                          
alter user 'archery_user'@'172.30.70.11' ACCOUNT LOCK;                          
alter user 'dzj_reporter'@'172.30.70.11' ACCOUNT LOCK;                          
```

## 数据库服务器防火墙配置

主库防火墙脚本，仅做参考
```bash
cat  << EOF > /etc/iptables.sh
#!/bin/bash
/usr/bin/systemctl stop firewalld &>/dev/null
/usr/bin/systemctl disable firewalld &>/dev/null

IPTABLES=/usr/sbin/iptables

modprobe ip_conntrack
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp

$IPTABLES -F -t filter
$IPTABLES -F -t nat
$IPTABLES -F -t mangle

$IPTABLES -X -t filter
$IPTABLES -X -t nat
$IPTABLES -X -t mangle

$IPTABLES -Z -t filter
$IPTABLES -Z -t nat
$IPTABLES -Z -t mangle

$IPTABLES -t filter -P INPUT     DROP
$IPTABLES -t filter -P OUTPUT    ACCEPT
$IPTABLES -t filter -P FORWARD   ACCEPT

$IPTABLES -t nat -P PREROUTING   ACCEPT
$IPTABLES -t nat -P POSTROUTING  ACCEPT
$IPTABLES -t nat -P OUTPUT       ACCEPT

$IPTABLES -t mangle -P INPUT     ACCEPT
$IPTABLES -t mangle -P OUTPUT    ACCEPT
$IPTABLES -t mangle -P FORWARD   ACCEPT


$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

$IPTABLES -A INPUT -p tcp -s 172.30.1.37 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.1.37 --dport 3106 -j ACCEPT


$IPTABLES -A INPUT -p tcp -s 172.30.2.246 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.2.246 --dport 3106 -j ACCEPT


$IPTABLES -A INPUT -p tcp -s 172.30.2.251 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.2.251 --dport 3106 -j ACCEPT


###########################################################################
$IPTABLES -A INPUT -p tcp -s 10.159.65.152 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 10.159.65.153 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 10.159.65.154 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 10.159.65.155 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 10.159.65.156 --dport 3106 -j ACCEPT

$IPTABLES -A INPUT -p tcp -s 10.159.65.152 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 10.159.65.153 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 10.159.65.154 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 10.159.65.155 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 10.159.65.156 --dport 22 -j ACCEPT

$IPTABLES -A INPUT -p tcp -s  10.159.65.151 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s  10.159.65.157 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s  10.159.65.158 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s  10.159.65.159 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s  10.159.65.160 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s  10.159.65.161 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s  10.159.65.162 --dport 3106 -j ACCEPT

# 航天云VPN访问服务器的源地址
iptables -A INPUT -s 10.159.176.12 -j ACCEPT

###########################################################################
/usr/sbin/iptables-save > /etc/sysconfig/iptables

EOF
```

防火墙生效
```bash
bash /etc/iptables.sh
```
