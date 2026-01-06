[(6 封私信 / 13 条消息) 秒杀redis和db库存怎么保证一致性? - 知乎](https://www.zhihu.com/question/654457836/answer/3509948949) 

 关于秒杀系统中如何保证Redis和[数据库库存](https://zhida.zhihu.com/search?content_id=668243932&content_type=Answer&match_order=1&q=%E6%95%B0%E6%8D%AE%E5%BA%93%E5%BA%93%E5%AD%98&zhida_source=entity)一致性，这确实是一个非常具有挑战性的问题。我们来深入探讨一下，看看能不能找到一个更优的解决方案。

### 问题分析

你的现状是这样的：

1.  库存同步到Redis。
2.  使用[Lua脚本](https://zhida.zhihu.com/search?content_id=668243932&content_type=Answer&match_order=1&q=Lua%E8%84%9A%E6%9C%AC&zhida_source=entity)在Redis中扣减库存。
3.  扣减完成后，通过[RabbitMQ](https://zhida.zhihu.com/search?content_id=668243932&content_type=Answer&match_order=1&q=RabbitMQ&zhida_source=entity)异步创建订单并插入数据库。

现在的问题是，是否需要在RabbitMQ异步操作之前先扣减数据库的库存，保证数据一致性。这涉及到分布式系统中的事务一致性问题。

### 方案一：[乐观锁](https://zhida.zhihu.com/search?content_id=668243932&content_type=Answer&match_order=1&q=%E4%B9%90%E8%A7%82%E9%94%81&zhida_source=entity)

一种常见的方式是使用乐观锁来控制库存扣减，这样可以有效地避免并发问题：

1.  **Redis扣减库存**：使用Lua脚本在Redis中扣减库存，确保原子性。
2.  **数据库扣减库存**：通过数据库的乐观锁机制进行扣减库存。例如，使用 `update products set stock = stock - 1 where product_id = ? and stock > 0` 这样的SQL语句，确保库存扣减的安全性。
3.  **异步创建订单**：如果数据库扣减库存成功，再通过RabbitMQ异步创建订单。

**优点：** 

*   保证了库存扣减的原子性和一致性。
*   数据库操作失败时，可以及时回滚Redis中的库存。

**缺点：** 

*   在高并发场景下，数据库的性能压力较大。

### 方案二：[分布式事务](https://zhida.zhihu.com/search?content_id=668243932&content_type=Answer&match_order=1&q=%E5%88%86%E5%B8%83%E5%BC%8F%E4%BA%8B%E5%8A%A1&zhida_source=entity)

另一种方式是使用分布式事务（如2PC或TCC），但由于其实现复杂度和性能问题，在秒杀场景下不太常用。

**2PC（两阶段提交）**：

1.  **准备阶段**：所有涉及的数据库先准备事务，但不提交。
2.  **提交阶段**：所有事务都准备好后，统一提交。

**TCC（Try-Confirm-Cancel）**：

1.  **Try阶段**：预扣减库存。
2.  **Confirm阶段**：确认事务成功，扣减库存。
3.  **Cancel阶段**：事务失败，回滚库存。

**优点：** 

*   能够保证强一致性。

**缺点：** 

*   实现复杂，性能开销大，不适合高并发秒杀场景。

### 方案三：最终一致性

比较实际的方案是保证最终一致性，而不是强一致性。这样可以在高并发场景下保持较好的性能：

1.  **Redis扣减库存**：使用Lua脚本在Redis中原子性扣减库存。
2.  **记录扣减日志**：将扣减操作记录到日志中（比如[Kafka](https://zhida.zhihu.com/search?content_id=668243932&content_type=Answer&match_order=1&q=Kafka&zhida_source=entity)）。
3.  **异步更新数据库**：通过RabbitMQ异步消费扣减日志，更新数据库中的库存。

**优点：** 

*   性能较好，适合高并发场景。
*   异步处理，可以分担数据库压力。

**缺点：** 

*   存在短暂的时间窗口内数据不一致的风险。
*   需要额外处理补偿机制，确保最终一致性。

### 具体实现

假设我们选择最终一致性方案，具体实现步骤如下：

1.  **Redis Lua脚本扣减库存**：

```lua
if (redis.call('exists', KEYS[1]) == 1) then
    local stock = tonumber(redis.call('get', KEYS[1]))
    if (stock <= 0) then
        return -1
    end
    redis.call('decr', KEYS[1])
    return stock - 1
else
    return -1
end

```

1.  这个脚本确保Redis中的库存扣减是原子操作。
2.  **记录扣减日志**： 在Lua脚本执行后，记录扣减操作日志到Kafka或RabbitMQ。
3.  **异步更新数据库**： 消费扣减日志，通过异步任务更新数据库库存，并创建订单。如果更新数据库失败，可以回滚Redis中的库存。

### 总结

秒杀系统中的数据一致性问题非常复杂，需要在性能和一致性之间找到一个平衡点。

乐观锁方案适合中小型系统，但在高并发下性能瓶颈明显。

分布式事务虽然保证了强一致性，但实现复杂度高且性能开销大。

最终一致性方案则在性能和一致性之间找到了一个折中点，适合高并发的秒杀场景。

说在最后
----

最后再推荐一个免费的Redis进阶实战专栏教程，里面有优惠券秒杀和秒杀优化实战案例，希望能帮到你

### Redis进阶实战

[01、Redis项目实战：Redis常见命令（数据结构](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8446)

[02、Redis项目实战：Redis的安装及启动](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8448)

[03、Redis项目实战：Redis的Java客户端](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8450)

[04、Redis项目实战：session实现短信登录（并剖析问题）](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8452)

[05、Redis项目实战：Redis实现短信登录（原理剖析+代码优化）](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8454)

[06、Redis项目实战：Redis缓存最佳实践（问题解析+高级实现）](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8456)

[07、Redis项目实战：解决Redis缓存穿透](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8458)

[08、Redis项目实战：互斥锁](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8460)

[09、Redis项目实战：封装缓存工具（高级写法）](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8462)

[10、Redis项目实战：优惠券秒杀+细节解决超卖](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8464)

[11、Redis项目实战：基于Redis的分布式锁及优化](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8466)

[12、Redis项目实战：秒杀优化](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8468)

[13、Redis项目实战：Redis消息队列实现异步秒杀](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8470)

[14、Redis项目实战：达人探店（Redis实现点赞](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8472)

[15、Redis项目实战：好友关注](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8474)

[16、Redis项目实战：GEO实现附近商铺](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8476)

[17、Redis项目实战：BitMap实现用户签到功能](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8478)

[18、Redis项目实战：终结篇（HyperLogLog实现UV统计）](https://link.zhihu.com/?target=https%3A//cxykk.com/%3Fp%3D8480)