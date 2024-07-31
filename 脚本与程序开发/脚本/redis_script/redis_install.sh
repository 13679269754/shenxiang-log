#!/bin/bash

# Step 0
package='redis-5.0.3.tar.gz'
package_name=${package/'.tar.gz'/''}
redis_dir='/usr/local/redis'
source_dir=$PWD

if [ $# == 1 ] && [[ $1 =~ ^[0-9]*$ ]]
then
    redis_port=$1
else
    redis_port=40000
fi

randstr() {
  index=0
  str=""
  for i in {a..z}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {A..Z}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {0..9}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {1..20}; do str="$str${arr[$RANDOM%$index]}"; done
  passwd_str=$str
}

echo "====================================================================================="
echo ""
echo "Start Install Redis version 5.0.3" 
echo ""
echo "====================================================================================="
echo ""
echo ""
#step1 Install Yum Module
function install_module()
{   
    echo ""
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Install Yum Begining<<<<<<<<<<<<<<<<<<<<<<<<<"
    echo ""
    yum install tcl -y
}

#step3 Write Config
function write_config()
{   

    echo ""
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Write Config Begining<<<<<<<<<<<<<<<<<<<<<<<<"
    echo ""
    config1_count=$(cat /etc/rc.local | grep "/sys/kernel/mm/transparent_hugepage/enabled" | grep never | wc -l)
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
    if [ "$config1_count" == "0" ]; then
        echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local
    fi
	
    config2_count=$(cat /etc/rc.local | grep "/proc/sys/net/core/somaxconn" | grep 511 | wc -l)
    echo 511 > /proc/sys/net/core/somaxconn
    if [ "$config2_count" == "0" ];
    then
        echo "echo 511 > /proc/sys/net/core/somaxconn" >> /etc/rc.local
    fi
	
    config3_count=$(cat /etc/sysctl.conf | grep vm.overcommit_memory | wc -l)
    if [ "$config3_count" == "0" ];
    then
        echo "vm.overcommit_memory=1" >> /etc/sysctl.conf
    fi
	
    if [ `grep -c "redis" /etc/security/limits.conf` -eq 0 ]
    then
        echo "redis soft nproc  65535" >> /etc/security/limits.conf
        echo "redis hard nproc  65535" >> /etc/security/limits.conf
        echo "redis soft nofile 65535" >> /etc/security/limits.conf
        echo "redis hard nofile 65535" >> /etc/security/limits.conf
    fi
}

#step3 Create Group and User
function create_redis_group()
{   
    echo ""
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Create Group and User Begining<<<<<<<<<<<<<<<"
    echo ""
    group=$(more /etc/group | grep redis)
    if [ "$group" != "" ]; then
        echo "group already created!"
    else
        groupadd redis
    fi
    
    user=$(more /etc/passwd | grep redis)
    if [ "$user" != "" ]; then
        echo "user already created!"
    else
        useradd -g redis redis
    fi
}


#step4 Install Redis Software
function install_redis()
{
    echo ""
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Install Redis Software Begining<<<<<<<<<<<<<<"
    echo ""
    
    redis_cmd=$(whereis redis-server | grep / | wc -l)
    if [ "$redis_cmd" == "0" ];
    then
        if [ ! -d $redis_dir ]
        then
            mkdir -p $redis_dir
            chown -R redis. $redis_dir
        fi
        
        cp $source_dir/$package $redis_dir/
        cd $redis_dir/
        tar zxvf $package
        
        cd $package_name
        make 
        cd src/
        taskset -c 1 make test
        make install
    else
        echo "Redis Software Already Install!"
    fi
}

#step5 Create Directory
function create_dir()
{   

    echo ""
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Create Directory Begining<<<<<<<<<<<<<<<<<<<<"
    echo ""
    
    if [ -d $redis_dir/data/${redis_port} ]
    then
        echo
        echo "Error: Data Directory Is Exist...."
        echo "Error: Exit Install...."
        echo
        exit
    fi
    
    if [ ! -d $redis_dir/data ]
    then
        mkdir -p $redis_dir/data
        chown -R redis. $redis_dir/data
    fi
    
    if [ ! -d $redis_dir/data/${redis_port} ]
    then
        mkdir -p $redis_dir/data/${redis_port}/conf
        mkdir -p $redis_dir/data/${redis_port}/run
        mkdir -p $redis_dir/data/${redis_port}/log
        mkdir -p $redis_dir/data/${redis_port}/data
        chown -R redis. $redis_dir/data
    fi
    
	randstr
	
    cp $source_dir/redis.conf $redis_dir/data/${redis_port}/conf/
    cp $source_dir/master_instance.conf $redis_dir/data/${redis_port}/conf/
    
    sed -i "s/40000/${redis_port}/" $redis_dir/data/${redis_port}/conf/master_instance.conf
    sed -i "s/40000/${redis_port}/" $redis_dir/data/${redis_port}/conf/redis.conf
	echo "requirepass $passwd_str" >> $redis_dir/data/${redis_port}/conf/master_instance.conf
}

function start_redis()
{    
    echo ""
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Start Redis Begining<<<<<<<<<<<<<<<<<<<<<<<<<"
    echo ""
    redis-server $redis_dir/data/${redis_port}/conf/redis.conf
}

install_module
write_config
create_redis_group
install_redis
create_dir
start_redis

echo ""
echo "Install Complete........"