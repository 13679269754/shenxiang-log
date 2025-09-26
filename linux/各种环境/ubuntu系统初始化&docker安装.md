| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2024-9月-12 | 2024-9月-12 |

---
# ubuntu系统初始化&docker安装.md

## 原网页  

[Ubuntu 22.04下Docker安装（最全指引）](https://blog.csdn.net/u011278722/article/details/137673353) 
[sudo apt update:仓库 “http://mirrors.aliyun.com/docker-ce/linux/debian ulyana Release” 没有 Release 文件](https://blog.csdn.net/yzpbright/article/details/118307388)

## 初始化
[[ubuntu_dbnode_init.sh]]



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