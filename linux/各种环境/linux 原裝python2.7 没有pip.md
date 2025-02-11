[linux的python2.7安装pip的三种方式，Linux（Centos）在装有Python2的情况下安装Python3 两版本并存，安装完python3后pip、pip2都指向了python3_linux python2.7安装pip-CSDN博客](https://blog.csdn.net/qq_42402648/article/details/112059939) 

 安装pip的三种方式
----------

pip是python的一个工具，用来安装python包特别方便。  
Linux系统是是内置python程序，因为许多Linux内置文件都是使用python来编写的，比如说yum。

### 1.脚本安装

推荐安装方式  
通过脚本的方式可以保证都能够安装到最新版本的pip，同时操作简单。


`curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py` 


`python get-pip.py` 


### 2.源码包安装

下载地址：https://pypi.org/search/?q=pip


`wget --no-check-certific ate https://pypi.python.org/packages/source/p/pip/pip-10.0.1.tar.gz >>/dev/null` 

`tar -zvxf pip-10.0.1.tar.gz >> /dev/null` 


`cd pip.10.0.1` 

`python3 setup.py build` 


`python3 setup.py install` 


注意，这里是安装到python3中，默认是安装到python所链接的具体版本中。

### 3.python安装

这种方式，直接通过python安装，与脚本安装类似，但是这个安装的是当前python版本所以依赖的pip，可能版本较低，因为内置python版本并不高。

`yum upgrade python-setuptools` 


`yum install python-pip` 


感兴趣的小伙伴可以看一下官方文档连接[https://pip.pypa.io/en/stable/installing/](https://pip.pypa.io/en/stable/installing/)

Linux安装pip
----------

脚本安装方式，如果直接用yum install 安装可能会遇到很多问题。官网的这个方法可以很快很安全的安装好pip。也就是上述的方式一  
官网地址：[https://pypi.org/project/pip/](https://pypi.org/project/pip/)  
1、打开[pip官网](https://pypi.org/project/pip/)后，点击“Installation”  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2014-15-54/477caa04-065e-4003-a0f0-2551a6028b62.png?raw=true)
  
2、进入Installation页面后，右键点击“get-pip.py”,选择“复制链接地址”  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2014-15-54/d8553d06-7f63-48e7-af38-1e54288db1fe.png?raw=true)
  
3、在Linux中输入 wget 粘帖复制的地址

4、下载完成后，执行命令python get-pip.py  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2014-15-54/a80e25d4-0614-474a-9d94-099f8ad648bb.png?raw=true)

Linux（Centos）在装有Python2的情况下安装Python3 两版本并存
------------------------------------------

Centos7自带python2.7版本，如果想要安装python3，要么卸载Linux自带的python(风险较大，浪费过一中午的时间)，再安装python3；要么在装有python2的基础上直接安装python3，让两版本并存【这部分就是详细展开说说…】

#### 1、查看Python2的位置

whereis python  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2014-15-54/2453ddd0-2da4-483e-837a-4503476d40fa.png?raw=true)
  
可知，python 在/usr/bin/中  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2014-15-54/6e2ccdef-d8ae-4957-942b-2acff2508941.png?raw=true)
  
从上面可以看出python和python2指向的都是python2。  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2014-15-54/145c2f28-0389-4496-a871-5cf368fa6bf7.png?raw=true)
  
执行python和python2都可以启动python2.7，所以后续安装python3后可以将python3软连接到python。

#### 2、安装编译python的相关包

`yum install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make -y` 



![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2014-15-54/bd0d0881-b846-46be-9bec-ad81a5a8fe5d.png?raw=true)

#### 3、下载要安装的python3版本

去官网选择自己想要的版本去下载，下载网址：[https://www.python.org/downloads/release/](https://www.python.org/downloads/release/)

* * *

小插曲：  
.tgz是.tar.gz 的简写形式

* * *

1.下载python3 （可以到官方先看最新版本多少，因为我windows上装的是3.7.8，所以我想在linux上也装3.7.8，大家可以根据自己的需求选择版本）

输入命令  
`wget https://www.python.org/ftp/python/3.7.8/Python-3.7.8.tgz`  
wget后面的地址根据自己的需求更换

2.安装Python3

我这里安装在/usr/bin/python3（具体安装位置看个人喜好）  
在/usr/bin/目录下创建python3目录  
（1）创建目录： mkdir python3

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2014-15-54/2cc4cf82-9ed8-43ca-8d1c-cccbe8434882.png?raw=true)
  
