| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-9月-12 | 2024-9月-12  |
| ... | ... | ... |
---
# ubunto系统初始化&docker安装.md

[toc]

## 原网页  

[Ubuntu 22.04下Docker安装（最全指引）](https://blog.csdn.net/u011278722/article/details/137673353) 
[sudo apt update:仓库 “http://mirrors.aliyun.com/docker-ce/linux/debian ulyana Release” 没有 Release 文件](https://blog.csdn.net/yzpbright/article/details/118307388)

## 初始化

`vim dbnode_init.sh`
```bash
#!/bin/bash

# 创建目录
mkdir -p /root/soft

# 设置变量
fdisk_opt=1
disk='/dev/vdb'
mount_dir='/usr/local/data'
lv_name='data'

# 定义函数
program_exists() {
  command -v "$1" >/dev/null 2>&1
}

# 修改密码
#echo "dzj123,./" | passwd --stdin root

# 修改 SSH 配置
#sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
#systemctl restart sshd

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
# apt remove -y python3

# 安装 Python
# program_exists python3
# python_exist=$?
# if [[ $python_exist -eq 0 ]]; then
#   cd /root/soft
#   tar -zxvf Python-3.8.16.tgz
#
#   cd /root/soft/Python-3.8.16
#   make clean
#   ./configure && make && make install
# fi

# 安装 Docker
#apt install -y apt-transport-https
#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
#add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
#apt update
#apt install -y docker-ce docker-ce-cli containerd.io

#systemctl start docker
#pip3 install docker-compose

# 修改日期
ntpdate ntp.tencent.com
date

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
```

## docker安装

centos建议参考[docker 环境](<各种环境/docker 环境.md>)

```bash 

# 准备条件
sudo apt-get remove docker docker-engine docker.io containerd runc 

sudo apt install apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

# 准备安装

# 阿里源（推荐使用阿里的gpg KEY）
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 阿里apt源
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 更新源
sudo apt update
sudo apt-get update

# 安装Docker
sudo apt install docker-ce docker-ce-cli containerd.io 

#查看Docker版本
sudo docker version

#查看Docker运行状态
sudo systemctl status docker

sudo systemctl start docker

# 安装Docker 命令补全工具 

sudo apt-get install bash-completion

sudo curl -L https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker -o /etc/bash_completion.d/docker.sh

source /etc/bash_completion.d/docker.sh

```

## docker源

关于最近国内无法访问到Docker的，首先在安装的时候，我们可以选国内阿里的源。参考上面的更新。

另外，我们需要在docker daemon 配置文件中增加国的可用的 docker hub mirror ，

找到你的daemon.json 文件，通常在 /etc/docker/daemon.json 这个位置

在daemon.json 中增加

```bash 
{
"registry-mirrors": [
    "https://docker.m.daocloud.io"
  ]
}
```


目前可用的国内docker hub 镜像，https://docker.m.daocloud.io。