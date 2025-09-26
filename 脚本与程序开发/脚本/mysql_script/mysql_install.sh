#!/bin/bash
################################################################
#
#                     Mysql脚本一键安装
#
#Auth:        qian
#version:     v1.0
#                    
#执行方式
#
#软件目录结构:
#  开启版本控制 例： 填写/usr/local/mysql  则实际安装目录为 /usr/local/mysql/mysql56+小版本
#  未开启版本控制则不区分版本，只使用传入的目录
#  /usr/local/mysql/mysqlserver
#          - mysql5628
#          - mysql5735
#          - mysql8023
#
#
#数据目录结构:
#  开启版本控制 例： 填写/usr/local/mysql_data  则实际数据目录为 /usr/local/mysql_data/mysqldata56+小版本/db3306 
#  未开启版本控制则不区分版本，只使用传入的目录/db3306
#  /usr/local/mysql/mysqldata
#          - db3306
#          - db3307
#          - db3308
#  data目录 /usr/local/mysql/mysqldata/db3306/data
#  log目录  /usr/local/mysql/mysqldata/db3306/log
#  tmp目录  /usr/local/mysql/mysqldata/db3306/tmp
#  run目录  /usr/local/mysql/mysqldata/db3306/run
#  conf目录 /usr/local/mysql/mysqldata/db3306/conf
################################################################


######      自定义参数     #######
## 软件目录（mysql官方tar包，不允许更改官方tar包名称（判断version））
package_dir= 
package_file=


## 软件安装目录 里层区分版本 
## 开启版本控制 例： 填写/usr/local/mysql  则实际安装目录为 /usr/local/mysql/mysql56+小版本
## 未开启版本控制则不区分版本，只使用传入的目录
base_path='/usr/local/mysql/mysqlserver' 

## 数据保存目录 里层区分端口 
## 开启版本控制 例： 填写/usr/local/mysql_data  则实际数据目录为 /usr/local/mysql_data/mysqldata56+小版本/db3306 
## 未开启版本控制则不区分版本，只使用传入的目录/db3306 
data_path='/usr/local/mysql/mysqldata'  

## 实例端口
dbport=3306

#目录版本控制开关 0 不开启 1 全部开启 2 开启basedir 3 开启datadir
version_control=0  

#运行步骤
run_step=0

function dir_format(){
    dir=$1
    path1=$(basename $dir)
    path2=$(dirname $dir)
    path=$path2/$path1
    echo "$path"
}

function usage(){
    echo ""
    echo "Usage: "
    echo "   --package_dir:      输入Mysql安装包目录"
    echo "   --package_file:     输入Mysql安装包文件名称（注意使用Mysql官方安装包）"
    echo "   --port|-p:          输入需要安装的Mysql的端口"
    echo "   --data_path:        输入需要安装的Mysql的数据保存目录"
    echo "   --base_path:        输入需要安装的Mysql的软件安装目录"
    echo "   --version_control:  目录版本控制开关: 0 不开启 1 全部开启 2 开启basedir 3 开启datadir 默认0 不开启"
    echo "   --run_step:         运行步骤: 0 linux系统配置 和 安装Mysql server 和 Mysql instance 和 初始化Mysql配置 1 安装Mysql server 和 Mysql instance 和 初始化Mysql配置 2 Mysql instance 和 初始化Mysql配置 11 linux系统配置 12 安装Mysql server 13 创建Mysql instance 14 初始化Mysql配置 默认0"
    echo ""
    echo ""
}

