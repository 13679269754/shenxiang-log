| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2023-12月-18 | 2023-12月-18  |
| ... | ... | ... |
---
# python3.9安装


[Linux下(CentOS7)下载并安装Python 3.9教程_linux下安装python3.9-CSDN博客](https://blog.csdn.net/qq_28770757/article/details/109684720) 


思路：

*   查看是否安装
*   安装到常用路径下（Linux软件安装通常安装在/usr/local目录下）
*   下载python对应的依赖（能避免很多问题，暂不清除缘由）
*   下载安装包
*   解压到对应路径并安装
*   添加软链接(类似于window电脑的快捷方式)

CentOS7安装Python
---------------

### 1\. 查看当前python版本

CentOS7默认安装的是python2.7.5，直接安装python3不冲突

```bash
[root@centos-moxc ~]
Python 2.7.5 (default, Apr  2 2020, 13:16:51) 
[GCC 4.8.5 20150623 (Red Hat 4.8.5-39)] on linux2
Type "help", "copyright", "credits" or "license" for more information.

>>>

```

### 2.打开/usr/local目录

在Linux系统下，路径/usr/local相当于C:/Progrem Files/，通常安装软件时便安装到此目录下。


`cd /usr/local`

### 3.下载依赖

首选前者

```
 yum install  gcc libffi-devel zlib* openssl-devel

yum install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make libffi-devel

```

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2011-19-51/4a1828c9-2950-4017-8190-35e313850a4a.png?raw=true)
  
这里会提示安装需要的大小，询问是否同意，输入 y 即可  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2011-19-51/1c39971c-0403-41e5-8926-ff84b9a7d98e.png?raw=true)

### 4.下载安装包

> 说明，没有安装wegt的需要先安装  
> yum install wegt

```
wget https://www.python.org/ftp/python/3.9.0/Python-3.9.0.tgz

wget http://npm.taobao.org/mirrors/python/3.9.0/Python-3.9.0.tgz


```

### 5.解压安装

```
tar -zxvf Python-3.9.0.tgz  


cd Python-3.9.0

./configure prefix=/usr/local/python3

1.(建议)使用 altinstall 而不是 install，是为了避免覆盖系统默认的 python 命令（通常指向 Python 2.x）
sudo make altinstall

2.（不建议）make && make install

```

**安装成功后/usr/local/目录下多一个python3文件夹**  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2011-19-51/f5e1b129-62d5-45eb-a4a9-6d8bbdfe17aa.png?raw=true)

### 6.添加软连接

```bash 
[root@centos-moxc bin]# ln -s /usr/local/python3/bin/python3.9 /usr/bin/python3
[root@centos-moxc bin]# ln -s /usr/local/python3/bin/pip3.9 /usr/bin/pip3
[root@centos-moxc bin]# python3 -V
Python 3.9.0
[root@centos-moxc bin]# pip3 -V
pip 20.2.3 from /usr/local/python3/lib/python3.9/site-packages/pip (python 3.9)

[root@centos-moxc bin]
-rwxr-xr-x  1 root root      11240 Apr  2  2020 abrt-action-analyze-python
lrwxrwxrwx  1 root root         29 Nov 14 01:04 pip3 -> /usr/local/python3/bin/pip3.9
lrwxrwxrwx  1 root root          7 Sep  3 11:48 python -> python2
lrwxrwxrwx  1 root root          9 Sep  3 11:48 python2 -> python2.7
-rwxr-xr-x  1 root root       7144 Apr  2  2020 python2.7
lrwxrwxrwx  1 root root         32 Nov 14 01:04 python3 -> /usr/local/python3/bin/python3.9
[root@centos-moxc bin]
-rwxr-xr-x. 1 root root       2291 Jul 31  2015 lesspipe.sh
lrwxrwxrwx  1 root root         29 Nov 14 01:04 pip3 -> /usr/local/python3/bin/pip3.9

```

> 【**拓展**】  
> **软连接**：相当于windows的**快捷方式**，通常我们[安装软件](https://so.csdn.net/so/search?q=%E5%AE%89%E8%A3%85%E8%BD%AF%E4%BB%B6&spm=1001.2101.3001.7020)后都会在桌面添加一个快捷图片，方便我们快速的操作软件。  
> CentOS7默认python2.7-----软连接对应是python和python2.7  
> CentOS7新安装python3.9\-----软连接命名为python3

> 可以看到一个路径是可以有多个软连接(快捷方式)，深入一点，软连接指向是可以改变的。如果想可以让python指向python3.9，则先删除python软连接，再重新指向python3即可。（但是不建议删除系统默认的指向，可以修改其他新添加的）  

查看软连接指向：  
```bash
[root@centos-moxc mysql]# ll /usr/bin/ |grep python
```

> **将python软连接重新指向回python2.7**  
```bash
[root@centos-moxc mysql]# rm -rf /usr/bin/python  
[root@centos-moxc mysql]# ln -s /usr/bin/python2.7 /usr/bin/python
```

### 7.更改yum配置（非必须）

因为其要用到python2才能执行，否则会导致yum不能正常使用（不管安装 python3的那个版本，都必须要做的）
```bash
vi /usr/bin/yum  
把 #! /usr/bin/python 修改为 #! /usr/bin/python2  
vi /usr/libexec/urlgrabber-ext-down  
把 #! /usr/bin/python 修改为 #! /usr/bin/python2  
vi /usr/bin/yum-config-manager  
#!/usr/bin/python 改为 #!/usr/bin/python2
```


yum源问题：https://www.cnblogs.com/ryanzheng/p/11263388.html