| operator | createtime  | updatetime  |
| -------- | ----------- | ----------- |
| shenx    | 2023-12月-05 | 2023-12月-05 |
| ... | ... | ... |
---
# 单机安装集群-添加SSL及用户认证

[toc]

## ES搭建
[ES搭建](https://app.yinxiang.com/fx/21f75ea1-b20d-42b6-ab15-0c848cda8756)

## 单机多实例
原`./bash_profile` 有环境变量配置如下
```bash
export ES_HOME=/usr/local/data/elasticsearch-server
export ES_DATA=/usr/local/data/elasticsearch_data
PATH=$PATH:$ES_HOME/bin
export PATH
```

原启动命令 `./start_es.sh`
```bash
elasticsearch -d  -p /usr/local/data/elasticsearch_data/es9400/run/es9400.pid
```
修改 为如下
```bash 
export ES_PATH_CONF=/usr/local/data/elasticsearch-server/config/ && elasticsearch -d  -p /usr/local/data/elasticsearch_data/es9400/run/es9400.pid
```
即通过ES_PATH_CONF 来控制使用的是哪一个ES 的配置文件

多实例只需要配置多个
/usr/local/data/elasticsearch-server/config/
在启动命令中指定`ES_PATH_CONF`即可

注意：
>需要在在配置文件中指定本地节点数，这个配置影响 $ES_HOME/data中的文件夹
>node.max_local_storage_nodes: 3

其余配置与搭建多机ES集群保持一致即可


