[FTWRL 一个奇怪的堵塞现象和其堵塞总结](https://mp.weixin.qq.com/s?__biz=MzU2NzgwMTg0MA==&mid=2247485690&idx=1&sn=8dd60d56f15be145c466caeaf9fce3fb&ascene=4&devicetype=android-34&version=4.1.26.6024&abtest_cookie=AAACAA%3D%3D&lang=zh_CN&countrycode=CN&exportkey=n_ChQIAhIQyaceR%2BN9WaXsMPzw7qLWFxLiAQIE97dBBAEAAAAAAPQDBTK6D%2FkAAAAOpnltbLcz9gKNyK89dVj0Gh0R3J5j4u%2BpnBTzQIjhf9dT5xTitFA7YBw0JC8uhmjEzmMxrsNraNovpUOxN0Myuts5fGkXX2OHNSbrRVUYR6zuC94uXiZnF7u8gJHyhDUclLPuYXC9tbdgg6Aah6pqfzrHNCa8ydOto75HOhWRsYFzKyz35VRmPY8CTpp76hgu2yAXE2ymI4KIdpB7XW7ZD74FL9KKwR0x1dHornnGoqriIP9dzTh5LnPDDzhP7Q5FSglN3ElyJiwxwIg%3D&pass_ticket=iRqB5f29jrh%2BGc1ulgcUZxZqouzBPWj8W7feh46vm%2F%2FfC3G860y%2BngizXU87MIXa&wx_header=3&from=industrynews&platform=win&nwr_flag=1#wechat_redirect)

（1）被什么堵塞
* 长时间的 DDL\DML\FOR UPDATE 堵塞 FTWRL ，因为 FTWRL 需要获取 GLOBAL 的 S 锁，而这些语句都会对 GLOBAL 持有 IX（MDL_INTENTION_EXCLUSIVE） 锁，根据兼容矩阵不兼容。等待为：Waiting for global read lock 。本文的案例 1 就是这种情况。

* 长时间的 select 堵塞 FTWRL ， 因为 FTWRL 会释放所有空闲的 table 缓存，如果有占用者占用某些 table 缓存，则会等待占用者自己释放这些 table 缓存。等待为：Waiting for table flush 。本文的案例 2 就是这种情况，会堵塞随后关于本表的任何语句，即便 KILL FTWRL 会话也不行，除非 KILL 掉长时间的 select 操作才行。实际上 flush table 也会存在这种堵塞情况。

* 长时间的 commit(如大事务提交)也会堵塞 FTWRL ，因为 FTWRL 需要获取 COMMIT 的 S 锁，而 commit 语句会对 commit 持有 IX（MDL_INTENTION_EXCLUSIVE）锁，根据兼容矩阵不兼容。等待为 Waiting for commit lock 。

（2）堵塞什么
* FTWRL 会堵塞 DDL\DML\FOR UPDATE 操作，堵塞点为 GLOBAL 级别的 S 锁，等待为：Waiting for global read lock 。

* FTWRL 会堵塞 commit 操作，堵塞点为 COMMIT 的 S 锁，等待为 Waiting for commit lock 。

* FTWRL 不会堵塞 select 操作，因为 select 不会在 GLOBAL 级别上锁。

最后提醒一下很多备份工具都要执行 FTWRL 操作，一定要注意它的堵塞/被堵塞场景和特殊场景。