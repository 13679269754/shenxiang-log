#!/usr/bin/env python3
# -*- coding: utf8 -*-
import argparse

from  service_opt  import *
from env_opt import *
from components.log_format import log_decorator


# pmm_agent_manage
# 控制注册节点的标签
custom_labels = ''

# 支持服务： mysql ,proxysql ,redis ,es ,mongodb ,neo4j
# rsync 拉取脚本与export
# node_export 安装 ; node注册pmm
# service_export 安装 ; service 注册pmm


def parser_cmd_args():
    """
    实现命令行参数的处理
    """
    parser = argparse.ArgumentParser(
        __name__, formatter_class=argparse.RawTextHelpFormatter
    )
    parser.epilog = f"""脚本配置文件为同目录级别的{BOLD}config.py{END},使用示例
    生成配置文件 
    {BOLD}python3 pmm_agent_manage.py --model interactive{END}
    安装监控 
    {BOLD}python3 pmm_agent_manage.py --operation install --node_type redis,mysql,elasticsearch{END}
    若需要监控的数据库服务端口不是默认端口，可以修改 {BOLD}config.py{END} 中的 {BOLD}default_port{END}
    若需要监控的数据库服务用户名用户名密码，自行修改 {BOLD}config.py{END} """

    parser.add_argument('--node_type',
                        type=str,
                        default=None,
                        help=fr"""安装的监控的类型:
                                传入{BOLD}node 必被安装,且当node被配置的时候忽略服务，仅注册node节点{END}, 其他选项:  mysql ,proxysql ,redis ,es ,mongodb ,neo4j,influxdb, postgresql...
                                process 安装服务监控; 
                                多个值用','分割;
                                未使用该选项时自动探测当前服务器正在运行的服务;
                                当等于未传入参数表示对当前服务器上正在运行的db服务操作;""")

    parser.add_argument('--model',
                        type=str,
                        default="config",
                        help="""参数填写模式 (必填) 可选值:
                        config 通过配置文件添加配置(备份手工配置的备份文件) 
                        interactive（仅能用于配置文件生成） 交互式参数输入 -- 所有配置可以通过 config_template.txt 来修改端口 以及日志目录配置，修改 config.py 会被手工输入的用户密码覆盖
                        """)


    parser.add_argument('--operation',
                        type=str,
                        default='install',
                        help=""" 操作类型 可选值: 
                                 config             配置文件生成,仅生承配置文件不做后续操作（用于交互式配置文件生成后，调整默认的日志路径等功能）
                                 init               初始化服务器,拉取exporter，创建目录
                                 install            安装服务监控
                                 reinstall          重新安装服务监控 clean+install
                                 clean              清理安装的export，并在pmm server端注销服务,但不会清理安装脚本
                                 stop               仅停止export服务
                                 remove             stop 并卸载当前pmm-client""")


    args = parser.parse_args()

    return args

@log_decorator
def main(cipher=None):
    args = parser_cmd_args()

    if args.node_type is not None:
        args.node_type = args.node_type.split(',')

    if 'init' in args.operation:
        env_init()
        logger.info('环境初始化完成(仅拉取安装包,不进行后续安装)')
        exit(0)

    if args.model == 'interactive':
        rebuild_config_file()
        print('重新生成配置文件完成 执行 python3 pmm_agent_manage.py --operation install 安装pmm客户端')
        exit(0)

    if args.operation == 'install':
        if args.model == "":
            raise Exception("""参数 model 为必填项 , 
                             \nconfig 通过配置文件添加配置(备份手工配置的备份文件) 
                             \ninteractive 交互式参数输入 -- 所有配置可以通过 config_template.txt 来修改端口 以及日志目录配置，修改 config.py 会被手工输入的用户密码覆盖""")


        install(args)
    if args.operation == 'reinstall':
        clean(args.node_type)
        install(args)
    if args.operation == 'clean':
        clean(args.node_type)
    if args.operation == 'stop':
        stop_exporter(args.node_type)

    if args.operation == 'start':
        start_exporter(args.node_type)

    if args.operation == 'remove':
        stop_exporter(args.node_type)
        remove_pmm_client()
    # # 处理config文件,避免明文密码
    # reset_service_config()
    return True


def clean(service):
    # 注销node
    unregister_node()
    # 关闭exporter 进程
    stop_exporter(service)


def install(args):
    # 服务探测
    if args.node_type is None:
        args.node_type = server_discovery()
        logger.info(f'当前运行的服务:{args.node_type}')
    # 注册监控节点到监控服务器
    install_server()
    if ',' not in args.node_type and args.node_type in service_list or args.node_type == "":
        # 节点类型标签
        global custom_labels
        custom_labels = f'--custom-labels=node_type={args.node_type}'
    # 注册node
    if (args.node_type in service_list or args.node_type == "") and not "node" in args.node_type:
        # 安装服务监控
        register_server(pmm_user, pmm_pass, cf.env_name, args.node_type)
    elif "node" in args.node_type:
        return True
    else:
        for server_type in args.node_type:
            if server_type in list(set(service_list) - set(list('process'))):
                register_server(pmm_user, pmm_pass, cf.env_name, server_type)
            elif server_type == 'process':
                # 安装进程监控
                register_process_exporter(pmm_user, pmm_pass, cf.env_name, 'process_exporter')
            else:
                raise ValueError(f"不正确的node_type：{server_type}，例子：mysql,redis...")

if __name__ == '__main__':
    main()





