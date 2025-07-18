#!/bin/bash

# 检查参数数量
if [ $# -lt 4 ]; then
    echo "Usage: $0 <mysql_path> <username> <port> <ip1> <ip2> ..."
    exit 1
fi

mysql_path=$1
username=$2
port=$3
shift 3
ip_list=("$@")

# 提示输入密码并使用 mysql_config_editor 存储凭证

mysql_config_editor set --login-path=customlogin --host=localhost --user="$username" --password <<< "$password"

# 查找主库
master_ip=""
for ip in "${ip_list[@]}"; do
    info_time=$(date +"%Y-%m-%d %H:%M:%S")
    read_only=$($mysql_path --login-path=customlogin -h "$ip" -P "$port" -e "SHOW GLOBAL VARIABLES LIKE 'read_only';" | awk 'NR==2 {print $2}')
    if [ "$read_only" = "OFF" ]; then
        master_ip=$ip
        master_info_time=$info_time
        break
    fi
done

if [ -z "$master_ip" ]; then
    echo "Could not find the master server."
    exit 1
fi

# 获取主库 GTID 和 POS 信息
master_info_time=$(date +"%Y-%m-%d %H:%M:%S")
master_gtid=$($mysql_path --login-path=customlogin -h "$master_ip" -P "$port" -e "SHOW MASTER STATUS\G" | sed -n '/Executed_Gtid_Set:/,/^[[:space:]]*$/  {p} ' | tr -d '\n' | sed 's/^[[:space:]]*//')
master_pos=$($mysql_path --login-path=customlogin -h "$master_ip" -P "$port" -e "SHOW MASTER STATUS\G" | grep "Position" | awk '{print $2}')

# 检查从库信息
slave_info=()
gtid_info=()
gtid_info+=("$master_ip|$master_gtid")
for ip in "${ip_list[@]}"; do
    if [ "$ip" != "$master_ip" ]; then
        info_time=$(date +"%Y-%m-%d %H:%M:%S")
        read_only=$($mysql_path --login-path=customlogin -h "$ip" -P "$port" -e "SHOW GLOBAL VARIABLES LIKE 'read_only';" | awk 'NR==2 {print $2}')
        slave_gtid=$($mysql_path --login-path=customlogin -h "$ip" -P "$port" -e "SHOW SLAVE STATUS\G" | sed -n '/Executed_Gtid_Set:/,/^[[:space:]]*$/ { p }' | grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}:[0-9-]+,?' | tr -d '\n' | sed 's/^[[:space:]]*//' )
        slave_pos=$($mysql_path --login-path=customlogin -h "$ip" -P "$port" -e "SHOW SLAVE STATUS\G" | grep "Read_Master_Log_Pos" | awk '{print $2}')
        seconds_behind_master=$($mysql_path --login-path=customlogin -h "$ip" -P "$port" -e "SHOW SLAVE STATUS\G" | grep "Seconds_Behind_Master" | awk '{print $2}')
        master_gtid_list=(${master_gtid//,/ })
        slave_gtid_list=(${slave_gtid//,/ })
        inconsistent_gtid=""
        for gtid in "${slave_gtid_list[@]}"; do
            if [[ ! " ${master_gtid_list[@]} " =~ " ${gtid} " ]]; then
                if [ -z "$inconsistent_gtid" ]; then
                    inconsistent_gtid="$gtid"
                else
                    inconsistent_gtid="$inconsistent_gtid,$gtid"
                fi
            fi
        done
        if [ -z "$inconsistent_gtid" ]; then
            gtid_consistent="一致"
        else
            gtid_consistent="不一致"
        fi
        slave_info+=("$ip|$info_time|$read_only|$slave_pos|$seconds_behind_master|$gtid_consistent|$inconsistent_gtid")
        gtid_info+=("$ip|$slave_gtid")
    fi
done

# 生成 HTML 头部
html_content='<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MySQL 主从复制信息</title>
    <style>
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        .highlight {
            background-color: #ffcccc;
        }
    </style>
</head>
<body>
'

# 主从信息表格
html_content+='<h2>主从信息表格</h2>
<table>
    <tr>
        <th>Type</th>
        <th>IP</th>
        <th>Info Time</th>
        <th>Read_only</th>
        <th>POS</th>
        <th>Seconds Behind Master</th>
        <th>GTID 一致性</th>
        <th>不一致的 GTID</th>
    </tr>
    <tr>
        <td>Master</td>
        <td>'"$master_ip"'</td>
        <td>'"$master_info_time"'</td>
        <td>OFF</td>
        <td>'"$master_pos"'</td>
        <td></td>
        <td>一致</td>
        <td></td>
    </tr>
'

for info in "${slave_info[@]}"; do
    IFS='|' read -r ip info_time read_only slave_pos seconds_behind_master gtid_consistent inconsistent_gtid <<< "$info"
    html_content+='    <tr>
        <td>Slave</td>
        <td>'"$ip"'</td>
        <td>'"$info_time"'</td>
        <td>'"$read_only"'</td>
        <td>'"$slave_pos"'</td>
        <td>'"$seconds_behind_master"'</td>
        <td>'"$gtid_consistent"'</td>
        <td>'"$inconsistent_gtid"'</td>
    </tr>
'
done

html_content+='</table>
'

# GTID 信息表格
html_content+='<h2>GTID 信息表格</h2>
<table>
    <tr>
        <th>Host</th>
        <th>GTID</th>
    </tr>
'

for info in "${gtid_info[@]}"; do
    IFS='|' read -r host gtid <<< "$info"
    master_gtid_list=(${master_gtid//,/ })
    slave_gtid_list=(${gtid//,/ })
    highlighted_gtid=""
    for gtid_part in "${slave_gtid_list[@]}"; do
        if [[ ! " ${master_gtid_list[@]} " =~ " ${gtid_part} " ]]; then
            highlighted_gtid+="<span class='highlight'>$gtid_part</span>,"
        else
            highlighted_gtid+="$gtid_part,"
        fi
    done
    highlighted_gtid=${highlighted_gtid%,}
    html_content+='    <tr>
        <td>'"$host"'</td>
        <td>'"$highlighted_gtid"'</td>
    </tr>
'
done

html_content+='</table>
</body>
</html>'

# 输出 HTML 文件
echo "$html_content" > mysql_replication_info.html

# 删除存储的凭证
mysql_config_editor remove --login-path=customlogin
