没问题！我会帮你从 **环境搭建→项目创建→镜像打包→配置中心→K8s滚动发布** 完整走一遍流程，所有步骤都尽量简化（适合快速上手），同时重点解释关键配置的含义和注意事项。


### 整体流程概览
我们会用 **Spring Boot 项目** 作为示例（简单易上手，适合演示配置中心），全程使用 Docker 和 Kubernetes 进行部署，步骤如下：
1. 搭建基础环境（Docker + Kubernetes 单节点集群）
2. 创建一个简单的 Spring Boot 项目（提供一个 API 接口）
3. 搭建配置中心（使用 Nacos，轻量级且易用）
4. 项目打包为 Docker 镜像
5. 编写 K8s 配置文件，实现滚动发布


## 一、环境搭建（Docker + K8s 单节点）
为了快速上手，我们用 **Minikube** 搭建单节点 K8s 集群（自带 Docker 环境，无需单独安装），适合本地测试。

### 1. 安装 Minikube（选对应系统的步骤）
#### （1）Linux 系统（以 CentOS/Ubuntu 为例）
```bash
# 安装依赖（Docker 会被 Minikube 自动安装）
sudo apt update && sudo apt install -y curl conntrack  # Ubuntu
# 或 CentOS：sudo yum install -y curl conntrack

# 下载 Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 启动单节点集群（指定容器运行时为 Docker）
minikube start --driver=docker

# 验证：查看节点状态（Ready 表示成功）
kubectl get nodes
```

