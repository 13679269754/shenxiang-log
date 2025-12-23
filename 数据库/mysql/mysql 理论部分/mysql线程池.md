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

## 行业方案：Percona 线程池实现

###  线程池的架构

**worker 线程**
- 如果该线程所在组中没有 listener 线程，则该 worker 线程将成为 listener 线程，通过 epoll 的
- worker 线程数目动态变化，并发较大时会创建更多的 worker 线程，当从队列中取不到 event 
- 一个 worker 线程只属于一个线程组。

**listener 线程**
当高低队列为空，listen 线程会自己处理，无论这次获取到多少事务。否则 listen 线程会把请求加入到队列中，**如果此时`active_thread_count=0`，唤醒一个工作线程**。

**timer 线程**
负责周期性（检查时间间隔为`threadpool_stall_limit`毫秒）检查线程组是否处于阻塞状态。当检测到阻塞的线程组时，timer 线程会通过唤醒或创建新的工作线程（`wake_or_create_thread` 函数）来让线程组恢复工作。

**高低优先级队列**
为了提高性能，将队列分为优先队列和普通队列。这里采用引入两个新变量`thread_pool_high_prio_tickets`和`thread_pool_high_prio_mode`。由它们控制高优先级队列策略。对**每个新连接**分配可以进入高优先级队列的 ticket。