[(5 封私信) 为什么MySQL不推荐使用uuid或者雪花id作为主键？ - 知乎](https://www.zhihu.com/question/648907464/answer/31704831575) 

 **先说结论：**  UUID 主键、[雪花 ID](https://zhida.zhihu.com/search?content_id=699457339&content_type=Answer&match_order=1&q=%E9%9B%AA%E8%8A%B1+ID&zhida_source=entity) 主键以及其他类型主键（比如自增）都有自己的适用场景，各有所长，无法脱离背景讲推荐 or 不推荐。

* * *

这个问题下GPT浓度太高，进入正文前有必要简单纠正几个误区~

**误区一：随机插入会引发索引树频繁大量左旋右旋**

严格来讲，这种说法算“错误”，叫“误区”还是保留了三分情面。

因为 [B+ 树](https://zhida.zhihu.com/search?content_id=699457339&content_type=Answer&match_order=1&q=B%2B+%E6%A0%91&zhida_source=entity)真的没有旋转操作~

**误区二：随机插入会引发更多的页分裂，并增加树的高度**

在该问题下，我们是在对比“随机插入”和“顺序插入”之间的区别，而不是“随机插入”和“不插入”的差异。

B+ 树只有“插入路径”上的页有分裂的可能性，无论随机还是顺序，路径上经过的页数量是相同的。

而且，正相反，随机插入引发页分裂的概率可能会更低一些，因为树中的所有页的空间都可能会被用于存储节点，将页加满并触发分裂的次数可能会更少一点。不像顺序插入，瞄准最右路径上的页面进行“狙击”。

旧金山大学有个数据结构可视化页面，大家可以选择 B+ 树感受下。

**误区三：用字符串类型存储 UUID，并以此为基础进行性能测试，尝试说明问题**

除非是可读性较为重要的场景，否则我们一般不会用形如“48e67392-ff2f-0d07-6bf5-ad4312132f50”的字符串类型存储 UUID，而是用 BINARY 直接存储其 128 bits 序列。

**误区四：因为某个方案或建议被“八股文”包含了，所以是错的**

这个误区本身也是另一种形式的“八股”~

“八股”的反义词是“实事求是”，而不是简单在“八股结论”前加个“Not”。

* * *

接下来，正文开始。

一. UUID 作为主键的考量
---------------

UUID 原本是不适合用作主键的，多数场景下都没有讨论其优缺点的必要。因为 [OSF DCE](https://zhida.zhihu.com/search?content_id=699457339&content_type=Answer&match_order=1&q=OSF+DCE&zhida_source=entity) 变种的版本1到5生成的 UUID 都近乎无序。这会使得 MySQL 页缓存命中率极低。

但，2024 年，[RFC-9562](https://zhida.zhihu.com/search?content_id=699457339&content_type=Answer&match_order=1&q=RFC-9562&zhida_source=entity) 发布，追加了 6、7、8 三个版本；其中的 6、7 两版本生成的 UUID 总体上是单调递增的，UUID 主键方案的可行性大幅提升。

在这里也简要描述下 OSF DCE 版本 1-8 的格式。

> 备注：高版本未必对低版本形成替换关系，更多的是适用于不同的业务场景。

### 1.1 UUID 总体格式

这 8 个版本都遵从如下布局

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-5-22%2013-23-03/d4ce4b3f-8b36-4322-914e-ea10c4ed5a07.jpeg?raw=true)

UUID 总体格式

其中有两位固定值 10，表示 OSF DCE 变种；有 4 位表示版本号；其余位的内容取决于具体的版本。

### 1.2 UUID 版本 1

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-5-22%2013-23-03/f7e12b97-2f0e-46d6-9ad5-2e11ff1cebba.jpeg?raw=true)

UUID 版本1格式

将 60 位时间戳拆成 3 部分：低 32 位、中间 16 位、高 12 位；分别填充至可由版本定义的靠前的位置。因为这三部分不是按照高、中、低的顺序排列的，所以版本 1 的 UUID 并非严格递增（只能在 400 多秒内维持递增）。

clock\_seq 类似于计数器，防止在同一个时间戳下生成相同 UUID。

最后一部分是生成 UUID 的节点对应的 MAC 地址。

### 1.3 UUID 版本 2

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-5-22%2013-23-03/a526e5e5-a32a-447f-b02d-08d1e5d901ad.jpeg?raw=true)

UUID 版本2格式

RFC 9562 只是声明了这个版本，具体细节则交由另一个技术标准来描述)。

总体和 Version 1 类似，但时间戳低 32 位被换成了“本地用户id”，clock_seq 低 8 位也分出来用于存储 Domain 信息。

Version 2 是为身份验证服务的，不具备通用性。

### 1.4 UUID 版本 3

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-5-22%2013-23-03/5d105e01-60ed-456f-b5d6-e9c61b4c25b9.jpeg?raw=true)