#-o或--options选项后面接可接受的短选项，如ab:c::，表示可接受的短选项为-a -b -c，其中-a选项不接参数，-b选项后必须接参数，-c选项的参数为可选的
#-l或--long选项后面接可接受的长选项，用逗号分开，冒号的意义同短选项。
#-n选项后接选项解析错误时提示的脚本名字
ARGS=$(getopt --options p:h --long package_dir:,package_file:,port:,help,data_path:,base_path:,version_control:,run_step:, -n 'mysql_install.sh' -- "$@")
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
            dbport=$2
            shift 2
            ;;
        --package_dir)
            package_dir=$2
            shift 2
            ;;
        --package_file)
            package_file=$2
            shift 2
            ;;
        --data_path)
            data_path=$2
            shift 2
            ;;
        --base_path)
            base_path=$2
            shift 2
            ;;
        --version_control)
            version_control=$2
            if [[ $version_control -ne 0 && $version_control -ne 1  && $version_control -ne 2 && $version_control -ne 3 ]];then
               echo ""
               echo "Internal error! version_control is not correct"
               usage
               exit 1
            fi
            shift 2
            ;;
        --run_step)
            run_step=$2
            if [[ $run_step -ne 0 && $run_step -ne 1 && $run_step -ne 2 && $run_step -ne 11 && $run_step -ne 12 && $run_step -ne 13 && $run_step -ne 14 ]];then
               echo ""
               echo "Internal error! run_step is not correct"
               usage
               exit 1
            fi
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

echo ""
echo -e "\e[032mINFO:    variables param\e[0m"
echo "package_dir:       $package_dir"
echo "package_file:      $package_file"
echo "dbport:            $dbport"
echo "data_path:         $data_path"
echo "base_path:         $base_path"
echo "version_control:   $version_control"
echo "run_step:          $run_step"
echo ""
echo ""

#exit 1

#while getopts "p:h" opt
#do
#    case $opt in
#        p)
#        dbport=$OPTARG
#        ;;
#        h)
#        echo "Usage: "
#        echo "     -h help "
#        echo "     -p port"
#        exit 1
#        ;;
#        ?)
#        echo "Invalid option: -$OPTARG"
#        echo ""
#        echo "Usage: "
#        echo "     -h help "
#        echo "     -p port"
#        exit 1;;
#    esac
#done



######       开始安装      #######
package_path=$package_dir/$package_file
base_path=$(dir_format "$base_path")
data_path=$(dir_format "$data_path")
version=$(ls "$package_path"|awk -F '-' '{print $2}'|awk -F '.' '{print $1$2}')
little_version=$(ls "$package_path"|awk -F '-' '{print $2}'|awk -F '.' '{print $1$2$3$4}')
date=$(/usr/bin/date +%Y%m%d_%H_%M)

if [[ $version -ne '56' && $version -ne '57' && $version -ne '80' ]]; then
    echo "mysql version not right!!!"
    exit 1
fi

if [ "$version_control" -eq 0 ];then
    base_dir=$base_path
    data_dir=$data_path
elif [ "$version_control" -eq 1 ];then
    base_dir=$base_path/mysql$little_version
    data_dir=$data_path/mysqldata$little_version
elif [ "$version_control" -eq 2 ];then
    base_dir=$base_path/mysql$little_version
    data_dir=$data_path
elif [ "$version_control" -eq 3 ];then
    base_dir=$base_path
    data_dir=$data_path/mysqldata$little_version
fi

conf_path=$data_dir/db$dbport/conf/my$dbport.cnf 
if [ ! -e "$package_path" ]; then
    echo "mysql package not exist!!!"
    exit 1
fi


function log(){
    if [ "$1" == 'warning' ]; then 
        echo -e "\e[033mWarning: $2\e[0m"
    elif [ "$1" == 'info' ]; then
        echo -e "\e[032mInfo:    $2\e[0m"
    elif [ "$1" == 'error' ]; then
        echo -e "\e[031mError:   $2\e[0m"
    else 
        echo "$1"
    fi
}


