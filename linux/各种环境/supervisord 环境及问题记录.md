| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-4月-24 | 2025-4月-24  |
| ... | ... | ... |
---
# supervisord 环境及问题记录

[toc]

## 安装

```bash
# CentOS 7（需先启用 EPEL 源）
sudo yum install epel-release
sudo yum install supervisor

sudo systemctl enable --now supervisord  # 开机自启并启动服务
```

```bash
# 其他常用命令
supervisorctl reload  # 重新加载配置 Restarted supervisord
supervisorctl reread  # 重新加载配置 

supervisord -c /etc/supervisord.conf -n # 调试启动

supervisorctl status
supervisorctl start [server_name]
```

## 配置案例

**redis_sentinel**

`vim /etc/supervisord.d/redis_sentinel.ini`
```bash
[program:redis_sentinel]
command=/usr/local/data/redis/bin/redis-server /etc/redis/sentinel_26379.conf --sentinel
autostart=true
autorestart=true
startsecs=5
stdout_logfile=/var/log/redis_sentinel.log
stderr_logfile=/var/log/redis_sentinel.err.log
user=redis
```

## 报错

```bash
025-04-24 11:57:33,840 CRIT Supervisor is running as root.  Privileges were not dropped because no user is specified in the config file.  If you intend to run as root, you can set user=root in the config file to avoid this message.
2025-04-24 11:57:33,840 INFO Included extra file "/etc/supervisord.d/redis_sentinel.ini" during parsing
2025-04-24 11:57:33,861 INFO RPC interface 'supervisor' initialized
2025-04-24 11:57:33,861 CRIT Server 'unix_http_server' running without any HTTP authentication checking
2025-04-24 11:57:33,862 INFO supervisord started with pid 6685
2025-04-24 11:57:34,864 INFO spawned: 'redis_sentinel' with pid 6724
2025-04-24 11:57:34,873 INFO exited: redis_sentinel (exit status 0; not expected)
2025-04-24 11:57:35,875 INFO spawned: 'redis_sentinel' with pid 6749
2025-04-24 11:57:35,882 INFO exited: redis_sentinel (exit status 0; not expected)
2025-04-24 11:57:37,885 INFO spawned: 'redis_sentinel' with pid 6805
2025-04-24 11:57:37,892 INFO exited: redis_sentinel (exit status 0; not expected)
2025-04-24 11:57:40,896 INFO spawned: 'redis_sentinel' with pid 6881
2025-04-24 11:57:40,902 INFO exited: redis_sentinel (exit status 0; not expected)
2025-04-24 11:57:40,903 INFO gave up: redis_sentinel entered FATAL state, too many start retries too quickly

# 可以看到redis_sentinel 被启动了多次
```

**Redis Sentinel 以守护进程模式启动**  
**原因**：supervisor 启动 Redis Sentinel 后，若 Redis Sentinel 以守护进程模式启动，supervisor 会认为启动命令执行完毕并退出，从而导致 supervisor 认为进程已经退出。  

