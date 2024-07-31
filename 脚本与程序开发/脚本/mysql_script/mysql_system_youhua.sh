#!/bin/bash

# 修改 I/O 调度器为 deadline 或 noop
echo "Which I/O scheduler do you want to use: deadline or noop?"
read scheduler
echo "$scheduler" > /sys/block/sda/queue/scheduler

# 修改 vm.swappiness 参数
echo "vm.swappiness = 5" >> /etc/sysctl.conf

# 修改 vm.dirty_background_ratio 和 vm.dirty_ratio 参数
echo "vm.dirty_background_ratio = 5" >> /etc/sysctl.conf
echo "vm.dirty_ratio = 10" >> /etc/sysctl.conf

# 修改 net.ipv4.tcp_tw_recycle 和 net.ipv4.tcp_tw_reuse 参数
echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf

# 使上述修改的内核参数立即生效
sysctl -p