| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-9月-11 | 2024-9月-11  |
| ... | ... | ... |
---
# elasticsearch + kibana 安装 添加用户验证 开启https访问

[toc]

## 一.安装elasticsearch1.1环境设置
修改最大文件数以及线程数  
`vim /etc/security/limits.conf`

```bash
* hard core 0
* soft nproc 65535
* hard nproc 65535
* soft nofile 1048576
* hard nofile 1048576
* hard memlock unlimited
* soft memlock unlimited
* - as unlimited
# 备注：* 表示对用户进行通配，nofile 最大打开文件数目，nproc 最大打开线程数目
``` 

`ulimit -a`

修改文件句柄附全部sysctl.conf文件  
`vim  /etc/sysctl.conf`
```bash
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

`vm.max_map_count = 655360`

为关键指标 默认值为65530会导致报错。

```bash
# 生效
sysctl -p
```

### 1.2开始安装ES

[ElasticSearch kibana 的安装和使用方法是什么？](https://www.zhihu.com/question/485968637/answer/2933369226)

Elasticsearch 部署文档及安装规范
elasticsearch.yml 可以使用如下配置
```bash
cluster.name : node-es
node.name: node-1
cluster.initial_master_nodes: ["node-1"]
node.master: true
node.data: true
path.data: /data/elasticsearch/data
path.logs: /data/elasticsearch/log
bootstrap.memory_lock: false
bootstrap.system_call_filter: false
http.port: 9200
network.host: 0.0.0.0
discovery.zen.minimum_master_nodes: 6
discovery.zen.ping_timeout: 3s
discovery.zen.ping.unicast.hosts: ip:9300
```

### 1.3 开启用户验证

[docker部署elasticsearch集群实现用户认证](https://zhuanlan.zhihu.com/p/382572919)

主要流程  

1.  生成p12认证文件
2. 开启用户 认证
3. 添加用户

#### 1.生成p12认证文件

```bash
./bin/elasticsearch-certutil ca  
./bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12
```

如果`./bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12`添加了密码
需要在es keystore 中添加密码  
```bash
./bin/elasticsearch-keystore add xpack.security.transport.ssl.keystore.secure_password

./bin/elasticsearch-keystore add xpack.security.transport.ssl.truststore.secure_password
```

#### 2.开启用户 认证
```bash
# 开启 xpack用户验证插件xpack.security.enabled: true
# TLS

xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12
xpack.security.transport.filter.allow: "192.168.*"
```



#### 3.添加用户

启动es启动  

``` bash
useradd esuser 
su - esuser
echo export ES_PATH_CONF=/usr/local/data/elasticsearch-server/config/ && elasticsearch -d -p /usr/local/data/elasticsearch-data/es9200.pid > start.sh
```

es 添加用戶
```bash
# ./bin/elasticsearch-keystore create
./bin/elasticsearch-setup-passwords interactive
```

### 1.4 开启TLS 
需要使用1.3生成的p12文件  
TLS
```bash
tee -a /usr/local/data/config/elasticsearch-server/elasticsearch.yml  << EOF
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: elastic-certificates.p12
xpack.security.http.ssl.truststore.path: elastic-certificates.p12
EOF
```

同理如果elastic-certificates.p12 是有密码的需要在es keystore 中添加密码才可以
```bash
./bin/elasticsearch-keystore add xpack.security.http.ssl.keystore.secure_password

./bin/elasticsearch-keystore add xpack.security.http.ssl.truststore.secure_password
```

### 1.5 命令行创建用户和角色
```bash
curl  -k --user elastic:Dzj_pwd_hty    -H "Content-Type: application/json" -XPUT https://10.159.65.41:9200/_security/role/DmlRole -d '{
"indices": [
    {
      "names": [
        "*"
      ],
      "privileges": [
        "read",
"write",
"create_index"
      ]
    }
  ]
}'


