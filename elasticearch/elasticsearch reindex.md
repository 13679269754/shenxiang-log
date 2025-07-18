| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-3月-25 | 2025-3月-25  |
| ... | ... | ... |
---
# elasticsearch reindex

[toc]

## 资料

[es 用 reindex 做数据迁移-从集群A 的数据，导入到 集群B](https://zhuanlan.zhihu.com/p/602244582)

[Reindex settings](https://www.elastic.co/guide/en/elasticsearch/reference/current/index-management-settings.html#reindex-settings)

## 配置文件

```bash

## reindex

reindex.remote.whitelist: ["elasticsearch:9200"]
reindex.ssl.keystore.path: certs/reindex_http.p12
reindex.ssl.truststore.path: certs/reindex_http.p12
```

## reindex_http.p12获取

类似于elasticsearch 客户端https 的生成方法
[es-https](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/security-basic-setup-https.html#encrypt-http-communication)
```bash
./bin/elasticsearch-certutil http

mv http.p12 reindex_http.p12
chown esuser. reindex_http.p12
mv reindex_http.p12 config/certs/

# 添加到keystore
./bin/elasticsearch-keystore add reindex.ssl.keystore.secure_password
./bin/elasticsearch-keystore add reindex.ssl.truststore.secure_password

```

## 进行reindex


```bash
curl -XPOST -H "Content-Type: application/json" -s -u elastic:*****  "localhost:9200/_reindex?pretty" -d'
{
  "source": {
    "remote": {
      "host": "https://elasticsearch:9200",
      "username": "elastic",
      "password": "qRYIcUELwfkOUL570JO4",
      "socket_timeout": "1m",
      "connect_timeout": "60s"
    },
    "index": "academician_index-20250319110000",
    "size": 1000
  },
  "dest": {
    "index": "academician_index-20250319110000",
    "op_type": "create",
    "routing": "=cat"
  }
}'
```

**KIBANA**

```http
POST _reindex
{
  "source": {
    "remote": {
      "host": "https://elasticsearch:9200",
      "username": "elastic",
      "password": "qRYIcUELwfkOUL570JO4",
      "socket_timeout": "1m",
      "connect_timeout": "60s"
    },
    "index": "academician_index-20250319110000",
    "size": 1000
  },
  "dest": {
    "index": "academician_index-20250319110000",
    "op_type": "create",
    "routing": "=cat"
  }
}


GET /_tasks

```

## 查看当前正在进行的reindex 任务
### Reindex API 执行状态监控与结果验证指南  


#### 一、判断 Reindex 是否成功的方法  

##### 1. **同步模式下的直接响应**  
当使用 `wait_for_completion=true`（默认）时，API 会直接返回执行结果：  
```json
{  
  "took": 242,                  // 耗时（毫秒）  
  "timed_out": false,           // 是否超时  
  "total": 1000,                // 总文档数  
  "updated": 0,                 // 更新的文档数  
  "created": 1000,              // 新建的文档数  
  "deleted": 0,                 // 删除的文档数  
  "batches": 1,                 // 批次数  
  "version_conflicts": 0,       // 版本冲突数  
  "noops": 0,                   // 无操作的文档数  
  "retries": {  
    "bulk": 0,                  // Bulk API 重试次数  
    "search": 0                 // 搜索请求重试次数  
  },  
  "throttled_millis": 0,        // 限流耗时  
  "requests_per_second": -1.0,  // 请求速率（-1 表示未限制）  
  "throttled_until_millis": 0,  // 下次限流开始时间  
  "failures": []                // 失败列表（空表示成功）  
}  
```
**关键判断条件**：  
- `failures` 数组为空  
- `timed_out` 为 `false`  
- `created` + `updated` + `deleted` = `total`  


##### 2. **异步模式下的任务状态检查**  
使用 `wait_for_completion=false` 时，需通过任务 ID 检查状态：  
```json
POST _reindex?wait_for_completion=false  
{  
  "source": { "index": "source" },  
  "dest": { "index": "target" }  
}  

// 返回任务 ID  
{  
  "task": "dXJQa8xLRfGfQpYbLx4JhA:123456"  
}  
```
**查询任务状态**：  
```
GET _tasks/dXJQa8xLRfGfQpYbLx4JhA:123456  
```
**成功状态示例**：  
```json
{  
  "completed": true,  
  "task": {  
    "status": {  
      "total": 1000,  
      "updated": 0,  
      "created": 1000,  
      "deleted": 0,  
      "batches": 1,  
      "version_conflicts": 0,  
      "noops": 0,  
      "retries": { "bulk": 0, "search": 0 },  
      "failures": []  
    }  
  }  
}  
```


##### 3. **验证目标索引数据**  
- **文档数量对比**：  
  ```
  GET source-index/_count  
  GET target-index/_count  
  ```
- **关键文档校验**：随机选择源索引中的文档，验证是否存在于目标索引且内容一致。  
- **聚合结果验证**：对比源索引和目标索引的统计结果（如时间范围聚合）。  


#### 二、查看当前正在进行的任务  

##### 1. **查看所有正在运行的任务**  
```
GET _tasks?actions=*reindex&detailed=true&status=true  
```
- `actions=*reindex`：仅显示 Reindex 任务  
- `detailed=true`：显示详细信息  
- `status=true`：包含任务状态统计  


##### 2. **筛选特定任务**  
```json
// 按节点筛选  
GET _tasks?actions=*reindex&nodes=node_id  

// 按时间范围筛选（Elasticsearch 7.10+）  
GET _tasks?actions=*reindex&start_time=2023-05-01T00:00:00  
```


##### 3. **任务状态字段说明**  
```json
{  
  "nodes": {  
    "node_id": {  
      "tasks": {  
        "task_id": {  
          "action": "indices:data/write/reindex",  
          "description": "reindex from [source] to [target]",  
          "start_time_in_millis": 1683628800000,  
          "running_time_in_nanos": 1234567890,  
          "cancellable": true,  
          "headers": {},  
          "status": {  
            "total": 10000,  
            "updated": 0,  
            "created": 5000,  // 当前已创建的文档数  
            "deleted": 0,  
            "batches": 5,  
            "version_conflicts": 0,  
            "noops": 0,  
            "retries": { "bulk": 0, "search": 0 },  
            "throttled_millis": 0,  
            "requests_per_second": -1.0  
          }  
        }  
      }  
    }  
  }  
}  
```


#### 三、处理失败与异常情况  

##### 1. **查看失败详情**  
```json
// 异步任务失败信息  
GET _tasks/task_id  

// 响应中的 failures 字段会包含错误详情  
{  
  "completed": true,  
  "task": {  
    "status": {  
      "failures": [  
        {  
          "index": "target-index",  
          "type": "_doc",  
          "id": "123",  
          "cause": {  
            "type": "mapper_parsing_exception",  
            "reason": "failed to parse field [timestamp] of type [date]"  
          }  
        }  
      ]  
    }  
  }  
}  
```


##### 2. **处理常见错误**  
| 错误类型                  | 原因与解决方案                                                                 |  
|```|```--|  
| `version_conflicts`       | 源文档在迁移过程中被修改，可设置 `"conflicts": "proceed"` 忽略冲突继续执行。 |  
| `mapper_parsing_exception`| 目标索引映射与源数据不匹配，需调整目标索引的 mapping。                         |  
| `circuit_breaking_exception`| 集群内存不足，减少批量大小（`size`）或增加节点内存。                        |  


##### 3. **取消正在运行的任务**  
```
POST _tasks/task_id/_cancel  
```


#### 四、性能监控与优化建议  

##### 1. **监控集群资源**  
```json
// 查看集群健康状态  
GET _cluster/health  

// 查看节点资源使用情况  
GET _nodes/stats/process,thread_pool,indices  
```


##### 2. **优化 Reindex 性能**  
- **并行分片处理**：  
  ```json
  POST _reindex  
  {  
    "source": { "index": "source" },  
    "dest": { "index": "target" },  
    "slice": { "max": 5 }  // 并行分片数  
  }  
  ```
- **控制速率**：  
  ```
  "requests_per_second": 100  // 限制每秒请求数  
  ```
- **使用低优先级**：  
  ```
  "priority": "LOW"  // 降低任务优先级，减少对集群的影响  
  ```


#### 五、自动化验证脚本示例（Python）  

```python
from elasticsearch import Elasticsearch  

es = Elasticsearch()  

def verify_reindex(source_index, target_index):  
    # 获取源索引和目标索引的文档数  
    source_count = es.count(index=source_index)['count']  
    target_count = es.count(index=target_index)['count']  
    
    # 验证文档数是否一致  
    if source_count == target_count:  
        print(f"✅ 文档数量一致: {source_count}")
        
        # 验证部分文档（前10个）  
        source_docs = es.search(index=source_index, size=10)['hits']['hits']  
        for doc in source_docs:  
            doc_id = doc['_id']  
            target_doc = es.get(index=target_index, id=doc_id, ignore=404)
            
            if not target_doc.get('found', False):  
                print(f"❌ 文档 {doc_id} 不存在于目标索引")  
            elif doc['_source'] != target_doc['_source']:  
                print(f"❌ 文档 {doc_id} 内容不一致")  
            else:  
                print(f"✅ 文档 {doc_id} 验证通过")  
    else:  
        print(f"❌ 文档数量不一致: 源索引 {source_count}, 目标索引 {target_count}")  

# 执行验证  
verify_reindex("source-index", "target-index")  
```  

通过以上方法，可全面监控 Reindex 过程并确保数据成功迁移。