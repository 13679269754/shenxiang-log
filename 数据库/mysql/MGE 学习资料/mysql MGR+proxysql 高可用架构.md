[MySQL-proxysql+MGR高可用 - Harda - 博客园](https://www.cnblogs.com/harda/p/16995787.html) 

 ProxySQL 是用 C++ 语言开发的，虽然也是一个轻量级产品，但性能很好 (据测试，能处理千亿级的数据)，功能也足够，能满足中间件所需的绝大多数功能，可以更好更好的支持 master slave\\MGR\\PXC 等高可用集群，常见功能分库分表、SQL 审计、负载均衡、主从切换，以及最基本的读 / 写分离，且方式有多种：

可缓存查询结果。虽然 ProxySQL 的缓存策略比较简陋，但实现了基本的缓存功能，绝大多数时候也够用了。此外，监控后端节点。ProxySQL 可以监控后端节点的多个指标，包括：ProxySQL 和后端的心跳信息，后端节点的 read-only/read-write，slave 和 master 的数据同步延迟性 (replication lag)。

1、简介   
MySQL Group Replication（简称 MGR）是 MySQL 官方推出的一个全新的高可用与高扩展的解决方案。   
2、MGR 组复制的特点   
-  高一致性：基于分布式 paxos 协议实现组复制，保证数据一致性；   
-  高容错性：自动检测机制，只要不是大多数节点都宕机就可以继续工作，内置防脑裂保护机制；   
-  高扩展性：节点的增加与移除会自动更新组成员信息，新节点加入后，自动从其他节点同步增量数据，直到与其他节点数据一致；   
-  高灵活性：提供单主模式和多主模式，单主模式在主库宕机后能够自动选主，所有写入都在主节点进行，多主模式支持多节点写入；   
3、组复制两种运行模式   
->  在单主模式下, 组复制具有自动选主功能，每次只有一个 server 成员接受更新。单写模式 group 内只有一台节点可写可读，其他节点只可以读。对于 group 的部署，需要先跑起 primary 节点（即那个可写可读的节点，read_only = 0）然后再跑起其他的节点，并把这些节点一一加进 group。其他的节点就会自动同步 primary 节点上面的变化，然后将自己设置为只读模式（read_only = 1）。当 primary 节点意外宕机或者下线，在满足大多数节点存活的情况下，group 内部发起选举，选出下一个可用的读节点，提升为 primary 节点。primary 选举根据 group 内剩下存活节点的 UUID 按字典序升序来选择，即剩余存活的节点按 UUID 字典序排列，然后选择排在最前的节点作为新的 primary 节点。   
->  在多主模式下, 所有的 server 成员都可以同时接受更新。group 内的所有机器都是 primary 节点，同时可以进行读写操作，并且数据是最终一致的。   
4.2 安装和配置 MGR 信息   
1) 配置所有节点的组复制信息，在配置文件中添加组复制信息 (三个节点)   
\[mysql@db7 ~]# vim data3308/my3308.cnf   
# 复制框架   
log_slave_updates         = 1   
slave_preserve_commit_order = 1   
gtid_mode                 = ON   
enforce_gtid_consistency  = ON   
skip_slave_start          = 1   
binlog_checksum           = NONE 

\#组复制设置   
#server 必须为每个事务收集写集合，并使用 XXHASH64 哈希算法将其编码为散列   
transaction_write_set_extraction=XXHASH64   
#告知插件加入或创建组命名，UUID   
loose-group_replication_group_name="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"   
#server 启动时不自启组复制, 为了避免每次启动自动引导具有相同名称的第二个组, 所以设置为 OFF。   
loose-group_replication_start_on_boot=off   
#告诉插件使用 IP 地址，端口 24901 用于接收组中其他成员转入连接   
loose-group_replication_local_address="192.168.65.157:24901"   
#启动组 server，种子 server，加入组应该连接这些的 ip 和端口；其他 server 要加入组得由组成员同意   
loose-group_replication_group_seeds="192.168.65.157:24901,192.168.65.159:24901,192.168.65.160:24901"   
loose-group_replication_bootstrap_group=off   
report_host=192.168.65.157   
report_port=3308   
注意：3 个 MGR 节点除了 server_id、loose-group_replication_local_address、report_host 三个参数不一样外，其他保持一致。 

2) 配置完成后，重启数据库服务，安装 MGR 插件，设置复制账号 (三个节点)   
mysql> install plugin group_replication soname "group_replication.so"; 

