#!/bin/sh
#version 1.0


#默认软件安装路径 /usr/local
mysql_install_dir='/usr/local'

#默认数据文件安装路径 /data/mysql
mysql_db_dir='/data/mysql'

#默认配置文件路径 /etc
mysql_cf_dir='/etc'

#默认设置环境变量
set_profile=1

#是否是安装多实例
is_multi_instance=1

#默认存放安装文件的目录
datamenu="/home/sx/soft"

mysql_version=8.0.28
mysql_port=3306

count=`ip a | grep inet| grep -v '127.0.0.1' | grep -v bond0:1  | grep -v inet6 | awk '{print $2}' | awk -F / '{print $1}' |awk -F . '{print $3$4}' |wc -l `
if [[ $count == 1 ]] ;
then
    is_server_id=`ip a | grep inet| grep -v '127.0.0.1' | grep -v bond0:1  | grep -v inet6 | awk '{print $2}' | awk -F / '{print $1}' |awk -F . '{print $3$4}'`

else
    read -p "please enter server_id for mysql :" is_server_id
fi


mysql_server_id=$is_server_id
#mysql_db_type=sit


#判断端口是否占用
netstat -antupl|grep $mysql_port  >& /dev/null
if [ $? -eq 0 ]
then
    echo "端口被占用,请更换其他端口!"
        exit 1
fi


#安装前清除目录,测试时用
rm -rf $mysql_db_dir
rm -rf /usr/local/mysql*
rm -rf /etc/my.cnf

#定义mysql文件名
mysqlfile="$datamenu/mysql-$mysql_version-linux-glibc2.12-x86_64.tar"
echo "================================================================"
echo "默认安装文件位置$mysqlfile"
echo "================================================================"

#判断/opt/soft目录是否存在，若不存在则创建，并且下载mysql
#echo "开始下载 mysql-$mysql_version-linux-glibc2.12-x86_64.tar.gz"
#if [ ! -d "$datamenu" ];then
#     mkdir -p "$datamenu"
#     wget -P $datamenu -c https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-$mysql_version-linux-glibc2.12-x86_64.tar.gz
#elif [ ! -f "$mysqlfile" ];then
#     wget -P $datamenu -c https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-$mysql_version-linux-glibc2.12-x86_64.tar.gz
#fi

if [ -d '/opt/soft' ];
then echo''
else mkdir /opt/soft
fi



cd /opt/soft
#下载数据库管理等相关软件
echo "下载数据库相关软件"


#判断安装目录是否存在mysql文件夹
echo "解压包tar.gz到指定文件夹"
if [ -d $mysql_install_dir/mysql ]; then
     echo "安装目录下存在mysql文件夹,请确认!"
         exit 1
fi


#解压mysql文件
tar -xvf $mysqlfile -C $mysql_install_dir

#tar -xvf  percona-toolkit-3.0.12-re3a693a-el7-x86_64-bundle.tar
#tar -xvf  Percona-XtraBackup-2.4.14-ref675d4-el7-x86_64-bundle.tar

#安装工具包及相关依赖
echo "安装相关工具包和依赖"
yum install -y  *.rpm
yum install -y  libaio perl  perl-devel  libaio-devel perl-Time-HiRes perl-DBD-MySQL libev glibc-static zlib-devel devscripts-minimal 

#创建mysql组和用户
egrep "^mysql" /etc/group >& /dev/null
if [ $? -ne 0 ]
then
    groupadd mysql
fi

egrep "^mysql" /etc/passwd >& /dev/null
if [ $? -ne 0 ]
then
    useradd -g mysql -s /sbin/nologin -d /home/mysql mysql
fi

#创建mysql软连接，并授权给mysql用户
cd $mysql_install_dir
ln -s $mysql_install_dir/mysql-$mysql_version-linux-glibc2.12-x86_64 $mysql_install_dir/mysql
chown -R mysql:mysql $mysql_install_dir/mysql
chown -R mysql:mysql $mysql_install_dir/mysql/



