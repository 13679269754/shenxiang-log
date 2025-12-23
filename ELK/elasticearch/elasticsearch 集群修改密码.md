在没有 `elasticsearch-reset-password` 工具的 Elasticsearch 版本（如 7.x）中，重置集群密码可以通过以下方法实现，核心思路是**直接安全索引并重新初始化**或**通过 API 重置**（需知道至少一个管理员密码）：

### 方法一：先取消用户验证，在重新添加用户

取消用户验证
```bash
#xpack.security.enabled: true
#xpack.license.self_generated.type: basic
#xpack.security.transport.ssl.enabled: true
#xpack.security.transport.ssl.verification_mode: certificate
#xpack.security.transport.ssl.client_authentication: required
#xpack.security.transport.ssl.keystore.path: certs/elastic-certificates.p12
#xpack.security.transport.ssl.truststore.path: certs/elastic-certificates.p12
```

![[elasticearch+kibana搭建#开启用户认证+配置集群间认证证书]]

**注意** : 要注意修改elasticsearch 集群启动需要时间，需要等待集群green 才应该去尝试新的密码。


### 方法二：删除安全索引并重新初始化（适用于完全忘记密码）
Elasticsearch 的用户密码存储在内部索引 `.security-7` 中，删除该索引后可重新设置所有内置用户密码。

#### 步骤：
1. **停止所有 Elasticsearch 节点**  
   确保集群完全关闭，避免操作冲突：
   ```bash
   # 在每个节点执行
   sudo systemctl stop elasticsearch
   ```

2. **删除安全索引文件（所有节点）**  
   找到 `.security-7` 索引的存储目录（通常在 `elasticsearch/data` 下），删除整个索引文件夹：
   ```bash
   # 替换为你的 ES 数据目录（在 elasticsearch.yml 中由 path.data 指定）
   sudo rm -rf /usr/local/data/elasticsearch-server/data/nodes/0/indices/.security-7*
   ```
   > 注意：此操作会清除所有用户、角色和权限配置，需重新设置。

3. **启动一个节点并重新初始化密码**  
   先启动集群中的一个节点：
   ```bash
   sudo systemctl start elasticsearch
   ```
   等待节点启动后（约 1-2 分钟），执行 `setup-passwords` 工具重新设置所有内置用户密码：
   ```bash
   cd /usr/local/data/elasticsearch-server/bin
   sudo ./elasticsearch-setup-passwords interactive
   ```
   按照提示为 `elastic`、`apm_system`、`kibana_system` 等内置用户设置新密码（推荐选择 `interactive` 交互式输入）。

4. **启动其他节点**  
   完成密码设置后，启动集群中剩余的节点，它们会自动同步新的安全配置：
   ```bash
   # 在其他节点执行
   sudo systemctl start elasticsearch
   ```


### 方法三：通过 API 重置（适用于记得至少一个管理员密码）
如果还记得某个管理员用户（如 `elastic` 或其他自定义管理员）的密码，可直接通过 API 重置其他用户密码：

#### 步骤：
1. **重置 `elastic` 用户密码**（以 `kibana_system` 用户为例）  
   使用已知密码的管理员用户认证，发送重置请求：
   ```bash
   curl -X POST "http://localhost:9200/_security/user/elastic/_password" \
     -H "Content-Type: application/json" \
     -u 已知管理员用户名:已知管理员密码 \
     -d '{
       "password": "新的elastic密码"
     }'
   ```
   成功返回 `{"acknowledged":true}`。

2. **重置其他用户密码**  
   同理，替换用户名即可重置其他用户（如 `kibana_system`）：
   ```bash
   curl -X POST "http://localhost:9200/_security/user/kibana_system/_password" \
     -H "Content-Type: application/json" \
     -u elastic:新的elastic密码 \
     -d '{
       "password": "新的kibana密码"
     }'
   ```


### 注意事项：
1. **方法一的影响**：删除 `.security-7` 会清除所有用户配置，需重新创建自定义用户和角色，适合完全失忆的场景。
2. **集群一致性**：操作前确保所有节点关闭，避免部分节点残留旧的安全数据。
3. **版本兼容性**：`elasticsearch-setup-passwords` 工具在 7.x 版本可用，仅用于首次初始化或删除安全索引后重新设置。

根据你的情况选择对应方法，重置后建议立即记录新密码，并通过 `curl -u 用户名:新密码 http://localhost:9200` 验证登录。