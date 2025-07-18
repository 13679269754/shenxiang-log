#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os.path

from config import *
import socket
from  components.ordinary import *

def TelnetPort(server_ip,port):
    sk = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sk.settimeout(1) #设置超时时间
    try:
        port = int(port)
        sk.connect((server_ip, int(port)))
    except Exception as e:
        raise Exception("rsync服务器,网络不可达,请检查网络")
    sk.close()
    return True


def PathCheck(path):
    return os.path.exists(path)


def UserCheck(user):
    return if_user_exists(user)


def CommandCheck(command):
    command = f"which {command}"
    result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if result.stdout.decode('utf-8').find(" no ") != -1:
        logger.error(f"{command}命令不存在")
        return False
    return True

def process_check(process):
    command = f"ps -ef | grep {process}"
    exe_shell_cmd(command)
    return True

def PortCheck(port):
    command = f"netstat -antulp | grep {port}"
    exe_shell_cmd(command)
    return True

def path_create():
    exe_shell_cmd(f"mkdir -p {log_path}/rsync_log")
    exe_shell_cmd(f"mkdir -p {log_path}/extend_server_exporter_log")
    exe_shell_cmd(f"mkdir -p {local_package_path}")

def env_check_pre():
    return TelnetPort(rsync_host, '873') & CommandCheck('rsync')


def install_rsync(passwd):
    with open(rsync_passwd_file,'w') as pass_f:
        pass_f.write(passwd)
    command = f"chmod 600 {rsync_passwd_file}"
    command = f"chmod 600 {rsync_passwd_file}"
    exe_shell_cmd(command)
    return True

def rsync_get_script(remote_rsync_host, remote_rsync_user, remote_rsync_pass, remote_rsync_module ,local_package_path):
    # 添加pass文件
    install_rsync(remote_rsync_pass)

    command = f"rsync -avzP --no-perms --password-file={rsync_passwd_file} {remote_rsync_user}@{remote_rsync_host}::{remote_rsync_module}  {local_package_path} > {log_path}/rsync_log/rsync_{date_time}.log"

    exe_shell_cmd(command)

def env_check_later():
    return PathCheck(local_package_path)

def path_init(path):
    os.mkdir(path)
    return True


def env_init():
    # 判断rsync是否可访问
    env_check_pre()
    # path create
    path_create()
    # 获取pmm-client,exporter等安装包
    rsync_get_script(rsync_host, rsync_user, rsync_pass, rsync_module, local_package_path)
    # 验证环境
    env_check_later()


def env_reinitialize():
    """清理所有注册的服务"""
    pass







