import logging
import os
import sys
import argparse
import time,datetime

basedir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, basedir)
GLOBAL_NOW_TIME = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
try:
    from .get_config_info import get_proxysql_admin_password
    from .get_config_info import get_proxysql_host_info
    from .get_config_info import get_proxysql_group_id
    from .get_config_info import get_proxysql_connect_dict
    from .get_config_info import send_alert
    from .os_utils import get_host_ip
    from .os_utils import write_json
    from .os_utils import read_json
    from .os_utils import message_format
except Exception:
    from get_config_info import get_proxysql_admin_password
    from get_config_info import get_proxysql_host_info
    from get_config_info import get_proxysql_group_id
    from get_config_info import get_proxysql_connect_dict
    from get_config_info import send_alert
    from os_utils import get_host_ip
    from os_utils import write_json
    from os_utils import read_json
    from os_utils import message_format



try:
    from .mysql_utils import sql_execute
    from .mysql_utils import set_instance_read_only
    from .mysql_utils import get_transaction_from_meta
    from .mysql_utils import get_mysql_gtid
    from .mysql_utils import get_mysql_all_slave
    from .mysql_utils import get_orchestrator_mysql_info
    from .mysql_utils import sql_execute_without_close
    from .mysql_utils import restore_instance_read_only
    from .mysql_utils import get_read_only_status
    from .mysql_utils import set_proxysql_offline_soft
    from .mysql_utils import restore_proxysql_offline_soft
except Exception as e:
    from mysql_utils import sql_execute
    from mysql_utils import set_instance_read_only
    from mysql_utils import get_transaction_from_meta
    from mysql_utils import get_mysql_gtid
    from mysql_utils import get_mysql_all_slave
    from mysql_utils import get_orchestrator_mysql_info
    from mysql_utils import sql_execute_without_close
    from mysql_utils import restore_instance_read_only
    from mysql_utils import get_read_only_status
    from mysql_utils import set_proxysql_offline_soft
    from mysql_utils import restore_proxysql_offline_soft

try:
    from .info_config import mysql_topology_user
    from .info_config import mysql_topology_password
    from .info_config import retry_get_transaction
    from .info_config import get_transaction_count_interval
    from .info_config import check_transaction_option
    from .info_config import compare_gtid
    from .info_config import compare_gtid_type
    from .info_config import orchestrator_http_auth_user
    from .info_config import orchestrator_http_auth_password
    from .info_config import orchestrator_url
    from .info_config import gtid_check_time
    from .info_config import gtid_check_interval
    from .info_config import proxysql_wait_time
    from .info_config import proxysql_read_group_master
except Exception as e:
    from info_config import mysql_topology_user
    from info_config import mysql_topology_password
    from info_config import retry_get_transaction
    from info_config import get_transaction_count_interval
    from info_config import check_transaction_option
    from info_config import compare_gtid
    from info_config import compare_gtid_type
    from info_config import orchestrator_http_auth_user
    from info_config import orchestrator_http_auth_password
    from info_config import orchestrator_url
    from info_config import gtid_check_time
    from info_config import gtid_check_interval
    from info_config import proxysql_wait_time
    from info_config import proxysql_read_group_master

log = logging.getLogger(__name__)
log_dir = "{basedir}/log/graceful_takeover/".format(basedir=basedir)

# window环境测试
log_dir = r"{basedir}\log\graceful_takeover".format(basedir=basedir)

if not os.path.exists(log_dir):
    os.makedirs(log_dir)
log_name =os.path.join( r"C:\Users\shenxiang.DAZHUANJIA\Desktop\脚本\orchestrator_script\log\graceful_takeover\orchestrator_graceful_takeover_check_processes-{now_time}.log".format(now_time=GLOBAL_NOW_TIME))

formatter = logging.basicConfig(filename=log_name,
                                level=logging.INFO,
                                format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                                datefmt='%a, %d %b %Y %H:%M:%S')

parser = argparse.ArgumentParser(description='mysql backup command line .',
                                 usage=None,
                                 add_help=True)
parser.add_argument('--fail_host', '-fi', type=str, help='host of mysql fail instance', required=True)
parser.add_argument('--fail_port', '-fp', type=int, help='port of mysql fail instance', required=True)
parser.add_argument('--success_host', '-si', type=str, help='host of mysql success instance', required=True)
parser.add_argument('--success_port', '-sp', type=int, help='port of mysql success instance', required=True)
parser.add_argument('--command', '-c', type=str, help='command', required=False, nargs='?', const='')

args = parser.parse_args()
mysql_demote_host = args.fail_host
mysql_demote_port = args.fail_port
mysql_success_host = args.success_host
mysql_success_port = args.success_port
command = args.command

local_host_ip = get_host_ip()
master_mysql_config_dict = {"database_name": None,
                            "host": mysql_demote_host,
                            "port": mysql_demote_port,
                            "password": mysql_topology_password,
                            "username": mysql_topology_user}

proxysql_config_dict = get_proxysql_connect_dict(mysql_demote_host,mysql_demote_port)



