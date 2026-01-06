[再有谁说不熟悉夜莺（ Nightingale ）监控系统，就把这个给他扔过去！-腾讯云开发者社区-腾讯云](https://cloud.tencent.com/developer/article/2359150) 

 ### **夜莺监控（ Nightingale ）**

官方网址：https://n9e.github.io/

![](https://developer.qcloudimg.com/http-save/yehe-7754373/ce7dd8b46ee2bc9067c30a94caca972e.png)

夜莺监控（ Nightingale ）是一款国产、开源云原生监控分析系统，采用 All-In-One 的设计，集数据采集、可视化、监控告警、数据分析于一体。于 2020 年 3 月 20 日，在 github 上发布 v1 版本，已累计迭代 60 多个版本。从 v5 版本开始与 Prometheus、VictoriaMetrics、Grafana、Telegraf、Datadog 等生态紧密协同集成，提供开箱即用的企业级监控分析和告警能力，已有众多企业选择将 Prometheus + AlertManager + Grafana 的组合方案升级为使用夜莺监控。

夜莺监控，由滴滴开发和开源，并于 2022 年 5 月 11 日，捐赠予中国计算机学会开源发展委员会（CCF ODC），为 CCF ODC 成立后接受捐赠的第一个开源项目。夜莺监控的核心开发团队，也是Open-Falcon项目原核心研发人员。

![](https://developer.qcloudimg.com/http-save/yehe-7754373/e153b6f89a7fb1ef379978998d501c71.gif)

##### **特性**

*   开箱即用：支持 Docker、Helm Chart、云服务等多种部署方式；集数据采集、监控告警、可视化为一体；内置多种监控仪表盘、快捷视图、告警规则模板，导入即可快速使用；大幅降低云原生监控系统的建设成本、学习成本、使用成本；
*   专业告警：可视化的告警配置和管理，支持丰富的告警规则，提供屏蔽规则、订阅规则的配置能力，支持告警多种送达渠道，支持告警自愈、告警事件管理等；
*   云原生：以交钥匙的方式快速构建企业级的云原生监控体系，支持 Categraf、Telegraf、Grafana-agent 等多种采集器，支持 Prometheus、VictoriaMetrics、M3DB、ElasticSearch 等多种数据库，兼容支持导入 Grafana 仪表盘，与云原生生态无缝集成；
*   高性能、高可用：得益于夜莺的多数据源管理引擎，和夜莺引擎侧优秀的架构设计，借助于高性能时序库，可以满足数亿时间线的采集、存储、告警分析场景，节省大量成本；夜莺监控组件均可水平扩展，无单点，已在上千家企业部署落地，经受了严苛的生产实践检验；
*   灵活扩展、中心化管理：夜莺监控，可部署在 1 核 1G 的云主机，可在上百台机器集群化部署，可运行在 K8s 中；也可将时序库、告警引擎等组件下沉到各机房、各 Region，兼顾边缘部署和中心化统一管理，解决数据割裂，缺乏统一视图的难题；
*   开放社区：托管于中国计算机学会开源发展委员会，有快猫星云和众多公司的持续投入，和数千名社区用户的积极参与，以及夜莺监控项目清晰明确的定位，都保证了夜莺开源社区健康、长久的发展。活跃、专业的社区用户也在持续沉淀更多的最佳实践于产品中。

### **架构**

##### **系统架构**

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/e3028623-d0c5-4818-a5d4-efe425209776.png?raw=true)

夜莺（Nightingale ）的核心是 server 和 webapi 两个模块，webapi 无状态，放到中心端，承接前端请求，将用户配置写入数据库；server 是告警引擎和数据转发模块，一般随着时序库走，一个时序库就对应一套 server，每套 server 可以只用一个实例，也可以多个实例组成集群，server 可以接收 Categraf、Telegraf、Grafana-Agent、Datadog-Agent、Falcon-Plugins 上报的数据，写入后端时序库，周期性从数据库同步告警规则，然后查询时序库做告警判断。每套 server 依赖一个 redis。

##### **组件架构**

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/f5e49202-3cb5-4a45-a38f-8434b4a34c51.png?raw=true)

*   collectors：采集器，这里选择Categraf。
*   Nightingale：接收采集器上报的监控数据，转存到时序库，，并提供告警规则、屏蔽规则、订阅规则的配置能力，提供监控数据的查看能力，提供告警自愈机制（告警触发之后自动回调某个webhook地址或者执行某个脚本），提供历史告警事件的存储管理、分组查看的能力。
*   Prometheus：时序库，存储采集器上报的监控数据。
*   Ibex：告警自愈功能依赖的模块，提供一个批量执行命令的通道，可以做到在告警的时候自动去目标机器执行脚本。

##### **部署架构**

![](https://developer.qcloudimg.com/http-save/yehe-7754373/9c27e97b0cb4fc2cbeabfd00ef69cf23.png)

### **安装配置**

##### **服务端(Nightingale)**

根据【架构规划】-【组件架构】，Nightingale用于接收采集器上报的监控数据，转存到时序库，，并提供告警规则、屏蔽规则、订阅规则的配置能力，提供监控数据的查看能力，提供告警自愈机制（告警触发之后自动回调某个webhook地址或者执行某个脚本），提供历史告警事件的存储管理、分组查看的能力。服务端由4个部分组成：

*   n9e-webapi
*   n9e-server
*   MySQL
*   redis
*   Prometheus
*   Ibex

###### **架构**

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/37cea44c-62d4-41a0-a93b-8195883543b6.png?raw=true)

*   n9e-webapi：用于提供 API 给前端 JavaScript 使用
*   n9e-server：告警引擎和数据转发器
*   MySQL：[关系型数据库](https://cloud.tencent.com/product/tencentdb-catalog?from_column=20065&from=20065)，存储配置、用户、告警规则等基础信息
*   redis：缓存数据库，jwt、cache
*   Prometheus：：时序库，存储采集器上报的监控数据
*   Ibex：自愈组件

##### **安装**

###### **Docker**

基础环境：docker、 Docker-compose、git

拉取代码包

```
# git clone https://github.com/ccfos/nightingale 
```

修改默认mysql密码，相关配置文件路径：

```
nightingale/docker/Docker-compose.yaml  
nightingale/docker/n9eetc/server.conf  
nightingale/docker/n9eetc/webapi.conf  
nightingale/docker/docker/ibexetc/server.conf 
```

修改内容如下：

Docker-compose.yaml

```
services:
  mysql:
    image: mysql:5.7
    container_name: mysql
    hostname: mysql
    restart: always
    ports:
      - "3306:3306"
    environment:
      TZ: Asia/Shanghai
      MYSQL_ROOT_PASSWORD: 修改后密码
    volumes:
      - ./mysqldata:/var/lib/mysql/
      - ./initsql:/docker-entrypoint-initdb.d/
      - ./mysqletc/my.cnf:/etc/my.cnf
    networks:
      - nightingale 
```

server.conf

```
[DB]
# postgres: host=%s port=%s user=%s dbname=%s password=%s sslmode=%s
DSN="root:修改后密码@tcp(mysql:3306)/n9e_v5?charset=utf8mb4&parseTime=True&loc=Local&allowNativePasswords=true"
# enable debug mode or not
Debug = false
# mysql postgres
DBType = "mysql"
# unit: s
MaxLifetime = 7200
# max open connections
MaxOpenConns = 150
# max idle connections
MaxIdleConns = 50
# table prefix
TablePrefix = ""
# enable auto migrate or not
# EnableAutoMigrate = false 
```

webapi.conf

```
[DB]
# postgres: host=%s port=%s user=%s dbname=%s password=%s sslmode=%s
DSN="root:修改后密码@tcp(mysql:3306)/n9e_v5?charset=utf8mb4&parseTime=True&loc=Local&allowNativePasswords=true"
# enable debug mode or not
Debug = true
# mysql postgres
DBType = "mysql"
# unit: s
MaxLifetime = 7200
# max open connections
MaxOpenConns = 150
# max idle connections
MaxIdleConns = 50
# table prefix
TablePrefix = ""
# enable auto migrate or not
# EnableAutoMigrate = false 
```

ibexetc/server.conf

```
[MySQL]
# mysql address host:port
Address = "mysql:3306"
# mysql username
User = "root"
# mysql password
Password = "修改后密码"
# database name
DBName = "ibex"
# connection params
Parameters = "charset=utf8mb4&parseTime=True&loc=Local&allowNativePasswords=true" 
```

##### **使用Docker Compose一键启动夜莺**

```
# cd nightingale/docker
# docker-compose up -d
Creating network "docker_nightingale" with driver "bridge"
Restarting categraf   ... done
Restarting nserver    ... done
Restarting nwebapi    ... done
Restarting agentd     ... done
Restarting ibex       ... done
Restarting redis      ... done
Restarting mysql      ... done
Restarting prometheus ... done 
```

##### **安装Ibex(自选)**

项目地址：

*   Repo：https://github.com/flashcatcloud/ibex
*   Linux-amd64 有编译好的二进制：https://github.com/flashcatcloud/ibex/releases

Ibex 是告警自愈功能依赖的模块，提供一个批量执行命令的通道，可以做到在告警的时候自动去目标机器执行脚本。

所谓的告警自愈，典型手段是在告警触发时自动回调某个 webhook 地址，在这个 webhook 里写告警自愈的逻辑，夜莺默认支持这种方式。另外，夜莺还可以更进一步，配合 ibex 这个模块，在告警触发的时候，自动去告警的机器执行某个脚本，这种机制可以大幅简化构建运维自愈链路的工作量，毕竟，不是所有的运维人员都擅长写 http server，但所有的运维人员，都擅长写脚本。这种方式是典型的物理机时代的产物，希望各位朋友用不到这个工具（说明贵司的IT技术已经走得非常靠前了）。

###### **架构**

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/7eeb2f1a-413f-48d1-859b-c06cb1a7a2a8.png?raw=true)

ibex 包括 server 和 agentd 两个模块，agentd 周期性调用 server 的 rpc 接口，询问有哪些任务要执行，如果有分配给自己的任务，就从 server 拿到任务脚本信息，在本地 fork 一个进程运行，然后将结果上报给服务端。为了简化部署，server 和 agentd 融合成了一个二进制，就是 ibex，通过传入不同的参数来启动不同的角色。ibex 架构图如下：

###### **安装**

下载安装包之后，解压缩，在 etc 下可以找到服务端和客户端的配置文件，在 sql 目录下可以找到初始化 sql 脚本。

初始化 sql

启动 server：server 的配置文件是 etc/server.conf，注意修改里边的 mysql 连接地址，配置正确的 mysql 用户名和密码。然后就可以直接启动了：

```
nohup ./ibex server &> server.log & 
```

ibex 没有 web 页面，只提供 api 接口，鉴权方式是 http basic auth，basic auth 的用户名和密码默认都是 ibex，在 etc/server.conf 中可以找到，如果ibex 部署在互联网，一定要修改默认用户名和密码，当然，因为 Nightingale 要调用 ibex，所以 Nightingale 的 server.conf 和 webapi.conf 中也配置了 ibex 的 basic auth 账号信息，需要一并修改。

启动agentd，客户端的配置agentd.conf 内容如下：

```
# debug, release
RunMode = "release"
# task meta storage dir
MetaDir = "./meta"
[Heartbeat]
# unit: ms
Interval = 1000
# rpc servers
Servers = ["10.2.3.4:20090"]
# $ip or $hostname or specified string
Host = "telegraf01" 
```

*   Heartbeat：Interval 是心跳频率，默认是 1000 毫秒，如果机器量比较小，比如小于 1000 台，维持 1000 毫秒没问题，如果机器量比较大，可以适当调大这个频率，比如 2000 或者 3000，可以减轻服务端的压力。
*   Servers：数组，配置的是 ibex-server 的地址，ibex-server 可以启动多个，多个地址都配置到这里即可。
*   Host：本机的唯一标识，有三种配置方式，如果配置为 ip，系统会自动探测本机的IP，如果是hostname，系统会自动探测本机的 hostname，如果是其他字符串，那就直接把该字符串作为本机的唯一标识。每个机器上都要部署 ibex-agentd，不同的机器要保证 Host 字段获取的内容不能重复。

要想做到告警的机器自动执行脚本，需要保证告警消息中的 ident 表示机器标识，且和 ibex-agentd 中的 Host 配置对应上。

下面是启动 ibex-agentd 的命令：

```
nohup ./ibex agentd &> agentd.log & 
```

### **配置**

##### **nightingale**

###### **server.conf**

```
# debug, release
# 运行方式选择
RunMode = "release"

# 集群名称，必须与webapi.conf 中对应"[[Clusters]]"配置下的name保持一致，且不能为中文
# my cluster name
ClusterName = "ZW-HLW"

# 默认业务组关键字名称，不要更改
# Default busigroup Key name
# do not change
BusiGroupLabelKey = "busigroup"

# 休眠时间，休眠x秒，然后启动判断引擎
# sleep x seconds, then start judge engine
EngineDelay = 60
# 禁用使用率报告
DisableUsageReport = false

# 从那里读取配置，默认为config
# config | database
ReaderFrom = "config"

# 日志配置
[Log]
# log write dir
Dir = "logs"
# log level: DEBUG INFO WARNING ERROR
Level = "INFO"
# stdout, stderr, file
Output = "stdout"
# # rotate by time
# KeepHours: 4
# # rotate by size
# RotateNum = 3
# # unit: MB
# RotateSize = 256

# http配置
[HTTP]
# http listening address
Host = "0.0.0.0"
# http listening port
Port = 19000
# https cert file path
CertFile = ""
# https key file path
KeyFile = ""
# whether print access log
PrintAccessLog = false
# whether enable pprof
PProf = false
# http graceful shutdown timeout, unit: s
ShutdownTimeout = 30
# max content length: 64M
MaxContentLength = 67108864
# http server read timeout, unit: s
ReadTimeout = 20
# http server write timeout, unit: s
WriteTimeout = 40
# http server idle timeout, unit: s
IdleTimeout = 120

# [BasicAuth]
# user002 = "ccc26da7b9aba533cbb263a36c07dcc9"

# 心跳配置
[Heartbeat]
# auto detect if blank
IP = ""
# unit ms
Interval = 1000

# 邮件服务配置，不需要请全注释
[SMTP]
Host = "smtp.163.com"
Port = 994
User = "username"
Pass = "password"
From = "username@163.com"
InsecureSkipVerify = true
Batch = 5

# 消息通知媒介配置（告警）
## 模板配置
### TemplatesDir指定模板文件的目录，这个目录下有多个模板文件，遵从Go Template语法，可以控制告警发送的消息的格式
### NotifyConcurrency 表示并发度，可以维持默认，处理不过来了，有事件堆积（事件是否堆积可以查看n9e-server的这个指标：n9e_server_alert_queue_size，通过 /metrics 接口暴露的）了再调大
### NotifyBuiltinChannels 是配置Go代码内置的通知媒介，默认5个通知媒介都让Go代码来做，如果某些通知媒介想做一些自定义，可以从这个数组中删除对应的通知媒介，Go代码就不处理那个通知媒介了，自定义的通知媒介可以在后面介绍的脚本里自行处理，灵活自定义
[Alerting]
# timeout settings, unit: ms, default: 30000ms
Timeout=30000
TemplatesDir = "./etc/template"
NotifyConcurrency = 10
# use builtin go code notify
NotifyBuiltinChannels = ["email", "dingtalk", "wecom", "feishu", "mm"]

## 配置告警通知脚本
### CallScript是配置告警通知脚本的，如果没有自定义的需求，Go内置的5种发送通道 ["email", "dingtalk", "wecom", "feishu","mm"] 完全可以满足需求，这个CallScript是无需关注的，所以默认Enable=false。
### 如果内置的发送逻辑搞不定了，比如想支持短信、电话等通知方式，就可以启用CallScript，夜莺发现这里的Enable=true且指定了一个脚本，就会去执行这个脚本，把告警事件的内容发给这个脚本，由这个脚本做后续处理。
### notify.py的同级目录，还有一个notify.bak.py，很多逻辑可以参考这个脚本。因为夜莺刚开始的版本发送告警只能通过脚本来做，后来才内置到go代码中的，所以，notify.bak.py里备份了很多老的逻辑，大家可以参考。
[Alerting.CallScript]
# built in sending capability in go code
# so, no need enable script sender
Enable = false
ScriptPath = "./etc/script/notify.py"

## CallPlugin是动态链接库的方式加载外部逻辑，默认Enable=false
[Alerting.CallPlugin]
Enable = false
# use a plugin via `go build -buildmode=plugin -o notify.so`
PluginPath = "./etc/script/notify.so"
# The first letter must be capitalized to be exported
Caller = "N9eCaller"

## 这个配置如果开启，n9e-server会把生成的告警事件publish给redis，如果有自定义的逻辑，可以去subscribe，然后自行处理。
[Alerting.RedisPub]
Enable = false
# complete redis key: ${ChannelPrefix} + ${Cluster}
ChannelPrefix = "/alerts/"

## 这是全局Webhook，如果启用，n9e-server生成告警事件之后，就会回调这个Url，对接一些第三方系统。告警事件的内容会encode成json，放到HTTP request body中，POST给这个Url，也可以自定义Header，即Headers配置，Headers是个数组，必须是偶数个，Key1, Value1, Key2, Value2 这个写法。
[Alerting.Webhook]
Enable = false
Url = "http://a.com/n9e/callback"
BasicAuthUser = ""
BasicAuthPass = ""
Timeout = "5s"
Headers = ["Content-Type", "application/json", "X-From", "N9E"]

[NoData]
Metric = "target_up"
# unit: second
Interval = 120

# 自愈组件配置
[Ibex]
# callback: ${ibex}/${tplid}/${host}
Address = "ibex:10090"
# basic auth
BasicAuthUser = "ibex"
BasicAuthPass = "ibex"
# unit: ms
Timeout = 3000

# redis连接配置
[Redis]
# address, ip:port
Address = "redis:6379"
# requirepass
Password = ""
# # db
# DB = 0

# mysql连接配置
[DB]
# postgres: host=%s port=%s user=%s dbname=%s password=%s sslmode=%s
DSN="root:数据库密码@tcp(mysql:3306)/n9e_v5?charset=utf8mb4&parseTime=True&loc=Local&allowNativePasswords=true"
# enable debug mode or not
Debug = false
# mysql postgres
DBType = "mysql"
# unit: s
MaxLifetime = 7200
# max open connections
MaxOpenConns = 150
# max idle connections
MaxIdleConns = 50
# table prefix
TablePrefix = ""
# enable auto migrate or not
# EnableAutoMigrate = false

# 一个server对应一个时序库，表示：去该时序库读取监控数据
# 采集器采集数据上报给server,server将获取的数据写入writer,server获取数据分析判断从reader处读
[Reader]
# prometheus base url
Url = "http://prometheus:9090"
# Basic auth username
BasicAuthUser = ""
# Basic auth password
BasicAuthPass = ""
# timeout settings, unit: ms
Timeout = 30000
DialTimeout = 3000
MaxIdleConnsPerHost = 100

[WriterOpt]
# queue channel count
QueueCount = 1000
# queue max size
QueueMaxSize = 1000000
# once pop samples number from queue
QueuePopSize = 1000
# metric or ident
ShardingKey = "ident"

# 一个server对应一个【reader】,对应多个[[writer]]，及将采集器上报的数据存储与不同的时序库
[[Writers]]
Url = "http://prometheus:9090/api/v1/write"
# Basic auth username
BasicAuthUser = ""
# Basic auth password
BasicAuthPass = ""
# timeout settings, unit: ms
Timeout = 10000
DialTimeout = 3000
TLSHandshakeTimeout = 30000
ExpectContinueTimeout = 1000
IdleConnTimeout = 90000
# time duration, unit: ms
KeepAlive = 30000
MaxConnsPerHost = 0
MaxIdleConns = 100
MaxIdleConnsPerHost = 100
# [[Writers.WriteRelabels]]
# Action = "replace"
# SourceLabels = ["__address__"]
# Regex = "([^:]+)(?::\\d+)?"
# Replacement = "$1:80"
# TargetLabel = "__address__"

# [[Writers]]
# Url = "http://m3db:7201/api/v1/prom/remote/write"
# # Basic auth username
# BasicAuthUser = ""
# # Basic auth password
# BasicAuthPass = ""
# # timeout settings, unit: ms
# Timeout = 30000
# DialTimeout = 10000
# TLSHandshakeTimeout = 30000
# ExpectContinueTimeout = 1000
# IdleConnTimeout = 90000
# # time duration, unit: ms
# KeepAlive = 30000
# MaxConnsPerHost = 0
# MaxIdleConns = 100
# MaxIdleConnsPerHost = 100 
```

###### **webapi.conf**

```
# debug, release
# 运行方式选择
RunMode = "release"

# i18n配置相关
# # custom i18n dict config
# I18N = "./etc/i18n.json"

# # custom i18n request header key
# I18NHeaderKey = "X-Language"

# metrics descriptions
MetricsYamlFile = "./etc/metrics.yaml"
BuiltinAlertsDir = "./etc/alerts"
BuiltinDashboardsDir = "./etc/dashboards"

# config | api
ClustersFrom = "config"

# using when ClustersFrom = "api"
# ClustersFromAPIs = []

# 告警通知渠道配置
[[NotifyChannels]]
Label = "邮箱"
# do not change Key
Key = "email"

[[NotifyChannels]]
Label = "钉钉机器人"
# do not change Key
Key = "dingtalk"

[[NotifyChannels]]
Label = "企微机器人"
# do not change Key
Key = "wecom"

[[NotifyChannels]]
Label = "飞书机器人"
# do not change Key
Key = "feishu"

[[NotifyChannels]]
Label = "mm bot"
# do not change Key
Key = "mm"

[[ContactKeys]]
Label = "Wecom Robot Token"
# do not change Key
Key = "wecom_robot_token"

[[ContactKeys]]
Label = "Dingtalk Robot Token"
# do not change Key
Key = "dingtalk_robot_token"

[[ContactKeys]]
Label = "Feishu Robot Token"
# do not change Key
Key = "feishu_robot_token"

[[ContactKeys]]
Label = "MatterMost Webhook URL"
# do not change Key
Key = "mm_webhook_url"

# 日志配置
[Log]
# log write dir
Dir = "logs"
# log level: DEBUG INFO WARNING ERROR
Level = "DEBUG"
# stdout, stderr, file
Output = "stdout"
# # rotate by time
# KeepHours: 4
# # rotate by size
# RotateNum = 3
# # unit: MB
# RotateSize = 256

# http服务配置
[HTTP]
# http listening address
Host = "0.0.0.0"
# http listening port
Port = 18000
# https cert file path
CertFile = ""
# https key file path
KeyFile = ""
# whether print access log
PrintAccessLog = true
# whether enable pprof
PProf = false
# http graceful shutdown timeout, unit: s
ShutdownTimeout = 30
# max content length: 64M
MaxContentLength = 67108864
# http server read timeout, unit: s
ReadTimeout = 20
# http server write timeout, unit: s
WriteTimeout = 40
# http server idle timeout, unit: s
IdleTimeout = 120

# JWT授权，建议更改SigningKey
[JWTAuth]
# signing key
SigningKey = "5b94a0fd640fe2765af826acfe42d151"
# unit: min
AccessExpired = 1500
# unit: min
RefreshExpired = 10080
RedisKeyPrefix = "/jwt/"

# 代理授权
[ProxyAuth]
# if proxy auth enabled, jwt auth is disabled
Enable = false
# username key in http proxy header
HeaderUserNameKey = "X-User-Name"
DefaultRoles = ["Standard"]

# 基本认证，建议更改
[BasicAuth]
user001 = "ccc26da7b9aba533cbb263a36c07dcc5"

# 匿名访问配置，默认关闭
[AnonymousAccess]
PromQuerier = false
AlertDetail = false

# LDAP配置，不涉及，可全注释
[LDAP]
Enable = false
Host = "ldap.example.org"
Port = 389
BaseDn = "dc=example,dc=org"
# AD: manange@example.org
BindUser = "cn=manager,dc=example,dc=org"
BindPass = "*******"
# openldap format e.g. (&(uid=%s))
# AD format e.g. (&(sAMAccountName=%s))
AuthFilter = "(&(uid=%s))"
CoverAttributes = true
TLS = false
StartTLS = true
# ldap user default roles
DefaultRoles = ["Standard"]

[LDAP.Attributes]
Nickname = "cn"
Phone = "mobile"
Email = "mail"

# OIDC认证配置，默认
[OIDC]
Enable = false
RedirectURL = "http://n9e.com/callback"
SsoAddr = "http://sso.example.org"
ClientId = ""
ClientSecret = ""
CoverAttributes = true
DefaultRoles = ["Standard"]

[OIDC.Attributes]
Nickname = "nickname"
Phone = "phone_number"
Email = "email"

# redis连接配置
[Redis]
# address, ip:port
Address = "redis:6379"
# requirepass
Password = ""
# # db
# DB = 0

# mysql连接配置
[DB]
# postgres: host=%s port=%s user=%s dbname=%s password=%s sslmode=%s
DSN="root:数据库密码@tcp(mysql:3306)/n9e_v5?charset=utf8mb4&parseTime=True&loc=Local&allowNativePasswords=true"
# enable debug mode or not
Debug = true
# mysql postgres
DBType = "mysql"
# unit: s
MaxLifetime = 7200
# max open connections
MaxOpenConns = 150
# max idle connections
MaxIdleConns = 50
# table prefix
TablePrefix = ""
# enable auto migrate or not
# EnableAutoMigrate = false

# [[ ]] 数组配置，可复制多份；集群配置，多集群接入时，配置多个Clusters，如下配置接入两个Prometheus集群
[[Clusters]]
# Prometheus cluster name
# 与server.conf的clustername 必须保持一致
Name = "ZW-HLW"
# Prometheus APIs base url
Prom = "http://prometheus:9090"
# Basic auth username
BasicAuthUser = ""
# Basic auth password
BasicAuthPass = ""
# timeout settings, unit: ms
Timeout = 30000
DialTimeout = 3000
MaxIdleConnsPerHost = 100

[[Clusters]]
# Prometheus cluster name
Name = "ZW-WW"
# # Prometheus APIs base url
Prom = "http://1.2.3.4:9090"
# # Basic auth username
BasicAuthUser = ""
# # Basic auth password
BasicAuthPass = ""
# # timeout settings, unit: ms
Timeout = 30000
DialTimeout = 3000
MaxIdleConnsPerHost = 100

# 自愈模块配置
[Ibex]
Address = "http://ibex:10090"
# basic auth
BasicAuthUser = "ibex"
BasicAuthPass = "ibex"
# unit: ms
Timeout = 3000

# TargetMetrics
[TargetMetrics]
TargetUp = '''max(max_over_time(target_up{ident=~"(%s)"}[%dm])) by (ident)'''
LoadPerCore = '''max(max_over_time(system_load_norm_1{ident=~"(%s)"}[%dm])) by (ident)'''
MemUtil = '''100-max(max_over_time(mem_available_percent{ident=~"(%s)"}[%dm])) by (ident)'''
DiskUtil = '''max(max_over_time(disk_used_percent{ident=~"(%s)", path="/"}[%dm])) by (ident)''' 
```

###### **alert\_cur\_event.go**

警报当前事件源码：/src/models/alert\_cur\_event.go；通过源码字段信息，可根据实际需求，定制化告警模板内容。

```
type AlertCurEvent struct {
 Id                 int64             `json:"id" gorm:"primaryKey"`                                          告警事件ID 【告警管理】→【历史告   
 Cate               string            `json:"cate"`                                                          数据源类型
 Cluster            string            `json:"cluster"`                                                       所属集群名称
 GroupId            int64             `json:"group_id"`   
 GroupName          string            `json:"group_name"` 
 Hash               string            `json:"hash"`       
 RuleId             int64             `json:"rule_id"`                                                       告警规则ID
 RuleName           string            `json:"rule_name"`                                                     告警规则名称
 RuleNote           string            `json:"rule_note"`                                                     告警规则备注
 RuleProd           string            `json:"rule_prod"`                                                     规则产品
 RuleAlgo           string            `json:"rule_algo"`                                                     规则算法
 Severity           int               `json:"severity"`                                                      告警级别1、2、3
 PromForDuration    int               `json:"prom_for_duration"`                                             持续时间
 PromQl             string            `json:"prom_ql"`                                                       告警规则PromQl
 PromEvalInterval   int               `json:"prom_eval_interval"`                                            执行频率
 Callbacks          string            `json:"-"`                  
 CallbacksJSON      []string          `json:"callbacks" gorm:"-"` 
 RunbookUrl         string            `json:"runbook_url"`                                                   回调地址
 NotifyRecovered    int               `json:"notify_recovered"`                                              启用恢复通知
 NotifyChannels     string            `json:"-"`                          
 NotifyChannelsJSON []string          `json:"notify_channels" gorm:"-"`   
 NotifyGroups       string            `json:"-"`                          
 NotifyGroupsJSON   []string          `json:"notify_groups" gorm:"-"`     
 NotifyGroupsObj    []*UserGroup      `json:"notify_groups_obj" gorm:"-"` 
 TargetIdent        string            `json:"target_ident"`                                                  目标标识,即告警服务器配置的Ident
 TargetNote         string            `json:"target_note"`                                                   目标备注，即告警服务器配置的备注
 TriggerTime        int64             `json:"trigger_time"`                                                  触发时间
 TriggerValue       string            `json:"trigger_value"`                                                 触发时值
 Tags               string            `json:"-"`                         
 TagsJSON           []string          `json:"tags" gorm:"-"`             
 TagsMap            map[string]string `json:"-" gorm:"-"`                
 IsRecovered        bool              `json:"is_recovered" gorm:"-"`     
 NotifyUsersObj     []*User           `json:"notify_users_obj" gorm:"-"` 
 LastEvalTime       int64             `json:"last_eval_time" gorm:"-"`   
 LastSentTime       int64             `json:"last_sent_time" gorm:"-"`   
 NotifyCurNumber    int               `json:"notify_cur_number"`         
 FirstTriggerTime   int64             `json:"first_trigger_time"`        
} 
```

##### **Prometheus**

prometheus.yaml 一个默认的prometheus配置文件，此次不做详解。

##### **Ibex**

###### **服务端配置**

etc/server.conf 服务端配置

```
# 运行方式选择
# debug, release
RunMode = "release"

# 日志配置
[Log]
# log write dir
Dir = "logs-server"
# log level: DEBUG INFO WARNING ERROR
Level = "DEBUG"
# stdout, stderr, file
Output = "stdout"
# # rotate by time
# KeepHours: 4
# # rotate by size
# RotateNum = 3
# # unit: MB
# RotateSize = 256

# http配置
[HTTP]
Enable = true
# http listening address
Host = "0.0.0.0"
# http listening port
Port = 10090
# https cert file path
CertFile = ""
# https key file path
KeyFile = ""
# whether print access log
PrintAccessLog = true
# whether enable pprof
PProf = false
# http graceful shutdown timeout, unit: s
ShutdownTimeout = 30
# max content length: 64M
MaxContentLength = 67108864
# http server read timeout, unit: s
ReadTimeout = 20
# http server write timeout, unit: s
WriteTimeout = 40
# http server idle timeout, unit: s
IdleTimeout = 120

# 基础认证，用于api调用，默认ibex，建议更改
[BasicAuth]
# using when call apis
ibex = "ibex"

# RPC协议监听
[RPC]
Listen = "0.0.0.0:20090"

# 心跳配置
[Heartbeat]
# auto detect if blank
IP = ""
# unit: ms
Interval = 1000

# 输出 默认databases
[Output]
# database | remote
ComeFrom = "database"
AgtdPort = 2090

# 对象关联映射配置，指定模式、数据库类型、最大连接数等
[Gorm]
# enable debug mode or not
Debug = false
# mysql postgres
DBType = "mysql"
# unit: s
MaxLifetime = 7200
# max open connections
MaxOpenConns = 150
# max idle connections
MaxIdleConns = 50
# table prefix
TablePrefix = ""

# mysql连接配置
[MySQL]
# mysql address host:port
Address = "mysql:3306"
# mysql username
User = "root"
# mysql password
Password = "数据库密码@tcp"
# database name
DBName = "ibex"
# connection params
Parameters = "charset=utf8mb4&parseTime=True&loc=Local&allowNativePasswords=true"

# 如果Gorm中dbtype=postgres,则配置postgres库连接信息
[Postgres]
## pg address host:port
#Address = "postgres:5432"
## pg user
#User = "root"
## pg password
#Password = "1234"
## database name
#DBName = "ibex"
## ssl mode
#SSLMode = "disable" 
```

###### **客户端配置**

etc/agentd.conf 客户端配置

```
# 运行方式选择
# debug, release
RunMode = "release"

# 存储目录
# task meta storage dir
MetaDir = "./meta"

# http配置
[HTTP]
Enable = true
# http listening address
Host = "0.0.0.0"
# http listening port
Port = 2090
# https cert file path
CertFile = ""
# https key file path
KeyFile = ""
# whether print access log
PrintAccessLog = true
# whether enable pprof
PProf = false
# http graceful shutdown timeout, unit: s
ShutdownTimeout = 30
# max content length: 64M
MaxContentLength = 67108864
# http server read timeout, unit: s
ReadTimeout = 20
# http server write timeout, unit: s
WriteTimeout = 40
# http server idle timeout, unit: s
IdleTimeout = 120

# 心跳配置
## Interval 是心跳频率，默认是 1000 毫秒，如果机器量比较小，比如小于 1000 台，维持 1000 毫秒没问题，如果机器量比较大，可以适当调大这个频率，比如 2000 或者 3000，可以减轻服务端的压力
## Servers 是个数组，配置的是 ibex-server 的地址，ibex-server 可以启动多个，多个地址都配置到这里即可，Host 这个字段，是本机的唯一标识，有三种配置方式，如果配置为 $ip，系统会自动探测本机的 IP，如果是 $hostname，系统会自动探测本机的 hostname，如果是其他字符串，那就直接把该字符串作为本机的唯一标识。每个机器上都要部署 ibex-agentd，不同的机器要保证 Host 字段获取的内容不能重复
[Heartbeat]
# unit: ms
Interval = 1000
# rpc servers
Servers = ["ibex:20090"]
# $ip or $hostname or specified string
#Host = "test"
Host = $ip
#Host = $hostname 
```

###### **监控对象**

夜莺的监控对象及所监控的主机

![](https://developer.qcloudimg.com/http-save/yehe-7754373/595164850b282a1fbf6cdf1353a4fa7e.png)

###### **监控看图**

监控看图包含：夜莺监控大盘、pormql即时查询、自定义快捷视图。

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/edf154d2-85a3-4e32-a84d-43b7b080cf98.png?raw=true)

*   `即时查询`:用于快速定位排查，以及监控指标验等；
*   `快捷视图`:用于自定义快速查询指定监控主机的所有监控项结果；
*   `监控大盘`:自定义大盘，指定展示监控项结果。夜莺带有基本的内置大盘，可直接导入使用，也可自定义编辑，支持JSON、Grafana大盘JSON直接导入使用，也可图形化编辑。

###### **mysql监控大盘**

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/0d3a520d-7d59-43ca-8a47-f51c88b95229.png?raw=true)

