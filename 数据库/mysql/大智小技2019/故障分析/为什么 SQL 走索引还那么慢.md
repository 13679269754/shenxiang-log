[技术分享 | MySQL 优化：为什么 SQL 走索引还那么慢？](https://mp.weixin.qq.com/s?__biz=MzU2NzgwMTg0MA==&mid=2247486365&idx=1&sn=dfba1fb5131d727bc06629bd947eec58&ascene=4&devicetype=android-34&version=4.1.26.6024&abtest_cookie=AAACAA%3D%3D&lang=zh_CN&countrycode=CN&exportkey=n_ChQIAhIQ%2BOzjWr1xNj24jxLFV5MHaRLiAQIE97dBBAEAAAAAAFs1NJiBuGMAAAAOpnltbLcz9gKNyK89dVj0WzSaQuDPs%2FyP9Ld%2FFS0ReD7B9WbAohyGTSgm5tl25cGRcMsCXgo%2Bxs8fKsNNXLb7aMl96BV0thSxOlLZ32VgtgWn%2FPbSyBLwd7XoUgLWCNvIdjkW5s1YhKjhf9884CGtocUHqmnzO1mEBezyHVZUtEDokFI%2BrI1anZFGwcXPSxviGFKoV15yruo8j4zD%2FfdhLwYTE8Ci9tVhf1HyITCUMHqzk74Yp1GO9IgfUYw7Zxawz59b7IBlnTOMQ5c%3D&pass_ticket=zaF1eblI%2BH%2Fth4fNwEG14ViBDxiEpDt6eXBAdcXC1UbzN%2BHfg6w%2FKsa17tOLTZ%2FK&wx_header=3&from=industrynews&platform=win&nwr_flag=1#wechat_redirect)

小结：
一个典型的 order by 查询的优化，添加更合适的索引可以避免性能问题：执行计划使用索引并不意味着就能执行快（索引的选择度过低，由于需要回表，中间结果集排序等原因，查询很慢）。


