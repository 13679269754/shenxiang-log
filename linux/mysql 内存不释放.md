[源地址](https://cubox.pro/my/card?id=7118620448719374769)

## **问题3，mysqld进程占用内存过高怎么排查**

遇到一个比较极端的案例，`innodb_buffer_pool_size` 值仅设置为2GB，但是mysqld进程却占用了25GB的内存。

      PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
    45305 mysql     20   0   28.4g    25g   8400 S  48.5 81.4  64:46.82 mysqld
    

后面会有专门的文章介绍详细分析排查过程，这里先直接说可能的原因以及解决方案。

### **可能的原因**

1、session（会话）级内存buffer参数设置过高，并且连接数也设置过高，例如

    read_buffer_size = 64M
    read_rnd_buffer_size = 32M
    sort_buffer_size = 64M
    join_buffer_size = 64M
    tmp_table_size = 1G
    max_heap_table_size = 1G
    max_connections=2000
    

当连接数较少时，需要消耗的内存并不多。

但是当遇到突发流量时，可能并发连接数会接近打满，再加上可能有产生临时表、额外排序的低效率的SQL频繁出现，这就很容易导致内存占用快速增长。

因此建议调低session级buffer参数值，并有效控制并发连接数，下面是一个比较通用的设置值参考：

    read_buffer_size = 4M
    read_rnd_buffer_size = 4M
    sort_buffer_size = 4M
    join_buffer_size = 4M
    tmp_table_size = 32M
    max_heap_table_size = 32M
    max_connections = 512
    

2、PFS中开启过多检测指标，造成内存消耗过大。

在上面也提到过，全部开启PFS后，可能需要大约1GB内存。不过在高并发并伴随频繁低效SQL的情况下，可能需要消耗更多内存。

3、可能还用到MyISAM引擎，并且 `key_buffer_size` 设置过大。

不过现在MyISAM引擎大家一般用得也比较少了。

4、程序内存泄漏风险。

可以用**valgrind**工具检验是否存在这个问题，如果确定的话，可以考虑升级MySQL版本，或者定期在维护时间重启mysqld实例，或者通过高可用切换方式将有风险的实例重启。

5、glibc的内存管理器自身缺陷导致。

简言之，就是调用glibc申请的内存使用完毕后，归还给OS时没有被正常回收，而变成了碎片，随着碎片的不断增长，就能看到mysqld进程占用的内存不断上升。这时候，我们可以调用函数主动回收释放这些碎片。

      PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
    45305 mysql     20   0   28.4g    25g   8400 S  48.5 81.4  64:46.82 mysqld
    
    [root@mysql#] gdb --batch --pid `pidof mysqld` --ex 'call malloc_trim(0)'
    
      PID USER      PR  NI    VIRT    RES    SHR  S  %CPU %MEM     TIME+ COMMAND
    45305 mysql     20   0   28.4g    5.2g   8288 S  2.7  17.0  64:56.82 mysqld
    

这就像是在InnoDB表中产生太多碎片后，我们主动执行 `OPTIMIZE TABLE` 重建表的做法。

有个相关的bug可以关注下：Memory leak in MEMORY table by glibc, https://bugs.mysql.com/bug.php?id=94647

Enjoy MySQL :)

[跳转到 Cubox 查看](https://cubox.pro/my/card?id=7118620448719374769)