#################################################################
# 说明：
# 脚本用于influxdb备份和恢复,备份周期为每天，数据为T+1
# 步骤：
# 1.备份backup服务器的influxdb
# 2.关闭retore服务器influxdb,并备份数据目录
# 3.scp传输到restore服务器
# 4.在restore服务器覆盖恢复备份文件
# 5.启动restore influxdb
# 要求：
# backup 服务器需要安装sshpass工具
#################################################################


#!/bin/bash

# 日志文件路径
LOG_FILE="influxdb_backup_restore.log"

# 企业微信通知脚本路径
QYWECHAT_NOTIFY_SCRIPT="python3 /root/script/qywechat_notify.py"

# 显示帮助信息
show_help() {
    echo "此脚本用于 InfluxDB 2.0 OSS 版本的备份和恢复操作。"
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  --backup-node-ip <IP>              需要备份的节点 IP"
    echo "  --restore-node-ip <IP>             需要恢复的节点 IP"
    echo "  --backup-data-dir <目录>           备份节点的数据目录"
    echo "  --restore-data-dir <目录>          恢复节点的数据目录"
    echo "  --remote-backup-dir <目录>         备份到远程的数据目录"
    echo "  --root-token <token>               InfluxDB 的备份 root-token"
    echo "  --restore-root-token <token>       InfluxDB 的恢复 root-token"
    echo "  --backup-ssh-pass <密码>           备份节点 SSH 密码"
    echo "  --restore-ssh-pass <密码>          恢复节点 SSH 密码"
    echo "  --influxd-path <路径>              influxd 可执行文件的路径"
    echo "  --restore-node-backup-dir <目录>   恢复节点数据备份目录，默认值：/usr/local/data/backup/influxdb_$(date +%Y%m%d)"
    echo "  --backup-retention-days <天数>     备份保留天数，默认值：30"
    echo "  --help                             显示此帮助信息"
    echo "  --host                             influxdb 数据库连接串 选填,当两个influxdb port 不一致时 时必填 http://[backup-node-ip]:[port] 备份实例ip:port"
    echo "  --restore_host                     restore influxdb 数据库连接串 选填,当两个influxdb port 不一致时 时必填 http://[restore-node-ip]:[port] 恢复实例ip:port"
    echo "example : ./influxdb_backup_restore.sh --backup-node-ip 172.29.29.104 --restore-node-ip 172.29.29.105 --backup-data-dir /usr/local/data/influxdb2 --restore-data-dir /usr/local/data/influxdb2 --remote-backup-dir /usr/local/data/backup/influxdb --restore-root-token _Sd_8eNo5vC2PKl_38QGLp9Ltl81GZTxabq3EnwBDzw3pL-hCtAt-4_ucejvfS3HBqnF-MgcEWUAcYbVZ4LKPZA== --root-token YmvIhTlLrxneYcruvtRrhgOwmbD6RDxvNlye8lGxFeHc_pxSRPlICC0DjVIYUrth5skXyoAvxZu2SEiOYlxnDg=="
}

# 记录日志函数，添加函数名输出
log() {
    local function_name="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp - $function_name - $message" | tee -a "$LOG_FILE"
}

# 发送企业微信通知函数
send_qywechat_notify() {
    local status="$1"
    local title="数据库日常 INFLUXDB 数据同步任务信息"
    if [ "$status" = "info" ]; then
        local msg="${backup_node_ip} influxdb restore to 恢复地址 ${restore_node_ip} Success !!!!!"
    else
        local msg="${backup_node_ip} influxdb restore to 恢复地址 ${restore_node_ip} Failed, please check !!!!!"
    fi
    $QYWECHAT_NOTIFY_SCRIPT "$status" "$title" "$msg"
}

