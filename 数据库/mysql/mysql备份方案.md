| operator | createtime  | updatetime  |
| -------- | ----------- | ----------- |
| shenx    | 2023-10月-18 | 2023-10月-18 |
| ... | ... | ... |
---
# mysql备份方案

[toc]

## mysqldump(逻辑导出)

单线程导出，恢复，导出文件为一个。不适合用于大数据量的恢复。

## mydumper(逻辑导出)

多线程，支持单表多线程的导出，导出多个文件，支持多文件多线程导入。

## xtrabackup

### xtrabackup 2.4 与 8.0 的区别

[xtrabackup-8.0的安装、备份以及恢复（innoxtrabackup有待测试）](https://blog.csdn.net/dwjriver/article/details/117792271)

[Peronca Xtrabackup 8.0近日踩坑总结 - xtrabackup 2.4和8.0区别](https://www.cnblogs.com/dbkernel/p/13571397.html)

## Netbackup(企业级)
