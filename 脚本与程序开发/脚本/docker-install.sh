#!/bin/bash

# ========= 配置部分 =========
# 定义 Docker 数据目录
DOCKER_DATA_ROOT="/usr/local/data/docker"  # 可修改为自定义目录
# DOCKER_DATA_ROOT="/mnt/data/docker"       # 取消注释并修改

# 定义Docker Compose版本（留空则自动获取最新版）
# COMPOSE_VERSION="v2.24.5"

# 定义国内镜像源列表（建议保留至少2-3个常用镜像源）
MIRROR_LIST=(
    "https://dockerpull.org"
    "https://docker.1panel.dev"
    "https://docker.foreverlink.love"
    "https://docker.fxxk.dedyn.io"
    "https://docker.xn--6oq72ry9d5zx.cn"
    "https://docker.zhai.cm"
    "https://docker.5z5f.com"
    "https://a.ussh.net"
    "https://docker.cloudlayer.icu"
    "https://hub.littlediary.cn"
    "https://hub.crdz.gq"
    "https://docker.unsee.tech"
    "https://docker.kejilion.pro"
    "https://registry.dockermirror.com"
    "https://hub.rat.dev"
    "https://dhub.kubesre.xyz"
    "https://docker.nastool.de"
    "https://docker.udayun.com"
    "https://docker.rainbond.cc"
    "https://hub.geekery.cn"
    "https://docker.1panelproxy.com"
    "https://atomhub.openatom.cn"
    "https://docker.m.daocloud.io"
    "https://docker.1ms.run"
    "https://docker.linkedbus.com"
    "https://dytt.online"
    "https://func.ink"
    "https://lispy.org"
    "https://docker.xiaogenban1993.com"
)


# ========= 工具函数 =========
# 日志输出函数
log() {
    echo -e "\033[32m[INFO]\033[0m $1"
}

error() {
    echo -e "\033[31m[ERROR]\033[0m $1" >&2
}

warning() {
    echo -e "\033[33m[WARNING]\033[0m $1" >&2
}


# ========= 检测操作系统 =========
log "检测操作系统..."
OS=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
elif [ -f /etc/centos-release ]; then
    OS="CentOS Linux"
elif [ -f /etc/debian_version ]; then
    OS="Debian GNU/Linux"
elif [ -f /etc/redhat-release ]; then
    OS="Red Hat Enterprise Linux"
fi

if [ -z "$OS" ]; then
    error "无法检测操作系统，仅支持Ubuntu/CentOS/Debian/RHEL"
    exit 1
fi
log "当前操作系统: $OS"


# ========= 安装Docker =========
install_docker() {
    log "开始安装Docker..."
    local packages_installed=0

    if [[ $OS == "Ubuntu" || $OS == "Debian GNU/Linux" ]]; then
        # Debian系系统安装逻辑
        sudo apt-get update || { error "更新软件源失败"; return 1; }
        
        # 安装依赖包
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common || {
            error "安装依赖包失败"; return 1;
        }
        packages_installed=1

        # 添加Docker官方GPG密钥
        log "添加Docker官方GPG密钥..."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || {
            error "添加GPG密钥失败"; return 1;
        }

        # 添加Docker源（使用阿里云镜像源）
        log "配置Docker软件源..."
        if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
            local codename=$(lsb_release -cs || echo "jammy")
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $codename stable" | 
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || {
                error "配置软件源失败"; return 1;
            }
        fi

        # 安装Docker CE
        sudo apt-get update || { error "更新软件源失败"; return 1; }
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io || {
            error "安装Docker失败"; return 1;
        }

    elif [[ $OS == "CentOS Linux" || $OS == "Red Hat Enterprise Linux" ]]; then
        # RHEL系系统安装逻辑
        sudo yum install -y yum-utils || { error "安装yum-utils失败"; return 1; }
        packages_installed=1

        # 配置Docker源（使用阿里云镜像源）
        log "配置Docker软件源..."
        if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
            sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo || {
                error "配置软件源失败"; return 1;
            }
        fi

        # 安装Docker CE
        sudo yum makecache fast || { error "生成缓存失败"; return 1; }
        sudo yum install -y docker-ce docker-ce-cli containerd.io || {
            error "安装Docker失败"; return 1;
        }
    else
        error "不支持的操作系统: $OS"
        return 1
    fi

    # 检查Docker是否安装成功
    if ! command -v docker &> /dev/null; then
        error "Docker安装失败，请手动检查"
        return 1
    fi

    log "Docker安装成功"
    return 0
}


