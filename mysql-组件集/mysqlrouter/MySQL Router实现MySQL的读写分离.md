| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-8月-13 | 2024-8月-13  |
| ... | ... | ... |
---

# MySQL Router实现MySQL的读写分离

[toc]

## 资料

[MySQL Router实现MySQL的读写分离](https://www.cnblogs.com/f-ck-need-u/p/9276639.html)

总结就二十玩玩就好，只是玩具，需要应用端来控制读写的是实例，并不支持可配置的sql分发机制。

## 原文

MySQL Router是MySQL官方提供的一个轻量级MySQL中间件，用于取代以前老版本的SQL proxy。

既然MySQL Router是一个数据库的中间件，那么MySQL Router必须能够分析来自前面客户端的SQL请求是写请求还是读请求，以便决定这个SQL请求是发送给master还是slave，以及发送给哪个master、哪个slave。这样，**MySQL Router就实现了MySQL的读写分离，对MySQL请求进行了负载均衡。** 

因此，MySQL Router的前提是后端实现了MySQL的主从复制。

**MySQL Router很轻量级，只能通过不同的端口来实现简单的读/写分离，且读请求的调度算法只能使用默认的rr(round-robin)**，更多一点、更复杂一点的能力都不具备。所以，在实现MySQL Router时，需要自行配置好后端MySQL的高可用。高可用建议通过Percona XtraDB Cluster或MariaDB Galera或MySQL官方的group replication实现，如果实在没有选择，还可以通过MHA实现。

所以，一个简单的MySQL Router部署图如下。

![](https://images2018.cnblogs.com/blog/733013/201807/733013-20180707105817406-163197375.png)

本文将使用MySQL Router分别实现后端无MySQL主从高可用情形的读写分离，至于为什么不实现后端有MySQL高可用的读写分离情形。在我看来，MySQL Router只是一个玩具，不仅功能少，而且需要在应用程序代码中指定读/写的不同端口(见后文关于配置文件的解释)，在实际环境中应该没人会这样用。

以下是实验环境。

| 角色名 | 主机IP | MySQL版本 | 数据状态 |
| --- | --- | --- | --- |
| MySQL Router | 192.168.100.21 | MySQL 5.7.22 | 无 |
| master | 192.168.100.22 | MySQL 5.7.22 | 全新实例 |
| slave1 | 192.168.100.23 | MySQL 5.7.22 | 全新实例 |
| slave2 | 192.168.100.24 | MySQL 5.7.22 | 全新实例 |

因为后端MySQL主从复制没有实现高可用，所以只有一个master节点负责写操作。

所有后端MySQL节点都是刚安装好的全新MySQL实例，所以直接开启主从复制即可。如果是已有数据的主从复制，需要先保证它们已同步好，方法见：[将slave恢复到master指定的坐标](https://www.cnblogs.com/f-ck-need-u/p/9155003.html#blog4.2)。

2.1 安装MySQL Router
------------------

二进制版MySQL Router下载地址：[https://dev.mysql.com/downloads/router/](https://dev.mysql.com/downloads/router/)  
rpm仓库：[http://repo.mysql.com/yum/mysql-tools-community/el/7/x86_64/](http://repo.mysql.com/yum/mysql-tools-community/el/7/x86_64/)

此处使用二进制版的[MySQL Router 2.1.6](https://dev.mysql.com/get/Downloads/MySQL-Router/mysql-router-2.1.6-linux-glibc2.12-x86-64bit.tar.gz)。

```null
tar xf mysqlrouter-2.1.6-linux-glibc2.12-x86-64bit.tar.gz
mv mysqlrouter-2.1.6-linux-glibc2.12-x86-64bit /usr/local/mysqlrouter

```

这就完了，就这么简单。

解压二进制包后，解压目录下有以下几个文件。

```null
[root@s1 mr]# ls
bin  data  include  lib  run  share

```

**bin目录**下只有一个二进制程序mysqlrouter，这也是MySQL Router的主程序。

share目录下有示例配置文件和示例SysV风格的启动脚本，但是很不幸该脚本基于debian平台，在redhat系列上需要修改和安装一些东西才能使用。所以后文我自己写了一个centos下的SysV脚本。

```null
[root@s1 mr]# ls share/doc/mysqlrouter/
License.txt  README.txt  sample_mysqlrouter.conf  sample_mysqlrouter.init

```

最后，将主程序添加到PATH环境变量中。

```null
echo "PATH=$PATH:/usr/local/mysqlrouter/bin" >/etc/profile.d/mysqlrouter.sh
chmod +x /etc/profile.d/mysqlrouter.sh
source /etc/profile.d/mysqlrouter.sh

```

2.2 启动并测试MySQL Router
---------------------

以下是上述实验环境的配置文件，这里只有一个master节点`192.168.100.22:3306`，如果有多个写节点(master)，则使用逗号分隔各节点。关于配置文件，后文会解释。

```null
[DEFAULT]
config_folder = /etc/mysqlrouter
logging_folder = /usr/local/mysqlrouter/log
runtime_folder = /var/run/mysqlrouter

[logger]
level = INFO

[routing:slaves]
bind_address = 192.168.100.21:7001
destinations = 192.168.100.23:3306,192.168.100.24:3306
mode = read-only
connect_timeout = 1

[routing:masters]
bind_address = 192.168.100.21:7002
destinations = 192.168.100.22:3306
mode = read-write
connect_timeout = 2

```

然后在MySQL Router所在的机器上创建上面使用的目录。

```null
shell> mkdir /etc/mysqlrouter /usr/local/mysqlrouter/log /var/run/mysqlrouter

```

这样就可以启动MySQL Router来提供服务了(启动之前，请确保后端MySQL已被配置好主从复制)。

```null
[root@s1 mr]# mysqlrouter &
[1] 16122
```

查看监听状态。这里监听的两个端口7001和7002是前端连接MySQL Router用的，它们用来接收前端发送的SQL请求，并按照读、写规则，将SQL请求路由到后端MySQL主从节点。

```null
[root@s1 mr]# netstat -tnlp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address        Foreign Address  State   PID/Program name 
tcp        0      0 0.0.0.0:6032         0.0.0.0:*        LISTEN  1231/proxysql    
tcp        0      0 0.0.0.0:6033         0.0.0.0:*        LISTEN  1231/proxysql    
tcp        0      0 0.0.0.0:22           0.0.0.0:*        LISTEN  1152/sshd        
tcp        0      0 192.168.100.21:7001  0.0.0.0:*        LISTEN  16122/mysqlrouter
tcp        0      0 127.0.0.1:25         0.0.0.0:*        LISTEN  2151/master      
tcp        0      0 192.168.100.21:7002  0.0.0.0:*        LISTEN  16122/mysqlrouter
tcp6       0      0 :::22                :::*             LISTEN  1152/sshd        
tcp6       0      0 ::1:25               :::*             LISTEN  2151/master      

```

查看日志：

```null

[root@s1 mr]# cat /usr/local/mysqlrouter/log/mysqlrouter.log 
2018-07-07 10:14:29 INFO  [7f8a8e253700] [routing:slaves] started: listening on 192.168.100.21:7001; read-only

2018-07-07 10:14:29 INFO  [7f8a8ea54700] [routing:masters] started: listening on 192.168.100.21:7002; read-write

```

最后进行测试即可。测试前，先在后端Master上授权MySQL Router节点允许连接，它将会复制到两个slave节点上。

```null
mysql> grant all on *.* to root@'192.168.100.%' identified by 'P@ssword1!';

```

连上MySQL Router的7002端口，这个端口是负责写的端口。由于没有配置主从高可用，所以，简单测试下是否能写即可。

```null
[root@s1 mr]# mysql -uroot -pP@ssword1! -h192.168.100.21 -P7002 -e 'select @@server_id;'
mysql: [Warning] Using a password on the command line interface can be insecure.
+-------------+
| @@server_id |
+-------------+
|         110 |
+-------------+

[root@s1 mr]# mysql -uroot -pP@ssword1! -h192.168.100.21 -P7002 -e 'create database mytest;'
mysql: [Warning] Using a password on the command line interface can be insecure.

[root@s1 mr]# mysql -uroot -pP@ssword1! -h192.168.100.21 -P7002 -e 'show databases;'
mysql: [Warning] Using a password on the command line interface can be insecure.
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| mytest             |
| performance_schema |
| sys                |
+--------------------+

```

再测试下各slave节点，是否能实现rr调度算法的读请求的负载均衡。

```null
[root@s1 mr]# mysql -uroot -pP@ssword1! -h192.168.100.21 -P7001 -e 'select @@server_id;' 
mysql: [Warning] Using a password on the command line interface can be insecure.
+-------------+
| @@server_id |
+-------------+
|         120 |
+-------------+

[root@s1 mr]# mysql -uroot -pP@ssword1! -h192.168.100.21 -P7001 -e 'select @@server_id;'
mysql: [Warning] Using a password on the command line interface can be insecure.
+-------------+
| @@server_id |
+-------------+
|         130 |
+-------------+

[root@s1 mr]# mysql -uroot -pP@ssword1! -h192.168.100.21 -P7001 -e 'show databases;'
mysql: [Warning] Using a password on the command line interface can be insecure.
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| mytest             |
| performance_schema |
| sys                |
+--------------------+

```

显然，测试的结果一切正常。

这样看来MySQL Router好简单，确实好简单。只需提供一个合理的配置文件，一切都完成了。那么，下面解释下MySQL Router的配置文件。

MySQL Router的配置文件也很简单，需要配置的项不多。

mysql router默认会寻找安装目录下的"mysqlrouter.conf"和家目录下的".mysqlrouter.conf"。也可以在二进制程序mysqlrouter命令下使用"-c"或者"--config"手动指定配置文件。

MySQL router的配置文件是片段式的，常用的就3个片段：[DEFAULT]、[logger]、[routing:NAME]。片段名称区分大小写，且只支持单行"#"或";"注释，不支持行中、行尾注释。

以上面示例的配置文件为例。

```null
[DEFAULT]
config_folder = /etc/mysqlrouter
logging_folder = /usr/local/mysqlrouter/log
runtime_folder = /var/run/mysqlrouter

[logger]
level = INFO

[routing:slaves]
bind_address = 192.168.100.21:7001
destinations = 192.168.100.23:3306,192.168.100.24:3306
mode = read-only
connect_timeout = 1

[routing:masters]
bind_address = 192.168.100.21:7002
destinations = 192.168.100.22:3306
mode = read-write
connect_timeout = 2
```

**1.DEFAULT片段的配置。** 

`[DEFAULT]`片段通常配置配置文件的目录、日志的目录、MySQL router运行时的目录(如pid文件)。

例如：

```null
[DEFAULT]
config_folder=/etc/mysqlrouter   # 指定额外的配置文件目录，该目录下的conf文件都会被加载
logging_folder=/usr/local/mysqlrouter/log  # 指定日志目录，日志文件名为mysqlrouter.log
runtime_folder=/var/run/mysqlrouter        # 指定运行时目录，默认为/run/mysqlrouter

```

**2.logger片段的配置。** 

`[logger]`片段只有一个选项，设置日志的记录级别。

```null
[logger]
level=debug   # 有debug、info(默认)、warning、error、fatal，不区分大小写

```

**3.routing片段的配置。** 

`[routing:NAME]`是MySQL router主要部分，设置不同的路由实例，其中NAME可以随意命名。如`[routing:slaves]`、`[routing:masters]`。

在routing配置片段，可以设置的选项包括：

*   (1).`bind_address`和`bind_port`  
    bind\_address和bind\_port是mysql router监听前端SQL请求的地址和端口。其中**端口是MySQL Router要求强制提供**的，但可以不用bind\_port绑定，因为它可用通过bind\_address的`IP:PORT`格式指定。  
    一个routing规则中只能设置一个地址监听指令，但可以通过"0.0.0.0"来监听主机上所有的地址。如果没有提供监听地址，则默认监听127.0.0.1。  
    另外，监听地址不能出现在destinations指令指定的列表中。  
    示例如下：

```null
[routing:slaves]
bind_port = 7001
[routing:slaves]
bind_address = 192.168.100.21
bind_port = 7001
[routing:slaves]
bind_address = 192.168.100.21:7001

```

一般来说，通过不同端口实现读/写分离，并非好方法，最大的原因是需要在应用程序代码中指定这些连接端口。但是，MySQL Router只能通过这种方式实现读写分离，所以**MySQL Router拿来当玩具玩玩就好**。

*   (2).`destinations`  
    定义routing规则的转发目标，格式为`HOST:PORT`，HOST可以是IP也可以是主机名，多个转发目标使用逗号分隔。如定义的目标列表是多个slave。

```null
[routing:slaves]
bind_address = 192.168.100.21:7001
destinations = 192.168.100.23:3306,192.168.100.24:3306
[routing:masters]
bind_address = 192.168.100.21:7002
destinations = 192.168.100.22:3306,192.168.100.100:3306

```

*   (3).`mode`  
    MySQL router提供两种mode：**read-only和read-write**。这两种方式会产生不同的转发调度方式。
    *   设置为read-write，常用于设置destinations为master时，实现master的高可用。
        *   调度方式：当MySQL router第一次收到客户端请求时，会将请求转发给destinations列表中的第一个目标，第二次收到客户端请求还是会转发给第一个目标，只有当第一个目标联系不上(如关闭了MySQL服务、宕机等)才会联系第二个目标，如果所有目标都联系不上，MySQL Router会中断。这种调度方式被称为"**first-available**"。
        *   当联系上了某一个目标时，MySQL Router会将其缓存下来，下次收到请求还会继续转发给该目标。既然是缓存的目标，就意味着在MySQL Router重启之后就会失效。
        *   所以通过MySQL Router实现读写分离的写时，可以设置多个master，让性能好的master放在destinations列表的第一个位置，其他的master放在后面的位置作为备用master。
    *   设置为read-only，常用于设置destinations为slave时，实现MySQL读请求负载均衡。
        *   调度方式：当MySQL route收到客户端请求时，会从destinations列表中的第一个目标开始向后轮询(round-robin)，第一个请求转发给第一个目标，第二个请求转发给第二个目标，转发给最后一个目标之后的下一个请求又转发给第一个目标。如果第一个目标不可用，会依次向后检查，直到目标可用，如果所有目标都不可用，则MySQL Router中断。
        *   那些不可用的目标会暂时被隔离，并且mysql router会不断的检查它们的状况，当重新可用时会重新加入到目标列表。
*   (4).`connect_timeout`  
    MySQL Router联系destinations的超时时间，默认为1秒，值的范围为1-65536。应该尽量设置值小点，免得等待时间过长。  
    对于read-write模式，可以将超时时间设置的稍长一点点，防止误认为主master不可用而去联系备master。  
    对于read-only模式，可以将超时时间设置的稍短一点点，因为这种模式下是destinations列表轮询的，即使误判了影响也不会太大。
*   (5).其他选项  
    还能设置一些其他的指令，如使用的协议、最大请求数等，但是都可以不用设置使用默认值，它们都是MySQL Router结合MySQL优化过的一些选项，本身已经较完美了。

配置文件大概就这些内容，配置好后，记得先创建default片段中涉及到的目录。之后就可以启动mysql router提供读/写分离服务了。

MySQL Router只提供了一个主程序(bin目录下的mysqlrouter)，且该程序只能启动，没有停止选项，所以只能使用kill命令来杀掉进程。

MySQL Router也提供了示例启动脚本，该脚本在位置为`$basedir/share/doc/mysqlrouter/sample_mysqlrouter.init`，但是该脚本是基于Debian平台的，在CentOS上需要设置和安装一些东西，所以不用它，自己写个粗糙点的脚本即可。

```null
shell> vim /etc/init.d/mysqlrouter
#!/bin/bash

# chkconfig: - 78 30
# Description: Start / Stop MySQL Router

DAEMON=/usr/local/mysqlrouter
proc=$DAEMON/bin/mysqlrouter
DAEMON_OPTIONS="-c ${DAEMON}/mysqlrouter.conf"

. /etc/init.d/functions

start() {
    if [ -e /var/lock/subsys/mysqlrouter ]; then
        action "MySQL Router is working" /bin/false
    else
        $proc $DAEMON_OPTIONS & &>/dev/null
        retval=$?
        echo
    if [ $retval -eq 0 ]; then
             touch /var/lock/subsys/mysqlrouter
        action "Starting MySQL Router" /bin/true
        else
        echo "Starting MySQL Router Failure"
        fi
    fi
}
    
stop() {
    if [ -e /var/lock/subsys/mysqlrouter ]; then
        killall $proc
        retval=$?
        echo
        if [ $retval -eq 0 ]; then
            rm -f /var/lock/subsys/mysqlrouter
            action "Stoping MySQL Router" /bin/true
        fi
    else
        action "MySQL Router is not working" /bin/false
    fi
}

status() {
    if [ -e /var/lock/subsys/mysqlrouter ]; then
        echo "MySQL Router is running"
    else
        echo "MySQL Router is not running"
    fi
}

case "$1" in
    start)
        start
        sleep 1
        ;;
     stop)
        stop
        sleep 1
        ;;
    restart)
        stop
        start
        sleep 1
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        retval=1
        ;;
esac

exit $retval   
```

然后赋予执行权限。

```null
shell> chmod +x /etc/init.d/mysqlrouter

```

**转载请注明出处：[https://www.cnblogs.com/f-ck-need-u/p/9276639.html](https://www.cnblogs.com/f-ck-need-u/p/9276639.html)**

**如果觉得文章不错，不妨给个打赏，写作不易，各位的支持，能激发和鼓励我更大的写作热情。谢谢！**  

