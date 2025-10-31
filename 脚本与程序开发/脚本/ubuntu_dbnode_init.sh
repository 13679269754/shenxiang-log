#!/bin/bash

# 创建目录
mkdir -p /root/soft

# 设置变量
fdisk_opt=0
disk='/dev/vdb'
mount_dir='/usr/local/data'
lv_name='data'

# 定义函数
program_exists() {
  command -v "$1" >/dev/null 2>&1
}

# 修改密码
echo "dzj123,./" | passwd --stdin root

# 修改 SSH 配置
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit/password/PermitRootLogin yes/g' /etc/ssh/sshd_config
systemctl restart ssh

# 安装软件
mv /etc/apt/sources.list /etc/apt/sources.list.1bak
cat > /etc/apt/sources.list << EOF
deb https://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse

# deb https://mirrors.aliyun.com/ubuntu/ noble-proposed main restricted universe multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ noble-proposed main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse
EOF



apt update
apt install -y ntpdate lvm2 lrzsz wget curl unzip net-tools telnet tcpdump iftop iotop sysstat netcat  xfsprogs htop psmisc tree net-tools bash-completion vim
apt install -y zlib1g-dev libssl-dev libncurses5-dev libsqlite3-dev libreadline-dev libffi-dev
apt install -y gcc g++ make cmake bison
apt remove -y python3

安装 Python
program_exists python3
python_exist=$?
if [[ $python_exist -eq 0 ]]; then
  cd /root/soft
  tar -zxvf Python-3.8.16.tgz

  cd /root/soft/Python-3.8.16
  make clean
  ./configure && make && make install
fi

# 安装 Docker
#apt install -y apt-transport-https
#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
#add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
#apt update
#apt install -y docker-ce docker-ce-cli containerd.io

#systemctl start docker
#pip3 install docker-compose

# 修改日期
apt-get install chrony -y
cat > /etc/chrony/sources.d/cn-ntp.sources <<EOF
# 中国境内 NTP 服务器
server ntp.ntsc.ac.cn iburst
server time1.cloud.tencent.com iburst
server time2.cloud.tencent.com iburst
server time1.aliyun.com iburst
server time2.aliyun.com iburst
EOF
timedatectl set-timezone Asia/Shanghai
locale-gen zh_CN.UTF-8
echo "----------------当前时间：`date`------------------"

# 如果 fdisk_opt 为 1，则执行以下操作
if [[ $fdisk_opt -eq 1 ]]; then
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
  echo "/dev/mapper/$vg_path-$lv_path $mount_dir ext4 defaults 0 0" >> /etc/fstab
fi
