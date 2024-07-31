
**问题描述**

> **MySQL版本：5.7.16，5.7.17，5.7.21**

存在多个半同步从库时，如果参数 rpl\_semi\_sync\_master\_wait\_for\_slave\_count=1，启动第1个半同步从库时可以正常启动，启动第2个半同步从库后有很大概率 slave\_io_thread 停滞,（复制状态正常，Slave\_IO\_Running: Yes，Slave\_SQL\_Running: Yes，但是完全不同步主库 binlog ）

**复现步骤**

1\. 主库配置参数如下：

```
rpl_semi_sync_master_wait_for_slave_count = 1  
rpl_semi_sync_master_wait_no_slave = OFF  
rpl_semi_sync_master_enabled = ON  
rpl_semi_sync_master_wait_point = AFTER_SYNC
```

2\. 启动从库A的半同步复制 start slave，查看从库A复制正常

3\. 启动从库B的半同步复制 start slave，查看从库B，复制线程正常，但是不同步主库 binlog

**分析过程**

首先弄清楚这个问题 ，需要先结合MySQL其他的一些状态信息，尤其是主库的 dump 线程状态来进行分析：

**1\. 从库A启动复制后，主库的半同步状态已启动：** 

```
show global status like '%semi%';  
+--------------------------------------------+-----------+  
| Variable_name | Value |  
+--------------------------------------------+-----------+  
| Rpl_semi_sync_master_clients | 1   
....  
| Rpl_semi_sync_master_status | ON   
...  

```

再看主库的 dump 线程，也已经启动：

```
select * from performance_schema.threads where PROCESSLIST_COMMAND='Binlog Dump GTID'\G  
*************************** 1. row ***************************  
THREAD_ID: 21872  
NAME: thread/sql/one_connection  
TYPE: FOREGROUND  
PROCESSLIST_ID: 21824  
PROCESSLIST_USER: universe_op  
PROCESSLIST_HOST: 172.16.21.5  
PROCESSLIST_DB: NULL  
PROCESSLIST_COMMAND: Binlog Dump GTID  
PROCESSLIST_TIME: 300  
PROCESSLIST_STATE: Master has sent all binlog to slave; waiting for more updates  
PROCESSLIST_INFO: NULL  
PARENT_THREAD_ID: NULL  
ROLE: NULL  
INSTRUMENTED: YES  
HISTORY: YES  
CONNECTION_TYPE: TCP/IP  
THREAD_OS_ID: 24093
```

再看主库的 error log，也显示 dump 线程（21824）启动成功，其启动的半同步复制：

```
2018-05-25T11:21:58.385227+08:00 21824 [Note] Start binlog_dump to master_thread_id(21824) slave_server(1045850818), pos(, 4)  
2018-05-25T11:21:58.385267+08:00 21824 [Note] Start semi-sync binlog_dump to slave (server_id: 1045850818), pos(, 4)  
2018-05-25T11:21:59.045568+08:00 0 [Note] Semi-sync replication switched ON at (mysql-bin.000005, 81892061)
```

**2\. 从库B启动复制后，主库的半同步状态，还是只有1个半同步从库** Rpl\_semi\_sync\_master\_clients=1：

```
show global status like '%semi%';  
+--------------------------------------------+-----------+  
| Variable_name | Value |  
+--------------------------------------------+-----------+  
| Rpl_semi_sync_master_clients | 1   
...  
| Rpl_semi_sync_master_status | ON   
...
```

再看主库的 dump 线程，这时有3个 dump 线程，但是新起的那两个一直为 starting 状态：

再看主库的 error log，21847 这个新的 dump 线程一直没起来，直到1分钟之后从库 retry ( Connect\_Retry 和 Master\_Retry_Count 相关)，主库上又启动了1个 dump 线程 21850，还是起不来，并且 21847 这个僵尸线程还停不掉：

```
2018-05-25T11:31:59.586214+08:00 21847 [Note] Start binlog_dump to master_thread_id(21847) slave_server(873074711), pos(, 4)  
2018-05-25T11:32:59.642278+08:00 21850 [Note] While initializing dump thread for slave with UUID <f4958715-5ef3-11e8-9271-0242ac101506>, found a zombie dump thread with the same UUID. Master is killing the zombie dump thread(21847).  
2018-05-25T11:32:59.642452+08:00 21850 [Note] Start binlog_dump to master_thread_id(21850) slave_server(873074711), pos(, 4)
```

