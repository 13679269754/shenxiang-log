| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-17 | 2024-10月-17  |

---
# elasticsearch

[toc]

## crud



## curl es命令

```bash
curl --insecure -XPOST https://192.168.52.134:9200/_security/api_key -u elastic:MvYS7epMGk -H 'Content-Type: application/json' -d '{ "name": "filebeat_131", "role_descriptors": { "filebeat_writer": {  "cluster": ["monitor", "read_ilm", "read_pipeline"], "index": [{"names": ["filebeat-*"], "privileges": ["view_index_metadata", "create_doc"] }]}}}'
```

---

### ES 查询

```bash
GET  tcbiz_mkt_log_data/_search
{
    "query":{
        "bool":{
            "filter":[
                {
                    "range":{
                        "createTime":{
                            "lte”:1577808000000
                        }
                    }
                }
            ]
        }
    },
    "size":1000
}
```

---

## 删除数据

```bash
POST  tcbiz_mkt_log_data/_delete_by_query?scroll_size=1000
{
    "query":{
        "bool":{
            "filter":[    
                {
                    "range":{
                        "createTime":{
                            "lte":1577808000000
                        }
                    }
                }
            ]
        }
    },
    "size":1000
}
```
停止删除查找到对应的taskid.然后cancel
GET /_tasks

然后取消掉
POST _tasks/grhPDoI4T0CwBHuLiDv_5Q:10657464910/_cancel

---

## 一个kibana连接多个es


1.设置persistent

PUT /_cluster/settings
{
    "persistent" : {
        "indices.recovery.max_bytes_per_sec" : "50mb"
    }
}


2.设置远程的es

PUT _cluster/settings
{
  "persistent": {
    "search": {
      "remote": {
        "inte-aliyun": {
          "seeds": [
            "10.31.68.165:9300"
          ]
        }
      }
    }
  }
}
3.测试
GET inte-aliyun:inte-egw-audit-2021.07.11/_search
获取数据ok

---

## 查看API
查看别名接口(_cat/aliases): 查看索引别名  
查看分配资源接口(_cat/allocation)  
查看文档个数接口(_cat/count)  
查看字段分配情况接口(_cat/fielddata)  
查看健康状态接口(_cat/health)  
查看索引信息接口(_cat/indices)  
查看master信息接口(_cat/master)  
查看nodes信息接口(_cat/nodes)  
查看正在挂起的任务接口(_cat/pending_tasks)  
查看插件接口(_cat/plugins)  
查看修复状态接口(_cat/recovery)  
查看线城池接口(_cat/thread_pool)  
查看分片信息接口(_cat/shards)  
查看lucence的段信息接口(_cat/segments)  

--- 

## es访问 常用参数
v  &h=字段名,字段名   &bytes=kb  &format=json &pretty=  &s=index, doc.count:desc
?help

curl "http://172.25.221.221:9200/_cat/indices?v&h=health,status,index,uuid,pri,rep,docs.count,docs.deleted,store.size,pri.store.size&bytes=kb&s=pri.store.size:desc"

---

## es 水位调整

```bash
curl -H 'Content-Type:application/json' -XPUT 'http://10.12.24.77:9202/_cluster/settings' -d'{"transient" : {"cluster.routing.allocation.disk.watermark.low" : “90%","cluster.routing.allocation.disk.watermark.high" : “95%"}}'
```

---

## 禁止分片relocal

```bash
curl  http://172.18.42.15:9200/_cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.enable": "primaries"
  }
}
```

---

## 修改副本和模板 （修改副本数）
curl -X PUT "192.xxx.x.xxx:9200/_settings" -H 'Content-Type: application/json' -d '{"index":{"number_of_replicas":0}}'


curl -X PUT 192.168.1.195:9200/_template/log -H 'Content-Type: application/json' -d '{ "template": "*", "settings": { "number_of_shards": 1, "number_of_replicas": "0" } }'


"template": "*" 代表所有 索引 
"template": "apple*" 代表生成apple*的索引都会按照这个模板来了

---

## 索引策略 

/_ilm/policy为固定格式，leefs_ilm_policy为创建索引策略名称 

```bash
PUT /_ilm/policy/leefs_ilm_policy
{
  # policy:配置策略
  "policy": {
    # phases:阶段配置
    "phases": {
      "hot": {
        "actions": {
          # rollover:滚动更新
          "rollover": {
            # max_docs:文档数量最大为5执行操作
            #"max_docs": "5"
            "max_age": "1d",
            "max_size": "5gb"
          }
        }
      },
      "warm": {
        # min_age:该阶段最小停留时长
        "min_age": "3d",
        "actions": {
          # allocate:指定一个索引的副本数
          "allocate": {
              # number_of_replicas:进行索引副本数量设置
            "number_of_replicas": 0
          }
        }
      },
      "delete": {
        "min_age": "30s",
        "actions": {
          # delete:删除索引，如果没有该方法即使到删除阶段也不执行删除操作
          "delete": {}
        }
      }
    }
  }
}
```

--- 

## 索引模板

leefs_ilm_template:索引模版名称
```bash
PUT _template/leefs_ilm_template
{
  # 模版匹配的索引名以"leefs_logs-"开头
  "index_patterns": ["leefs_logs-*"],                 
  "settings": {
    # number_of_shard：设置主分片数量
    "number_of_shards": 1,
    # number_of_replicas：设置副本分片数量
    "number_of_replicas": 1,
    # 通过索引策略名称指定模版所匹配的索引策略
    "index.lifecycle.name": "leefs_ilm_policy", 
    # 索引rollover后切换的索引别名为leefs_logs
    "index.lifecycle.rollover_alias": "leefs_logs"
  }
}
```


## 别名alias
为索引secisland添加别名secisland_alias：
POST _aliases
{
  "actions": [
    {
      "add": {
        "index": "secisland",
        "alias": "secisland_alias"
      }
    }
  ]
}

删除别名：

POST _aliases
{
  "actions": [
    {
      "remove": {
        "index": "secisland",
        "alias": "secisland_alias"
      }
    }
  ]
}



------------------------------------

## elasticsearchdump

带有用户验证和ssl的elasticsearch 实例
```bash
 NODE_TLS_REJECT_UNAUTHORIZED=0 elasticdump   
 --input=https://dba_user:Aa123456@172.29.105.53:9200/knowledge_library_index-20250515160138   
 --output=https://elastic:123456@172.29.29.105:9200/knowledge_library_index-20250515160138   
 --output-ssl-verify=false  
 --input-ssl-verify=false  
 --type=data
```