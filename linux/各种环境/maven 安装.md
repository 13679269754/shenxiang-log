| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2025-6月-13 | 2025-6月-13 |
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



### ✅ 2. 设置国内镜像源（推荐）
如果你在国内，访问 Maven 中央仓库可能会很慢或失败。可以配置阿里云镜像：

编辑 Maven 的配置文件：
```bash
vim ~/.m2/settings.xml
```

如果没有这个文件，可以创建一个。添加以下内容：

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
          http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <mirrors>
    <mirror>
      <id>aliyunmaven</id>
      <mirrorOf>central</mirrorOf>
      <name>Aliyun Maven</name>
      <url>https://maven.aliyun.com/repository/central</url>
    </mirror>
  </mirrors>
</settings>
```

保存后重新执行：
```bash
mvn clean package
```