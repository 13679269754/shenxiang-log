# elasticearch + kibana 搭建

[toc]

## 综述

## 旧版安装文档
[elasticsearch + kibana 安装 添加用户验证 开启https访问](<../../elasticearch/elasticsearch + kibana 安装 添加用户验证 开启https访问.md>)

## 搭建规格
1. 版本：elasticsearch 7.17.9
2. 添加用户验证
3. 集群SSL认证
4. 客户端SSL认证
5. kibanaSSL认证

## 安装包

`elasticsearch-7.17.9-linux-x86_64.tar.gz`  
`kibana-7.17.9-linux-x86_64.tar.gz`  

## 安装目录

`/usr/local/data/elasticsearch-server`  
`/usr/local/data/elasticsearch_data`  
`/usr/local/data/kibana`  

## 环境准备

环境设置修改最大文件数以及线程数  

vim /etc/security/limits.conf
```bash
* hard core 0
* soft nproc 65535
* hard nproc 65535
* soft nofile 1048576
* hard nofile 1048576
* hard memlock unlimited
* soft memlock unlimited
* - as unlimited
```

备注：* 表示对用户进行通配，nofile 最大打开文件数目，nproc 最大打开线程数目

修改文件句柄附全部sysctl.conf文件
vim /etc/sysctl.conf
``` bash
fs.file-max = 4194304
fs.nr_open = 5242880
kernel.core_uses_pid = 1
kernel.msgmax = 1048560
kernel.msgmnb = 1073741824
kernel.shmall = 4294967296
kernel.shmmax = 68719476736
kernel.sysrq=1
net.core.netdev_max_backlog = 1048576
net.core.rmem_default = 2097152
net.core.rmem_max = 16777216
net.core.somaxconn = 32768
net.core.wmem_default = 2097152
net.core.wmem_max = 16777216
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.rp_filter=0
net.ipv4.ip_local_port_range = 1024 65533
net.ipv4.neigh.default.gc_thresh1 = 10240
net.ipv4.neigh.default.gc_thresh2 = 40960
net.ipv4.neigh.default.gc_thresh3 = 81920
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_time = 30
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 1048576
net.ipv4.tcp_max_tw_buckets = 60000
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_reordering = 5
net.ipv4.tcp_retrans_collapse = 0
net.ipv4.tcp_retries2 = 5
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_sack = 0
net.ipv4.tcp_tw_reuse = 0
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_wmem = 94500000 915000000 927000000
vm.max_map_count = 655360
vm.overcommit_memory = 1
vm.swappiness = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.neigh.default.gc_stale_time=120
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.all.arp_announce=2
net.ipv4.conf.lo.arp_announce=2
```

`sysctl -p` 

重要  
**vm.max_map_count = 655360**  
为关键指标 默认值为65530会导致报错。


## elasticsearch 配置文件

```bash

## cluster
cluster.name: dzj_es_cluster
cluster.initial_master_nodes: ["es1", "es2", "es3"]
discovery.seed_hosts: ["10.159.65.129", "10.159.65.130", "10.159.65.131"]
ingest.geoip.downloader.enabled: false
xpack.security.audit.enabled: true

## node
node.name: es1
node.master: true
node.data: true
node.ingest: true

## path
path.data: /usr/local/data/elasticsearch_data/es9200/data
path.logs: /usr/local/data/elasticsearch_data/es9200/log

## port
network.host: 0.0.0.0
transport.tcp.port: 9300
http.port: 9200

## security
# xpack.security.enabled: true
# xpack.license.self_generated.type: basic
# xpack.security.transport.ssl.enabled: true
# xpack.security.transport.ssl.verification_mode: certificate
# xpack.security.transport.ssl.client_authentication: required
# xpack.security.transport.ssl.keystore.path: certs/elastic-certificates.p12
# xpack.security.transport.ssl.truststore.path: certs/elastic-certificates.p12
# xpack.security.http.ssl.enabled: true
# xpack.security.http.ssl.keystore.path: certs/http.p12
# xpack.security.http.ssl.truststore.path: certs/http.p12

## index
action.auto_create_index: true
action.destructive_requires_name: true

## reblance
cluster.routing.allocation.cluster_concurrent_rebalance: 16
cluster.routing.allocation.node_concurrent_recoveries: 16
cluster.routing.allocation.node_initial_primaries_recoveries: 16

## other
transport.tcp.compress: true
http.cors.enabled: true
http.cors.allow-origin: "*"

```

