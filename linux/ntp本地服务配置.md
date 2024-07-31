| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2023-9月-20 | 2023-9月-20  |
| ... | ... | ... |

---

# ntp本地服务配置

[toc]

## 配置ntp本地服务器

**安装ntp**

yum 安装ntp

```bash
yum install ntp -y
systemctl enable ntpd
systemctl start ntpd
```

**修改配置文件**

```bash
vim /etc/ntp.conf
```

*配置文件模板*

```bash

driftfile /var/lib/ntp/drift

# Permit time synchronization with our time source, but do not
# permit the source to query or modify the service on this system.
restrict default nomodify notrap nopeer noquery

# Permit all access over the loopback interface.  This could
# be tightened as well, but to do so would effect some of
# the administrative functions.
restrict 127.0.0.1
restrict ::1

# Hosts on local network are less restricted.
#restrict 172.30.70.41 mask 255.255.255.0 nomodify notrap

# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
#server 0.centos.pool.ntp.org iburst
#server 1.centos.pool.ntp.org iburst
#server 2.centos.pool.ntp.org iburst
#server 3.centos.pool.ntp.org iburst

#broadcast 192.168.1.255 autokey        # broadcast server
#broadcastclient                        # broadcast client
#broadcast 224.0.1.1 autokey            # multicast server
#multicastclient 224.0.1.1              # multicast client
#manycastserver 239.255.254.254         # manycast server
#manycastclient 239.255.254.254 autokey # manycast client

# Enable public key cryptography.
#crypto

server  127.127.1.0   # local clock
fudge  127.127.1.0 stratum 10

includefile /etc/ntp/crypto/pw

# Key file containing the keys and key identifiers used when operating
# with symmetric key cryptography.
keys /etc/ntp/keys

# Specify the key identifiers which are trusted.
#trustedkey 4 8 42

# Specify the key identifier to use with the ntpdc utility.
#requestkey 8

# Specify the key identifier to use with the ntpq utility.
#controlkey 8

# Enable writing of statistics records.
#statistics clockstats cryptostats loopstats peerstats

# Disable the monitoring facility to prevent amplification attacks using ntpdc
# monlist command when default restrict does not include the noquery flag. See
# CVE-2013-5211 for more details.
# Note: Monitoring will not be disabled with the limited restriction flag.
disable monitor

```
主要参数意义 与 修改
- driftfile 硬件时间与系统时间差异记录文件，需要ntpd可写


- restrict管理权限控制
```bash 
restrict [address] mask [mask] [parameter]
```

- server设定上层NTP服务器
```bash 
server [address] [options...]
```
表示本地服务器同步的源服务器，ntp服务器允许拓扑结构

- ntp作为server配置
```bash
server 127.127.1.0
fudge 127.127.1.0 stratum 5
```

---

**NOTE**
> 其中parameter的参数主要有下面这些:
>> ignore
>>    : 拒绝所有类型的NTP联机;
>>
>> nomodify
>>    : 客户端不能使用ntpc与ntpq这两个程序来修改服务器的时间参数，但客户端仍可透过这个主机来进行网络校时;
>>
>> noquery
>>    : 客户端不能使用ntpq，ntpc等指令来查询时间服务器，等于不提供NTP的网络校时;
>>
>> notrap
>>    : 不提供trap这个远程事件登录(remote event logging)的功能;
>>
>> notrust
>>    : 拒绝没有认证的客户端;

## server 端口开放

server 服务器需要对client 开放123端口(默认)的**UDP**协议。

```bash
/usr/sbin/iptables -A INPUT -p udp -s [client_ip] --dport 123 -j ACCEPT
```

否则报错

```bash
 ntpdate[15309]: no server suitable for synchronization **found**
```

## ntp cilent 配置

在client 安装ntpd 服务器
```baah
yum install -y ntp
```

方式一：
配置 server (在 client 端)
每5-10分钟进行一次对时
vim  /etc/ntp.conf
```bash 
sed -i "s/server 127.127.1.0/server [本地server_ip]/g" /etc/ntp.conf
sed -i "s/fudge 127.127.1.0 stratum 5/#fudge 127.127.1.0 stratum 5/g" /etc/ntp.conf
```
> 关于时间间隔
> : ntpd服务 是一个有网络拓扑的架构上层服务器同步过上层服务器后才能接收下层服务器的同步请求。一般设置为 stratum 5 ，但具体的同步时间可能在5 - 10分钟之间

