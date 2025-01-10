# python虚拟环境安装

不同项目之间可能使用到的库之间的版本不相同，比如项目一需要用到redis2.0这个版本，而项目二需要用redis2.3这个版本，但是如果我们都在python根目录下载，一次只能存在一个版本，如果需要其他版本每次都需要卸载重下，这个时候就可以用到虚拟环境。  我们可以为每个项目都创建一个虚拟环境，各个虚拟环境之间相互不干扰，需要什么库可以直接下载。
## 安装虚拟环境
`pip install   virtualenv `
环境管理工具
```bash
pip install virtualenvwrapper
export WORKON_HOME=/root/python3_env 
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3  
export VIRTUALENVWRAPPER_VIRTUALENV=/usr/local/python3.8/bin/virtualenv 
source /usr/local/python3/bin/virtualenvwrapper.sh  # 不一定是该路径 可以找一下pip 安装在哪里
pip不存在时：
wget https://bootstrap.pypa.io/get-pip.py 
wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
python get-pip.py
# or
yum install python3-pip -y
```

## virtualenv使用
创建虚拟环境
`virtualenv 环境名 `

如果有多个python脚本，可以通过下面命令来创建虚拟环境
`virtualenv -p [python路径] 环境名 `
进入环境下的Scripts文件夹
输入命令
`activate `
安装自己想要的包并退出
比如要安装django2.0版本可以
`pip install django==2.0 `
退出虚拟环境
`deactivate `
管理虚拟环境
虚拟环境可以通过一些工具来管理，这里使用virtualenvwrapper，输入下面命令下载virtualenvwrapper
`pip install virtualenvwrapper-win(windows版) `

创建虚拟环境
输入命令
`mkvirtualenv 环境名` 
与直接用virtualenv创建虚拟环境不同的是，那个是在当前文件夹下创建虚拟环境，而这个是统一在当前用户的envs文件夹下（C:\user\envs）创建，并且会自动进入到该虚拟环境下  如果不想在默认地方创建，可以新建一个环境变量：WORKON_HOME，然后里面设置默认路径，如果要指定python版本，输入
`mkvirtualenv --python=python路径(到exe文件) 环境名`

## 错误提示

```bash
[root@localhost percona]# mkvirtualenv --python=/usr/local/python3  pmm_manager
which: no virtualenv in (/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin)
ERROR: virtualenvwrapper could not find virtualenv in your path

```
错误原因`virtualenv` 没有直接加入到PATH中，
```bash 
ll /usr/local/python3/bin/virtualenv 
ln /usr/local/python3/bin/virtualenv /usr/bin/virtualenv
```


进入虚拟环境
**输入命令**：`workon 环境名`
退出虚拟环境
**输入命令**：`deactivate`
删除虚拟环境
**输入命令**：`rmvirtualenv 环境名`

列出虚拟环境
**输入命令**：：`lsvirtualenv`
进入虚拟环境目录
**输入命令**：`cdvirtualenv 环境名`