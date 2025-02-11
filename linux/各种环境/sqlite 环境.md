[Centos7 上的sqlite3安装及升级_sqlite升级-CSDN博客](https://blog.csdn.net/ldq_sd/article/details/131323947) 

  

Centos7 上的sqlite3安装及升级
======================


**一.wget升级**

> **yum install -y wget**

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-13%2014-04-36/aa8f4040-7f4d-4539-8e92-3b0e76989ae1.png?raw=true)

**二.sqlite3安装**

> **sudo yum install sqlite-devel**

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-13%2014-04-36/b2a5356f-3970-4a1c-bc6e-5b6f9e75d14f.png?raw=true)

查看[sqlite3](https://so.csdn.net/so/search?q=sqlite3&spm=1001.2101.3001.7020)的版本

> **sqlite3 -version**

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-13%2014-04-36/3db5c449-148d-4889-a6b8-c651a08f73b2.png?raw=true)

**三.sqlite3升级**

**下载源码**

> **wget** https://www.sqlite.org/2023/sqlite-autoconf-3420000.tar.gz

> 版本可去官网选择

 [SQLite Download Page](https://www.sqlite.org/download.html "SQLite Download Page")

解压、编译

> **tar zxvf sqlite-autoconf-3420000.tar.gz**  
> **cd sqlite-autoconf-3420000/**  
> **./configure --prefix=/usr/local**  
> **make && make install**

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-13%2014-04-36/7b7ed56b-48ea-41fa-aa25-f20af44d4fdc.png?raw=true)

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-13%2014-04-36/a7bb9fe3-76be-4bda-99a3-c642ef8f69d4.png?raw=true)

删除旧版，替换新版

> **mv /usr/bin/sqlite3 /usr/bin/sqlite3\_old**  
> **ln -s /usr/local/bin/sqlite3 /usr/bin/sqlite3**  
> **echo "/usr/local/lib" > /etc/ld.so.conf.d/sqlite3.conf**  
> **ldconfig**

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-13%2014-04-36/1aa5932c-79e7-4b0e-9acf-39df9854a536.png?raw=true)

最后查看新的版本号

> **sqlite3 -version**

至此sqlite3就安装升级完成了。
