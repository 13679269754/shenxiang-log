| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-25 | 2024-10月-25  |
| ... | ... | ... |
---
# linux.md

[toc]

## 查看 cpu 信息

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

---

## 基础信息

[Linux系统查看CPU、机器型号、内存等信息](https://cloud.tencent.com/developer/article/1721406)