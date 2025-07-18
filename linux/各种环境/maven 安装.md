| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-6月-13 | 2025-6月-13  |
| ... | ... | ... |
---
# maven 安装

[toc]

## 前置
JDK 安装 

[JDK17 安装](<JDK17 安装.md>)

## 手动安装

### 下载解压

```bash
curl -O https://dlcdn.apache.org/maven/maven-3/3.9.10/binaries/apache-maven-3.9.10-bin.tar.gz
tar -zxvf apache-maven-3.9.10-bin.tar.gz -C /usr/local/data/
mv /usr/local/data/apache-maven-3.9.10 /usr/local/data/maven

```

### 配置环境变量
```bash
# 编辑环境变量配置文件
sudo vi /etc/profile.d/maven.sh

# 添加以下内容
export MAVEN_HOME=/usr/local/data/maven
export PATH=$PATH:$MAVEN_HOME/bin

# 使配置生效
source /etc/profile.d/maven.sh
```

### 验证安装

```bash
mvn -version
```
