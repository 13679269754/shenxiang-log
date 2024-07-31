| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2023-12月-21 | 2023-12月-21  |
| ... | ... | ... |
---
# mysql线程池


[mysql线程池](https://mp.weixin.qq.com/s/ZhdAbtGFchCV87NJNUK_MQ)

线程池适合场景  
1.OLTP  
2.大量连接的只读短查询  
3.大量连接出现后导致mysql性能衰减（频繁的上下文切换导致） 

3种线程
listener 线程
timer 线程
worker 线程

两种线程队列：高优先级，与低优先级

各mysql 分支版本的区别