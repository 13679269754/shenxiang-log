| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-3月-07 | 2024-3月-07  |
| ... | ... | ... |
---
# redis命令.md

[toc]

[命令手册](https://redis.com.cn/commands.html)

读:
| 命令 | 描述 |
| ---- | ---- |
| ***key*** |
| DUMP |序列化给定 key ，并返回被序列化的值 |
| EXISTS | 检查给定 key 是否存在 |
| KEYS | 查找所有符合给定模式的 key |
| PERSIST | 移除 key 的过期时间，key 将持久保持 |
| PTTL | 以**毫秒**为单位返回 key 的剩余的生存时间 |
| TTL | 以**秒**为单位，返回给定 key 的剩余生存时间 |
| RANDOMKEY | 从当前数据库中随机返回一个 key |
| TYPE | 返回 key 所储存的值的类型 |
| ***String*** |
| GET | 获取指定 key 的值 |
| GETRANGE | 返回 key 中字符串值的子字符 |
| GETBIT | 对 key 所储存的字符串值，获取指定偏移量上的位 ( bit ) |
| MGET | 获取所有(一个或多个)给定 key 的值 |
| ***Hash*** |
| HEXISTS | 用于判断哈希表中字段是否存在 |
| HGET | 获取存储在哈希表中指定字段的值 |
| HGETALL | 获取在哈希表中指定 key 的所有字段和值 |
| HINCRBY | 为存储在 key 中的哈希表指定字段做整数增量运算 |
| HLEN | 获取存储在 key 中的哈希表的字段数量|
| HVALS | 用于获取哈希表中的所有值 |
| ***List*** |
| BLPOP | 移出并获取列表的第一个元素 |
| BRPOP | 移出并获取列表的最后一个元素 |
| BRPOPLPUSH | 从列表中弹出一个值，并将该值插入到另外一个列表中并返回它 |
| LINDEX | 	通过索引获取列表中的元素 |
| LLEN | 获取列表长度 |
| LPOP | 移出并获取列表的第一个元素 |
| RPOP | 移除并获取列表最后一个元素 |
| RPOPLPUSH | 移除列表的最后一个元素，并将该元素添加到另一个列表并返回 |
| ***Set*** |
| SCARD | 获取集合的成员数 |
| SDIFF | 返回给定所有集合的差集 |
| SDIFFSTORE | 返回给定所有集合的差集并存储在 destination 中 |
| SINTER | 返回给定所有集合的交集 |
| SINTERSTORE | 返回给定所有集合的交集并存储在 destination 中 |
| SMEMBERS | 返回集合中的所有成员 |
| SRANDMEMBER | 返回集合中一个或多个随机数 |
| SUNION | 返回所有给定集合的并集 |
| SSCAN | 迭代集合中的元素 |
| SISMEMBER | 判断 member 元素是否是集合 key 的成员 |
| ***Zset*** |
| ZCARD | 获取有序集合的成员数 |
| ZCOUNT | 计算在有序集合中指定区间分数的成员数 |
| ZLEXCOUNT | 在有序集合中计算指定字典区间内成员数量 |
| ZRANGE | 通过索引区间返回有序集合成指定区间内的成员 |
| ZRANGEBYLEX | 通过字典区间返回有序集合的成员 |
| ZRANGEBYSCORE | 通过分数返回有序集合指定区间内的成员 |
| ZRANK | 返回有序集合中指定成员的索引 |
| ZREVRANGE | 返回有序集中指定区间内的成员，通过索引，分数从高到底 |
| ZREVRANGEBYSCORE | 返回有序集中指定分数区间内的成员，分数从高到低排序 |
| ZREVRANK | 返回有序集合中指定成员的排名，有序集成员按分数值递减(从大到小)排序 |
| ZSCORE | 返回有序集中，成员的分数值 |
| SSCAN | 迭代集合中的元素 |
| ZSCAN | 迭代有序集合中的元素（包括元素成员和元素分值） |
| ***Redis 管理***  |
| CONFIG GET | 获取指定配置参数的值 |
| DBSIZE | 返回当前数据库的 key 的数量 |
| INFO | 获取 Redis 服务器的各种信息和统计数值 | 
| LASTSAVE | 返回最近一次 Redis 成功将数据保存到磁盘上的时间 | 
| ROLE | 返回主从实例所属的角色 |



写
| 命令 | 描述 |
| ---- | ---- |
| ***key*** |
| DEL | 用于删除 key |
| MOVE | 将当前数据库的 key 移动到给定的数据库中 |
| PERSIST | 移除 key 的过期时间，key 将持久保持 |
| RENAME | 	修改 key 的名称 |
| RENAMENX | 仅当 newkey 不存在时，将 key 改名为 newkey |
| ***String*** |
| SET | 设置指定 key 的值 |
| GETSET | 将给定 key 的值设为 value ，并返回 key 的旧值 ( old value ) |
| SETBIT | 对 key 所储存的字符串值，设置或清除指定偏移量上的位(bit) |
| SETEX | 设置 key 的值为 value 同时将过期时间设为 seconds |
| SETNX | 只有在 key 不存在时设置 key 的值 |
| SETRANGE | 从偏移量 offset 开始用 value 覆写给定 key 所储存的字符串值 |
| MSET | 同时设置一个或多个 key-value 对 |
| MSETNX | 同时设置一个或多个 key-value 对 ,只有在 key 不存在时设置 key 的值 |
| PSETEX | 以毫秒为单位设置 key 的生存时间 |
| INCR | 将 key 中储存的数字值增一 |
| INCRBY | 将 key 所储存的值加上给定的增量值 ( increment ) |
| INCRBYFLOAT | 将 key 所储存的值加上给定的浮点增量值 ( increment ) |
| DECR | 将 key 中储存的数字值减一 |
| DECRBY | 将 key 所储存的值减去给定的减量值 ( decrement ) |
| APPEND | 将 value 追加到 key 原来的值的末尾 |
| ***Hash*** |
| HDEL | 用于删除哈希表中一个或多个字段 |
| HINCRBY | 为存储在 key 中的哈希表指定字段做整数增量运算 |
| HSET | 用于设置存储在 key 中的哈希表字段的值 |
| ***List*** |
| LINSERT | 在列表的元素前或者后插入元素 |
| LLEN | 获取列表长度 |
| LINSERT | 在列表的元素前或者后插入元素 |
| LPUSH | 将一个或多个值插入到列表头部 |
| LPUSHX | 将一个值插入到已存在的列表头部 |
| LREM | 移除列表元素 |
| LSET | 通过索引设置列表元素的值 |
| LTRIM | 对一个列表进行修剪(trim) |
| RPUSH | 在列表中添加一个或多个值 |
| RPUSHX | 为已存在的列表添加值 |
| ***Set*** |
| SADD | 向集合添加一个或多个成员 |
| SMOVE | 将 member 元素从 source 集合移动到 destination 集合 |
| SPOP | 移除并返回集合中的一个随机元素 |
| SREM | 移除集合中一个或多个成员 |
| SUNIONSTORE | 所有给定集合的并集存储在 destination 集合中 |
| ***Zset*** |
| ZINCRBY | 有序集合中对指定成员的分数加上增量 increment |
| ZINTERSTORE | 计算给定的一个或多个有序集的交集并将结果集存储在新的有序集合 key 中 |
| ZREM | 移除有序集合中的一个或多个成员 |
| ZREMRANGEBYLEX | 移除有序集合中给定的字典区间的所有成员 |
| ZREMRANGEBYRANK | 移除有序集合中给定的排名区间的所有成员 |
| ZREMRANGEBYSCORE | 移除有序集合中给定的分数区间的所有成员 |
| ZUNIONSTORE | 计算一个或多个有序集的并集，并存储在新的 key 中 |
| ***Redis 管理***  |
| CONFIG REWRITE | 修改 redis.conf 配置文件 |
| CONFIG SET | 修改 redis 配置参数，无需重启 |
| FLUSHALL | 删除所有数据库的所有 key | 
| FLUSHDB | 删除当前数据库的所有 key | 



其他
| 命令 | 描述 |
| ---- | ---- |
| ***key*** |
| EXPIREAT | 用于为 key 设置过期时间，接受的时间参数是 UNIX 时间戳 |
| PEXPIRE | 设置 key 的过期时间，以毫秒计 |
| PEXPIREAT | 	设置 key 过期时间的时间戳(unix timestamp)，以毫秒计 |
| ***String*** |
| ***Hash*** |
| ***List*** |
| ***Set*** |
| ***Zset*** |
| ***Redis 管理***  |
| BGREWRITEAOF | 异步执行一个 AOF（AppendOnly File） 文件重写操作 |
| BGSAVE | 在后台异步保存当前数据库的数据到磁盘 |
| CLIENT | 关闭客户端连接 |
| CLIENT LIST | 获取连接到服务器的客户端连接列表 |
| CLIENT GETNAME | 获取连接的名称 |
| CLIENT PAUSE | 在指定时间内终止运行来自客户端的命令 |
| CLIENT SETNAME | 设置当前连接的名称 |
| CLUSTER SLOTS | 获取集群节点的映射数组 |
| COMMAND | 设置当前连接的名称 |
| COMMAND COUNT | 获取 Redis 命令总数 |
| COMMAND GETKEYS | 获取给定命令的所有键 |
| TIME | 返回当前服务器时间 |
| COMMAND INFO | 获取指定 Redis 命令描述的数组 |
| CONFIG RESETSTAT | 重置 INFO 命令中的某些统计数据 |
| DEBUG OBJECT | 获取 key 的调试信息 |
| DEBUG SEGFAULT | 让 Redis 服务崩溃 |
| MONITOR | 实时打印出 Redis 服务器接收到的命令，调试用 |
| SAVE | 异步保存数据到硬盘 |
| SHUTDOWN | 异步保存数据到硬盘，并关闭服务器 |
| SLAVEOF | 将当前服务器转变从属服务器(slave server) |
| SLOWLOG | 管理 redis 的慢日志 |
| SYNC | 用于复制功能 ( replication ) 的内部命令 |
| ***Redis 发布订阅*** |
| PSUBSCRIBE | 订阅一个或多个符合给定模式的频道 |
| PUBSUB | 查看订阅与发布系统状态 |
| PUBLISH | 将信息发送到指定的频道 |
| PUNSUBSCRIBE | 退订所有给定模式的频道 |
| SUBSCRIBE | 订阅给定的一个或多个频道的信息 |
| UNSUBSCRIBE | 指退订给定的频道 |
| ***Redis 事务*** |
| DISCARD | 取消事务，放弃执行事务块内的所有命令 |
| EXEC | 执行所有事务块内的命令 |
| MULTI | 标记一个事务块的开始 |
| UNWATCH | 取消 WATCH 命令对所有 key 的监视 |
| WATCH | 监视一个(或多个) key |
| ***Redis 连接*** |
| AUTH password | 验证密码是否正确 |
| ECHO message | 打印字符串 |
| PING | 查看服务是否运行 |
| QUIT | 关闭当前连接 |
| SELECT index | 切换到指定的数据库 |