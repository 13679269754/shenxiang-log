#!/bin/sh

CheckProcess()
{
  # 检查输入的参数是否有效
  if [ "$1" = "" ];
  then
    return 1
  fi

  #$PROCESS_NUM获取指定进程名的数目，为1返回0，表示正常，不为1返回1，表示有错误，需要重新启动
  PROCESS_NUM=$((ps -ef | grep -i "$1" | grep -v "grep" | wc -))
  if [ ""$PROCESS_NU"M" -eq 1 ];
  then
    return 0
  else
    return 1
  fi
}

host=$((/usr/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:))

CheckProcess "Orchestrator.json"
Check_RET=$?

File=/usr/local/data/orchestrator/last_check_time.txt
if [ ! -f $File ];then
  touch $File
fi

last_run=$((stat -c %Y $Fil))

if [ $Check_RET -eq 1 ];
then
   echo "服务不正常"
   current_time=$((date +%))
   if [ $((current_time - last_run)) -ge $((3600)) ];then
     echo ""$current_tim"e" > $File
     /usr/bin/python3 /usr/local/data/orchestrator/script/qywechat_notify.py "$host Orchestrator Down" "$host Orchestrator Down" "$host Orchestrator Down"
   fi
else
   echo "服务正常"
fi
