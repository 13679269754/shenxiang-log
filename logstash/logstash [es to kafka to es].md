| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-6月-21 | 2025-6月-21  |
| ... | ... | ... |
---
# logstash [es to kafka to es]

[toc]

## 环境

| 组件 | 环境 |
| -- | -- |
|logstash | 9.0.2 | 
|kafka | 4.0.0 |
| elasticsearch | 7.17.9 |
| JDK | openJDK 17|

## 单任务配置

/path/config/logstash.yml

```bash
cat >> /path/config/logstash.yml << EOF
api.http.host: "0.0.0.0"
api.http.port: 9600
pipeline.id: e2k
path.data: "/usr/local/data/logstash_data/e2k"



# 其他全局配置
path.data: "/usr/local/data/logstash"
path.logs: "/usr/local/data/logstash"
```

## 多任务配置

path/config/pipeline.yml


cat >> path/config/pipeline.yml << EOF
```bash
- pipeline.id: e2k
  pipeline.workers: 2
  pipeline.batch.size: 200
  pipeline.batch.delay: 50
  path.config: "/usr/local/data/logstash_server/pipeline/elasticsearch_to_kafka.conf"


- pipeline.id: k2e
  pipeline.workers: 2
  pipeline.batch.size: 200
  pipeline.batch.delay: 50
  path.config: "/usr/local/data/logstash_server/pipeline/kafka_to_elasticsearch.conf"
```

## 前置

**JDK**
[各种环境/JDK17 安装](<../linux/各种环境/JDK17 安装.md>) 

**用户创建&赋权**

```bash
useradd logstash
chown -R logstash. /path/logstash_server
chown -R logstash. /path/logstash_date
```


## 同步任务创建

**elasticsearch_to_kafka**

```bash
cat > /usr/local/data/logstash_server/pipeline/elasticsearch_to_kafka.conf << EOF
input {
  elasticsearch {
    # Elasticsearch 连接配置
    hosts => ["https://172.29.29.105:9200"]
    user => "elastic"
    password => "123456"
    slices => 4
    ssl_enabled => true
    ssl_keystore_path => "/usr/local/data/logstash_server/certs/e2kelastic-certificates.p12"
    ssl_keystore_password => "123456"
    ssl_truststore_path => "/usr/local/data/logstash_server/certs/e2kelastic-stack-ca.p12"
    ssl_truststore_password => "123456"

    # 查询配置
    index => "knowledge_library_index-*"  # 源索引模式
    size => 1000  # 每次查询的文档数
    query => '{"query":{"range":{"modify_time":{"gte":"now-20d","lte":"now/m"}}}}'
    scroll => "2m"  # 滚动查询保持时间

    schedule => "* * * * *"

    # 跟踪已处理文档（避免重复）
    docinfo => true  # 包含原始文档信息
    docinfo_target => "_docinfo"  # 存储文档信息的字段
    docinfo_fields => ["_index", "_id"]  # 存储的文档信息字段
  }
}


# output: 写入 Kafka 和控制台
output {
  # 调试输出（独立插件）
  stdout {
    codec => rubydebug
  }

  # Kafka 输出
  kafka {
    # Kafka 集群配置
    bootstrap_servers => "172.29.29.106:9092,172.29.29.106:9082,172.29.29.106:9072"

    # 目标主题
    topic_id => "knowledge_library_index-20250515160138"  # 目标 Kafka 主题

    # 消息配置
    codec => "json"  # 消息格式（使用 JSON 编码）

    # 性能优化
    batch_size => 100  # 批量发送的消息数
    compression_type => "lz4"  # 压缩类型
    max_request_size => 1048576  # 最大请求大小（字节）

    # 错误处理
    retry_backoff_ms => 1000  # 重试间隔（毫秒）
    retries => 3  # 最大重试次数
  }
}
```

**elasticsearch_to_kafka**

```bash
input {
  # 第一个 Kafka 输入插件（处理知识文库索引数据）
  kafka {
    bootstrap_servers => "172.29.29.106:9092,172.29.29.106:9082,172.29.29.106:9072"
    topics => "knowledge_library_index-20250515160138"

    auto_offset_reset => "earliest"
    enable_auto_commit => true

    max_partition_fetch_bytes => 10485760
    max_poll_records => 500


    codec => "json"
    consumer_threads => 1
    decorate_events => true
  }
}

output {
  # 输出到 Elasticsearch（知识文库索引）
  elasticsearch {
    hosts => ["172.29.29.104:9200"]
    index => "knowledge_library_index-20250515160138"
    user => "elastic"
    password => "123456"

    # 修正：将SSL配置移到elasticsearch插件内部
    ssl_enabled => true
    ssl_keystore_path => "/usr/local/data/logstash_server/certs/k2eelastic-certificates.p12"
    ssl_keystore_password => "123456"
    ssl_truststore_path => "/usr/local/data/logstash_server/certs/k2eelastic-stack-ca.p12"
    ssl_truststore_password => "123456"
  }

  # 调试输出
  stdout {
    codec => rubydebug
  }
}

```

## 其他相关内容说明

### kafka offset

```bash
# 查看offset
bin/kafka-consumer-groups.sh   --bootstrap-server 172.29.29.106:9092   --describe   --group logstash --topic [topic]

# 重置offset 
bin/kafka-consumer-groups.sh   --bootstrap-server 172.29.29.106:9092   --group logstash   --reset-offsets   --to-earliest   --execute   --topic knowledge_library_index-20250515160138

```

### elasticsearch 验证

以下只针对对应的版本，不同版本es和logstash 的用户验证方式不尽相同
```bash
  ssl_enabled => true
  ssl_keystore_path => "/usr/local/data/logstash_server/certs/k2eelastic-certificates.p12"
  ssl_keystore_password => "123456"
  ssl_truststore_path => "/usr/local/data/logstash_server/certs/k2eelastic-stack-ca.p12"
  ssl_truststore_password => "123456"
```
相关文件由对应的elasticsearch 集群certs中得到。


### 部分报错

1. 权限问题
```bash
[2025-06-30T14:55:31,404][FATAL][logstash.runner          ] An unexpected error occurred! {:error=>#<RuntimeError: Logstash cannot be run as superuser.>, :backtrace=>["/usr/local/data/logstash_server/logstash-core/lib/logstash/runner.rb:430:in `running_as_superuser'", 
```

处理：使用非root用户。

