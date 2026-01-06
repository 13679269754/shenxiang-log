在 Ubuntu 24.04 上安装和配置 InnoDB Cluster（MySQL 集群）需要依次部署 MySQL Server、MySQL Shell、MySQL Router，并通过 MySQL Shell 配置集群。以下是完整步骤：


### **前提条件**
1. 至少 3 台 Ubuntu 24.04 服务器（或虚拟机），用于部署集群节点（1 个主节点 + 2 个从节点，确保网络互通）。
2. 每台服务器已设置静态 IP（例如：`node1: 192.168.1.10`、`node2: 192.168.1.11`、`node3: 192.168.1.12`）。
3. 关闭或配置防火墙，开放 MySQL 端口（3306、33060 等）：
   ```bash
   sudo ufw allow 3306/tcp
   sudo ufw allow 33060/tcp
   sudo ufw reload
   ```
建议第三步采用iptable.sh 脚本
```bash
#!/bin/bash
/usr/bin/systemctl stop firewalld &>/dev/null
/usr/bin/systemctl disable firewalld &>/dev/null

IPTABLES=/usr/sbin/iptables

modprobe ip_conntrack
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp

$IPTABLES -F -t filter
$IPTABLES -F -t nat
$IPTABLES -F -t mangle

$IPTABLES -X -t filter
$IPTABLES -X -t nat
$IPTABLES -X -t mangle

$IPTABLES -Z -t filter
$IPTABLES -Z -t nat
$IPTABLES -Z -t mangle

$IPTABLES -t filter -P INPUT     DROP
$IPTABLES -t filter -P OUTPUT    ACCEPT
$IPTABLES -t filter -P FORWARD   ACCEPT

$IPTABLES -t nat -P PREROUTING   ACCEPT
$IPTABLES -t nat -P POSTROUTING  ACCEPT
$IPTABLES -t nat -P OUTPUT       ACCEPT

$IPTABLES -t mangle -P INPUT     ACCEPT
$IPTABLES -t mangle -P OUTPUT    ACCEPT
$IPTABLES -t mangle -P FORWARD   ACCEPT

$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

$IPTABLES -A INPUT -p tcp -s 172.30.1.37 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.1.37 --dport 3106 -j ACCEPT

###########################################################################
$IPTABLES -A INPUT -p tcp -s 172.30.70.41 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.42 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.43 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.44 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.45 --dport 3106 -j ACCEPT

###########################################################################
/usr/sbin/iptables-save > /etc/sysconfig/iptables

```


### **步骤 1：在所有节点安装 MySQL Server**

[[ubuntu 安装mysql]]
### **步骤 2：在所有节点配置 MySQL 实例**

#### 2.1 编辑配置文件
```bash
vim /usr/local/data/mysql_data/3306/cong/my3306.cnf
```

#### 2.2 添加以下配置（根据节点调整）
**node1（192.168.1.10）配置**：
```ini
########### Group Replication 必需配置##############
report_host = 172.29.105.241
plugin_dir = "/usr/local/data/mysql/lib/plugin"


gtid_mode = ON
enforce_gtid_consistency = ON
binlog_checksum = NONE
log_bin = binlog
log_slave_updates = ON
binlog_format = ROW
master_info_repository = TABLE
relay_log_info_repository = TABLE
transaction_write_set_extraction = XXHASH64
loose-group_replication_group_name = "c342b755-8253-11f0-899b-005056ab29b6"  # 集群唯一 ID（可自定义 UUID）
loose-group_replication_start_on_boot = OFF
loose-group_replication_local_address = "172.29.105.241:33061"  # 当前节点 IP:33061
loose-group_replication_group_seeds = "172.29.105.240:3306,172.29.105.241:33061,172.29.105.241:33061"  # 所有节点
loose-group_replication_bootstrap_group = OFF  # 仅初始化集群时在主节点设为 ON

```

**node2（192.168.1.11）配置**：
- `server-id = 11`
- `loose-group_replication_local_address = "172.29.105.241:33061"`
- 其他配置与 node1 一致。

**node3（192.168.1.12）配置**：
- `server-id = 12`
- `loose-group_replication_local_address = "172.29.105.242:33061"`
- 其他配置与 node1 一致。

#### 2.3 重启 MySQL 服务
```bash
 /usr/local/data/mysql/bin/mysqladmin -S /usr/local/data/mysql_data/db3306/run/mysql3306.sock -p6inbCOdtoMtXvFjF shutdown
 
 /usr/local/data/mysql/bin/mysqld_safe --defaults-file=/usr/local/data/mysql_data/db3306/conf/my3306.cnf &2>&1 > /dev/null
```

### **步骤 3：在所有节点安装 MySQL Shell**
MySQL Shell 是管理 InnoDB Cluster 的工具，需在所有节点安装：
```bash
tar -zxvf mysql-shell-8.0.34-linux-glibc2.17-x86-64bit.tar.gz -C /usr/local/data/mysql_shell

cat >> /home/mysql/.bash_profile << 'EOF'
MYSQL_ROUTER=/usr/local/data/mysql_router
MYSQL_HOME=/usr/local/data/mysql
MYSQL_SHELL=/usr/local/data/mysql_shell
PATH=$PATH:$MYSQL_HOME/bin:$MYSQL_SHELL/bin:$MYSQL_ROUTER/bin
export PATH

source /home/mysql/.bashrc
EOF

chown -R mysql:mysql /usr/local/data/
```