mysql> show variables like "%sql_log_bin%";   
+---------------+-------+   
| Variable_name | Value |   
+---------------+-------+   
| sql_log_bin   | ON    |   
+---------------+-------+ 

mysql> set sql_log_bin=0; 

mysql> create user repl@"%" identified by "repl";   
mysql> grant replication slave on \*.\* to repl@"%";   
注意：mysql8 授权和 mysql5.7 略有不同 

mysql> flush privileges;   
Query OK, 0 rows affected (0.00 sec) 

mysql> set sql_log_bin=1;   
mysql> change master to master_user="repl", master_password="repl" for channel "group_replication_recovery";   
Query OK, 0 rows affected, 2 warnings (0.02 sec) 

4.3 启动 MGR 单主模式   
1) 启动 MGR，在主库 db07 上执行   
mysql> set global group_replication_bootstrap_group=ON;   
mysql> start group_replication;   
mysql> set global group_replication_bootstrap_group=OFF; 

查看 MGR 组信息：   
mysql> SELECT \* FROM performance_schema.replication_group_members;   
注意：主库重启服务，再开启 group_replication, 需要先把 group_replication_bootstrap_group 打开 (比如三台主机关机后，重启) 

2) 其他节点加入 MGR 集群，在从库 db09 和 db10 上执行；   
mysql> start group_replication;   
在三台服务器均加入 MGR 集群后，通过 select \* from performance_schema.replication_group_members; 查看，db09 和 db10 两个节点在集群里的状态是 RECOVERING!!!   通过查看 db9 和 db10 的日志，发现均报下列错误；   
2020-11-02T16:48:37.764214+08:00 197 \[ERROR] \[MY-010584] \[Repl] Slave I/O for channel 'group_replication_recovery': error connecting to master'repl@192.168.65.157:3308'- retry-time: 60 retries: 1 message: Authentication plugin'caching_sha2_password' reported error: Authentication requires secure connection. Error_code: MY-002061   
2020-11-02T16:48:37.953674+08:00 33 \[ERROR] \[MY-011582] \[Repl] Plugin group_replication reported: 'There was an error when connecting to the donor server. Please check that group_replication_recovery channel credentials and all MEMBER_HOST column values of performance_schema.replication_group_members table are correct and DNS resolvable.' 

该错是认证错误，解决方法：   
在主库上 db7 上执行以下命令：   
mysql> SET SQL_LOG_BIN=0;   
Query OK, 0 rows affected (0.00 sec) 

mysql> alter user repl@"%" identified with sha256_password by "repl";   
Query OK, 0 rows affected (0.01 sec) 

mysql> grant replication slave on \*.\* to repl@"%";   
Query OK, 0 rows affected (0.00 sec) 

mysql> SET SQL_LOG_BIN=1;   
Query OK, 0 rows affected (0.00 sec)   
在 db9 和 db10 从库上分别执行下面命令：   
mysql> stop group_replication; 

mysql> start group_replication;   
再次查看, 三个节点均处于 ONLINE 状态：   
mysql> select \* from performance_schema.replication_group_members;   
+---------------------------+--------------------------------------+----------------+-------------+--------------+-------------+----------------+   
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST    | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |   
+---------------------------+--------------------------------------+----------------+-------------+--------------+-------------+----------------+   
| group_replication_applier | 86b068b1-1cde-11eb-b734-000c2942f665 | 192.168.65.159 |        3308 | ONLINE       | SECONDARY   | 8.0.21         |   
| group_replication_applier | 8cd2939a-1cdf-11eb-ab90-000c291f6651 | 192.168.65.160 |        3308 | ONLINE       | SECONDARY   | 8.0.21         |   
| group_replication_applier | bb19bc06-1cdc-11eb-9824-000c298fe356 | 192.168.65.157 |        3308 | ONLINE       | PRIMARY     | 8.0.21         |   
+---------------------------+--------------------------------------+----------------+-------------+--------------+-------------+----------------+ 

在从库 db09/db10 上进行插入数据，报错, 因为这是 MGR 单主模式, 从库只能进行读操作, 不能进行写操作!   
mysql> insert into kevin.haha values(5,"wangshibo");   
ERROR 1290 (HY000): The MySQL server is running with the --super-read-only option so it cannot execute this statement   
mysql>  

