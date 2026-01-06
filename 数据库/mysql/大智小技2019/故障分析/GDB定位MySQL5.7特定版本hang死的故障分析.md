[深度分析 | GDB定位MySQL5.7特定版本hang死的故障分析](https://mp.weixin.qq.com/s?__biz=MzU2NzgwMTg0MA==&mid=2247484150&idx=1&sn=538f034b76c792383e08be8f2a80c272&ascene=4&devicetype=android-34&version=4.1.26.6024&abtest_cookie=AAACAA%3D%3D&lang=zh_CN&countrycode=CN&exportkey=n_ChQIAhIQPSU75ObsKLe0Ll7%2FT1bzzRLiAQIE97dBBAEAAAAAACAIFyvE4ckAAAAOpnltbLcz9gKNyK89dVj0d9PfSdlT82zSF%2B%2FVQI3G%2FbrBG5MXOlyYudkHdF2Pe2oWxG0aqOlskOOLRNMtMOKrek60d5GD9yX1oSmBbvih0LKwVHkD0mceYjJCYQpjG33%2BsQ7Z970ZmN50pbICXg1w9iQjbejMmqzZJmmnXxnu6rGq6nrzSK%2Fl74rGzp%2BlYBJHkAqRnD82KLorv7ayHQHCO10QYz%2B7nrW5OLBNPK6w9ysVY4RHxhHhKobGD5j9UqyLTLiL%2Br7FBc47PrE%3D&pass_ticket=NjQaPnXHmb0cj9Cgh%2B0hyOaueiT9Stdc9pJwAAk7YpYrKe415Rd0oZDoyXjclYTR&wx_header=3&from=industrynews&platform=win&nwr_flag=1#wechat_redirect)


问题分析：

1.SHOW GLOBAL VARIABLES
* 持有LOCK_global_system_variables, 等待LOCK_log

2.SLAVE SQL THREAD
* 持有LOCK_log, 等待LOCK_status

3.SHOW GLOBAL STATUS
* 持有LOCK_status, 等待LOCK_global_system_variables

```
问题1: 新连接为什么无法建立?
连接的初始化需要 LOCK_global_system_variables, 此 mutex 被占用,导致新连接无法初始化

问题 2:查询操作为什么超时?
SQL 查询时也需要 LOCK_global_system_variables, 此 mutex 被占用,导致查询被阻塞
```

问题结论

经过一轮分析,我们基本找到问题原因. 但心中还存在疑问：
* LOCK_global_system_variables是热点的mutex,大概率会出现争用,但不至于死锁.
* show global variables操作为何需要LOCK_log?
* 这样常用的查询真的会稳定导致数据库死锁么?

问题处理：
对于环境中出现死锁的这一组Percona MySQL 5.7.23-23半同步主从,我们使用5.7.25-28版本进行了升级后此问题消失,至此可以基本确定导致问题的根本原因.