
**核心目标**：快速掌握游戏高并发场景下的 MySQL 优化、分库分表、Redis 高可用核心技能，跳过非必要游戏业务知识，直接适配岗位需求
**基础前提**：你已掌握 Linux、MySQL 基础、Percona XtraBackup、Git

| 天数 | 核心学习目标 | 具体学习内容 & 实战任务 | 工具 & 资源 | 验收标准 |
|------|--------------|------------------------|-------------|----------|
| **Day1** | 搞定 MySQL 高并发参数调优 + 压力测试 | **学习内容**<br>1. MySQL 高并发核心参数：`max_connections`（游戏建议2000-5000）、`innodb_buffer_pool_size`（物理内存70%）、`innodb_flush_log_at_trx_commit`（非核心业务设2）、`wait_timeout`（短连接设30s）<br>2. 慢查询阈值设置（游戏建议100ms，`long_query_time=0.1`）<br><br>**实战任务**<br>1. 本地搭 MySQL 实例，修改上述参数并重启验证<br>2. 用 sysbench 压测：`sysbench oltp_read_write --tables=10 --table-size=1000000 --threads=200 --time=60 run`，对比调优前后 QPS/TPS 变化 | 工具：sysbench、MySQL 8.0<br>资源：MySQL 官方手册《Server System Variables》 | 1. 参数修改生效<br>2. 压测后 QPS 提升 30% 以上<br>3. 慢查询日志能捕获 100ms 以上 SQL |
| **Day2** | 掌握游戏场景索引设计 + 锁优化 | **学习内容**<br>1. 游戏核心表索引原则：<br> - `t_player` 必须建 `uid` 主键，联合索引（`uid+server_id`）<br> - 禁止冗余索引，优先用**覆盖索引**（避免回表）<br>2. 游戏事务优化：缩小事务范围、乐观锁（版本号）替代悲观锁（解决道具扣减锁等待）<br><br>**实战任务**<br>1. 建游戏核心表 `t_player(uid,server_id,gold,props,create_time)`，按原则设计索引<br>2. 模拟道具扣减场景：写 2 段 SQL（悲观锁 vs 乐观锁），用 sysbench 压测对比锁等待时间 | 工具：MySQL Workbench、sysbench<br>资源：《高性能MySQL》第6章（索引）、第7章（锁） | 1. 索引设计符合游戏规范<br>2. 乐观锁方案锁等待时间降低 80% 以上 |
| **Day3** | Sharding-JDBC 分库分表实战落地 | **学习内容**<br>1. 回顾之前给你的玩家数据分库分表配置<br>2. 核心知识点：分片键选择（uid 均匀分片）、读写分离配置、跨库查询规避方案<br><br>**实战任务**<br>1. 用 Docker 搭 10 个 MySQL 实例（模拟 ds_0~ds_9）<br>2. 按配置文件完成 Sharding-JDBC 部署，插入 100 万条 uid 数据<br>3. 验证：查询任意 uid，能正确路由到对应库表 | 工具：Docker、Sharding-JDBC 5.4.1、Maven<br>资源：ShardingSphere 官网《用户手册-分库分表》 | 1. 成功搭建分库分表环境<br>2. 数据均匀分布在 100 张表中<br>3. 读写分离生效（写主库、读从库） |
| **Day4** | Online DDL 工具实战（游戏无停机改表） | **学习内容**<br>1. 游戏场景改表痛点：不能停机，大表加索引会锁表<br>2. 工具对比：pt-online-schema-change vs gh-ost（优先 gh-ost，更稳定）<br><br>**实战任务**<br>1. 下载安装 percona-toolkit、gh-ost<br>2. 对 `t_player` 大表（100 万数据）执行 `ADD COLUMN`，用 gh-ost 实现无锁改表<br>3. 观察改表期间，sysbench 压测是否有性能波动 | 工具：percona-toolkit、gh-ost<br>资源：gh-ost 官方文档、Percona 博客《Online DDL Best Practices》 | 1. 成功无锁给大表加字段<br>2. 改表期间 QPS 波动小于 10% |
| **Day5** | Redis 哨兵模式部署 + 缓存三大问题解决 | **学习内容**<br>1. 哨兵模式核心配置：主从节点、哨兵节点（至少 3 个）、脑裂预防（`min-replicas-to-write 1`）<br>2. 游戏缓存三大问题解决方案：<br> - 穿透：布隆过滤器拦截无效 uid<br> - 击穿：热点 uid 加互斥锁<br> - 雪崩：设置随机过期时间<br><br>**实战任务**<br>1. 本地搭 1主2从3哨兵的 Redis 集群<br>2. 模拟主库宕机，验证哨兵 10 秒内自动切换<br>3. 写代码实现布隆过滤器拦截无效 uid 查询 | 工具：Redis 6.2、Java/Python（任选）<br>资源：Redis 官方手册《Sentinel》、B站《Redis 缓存三大问题实战》 | 1. 哨兵模式部署成功，主从切换自动完成<br>2. 布隆过滤器能拦截 99% 无效 uid 查询 |
| **Day6** | 监控告警体系搭建（MySQL + Redis） | **学习内容**<br>1. 游戏 DBA 核心监控指标：<br> - MySQL：QPS/TPS、锁等待数、慢查询数、连接数<br> - Redis：内存使用率、命中率、主从同步延迟、key 过期数<br>2. Prometheus + Grafana 部署流程<br><br>**实战任务**<br>1. 用 Docker 搭 Prometheus + Grafana<br>2. 配置 mysqld_exporter、redis_exporter，接入监控<br>3. 配置告警规则（如 MySQL 慢查询>10 个/分钟告警） | 工具：Docker、Prometheus、Grafana、mysqld_exporter、redis_exporter<br>资源：Grafana 官网 MySQL/Redis 监控模板 | 1. 监控大盘能展示核心指标<br>2. 触发阈值时能收到告警通知 |
| **Day7** | 备份恢复实战 + 知识整合 & 踩坑总结 | **学习内容**<br>1. 游戏数据备份要求：秒级快照、分钟级恢复<br>2. Percona XtraBackup 增量备份 + 恢复流程<br><br>**实战任务**<br>1. 用 xtrabackup 做全量备份 + 增量备份<br>2. 模拟数据库宕机，用备份文件恢复，记录恢复时间（要求 <5 分钟）<br>3. 整理 6 天学习的**游戏 DBA 踩坑清单**（如禁止 select *、uid 必须做主键等） | 工具：Percona XtraBackup<br>资源：Percona XtraBackup 官方文档 | 1. 增量备份恢复成功，耗时 <5 分钟<br>2. 整理出至少 10 条游戏 DBA 避坑结论 |

## 额外紧急建议
1. **碎片化时间**：刷游戏 DBA 面试高频题（如“如何解决游戏跨库查询”“Redis 脑裂怎么处理”），直接记结论。
2. **实战优先**：所有任务必须动手做，看文档 10 遍不如实操 1 遍，遇到问题优先查官方文档/Stack Overflow。
3. **避坑清单**：每天结束后，把当天踩的坑记下来，比如“sysbench 压测时线程数不能超过 CPU 核心数 2 倍”。
