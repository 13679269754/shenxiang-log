#################################################################
# 说明：
# 脚本用于orientdb备份和恢复,备份恢复周期为每天，数据为T+1
# 步骤：
# 1.备份backup服务器的orientdb
# 2.关闭retore服务器orientdb集群全部服务
# 3.scp传输到restore服务器
# 4.在restore服务器覆盖恢复备份文件
# 5.启动restore orientdb
# 要求：
#   1.SOURCE_SERVER 需要安装sshpass
#   2.使用TARGET_CLUSTER_SERVER的话，需要ssh密码一致
#################################################################

#!/bin/bash

# 日志文件路径
LOG_FILE="orientdb_backup_restore.log"


# 企业微信通知脚本路径
QYWECHAT_NOTIFY_SCRIPT="/usr/local/bin/python3 /root/script/qywechat_notify.py"

# 记录日志函数
log() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp - $1" | tee -a "$LOG_FILE"
}


# 发送企业微信通知函数
send_qywechat_notify() {
    local status="$1"
    local title="数据库日常 ORIENTDB 数据同步任务信息"
    if [ "$status" = "info" ]; then
        local msg="${SOURCE_SERVER} orientdb restore to 恢复地址 ${TARGET_SERVER} Success !!!!!"
    else
        local msg="${SOURCE_SERVER} orientdb restore to 恢复地址 ${TARGET_SERVER} Failed, please check !!!!!"
    fi
    $QYWECHAT_NOTIFY_SCRIPT "$status" "$title" "$msg"
}

# 显示帮助信息
show_help() {
    echo "此脚本用于 OrientDB 数据库的备份和恢复操作，支持多服务器之间的数据传输。"
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  --source-server <IP>               源服务器 IP 地址"
    echo "  --target-server <IP>               目标服务器 IP 地址"
    echo "  --target-cluster-server <IP>       目标服务器集群 IP 地址,当目标orientdb是集群时需要输入，第一个ip为恢复操作实际执行的节点,节点之间用逗号分割"
    echo "  --source-orientdb-home <目录>      源服务器上 OrientDB 的主目录"
    echo "  --target-orientdb-home <目录>      目标服务器上 OrientDB 的主目录"
    echo "  --source-database-path <路径>      源服务器上数据库路径，如 /data/orientdb/databases/dzj"
    echo "  --target-database-path <路径>      目标服务器上数据库路径，如 /data/orientdb/databases/dzj"
    echo "  --username <用户名>                数据库用户名"
    echo "  --password <密码>                  数据库密码"
    echo "  --backup-dir <目录>                备份文件存储目录"
    echo "  --backup-retention-days <天数>     备份保留天数，默认值为 7 天"
    echo "  --source-ssh-pass <密码>           源服务器 SSH 密码"
    echo "  --target-ssh-pass <密码>           目标服务器(集群) SSH 密码"
    echo "  --help                             显示此帮助信息"
    echo "示例: $0 --source-server 192.168.1.100 --target-server 192.168.1.101 --source-orientdb-home /usr/local/data/orientdb-server/bin --target-orientdb-home /usr/local/data/orientdb-server/bin --source-database-path data/orientdb/databases/dzj --target-database-path /data/orientdb/databases/dzj --username admin --password cmHKfV269q0ZR1MrW --backup-dir /usr/local/data/backup --backup-retention-days 7 --source-ssh-pass your_source_ssh_pass --target-ssh-pass your_target_ssh_pass"
}

# 解析命令行参数
BACKUP_RETENTION_DAYS=30
SOURCE_BACKUP_RETENTION_DAYS=7
SOURCE_SSH_PASS='dzj123,./'
TARGET_SSH_PASS='dzj123,./'
USERNAME='admin'
PASSWORD='cmHKfV269q0ZR1MrW'
BACKUP_DIR=/usr/local/data/backup/orientdb/
SOURCE_DATABASE_PATH='/usr/local/data/orientdb-server/databases/dzj'
TARGET_DATABASE_PATH='/usr/local/data/orientdb-server/databases/dzj'
SOURCE_ORIENTDB_HOME='/usr/local/data/orientdb-server/bin'
TARGET_ORIENTDB_HOME='/usr/local/data/orientdb-server/bin'
SOURCE_SERVER='172.29.29.105'
TARGET_CLUSTER_SERVER='172.29.29.104,172.29.29.103'

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source-server)
            SOURCE_SERVER="$2"
            shift 2
            ;;
        --target-server)
            TARGET_SERVER="$2"
            shift 2
            ;;
        --target-cluster-server)
            TARGET_CLUSTER_SERVER="$2"
            shift 2
            ;;
        --source-orientdb-home)
            SOURCE_ORIENTDB_HOME="$2"
            shift 2
            ;;
        --target-orientdb-home)
            TARGET_ORIENTDB_HOME="$2"
            shift 2
            ;;
        --source-database-path)
            SOURCE_DATABASE_PATH="$2"
            shift 2
            ;;
        --target-database-path)
            TARGET_DATABASE_PATH="$2"
            shift 2
            ;;
        --username)
            USERNAME="$2"
            shift 2
            ;;
        --password)
            PASSWORD="$2"
            shift 2
            ;;
        --backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        --backup-retention-days)
            BACKUP_RETENTION_DAYS="$2"
            shift 2
            ;;
        --source-ssh-pass)
            SOURCE_SSH_PASS="$2"
            shift 2
            ;;
        --target-ssh-pass)
            TARGET_SSH_PASS="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 检查必要的参数是否提供
