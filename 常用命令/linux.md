| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-25 | 2024-10月-25  |
| ... | ... | ... |
---
# linux.md

[toc]

## 查看 cpu 信息

```
linux 系统
查看物理 cpu 数：

cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l
查看每个物理 cpu 中 核心数(core 数)：

cat /proc/cpuinfo | grep "cpu cores" | uniq
查看总的逻辑 cpu 数（processor 数）：

cat /proc/cpuinfo| grep "processor"| wc -l
查看 cpu 型号：

cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c

判断 cpu 是否 64 位：
检查 cpuinfo 中的 flags 区段，看是否有 lm （long mode） 标识
```

---

## io信息
```
# 查看实时 I/O 消耗
iotop -oP

# 查看进程 I/O 统计
pidstat -d 1
```
## 基础信息

[Linux系统查看CPU、机器型号、内存等信息](https://cloud.tencent.com/developer/article/1721406)

## dstat

```bash
dstat -mclrstn --tcp | tee dstat.log
```

## rsync 

保留属主，属组，权限信息
```bash
rsync -avz -A /local/path/ user@192.168.1.100:/remote/path/
```
-a (--archive)：归档模式，保留大部分属性（权限、时间戳等）。  
-v (--verbose)：显示详细输出。  
-z (--compress)：压缩传输。  
-A (--acls)：保留 ACL 和扩展属性（等同于 --owner --group --perms）。  


## xargs

```bash
redis-cli -p 6600 -a HqGKZDcO6onuAigHtu -n 3 nokeys  RESEARCH:TEMPLATE:CONTENT* | xargs redis-cli -p 6600 -a HqGKZDcO6onuAigHtu -n 3 DEL
```


## fio

```bash
fio --name=randwrite --rw=randwrite --bs=4k --iodepth=64 --size=10G --runtime=300 \
    --ioengine=libaio --direct=1 --group_reporting
```