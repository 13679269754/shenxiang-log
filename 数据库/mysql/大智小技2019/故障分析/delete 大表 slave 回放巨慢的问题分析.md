[delete 大表 slave 回放巨慢的问题分析](https://mp.weixin.qq.com/s?__biz=MzU2NzgwMTg0MA==&mid=2247484885&idx=1&sn=f4ed03270c6831e78846cf0932af8514&ascene=4&devicetype=android-34&version=4.1.26.6024&abtest_cookie=AAACAA%3D%3D&lang=zh_CN&countrycode=CN&exportkey=n_ChQIAhIQ1XjmicWOGa5dp%2Bv1nl94HRLiAQIE97dBBAEAAAAAAOLnBaQNMmwAAAAOpnltbLcz9gKNyK89dVj0KODb2aFXtgLOTIC5VMgYH3JaoBBOdWVdzu89oSNDGQpVsh6Jryznpkz3GzyC3sWfc8vDcZykZI5NCWUKkPFnwK%2Bnmy6b7jrBTUzvL6UwLO99CDcc%2F7u%2FCChzABSYyRGaMKTeQepIQuOk1DgLbof7%2FS56XY%2Fv6jXgzOsjEz4iAhmVkQQf0t58gM27ap4TA1IEkOhwETlSLy8CJF4nOsg8Ac1sEzgsqMsPx2k7p627PGVAk1JIwP%2FF5NgQ0Mg%3D&pass_ticket=v6y3v6ZSdp41yqQjkX%2FejgxEtCliBAMVXju%2FV9YBX9HKrzQzZCcHiMjj9NDuMzGf&wx_header=3&from=industrynews&platform=win&nwr_flag=1#wechat_redirect)

结论:  
通过测试发现使用 slave_rows_search_algorithms= INDEX_SCAN,HASH_SCAN 配置在此场景下回放 binlog  
会有大幅性能改善，这种方式会有一定内存开销，所以要保障内存足够创建 hash 表，才会看到性能提升。  

对于此问题的改进建议：  
1. 避免无 where 条件的 delete 或 update 操作大表，如果需要全表 delete 请使用 truncate 操作  
2. 在 binlog row 模式下表结构最好能有主键  
3. 将 slave_rows_search_algorithms 设置为 INDEX_SCAN,HASH_SCAN，会有一定性能改善。  