if [[ -z "$SOURCE_SERVER" ||
      ( -z "$TARGET_SERVER" && -z "$TARGET_CLUSTER_SERVER" ) ||
      -z "$SOURCE_ORIENTDB_HOME" ||
      -z "$TARGET_ORIENTDB_HOME" ||
      -z "$SOURCE_DATABASE_PATH" ||
      -z "$TARGET_DATABASE_PATH" ||
      -z "$USERNAME" ||
      -z "$PASSWORD" ||
      -z "$BACKUP_DIR" ||
      -z "$SOURCE_SSH_PASS" ||
      -z "$TARGET_SSH_PASS" ]]; then
    log "错误: 缺少必要的参数。"
    show_help
    exit 1
fi

# 检查TARGET_CLUSTER_SERVER是否符合要求
if [[ ! -z "$TARGET_CLUSTER_SERVER" ]]; then
    if  [[ "$TARGET_CLUSTER_SERVER" != *","* ]]; then
        echo "输入错误：TARGET_CLUSTER_SERVER必须是用逗号分隔的IP列表"
        send_qywechat_notify "error"
        exit 1
    else
    # 分割IP列表
        IFS=',' read -ra SERVERS <<< "$TARGET_CLUSTER_SERVER"
        TARGET_SERVER="${SERVERS[0]}"  # 将第一个服务器设为目标服务器
    fi
fi


##################################################################
# 检查集群实例状态
##################################################################
check_cluster_shutdown() {
    local servers=($1)  # 以空格分隔的服务器列表
    local ssh_pass=$2
    local success=true

    log "开始检查集群实例状态..."

    for server in "${servers[@]}"; do
        log "检查服务器: $server"

        # 尝试连接服务器并执行简单命令（如检查进程）
        if ssh_with_pass "$ssh_pass" "$server" "systemctl is-active orientdb --quiet" ; then
            log "服务器 $server 仍在运行"
            success=false
        else
            log "服务器 $server 已关闭"
        fi
    done

    $success
}

# 主函数：带重试机制的集群关闭检查
wait_for_cluster_shutdown() {
    local servers=($1)
    local ssh_pass=$2
    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        if check_cluster_shutdown "${servers[*]}" "$ssh_pass"; then
            log "所有集群实例已成功关闭"
            return 0
        fi

        retry_count=$((retry_count + 1))
        log "检查失败，剩余重试次数: $((max_retries - retry_count))"

        if [ $retry_count -lt $max_retries ]; then
            log "等待 5 秒后重试..."
            sleep 5
        fi
    done

    log "错误：经过 $max_retries 次尝试，仍有集群实例在运行"
    return 1
}


# 检查集群实例是否已成功启动
check_cluster_startup() {
    local servers=($1)  # 以空格分隔的服务器列表
    local ssh_pass=$2
    local success=true

    log "开始检查集群实例状态..."

    for server in "${servers[@]}"; do
        log "检查服务器: $server"

        # 使用 ps 命令检查 OrientDB 进程是否存在
        if ssh_with_pass "$ssh_pass" "$server" "systemctl is-active orientdb --quiet"; then
            log "服务器 $server 上的 OrientDB 进程正在运行"
        else
            log "服务器 $server 上的 OrientDB 进程未运行"
            success=false
        fi
    done

    $success
}

