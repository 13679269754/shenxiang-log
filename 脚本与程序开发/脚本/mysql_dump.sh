#!/bin/bash
########################################
#mysqldump 导入导出脚本
#支持mysql db.tables 的方式导出
#
########################################

#是否一个表一个表导出,0：不是 ，1：是
PER_TABLE=1
#库名修改 1:修改，0：不改
ALTER_DB_NAME=1


#源端
OLD_DB_HOST="172.29.28.37"
OLD_DB_PORT='3306'
OLD_DB_USER="dbadmin"
OLD_DB_PASSWD="alipswxx"
OLD_DATABASES='hrs'
TABLE="disease_screening_spec"

#目标端
NEW_DB_HOST="172.29.105.51"
NEW_DB_PORT='3106'
NEW_DB_USER="dzjroot"
NEW_DB_PASSWD="dzjroot_pwd"
NEW_DATABASES='old_hrs'

#脚本获取的全局变量
#FILE_PATH='/home/mysql'

if  [[ $NEW_DATABASES == '' ]] && [[ $ALTER_DB_NAME -eq 1 ]];then
	NEW_DATABASES='OLD_'${OLD_DATABASES}
else
	NEW_DATABASES=$OLD_DATABASES
fi


function  path_init()
{
	if [[ ! -d $1 ]];then
		mkdir -p $1
	else 
		FILE_PATH=$1
	fi
}


function dump_table()
{
	if [[ "$PER_TABLE" -eq 0 ]];then
		path_init "/home/mysql"
		DUMP_FILE=/home/mysql/dump_${OLD_DATABASES}.sql
		dump
	else 
		IFS=' ' read -r -a TABLE_ARRAY <<< "$TABLE"
		path_init "/home/mysql/${OLD_DATABASES}"
		for TABLE_SINGLE in "${TABLE_ARRAY[@]}"
		do
			TABLE=$TABLE_SINGLE
			DUMP_FILE=/home/mysql/$OLD_DATABASES/dump_${OLD_DATABASES}_$TABLE.sql
			dump 
		done
	fi


}


function dump()
{
	/usr/local/mysql/mysqlserver/mysql57/bin/mysqladmin ping  -h $OLD_DB_HOST -u $OLD_DB_USER -p$OLD_DB_PASSWD -P $OLD_DB_PORT 
	if [ $? != 1 ];then 
		/usr/local/mysql/mysqlserver/mysql57/bin/mysqldump -h $OLD_DB_HOST -u $OLD_DB_USER -p$OLD_DB_PASSWD -P $OLD_DB_PORT   --single-transaction --databases $OLD_DATABASES --tables $TABLE --net_buffer_length=16777216 --max_allowed_packet=134217728 --master-data=1 --extended-insert > $DUMP_FILE
		echo -e "\e[033m备份文件位置：$DUMP_FILE\e[0m\n"
	else
		echo -e "\e[031merror: 数据库连接失败\e[0m"
	fi 
}


function input_table()
{	
	#新库名检测，没有就创建
	DB_QUERY="select schema_name from information_schema.SCHEMATA where schema_name = '"${NEW_DATABASES}"' ;"
	QUERY_RESULT=$(/usr/local/mysql/mysqlserver/mysql57/bin/mysql -h $NEW_DB_HOST -u $NEW_DB_USER -p$NEW_DB_PASSWD -P $NEW_DB_PORT -e "$DB_QUERY" | awk '{ print $1 }')
	DATABASE_NAME=$(echo "$QUERY_RESULT" | sed -n '2p')
	if [[  -z ${DATABASE_NAME} ]];then
		/usr/local/mysql/mysqlserver/mysql57/bin/mysql -h $NEW_DB_HOST -u $NEW_DB_USER -p$NEW_DB_PASSWD -P $NEW_DB_PORT  -e "create database $NEW_DATABASES"
	fi

	if [[ "$PER_TABLE" -eq 0 ]];then
		input $DUMP_FILE
	else
		for INPUT_FILE in "$FILE_PATH"/*
		do
			if [[ -f $INPUT_FILE ]]; then

				input $INPUT_FILE
			fi
		done
	fi
}




function input()
{
	INPUT_FILE_PERTABLE=$1
	/usr/local/mysql/mysqlserver/mysql57/bin/mysqladmin ping  -h $NEW_DB_HOST -u $NEW_DB_USER -p$NEW_DB_PASSWD -P $NEW_DB_PORT 
	if [[ $? != 1 ]];then 
# 以下下内容作为对全部导出的
#		if [[ "$PER_TABLE" -eq 0 ]] && $;then
#			echo  -e "导入备份文件：$DUMP_FILE\n"
#			USE_DB="USE \`${NEW_DATABASES}\`"
#			awk -v db="$OLD_DATABASES" '$0 ~ db  { found = 1; exit } END { if (found) print "Database found"; else print "Database not found" }' $DUMP_FILE
#			if [ $? -ne 0 ]; then
#	   			echo -e "\e[031mError: 新库名不存在请检查备份文件\e[0m"
#				exit 1
#			fi
#		fi
		/usr/local/mysql/mysqlserver/mysql57/bin/mysql -h $NEW_DB_HOST -u $NEW_DB_USER -p$NEW_DB_PASSWD -P $NEW_DB_PORT $NEW_DATABASES < ${INPUT_FILE_PERTABLE}

	else
		echo -e "\e[031merror: 数据库连接失败\e[0m"
	fi 
}




echo '#######数据全量迁移#######'
echo "源库名：$OLD_DATABASES"
echo "目标库名：$NEW_DATABASES"
current_time=$(date "+%Y-%m-%d %H:%M:%S")
echo -e "\e[033m开始备份时间: $current_time\e[0m"
echo "##########开始备份###########"
dump_table

current_time=$(date "+%Y-%m-%d %H:%M:%S")
echo -e "\e[033m备份完成时间: $current_time\e[0m"
echo "##########开始导入###########"
input_table

current_time=$(date "+%Y-%m-%d %H:%M:%S")
echo -e "\e[033m导入完成时间: $current_time\e[0m"
