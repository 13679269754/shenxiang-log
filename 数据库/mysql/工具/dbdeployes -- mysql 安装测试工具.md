[dbdeployer MySQL沙盒部署详解 - easydba - 博客园](https://www.cnblogs.com/easydb/p/13741861.html) 

 ### 一、工具介绍

*   前几日用[`mysql-sandbox`](https://github.com/datacharmer/mysql-sandbox)来搭建`MySQL8.0`新版本时发现用不了，提示需要使用`dbdeployer`才行，瞬间觉得`mysql-sandbox`不香了，只好咬咬牙来熟悉`dbdeployer`了。
*   `dbdeployer`是使用`go`语言重构的`sandbox`，和`sandbox`同一个作者。
*   当然，`dbdeployer`延续了`sandbox`所有功能。可实现一键部署不同架构、不同版本的数据库环境。如，MySQL 主从复制、GTID 模式复制、MySQL 组复制(单主模式、多主模式等)
*   完整的数据库类型支持及版本，可在安装完 dbdeployer 后使用`dbdeployer admin capabilities`命令进行查看，以下是当前已支持数据库及组件类型

1.  \-- pxc (Percona XtraDB Cluster)
2.  \-- mysql-shell
3.  \-- mysql (MySQL server)
4.  \-- percona (Percona Server)
5.  \-- mariadb
6.  \-- tidb (TiDB isolated server)
7.  \-- ndb (MySQL NDB Cluster)

### 二、工具安装

*   OS：`centos8`
*   dbdeployer：`1.54.0`
*   mysql：`8.0.20`

#### 2.1 `dbdeployer`工具下载

直接到github下载release包即可：

[https://github.com/datacharmer/dbdeployer/releases](https://github.com/datacharmer/dbdeployer/releases)

#### 2.2 解压

软件解压后实际只有一个单独的编译好的可执行文件

```null
tar -zxvf dbdeployer-1.54.0.linux.tar.gz

```

#### 2.3 赋予可执行权限

```null
chmod +x dbdeployer-1.54.0.linux

```

#### 2.4 移动到系统可执行目录下方便使用

```null
mv dbdeployer-1.54.0.linux /usr/local/bin/dbdeployer

```

#### 2.5 验证是否可以使用

```null
[root@db01 tmp]
dbdeployer version 1.54.0
[root@db01 tmp]
dbdeployer makes MySQL server installation an easy task.
Runs single, multiple, and replicated sandboxes.

Usage:
  dbdeployer [command]

Available Commands:
  admin           sandbox management tasks
  cookbook        Shows dbdeployer samples
  defaults        tasks related to dbdeployer defaults
  delete          delete an installed sandbox
  delete-binaries delete an expanded tarball
  deploy          deploy sandboxes
  downloads       Manages remote tarballs
  export          Exports the command structure in JSON format
  global          Runs a given command in every sandbox
  help            Help about any command
  import          imports one or more MySQL servers into a sandbox
  info            Shows information about dbdeployer environment samples
  init            initializes dbdeployer environment
  sandboxes       List installed sandboxes
  unpack          unpack a tarball into the binary directory
  update          Gets dbdeployer newest version
  usage           Shows usage of installed sandboxes
  use             uses a sandbox
  versions        List available versions

Flags:
      --config string           configuration file (default "/root/.dbdeployer/config.json")
  -h, --help                    help for dbdeployer
      --sandbox-binary string   Binary repository (default "/root/opt/mysql")
      --sandbox-home string     Sandbox deployment directory (default "/root/sandboxes")
      --shell-path string       Which shell to use for generated scripts (default "/usr/bin/bash")
      --skip-library-check      Skip check for needed libraries (may cause nasty errors)
  -v, --version                 version for dbdeployer

Use "dbdeployer [command] --help" for more information about a command.


```

#### 2.6 初始化环境

安装dbdeployer之后，可以立即使用以下命令为操作做好准备的环境，此命令会创建必要的目录，然后下载最新的MySQL二进制文件，在默认的位置解压它们。

```null
dbdeployer init

```

三、基本使用
------

#### 3.1 自行下载MySQL并解压

访问 [https://downloads.mysql.com/archives/community/](https://downloads.mysql.com/archives/community/) 可下载各不同的MySQL

```null
dbdeployer unpack /tmp/mysql-8.0.20-linux-glibc2.12-x86_64.tar.xz

```

#### 3.2 使用dbdeployer工具下载MySQL并解压

##### 3.2.1 查看dbdeployer工具支持下载的软件包

```null
[root@mysql8 ~]
Available tarballs  ()
                              name                                 OS     version     flavor        size   minimal 
---------------------------------------------------------------- ------- --------- ------------- -------- ---------
 tidb-master-linux-amd64.tar.gz                                   Linux     3.0.0   tidb           26 MB           
 mysql-8.0.16-linux-glibc2.12-x86_64.tar.xz                       Linux    8.0.16   mysql         461 MB           
 mysql-8.0.16-linux-x86_64-minimal.tar.xz                         Linux    8.0.16   mysql          44 MB   Y       
 mysql-5.7.27-linux-glibc2.12-x86_64.tar.gz                       Linux    5.7.27   mysql         645 MB           
 mysql-8.0.17-linux-glibc2.12-x86_64.tar.xz                       Linux    8.0.17   mysql         480 MB           
 mysql-8.0.17-linux-x86_64-minimal.tar.xz                         Linux    8.0.17   mysql          45 MB   Y       
 mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz                       Linux    5.7.26   mysql         645 MB           
 mysql-5.6.44-linux-glibc2.12-x86_64.tar.gz                       Linux    5.6.44   mysql         329 MB           
 mysql-5.5.62-linux-glibc2.12-x86_64.tar.gz                       Linux    5.5.62   mysql         199 MB           
 mysql-8.0.15-linux-glibc2.12-x86_64.tar.xz                       Linux    8.0.15   mysql         376 MB           
 mysql-8.0.13-linux-glibc2.12-x86_64.tar.xz                       Linux    8.0.13   mysql         394 MB           
 mysql-5.7.25-linux-glibc2.12-x86_64.tar.gz                       Linux    5.7.25   mysql         645 MB           
 mysql-5.6.43-linux-glibc2.12-x86_64.tar.gz                       Linux    5.6.43   mysql         329 MB           
 mysql-5.5.61-linux-glibc2.12-x86_64.tar.gz                       Linux    5.5.61   mysql         199 MB           
 mysql-5.1.73-linux-x86_64-glibc23.tar.gz                         Linux    5.1.73   mysql         134 MB           
 mysql-5.0.96.tar.xz                                              Linux    5.0.96   mysql         5.5 MB   Y       
 mysql-5.1.72.tar.xz                                              Linux    5.1.72   mysql          10 MB   Y       
 mysql-5.5.61.tar.xz                                              Linux    5.5.61   mysql         6.6 MB   Y       
 mysql-5.5.62.tar.xz                                              Linux    5.5.62   mysql         6.6 MB   Y       
 mysql-5.6.43.tar.xz                                              Linux    5.6.43   mysql         9.0 MB   Y       
 mysql-5.6.44.tar.xz                                              Linux    5.6.44   mysql         9.1 MB   Y       
 mysql-5.7.25.tar.xz                                              Linux    5.7.25   mysql          23 MB   Y       
 mysql-5.7.26.tar.xz                                              Linux    5.7.26   mysql          23 MB   Y       
 mysql-5.0.96-linux-x86_64-glibc23.tar.gz                         Linux    5.0.96   mysql         127 MB           
 mysql-4.1.22.tar.xz                                              Linux    4.1.22   mysql         4.6 MB   Y       
 mysql-cluster-gpl-7.6.10-linux-glibc2.12-x86_64.tar.gz           Linux    7.6.10   ndb           916 MB           
 mysql-cluster-8.0.16-dmr-linux-glibc2.12-x86_64.tar.gz           Linux    8.0.16   ndb           1.1 GB           
 mysql-cluster-gpl-7.6.11-linux-glibc2.12-x86_64.tar.gz           Linux    7.6.11   ndb           916 MB           
 mysql-cluster-8.0.17-rc-linux-glibc2.12-x86_64.tar.gz            Linux    8.0.17   ndb           1.1 GB           
 mysql-shell-8.0.17-linux-glibc2.12-x86-64bit.tar.gz              Linux    8.0.17   mysql-shell    30 MB           
 mysql-5.7.28-linux-glibc2.12-x86_64.tar.gz                       Linux    5.7.28   mysql         725 MB           
 mysql-8.0.18-linux-glibc2.12-x86_64.tar.xz                       Linux    8.0.18   mysql         504 MB           
 mysql-8.0.18-linux-x86_64-minimal.tar.xz                         Linux    8.0.18   mysql          48 MB   Y       
 mysql-8.0.19-linux-x86_64-minimal.tar.xz                         Linux    8.0.19   mysql          45 MB           
 mysql-cluster-8.0.19-linux-glibc2.12-x86_64.tar.gz               Linux    8.0.19   ndb           1.2 GB           
 mysql-5.7.29-linux-glibc2.12-x86_64.tar.gz                       Linux    5.7.29   mysql         665 MB           
 mysql-cluster-8.0.20-linux-glibc2.12-x86_64.tar.gz               Linux    8.0.20   ndb           1.2 GB           
 mysql-8.0.20-linux-x86_64-minimal.tar.xz                         Linux    8.0.20   mysql          44 MB   Y       
 mysql-5.7.30-linux-glibc2.12-x86_64.tar.gz                       Linux    5.7.30   mysql         660 MB           
 mysql-8.0.21-linux-glibc2.17-x86_64-minimal.tar.xz               Linux    8.0.21   mysql          48 MB   Y       
 Percona-Server-8.0.20-11-Linux.x86_64.glibc2.12-minimal.tar.gz   Linux    8.0.20   percona       103 MB   Y       
 mysql-5.7.31-linux-glibc2.12-x86_64.tar.gz                       Linux    5.7.31   mysql         376 MB           
 mysql-shell-8.0.21-linux-glibc2.12-x86-64bit.tar.gz              Linux    8.0.21   shell          43 MB       

```

##### 3.2.2 下载并解压指定软件包

使用`dbdeployer downloads get file_name`，从上面的列表中复制需要下载的版本并粘贴文件名。例如：

```null
[root@mysql8 ~]
Downloading mysql-5.7.31-linux-glibc2.12-x86_64.tar.gz
.........105 MB.........210 MB.........315 MB.....  376 MB
File /root/mysql-5.7.31-linux-glibc2.12-x86_64.tar.gz downloaded
Checksum matches
Unpacking tarball mysql-5.7.31-linux-glibc2.12-x86_64.tar.gz to $HOME/opt/mysql/5.7.31
.........100.........200.........300302
Renaming directory /root/opt/mysql/mysql-5.7.31-linux-glibc2.12-x86_64 to /root/opt/mysql/5.7.31

```

#### 3.3 检查DBdeployer的已安装/可用的tarball二进制软件包列表

```null
[root@mysql8 ~]
Basedir: /root/opt/mysql
5.7.31  8.0.20  8.0.21 

```

```null
[root@mysql8 ~]
/root/opt
└── mysql
    ├── 5.7.31
    ├── 8.0.20
    └── 8.0.21

```

#### 3.4 快速部署实例`dbdeployer deploy -h`

##### 3.4.1 该命令可以部署单个，多个或复制的MySQL沙箱实例

```null
multiple    创建多个独立的mysql
replication 创建复制环境的mysql
single      创建单节点的mysql

```

##### 3.4.2 如果要使用多个相同版本的沙箱，且没有任何复制关系，请使用`dbdeployer deploy multiple -h`,例如：

```null
dbdeployer deploy multiple 8.0.21
ps -ef | grep mysqld

```

默认创建三个节点，我们可以用`-n`选项来指定需要创建的节点数，`--force`强制覆盖之前的安装

```null
dbdeployer deploy multiple -n 2 --force 8.0.21

```

##### 3.4.3 如果需要安装一主多从的复制环境，请使用`dbdeployer deploy replication -h`，例如：

```null
dbdeployer deploy replication 5.7.31

```

```null
[root@mysql8 rsandbox_5_7_31]# ./status_all 
REPLICATION  /root/sandboxes/rsandbox_5_7_31
master : master on  -  port	19832 (19832)
node1 : node1 on  -  port	19833 (19833)
node2 : node2 on  -  port	19834 (19834)

```

默认为一主两从三节点版，同样可以使用`-n`选项来指定节点数，`--gtid`指定为gtid复制模式

```null
dbdeployer deploy replication 5.7.31 -n 2 --gtid --force

```

```null
[root@mysql8 rsandbox_5_7_31]# ./status_all 
REPLICATION  /root/sandboxes/rsandbox_5_7_31
master : master on  -  port	19832 (19832)
node1 : node1 on  -  port	19833 (19833)

```

##### 3.4.4 如果只想测试单个实例MySQL，请使用`dbdeployer deploy single -h`，例如：

```null
dbdeployer deploy single 8.0.20

```

##### 3.4.5 部署一套多主MGR集群

```null
dbdeployer deploy --topology=group replication 8.0.20

```

### 四、实例组操作

一键部署完成后会在 $HOME/sandboxes 目录下生成各实例组对应的数据目录，该目录包含以下信息(部分信息)

*   一键启停该组所有实例的脚本
*   一键登录数据库脚本
*   一键重置该组所有实例的脚本（清除所有测试数据并重新初始化成全新的主从）
*   主从实例的数据目录（主库为 master，从库分别为 node1、node2 依次递增）
*   各实例的配置文件
*   默认用户授权命令
*   单独启停实例命令
*   binlog、relaylog 解析命令

##### 4.1 使用示例

```null
[root@mysql8 ~]# cd $HOME/sandboxes/group_msb_8_0_20
[root@mysql8 group_msb_8_0_20]# ls
check_nodes       metadata_all  n3     node3           sbdescription.json  status_all        test_sb_all      use_all_slaves
clear_all         n1            node1  replicate_from  send_kill_all       stop_all          use_all
initialize_nodes  n2            node2  restart_all     start_all           test_replication  use_all_masters

```

##### 4.2 查看该组所有实例状态

```null
[root@mysql8 group_msb_8_0_20]# ./status_all 
MULTIPLE  /root/sandboxes/group_msb_8_0_20
node1 : node1 on  -  port	22021 (22021)
node2 : node2 on  -  port	22022 (22022)
node3 : node3 on  -  port	22023 (22023)

```

##### 4.3 一键重启该组所有实例

```null
[root@mysql8 group_msb_8_0_20]# ./restart_all 
# executing 'stop' on /root/sandboxes/group_msb_8_0_20
executing 'stop' on node3
stop /root/sandboxes/group_msb_8_0_20/node3
executing 'stop' on node2
stop /root/sandboxes/group_msb_8_0_20/node2
executing 'stop' on node1
stop /root/sandboxes/group_msb_8_0_20/node1
# executing 'start' on /root/sandboxes/group_msb_8_0_20
executing "start" on node 1
. sandbox server started
executing "start" on node 2
. sandbox server started
executing "start" on node 3
. sandbox server started

```

##### 4.4 单独操作某一节点，需进入对应节点数据目录

```null
[root@mysql8 group_msb_8_0_20]
[root@mysql8 node1]
add_option            clone_from       data          metadata        replicate_from      send_kill      start      test_sb
after_start           connection.conf  grants.mysql  my              restart             show_binlog    start.log  tmp
clear                 connection.json  init_db       my.sandbox.cnf  sbdescription.json  show_log       status     use
clone_connection.sql  connection.sql   load_grants   mysqlsh         sb_include          show_relaylog  stop

```

##### 4.5 登陆指定实例

```null
[root@mysql8 node1]
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 8
Server version: 8.0.20 MySQL Community Server - GPL

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

node1 [localhost:22021] {msandbox} ((none)) > 

```

##### 4.6 msyql日志管理

每个实例下有便捷日志脚本

```null
show_log    
show_binlog
show_relaylog

```

##### 4.7 相关mysql用户密码

| user name | password | privileges |
| --- | --- | --- |
| root@localhost | msandbox | all on \*.\* with grant option |
| msandbox@localhost | msandbox | all on \*.\* |
| rsandbox@127.% | rsandbox | REPLICATION SLAVE |

##### 4.8 本地root用户登陆

```null
mysql -uroot -pmsandbox -S /tmp/mysql_sandbox8020.sock

```

### 五、dbdeployer 常用管理命令

以下是使用 dbdeployer 过程中总结的常用命令，详细使用方式可查看文末 dbdeployer 文档链接。

##### 5.1 更新dbdeployer

```null
dbdeployer update

```

##### 5.2 列出以解压的MySQL版本

```null
dbdeployer versions

```

##### 5.3 列出已安装的沙箱实例

```null
dbdeployer sandboxes

```

##### 5.4 删除已安装沙箱实例

```null
dbdeployer delete multi_msb_8_0_21

```

##### 5.5 锁定及解锁一个或多个沙箱实例，以防止删除

```null
[root@mysql8 ~]
Sandbox group_msb_8_0_20 locked
[root@mysql8 ~]
Sandbox group_msb_8_0_20 unlocked


```

### 六、相关连接

*   dbdeployer 官方下载：[https://github.com/datacharmer/dbdeployer/releases](https://github.com/datacharmer/dbdeployer/releases)
*   dbdeployer 官方手册：[https://github.com/datacharmer/dbdeployer](https://github.com/datacharmer/dbdeployer)
*   MySQL 各历史版本下载链接：[https://downloads.mysql.com/archives/community/](https://downloads.mysql.com/archives/community/)
*   dbdeployer 的功能特性：[https://github.com/datacharmer/dbdeployer/blob/master/docs/features.md](https://github.com/datacharmer/dbdeployer/blob/master/docs/features.md)

#### 因为有悔，所以披星戴月；因为有梦，所以奋不顾身！ 个人博客首发：`easydb.net` 微信公众号：`easydb` 关注我，不走丢！