###创建data的存放目录

#判断目录是否存在
if [ -d $mysql_db_dir ]; then
     echo "数据目录下存在文件夹,请确认!"
         exit 1
fi

mkdir -p $mysql_db_dir/{mysql_data,mysql_log,mysql_tmp}
mkdir -p $mysql_db_dir/mysql_log/{binlog,relaylog,logs}
chown -R mysql:mysql $mysql_db_dir


#写配置文件,用mysqld_multi方式启动数据库
echo "生成配置文件"
cat > $mysql_cf_dir/my.cnf << EOF

[client]
port            = ${mysql_port}
socket          = ${mysql_db_dir}/mysql.sock

[mysql]
no-auto-rehash
max_allowed_packet = 128M
prompt                         = '(\u@\h) [\d]> '
default_character_set          = utf8mb4
#pager = "more"


[mysqld_multi]
mysqld      = $mysql_install_dir/mysql/bin/mysqld
mysqladmin  = $mysql_install_dir/mysql/bin/mysqladmin
user        = root

[mysqldump]
quick
max_allowed_packet = 1024M
#myisam_max_sort_file_size  = 10G

[myisamchk]
key_buffer_size            = 64M
sort_buffer_size           = 512k
read_buffer                = 2M
write_buffer               = 2M

[mysqlhotcopy]
interactive-timeout

[mysqld_safe]
#malloc-lib= $mysql_install_dir/mysql/lib/mysql/libjemalloc.so
default_authentication_plugin = mysql_native_password



#[mysqld$mysql_port]
[mysqld]
port            = ${mysql_port}
user            = mysql
socket          = ${mysql_db_dir}/mysql.sock
basedir         = $mysql_install_dir/mysql
datadir         = ${mysql_db_dir}/mysql_data
tmpdir          = ${mysql_db_dir}/mysql_tmp

character-set-server    = utf8mb4
sysdate-is-now
skip-name-resolve
read_only              =0

open_files_limit        = 60000
table_open_cache        = 4096
table_definition_cache  = 4096

max_connections         = 5000
max_connect_errors      = 100000
back_log                                = 1000

wait_timeout                    = 3000
interactive_timeout     = 3000


sort_buffer_size            = 32M
read_buffer_size                = 8M
read_rnd_buffer_size    = 16M
join_buffer_size                = 32M
tmp_table_size                  = 512M
max_heap_table_size     = 512M
max_allowed_packet              = 128M
myisam_sort_buffer_size = 64M


key_buffer_size             = 1G
query_cache_type                = 0
query_cache_size                = 0



eq_range_index_dive_limit= 2000
lower_case_table_names    = 1

explicit_defaults_for_timestamp = 1
# ====================== Logs Settings ================================
log-error            = ${mysql_db_dir}/mysql_log/logs/error.log
slow-query-log
slow-query-log-file  = ${mysql_db_dir}/mysql_log/logs/slow.log
long_query_time      = 3

#log_slow_slave_statements = 1

log_bin_trust_function_creators=1
log-bin         = ${mysql_db_dir}/mysql_log/binlog/mysql-bin
log-bin-index   = ${mysql_db_dir}/mysql_log/binlog/mysql-bin.index

sync_binlog        = 1
expire_logs_days   = 7
binlog_format      = ROW
binlog_cache_size  = 8M


# ===================== Replication settings =========================
server-id          = ${mysql_server_id}
binlog_gtid_simple_recovery      = 1
gtid_mode                        = on
enforce-gtid-consistency         = 1

relay-log          = ${mysql_db_dir}/mysql_log/relaylog/mysql-relay-bin
relay-log-index    = ${mysql_db_dir}/mysql_log/relaylog/mysql-relay-bin.index
relay-log-purge    = 0
log-slave-updates
master_info_repository    = TABLE
relay_log_info_repository = TABLE
relay_log_recovery                = 1

