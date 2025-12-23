---

mindmap-plugin: markdown

---


# Proxmox Ceph 搭建教程


## 1. 安装 PVE


### 节点信息


| 节点名称               | IP 地址      |
|------------------------|--------------|
| pve-s1-bs.dazhuanjia.com | 172.30.2.17 |
| pve-s2-bs.dazhuanjia.com | 172.30.2.18 |
| pve-s3-bs.dazhuanjia.com | 172.30.2.19 |


### 配置网络


```bash
# 备份原有网络配置
cp /etc/network/interfaces /etc/network/interfaces.bak

# 编辑网络配置文件
nano /etc/network/interfaces
```


将以下内容写入配置文件：


```bash
# 物理网卡（从网卡）：禁用IP，仅用于绑定
auto ens2f0
iface ens2f0 inet manual
    bond-master public

auto ens4f0
iface ens4f0 inet manual
    bond-master public

auto ens2f1
iface ens2f1 inet manual
    bond-master cluster

auto ens4f1
iface ens4f1 inet manual
    bond-master cluster

# public绑定组（LACP模式）
auto public
iface public inet manual
    bond-slaves ens2f0 ens4f0
    bond-mode 802.3ad
    bond-xmit-hash-policy layer3+4
    bond-miimon 100
    bond-lacp-rate slow

# cluster绑定组（LACP模式）
auto cluster
iface cluster inet manual
    bond-slaves ens2f1 ens4f1
    bond-mode 802.3ad
    bond-xmit-hash-policy layer3+4
    bond-miimon 100
    bond-lacp-rate slow

# public.200 VLAN子接口（外部通信）
auto public.200
iface public.200 inet static
    address 172.30.2.17/24
    gateway 172.30.2.254
    dns-nameservers 8.8.8.8 114.114.114.114

# cluster.1001 VLAN子接口（集群内部）
auto cluster.1001
iface cluster.1001 inet static
    address 1.1.1.17/24
```


重启网络服务：


```bash
systemctl restart networking
```


### 合并分区


```bash
# 删除原有data逻辑卷
lvremove pve/data  # 输入y确认删除
# 扩展root逻辑卷至全部空闲空间
lvextend -l +100%FREE -r pve/root
```


登录 Proxmox Web 管理平台，进行以下操作：

1. 进入 **数据中心 → 存储**
2. 删除 `local-lvm` 存储
3. 编辑 `local` 存储，勾选所有存储类型（镜像、ISO、容器、虚拟机磁盘等），保存完成配置

### 换源配置


#### 配置 Ceph 源（中科大源）


```bash
mv /etc/apt/sources.list.d/ceph.sources /etc/apt/sources.list.d/ceph.sources.bak
cat > /etc/apt/sources.list.d/ceph.sources << EOF
Types: deb
URIs: https://mirrors.ustc.edu.cn/proxmox/debian/ceph-squid
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
```


#### 配置 Debian 系统源（中科大源）


```bash
mv /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian.sources.bak
cat > /etc/apt/sources.list.d/debian.sources << EOF
Types: deb
URIs: https://mirrors.ustc.edu.cn/debian
Suites: trixie trixie-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://mirrors.ustc.edu.cn/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
```


#### 配置 PVE 源（替换企业源为中科大免费源）


```bash
mv /etc/apt/sources.list.d/pve-enterprise.sources /etc/apt/sources.list.d/pve-enterprise.sources.bak
cat > /etc/apt/sources.list.d/pve-no-subscription.sources << EOF
Types: deb
URIs: https://mirrors.ustc.edu.cn/proxmox/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
```


更新软件源缓存：


```bash
apt clean && apt update -y
```


### 添加节点到集群


通过 Proxmox Web 管理平台，将 `pve-s2-bs`、`pve-s3-bs` 节点添加到以 `pve-s1-bs` 为核心的集群中。


## 2. 安装 Ceph


可通过两种方式安装 Ceph：

1. **Proxmox Web 管理页面安装**：进入 **数据中心 → Ceph → 安装**，选择目标节点和 Ceph 版本进行安装。
2.  **命令行安装**：在所有节点执行以下命令：
    ```bash
    apt install ceph -y
    ```

安装完成后，配置 Ceph 节点、监控（MON）、管理器（MGR）等组件。


### 2.1 OSD 创建


#### 2.1.1 SSD OSD


直接通过 Proxmox Web 管理页面，选中 SSD 磁盘，点击 **创建 OSD** 完成配置。


#### 2.1.2 HDD OSD


##### 2.1.2.1 缓存盘处理


