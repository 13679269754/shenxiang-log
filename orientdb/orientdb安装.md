| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-9月-10 | 2024-9月-10  |
| ... | ... | ... |
---
# orientdb安装.md

[toc]

## 1.官方网站  
官方网站  
https://orientdb.org/  


官方文档  
https://orientdb.org/docs/3.0.x/  

## 2.环境准备
### 2.1 下载网站
https://repo1.maven.org/maven2/com/orientechnologies/
https://github.com/orientechnologies/orientdb/releases?expanded=true&page=7&q=3.0.19
### 2.2 下载解压
```bash
wget https://repo1.maven.org/maven2/com/orientechnologies/orientdb-community/3.0.19/orientdb-community-3.0.19.tar.gz  

tar -zxvf orientdb-community-3.0.19.tar.gz   
mv orientdb-community-3.0.19 /usr/local/data/orientdb/orientdb-server
[root@localhost orientdb-server]# ll 
drwxr-xr-x 2 root root 4096 12月 27 17:27 bin 
drwxr-xr-x 3 mysql mysql 4096 5月 15 2019 config 
drwxr-xr-x 3 root root 4096 5月 16 2019 databases 
-r--r--r-- 1 mysql mysql 71754 5月 15 2019 history.txt 
drwxr-xr-x 2 root root 4096 12月 27 17:27 lib 
-r--r--r-- 1 mysql mysql 11357 5月 15 2019 license.txt 
drwxr-xr-x 2 mysql mysql 4096 5月 15 2019 log 
drwxr-xr-x 2 mysql mysql 4096 12月 27 17:27 plugins 
-r--r--r-- 1 mysql mysql 3227 5月 15 2019 readme.txt 
drwxr-xr-x 2 mysql mysql 4096 5月 15 2019 www
```

### 2.3 安装java
JDK：建议jdk8版本（3.0版本要求jdk8）
```bash
rpm -ivh jdk-8u341-linux-x64.rpm
[root@localhost orientdb]# java -version 
java version "1.8.0_341" 
Java(TM) SE Runtime Environment (build 1.8.0_341-b10) 
Java HotSpot(TM) 64-Bit Server VM (build 25.341-b10, mixed mode)
```

### 2.4 创建用户
```bash
groupadd orientdb
useradd -g orientdb orientdb
#export JAVA_HOME=/usr/local/java
#export PATH=$PATH:$JAVA_HOME/bin
export ORIENTDB_HOME=/usr/local/data/orientdb/orientdb-server
export PATH=$PATH:$ORIENTDB_HOME/bin
chown -R orientdb. /usr/local/data/orientdb/orientdb-server/
```
## 3.单节点安装搭建
### 3.1 初始化启动

启动数据库使用`server.sh`  
并在启动过程中提示配置root账号密码 
如不采用此方式启动，则会随机生成root账号的密码。  
因此单实例启动时建议用该方式启动。注意要用orientdb用户去做./server.sh  

启动完成后即可 ctrl + c 关闭即可  
文件属主确认   
首次启动后会在databases目录下生成OSystem，如果该目录属主不是orientdb则需要手动修改为orientdb，否则下次启动时异常（报没有权限操作OSystem目录的错误）   

### 3.2 手动脚本启动方式
此脚本是官方的启动脚本，也是使用 server.sh 进行启动
配置脚本orientdb.sh
为了在系统上使用该脚本，您需要编辑该文件以定义两个变量：安装目录的路径和要运行数据库服务器的用户。  
` vi $ORIENTDB_HOME/bin/orientdb.sh`
```bash
#!/bin/sh
# OrientDB service script
#
# Copyright (c) Orient Technologies LTD (http://www.orientechnologies.com)
# chkconfig: 2345 20 80
# description: OrientDb init script
# processname: orientdb.sh
# You have to SET the OrientDB installation directory here
ORIENTDB_DIR="YOUR_ORIENTDB_INSTALLATION_PATH"
ORIENTDB_USER="USER_YOU_WANT_ORIENTDB_RUN_WITH"
ORIENTDB_DIR="/usr/local/data/orientdb/orientdb-server" 
ORIENTDB_USER="orientdb"
编辑变量以指示安装目录。编辑变量以指示要运行数据库服务器的用户
在root下执行，否则需要输入 orientdb用户 密码
[root@localhost bin]# ./orientdb.sh start
Starting OrientDB server daemon...
[root@localhost bin]# ./orientdb.sh status
OrientDB server daemon is running with PID: 11735
[root@localhost bin]# ps -ef |grep orientdb
[root@localhost bin]# ./orientdb.sh stop
OrientDB server daemon is already not running
[root@localhost bin]# ./orientdb.sh status
OrientDB server daemon is NOT running
```
### 3.3 service 启动方式
安装脚本
不同的操作系统和 Linux 发行版在管理系统守护程序方面具有不同的过程，以及在启动和关闭期间启动和停止它们的过程。
以下是基于 init 和 systemd 的 unix 系统以及 Mac OS X 的通用指南。
#### 3.3.1 为 init 安装
许多类Unix操作系统，如FreeBSD，大多数较旧的Linux发行版，以及当前版本的Debian，  Ubuntu及其衍生产品，都使用SysV风格的init变体来执行这些进程。  
这些通常是使用命令 service 管理此类进程的系统。  
要在基于 init 的 unix 或 Linux 系统上安装 OrientDB 即服务，请将修改后的文件从 $ORIENTDB_HOME/bin/orientdb.sh 复制到 /etc/init.d/ 中：  
```bash
# cp $ORIENTDB_HOME/bin/orientdb.sh /etc/init.d/orientdb
完成此操作后，您可以使用以下命令 service 启动和停止 OrientDB
# service orientdb start
Starting OrientDB server daemon...  
```
#### 3.3.2 为 systemd 安装
大多数较新版本的Linux，特别是在基于RPM的发行版中，如Red Hat，Fedora和CentOS，以及Debian和Ubuntu的未来版本都使用systemd进行这些进程。  
这些是使用该命令systemctl管理此类进程的系统。  
OrientDB的软件包包含一个基于systemd发行版的服务描述符文件 orientdb.service。
放置在目录中。要安装 OrientDB，请复制 bin/orientdb.service to /etc/systemd/system 目录（检查此内容，可能取决于发行版）。  
cp bin/orientdb.service /etc/systemd/system/  
编辑文件：
```bash
# vi /etc/systemd/system/orientdb.service
#
# Copyright (c) OrientDB LTD (http://http://orientdb.com/)
#

[Unit]
Description=OrientDB Server
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=ORIENTDB_USER
Group=ORIENTDB_GROUP
ExecStart=/usr/local/data/orientdb/orientdb-server/bin/server.sh
修改bin目录下orientdb.service
设置正确的用户和组。您可能希望使用绝对路径而不是环境变量。
User=orientdb
Group=orientdb
ExecStart=$ORIENTDB_HOME/bin/server.sh
保存此文件后，您可以使用以下命令systemctl启动和停止 OrientDB 服务器
# systemctl start orientdb.service
此外，保存文件后，可以通过发出以下命令将 systemd 设置为在引导期间自动启动数据库服务器：orientdb.serviceenable
# systemctl enable orientdb.service
Synchronizing state of orientdb.service with SysV init with /usr/lib/systemd/systemd-sysv-install...
Executing /usr/lib/systemd/systemd-sysv-install enable orientdb
Created symlink from /etc/systemd/system/multi-user.target.wants/orientdb.service to /etc/systemd/system/orientdb.service.
```