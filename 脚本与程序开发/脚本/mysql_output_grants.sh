#!/bin/bash

# MySQL连接配置
MYSQL="mysql -uroot -pTWjVneX6kzsxErDMJapx -S /usr/local/data/mysql_data/2025-10-13_0010_2025-10-12/dbmysql/run/mysql3406.sock  -N -B"
OUTPUT_SQL="all_user_grants.sql"  # 输出文件名：所有用户的授权语句

# 清空输出文件（若存在）
> "$OUTPUT_SQL"

# 获取所有用户账号（排除系统内置的匿名用户和mysql库管理用户）
USER_ENTRIES=$($MYSQL -e "SELECT CONCAT('\'', user, '\'@\'', host, '\'') FROM mysql.user WHERE user != '';")

# 遍历每个用户，导出其所有授权语句
while read -r USER_ENTRY; do
    # 提取用户名和主机（去除单引号）
    USER=$(echo "$USER_ENTRY" | cut -d'@' -f1 | tr -d "'")
    HOST=$(echo "$USER_ENTRY" | cut -d'@' -f2 | tr -d "'")

    echo "-- 以下是用户 $USER@$HOST 的所有授权语句" >> "$OUTPUT_SQL"

    # 获取该用户的全部授权
    GRANTS=$($MYSQL -e "SHOW GRANTS FOR '$USER'@'$HOST';")

    # 将授权语句写入输出文件
    while read -r GRANT_LINE; do
        echo "$GRANT_LINE;" >> "$OUTPUT_SQL"  # 补充分号确保语法完整
    done <<< "$GRANTS"

    echo "" >> "$OUTPUT_SQL"  # 每个用户的授权之间空一行，便于阅读

done <<< "$USER_ENTRIES"

echo "所有用户的授权语句已生成：$OUTPUT_SQL"