###### **linux监控大盘**

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/53d50cbb-e960-4ab4-aab3-50969ee2aef5.png?raw=true)

##### **监控项**

###### **相关配置**

监控项为categraf插件配置控制，categraf采集插件说明：

采集插件的代码，在代码的inputs目录，每个插件一个独立的目录，目录下是采集代码，以及相关的监控大盘JSON（如有）和告警规则JSON（如有），Linux相关的大盘和告警规则没有散在 cpu、mem、disk等采集器目录，而是一并放到了 system 目录下，方便使用。

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/066f0545-db75-45d6-9843-241e1b6cb5ff.png?raw=true)

插件的配置文件，放在categraf/conf目录，以input.打头，每个配置文件都有详尽的注释，如果整不明白，就直接去看inputs目录下的对应采集器的代码，Go的代码非常易读，比如某个配置不知道是做什么的，去采集器代码里搜索相关配置项，很容易就可以找到答案。

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/5f365290-5150-41fc-9b86-482afb9a1b72.png?raw=true)

对于每个采集器的配置，不在这里一一赘述，只讲一些相对通用的配置项。

`interval`:每个插件的配置中，一开始通常都是 interval 配置，表示采集频率，如果这个配置注释掉了，就会复用 config.toml 中的采集频率，这个配置如果配置成数字，单位就是秒，如果配置成字符串，就要给出单位，比如：

