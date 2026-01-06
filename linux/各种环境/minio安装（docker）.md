
## 部署 MinIO（Docker 方式，推荐）
无论 ES 是原生还是 Docker 安装，MinIO 都推荐用 Docker 部署（无需手动解决依赖和指令集问题）。针对你之前遇到的 `x86-64-v2` 指令集错误，直接使用**兼容旧 CPU 的 MinIO 旧版本镜像**。

### 1. 安装 Docker（若未安装）
若 MinIO 服务器未安装 Docker，先执行以下命令安装：
```bash
# CentOS 系统
yum install -y docker
systemctl start docker
systemctl enable docker

# Ubuntu 系统
apt update && apt install -y docker.io
systemctl start docker
systemctl enable docker
```

### 2. 创建 MinIO 数据目录
在 MinIO 服务器创建数据持久化目录，避免容器删除后快照数据丢失：
```bash
mkdir -p /data/minio
chmod 777 /data/minio  # 简化权限，生产环境可配置更严格的权限
```

### 3. 启动 MinIO 容器（兼容旧 CPU 版本）
执行以下命令启动 MinIO，解决 `x86-64-v2` 指令集问题，同时配置访问密钥和桶：
```bash
docker run -d \
  --name minio \
  -p 9000:9000 \
  -p 9001:9001 \
  -v /data/minio:/data \
  -e "MINIO_ROOT_USER=ES_BACKUP_ACCESS_KEY" \  # 自定义 Access Key（用户名）
  -e "MINIO_ROOT_PASSWORD=ES_BACKUP_SECRET_KEY123" \  # 自定义 Secret Key（密码，需8位以上）
  -e "MINIO_REGION=cn-hangzhou" \  # 自定义区域，与 ES 仓库配置一致
  --restart unless-stopped \
  minio/minio:RELEASE.2024-03-04T21-13-21Z server /data --console-address ":9001"
```
- 若 MinIO 与 ES 不在同一服务器，需开放 9000/9001 端口（防火墙/安全组）；
- 若为 ARM 架构服务器，将镜像替换为 `minio/minio:RELEASE.2024-03-04T21-13-21Z-arm64`。

### 4. 配置 MinIO 快照桶
1. 访问 MinIO 控制台：`http://MinIO服务器IP:9001`，使用上述 `MINIO_ROOT_USER` 和 `MINIO_ROOT_PASSWORD` 登录。
2. 点击**创建桶**，输入桶名（如 `es-snapshot-bucket`），保持默认配置并点击**创建**（桶名需唯一，小写）。
3. （可选）配置桶权限：若需限制 ES 访问，可在桶的**权限**中添加读写策略，生产环境建议开启。