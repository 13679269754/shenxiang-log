
## 事故信息
### 服务访问报错信息
![[企业微信截图_17643105873070.png]]
### 事故原因

1. 判断为从库与主库间的网络被占满，心跳包无法发送到从库。
2. 主从间网络时断时续，无法在 down-after-milliseconds （60000 60秒）内判断从库下线。
导致部分服务，部分时间点访问报错。

## 相关配置项目

| 配置项                          | 作用说明                                                                 | 推荐配置值                |
|---------------------------------|--------------------------------------------------------------------------|---------------------------|
| `sentinel monitor mymaster 主库IP 6379 2` | 判定主库“客观不可用（ODOWN）”需要的哨兵节点数（默认 2，需 ≤ 哨兵总节点数） | 保持默认（如 3 个哨兵设 2）|
| `sentinel minimum-replicas-to-write 0` | 主库接受写操作前，至少需要多少个从库处于“已同步”状态（关键配置）           | 设为 0（无需从库也能写）  |
| `sentinel minimum-replicas-max-lag 10` | 从库同步主库的最大延迟（秒），超过则视为“同步失效”                       | 设为 10（宽松阈值，避免误判）|
| `sentinel down-after-milliseconds mymaster 30000` | 哨兵判定单个节点（主/从）不可用的超时时间                                 | 保持 30 秒（避免网络抖动误判）|

## 优化方案


调低 down-after-milliseconds 调整为 3000 (3s)
```bash
SENTINEL SET master-hty-6100 down-after-milliseconds 3000
```

同时修改配置文件添加相关配置

```bash
sentinel down-after-milliseconds master-hty-6000 3000
```

调整从库下线灵敏度，我们未使用redis读写分离架构；且从库位于不同网络环境，网络环境复杂，可能偶发网络不可达。


### 应用侧redis 修改
Redisson 作为应用侧组件，需要配置“优先主库、忽略从库状态”，避免从库不可用时 Redisson 连接报错。  

通过 `application.yml` 配置 Redisson 的哨兵连接策略，核心是：**读操作也路由到主库，从库故障不影响连接**。

```yaml
spring:
  redis:
    # Redis 基础连接配置
    password: 123456
    database: 0
    # Redisson 专属配置（核心）
    redisson:
      config: |
        sentinelServersConfig:
          masterName: mymaster  # 哨兵监控的主库名称（必须和哨兵配置一致）
          sentinelAddresses:  # 所有哨兵节点地址（至少 3 个）
            - "redis://哨兵IP1:26379"
            - "redis://哨兵IP2:26379"
            - "redis://哨兵IP3:26379"
          readMode: MASTER  # 关键：所有读操作都路由到主库（从库挂了也不影响读）
          # readMode: MASTER_SLAVE（默认值，会路由到从库，需改为 MASTER）
          writeMode: MASTER  # 写操作只能路由到主库（默认值，保持即可）
          retryAttempts: 3  # 连接失败重试 3 次（避免网络抖动）
          retryInterval: 1000  # 重试间隔 1 秒
          timeout: 3000  # 连接超时 3 秒（避免阻塞应用）
          failedSlaveReconnectionInterval: 60000  # 从库重连间隔 1 分钟（不频繁重试）
          failedSlaveCheckInterval: 30000  # 检查故障从库的间隔 30 秒（降低哨兵压力）
```

##### 配置解读：
1. `readMode: MASTER`：最关键！  
   - 默认 `readMode: MASTER_SLAVE` 会让 Redisson 把读操作路由到从库，若从库全部挂了，Redisson 会报错“无可用从库”；  
   - 改为 `MASTER` 后，所有读写都走主库，从库是否可用完全不影响 Redisson 连接，彻底隔离从库故障。  

2. 其他辅助配置：  
   - `retryAttempts`/`retryInterval`：避免因网络抖动导致的临时连接失败；  
   - `failedSlaveReconnectionInterval`：从库故障后，Redisson 每 1 分钟才重试连接，不频繁占用资源。