```
interval = 60
interval = "60s"
interval = "1m" 
```

上面三种写法，都表示采集频率是1分钟，如果是使用字符串，可以使用的单位有：

*   秒：s
*   分钟：m
*   小时：h

`instances`:很多采集插件的配置中，都有 instances 配置段，用`[[]]` 包住，说明是数组，即，可以出现多个 `[[instances]]` 配置段，比如 ping 监控的采集插件，想对4个IP做PING探测，可以按照下面的方式来配置：

```
[[instances]]
targets = [
    "www.baidu.com",
    "127.0.0.1",
    "10.4.5.6",
    "10.4.5.7"
] 
```

也可以下面这样子配置：

```
[[instances]]
targets = [
    "www.baidu.com",
    "127.0.0.1"
]

[[instances]]
targets = [
    "10.4.5.6",
    "10.4.5.7"
] 
```

`interval_times`:instances 下面如果有 interval\_times 配置，表示 interval 的倍数，比如ping监控，有些地址采集频率是15秒，有些可能想采集的别太频繁，比如30秒，那就可以把interval配置成15，把不需要频繁采集的那些instances的interval\_times配置成2;或者：把interval配置成5，需要15秒采集一次的那些instances的interval\_times配置成3，需要30秒采集一次的那些instances的interval\_times配置成6

