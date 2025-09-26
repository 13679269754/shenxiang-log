| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-19 | 2024-10月-19  |

---
# mysql长连接问题长时间不释放导致临时表空间过大

[toc]

## 源文章

[故障分析 | MySQL 临时表空间数据过多导致磁盘空间不足的问题排查](https://zhuanlan.zhihu.com/p/266779699)

---

## **一、事件背景**
----------

我们的合作客户，驻场人员报告说一个 RDS 实例出现磁盘不足的告警，需要排查。

**告警信息：** 

![](https://pic1.zhimg.com/v2-5edffb56dbd23fbc6adf53d44765a89a_b.jpg)

**告警内容：** 

数据库 data 磁盘不足，磁盘占用 80% 以上

数据库 binlog 磁盘不足，磁盘占用 80% 以上

## **二、排查过程**
----------

登陆告警的服务器，查看磁盘空间，并寻找大容量文件后，发现端口号为 4675 的实例临时表空间 ibtmp1 的大小有 955G，导致磁盘被使用了 86%；

![](https://pica.zhimg.com/v2-12acff2d4a892da5fa2ad3c69d0c065e_b.png)

猜测和库里执行长 SQL 有关系，产生了很多临时数据，并写入到临时表空间。

![](https://pic1.zhimg.com/v2-aa709b57819279f964d3837114812312_b.jpg)

看到有这样一条 SQL，继续分析它的执行计划；

![](https://pica.zhimg.com/v2-d1724d4c227dc63f06633746dcea5ec8_b.jpg)

很明显看到图中标记的这一点为使用了临时计算，说明临时表空间的快速增长和它有关系。这条 SQL 进行了三表关联，每个表都有几十万行数据，三表关联并没有在 where 条件中设置关联字段，形成了[笛卡尔积](https://zhida.zhihu.com/search?content_id=147415036&content_type=Article&match_order=1&q=%E7%AC%9B%E5%8D%A1%E5%B0%94%E7%A7%AF&zhida_source=entity)，所以会产生大量临时数据；而且都是全表扫描，加载的临时数据过多;还涉及到排序产生了临时数据；这几方面导致 ibtmp1 空间快速爆满。

## **三、解决办法**
----------

和项目组沟通后，杀掉这个会话解决问题；

![](https://pic4.zhimg.com/v2-fa2ca255614b42aa222ee5ab13bf3f0f_b.jpg)

![](https://picx.zhimg.com/v2-8aa03645964b7f93fef370eb9bb310f1_b.png)

但是这个 SQL 停下来了，临时表空间中的临时数据没有释放；

![](https://pica.zhimg.com/v2-12acff2d4a892da5fa2ad3c69d0c065e_b.png)

最后通过重启 [mysql 数据库](https://zhida.zhihu.com/search?content_id=147415036&content_type=Article&match_order=1&q=mysql+%E6%95%B0%E6%8D%AE%E5%BA%93&zhida_source=entity)，释放了临时表空间中的临时数据，这个只能通过重启释放。

![](https://pica.zhimg.com/v2-88b6afc3a395eb90959da65da46660ee_b.png)

## **四、分析原理**
----------

通过查看官方文档，官方是这么解释的：

![](https://picx.zhimg.com/v2-18f7d4b5c68dd99ca9db5aae9e513787_b.png)

翻译：

![](https://picx.zhimg.com/v2-22cae46361facb0b88853dbd55ef62c9_b.png)

**根据官网文档的解释，在正常关闭或初始化中止时，将删除临时表空间，并在每次启动服务器时重新创建。重启能够释放空间的原因在于正常关闭数据库，临时表空间就被删除了，重新启动后重新创建，也就是重启引发了临时表空间的重建，重新初始化，所以，重建后的大小为 12M。** 

从错误日志里可以验证上面的观点：

![](https://pic2.zhimg.com/v2-e93259a077eea1b90888da894201ed45_b.png)

## **五、官网对于 ibtmp1 大小的说明**
-----------------------

![](https://pic3.zhimg.com/v2-b4fc19c5caa1068d6653e07b7795afda_b.jpg)

![](https://pic4.zhimg.com/v2-74e725c90a8663ff1d0728ef9c4d333b_b.png)

## **六、如何避免**
----------

1\. 对临时表空间的大小进行限制，允许自动增长，但最大容量有上限,本例中由于 innodb\_temp\_data\_file\_path 设置的自动增长，但未设上限，所以导致 ibtmp1 有 955G。正确方法配置参数 innodb\_temp\_data\_file\_path：\[mysqld\]innodb\_temp\_data\_file\_path=ibtmp1:12M:autoextend:max:500M参考官方文档：

![](https://pica.zhimg.com/v2-739044f559fd38c174b074e4fe111404_b.jpg)

![](https://pic3.zhimg.com/v2-600f7e8ac0a8d1e28fdcd6e2af3b08fa_b.png)

设置了上限的大小，当数据文件达到最大大小时，查询将失败，并显示一条错误消息，表明表已满，查询不能往下执行，避免 ibtmp1 过大。

2\. 在发送例如本例中的多表关联 SQL 时应确保有关联字段而且有索引，避免笛卡尔积式的全表扫描，对存在 group by、order by、多表关联的 SQL 要评估临时数据量，对 SQL 进行审核，没有审核不允许上线执行。

3\. 在执行前通过 explain 查看执行计划，对 Using temporary 需要格外关注。

## **七、其他补充**
----------

1> 通过字典表查看执行的 SQL 产生临时表、使用临时表空间的情况：查询字典表：sys.x$statements\_with\_temp\_tablesselect \* from sys.x$statements\_with\_temp\_tables where query like 'select%' and db='test' order by tmp\_tables\_to\_disk\_pct,disk\_tmp\_tables desc\\G;

![](https://pica.zhimg.com/v2-d32eab1a26449832209ab117ff3a0498_b.png)

查询字典表：sys.statements\_with\_temp\_tablesselect \* from sys.statements\_with\_temp\_tables where query like 'select%' and db='test' order by tmp\_tables\_to\_disk\_pct,disk\_tmp\_tables desc\\G;

![](https://pic1.zhimg.com/v2-d461d5fe894bd166f15a77cecfda86f0_b.png)

这两个表查询的结果是一样的，各列含义如下：

query：规范化的语句字符串。

db：语句的默认数据库， NULL 如果没有。

exec\_count：语句已执行的总次数。

total\_latency：定时出现的语句的总等待时间。

memory\_tmp\_tables：由该语句的出现创建的内部内存临时表的总数。

disk\_tmp\_tables：由该语句的出现创建的内部磁盘临时表的总数。

avg\_tmp\_tables\_per\_query：每次出现该语句创建的内部临时表的平均数量。

tmp\_tables\_to\_disk\_pct：内部内存临时表已转换为磁盘表的百分比。

first\_seen：第一次看到该声明的时间。

last\_seen：最近一次发表该声明的时间。digest：语句摘要。

参考链接：[https://dev.mysql.com/doc/refman/5.7/en/sys-statements-with-temp-tables.html](https://link.zhihu.com/?target=https%3A//dev.mysql.com/doc/refman/5.7/en/sys-statements-with-temp-tables.html)通过字典表 tmp\_tables\_to\_disk\_pct 这一列结果可知，[内存临时表](https://zhida.zhihu.com/search?content_id=147415036&content_type=Article&match_order=3&q=%E5%86%85%E5%AD%98%E4%B8%B4%E6%97%B6%E8%A1%A8&zhida_source=entity)已转换为磁盘表的比例是 100%，说明通过复现这个查询，它的临时计算结果已经都放到磁盘上了，进一步证明这个查询和临时表空间容量的快速增长有关系。

2> 对于 mysql5.7 中 kill 掉运行长 SQL 的会话，ibtmp1 容量却没有收缩问题的调研；来源链接：[http://mysql.taobao.org/monthly/2019/04/01/](https://link.zhihu.com/?target=http%3A//mysql.taobao.org/monthly/2019/04/01/)

![](https://pic4.zhimg.com/v2-d90c1c958d3fd33c2278d5169c86cc69_b.jpg)

**从文章中的解释看，会话被杀掉后，临时表是释放的，只是在 ibtmp1 中打了删除标记，空间并没有还给操作系统，只有重启才可以释放空间。** 

3> 下面，进一步用 mysql8.0 同样跑一下这个查询，看是否有什么不同;mysql 版本：8.0.18

![](https://pic4.zhimg.com/v2-82a1b37e457e1e8e18625bbf829d627b_b.jpg)

![](https://pic2.zhimg.com/v2-d448b187839f94d721df1ad5f401ce49_b.jpg)

![](https://picx.zhimg.com/v2-47bca6db7695186ea7a622fdd7041693_b.jpg)

当这个 sql 将磁盘跑满之后，发现与 5.7 不同的是这个 SQL 产生的临时数据保存到了 tmpdir，mysql5.7 是保存在 ibtmp1 中，而且由于磁盘满，SQL 执行失败，很快磁盘空间就释放了；

**问题：如何使用到 8.0 版本的临时表空间？**

通过查看 8.0 的官方文档得知，8.0 的临时表空间分为会话临时表空间和全局临时表空间，会话临时表空间存储用户创建的临时表和当 InnoDB 配置为磁盘内部临时表的存储引擎时由优化器创建的内部临时表，当会话断开连接时，其临时表空间将被截断并释放回池中；也就是说，在 8.0 中有一个专门的会话临时表空间，当会话被杀掉后，可以回收磁盘空间；而原来的 ibtmp1 是现在的全局临时表空间，存放的是对用户创建的临时表进行更改的回滚段，在 5.7 中 ibtmp1 存放的是用户创建的临时表和磁盘内部临时表；

**也就是在 8.0 和 5.7 中 ibtmp1 的用途发生了变化，5.7 版本临时表的数据存放在 ibtmp1 中，在 8.0 版本中临时表的数据存放在会话临时表空间，如果临时表发生更改，更改的 undo 数据存放在 ibtmp1 中；**

![](https://pic4.zhimg.com/v2-c0fa1b5ee9476e460df49de9451afeb7_b.jpg)

![](https://pic4.zhimg.com/v2-852a3a1b0325eaa29497c9cff3278075_b.jpg)

![](https://pica.zhimg.com/v2-1f39f2c8902e69b0e90561675855084e_b.png)

![](https://pica.zhimg.com/v2-67b32627ef7f863e22b6915fbb90f520_b.png)

![](https://pica.zhimg.com/v2-35c27f7b6ff3dd873434cabfcf3e26d8_b.png)

实验验证：将之前的查询结果保存成临时表，对应会话是 45 号，通过查看对应字典表，可知 45 号会话使用了 temp\_8.ibt 这个[表空间](https://zhida.zhihu.com/search?content_id=147415036&content_type=Article&match_order=21&q=%E8%A1%A8%E7%A9%BA%E9%97%B4&zhida_source=entity)，通过把查询保存成临时表，可以用到会话临时表空间，如下图：

![](https://pic3.zhimg.com/v2-e72b222650689a4901f0bf2c358f5576_b.jpg)

下一步杀掉 45 号会话，发现 temp\_8.ibt 空间释放了，变为了初始大小，状态为非活动的，**证明在 mysql8.0 中可以通过杀掉会话来释放临时表空间。** 

![](https://pica.zhimg.com/v2-5d1165221adcb9c58bb7fed84d41e40c_b.jpg)

**总结：在 mysql5.7 时，杀掉会话，临时表会释放，但是仅仅是在 ibtmp 文件里标记一下，空间是不会释放回操作系统的。如果要释放空间，需要重启数据库；在 [mysql8.0](https://zhida.zhihu.com/search?content_id=147415036&content_type=Article&match_order=3&q=mysql8.0&zhida_source=entity) 中可以通过杀掉会话来释放临时表空间。** 

## **八、参考文档**
----------

> [https://dev.mysql.com/doc/refman/5.7/en/innodb-temporary-tablespace.html](https://link.zhihu.com/?target=https%3A//dev.mysql.com/doc/refman/5.7/en/innodb-temporary-tablespace.html)  
> [https://dev.mysql.com/doc/refman/8.0/en/innodb-temporary-tablespace.html](https://link.zhihu.com/?target=https%3A//dev.mysql.com/doc/refman/8.0/en/innodb-temporary-tablespace.html)  
> [http://mysql.taobao.org/monthly/2019/04/01/](https://link.zhihu.com/?target=http%3A//mysql.taobao.org/monthly/2019/04/01/)