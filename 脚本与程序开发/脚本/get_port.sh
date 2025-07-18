#!/bin/bash
# creater: qianxiangzhou

function usage(){
    echo ""
    echo "Usage: "
    echo "   --user|-u:             按照用户搜寻信息"
    echo "   --port|-p:             按照端口搜寻信息"
    echo "   --service|-s:          按照服务名称搜寻信息"
    echo ""
    echo ""
}

#-o或--options选项后面接可接受的短选项，如ab:c::，表示可接受的短选项为-a -b -c，其中-a选项不接参数，-b选项后必须接参数，-c选项的参数为可选的
#-l或--long选项后面接可接受的长选项，用逗号分开，冒号的意义同短选项。
#-n选项后接选项解析错误时提示的脚本名字
ARGS=$(getopt --options hu:p:s: --long user:,port:,service:,help -- "$@")
if [ $? != 0 ]; then
    echo ""
    echo "Terminating..."
    usage
    exit 1
fi
#echo $ARGS
#将规范化后的命令行参数分配至位置参数（$1,$2,...)
eval set -- "${ARGS}"

while true
do
    case "$1" in
        -p|--port)
            search_port=$2
            shift 2
            ;;
        -u|--user)
            search_user=$2en 
            shift 2
            ;;
        -s|--service)
            search_service=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 1
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Internal error!"
            usage
            exit 1
            ;;
    esac
done


# 使用netstat获取所有监听的端口
port_info=($(/usr/bin/netstat -tulnpl |grep -i listen| awk '{print $4}' | awk -F ':' '{print $NF}' | sort -n | uniq))

function get_docker_port_info(){
    # 查找PID对应的docker-proxy进程
    docker_proxy_process=$(ps aux | grep "docker-proxy" | grep -v grep | grep "$1")

    # 检查是否找到了docker-proxy进程
    if [ -z "$docker_proxy_process" ]; then
        echo "未找到PID为$1的docker-proxy进程"
    fi

    # 查找容器信息
    container_name=$(docker ps | grep "$2/tcp" | awk '{print $NF}')
    # 输出容器的名称或ID
    echo "$container_name"
    #echo "PID为$i的Docker容器名称或ID: $container_name"
}


declare -A java_processes
jps_output=$(jps)
while IFS= read -r line; do
    pid=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{print $2}')
    java_processes[$pid]=$name
done <<< "$jps_output"

function get_java_port_info() {
    pid=$1
    # 检查PID是否在字典中
    if [[ -z ${java_processes[$pid]} ]]; then
        echo "未找到PID为$pid的Java进程"
        return
    fi

    echo "${java_processes[$pid]}"
}


port_map=""
max_port_length=0
max_pid_length=0
max_pid_name_length=0
max_user_length=0
max_program_length=100
max_type_length=0
for n in ${port_info[@]}; do
    port=$n
    pid_list=($(/usr/bin/netstat -tulnpl | grep -i listen | grep ":$port " | awk '{printf $7}'| awk -F '/' '{print $1}'| sort -n | uniq)) 
    for pid in ${pid_list[@]}; do
        pid_name=$(/usr/bin/netstat -tulnpl |grep -i listen| grep "$pid/" | awk '{print $7}' | awk -F '/' '{print $2}'| sort -n | uniq)
        user=$(ps -p "$pid" -o user=)
        type=''
        if [[ $pid_name =~ 'docker' ]];then
            pid_name=$(get_docker_port_info "$pid" "$port")
            type='docker'
        elif [[ $pid_name =~ 'java' ]];then
            pid_name=$(get_java_port_info "$pid")
            type='java'
        fi
        port_map="$port_map$port,$pid,$pid_name,$user,$type\n"

        length_port=${#port}
        length_pid=${#pid}
        length_pid_name=${#pid_name}
        length_user=${#user}
        length_type=${#type}

        if [ "$length_pid_name" -gt "$max_pid_name_length" ]; then
            max_pid_name_length=$length_pid_name
        fi

        if [ "$length_user" -gt "$max_user_length" ]; then
            max_user_length=$length_user
        fi

        if [ "$length_port" -gt "$max_port_length" ]; then
            max_port_length=$length_port
        fi

        if [ "$length_pid" -gt "$max_pid_length" ]; then
            max_pid_length=$length_pid
        fi

        if [ "$length_type" -gt "$max_type_length" ]; then
            max_type_length=$length_type
        fi
        
    done
done


# 设置颜色和格式化字符串
color_column="\e[31m"   # 红色
color_port="\e[32m"     # 绿色
bold="\e[1m"
color_reset="\e[0m"
column_format_string="| ${bold}${color_column}%-${max_port_length}s ${color_reset}| ${bold}${color_column}%-${max_pid_length}s ${color_reset}| ${bold}${color_column}%-${max_user_length}s ${color_reset}| ${bold}${color_column}%-${max_type_length}s ${color_reset}| ${bold}${color_column}%-${max_pid_name_length}s ${color_reset}| ${bold}${color_column}%-${max_program_length}s ${color_reset}|\n"
format_string="| ${color_port}%-${max_port_length}s${color_reset} | ${color_reset}%-${max_pid_length}s | ${color_reset}%-${max_user_length}s | ${color_reset}%-${max_type_length}s | ${color_reset}%-${max_pid_name_length}s | ${color_reset}%-${max_program_length}s |\n"

# 打印格式化的输出
other_format="|-%-${max_port_length}s | %-${max_pid_length}s | %-${max_user_length}s | %-${max_type_length}s | %-${max_pid_name_length}s-| %-${max_program_length}s-|\n"
printf "$other_format" "-" | tr ' ' '-'
printf "$column_format_string" "Port" "Pid" "User" "type" "Service" "Program"

#遍历端口数组，找到未被使用的端口 
port_output=$(echo -e "$port_map"|sort -t ',' -k 4 -k 3 -k 1n)
while IFS= read -r line; do
    if [ -z "$line" ]; then
        continue
    fi
    port=$(echo "$line" | awk -F ',' '{print $1}')
    pid=$(echo "$line" | awk -F ',' '{print $2}')
    pid_name=$(echo "$line" | awk -F ',' '{print $3}')
    user=$(echo "$line" | awk -F ',' '{print $4}')
    type=$(echo "$line" | awk -F ',' '{print $5}')
    program_info=$(ps -p "$pid" -o command= | cut -c 1-$max_program_length)
    
    if [ -n "$search_port" ]; then
        if [[ ! "$port" =~ "$search_port" ]]; then
            continue
        fi
    fi

    if [ -n "$search_user" ]; then
        if [[ ! "$user" =~ "$search_user" ]]; then
            continue
        fi
    fi

    if [ -n "$search_service" ]; then
        if [[ ! "$pid_name" =~ "$search_service" ]]; then
            continue
        fi
    fi
    printf "$other_format" "-" | tr ' ' '-'
    printf "$format_string" "$port" "$pid" "$user" "$type" "$pid_name" "$program_info"

done <<< "$port_output"

printf "$other_format" "-" | tr ' ' '-'
echo -e "\n"


