| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-6月-05 | 2025-6月-05  |
| ... | ... | ... |
---
# docker 容器安装网络诊断工具

[toc]

## 方法三：在容器运行时动态安装（临时方案）

如果不想修改镜像，可以进入运行中的容器后手动安装：

进入容器 Shell
```bash
docker exec -it kafka1 /bin/bash
```

安装工具（以 Debian 为例）
```bash
apt-get update
apt-get install -y dnsutils iputils-ping telnet netcat-traditional
```

验证工具可用性
```bash
nslookup google.com
ping kafka2
telnet kafka3 9072
```