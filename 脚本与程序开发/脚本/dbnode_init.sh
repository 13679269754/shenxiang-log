#!/bin/bash

mkdir -p /root/soft

fdisk_opt=0
disk='/dev/sdb'
mount_dir='/usr/local/data'
lv_name='data'



function program_exists() {
    local ret='0'
    command -v $1 >/dev/null 2>&1 || { local ret='1'; }
    # fail on non-zero return value
    if [ "$ret" -ne 0 ]; then
        return 0
    fi
    return 1
}


# change passwd
#echo "dzj123,./" | passwd --stdin root

# change ssd
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
systemctl restart sshd

# yum install
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
    cd /root/soft
    tar -zxvf Python-3.8.16.tgz
    
    cd /root/soft/Python-3.8.16
    make clean 
    ./configure && make && make install
fi 

# yum install docker
yum install -y yum-utils
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache fast
yum install -y docker-ce docker-ce-cli containerd.io

systemctl start docker
pip3 install docker-compose

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



pmm_monitor



GRANT RELOAD, PROCESS, REPLICATION CLIENT ON *.* TO `pmm_monitor`@`127.0.0.1`; 
GRANT BACKUP_ADMIN ON *.* TO `pmm_monitor`@`127.0.0.1`;                    
GRANT SELECT ON `mysql`.* TO `pmm_monitor`@`127.0.0.1`;                       
GRANT SELECT ON `sys`.* TO `pmm_monitor`@`127.0.0.1`;                         
GRANT SELECT ON `performance_schema`.* TO `pmm_monitor`@`127.0.0.1`;



create user `pmm_monitor`@`127.0.0.1` identified by "bP7oKjo05QBPEgfJ"


pmm2-client-2.36.0-6.el7.x86_64.rpm




create user `pmm_monitor`@`127.0.0.1` identified by "bT97wtS2WcEt6oET"

GRANT RELOAD, PROCESS, REPLICATION CLIENT ON *.* TO `pmm_monitor`@`127.0.0.1`; 
GRANT BACKUP_ADMIN ON *.* TO `pmm_monitor`@`127.0.0.1`;                    
GRANT SELECT ON `mysql`.* TO `pmm_monitor`@`127.0.0.1`;                       
GRANT SELECT ON `sys`.* TO `pmm_monitor`@`127.0.0.1`;                         
GRANT SELECT ON `performance_schema`.* TO `pmm_monitor`@`127.0.0.1`;
