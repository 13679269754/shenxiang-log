import argparse
import logging
import sys
import os
import time

basedir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, basedir)

# try:
from os_utils import read_json
from os_utils import convert_to_sql

from mysql_utils import restore_instance_read_only

from info_config import mysql_topology_user
from info_config import mysql_topology_password
from info_config import mysql_topology_user
from info_config import mysql_topology_password
from info_config import second_behind_master_threshold
from info_config import check_slave_delay_interval
from info_config import default_rep_user_info

from mysql_utils import sql_execute
from get_config_info import get_proxysql_admin_password
from get_config_info import get_proxysql_instance_info_by_mysql_instance_info
from get_config_info import get_mysql_password

# except ImportError:
#     from .os_utils import read_json
#     from .os_utils import convert_to_sql
#
#     from .info_config import mysql_topology_user
#     from .info_config import mysql_topology_password
#
#     from .mysql_utils import get_database_connect
#     from .mysql_utils import sql_execute

log = logging.getLogger(__name__)

log_dir = "{basedir}/recovery_info/".format(basedir=basedir)

log_name = "{log_dir}/recovery_info.log".format(log_dir=log_dir)
print("Please check log:{log_name}".format(log_name=log_name))
formatter = logging.basicConfig(
    # filename=log_name,
    level=logging.INFO,
    format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
    datefmt='%a, %d %b %Y %H:%M:%S'
)

parser = argparse.ArgumentParser(description='mysql backup command line .',
                                 usage=None,
                                 add_help=True)
parser.add_argument('--file', '-f', type=str, help='恢复信息文件', required=True)
parser.add_argument('--command', '-c', type=str, help='恢复选择:(r:恢复同步;p:恢复proxysql;a:恢复同步同时恢复proxysql) ', required=False)
parser.add_argument('--rep_user_password', '-e', type=str, help='从库复制用户密码,若为空,则从平台中获取. ', required=False)
parser.add_argument('--force_set_read_only', type=int, help='强制设置read_only 与super read_only', required=False)
args = parser.parse_args()
recovery_info_file = args.file
recovery_set_read_only_force = args.force_set_read_only
replication_user_password = args.rep_user_password
if replication_user_password is not None:
    log.warning('repuser password is on the command line, for the security consideration , it is not a good idea . ')
command = args.command
if command is None:
    command = 'a'


def get_read_only_status(mysql_config_dict):
    get_super_read_only_sql = "show variables like 'super_read_only';"
    get_read_only = "show variables like 'read_only';"
    super_read_only_sql_status = sql_execute(sql_to_execute=get_super_read_only_sql,
                                             mysql_config_dict=mysql_config_dict)
    super_read_only_status_value = super_read_only_sql_status[0].get("Value")
    read_only_status = sql_execute(sql_to_execute=get_read_only, mysql_config_dict=mysql_config_dict)
    read_only_status_value = read_only_status[0].get("Value")
    return super_read_only_status_value, read_only_status_value


def get_proxysql_host_port(mysql_host, mysql_port):
    return get_proxysql_instance_info_by_mysql_instance_info(mysql_host=mysql_host, mysql_port=mysql_port)


def get_proxysql_cluster_password(proxysql_host, proxysql_port):
    return get_proxysql_admin_password(proxysql_host, proxysql_port)


def get_proxysql_connect_by_mysql(mysql_host, mysql_port):
    proxysql_username = "cluster"
    proxysql_host, proxysql_port = get_proxysql_host_port(mysql_host, mysql_port)
    log.info("Now get the proxysql instance info.")
    if proxysql_host is None or proxysql_port is None:
        log.error("Can't not find proxysql information of instance: {fail_host}:{fail_port}".format(
            fail_host=mysql_host, fail_port=mysql_port))
        sys.exit(1)
    log.info("Instance of proxysql :{proxysql_host}:{proxysql_port}".format(proxysql_host=proxysql_host,
                                                                            proxysql_port=proxysql_port))
    proxysql_password = get_proxysql_cluster_password(proxysql_host, proxysql_port)
    if proxysql_password is None:
        log.error("Can't get password of proxysql instance: {proxysql_host}:{proxysql_port}".format(
            proxysql_host=proxysql_host, proxysql_port=proxysql_port))
        sys.exit(1)

    proxysql_config_dict = {"database_name": None, "host": proxysql_host, "port": proxysql_port,
                            "password": proxysql_password,
                            "username": proxysql_username}
    return proxysql_config_dict