def check_transaction():
    if check_transaction_option == 1:
        retry_get_transaction_count_time = retry_get_transaction
        transaction_result = get_transaction_from_meta(mysql_config_dict=master_mysql_config_dict)
        while retry_get_transaction_count_time:
            if transaction_result is not None and len(transaction_result) > 0:
                log.info("事务信息：\n{transaction_result}".format(transaction_result=message_format(transaction_result)))
                time.sleep(get_transaction_count_interval)
                retry_get_transaction_count_time -= 1

                if retry_get_transaction_count_time > 0:
                    continue
            else:
                break

            transaction_check_hint_info = "Now we exit this grace switch process.\n"\
            "because we detect that there are some transactions still running.\n"\
            "You can check the log : {log_name}.\n"\
            "If you want to force processing this progress.\n"\
            "you should config the file : {basedir}/info_config.py on {local_host_ip}\n"\
            "option : 'check_transaction_option' to 0\n"\
            "to skip this step.".format(log_name=log_name, basedir=basedir, local_host_ip=local_host_ip)
            log.info(transaction_check_hint_info)
            raise RuntimeWarning(transaction_check_hint_info)


def judge_gtid(check_time, check_interval, slave_host, slave_port, master_gtid):
    gtid_check_time_run = check_time
    slave_mysql_config_dict = {"database_name": None,
                               "host": slave_host,
                               "port": slave_port,
                               "password": mysql_topology_password,
                               "username": mysql_topology_user}
    while gtid_check_time_run:
        slave_gtid = get_mysql_gtid(slave_mysql_config_dict)

        if slave_gtid == master_gtid:
            log.info("The instance({slave_host}:{slave_port}) gtid is the same from the master gtid. ".format(slave_host=slave_host, slave_port=slave_port))
            return True
        else:
            gtid_check_time_run -= 1
            time.sleep(check_interval)
    return False

def compare_gtid_fun():
    if compare_gtid == 1:
        master_gtid = get_mysql_gtid(master_mysql_config_dict)


        if compare_gtid_type == 1:
            mysql_slave_list = [{'Hostname':mysql_success_host,'Port':mysql_success_port}]
        else:
            mysql_slave_list = get_mysql_all_slave(orchestrator_username=orchestrator_http_auth_user,
                                                   orchestrator_password=orchestrator_http_auth_password,
                                                   orchestrator_url=orchestrator_url,
                                                   mysql_host=mysql_demote_host,
                                                   mysql_port=mysql_demote_port)

        for inst in mysql_slave_list:
            slave_host = inst.get('Hostname')
            slave_port = inst.get('Port')

            if compare_gtid_type == 2:
                slave_info = get_orchestrator_mysql_info(orchestrator_username=orchestrator_http_auth_user,
                                                         orchestrator_password=orchestrator_http_auth_password,
                                                         orchestrator_url=orchestrator_url,
                                                         mysql_host=slave_host,
                                                         mysql_port=slave_port)
                PromotionRule_info = slave_info.get('PromotionRule')

                if PromotionRule_info not in ('prefer','neutral'):
                    continue

            gtid_check_time_run = gtid_check_time
            judge_gtid_result = judge_gtid(check_time=gtid_check_time_run,
                                           check_interval=gtid_check_interval,
                                           slave_host=slave_host,
                                           slave_port=slave_port,
                                           master_gtid=master_gtid)

            if not judge_gtid_result:
                info_heads_up = "Now we detect that the gtid of slave instance({slave_inst}).\n"\
                "is different from the demote master instance({mysql_demote_host}:{mysql_demote_port}).\n"\
                "and now we raise a RuntimeWarning exception to avoid mistake to try to maintain the data consistence.\n"\
                "If you confirm this is not an issue and still want to do a switch ,\n"\
                "you should config the file : {basedir}/info_config.py on {local_host_ip} option compare_gtid to 0.\n"\
                "to skip this gtid check step.".format(slave_inst=slave_host + ':' + str(slave_port),
                                                          mysql_demote_host=mysql_demote_host,
                                                          mysql_demote_port=mysql_demote_port,
                                                          basedir=basedir,
                                                          local_host_ip=local_host_ip)
                log.info(info_heads_up)
                raise RuntimeWarning(info_heads_up)



def graceful_switch():
    log.info("Graceful switch cluster , demote instance is:{mysql_demote_host}:{mysql_demote_port}".format(mysql_demote_host=mysql_demote_host, mysql_demote_port=mysql_demote_port))
    set_proxysql_offline_soft(proxysql_config_dict=proxysql_config_dict,host=mysql_demote_host,port=mysql_demote_port)
    check_transaction()
    time.sleep(proxysql_wait_time)

    set_instance_read_only(mysql_config_dict=master_mysql_config_dict)
    check_transaction()

    compare_gtid_fun()

def main():
    message = "故障Mysql HOST: {mysql_fail_host}:{mysql_fail_port} ! \n" \
              "变更Mysql HOST: {mysql_success_host}:{mysql_success_port} !\n" \
              "执行变更 HOST : {local_host_ip}\n\n".format(
        mysql_fail_host=mysql_demote_host,
        mysql_fail_port=mysql_demote_port,
        mysql_success_host=mysql_success_host,
        mysql_success_port=mysql_success_port,
        local_host_ip=local_host_ip)

    super_read_only_status, read_only_status = get_read_only_status(mysql_config_dict=master_mysql_config_dict)
    try:
        graceful_switch()
        log.info('Orchestrator grace full takeover 检查成功')
        send_alert('Orchestrator grace full takeover 检查成功', message)
    except Exception as e:
        restore_instance_read_only(master_mysql_config_dict, super_read_only_status, read_only_status)
        restore_proxysql_offline_soft(proxysql_config_dict=proxysql_config_dict,host=mysql_demote_host,port=mysql_demote_port)
        log.error('Orchestrator grace full takeover 检查失败')
        send_alert('Orchestrator grace full takeover 检查失败',message + str(e))
        raise e



if __name__ == "__main__":
    sys.exit(main())

