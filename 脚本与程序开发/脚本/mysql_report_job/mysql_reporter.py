#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
mysql_report_job/

date : 2024/4/22
comment : 提示信息
"""
from config import html_path, db_restore
from mail import report_mail
from mysql_operator import reporterOperator,init_db
import argparse

def parser_cmd_args():
    """
    实现命令行参数的处理
    """
    parser = argparse.ArgumentParser(
        __name__, formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.epilog = """该脚本用户获得数据库基本运行状态;
                        1. 添加新的服务器，在mysql_reporter.source_target添加新的行;
                            1.1 数据库用户需要权限：如下
                            CREATE USER dzj_reporter@'172.30.70.11' IDENTIFIED BY 'k1Nk09ZIb2GicwHB';
                            GRANT PROCESS, EXECUTE, REPLICATION CLIENT ON *.* TO `dzj_reporter`@'172.30.70.11';
                            GRANT SELECT ON `mysql`.* TO `dzj_reporter`@'172.30.70.11';
                            GRANT SELECT ON `performance_schema`.* TO `dzj_reporter`@`172.30.70.11`;
                            GRANT SELECT ON `sys`.* TO `dzj_reporter`@`172.30.70.11`;
                            服务器查询用户创建：
                            useradd reporter
                            passwd reporter
                            1.2 开放端口
                            开放需要对脚本部署的服务器开放数据库端口和ssh端口.
                        2. 添加服务器，指标命令
                           增加服务器 mysql_report.source_target os与mysql分别添加 支持单机多实例配置
                           增加mysql相关指标 mysql_report.report_sql增加行 
                           增加os相关指标 mysql_report.report_os 增加行
                           调整导航栏 mysql_report.navigation_table
                           调整计算函数 参考 mysql_operator.py 中的 disk_handle() 计算函数
                           调整指标分类排序 config.py 中 metric_order 变量中的指标分类顺序(建议与导航栏中的顺序一致)
                           调整具体指标排序 mysql_report.metric_report_format order_id 字段 或使用字符串排序方法 -sort 
                    """



    parser.add_argument(
        "-i","--init_db",
        action="store_true",
        help=f"当次参数存在时表示初始化，默认进行初始化"
    )

    parser.add_argument(
        "-iu","--init_user",
        type=str,
        default='',
        help=f"初始化用户"
    )

    parser.add_argument(
        "-ip","--init_password",
        type=str,
        default='',
        help=f"初始化密码"
    )

    parser.add_argument(
        "-ih","--init_host",
        type=str,
        default='',
        help=f"初始化host"
    )

    parser.add_argument(
        "-iP","--init_port",
        type=int,
        default=0,
        help=f"初始化端口"
    )
    parser.add_argument(
        "-sort","--sort_metric",
        action="store_true",
        help=f"当次参数存在时表示进行指标的重排序，用于控制输出的html页面中的指标显示顺序,也可以手动更新数据库中的order_id值,默认不重新排序"
    )

    args = parser.parse_args()

    return args

if __name__ == "__main__":
    args=parser_cmd_args()
    try :
        # 初始化数据库
        if  args.init_db :
            if args.init_user != '' and args.init_password != '' and args.init_host != '' and args.init_port != 0:
                db_init = {'host': args.init_host, 'port': args.init_port, 'user': str(args.init_user), 'password': str(args.init_password)}
            else :
                db_init = db_restore
            init_db(db_init)
    except Exception as e:
        print(e)

    # 获取操作对象
    config_db = reporterOperator()
    # 指标重排序
    if args.sort_metric:
        reporterOperator().sort_metric()

    args = parser_cmd_args()
    # 获得sql
    config_db.get_all_query()
    # 获取metric
    config_db.get_all_metric()
    # 写入metric
    config_db.insert_all_metric()
    # 计算指标
    config_db.os_calculate_fun_handle()
    # 生成html
    config_db.metric_result_html_format()

    # 发送邮件
    report_mail(config_db,html_path)

