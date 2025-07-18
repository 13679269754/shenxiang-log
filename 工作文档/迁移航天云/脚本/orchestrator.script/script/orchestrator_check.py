import logging
import os
import sys
import argparse
import datetime
import time

basedir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, basedir)
GLOBAL_NOW_TIME = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

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

try:
    from .mysql_utils import sql_execute
    from .get_config_info import get_proxysql_admin_password
    from .get_config_info import get_proxysql_connect_dict
    from .get_config_info import get_proxysql_group_id
    from .get_config_info import send_alert
    from .os_utils import get_host_ip
    from .os_utils import write_json
    from .os_utils import read_json
    from .os_utils import message_format
except Exception:
    from mysql_utils import sql_execute
    from get_config_info import get_proxysql_admin_password
    from get_config_info import get_proxysql_connect_dict
    from get_config_info import get_proxysql_group_id
    from get_config_info import send_alert
    from os_utils import get_host_ip
    from os_utils import write_json
    from os_utils import read_json
    from os_utils import message_format

log = logging.getLogger(__name__)
log_dir = "{basedir}/log/check_log".format(basedir=basedir)
if not os.path.exists(log_dir):
    os.makedirs(log_dir)

log_name = os.path.join(log_dir,"orchestrator-check-{now_time}.log".format(now_time=GLOBAL_NOW_TIME))
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
parser.add_argument('--start_slave', '-ss', type=int, help='command', required=True, nargs='?', const='')
args = parser.parse_args()
mysql_fail_host = args.fail_host
mysql_fail_port = args.fail_port
mysql_success_host = args.success_host
mysql_success_port = args.success_port
command = args.command
start_slave = args.start_slave

master_mysql_config_dict = {"database_name": None,
                           "host": mysql_success_host,
                           "port": mysql_success_port,
                           "password": mysql_topology_password,
                           "username": mysql_topology_user}

proxysql_config_dict = get_proxysql_connect_dict(mysql_success_host,mysql_success_port)
proxysql_read_groupid, proxysql_write_groupid = get_proxysql_group_id()

def check_proxysql_info(proxysql_config_dict, host, port, type):
    log.info("Now check the proxysql")
    info_write_sql = "select * from runtime_mysql_servers where hostname='{host}' and port = '{port}' and status = 'ONLINE' and hostgroup_id = {proxysql_write_groupid}".format(
        host=host, port=port, proxysql_write_groupid=proxysql_write_groupid)
    return_write_data = sql_execute(sql_to_execute=info_write_sql, mysql_config_dict=proxysql_config_dict)
    info_read_sql = "select * from runtime_mysql_servers where hostname='{host}' and port = '{port}' and status = 'ONLINE' and hostgroup_id = {proxysql_read_groupid}".format(
        host=host, port=port, proxysql_read_groupid=proxysql_read_groupid)
    return_read_data = sql_execute(sql_to_execute=info_read_sql, mysql_config_dict=proxysql_config_dict)
    msg = ''
    if type == 'Master':
        if return_write_data:
            msg += 'Master {host}:{port} ProxySql 检测正常\n'.format(host=host,port=port)
        else:
            msg += 'Master {host}:{port} ProxySql 检测失败\n'.format(host=host,port=port)
    elif type == 'Slave':
        if return_read_data and not return_write_data:
            msg += 'Slave {host}:{port} ProxySql 检测正常\n'.format(host=host,port=port)
        else:
            msg += 'Slave {host}:{port} ProxySql 检测失败\n'.format(host=host,port=port)
    return msg

def proxysql_mysql_servers_info_get(proxysql_config_dict):
    try:
        backup_mysql_servers_sql = "select * from mysql_servers order by 1,2;"
        mysql_servers_backup_info = sql_execute(sql_to_execute=backup_mysql_servers_sql, mysql_config_dict=proxysql_config_dict)
        log.info("Table mysql_servers backup info: \n{mysql_servers_backup_info}".format(mysql_servers_backup_info=message_format(mysql_servers_backup_info)))

        backup_runtime_mysql_servers_sql = "select * from runtime_mysql_servers order by 1,2;"
        runtime_mysql_servers_backup_info = sql_execute(sql_to_execute=backup_runtime_mysql_servers_sql,mysql_config_dict=proxysql_config_dict)
        log.info("Table runtime_mysql_servers_backup_info backup info: \n{runtime_mysql_servers_backup_info}".format(runtime_mysql_servers_backup_info=message_format(runtime_mysql_servers_backup_info)))
        return mysql_servers_backup_info,runtime_mysql_servers_backup_info
    except:
        log.error("Can't not get proxysql information: {proxysql_config_dict}".format(proxysql_config_dict=proxysql_config_dict))
        sys.exit(1)