# 主函数：带重试机制的集群启动检查
wait_for_cluster_startup() {
    local servers=($1)
    local ssh_pass=$2
    local db_username=$3
    local db_password=$4
    local max_retries=5  # 增加重试次数，因为启动可能需要更长时间
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        if check_cluster_startup "${servers[*]}" "$ssh_pass" "$db_username" "$db_password"; then
            log "所有集群实例已成功启动"
            return 0
        fi

        retry_count=$((retry_count + 1))
        log "检查失败，剩余重试次数: $((max_retries - retry_count))"

        if [ $retry_count -lt $max_retries ]; then
            log "等待 10 秒后重试..."  # 增加等待时间，给服务器更多启动时间
            sleep 10
        fi
    done

    log "错误：经过 $max_retries 次尝试，仍有集群实例未成功启动"
    return 1
}

###################################################################


# 确保 sshpass 已安装
if ! command -v sshpass &> /dev/null; then
    log "sshpass 未安装，正在尝试安装..."
    if command -v apt &> /dev/null; then
        sudo apt-get update
        sudo apt-get install sshpass -y
    elif command -v yum &> /dev/null; then
        sudo yum install sshpass -y
    else
        log "不支持的包管理器，无法安装 sshpass。"
        send_qywechat_notify "error"
        exit 1
    fi
    log "sshpass 安装完成。"
fi

# 带密码的 ssh 函数
ssh_with_pass() {
    local ssh_pass=$1
    local ssh_host=$2
    local ssh_command=$3
    log "sshpass -p $ssh_pass ssh $ssh_host $ssh_command"
    sshpass -p "$ssh_pass" ssh "$ssh_host" "$ssh_command"
}


DATE=$(date +"%Y%m%d")

log "$DATE orientdb 备份 ###################################################################################################"

# 确保备份目录存在
log "检查并创建备份目录: $BACKUP_DIR"
ssh_with_pass "$SOURCE_SSH_PASS" "$SOURCE_SERVER" "mkdir -p $BACKUP_DIR"
ssh_with_pass "$TARGET_SSH_PASS" "$TARGET_SERVER" "mkdir -p $BACKUP_DIR"

# 生成备份文件名
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.zip"


# 关闭备份orientdb实例
ssh_with_pass "$SOURCE_SSH_PASS" "$SOURCE_SERVER" "systemctl stop orientdb.service"

# 确认备份orientdb实例为关闭状态
wait_for_cluster_shutdown "$SOURCE_SERVER" "$SOURCE_SSH_PASS"
if [ $? -eq 0 ]; then
    log "备份实例${SOURCE_SERVER}已成功关闭，可以继续恢复操作"
else
    log "备份实例${SOURCE_SERVER}关闭检查失败"
    send_qywechat_notify "error"
    exit 1
fi

# 执行备份操作
log "开始备份数据库: $SOURCE_DATABASE_PATH"
ssh_with_pass "$SOURCE_SSH_PASS" "$SOURCE_SERVER" "$SOURCE_ORIENTDB_HOME/backup.sh plocal:$SOURCE_DATABASE_PATH $USERNAME $PASSWORD $BACKUP_FILE"
if  [ ! $? -eq 0 ];then
    log "备份失败 ++++++++++++++++++++++++++++++++++++++"
    log $?
    send_qywechat_notify "error"
    exit 1
fi

# 开启备份实例
ssh_with_pass "$SOURCE_SSH_PASS" "$SOURCE_SERVER" "systemctl start orientdb.service"

# 确认备份orientdb实例为开启状态
wait_for_cluster_startup "$SOURCE_SERVER" "$SOURCE_SSH_PASS" "$USERNAME" "$PASSWORD"


# 使用 scp 传输备份文件到目标服务器
log "开始将备份文件传输到目标服务器: $TARGET_SERVER"
ssh_with_pass "$SOURCE_SSH_PASS" "$SOURCE_SERVER" "sshpass -p \"$TARGET_SSH_PASS\" scp  $BACKUP_FILE $TARGET_SERVER:$BACKUP_DIR"

if [ $? -eq 0 ]; then
    log "备份文件传输成功，可以继续恢复操作"
else
    log "备份文件传输失败"
    send_qywechat_notify "error"
    exit 1
fi


###################################################################
# 处理集群服务器列表，且关闭恢复集群实例
###################################################################
if [ ! -z "$TARGET_CLUSTER_SERVER" ]; then
    # 遍历所有服务器执行关闭命令
    for server in "${SERVERS[@]}"; do
        echo "正在关闭服务器: $server"
        ssh_with_pass "$TARGET_SSH_PASS" "$server" "systemctl stop orientdb.service"
    done
else
    # TARGET_CLUSTER_SERVER为空，仅关闭目标服务器
    echo "正在关闭目标服务器: $TARGET_SERVER"
    ssh_with_pass "$TARGET_SSH_PASS" "$TARGET_SERVER" "systemctl stop orientdb.service"
