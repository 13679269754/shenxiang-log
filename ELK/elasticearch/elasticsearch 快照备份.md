
## 说明

1. 备份方式：elasticsearch快照
2. 快照仓库：s3（minio）
3. 备份流程
   * hty-es-cluster 快照备份到10.159.65.137(数据库备份服务器）的bucket(hty-es-snapshot-bucket--整个备份的线上bucket名字不变)中
   * 将备份同步到idc环境中的备份服务器172.30.2.226 的minio中
   * 从172.30.2.226的minio 同步 归档服务器 172.29.28.7 上的minio (待服务器迁移完成)

## 一、minio安装

[[minio安装（docker）]]

## 二、原生 ES 配置对接 MinIO
### 1. 安装 ES 的 `repository-s3` 插件
原生 ES 的插件安装需通过 `elasticsearch-plugin` 命令，该命令位于 ES 的 `bin` 目录下（需根据你的 ES 安装路径调整）。

#### （1）找到 ES 的安装路径
执行以下命令查看 ES 安装路径（以默认安装为例）：
```bash
# 查看 ES 进程的可执行文件路径
ps -ef | grep elasticsearch
# 示例输出：/usr/share/elasticsearch/bin/elasticsearch → 安装路径为 /usr/share/elasticsearch
```
常见的 ES 安装路径：
- 手动解压安装：`/opt/elasticsearch`；
- YUM/APT 安装：`/usr/share/elasticsearch`；
- 源码安装：`/usr/local/elasticsearch`。

#### （2）安装 `repository-s3` 插件
进入 ES 的 `bin` 目录，执行安装命令（**需与 ES 版本完全一致**，如 8.14.0）：
```bash
# 进入 ES bin 目录（替换为你的实际路径）
cd /usr/share/elasticsearch/bin

# 安装 repository-s3 插件
sudo -u elasticsearch ./elasticsearch-plugin install repository-s3
```
- 安装时会提示“是否继续”，输入 `y` 回车；
- 若 ES 是集群部署，**需在所有节点执行此安装命令**。

#### （3）重启 ES 服务
安装插件后必须重启 ES，使插件生效：
```bash
# 系统服务方式重启（推荐）
systemctl restart elasticsearch

# 手动启动的 ES（解压安装）
cd /opt/elasticsearch/bin
./elasticsearch -d  # 后台启动
```

### 2. 配置 ES 访问 MinIO 的凭证
ES 访问 MinIO 需配置 S3 协议的 Access Key 和 Secret Key，推荐通过 **ES keystore** 存储（安全，避免明文配置），步骤如下：

#### （1）进入 ES bin 目录
```bash
cd /usr/share/elasticsearch/bin  # 替换为你的 ES bin 路径
```

#### （2）添加凭证到 ES keystore
```bash
# 添加 MinIO 的 Access Key（即 MINIO_ROOT_USER）
sudo -u elasticsearch ./elasticsearch-keystore add s3.client.default.access_key
# 输入：ES_BACKUP_ACCESS_KEY（回车）

# 添加 MinIO 的 Secret Key（即 MINIO_ROOT_PASSWORD）
sudo -u elasticsearch ./elasticsearch-keystore add s3.client.default.secret_key
# 输入：ES_BACKUP_SECRET_KEY123（回车）
```
- 若提示 `keystore does not exist`，先执行 `./elasticsearch-keystore create` 创建 keystore；
- 生产环境需确保 `elasticsearch-keystore` 文件的权限为 `elasticsearch:elasticsearch`。

#### （3）重启 ES 服务
```bash
systemctl restart elasticsearch
```

### 3. 配置 ES 的 S3 客户端（可选，核心）
原生 ES 需通过 `elasticsearch.yml` 配置文件，指定 MinIO 的端点地址、区域等信息（关键：让 ES 识别 MinIO 而非 AWS S3）。

#### （1）编辑 ES 的 `elasticsearch.yml`
```bash
# 打开 elasticsearch.yml 配置文件（替换为你的实际路径）
vim /etc/elasticsearch/elasticsearch.yml  # YUM/APT 安装路径
# 解压安装路径：/opt/elasticsearch/config/elasticsearch.yml
```

#### （2）添加 MinIO 相关配置
在配置文件末尾添加以下内容（**需与 MinIO 配置一致**）：
```yaml
# MinIO S3 客户端配置
s3.client.default.endpoint: http://MinIO服务器IP:9000  # 替换为 MinIO 的 IP:端口（同一服务器填 127.0.0.1:9000）
s3.client.default.region: cn-hangzhou  # 与 MinIO 的 REGION 一致
s3.client.default.path_style_access: true  # 必须开启，MinIO 默认使用路径样式访问
s3.client.default.protocol: http  # 测试环境用 http，生产环境建议配置 https
```

#### （3）重启 ES 服务
```bash
systemctl restart elasticsearch
```


## 三、在原生 ES 中创建 MinIO 快照仓库
通过 ES 的 REST API 创建基于 MinIO 的 S3 快照仓库（可通过 `curl` 或 Kibana Dev Tools 执行）。

### 1. 执行仓库创建命令
```bash
curl -X PUT "http://ES服务器IP:9200/_snapshot/minio_es_backup?pretty" -H "Content-Type: application/json" -d '
{
  "type": "s3",
  "settings": {
    "bucket": "es-snapshot-bucket",  # 你在 MinIO 中创建的桶名
    "compress": true,  # 开启快照压缩
    "max_snapshot_bytes_per_sec": "50mb",  # 备份速度限制（可选）
    "max_restore_bytes_per_sec": "50mb"    # 恢复速度限制（可选）
  }
}
'

或者工具执行

PUT /_snapshot/minio_es_backup
{
  "type": "s3",
  "settings": {
    "bucket": "hty-es-snapshot-bucket",  
    "compress": true,               
    "max_snapshot_bytes_per_sec": "50mb",  
    "max_restore_bytes_per_sec": "50mb",   
    "client": "default"              
  }
}



```
- 若 ES 开启了安全认证（xpack.security.enabled=true），需在 curl 中添加用户名和密码：`-u "elastic:密码"`；
- 若 MinIO 与 ES 同一服务器，`s3.client.default.endpoint` 已配置为 `127.0.0.1:9000`，无需在仓库中重复配置。

### 2. 验证仓库创建
执行以下命令，若返回仓库配置且无报错，说明创建成功：
```bash
curl -X GET "http://ES服务器IP:9200/_snapshot/minio_es_backup?pretty"
```


## 四、执行 ES 快照备份与恢复
### 1. 创建 ES 快照（存储到 MinIO）
执行以下命令，将 ES 索引备份到 MinIO 的桶中（按时间命名快照，便于管理）：
```bash
# 备份所有索引（快照名：snapshot_20251121）
curl -X PUT "http://ES服务器IP:9200/_snapshot/minio_es_backup/snapshot_20251121?wait_for_completion=true&pretty" -H "Content-Type: application/json" -d '
{
  "indices": "*",  # 备份所有索引，可指定具体索引如 "nginx_logs,app_logs"
  "ignore_unavailable": true,  # 忽略不存在的索引
  "include_global_state": true  # 备份集群全局状态（别名、模板、ILM 策略等）
}
'
```
执行后，可在 MinIO 控制台的 `es-snapshot-bucket` 桶中看到生成的快照文件（以 `snapshot-` 开头）。

### 2. 查看快照状态
```bash
# 查看 MinIO 仓库下的所有快照
curl -X GET "http://ES服务器IP:9200/_snapshot/minio_es_backup/_all?pretty"

# 查看指定快照的详情
curl -X GET "http://ES服务器IP:9200/_snapshot/minio_es_backup/snapshot_20251121?pretty"
```

### 3. 从 MinIO 恢复快照
即使在全新的原生 ES 集群中，只需重复步骤 2-3 配置 MinIO 仓库，即可执行恢复。恢复命令如下：
```bash
# 恢复所有索引（替换为你的快照名）
curl -X POST "http://ES服务器IP:9200/_snapshot/minio_es_backup/snapshot_20251121/_restore?pretty" -H "Content-Type: application/json" -d '
{
  "indices": "*",
  "ignore_unavailable": true,
  "include_global_state": true,
  "rename_pattern": "(.+)",  # 可选：重命名索引（避免冲突）
  "rename_replacement": "restored_$1"
}
'

# 仅恢复指定索引（如 nginx_logs）
curl -X POST "http://ES服务器IP:9200/_snapshot/minio_es_backup/snapshot_20251121/_restore?pretty" -H "Content-Type: application/json" -d '
{
  "indices": "nginx_logs",
  "ignore_unavailable": true
}
'
```

### 4. 验证恢复结果
```bash
# 查看恢复的索引列表
curl -X GET "http://ES服务器IP:9200/_cat/indices?v"

# 查看索引数据
curl -X GET "http://ES服务器IP:9200/nginx_logs/_search?pretty"
```



## 五、定时备份（原生 ES 自动化）
结合 Linux 的 `crontab` 实现定时快照备份，步骤如下：

### 1. 创建备份脚本
创建 `/opt/elasticsearch/backup_es_to_minio.sh`，内容如下（替换为你的实际配置）：
```bash
#!/bin/bash
# 原生 ES 备份到 MinIO 的脚本
ES_IP="127.0.0.1"  # ES 服务器 IP（同一服务器填 127.0.0.1）
REPO_NAME="minio_es_backup"  # 快照仓库名
SNAPSHOT_NAME="snapshot_$(date +%Y%m%d_%H%M%S)"  # 按时间命名快照

# 执行备份（若 ES 开启认证，添加 -u "elastic:密码"）
curl -X PUT "http://${ES_IP}:9200/_snapshot/${REPO_NAME}/${SNAPSHOT_NAME}?wait_for_completion=true&pretty" -H "Content-Type: application/json" -d '
{
  "indices": "*",
  "ignore_unavailable": true,
  "include_global_state": true
}
'

# 可选：清理 7 天前的快照（避免 MinIO 存储满）
curl -X DELETE "http://${ES_IP}:9200/_snapshot/${REPO_NAME}/$(date -d '7 days ago' +%Y%m%d)*?pretty"
```

### 2. 添加执行权限
```bash
chmod +x /opt/elasticsearch/backup_es_to_minio.sh
```

### 3. 配置 crontab 定时任务
```bash
# 编辑 crontab 任务
crontab -e

# 添加以下内容（每天凌晨 2 点执行备份）
0 2 * * * /opt/elasticsearch/backup_es_to_minio.sh >> /opt/elasticsearch/backup_logs.log 2>&1
```
- `0 2 * * *`：每天凌晨 2 点执行；
- `>> /opt/elasticsearch/backup_logs.log 2>&1`：将备份日志输出到文件，便于排查问题。

## 六、生产环境关键注意事项
1. **权限安全**：
   - MinIO 建议配置 HTTPS（通过证书实现），避免明文传输凭证；
   - ES 的 `elasticsearch-keystore` 文件权限需设置为 `600`，仅允许 `elasticsearch` 用户访问。
2. **集群部署**：
   - ES 集群所有节点需安装 `repository-s3` 插件，并配置相同的 MinIO 凭证；
   - MinIO 建议部署分布式集群（多节点），避免单点故障。
3. **快照校验**：定期执行快照完整性校验，避免备份文件损坏：
   ```bash
   curl -X GET "http://ES服务器IP:9200/_snapshot/minio_es_backup/snapshot_20251121/_verify?pretty"
   ```
4. **存储扩容**：MinIO 的 `/data/minio` 目录建议挂载独立的磁盘/存储卷，避免磁盘满导致备份失败。
5. **防火墙/安全组**：确保 ES 服务器能访问 MinIO 的 9000 端口，MinIO 服务器仅开放必要端口给 ES。