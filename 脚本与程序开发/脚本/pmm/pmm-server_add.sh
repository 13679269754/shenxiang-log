#!/bin/bash
########################################
#title: pmm-service_add
#creater: shenx
#time: 23-5-9
#
########################################

# 初始化一些默认值
mysql_port=3308
query_source=perfschema
username=dzj_root
password=Dzj@2014

function usage(){
    echo "Usage: $0 [OPTIONS]."

    # 描述脚本用途、参数和选项等信息
    echo ""
    echo "A Bash script for adding MySQL services to PMM."
    echo ""
    echo "Options:"
    echo "-h, help.             Show this help message and exit."
    echo "-H, mysql_host.       Comma-separated list of MySQL hosts or IP addresses."
    echo "                       Required parameter."
    echo "-u, username.         The username to use for connecting to the MySQL service."
    echo "                       Default is $username."
    echo "-P, port.             The port number of the MySQL service. Default is $mysql_port."
    echo "-p, password.         The password to use for connecting to the MySQL service."
    echo "                       Default is $password."
    echo ""
    echo "Example usage:"
    echo "$0 -H 192.168.0.1,192.168.0.2,192.168.0.3 -P 3306 -u myuser -p mypassword"
}

function print_green() {
    printf "\033[32m$1\033[0m\n"
}

while getopts ":h:H:u:P:p:" opt; do
  case ${opt} in
    H )
      mysql_host=$OPTARG
      ;;
    u )
      username=$OPTARG
      ;;
    p )
      password=$OPTARG
      ;;
    P )
      mysql_port=$OPTARG
      ;;
    h )
      usage
      exit 0
      ;;
    \? )
      echo "Invalid option: $OPTARG." 1>&2
      usage
      exit 1
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument." 1>&2
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

if [ -z "$mysql_host" ]; then
  echo "Error: mysql_host is required."
  usage
  exit 1
fi

IFS=',' read -r -a HOSTS <<< "$mysql_host"

for index in "${!HOSTS[@]}"; do
  eval mysql_host$((index+1))="${HOSTS[index]}"
done

for index in "${!HOSTS[@]}"; do
  eval mysql_host=\$mysql_host$((index+1))
  cmd="pmm-admin add mysql --query-source=$query_source --username=$username --password=$password \
--service-name=MYSQL_${mysql_host} --host=${mysql_host} --port=$mysql_port"
  print_green "$cmd"
  output=$(eval "$cmd")
  if [[ "$output" == *"ERROR"* ||"$output" == *"Unauthorized"* ]]; then
    echo "$output"
    echo "Failed to add MySQL service for $mysql_host."
  else
    echo "MySQL service added successfully for $mysql_host."
  fi
done