**3\. 到这里我们可以知道，从库B  slave\_io\_thread 停滞的根本原因是因为主库上对应的 dump 线程启动不了。** 如何进一步分析线程调用情况？推荐使用 gstack 或者 pstack（实为gstack软链）来查看线程调用栈，其用法很简单：gstack <process-id>

**4\. 看主库的 gstack，可以看到 24102 线程（旧的复制 dump 线程）堆栈**：

![](https://mmbiz.qpic.cn/mmbiz_png/q2OyEbfuqCuGQRyVaHvjUcLtzWxVSicibrj9ibqGuMA5y5WbUc4Ughx8WHeP1rQHoDprJUrX2ficDDjwv1YaZP2o6w/640?wx_fmt=png)

可以看到 24966 线程（新的复制 dump 线程）堆栈：  

![](https://mmbiz.qpic.cn/mmbiz_png/q2OyEbfuqCuGQRyVaHvjUcLtzWxVSicibrOV6TU1QicOKnywOXdDwZngf1KQqpusCVg9VZcFicjsrbchUL4PyOHlPA/640?wx_fmt=png)

两线程都在等待 Ack_Receiver 的锁，而线程 21875 在持有锁，等待select：

```
Thread 15 (Thread 0x7f0bce7fc700 (LWP 21875)):  
#0 0x00007f0c028c9bd3 in select () from /lib64/libc.so.6  
#1 0x00007f0be7589070 in Ack_receiver::run (this=0x7f0be778dae0 <ack_receiver>) at /export/home/pb2/build/sb_0-19016729-1464157976.67/mysql-5.7.13/plugin/semisync/semisync_master_ack_receiver.cc:261  
#2 0x00007f0be75893f9 in ack_receive_handler (arg=0x7f0be778dae0 <ack_receiver>) at /export/home/pb2/build/sb_0-19016729-1464157976.67/mysql-5.7.13/plugin/semisync/semisync_master_ack_receiver.cc:34  
#3 0x00000000011cf5f4 in pfs_spawn_thread (arg=0x2d68f00) at /export/home/pb2/build/sb_0-19016729-1464157976.67/mysql-5.7.13/storage/perfschema/pfs.cc:2188  
#4 0x00007f0c03c08dc5 in start_thread () from /lib64/libpthread.so.0  
#5 0x00007f0c028d276d in clone () from /lib64/libc.so.6
```

理论上 select 不应hang， Ack_receiver 中的逻辑也不会死循环，请教公司大神黄炎进行一波源码分析。

**5.  semisync\_master\_ack_receiver.cc 的以下代码形成了对互斥锁的抢占, 饿死了其他竞争者：** 

```
void Ack_receiver::run()  
{  
...  
while(1)  
{  
mysql_mutex_lock(&m_mutex);  
...  
select(...);  
...  
mysql_mutex_unlock(&m_mutex);  
}  
...  
}
```

在 mysql\_mutex\_unlock 调用后，应适当增加其他线程的调度机会。

**试验:** 在 mysql\_mutex\_unlock 调用后增加 sched_yield();，可验证问题现象消失。

**结论**

*   从库 slave\_io\_thread 停滞的根本原因是主库对应的 dump thread 启动不了；
    
*   rpl\_semi\_sync\_master\_wait\_for\_slave\_count=1 时，启动第一个半同步后，主库 ack\_receiver 线程会不断的循环判断收到的 ack 数量是否 >= rpl\_semi\_sync\_master\_wait\_for\_slave\_count，此时判断为 true，ack\_receiver基本不会空闲一直持有锁。此时启动第2个半同步，对应主库要启动第2个 dump thread，启动 dump thread 要等待 ack_receiver 锁释放，一直等不到，所以第2个 dump thread 启动不了。
    

相信各位DBA同学看了后会很震惊，“什么？居然还有这样的bug...”，**这里要说明一点，****这个bug 触发是有几率的，但是几率又很大。** 这个问题已经由我司大神提交了 bug 和 patch：https://bugs.mysql.com/bug.php?id=89370，加上本人提交SR后时不时的催一催，官方终于确认修复在 5.7.23（官方最终另有修复方法，没采纳这个 patch）。

最后或许会有疑问“既然是概率，有没有办法降低概率呢？”，尤其是不具备及时升级版本条件的同学，**