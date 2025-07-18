| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-5月-28 | 2025-5月-28  |
| ... | ... | ... |
---
# kafka安装

[toc]

## docker 安装

```bash

docker pull bitnami/kafka

# 生成KAFKA_CLUSTER_ID
docker run --rm tchiotludo/akhq:latest kafka-storage random-uuid
# 输出类似：rJ6YqX9pTfOe5WvXjZpXqA

# 将生成的ID填入所有节点的KAFKA_CLUSTER_ID配置

mkdir -p /usr/local/data/kafka_cluster/

mkdir -p /usr/local/data/kafka_cluster/{kafka1,kafka2,kafka3,AKHQ}

cat > /usr/local/data/kafka_cluster/AKHQ/application.yml <<EOF
akhq:
  connections:
    kafka_cluster:
      properties:
        bootstrap.servers: "kafka1:9092,kafka2:9082,kafka3:9072"
        security.protocol: PLAINTEXT  # 若启用安全协议需修改
  server:
    port: 8080
EOF

chown -R 1001:1001 /usr/local/data/kafka_cluster 

# selinux 问题处理
# 临时禁用SELinux测试
sudo setenforce 0

# 或永久修改（需重启）
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

# 修复SELinux上下文
sudo semanage fcontext -a -t docker_var_lib_t "/usr/local/data/kafka_cluster(/.*)?"
sudo restorecon -Rv /usr/local/data/kafka_cluster


cat >> /usr/local/data/kafka_cluster/docker-compose.yaml << EOF
networks:
  app-tier:
    driver: bridge

services:
  kafka1:
    image: 'bitnami/kafka:latest'
    container_name: kafka1
    networks:
      - app-tier
    environment:
      - KAFKA_CFG_NODE_ID=10
      - KAFKA_CFG_PROCESS_ROLES=controller,broker
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093
      - KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
      - KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka1:9092,CONTROLLER://kafka1:9093
      - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@kafka1:9093,1@kafka2:9083,2@kafka3:9073
      - KAFKA_CLUSTER_ID=cfaef8f419c4e4b78c583597d6428b63166e90eeb194af890264d68051a22180
    volumes:
      - /usr/local/data/kafka_cluster/kafka1:/bitnami/kafka:Z
    ports:
      - "9092:9092"
    healthcheck:
      test: ["CMD", "sh", "-c", "kafka-topics.sh --bootstrap-server localhost:9092 --version > /dev/null 2>&1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  kafka2:
    image: 'bitnami/kafka:latest'
    container_name: kafka2
    networks:
      - app-tier
    environment:
      - KAFKA_CFG_NODE_ID=11
      - KAFKA_CFG_PROCESS_ROLES=controller,broker
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9082,CONTROLLER://:9083
      - KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
      - KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka2:9082,CONTROLLER://kafka2:9083
      - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@kafka1:9093,1@kafka2:9083,2@kafka3:9073
      - KAFKA_CLUSTER_ID=cfaef8f419c4e4b78c583597d6428b63166e90eeb194af890264d68051a22180
    volumes:
      - /usr/local/data/kafka_cluster/kafka2:/bitnami/kafka:Z
    ports:
      - "9082:9092"
    healthcheck:
      test: ["CMD", "sh", "-c", "kafka-topics.sh --bootstrap-server localhost:9092 --version > /dev/null 2>&1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  kafka3:
    image: 'bitnami/kafka:latest'
    container_name: kafka3
    networks:
      - app-tier
    environment:
      - KAFKA_CFG_NODE_ID=12
      - KAFKA_CFG_PROCESS_ROLES=controller,broker
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9072,CONTROLLER://:9073
      - KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
      - KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka3:9072,CONTROLLER://kafka3:9073
      - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@kafka1:9093,1@kafka2:9083,2@kafka3:9073
      - KAFKA_CLUSTER_ID=cfaef8f419c4e4b78c583597d6428b63166e90eeb194af890264d68051a22180
    volumes:
      - /usr/local/data/kafka_cluster/kafka3:/bitnami/kafka:Z
    ports:
      - "9072:9092"
    healthcheck:
      test: ["CMD", "sh", "-c", "kafka-topics.sh --bootstrap-server localhost:9092 --version > /dev/null 2>&1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s


  akhq:
    image: tchiotludo/akhq:latest
    container_name: akhq
    user: 1001:1001
    networks:
      - app-tier
    ports:
      - "8080:8080"
    environment:
      AKHQ_CONFIGURATION: |
        akhq:
          connections:
            kafka_cluster:
              properties:
                bootstrap.servers: "kafka1:9092,kafka2:9082,kafka3:9072"
                security.protocol: PLAINTEXT  # 若启用安全协议需修改
          server:
            port: 8080
    volumes:
      - /usr/local/data/kafka_cluster/AKHQ/application.yml:/app/application.yml
    #depends_on:
    #  kafka1:
    #    condition: service_healthy
    #  kafka2:
    #    condition: service_healthy
    #  kafka3:
    #    condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

```