3) 故障切换   
如果主节点挂掉了, 通过选举程序会从从库节点中选择一个作为主库节点.  如下模拟故障: 关闭 db07 的 mysql 服务   
\[mysql@db7 ~]# /usr/local/mysql/bin/mysqladmin -uroot -proot -S data3308/my3308.sock shutdown   
在 db09 从库上查看 mysql> select \* from performance_schema.replication_group_members;   
+---------------------------+--------------------------------------+----------------+-------------+--------------+-------------+----------------+   
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST    | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |   
+---------------------------+--------------------------------------+----------------+-------------+--------------+-------------+----------------+   
| group_replication_applier | 86b068b1-1cde-11eb-b734-000c2942f665 | 192.168.65.159 |        3308 | ONLINE       | PRIMARY     | 8.0.21         |   
| group_replication_applier | 8cd2939a-1cdf-11eb-ab90-000c291f6651 | 192.168.65.160 |        3308 | ONLINE       | SECONDARY   | 8.0.21         |   
+---------------------------+--------------------------------------+----------------+-------------+--------------+-------------+----------------+   
并在 db09 上进行如下操作：   
mysql> insert into kevin.haha values(5,"wangshibo");   
Query OK, 1 row affected (0.01 sec) 

mysql> insert into kevin.haha values(6,"wangshibo");   
Query OK, 1 row affected (0.01 sec) 

mysql> delete from kevin.haha where id>5;   
Query OK, 1 row affected (0.02 sec)   
如上, 发现在之前的主库 db07 节点挂掉后, db09 节点可以进行写操作了, 说明此时已经选举 db09 节点为新的主节点了   
那么, db10 节点还是从节点, 只能读不能写; 

然后再恢复 db07 节点，恢复后，主要手动激活下该节点的组复制功能   
\[mysql@db7 ~]# /usr/local/mysql/bin/mysqld_safe --defaults-file=/root/data3308/my3308.cnf &   
\[mysql@db7 ~]# mysql -uroot -proot -S data3308/my3308.sock   
mysql> start group_replication;   
mysql> delete from kevin.haha where id>3;   
ERROR 1290 (HY000): The MySQL server is running with the --super-read-only option so it cannot execute this statement 

发现 db07 节点恢复后, 则变为了从库节点, 只能读不能写.   
如果从节点挂了, 恢复后, 只需要手动激活下该节点的组复制功能 ("START GROUP_REPLICATION;"),   
即可正常加入到 MGR 组复制集群内并自动同步其他节点数据. 

4.4 MGR 多主模式   
MGR 切换模式需要重新启动组复制，因些需要在所有节点上先关闭组复制，设置 group_replication_single_primary_mode=OFF 等参数，再启动组复制 

1) 停止复制组 (在所有 MGR 节点上执行)   
mysql> stop group_replication;   
mysql> set global group_replication_single_primary_mode=OFF;   
mysql> set global group_replication_enforce_update_everywhere_checks=ON; 

2) 随便选择一个节点执行 (这里选择 db09)   
mysql> SET GLOBAL group_replication_bootstrap_group=ON;   
mysql> start group_replication;   
mysql> SET GLOBAL group_replication_bootstrap_group=OFF; 

3) 在其他两个节点 (db07 和 db10 上进行)   
mysql> start group_replication;   
4) 查看 MGR 组信息 (任意节点即可)   
mysql> select \* from performance_schema.replication_group_members;   
+---------------------------+--------------------------------------+----------------+-------------+--------------+-------------+----------------+   
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST    | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |   
+---------------------------+--------------------------------------+----------------+-------------+--------------+-------------+----------------+   
| group_replication_applier | 86b068b1-1cde-11eb-b734-000c2942f665 | 192.168.65.159 |        3308 | ONLINE       | PRIMARY     | 8.0.21         |   
| group_replication_applier | 8cd2939a-1cdf-11eb-ab90-000c291f6651 | 192.168.65.160 |        3308 | ONLINE       | PRIMARY     | 8.0.21         |   
| group_replication_applier | bb19bc06-1cdc-11eb-9824-000c298fe356 | 192.168.65.157 |        3308 | ONLINE       | PRIMARY     | 8.0.21         |   
+---------------------------+--------------------------------------+----------------+-------------+--------------+-------------+----------------+ 

可以看到所有 MGR 节点状态都是 online，角色都是 PRIMARY，MGR 多主模式搭建成功。   
5) 验证数据同步   
在 db10 上插入数据：mysql> insert into kevin.haha values(11,"beijing"),(12,"shanghai"),(13,"anhui");   
在 db07 上更新数据：   
结论：MGR 多主模式下, 所有节点都可以进行读写操作. 

