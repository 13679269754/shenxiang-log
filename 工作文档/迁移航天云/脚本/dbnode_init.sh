#!/bin/bash

mkdir -p /root/soft

# 挂载磁盘参数
fdisk_opt=0 # 0 不挂载，1 挂载
disk='/dev/vdb' # 未挂载的磁盘
mount_dir='/usr/local/data' # 挂载路径
lv_name='data' # 磁盘虚拟卷名称



function program_exists() {
    local ret='0'
    command -v "$1" >/dev/null 2>&1 || { local ret='1'; }
    # fail on non-zero return value
    if [ "$ret" -ne 0 ]; then
        return 0
    fi
    return 1
}


# 修改limit.conf

echo  fs.file-max = 6553600  >> /etc/sysctl.conf

echo "# 追加全用户打开最大文件数限制" >> /etc/security/limits.conf
echo "* soft nofile 655350" >> /etc/security/limits.conf
echo "* hard nofile 655350" >> /etc/security/limits.conf
echo "* soft nproc  655350" >> /etc/security/limits.conf
echo "* hard nproc  650000" >> /etc/security/limits.conf

# 修改tcp_keepalive
cat << EOF >> /etc/sysctl.conf
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 10
EOF
sysctl -p

# change passwd
#echo "dzj123,./" | passwd --stdin root

# change ssd
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
systemctl restart sshd

# yum 源配置
# yum install wget -y
# 关闭epel源
# sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/epel.repo 

# wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
# yum clean all
# yum makecache

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
