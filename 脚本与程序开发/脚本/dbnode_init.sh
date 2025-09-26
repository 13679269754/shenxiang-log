#!/bin/bash

mkdir -p /root/soft

# 挂载磁盘参数
fdisk_opt=0 # 0 不挂载，1 挂载
disk='/dev/vdb' # 未挂载的磁盘
mount_dir='/usr/local/data' # 挂载路径
lv_name='data' # 磁盘虚拟卷名称



function program_exists() {
    local ret='0'
    command -v ""$"1" >/dev/null 2>&1 || { local ret='1'; }
    # fail on non-zero return value
    if [ "$ret" -ne 0 ]; then
        return 0
    fi
    return 1
}


# 修改limits.conf

echo "# 追加全用户打开最大文件数限制" >> /etc/security/limits.conf
echo "* soft nofile 655350" >> /etc/security/limits.conf
echo "* hard nofile 655350" >> /etc/security/limits.conf
echo "* soft nproc  655350" >> /etc/security/limits.conf
echo "* hard nproc  650000" >> /etc/security/limits.conf

# 修改sysctl.conf
cat << EOF >> /etc/sysctl.conf
fs.file-max = 1048576          
fs.nr_open = 10485760         
kernel.core_uses_pid = 1      
kernel.msgmax = 65536          
kernel.msgmnb = 65536          
kernel.shmall = 4294967296     
kernel.shmmax = 68719476736    
kernel.sysrq = 0              

net.core.netdev_max_backlog = 32768  
net.core.rmem_default = 262144       
net.core.rmem_max = 4194304          
net.core.wmem_default = 262144       
net.core.wmem_max = 1048576          
net.core.somaxconn = 32768           
net.ipv4.conf.all.rp_filter = 1      
net.ipv4.conf.default.rp_filter = 1
net.ipv4.ip_local_port_range = 1024 65535  
net.ipv4.tcp_fin_timeout = 20        
net.ipv4.tcp_keepalive_time = 60      
net.ipv4.tcp_keepalive_intvl = 15     
net.ipv4.tcp_keepalive_probes = 3     
net.ipv4.tcp_max_orphans = 327680     
net.ipv4.tcp_max_syn_backlog = 8192   
net.ipv4.tcp_max_tw_buckets = 600000  
net.ipv4.tcp_mem = 786432 1048576 1572864  
net.ipv4.tcp_rmem = 4096 87380 6291456  
net.ipv4.tcp_wmem = 4096 65536 4194304  
net.ipv4.tcp_syn_retries = 2          
net.ipv4.tcp_synack_retries = 2       
net.ipv4.tcp_tw_reuse = 1             
net.ipv4.tcp_tw_recycle = 0           
net.ipv4.tcp_syncookies = 1           
net.ipv4.tcp_window_scaling = 1       

vm.max_map_count = 262144    
vm.overcommit_memory = 1     
vm.swappiness = 10           
vm.dirty_ratio = 10          
vm.dirty_background_ratio = 3  

net.ipv4.conf.all.accept_source_route = 0  
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1         
net.ipv4.conf.default.log_martians = 1
EOF
sysctl -p

