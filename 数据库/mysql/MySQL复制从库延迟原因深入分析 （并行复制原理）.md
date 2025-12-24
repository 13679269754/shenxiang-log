| operator | createtime   | updatetime   |
| -------- | ------------ | ------------ |
| shenx    | 2023-11 月-02 | 2023-11 月-02 |
| ... | ... | ... |
---
# MySQL复制从库延迟原因深入分析 （并行复制原理）

[toc]

### 原理参考
[5.7的MTS](https://www.cnblogs.com/konggg/p/16359474.html)
[8.0的writeset并行复制](https://cloud.tencent.com/developer/article/1684252)

### 背景介绍
----

近来一套业务系统，从库一直处于延迟状态，无法追上主库，导致业务风险较大。

从资源上看，从库的CPU、IO、网络使用率较低，不存在服务器压力过高导致回放慢的情况；从库开启了并行回放；在从库上执行 SHOW PROCESSLIST 看到没有回放线程阻塞，回放一直在持续；解析relay log日志文件，发现其中并没大事务回放。

过程分析
----

### 现象确认

收到运维同事的反馈，有一套从库延迟的非常厉害，提供了`SHOW SLAVE STATUS`延迟的截图信息

![](https://mmbiz.qpic.cn/sz_mmbiz_png/zYias49R9JlRpEHFDc3yYibpMVEpR2teQXhzTeaeqcj3hfKEszsyOxCIVmjLH0LlbdttdibAaUQ7Ths8frBCiaiabqw/640?wx_fmt=png&from=appmsg)

持续观察了一阵`SHOW SLAVE STATUS`的变化，发现pos点位信息在不停的变化，Seconds_Behind_master 也是不停的变化的，总体趋势还在不停的变大。

### 资源使用

观察了服务器资源使用情况，可以看到占用非常低

![](https://mmbiz.qpic.cn/sz_mmbiz_png/zYias49R9JlRpEHFDc3yYibpMVEpR2teQXCG9xialXEGN3ZhW0QibY14iaYgnk81ly9Dm0ogZJrQUqUWe62zVXSDiaLA/640?wx_fmt=png&from=appmsg)

观察从库进程情况，基本上只能看到有一个线程在回放工作

![](https://mmbiz.qpic.cn/sz_mmbiz_png/zYias49R9JlRpEHFDc3yYibpMVEpR2teQXbtGlrwy7qWRpfPt7XMhR6HOY8swyOlVXPDHKibA4rT04OG6tKkBxzZQ/640?wx_fmt=png&from=appmsg)

### 并行回放参数说明

在主库设置了`binlog_transaction_dependency_tracking = WRITESET`

在从库设置了`slave_parallel_type = LOGICAL_CLOCK`和`slave_parallel_workers = 64`

### error log日志对比

从error log中取并行回放的日志进行分析

```
$ grep 010559 100werror3306.log | tail -n 3  
2024-01-31T14:07:50.172007+08:00 6806 [Note] [MY-010559] [Repl] Multi-threaded slave statistics for channel 'cluster': seconds elapsed = 120; events assigned = 3318582273; worker queues filled over overrun level = 207029; waite  
d due a Worker queue full = 238; waited due the total size = 0; waited at clock conflicts = 348754579743300 waited (count) when Workers occupied = 34529247 waited when Workers occupied = 76847369713200  
  
2024-01-31T14:09:50.078829+08:00 6806 [Note] [MY-010559] [Repl] Multi-threaded slave statistics for channel 'cluster': seconds elapsed = 120; events assigned = 3319256065; worker queues filled over overrun level = 207029; waite  
d due a Worker queue full = 238; waited due the total size = 0; waited at clock conflicts = 348851330164000 waited (count) when Workers occupied = 34535857 waited when Workers occupied = 76866419841900  
  
2024-01-31T14:11:50.060510+08:00 6806 [Note] [MY-010559] [Repl] Multi-threaded slave statistics for channel 'cluster': seconds elapsed = 120; events assigned = 3319894017; worker queues filled over overrun level = 207029; waite  
d due a Worker queue full = 238; waited due the total size = 0; waited at clock conflicts = 348943740455400 waited (count) when Workers occupied = 34542790 waited when Workers occupied = 76890229805500  

```

上述信息的详细解释，可以参考 [MTS性能监控你知道多少](https://mp.weixin.qq.com/s?__biz=MzkzMTIzMDgwMg==&mid=2247502503&idx=1&sn=bf79ea7d658d9228345e9e74886f02a7&scene=21#wechat_redirect)

去掉了发生次数比较少的统计，显示了一些关键数据的对比

![](https://mmbiz.qpic.cn/sz_mmbiz_png/zYias49R9JlRpEHFDc3yYibpMVEpR2teQXLavnrSVpyUqnkm53JiaSEbOPcsG9CHSn6nahRkRSPNxWRUgqLQpQgicQ/640?wx_fmt=png&from=appmsg)

可以发现自然时间120，回放的协调线程有90多秒由于无法并行回放而进入等待，有近20秒是由于没有空闲的work线程进入等待，折算下来协调线程工作的时间只有10秒左右。

### 并行度统计

众所周知，MySQL 从库并行回放主要依赖于 binlog 中的  last_commmitted 来做判断，如果事务的 last_commmitted 相同，则基本上可以认为这些事务可以并行回放，下面从环境中获取一个relay log进行并行回放的大概统计

```
$ mysqlsqlbinlog --no-defaults mysql-bin.046638 |grep -o 'last_committed.*' | sed 's/=/ /g' | awk '{print $2}' |sort -n | uniq -c |awk 'BEGIN {print "last_commited group_count Percentage"} {count[$2]=$1   ; sum+=$1} END {for (i in count) printf "%d %d %.2f%%\n", i, count[i], (count[i]/sum)*100|"sort -k 1,1n"}' | awk '{if($2>=1 && $2 <11){sum+=$2}} END {print sum}'    235703``$ mysqlsqlbinlog --no-defaults mysql-bin.046638 |grep -o 'last_committed.*' | sed 's/=/ /g' | awk '{print $2}' |sort -n | uniq -c |awk 'BEGIN {print "last_commited group_count Percentage"} {count[$2]=$1   ; sum+=$1} END {for (i in count) printf "%d %d %.2f%%\n", i, count[i], (count[i]/sum)*100|"sort -k 1,1n"}' | awk '{if($2>10){sum+=$2}} END {print sum}'   314694   
```

上述第一条命令，是统计 last_commmitted 相同的事务数量在1-10个，即并行回放程度较低或者是无法并行回放，这些事务总数量为235703，占43%，详细解析并行回放度比较低的事务分布，可以看出这部分 last_commmitted 基本上都是单条的，都需要等待先序事务回放完成后，自己才能进行回放，这就会造成前面日志中观察到的协调线程等待无法并行回放而进入等待的时间比较长的情况

```
$ mysqlbinlog --no-defaults mysql-bin.046638 |grep -o 'last_committed.*' | sed 's/=/ /g' | awk '{print $2}' |sort -n | uniq -c |awk 'BEGIN {print "last_commited group_count Percentage"} {count[$2]=$1; sum+=$1} END {for (i in count) printf "%d %d %.2f%%\n", i, count[i], (count[i]/sum)*100|"sort -k 1,1n"}' | awk '{if($2>=1 && $2 <11) {print $2}}' | sort | uniq -c  
 200863 1  
  17236 2  
     98 3  
     13 4  
      3 5  
      1 7  

```

第二条命令统计 last_commmitted 相同的事务数量超过10个的总事务数，其数量为314694，占57%，详细解析了这些并行回放度比较高的事务，可以看到每一组是在6500~9000个事务

```
$ mysqlsqlbinlog --no-defaults mysql-bin.046638 |grep -o 'last_committed.*' | sed 's/=/ /g' | awk '{print $2}' |sort -n | uniq -c |awk 'BEGIN {print "last_commited group_count Percentage"} {count[$2]=$1  
; sum+=$1} END {for (i in count) printf "%d %d %.2f%%\n", i, count[i], (count[i]/sum)*100|"sort -k 1,1n"}' | awk '{if($2>11){print $0}}' | column -t  
last_commited  group_count  Percentage  
1              7340         1.33%  
11938          7226         1.31%  
23558          7249         1.32%  
35248          6848         1.24%  
46421          7720         1.40%  
59128          7481         1.36%  
70789          7598         1.38%  
82474          6538         1.19%  
93366          6988         1.27%  
104628         7968         1.45%  
116890         7190         1.31%  
128034         6750         1.23%  
138849         7513         1.37%  
150522         6966         1.27%  
161989         7972         1.45%  
175599         8315         1.51%  
189320         8235         1.50%  
202845         8415         1.53%  
218077         8690         1.58%  
234248         8623         1.57%  
249647         8551         1.55%  
264860         8958         1.63%  
280962         8900         1.62%  
297724         8768         1.59%  
313092         8620         1.57%  
327972         9179         1.67%  
344435         8416         1.53%  
359580         8924         1.62%  
375314         8160         1.48%  
390564         9333         1.70%  
407106         8637         1.57%  
422777         8493         1.54%  
438500         8046         1.46%  
453607         8948         1.63%  
470939         8553         1.55%  
486706         8339         1.52%  
503562         8385         1.52%  
520179         8313         1.51%  
535929         7546         1.37%  

```

### last_committed 机制介绍

主库的参数`binlog_transaction_dependency_tracking`用于指定如何生成其写入二进制日志的依赖信息，以帮助从库确定哪些事务可以并行执行，即通过该参数控制 last_commmitted 的生成机制，参数可选值有 **COMMIT_ORDER**、**WRITESET**、**SESSION_WRITESET**。从下面这段代码，很容易看出来三种参数关系：

1.  基础算法为 **COMMIT_ORDER**。
    
2.  **WRITESET** 算法是在 **COMMIT_ORDER** 基础上再计算一次。
    
3.  **SESSION_WRITESET** 算法是在 **WRITESET** 基础上再计算一次。
    

![](https://mmbiz.qpic.cn/sz_mmbiz_png/zYias49R9JlRpEHFDc3yYibpMVEpR2teQXK55cIRQ0jPve1icVbG3oCxj4ULLMB3HdXBwkDLNw7QY3FR0VcUjNlhw/640?wx_fmt=png&from=appmsg)

由于当前数据库实例设置的是**WRITESET**，因此只需关注 **COMMIT_ORDER** 算法和 **WRITESET** 算法即可。

#### COMMIT_ORDER

**COMMIT_ORDER** 计算规则：如果两个事务在主节点上是同时提交的，说明两个事务的数据之间没有冲突，那么一定也是可以在从节点上并行执行的，理想中的典型案例如下面的例子

| session-1 | session-2 |
| --- | --- |
| BEGIN | BEGIN |
| INSERT t1 values(1) |    |
|    | INSERT t2 values(2) |
| commit (group_commit) | commit (group_commit) |

但对于 MySQL 来说，group_commit 是内部行为，只要 session-1 和 session-2 是同时执行 commit，不管内部是否合并为 group_commit，两个事务的数据本质上都是没有冲突的；再退一步来讲，只要 session-1 执行 commit 之后，session-2 没有新的数据写入，两个事务依旧没有数据冲突，依然可以并行复制。

| session-1 | session-2 |
| --- | --- |
| BEGIN | BEGIN |
| INSERT t1 values(1) |   |
|   | INSERT t2 values(2) |
| commit |    |
|    | commit |

对于更多并发线程的场景，可能这些线程不能同时并行复制，但部分事务却可以。以如下一个执行顺序来说，在 session-3 提交之后，session-2 没有新的写入，那么这两个事务是可以并行复制的；而 session-3 提交后，session-1 又插入了一条新的数据，此时无法判定数据冲突，所以 session-3 和 session-1 的事务无法并行复制；但 session-2 提交后，session-1 之后没有新数据写入，所以 session-2 和 session-1 又可以并行复制。因此，这个场景中，session-2 分别可以和 session-1、session-3 并行复制，但3个事务无法同时并行复制。

| session-1 | session-2 | session-3 |
| --- | --- | --- |
| BEGIN | BEGIN | BEGIN |
| INSERT t1 values(1) | INSERT t2 values(1) | INSERT t3 values(1) |
| INSERT t1 values(2) | INSERT t2 values(2) |    |
|   |   | commit |
| INSERT t1 values(3) |    |    |
|    | commit |    |
| commit |    |    |

#### WRITESET

实际上是 **commit_order** + **writeset** 的组合，会先通过 **commit_order** 计算出一个last_commmitted 值，然后再通过 **writeset** 计算一个新值，最后取两者间的小值作为最终事务 GTID 的 last_commmitted。

在 MySQL 中，**writeset** 本质上是对 **schema_name + table_name + primary_key/unique_key** 计算的hash值，在DML执行语句过程中，通过 **binlog_log_row** 生成 row_event 之前，会将DML语句中所有的主键/唯一键都单独计算hash值，并加入到事务本身的 **writeset** 列表中。而如果存在无主键/唯一索引的表，还会对事务设置 has_missing_keys=true。

参数设置为 **WRITESET**，但是并不一定就能使用上，其限制如下

1.  非DDL语句或者表具有主键或者唯一键或者空事务。
    
2.  当前session使用的hash算法与hash map中的一致。
    
3.  未使用外键。
    
4.  hash map的容量未超过 binlog_transaction_dependency_history_size 的设置 以上4个条件均满足时，则可以使用 **WRITESET** 算法，如果有任意一个条件不满足，则会退化为 **COMMIT_ORDER** 计算方式。
    

![](https://mmbiz.qpic.cn/sz_mmbiz_png/zYias49R9JlRpEHFDc3yYibpMVEpR2teQXK5tic8pICrNJbIfdukmTJb0yHVXzic1UYIXofBQMUXuO2qMtzwg37Eicg/640?wx_fmt=png&from=appmsg)

具体 **WRITESET** 算法如下，事务提交时：

1.  last_commmitted 设置为 m_writeset_history_start，此值为 m_writeset_history 列表中最小的 sequence_number。
    
2.  遍历事务的 writeset 列表
    
    a 如果某个 writeset 在全局 m_writeset_history 中不存在，构建一个 pair<writeset，当前事务的 sequence_number 对象，插入到全局 m_writeset_history 列表中
    
    b. 如果存在，那么 last_committed=max（last_committed，历史 writeset 的 sequence_number 值），并同时更新 m_writeset_history 中该 writeset 对应的 sequence_number 为当前事务值
    
1.  如果 has_missing_keys\=false，即事务所有数据表均包含主键或者唯一索引，则最后取 commit_order 和 writeset 两种方式计算的最小值作为最终的 last_commmitted 值
    

![](https://mmbiz.qpic.cn/sz_mmbiz_png/zYias49R9JlRpEHFDc3yYibpMVEpR2teQXKPaMyiaQRnL5u2cqGgTy927SvumUibdOTsKIY9L2Oyv8ibxc2ibqgNCPcg/640?wx_fmt=png&from=appmsg)

_**TIPS：基于上面WRITESET规则，就会出现后提交的事务的 last_committed 比先提交的事务还小的情况**_

结论分析
----

### 结论描述

根据 **WRITESET** 的使用限制，对  relay log 及事务中涉及到的表结构进行了对比，分析单 last_commmitted 的事务组成发现如下两种情况：

1.  单 last_commmitted 的事务中涉及到的数据和 sequence_number 存在数据冲突
    
2.  单 last_commmitted 的事务中涉及到的表存在无主键的情况，而且这种事务特别多
    

从上面的分析中可以得出结论：无主键表的事务太多，导致 **WRITESET** 退化为**COMMIT_ORDER**，而由于数据库为TP应用，事务都快速提交，多个事务提交无法保证在一个commit周期内，导致 **COMMIT_ORDER** 机制产生的 last_commmitted 重复读很低。从库也就只能串行回放这些事务，引起回放延迟。

### 优化措施

1.  从业务侧对表做改造，在允许的情况下给相关表都添加上主键。
    
2.  尝试调大参数 binlog_group_commit_sync_delay、binlog_group_commit_sync_no_delay_count，从0修改为10000，由于特殊环境限制，该调整并未生效，不同的场景可能会有不同的表现。  
    

Enjoy GreatSQL :)


  

**文章推荐：**

*   [给MySQL 5.7打补丁，并且编译出和官方一致的Linux Generic包](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653941319&idx=1&sn=ab1d999ca6ad20c5215ab21f44639e38&chksm=bd3b742d8a4cfd3b985c2348e772529dca24b1e6fb69e821e8848f3efc03e8dd188761b68a44&scene=21#wechat_redirect)  
    
*   [探究网络延迟对事务的影响](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653941314&idx=1&sn=68570a739c8b46d1a43b857173e4c76e&chksm=bd3b74288a4cfd3e714404a795da93eb66d41535a4faf4d6d2eaf1312caf2c848aa61fe3d3b5&scene=21#wechat_redirect)  
    
*   [源码解析丨一次慢SQL排查之旅](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653941239&idx=1&sn=35aaa6835f20164686d7c8266d3a71bc&chksm=bd3b779d8a4cfe8b830a4fc3a263a81cd696a49e0637fc98a61b553359f27024281d911d377a&scene=21#wechat_redirect)  
    
*   [面试题：INSERT...t...SELECT s会对s表加锁吗](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653941233&idx=1&sn=e0c748f6b47b663f6dd6cfb4e962437b&chksm=bd3b779b8a4cfe8d2bf0a7fcbbe81a99a2c7d2541547cd8fac310121f5ba2f484df94b1be738&scene=21#wechat_redirect)
    
*   [被很多人忽视的NULL值对NOT IN子查询结果的影响问题](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653941214&idx=1&sn=17e688e6bffb289c9557884c3a1bfa88&chksm=bd3b77b48a4cfea2264926f183b9740582e3bed6bb49831575b1600c910fb185cb4d50ff2ee6&scene=21#wechat_redirect)  
    
*   [MySQL 8.0.26版本升级32版本查询数据为空的跟踪](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653941099&idx=1&sn=1f77d4b680d56e54cd071cd7f0187191&chksm=bd3b77018a4cfe1741dbc0373ea18fb421f29aaa24e27f933bb98142c02c78161042e0f623ef&scene=21#wechat_redirect)
    
*   [MyCat分库分表实时同步到GreatSQL](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653941084&idx=1&sn=63c2750c2a36cebff696637111c58a49&chksm=bd3b77368a4cfe20c1ce2f76b6002296e7d07109a5f5bf13ac5b2bf2b36d284fb898e3f5c044&scene=21#wechat_redirect)  
    
*   [SQL优化案例解析：MINUS改写为标量子查询后提升5倍，但还可以再快近百倍](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653941078&idx=1&sn=58afa8e7a7941dd098d607bd30c55d47&chksm=bd3b773c8a4cfe2ad61eca8c652f4fa908a5ce89952842324423518584be22378ba2b8b1f6bb&scene=21#wechat_redirect)
    
*   [关于GreatSQL字符集的总结](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653941062&idx=1&sn=4d21de711e7da899f2c4382d3413d708&chksm=bd3b772c8a4cfe3a0f4be4414a6793e6d33dc44a8d215da53bea164fc6d27fad89091ec20369&scene=21#wechat_redirect)
    
*   [为什么SHOW TABLE STATUS显示Rows少了40%](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653940983&idx=1&sn=ab085db4dfad74e5547703a243d01766&chksm=bd3b769d8a4cff8bde4ef8a1e909a0479411d7113a0b4c9842a09aed8d3fd6febd2f0539f402&scene=21#wechat_redirect)
    
*   [MTS性能监控你知道多少](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653940641&idx=1&sn=9dcff98e032e3722ab82e251fac72116&chksm=bd3b71cb8a4cf8dd0e3cfd66390d5d512656e6878f2fa31e77918997549d35072e8ee3e53836&scene=21#wechat_redirect)  
    

*   [MySQL对derived table的优化处理与使用限制](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653940469&idx=1&sn=91a9e69e86c518357976e2c1e7cc3732&chksm=bd3b709f8a4cf989d70e722c321785b036e514068168623cdabad0f491bc7cdf813c590a3f7d&scene=21#wechat_redirect)
    
*   [MySQL一次大量内存消耗的跟踪](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653940423&idx=1&sn=ce2f3b595ee413ef80815d45a55a1a2e&chksm=bd3b70ad8a4cf9bb3a89e942f97b0c18fa6d88436fea706e01f0129da1b249ee0bab97413c11&scene=21#wechat_redirect)
 