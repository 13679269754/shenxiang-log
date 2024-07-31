#!/bin/bash

init_type=$1

script_dir=/usr/local/percona/script
conf_dir=/usr/local/percona/config
other_exporter=/usr/local/percona/other_exporter
mkdir -p $script_dir
mkdir -p $conf_dir
mkdir -p $other_exporter

if [ ! -f "$conf_dir/cluster_config" ]; then
    echo "#CLUSTER_NAME=" > $conf_dir/cluster_config
fi

if [ ! -f "$conf_dir/.db_config" ]; then
    echo "#TYPE USER PASSWD PORT" > $conf_dir/.db_config
fi

function show_help(){
    echo "Usage: $0 [help|-h]"
    echo "example: "
    echo "init mysql service :   $0 mysql "
    echo "init Redis service :   $0 redis "
    echo "init All config service :   $0 all"
    echo ""
    exit 0
}

if [ "$init_type" = "help" ] || [ "$init_type" = "-h" ]; then
    echo "" 
    echo ""
    show_help
fi

if [ "$init_type" = "" ]; then
    echo "" 
    echo "目录已初始化,请查看 /usr/local/percona/"
    echo "" 
    echo ""
    show_help
fi

#pmm client installation
server_address=172.29.28.193
server_username=admin
server_passwd=123456
server_port=443
pass_config_file=$conf_dir/.db_config
cluster_config_file=$conf_dir/cluster_config
source $cluster_config_file


cluster_name='DZJ-'$CLUSTER_NAME
if [ "$cluster_name" = "DZJ-" ]; then
    cluster_cmd=''
else
    cluster_cmd='--cluster='$cluster_name
fi

env_name='DZJ-'$CLUSTER_NAME
if [ "$env_name" = "DZJ-" ]; then
    env_cmd=''
else
    env_cmd=$env_name'-'
fi

all_service="agent mysql elasticsearch influxdb redis neo4j mongodb postgresql proxysql"
pmm_init_service="mysql mongodb postgresql proxysql"

host_address=`ip a | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`

function check_port() {
    local port=$1
    while true; do
        if ! ss -tln | grep -q ":$port"; then
            break
        else
            port=$((port+1))
        fi
    done
    echo $port
}


function init_client(){ 
    rpm -ivh pmm2-client-2.36.0-6.el7.x86_64.rpm
     
    # Set up agent
    pmm-agent setup --config-file=/usr/local/percona/pmm2/config/pmm-agent.yaml --server-address=$server_address --server-insecure-tls --server-username=$server_username --server-password=$server_passwd
    
    # start agent
    pmm-agent --config-file=/usr/local/percona/pmm2/config/pmm-agent.yaml
    
    # Register client node
    pmm-admin config --server-insecure-tls --server-url=https://$server_username:$server_passwd@$server_address:$server_port $host_address generic node-$host_address
}


# Add service
function init_pmm_service(){
    local type=$1
    local user=$2
    local passwd=$3
    local port=$4
    local service_name=''
   
    if [ $type = "mysql" ]; then
        local service_name="MySQL-$host_address-$port"
        pmm-admin add mysql --query-source=perfschema --username=$user --password=$passwd --service-name=$service_name --host=127.0.0.1 --port=$port $cluster_cmd --environment="$env_cmd"MySQL
    fi
    
    if [ $type = "proxysql" ]; then
        local service_name="ProxySQL-$host_address-$port"
        pmm-admin add proxysql --username=$user --password=$passwd --service-name=$service_name --host=127.0.0.1 --port=$port $cluster_cmd --environment="$env_cmd"ProxySQL
    fi

    if [ $type = "mongodb" ]; then
        local service_name="MongoDB-$host_address-$port"
        pmm-admin add mongodb --username=$user --password=$passwd --service-name=$service_name --host=127.0.0.1 --port=$port --query-source=profiler $cluster_cmd --environment="$env_cmd"MongoDB
    fi

    if [ $type = "postgresql" ]; then
        local service_name="PgSQL-$host_address-$port"
        pmm-admin add postgresql --username=$user --password=$passwd --service-name=$service_name --host=127.0.0.1 --port=$port $cluster_cmd --environment="$env_cmd"PgSQL
    fi

    if [ $? -eq 0 ]; then
        echo "添加 $type exporter 服务成功, Service name: $service_name"  
    else    
        echo "添加 $type exporter 服务失败"
    fi
}


