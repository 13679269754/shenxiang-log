#!/usr/bin/env python
# -*- coding:utf-8 -*-
import re
import subprocess
from threading import RLock
import os
import contextlib
import time

from cryptography.fernet import Fernet

from config import *

# ANSI 转义码
RED = '\033[91m'   # 红色
BLUE = '\033[94m'  # 蓝色
BOLD = '\033[1m'    # 加粗
END = '\033[0m'    # 恢复默认样式

def check_service_running(service_name):
    ''' 检查数据库服务是否正在运行 ，运行返回服务名，否则None'''
    try:
        # 使用 ps 命令查看进程信息
        result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)

        # 使用正则表达式匹配特定数据库服务名
        pattern = r'\b' + re.escape(service_name) + r'(?<!_exporter)\b'  # 匹配整个单词

        if re.search(pattern, result.stdout) :
            print(f"{BLUE}{service_name} 数据库服务正在运行。{END}")
            return service_name
    except Exception as e:
        raise f"检查数据库服务 - {service_name} - 运行状态时出现错误：{str(e)}"


def check_service_exporter_running(service_name):
    ''' 检查数据库服务是否正在运行 ，运行返回服务名，否则None'''
    try:
        # 使用 ps 命令查看进程信息
        result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)

        # 使用正则表达式匹配特定数据库服务名
        pattern = r'\b' + re.escape(service_name) + r'_exporter\b'  # 匹配整个单词

        if re.search(pattern, result.stdout) :
            print(f"{BLUE}{service_name} 数据库服务正在运行。{END}")
            return service_name
    except Exception as e:
        raise f"检查数据库服务 - {service_name} - 运行状态时出现错误：{str(e)}"


def server_discovery():
    running_service = []
    for service in service_list:
        if check_service_running(service):
            running_service.append(service)
    return running_service


def get_environment():
    """"获取提示文件.environment.txt中的提示内容"""
    environment_list=list()
    with open('.environment.txt', 'r') as file:
        content = file.read()

    # 查找[node-environment]下的内容
    environment_content = re.split('########\n\[.*\]', content)[1]

    # 将内容按行分割并排除空行和[...]行
    node_environment_lines = [line.strip() for line in environment_content.split('\n') if
                              line.strip() and not line.startswith('[')]

    # 输出结果
    print(f"{BLUE}当前environment：{END}")
    for i, line in enumerate(node_environment_lines):
        environment_list.append(line.strip())
        print(f"{i + 1}.{line}")
    return environment_list

def get_rename(rename_for=None):
    """"获取提示文件.environment.txt中的提示内容"""
    rename_list = list()
    with open('.environment.txt', 'r') as file:
        content = file.read()

    # 查找[rename-example]下的内容
    rename_list = re.split('########\n\[.*\]', content)[2]

    if rename_for is not None:
        print (f"{BLUE}当前的rename_for_{rename_for}：{END}")
    print(f"{BLUE}当前{rename_for}-rename规则类似：{END}")
    print(f"{rename_list}")

    rename_input = input(f"请输入{rename_for}-rename:")
    return rename_input


def get_package_name(package_path,package_name):
    for file in os.listdir(package_path):
        if file.find(f"{package_name}") != -1:
            return file
    raise Exception(f"{package_name} 包不存在")


def local_ip():
    command = f''' ip a |grep inet |grep -v  127.0.0.1 |grep "scope global noprefixroute" |awk '{{print $2}}' |awk -F '/' '{{print $1}}' '''
    localip = exe_shell_cmd_stdout(command)
    print("本机IP：",localip)
    if localip :
        lip=localip
    else :
        lip=input("请输入选择的 IP 地址：")
    return lip


def wait_seconds(seconds):
    num_dots = 1
    direction = 1
    print(f' ')
    for _ in range(int(seconds / 0.5)):
        dots = '.' * num_dots
        print(f" \rWaiting for exporter start {dots}", end='', flush=True)
        time.sleep(0.5)  # 每隔0.5秒打印一次

        if num_dots == 5:
            num_dots = 0
        elif num_dots == 1:
            direction = 1

        num_dots += direction



def get_port(server):
       for d_server, d_port in default_port.items():
            if server.lower() == d_server:
                return d_port

def get_user(server):
    """获取 注册的服务的用户名"""
    pass

def get_user_pass(server):
    """获取 注册的服务的用户密码"""
    pass




def if_user_exists(username):
    command = f"id {username}"
    if os.system(command) == 0:
        return True
    else :
        raise ValueError(f"用户{username}未创建成功,请检查服务")

def exe_shell_cmd_stdout(cmd: str):
    """以 root 身份执行命令

    Parameter
    ---------
        cmd:str 要执行的命令

    Return
    ------
        str
    """
    with sudo():
        logger.info("执行命令:" + cmd)
        result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        logger.info(f"返回结果：")
        logger.info(result.stdout.decode('UTF-8').split('\n')[0].strip())
        return result.stdout.decode('UTF-8').split('\n')[0].strip()


_user_sudo_lock = RLock()

@contextlib.contextmanager
def sudo(message="sudo"):
    """临时升级权限到 root ."""
    # 对于权限这个临界区的访问要串行化
    with _user_sudo_lock as lk:
        # 得到当前进程的 euid
        old_euid = os.geteuid()
        # 提升权限到 root
        os.seteuid(0)
        yield message
        # 恢复到普通权限
        os.seteuid(old_euid)


def exe_shell_cmd(cmd: str):
    """以 root 身份执行命令

    Parameter
    ---------
        cmd:str 要执行的命令

    Return
    ------
        str
    """
    with sudo():
        logger.info("执行命令:" + cmd)
        result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if result.returncode != 0:
            raise Exception("执行命令失败:" + result.stdout.decode('UTF-8'))
        return True


def exe_shell_cmd_noerror(cmd: str):
    """以 root 身份执行命令

    Parameter
    ---------
        cmd:str 要执行的命令

    Return
    ------
        str
    """
    with sudo():
        logger.info("执行命令:" + cmd)
        result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        return result

def exe_shell_cmd_retry(cmd: str, retry:int=3):
    """以 root 身份执行命令

    Parameter
    ---------
        cmd:str 要执行的命令

    Return
    ------
        str
    """
    with sudo():
        logger.info("执行命令:" + cmd)
        result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        for _ in range(retry):
            if result.returncode == 0:
                return True
            wait_seconds(2)
            result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if result.returncode != 0:
            raise Exception("执行命令失败:" + result.stdout.decode('UTF-8'))
        return True

def encrypt_data(data, encrypted_flag = save_encrypted_pass):
    cipher = Fernet('pT8ZDjwCvnWkfPEYBm12q2p9srNkM-nWC6Ss9aAcMEw=')
    # 加密数据
    if encrypted_flag == str(0):
        return data
    else:
        # 加密数据
        encrypted_data = cipher.encrypt(data.encode()).decode()
        return encrypted_data


def decrypt_data(encrypted_data, encrypted_flag = save_encrypted_pass):
    cipher = Fernet('pT8ZDjwCvnWkfPEYBm12q2p9srNkM-nWC6Ss9aAcMEw=')
    # 解密数据
    if int(encrypted_flag) == 0:
        return encrypted_data
    else:
        # 解密数据
        decrypted_data = cipher.decrypt(encrypted_data.encode()).decode()
        return decrypted_data