curl -k --user elastic:Dzj_pwd_hty   -H "Content-Type: application/json"  -XPOST https://10.159.65.41:9200/_security/user/dzj_user -d '{

  "password" : "PBunUE8X2F94I59VsMBi",

  "roles" : ["DmlRole"]

}'
```


## 二.安装kibana1.1 开始安装
[ElasticSearch&kibana 的安装和使用方法是什么？](https://www.zhihu.com/question/485968637/answer/2933369226)

编写的配置文件中加入了以下内容
```bash
server.port: 5601         #kibana端口server.host: "0.0.0.0"   #所有主机都能访问，或者也可以指定一个ip
elasticsearch.hosts: "http://es服务公网IP:9200"  #配置es的访问地址    
kibana.index: ".kibana"
```

### 1.2 添加elastic search 用户验证
由于ES开启了用户验证， kibana也需要相应的认证配置1.2.1 ES没有开启用户验证的话不需要添加用户验证相关参数

#### 1.2.2 ES开启了xpack用户验证
kibana 配置文件中添加
```bash
elasticsearch.username: "your_username"
elasticsearch.password: "your_password"
```

#### 1.2.3kibana安全传输
[Encrypting communications in Kibana](https://www.elastic.co/guide/en/kibana/7.6/configuring-tls.html#configuring-tls-kib-es)

##### 1.2.3.1ES开启了SSL\TLS,kibana后端加密
生成pem 文件
```bash
openssl pkcs12 -in /usr/local/data/elasticsearch-server/config/cert/elastic-certificates.p12 -cacerts -nokeys -out elasticsearch-ca.pem
```
kibana.yml 添加如下配置
```bash
tee -a /usr/local/data/kibana-server/config/kibana.yml << EOF
elasticsearch.hosts: "https://172.29.28.195:9200" #修改为https
elasticsearch.ssl.certificateAuthorities: "/usr/local/data/kibana-server/config/elasticsearch-ca.pem"
elasticsearch.ssl.verificationMode: certificate
EOF
```

##### 1.2.3.2kibana 开始TLS,kibana前端(浏览器)加密传输
<1>获取PKCS#12 文件  
`bin/elasticsearch-certutil cert -name kibana-server -dns localhost,127.0.0.1`  
<2>添加密码到kibana密码管理中  
```bash
bin/kibana-keystore create
bin/kibana-keystore add server.ssl.keystore.password
```    
生成p12文件时没有给密码，输入空密码就可以了  

<3>修改配置文件添加https  
`server.ssl.keystore.path: "/data/kibana/kibna/config/kibana-server.p12"`  
`server.ssl.enabled: true`  

### 1.3 kibana与ES双向认证TLS
[Mutual TLS authentication between Kibana and Elasticsearch](https://www.elastic.co/guide/en/kibana/7.6/elasticsearch-mutual-tls.html) 

`bin/elasticsearch-certutil cert -ca elastic-stack-ca.p12 -name kibana-client -dns localhost,127.0.0.1  `

注意elastic-stack-ca.p12 需要在 ES主目录   
得到kibana-client.p12文件  
`openssl pkcs12 -in kibana-client.p12 -cacerts -nokeys -out kibana-ca.crt ` 
得到kibana-ca.crt文件  

elasticsearch.yml添加一下配置  
```bash
xpack.security.authc.realms.pki.realm1.order: 1xpack.security.authc.realms.pki.realm1.certificate_authorities: "/path/to/kibana-ca.crt"  
xpack.security.authc.realms.native.realm2.order: 2  
xpack.security.http.ssl.client_authentication: "optional"  
```

kibana.yml添加  
`elasticsearch.ssl.keystore.path: "/data/kibana/kibana/config/kibana-client.p12"`     
并添加bin/kibana-keystore add elasticsearch.ssl.keystore.password  

### 1.4 kibana 日志配置  
配置文件中增加需要配置  

```bash
tee -a /usr/local/data/kibana-server/config/kibana.yml << EOF
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
EOF
```

### 1.5 kibana监控ES状态
[Collecting Elasticsearch monitoring data with Metricbeat](https://www.elastic.co/guide/en/elasticsearch/reference/7.6/configuring-metricbeat.html)

### 1.6 客户端连接HTTPS
python 连接 elasticsearch  
https://www.elastic.co/guide/en/elasticsearch/client/python-api/8.8/connecting.html

连接参数
https://www.elastic.co/guide/en/elasticsearch/reference/7.17/http-clients.html

示例：
```
ELASTIC_PASSWORD = "dzjuser_pwd" 
client = Elasticsearch( "https://172.29.104.53:9200",
#    ssl_assert_fingerprint=CERT_FINGERPRINT,
ssl_assert_hostname= False, 
ca_certs=r"C:\Users\shenxiang.DAZHUANJIA\Desktop\client-ca.cer",
basic_auth=("dzjuser", ELASTIC_PASSWORD)
)
```
