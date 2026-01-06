| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-8月-14 | 2024-8月-14  |
| ... | ... | ... |
---

# InnoDB ReplicaSet：MySQL 副本集初体验.md

[toc]

## 资料

[InnoDB ReplicaSet：MySQL 副本集初体验](https://www.jianshu.com/p/3c435b211c66)

[![](https://cdn2.jianshu.io/default_avatar/6.jpg)
](https://www.jianshu.com/u/29ec69019733)

0.3832020.01.21 11:26:09字数 940阅读 904

*   MySQL 副本集（官方名称：MySQL InnoDB ReplicaSet）在 MySQL 8.0.19 版本（2020-01-13 Released）之后开始支持，本质还是是基于GTID的异步复制
*   角色分为Primary和Secondary
    *   Primary 即传统意义上的 Master，一个副本集只允许一个
    *   Secondary 即 Slave，允许一个或多个
*   通过 MySQL Shell 自带的AdminAPI创建、配置、删除等管理副本集
*   通过 MySQL Router 使用副本集，引导与连接方式与InnoDB Cluster和MGR有点类似，不同之处在于新增了`cluster_type = rs` 集群类型。

*   MySQL Shell 除了集成 AdminAPI 外还提供了 MySQL Sandbox 功能，可轻松部署用以测试的MySQL数据库实例
*   通过Sandbox一键部署三个MySQL实例

```
# mysqlsh
 MySQL  JS > dba.deploySandboxInstance(3306)
 MySQL  JS > dba.deploySandboxInstance(3307)
 MySQL  JS > dba.deploySandboxInstance(3308) 
```

*   指定root密码后自动创建MySQL实例，默认数据目录在 $HOME/mysql-sandboxes/port
*   ![](https://upload-images.jianshu.io/upload_images/20937113-ed5481c078f29917.png)
    
    image.png
    

创建集群管理账户
--------

*   创建集群管理员账户 `repl` 作为具有管理 InnoDB ReplicaSet 所需的权限集合

```
 MySQL  JS > dba.configureReplicaSetInstance('root@localhost:3306', {clusterAdmin: "'repl'@'%'", clusterAdminPassword: 'repl'}); 
```

*   ![](https://upload-images.jianshu.io/upload_images/20937113-d915d279a4934760.png)
    
    image.png
    

创建InnoDB副本集
-----------

*   连接到第一个MySQL实例3306，创建命名为 **renzy** 的副本集

```
 MySQL  JS > \connect root@localhost:3306
 MySQL  localhost:3306 ssl  JS > var rs = dba.createReplicaSet("renzy") 
```

*   ![](https://upload-images.jianshu.io/upload_images/20937113-de45c64c21d09617.png)
    
    image.png
    
*   查看副本集状态，默认第一个实例3306 选举为 **Primary** 节点
    

```
 MySQL  localhost:3306 ssl  JS > rs.status()
{
    "replicaSet": {
        "name": "renzy",
        "primary": "127.0.0.1:3306",
        "status": "AVAILABLE",
        "statusText": "All instances available.",
        "topology": {
            "127.0.0.1:3306": {
                "address": "127.0.0.1:3306",
                "instanceRole": "PRIMARY",
                "mode": "R/W",
                "status": "ONLINE"
            }
        },
        "type": "ASYNC"
    }
} 
```

添加节点到副本集
--------

```
 MySQL  localhost:3306 ssl  JS > rs.addInstance('localhost:3307')
 MySQL  localhost:3306 ssl  JS > rs.addInstance('localhost:3308') 
```

*   添加节点3307和3308到副本集涉及到数据拷贝有两种方式： `Clone 全量同步`和`Inremental recovery 增量同步`，本文使用 `Clone 全量同步`方式从 **Primary** 节点全量同步数据
    
    ![](https://upload-images.jianshu.io/upload_images/20937113-6ea10457c2102ed3.png)
    
    image.png
    
*   查看副本集状态，已添加到副本集的实例 3307 和 3308 的角色为 **Secondary** ，并自动与 **Primary** 节点 3306 建立复制关系
    

```
 MySQL  localhost:3306 ssl  JS > rs.status()
{
    "replicaSet": {
        "name": "renzy",
        "primary": "127.0.0.1:3306",
        "status": "AVAILABLE",
        "statusText": "All instances available.",
        "topology": {
            "127.0.0.1:3306": {
                "address": "127.0.0.1:3306",
                "instanceRole": "PRIMARY",
                "mode": "R/W",
                "status": "ONLINE"
            },
            "127.0.0.1:3307": {
                "address": "127.0.0.1:3307",
                "instanceRole": "SECONDARY",
                "mode": "R/O",
                "replication": {
                    "applierStatus": "APPLIED_ALL",
                    "applierThreadState": "Slave has read all relay log; waiting for more updates",
                    "receiverStatus": "ON",
                    "receiverThreadState": "Waiting for master to send event",
                    "replicationLag": null
                },
                "status": "ONLINE"
            },
            "127.0.0.1:3308": {
                "address": "127.0.0.1:3308",
                "instanceRole": "SECONDARY",
                "mode": "R/O",
                "replication": {
                    "applierStatus": "APPLIED_ALL",
                    "applierThreadState": "Slave has read all relay log; waiting for more updates",
                    "receiverStatus": "ON",
                    "receiverThreadState": "Waiting for master to send event",
                    "replicationLag": null
                },
                "status": "ONLINE"
            }
        },
        "type": "ASYNC"
    }
} 
```

副本集在线主从切换
---------

*   手工在线将实例 3308 切换为 **Primary** 节点

```
 MySQL  localhost:3306 ssl  JS > rs.setPrimaryInstance('127.0.0.1:3308') 
```

*   实例 3308 被提升为 Primary 后，副本集将自动将 实例 3306 降级为 **Secondary** 并与 3308 建立复制关系，副本集中其它实例 3307 也将自动与 3308 建立复制与同步

```
 MySQL  localhost:3306 ssl  JS > rs.status()
{
    "replicaSet": {
        "name": "renzy",
        "primary": "127.0.0.1:3308",
        "status": "AVAILABLE",
        "statusText": "All instances available.",
        "topology": {
            "127.0.0.1:3306": {
                "address": "127.0.0.1:3306",
                "instanceRole": "SECONDARY",
                "mode": "R/O",
                "replication": {
                    "applierStatus": "APPLIED_ALL",
                    "applierThreadState": "Slave has read all relay log; waiting for more updates",
                    "receiverStatus": "ON",
                    "receiverThreadState": "Waiting for master to send event",
                    "replicationLag": null
                },
                "status": "ONLINE"
            },
            "127.0.0.1:3307": {
                "address": "127.0.0.1:3307",
                "instanceRole": "SECONDARY",
                "mode": "R/O",
                "replication": {
                    "applierStatus": "APPLIED_ALL",
                    "applierThreadState": "Slave has read all relay log; waiting for more updates",
                    "receiverStatus": "ON",
                    "receiverThreadState": "Waiting for master to send event",
                    "replicationLag": null
                },
                "status": "ONLINE"
            },
            "127.0.0.1:3308": {
                "address": "127.0.0.1:3308",
                "instanceRole": "PRIMARY",
                "mode": "R/W",
                "status": "ONLINE"
            }
        },
        "type": "ASYNC"
    }
} 
```

副本集Primary节点故障
--------------

*   手工杀掉 **Primary** 节点进程

```
 root     18975     1  0 16:52 ?        00:01:23 /root/mysql-sandboxes/3308/bin/mysqld --defaults-file=/root/mysql-sandboxes/3308/my.cnf --user=root 
```

*   副本集 **无法自动进行故障转移** ，需要人工介入修复
    
    ![](https://upload-images.jianshu.io/upload_images/20937113-a69638816b6bed12.png)
    
    image.png
    
*   手工将 **Secondary** 节点 3306 强制提升为 **Primary**

```
 MySQL  localhost:3306 ssl  JS > rs.forcePrimaryInstance("127.0.0.1:3306") 
```

*   副本集恢复后，因 3308 不可用副本集状态显示为 `AVAIABLE_PARITAL` (部分可用)
    
    ![](https://upload-images.jianshu.io/upload_images/20937113-96164ec816a7c952.png)
    
    image.png
    

*   与使用MySQL Router连接MGR或InnoDB Cluster一样，副本集也可以通过MySQL Router访问，首先通过--bootstrap选项引导副本集

```
mysqlrouter --user=root --bootstrap root@localhost:3308 
```

![](https://upload-images.jianshu.io/upload_images/20937113-75f1dfb01e8194a2.png)

image.png

MySQL Router 通过R/W自动连接到Primary
------------------------------

*   启动MySQL Router

```
mysqlrouter -c /usr/local/mysql-router-8.0.19-linux-glibc2.12-x86_64/mysqlrouter.conf &

// 通过 MySQL Router R/W 端口可以自动识别并连接到 Primary

mysql: [Warning] Using a password on the command line interface can be insecure.
+--------+
| @@port |
+--------+
|   3308 |
+--------+

mysql: [Warning] Using a password on the command line interface can be insecure.
+------------+-----------+------+------------+--------------------------------------+
| Server_id  | Host      | Port | Master_id  | Slave_UUID                           |
+------------+-----------+------+------------+--------------------------------------+
| 1587786506 | 127.0.0.1 | 3307 | 2457151498 | cb569215-3b29-11ea-80f4-02000aba3f9e |
| 3616586416 | 127.0.0.1 | 3306 | 2457151498 | c23ee4be-3b29-11ea-815a-02000aba3f9e |
+------------+-----------+------+------------+--------------------------------------+ 
```

*   副本集主从切换后，MySQL Router R/W自动指向被选举出来的新的 **Primary**
    
    ![](https://upload-images.jianshu.io/upload_images/20937113-083781731d2c162d.png)
    
    image.png
    
    ![](https://upload-images.jianshu.io/upload_images/20937113-2c098df7215872e8.png)
    
    image.png
    

1.MySQL Router 可以很好的兼容InnoDB ReplicaSet，可自动识别到副本集主从切换，将新的R/W连接指向Primary。  
2.InnoDB ReplicaSet 当前还不完善，可作为新特性在测试环境试用，但因为不支持自动故障转移，Primary 宕机整个副本集将不可用。  
3.InnoDB ReplicaSet 目前仅支持基于GTID的**异步**复制，哪怕支持自动切换，数据也有丢失风险，所以离真正部署到生产环境还有一段路要走。  
4.InnoDB ReplicaSet 暂时还没有类似芒果DB完善的投票选举机制，故障切换时也会存在脑裂风险。  
总之，InnoDB副本集虽存在诸多不足之处，但作为2020年Oracle的开餐甜点其带来的效果也让众多MySQL DBA眼前一亮，既然有了副本集，相信 **Sharding** 也是未来可期，你觉得呢？