[tcmalloc解决mysqld实例引发的cpu过高问题](https://mp.weixin.qq.com/s?__biz=MzU2NzgwMTg0MA==&mid=2247485132&idx=1&sn=1aa7cfebc9188a2946094456d72075c0&ascene=4&devicetype=android-34&version=4.1.26.6024&abtest_cookie=AAACAA%3D%3D&lang=zh_CN&countrycode=CN&exportkey=n_ChQIAhIQJZOBRl3XRdn1N4m4%2F5T5rhLiAQIE97dBBAEAAAAAABrkI5LPhhMAAAAOpnltbLcz9gKNyK89dVj0yhiuqJjvfEV8cBl3r7wHOuTkim1Xhf06TkkyshipbDf9XclQTD7ydLI2S17dW%2BRgRc1tjuFbSVdDUfgXSS09nzmHQlx%2FE60ZccXXY5%2BGClfwF3OFWPiaiP6177rE8FCVSHMriYMYd8e7gZFYHiSWl7d9OXmML4afpNFHktf1KcgU3w53odTYIiJVEGs8xiJFSBqjfydIdE0AwGrvZLMv2Wutwo6o0IByWFnN00%2BCrlanLj%2Bx%2FHzsXiyX31k%3D&pass_ticket=eTzQavNLiCBUCOxsAeBl4bdZXhSEykooGMPWmkHbjBh%2BlxBAUTIkxEqS%2Ff5r6r6s&wx_header=3&from=industrynews&platform=win&nwr_flag=1#wechat_redirect)

故障表现：  
```select uid from test_history where cat_id = '99999' and create_time >= '2019-07-12 19:00:00.000' and uid in (......)```
单条执行可以秒级完成，但是并发执行会遭遇执行时间过长（超过1个小时）且CPU过高的问题。

诊断思路:  
mpstat -P ALL 1，查看cpu使用情况，主要消耗在sys即os系统调用上  
perf top，cpu主要消耗在_spin_lock  
生成perf report查看详细情况  


> row_vers_build_for_consistent_read会陷入一个死循环，跳出条件是该条记录不需要快照读或者已经从undo中找出对应的快照版本，每次循环都会调用mem_heap_alloc/free。  
> 而该表的记录更改很频繁，导致其undo history list比较长，搜索快照版本的代价更大，就会频繁的申请和释放堆内存。  
> Linux原生的内存库函数为ptmalloc，malloc/free调用过多时很容易产生锁热点。  
> 当多条 SQL 并发执行时，会最终触发os层面的spinlock，导致上述情形。  


将mysqld的内存库函数替换成tcmalloc，相比ptmalloc，tcmalloc可以更好的支持高并发调用。

