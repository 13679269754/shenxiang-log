## 使用[yum]自动安装

`yum install maven -y` 

> 如果是Ubuntu  
> apt install maven -y

## 手动安装

1. 下载maven

```bash
wget https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz

tar -zvxf apache-maven-3.6.3-bin.tar.gz

mv apache-maven-3.6.3 /usr/local/maven
```

2. 添加环境变量

`vim ~/.bashrc` 

添加如下命令
```bash
export MAVEN_HOME=/usr/local/maven
export PATH=$PATH:$MAVEN_HOME/bin
``` 

`source ~/.bashrc` 


