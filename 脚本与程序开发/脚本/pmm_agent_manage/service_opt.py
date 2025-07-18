#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os
from time import sleep

from jinja2 import Template
from getpass import getpass

import config
from components.ordinary import *
import config as cf
from env_opt import CommandCheck, process_check

import patoolib

from pmm_agent_manage import custom_labels
from components.log_format import log_decorator



def install_server():
    return init_client(cf.pmm_user, cf.pmm_pass, cf.pmm_server_address, cf.pmm_server_port)

@log_decorator
def init_client(pmm_user, pmm_pass, pmm_server_address, pmm_server_port):
    host = local_ip()
    environment_cmd = ''
    if not CommandCheck('pmm-agent'):
        # 后续可以改为读取文件名
        package=get_package_name(cf.local_package_path,"pmm-client")
        rpm_command = f'rpm -ivh {cf.local_package_path}/{package}'
        exe_shell_cmd(rpm_command)
    env_cmd = env_name
    environment_cmd = 'environment=' + env_cmd

    if not process_check('pmm-agent'):
        pmm_setup_command = f'pmm-agent setup --force --config-file=/usr/local/percona/pmm2/config/pmm-agent.yaml --server-address={pmm_server_address} --server-insecure-tls --server-username={pmm_user} --server-password={pmm_pass}'
        exe_shell_cmd(pmm_setup_command)

    # if not PortCheck('7777'):
    #     pmm_start_command = f'pmm-agent --config-file=/usr/local/percona/pmm2/config/pmm-agent.yaml'
    #     exe_shell_cmd(pmm_start_command)
    # 获取当前所有的cluster名称
    node_rename = get_rename(rename_for='node')

    pmm_register_command = (f'pmm-admin config --force --server-insecure-tls --custom-labels=' + f'{environment_cmd}' +
                            f',rename_node_name={node_rename} --server-url=https://{pmm_user}:{pmm_pass}@{pmm_server_address}:{pmm_server_port}  {host} generic node-{host}')
    exe_shell_cmd(pmm_register_command)

    return True

def register_process_exporter(pmm_user, pmm_pass,cluster_name, server ):
    env_cmd = env_name
    cluster_cmd = '--cluster=' + env_name + '-'
    ip = local_ip()
    port = get_port(server)
    if install_process_export( port):
        service_name = f"process-exporter-{ip}-{port}"
        command = f'pmm-admin add external --service-name={service_name} --listen-port={port} {cluster_cmd}process-exporter --environment={env_cmd}  --metrics-path=/metrics --custom-labels=node_type=elasticsearch,rename_service_name={service_name}'
        return exe_shell_cmd_retry(command)
    else:
        logger.error('install process exporter failed')
        return False


@log_decorator
def register_server(pmm_user, pmm_pass,cluster_name, server ):

    if server in 'mysql,proxysql,mongodb,postgresql':
        # 注册服务
        return register_internal_server(cluster_name, server)
    elif server in 'redis,elasticsearch,neo4j,influxdb,':
        # 注册external服务
        return register_external_server(cluster_name, server)
    else :
         raise Exception("未知的服务类型")
    # elif server == 'proxysql':
    #     register_external_server()



@log_decorator
def register_internal_server( env_name, server):
    env_cmd = env_name
    cluster_cmd = '--cluster=' + env_name + '-'

    register_flag = True
    ip = local_ip()

    port = get_port(server)
    service_rename = get_rename(server)
    if server == 'mysql':
        register_flag = register_flag & register_mysql(decrypt_data(config.mysql_user), decrypt_data(config.mysql_pass), cluster_cmd, env_cmd , ip, port,service_rename)
    elif server == 'proxysql':
        register_flag = register_flag & register_proxysql( decrypt_data(config.proxysql_user), decrypt_data(config.proxysql_pass), cluster_cmd, env_cmd , ip, port,service_rename)
    elif server == 'mongodb':
        register_flag = register_flag & register_mongodb(decrypt_data(config.mongodb_user),  decrypt_data(config.mongodb_pass), cluster_cmd, env_cmd , ip, port,service_rename)
    elif server == 'postgresql':
        register_flag = register_flag & register_postgresql(decrypt_data(config.postgresql_user), decrypt_data(config.postgresql_pass), cluster_cmd, env_cmd , ip, port,service_rename)

    return register_flag

