| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-4月-24 | 2025-4月-24  |
| ... | ... | ... |
---
# systemctl service文件模板

[toc]

**vim /etc/systemd/system/sentinel_26379.service**  

```bash
[Unit]
Description=Advanced key-value store
After=network.target
Documentation=http://redis.io/documentation, man:redis-sentinel(1)

[Service]
Type=forking
ExecStart=/usr/local/data/redis/bin/redis-server /etc/redis/sentinel_26379.conf --sentinel
EnvironmentFile=-/etc/default/sentinel_26379
PIDFile=/var/run/redis/sentinel_26379.pid
TimeoutStopSec=0
Restart=always
User=redis
Group=redis


UMask=007
PrivateTmp=yes
LimitNOFILE=16384
PrivateDevices=yes
ProtectHome=yes
ReadOnlyDirectories=/
ReadWriteDirectories=-/var/lib/redis/sentinel_26379
ReadWriteDirectories=-/var/run/redis
CapabilityBoundingSet=~CAP_SYS_PTRACE

# redis-sentinel writes its own config file so we allow writing there (NB.
# ProtectSystem=true over ProtectSystem=full)
ProtectSystem=true
ReadWriteDirectories=-/etc/redis

[Install]
WantedBy=multi-user.target
```

`systemctl daemon-reload`  