以九百多G的磁盘作为缓存盘，执行以下命令：


```bash
# 进入磁盘分区工具
gdisk /dev/sd***

# 操作步骤（交互模式）
o  # 创建GPT分区表
n  # 创建新分区，分区类型选择 8e00（LVM类型）
p  # 预览分区信息
w  # 保存分区配置并退出

# 创建物理卷和卷组
pvcreate /dev/sda1
vgcreate ceph-cache-sda1 /dev/sda1
```


##### 2.1.2.2 数据盘处理


无需特殊分区处理，直接在 Proxmox Web 管理页面创建 OSD：

1. 选中空闲 HDD 数据盘
2. 在缓存盘选项中，选择已创建的 `ceph-cache-sda1` 卷组
3. 一个数据盘对应创建一个 OSD

### 2.2 创建资源池


在 Proxmox Web 管理平台或命令行创建两个三副本资源池：


```bash
# 创建 SSD 资源池
ceph osd pool create iaas_ssd_pool 128 128 replicated 3

# 创建 HDD 资源池
ceph osd pool create iaas_hdd_pool 128 128 replicated 3
```


### 2.3 OSD Crush Rule


#### 2.3.1 OSD 绑定资源池规则名称

- SSD 资源池规则：`ssd-osd-rule`
- HDD 资源池规则：`hdd-osd-rule`

#### 2.3.2 规则内容


执行以下命令创建 Crush 规则：


```bash
# 创建 HDD 资源池规则
ceph osd crush rule create-replicated hdd-osd-rule default host class hdd

# 创建 SSD 资源池规则
ceph osd crush rule create-replicated ssd-osd-rule default host class ssd
```


### 2.4 iSCSI 网关配置（对外暴露）


#### 2.4.1 RBD 后端配置


在所有节点安装 iSCSI 网关依赖：


```bash
apt install -y ceph-iscsi tcmu-runner targetcli-fb
apt update && apt install jq targetcli-fb -y
```


#### 2.4.2 节点 172.30.2.17 执行命令


**步骤 1：安装依赖（仅首次执行）**


```bash
apt update && apt install jq targetcli-fb -y
```


**步骤 2：配置 iSCSI 目标器**


```bash
targetcli << EOF
# 1. 创建 RBD 后端
/backstores/user:rbd create iaas_hdd_backend cfgstring=iaas_hdd_pool/iaas_hdd size=7T
/backstores/user:rbd create iaas_ssd_backend cfgstring=iaas_ssd_pool/iaas_ssd size=6500G

# 2. 创建 iSCSI 目标器
/iscsi create iqn.2025-12.dzj.com:ceph-iscsi-storage

# 3. 映射 LUN（HDD→LUN0，SSD→LUN1）
/iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1/luns create /backstores/user:rbd/iaas_hdd_backend
/iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1/luns create /backstores/user:rbd/iaas_ssd_backend

# 4. 配置访问权限（允许所有客户端）
/iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1/acls create iqn.2025-12.dzj.com:client-*

# 5. 保存配置
saveconfig

# 退出
exit
EOF
```


**步骤 3：验证配置（可选）**


```bash
# 查看后端创建状态
targetcli ls /backstores/user:rbd

# 查看 iSCSI 目标器状态
targetcli ls /iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1
```


#### 2.4.3 节点 172.30.2.18 执行命令


**步骤 1：安装依赖（仅首次执行）**


```bash
apt update && apt install jq targetcli-fb -y
```


**步骤 2：配置 iSCSI 目标器**


```bash
targetcli << EOF
# 1. 创建 RBD 后端
/backstores/user:rbd create iaas_hdd_backend cfgstring=iaas_hdd_pool/iaas_hdd size=7T
/backstores/user:rbd create iaas_ssd_backend cfgstring=iaas_ssd_pool/iaas_ssd size=6500G

# 2. 创建 iSCSI 目标器
/iscsi create iqn.2025-12.dzj.com:ceph-iscsi-storage

# 3. 映射 LUN（HDD→LUN0，SSD→LUN1）
/iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1/luns create /backstores/user:rbd/iaas_hdd_backend
/iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1/luns create /backstores/user:rbd/iaas_ssd_backend

# 4. 配置访问权限
/iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1/acls create iqn.2025-12.dzj.com:client-*

# 5. 保存配置
saveconfig
exit
EOF
```


**步骤 3：验证配置（可选）**


```bash
targetcli ls /backstores/user:rbd
targetcli ls /iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1
```


#### 2.4.4 节点 172.30.2.19 执行命令


**步骤 1：安装依赖（仅首次执行）**