@log_decorator
def register_mysql(pmm_user, pmm_pass, cluster_cmd, env_cmd, ip, port,service_rename):
    service_name = f"MySQL-{ip}-{port}"
    command = f'pmm-admin add mysql --query-source=perfschema --username={pmm_user} --password={pmm_pass} --service-name={service_name} --host={ip} --port={port} {cluster_cmd}MySQL --environment={env_cmd} --custom-labels=rename_service_name={service_rename}  '
    return exe_shell_cmd(command)

@log_decorator
def register_proxysql(pmm_user, pmm_pass, cluster_cmd, env_cmd, ip, port,service_rename):
    service_name=f"ProxySQL-{ip}-{port}"
    command = f'pmm-admin add proxysql --username={pmm_user} --password={pmm_pass} --service-name={service_name} --host={ip} --port={port} {cluster_cmd}ProxySQL --environment={env_cmd} --custom-labels=rename_service_name={service_rename}'
    return exe_shell_cmd(command)

@log_decorator
def register_mongodb(pmm_user, pmm_pass, cluster_cmd, env_cmd, ip, port,service_rename):
    service_name = f"MongoDB-{ip}-{port}"
    command = f'pmm-admin add mongodb --username={pmm_user} --password={pmm_pass} --service-name={service_name} --host={ip} --port={port} --query-source=profiler {cluster_cmd}MongoDB --environment={env_cmd} --custom-labels=rename_service_name={service_rename}'
    return exe_shell_cmd(command)

@log_decorator
def register_postgresql(pmm_user, pmm_pass, cluster_cmd, env_cmd, ip, port,service_rename):
    service_name = f"PgSQL-{ip}-{port}"
    command = f'pmm-admin add postgresql --username={pmm_user} --password={pmm_pass} --service-name={service_name} --host={ip} --port={port} {cluster_cmd}PgSQL --environment={env_cmd} --custom-labels=rename_service_name={service_rename}'
    return exe_shell_cmd(command)


@log_decorator
def register_external_server(env_name, server):
    env_cmd = env_name
    cluster_cmd = '--cluster=' + env_name + '-'

    register_flag = True
    ip = local_ip()

    port = get_port(server)
    exporter_port = get_port(server+'_exporter')
    service_rename = get_rename(server)
    if server == 'redis':
        register_flag = register_flag & register_redis(cluster_cmd, env_cmd, ip, port, exporter_port, service_rename)
    elif server == 'elasticsearch':
        register_flag = register_flag & register_elasticsearch(cluster_cmd, env_cmd, ip, port, exporter_port, service_rename)

    return register_flag


@log_decorator
def register_redis(cluster_cmd, env_cmd , ip, port, exporter_port,service_rename):
    if install_redis_export( config.redis_pass, port, exporter_port):
        service_name = f"Redis-{ip}-{port}"
        command = f'pmm-admin add external --service-name={service_name} --listen-port={exporter_port} {cluster_cmd}Redis --environment={env_cmd}  --metrics-path=/metrics --custom-labels=node_type=Redis,rename_service_name={service_rename}'
        return exe_shell_cmd_retry(command)
    else:
        logger.error('install elasticsearch exporter failed')
        return False


@log_decorator
def install_redis_export( redis_pass, port, exporter_port):
    # 解压exporter安装包到指定目录
    package=get_package_name(config.local_package_path, 'redis_exporter')
    outdir_dir = config.exporter_path+'/redis_exporter'
    if not os.path.exists(outdir_dir):
        os.makedirs(outdir_dir)
    if  not os.listdir(outdir_dir):
        patoolib.extract_archive(config.local_package_path+package, outdir=outdir_dir)

    for file in  os.listdir(outdir_dir):
        if  'redis_exporter' in file:
            os.rename(os.path.join(outdir_dir, file), outdir_dir + '/redis_exporter')
    redis_pass = decrypt_data(redis_pass)
    command = f'''/usr/bin/nohup {outdir_dir}/redis_exporter/redis_exporter -redis.addr 127.0.0.1:{port}  -redis.password {redis_pass}  -web.listen-address 127.0.0.1:{exporter_port} >> {config.log_path}/extend_server_exporter_log/redis_exporter_{port}.log 2>&1 &'''
    if exe_shell_cmd(command):
        # 记录启动语句
        with open(f'{exporter_path}/start_redis_exporter.sh', 'w') as f:
            f.write(command)
        return True


