#!/bin/bash
# 确保脚本以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "此脚本需要root权限，请使用sudo运行" >&2
    exit 1
fi

# 检测主要块设备
block_device=""
if [ -e "/sys/block/sda" ]
then
    block_device="sda"
elif [ -e "/sys/block/nvme0n1" ]
then
    block_device="nvme0n1"
else
    echo "未找到主要块设备，无法设置I/O调度器" >&2
    exit 1
fi

# 选择I/O调度器
echo "请选择I/O调度器 (deadline/noop):  # 若设置为 noop（适合 SSD）或 deadline（适合 HDD）" 
read scheduler

if [ "$scheduler" != "deadline" ] && [ "$scheduler" != "noop" ]
then
    echo "错误：无效的调度器，只能是deadline或noop" >&2
    exit 1
fi

# 设置调度器
echo "$scheduler" > "/sys/block/$block_device/queue/scheduler"
echo "已设置$block_device的I/O调度器为$scheduler"

# 配置sysctl参数
update_sysctl() {
    local key=$1
    local value=$2
    if grep -q "^$key" /etc/sysctl.conf; then
        sed -i "s/^$key.*/$key = $value/" /etc/sysctl.conf
    else
        echo "$key = $value" >> /etc/sysctl.conf
    fi
}

update_sysctl "vm.swappiness" "0"
update_sysctl "vm.dirty_background_ratio" "5"
update_sysctl "vm.dirty_ratio" "10"
update_sysctl "net.ipv4.tcp_tw_reuse" "1"

# 生效配置
sysctl -p

echo "系统优化完成"

