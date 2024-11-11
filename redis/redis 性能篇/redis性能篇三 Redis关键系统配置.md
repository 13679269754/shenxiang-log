| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-25 | 2024-10月-25  |
| ... | ... | ... |
---
# Redis性能篇三 Redis关键系统配置.md

[toc]

## 总述

Redis被广泛使用的一个很重要的原因是它的高性能。因此我们必要要重视所有可能影响Redis性能的因素、机制以及应对方案。影响Redis性能的五大方面的潜在因素，分别是：

*   [Redis内部的阻塞式操作](https://www.cnblogs.com/liang24/p/14231309.html)
*   [CPU核和NUMA架构的影响](https://www.cnblogs.com/liang24/p/14232836.html)
*   [Redis关键系统配置](https://www.cnblogs.com/liang24/p/14232880.html)
*   [Redis内存碎片](https://www.cnblogs.com/liang24/p/14232890.html)
*   [Redis缓冲区](https://www.cnblogs.com/liang24/p/14232895.html)

在前面的2讲中，学习了会导致Redis变慢的潜在阻塞点以及相应的解决方案，即异步线程机制和CPU绑核。除此之外，还有一些因素会导致Redis变慢。

这一讲，介绍如何系统性应对Redis变慢这个问题。从问题认定、系统性排查和应对方案这3个方面来讲解。

判断Redis是否变慢？
------------

最直接的方法，查看Redis的响应延迟。通过绝对值来判断，比如执行时间突然增长到几秒。

但是这个方法在不同配置的机器上的误差比较大。第二个方法是基于当前环境下的Redis基线性能做判断。

基线性能指一个系统在低压力、无干扰下的基本性能。

**怎么确定基线性能**？从2.8.7版本开始，redis-cli命令提供了-intrinsic-latency选项，可以用来监测和统计测试期间内的最大延迟，这个延迟可以作为Redis的基线性能。其中，测试时长可以用-intrinsic-latency选项的参数来指定。

一般来说，运行时延和基线性能对比，如果运行时延是基线性能的2倍及以上时，就可以认定Redis变慢了。为了避免网络对基线性能的影响，直接在服务器端运行。

如何应对Redis变慢？
------------

影响Redis的关键因素有三个：Redis自身的操作特性、文件系统和操作系统。

Redis自身操作特性的影响
--------------

Redis有两个操作会对性能造成较大影响，分别是慢查询命令和过期key操作。

### 慢查询命令

慢查询命令，就是指在Redis中执行速度慢的命令，这会导致Redis延迟增加。

**排查**：通过Redis日志、或者是latency monitor工具。

**解决方法**：

*   **用其他高效命令代替**。比如不要使用SMEMBERS命令，而是用SSCAN多次迭代返回；
*   **当需要执行排序、交集、并集操作时，可以在客户端完成，而不要用SORT、SUNION、SINTER这些命令**。

还有一个比较容易遗漏的慢查询命令是KEYS命令，它用于返回和输入模式的所有key。因为KEYS命令需要遍历存储的键值对，所以操作延时高。**KEYS命令一般不被建议用于生产环境中**。

### 过期key操作

过期key的自动删除机制，它是Redis用来回收内存空间的常用机制，本身会引起Redis操作阻塞，导致性能变慢。

**排查**：检查业务代码在使用EXPIREAT命令设置key过期时间时，是否使用了相同的UNIX时间戳。因为这会造成大量key在同一时间过期，导致性能变慢。

**解决方法**：

*   根据实际业务需求来决定EXPIREAT和EXPIRE的过期时间参数。
*   如果一批key的确是同时过期，可以在EXPIREAT和EXPIRE的过期时间参数上，加上一个一定大小范围内的随机参数

文件系统的影响
-------

在基础篇讲过，为了保证数据可靠性，Redis会采用AOF日志或者RDB快照。其中，AOF日志提供了三种日志写回策略：no、everysec、always。这三种写回策略依赖文件系统的两个系统调用完成：write和fsync。

*   write只要把日志记录写到内核缓冲区即可；
*   fsync需要把日志记录写回磁盘，时间较长。

![](https://static001.geekbang.org/resource/image/9f/a4/9f1316094001ca64c8dfca37c2c49ea4.jpg)

**排查**：

*   首先，检查Redis配置文件中的appendfsync配置项；
*   其次，确认业务对数据可靠性的要求是否需要每一秒或每一个操作都记日志。

**解决方法**：

如果业务应用对延迟非常敏感，但同时允许一定量的数据丢失，把配置项no-appendfsync-on-rewrite设置为yes：

no-appendfsync-on-rewrite yes

如果的确需要高性能，同时也需要高可靠数据保证，考虑采用高速的固态硬盘作为AOF日志的写入设备。

操作系统的影响
-------

### swap

一个潜在的瓶颈：操作系统的内存swap。

内存swap是操作系统里将内存数据在内存和磁盘间来回换入和换出的机制，涉及到磁盘的读写。

Redis一旦swap被触发，Redis的请求操作需要等到磁盘数据读写完成。并且swap触发后影响的是Redis主IO线程，这会极大地增加Redis的响应时间。

通常触发swap的原因主要是**物理机器内存不足**。

**排查**：

首先，查找Redis的进程号：

$ redis-cli info | grep process\_id process\_id: 5332

其次，进入Redis所在机器的/proc目录下的该进程目录中：

最后，运行下面命令，查看Redis进程的使用情况：

![](https://assets.cnblogs.com/images/copycode.gif)

$cat smaps | egrep '^(Swap|Size)'
Size: 584 kB
Swap: 0 kB
Size: 4 kB
Swap: 4 kB
Size: 4 kB
Swap: 0 kB
Size: 462044 kB
Swap: 462008 kB
Size: 21392 kB
Swap: 0 kB

![](https://assets.cnblogs.com/images/copycode.gif)

**解决方法**：增加机器的内存或者使用Redis集群。

### 内存大页

还有一个和内存相关的因素，即内存大页机制（Transparent Huge Page，THP），也会影响Redis性能。

**排查**：

首先，在Redis实例运行的机器上执行：

cat /sys/kernel/mm/transparent\_hugepage/enabled

如果，执行结果是always，表示内存大页机制启动了；如果是never，表示禁止了。

**解决方法**：关闭内存大页。

echo never /sys/kernel/mm/transparent\_hugepage/enabled

总结
--

总结一份关于Redis变慢的Checklist：

1.  获取Redis实例在当前环境下的基线性能。
2.  是否用了慢查询命令？如果是的话，就使用其他命令替代慢查询命令，或者把聚合计算命令放在客户端做。
3.  是否对过期key设置了相同的过期时间？对于批量删除的key，可以在每个key的过期时间上加一个随机数，避免同时删除。
4.  是否存在bigkey？ 对于bigkey的删除操作，如果你的Redis是4.0及以上的版本，可以直接利用异步线程机制减少主线程阻塞；如果是Redis 4.0以前的版本，可以使用SCAN命令迭代删除；对于bigkey的集合查询和聚合操作，可以使用SCAN命令在客户端完成。
5.  Redis AOF配置级别是什么？业务层面是否的确需要这一可靠性级别？如果我们需要高性能，同时也允许数据丢失，可以将配置项no-appendfsync-on-rewrite设置为yes，避免AOF重写和fsync竞争磁盘IO资源，导致Redis延迟增加。当然， 如果既需要高性能又需要高可靠性，最好使用高速固态盘作为AOF日志的写入盘。
6.  Redis实例的内存使用是否过大？发生swap了吗？如果是的话，就增加机器内存，或者是使用Redis集群，分摊单机Redis的键值对数量和内存压力。同时，要避免出现Redis和其他内存需求大的应用共享机器的情况。
7.  在Redis实例的运行环境中，是否启用了透明大页机制？如果是的话，直接关闭内存大页机制就行了。
8.  是否运行了Redis主从集群？如果是的话，把主库实例的数据量大小控制在2~4GB，以免主从复制时，从库因加载大的RDB文件而阻塞。
9.  是否使用了多核CPU或NUMA架构的机器运行Redis实例？使用多核CPU时，可以给Redis实例绑定物理核；使用NUMA架构时，注意把Redis实例和网络中断处理程序运行在同一个CPU Socket上。

参考资料
----

*   [18 | 波动的响应延迟：如何应对变慢的Redis？（上）](https://time.geekbang.org/column/article/286549)
*   [19 | 波动的响应延迟：如何应对变慢的Redis？（下）](https://time.geekbang.org/column/article/287819)