# ========= 安装Docker Compose =========
install_docker_compose() {
    log "开始安装Docker Compose..."
    local compose_version="${COMPOSE_VERSION:-$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4 | sed 's/^v//')}"
    
    if [ -z "$compose_version" ]; then
        warning "无法获取Docker Compose最新版本，使用固定镜像源安装"
        compose_version="1.21.2"
        local compose_url="https://mirrors.aliyun.com/docker-toolbox/linux/compose/${compose_version}/docker-compose-$(uname -s)-$(uname -m)"
    else
        local compose_url="https://github.com/docker/compose/releases/download/v${compose_version}/docker-compose-$(uname -s)-$(uname -m)"
    fi

    log "下载Docker Compose v${compose_version}..."
    sudo curl -L "$compose_url" -o /usr/local/bin/docker-compose || {
        error "下载Docker Compose失败，尝试使用备用镜像源"
        # 备用镜像源（阿里云）
        sudo curl -L "https://mirrors.aliyun.com/docker-toolbox/linux/compose/1.21.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || {
            error "备用镜像源下载失败，请手动安装"
            return 1
        }
    }

    # 赋予执行权限
    sudo chmod +x /usr/local/bin/docker-compose || {
        error "设置执行权限失败"
        return 1
    }

    # 创建软链接
    if [ ! -f /usr/bin/docker-compose ]; then
        sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || {
            warning "创建软链接失败，可能需要手动添加到PATH"
        }
    fi

    # 验证安装
    docker-compose --version || {
        error "Docker Compose安装失败"
        return 1
    }

    log "Docker Compose安装成功: $(docker-compose --version)"
    return 0
}


# ========= 配置Docker镜像源和数据目录 =========
configure_docker_mirror() {
    log "配置Docker镜像源和数据目录..."
    local data_root="$DOCKER_DATA_ROOT"
    local mirror_json=$(printf "\"%s\"," "${MIRROR_LIST[@]}" | sed 's/,$/]/')  # 生成正确的JSON数组
    
    # 检查数据目录
    if [ ! -d "$data_root" ]; then
        log "创建数据目录: $data_root"
        sudo mkdir -p "$data_root" || {
            error "创建数据目录失败，请检查权限"
            return 1
        }
        sudo chown root:root "$data_root"
        sudo chmod 755 "$data_root"
    fi

    # 生成daemon.json配置
    log "生成Docker配置文件..."
    cat > /tmp/daemon.json <<EOF
{
    "data-root": "$data_root",
    "registry-mirrors": $mirror_json
}
EOF

    # 验证JSON格式
    if ! python3 -c "import json, sys; json.load(sys.stdin)" < /tmp/daemon.json &> /dev/null; then
        error "生成的JSON配置格式错误"
        cat /tmp/daemon.json
        return 1
    fi

    # 备份原配置
    if [ -f /etc/docker/daemon.json ]; then
        sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
        log "已备份原配置文件到 /etc/docker/daemon.json.bak"
    fi

    # 应用新配置
    sudo mv /tmp/daemon.json /etc/docker/daemon.json || {
        error "写入配置文件失败，请检查权限"
        return 1
    }

    # 重载配置并重启Docker
    log "重启Docker服务..."
    sudo systemctl daemon-reload || {
        error "重载systemd配置失败"
        return 1
    }

    # 尝试优雅重启，失败则强制重启
    if ! sudo systemctl restart docker; then
        warning "优雅重启失败，尝试强制重启"
        sudo systemctl stop docker
        sudo systemctl start docker
    fi

    # 验证配置
    log "验证Docker配置..."
    if ! docker info &> /dev/null; then
        error "Docker服务启动失败，查看日志:"
        sudo systemctl status docker -l
        return 1
    fi

    local data_root_info=$(docker info | grep "Data Root" | awk -F': ' '{print $2}')
    local mirrors_info=$(docker info | grep "Registry Mirrors" | awk -F': ' '{print $2}')
    
    log "Docker数据目录: $data_root_info"
    log "镜像源配置: $mirrors_info"
    return 0
}


# ========= 主函数 =========
main() {
    # 检查是否以root权限运行
    if [ "$(id -u)" -ne 0 ]; then
        error "请使用root权限运行此脚本"
        exit 1
    fi

    log "开始Docker安装流程..."
    
    # 安装Docker
    install_docker || {
        error "Docker安装失败，退出脚本"
        exit 1
    }
    
    # 安装Docker Compose
    install_docker_compose || {
        warning "Docker Compose安装失败，但Docker已安装完成"
    }
    
    # 配置镜像源和数据目录
    configure_docker_mirror || {
        warning "配置过程中出现错误，但Docker可能已正常运行"
    }
    
    # 启动并设置开机自启
    log "设置Docker开机自启..."
    sudo systemctl enable docker || {
        warning "设置开机自启失败"
    }
    
    # 最终验证
    log "安装完成，最终验证:"
    docker --version
    if command -v docker-compose &> /dev/null; then
        docker-compose --version
    else
        log "Docker Compose未成功安装，请手动安装"
    fi
    
    log "Docker安装流程完成"
    exit 0
}


# 执行主函数
main