# # ======================
# # 系统核心参数
# # ======================
# fs.file-max = 1048576          # 系统最大打开文件数
# fs.nr_open = 10485760         # 单个进程最大打开文件数
# kernel.core_uses_pid = 1      # 核心转储包含PID
# kernel.msgmax = 65536          # 消息队列最大字节数
# kernel.msgmnb = 65536          # 消息队列默认字节数
# kernel.shmall = 4294967296     # 共享内存总量
# kernel.shmmax = 68719476736    # 单个共享内存段最大值
# kernel.sysrq = 0              # 禁用SysRq键
# 
# # ======================
# # 网络参数优化
# # ======================
# net.core.netdev_max_backlog = 32768  # 网络设备接收缓冲区
# net.core.rmem_default = 262144       # 套接字接收缓冲区默认值
# net.core.rmem_max = 4194304          # 套接字接收缓冲区最大值
# net.core.wmem_default = 262144       # 套接字发送缓冲区默认值
# net.core.wmem_max = 1048576          # 套接字发送缓冲区最大值
# net.core.somaxconn = 32768           # 监听套接字最大连接数
# 
# net.ipv4.conf.all.rp_filter = 1      # 启用反向路径过滤
# net.ipv4.conf.default.rp_filter = 1
# net.ipv4.ip_local_port_range = 1024 65535  # 本地端口范围
# net.ipv4.tcp_fin_timeout = 20        # TCP FIN-WAIT-2超时
# net.ipv4.tcp_keepalive_time = 60      # 保活探测间隔
# net.ipv4.tcp_keepalive_intvl = 15     # 保活探测间隔
# net.ipv4.tcp_keepalive_probes = 3     # 保活探测次数
# net.ipv4.tcp_max_orphans = 327680     # 最大孤儿连接数
# net.ipv4.tcp_max_syn_backlog = 8192   # SYN队列长度
# net.ipv4.tcp_max_tw_buckets = 600000  # TIME-WAIT最大数量
# net.ipv4.tcp_mem = 786432 1048576 1572864  # TCP内存策略
# net.ipv4.tcp_rmem = 4096 87380 6291456  # 接收缓冲区
# net.ipv4.tcp_wmem = 4096 65536 4194304  # 发送缓冲区
# net.ipv4.tcp_syn_retries = 2          # SYN重试次数
# net.ipv4.tcp_synack_retries = 2       # SYN-ACK重试次数
# net.ipv4.tcp_tw_reuse = 1             # 重用TIME-WAIT套接字
# net.ipv4.tcp_tw_recycle = 0           # 禁用TIME-WAIT回收
# net.ipv4.tcp_syncookies = 1           # 启用SYN Cookies
# net.ipv4.tcp_window_scaling = 1       # 启用窗口缩放
# 
# # ======================
# # 内存管理
# # ======================
# vm.max_map_count = 262144    # 进程最大虚拟内存区域数
# vm.overcommit_memory = 1     # 内存超量分配策略
# vm.swappiness = 10           # 内存交换倾向
# vm.dirty_ratio = 10          # 脏页比例阈值
# vm.dirty_background_ratio = 3  # 后台回写脏页比例
# 
# # ======================
# # 安全相关
# # ======================
# net.ipv4.conf.all.accept_source_route = 0  # 禁用源路由
# net.ipv4.conf.default.accept_source_route = 0
# net.ipv4.conf.all.log_martians = 1         # 记录异常数据包
# net.ipv4.conf.default.log_martians = 1


# swap关闭
swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab




# change passwd
#echo "dzj123,./" | passwd --stdin root

# change ssd
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

# 修改 PermitRootLogin 配置（使用 | 作为分隔符）
sed -i 's|#PermitRootLogin prohibit-password|PermitRootLogin yes|g' /etc/ssh/sshd_config

systemctl restart sshd

# yum 源配置
yum install wget -y
# 关闭epel源
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/epel.repo 
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum clean all
yum makecache

yum install -y lvm lrzsz wget curl unzip net-work telnet tcpdump iftop iotop sysstat nc htop psmisc tree net-tools bash-completion vim-enhanced epel-release setuptool screen dos2unix ntp
yum install -y zlib zlib-devel openssl openssl-devel tkinter tk-devel tcl tk 
yum install -y gcc gcc-c++ devtoolset-7-gcc devtoolset-7-gcc-c++
yum install -y bzip2-devel ncurses-devel sqlite-devel readline-devel libffi-devel 
yum install -y make cmake bison-devel ncurses-devel bison
yum remove -y python3


# install python
program_exists python3
python_exist=$?
if [[ $python_exist -eq 0 ]]; then
    wget https://www.python.org/ftp/python/3.8.16/Python-3.8.16.tgz -P /root/soft
    cd /root/soft || exit 
    tar -zxvf Python-3.8.16.tgz
    
    cd /root/soft/Python-3.8.16 || exit 
    make clean 
    ./configure && make && make install
fi 

# yum install docker
#yum install -y yum-utils
#yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
#yum makecache fast
#yum install -y docker-ce docker-ce-cli containerd.io

#systemctl start docker
#pip3 install docker-compose

# chanage date
ntpdate ntp.tencent.com
date


if [[ $fdisk_opt -eq 1 ]];then
    echo -e "n\np\n1\n\n\np\nw\n" | fdisk $disk
    data_disk=$disk\1
    vg_path=vg_$lv_name\_1
    lv_path=lv_$lv_name\_1
 
    pvcreate $data_disk
    vgcreate $vg_path $data_disk
    lvcreate -l 100%VG -n $lv_path $vg_path
    mkfs.ext4 /dev/$vg_path/$lv_path
   
    mkdir -p $mount_dir
    mount /dev/$vg_path/$lv_path $mount_dir
    echo "/dev/mapper/$vg_path-$lv_path $mount_dir   ext4   defaults        0 0" >> /etc/fstab
fi
