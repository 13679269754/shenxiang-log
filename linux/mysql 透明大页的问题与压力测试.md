| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-12月-04 | 2024-12月-04  |
| ... | ... | ... |
---

# mysql 透明大页的问题与压力测试.md

[toc]

                            运行 GreatSQL 时为什么要求关闭透明大页                                                                       


运行 GreatSQL 时为什么要求关闭透明大页
========================

原创 YeJinrong/叶金荣 [老叶茶馆];)


在大部分运维规范中，一般都会要求在运行 GreatSQL/MySQL 的环境中要关闭透明大页，那么到底什么是透明大页，为什么要关闭，打开有什么风险吗？

在此之前，我也是有点懵的，本文试着回答这个疑问，并通过实验进行验证这个说法正确与否。

实际上，Linux 系统中是有两种大页支持机制的，即 **透明大页** 和 **静态大页**，先来看看那二者有什么不同。

P.S，本文的编辑整理借助 chatgpt 协助完成。

## 1\. 透明大页（Transparent Huge Pages, THP）和静态大页（HugeTLB）的区别**
----------------------------------------------------------

Linux 提供了两种机制来支持**大页（Huge Pages）**，即 **透明大页（Transparent Huge Pages, THP）** 和 **静态大页（HugeTLB）**。这两种机制旨在减少内存管理开销、提升性能，但它们的实现方式和适用场景有所不同。

### **1.1 透明大页（THP）**

#### **透明大页工作机制**

*   **动态分配**：  
    THP 会在系统运行时动态地将小页（通常是 4KB）合并成大页（通常是 2MB 或更大）。这种分配对应用程序透明，无需用户干预或显式配置。
    
*   **自动折叠（Compaction）**：  
    如果内存分布不连续（存在碎片），THP 会触发后台内存整理任务，将分散的小页整理成连续的物理内存块以分配大页。
    
*   **混合模式**：  
    系统在小页和大页之间动态切换。如果无法分配大页，系统会自动回退到小页。
    

#### **透明大页优点**

1.  **无需配置**：应用程序无需修改即可使用大页，简化了管理。
    
2.  **减少 TLB（Translation Lookaside Buffer）缺失**：大页减少了页表项数量，提高了 TLB 缓存命中率，降低了虚拟地址到物理地址转换的开销。
    
3.  **支持内存分配灵活性**：THP 可以动态调整内存分配方式，既支持大页又支持小页。
    

#### **透明大页缺点**

1.  **性能不可预测**：
    

*   动态分配大页和后台内存整理可能引入额外开销，特别是在高并发或内存紧张时，可能导致性能抖动。
    

3.  **大页分配失败**：
    

*   如果系统内存碎片化严重，THP 可能频繁回退到小页模式，降低收益。
    

5.  **高内存浪费**：
    

*   如果分配的大页中数据利用率较低，会浪费内存空间。
    

### **1.2 静态大页（HugeTLB）**

#### **静态大页工作机制**

*   **静态预分配**：  
    HugeTLB 需要在系统启动或运行时手动预分配一部分物理内存用于大页。分配后，这些大页无法用于其他用途。
    
*   **显式使用**：  
    应用程序需要显式地分配和管理大页内存。例如，用户需要通过特定的系统调用（如 `mmap` 或 `shmget`）请求大页。
    

#### **静态大页优点**

1.  **性能可预测**：  
    由于大页是静态分配的，系统在运行时不会触发内存整理任务，因此性能稳定，适用于高实时性需求的场景。
    
2.  **高效利用大页**：  
    HugeTLB 可以确保大页的分配和使用效率更高，减少动态分配的开销。
    
3.  **减少内存碎片**：  
    通过预分配内存，HugeTLB 避免了碎片化问题。
    

#### **静态大页缺点**

1.  **需要手动配置**：  
    用户需要明确指定大页的数量和大小，增加了管理复杂度。
    
2.  **内存利用率下降**：  
    预分配的大页区域无法被其他进程使用，可能导致内存浪费。
    
3.  **缺乏灵活性**：  
    如果预分配的大页不足，可能导致性能下降，且无法动态调整。
    

### **1.3 透明大页与静态大页的对比**

| **特性** | **透明大页（THP）** | **静态大页（HugeTLB）** |
| --- | --- | --- |
| **分配方式** | 动态分配（内核负责） | 静态分配（用户手动配置） |
| **内存管理灵活性** | 支持小页与大页混合使用 | 仅支持大页 |
| **性能稳定性** | 可能引入动态分配和折叠开销，性能抖动大 | 性能稳定，没有动态内存整理的开销 |
| **配置复杂性** | 无需配置，默认启用 | 需要手动设置 |
| **适用场景** | 顺序访问、高内存吞吐场景；低实时性应用 | 高实时性场景；性能要求严格、需要控制开销的应用 |
| **内存碎片** | 可能因碎片化导致大页分配失败 | 避免内存碎片 |
| **应用透明性** | 对用户和应用透明，无需显式修改代码 | 需要应用显式支持 |

## **2\. 什么场景下建议打开或关闭透明大页？**
-------------------------

### **2.1 建议打开透明大页（THP）的场景**

