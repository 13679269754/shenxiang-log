| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-7月-24 | 2025-7月-24  |
| ... | ... | ... |
---
# redis_cluster install

[toc]

### Redis Cluster 详细搭建指南

以下是基于 Redis 6.2.11 版本的集群搭建详细步骤，包含环境准备、配置、启动、验证及常见问题处理：


### **一、环境准备**

#### **1. 服务器规划**
建议使用 6 台服务器（或虚拟机），每台配置 2CPU/4GB 以上：
| 节点角色   | IP 地址        | 端口  |
|------------|----------------|-------|
| 主节点1    | 192.168.1.101  | 6379  |
| 主节点2    | 192.168.1.102  | 6379  |
| 主节点3    | 192.168.1.103  | 6379  |
| 从节点1    | 192.168.1.104  | 6379  |
| 从节点2    | 192.168.1.105  | 6379  |
| 从节点3    | 192.168.1.106  | 6379  |


#### **2. 安装 Redis**
所有节点执行以下命令：
```bash
# 下载并编译 Redis
wget https://download.redis.io/releases/redis-6.2.11.tar.gz
tar xzf redis-6.2.11.tar.gz
cd redis-6.2.11
make && make install

# 创建数据和配置目录
mkdir -p /data/redis/6379/{data,logs}
```


### **二、配置节点**

#### **1. 配置文件模板**
在所有节点创建 `/data/redis/6379/redis.conf`，内容如下：
```ini
# 基础配置
port 6379
bind 0.0.0.0
protected-mode no
daemonize yes
pidfile /var/run/redis_6379.pid
logfile "/data/redis/6379/logs/redis.log"
dir "/data/redis/6379/data"

# 集群配置
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 15000
cluster-require-full-coverage no  # 允许部分槽位可用时继续服务

# 持久化配置
appendonly yes
appendfsync everysec
save 900 1
save 300 10
save 60 10000

# 内存优化
maxmemory-policy allkeys-lru
maxmemory 2gb  # 根据实际内存调整
```


#### **2. 防火墙配置**
开放 Redis 服务端口和集群总线端口（默认 +10000）：
```bash
# CentOS/RHEL
firewall-cmd --zone=public --add-port=6379/tcp --permanent
firewall-cmd --zone=public --add-port=16379/tcp --permanent
firewall-cmd --reload

# Ubuntu/Debian
ufw allow 6379/tcp
ufw allow 16379/tcp
ufw reload
```


### **三、启动所有节点**
在所有 6 个节点上执行：
```bash
redis-server /data/redis/6379/redis.conf
```

验证节点是否正常运行：
```bash
ps -ef | grep redis
# 应看到类似输出：
# redis     1234     1  0 10:00 ?        00:00:00 redis-server *:6379 [cluster]
```


### **四、创建集群**

#### **1. 使用 redis-cli 创建集群**
在任意节点执行（替换为实际 IP）：
```bash
redis-cli --cluster create \
  192.168.1.101:6379 192.168.1.102:6379 192.168.1.103:6379 \
  192.168.1.104:6379 192.168.1.105:6379 192.168.1.106:6379 \
  --cluster-replicas 1
```

参数说明：
- `--cluster-replicas 1`：每个主节点对应 1 个从节点
- Redis 会自动分配 1-5461、5462-10922、10923-16383 三个槽位范围给三个主节点


#### **2. 确认集群创建成功**
```bash
# 连接任意节点
redis-cli -c -h 192.168.1.101 -p 6379

# 检查集群状态
123.168.1.101:6379> CLUSTER INFO
# 应显示：cluster_state:ok

# 查看节点列表
123.168.1.101:6379> CLUSTER NODES
# 应看到类似输出（包含所有 6 个节点及槽位分配）
```


### **五、验证集群功能**

#### **1. 写入测试**
```bash
# 连接任意节点
redis-cli -c -h 192.168.1.101 -p 6379

# 写入数据（自动路由到对应节点）
192.168.1.101:6379> SET key1 value1
192.168.1.101:6379> SET key2 value2

# 读取数据
192.168.1.101:6379> GET key1
192.168.1.101:6379> GET key2
```


#### **2. 故障转移测试**
```bash
# 模拟主节点 192.168.1.101 故障
redis-cli -h 192.168.1.101 -p 6379 SHUTDOWN

# 检查集群状态（等待约 15 秒）
redis-cli -c -h 192.168.1.102 -p 6379 CLUSTER INFO
# 应显示：cluster_state:ok

# 查看节点列表，确认从节点已提升为主节点
redis-cli -c -h 192.168.1.102 -p 6379 CLUSTER NODES
```


### **六、管理与维护**

#### **1. 添加新节点**
```bash
# 1. 启动新节点（如 192.168.1.107:6379）
redis-server /data/redis/6379/redis.conf

# 2. 将新节点加入集群
redis-cli --cluster add-node 192.168.1.107:6379 192.168.1.101:6379

# 3. 将新节点设置为从节点
redis-cli -c -h 192.168.1.107 -p 6379
192.168.1.107:6379> CLUSTER REPLICATE <目标主节点ID>
```


#### **2. 移除节点**
```bash
# 1. 迁移槽位（若为主节点）
redis-cli --cluster reshard 192.168.1.101:6379 \
  --cluster-from <待移除节点ID> \
  --cluster-to <目标节点ID> \
  --cluster-slots <槽位数量> \
  --cluster-yes

# 2. 从集群中删除节点
redis-cli --cluster del-node 192.168.1.101:6379 <待移除节点ID>
```


### **七、常见问题处理**

#### **1. 集群状态为 fail**
- **原因**：部分槽位未分配或节点间通信异常
- **解决**：
  ```bash
  # 检查槽位分配
  redis-cli -c -h 192.168.1.101 -p 6379 CLUSTER NODES | grep connected
  
  # 重新分配缺失的槽位
  redis-cli --cluster fix 192.168.1.101:6379
  ```


#### **2. 节点无法加入集群**
- **原因**：防火墙未开放端口或配置不一致
- **解决**：
  ```bash
  # 检查端口连通性
  telnet 目标节点IP 6379
  telnet 目标节点IP 16379
  
  # 确保所有节点配置文件中的 cluster-enabled 为 yes
  grep cluster-enabled /data/redis/6379/redis.conf
  ```


### **八、监控与优化**

#### **1. 性能监控**
```bash
# 查看集群信息
redis-cli -c -h 192.168.1.101 -p 6379 CLUSTER INFO

# 查看节点内存使用
redis-cli -c -h 192.168.1.101 -p 6379 INFO memory

# 监控慢查询
redis-cli -c -h 192.168.1.101 -p 6379 SLOWLOG GET
```


#### **2. 参数优化建议**
```ini
# redis.conf 优化参数
cluster-node-timeout 5000  # 降低故障检测时间
maxmemory-samples 10       # 提高 LRU 准确性
no-appendfsync-on-rewrite yes  # AOF 重写时不进行 fsync
```


### **九、生产环境注意事项**
1. **禁用 protected-mode**：在生产环境中，确保通过防火墙而非 `protected-mode` 控制访问
2. **启用持久化**：配置 `appendonly yes` 和合理的 `save` 选项
3. **定期备份**：配置定时任务备份 RDB 文件
4. **监控告警**：集成 Prometheus + Grafana 监控集群状态
5. **性能测试**：上线前进行压测，验证集群性能和扩展性


通过以上步骤，你可以成功搭建一个高可用的 Redis Cluster。建议在测试环境中先演练整个流程，再部署到生产环境。