function linux_system_limit(){
    log 'info' "Begin update linux system variables......"
    echo ""
    cp /etc/sysctl.conf /tmp/sysctl.conf_"$date"
    log 'info' "/etc/sysctl.conf backup path /tmp/sysctl.conf_$date"
    mem_max=$(cat /proc/meminfo | grep MemTotal | awk '{printf ("%d\n",$2*1024*0.8)}')
    mem_max_set=$(cat /etc/sysctl.conf | grep 'kernel.shmmax' | wc -l)
    if [ "$mem_max_set" -eq 0 ];then
        log 'info' "shmmax not set, shmmax value: $mem_max ......"
        echo "kernel.shmmax=$mem_max" >> /etc/sysctl.conf
    else
        log 'warning' "shmmax already set, please check ......"
        #sed -i "s/kernel.shmmax\s*=\s*[0-9]*/kernel.shmmax=$mem_max/g" /etc/sysctl.conf
    fi
    
    mem_all=$(cat /proc/meminfo | grep MemTotal | awk '{printf ("%d\n",$2*1024/4096)}')
    mem_all_set=$(cat /etc/sysctl.conf | grep 'kernel.shmall' | wc -l)
    if [ "$mem_max_set" -eq 0 ];then
        log 'info' "shmall not set, shmall value: $mem_all ......"
        echo "kernel.shmall=$mem_all" >> /etc/sysctl.conf
    else
        log 'warning' "shmall already set, please check ......"
        #sed -i "s/kernel.shmall\s*=\s*[0-9]*/kernel.shmall=$mem_all/g" /etc/sysctl.conf
    fi
    
    cp /etc/security/limits.conf /tmp/limits.conf_"$date"
    echo ""
    log 'info' "/etc/security/limits.conf backup path /tmp/limits.conf_$date"
    nofile_limit=$(cat /etc/security/limits.conf | grep -E 'mysql' | grep 'nofile' | grep -v "#"| wc -l)
    if [ "$nofile_limit" -eq 0 ];then
        echo 'mysql   soft    nofile   65535' >> /etc/security/limits.conf
        echo 'mysql   hard    nofile   65535' >> /etc/security/limits.conf
    else
        sed -i "s/^mysql\s*soft\s*nofile\s*[0-9]*/mysql soft nofile 65535/g" /etc/security/limits.conf 
        sed -i "s/^mysql\s*hard\s*nofile\s*[0-9]*/mysql hard nofile 65535/g" /etc/security/limits.conf 
    fi
    
    nproc_limit=$(cat /etc/security/limits.conf | grep -E 'mysql' | grep 'nproc' | grep -v "#"| wc -l)
    if [ "$nofile_limit" -eq 0 ];then
        echo 'mysql   soft    nproc   65535' >> /etc/security/limits.conf
        echo 'mysql   hard    nproc   65535' >> /etc/security/limits.conf
    else
        sed -i "s/^mysql\s*soft\s*nproc\s*[0-9]*/mysql soft nproc 65535/g" /etc/security/limits.conf 
        sed -i "s/^mysql\s*hard\s*nproc\s*[0-9]*/mysql hard nproc 65535/g" /etc/security/limits.conf 
    fi
    log 'info' "End update linux system variables...... \n\n\n"
}

function create_mysql_server() {

    log 'info' "Begin install mysql ......"
   
    if [ -e "$base_dir" ]; then
        log 'error' "Base dir $base_dir already exist, please check ...... \n\n\n"
        exit 1
    else
        mkdir -p "$base_dir"
    fi
    

    #create user
    user_count=$(id mysql | wc -l)
    if [ "$user_count" -eq 0 ];then
        groupadd mysql
        useradd -g mysql mysql
        
        echo "MYSQL_HOME=$base_dir" >> /home/mysql/.bash_profile
        echo "PATH=\$PATH:\$MYSQL_HOME/bin" >> /home/mysql/.bash_profile
        echo "export PATH" >> /home/mysql/.bash_profile
    else 
        echo ""
        echo ""
        log 'warning' "Mysql环境变量需要增加，请手动确认是否增加......"
        log 'warning' "    MYSQL_HOME=$base_dir"
        log 'warning' "    PATH=\$PATH:\$MYSQL_HOME/bin"
        echo ""
        echo ""
        echo ""
    fi 

    

    #install mysql 
    yum install -y make gcc-c++ cmake bison-devel ncurses-devel bison pstack openssl libaio  autoconf
  
    if [ "$version" -eq '56' ]; then
        tar -zxf "$package_path" -C "$base_dir" --strip-components 1
        cp "$base_dir"/bin/mysqld_safe "$base_dir"/bin/mysqld_safe_bak
        sed "s#/usr/local/mysql#$base_dir#g" "$base_dir"/bin/mysqld_safe_bak > "$base_dir"/bin/mysqld_safe
    else
        tar -zxf "$package_path" -C "$base_dir" --strip-components 1
    fi
    chown -R mysql. "$base_dir"
    
    log 'info' "END install mysql ......\n\n\n"

}


