在MySQL 8.0 之前， 我们假设一下有一条烂SQL，

```


1.  `mysql`
    
2.  `select * from t1 order by rand() ;`
    


```

以多个线程在跑，导致CPU被跑满了，其他的请求只能被阻塞进不来。那这种情况怎么办？ 

**大概有以下几种解决办法：** 

1.  设置max_execution_time 来阻止太长的读SQL。那可能存在的问题是会把所有长SQL都给KILL 掉。有些必须要执行很长时间的也会被误杀。
    
2.  自己写个脚本检测这类语句，比如order by rand()， 超过一定时间用Kill query thread_id 给杀掉。
    

那能不能不要杀掉而让他正常运行，但是又不影响其他的请求呢？

那mysql 8.0 引入的资源组（resource group，后面简写微RG）可以基本上解决这类问题。

比如我可以用 RG 来在SQL层面给他限制在特定的一个CPU核上，这样我就不管他，让他继续运行，如果有新的此类语句，让他排队好了。

为什么说基本呢？目前只能绑定CPU资源，其他的暂时不行。

那我来演示下如何使用RG。

**创建一个资源组user_ytt. 这里解释下各个参数的含义，**

1.  type = user 表示这是一个用户态线程，也就是前台的请求线程。如果type=system，表示后台线程，用来限制mysql自己的线程，比如Innodb purge thread,innodb read thread等等。
    
2.  vcpu 代表cpu的逻辑核数，这里0-1代表前两个核被绑定到这个RG。可以用lscpu，top等列出自己的CPU相关信息。
    
3.  thread_priority 设置优先级。user 级优先级设置大于0。
    

```


1.  `mysql`
    
2.  `mysql> create resource group user_ytt type = user  vcpu = 0-1 thread_priority=19 enable;`
    
3.  `Query OK, 0 rows affected (0.03 sec)`
    


```

RG相关信息可以从 information_schema.resource_groups 系统表里检索。

```


1.  `mysql`
    
2.  `mysql> select * from information_schema.resource_groups;`
    
3.  `+---------------------+---------------------+------------------------+----------+-----------------+`
    
4.  `| RESOURCE_GROUP_NAME | RESOURCE_GROUP_TYPE | RESOURCE_GROUP_ENABLED | VCPU_IDS | THREAD_PRIORITY |`
    
5.  `+---------------------+---------------------+------------------------+----------+-----------------+`
    
6.  `| USR_default         | USER                |                      1 | 0-3      |               0 |`
    
7.  `| SYS_default         | SYSTEM              |                      1 | 0-3      |               0 |`
    
8.  `| user_ytt            | USER                |                      1 | 0-1      |              19 |`
    
9.  `+---------------------+---------------------+------------------------+----------+-----------------+`
    
10.  `3 rows in set (0.00 sec)`
    


```

我们来给语句select guid from t1 group by left(guid,8) order by rand() 赋予RG user_ytt。

```


1.  `mysql> show processlist;`
    
2.  `+-----+-----------------+-----------+------+---------+-------+------------------------+-----------------------------------------------------------+`
    
3.  `| Id  | User            | Host      | db   | Command | Time  | State                  | Info                                                      |`
    
4.  `+-----+-----------------+-----------+------+---------+-------+------------------------+-----------------------------------------------------------+`
    
5.  `|   4 | event_scheduler | localhost | NULL | Daemon  | 10179 | Waiting on empty queue | NULL                                                      |`
    
6.  `| 240 | root            | localhost | ytt  | Query   |   101 | Creating sort index    | select guid from t1 group by left(guid,8) order by rand() |`
    
7.  `| 245 | root            | localhost | ytt  | Query   |     0 | starting               | show processlist                                          |`
    
8.  `+-----+-----------------+-----------+------+---------+-------+------------------------+-----------------------------------------------------------+`
    
9.  `3 rows in set (0.00 sec)`
    


```

找到连接240对应的thread_id。

```


1.  `mysql`
    
2.  `mysql> select thread_id from performance_schema.threads where processlist_id = 240;`
    
3.  `+-----------+`
    
4.  `| thread_id |`
    
5.  `+-----------+`
    
6.  `|       278 |`
    
7.  `+-----------+`
    
8.  `1 row in set (0.00 sec)`
    


```

给这个线程278赋予RG user_ytt。没报错就算成功了。

```


1.  `mysql`
    
2.  `mysql> set resource group user_ytt for 278;`
    
3.  `Query OK, 0 rows affected (0.00 sec)`
    


```

当然这个是在运维层面来做的，我们也可以在开发层面结合 MYSQL HINT 来单独给这个语句赋予RG。比如：

```


1.  `mysql`
    
2.  `mysql> select /*+ resource_group(user_ytt) */guid from t1 group by left(guid,8) order by rand().`
    
3.  `...`
    
4.  `8388602 rows in set (4 min 46.09 sec)`
    


```

**RG的限制：** 

1.  Linux 平台上需要开启 CAPSYSNICE 特性。比如我机器上用systemd 给mysql 服务加上
    
    systemctl edit mysql@80   
    [Service]   
    AmbientCapabilities=CAP_SYS_NICE
    
2.  mysql 线程池开启后RG失效。
    
3.  freebsd,solaris 平台thread_priority 失效。
    
4.  目前只能绑定CPU，不能绑定其他资源。
    