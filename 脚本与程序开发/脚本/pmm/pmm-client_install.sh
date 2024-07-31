#!/bin/bash


########################################
#title: pmm-client_install
#creater: shenx
#time: 23-5-9
#
########################################

#是否重新安装
re_yum_install=1
server_host=
server_port=

server_username="admin"
server_password="admin"
node_type="mysql"
#本机ip
local_host=$(hostname -I | awk '{print $1}')

function log(){
    if [ "$1" == 'warning' ]; then 
        echo -e "\e[033m警告: $2\e[0m"
    elif [ "$1" == 'info' ]; then
        echo -e "\e[032m消息: $2\e[0m"
    elif [ "$1" == 'error' ]; then
        echo -e "\e[031m错误: $2\e[0m"
    else 
        echo "$1"
    fi
}

#标识env_check是否通过
env_error=0
function env_check(){
    log info "开始环境检查"
    have_old_rpm=$(rpm -qa | grep pmm)
    if [ ! -z "$have_old_rpm" ]; then
        log error "pmm-client 已经安装"
        env_error=1
        read -p "是否重新安装 (y/n)?" choice
        case "$choice" in 
          y|Y ) re_install;;
          n|N ) echo "退出安装" && exit 1;;
          * ) echo "错误: 请输入 y 或 n." && exit 1;;
        esac
    fi
}


function uninstall_old_package(){
    log info "开始卸载pmm-client"
    rpm -qa | grep pmm2-client > /dev/null
    if [ $? -eq 0 ]; then
        rpm -e --nodeps $(rpm -qa | grep pmm2-client)
        log info "卸载pmm-client成功"
    else
        log info "pmm-client未安装"
    fi
}

function re_install(){
    log info "重新安装"
    uninstall_old_package
    install
}


function install(){
	log info "开始安装pmm-client"
    yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
    yum install -y pmm2-client-2.36.0-6.el7

    version=$(pmm-admin --version)
    if [ $? -eq 0 ]; then
        log info "安装成功，当前版本号为：$version"
    else
        log error "安装失败"
        exit 1
    fi
}

function start(){
    log info "添加 pmm-client 到 pmm-server"
     
    log info  "pmm-admin config --server-insecure-tls --server-url=https://$server_username:$server_password@$server_host:$server_port $local_host  generic ${node_type}-node$local_host"
    log info  "pmm-agent setup --config-file=/usr/local/percona/pmm2/config/pmm-agent.yaml --server-address=$server_host --server-insecure-tls --server-username=$server_username --server-password=$server_password"
    pmm-admin config --server-insecure-tls --server-url=https://$server_username:$server_password@$server_host:$server_port $local_host  generic ${node_type}-node$local_host

    if [ $? -eq 0 ]; then
        log info "启动成功"
    else
        log error "启动失败"
        exit 1
    fi
}



###########################
# 参数解析
###########################

# 初始化一些默认值
server_username="admin"
server_password="admin"

function usage(){
    echo "用法: $0 [选项]."

    # 描述脚本用途、参数和选项等信息
    echo ""
    echo "这是一个安装 pmm-client 的 Bash 脚本。"
    echo ""
    echo "选项:"
    echo "-h, help.             显示此帮助消息并退出."
    echo "-s, server-host.      PMM 服务器的主机或 IP 地址。"
    echo "                       必填参数."
    echo "-p, server-port.      PMM 服务器的端口号。默认为空。"
    echo "-u, server-username.  连接 PMM 服务器时使用的用户名。"
    echo "                       默认为 $server_username。"
    echo "-P, server-password.  连接 PMM 服务器时使用的密码。"
    echo "                       默认为 $server_password。"
    echo "-t, node-type.        节点类型，默认为mysql。"
    echo "                       默认为 $node_type。"
    echo ""
    echo "示例用法:"
    echo "$0 -s 192.168.0.1 -p 443 -u myuser -P mypassword"
}

while getopts ":h:s:p:u:P:t:" opt; do
  case ${opt} in
    s )
      server_host=$OPTARG
      ;;
    p )
      server_port=$OPTARG
      ;;
    u )
      server_username=$OPTARG
      ;;
    P )
      server_password=$OPTARG
      ;;
    t )
      node_type=$OPTARG
      ;;
    h )
      usage
      exit 0
      ;;
    \? )
      echo "无效的选项: $OPTARG." 1>&2
      usage
      exit 1
      ;;
    : )
      echo "无效的选项: $OPTARG 需要一个参数。" 1>&2
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

if [ -z "$server_host" ]; then
  echo "错误: 必须提供参数 server-host."
  usage
  exit 1
fi

###########################
# 安装和启动
###########################

env_check

if [ "$env_error" == 0 ]; then
    install
fi

start
# 打印相关信息到标准输出
log info "pmm-client:$(pmm-admin --version)"