@log_decorator
def install_process_export( exporter_port):
    # 解压exporter安装包到指定目录
    outdir_dir = package_unpack('process-exporter')
    # 创建process_exporter 的配置文件
    if process_monitor_config is not None:
        with open(f'{exporter_path}/process-exporter.yml', 'w') as f:
            f.write(process_monitor_config)
    command = f'''/usr/bin/nohup {outdir_dir}/process-exporter -config.path {outdir_dir}/process-exporter.yml   -web.listen-address 127.0.0.1:{exporter_port} >> {config.log_path}/extend_server_exporter_log/process_exporter_{exporter_port}.log 2>&1 &'''
    if exe_shell_cmd(command):
        # 记录启动语句
        with open(f'{exporter_path}/start_process_exporter.sh', 'w') as f:
            f.write(command)
        return True


def package_unpack(package_type):
    # 解压exporter安装包到指定目录
    package = get_package_name(config.local_package_path, package_type)
    outdir_dir = config.exporter_path + '/'+ package_type
    if not os.path.exists(outdir_dir):
        os.makedirs(outdir_dir)
    if not os.listdir(outdir_dir):
        patoolib.extract_archive(config.local_package_path + package, outdir=outdir_dir)
    for file in  os.listdir(outdir_dir):
        if  'process_export' in file:
            os.rename(os.path.join(outdir_dir, file), outdir_dir + '/process_export')
    return outdir_dir


@log_decorator
def register_elasticsearch(cluster_cmd, env_cmd , ip, port, exporter_port, service_rename):
    if install_elasticsearch_export(config.elasticsearch_user, config.elasticsearch_pass, port, exporter_port):

        service_name = f"ES-{ip}-{exporter_port}"

        command = f'pmm-admin add external --service-name={service_name} --listen-port={exporter_port} {cluster_cmd}ElasticSearch --environment={env_cmd}  --metrics-path=/metrics --custom-labels=node_type=elasticsearch,rename_service_name={service_rename}'

        return exe_shell_cmd_retry(command)
    else :
        logger.error('install elasticsearch exporter failed')
        return False

@log_decorator
def install_elasticsearch_export(es_user,es_pass,port,exporter_port):
    # 解压exporter安装包到指定目录
    outdir_dir=package_unpack('elasticsearch_exporter')

    es_user = decrypt_data(es_user)
    es_pass = decrypt_data(es_pass)
    command = f'''/usr/bin/nohup {outdir_dir}/elasticsearch_exporter-1.5.0.linux-amd64/elasticsearch_exporter --es.all --es.indices --es.cluster_settings --es.indices_settings --es.indices_mappings --es.shards --es.snapshots --es.timeout=10s --es.ssl-skip-verify --web.listen-address=127.0.0.1:{exporter_port} --web.telemetry-path=/metrics --es.uri https://{es_user}:{es_pass}@127.0.0.1:{port} >> {config.log_path}/extend_server_exporter_log/elasticsearch_exporter_{port}.log 2>&1 &'''
    if exe_shell_cmd(command):
        # 记录启动语句
        with open(f'{exporter_path}/start_elasticsearch_exporter.sh', 'w') as f:
            f.write(command)
        return True


@log_decorator
def stop_exporter(service):
    running_exporter = []
    command = "systemctl stop pmm-agent.service"
    exe_shell_cmd_noerror(command)
    if service is None:
        for service in cf.service_list:
            if service in cf.service_pmm_list: # 2024-12-19 用于关停pmm服务
                continue
            elif service in list(set(cf.service_list) - set(cf.service_pmm_list)) and check_service_exporter_running(service):
                running_exporter.append(service+'_exporter')
    else :
        for index,single_service in  enumerate(service):
            running_exporter.append(single_service+'_exporter')

    for exporter in running_exporter:
        command = f'killall {exporter}'
        exe_shell_cmd(command)
    return True

