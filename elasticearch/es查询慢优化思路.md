| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-15 | 2024-10月-15  |
| ... | ... | ... |
---
# es查询慢优化思路

[toc]

## 资料

[ES-优化建议](../../../ES-优化建议-emily-2021203.pdf)

## 慢查询思路总结

### searchtype 

[Elasticsearch搜索类型讲解（QUERY_THEN_FETCH,QUERY_AND_FEATCH,DFS_QUERY_THEN_FEATCH和DFS_QUERY_AND_FEATCH）](https://www.cnblogs.com/ningskyer/articles/5984346.html)

**1、query and fetch** -- 7 版本不再支持

向索引的所有分片（shard）都发出查询请求，各分片返回的时候把元素文档（document）和计算后的排名信息一起返回。这种搜索方式是最快的。因为相比下面的几种搜索方式，这种查询方法只需要去shard查询一次。但是各个shard返回的结果的数量之和可能是用户要求的size的n倍。

**2、query then fetch（默认的搜索方式）**

如果你搜索时，没有指定搜索方式，就是使用的这种搜索方式。这种搜索方式，大概分两个步骤，第一步，先向所有的shard发出请求，各分片只返回排序和排名相关的信息（注意，不包括文档document)，然后按照各分片返回的分数进行重新排序和排名，取前size个文档。然后进行第二步，去相关的shard取document。这种方式返回的document与用户要求的size是相等的。

**3、DFS query and fetch** -- 7 版本不再支持

这种方式比第一种方式多了一个初始化散发(initial scatter)步骤，有这一步，据说可以更精确控制搜索打分和排名。

**4、DFS query then fetch**

比第2种方式多了一个初始化散发(initial scatter)步骤。

**DFS 过程**

从es的官方网站我们可以指定，初始化散发其实就是在进行真正的查询之前，先把各个分片的词频率和文档频率收集一下，然后进行词搜索的时候，各分片依据全局的词频率和文档频率进行搜索和排名。显然如果使用DFS_QUERY_THEN_FETCH这种查询方式，效率是最低的，因为一个搜索，可能要请求3次分片。但，使用DFS方法，搜索精度应该是最高的。 

### elasticsearch常见查询方式

[elasticsearch 常见几种查询方式](https://zhuanlan.zhihu.com/p/344773076) 
[elasticsearch7常见查询（term、match、bool、filter、match）](https://blog.csdn.net/lzxlfly/article/details/102771175)

### 数据类型

![数据类型不合适](image/数据类型不合适.png)

建议调整为准确数据类型， keyword，直接被存储二进制，检索时直接匹配，不匹配就返回false

## es 索引优化

### 无用索引不用保存太多

1. 索引预创建数量过多
2. 无效索引多，保留时间过长

### 索引刷新时间设置 

>Lucence 在新增数据时候，采用延迟写入策略，默认为1秒
>Lucene 降待写入的数据先写到内存中，超过1s 是就会触发一次refresh，然后refresh会把内
存中的数据刷新到操作系统的文件缓存系统中，索引较大时，高并发查询+实时写入，会造
成查询时间变大。建议将该参数改为1分钟后，查询时间可明显变短。

主要影响更新和插入。

### 静态索引内段较多

> 每一个 segment 都会占用文件句柄、内存、cpu资源，每个搜索请求都必须访问每一个
segment，这就意味着存在的 segment 越多，搜索请求就会变的更慢。所以建议针对历史
的index ，静态的进行段合并

```
post /popular_science_index-20241015100500/_forcemerge?max_num_segments=1&flush=true
```

### shards 设置的问题

现状索引数据大小在50-70G区间，主分片数量9个
现状："number_of_shards": "9"
调整number_of_shards的数量，建议单个分片的数据在20~35G区间较为合适

## 写入程序优化

应用服务写入ES方式推荐改为使用集散处理器BulkProcessor，批量提交
需要计算 每次提交的数据量，能达到最优性能，主要受到文件大小、网络情况、数据类
型、集群状态等因素影响。
API参考：
https://www.elastic.co/guide/en/elasticsearch/client/java-rest/current/java-rest-high-document-bulk.html
Order 这边：Hisorder 做法
间隔120S 数量大小超过20M 总数据量超过2000条 上述规则任一满足一个才会写入ES

## 查询分页优化

使用terminate_after 对查询排序过程进行截断，即先获取每个分片对应数量的文档，再排序。 

### terminate_after 导致的排序结果全量查询排序不一致的问题

"所以terminate_after参数是先在每个分片随机查询预设的数量之后再进行排序么，还是按时间范围查询，只是人为截断导致的"

按照query条件，先收集文档，然后截断，再进行排序，保证返回数据符合查询要求，但不保证排序的顺序与全量数据查询时的排序一致
 
"请问这个问题有办法避免吗"
 
如果需要避免，可以试试预排序（**index sorting**），让收集文档的过程和你的排序一致，就避免了先收集再排序导致的问题
同时预排序后自带提前结束的功能，可以对比下添加terminate_after和不添加时的性能差距
不过预排序会导致写入压力增加，好处是查询快很多