#!/bin/bash

#pmm client install

script_dir=/usr/local/percona/script
conf_dir=/usr/local/percona/config
other_exporter=/usr/local/percona/other_exporter
mkdir -p $script_dir
mkdir -p $conf_dir
mkdir -p $other_exporter/log

operation_type=$1
service_type=$2

function show_help(){
    echo "Usage: $0 [help|-h]"
    echo "example: "
    echo "start pmm-agent service :   $0 start agent "
    echo "start Redis service :   $0 start redis "
    echo "start All service : $0 start "
    echo ""
    exit 0
}

if [ "$operation_type" = "help" ] || [ "$operation_type" = "-h" ]; then
    echo $operation_type
    echo "" 
    echo ""
    show_help
fi

pass_config_file=$conf_dir/.db_config
host_address=`ip a | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
cur_date=`date +%Y%m%d_%H_%M_%S`

all_service="agent elasticsearch redis neo4j"
operation="start stop restart status"

if ! echo "${operation[@]}" | grep -q "$operation_type"; then
    echo "$operation_type not exists in the operation"
    echo "operation is $operation"
    exit 1
fi



function pmm_agent_start(){
    systemctl start pmm-agent.service
}

function pmm_agent_stop(){
    systemctl start pmm-agent.service
}

function pmm_agent_restart(){
    systemctl restart pmm-agent.service
}

function pmm_agent_status(){
    systemctl status pmm-agent.service
    pmm-admin list
}

function es_service_status(){
    local type=$1
    local process_count=`ps -ef | grep elasticsearch_exporter | grep -v "grep"| wc -l`
    if [ $process_count -gt 0 ]; then
        echo "$type exporter 服务进程数为: $process_count"  
    else    
        echo "$type exporter 服务未启动"
    fi
}

function es_service_start(){
    local type=$1
    local user=$2
    local passwd=$3
    local port=$4
    local exporter_port=$5

    /usr/bin/nohup $other_exporter/es_exporter/elasticsearch_exporter\
            --es.all \
            --es.indices \
            --es.cluster_settings \
            --es.indices_settings \
            --es.indices_mappings \
            --es.shards \
            --es.snapshots \
            --es.timeout=10s \
            --es.ssl-skip-verify	\
            --web.listen-address=:$exporter_port \
            --web.telemetry-path=/metrics \
            --es.uri https://$user:$passwd@127.0.0.1:$port >> $other_exporter/log/elasticsearch_exporter_$port.log 2>&1 &
    
    if [ $? -eq 0 ]; then
        sleep 2
        es_service_status $type
    else    
        echo "$type exporter 服务启动失败"
    fi
}

function es_service_stop(){
    local type=$1
    killall elasticsearch_exporter
    if [ $? -eq 0 ]; then
        echo "$type exporter 服务关闭成功"  
    else    
        echo "$type exporter 服务关闭失败"
    fi
}

function es_service_restart(){
    local type=$1
    local user=$2
    local passwd=$3
    local port=$4
    local exporter_port=$5

    es_service_stop $type
    es_service_start $type $user $passwd $port $exporter_port
}



function redis_service_status(){
    local type=$1
    local process_count=`ps -ef | grep redis_exporter | grep -v "grep" | wc -l`
    if [ $process_count -gt 0 ]; then
        echo "$type exporter 服务进程数为: $process_count"  
    else    
        echo "$type exporter 服务未启动"
    fi
}

function redis_service_start(){
    local type=$1
    local user=$2
    local passwd=$3
    local port=$4
    local exporter_port=$5

    /usr/bin/nohup $other_exporter/redis_exporter/redis_exporter\
                -redis.addr 127.0.0.1:$port  \
                -redis.user $user \
                -redis.password $passwd \
                -web.listen-address 127.0.0.1:$exporter_port >> $other_exporter/log/redis_exporter_$port.log 2>&1 &

    if [ $? -eq 0 ]; then
        sleep 2
        redis_service_status $type 
    else    
        echo "$type exporter 服务启动失败"
    fi
}

function redis_service_stop(){
    local type=$1
    killall redis_exporter
    if [ $? -eq 0 ]; then
        echo "$type exporter 服务关闭成功"  
    else    
        echo "$type exporter 服务关闭失败"
    fi
}

function redis_service_restart(){
    local type=$1
    local user=$2
    local passwd=$3
    local port=$4
    local exporter_port=$5

    redis_service_stop $type
    redis_service_start $type $user $passwd $port $exporter_port
}


function influxdb_service_status(){
    local type=$1
    local process_count=`ps -ef | grep influxdb_exporter | grep -v "grep" | wc -l`
    if [ $process_count -gt 0 ]; then
        echo "$type exporter 服务进程数为: $process_count"  
    else    
        echo "$type exporter 服务未启动"
    fi
}

function influxdb_service_start(){
    local type=$1
    local user=$2
    local passwd=$3
    local port=$4
    local exporter_port=$5


    /usr/bin/nohup $other_exporter/influxdb_exporter/influxdb_exporter\

                --web.listen-address :$exporter_port >> $other_exporter/log/influxdb_exporter_$port.log 2>&1 &

    if [ $? -eq 0 ]; then
        sleep 2
        influxdb_service_status $type
    else    
        echo "$type exporter 服务启动失败"
    fi

}


function influxdb_service_stop(){
    local type=$1
    killall influxdb_exporter
    if [ $? -eq 0 ]; then
        echo "$type exporter 服务关闭成功"  
    else    
        echo "$type exporter 服务关闭失败"
    fi
}

function influxdb_service_restart(){
    local type=$1
    local user=$2
    local passwd=$3
    local port=$4
    local exporter_port=$5

    influxdb_service_stop $type
    influxdb_service_start $type $user $passwd $port $exporter_port
}




if [ "$service_type"="" ] || echo "${all_service[@]}" | grep -q "$service_type"; then
    if [ "$service_type" = "" ] || [ $service_type = "agent" ]; then
        if [ "$operation_type" = "start" ]; then
            pmm_agent_start
        fi

        if [ "$operation_type" = "stop" ]; then
            pmm_agent_stop
        fi

        if [ "$operation_type" = "restart" ]; then
            pmm_agent_restart
        fi

        if [ "$operation_type" = "status" ]; then
            pmm_agent_status
        fi
    fi

    cat $pass_config_file | grep -v '#' | while read line; do 
        info=($line)
        type=${info[0]}
        user=${info[1]}
        passwd=${info[2]}
        port=${info[3]}
        exporter_port=${info[4]}
        info_count=${#info[*]}


        
        if [ "$service_type" = "" ] || [ "$type" = "$service_type" ]; then


            if [ $info_count -eq 4 ]; then 
                echo "$service_type $port not init"
                break
            fi 
    
            if [ "$type" = "redis" ]; then
                if [ "$operation_type" = "start" ]; then
                    redis_service_start $type $user $passwd $port $exporter_port $info_count
                fi
        
                if [ "$operation_type" = "stop" ]; then
                    redis_service_stop $type $user $passwd $port $exporter_port $info_count
                fi
        
                if [ "$operation_type" = "restart" ]; then
                    redis_service_restart $type $user $passwd $port $exporter_port $info_count
                fi
        
                if [ "$operation_type" = "status" ]; then
                    redis_service_status $type $user $passwd $port $exporter_port $info_count
                fi
            fi 

            if [ "$type" = "elasticsearch" ]; then
                if [ "$operation_type" = "start" ]; then
                    es_service_start $type $user $passwd $port $exporter_port $info_count
                fi
        
                if [ "$operation_type" = "stop" ]; then
                    es_service_stop $type $user $passwd $port $exporter_port $info_count
                fi
        
                if [ "$operation_type" = "restart" ]; then
                    es_service_restart $type $user $passwd $port $exporter_port $info_count
                fi
        
                if [ "$operation_type" = "status" ]; then
                    es_service_status $type $user $passwd $port $exporter_port $info_count
                fi
            fi 

            if [ "$type" = "influxdb" ]; then
                if [ $operation_type="start" ]; then
                    influxdb_service_start $type $user $passwd $port $exporter_port $info_count
                fi
        
                if [ $operation_type="stop" ]; then
                    influxdb_service_stop $type $user $passwd $port $exporter_port $info_count
                fi
        
                if [ $operation_type="restart" ]; then
                    influxdb_service_restart $type $user $passwd $port $exporter_port $info_count
                fi
        
                if [ $operation_type="status" ]; then
                    influxdb_service_status $type $user $passwd $port $exporter_port $info_count
                fi
            fi 
        fi
    done
else
    echo "$type not exists in the all_service"
    exit 1
fi