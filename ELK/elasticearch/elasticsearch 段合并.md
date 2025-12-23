| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-17 | 2024-10月-17  |
| ... | ... | ... |
---
# elasticsearch 段合并

[toc]

## Elasticsearch 性能调优：段合并(Segment merge)

Elasticsearch索引(elasticsearch index)由一个或者若干分片(shard)组成，分片(shard)通过副本(replica)来实现高可用。一个分片(share)其实就是一个Lucene索引(lucene index)，一个Lucene索引(lucene index)又由一个或者若干段(segment)组成。所以，当我们查询一个Elasticsearch索引时，查询会在所有分片上执行，既而到段(segment)，然后合并所有结果。

此文将从segment的视角，分析如何对Elasticsearch进行索引性能的优化。

### 倒排索引

Elasticsearch可以对全文进行检索主要归功于[倒排索引](https://zh.wikipedia.org/wiki/%E5%80%92%E6%8E%92%E7%B4%A2%E5%BC%95)，倒排索引被写入磁盘后是不可改变的，永远不能被修改。倒排索引的不变性有几个好处：

*   因为索引不能更新，不需要锁
*   文件系统缓存亲和性，由于索引不会改变，只要系统内存足够，大部分读请求直接命中内存，可以极大提高性能
*   其他缓存，如filter缓存，在索引的生命周期内始终有效
*   写入单个大的倒排索引允许数据被压缩，减少磁盘I/O和需要被缓存到内存的索引的使用量

但倒排索引的不变性，同样意味着当需要新增文档时，需要对整个索引进行重建，当数据更新频繁时，这个问题将会变成灾难。那Elasticsearch索引近似实时性，是如何解决这个问题的呢？

### 段(segment)

Elasticsearch是基于Lucene来生成索引的，Lucene引入了“按段搜索”的概念。用更多的倒排索引来反映最新的修改，这样就不需要重建整个倒排索引而实现索引的更新，查询时就轮询所有的倒排索引，然后对结果进行合并。  
除了上面提到的”段(segment)”的概念，Lucene还增加了一个”提交点(commit point)”的概念，”提交点(commit point)”用于列出了所有已知的”段”。

### 索引更新过程(段的不断生成)

索引的更新过程可以通过refresh api和flush API来说明。

#### refresh API

从内存索引缓冲区把数据写入新段(segment)中，并打开，可供检索，但这部分数据仍在缓存中，未写入磁盘。默认间隔是1s，这个时间会影响段的大小，对段的合并策略有影响，后面会分析。可以进行手动刷新：

```
# 刷新所有索引POST /_refresh# 指定刷新索引POST /index_name/_refresh
POST /_refresh# 指定刷新索引POST /index_name/_refresh
# 指定刷新索引POST /index_name/_refresh
# 指定刷新索引POST /index_name/_refresh
POST /index_name/_refresh
```

#### flush API

执行一个提交并且截断translog的行为在Elasticsearch被称作一次flush。每30分钟或者translog太大时会进行flush，所以可以通过translog的设置来调节flush的行为。完成一次flush会有以下过程：

*   所有在内存缓冲区的文档都被写入一个新的段。
*   缓冲区被清空。
*   一个提交点被写入硬盘。
*   文件系统缓存通过fsync被刷新(flush)。
*   老的translog被删除。

### 段合并(segment merge)

每次refresh都产生一个新段(segment)，频繁的refresh会导致段数量的暴增。段数量过多会导致过多的消耗文件句柄、内存和CPU时间，影响查询速度。基于这个原因，Lucene会通过合并段来解决这个问题。  
但是段的合并会消耗掉大量系统资源，尤其是磁盘I/O，所以在Elasticsearch 6.0版本之前对段合并都有“限流(throttling)”功能，主要是为了防止“段爆炸”问题带来的负面影响，这种影响会拖累Elasticsearch的写入速率。当出现”限流(throttling)”时，Elasticsearch日志里会出现类似如下日志：

```
now throttling indexing: numMergesInFlight=7, maxNumMerges=6stop throttling indexing: numMergesInFlight=5, maxNumMerges=6
stop throttling indexing: numMergesInFlight=5, maxNumMerges=6
```

但有时我们更在意索引批量导入的速度，这时我们就不希望Elasticsearch对段合并进行限流，可以通过_indices.store.throttle.max_bytes_per_sec_提高限流阈值，默认是20MB/s：

```
PUT /_cluster/settings{    "persistent" : {        "indices.store.throttle.max_bytes_per_sec" : "200mb"    }}
{    "persistent" : {        "indices.store.throttle.max_bytes_per_sec" : "200mb"    }}
    "persistent" : {        "indices.store.throttle.max_bytes_per_sec" : "200mb"    }}
        "indices.store.throttle.max_bytes_per_sec" : "200mb"    }}
    }}
}
```

当然也可以关掉段合并限流，”indices.store.throttle.type”设置为none即可：

```
PUT /_cluster/settings{    "transient" : {        "indices.store.throttle.type" : "none"     }}
{    "transient" : {        "indices.store.throttle.type" : "none"     }}
    "transient" : {        "indices.store.throttle.type" : "none"     }}
        "indices.store.throttle.type" : "none"     }}
    }}
}
```

需要注意的是，这里的”限流(throttling)”是对流量(注意单位是Byte)进行限流，而不是限制进程(index.merge.scheduler.max_thread_count)。

_indices.store.throttle.type_和_indices.store.throttle.max_bytes_per_sec_在版本6.x已被移除，在使用中经常会发现”限速(throttling)”是并发数(index.merge.scheduler.max_thread_count)，这两个参数感觉很鸡肋。

但即使上面的限流关掉(none)，我们在Elasticsearch日志里仍然能看到”throttling”日志，这主要是因为**_merge**_的线程数达到了最大，这个最大值通过参数_index.merge.scheduler.max_thread_count_来设置，这个配置不能动态更新，需要设置在配置文件elasticsearch.yml里：

```
index.merge.scheduler.max_thread_count: 3
```

这个设置允许 max_thread_count + 2 个线程同时进行磁盘操作，也就是设置为 3 允许5个线程。默认值是 Math.min(3, Runtime.getRuntime().availableProcessors() / 2)。

### 段合并策略(Merge Policy)

这里讨论的Elasticsearch版本是1.6.x(目前使用的版本，有点老)，这个版本里用的搜索引擎版本是Lucene4，Lucene4中段的合并策略默认使用的是TieredMergePolicy，所以在Elasticsearch 1.6中，旧的[LogMergePolicy合并策略参数](https://www.elastic.co/guide/en/elasticsearch/reference/1.6/index-modules-merge.html#log-byte-size)已经被弃用，在Elasticsearch 2.x里这些参数直接就被移除了。所以这节主要是讨论跟TieredMergePolicy有关的调优(在版本6.x里，merge相关的参数都被移除)。

TieredMergePolicy的特点是找出大小接近且最优的段集。首先，这个策略会计算在当前索引中可分配的段(segment)数量预算(budget，代码中变量allowedSegCount，通过index总大小totIndexBytes和最小段大小minSegmentBytes进行一系列计算获得)，如果超预算(budget)了，策略会对段(segment)安装大小进行降序排序，找到*最小成本(least-cost)_的段进行合并。_最小成本(least-cost)*由合并的段的”倾斜度(skew，最大段除以最小段的值)”、总的合并段的大小和回收的删除文档的百分比(percent deletes reclaimed)来衡量。”倾斜度(skew)”越小、段(segment)总大小越小、可回收的删除文档越大，合并将会获得更高的分数。

这个策略涉及到几个重要的参数

*   max_merged_segment：默认5G，合并的段的总大小不能超过这个值。
*   floor_segment：当段的大小小于这个值，把段设置为这个值参与计算。默认值为2m。
*   max_merge_at_once：合并时一次允许的最大段数量，默认值是10。
*   segments_per_tier：每层允许的段数量大小，默认值是10。一般 >= max_merge_at_once。

当增大floor_segment或者index.refresh_interval的值时，minSegmentBytes(所有段中最小段的大小，最小值为floor_segment)也会变大，从而使allowedSegCount变小，最终导致合并频繁。当减小segments_per_tier的值时，意味着更频繁的合并和更少的段。floor_segment需要设置多大，这个跟具体业务有很大关系。

需要了解更多细节，可以阅读这篇文章：[Elasticsearch: How to avoid index throttling, deep dive in segments merging](https://www.outcoldman.com/en/archive/2017/07/13/elasticsearch-explaining-merge-settings/)

### 再谈限流(throttling)

前文讲到Elasticsearch在进行段合并时，如果合并并发线程超过_index.merge.scheduler.max_thread_count_时，就会出现限流(throttling)，这时也会拖累索引的速度。那如何避免throttling呢？

Elasticsearch 1.6中，限速发生在[MergeSchedulerListener.beforeMerge](https://github.com/elastic/elasticsearch/blob/00967df092d3c13605535df443c95af9e259daa5/src/main/java/org/elasticsearch/index/engine/InternalEngine.java#L1247)，当_TieredMergePolicy.findMerges_策略返回的段数量超过了”maxNumMerges”值时，会激活限速。”maxNumMerges”可以通过_index.merge.scheduler.max_merge_count_来进行设置[ConcurrentMergeSchedulerProvider](https://github.com/elastic/elasticsearch/blob/00967df092d3c13605535df443c95af9e259daa5/src/main/java/org/elasticsearch/index/merge/scheduler/ConcurrentMergeSchedulerProvider.java#L62)，默认设置为_index.merge.scheduler.max_thread_count + 2_。这个参数在官方文档中找不到，不过可以动态更新：

```
PUT /index_name/_settings {  "index.merge.scheduler.max_merge_count": 100}
{  "index.merge.scheduler.max_merge_count": 100}
  "index.merge.scheduler.max_merge_count": 100}
}
```

不过这里有待进一步测试。

当然，也可以通过提高_index.merge.scheduler.max_thread_count_参数来增加限流的阈值，尤其当使用SSD时：

```
index.merge.scheduler.max_thread_count: 10
```

在**_段合并策略**_里有提到，当增加index.refresh_interval的值时，生成大段(large segment)有可能使allowedSegCount变小，导致合并更频繁，这样出现并发限流的几率更高。可以通过增加_index.translog.flush_threshold_size_(默认512 MB)的设置，提高每次清空触发(flush)时积累出更多的大段(larger segment)。刷新(flush)频率更低，大段(larger segment)合并的频率也就更低，对磁盘的影响更小，索引的速度更快，但要求更高的heap内存。

 原文：https://xiaoz.co/2020/02/22/elasticsearch-segment-merge/