`labels`:instances 下面的 labels 和 config.toml 中的 global.labels 的作用类似，只是生效范围不同，都是为时序数据附加标签，instances 下面的 labels 是附到对应的实例上，global.labels 是附到所有时序数据上。

###### **页面展示**

配置项在夜莺webapi的快捷视图里面可以直观查看：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/958b2025-ae77-4a92-acd2-5e264427ca8a.png?raw=true)

监控指标对应的注释，在夜莺服务端etc/conf/metrics.yaml文件中配置

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/c986a569-ce30-4ccf-8443-8e57146d1e66.png?raw=true)

###### **非默认常用监控项**

###### **mysql**

mysql监控采集插件，核心原理就是连到 mysql实例，执行一些 sql，解析输出内容，整理为监控数据上报。配置文件如下：

*   路径：/conf/input.mysql/mysql.toml

mysql.go 采集插件及配置介绍

```
# mysql
## Configuration
# # collect interval
# interval = 15
# 要监控 MySQL，首先要给出要监控的MySQL的连接地址、用户名、密码
[[instances]]
address = "127.0.0.1:3306"
username = "root"
password = "1234"

# 为mysql实例附一个instance的标签，因为通过address=127.0.0.1:3306不好区分
# important! use global unique string to specify instance
labels = { instance="n9e-10.2.3.4:3306" }

# # set tls=custom to enable tls
# parameters = "tls=false"

# 通过 show global status监控mysql，默认抓取一些基础指标，
# 如果想抓取更多global status的指标，把下面的配置设置为true
extra_status_metrics = true

# 通过show global variables监控mysql的全局变量，默认抓取一些常规的
# 常规的基本够用了，扩展的部分，默认不采集，下面的配置设置为false
extra_innodb_metrics = false

# 监控processlist，关注较少，默认不采集
gather_processlist_processes_by_state = false
gather_processlist_processes_by_user = false

# 监控各个数据库的磁盘占用大小
gather_schema_size = false

# 监控所有的table的磁盘占用大小
gather_table_size = false

# 是否采集系统表的大小，通过不用，所以默认设置为false
gather_system_table_size = false

# 通过 show slave status监控slave的情况，比较关键，所以默认采集
gather_slave_status = true

# # timeout
# timeout_seconds = 3

# # interval = global.interval * interval_times
# interval_times = 1

# TLS配置
## Optional TLS Config
# use_tls = false
# tls_min_version = "1.2"
# tls_ca = "/etc/categraf/ca.pem"
# tls_cert = "/etc/categraf/cert.pem"
# tls_key = "/etc/categraf/key.pem"
## Use TLS but skip chain & host verification
# insecure_skip_verify = true

# 自定义SQL，指定SQL、返回的各个列那些是作为metric，哪些是作为label
# [[instances.queries]]
# mesurement = "users"
# metric_fields = [ "total" ]
# label_fields = [ "service" ]
# # field_to_append = ""
# timeout = "3s"
# request = '''
# select 'n9e' as service, count(*) as total from n9e_v5.users

## 监控多个实例
`[[instances]]`部分表示数组，是可以出现多个的，所以，举例：

[[instances]]
address = "10.2.3.6:3306"
username = "root"
password = "1234"
labels = { instance="n9e-10.2.3.6:3306" }

[[instances]]
address = "10.2.6.9:3306"
username = "root"
password = "1234"
labels = { instance="zbx-10.2.6.9:3306" } 
```