UUID 版本3格式

该版本 UUID 的生成分为 3 步：

1.  明确对应实体所属“命名空间”和“唯一名称”；
2.  对“命名空间“和”唯一名称”两字符串追加在一起，并计算 [MD5](https://zhida.zhihu.com/search?content_id=699457339&content_type=Answer&match_order=1&q=MD5&zhida_source=entity)；
3.  根据 MD5 生成 UUID；

显然，这个版本的 UUID 近乎无序。

### 1.5 UUID 版本 4

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-5-22%2013-23-03/78835ba7-d5aa-4da1-b2d6-ad2163450d50.jpeg?raw=true)

UUID 版本4格式

该版本首先生成 122 bits 长度的随机值，并将这些随机值分 3 部分填充至对应位置，进而生成 UUID。

显然，这个版本的 UUID 无序。

### 1.6 UUID 版本 5

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-5-22%2013-23-03/89a3dc55-3b9b-420d-bed3-b07bdde946b1.jpeg?raw=true)

UUID 版本5格式

该版本和版本 3 很类似，只是摘要算法改用 [SHA-1](https://zhida.zhihu.com/search?content_id=699457339&content_type=Answer&match_order=1&q=SHA-1&zhida_source=entity)。

当然，近乎无序。

### 1.7 UUID 版本 6

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-5-22%2013-23-03/721a4e68-600e-4b67-967b-0a04c406d0a4.jpeg?raw=true)

UUID 版本6格式

可看做“有序的版本 1”，将时间戳“低、中、高”的排列改为了“高、中、低”的排列，其余部分和版本 1 类似。

### 1.8 UUID 版本 7

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-5-22%2013-23-03/0ff73239-2e3b-4724-8629-3e7bfd7d3edf.jpeg?raw=true)

UUID 版本7格式

开头 48 位时间戳，其余两个可自定义部分既可以用随机值填充，也可以用计数器填充。

总体有序。

### 1.9 UUID 版本 8

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-5-22%2013-23-03/c9f3afb5-62d7-4e2d-82a4-d5456fe6ca23.jpeg?raw=true)

UUID 版本8格式

该版本主打一个自由和扩展，对除版本号和变种编号两字段外的其余部分没有任何约束，交由生成器实现者随意发挥。

### 1.10 UUID 优缺点

UUID 的优点是：在生成全局唯一键过程中，无需额外的进程间协调通信，吞吐较高，成本较低。

UUID 的缺点是：

1.  有序版本 6、7 刚发布不久，很多三方库还没来得及支持；
2.  虽然 UUID 重复概率极低，但不为零，所以需要使用者自己做好冲突检测并处理；
3.  长度为 128 bits ，比自增主键常用类型 BIGINT 和雪花 ID 多了 64 bits；不过多数场景不会太纠结这 64 bits；

二. 雪花 ID 作为主键的考量
----------------

雪花 ID 算法由 Twitter（现在叫 X）提出，其由 64 bits 构成。

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-5-22%2013-23-03/f8246225-495d-4922-8212-495bc9f41c5b.jpeg?raw=true)

雪花ID格式

第一位是 0，紧接着是 41 位时间戳，然后是 10 位机器ID，最后是 12 位计数器。

雪花 ID 的优点是：

1.  在生成全局唯一键过程中，无需额外的进程间协调通信，吞吐较高，成本较低；
2.  只有 64 位，比 UUID 短；

雪花 ID 的缺点是：检测到时间回拨时，会直接拒绝生成新的 ID ，需要进行额外处理；

三. 自增主键的考量
----------

自增主键的优点是：简单，无需额外开发。

自增主键的缺点是：扩展性有限，当业务压力超过单表承载能力后，将无法保证全局唯一。

总结
--

本文分析了 UUID、雪花 ID、自增 ID 用作主键时的优缺点。

其实除此之外，还有很多其他 ID 生成方案；但限于篇幅，不在这里展开了。

才疏学浅，未能窥其十之一二，欢迎大家随时交流补充。

* * *



参考
--

1.  [^](#ref_1_0)Data Structure Visualization: https://www.cs.usfca.edu/~galles/visualization/Algorithms.html
2.  [^](#ref_2_0)RFC 4122: https://datatracker.ietf.org/doc/html/rfc4122
3.  [^](#ref_3_0)RFC 9562: https://datatracker.ietf.org/doc/html/rfc9562
4.  [^](#ref_4_0)C311: https://pubs.opengroup.org/onlinepubs/9696989899/toc.pdf
5.  [^](#ref_5_0)Snowflake ID - Wikipedia: https://en.wikipedia.org/wiki/Snowflake\_ID
6.  [^](#ref_6_0)GitHub - twitter-archive/snowflake: https://github.com/twitter-archive/snowflake/tree/b3f6a3c6ca8e1b6847baa6ff42bf72201e2c2231