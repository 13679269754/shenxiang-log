#!/bin/sh
################################################################
#
#                     proxysql yum包安装
#
#Auth:        shen
#version:     v1.0
#
#执行方式
#               systemd启动 service文件位置 /usr/lib/systemd/system/proxysql.service
#               手动启动 /usr/bin/proxysql --idle-threads -c /etc/proxysql.cnf
#软件目录结构:
#               /usr/bin/proxysql
#数据目录结构:
#               /usr/local/data/proxysql
################################################################



######      自定义参数     #######
#版本号

## 软件目录
package_dir='/root/soft'

## 数据保存目录 里层区分端口
data_path='/usr/local/data/proxysql'
errorlog='/usr/local/data/proxysql/proxysql.log'

## 实例端口
port=6032

version=''

passwd='admin'

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


function uninstall(){
    pg_count=$(ps -ef |grep '/usr/bin/proxysql' |grep -v 'grep' |wc -l)
    if [ "$pg_count" -gt 0 ];then
        log 'error' 'proxysql进程依然存在'
        exit 0
    fi
    wcount=$(rpm -qa |grep proxysql |wc -l)
    if [ "$wcount" -eq 1 ];then
        rpm_package=$(rpm -qa |grep proxysql)
        rpm -e "$rpm_package"
    fi
    num=$(cat /etc/passwd | grep proxysql | wc -l)
    if [ "$num" -eq 1 ];then
        userdel proxysql
    fi
    #移动数据目录
    #old_data_path=`ps -ef |grep '/usr/bin/proxysql' |grep -v 'grep' |awk '{print $11}' |awk -F '/' '{print $2"/"$3"/"$4"/"$5}'|head -n 1`
    #echo `mv $old_data_path /tmp/`
}

###初始化默认安装包目录
if [ ! -d $package_dir ];then
    mkdir -p $package_dir 
fi


function usage(){
    echo "proxysql_install --proxysql_servers [] --passwd []"
    echo "Usage: 默认创建3个节点的ProxySQL的集群,如需更多请自行修改proxysql.cnf"
    echo "   --package_dir:      输入ProxySQL rpm安装包目录 默认:/root/soft/"
    echo "   --version:          输入ProxySQL版本号 使用该参数表示接受yum安装 默认:2.4.5"
    echo "   --package_file:     输入ProxySQL本地安装包名"
    echo "   --port|-p:          输入需要安装的ProxySQL的管理端口 默认：6032"
    echo "   --data_path:        输入需要安装的ProxySQL的数据保存目录 默认：/usr/local/data/proxysql"
    echo "   --errorlog:         输入需要ProxySQL的错误日志目录 默认：/usr/local/data/proxysql/proxysql.log"
    echo "   --proxysql_servers: 输入ProxySQL的节点列表 例如host1,host2,host3"
    echo "   --passwd:           输入ProxySQL初始化用户passwd，默认用户admin,passwd=admin"
    echo ""
}


ARGS=$(getopt --options p:h --long package_dir:,version:,port:,help:,data_path:,errorlog:,proxysql_servers:,passwd:, -n 'mysql_install.sh' -- "$@")
if [ $? != 0 ]; then
    echo "Terminating..."
    exit 1
fi

#echo $ARGS
#将规范化后的命令行参数分配至位置参数($1,$2,...)
eval set -- "${ARGS}"

while true
do
    case "$1" in
        -p|--port)
            port=$2
            shift 2
            ;;
        --package_dir)
            package_dir=$2
            shift 2
            ;;
        --version)
            version=$2
            shift 2
            ;;
        --data_path)
            data_path=$2
            shift 2
            ;;
        --errorlog)
            errorlog=$2
            shift 2
            ;;
        --proxysql_servers)
            proxysql_servers=$2
            node_count=0
            IFS=,
            for host in $proxysql_servers; do
                node_count=$((node_count+1))
                eval "proxysql_server$node_count=$host"
            done
            shift 2
            ;;
        --passwd)
            passwd=$2
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
################参数检查#############



