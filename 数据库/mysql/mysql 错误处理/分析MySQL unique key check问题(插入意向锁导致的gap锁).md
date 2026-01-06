| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2024-4月-11 | 2024-4月-11 |

---
# 分析MySQL unique key check问题(插入意向锁导致的gap锁).md

[toc]

原文  
[插入意向锁导致的gap锁](https://help.aliyun.com/zh/polardb/polardb-for-mysql/resolve-the-unique-key-check-problem-in-mysql)




可以看出，在二级唯一索引插入record时，分成了两个阶段。

1. 判断当前的物理记录上是否有冲突的record（delete-marked 是不冲突）。

2. 如果没有冲突，执行插入操作。

阶段1和阶段2之间必须有锁来保证（可以是lock，也可以是latch）。否则，阶段1判断没有冲突可以执行插入操作，但在阶段1和阶段2之间另外一个事务插入了一个冲突的record，那么阶段2再插入时，会产生冲突。

所以当前的实现为：如果gap上存在至少一个相同的record，**大概率是delete-marked record。那么，需要给整个range都加上gap X lock**。加了gap X lock后，就可以禁止其他事务在这个gap区间插入数据，也就是通过lock来保证阶段1和阶段2的原子性。

如果gap上没有相同的record，那么就不需要任何gap lock。例如，一个只包含pk、sk的table。


--- 

**为什么需要给整个区间都加入gap x lock呢？** 
```已经存在的二级索引记录（1, 1）、（4, 2）、（10(delete-mark)，3）、（10(d), 8）、（10(d), 11）、（10(d), 21）和（15, 9）需要插入二级索引（10, 6），那么就需要给（10,3）、（10, 8）、（10,11）、（10,21）和（15, 9） 都加上next-key lock。```

整个区间的记录都要加上next-key lock 
因为如果只在插入记录的后一条记录加，会就导致，插入不同的记录锁住的是不同区间，可能会导致unique key约束失效。

![问题说明1](SQL/image.png)

--- 

**执行INSERT操作时，为什么要持有LOCK_GAP而不是LOCK_ORDINARY？**  
例如，原来已经存在record 1、4、10，需要插入record 6、7。

Trx抢的是record 10的lock，且record 10是next record。此时record6、7 都还未在Btree中，如果为record 10加上LOCK_ORDINARY，那么插入record 6、7 就会互相等待死锁。因此只能为record 10加LOCK_GAP。

对于有可能冲突的sk，会出现互相等待死锁的现象。

例如，如果现有record（1,1）、（4,2）、（10(delete-mark),3）、 （10(d),8）、（10(d),11）、 （10(d),21）、（15,9）。需要插入trx1:（10,6）、trx2:（10,7）。您需要在trx1插入成功后，再插入trx2。

首先，您需要给（10,3）、（10,8）、（10,11）和（10,21）加records lock。插入的位置是在（10,3）和（10,8）之间，那么在申请（10,8）的LOCK_X | LOCK_ORDINARY | insert_intention时，和已经持有的records lock互相冲突，处于死锁状态。

插入（10,6）和（10,9）也一样，需要给所有（10,x）都加records lock。插入时trx1申请（10, 8）的LOCK_ORDINARY，且持有trx2需要的（10, 11）的records lock。trx2申请（10, 11）的LOCK_X 或LOCK_ORDINARY，持有trx1想要的（10, 8）的records lock。因此也会出现死锁冲突。

--- 

**Primary key也是unique key index，为什么primary key不存在此问题？**

在secondary index中，由于MVCC的存在，当删除一个record，再在插入一个新的record时，保留delete marked record。

在primary index中，DELETE后又INSERT一个数据，会将该record delete marked标记修改为non-delete marked，然后在undo log中记录一个delete marked的record。如果查询历史版本，会通过MVCC从undo log中恢复该数据。因此，不会出现相同的delete mark record跨多个page的情况，也就不会出现上述case中（13000,100）在page1, （13000,112）在page3的情况。

Kubernetes 的三种探针探测方式（`exec`、`tcpSocket`、`httpGet`）适用于不同场景，分别通过“执行命令”“建立 TCP 连接”“发送 HTTP 请求”来判断容器状态。以下是具体实现方式和适用场景：


### 一、exec 方式：执行命令判断状态
**原理**：在容器内执行一条命令，通过命令的“退出码”判断健康状态（退出码为 `0` 表示成功，非 `0` 表示失败）。  
**适用场景**：无 HTTP 接口的服务（如数据库、脚本类应用），或需要复杂逻辑判断的场景。

#### 配置示例（检测 Nginx 配置文件是否存在）：
```yaml
livenessProbe:
  exec:
    command:  # 在容器内执行的命令（数组形式，空格分隔的命令拆分为元素）
      - test  # 命令：test -f 检查文件是否存在
      - -f
      - /etc/nginx/nginx.conf  # Nginx 配置文件路径
  initialDelaySeconds: 5       # 启动后 5 秒开始探测
  periodSeconds: 10            # 每 10 秒探测一次
  failureThreshold: 3          # 连续 3 次失败则重启容器
```

**逻辑说明**：  
- 若 `/etc/nginx/nginx.conf` 存在，`test -f` 命令退出码为 `0` → 探针成功（容器健康）。  
- 若文件不存在，退出码为非 `0` → 探针失败（多次失败后重启容器）。


### 二、tcpSocket 方式：通过 TCP 连接判断状态
**原理**：尝试与容器内的指定端口建立 TCP 连接，若连接成功则视为健康，失败则视为异常。  
**适用场景**：TCP 服务（如数据库、Redis、SSH 等），无需应用层逻辑支持。

#### 配置示例（检测 Redis 服务是否存活）：
```yaml
livenessProbe:
  tcpSocket:
    port: 6379  # Redis 监听的端口
  initialDelaySeconds: 10      # Redis 启动较慢，延迟 10 秒探测
  periodSeconds: 5             # 每 5 秒探测一次
  timeoutSeconds: 3            # 3 秒内未建立连接视为失败
```

**逻辑说明**：  
- 若容器的 6379 端口能成功建立 TCP 连接（Redis 服务正常运行）→ 探针成功。  
- 若端口未监听（如 Redis 进程崩溃）→ 连接失败 → 多次失败后重启容器。


### 三、httpGet 方式：通过 HTTP 请求判断状态
**原理**：向容器内的指定路径和端口发送 HTTP 请求，通过“响应状态码”判断健康状态（`2xx` 或 `3xx` 表示成功，`4xx` 或 `5xx` 表示失败）。  
**适用场景**：Web 服务（如 Nginx、Spring Boot 应用），需应用提供 HTTP 接口（可专用健康检查接口）。

#### 配置示例（检测 Spring Boot 应用的健康接口）：
```yaml
readinessProbe:
  httpGet:
    path: /actuator/health  # Spring Boot 健康检查接口（需开启 Actuator）
    port: 8080              # 应用监听的端口
    scheme: HTTP            # 协议（HTTP 或 HTTPS，默认 HTTP）
    # 可选：添加请求头（如认证信息）
    httpHeaders:
      - name: Authorization
        value: Bearer <token>
  initialDelaySeconds: 30    # 应用启动慢，延迟 30 秒探测
  periodSeconds: 5           # 每 5 秒探测一次
  successThreshold: 2        # 连续 2 次成功视为就绪
```

**逻辑说明**：  
- 若 `/actuator/health` 返回 `200 OK` → 探针成功（应用就绪，可接收流量）。  
- 若返回 `503 Service Unavailable`（如应用未初始化完成）→ 探针失败 → 从 Service 中移除 Pod。


### 三种方式的对比与选择建议
| 探测方式   | 核心判断依据          | 优势                          | 劣势                          | 典型适用服务                  |
|------------|-----------------------|-------------------------------|-------------------------------|-------------------------------|
| `exec`     | 命令退出码            | 支持复杂逻辑判断              | 命令执行可能消耗资源          | 数据库、脚本应用、无网络服务  |
| `tcpSocket`| TCP 连接是否建立      | 无需应用层支持，通用性强      | 只能判断端口存活，无法检测应用内部状态 | Redis、MySQL、SSH  |
| `httpGet`  | HTTP 响应状态码       | 直接反映应用服务状态          | 依赖应用提供 HTTP 接口        | Nginx、API 服务、Web 应用     |


### 总结
- 优先根据服务类型选择：Web 服务用 `httpGet`，TCP 服务用 `tcpSocket`，复杂逻辑用 `exec`。  
- 探针配置需结合应用特性：启动慢的服务（如 Java 应用）增大 `initialDelaySeconds`，高频探测的服务（如网关）减小 `periodSeconds`。  
- 生产环境中，`livenessProbe` 和 `readinessProbe` 可组合使用不同探测方式（如 `livenessProbe` 用 `tcpSocket` 检测进程存活，`readinessProbe` 用 `httpGet` 检测服务就绪）。