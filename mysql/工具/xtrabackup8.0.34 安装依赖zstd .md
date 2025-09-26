| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-5月-19 | 2025-5月-19  |
| ... | ... | ... |
---
# xtrabackup8.0.34 安装依赖zstd 

[toc]

## 说明

本文为工作中遇到问题花费了一点时间做一点整理  
发生 mysql8.0.23 升级到8.0.34，原来的xtrabackup 8.0.23 备份失败。  
升级xtrabackup 8.0.23 提示依赖zstd。  
未找到centos 7 相关的zstd rpm包  
发现了一个有趣的工具rpmbuild  

## 环境

系统： centos 7
MYSQL： 8.0.34
xtrabackup: 8.0.34

## 问题解决

编译安装zstd

```bash
# 下载
wget https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz 
# 解压
mkdir -p /usr/local/data/tools/
tar -zxvf zstd-1.5.7.tar.gz  -C  /usr/local/data/tools/
# 编译安装
cd /usr/local/data/tools/zstd-1.5.7&&make&&make install 
# 建立软连接
ln -s /usr/local/data/tools/zstd-1.5.7/lib/libzstd.so.1 /usr/lib64/libzstd.so.1
```

## xtrabackup 升级
[downloads](https://www.percona.com/downloads)
```bash
rpm -e percona-xtrabackup-80-8.0.23-16.1.el7.x86_64
rpm -ivh --nodeps percona-xtrabackup-80-8.0.34-29.1.el7.x86_64.rpm
```