（2）输入命令 tar -zxvf Python-3.7.1.tgz 解压下载的python压缩文件  
（3）用mv 命令把解压过的python包移到/usr/bin/python3/目录下  
（4）进入解压后的目录，编译安装。  
4.1）（编译安装前需要安装编译器yum install gcc）安装gcc  
用`which gcc`命令查看是否安装了gcc，如果没有执行下面命令  
输入命令 `yum install gcc`，确认下载安装输入“y”  
![](https://i-blog.csdnimg.cn/blog_migrate/7798c848b7c39fc3ae11be9d4ba3ba20.png)
  
4.2）3.7版本之后需要一个新的包libffi-devel

安装即可：`yum install libffi-devel -y ` 
![](https://i-blog.csdnimg.cn/blog_migrate/63d2fec0cf78e79ee1a58fb281d24f4c.png)
  
4.3）进入python文件夹，生成编译脚本(指定安装目录)：

 `cd Python-3.7.8` 


进入Python-3.7.8文件下后，执行下面命令


`./configure --prefix=/usr/bin/python3` 


#/usr/bin/python3为上面步骤创建的目录 ，python3.7.8的安装路径。执行./configure命令，自动产生Makefile文件，不懂得[点这里](https://blog.csdn.net/qq_42402648/article/details/111769462)，可以在这篇文章里去了解  
4.4）编译：`make`  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2014-15-54/b24b669f-07c9-41cd-ba63-144a2cd1746d.png?raw=true)
  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2014-15-54/0fd0386c-cbac-40fe-ae79-ad0c012b7c9a.png?raw=true)
  
4.5）编译成功后，编译安装：make install  
![](https://i-blog.csdnimg.cn/blog_migrate/6b8717c33615e786f867b079d65e85ab.png)

安装成功：  
![](https://i-blog.csdnimg.cn/blog_migrate/b636f1a6be9e20daec86cf1c39362720.png)
  
4.6）检查python3.7的编译器：/usr/bin/python3/bin/python3.7![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2014-15-54/356e3f02-b806-4ee3-9e8f-d36ed67eeffa.png?raw=true)
  
3、添加软连接

（1）python软连接,这样以后输入python就会链接得python3版本，而不会去连接python2版本

将原来的python备份：  
`mv /usr/bin/python /usr/bin/python.bak`  
添加python3的软连接 ：  
`ln -s /usr/local/python37/bin/python3.7 /usr/bin/python`  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2014-15-54/b9686da3-17e0-4b0f-95c5-591913c89d62.png?raw=true)
  
![](https://i-blog.csdnimg.cn/blog_migrate/05868a31599e82dca664f01781fd5edd.png)
  
有时候我们装完python3后，上面我们将python3软连接到python上，之前pip、pip2、pip2.7全都指向了python3，原因如下：

```bash
**#vim /usr/bin/pip**
将第一行 #!/usr/bin/python 修改为#!/usr/bin/python2
然后pip 就指向python2了

**#vim /usr/bin/pip2**
将第一行 #!/usr/bin/python 修改为 #!/usr/bin/python2
然后pip2 就指向python2了

**#vim /usr/bin/pip2.7**
将第一行 #!/usr/bin/python 修改为#!/usr/bin/python2
然后pip2.7 就指向python2了
```

* * *

上面的操作有利于我们统一规划，统一管理，然后我们建立pip的软连接  
（2）pip软连接

此时查看pip版本pip -V 指向的还是python2  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2014-15-54/faeae9f8-e4bf-40f6-9e98-cadfd2e4a20c.png?raw=true)

因此pip也需要创建软连接

备份：mv /usr/bin/pip /usr/bin/pip.bak  
![](https://i-blog.csdnimg.cn/blog_migrate/b0032389c3902751d00ae12da5182916.png)

创建软连接：ln -s /usr/bin/python3/bin/pip3 /usr/bin/pip  
![](https://i-blog.csdnimg.cn/blog_migrate/c377e76d0fece28aa158933e9288d643.png)

* * *

4.并将/usr/bin/python3/bin加入PATH

（1）`vim /etc/profile` 到最后一行

（2）按“i”，然后贴上下面内容：

```bash
 `if [ -f ~/.bashrc ]; then

. ~/.bashrc

fi

PATH=$PATH:$HOME/bin:/usr/bin/python3/bin

export PATH` 

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-20%2014-15-54/9a2296d7-bc1c-44c2-8304-7f86b03fa3cf.png?raw=true)

```

（3）按ESC，输入:wq回车退出。

（4）修改完记得执行行下面的命令，让上一步的修改生效：

`source ~/.bash_profile` 


7.检查Python及pip是否正常可用，是否匹配python3：


`python -V` 


`pip -V` 

