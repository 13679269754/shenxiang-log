
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