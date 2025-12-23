| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-5月-28 | 2025-5月-28  |
| ... | ... | ... |
---
# elasticsearchdump
[toc]

# 安装

```bash
yum  install npm
npm install elasticdump -g
```

##  实践
 ```bash
 NODE_TLS_REJECT_UNAUTHORIZED=0 elasticdump   
 --input=https://dba_user:Aa123456@172.29.105.53:9200/knowledge_library_index-20250515160138   
 --output=https://elastic:123456@172.29.29.105:9200/knowledge_library_index-20250515160138   
 --output-ssl-verify=false  
 --input-ssl-verify=false  
 --type=data
 ```
NODE_TLS_REJECT_UNAUTHORIZED=0 node.js忽略cs证书验证
--input-ssl-verify=false  忽略cs证书验证
--input 目标端索引
--output 源端索引
--type 导出数据类型 data,mapping等