categraf/conf/input.mysql/mysql.toml配置

```
[[instances]]
address = "127.0.0.1:3306"
username = "root"
password = "数据库密码"
labels = { instance="xxx数据库" }

# # set tls=custom to enable tls
# # parameters = "tls=false"

extra_status_metrics = true
extra_innodb_metrics = true
gather_processlist_processes_by_state = false
gather_processlist_processes_by_user = false
gather_schema_size = false
gather_table_size = false
gather_system_table_size = false
gather_slave_status = true

#[[instances.queries]]
# mesurement = "lock_wait"
# metric_fields = [ "total" ]
# timeout = "3s"
# request = '''
#SELECT count(*) as total FROM information_schema.innodb_trx WHERE trx_state='LOCK WAIT'
#'''

# [[instances.queries]]
# mesurement = "users"
# metric_fields = [ "total" ]
# label_fields = [ "service" ]
# # field_to_append = ""
# timeout = "3s"
# request = '''
# select 'n9e' as service, count(*) as total from n9e_v5.users
# ''' 
```

###### **自定义脚本**

exec.go 采集插件及配置介绍

*   采集插件exec.go

该插件用于给用户自定义监控脚本，监控脚本采集到监控数据之后通过相应的格式输出到stdout，categraf截获stdout内容，解析之后传给服务端，脚本的输出格式支持3种：influx、falcon、prometheus。