function create_mysql_instance(){
    log 'info' "Begin install mysql instance......"
    if [ -e "$data_dir"/db"$dbport" ]; then
        log 'error' "Mysql $data_dir/db$dbport already exist!!!"
        exit 1    
    fi 
    
    port_count=$(netstat -anl| grep "$dbport" | grep -v 33060 | grep -v 33061 | grep LISTEN | wc -l)
    if [ "$port_count" -gt 0 ]; then
        log 'error' "Mysql $dbport already exist!!!"
        exit 1    
    fi 
    

    mkdir -p "$data_dir"/db"$dbport"
    mkdir -p "$data_dir"/db"$dbport"/log
    mkdir -p "$data_dir"/db"$dbport"/run
    mkdir -p "$data_dir"/db"$dbport"/data
    mkdir -p "$data_dir"/db"$dbport"/tmp
    mkdir -p "$data_dir"/db"$dbport"/conf
	touch "$data_dir"/db"$dbport"/log/alert.log
	
    if [ "$version" -eq '56' ]; then
        init_mysql_cmd="$base_dir/scripts/mysql_install_db --user=mysql --basedir=$base_dir --datadir=$data_dir/db$dbport/data --innodb-data-file-path=ibdata1:16m --innodb-undo-tablespaces=4 --lower-case-table-names=1"
        cp ./my56.cnf "$conf_path"
    elif [ "$version" -eq '57' ]; then
        init_mysql_cmd="$base_dir/bin/mysqld --initialize-insecure --user=mysql --basedir=$base_dir --datadir=$data_dir/db$dbport/data --innodb-undo-tablespaces=4 --lower-case-table-names=1 --innodb-data-file-path=ibdata1:16m"
        cp ./my57.cnf "$conf_path"
    elif [ "$version" -eq '80' ]; then
        init_mysql_cmd="$base_dir/bin/mysqld --initialize-insecure --user=mysql --basedir=$base_dir --datadir=$data_dir/db$dbport/data --innodb-undo-tablespaces=4 --lower-case-table-names=1 --innodb-data-file-path=ibdata1:16m"
        cp ./my80.cnf "$conf_path"
    fi

    chown mysql. "$data_dir"
    chown -R mysql. "$data_dir"/db"$dbport"
    
    log 'info' "$init_mysql_cmd"
    echo ""
    echo ""
    $($init_mysql_cmd)
    
    ##配置参数
    buffer_limit=$(cat /proc/meminfo | grep MemTotal | awk '{printf ("%d\n",$2/1024/1024*0.8*0.8)}')G
    server_id=$RANDOM
    #sed -i "s/innodb_buffer_pool_size=[0-9]*G/innodb_buffer_pool_size=$buffer_limit/g" $conf_path
    sed -i "s/server_id=[0-9]*/server_id=$server_id/g" "$conf_path"
    sed -i "s/3306/$dbport/g" "$conf_path"
	sed -i "s#/usr/local/mysql/mysqldata#$data_dir#g" "$conf_path"
	sed -i "s#/usr/local/mysql/mysqlserver#$base_dir#g" "$conf_path"
    echo ""
    echo ""
    log 'warning' "Server_id: $server_id"
    log 'warning' "Notice:"
    log 'warning' "sort buffer:     sort_buffer_size     默认:256K"
    log 'warning' "join buffer:     join_buffer_size     默认:128K"
    log 'warning' "最大连接数:       max_connections      默认:4500"
    log 'warning' "user最大连接数:   max_user_connections 默认:4000"
    log 'warning' "配置文件目录:     vi $conf_path"
    echo ""
    echo ""

    
}