6) 故障切换   
让主机 dbo9 的 mysql 服务停掉：mysqladmin -uroot -proot -S data3308/my3308.sock shutdown   
任一节点查看 MGR 状态，并插入数据：   
mysql> select \* from performance_schema.replication_group_members;   
+---------------------------+--------------------------------------+----------------+-------------+--------------+-------------+----------------+   
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST    | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |   
+---------------------------+--------------------------------------+----------------+-------------+--------------+-------------+----------------+   
| group_replication_applier | 8cd2939a-1cdf-11eb-ab90-000c291f6651 | 192.168.65.160 |        3308 | ONLINE       | PRIMARY     | 8.0.21         |   
| group_replication_applier | bb19bc06-1cdc-11eb-9824-000c298fe356 | 192.168.65.157 |        3308 | ONLINE       | PRIMARY     | 8.0.21         |   
+---------------------------+--------------------------------------+----------------+-------------+--------------+-------------+----------------+   
mysql> insert into kevin.haha values(14,"beijing"); 

结论：如果某个节点挂了, 则其他的节点继续进行同步.   
 当故障节点恢复后, 只需要手动激活下该节点的组复制功能 ("START GROUP_REPLICATION;"),   
 即可正常加入到 MGR 组复制集群内并自动同步其他节点数据.   
注意：在 start group_replication 之前，必须先执行如下命令，不然会报如下错误：   
mysql> set global group_replication_single_primary_mode=OFF;   
mysql> set global group_replication_enforce_update_everywhere_checks=ON; 

2020-11-03T17:27:02.204557+08:00 0 \[ERROR] \[MY-011529] \[Repl] Plugin group_replication reported: 'The member configuration is not compatible with the group configuration. Variables such as group_replication_single_primary_mode or group_replication_enforce_update_everywhere_checks must have the same value on every server in the group. (member configuration option: \[group_replication_single_primary_mode], group configuration option: \[group_replication_enforce_update_everywhere_checks]).'   
2020-11-03T17:27:02.204730+08:00 0 \[System] \[MY-011503] \[Repl] Plugin group_replication reported: 'Group membership changed to 192.168.65.159:3308, 192.168.65.160:3308, 192.168.65.157:3308 on view 16043947113931758:7.' 

MGR 无论是单主模式还是多主模式，均可以实现高一致性，高容错性。

三、部署 ProxySQL

\#配置 yum 源

cat &lt;&lt;EOF | tee /etc/yum.repos.d/proxysql.repo

\[proxysql_repo]

name= ProxySQL

gpgcheck=1

EOF

\# 安装 proxysql

yum install -y proxysql

\#  启动 proxysql 服务

systemctl start proxysql

systemctl status proxysql

四、在 MGR 集群的 primary 主机上上添加相关账号

\#  前端监控账号

mysql> create user monitor@'%' identified by 'monitor';

mysql> grant all on \*.\* to monitor@'%';

\# 后端程序账号

mysql> create user run@'%' identified by 'run';

mysql> grant all on \*.\* to  run@'%';

五、配置 / etc/proxysql.cnf，

\# 前端登陆配置监控账号

\[root@master yum.repos.d]# mysql -uadmin -padmin -P6032 -h127.0.0.1

mysql> set mysql-monitor_username='monitor';

mysql> set mysql-monitor_password='monitor';

六、proxysql 配置相关组、用户、后端节点、以及读写分离规则等信息

\#配置默认组信息

mysql> insert into mysql_group_replication_hostgroups(writer_hostgroup,backup_writer_hostgroup,reader_hostgroup,offline_hostgroup,active) values(10,20,30,40,1);

组 ID 的含义：

写组：10

备写组：20

读组：30

离线组 (不可用)：40

mysql> select \* from mysql_group_replication_hostgroups;

\+------------------+-------------------------+------------------+-------------------+--------+-------------+-----------------------+-------------------------+---------+

| writer_hostgroup | backup_writer_hostgroup | reader_hostgroup | offline_hostgroup | active | max_writers | writer_is_also_reader | max_transactions_behind | comment |

\+------------------+-------------------------+------------------+-------------------+--------+-------------+-----------------------+-------------------------+---------+

| 10               | 20                      | 30               | 40                | 1      | 1           | 0                     | 0                       | NULL    |

\+------------------+-------------------------+------------------+-------------------+--------+-------------+-----------------------+-------------------------+---------+