```
# exec
## influx

influx 格式的内容规范：

mesurement,labelkey1=labelval1,labelkey2=labelval2 field1=1.2,field2=2.3

- 首先mesurement，表示一个类别的监控指标，比如 connections；
- mesurement后面是逗号，逗号后面是标签，如果没有标签，则mesurement后面不需要逗号
- 标签是k=v的格式，多个标签用逗号分隔，比如region=beijing,env=test
- 标签后面是空格
- 空格后面是属性字段，多个属性字段用逗号分隔
- 属性字段是字段名=值的格式，在categraf里值只能是数字

最终，mesurement和各个属性字段名称拼接成metric名字

## falcon

Open-Falcon的格式如下，举例：
[
    {
        "endpoint": "test-endpoint",
        "metric": "test-metric",
        "timestamp": 1658490609,
        "step": 60,
        "value": 1,
        "counterType": "GAUGE",
        "tags": "idc=lg,loc=beijing",
    },
    {
        "endpoint": "test-endpoint",
        "metric": "test-metric2",
        "timestamp": 1658490609,
        "step": 60,
        "value": 2,
        "counterType": "GAUGE",
        "tags": "idc=lg,loc=beijing",
    }
]
timestamp、step、counterType，这三个字段在categraf处理的时候会直接忽略掉，endpoint会放到labels里上报。

## prometheus

prometheus 格式大家不陌生了，比如我这里准备一个监控脚本，输出 prometheus 的格式数据：

#!/bin/sh

echo '# HELP demo_http_requests_total Total number of http api requests'
echo '# TYPE demo_http_requests_total counter'
echo 'demo_http_requests_total{api="add_product"} 4633433'

其中 `#` 注释的部分，其实会被 categraf 忽略，不要也罢，prometheus 协议的数据具体的格式，请大家参考 prometheus 官方文档 
```

categraf/conf/input.exec/exec.toml配置

```
## 收集间隔时间s
# # collect interval
# interval = 15

[[instances]]
# # commands, support glob
commands = [
# 指定脚本位置
#     "/opt/categraf/scripts/*.sh"
"/categraf/categraf-v0.2.22-linux-amd64/sh/*.sh"
]

## 每个命令完成的超时时间
# # timeout for each command to complete
 timeout = 5

## 间隔时间s
# # interval = global.interval * interval_times
 interval_times = 1

## influx 输出格式
# # mesurement,labelkey1=labelval1,labelkey2=labelval2 field1=1.2,field2=2.3
 data_format = "influx" 
```

###### **influx 输出格式脚本示列**

监控指标名生成方式为：mesurement\_field ，该脚本为查看centos服务器当前登录用户数，监控指标名为exec\_who\_whosum：

```
 whosum=`who |wc -l`
echo "exec_who,remark=当前登录用户总数 whosum=$whosum" 
```

图示：

![](https://developer.qcloudimg.com/http-save/yehe-7754373/0324120c4022c068dcb631fc65f8a2ad.png)

###### **关于采集kubectl top命令中相关值（获取pod所占用的资源）**

目前查阅到的信息来看，想获取当前pod运行的所消耗的资源，官方推荐采集器 kube-state-metrics（截止2.9.2）中没有该监控项。而可以获取值的 metrics-server没找到有采集器可以去采集其中的资源。

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/80233998-878c-4d8c-8d53-422560990c43.png?raw=true)

基于所有监控即是调用底层命令采集数据。使用该脚本在服categraf上做自定义采集。以pod为例.

```
#bin/sh
> /categraf/categraf-v0.2.22-linux-amd64/kubetop/result.txt
#######################
#     POD采集
#######################

#获取所有namespace
kubens=$(kubectl get namespace | awk 'NR>2{print line}{line=$1} END{print $1}')
#将namespace定义为一个数组
kubennslist=($kubens)
#循环遍历通过namespace获取pod运行时的数据
for ns in "${kubennslist[@]}"
do
#获取container名称
   con=$(kubectl top pod -n $ns  | awk 'NR>2{print line}{line=$1} END{print $1}')
#获取cpu使用量(m)
  cpu=$(kubectl top pod -n $ns  | awk 'NR>2{print line}{line=$2} END{print $2}')
#获取内存使用量（Mi）
  memo=$(kubectl top pod -n $ns  | awk 'NR>2{print line}{line=$3} END{print $3}')
#将取到的值加入数组循环
   listcon=($con)
   listcpu=($cpu)
   listmemo=($memo)