# ====================== INNODB Specific Options ======================
innodb_data_home_dir             = ${mysql_db_dir}/mysql_data
innodb_data_file_path                = ibdata1:10M:autoextend
innodb_buffer_pool_size              = 512M
innodb_log_buffer_size               = 64M
innodb_log_group_home_dir            = ${mysql_db_dir}/mysql_data
innodb_log_files_in_group            = 5
innodb_log_file_size                 = 50m
innodb_fast_shutdown                 = 1
innodb_force_recovery                = 0
innodb_file_per_table                = 1
innodb_lock_wait_timeout             = 100
innodb_thread_concurrency            = 64
innodb_flush_log_at_trx_commit       = 1
innodb_flush_method                  = O_DIRECT
innodb_read_io_threads               = 12
innodb-write-io-threads              = 16
innodb_io_capacity                   = 100
innodb_io_capacity_max               = 500
innodb_purge_threads                 = 1
innodb_autoinc_lock_mode             = 2
innodb_buffer_pool_instances         = 8
innodb_sort_buffer_size              = 6M
innodb_max_dirty_pages_pct           = 75
transaction-isolation                = READ-COMMITTED
# ======================  Undo Options ======================
innodb_undo_directory =${mysql_db_dir}/mysql_data
innodb_undo_logs = 128
innodb_undo_tablespaces = 4
innodb_undo_log_truncate = on
innodb_max_undo_log_size = 100m
innodb_purge_rseg_truncate_frequency = 128

# ======================  mysqld-5.7 ======================
log_timestamps                   = system
innodb_purge_rseg_truncate_frequency = 128
innodb_buffer_pool_dump_pct      = 40
innodb_undo_log_truncate         = on
innodb_max_undo_log_size         = 5M
slave_preserve_commit_order      = 1
show_compatibility_56            =on
slave-parallel-type              = LOGICAL_CLOCK
slave_parallel_workers          = 8
sql_mode = ''
event_scheduler=ON


EOF

#版本处理

#8.0版本补在支持的参数调整
echo "$mysql_version" |egrep  '8.[0-9].{1,}[0-9]'
if [ $? -eq 0 ]
    then
      sed -i "s/query_cache_type/#query_cache_type/" /etc/my.cnf
      sed -i "s/query_cache_size/#query_cache_size/" /etc/my.cnf
      sed -i "s/innodb_undo_logs/#innodb_undo_logs/" /etc/my.cnf
      sed -i "s/show_compatibility_56/#show_compatibility_56/" /etc/my.cnf

fi


#初始化mysql
echo "初始化DB"
cd $mysql_install_dir/mysql
bin/mysqld --initialize-insecure --user=mysql --lc-messages-dir=$mysql_install_dir/mysql/share --basedir=$mysql_install_dir/mysql --datadir=${mysql_db_dir}/mysql_data --default-authentication-plugin=mysql_native_password
echo "初始化DB Done"

#在/etc/init.d下创建mysqld 启动脚本
cp $mysql_install_dir/mysql/support-files/mysql.server /etc/init.d/mysqld
cp $mysql_install_dir/mysql/support-files/mysql.server /usr/lib/systemd/system/mysql



#设置环境变量
if [ $set_profile -ne 0 ];then
    echo "export PATH=\$PATH:$mysql_install_dir/mysql/bin" >> /etc/profile
    source /etc/profile
fi


echo  "安装完成后 service mysqld start 启动 DB"
service mysqld start
echo  "无密码登陆 mysql -S /xxx/mysql.sock"


#删除初始化后的db及log文件
#rm $mysql_db_dir/data/ib* -rf
#rm $mysql_db_dir/logs/ib* -rf


sleep 5

#replace mysql.server basedir and datadir
sed -i 's#^basedir.*#basedir='$mysql_install_dir'/mysql#g'  /etc/init.d/mysqld
sed -i 's#^datadir.*#datadir='$mysql_db_dir'/mysql_data#g' /etc/init.d/mysqld

#registe service
/sbin/chkconfig mysqld on