@log_decorator
def start_exporter(service):
    need_start_exporter = []
    command = "systemctl stop pmm-agent.service"
    exe_shell_cmd_noerror(command)
    if service is None:
        for service in cf.service_list:
            if service in cf.service_pmm_list: # 2024-12-19 用于关停pmm服务
                continue
            elif service in list(set(cf.service_list) - set(cf.service_pmm_list)) and check_service_exporter_running(
                    service):
                need_start_exporter.append(service + '_exporter')
    else :
        for index,single_service in  enumerate(service):
            need_start_exporter.append(single_service+'_exporter')


    for exporter in need_start_exporter:
        command = f'{exporter_path}/start_{exporter}.sh'
        exe_shell_cmd(command)
    return True

@log_decorator
def remove_pmm_client():
    packages = subprocess.getoutput('rpm -qa | grep pmm.*-client')
    if packages:
        # 构建卸载命令，以字符串形式
        command = f"rpm -e {packages}"
        if exe_shell_cmd(command):
            print("已经卸载pmm-client:",packages)
            return True


def unregister_node():
    command = "pmm-admin list | grep -v 'type' | awk -F ' ' '{print $2}' | awk -F '-' '{if($1 != \"\") print $1}'"
    print(command)
    if exe_shell_cmd_stdout(command).strip() != "" and exe_shell_cmd_stdout(command).find('Failed'):
        command_unregister = f'pmm-admin unregister --force'
        command_restart_pmm_client = f'systemctl restart pmm-agent'
        return exe_shell_cmd(command_unregister) and exe_shell_cmd(command_restart_pmm_client)


def reset_service_config():
    if service_pass_reset == 1:
        reset_flag = input("是否重置配置文件：y/n. ==>")
        if reset_flag == 'y' or reset_flag == '':
            restore_flag = input("是否备份当前配置文件：y/n .==>")
            if restore_flag == 'y' or restore_flag == '':
                config_bak()
            config_file = os.getcwd() + '/config.py'
            default_config_file = os.getcwd() + '/.config.default.py'
            command = f"mv  -f {default_config_file} {config_file}"
            return exe_shell_cmd(command)
        else :
            return True


def config_bak():
    config_file = os.getcwd() + '/config.py'
    date_time=datetime.datetime.now().strftime('%Y%m%d%H%M%S')
    bak_file = os.getcwd() + '/.config.py.bak' + date_time
    command = f"mv -f {config_file} {bak_file}"
    return exe_shell_cmd(command)


def rebuild_config_file():
    """cipher 全局秘钥"""
    config_bak()
    # 定义需要填充的变量
    variables = dict()
    # 获取当前environment名称
    environment_list=get_environment()
    environment_input = str(input("请输入environment（输入前面的数字即可，新添加输入0）："))
    for i,environment in enumerate(environment_list):
        if environment_input == str(i+1):
            env_name = 'environment'
            variables[env_name] = environment
            break
        elif environment_input == str(0):
            env_name = 'env_name'
            variables[env_name] = str(input("新添加environment："))
            break
    if variables == {}:
        logger.error("输入错误,请输入env_name前的编号,新添加环境输入0")
        raise Exception("输入错误,请输入env_name前的编号,新添加环境输入0")

    service_list = server_discovery()
    logger.info(f'当前运行的服务:{service_list}')
    for service in service_list:
        user = input(f'{service}_user:')
        user_pass = getpass(f'{service}_pass:')
        # 读取配置文件模板
        with open('config_template.txt') as file:
            template = Template(file.read())

            service_user = service + '_user'
            service_pass = service + '_pass'
            variables[service_user] = encrypt_data(user)
            variables[service_pass] = encrypt_data(user_pass)

    # 使用变量填充模板
    config_content = template.render(variables)
    # 将填充后的内容写入最终配置文件
    with open('config.py', 'w') as file:
        file.write(config_content)

    return True