#循环输出每一条记录
    for ((i=0; i<${#listcon[@]}; i++)); do
#取消值后1位，使其变成一个值
      cpuvalue=${listcpu[$i]::-1}
#取消值后2位，使其变成一个值
      memovalue=${listmemo[$i]::-2}
#将结果输出到一个文件中，直接执行在没有pod的命名空间下，会强制输出：No resources found in xxxxx namespace
      echo "kubectl_top_pod,namespace=$ns,container=${listcon[$i]} cpu=$cpuvalue,memory=$memovalue" >> /categraf/categraf-v0.2.22-linux-amd64/kubetop/result.txt
    done
done
#在categraf采集器脚本中直接每一段去读取一行，输出到Prometheus

#######################
#     NODE采集
#######################
#获取node名称
  node=$(kubectl top node | awk 'NR>2{print line}{line=$1} END{print $1}')
#获取cpu使用量 
 cpu=$(kubectl top node  | awk 'NR>2{print line}{line=$2} END{print $2}')
#获取cpu使用率
  cpubfb=$(kubectl top node  | awk 'NR>2{print line}{line=$3} END{print $3}')
#获取内存使用量
  memo=$(kubectl top node  | awk 'NR>2{print line}{line=$4} END{print $4}')
#获取内存使用率
  memobfb=$(kubectl top node  | awk 'NR>2{print line}{line=$5} END{print $5}')
#加入数组
   listnode=($node)
   listcpu=($cpu)
   listcpubfb=($cpubfb)
   listmemo=($memo)
   listmemobfb=($memobfb)
    for ((i=0; i<${#listnode[@]}; i++)); do
#取消输出的单位
      cpuvalue=${listcpu[$i]::-1}
      cpubfbvalus=${listcpubfb[$i]::-1}
      memovalue=${listmemo[$i]::-2}
      memobfbvalue=${listmemobfb[$i]::-1}
      echo "kubectl_top_node,node=${listnode[$i]} cpu=$cpuvalue,cpubfb=$cpubfbvalus,memory=$memovalue,memobfb=$memobfbvalue" >> /categraf/categraf-v0.2.22-linux-amd64/kubetop/result.txt
    done 
```

```
 while read line
do
    echo $line
done < /categraf/categraf-v0.2.22-linux-amd64/kubetop/result.txt 
```

效果图：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/b4e3a236-064a-4531-8e42-13945da49c45.png?raw=true)

### **告警**

##### **告警规则**

告警规则支持可视化配置，菜单如下：`[告警管理]`→`[告警规则]`

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/c4eb9e5b-f145-4122-b1c6-3f2e526aa48b.png?raw=true)

菜单所需填写项很明确，以客户端连接情况监控为列，配置如下：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/ad98619c-0b86-4ad1-a221-9d619c065b20.png?raw=true)

##### **屏蔽规则**

在实际应用中，对于一些监控项，并不适用所有监控主机告警，所以应根据实际情况配置屏蔽规则 屏蔽规则：根据告警事件的标签匹配屏蔽。在`[历史告警]`菜单中，可以直观的看到监控项通过告警规则后生成告警所带的标签（该标签自主可配，主机lable、告警规则lable等）。

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/5e5b5eca-036f-47f2-8ad9-61647b3b5411.png?raw=true)

示列：屏蔽ident=xxxx.xxx.xxx.xxx且告警规则名为"硬盘-IO有点繁忙，请关注"的相关告警。

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/3b1b6442-d67f-4a84-8ca7-8e2edd6bb943.png?raw=true)

##### **接入钉钉告警通知**

###### **钉钉告警流程图**

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/eacd1a2a-f70f-4f0d-b021-7e047307a0dc.png?raw=true)

###### **接入钉钉告警配置**

*   钉钉添加机器人，获取机器人webhook地址（不赘述）；
*   夜莺webapi(`[人员组织]`→`[用户管理]`→`[创建用户]`)新建告警用户，添加用户联系方式，如图：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/091a7da3-fcff-4f5a-89a6-688995571368.png?raw=true)

添加用户联系方式为dingtalk,并填入2.1获取到的webhook地址

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/75a3c19b-0993-44dc-8206-2f662d9374d3.png?raw=true)

###### **新建告警团队，并将告警用户加入团队**

`[人员组织]`→`[团队管理]`→`[新建团队]`

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/93fb8d46-47ec-4858-97e9-dcb6e917a05a.png?raw=true)

将告警用户加入告警团队

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/d80ed720-31c8-417d-b115-fca691991f0b.png?raw=true)

###### **告警规则添加告警团队**

`[告警管理]`→`[告警规则]`→`[编辑]`

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/a1a15b9f-d46f-4da9-a484-21c274931f42.png?raw=true)

##### **通知模板自定义**

夜莺配了默认的钉钉消息模板，模板路径：etc/template/dingtalk.tpl ，基本上能够明确告警信息，模板为markdown语法编写，内容如下：

```
#### {{if .IsRecovered}}<font color="#008800">S{{.Severity}} - Recovered - {{.RuleName}}</font>{{else}}<font color="#FF0000">S{{.Severity}} - Triggered - {{.RuleName}}</font>{{end}}

---

- **规则标题**: {{.RuleName}}{{if .RuleNote}}
- **规则备注**: {{.RuleNote}}{{end}}
- **监控指标**: {{.TagsJSON}}
- {{if .IsRecovered}}**恢复时间**：{{timeformat .LastEvalTime}}{{else}}**触发时间**: {{timeformat .TriggerTime}}
- **触发时值**: {{.TriggerValue}}{{end}}
- **发送时间**: {{timestamp}} 
```

如需根据业务自定义模板，建议仔细阅读本文档【安装配置】- 【服务端】-【配置】-【alert\_cur\_event.go】，添加所需要告警的字段到dingtalk.tpl。

ps：了解告警配置，掌握基本markdown语法，该模板随意编写。这里我自定义了一个模板，如下：

```
## {{if .IsRecovered}}<font color="#008800">【恢复】：&#x1F449;{{.RuleName}}&#x1F448; 已恢复正常！</font>{{else}}<font color="#FF0000">【故障】：{{.RuleName}}</font>{{end}}

---
>- **告警标题**: {{.RuleName}}{{if .RuleNote}}
>- **告警备注**: {{.RuleNote}}{{end}}
>- **告警级别**: {{.Severity}}
---
>- **告警设备**: {{.TargetIdent}}
>- **设备所属**: {{.GroupName}}
---
>- **监控指标**: {{.PromQl}}
>- **告警说明**: {{.TagsJSON}}
---
>- {{if .IsRecovered}}**恢复时间**：{{timeformat .LastEvalTime}}
>- **恢复时值**: {{.TriggerValue}}{{else}}**触发时间**: {{timeformat .TriggerTime}}
>- **触发时值**: {{.TriggerValue}}
>- **持续时间**: {{.PromForDuration}}{{end}}
---
>- **发送时间**: {{timestamp}}
---
- **详情请戳**&#x1F449;：[**告警规则**](http://IP:18000/alert-rules/edit/{{.RuleId}})    [**告警详情**](http://IP:18000/alert-his-events/{{.Id}}) 
```

效果如下：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/b4f1b4e1-7a85-4967-8571-66b3a4d875d8.png?raw=true)

### **接入多个Prometheus集群**

由于Prometheus没有集群版本，受限于容量问题，很多公司会搭建多套Prometheus，比如按照业务拆分，不同的业务使用不同的Prometheus集群，或者按照地域拆分，不同的地域使用不同的Prometheus集群。这里是以Prometheus来举例，VictoriaMetrics、M3DB都有集群版本，不过有时为了不相互干扰和地域网络问题，也会拆成多个集群。对于多集群的协同，需要在夜莺里做一些配置，回顾一下夜莺的架构图：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/f17a1cb6-2866-4a6a-821e-e96213e37d87.png?raw=true)

*   ❗ 图上分了3个地区每个地区一套时序库，每个地区一套 n9e-server，n9e-server 依赖 redis，所以每个地区一个 redis，n9e-webapi和mysql放到中心，n9e-webapi也依赖一个 redis，所以中心端放置的是n9e-webapi、redis、mysql，如果想图省事，redis也是可以复用的，各个地区的n9e-server 都连接中心的redis也是可以的。
*   ❗ 为了高可用，各个地区的n9e-server 可以多部署几个实例组成一个集群，集群中的所有n9e-server 的配置文件server.conf中的ClusterName要设置成一样的字符串。
*   ❗ 假设，我们有两个时序库，在重庆搭建了一个 Prometheus，在阿里云搭建了一个Prometheus，n9e-webapi 会把这两个时序库作为数据源，所以在服务端n9e-webapi 的配置文件中，要配置上这俩存储的地址，举例：

```
# 重庆Prometheus集群数据源配置
[[Clusters]]
# cluster name
Name = "Prom-chongqing"
# Prometheus APIs base url
Prom = "http://重庆Prometheus-api-ip:9090"
# Basic auth username
BasicAuthUser = ""
# Basic auth password
BasicAuthPass = ""
# timeout settings, unit: ms
Timeout = 30000
DialTimeout = 10000
TLSHandshakeTimeout = 30000
ExpectContinueTimeout = 1000
IdleConnTimeout = 90000
# time duration, unit: ms
KeepAlive = 30000
MaxConnsPerHost = 0
MaxIdleConns = 100
MaxIdleConnsPerHost = 100

# 阿里云Prometheus集群数据源配置
[[Clusters]]
# cluster name
Name = "Prom-chongqing"
# Prometheus APIs base url
Prom = "http://阿里云Prometheus-api-ip:9090"
# Basic auth username
BasicAuthUser = ""
# Basic auth password
BasicAuthPass = ""
# timeout settings, unit: ms
Timeout = 30000
DialTimeout = 10000
TLSHandshakeTimeout = 30000
ExpectContinueTimeout = 1000
IdleConnTimeout = 90000
# time duration, unit: ms
KeepAlive = 30000
MaxConnsPerHost = 0
MaxIdleConns = 100
MaxIdleConnsPerHost = 100 
```

*   ❗ 另外从架构图上也可以看出，一个n9e-server对应一个时序库，所以在n9e-server的配置文件中，也需要配置对应的时序库的地址，比如重庆的server，配置如下，Writers 下面的 Url 配置的是远程写入的地址，而 Reader 下面配置的 Url 是实现Prometheus 原生查询接口的 BaseUrl。

配置详情可查看本文档【安装配置】-【配置】-【Nightingale】-【server.conf】【webapi.conf】

```
[Reader]
# prometheus base url
Url = "http://重庆-prometheus-base-ip:9090"
# Basic auth username
BasicAuthUser = ""
# Basic auth password
BasicAuthPass = ""
# timeout settings, unit: ms
Timeout = 30000
DialTimeout = 3000
MaxIdleConnsPerHost = 100

[WriterOpt]
# queue channel count
QueueCount = 1000
# queue max size
QueueMaxSize = 1000000
# once pop samples number from queue
QueuePopSize = 1000
# metric or ident
ShardingKey = "ident"

[[Writers]]
Url = "http://重庆-prometheus-api-ip:9090/api/v1/write"
# Basic auth username
BasicAuthUser = ""
# Basic auth password
BasicAuthPass = ""
# timeout settings, unit: ms
Timeout = 10000
DialTimeout = 3000
TLSHandshakeTimeout = 30000
ExpectContinueTimeout = 1000
IdleConnTimeout = 90000
# time duration, unit: ms
KeepAlive = 30000
MaxConnsPerHost = 0
MaxIdleConns = 100
MaxIdleConnsPerHost = 100 
```

##### **注意事项**

n9e-webapi 是要响应前端 ajax 请求的，前端会从 n9e-webapi 查询监控数据，n9e-webapi自身不存储监控数据，而是仅仅做了一个代理，把请求代理给后端的时序库，前端读取数据时会调用 Prometheus 的那些原生接口，即：`/api/v1/query/api/v1/query_range/api/v1/labels` 这种接口，所以注意，n9e-webapi 中配置的 Clusters 下面的Url，都是要支持Prometheus 原生接口的 BaseUrl。

对于 n9e-server，有两个重要作用，一个是接收监控数据，然后转发给后端多个Writer，所以Writer可以配置多个，配置文件是toml格式 ,`[[Writers]]`双中括号这种就表示数组，数据写给后端存储，走的协议是 Prometheus 的 Remote Write，所以，所有支持 Remote Write的存储，都可以使用。n9e-server 的另一个重要作用，是做告警判断，会周期性从 mysql 同步告警规则，然后根据用户配置的 PromQL 调用时序库的 query 接口，所以 n9e-server 的 Reader 下面的 Url，也是要配置支持 Prometheus 原生接口的 BaseUrl。

另外注意，Writer 可以配置多个，但是 Reader 只能配置一个。

比如监控数据可以写一份到Prometheus存储近期数据用于告警判断，再写一份到OpenTSDB存储长期数据，Writer就可以配置为Prometheus和OpenTSDB这两个，而Reader只配置Prometheus 即可。

### **分布式部署方案**

##### **中心集群部署方案**

基础环境 redis、mysql、prometheus（M3DB或VictoriaMetrics）高可用部署。假设我们有3台机器，部署方案就是在每台机器上分别部署server和webapi模块，然后在server和webapi前面分别配置[负载均衡](https://cloud.tencent.com/product/clb?from_column=20065&from=20065) server的负载均衡地址暴露给agent，agent用来推送监控数据，webapi的负载均衡地址可以配置一个域名，让终端用户通过域名访问夜莺的UI。此时，前端静态资源文件是由n9e-webapi来serve，也可以搭配一个小的nginx集群，把webapi作为nginx的upstream，前端静态资源文件由nginx来serve。

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/2ae7cc0e-cc80-42e8-8e4e-11031c0dbb71.png?raw=true)

##### **多地域拆分方案**

实际工作环境下，很多公司会把 Prometheus 拆成多个集群，按照业务线或者按照地域来拆分，此时就相当于夜莺接入多个 Prometheus 数据源。中心端部署 webapi 模块，而 server 模块是随着时序库走的，所以，时序库在哪个机器上，server 模块就部署在哪个机器上就好，架构图如下：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/08dd9bd3-50a3-46ff-b10d-35a1c0e3e00d.png?raw=true)

##### **多地域拆分集群方案**

把 server 和 webapi 模块都做集群高可用，及官方架构图：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-10-17%2010-54-25/2df495ba-aedd-40f9-8ccb-ffb7d3907dd3.png?raw=true)

中心端是 webapi 集群、redis、mysql，每个地域是时序库、redis、server集群，redis实际可以复用中心的那个，但是不推荐，担心网络链路可能不好影响通信，最好是和 server 集群放到一个地域。

### **客户端（Categraf采集器）**

Categraf 是一个来自快猫研发团队开源的监控采集Agent，类似 Telegraf、Grafana-Agent、Datadog-Agent，采用 All-in-one 的设计，不但支持指标采集，也支持日志和调用链路的数据采集。

categraf 的[代码托管](https://cloud.tencent.com/product/coding?from_column=20065&from=20065)在 github：https://github.com/flashcatcloud/categraf

##### **安装配置**

###### **安装**

*   项目地址：https://github.com/flashcatcloud/categraf
*   安装包下载地址：https://github.com/flashcatcloud/categraf/releases/

```
mkdir -p /categraf && cd /categraf
wget -c https://github.com/flashcatcloud/categraf/releases/download/v0.2.22/categraf-v0.2.22-linux-amd64.tar.gz
tar -zxvf categraf-v0.2.22-linux-amd64.tar.gz  && rm -f categraf-v0.2.22-linux-amd64.tar.gz
mv   categraf-v0.2.22-linux-amd64
```

##### **配置说明**

配置文件路径：/categraf/conf/config.toml

```
[global]
# 启动的时候是否在stdout中打印配置内容
print_configs = false

# 机器名，作为本机的唯一标识，会为时序数据自动附加一个 agent_hostname=$hostname 的标签
# hostname 配置如果为空，自动取本机的机器名
# hostname 配置如果不为空，就使用用户配置的内容作为hostname
# 用户配置的hostname字符串中，可以包含变量，目前支持两个变量，
# $hostname 和 $ip，如果字符串中出现这两个变量，就会自动替换
# $hostname 自动替换为本机机器名，$ip 自动替换为本机IP
# 建议大家使用 --test 做一下测试，看看输出的内容是否符合预期
hostname = ""

# 是否忽略主机名的标签，如果设置为true，时序数据中就不会自动附加agent_hostname=$hostname 的标签
omit_hostname = false

# 时序数据的时间戳使用ms还是s，默认是ms，是因为remote write协议使用ms作为时间戳的单位
precision = "ms"

# 全局采集频率，15秒采集一次
interval = 15

# 全局附加标签，一行一个，这些写的标签会自动附到时序数据上
[global.labels]
region = "重庆"
env = "监控服务器"

# 发给后端的时序数据，会先被扔到 categraf 内存队列里，每个采集插件一个队列
# chan_size 定义了队列最大长度
# batch 是每次从队列中取多少条，发送给后端backend
[writer_opt]
# default: 2000
batch = 2000
# channel(as queue) size
chan_size = 10000

# 后端backend配置，在toml中 [[]] 表示数组，所以可以配置多个writer
# 每个writer可以有不同的url，不同的basic auth信息
[[writers]]
url = "http://127.0.0.1:19000/prometheus/v1/write"

# Basic auth username
basic_auth_user = ""

# Basic auth password
basic_auth_pass = ""

# timeout settings, unit: ms
timeout = 5000
dial_timeout = 2500
max_idle_conns_per_host = 100 
```

##### **产品对比**

categraf 和 telegraf、exporters、grafana-agent、datadog-agent

*   telegraf 是 influxdb生态的产品，因为 influxdb 是支持字符串数据的，所以 telegraf 采集的很多 field 是字符串类型，另外 influxdb 的设计，允许 labels 是非稳态结构，比如 result\_code 标签，有时其 value 是 0，有时其 value 是 1，在 influxdb 中都可以接受。但是上面两点，在类似 prometheus 的时序库中，处理起来就很麻烦。
*   prometheus生态有各种 exporters，但是设计逻辑都是一个监控类型一个 exporter，甚至一个实例一个 exporter，生产环境可能会部署特别多的 exporters，管理起来略麻烦。
*   grafana-agent import 了大量 exporters 的代码，没有裁剪，没有优化，没有最佳实践在产品上的落地，有些中间件，仍然是一个 grafana-agent 一个目标实例，管理起来也很不方便
*   datadog-agent 确实是集大成者，但是大量代码是 python 的，整个发布包也比较大，有不少历史包袱，而且生态上是自成一派，和社区相对割裂。
*   categraf
    *   支持 remote\_write 写入协议，支持将数据写入 promethues、M3DB、VictoriaMetrics、InfluxDB;
    *   指标数据只采集数值，不采集字符串，标签维持稳态结构
    *   采用 all-in-one 的设计，所有的采集工作用一个 agent 搞定;
    *   纯Go代码编写，静态编译依赖少，容易分发，易于安装;
    *   尽可能落地最佳实践，不需要采集的数据无需采集，针对可能会对时序库造成高基数的问题在采集侧做出处理;
    *   不但提供采集能力，还要整理出监控大盘和告警规则，可以直接导入使用.

> _参考来源：https://blog.csdn.net/weixin\_47055136_ _/article/details/131289017_