```bash
apt update && apt install jq targetcli-fb -y
```


**步骤 2：配置 iSCSI 目标器**


```bash
targetcli << EOF
# 1. 创建 RBD 后端
/backstores/user:rbd create iaas_hdd_backend cfgstring=iaas_hdd_pool/iaas_hdd size=7T
/backstores/user:rbd create iaas_ssd_backend cfgstring=iaas_ssd_pool/iaas_ssd size=6500G

# 2. 创建 iSCSI 目标器
/iscsi create iqn.2025-12.dzj.com:ceph-iscsi-storage

# 3. 映射 LUN
/iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1/luns create /backstores/user:rbd/iaas_hdd_backend
/iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1/luns create /backstores/user:rbd/iaas_ssd_backend

# 4. 配置访问权限
/iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1/acls create iqn.2025-12.dzj.com:client-*

# 5. 保存配置
saveconfig
exit
EOF
```


**步骤 3：验证配置（可选）**


```bash
targetcli ls /backstores/user:rbd
targetcli ls /iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1
```


#### 2.4.5 批量处理认证


关闭 iSCSI 认证和 ACL 限制：


```bash
targetcli
cd /iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1
set attribute authentication=0
set attribute generate_node_acls=1
exit
```


### 2.5 后续扩容通用命令


任意节点执行以下命令，批量同步 3 节点配置（需配置节点间免密登录）：


```bash
# 示例：扩容 HDD 镜像到 8T
rbd resize iaas_hdd_pool/iaas_hdd --size 8T

# 批量更新 3 个节点的配置
for node_ip in 172.30.2.17 172.30.2.18 172.30.2.19; do
  ssh root@$node_ip "targetcli << EOF
/iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1/luns delete 0
/backstores/user:rbd delete iaas_hdd_backend
/backstores/user:rbd create iaas_hdd_backend cfgstring=iaas_hdd_pool/iaas_hdd size=8T
/iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1/luns create /backstores/user:rbd/iaas_hdd_backend
saveconfig
exit
EOF"
done
```


## 3. 高可用配置


### 步骤 1：所有网关统一安装依赖


```bash
apt update && apt install keepalived -y
# 启动并开机自启相关服务
systemctl enable --now rbd-target-gw
systemctl enable --now rbd-target-api
systemctl enable --now tcmu-runner
```


### 步骤 2：所有网关配置 VIP 切换脚本


创建脚本文件 `/etc/keepalived/iscsi_switch.sh`：


```bash
#!/bin/bash
# 配置参数
IQN="iqn.2025-12.dzj.com:ceph-iscsi-storage"
CONF_FILE="/etc/target/saveconfig.json"
LOG_FILE="/var/log/iscsi_ha_switch.log"

# 日志函数
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

# 核心逻辑：根据 keepalived 状态启停 iSCSI
case "$1" in
    "master")
        log "当前节点成为主节点，启用 iSCSI 目标"
        targetcli restoreconfig $CONF_FILE &>/dev/null
        targetcli /iscsi/${IQN}/tpg1 set attribute enabled=1 &>/dev/null
        targetcli saveconfig &>/dev/null
        ;;
    "backup")
        log "当前节点成为备节点，禁用 iSCSI 目标"
        targetcli /iscsi/${IQN}/tpg1 set attribute enabled=0 &>/dev/null
        targetcli saveconfig &>/dev/null
        ;;
    "fault")
        log "当前节点故障，禁用 iSCSI 目标"
        targetcli /iscsi/${IQN}/tpg1 set attribute enabled=0 &>/dev/null
        targetcli saveconfig &>/dev/null
        ;;
    *)
        log "无效参数：$1，仅支持 master/backup/fault"
        exit 1
        ;;
esac
```


赋予脚本执行权限并创建日志文件：


```bash
chmod +x /etc/keepalived/iscsi_switch.sh
touch /var/log/iscsi_ha_switch.log
chmod 644 /var/log/iscsi_ha_switch.log
```


### 步骤 3：分节点配置 keepalived.conf


#### 3.1 主网关（172.30.2.17）配置


创建 `/etc/keepalived/keepalived.conf`：