# 解析命令行参数
root_token="bx8NQKi_DP94m8PUG_JwUxXvxHkixvd4LQMcbKktQZ9irF7B1ADiG07o53h_sFm5bqXeFlnmztNVAYtYzLMlRg=="
restore_root_token="bx8NQKi_DP94m8PUG_JwUxXvxHkixvd4LQMcbKktQZ9irF7B1ADiG07o53h_sFm5bqXeFlnmztNVAYtYzLMlRg=="
backup_ssh_pass="YCPkWm2Q*28@"
restore_ssh_pass="dzj123,./"
influxd_path="/usr/local/data/influxdb2-server/influx"
restore_node_backup_dir="/usr/local/data/backup/influxdb_$(date +%Y%m%d)"
backup_retention_days=30
port='8086'
while [[ $# -gt 0 ]]; do
    case "$1" in
        --backup-node-ip)
            backup_node_ip="$2"
            shift 2
            ;;
        --restore-node-ip)
            restore_node_ip="$2"
            shift 2
            ;;
        --backup-data-dir)
            backup_data_dir="$2"
            shift 2
            ;;
        --restore-data-dir)
            restore_data_dir="$2"
            shift 2
            ;;
        --remote-backup-dir)
            remote_backup_dir="$2"
            shift 2
            ;;
        --root-token)
            root_token="$2"
            shift 2
            ;;
        --restore-root-token)
            restore_root_token="$2"
            shift 2
            ;;
        --backup-ssh-pass)
            backup_ssh_pass="$2"
            shift 2
            ;;
        --restore-ssh-pass)
            restore_ssh_pass="$2"
            shift 2
            ;;
        --influxd-path)
            influxd_path="$2"
            shift 2
            ;;
        --restore-node-backup-dir)
            restore_node_backup_dir="$2"
            shift 2
            ;;
        --backup-retention-days)
            backup_retention_days="$2"
            shift 2
            ;;
        --host)
            host="$2"
            shift 2
            ;;
        --restore_host)
            restore_host="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log "main" "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done




# 检查必要的参数是否提供
if [ -z "$backup_node_ip" ] || [ -z "$restore_node_ip" ] || [ -z "$backup_data_dir" ] || [ -z "$restore_data_dir" ] || [ -z "$remote_backup_dir" ] || [ -z "$root_token" ] || [ -z "$restore_root_token" ]; then
    log "main" "错误: 缺少必要的参数。"
    send_qywechat_notify "error"
    show_help
    exit 1
fi


if [ -z "$host" ] || [ -z "$restore_host" ];then
    host=http://$backup_node_ip:$port
    restore_host=http://$restore_node_ip:$port
fi

# 检查并安装 sshpass
install_sshpass() {
    if ! command -v sshpass &> /dev/null; then
        log "main" "sshpass 未安装，正在安装..."
        if command -v apt &> /dev/null; then
            sudo apt-get update
            sudo apt-get install sshpass -y
        elif command -v yum &> /dev/null; then
            sudo yum install sshpass -y
        else
            log "main" "不支持的包管理器，无法安装 sshpass。"
            send_qywechat_notify "error"
            exit 1
        fi
        log "main" "sshpass 安装完成。"
    fi
}