function init_es_service(){
    local port=$4
    local line_num=$5
    local info_count=$6
    local service_name="ES-$host_address-$port"
    
    local exporter_port=$(check_port 53001)
    echo "$exporter_port"
    echo "$type exporter 可用端口号为: $exporter_port"

    if [ ! -f $other_exporter/es_exporter/elasticsearch_exporter ]; then 
        echo $other_exporter/es_exporter
        mkdir -p $other_exporter/es_exporter
        tar -zxvf elasticsearch_exporter-1.5.0.linux-amd64.tar.gz -C $other_exporter/es_exporter --strip-components=1
    fi

    if [ $info_count -eq 4 ];then
        sed -i "${line_num}s/$/ $exporter_port/" $pass_config_file
    fi 

    if [ $info_count -eq 5 ];then
        sed -i -E ${line_num}'s/^(\S+\s+\S+\s+\S+\s+\S+\s+)([[:graph:]]+)/\1'"$exporter_port"'/' $pass_config_file
        echo
    fi 

    $script_dir/pmm_client.sh start $type
    sleep 8
    pmm-admin add external --service-name=$service_name --listen-port=$exporter_port --metrics-path=/metrics $cluster_cmd --environment="$env_cmd"ElasticSearch --custom-labels=node_type=ElasticSearch

    if [ $? -eq 0 ]; then
        echo "添加 ElasticSearch exporter 服务成功, exporter端口号：$exporter_port , ElasticSearch 端口号: local port=$port , Service name: $service_name" 
    else    
        echo "添加 ElasticSearch exporter 服务失败"
        $script_dir/pmm_client.sh stop $type
        sed -i -E ${line_num}'s/^(\S+\s+\S+\s+\S+\s+\S+\s+)([[:graph:]]+)/\1'""'/' $pass_config_file
    fi

    
}

function init_redis_service(){
    local port=$4
    local line_num=$5
    local info_count=$6
    local service_name="Redis-$host_address-$port"

    local exporter_port=$(check_port 53101)
    echo "$exporter_port"
    echo "$type exporter 可用端口号为: $exporter_port"
    
    if [ ! -f $other_exporter/redis_exporter/redis_exporter ]; then 
        mkdir -p $other_exporter/redis_exporter
        tar -zxvf redis_exporter-v1.50.0.linux-amd64.tar.gz -C $other_exporter/redis_exporter --strip-components=1
    fi 
    
    if [ $info_count -eq 4 ];then
        sed -i "${line_num}s/$/ $exporter_port/" $pass_config_file
    fi 

    if [ $info_count -eq 5 ];then
        sed -i -E ${line_num}'s/^(\S+\s+\S+\s+\S+\s+\S+\s+)([[:graph:]]+)/\1'"$exporter_port"'/' $pass_config_file
    fi 
   
    $script_dir/pmm_client.sh start $type
    sleep 8

    
    pmm-admin add external --service-name=$service_name --listen-port=$exporter_port --metrics-path=/metrics $cluster_cmd --environment="$env_cmd"Redis  --custom-labels=node_type=Redis
    if [ $? -eq 0 ]; then
        echo "添加 Redis exporter 服务成功, exporter端口号：$exporter_port , Redis 端口号: local port=$port , Service name: $service_name"  
    else    
        echo "添加 Redis exporter 服务失败"
        $script_dir/pmm_client.sh stop $type
        sed -i -E ${line_num}'s/^(\S+\s+\S+\s+\S+\s+\S+\s+)([[:graph:]]+)/\1'""'/' $pass_config_file
    fi

    
}