```bash
! Configuration File for keepalived

global_defs {
   router_id ISCSI_HA  # 自定义标识，全网唯一
}

vrrp_instance VI_1 {
    state MASTER        # 主节点
    interface eth0      # 替换为实际业务网卡
    virtual_router_id 51 # 同一集群需相同（51-255 之间）
    priority 100        # 主节点优先级最高
    advert_int 0.5      # 检测间隔
    garp_master_delay 0.1 # VIP 漂移后立即发 ARP 广播

    # 认证配置
    authentication {
        auth_type PASS
        auth_pass Dzj20251222  # 自定义密码
    }

    # 绑定 VIP
    virtual_ipaddress {
        172.30.2.20/24 dev eth0  # 替换为实际网卡
    }

    # 状态切换触发脚本
    notify_master "/etc/keepalived/iscsi_switch.sh master"
    notify_backup "/etc/keepalived/iscsi_switch.sh backup"
    notify_fault "/etc/keepalived/iscsi_switch.sh fault"
}
```


#### 3.2 备用网关 1（172.30.2.18）配置


创建 `/etc/keepalived/keepalived.conf`：


```bash
! Configuration File for keepalived

global_defs {
   router_id ISCSI_HA
}

vrrp_instance VI_1 {
    state BACKUP         # 备节点
    interface eth0
    virtual_router_id 51
    priority 90          # 低于主节点
    advert_int 0.5
    garp_master_delay 0.1

    authentication {
        auth_type PASS
        auth_pass 1111
    }

    virtual_ipaddress {
        172.30.2.20/24 dev eth0
    }

    notify_master "/etc/keepalived/iscsi_switch.sh master"
    notify_backup "/etc/keepalived/iscsi_switch.sh backup"
    notify_fault "/etc/keepalived/iscsi_switch.sh fault"
}
```


#### 3.3 备用网关 2（172.30.2.19）配置


创建 `/etc/keepalived/keepalived.conf`，仅修改 `priority` 为 80，其余与备用网关 1 一致：


```bash
! Configuration File for keepalived

global_defs {
   router_id ISCSI_HA
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 80  # 最低优先级
    advert_int 0.5
    garp_master_delay 0.1

    authentication {
        auth_type PASS
        auth_pass 1111
    }

    virtual_ipaddress {
        172.30.2.20/24 dev eth0
    }

    notify_master "/etc/keepalived/iscsi_switch.sh master"
    notify_backup "/etc/keepalived/iscsi_switch.sh backup"
    notify_fault "/etc/keepalived/iscsi_switch.sh fault"
}
```


### 步骤 4：启动并验证 keepalived 服务


所有网关执行以下命令：


```bash
# 启动服务并设置开机自启
systemctl enable --now keepalived

# 检查服务状态
systemctl status keepalived
```


### 步骤 5：验证配置

1.  **验证 VIP 绑定**：仅主网关会显示 VIP
    ```bash
    ip addr show eth0  # 查看是否存在 172.30.2.20/24
    ```
2.  **验证 iSCSI 状态**
    ```bash
    # 主网关应显示 enabled=1
    targetcli ls /iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1 | grep enabled
    
    # 备用网关应显示 enabled=0
    targetcli ls /iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1 | grep enabled
    ```

### 步骤 6：配置文件同步脚本（可选）


创建 `/usr/local/bin/sync_iscsi_config.sh` 脚本，用于主网关配置修改后同步到备用网关：


```bash
#!/bin/bash
# 配置参数
MASTER_GW="172.30.2.17"
BACKUP_GWS=("172.30.2.18" "172.30.2.19")
CONF_FILE="/etc/target/saveconfig.json"
LOG_FILE="/var/log/iscsi_config_sync.log"

# 日志函数
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

# 1. 主网关保存最新配置
log "主网关保存最新配置"
ssh root@$MASTER_GW "targetcli saveconfig"

# 2. 同步配置到备用网关
for gw in "${BACKUP_GWS[@]}"; do
    log "同步配置到备用网关 $gw"
    scp root@$MASTER_GW:$CONF_FILE root@$gw:$CONF_FILE
    ssh root@$gw "targetcli restoreconfig $CONF_FILE && targetcli /iscsi/iqn.2025-12.dzj.com:ceph-iscsi-storage/tpg1 set attribute enabled=0 && targetcli saveconfig"
done

log "配置同步完成"
exit 0
```


赋予执行权限并执行：


```bash
chmod +x /usr/local/bin/sync_iscsi_config.sh
/usr/local/bin/sync_iscsi_config.sh
```


## 4. 故障切换验证


在主网关执行以下命令，模拟主节点故障：


```bash
systemctl stop keepalived
```


验证备用网关是否自动接管 VIP 和 iSCSI 服务：

1. 查看备用网关的 VIP 绑定情况
2. 检查备用网关的 iSCSI 服务状态是否变为 `enabled=1`

故障恢复后，重启主网关 `keepalived` 服务，验证 VIP 是否漂移回主节点。