1 row in set (0.00 sec)

\# 配置用户 (主要是添加程序端这个用户，也就是 run)

mysql> insert into mysql_users(username,password,default_hostgroup) values('run','run',10);

mysql> select \* from mysql_users;

\# 配置后端节点信息

mysql> insert into mysql_servers(hostgroup_id,hostname,port,comment) values(10,'192.168.65.157',3307,'write');

mysql> insert into mysql_servers(hostgroup_id,hostname,port,comment) values(30,'192.168.65.160',3307,'read');

mysql> insert into mysql_servers(hostgroup_id,hostname,port,comment) values(30,'192.168.65.161',3307,'read');

\# 配置读写分离参数

mysql> insert into mysql_query_rules(rule_id,active,match_digest,destination_hostgroup,apply)values(1,1,'^SELECT.\*FOR UPDATE$',10,1);

mysql> insert into mysql_query_rules(rule_id,active,match_digest,destination_hostgroup,apply)values(2,1,'^SELECT',30,1);

mysql> select rule_id,active,match_digest,destination_hostgroup,apply from mysql_query_rules;

\+---------+--------+----------------------+-----------------------+-------+

| rule_id | active | match_digest         | destination_hostgroup | apply |

\+---------+--------+----------------------+-----------------------+-------+

| 1       | 1      | ^SELECT.\*FOR UPDATE$ | 10                    | 1     |

| 2       | 1      | ^SELECT              | 30                    | 1     |

\+---------+--------+----------------------+-----------------------+-------+

\# 保存到磁盘并 load 到 runtime

\# 一共操作了 5 张表

mysql_users

mysql_servers

mysql_query_rules

global_variables

mysql_group_replication_hostgroups

前 4 张都需要执行 save 和 load 操作，save 是使内存数据永久存储到磁盘，load 事内存数据加载到 runtime 生效

mysql> save mysql users to disk;

mysql> save mysql servers to disk;

mysql> save mysql query rules to disk;

mysql> save mysql variables to disk;

mysql> save admin variables to disk;

mysql> load mysql users to runtime;

mysql> load mysql servers to runtime;

mysql> load mysql query rules to runtime;

mysql> load mysql variables to runtime;

mysql> load admin variables to runtime;

mysql> show tables;

\# 使用程序端账号并使用 6033 端口登陆，并执行 show databases; 得到结果，证明状态畅通

\[root@master ~]# mysql -urun -prun -P6033 -h127.0.0.1

mysql> show databases;

ERROR 2058 (HY000): Plugin caching_sha2_password could not be loaded: /usr/local/lib/plugin/caching_sha2_password.so: cannot open shared object file: No such file or directory

mysql>

\# 原因： 由于 mysql8.0 的加密方法变了。mysql8.0 默认采用 caching_sha2_password 的加密方式

解决方法：在 MGR 集群的 primary 机器上 (157) 执行：

mysql> ALTER USER  'run'@'%' IDENTIFIED WITH mysql_native_password BY 'run';

mysql> FLUSH PRIVILEGES;

mysql> show databases;

\+--------------------+

| Database           |

\+--------------------+

| information_schema |

| mysql              |

| performance_schema |

| sys                |

| test               |

\+--------------------+

mysql> select \* from test.t;  ===》160，执行多次均是 160 主机上的数据

七、主节点创建视图用于 proxysql 检测 MGR 状态

\#在 mysql 库添加一个监控脚本 ---》 在 primary master 的 mysql 上创建 proxysql 所需的表和函数

\#以下 SQL 在 mysql 执行

CREATE FUNCTION my_id() RETURNS TEXT(36) DETERMINISTIC NO SQL RETURN (SELECT @@global.server_uuid as my_id);$$

CREATE FUNCTION gr_member_in_primary_partition()

RETURN (SELECT IF( MEMBER_STATE='ONLINE' AND ((SELECT COUNT(\*) FROM

performance_schema.replication_group_members WHERE MEMBER_STATE NOT IN ('ONLINE', 'RECOVERING')) >=

((SELECT COUNT(\*) FROM performance_schema.replication_group_members)/2) = 0),

'YES', 'NO' ) FROM performance_schema.replication_group_members JOIN

performance_schema.replication_group_member_stats USING(member_id) where member_id=my_id());

CREATE VIEW gr_member_routing_candidate_status AS SELECT

sys.gr_member_in_primary_partition() as viable_candidate,