# 带 sshpass 的 ssh 函数
ssh_with_pass() {
    if [ $# -eq 3 ]; then
        local ssh_pass=$1
        local ssh_host=$2
        local ssh_command=$3
        install_sshpass
        log "ssh_with_pass" "执行远程命令:ssh $ssh_host  $ssh_command"
        sshpass -p "$ssh_pass" ssh "$ssh_host" "$ssh_command"
    elif [ $# -eq 2 ]; then
        local ssh_pass=$1
        local ssh_command=$2
        install_sshpass
        log "ssh_with_pass" "执行远程命令:$ssh_command"
        sshpass -p "$ssh_pass" """$ssh_comma"n"d"
    fi
}

# 备份函数
backup_influxdb() {
    log "backup_influxdb" "开始备份 InfluxDB 数据####################################################################################################"
    # 生成带日期时间戳的备份目录
    timestamp=$(date +"%Y-%m-%d-%H-%M")
    timestamped_remote_backup_dir="${remote_backup_dir}/${timestamp}"
    # 创建远程备份目录
    log "backup_influxdb" "创建远程备份目录: $timestamped_remote_backup_dir"
    if ! ssh_with_pass "$backup_ssh_pass" "$backup_node_ip" "mkdir -p $timestamped_remote_backup_dir" ||
       ! ssh_with_pass "$restore_ssh_pass" "$restore_node_ip" "mkdir -p $remote_backup_dir/";then
        log "backup_influxdb" "创建远程备份目录失败。"
        send_qywechat_notify "error"
        exit 1
    fi

    # 备份数据目录，使用 root-token
    backup_cmd="$influxd_path backup $timestamped_remote_backup_dir -t $root_token --host $host"
    log "backup_influxdb" "执行备份命令: $backup_cmd"
    ssh_with_pass "$backup_ssh_pass" "$backup_node_ip" "$backup_cmd" || {
        log "backup_influxdb" "备份数据目录失败。"
        ssh_with_pass "$backup_ssh_pass" "$backup_node_ip" "rm -rf $timestamped_remote_backup_dir"
        send_qywechat_notify "error"
        exit 1
    }
    log "backup_influxdb" "备份完成。"
    # 存储带时间戳的备份目录，供恢复使用
    export TIMESTAMPED_REMOTE_BACKUP_DIR="$timestamped_remote_backup_dir"
}

# 清理过期备份函数
cleanup_old_backups() {
    log "cleanup_old_backups" "开始清理过期备份，保留 $backup_retention_days 天的备份。"
    find_output=$(ssh_with_pass "$restore_ssh_pass" "$restore_node_ip" "find $(dirname """$restore_node_backup_d"i"r") -type d -mtime +$backup_retention_days")
    if [ -n "$find_output" ]; then
        log "cleanup_old_backups" "找到以下过期备份目录: $find_output"
        deletion_result=$(ssh_with_pass "$restore_ssh_pass" "$restore_node_ip" "find $(dirname """$restore_node_backup_d"i"r") -type d -mtime +$backup_retention_days -exec rm -rf {} \;")
        log "cleanup_old_backups" "删除过期备份目录的结果: $deletion_result"
    else
        log "cleanup_old_backups" "未找到过期备份目录。"
    fi
 }


# 恢复前的准备和恢复操作，失败时进行回滚
restore_influxdb() {
    log "restore_influxdb" "开始恢复 InfluxDB 数据..."
    # 检查恢复节点的 influxdb 服务状态，通过进程判断
    log "restore_influxdb" "检查恢复节点的 InfluxDB 服务状态，关闭恢复节点$restore_node_ip InfluxDB 并 备份 InfluxDB 数据目录"
    status=$(ssh_with_pass "$restore_ssh_pass" "$restore_node_ip" "pgrep influxd")
    if [ -n "$status" ]; then
        log "restore_influxdb" "恢复节点的 InfluxDB 服务正在运行，将其关闭..."
        ssh_with_pass "$restore_ssh_pass" "$restore_node_ip" "pkill influxd" || {
            log "restore_influxdb" "停止恢复节点的 InfluxDB 服务失败。"
            send_qywechat_notify "error"
            exit 1
        }
    else
        log "restore_influxdb" "恢复节点的 InfluxDB 服务未运行。"
    fi

    # 移动备份
    log "restore_influxdb" "将 $restore_node_ip 恢复前数据保存到 $restore_data_dir_$(date +"%Y-%m-%d-%H-%M")"
    ssh_with_pass "$restore_ssh_pass" "$restore_node_ip" "cp -R  ${restore_data_dir}/data  ${restore_data_dir}/data_yesterday"

    # 启动恢复节点的 InfluxDB 服务，以 influxdb 用户执行启动脚本
    log "restore_influxdb" "启动恢复节点的 InfluxDB 服务"
    ssh_with_pass "$restore_ssh_pass" "$restore_node_ip" "sudo -E -u influxdb bash -l -c '/home/influxdb/start.sh'" || {
        log "restore_influxdb" "启动恢复节点的 InfluxDB 服务失败，请确认恢复节点状态"
        send_qywechat_notify "error"
        exit 1
    }
    ssh_with_pass "$restore_ssh_pass" "$restore_node_ip" "ss -antulp |grep influx"
    # 恢复数据
    log "restore_influxdb" "从 $backup_node_ip:$timestamped_remote_backup_dir scp 到 $restore_node_ip:$remote_backup_dir"
    ssh_with_pass "$backup_ssh_pass" "$backup_node_ip"  "sshpass -p \"$restore_ssh_pass\" scp -r $timestamped_remote_backup_dir $restore_node_ip:$remote_backup_dir/"
    log "restore_influxdb" "从 $TIMESTAMPED_REMOTE_BACKUP_DIR 恢复数据到 $restore_data_dir"
    restore_cmd=" $influxd_path restore $TIMESTAMPED_REMOTE_BACKUP_DIR --full -t $restore_root_token --host $restore_host"
    ssh_with_pass "$restore_ssh_pass" "$restore_node_ip" "$restore_cmd" || {
        log "restore_influxdb" "恢复数据失败，请确认恢复节点状态并回滚"
        send_qywechat_notify "error"
        exit 1
    }

    # 清理过期备份
    cleanup_old_backups
    log "restore_influxdb" "恢复完成。"
}

# 执行备份和恢复操作
backup_influxdb
restore_influxdb
send_qywechat_notify "info"

log "all_script" "influxdb 备份完成##################################################################################################################"
