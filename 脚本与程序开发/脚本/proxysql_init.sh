#!/bin/bash
######################################################
#creater:shenxiang
#createtime:2023-4-10
#version:1.0
#
#
######################################################


# 设置默认值

read_username="app_dzj_read"
read_password="Dzj_pwd_2022"
rw_username="app_dzj_rw"
rw_password="Dzj_pwd_2022"
# app_dzj_read 与 app_dzj_rw 在数据库中的host
host="10.10.%"
mysql_host="10.10.1.9"
help_info=""

# proxysql及mysql登录密码
proxysql_pw='admin_pwd'
mysql_pw='Dzj_pwd_2022'


# 一般不需要修改的参数
# proxysql-admin
proxysql_admin_user="cluster_demo"
# mysql create_user权限用户
mysql_create_user='dzjroot'
# proxysql_ip
proxysql_ip=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d '/' -f 1)
# proxysql_port
proxysql_port='6032'



# 解析输入参数
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        --read_username)
            read_username="$2"
            shift
            shift
            ;;
        --read_password)
            read_password="$2"
            shift
            shift
            ;;
        --rw_username)
            rw_username="$2"
            shift
            shift
            ;;
        --rw_password)
            rw_password="$2"
            shift
            shift
            ;;
        --host)
            host="$2"
            shift
            shift
            ;;
        -h|--help)
            help_info="Usage: ./create_mysql_user.sh [OPTIONS]
            Creates a new MySQL user and grants them the permissions needed to perform a variety of actions.

            Options:
              --read_username           MySQL username for read-only user.
              --read_password           MySQL password for read-only user.
              --rw_username             MySQL username for read-write user.
              --rw_password             MySQL password for read-write user.
              --host                    MySQL server IP address.
              -h, --help                display this help and exit"
            echo "$help_info"
            exit 0
            ;;
        *)
            echo "Invalid option: $key"
            exit 1
            ;;
    esac
done

# 验证必须参数
if [ -z "$read_username" ] || [ -z "$read_password" ] || [ -z "$rw_username" ] || [ -z "$rw_password" ] || [ -z "$host" ] || [ -z "$mysql_host" ]; then
    echo "Error: Invalid or missing arguments. Use -h or --help for more information."
    exit 1
fi

# 执行SQL语句，创建用户
mysql -u $mysql_create_user -p$mysql_pw -h $mysql_host  -P 3106  --default-auth=mysql_native_password -e "create user '$read_username'@'$host' identified  with mysql_native_password by '$read_password';
GRANT SELECT, SHOW DATABASES, SHOW VIEW ON *.* TO '$read_username'@'$host';

create user '$rw_username'@'$host' identified by '$rw_password';
GRANT SELECT, INSERT, UPDATE, CREATE, RELOAD, PROCESS, INDEX, ALTER, CREATE TEMPORARY TABLES, EXECUTE, CREATE VIEW, CREATE ROUTINE, ALTER ROUTINE ON *.* TO '$rw_username'@'$host';"

# 将用户信息写入mysql_users表并加载到运行时并保存到磁盘
mysql -u $proxysql_admin_user -p$proxysql_pw -h $proxysql_ip  -P 6032  -e "insert into mysql_users(username, password, active, use_ssl, default_hostgroup, default_schema, schema_locked, transaction_persistent, fast_forward, backend, frontend ,max_connections) values
('$read_username','$read_password',1, 0, 30,'' ,0 ,1 , 0 ,1 ,1,3000),
('$rw_username', '$rw_password',1, 0, 10,'' ,0 ,1 , 0 ,1 ,1,3000);

LOAD MYSQL users TO RUNTIME;
SAVE MYSQL users TO DISK;"

# 将服务器信息写入mysql_servers表并加载到运行时并保存到磁盘
mysql -u $proxysql_admin_user -p$proxysql_pw  -h $proxysql_ip  -P 6032 -e "insert into mysql_servers(hostgroup_id, hostname, port, gtid_port, status, weight, compression, max_connections, max_replication_lag, use_ssl, max_latency_ms)
    values(10, '$mysql_host', 3106, 0, 'ONLINE', 1, 0, 3000, 0, 0, 0),
    (30, '$mysql_host', 3106, 0, 'ONLINE', 1, 0, 3000, 0, 0, 0);

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

insert into mysql_query_rules(rule_id,username,active,destination_hostgroup,apply,flagOUT,flagIN) values(1,'$rw_username',1,10,0,1001,0);
insert into mysql_query_rules(rule_id,username,active,destination_hostgroup,apply,flagOUT,flagIN) values(2,'$read_username',1,30,0,1002,0);

insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN) values(100,'',1,'^SELECT.*FOR UPDATE$',10,1,'',1001);
insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN) values(101,'',1,'^SHOW',30,1,'',1001);
insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN) values(102,'',1,'^SELECT',30,1,'',1001);
insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN,error_msg) values(103,'',1,'^ALTER|^CREATE|^DROP|^TRUNCATE|^LOCK|^FLUSH|^KILL',30,1,'',1001,'ProxySql User Not Allowed This Option.');

insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN,error_msg) values(200,'',1,'^SELECT.*FOR UPDATE$',30,1,'',1002,'ProxySql User Not Allowed Select For Update On Slave.');
insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN) values(201,'',1,'^SELECT',30,1,'',1002);
insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN) values(202,'',1,'^SHOW',30,1,'',1002);
insert into mysql_query_rules(rule_id,username,active,match_digest,destination_hostgroup,apply,flagOUT,flagIN) values(203,'',1,'^SET',30,1,'',1002);
insert into mysql_query_rules(rule_id,username,active,match_digest,negate_match_pattern,destination_hostgroup,apply,flagOUT,flagIN,error_msg) values(204,'',1,'^SELECT|^SHOW|^SET',1,30,1,'',1002,'ProxySql User Not Allowed This Option.');

LOAD MYSQL RULE TO RUNTIME;
SAVE MYSQL RULE TO DISK;"



