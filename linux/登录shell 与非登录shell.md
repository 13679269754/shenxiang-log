| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-5月-07 | 2025-5月-07  |
| ... | ... | ... |
---
# 登录shell 与非登录shell.md

[toc]

## 问题发现

问题发现:  
我在shell脚本中调用ssh ，远程登录使用其他用户执行命令发现无法加载环境变量  
`sshpass -p "dzj123,./" ssh 172.29.29.105 sudo -u influxdb  /home/influxdb/start.sh`  
添加-E 也没法加载  
`sshpass -p "dzj123,./" ssh 172.29.29.105 sudo -E -u influxdb  /home/influxdb/start.sh`  
最后解决办法使用-l 强制使用登录shell方式  
`sshpass -p "dzj123,./" ssh 172.29.29.105 sudo -E -u influxdb bash -l -c '/home/influxdb/start.sh'`  

## 什么是登录shell 什么是非登录shell

登录 shell 和非登录 shell 是两种不同类型的 shell 会话，它们在启动方式和加载配置文件等方面存在差异

### 登录 shell

定义：用户通过输入用户名和密码进行登录后启动的 shell，或者使用 ssh 远程登录到系统时启动的 shell，都属于登录 shell。它通常用于用户首次登录系统时，用于初始化用户的环境。  
特点：登录 shell 会读取并执行一系列特定的配置文件，如 /etc/profile 以及用户主目录下的 `~/.bash_profile`、`~/.bash_login` 或`~/.profile`（根据系统和配置的不同，具体读取的文件可能会有所差异）。这些配置文件用于设置环境变量、定义别名、加载系统默认设置等，以便为用户提供一个合适的工作环境。  

### 非登录 shell

定义：在已经登录到系统的情况下，通过打开一个新的终端窗口、执行 bash 命令（**在已经是 shell 环境中再次启动一个新的 shell 进程**）或**在脚本中调用 shell 等方式启动的 shell** 为非登录 shell。  
特点：非登录 shell 不会读取登录 shell 所读取的那些配置文件，而是会读取 `~/.bashrc` 文件（对于 bash shell 而言）。这个文件通常用于设置一些本地的环境变量、别名和函数等，这些设置仅在当前的非登录 shell 会话中生效。  
了解登录 shell 和非登录 shell 的区别，有助于理解为什么在某些情况下环境变量或配置没有按照预期生效，也有助于正确地设置和管理用户的 shell 环境。