IF( (SELECT (SELECT GROUP_CONCAT(variable_value) FROM

performance_schema.global_variables WHERE variable_name IN ('read_only',

'super_read_only')) !='OFF,OFF'),'YES','NO') as read_only,

Count_Transactions_Remote_In_Applier_Queue as transactions_behind, Count_Transactions_in_queue as'transactions_to_ce' from  performance_schema.replication_group_member_stats where member_id=my_id();$$

DELIMITER ;

primary 节点：

mysql> select \* from sys.gr_member_routing_candidate_status;

\+------------------+-----------+---------------------+--------------------+

| viable_candidate | read_only | transactions_behind | transactions_to_ce |

\+------------------+-----------+---------------------+--------------------+

| YES              | NO        |                   0 |                  0 |

\+------------------+-----------+---------------------+--------------------+

备用节点：

mysql> select \* from sys.gr_member_routing_candidate_status;

\+------------------+-----------+---------------------+--------------------+

| viable_candidate | read_only | transactions_behind | transactions_to_ce |

\+------------------+-----------+---------------------+--------------------+

| YES              | YES       |                   0 |                  0 |

\+------------------+-----------+---------------------+--------------------+

1 row in set (0.00 sec)

八、读写分离测试

监控端：使用 admin 用户登陆 6032 端口

程序端：使用 run 用户登陆 6033 端口

节点端：使用 root 用户在 mysql 实例本地登录

\# 使用程序账号执行如下命令

mysql -uadmin -padmin -P6033 -h127.0.0.1

mysql>show databases;

mysql>create database test;

mysql>use test;

mysql>create table t (id int primary key);

mysql> insert into test.t(id) values(1);

\# 使用程序账号插入数据

mysql> insert into test.t(id) values(1);

ERROR 3098 (HY000): The table does not comply with the requirements by an external plugin.

原因：是 MGR 要求表必须有主键

解决方法：mysql> alter table test.t add primary key(id);

\# 在监控端查看：

mysql -uadmin -padmin -P6032 -h127.0.0.1

mysql> select \* from runtime_mysql_servers;


| hostgroup_id | hostname       | port | status  | weight | compression | max_connections | max_replication_lag | use_ssl | max_latency_ms | comment |
| -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- |
| 10           | 192.168.65.157 | 3307 | SHUNNED | 1      | 0           | 1000            | 0                   | 0       | 0              | write   |
| 30           | 192.168.65.161 | 3307 | SHUNNED | 1      | 0           | 1000            | 0                   | 0       | 0              | read    |
| 30           | 192.168.65.160 | 3307 | SHUNNED | 1      | 0           | 1000            | 0                   | 0       | 0              | read    |

\#监控端查看路由的状态

mysql> select hostgroup,schemaname,username,digest,digest_text,count_star from stats_mysql_query_digest;


| hostgroup | schemaname| username | digest      |digest_text  | count_star |
| -- | -- | -- | -- | -- | -- | 
| 30        | test               | run      | 0x0BC1AE031E4721D4 | SELECT \* FROM t WHERE ?=?                                 | 2          |
| 10        | information_schema | run      | 0x226CD90D52A2BA0B | select @@version_comment limit ?                          | 6          |
| 10        | test               | run      | 0x68D0B3544BA3210A | insert into test.t(id) values(?)                          | 2          |
| 30        | information_schema | run      | 0x3E1AF774B5167941 | select \* from test.t                                      | 5          |
| 10        | information_schema | run      | 0x02033E45904D3DF0 | show databases                                            | 4          |
| 10        | information_schema | run      | 0x58999D00F326815E | ALTER USER?@? IDENTIFIED WITH mysql_native_password BY ?  | 1          |
| 10        | test               | run      | 0x02033E45904D3DF0 | show databases                                            | 3          |
| 10        | information_schema | run      | 0xFF8947A6893D0C92 | ALTER USER ?@? IDENTIFIED WITH mysql_native_password BY ? | 1          |
| 10        | test               | run      | 0x99531AEFF718C501 | show tables                                               | 3          |
| 30        | information_schema | run      | 0x374D63441E8BE4C4 | select \* from runtime_mysql_servers                       | 1          |
| 10        | information_schema | run      | 0xB217E4D8B056AC0B | insert into test.t values(?)                              | 1          |
| 30        | information_schema | run      | 0x620B328FE9D6D71A | SELECT DATABASE()                                         | 1          |


=========== 读写分离测试成功 ==============