1.  **顺序内存访问的应用**：如大数据处理、机器学习训练、视频流处理等。这类应用程序通常具有线性内存访问模式，THP 可有效减少 TLB 缺失，提高性能。
    
2.  **大内存使用的应用**：如内存缓存（Memcached、Redis）或需要大内存区域的计算密集型程序（如高性能计算应用），THP 可以显著降低页表项的管理开销。
    
3.  **系统对延迟不敏感**：如果应用对延迟的要求较低（如批处理任务），THP 的动态行为不会显著影响整体性能。
    

### **2.2 建议关闭透明大页（THP）的场景**

1.  **数据库应用**（如 GreatSQL/MySQL 等）：数据库通常对延迟敏感，且有大量随机内存访问，THP 的动态分配可能引入延迟峰值，影响稳定性。
    
2.  **实时性要求高的场景**：如交易系统、低延迟 Web 服务、金融系统等。这类场景需要尽可能避免延迟抖动。
    
3.  **高并发负载**：在高并发的请求场景下，THP 的内存折叠任务可能争用 CPU 和内存资源，降低服务吞吐量。
    

### **2.3 运行 GreatSQL 时如何选择**

从上面的描述中能看出来，在运行 GreatSQL/MySQL 等需要申请大块随机内存又要求快速响应的数据库类应用而言，最好是 **关闭透明大页**，而是 **开启静态大页** 方式来运行。

运行 GreatSQL 时建议关闭透明大页，因为以下几点原因：

1.  **动态分配引入额外开销**：
    

*   THP 在分配大页时可能触发内存整理任务，增加 CPU 和磁盘 I/O 的负载，特别是在高并发或内存紧张的情况下，可能导致性能抖动。
    

3.  **对数据库负载收益有限**：
    

*   数据库应用通常具有随机内存访问模式，THP 对顺序访问场景优化更显著，但对随机访问场景帮助有限。
    

5.  **GreatSQL 的内存管理机制冲突**：
    

*   GreatSQL 的 InnoDB Buffer Pool 已经对内存分配和管理进行了高度优化。THP 的动态行为可能干扰 GreatSQL 的内存管理策略。
    

**关闭 THP 的方法**：

`echo never > /sys/kernel/mm/transparent_hugepage/enabled  
echo never > /sys/kernel/mm/transparent_hugepage/defrag  
`

运行 GreatSQL 时建议开启静态大页是为了能提高内存管理效率，并且在运行过程中保护好所需的大块内存不被其他应用抢占，造成额外的等待，以及其他几点原因：

*   GreatSQL 的内存管理模块（如 InnoDB Buffer Pool）已经针对小页进行了优化。
    
*   动态分配和内存折叠可能导致性能抖动，特别是在高负载下。
    
*   开启 THP 对 GreatSQL 的性能没有显著提升，反而可能导致延迟峰值。
    

## **3\. 运行 GreatSQL 时如何启用静态大页（HugeTLB）**
--------------------------------------

接下来介绍如何在 GreatSQL 中启用静态大页支持。

### **1\. 首先，确认运行 GreatSQL 所属的用户组**

```
$ ps aux|grep -i mysqld  
mysql     75607 1512  5.8 46383532 23093520 ?   Ssl  13:59 1130:13 /usr/local/GreatSQL-8.0.32-26-Linux-glibc2.28-x86_64/bin/mysqld  
  
$ id mysql  
uid=997(mysql) gid=1000(mysql) groups=1000(mysql)  
```

### **2\. 其次，计算预估 GreatSQL 运行时总共所需的内存总大小**

可以采用下面的方法简单估算：

`-- SGA  
innodb_buffer_pool_size +  
innodb_log_buffer_size +  
table_open_cache +  
table_definition_cache +  
temptable_max_ram  
key_buffer_size +  
  
-- PGA  
( read_buffer_size  
+ read_rnd_buffer_size  
sort_buffer_size  
join_buffer_size  
binlog_cache_size  
histogram_generation_max_mem_size) * max_connections  
`

其中占比最高的是 `innodb_buffer_pool_size`，简单起见，通常在 `innodb_buffer_pool_size` 参数值的基础上适当上浮约 30% 基本上就够，运行过程中如果出现分配的大页内存不够用，GreatSQL 可能会出现类似下面的错误提示：

`[InnoDB] large_page_aligned_alloc mmap(XXXX bytes) failed; errno 12  
`

出现这种错误的话，就需要继续调大可用大页内存值，详见下方第3和第5步，也有可能是当前内存中有部分缓存还没回收，可以执行 `sync` 命令将所有未写入磁盘的数据（即脏数据）从内存中同步到磁盘，再执行 `echo 3 > /proc/sys/vm/drop_caches` 清除内存中的缓存，以及执行 `echo 1 > /proc/sys/vm/compact_memory` 尝试将物理内存中的页面重新排列，以减少内存碎片，提高内存分配效率。

``` bash
echo 3 > /proc/sys/vm/drop_caches  
echo 1 > /proc/sys/vm/compact_memory  
``` 