#### （2）Windows/Mac 系统
- 下载安装 [Docker Desktop](https://www.docker.com/products/docker-desktop)（勾选“Enable Kubernetes”），启动后自动创建单节点集群。
- 或用 Minikube：[官方安装指南](https://minikube.sigs.k8s.io/docs/start/)


### 2. 安装 Nacos 配置中心（用 Docker 快速启动）
```bash
# 启动 Nacos 容器（单机模式，默认账号密码 nacos/nacos）
docker run -d --name nacos -p 8848:8848 -e MODE=standalone nacos/nacos-server:v2.2.3

# 验证：访问 http://localhost:8848/nacos（Linux 用 minikube ip 代替 localhost）
# 登录后进入“配置管理→配置列表”，后续会在这里添加配置
```


## 二、创建 Spring Boot 项目（提供测试 API）
我们创建一个最简单的 Spring Boot 项目，包含一个接口，从 Nacos 配置中心获取参数。

### 1. 项目结构（手动创建，无需 IDE）
创建文件夹 `simple-api`，并新建以下文件：

#### （1）`pom.xml`（Maven 依赖配置）
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.7.0</version>
        <relativePath/>
    </parent>
    <groupId>com.example</groupId>
    <artifactId>simple-api</artifactId>
    <version>1.0.0</version>
    <name>simple-api</name>
    <dependencies>
        <!-- Web 依赖：提供 HTTP 接口 -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <!-- Nacos 配置中心依赖 -->
        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-alibaba-nacos-config</artifactId>
            <version>2.2.7.RELEASE</version>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <!-- 打包为可执行 JAR -->
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

#### （2）`src/main/java/com/example/SimpleApiApplication.java`（主程序）
```java
package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SimpleApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(SimpleApiApplication.class, args);
    }
}
```

#### （3）`src/main/java/com/example/controller/TestController.java`（API 接口）
```java
package com.example.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TestController {
    // 从配置中心获取参数（key 为 app.message）
    @Value("${app.message:默认消息}")
    private String message;

    // 提供一个测试接口：http://localhost:8080/test
    @GetMapping("/test")
    public String test() {
        return "接口响应：" + message;
    }
}
```

#### （4）`src/main/resources/bootstrap.yml`（Nacos 配置中心连接配置）
```yaml
spring:
  application:
    name: simple-api  # 服务名，对应 Nacos 配置的 Data ID
  cloud:
    nacos:
      config:
        server-addr: 172.29.105.240:8848  # Nacos 地址（替换为你的 Nacos 所在机器 IP）
        file-extension: yaml  # 配置文件格式
```


### 2. 在 Nacos 中添加配置
1. 登录 Nacos 控制台（http://你的NacosIP:8848/nacos），账号密码 `nacos/nacos`。
2. 进入 **配置管理→配置列表**，点击“+”新建配置：
   - Data ID：`simple-api.yaml`（必须与 `bootstrap.yml` 中 `spring.application.name` + `file-extension` 一致）
   - 配置格式：YAML
   - 配置内容：
     ```yaml
     app:
       message: 这是从 Nacos 配置中心获取的消息（v1版本）
     ```
   - 点击“发布”。


## 三、打包项目为 Docker 镜像
### 1. 编写 `Dockerfile`（在项目根目录）
```dockerfile
# 基础镜像：Java 8
FROM openjdk:8-jre-slim

# 作者信息（可选）
LABEL maintainer="test@example.com"

# 把打包好的 JAR 包复制到容器中（target/simple-api-1.0.0.jar 是 Maven 打包产物）
COPY target/simple-api-1.0.0.jar /app.jar

# 容器启动时执行的命令
ENTRYPOINT ["java", "-jar", "/app.jar"]

# 暴露端口（项目运行在 8080 端口）
EXPOSE 8080
```

### 2. 打包 JAR 并构建镜像
```bash
# 1. 打包 Spring Boot 项目（需安装 Maven，或用 IDE 打包）
mvn clean package -Dmaven.test.skip=true  # 生成 target/simple-api-1.0.0.jar

# 2. 构建 Docker 镜像（标签为 simple-api:v1）
docker build -t simple-api:v1 .

# 3. 验证镜像
docker images | grep simple-api  # 能看到 simple-api:v1 即为成功
```

### 3. 推送到 Minikube 可访问的仓库（可选，本地测试可跳过）
Minikube 内部的 Docker 环境可能无法直接访问本地镜像，需执行：
```bash
# 把镜像加载到 Minikube 环境中
minikube load simple-api:v1
```


## 四、Kubernetes 部署配置（滚动发布核心）
### 1. 编写 Deployment 配置（`simple-api-deploy.yaml`）
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: simple-api  # Deployment 名称
spec:
  replicas: 2  # 运行 2 个 Pod 实例（便于演示滚动更新）
  selector:
    matchLabels:
      app: simple-api  # 匹配标签为 app=simple-api 的 Pod
  strategy:
    # 滚动更新策略（核心配置）
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1  # 更新时最多可超出期望副本数的数量（如 2 个副本，最多同时运行 3 个）
      maxUnavailable: 0  # 更新时最多不可用的副本数（0 表示不允许任何 Pod 不可用，保证服务不中断）
  template:
    metadata:
      labels:
        app: simple-api  # Pod 标签，需与 selector 匹配
    spec:
      containers:
      - name: simple-api  # 容器名称
        image: simple-api:v1  # 镜像名称（与前面构建的一致）
        ports:
        - containerPort: 8080  # 容器内端口（项目运行端口）
        resources:
          limits:
            cpu: "0.5"  # 最大 CPU 限制
            memory: "512Mi"  # 最大内存限制
          requests:
            cpu: "0.2"  # 最小 CPU 需求
            memory: "256Mi"  # 最小内存需求
        livenessProbe:  # 存活探针（检测容器是否健康）
          httpGet:
            path: /test
            port: 8080
          initialDelaySeconds: 30  # 启动后 30 秒开始检测
          periodSeconds: 10  # 每 10 秒检测一次
```

### 2. 编写 Service 配置（`simple-api-svc.yaml`，暴露访问入口）
```yaml
apiVersion: v1
kind: Service
metadata:
  name: simple-api-svc  # Service 名称
spec:
  selector:
    app: simple-api  # 关联标签为 app=simple-api 的 Pod
  ports:
  - port: 80  # Service 暴露的端口
    targetPort: 8080  # 转发到 Pod 的 8080 端口
  type: NodePort  # 暴露到宿主机端口，便于外部访问
```


## 五、部署到 K8s 并测试滚动发布
### 1. 首次部署
```bash
# 部署 Deployment 和 Service
kubectl apply -f simple-api-deploy.yaml -f simple-api-svc.yaml

# 查看 Pod 状态（确保 2 个 Pod 都是 Running）
kubectl get pods -l app=simple-api

# 查看 Service 暴露的端口（找到 80:3xxxx/TCP 中的 3xxxx 端口）
kubectl get svc simple-api-svc
```

### 2. 访问测试
```bash
# 获取 Minikube 节点 IP（Linux）
MINIKUBE_IP=$(minikube ip)
# 或 Windows/Mac：在 Docker Desktop 中，K8s 节点 IP 为 localhost

# 访问接口（替换 3xxxx 为实际 NodePort）
curl http://$MINIKUBE_IP:3xxxx/test
# 预期输出：接口响应：这是从 Nacos 配置中心获取的消息（v1版本）
```


### 3. 滚动发布（更新版本）
#### （1）修改代码并构建新版本镜像
- 在 Nacos 中更新配置（Data ID: simple-api.yaml）：
  ```yaml
  app:
    message: 这是从 Nacos 配置中心获取的消息（v2版本，滚动更新后）
  ```
- 构建新镜像：
  ```bash
  docker build -t simple-api:v2 .
  minikube load simple-api:v2  # 加载到 Minikube
  ```

#### （2）执行滚动更新
```bash
# 更新 Deployment 的镜像版本
kubectl set image deployment/simple-api simple-api=simple-api:v2