#!/bin/bash

# 获取命令行参数，第一个参数表示完整的 JDK 版本号，第二个参数表示短的版本号
JDK_VERSION=$1
SHORT_JDK_VERSION=$2

# 定义 JDK 文件名和下载地址，注意可能需要根据具体情况修改版本号和链接地址
JDK_FILENAME="openjdk-${JDK_VERSION}_linux-x64_bin.tar.gz"
JDK_DOWNLOAD_URL="https://repo.huaweicloud.com/openjdk/${JDK_VERSION}/${JDK_FILENAME}"

# 定义 JDK 安装目录和 JAVA_HOME 环境变量的值
JDK_DIR=/usr/local
JAVA_HOME="$JDK_DIR/jdk-$SHORT_JDK_VERSION"

# 下载 JDK 安装包并解压到指定目录
cd $JDK_DIR && \
wget $JDK_DOWNLOAD_URL && \
tar -zxvf $JDK_FILENAME   && \
mv *jdk-$SHORT_JDK_VERSION* "jdk-$SHORT_JDK_VERSION"
rm -f $JDK_FILENAME

# 配置环境变量
echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile
echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/profile

# 使环境变量生效
source /etc/profile

# 输出 JDK 版本号以及 Java 运行时信息
java -version