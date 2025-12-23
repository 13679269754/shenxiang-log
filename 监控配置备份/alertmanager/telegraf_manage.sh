#!/bin/bash

is_exist(){
pid=`ps -ef | grep telegraf | grep -v grep | awk '{print $2}'` # 如果不存在返回 1，存在返回 0
if [ -z "${pid}" ]; then return 1
else
return 0
fi
}

stop(){
is_exist
if [ $? -eq "0" ]; then kill ${pid}
if [ $? -eq "0" ]; then
echo "进程号:${pid},弄死你" else
echo "进程号:${pid},没弄死"
fi else
echo "本来没有 telegraf 进程"
fi
}

start(){
is_exist
if [ $? -eq "0" ]; then
echo "跑着呢，pid 是${pid}" else
export INFLUX_TOKEN=v4TsUzZWtqgot18kt_adS1r-
7PTsMIQkbnhEQ7oqLCP2TQ5Q-PcUP6RMyTHLy4IryP1_2rIamNarsNqDc_S_eA==
/opt/module/telegraf-1.23.4/usr/bin/telegraf --config http://localhost:8086/api/v2/telegrafs/09dcf4afcfd90000
fi
}

status(){
is_exist
if [ $? -eq "0" ]; then echo "telegraf 跑着呢"
else
echo "telegraf 没有跑"
fi
}

usage(){
echo "哦！请你 start 或 stop 或 status" exit 1
}

case "$1" in "start")
start
;;
"stop")
stop
;;
"status")
status
;;
*)
usage
;;
esac 最后