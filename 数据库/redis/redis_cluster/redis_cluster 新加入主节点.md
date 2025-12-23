| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2025-7月-24 | 2025-7月-24 |

---
# redis_cluster 新加入主节点

[toc]

在 Redis Cluster 中添加新的主节点需要执行以下步骤：


### **一、准备新节点**
1. **安装 Redis**（与现有集群版本一致）
2. **创建配置文件**（示例：`/data/redis/6380/redis.conf`）：
```ini
port 6380
bind 0.0.0.0
protected-mode no
daemonize yes
pidfile /var/run/redis_6380.pid
logfile "/data/redis/6380/logs/redis.log"
dir "/data/redis/6380/data"

# 集群配置
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 15000
cluster-require-full-coverage no
```
3. **启动新节点**：
```bash
redis-server /data/redis/6380/redis.conf
```


### **二、将新节点加入集群**
```bash
# 使用 redis-cli --cluster add-node 命令
# 语法：redis-cli --cluster add-node 新节点IP:端口 集群内任意节点IP:端口

# 示例：将 192.168.1.107:6380 加入集群
redis-cli --cluster add-node 192.168.1.107:6380 192.168.1.101:6379
```
此时新节点作为**空主节点**加入集群（未分配槽位）。


### **三、验证节点加入**
```bash
# 查看集群节点列表
redis-cli -c -h 192.168.1.101 -p 6379 CLUSTER NODES

# 输出应包含新节点（状态为 connected，无槽位分配）
# 例如：
# 3c1a... 192.168.1.107:6380@16380 master - 0 1625463780000 0 connected
```


### **四、为新节点分配槽位**
从现有主节点迁移部分槽位到新节点：
```bash
# 使用 redis-cli --cluster reshard 命令
# 语法：redis-cli --cluster reshard 集群内任意节点IP:端口 --cluster-from 源节点ID --cluster-to 目标节点ID --cluster-slots 槽数量 --cluster-yes

# 示例：从所有现有主节点迁移 1000 个槽到新节点
redis-cli --cluster reshard 192.168.1.101:6379 \
  --cluster-from all \
  --cluster-to $(redis-cli -c -h 192.168.1.101 -p 6379 CLUSTER NODES | grep 192.168.1.107:6380 | awk '{print $1}') \
  --cluster-slots 1000 \
  --cluster-yes
```

**参数说明**：
- `--cluster-from all`：从所有现有主节点平均迁移槽位
- `--cluster-to`：新节点的 ID（通过 `CLUSTER NODES` 获取）
- `--cluster-slots 1000`：迁移 1000 个槽（约占总量的 6%）


### **五、验证槽位迁移**
```bash
# 查看新节点槽位分配
redis-cli -c -h 192.168.1.101 -p 6379 CLUSTER NODES | grep 192.168.1.107:6380

# 输出应显示新节点分配的槽位范围（如 0-999）
# 例如：
# 3c1a... 192.168.1.107:6380@16380 master - 0 1625463780000 0 connected 0-999
```


### **六、为新主节点添加从节点（可选）**
若需要高可用，可为新主节点添加从节点：
```bash
# 1. 启动新的从节点（配置同主节点）
redis-server /data/redis/6381/redis.conf

# 2. 将从节点加入集群
redis-cli --cluster add-node 192.168.1.108:6381 192.168.1.101:6379

# 3. 设置为新主节点的从节点
redis-cli -c -h 192.168.1.108 -p 6381 CLUSTER REPLICATE <新主节点ID>
```


### **七、验证集群状态**
```bash
# 检查集群健康状态
redis-cli -c -h 192.168.1.101 -p 6379 CLUSTER INFO

# 应显示：cluster_state:ok
# 查看槽位总数
# 应显示：cluster_slots_assigned:16384
```


### **八、注意事项**
1. **槽位分配策略**：  
   - 新增 N 个主节点时，建议每个节点分配 `16384/N` 个槽位
   - 示例：从 3 主节点扩展到 4 主节点，每个新节点应分配约 4096 个槽位

2. **性能影响**：  
   - 槽位迁移期间可能影响集群性能，建议在低峰期操作
   - 可通过 `CLUSTER SETSLOT ... MIGRATING` 命令手动控制迁移速度

3. **配置一致性**：  
   - 所有节点的 `cluster-node-timeout` 配置需保持一致
   - 新节点的防火墙需开放客户端端口（如 6380）和集群总线端口（如 16380）


### **九、完整示例**
```bash
# 1. 启动新节点
redis-server /data/redis/6380/redis.conf

# 2. 加入集群
redis-cli --cluster add-node 192.168.1.107:6380 192.168.1.101:6379

# 3. 获取新节点ID
NEW_NODE_ID=$(redis-cli -c -h 192.168.1.101 -p 6379 CLUSTER NODES | grep 192.168.1.107:6380 | awk '{print $1}')

# 4. 计算需迁移的槽位数量（假设从3主扩展到4主）
SLOT_COUNT=$((16384/4))  # 约4096个槽

# 5. 迁移槽位
redis-cli --cluster reshard 192.168.1.101:6379 \
  --cluster-from all \
  --cluster-to $NEW_NODE_ID \
  --cluster-slots $SLOT_COUNT \
  --cluster-yes

# 6. 验证集群状态
redis-cli -c -h 192.168.1.101 -p 6379 CLUSTER INFO
redis-cli -c -h 192.168.1.101 -p 6379 CLUSTER NODES
```

通过以上步骤，可安全扩展 Redis Cluster 并添加新的主节点。