### Centos7下安装postgresql（tar包形式安装）

#### 1、官网下载地址：

[https://www.postgresql.org/ftp/source/](https://www.postgresql.org/ftp/source/)

[![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-3-21%2015-51-45/0884d0fc-c958-466c-8f2e-6a81ca3eb1b5.png?raw=true)
](https://img2022.cnblogs.com/blog/2608099/202207/2608099-20220715092740923-1712112561.png)

#### 2、将下载来tar包上传到linux服务器上

[![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-3-21%2015-51-45/583ac4d4-bd12-4886-8ae3-3d9363886c34.png?raw=true)
](https://img2022.cnblogs.com/blog/2608099/202207/2608099-20220715092802206-1798563004.png)

#### 3、将tar包解压到指定目录下

shell

```
# -C 后面是解压后存放的目录
tar -zxvf postgresql-14.4.tar.gz -C /opt/module/
```

[![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-3-21%2015-51-45/acef160f-398f-4af6-b8f8-91be5f32b9de.png?raw=true)
](https://img2022.cnblogs.com/blog/2608099/202207/2608099-20220715092818764-1447403388.png)

#### 4、编译，进入到postgresql-14.2目录下,执行下面的命令

1.  执行编译命令前先安装依赖

*   安装C语言编译器

shell

```
yum install gcc -y
```

*   安装编译需要的依赖

shell

```
yum install -y readline-devel
yum install zlib-devel
```

2.  执行编译命令

shell

```
./configure --prefix=/usr/local/postgresql
```

安装完编译所需的依赖后，执行以上编译命令就可以编译成功喽！

#### 5、安装

shell

```
make && make install
```

执行完毕，在/usr/local目录下就会有pgsql这个目录

[![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-3-21%2015-51-45/b867b9bd-7844-49b9-8c44-1dfebafe82d8.png?raw=true)
](https://img2022.cnblogs.com/blog/2608099/202207/2608099-20220715092848007-1090593749.png)

#### 6、创建data和log目录

shell

```
 mkdir /usr/local/postgresql/data
 mkdir /usr/local/postgresql/log
```

[![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-3-21%2015-51-45/eee2ca1c-880d-4d5a-8d63-b6940528a5b5.png?raw=true)
](https://img2022.cnblogs.com/blog/2608099/202207/2608099-20220715092906334-421272537.png)

#### 7、加入系统环境变量

1.  打开系统环境配置文件

shell

```
# 本安装示例中此处的my_env.sh是自己新建的，也可以直接在/etc/profile 中配置
vim /etc/profile.d/my_env.sh
```

2.  配置环境变量

shell

```
export PGHOME=/usr/local/postgresql
export PGDATA=/usr/local/postgresql/data
export PATH=$PATH:$JAVA_HOME/bin:$PGHOME/bin
```

[![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-3-21%2015-51-45/0cc397eb-caf2-4696-a24f-ca09df358ef6.png?raw=true)
](https://img2022.cnblogs.com/blog/2608099/202207/2608099-20220715092921739-388633725.png)

3.  使配置生效

shell

```
source /etc/profile
```

#### 8、增加用户 postgres 并赋权

shell

```
useradd postgres
chown -R postgres:root /usr/local/postgresql/
```

[![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-3-21%2015-51-45/ef7ff272-0588-46c5-9147-77969a6c43b9.png?raw=true)
](https://img2022.cnblogs.com/blog/2608099/202207/2608099-20220715093150175-31955150.png)

#### 9、初始化数据库

shell

```
# 切换为自己前面创建的用户
su postgres
# 初始化数据库操作
/usr/local/postgresql/bin/initdb -D /usr/local/postgresql/data/
```

[![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-3-21%2015-51-45/57fa3c4f-4d41-4f25-a1f7-07c4255ff96f.png?raw=true)
](https://img2022.cnblogs.com/blog/2608099/202207/2608099-20220715093209570-209740268.png)

**注：** 不能在 root 用户下初始数据库，否则会报错

shell

```
\[root@develop-env~\]# /usr/local/postgresql/bin/initdb -D /usr/local/postgresql/data/
initdb: cannot be run as root
Please log in (using, e.g., "su") as the (unprivileged) user that will
own the server process.
```

#### 10、编辑配置文件

1.  打开postgresql.conf配置文件

shell

```
vim /usr/local/postgresql/data/postgresql.conf
```

2.  修改配置信息

shell

```
# 设置所有ip可连接
listen_addresses = '\*' 
 # 设置监听端口
port = 5432 
``` 

[![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-3-21%2015-51-45/40501ca5-68d7-4992-af79-a25f8be0d2d2.png?raw=true)
](https://img2022.cnblogs.com/blog/2608099/202207/2608099-20220715093233342-172577371.png)

3.  打开pg_hba.conf配置文件

shell

```
vim /usr/local/postgresql/data/pg_hba.conf
```

3.  修改配置信息

shell

```
# 所有数据库（all）、所有用户（all）、从本机（127.0.0.1/32）均可免密访问（trust）
host    all             all             0.0.0.0/0               trust
```

**注：** 

TYPE：pg的连接方式，local：本地unix套接字，host：tcp/ip连接

DATABASE：指定数据库

USER：指定数据库用户

ADDRESS：ip地址，可以定义某台主机或某个网段，32代表检查整个ip地址，相当于固定的ip，24代表只检查前三位，最后一位是0~255之间的任何一个

METHOD：认证方式，常用的有ident，md5，password，trust，reject。

*   md5是常用的密码认证方式。
    
*   password是以明文密码传送给数据库，建议不要在生产环境中使用。
    
*   trust是只要知道数据库用户名就能登录，建议不要在生产环境中使用。
    
*   reject是拒绝认证。
    

#### 11、启动服务

shell

```
pg_ctl start -l /usr/local/postgresql/log/pg_server.log
```

[![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-3-21%2015-51-45/f1a8c957-4279-479a-a8e0-43e97dbfa635.png?raw=true)
](https://img2022.cnblogs.com/blog/2608099/202207/2608099-20220715093247879-1532312564.png)

#### 12、查看版本

shell

```
 psql -v
```

[![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-3-21%2015-51-45/72f61024-1beb-45f3-9b0e-2aa7a0e0c7dd.png?raw=true)
](https://img2022.cnblogs.com/blog/2608099/202207/2608099-20220715093303194-659151025.png)

#### 13、登录数据库

shell

```
psql -U postgres -d postgres
```

[![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-3-21%2015-51-45/74b61c8a-0179-4811-b957-ad5957801de7.png?raw=true)
](https://img2022.cnblogs.com/blog/2608099/202207/2608099-20220715093317965-719668195.png)

#### 14、第三方可视化工具连接

Navicat Premium

[![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-3-21%2015-51-45/9bf5487d-d7ed-4181-9200-d293e6c8133d.png?raw=true)
](https://img2022.cnblogs.com/blog/2608099/202207/2608099-20220715093329647-501903080.png)

[![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-3-21%2015-51-45/ef387c06-7dca-43e6-b1b7-8dd1eb4d7cdd.png?raw=true)
](https://img2022.cnblogs.com/blog/2608099/202207/2608099-20220715093338168-514737045.png)

#### 15、无法远程访问

> 取消了远程访问ip的限制后，还是无法远程访问的问题
> 
> 可能原因：5432端口未开放

解决措施：

1.  直接关闭防火墙

shell

```
# 关闭防火墙
systemctl stop firewalld
# 开启防火墙
systemctl start firewalld
# 查看防火墙状态
systemctl status firewalld
# 重启防火墙
systemctl restart firewalld
```

2.  配置防火墙，开启5432端口

*   开放5432端口

shell

```
firewall-cmd --zone=public --add-port=5432/tcp --permanent
```

*   关闭5432端口

shell

```
firewall-cmd --zone=public --remove-port=5432/tcp --permanent 
``` 

*   让配置立即生效

shell

```
firewall-cmd --reload 
``` 

*   重启防火墙

shell

```
systemctl restart firewalld
```

*   查看已开放的端口

shell

```
firewall-cmd --list-ports
```

**至此postgresql安装完成**O(∩_∩)O哈哈~ヾ(◍°∇°◍)ﾉﾞ
