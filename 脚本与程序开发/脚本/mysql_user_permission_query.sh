#!/bin/bash

######################
#导出mysql用户创建用户信息
#以及用户权限信息
######################

# MySQL 连接信息
MYSQL_USER="dzjetl"
MYSQL_PASSWORD="EJhGcfpypgu0r0Xj"
MYSQL_HOST="172.30.70.45"
MYSQL_PORT="3106"


# 系统用户列表
SYSTEM_USERS=("mysql.infoschema" "mysql.session" "mysql.sys" "root")

# 输出文件
OUTPUT_FILE="user_grants.sql"

# 清空输出文件
> "$OUTPUT_FILE"

# 输出用户信息
mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -N -e "SELECT CONCAT('create user ',USER,'@','''',HOST,'''',' identified by ''','dzjpwd_',USER,'_',SUBSTR(HEX(MD5(USER)),1,2),''';') FROM mysql.user WHERE USER NOT IN ('mysql.infoschema','mysql.session','mysql.sys','root') and host not in ('localhost');" > "$OUTPUT_FILE"

# 查询所有用户
USERS=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -N -e "SELECT DISTINCT User, Host FROM mysql.user")
echo mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -N -e "SELECT DISTINCT User, Host FROM mysql.user"
# 遍历用户
while IFS=$'\t' read -r USER HOST; do
    # 检查是否为系统用户
    IS_SYSTEM_USER=false
    for SYSTEM_USER in "${SYSTEM_USERS[@]}"; do
        if [ "$USER" = "$SYSTEM_USER" ]; then
            IS_SYSTEM_USER=true
            break
        fi
    done

    # 如果不是系统用户，获取 GRANT 语句
    if [ "$IS_SYSTEM_USER" = false ]; then
        GRANTS=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST"  -P "$MYSQL_PORT" -N -e "SHOW GRANTS FOR '$USER'@'$HOST'")
        while IFS= read -r GRANT; do
            echo "$GRANT;" >> "$OUTPUT_FILE"
        done <<< "$GRANTS"
    fi
done <<< "$USERS"

echo "GRANT 语句已成功导出到 $OUTPUT_FILE 文件。"
