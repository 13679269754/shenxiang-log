#!/bin/bash

# 配置 MySQL 连接信息
DB_USER="dzj_root"
DB_PASSWORD="Dzj@2014"

# 用户信息
read -p "请输入要创建的用户名：" username
read -sp "请输入要创建的用户密码：" password
echo

# 用户角色选择
options=("只读用户" "读写用户" "DB运维账户" "物理备份用户" "逻辑备份用户" "主从账户" "其他")
echo "请选择要创建用户的角色："
for i in "${!options[@]}"
do
  echo "$(($i+1))). ${options[$i]}"
done
read -p "请输入要选择的角色编号（例如：1）：" role
case $role in
  1)
    grant_sql="SELECT, SHOW DATABASES, SHOW VIEW"
    ;;
  2)
    grant_sql="SELECT, INSERT, UPDATE, CREATE, RELOAD, PROCESS, INDEX, ALTER, CREATE TEMPORARY TABLES, EXECUTE, CREATE VIEW, CREATE ROUTINE, ALTER ROUTINE"
    ;;
  3)
    grant_sql="ALL PRIVILEGES"
    ;;
  4)
    grant_sql="RELOAD, LOCK TABLES, REPLICATION CLIENT, FILE"
    ;;
  5)
    grant_sql="SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER, RELOAD, REPLICATION CLIENT, CREATE USER, EXECUTE"
    ;;
  6)
    grant_sql="REPLICATION CLIENT,REPLICATION SLAVE"
    ;;
  7)
    read -p "请输入该账户需要的权限：" grant_sql
    ;;
  *)
    echo "选择的角色编号不正确！"
    exit 1
    ;;
esac

# 多选环境
options=("dev" "test" "prod" "pre")
selected=("dev" "test") # 设置默认环境
echo "请选择要在哪些环境中创建用户："
for i in "${!options[@]}"
do
  echo "$(($i+1))). ${options[$i]}"
done
read -p "请用逗号分隔选择的环境编号（例如：1,3）[默认：dev,test]：" input
if [ ! -z "$input" ]; then
  unset selected
  IFS=',' read -ra selected_opts <<< "$input"
  for opt in "${selected_opts[@]}"
  do
    case $opt in
      1)
        selected+=("dev")
        ;;
      2)
        selected+=("test")
        ;;
      3)
        selected+=("prod")
        ;;
      4)
        selected+=("pre")
        ;;
      *)
        echo "选择的环境编号不正确！"
        exit 1
        ;;
    esac
  done
fi


# 创建用户和授权
for env in "${selected[@]}"
do
  case $env in
  dev)
    db_host='172.29.104.51'
    db_port='3308'
    ;;
  test)
    db_host='172.29.105.51'
    db_port='3308'
    ;;
  prod)
    db_host='172.29.28.195'
    db_port='3308'
    ;;
  pre)
    db_host='172.29.28.196'
    db_port='3308'
    ;;
  *)
    echo "选择的环境编号不正确！"
    exit 1
    ;;
  esac

  read -p "请输入该账户的host,默认'%'：" host
  if [ ! -z "$host" ];then
      host='%'
  fi
  read -p "请输入该账户的DB_NAME,默认'mysql'：" DB_NAME 
  if [ ! -z "$DB_NAME" ];then
      DB_NAME='*'
  fi

  if [ $role -eq 4 ]; then
    user="physical_backup_${env}"
  elif [ $role -eq 5 ]; then
    user="logical_backup_${env}"
  elif [ $role -eq 6 ] || [ $role -eq 7 ]; then
    user="${username}_${env}"
  else 
    user="${username}_${env}"
  fi
  sql="CREATE USER IF NOT EXISTS '${user}'@'${host}' IDENTIFIED WITH MYSQL_NATIVE_PASSWORD BY '${password}';"
  sql+="GRANT ${grant_sql} ON ${DB_NAME}.* TO '${user}'@'${host}';"


  echo "正在在 ${env} 环境中创建用户：${user}"
  echo "授权语句：${sql}"
  mysql -h${db_host} -P${db_port} -u${DB_USER} -p${DB_PASSWORD} -e"${sql}"
  if [ $? -eq 0 ]; then
    echo "======================================="
    echo "用户 ${username} 创建完成！"
    echo "用户名密码信息："
    echo "用户名：${username}"
    echo "密码：${password}"
    echo "MySQL实例IP：${db_host}"
    echo "MySQL实例端口：${db_port}"
    echo "======================================="
  fi
done