## 开启用户认证+配置集群间认证证书

### 1. 生成p12认证文件

```bash
./bin/elasticsearch-certutil ca
./bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12
```
说明：
1. 输入密码后需要将密码添加到elasticsearch-keystore管理器
```bash
./bin/elasticsearch-keystore add xpack.security.transport.ssl.keystore.secure_password
./bin/elasticsearch-keystore add xpack.security.transport.ssl.truststore.secure_password
```

2. 需要将生成的文件放到对应目录下
下一步配置中需要使用路径，这里将文件放在了`./config/certs`下 

### 2. 开启用户认证

开启 xpack用户验证插件`xpack.security.enabled: true`

取消配置文件注释
```bash
xpack.security.enabled: true
xpack.license.self_generated.type: basic
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.client_authentication: required
xpack.security.transport.ssl.keystore.path: certs/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: certs/elastic-certificates.p12
```

重启eleasticearch

### 3.添加用户
启动es
```bash
#./bin/elasticsearch-keystore create  
./bin/elasticsearch-setup-passwords interactive
```

## 开启客户端SSL认证

[es-https](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/security-basic-setup-https.html#encrypt-http-communication)

```bash
    ./bin/elasticsearch-certutil http
```
>When asked if you want to generate a CSR, enter n.  
>When asked if you want to use an existing CA, enter y.  
>Enter the path to your CA. This is the absolute path to the elastic-stack-ca.p12 file that you generated for your cluster.  
>Enter the password for your CA.  
>Enter an expiration value for your certificate. You can enter the validity period in years, months, or days. For example, enter 90D for 90 days.  
>When asked if you want to generate one certificate per node, enter y.  
>
>Each certificate will have its own private key, and will be issued for a specific hostname or IP address.
>
>When prompted, enter the name of the first node in your cluster. Use the same node name that you used when generating node certificates.  
>Enter all hostnames used to connect to your first node. These hostnames will be added as DNS names in the Subject Alternative Name (SAN) field in your certificate.  
>
>List every hostname and variant used to connect to your cluster over HTTPS.  
>
>Enter the IP addresses that clients can use to connect to your node.  
>Repeat these steps for each additional node in your cluster.  

取消注释 elasticsearch.yml 中
```bash
    xpack.security.http.ssl.enabled: true
    xpack.security.http.ssl.keystore.path: certs/http.p12
    xpack.security.http.ssl.truststore.path: certs/http.p12
```
如果设置了密码需要将密码添加到keystore
```bash
    ./bin/elasticsearch-keystore add reindex.ssl.truststore.secure_password
    ./bin/elasticsearch-keystore add xpack.security.http.ssl.truststore.secure_password
```

Unzip the generated elasticsearch-ssl-http.zip file. This compressed file contains one directory for both Elasticsearch and Kibana.

```bash
    /elasticsearch
    |_ README.txt
    |_ http.p12
    |_ sample-elasticsearch.yml
    /kibana
    |_ README.txt
    |_ elasticsearch-ca.pem
    |_ sample-kibana.yml
```

```bash
    mv elasticsearch/http.p12 ./config/certs
    mv kibana/elasticsearch-ca.pem ../kibana/config/certs
```

### 4. 启动脚本
```bash
useradd esuser
chown -R esuser. /usr/local/data/elasticsearch*
su - esuser 
echo "export ES_PATH_CONF=/usr/local/data/elasticsearch-server/config/ && /usr/local/data/elasticsearch-server/bin/elasticsearch -d -p /usr/local/data/elasticsearch-data/es9200.pid " > ~/start.sh
echo "pkill -F /usr/local/data/elasticsearch-data/es9200.pid" > ~/stop.sh
```


## 安装kibana

### 官网的方案 x509证书 证书
Generate a server certificate and private key for Kibana.
```bash
    ./bin/elasticsearch-certutil csr -name kibana-server -dns 10.159.65.129
```

```bash
    /kibana-server
    |_ kibana-server.csr
    |_ kibana-server.key
```

只能获得csr 和 key 文件
csr文件需要进行CA签发

### 自己进行签发

[x509证书生成](../../linux/x509%E8%AF%81%E4%B9%A6%E7%94%9F%E6%88%90.md)

[安全认证https下的crt和key证书的生成](https://blog.csdn.net/C_PlayBoy/article/details/109181818)

```bash
    openssl genrsa -des3 -out server.key 2048 # 需要密码
    openssl rsa -in server.key -out server.key # 获得不需要密码server.key
    openssl req -new -x509 -key server.key -out ca.crt -days 3650 
    openssl req -new -key server.key -out server.csr 
    openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey server.key -CAcreateserial -out server.crt # 获得crt文件
```

vim ./config/kibana.yml

```bash
    server.port: 5601
    server.host: "0.0.0.0"
    server.name: "kibana-hty"

    i18n.locale: "zh-CN"
    elasticsearch.hosts: ['https://10.159.65.129:9200','https://10.159.65.130:9200','https://10.159.65.131:9200']

    xpack.security.enabled: true
    elasticsearch.ssl.certificateAuthorities: "/usr/local/data/kibana/config/certs/elasticsearch-ca.pem"
    elasticsearch.ssl.verificationMode: certificate

    server.ssl.certificate: "/usr/local/data/kibana/config/certs/server.crt"
    server.ssl.key: "/usr/local/data/kibana/config/certs/server.key"
    server.ssl.enabled: true

    # kibana日志文件存储路径，默认stdout
    logging.dest: stdout

    # 此值为true时，禁止所有日志记录输出
    # 默认false
    logging.silent: false

    # 此值为true时，禁止除错误消息之外的所有日志记录输出
    # 默认false
    logging.quiet: false

    # 此值为true时，记录所有事件，包括系统使用信息和所有请求
    # 默认false
    logging.verbose: false

```

elasticsearch-认证添加
1. 添加到kibana-keystore
```bash
./bin/kibana-keystore add elasticsearch.username
./bin/kibana-keystore add elasticsearch.password
```
2. 添加到配置文件
```bash
tee -a ./config/kibana.yml << EOF
elasticsearch.username: "kibana_system"
elasticsearch.password: "123456"
EOF
```


### 启动服务

```bash

echo "/usr/local/data/kibana-server/bin/kibana 1> /usr/local/data/kibana-server/logs/kibana.log &" > /home/esuser/kibana_start.sh

```


### 其他elasticsearch相关配置参考

```bash
## reindex
reindex.remote.whitelist: ["elasticsearch:9200"]
reindex.ssl.keystore.path: certs/reindex_http.p12
reindex.ssl.truststore.path: certs/reindex_http.p12


#cluuster
cluster.name: dzj_es_cluster
cluster.initial_master_nodes: ["es1", "es2", "es3"]
discovery.seed_hosts: ["10.159.65.129", "10.159.65.130", "10.159.65.131"]
ingest.geoip.downloader.enabled: false
xpack.security.audit.enabled: true

## node
node.name: es1
node.master: true
node.data: true
node.ingest: true

## path
path.data: /usr/local/data/elasticsearch_data/es9200/data
path.logs: /usr/local/data/elasticsearch_data/es9200/log

## port
network.host: 0.0.0.0
transport.tcp.port: 9300
http.port: 9200

## index
action.auto_create_index: true
action.destructive_requires_name: true

## reblance
cluster.routing.allocation.cluster_concurrent_rebalance: 16
cluster.routing.allocation.node_concurrent_recoveries: 16
cluster.routing.allocation.node_initial_primaries_recoveries: 16

## other
transport.tcp.compress: true
http.cors.enabled: true
http.cors.allow-origin: "*"

## thread
thread_pool.get.queue_size: 5000
thread_pool.write.queue_size: 5000
thread_pool.analyze.queue_size: 1000
thread_pool.search.queue_size: 500
thread_pool.listener.queue_size: 5000
thread_pool.vectortile.queue_size: 100

## index
action.auto_create_index: true
action.destructive_requires_name: true

```