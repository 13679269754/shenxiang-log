| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-7月-31 | 2024-7月-31  |
| ... | ... | ... |
---
# centos7 job dev-mapper-vg_data_2.device.start timeout

[toc]

## 问题 - 处理
服务器重启后出现问题如下：
![linux 启动进入emergency model](<image/linux 启动进入emergency model.png>)

1. 再次重启服务器按住Esc 查看启动进度

2. 问题出现time超时，无法挂载home.device设备
```bash
journalctl -xb

a start job is running for dev-mapper-centos\x2dhome.device
Job dev-mapper-centos\x2dhome.device/start failed with result 'timoue'
job selinux-policy-migrate-local-changes@targeted.service/start failed with result 'dependency' 
```

![Journalctl -xb log](<image/journalctl -xb log.png>)

3. 或者进入系统查看/var/log/boot.log启动日志

4. 检查启动时磁盘挂载文件/etc/fstab,多出的home.device设备注释掉即可。