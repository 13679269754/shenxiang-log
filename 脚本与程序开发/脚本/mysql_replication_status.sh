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
read -sp "请输入 MySQL 密码: " password
echo
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

# 计算各列最大宽度
declare -A max_widths
headers=("Type" "IP" "Info Time" "Read_only" "POS" "Seconds Behind Master" "GTID 一致性" "不一致的 GTID")
for header in "${headers[@]}"; do
    max_widths["$header"]=${#header}
done

# 更新主库信息列宽
if [[ ${#master_ip} -gt ${max_widths["IP"]} ]]; then
    max_widths["IP"]=${#master_ip}
fi
if [[ ${#master_info_time} -gt ${max_widths["Info Time"]} ]]; then
    max_widths["Info Time"]=${#master_info_time}
fi
if [[ ${#master_pos} -gt ${max_widths["POS"]} ]]; then
    max_widths["POS"]=${#master_pos}
fi

# 更新从库信息列宽
for info in "${slave_info[@]}"; do
    IFS='|' read -r ip info_time read_only slave_pos seconds_behind_master gtid_consistent inconsistent_gtid <<< "$info"
    if [[ ${#ip} -gt ${max_widths["IP"]} ]]; then
        max_widths["IP"]=${#ip}
    fi
    if [[ ${#info_time} -gt ${max_widths["Info Time"]} ]]; then
        max_widths["Info Time"]=${#info_time}
    fi
    if [[ ${#read_only} -gt ${max_widths["Read_only"]} ]]; then
        max_widths["Read_only"]=${#read_only}
    fi
    if [[ ${#slave_pos} -gt ${max_widths["POS"]} ]]; then
        max_widths["POS"]=${#slave_pos}
    fi
    if [[ ${#seconds_behind_master} -gt ${max_widths["Seconds Behind Master"]} ]]; then
        max_widths["Seconds Behind Master"]=${#seconds_behind_master}
    fi
    if [[ ${#gtid_consistent} -gt ${max_widths["GTID 一致性"]} ]]; then
        max_widths["GTID 一致性"]=${#gtid_consistent}
    fi
    if [[ ${#inconsistent_gtid} -gt ${max_widths["不一致的 GTID"]} ]]; then
        max_widths["不一致的 GTID"]=${#inconsistent_gtid}
    fi
done

# 输出表头
format=""
for header in "${headers[@]}"; do
    format+="%-${max_widths[$header]}s "
done
format+="\n"
printf "$format" "${headers[@]}"

# 输出主库信息
printf "$format" "Master" "$master_ip" "$master_info_time" "OFF" "$master_pos" "" "一致" ""

# 输出分隔线
total_width=0
for header in "${headers[@]}"; do
    ((total_width+=max_widths[$header]+1))
done
printf "%0.s-" $(seq 1 $total_width)
echo

# 输出从库信息
for info in "${slave_info[@]}"; do
    IFS='|' read -r ip info_time read_only slave_pos seconds_behind_master gtid_consistent inconsistent_gtid <<< "$info"
    printf "$format" "Slave" "$ip" "$info_time" "$read_only" "$slave_pos" "$seconds_behind_master" "$gtid_consistent" "$inconsistent_gtid"
done

# 输出 GTID 信息表格表头
gtid_headers=("Host" "GTID")
gtid_max_widths=()
for header in "${gtid_headers[@]}"; do
    gtid_max_widths["$header"]=${#header}
done

for info in "${gtid_info[@]}"; do
    IFS='|' read -r host gtid <<< "$info"
    if [[ ${#host} -gt ${gtid_max_widths["Host"]} ]]; then
        gtid_max_widths["Host"]=${#host}
    fi
    if [[ ${#gtid} -gt ${gtid_max_widths["GTID"]} ]]; then
        gtid_max_widths["GTID"]=${#gtid}
    fi
done

gtid_format=""
for header in "${gtid_headers[@]}"; do
    gtid_format+="%-${gtid_max_widths[$header]}s "
done
gtid_format+="\n"
printf "\nGTID 信息表格:\n"
printf "$gtid_format" "${gtid_headers[@]}"

# 输出 GTID 信息表格分隔线
gtid_total_width=0
for header in "${gtid_headers[@]}"; do
    ((gtid_total_width+=gtid_max_widths[$header]+1))
done
printf "%0.s-" $(seq 1 $gtid_total_width)
echo

# 输出 GTID 信息
for info in "${gtid_info[@]}"; do
    IFS='|' read -r host gtid <<< "$info"
    printf "$gtid_format" "$host" "$gtid"
done

# 删除存储的凭证
mysql_config_editor remove --login-path=customlogin