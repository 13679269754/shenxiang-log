| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-15 | 2024-10月-15  |
| ... | ... | ... |
---
# elasticsearch 查询分析

[toc]

## 查询分析接口

**_profile API**
```bash
GET /my-index-000001/_search
{
  "profile": true,
  "query" : {
    "match" : { "message" : "GET /search" }
  }
}
```

**kibana profile**
![kibana profile](<kibana profile.png>)



## 排查各阶段花费时间优化策略


原文链接 [ES慢查询分析](https://blog.csdn.net/star1210644725/article/details/135229578)


问题
--

        生产环境频繁报警。查询跨度91天的数据，请求耗时已经来到了30+s。报警的阈值为5s。我们期望值是5s内，大于该阈值的请求，我们认为是[慢查询](https://so.csdn.net/so/search?q=%E6%85%A2%E6%9F%A5%E8%AF%A2&spm=1001.2101.3001.7020)。这些慢查询，最终排查，是因为走到了历史集群上。受到了数据迁移的一定影响，也做了一些优化，最终从30s提升到5s。

![](https://i-blog.csdnimg.cn/blog_migrate/a62ce26dfff5d332b3b40842b07107ac.png)

背景
--

查询关键词简单，为‘北京’

单次仅检索两个字段

查询时间跨度为91天，覆盖数据为450亿数据

问题分析
----

使用profle分析，复现监控报警的语句，确实慢。集群分片太多，这里放一个分片的内容。

```null
"id" : "[YWAxM5F9Q0G1PXfTtYZKkzQ][_20230921-000001][3]","type" : "FunctionScoreQuery","description" : "function score (+((title:北京)^2.0 | content:北京) +publish_time:[1687431307000 TO 1695254417999] +es_insert_time:[-9223372036854775808 TO 1703084327999], functions: [{scriptScript{type=stored, lang='null', idOrCode='search-score', options=null, params={}}}])","time_in_nanos" : 10079315883,"set_min_competitive_score_count" : 0,"shallow_advance_count" : 0,"set_min_competitive_score" : 0,"compute_max_score_count" : 0,"build_scorer_count" : 40,"create_weight" : 3965124112,"create_weight_count" : 1,"build_scorer" : 546462281
```

在Elasticsearch Profile API结果中，主要关注查询的**time**和**breakdown**字段，这提供了查询执行的总时间和各个步骤的时间分解。在这个例子中，查询的总时间为10秒。

具体来看，主要的时间花费在**FunctionScoreQuery**的**create\_weight**步骤上，该步骤耗时为3,965,124,112纳秒（大约3.97秒）。**create\_weight**是在查询执行之前创建用于评分的权重的阶段。

以下是一些步骤的关键信息：

*   **create\_weight**步骤耗时最长，可能是性能瓶颈。
*   **build\_scorer**步骤也占用了大量时间，这通常是评分过程中的一个重要步骤。
*   **next\_doc**步骤的时间比较大，这可能涉及到遍历文档的过程。

### **疑问？为什么 create\_weight 过程耗时会这么长**

> 从我的查询条件来看，请求是很简单的，没有复杂的条件，为什么 create\_weight 过程耗时会这么长？

**create\_weight**阶段的耗时主要取决于查询中使用的权重计算方式以及索引的结构和数据量。在你提供的Profile API结果中，**create\_weight**的耗时非常大，说明这个步骤在整个查询过程中占用了大量的时间。

有几个潜在的原因可能导致**create\_weight**步骤的性能下降：

1.  **脚本复杂性：**  如果你在Function Score Query中使用了复杂的脚本，脚本的执行可能会消耗大量的时间。检查你的脚本逻辑，尽量确保它是高效的。
2.  **文档数和大小：**  如果你的索引中包含大量的文档或者文档非常大，创建权重可能会变得更加耗时。在这种情况下，考虑优化索引结构、调整分片数量等。
3.  **Function Score Query的配置：**  如果在Function Score Query中使用了复杂的函数或者过多的函数，计算每个文档的权重可能会更加耗时。检查你的Function Score Query配置，确保它符合你的需求。

### **create\_weight 究竟在干什么，源码？**

这里主要是lucene去IO底层文件。这里比较明显的是性能问题。

### **第一个尝试，去掉脚本排序**

脚本排序的时间会算在create\_weight过程中（猜想，待验证）

测试把我的搜索条件，去掉脚本排序。原来是15s，现在是10s，脚本排序的耗时在我请求中，占据了30%多。

![](https://i-blog.csdnimg.cn/blog_migrate/f49311a3de02fdaa397d847d4f98f52f.png)

继续分析慢查询的分片
----------

其中，耗时最长的分片还是，create\_weight 过程耗时最严重。

![](https://i-blog.csdnimg.cn/blog_migrate/2dcb63d96a2b230621f45a0c6ef0959f.png)

耗时发生在我的title字段上的这个子查询上。

![](https://i-blog.csdnimg.cn/blog_migrate/944bc12e136c87446fb41efe34a08157.png)

### **调整terminate\_after  从200->10**

检索耗时进一步降低。

![](https://i-blog.csdnimg.cn/blog_migrate/067a8bdb51d5f4488da5f7316615c09d.png)

其中还是有耗时长的个别分片

整个请求6.2s，在这个分片上的请求就花了6s，并且时间还是花在了create\_weight上。

![](https://i-blog.csdnimg.cn/blog_migrate/3de948bb55553380346b8f61c4085942.png)

### **如何才能降低create\_weight的耗时？**

降低terminate\_after的值可以降低，代价是影响整体的排序效果。

减少段的个数，可以减少耗时。通过段合并。因为可以减少段的遍历。

### **疑问？是不是在查询的时候负载高？**

```
`GET _cat/nodes?v` 
```

![](https://i-blog.csdnimg.cn/blog_migrate/18e5296778d2dcb2e8ec84993a217628.png)

**问题解决方案**
----------

### **动态调整terminate\_after**

  并非所有的请求，都需要每个分片都200条数据。特别在大的时间跨度下，分片可能会非常多，动辄几千个，以2000个分片算，最多会匹配2000\*200=400000数据。加上脚本排序，这40W数据，都需要参与分数的计算，最终才能角逐出top20的数据。最终的结果是请求耗时长。

  实际上，terminate\_after的取值，是可以动态调整的。检索分为乐观和悲观情况，乐观情况下，数据分布是均匀的，在分片上分配是均匀的，且检索条件命中的数据较多。在悲观情况下，检索的数据分布不均匀，且搜索的条件比较特殊，命中的数据很少，或者命中的数据在分片上分布不均匀。

  大多数情况下，数据分布是均匀的，检索的数据量越大，分布可能越均匀。例如检索3个月，总数据大约450亿数据，随便一个搜索条件，搜索的数据大概率是大于10000条的。所以可以设计一个动态调整方案，来调整terminate\_after的取值，能够获取更好的性能，提升200%-300%。另外需要一个悲观情况下的担保机制，避免在悲观情况下检索丢失数据。

  terminate\_after的值是限定在分片上的，假如一个索引有10个分片，如果设置terminate\_after为200，则最后返回的数据总量为 10\*200=2000条。考虑到分页为500页，每页20条数据，共计可以翻页10000条数据。如何设置terminate\_after的值呢？要考虑到翻页的情况。

  请求的入参，一般包含了翻页和每页的条数。 期望数据总量= 页码\* 每页的数量。  es的召回总量为= 分片数\*terminate\_after数量\*偏差。偏差可以算0.1，预期10倍可以弥补数据分布不均匀带来的影响。分片数暂时可以按每天15个来算。 页码\* 每页的数量 = 分片数\*terminate\_after数量\*偏差 。可以得出  terminate\_after数量 = 页码\* 每页的数量 / (分片数\*偏差)。terminate\_after数量不足10则向上取正为10。 当查询的天数小于7天，则可以直接取值为200。

  担保机制，需要解决悲观情况下的问题。根据es返回的数据总量。 如果返回的数据总量小于期望的数据总量，则触发担保机制。需要调大terminate\_after的值（暂定为500），再去搜索一次。

### **索引段合并**

  段合并可以提升减速效果。

### 调大在请求在单个节点上的最大并发度

默认情况下，一个请求在单个节点上最大并发度为5，超过5以后则需要排队，串行执行。这里先避免排队的时间。我这里给了30。 注意此参数，在负载不高，且线程池充足和堆空间充足的情况下可以这样用。其它情况不适合，在聚合请求中不建议使用！

![](https://i-blog.csdnimg.cn/blog_migrate/468fd37190d30bd30daf0bd33bec79f8.png)

**最终的检索效果**
-----------

![](https://i-blog.csdnimg.cn/blog_migrate/468fd37190d30bd30daf0bd33bec79f8.png)

### **检索耗时情况**

![](https://i-blog.csdnimg.cn/blog_migrate/3095aa7f47ac370b32abdaf4866c07e8.png)

最后 
---

搜索优化不是一朝一夕的事情。需要长时间的知识储备。我已经做了四年优化es搜索优化。我把一些高质量的优化提升的案例放在了我的专栏里。（目前还是免费的，未来可能会收费把...）想要做更多的搜索提升，可以看看这些文章，或许会能起到抛砖引玉的作用。

[https://blog.csdn.net/star1210644725/category\_12341074.html](https://blog.csdn.net/star1210644725/category_12341074.html "https://blog.csdn.net/star1210644725/category_12341074.html")


### terminate_after 导致的排序结果全量查询排序不一致的问题

"所以terminate_after参数是先在每个分片随机查询预设的数量之后再进行排序么，还是按时间范围查询，只是人为截断导致的"

按照query条件，先收集文档，然后截断，再进行排序，保证返回数据符合查询要求，但不保证排序的顺序与全量数据查询时的排序一致
 
"请问这个问题有办法避免吗"
 
如果需要避免，可以试试预排序（**index sorting**），让收集文档的过程和你的排序一致，就避免了先收集再排序导致的问题
同时预排序后自带提前结束的功能，可以对比下添加terminate_after和不添加时的性能差距
不过预排序会导致写入压力增加，好处是查询快很多