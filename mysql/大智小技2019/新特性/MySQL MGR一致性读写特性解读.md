                            社区投稿 | MySQL MGR"一致性读写"特性解读                                                                      

![](https://mmbiz.qlogo.cn/mmbiz_jpg/a4DRmyJYHOy3v0apocbgfGatkpJ6DdL4vm85YFg47ib65XUuT2mE4E2XlFGWOpH8KfBt4BsseGsY4vMLZrPickFg/0?wx_fmt=jpeg)

社区投稿 | MySQL MGR"一致性读写"特性解读
===========================

原创 田帅萌 [爱可生开源社区](javascript:void(0);)

**爱可生开源社区** 

微信号 ActiontechOSS

功能介绍 爱可生开源社区，提供稳定的MySQL企业级开源工具及服务，每年1024开源一款优良组件，并持续运营维护。

_2019-04-10 18:17_

MySQL 8.0.14版本增加了一个新特性：MGR读写一致性；有了此特性，“妈妈”再也不用担心读MGR非写节点数据会产生不一致啦。

有同学会疑问：“MGR不是'全同步'么，也会产生读写不一致？”，在此肯定的告诉大家MGR会产生读写不一致，原因如下：

  

![](https://mmbiz.qpic.cn/mmbiz_jpg/a4DRmyJYHOy3v0apocbgfGatkpJ6DdL4bMuzGHKMwW3Kws0icibRaYLwsBia8IaKR7fRMiaOqdjbBf8BKTvI5TnicLQ/640?wx_fmt=jpeg)

  

MGR相对于半同步复制，在relay log前增加了冲突检查协调，但是binlog回放仍然可能延时，也就是跟我们熟悉的半同步复制存在io线程的回放延迟情况类似。当然关于IO线程回放慢的原因，跟半同步也类似，比如大事务！！

所以MGR并不是全同步方案，关于如何处理一致性读写的问题，MySQL 在8.0.14版本中加入了“读写一致性”特性，并引入了参数：**group\_replication\_consistenc，**下面将对读写一致性的相关参数及不同应用场景进行详细说明。

  

**参数group\_replication\_consistenc的说明**

  

**可选配置值**

  

*   **EVENTUAL** 默认值，开启该级别的事务（T2），事务执行前不会等待先序事务（T1）的回放完成，也不会影响后序事务等待该事务回放完成。
    

  

![](https://mmbiz.qpic.cn/mmbiz_jpg/a4DRmyJYHOy3v0apocbgfGatkpJ6DdL4CbSBjWicGhh3EOW545rwTXrMBOPh4zhdYOZdHxFuwBqkW5aicB8COIEg/640?wx_fmt=jpeg)

  

*   **BEFORE** 开启了该级别的事务（T2），在开始前首先要等待先序事务（T1）的回放完成，确保此事务将在最新的数据上执行。
    

  

![](https://mmbiz.qpic.cn/mmbiz_jpg/a4DRmyJYHOy3v0apocbgfGatkpJ6DdL4RupZaOLREjeThZafYe7A1wXI8gL8xiaZUiaqCaRR18bekDIjq3O2GF3Q/640?wx_fmt=jpeg)

  

*   **AFTER，**开启该级别的事务（T1），只有等该事务回放完成。其他后序事务（T2）才开始执行，这样所有后序事务都会读取包含其更改的数据库状态，而不管它们在哪个成员上执行。
    

  

![](https://mmbiz.qpic.cn/mmbiz_jpg/a4DRmyJYHOy3v0apocbgfGatkpJ6DdL4QDmN5zhsIvBXdeWicQ36o01vefvSiatU9icZQTUvEUwFUG58OfcuHficgw/640?wx_fmt=jpeg)

  

*   **BEFORE\_AND\_AFTER** 开启该级别等事务（T2），需要等待前序事务的回放完成（T1）；同时后序事务（T3）等待该事务的回放完成；
    

![](https://mmbiz.qpic.cn/mmbiz_png/a4DRmyJYHOy3v0apocbgfGatkpJ6DdL4xjwGwT9gkzgFPEJL3pSRlZ6BZv4icfjboSRFuHODcwZNz8ad4nKZSSQ/640?wx_fmt=png)

*   **BEFORE\_ON\_PRIMARY_FAILOVER，**在发生切换时，连到新主的事务会被阻塞，等待先序提交的事务回放完成；这样确保在故障切换时客户端都能读取到主服务器上的最新数据，保证了一致性
    

  

> group\_replication\_consistency参数可以用法SESSION，GLOBAL去进行更改。
> 
> 官方说明请参考：
> 
> https://dev.mysql.com/doc/refman/8.0/en/group-replication-options.html

  

**MGR读写一致性的优缺点**

  

官方引入的MGR读写一致性既有它自身的天然优势，也不可避免的存在相应的不足，其优缺点如下：

  

*   **优点**：MGR配合中间件，比如DBLE这类有读写分离功能的中间件，在MGR单主模式下，可以根据业务场景进行读写分离，不用担心会产生延迟，充分利用了MGR主节点以外的节点。
    
*   **缺点**：使用读写一致性会对性能有极大影响，尤其是网络环境不稳定的场景下。
    

  

在实际应用中需要大家因地制宜，根据实际情况选择最适配的方案。

**MGR读写一致性的方案**

  

针对不同应用场景应当如何选择MGR读写一致性的相关方式，官方提供了几个参数以及与其相对应的应用场景：

  

**AFTER**

  

**适用场景1：** 写少读多的场景进行读写分离，担心读取到过期事务，可选择AFTER。

  

**适用场景2：** 只读为主的集群，有RW的事务需要保证提交的事务能被其他后序事务读到最新读数据，可选择AFTER。

  

**BEFORE**

  

**适用场景1：** 应用大量写入数据，_偶尔进行读取一致性数据_，应当选择BEFORE。

  

**适用场景2：** 有特定事务需要读写一致性，以便对敏感数据操作时，始终读取最新的数据；应当选择BEFORE。

  

**BEFORE\_AND\_AFTER**

  

**适用场景：** 有一个读为主的集群，有RW的事务既要保证读到最新的数据，又要保证这个事务提交后，被其他后序事务读到；在这种情况下可选择BEFORE\_AND\_AFTER。

  

**在特定会话上设置一致性**

  

**举例1：** 某一事务语句，需要其他节点的数据强一致性。可以使用SET@@SESSION.group\_replication\_consistency= ‘AFTER’进行设置。

  

**举例2：** 跟例1相似，在每天执行分析语句事务并且需要获得读取新数据的情况下。

可以使用SET @@SESSION.group\_replication\_consistency= ‘BEFORE’ 进行设置

  

> **参考文档：** 
> 
> https://dev.mysql.com/doc/refman/8.0/en/group-replication-configuring-consistency-guarantees.html#group-replication-choose-consistency-level

  