注:这里先把mysql_router 的路径写上了

### **步骤 4：创建mysql用户（所有节点）**
默认 root 仅允许本地登录，需授权远程访问（用于集群节点通信）：

#### 4.1 角色初始化脚本
![[mysql 8.0 角色初始化#五、sql脚本]]

#### 4.2 用户创建以及赋权

官方建议使用
```json
dba.configureInstance()
```
来交互式的创建用户。

```sql
-- 授予角色给用户，并允许用户激活该角色
GRANT `group_replication_manager` TO 'dzjroot'@'%';

-- 设置用户默认激活该角色（登录后自动拥有角色权限）
SET DEFAULT ROLE `group_replication_manager` TO 'dzjroot'@'%';
```


### **步骤 5：通过 MySQL Shell 创建 InnoDB Cluster**
在 **node1（主节点）** 操作：

#### 5.1 启动 MySQL Shell 并连接到本地实例
```bash
mysqlsh
\connect dzjroot@192.168.1.10:3306  # 输入 root 密码
```

#### 5.2 检查实例是否符合集群要求
```sql
dba.checkInstanceConfiguration('dzjroot@192.168.1.10')
```
- 若提示配置问题，按提示修复（例如执行 `dba.configureInstance(...)`）。

#### 5.3 创建集群
```sql
var cluster = dba.createCluster('my_innodb_cluster')  # 集群名称自定义
```

#### 5.4 添加 node2 和 node3 到集群
```sql
cluster.addInstance('root@192.168.1.11')  # 输入 node2 的 root 密码
cluster.addInstance('root@192.168.1.12')  # 输入 node3 的 root 密码
```
- 添加过程中会自动配置复制，选择默认的“ incremental ”方式同步数据。

#### 5.5 验证集群状态
```sql
cluster.status()
```
- 输出应显示 3 个节点，其中 1 个为 `PRIMARY`（主节点），2 个为 `SECONDARY`（从节点）。



### **步骤 6：安装和配置 MySQL Router**
MySQL Router 用于自动路由客户端连接到集群（主节点负责写，从节点负责读），需在 **应用服务器** 或 **集群节点** 安装：

#### 6.1 安装 MySQL Router
```bash
sudo apt install -y mysql-router
## or
tar -zxvf mysql-router-8.0.34-linux-glibc2.17-x86_64.tar.gz -C /usr/local/data/
mv /usr/local/data/mysql-router-8.0.34-linux-glibc2.17-x86_64/ mysql_router

```

#### 6.2 配置 Router（连接到集群）

```sql
-- 创建mysql_router用户并赋权
-- 创建元数据读取用户
CREATE USER 'router_metadata_reader'@'router_host_ip' IDENTIFIED BY '密码';

-- 授予元数据读取权限
GRANT SELECT ON mysql_innodb_cluster_metadata.* TO 'router_metadata_reader'@'router_host_ip';
GRANT SELECT ON performance_schema.replication_group_members TO 'router_metadata_reader'@'router_host_ip';
```

```bash                        
sudo mysqlrouter --bootstrap root@192.168.1.10 --user=mysqlrouter
```
- 输入 root 密码后，Router 会自动生成配置文件（默认路径：`/etc/mysqlrouter/mysqlrouter.conf`）。
- 输出会显示 Router 的端口信息（例如：写端口 6446，读端口 6447）。

#### 6.3 启动 MySQL Router
```bash
sudo systemctl start mysqlrouter
sudo systemctl enable mysqlrouter
```


### **步骤 7：测试 InnoDB Cluster**
1. 通过 Router 连接集群（写操作自动路由到主节点）：
   ```bash
   mysql -h 127.0.0.1 -P 6446 -u root -p  # 6446 是写端口
   ```

2. 创建测试数据库和表：
   ```sql
   CREATE DATABASE test_cluster;
   USE test_cluster;
   CREATE TABLE messages (id INT AUTO_INCREMENT PRIMARY KEY, content VARCHAR(100));
   INSERT INTO messages (content) VALUES ('Hello InnoDB Cluster');
   ```

3. 在 node2 或 node3 验证数据同步：
   ```bash
   mysql -u root -p -e "SELECT * FROM test_cluster.messages"
   ```
   - 应能看到刚插入的数据，说明复制正常。

4. 测试故障转移（可选）：
   - 停止主节点（node1）的 MySQL 服务：`sudo systemctl stop mysql`。
   - 等待 30 秒后，在 MySQL Shell 中查看集群状态：`cluster.status()`，应显示新的主节点被选举出来。


### **常见问题解决**
![[innodb cluster 搭建问题处理]]
- **节点添加失败**：检查网络连通性、MySQL 配置文件中的 `group_replication` 参数是否正确、防火墙是否开放 33061 端口。
- **数据同步延迟**：确保节点间时间同步（可安装 `ntp` 服务）。
- **Router 无法连接集群**：检查 `mysqlrouter.conf` 中的集群地址是否正确，重启 Router 服务。


通过以上步骤，即可在 Ubuntu 24.04 上搭建一个高可用的 InnoDB Cluster。