## 问题处理

### 问题1

**问题**

```bash
kafka 06:57:11.10 INFO  ==> ** Starting Kafka setup **
mkdir: cannot create directory '/bitnami/kafka/config': Permission denied
```

**问题处理**

```bash
chown -R 1001:1001 /usr/local/data/kafka_cluster/kafka*
```

## 知识点整理

### 一、Kafka3 配置详解
 
您提供的配置是针对 Kafka 3.x 版本的 **KRaft 模式**（无 ZooKeeper 架构），以下是关键参数的解释：

#### 1. 节点基础配置
```yaml
- KAFKA_CFG_NODE_ID=2
```
- **作用**：唯一标识当前 Kafka 节点的 ID，必须在集群中全局唯一。
- **注意**：在 KRaft 模式中，`KAFKA_CFG_NODE_ID` 替代了传统的 `KAFKA_BROKER_ID`。


#### 2. 节点角色配置
```yaml
- KAFKA_CFG_PROCESS_ROLES=controller,broker
```
- **作用**：指定节点同时承担 **控制器（Controller）** 和 **代理（Broker）** 角色。
  - **Controller**：管理集群元数据（如主题、分区信息）。
  - **Broker**：处理消息的生产和消费。
- **推荐配置**：生产环境通常建议将 Controller 和 Broker 角色分离到不同节点。


#### 3. 网络监听器配置
```yaml
- KAFKA_CFG_LISTENERS=PLAINTEXT://:9072,CONTROLLER://:9073
- KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
- KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
```
- **作用**：
  - `LISTENERS`：定义节点监听的网络接口和端口。
    - `PLAINTEXT://:9072`：普通客户端通信端口。
    - `CONTROLLER://:9073`：控制器内部通信专用端口。
  - `SECURITY_PROTOCOL_MAP`：指定监听器的安全协议（此处使用明文传输）。
  - `CONTROLLER_LISTENER_NAMES`：指定控制器使用的监听器名称。


#### 4. 广告地址配置
```yaml
- KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka3:9072,CONTROLLER://kafka3:9073
```
- **作用**：向外部暴露的访问地址。
  - `kafka3`：Docker 网络中的服务名，用于容器间通信。
  - **注意**：若需从宿主机或外部网络访问，需修改为实际可访问的 IP 或域名。


#### 5. 控制器选举配置
```yaml
- KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@kafka1:9093,1@kafka2:9083,2@kafka3:9073
```
- **作用**：定义参与控制器选举的节点列表。
  - 格式：`节点ID@主机名:控制器端口`。
  - **选举机制**：基于 Raft 协议，需多数节点（≥2）达成一致才能选举出 Leader Controller。


#### 6. 集群标识符
```yaml
- KAFKA_CLUSTER_ID=生成的实际ID
```
- **作用**：全局唯一标识 Kafka 集群，首次启动时必须通过命令生成。
- **生成命令**：
```bash
docker run --rm bitnami/kafka:latest kafka-storage.sh random-uuid
```
- **注意**：所有节点必须使用相同的 `CLUSTER_ID`，否则会导致集群分裂。


### 二、KRaft 模式详解