def get_master_instance_info(proxysql_config_dict):
    get_master_instance = "select * from runtime_mysql_servers , runtime_mysql_replication_hostgroups  " \
                          "where runtime_mysql_servers.hostgroup_id = runtime_mysql_replication_hostgroups.writer_hostgroup ; "
    master_instance = sql_execute(sql_to_execute=get_master_instance,
                                  mysql_config_dict=proxysql_config_dict)
    try:
        master_instance_info = master_instance[0]
    except Exception:
        log.error('Can not get the master info of this cluster . ')
        sys.exit(1)
    return master_instance_info


def mysql_replication_delay_check(**kwargs):
    mysql_config_dict = kwargs.get('mysql_config_dict')
    get_repl_info_sql = 'show slave status ; '

    try:
        while True:
            slaves_status = sql_execute(sql_to_execute=get_repl_info_sql,
                                        mysql_config_dict=mysql_config_dict)
            if len(slaves_status) == 0:
                log.error("There is no replication info in this instance .")
                return False
            return_flag = 1
            for slave_status in slaves_status:
                if slave_status.get('Slave_IO_Running') != "Yes" or slave_status.get('Slave_IO_Running') != 'Yes':
                    log.error("Replication error , please check Slave_IO_Running or Slave_IO_Running . ")
                    return False
                second_behind_master = slave_status.get('Seconds_Behind_Master')
                if second_behind_master is None:
                    log.error("Secondary behind Master is None. It regard it as a replication error . ")
                    return False
                if second_behind_master > second_behind_master_threshold:
                    return_flag = 0
            if return_flag == 1:
                return True

            log_msg = "There is a replication delay(Seconds_Behind_Master)" \
                      " between the master and slave . now we sleep {} seconds".format(check_slave_delay_interval)
            log.info(log_msg)
            time.sleep(check_slave_delay_interval)
    except Exception:
        return False


def mysql_replication_info_check(**kwargs):
    mysql_config_dict = kwargs.get('mysql_config_dict')
    get_repl_info_sql = 'show slave status ; '
    slave_status = sql_execute(sql_to_execute=get_repl_info_sql,
                               mysql_config_dict=mysql_config_dict)
    try:
        if len(slave_status) == 0:
            return True
        else:
            return False
    except Exception:
        return False


def mysql_replication_change(mysql_config_dict, master_host, master_port):
    mysql_repl_user = 'repuser'
    master_password = get_replication_user_psw(mysql_host=master_host, mysql_port=master_port,
                                               repl_user=mysql_repl_user)
    change_master_sql = "change master to master_host='{master_host}'," \
                        "master_port={master_port},master_user='{mysql_repl_user}'," \
                        "master_password='{master_password}'," \
                        "master_auto_position = 1; ".format(master_host=master_host,
                                                            master_port=master_port,
                                                            mysql_repl_user=mysql_repl_user,
                                                            master_password=master_password)
    sql_execute(sql_to_execute=change_master_sql,
                mysql_config_dict=mysql_config_dict)
    start_slave_sql = 'start slave ; '
    sql_execute(sql_to_execute=start_slave_sql,
                mysql_config_dict=mysql_config_dict)


def get_replication_user_psw(mysql_host, mysql_port, repl_user='repuser'):
    if replication_user_password is not None:
        return replication_user_password
    try:
        rep_user_password = get_mysql_password(mysql_host, mysql_port, mysql_host, user_name=repl_user)
        return rep_user_password
    except Exception:
        return default_rep_user_info


def set_super_read_only(mysql_config_dict):
    restore_instance_read_only(mysql_config_dict, super_read_only_status=1, read_only_status=1)


