#/bin/bash

DateTime=`date +%Y%m%d%H%M%S`
DBHost='172.30.70.44'
DBPort=3106
DBUser='flushlogs_user'
DBPass='dzj123,./'
SocketFile='/usr/local/data/mysql_data/db3106/run/mysql3106.sock'
SlowLogDir='/usr/local/data/mysql_data/db3106/log'
SlowLogFile='slow.log'
SlowLogBakDir='/usr/local/data/mysql_data/db3106/log_bak'
SlowLogBakFile="${SlowLogFile}-${DateTime}"

# 判断慢日志备份目录是否存在，没有则创建
[ -d $SlowLogBakDir ] || mkdir -p $SlowLogBakDir

# 判断MySQL实例是否可以正常连接
/usr/local/data/mysql/bin/mysqladmin ping -u$DBUser -p$DBPass -S $SocketFile &>/dev/null;ReturnValue=`echo $?`
if [ $ReturnValue -ne 0 ]; then
	echo -e "MySQL实例无法连接，退出脚本！！！"
	exit 1
fi


# 重命名 Slow log 文件
mv $SlowLogDir/$SlowLogFile $SlowLogDir/$SlowLogBakFile

# 刷新 slow log
/usr/local/data/mysql/bin/mysqladmin -u$DBUser -p$DBPass -S $SocketFile flush-logs slow

# 拷贝刷新前重命名的 slow log 到备份目录下
mv $SlowLogDir/$SlowLogBakFile $SlowLogBakDir/
gzip $SlowLogBakDir/$SlowLogBakFile