如果当前内存中脏数据较多，待清除缓存较大或内存碎片较多的话，上述操作执行起来可能略慢，需要一定时间。

### **3\. 修改 GreatSQL 进程属主用户 memlock 限制**

编辑 _/etc/security/limits.conf_，增加下面相应设置：

```bash
# /etc/security/limits.conf  
#Each line describes a limit for a user in the form:  
#  
#<domain>        <type>  <item>  <value>  
@mysql soft memlock unlimited  
@mysql hard memlock unlimited  
```

允许 GreatSQL 进程可以无限制地申请内存，如果担心会发生 OOM，也可以适当设置硬限制（hard）的上限值，避免内存被耗尽。

### **4\. 修改 GreatSQL 配置参数**

编辑 _my.cnf_ 配置文件，增加 `large_pages = ON` 参数：

`[mysqld]innodb_buffer_pool_size = 40G  
large_pages = ON  
`

### **5\. 修改 /etc/sysctl.conf，修改 HugeTLB 设置**

编辑 _/etc/sysctl.conf_ 文件，添加两行配置

```bash
# 运行 GreatSQL 的用户组GID  
vm.hugetlb_shm_group = 1000  
  
# 静态大页数目  
vm.nr_hugepages = 26624  
```

编辑完后，执行 `sysctl -p` 使之生效，并再次确认：

```bash
$ sysctl -p  
vm.hugetlb_shm_group = 1000  
vm.nr_hugepages = 26624  
  
$ sysctl -a | egrep 'vm.hugetlb_shm_group|vm.nr_hugepages '  
vm.hugetlb_shm_group = 1000  
vm.nr_hugepages = 0  
  
$ grep -i huge /proc/meminfo  
AnonHugePages:     24576 kB  
ShmemHugePages:        0 kB  
FileHugePages:         0 kB  
HugePages_Total:   25160  
HugePages_Free:    22225  
HugePages_Rsvd:    15083  
HugePages_Surp:        0  
Hugepagesize:       2048 kB  
Hugetlb:        54525952 kB  
```

在上述例子中，静态大页数目是 **26624**，那么静态大页的内存大小就是 **26624 \* 2M = 52G**（每个静态大页是 2M）。

申请的静态大页内存共 52G，而设置 IBP 为 40G，上浮了 30%，一般情况下是够用的。

## **4\. 对比测试**
------------

百闻不如一见，利用 BenchmarkSQL 进行测试看看结果有什么不同。下面是测试结果：

![](https://mmbiz.qpic.cn/sz_mmbiz_png/nts52nHheTyL2zVNyM3C1qQMgOKbyJ3yzAu7XZnKiag8oOG53Gm0GD3lKmRodF55lkzZAc3q9F9ofSqFmzL22FA/640?wx_fmt=png&from=appmsg)

从这份测试结果可以看到：

*   当 IBP 充足时，内存资源不是瓶颈，不需要频繁分配和回收，此时启用动态大页的整体性能更好。
    
*   当 IBP 不足时，内存资源成为瓶颈，可能需要频繁分配和回收，此时启用静态大页的整体性能更好（相对于启用动态大约tpmC约高出7%）。
    
*   当 IBP 充足时，启用静态大页的性能反倒较低。
    
*   反过来，当 IBP 不足时，开启动态大页的性能较低。
    

BenchmarkSQL 测试相关信息：

*   GreatSQL 8.0.32-26
    
*   warehouses=1000（datasize约180G，具体不记得了）
    
*   terminals=32
    
*   runMins=5
    
*   IBP 充足是指 IBP = 256G
    
*   IBP 不足是指 IBP = 128G
    
*   每次总共运行4次，结果取平均值
    

继续用 Sysbench 在 `oltp_read_write` 模式下做了补充测试，结论基本上和上述一致。结合上面的测试结论，**线上生产环境的内存通常是没办法完全满足的**，这种情况下建议**启用静态大页、关闭动态大页**，在内存充足的情况下无需做出调整。

即便如此，在生产环境中是否启大页支持还是要根据实际业务特点及您的实际测试结果动态调整，这一次测试结果不能覆盖所有的场景，有条件的读者建议也自行测试验证。

## **5\. 总结**
----------

*   **透明大页（THP）** 更适合顺序访问、大吞吐的场景，但对数据库应用（如 GreatSQL/GreatSQL）可能引入性能抖动，因此建议关闭 THP。
    
*   **静态大页（HugeTLB）** 提供更高的性能稳定性，适用于高实时性和高并发场景。如果对性能要求严格，可以考虑启用 HugeTLB 并进行精细配置。
    
*   运行 GreatSQL/MySQL/Oracle 等这类需要申请大块随机内存又要求快速响应的数据库类应用而言，最好是 **关闭透明大页**，而是 **开启静态大页** 方式来运行。
    
*   芬达、yangyidba二位老师对本文亦有贡献，感谢。  
    

**延伸阅读**

*   [huge page 能给MySQL 带来性能提升吗？](https://mp.weixin.qq.com/s?__biz=MzI4NjExMDA4NQ==&mid=2648451664&idx=1&sn=5b6807f0248e2b2cd984627329e6053a&scene=21#wechat_redirect)
  