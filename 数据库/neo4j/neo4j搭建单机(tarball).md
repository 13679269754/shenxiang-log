| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2023-12月-06 | 2023-12月-06  |
| ... | ... | ... |
---
# neo4j搭建单机

[toc]

[官网安装](https://neo4j.com/docs/operations-manual/current/installation/linux/)

## JDK安装 

[System requirements](https://neo4j.com/docs/operations-manual/current/installation/requirements/)


## 安装包获取

[Deployment Center](https://neo4j.com/deployment-center/)

## 安装

[Linux executable (.tar)](https://neo4j.com/docs/operations-manual/current/installation/linux/tarball/)

## 配置文件修改
开放的访问ip  
`dbms.default_listen_address=0.0.0.0`

指定的数据库
```bash
dbms.default_database=neo4j # 社区版只能指定一个数据库，即只有一个数据库是可用状态
```

bolt连接器(客户端连接)
```bash
dbms.connector.bolt.enabled=true
dbms.connector.bolt.listen_address=:7787
dbms.connector.bolt.advertised_address=:7787
```

http端口
```bash
dbms.connector.http.enabled=true
dbms.connector.http.listen_address=:7674
dbms.connector.http.advertised_address=:7674 

```
**具体port 建议参考原有环境**


## 创建系统用户及环境配置

```bash
useradd neo4j

chown -R neo4j. /usr/local/data/neo4j-server

chown -R neo4j. /usr/local/data/java11

su - neo4j

cat << EOF >> /home/neo4j/.bash_profile
NEO4J_HOME=/usr/local/data/neo4j-server
NEO4J_CONF=/usr/local/data/neo4j-server/conf
PATH=\$PATH:\$NEO4J_HOME/bin
export PATH
export NEO4J_CONF
export NEO4J_HOME
EOF

source /home/neo4j/.bash_profile

echo "neo4j start" > /home/neo4j/start.sh

echo "pkill /usr/local/data/neo4j-server/run/neo4j.pid" > /home/neo4j/stop.sh

chmod 755 /home/neo4j/*.sh
```

## 用户创建
默认用户neo4j:neo4j  
> Connect using the username neo4j with the default password neo4j. You will then be prompted to change the password.

访问 `http://ip:port` 登录用户以后会提示修改密码
