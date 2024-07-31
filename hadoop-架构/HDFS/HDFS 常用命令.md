| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2023-9月-22 | 2023-9月-22  |
| ... | ... | ... |
---
# HDFS 常用命令.md

hadoop fs = hdfs dfs

## 文件操作
hdfs dfs put 
hdfs dfs get
hdfs dfs copyToLocal
hdfs dfs copyFromLocal


## 新加磁盘数据均衡

生成均衡计划
hdfs diskbalance -plan [服务器名称]
执行均衡计划
hdfs diskbalance -execute [计划文件名称]
查看
hdfs diskbalance -query [服务器名称]
取消
hdfs diskbalance -cancel [计划文件名称]



其余用法与
hdfs dfs + linux命令

