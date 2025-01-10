| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-1月-09 | 2025-1月-09  |
| ... | ... | ... |
---
# docker 环境

[toc]

## 原文

[在 CentOS 上安装 Docker 和 Docker Compose](https://blog.csdn.net/weixin_51524504/article/details/145016888)

* * *

### 一、安装 Docker

#### 1.1 安装最新版本的 Docker

1.  **更新系统软件包**
    
    ```
    sudo yum update -y
    ```
    
2.  **安装必要的软件包**
    
    ```
    sudo yum install -y yum-utils
    ```
    
3.  **添加 Docker 的官方 Yum 仓库（使用阿里云镜像）**
    
    ```
    sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    ```
    
4.  **安装最新版本的 Docker**
    

    `sudo yum install -y docker-ce docker-ce-cli containerd.io` 

    
5.  **启动并设置开机自启**
    
    ```
    sudo systemctl start docker
    sudo systemctl enable docker
    ```
    
6.  **验证安装结果**
    
    `docker --version` 

    如果输出类似 `Docker version 20.10.xx`，说明安装成功。
    

* * *

#### 1.2 安装指定版本的 Docker

如果需要安装特定版本（如为了兼容某些软件），可以按以下步骤操作：

1.  **查看支持的 Docker 版本**
    
    ```
    yum list docker-ce --showduplicates | sort -r
    ```
    
    输出示例如：
    
    ```
    docker-ce.x86_64    3:20.10.12-3.el7   docker-ce-stable
    docker-ce.x86_64    3:19.03.15-3.el7   docker-ce-stable
    docker-ce.x86_64    3:18.09.1-3.el7    docker-ce-stable
    ...
    ```
    
2.  **安装指定版本的 Docker**
    
    假设需要安装 `19.03.15`，可以运行：
    
    ```
    sudo yum install -y docker-ce-19.03.15 docker-ce-cli-19.03.15 containerd.io
    ```
    
3.  **启动并设置开机自启**
    
    ```
    sudo systemctl start docker
    sudo systemctl enable docker
    ```
    
4.  **验证安装版本**
    
    ```
    docker --version
    ```
    

* * *

### 二、配置 Docker 镜像加速器（国内镜像源）

在国内网络环境下，直接访问 Docker Hub 可能速度较慢。可通过配置国内镜像源加速拉取镜像。

1.  **配置加速器**
    
    ```
    `sudo tee /etc/docker/daemon.json <<-'EOF'
    {
      "registry-mirrors": [
        "https://docker.m.daocloud.io",
        "https://dockerproxy.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://docker.nju.edu.cn",
        "https://vp5v3vra.mirror.aliyuncs.com",
        "https://docker.registry.cyou",
        "https://docker-cf.registry.cyou",
        "https://dockercf.jsdelivr.fyi",
        "https://docker.jsdelivr.fyi",
        "https://dockertest.jsdelivr.fyi",
        "https://mirror.baidubce.com",
        "https://docker.m.daocloud.io",
        "https://docker.nju.edu.cn",
        "https://docker.mirrors.sjtug.sjtu.edu.cn",
        "https://docker.mirrors.ustc.edu.cn",
        "https://mirror.iscas.ac.cn",
        "https://docker.rainbond.cc"
      ]
    }
    EOF    

    ```
    
2.  **重启 Docker 服务**
    
    ```
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    ```
    

* * *

### 三、安装 Docker Compose

#### 3.1 安装最新版本的 Docker Compose

1.  **下载最新版本**

可以执行下面命令：

```
sudo curl -L "https://github.com/docker/compose/releases/download/${latest_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

> **注意**：也可以将`${latest_version}` 需替换为实际版本号，例如 `v2.32.2`。

2.  **赋予执行权限**
    
    ```
    sudo chmod +x /usr/local/bin/docker-compose
    ```
    
3.  **验证安装结果**
    
    ```
    docker-compose --version
    ```
    
    若输出类似 `Docker Compose version v2.32.2` 则说明安装成功。
    

* * *

#### 3.2 安装指定版本的 Docker Compose

可以先在 [GitHub Releases 页面](https://github.com/docker/compose/releases) 查看有哪些版本号，如果需要安装某个固定版本（如 `v2.32.2`），可按以下步骤操作：

1.  **下载指定版本**
    
    ```
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    ```
    
    在网络环境不佳的情况下，此方式可能比较慢甚至会超时。可以直接在 GitHub 上下载相应的 `.tar.gz` 或可执行文件后手动上传至服务器。例如：
    
    1.  在 [GitHub Releases](https://github.com/docker/compose/releases) 选择对应版本并下载 `docker-compose-Linux-x86_64`（根据系统架构选择文件）。
    2.  使用 `scp` 或其他方式上传至服务器的 `/usr/local/bin/` 目录。
    3.  将文件重命名为 `docker-compose`，以便统一使用。
2.  **赋予执行权限**
    
    ```
    sudo chmod +x /usr/local/bin/docker-compose
    ```
    
3.  **验证安装版本**
    
    ```
    docker-compose --version
    ```
    
    如果输出类似 `docker-compose version 1.29.2`，表示安装成功。
    

* * *

### 四、卸载 Docker 和 Docker Compose

#### 4.1 卸载 Docker

如无需再使用 Docker，可按照以下步骤卸载：

1.  **停止 Docker 服务**
    
    ```
    sudo systemctl stop docker
    ```
    
2.  **卸载相关组件**
    
    ```
    sudo yum remove -y docker-ce docker-ce-cli containerd.io
    ```
    
3.  **清理 Docker 数据**
    
    ```
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    ```
    
    以上操作会删除 Docker 及其相关数据（包括容器、镜像等），请谨慎执行。
    

* * *

#### 4.2 卸载 Docker Compose

Docker Compose 卸载很简单，只需删除其二进制文件：

```
sudo rm -f /usr/local/bin/docker-compose
```

验证是否已卸载：

```
docker-compose --version
```

如果提示 `command not found`，则说明卸载成功。

* * *

### 五、常见问题与解决方案

1.  **无法访问官方仓库导致安装失败**
    
    配置国内镜像源，例如：
    
    ```
    sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    ```
    
    然后重新安装 Docker。
    
2.  **`docker-compose` 无法执行或出现 “Permission denied”**
    
    *   确认 `/usr/local/bin/docker-compose` 文件权限正确：

        `sudo chmod +x /usr/local/bin/docker-compose`

        
    *   若仍无法使用，检查是否需要手动添加 `/usr/local/bin` 至系统 `PATH`：
        `export PATH=$PATH:/usr/local/bin`
        
    *   或将上述命令添加进 `~/.bashrc`，然后 `source ~/.bashrc`。

* * *

### 六、总结

*   **安装最新版本**：无需特定依赖要求时，可直接获取最新特性与安全补丁。
*   **安装指定版本**：在对环境兼容性要求较高、尤其是生产环境时，可选择特定版本。
*   **镜像加速器配置**：国内网络环境下拉取镜像会更稳定、更快速。
*   **卸载与数据清理**：提供从系统中彻底移除 Docker 及其数据的方式，便于重新配置或节省资源。
*   **常见问题处理**：针对国内访问缓慢、`docker-compose` 权限等问题进行了说明。