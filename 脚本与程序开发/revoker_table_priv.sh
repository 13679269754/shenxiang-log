#!/bin/bash

MYSQL="mysql -uroot -p'your_password' -N -B"
TARGET_DB="research"
USER_LIST_FILE="user_list.txt"
OUTPUT_SQL="revoke_research_privs.sql"

> "$OUTPUT_SQL"

while read -r USER_ENTRY; do
    USER=$(echo "$USER_ENTRY" | cut -d'@' -f1 | tr -d "'")
    HOST=$(echo "$USER_ENTRY" | cut -d'@' -f2 | tr -d "'")

    echo "-- Checking $USER@$HOST" >> "$OUTPUT_SQL"

    GRANTS=$($MYSQL -e "SHOW GRANTS FOR '$USER'@'$HOST';")

    while read -r GRANT_LINE; do
        # 匹配所有 research.* 或 research.表名 的授权
        if echo "$GRANT_LINE" | grep -qE "ON \`?$TARGET_DB\`?\.\*|ON \`?$TARGET_DB\`?\.\`?[a-zA-Z0-9_]+\`?"; then
            # 提取权限和对象
            PRIVS=$(echo "$GRANT_LINE" | sed -n "s/^GRANT \(.*\) ON .\+ TO.*/\1/p")
            OBJECT=$(echo "$GRANT_LINE" | sed -n "s/^GRANT .* ON \(.*\) TO.*/\1/p")
            echo "REVOKE $PRIVS ON $OBJECT FROM '$USER'@'$HOST';" >> "$OUTPUT_SQL"
        fi
    done <<< "$GRANTS"

done < "$USER_LIST_FILE"

echo "生成完成：$OUTPUT_SQL"