function mysql_startup(){
    echo "$base_dir/bin/mysqld_safe --defaults-file=$conf_path &2>&1 > /dev/null" > /home/mysql/"$dbport"-start.sh
    echo "$base_dir/bin/mysql -S $data_dir/db$dbport/run/mysql$dbport.sock" > /home/mysql/"$dbport"-login.sh 
    
    chmod u+x /home/mysql/"$dbport"-login.sh 
    chown -R mysql. /home/mysql/"$dbport"-login.sh 
    
    chmod u+x /home/mysql/"$dbport"-start.sh
    chown -R mysql. /home/mysql/"$dbport"-start.sh
    
    
    /home/mysql/"$dbport"-start.sh
    echo ""
    echo ""
    log 'info' "Mysql $dbport Already in starting....."
    log 'info' "LOG Directory: tail -f $data_dir/db$dbport/log/alert.log"
    echo ""
    echo ""
    
    while true
    do  
        sleep 10
        connect=$($base_dir/bin/mysql -S "$data_dir"/db"$dbport"/run/mysql"$dbport".sock -e 'select now()' | wc -l)
        if [ "$connect" -gt 0 ];then
            break
        fi
    done
    echo ""
    log 'info' "Mysql $dbport Already started....."
    echo ""
    
}


function create_mysql_user(){
echo ""
log 'info' "Create mysql user......"

if [ "$version" -eq '56' ]; then
"$base_dir"/bin/mysql -S "$data_dir"/db"$dbport"/run/mysql"$dbport".sock <<EOF
    create user 'dzjroot'@'%' identified by 'Dzj_pwd_2022';
    grant all privileges on *.* to 'dzjroot'@'%';
    create user 'dzjrep'@'%' identified by 'Dzj_pwd_2022';
    grant replication client,replication slave on *.* to 'dzjrep'@'%';

    flush privileges;
EOF
else
"$base_dir"/bin/mysql -S "$data_dir"/db"$dbport"/run/mysql"$dbport".sock <<EOF
    drop user if EXISTS 'dzjroot'@'%';
    create user 'dzjroot'@'%' identified by 'Dzj_pwd_2022';
    grant all privileges on *.* to 'dzjroot'@'%';
    
    drop user if EXISTS 'dzjrep'@'%';
    create user 'dzjrep'@'%' identified by 'Dzj_pwd_2022';
    grant replication client,replication slave on *.* to 'dzjrep'@'%';

    flush privileges;
    -- select user from mysql.user;
EOF
fi

if [ $? = 0 ]; then 
    echo ""
    echo ""
    log 'info' "Already create mysql user dzjroot......"
    log 'info' "Already create mysql user dzjrep......"
else
    echo ""
    echo ""
    log 'error' "Failed create mysql user dzjroot......"
    log 'error' "Failed create mysql user dzjrep......"
fi 
}

if [ "$run_step" -eq 0 ] || [ "$run_step" -eq 11 ]; then
    linux_system_limit
fi

if [ "$run_step" -eq 0 ] || [ "$run_step" -eq 1 ] || [ "$run_step" -eq 12 ]; then
    create_mysql_server
fi

if [ "$run_step" -eq 0 ] || [ "$run_step" -eq 1 ] || [ "$run_step" -eq 2 ] || [ "$run_step" -eq 13 ]; then
    create_mysql_instance
    mysql_startup
fi

if [ "$run_step" -eq 0 ] || [ "$run_step" -eq 1 ] || [ "$run_step" -eq 2 ] || [ "$run_step" -eq 14 ]; then
    create_mysql_user
fi
