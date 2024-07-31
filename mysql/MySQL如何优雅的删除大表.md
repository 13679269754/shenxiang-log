# MySQL如何优雅的删除大表

[toc]

# 前言

删除表，大家下意识想到的命令可能是直接使用`DROP TABLE "表名"`，这是初生牛犊的做法，因为当要删除的表达空间到几十G，甚至是几百G的表时候。这样一条命令下去，MySQL可能就直接夯住了，外在表现就是QPS急速下降，客户请求变慢。

## 解决办法

## 1.业务低峰时间手动执行删除

这个可能就需要DBA不辞辛劳，大晚上爬起来删表了。

## 2.先清除数据，最后再删除的方式

譬如1000万条数据，写脚本每次删除20万，睡眠一段时间，继续执行。这样也能做到对用户无感知。

## 3.对表文件（idb文件）做一个硬链接来加速删除

这个方法利用了linux下硬链接的知识，来进行快速删除，不记得话可以回去翻一下《鸟哥的linux私房菜》

```null
ln data_center_update_log.ibd data_center_update_log.ibd.hdlk

[root@mysql01 sports_center]# ll
总用量 19903792
-rw-r----- 1 mysql mysql       9076 10月 17 13:15 data_center_update_log.frm
-rw-r----- 2 mysql mysql 8447328256 12月 23 11:35 data_center_update_log.ibd
-rw-r----- 2 mysql mysql 8447328256 12月 23 11:35 data_center_update_log.ibd.hdlk
```

*   执行上面命令后，我们就多了一个data\_center\_update_log.ibd.hdlk文件。此操作实际上不会占用磁盘空间，只是增加了一次对磁盘上文件的引用。
*   当我们删除其中任何一个文件时，都不会影响磁盘上真实的文件，只是将其引用数目减去1。当被引用的数目变为1的时候，再去删除文件，才会真正做IO来删除它。
*   正是利用这个特点，将由原来mysql来删除大文件的操作，转换为一个简单的操作系统级的文件删除，从而减少了对mysql的影响。

## 4.登陆mysql，执行drop表操作

```null
很快，200万条数据只用了1秒完成，此操作是在创建硬链接后执行的
mysql> drop tables data_center_update_log;
Query OK, 0 rows affected (1.02 sec)


mysql> exit
Bye

退出来，再次查看数据目录，发现就只剩data_center_update_log.ibd.hdlk硬链接文件了
[root@mysql01 sports_center]# ll
总用量 19903792
-rw-r----- 2 mysql mysql 8447328256 12月 23 11:35 data_center_update_log.ibd.hdlk
```

## 5.如何正确删除`ibd.hdlk`硬链接文件呢

*   虽然`drop table`之后，剩下的硬链接文件已经和mysql没有关系了。但如果文件过大，直接用`rm`命令来删除，也是会造成IO开销飙升，CPU负载过高，进而影响到MySQL。
*   这里我们用到的方法，可以循环分块删除，慢慢地清理文件，通过一个脚本即可搞定
*   Truncate命令通常用于将文件缩小或扩展到指定的大小。如果文件大于指定的大小，则会丢失额外的数据。如果文件较短，则会对其进行扩展，并且扩展部分的读数为零字节。

### 5.1 安装`truncate`命令

```bash
[root@mysql01 ~]# cruncate
-bash: cruncate: 未找到命令
通常操作系统会安装truncate命令，该命令在coreutils安装包里面，如果没有安装可以使用下面命令安装

[root@mysql01 ~]  yum provides truncate
coreutils-8.22-24.el7.x86_64 : A set of basic GNU tools commonly used in shell scripts
源    ：base
匹配来源：
文件名    ：/usr/bin/truncate

可以看到truncate由coreutils安装包提供，下面安装coreutils安装包：

[root@mysql01 ~]# yum install -y coreutils


```

### 5.2 `truncate`常用选项

```null
-c, --no-create --> 不创建任何文件 
-o, --io-blocks --> 将大小视为存储块的数量，而不是字节 
-r, --reference=RFILE --> 参考指定的文件大小 
-s, --size=SIZE --> 按照指定的字节设置文件大小 

```

### 5.3 truncate_bigfile.sh脚本

*   原理：使用`truncate -s`选项可以指定文件大小，通过脚本指定每次文件减少的大小，并sleep睡眠一定时间，从而达到可控的删除文件
*   附：truncate_bigfile.sh脚本

```null
#! /bin/bash


TRUNCATE=/usr/bin/truncate
FILE=$1

if [ x"$1" = x ];then
	echo "Please input filename in"
	exit 1;
else
	SIZE_M=$(du -sm "$1" | awk '{print $1}')

	for i in $(seq "${SIZE_M}" -100 0)
	do
		sleep 1
		echo "${TRUNCATE} -s ${i}M ${FILE}"
		${TRUNCATE} -s "${i}"M "${FILE}"
	done
fi

if [  $? -eq 0 ];then
        \rm -f "${FILE}"
else
        echo "Please check file"
fi

```

