| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-6月-14 | 2025-6月-14  |
| ... | ... | ... |
---
# 手动构建kafka-connect-elasticsearch.md

[toc]

## 原文
[Kafka Connect Elasticsearch 连接器使用教程-CSDN博客](https://blog.csdn.net/gitblog_00738/article/details/142805481) 

## 前置

[各种环境/JDK17 安装](<JDK17 安装.md>)  
[kafka tar 安装集群(kraft 单机集群)](<kafka tar 安装集群(kraft 单机集群).md>)  
[maven 安装](<maven 安装.md>)
git 安装  

注：注意各组件版本是否适配


### 1\. 项目介绍

Kafka Connect Elasticsearch 连接器是一个用于在 Kafka 和 Elasticsearch 之间复制数据的 Kafka 连接器。它允许用户将数据从 Kafka 主题传输到 Elasticsearch 索引，或者从 Elasticsearch 索引传输到 Kafka 主题。这个连接器由 Confluent 公司开发，是 Kafka Connect 生态系统的一部分，旨在简化数据集成任务。

#### 主要功能

*   **数据同步**：支持将 Kafka 主题中的数据同步到 Elasticsearch 索引。
*   **配置灵活**：提供多种配置选项，以适应不同的数据处理需求。
*   **易于扩展**：基于 Kafka Connect 框架，易于集成到现有的 Kafka 生态系统中。

### 2\. 项目快速启动

#### 2.1 环境准备

*   安装 Kafka 和 Elasticsearch。
*   确保 Kafka 和 Elasticsearch 服务正在运行。

#### 2.2 下载并构建项目

**下载**
```bash
git clone https://github.com/confluentinc/kafka-connect-elasticsearch.git
```

**构建**
需要安装好了maven
```bash
cd kafka-connect-elasticsearch

mvn clean package -DskipTests
```
注意：打包配置文件pom.xml，可以看到有什么连接器module

构建后会在./target目录中生成tarb包

#### 2.3 配置连接器

查看kafka_server 中 config/connect-standalone.properties 或 config/connect-distributed.properties 中的配置
```bash
plugin.path=/usr/local/data/kafka_server/plugins
```
将上一步生成的jar包放在这个目录下/usr/local/data/kafka_server/plugins


创建一个配置文件 `elasticsearch-sink.properties`，内容如下：

```bash
name=elasticsearch-sink
connector.class=io.confluent.connect.elasticsearch.ElasticsearchSinkConnector
tasks.max=1
topics=test-topic
key.ignore=true
schema.ignore=true
connection.url=http://localhost:9200
type.name=kafka-connect` 

```


#### 2.4 启动连接器

```
bin/connect-standalone.sh config/connect-standalone.properties elasticsearch-sink.properties
```

#### 2.5 查看连接器状态

**检查Kafka Connect进程**
```bash
ps -ef | grep connect-standalone
```

vim elasticsearch-source.json
```bash
{
  "name": "elasticsearch-sink-connector",
  "config": {
    "connector.class": "com.github.dariobalinzo.ElasticSinkConnector",
    "tasks.max": "1",
    "es.host": "localhost",
    "es.port": "9200",
    "es.index": "your_index",
    "topic": "es-data-topic"
  }
}
```

**确认服务运行：**

```bash
curl http://localhost:8083/
# 应返回Kafka Connect API信息
```

**创建连接器curl 方式：**
```
curl -X POST -H "Content-Type: application/json" --data @elasticsearch-sink.json http://localhost:8083/connectors
```

**检查连接器列表：**
```
curl http://localhost:8083/connectors | python -m json.tool
```

### 3\. 应用案例和最佳实践

#### 3.1 日志数据同步

将应用程序的日志数据从 Kafka 同步到 Elasticsearch，以便进行实时分析和监控。

#### 3.2 事件数据存储

将 Kafka 中的事件数据存储到 Elasticsearch，以便进行复杂查询和数据分析。

#### 3.3 最佳实践

*   **配置优化**：根据实际需求调整连接器的配置参数，如批处理大小、缓冲区大小等。
*   **监控与报警**：使用 Kafka Connect 的监控工具和 Elasticsearch 的监控插件，实时监控数据同步状态。

### 4\. 典型生态项目

#### 4.1 Kafka

Kafka 是一个分布式流处理平台，广泛用于构建实时数据管道和流应用。

#### 4.2 Elasticsearch

Elasticsearch 是一个分布式搜索和分析引擎，适用于各种数据类型的实时搜索和分析。

#### 4.3 Confluent Platform

Confluent Platform 是一个基于 Kafka 的流数据平台，提供了一系列工具和服务，用于构建和管理实时数据管道。

通过 Kafka Connect Elasticsearch 连接器，用户可以轻松地将 Kafka 和 Elasticsearch 集成在一起，构建强大的数据处理和分析系统。

