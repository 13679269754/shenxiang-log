| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2023-12月-05 | 2023-12月-05  |
| ... | ... | ... |
---
# influxdb搭建

[toc]

[官网](https://docs.influxdata.com/influxdb/v2/install/)

## 获取安装包
```bash
curl -O https://dl.influxdata.com/influxdb/releases/influxdb2-2.7.4_linux_amd64.tar.gz
```

## 解压到指定路径
```bash

mkdir /usr/local/data/

tar -xvzf /root/soft/influxdb2-2.7.4_linux_amd64.tar.gz -C /usr/local/data/

mv /usr/local/data/influxdb2-2.7.4 /usr/local/data/influxdb2

```

## 配置环境变量
（一般配置在~/.bash_profile）
```bash 
INFLUXDB_HOME=/usr/local/data/influxdb2-service
INFLUXD_CONFIG_PATH=/usr/local/data/influxdb2/conf
INFLUX_CONFIGS_PATH=/usr/local/data/influxdb2/conf/influx_conf
INFLUX_HOST=http:
PATH=$PATH:$INFLUXDB_HOME

export PATH
export INFLUXD_CONFIG_PATH
export INFLUX_CONFIGS_PATH
```

## 目录创建

```bash
mkdir  -p /usr/local/data/influxdb2/conf
```

## 编写配置文件
配置文件模板 $INFLUXD_CONFIG_PATH/influx_conf.yaml
```bash
bolt-path: /usr/local/data/influxdb2/data/influxd.bolt
engine-path: /usr/local/data/influxdb2/data/engine
sqlite-path: /usr/local/data/influxdb2/data/influxd.sqlite

flux-log-enabled: true
hardening-enabled: false

http-bind-address: ':8480'
http-idle-timeout: 3m0s
http-read-header-timeout: 10s
http-read-timeout: 0
http-write-timeout: 0

influxql-max-select-buckets: 0
influxql-max-select-point: 0
influxql-max-select-series: 0

instance-id: ''
log-level: info

query-concurrency: 1024
query-initial-memory-bytes: 10485760
query-max-memory-bytes: 6442450944
query-memory-bytes: 10485760
query-queue-size: 1024

reporting-disabled: true
secret-store: bolt
session-length: 60
session-renew-disabled: true


storage-cache-max-memory-size: 1073741824
storage-cache-snapshot-memory-size: 26214400
storage-cache-snapshot-write-cold-duration: 10m0s
storage-compact-full-write-cold-duration: 4h0m0s
storage-compact-throughput-burst: 50331648
storage-max-concurrent-compactions: 0
storage-max-index-log-file-size: 1048576
storage-no-validate-field-size: false
storage-retention-check-interval: 30m0s
storage-series-file-max-concurrent-snapshot-compactions: 0
storage-series-id-set-cache-size: 0
storage-shard-precreator-advance-period: 30m0s
storage-shard-precreator-check-interval: 10m0s
storage-tsm-use-madv-willneed: false
storage-validate-keys: true
storage-wal-fsync-delay: 0s
storage-wal-max-concurrent-writes: 0
storage-wal-max-write-delay: 10m
storage-write-timeout: 10s

store: disk
#tls-cert: '/usr/local/data/influxdb2/conf/influx_ssl/influxdb-selfsigned.crt'
##tls-key: '/usr/local/data/influxdb2/conf/influx_ssl/influxdb-selfsigned.key'
##tls-min-version: '1.2'
##tls-strict-ciphers: false
#tracing-type: ''
#ui-disabled: false
#vault-addr: ''
#vault-cacert: ''
#vault-capath: ''
#vault-client-cert: ''
#vault-client-key: ''
#vault-client-timeout: 0
#vault-max-retries: 0
#vault-skip-verify: false
#vault-tls-server-name: ''
#vault-token: ''
```
>关注
> 内存配置  
> `query-max-memory-bytes`  
> 端口配置  
> `http-bind-address`  
> tls配置(官方建议开启)  
> [Enable TLS encryption](https://docs.influxdata.com/influxdb/v2/admin/security/enable-tls/#configure-influxdb-to-use-tls)

## 用户添加等

```bash
useradd influxdb

chown -R influxdb. /usr/local/data

echo "influxd 1 >> /usr/local/data/influxdb2/log/influxdb.log &"  > /home/influxdb/start.sh
 
echo "pkill influxd" > /home/influxdb/stop.sh

```

## 启动服务

```bash
su - influxdb
./start.sh
```

## 防火墙端口放开


## 创建用户

https://ip:port

参照[Set up InfluxDB](https://docs.influxdata.com/influxdb/v2/get-started/setup/)