def replication_recover(**kwargs):
    mysql_config_dict = kwargs.get('mysql_config_dict')
    mysql_host = kwargs.get('mysql_host')
    mysql_port = kwargs.get('mysql_port')
    proxysql_config_dict = get_proxysql_connect_by_mysql(mysql_host=mysql_host, mysql_port=mysql_port)
    master_instance_info = get_master_instance_info(proxysql_config_dict=proxysql_config_dict)
    log.info("Now get the master instance of this cluster is : {master_instance_info}".format(
        master_instance_info=master_instance_info))
    master_host = master_instance_info.get('hostname')
    master_port = master_instance_info.get('port')
    if master_host == mysql_host and master_port == mysql_port:
        log.error('We now detect the instance is the same instance of the master instance , we do nothing here . ')
        return -1
    try:
        if mysql_replication_info_check(mysql_config_dict=mysql_config_dict):
            mysql_replication_change(mysql_config_dict=mysql_config_dict, master_host=master_host,
                                     master_port=master_port)
            return 0
        else:
            log.info('There is replication info in this mysql instance , Now we do nothing here . ')
            return 1
    except Exception:
        return -1


def proxysql_info_recovery(**kwargs):
    mysql_config_dict = kwargs.get('mysql_config_dict')
    mysql_servers_info_dict = kwargs.get('mysql_servers_info_dict')
    super_read_only_status_value, read_only_status_value = get_read_only_status(mysql_config_dict)
    if super_read_only_status_value != 'ON' or read_only_status_value != "ON":
        if recovery_set_read_only_force != 1:
            message_to_output = 'super_read_only and read_only is not all set to ON. Now exit. please check.'
            log.error(message_to_output)
            sys.exit(1)
        else:
            set_super_read_only(mysql_config_dict)
    replication_check_result = mysql_replication_delay_check(mysql_config_dict=mysql_config_dict)
    if replication_check_result is None or replication_check_result is False:
        return False
    mysql_servers_info_dict.update({"status": "ONLINE"})
    recovery_sql = convert_to_sql(table='mysql_servers', column_dict=mysql_servers_info_dict)
    mysql_host = mysql_config_dict.get('host')
    mysql_port = mysql_config_dict.get('port')
    proxysql_config_dict = get_proxysql_connect_by_mysql(mysql_host=mysql_host, mysql_port=mysql_port)

    load_servers_to_runtime = "LOAD MYSQL SERVERS TO RUNTIME;"
    save_servers_to_disk = "SAVE MYSQL SERVERS TO DISK;"

    sql_execute(sql_to_execute=recovery_sql, mysql_config_dict=proxysql_config_dict)
    sql_execute(sql_to_execute=load_servers_to_runtime, mysql_config_dict=proxysql_config_dict)
    sql_execute(sql_to_execute=save_servers_to_disk, mysql_config_dict=proxysql_config_dict)


def main():
    recovery_info = read_json(filename=recovery_info_file)
    mysql_info_in_proxysql = recovery_info.get("mysql_info_in_proxysql")
    mysql_servers_info_dict = mysql_info_in_proxysql[0]
    mysql_username = mysql_topology_user
    mysql_password = mysql_topology_password
    mysql_host = mysql_servers_info_dict.get('hostname')
    mysql_port = int(mysql_servers_info_dict.get('port'))
    mysql_config_dict = {
        "database_name": None, "host": mysql_host, "port": mysql_port,
        "username": mysql_username,
        "password": mysql_password,
    }
    if command == 'r':
        replication_recover(mysql_config_dict=mysql_config_dict, mysql_host=mysql_host, mysql_port=mysql_port)
    elif command == 'p':
        proxysql_info_recovery(mysql_config_dict=mysql_config_dict, mysql_servers_info_dict=mysql_servers_info_dict)
    elif command == 'a':
        replication_recover_result = replication_recover(mysql_config_dict=mysql_config_dict, mysql_host=mysql_host,
                                                         mysql_port=mysql_port)
        if replication_recover_result == 0:
            proxysql_info_recovery(mysql_config_dict=mysql_config_dict, mysql_servers_info_dict=mysql_servers_info_dict)
        else:
            log.error("Error occur while recovering the mysql replication . ")
    else:
        log.error("unknown command")
        sys.exit(1)


if __name__ == "__main__":
    sys.exit(main())
