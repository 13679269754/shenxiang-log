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

## 用户创建
默认用户neo4j:neo4j  
Connect using the username neo4j with the default password neo4j. You will then be prompted to change the password.

访问 `http://ip:port` 登录用户以后会提示修改密码