#### 1. 定义与起源
- **全称**：Kafka Raft Metadata 模式。
- **起源**：从 **Kafka 2.8.0** 版本开始引入，**Kafka 3.0.0** 版本正式推荐使用，计划在未来版本完全替代 ZooKeeper。


#### 2. 核心区别
| **特性**               | **传统 ZooKeeper 模式**          | **KRaft 模式**                   |
|````````````````````````|`````````````````````````````````-|`````````````````````````````````-|
| 元数据存储             | 依赖 ZooKeeper 集群             | 内置 Raft 协议，无需外部依赖    |
| 架构复杂度             | 需要维护 ZooKeeper 集群         | 单一 Kafka 集群，简化运维        |
| 配置参数               | `KAFKA_ZOOKEEPER_CONNECT`       | `KAFKA_CLUSTER_ID`              |
| 控制器选举             | ZooKeeper 主导                   | 基于 Raft 协议内部选举           |
| 典型端口               | ZooKeeper: 2181<br>Kafka: 9092  | 仅需 Kafka 端口（如 9092/9093）  |


#### 3. 优势
- **架构简化**：移除外部依赖（ZooKeeper），降低运维成本。
- **性能提升**：元数据操作更高效，减少网络跳数。
- **故障恢复快**：控制器选举和故障转移速度更快。


#### 4. 适用场景
- **新项目**：推荐直接使用 KRaft 模式，避免未来迁移成本。
- **大规模集群**：KRaft 在处理大规模集群（>100 节点）时性能更优。
- **云原生环境**：与 Kubernetes 等容器编排系统更兼容。


### 三、生产环境建议

#### 1. 角色分离
将 Controller 角色集中到专用节点（如 3 个节点），Broker 节点专注处理客户端请求。
```yaml
# 示例：专用 Controller 节点
controller1:
  environment:
    - KAFKA_CFG_NODE_ID=0
    - KAFKA_CFG_PROCESS_ROLES=controller  # 仅作为控制器

# 示例：专用 Broker 节点
broker1:
  environment:
    - KAFKA_CFG_NODE_ID=100
    - KAFKA_CFG_PROCESS_ROLES=broker  # 仅作为代理
```


#### 2. 持久化配置
确保数据目录权限正确，避免容器内用户无法写入。
```yaml
volumes:
  - /usr/local/data/kafka_cluster/kafka3:/bitnami/kafka:Z
```
- `:Z` 标记：适用于 SELinux 系统，自动设置正确的文件上下文。


#### 3. 监控与告警
- 集成 Prometheus 和 Grafana 监控 KRaft 控制器状态。
- 重点监控指标：
  - `controller.active`：当前活跃控制器。
  - `controller.election.rate`：控制器选举频率。
  - `metadata.version`：元数据版本一致性。


### 四、验证 KRaft 集群

#### 1. 检查集群状态
```bash
docker exec -it kafka1 kafka-metadata-shell.sh --sasl-mechanism PLAIN --bootstrap-server kafka1:9092
```

#### 2. 查看控制器信息
```bash
docker exec -it kafka1 kafka-controller.sh --bootstrap-server kafka1:9092 --describe
```

#### 3. 测试主题操作
```bash
# 创建主题
docker exec -it kafka1 kafka-topics.sh --create --topic test --bootstrap-server kafka1:9092 --partitions 3 --replication-factor 3

# 生产消息
docker exec -it kafka1 kafka-console-producer.sh --topic test --bootstrap-server kafka1:9092

# 消费消息
docker exec -it kafka1 kafka-console-consumer.sh --topic test --bootstrap-server kafka1:9092 --from-beginning
```


通过理解和正确配置 KRaft 模式，您可以构建更简洁、高效的 Kafka 集群。


### 注意事项

docker 启动kafka 有最小内存限制，且kafka退出不会提示内存溢出。
可能报错为

```bash
[2025-06-12 00:00:15,445] INFO [BrokerLifecycleManager id=4] Unable to register broker 4 because the controller returned error DUPLICATE_BROKER_REGISTRATION (kafka.server.BrokerLifecycleManager)
```