def proxysql_cluster_info(proxysql_config_dict):
    try:
        cluster_info_sql = "select * from stats_proxysql_servers_checksums where diff_check > 0 order by 1,2;"
        cluster_info = sql_execute(sql_to_execute=cluster_info_sql,mysql_config_dict=proxysql_config_dict)
        log.info("Table stats_proxysql_servers_checksums info: \n{cluster_info}".format(cluster_info=message_format(cluster_info)))
        return cluster_info
    except:
        log.error("Can't not get proxysql cluster information: {proxysql_config_dict}".format(proxysql_config_dict=proxysql_config_dict))
        sys.exit(1)

def proxy_sql_check():
    mysql_servers_info,runtime_mysql_servers_info = proxysql_mysql_servers_info_get(proxysql_config_dict)
    cluster_info = proxysql_cluster_info(proxysql_config_dict)

    message = '当前mysql_servers信息: \nmysql_servers: \n{mysql_servers_info}\nruntime_mysql_servers:\n{runtime_mysql_servers_info}\n' \
              '当前proxysql cluster信息: \n {cluster_info}\n-------------------------------------\n'.format(
        mysql_servers_info=message_format(mysql_servers_info, [0, 1, 2, 4]),
        runtime_mysql_servers_info=message_format(runtime_mysql_servers_info, [0, 1, 2, 4]),
        cluster_info=message_format(cluster_info, [0, 1, 2, 8]))

    msg = check_proxysql_info(proxysql_config_dict, mysql_success_host, mysql_success_port, 'Master')
    message += msg

    mysql_slave_list = get_mysql_all_slave(orchestrator_username=orchestrator_http_auth_user,
                                           orchestrator_password=orchestrator_http_auth_password,
                                           orchestrator_url=orchestrator_url,
                                           mysql_host=mysql_success_host,
                                           mysql_port=mysql_success_port)

    for inst in mysql_slave_list:
        slave_host = inst.get('Hostname')
        slave_port = inst.get('Port')
        msg = check_proxysql_info(proxysql_config_dict, slave_host, slave_port, 'Slave')
        message += msg

    send_alert("ProxySql 信息检测:", message)


def mysql_read_only_check():
    msg= ''
    super_read_only_status, read_only_status = get_read_only_status(mysql_config_dict=master_mysql_config_dict)
    if super_read_only_status == 'ON' or read_only_status == 'ON':
        msg += "Master {mysql_success_host}:{mysql_success_port} read only 检测失败\n".format(mysql_success_host=mysql_success_host,mysql_success_port=mysql_success_port)
    else:
        msg += "Master {mysql_success_host}:{mysql_success_port} read only 检测成功\n".format(mysql_success_host=mysql_success_host,mysql_success_port=mysql_success_port)

    mysql_slave_list = get_mysql_all_slave(orchestrator_username=orchestrator_http_auth_user,
                                           orchestrator_password=orchestrator_http_auth_password,
                                           orchestrator_url=orchestrator_url,
                                           mysql_host=mysql_success_host,
                                           mysql_port=mysql_success_port)

    for inst in mysql_slave_list:
        slave_host = inst.get('Hostname')
        slave_port = inst.get('Port')

        slave_mysql_config_dict = {"database_name": None,
                                   "host": slave_host,
                                   "port": slave_port,
                                   "password": mysql_topology_password,
                                   "username": mysql_topology_user}

        super_read_only_status, read_only_status = get_read_only_status(mysql_config_dict=slave_mysql_config_dict)

        if super_read_only_status != 'ON' or read_only_status != 'ON':
            set_instance_read_only(slave_mysql_config_dict)
            new_super_read_only_status, new_read_only_status = get_read_only_status(mysql_config_dict=slave_mysql_config_dict)
            msg += "Slave   {slave_host}:{slave_port} read only 检测失败，重新设置super_read_only 和 read_only, 最新值为: {new_super_read_only_status},{new_read_only_status}\n".format(slave_host=slave_host, slave_port=slave_port,new_super_read_only_status=new_super_read_only_status,new_read_only_status=new_read_only_status)

        else:
            msg += "Slave   {slave_host}:{slave_port} read only 检测成功\n".format(slave_host=slave_host,slave_port=slave_port)
    log.info(msg)
    send_alert('Read_only 检测:', msg)

def start_slave_host():
    old_master_mysql_config_dict = {"database_name": None,
                                "host": mysql_fail_host,
                                "port": mysql_fail_port,
                                "password": mysql_topology_password,
                                "username": mysql_topology_user}
    start_slave_sql='start slave;'
    sql_execute(sql_to_execute=start_slave_sql, mysql_config_dict=old_master_mysql_config_dict)
    time.sleep(10)


def main():
    if command == "graceful-master-takeover":
        if start_slave == 1:
            start_slave_host()
            mysql_read_only_check()
            proxy_sql_check()
        else:
            pass
    else:
        mysql_read_only_check()
        proxy_sql_check()

if __name__ == '__main__':
    sys.exit(main())
