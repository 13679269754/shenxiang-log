| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-1月-05 | 2024-1月-05  |
| ... | ... | ... |
---
# 数据库快速部署dba-agent

[toc]

## 写在前面
用这个工具本来是想法快速搭建mysql数据库来玩，结果没想到，这个工具的安装过程遇到了这么多麻烦

## github地址
[dba-agent](https://github.com/Neeky/dbm-agent)

[问题处理](..\\python\\python缺少系统库的原因及解决办法.md)

还有其他问题相对容易处理
1.缺少mysql依赖包 找到对应的安装包，yum 安装即可.
表现为数据初始化失败
```bash
/usr/local/mysql-8.2.0-linux-glibc2.17-x86_64/bin/mysqld --defaults-file=/tmp/mysql-init.cnf --init-file=/tmp/mysql-init-user.sql --initialize-insecure
```
2.安装的mysql版本没有预设配置文件,新建即可.