function init_influxdb_service(){
    local port=$4
    local line_num=$5
    local info_count=$6
    local service_name="InfluxDB-$host_address-$port"

    local exporter_port=$(check_port 53201)
    echo "$exporter_port"
    echo "$type exporter 可用端口号为: $exporter_port"
    
    if [ ! -f $other_exporter/es_exporter/elasticsearch_exporter ]; then 
        mkdir -p $other_exporter/influxdb_exporter
        tar -zxvf influxdb_exporter-0.11.4.linux-amd64.tar.gz -C $other_exporter/influxdb_exporter --strip-components=1
        
    fi 

    if [ $info_count -eq 4 ];then
        sed -i "${line_num}s/$/ $exporter_port/" $pass_config_file
    fi 

    if [ $info_count -eq 5 ];then
        sed -i -E ${line_num}'s/^(\S+\s+\S+\s+\S+\s+\S+\s+)([[:graph:]]+)/\1'"$exporter_port"'/' $pass_config_file
    fi 
    
    $script_dir/pmm_client.sh start $type
    sleep 8
    pmm-admin add external --service-name=$service_name --listen-port=$exporter_port --metrics-path=/metrics $cluster_cmd --environment="$env_cmd"Influxdb  --custom-labels=node_type=Influxdb
    if [ $? -eq 0 ]; then
        echo "添加 Influxdb exporter 服务成功, exporter端口号：$exporter_port , Influxdb 端口号: local port=$port , Service name: $service_name"  
    else    
        echo "添加 Influxdb exporter 服务失败"
        $script_dir/pmm_client.sh stop $type
        sed -i -E ${line_num}'s/^(\S+\s+\S+\s+\S+\s+\S+\s+)([[:graph:]]+)/\1'""'/' $pass_config_file
    fi

}

function init_neo4j_service(){
    local port=$4
    local line_num=$5
    local info_count=$6
    local service_name="Neo4j-$host_address-$port"

    local exporter_port=$(check_port 53301)
    echo "$exporter_port"
    echo "$type exporter 可用端口号为: $exporter_port"

    if [ $info_count -eq 4 ];then
        sed -i "${line_num}s/$/ $exporter_port/" $pass_config_file
    fi 

    if [ $info_count -eq 5 ];then
        sed -i -E ${line_num}'s/^(\S+\s+\S+\s+\S+\s+\S+\s+)([[:graph:]]+)/\1'"$exporter_port"'/' $pass_config_file
    fi 
    
    $script_dir/pmm_client.sh start $type
    sleep 8
    pmm-admin add external --service-name=$service_name --listen-port=$exporter_port --metrics-path=/metrics $cluster_cmd --environment="$env_cmd"Neo4j  --custom-labels=node_type=Neo4j

    if [ $? -eq 0 ]; then
        echo "添加 Neo4j exporter 服务成功, exporter端口号：$exporter_port , Neo4j 端口号: local port=$port , Service name: $service_name"  
    else    
        echo "添加 Neo4j exporter 服务失败"
        sed -i -E ${line_num}'s/^(\S+\s+\S+\s+\S+\s+\S+\s+)([[:graph:]]+)/\1'""'/' $pass_config_file
    fi

}

if [ "$init_type" = "all" ] || echo "${all_service[@]}" | grep -q "$init_type"; then

    if [ "$init_type" = "all" ] || [ $init_type = "agent" ]; then
        init_client
    fi 
    
    line_num=0
    cat $pass_config_file | grep -v '#' | while read line; do 
        info=($line)
        type=${info[0]}
        user=${info[1]}
        passwd=${info[2]}
        port=${info[3]}
        line_num=$((line_num+1))
        echo $line_num
        info_count=${#info[*]}

        if [ "$init_type" = "all" ] || [ "$type" = "$init_type" ]; then
            echo "$type 检验通过，开始添加服务"

            if [ $info_count -eq 5 ];then
                break
            fi 

            if echo "${pmm_init_service[@]}" | grep -q "$type"; then
                init_pmm_service $type $user $passwd $port $line_num $info_count
            else
                if [ $type = "elasticsearch" ]; then
                    init_es_service $type $user $passwd $port $line_num $info_count
                fi
    
                if [ $type = "influxdb" ]; then
                    init_influxdb_service $type $user $passwd $port $line_num $info_count
                fi
    
                if [ $type = "redis" ]; then
                    init_redis_service $type $user $passwd $port $line_num $info_count
                fi
    
                if [ $type = "neo4j" ]; then
                    init_neo4j_service $type $user $passwd $port $line_num $info_count
                fi
            fi
        fi
    done
    
    # copy script
    cp pmm_client.sh $script_dir/

else
    echo "$init_type not exists in the all_service"
    exit 1
fi
