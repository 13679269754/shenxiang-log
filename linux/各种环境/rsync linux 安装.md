| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-1月-02 | 2025-1月-02  |
| ... | ... | ... |
---
# rsync linux 安装.md

[toc]


## rsync适用场景
可以用作大文件的远程传输，备份，同步等任务rsync与scp
一般而言，我们会选择使用rsync进行远程同步或拷贝。rsync和scp的区别在于：  
-> rsync只对差异文件做更新，可以做增量或全量备份；而scp只能做全量备份。简单说就是rsync只传修改了的部分，如果改动较小就不需要全部重传，所以rsync备份速度较快；默认情况下，rsync 通过比较文件的最后修改时间（mtime）和文件的大小（size）来确认哪些文件需要被同步过去。  
-> rsync是分块校验+传输，scp是整个文件传输。rsync比scp有优势的地方在于单个大文件的一小部分存在改动时，只需传输改动部分，无需重新传输整个文件。如果传输一个新的文件，理论上rsync没有优势；  
-> rsync不是加密传输，而scp是加密传输，使用时可以按需选择。  
-> rsync  支持保留原数据权限，属主等信息  
-> rsync支持断点续传  

## 三种模式
[rsync服务的三种模式测试_rsync shell 模式_RSQ博客的博客-CSDN博客](https://blog.csdn.net/Mr_rsq/article/details/79272189)  
[Rsync 数据同步工具应用指南 - 知乎⁤ (zhihu.com)](https://zhuanlan.zhihu.com/p/40022680)


## rsync daemon 和 本机模式

read only = no 配置文件中的这个配置可以开启rsync 的只读
### rsync daemon
```bash
cat >> /etc/rsyncd.conf << EOF
[test]log file = /var/log/rsync.log
path=/data/mysql_backup
uid = sync_user
gid = sync_user
secrets file = /etc/rsyncd.passwd

EOF
```

#### 创建用户

```bash
useradd sync_user
passwd sync_user
```

#### 配置密码
```bash
cat > /etc/rsyncd.passwd << EOF
sync_user:passwd
EOF
```

#### 创建目录

创建/etc/rsyncd.conf指定的目录，并赋权（修改属主）
```bash
mkdir /data/mysql_backup
chown sync_user. /data/mysql_backup -R
```

#### 启动后台进程
`rsync --daemon`

#### 加入开机自启动
```bash
[root@backup ~]# echo "/usr/bin/rsync --damon" >>/etc/rc.local

[root@backup ~]# tail -1 /etc/rc.local
/usr/bin/rsync --damon
```