fi


####################################################################
# 判断集群实例是否已经全部关闭
####################################################################
SERVERS=($(echo "$TARGET_CLUSTER_SERVER" | tr ',' ' '))

# 如果没有集群服务器列表，则只检查目标服务器
if [ ${#SERVERS[@]} -eq 0 ]; then
    SERVERS=("$TARGET_SERVER")
fi

# 等待集群关闭
wait_for_cluster_shutdown "${SERVERS[*]}" "$TARGET_SSH_PASS"

if [ $? -eq 0 ]; then
    log "集群已成功关闭，可以继续恢复操作"
else
    log "集群关闭检查失败"
    send_qywechat_notify "error"
    exit 1
fi

#####################################################################

log "开始在目标服务器上恢复数据库"
restore_output=$(ssh_with_pass "$TARGET_SSH_PASS" "$TARGET_SERVER" "$TARGET_ORIENTDB_HOME/console.sh <<EOF
CONNECT embedded:$TARGET_DATABASE_PATH $USERNAME $PASSWORD
RESTORE DATABASE $BACKUP_FILE
EXIT
EOF"
2>&1)

# 检查是否包含成功标志
if echo "$restore_output" | grep -q -i "Database restored in"; then
    log "恢复成功"
else
    log "恢复失败: 未检测到成功标志"
    log "$restore_output"
    send_qywechat_notify "error"
    exit 1
fi



log "恢复操作完成。"
####################################################################
# 启动恢复集群实例
####################################################################
if [ ! -z "$TARGET_CLUSTER_SERVER" ]; then
    # 分割IP列表
    IFS=',' read -ra SERVERS <<< "$TARGET_CLUSTER_SERVER"
    TARGET_SERVER="${SERVERS[0]}"  # 将第一个服务器设为目标服务器

    # 遍历所有服务器执行关闭命令
    for server in "${SERVERS[@]}"; do
        echo "正在启动服务器: $server"
        ssh_with_pass "$TARGET_SSH_PASS" "$server" "systemctl start orientdb.service"
    done
else
    # TARGET_CLUSTER_SERVER为空，仅关闭目标服务器
    echo "正在启动目标服务器: $TARGET_SERVER"
    ssh_with_pass "$TARGET_SSH_PASS" "$TARGET_SERVER" "systemctl start orientdb.service"
fi


# 等待集群启动
wait_for_cluster_startup "${SERVERS[*]}" "$TARGET_SSH_PASS" "$USERNAME" "$PASSWORD"

# 根据返回值处理结果
if [ $? -eq 0 ]; then
    log "集群已成功启动，可以继续后续操作"
else
    log "集群启动检查失败，请手动检查服务器状态"
    send_qywechat_notify "error"
    exit 1
fi

#####################################################################

log "备份和恢复操作完成。"

# 清理过期备份
log "开始清理源服务器 $SOURCE_SERVER 上的过期备份，保留 $SOURCE_BACKUP_RETENTION_DAYS 天的备份。"
ssh_with_pass "$SOURCE_SSH_PASS" "$SOURCE_SERVER" <<EOF
echo "\$(date '+%Y-%m-%d %H:%M:%S') - 开始查找过期备份文件..."
find $BACKUP_DIR -type f -mtime +$SOURCE_BACKUP_RETENTION_DAYS -print
echo "\$(date '+%Y-%m-%d %H:%M:%S') - 开始删除过期备份文件..."
find $BACKUP_DIR -type f -mtime +$SOURCE_BACKUP_RETENTION_DAYS -exec rm -f {} \;
echo "\$(date '+%Y-%m-%d %H:%M:%S') - 源服务器备份清理完成"
EOF

# 清理目标主服务器上的过期备份
log "开始清理目标服务器 $TARGET_SERVER 上的过期备份，保留 $BACKUP_RETENTION_DAYS 天的备份。"
ssh_with_pass "$TARGET_SSH_PASS" "$TARGET_SERVER" <<EOF
echo "\$(date '+%Y-%m-%d %H:%M:%S') - 开始查找过期备份文件..."
find $BACKUP_DIR -type f -mtime +$BACKUP_RETENTION_DAYS -print
echo "\$(date '+%Y-%m-%d %H:%M:%S') - 开始删除过期备份文件..."
find $BACKUP_DIR -type f -mtime +$BACKUP_RETENTION_DAYS -exec rm -f {} \;
echo "\$(date '+%Y-%m-%d %H:%M:%S') - 目标服务器备份清理完成"
EOF

log "清理过期备份完成#########################################################################################################"
send_qywechat_notify "info"
