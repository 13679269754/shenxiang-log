| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2023-12月-12 | 2023-12月-12  |
| ... | ... | ... |
---
# influxdb 服务监控(自身)

[toc]

> 前言：influxdb2 接入prometheus(pmm)没有好用的dashboard，基本需要自己写。如果只是告警，要好一点

## influxdb(1)
[(influxdb 1)Prometheus监控influxdb的方法及指标释义](https://blog.csdn.net/sinat_32582203/article/details/123050278)

上面两种方式分别对应prometheu 的两种指标获取方式,push 和poll
由于选用的是pmm作为监控平台，客户端主动注册为push 模式，服务端添加服务为poll模式

### telegraf 安装
[telegraf 安装](https://docs.influxdata.com/telegraf/v1/install/)

telegraf.conf 配置
```bash
[[outputs.prometheus_client]]
        urls = [
                "http://localhost:53201"
        ]
        listen = ":53201"
```

## influxdb2

由于未找到telegraf 关于output.influxdb_v2的配置项，使用telegraf 无法实现，prometheus exporter 也不支持influxdb2

### 使用influxdb2指标接口实现

influxdb2指标接口
http://localhost:port/metrics
>influxdb(1)指标接口
>http://localhost:port/debug/var