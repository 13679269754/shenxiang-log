| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-8月-14 | 2024-8月-14  |
| ... | ... | ... |
---

# MySQL 8.0.19 支持 DNS SRV.md

[toc]

## 资料

[MySQL 8.0.19 支持 DNS SRV](https://my.oschina.net/actiontechoss/blog/4478043)

[使用mysqlsh搭建mysql8.0集群，并使用mysql-ruter实现负载均衡](https://blog.csdn.net/DWJRIVER/article/details/118701470)

[consul 服务注册，查询服务](https://kingfree.gitbook.io/consul/getting-started/services)

[dnsmasq（ DNS和DHCP）服务](https://www.cnblogs.com/liugp/p/16412649.html)


## 实验步骤（最后异步失败了，不知道原因，需要更多的DNS，网络方面的知识）

### 首先使用 mysql shell 创建一组 InnoDB Cluster 集群

```bash
for i in `seq 4000 4002`; do
        echo "Deploy mysql sandbox $i"
        mysqlsh -- dba deploy-sandbox-instance $i --password=root
done

echo "Create innodb cluster..."
mysqlsh root@localhost:4000 -- dba create-cluster cluster01
mysqlsh root@localhost:4000 -- cluster add-instance --recoveryMethod=clone --password=root root@localhost:4001
mysqlsh root@localhost:4000 -- cluster add-instance --recoveryMethod=clone --password=root root@localhost:4002
```

### 部署两个 mysql router 作为访问代理

```bash

for i in 6446 6556; do
        echo "Bootstrap router $i"
        mysqlrouter --user=mysql --report-host=172.29.29.100  --bootstrap root@localhost:4000 --conf-use-gr-notifications -d router_$i --conf-base-port $i --name router_$i 2>&1 >/dev/NULL
        sh /root/mysql-sandboxes/router_$i/stop.sh
        sed -i 's/level = INFO/level = DEBUG/g' /root/mysql-sandboxes/router_$i/mysqlrouter.conf
        sed -i "s/port=8443/port=5$i/g"  /root/mysql-sandboxes/router_$i/mysqlrouter.conf
        sh /root/mysql-sandboxes/router_$i/start.sh
done

```

### consul安装

[consul 下载](https://developer.hashicorp.com/consul/install?product_intent=consul)

consul启动  
`consul agent -dev -ui -client=0.0.0.0 &`  

```bash
echo "Services register..."
consul services register -name router -id router1 -port 6446 -tag rw
consul services register -name router -id router2 -port 6556 -tag rw

```

### 测试下 DNS SRV 是否能正常解析

`dig @127.0.0.1 SRV -p 8600 router.service.consul`

### dnsmasq 做本地转发

-- 生产环境可使用 BIND 服务

```bash
yum install  dnsmasq

echo 'server=/consul/127.0.0.1#8600' > /etc/dnsmasq.d/consul.conf

systemctl restart dnsmasq
```

### 测试不写明端口

`dig @127.0.0.1  router.service.consul SRV`

### 安装 python connector和 dnspython

```bash
pip install mysql-connector-python

pip install dnspython

```

### 在设置 connector 连接参数是注意 host 填写在 consul 注册的服务地址，并加上 dns_srv 参数，不需要指定端口

```python
import mysql.connector
from mysql.connector import connect

# Install dnspython using pip if you haven't already
# pip install dnspython

# Set up the DNS SRV connection configuration
config = {
    'host': 'router.service.consul',
    'user': 'root',
    'password': 'root',
    'dns_srv': True
}

# Establish the connection
cnx = connect(**config)

# Create a cursor object
cursor = cnx.cursor()

# Execute a query
query = ("SELECT @@server_id")
cursor.execute(query)

# Fetch the results
for row in cursor.fetchall():
    print(row)

# Close the cursor and connection
cursor.close()
cnx.close()
```

报错  

```bash
mysql.connector.errors.InterfaceError: Unable to locate any hosts for 'router.service.consul';
```

无法解决


### 从 MySQL Router 日志中可以看到请求以负载均衡方式发送到两边