if [ ${#proxysql_servers[@]} -eq 0  ];then
    log info "proxysql_servers 没有输出，例如host1,host2,host3 请输入： "
    read cmd
    if [ "$cmd"!='' ];then
        proxysql_servers=$cmd
        node_count=1
        IFS=,
        for host in $proxysql_servers; do
            eval "proxysql_servers$node_count=$host"
            node_count=$((node_count+1))
        done
    else
        log error "没有输入proxysql_servers"
        exit 0
    fi
fi

count_package=$(ls "$package_dir" |grep 'proxysql' |wc -l)
if [[ -d $package_dir ]];then
    if [[  $version ]];then
        package_file=$(ls "$package_dir" |grep 'proxysql' |grep "$version")
    elif [[ $count_package -eq 1 ]] ;then
        package_file=$(ls "$package_dir" |grep 'proxysql' )
    else
        log info "安装包目录中有不止一个proxysql包 例子(默认)2.4.5 请输入需要安装的版本："
        read "$version"
        if [[ ! $version ]];then
            version=2.4.5
            package_file=$(ls "$package_dir" |grep  'proxysql' |grep "$version")
        else
            package_file=$(ls "$package_dir" |grep  'proxysql' |grep "$version")
        fi
    fi
else
    log error "package_dir:$package_dir 不存在"
    exit 0
fi


#######################################


function yum_install(){

    if [[ -e $package_dir/$package_file ]] && [ "$package_file" ];then
        echo "rpm包安装$package_dir/$package_file"
        echo "------------------"
        echo "yum install -y $package_dir/$package_file"
        yum install -y "$package_dir"/"$package_file"
    else
        echo "是否下载yum包,并安装y/n ,默认不下载并退出 :"
        read cmd
        if [ "$cmd" = 'y' ] || [ "$cmd" = 'Y' ];then 
            cat > /etc/yum.repos.d/proxysql.repo << EOF
[proxysql]
name=ProxySQL YUM repository
baseurl=https://repo.proxysql.com/ProxySQL/proxysql-2.4.x/centos/\$releasever
gpgcheck=1
gpgkey=https://repo.proxysql.com/ProxySQL/proxysql-2.4.x/repo_pub_key
EOF
            echo "yum安装proxysql ......"    
            echo  "yum install -y proxysql-$version"
            yum install -y proxysql-"$version" 
            if [ $? = 0 ];then
                log error "yum安装proxysql 失败"
                exit 0
            fi
        fi
    fi
    mkdir -p "$data_path"/conf  
}


function user_init(){
    num=$(cat /etc/passwd | grep proxysql | wc -l)
    if [ "$num" -eq 1 ];then
        userdel proxysql
    fi

    groupadd proxysql
    useradd proxysql -g proxysql -s /bin/bash
    
    PROXYSQL_HOME=/home/proxysql
    echo "/usr/bin/proxysql --idle-threads -c $data_path/conf/proxysql.cnf" > $PROXYSQL_HOME/proxysql_start.sh
    echo 'ps -ef | grep proxysql |grep -v 'grep'
    yum install -y psmisc 
    killall proxysql' > $PROXYSQL_HOME/proxysql_stop.sh
    echo -e "/usr/local/data/mysql/bin/mysql -uadmin -p -h127.0.0.1 -P6032 --prompt='Admin> ' --default-auth=mysql_native_password" > $PROXYSQL_HOME/proxysql_login.sh
    
    chown -R proxysql:proxysql "$data_path"
    chmod u+x $PROXYSQL_HOME/proxysql*.sh
    chown -R proxysql:proxysql $PROXYSQL_HOME
}


function  conf_init(){
    cat >  "$data_path"/conf/proxysql.cnf << EOF
    datadir="${data_path}"
    errorlog="${errorlog}"
    
    admin_variables=
    {
        admin_credentials="admin:${passwd};cluster_demo:${passwd}"
        #       mysql_ifaces="127.0.0.1:${port};/tmp/proxysql_admin.sock"
        mysql_ifaces="0.0.0.0:${port}"
        cluster_username="cluster_demo"  #同上面的culster名字自定义
        cluster_password="${passwd}"   #同上面的cluster密码
        cluster_check_interval_ms=200
        cluster_check_status_frequency=100
        cluster_mysql_query_rules_save_to_disk=true
        cluster_mysql_servers_save_to_disk=true
        cluster_mysql_users_save_to_disk=true
        cluster_proxysql_servers_save_to_disk=true
        cluster_mysql_query_rules_diffs_before_sync=3
        cluster_mysql_servers_diffs_before_sync=3
        cluster_mysql_users_diffs_before_sync=3
        cluster_proxysql_servers_diffs_before_sync=3
        #refresh_interval=2000
        #debug=true
    }
    
    
    #数据库相关参数：
    mysql_variables=
    {
        threads=4
        max_connections=2048
        default_query_delay=0
        default_query_timeout=36000000
        have_compress=true
        poll_timeout=2000
        #interfaces="0.0.0.0:6033;/tmp/proxysql.sock"
        interfaces="0.0.0.0:6033"
        default_schema="information_schema"
        stacksize=1048576
        server_version="8.0.19"
        connect_timeout_server=3000
        # make sure to configure monitor username and password
        # https://github.com/sysown/proxysql/wiki/Global-variables#mysql-monitor_username-mysql-monitor_password
        monitor_username="monitor"  #监控账号
        monitor_password="monitor"
        monitor_history=600000
        monitor_connect_interval=60000
        monitor_ping_interval=10000
        monitor_read_only_interval=1500
        monitor_read_only_timeout=500
        ping_interval_server_msec=120000
        ping_timeout_server=500
        commands_stats=true
        sessions_sort=true
        connect_retries_on_failure=10
    }
EOF
}

function node_cluster(){
    i=1
    cluster_conf="proxysql_servers = \n(\n"
    node_count_num=$(($node_count-1))
    while  (( i <= $node_count_num ))
    do
        
        cluster_node="proxysql_server${i}"
        cluster_conf="$cluster_conf {\n    hostname=\"${!cluster_node}\"\n    port=$port\n    weight=0\n    comment=\"proxysql${i}\"\n },\n"
        i=$((i+1))
    done
        cluster_node="proxysql_server${i}"
        cluster_conf="$cluster_conf {\n    hostname=\"${!cluster_node}\"\n    port=$port\n    weight=0\n    comment=\"proxysql${i}\"\n }\n"
    cluster_conf="$cluster_conf)"
    cluster_conf_format=$(echo -e $cluster_conf)
    echo -e "$cluster_conf" >> "$data_path"/conf/proxysql.cnf
}

function conf_bulid(){
    conf_init
    node_cluster
}


function systemd_updata(){
   service_path=$(rpm -ql proxysql-2.4.5-1.x86_64 |grep proxysql.service)
   sed -i "s|PIDFile=/var/lib/proxysql/proxysql.pid|PIDFile=${data_path}/proxysql.pid|g" "$service_path"
   sed -i "s|/etc/proxysql.cnf|$data_path/conf/proxysql.cnf|g" "$service_path"
}

uninstall

yum_install

user_init

conf_bulid

systemd_updata

echo "启动ProxySQL"
#修改systemd脚本相关配置

echo "######################"
echo "systemd启动 service文件位置 $service_path"
echo "手动启动 $PROXYSQL_HOME/proxysql_start.sh"
echo "访问方式: 示例：mysql -uadmin -p${passwd}  -h127.0.0.1  -P${port}"
echo "数据目录: ${data_path}/${package_file}"
echo "错误日志目录: ${errorlog}"
echo "集群节点为 ${proxysql_servers}"
echo "######################"
