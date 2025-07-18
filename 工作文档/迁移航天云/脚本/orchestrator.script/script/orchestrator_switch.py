import logging
import os
import sys
import argparse
import datetime
import time

basedir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, basedir)
GLOBAL_NOW_TIME = datetime.datetime.now().strftime("%Y%m%d_%H_%M_%S")

try:
    from .mysql_utils import sql_execute
    from .mysql_utils import get_proxysql_replication_info
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
    from mysql_utils import sql_execute
    from mysql_utils import get_proxysql_replication_info
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
    from .info_config import proxysql_wait_time
    from .info_config import proxysql_read_group_master
except Exception as e:
    from info_config import proxysql_wait_time
    from info_config import proxysql_read_group_master


parser = argparse.ArgumentParser(description='mysql backup command line .',
                                 usage=None,
                                 add_help=True)
parser.add_argument('--fail_host', '-fi', type=str, help='host of mysql fail instance', required=True)
parser.add_argument('--fail_port', '-fp', type=int, help='port of mysql fail instance', required=True)
parser.add_argument('--success_host', '-si', type=str, help='host of mysql success instance', required=True)
parser.add_argument('--success_port', '-sp', type=int, help='port of mysql success instance', required=True)
parser.add_argument('--command', '-c', type=str, help='command', required=False, nargs='?', const='')
args = parser.parse_args()
mysql_fail_host = args.fail_host
mysql_fail_port = args.fail_port
mysql_success_host = args.success_host
mysql_success_port = args.success_port
command = args.command

log = logging.getLogger(__name__)

if command == "graceful-master-takeover":
    log_dir = "{basedir}/log/graceful_takeover/".format(basedir=basedir)
    log_name = os.path.join(log_dir,"orchestrator_takeover_switch_processes-{now_time}.log".format(now_time=GLOBAL_NOW_TIME))
else:
    log_dir = "{basedir}/log/fail_over_log/".format(basedir=basedir)
    log_name = os.path.join(log_dir, "orchestrator_failover_switch_processes-{now_time}.log".format(now_time=GLOBAL_NOW_TIME))

if not os.path.exists(log_dir):
    os.makedirs(log_dir)

formatter = logging.basicConfig(filename=log_name,
                                level=logging.INFO,
                                format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                                datefmt='%a, %d %b %Y %H:%M:%S')


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

def proxysql_mysql_servers_info_backup(mysql_host, mysql_port, proxysql_config_dict):
    try:
        # now_time = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
        now_time = GLOBAL_NOW_TIME
        recovery_directory = "{basedir}/log/recovery_info/instance_backup_info_on_proxysql".format(basedir=basedir)
        if not os.path.exists(recovery_directory):
            os.makedirs(recovery_directory)
        filename = "{recovery_directory}/{mysql_host}-{mysql_port}-{now_time}.json".format(recovery_directory=recovery_directory, mysql_host=mysql_host, mysql_port=mysql_port, now_time=now_time)

        backup_dict_info_for_special_instance = "select * from mysql_servers where hostname = '{mysql_host}' and port={mysql_port} order by 1,2; ".format(mysql_host=mysql_host,mysql_port=mysql_port)
        mysql_servers_backup_info = sql_execute(sql_to_execute=backup_dict_info_for_special_instance, mysql_config_dict=proxysql_config_dict)
        write_json(filename=filename, json_to_write={"mysql_info_in_proxysql": mysql_servers_backup_info})
    except:
        log.error("Can't not backup proxysql information of instance: {mysql_host}:{mysql_port}".format(mysql_host=mysql_host, mysql_port=mysql_port))
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


def mysql_route_down(fail_host, fail_port, success_host, success_port):
    proxysql_config_dict = get_proxysql_connect_dict(fail_host,fail_port)
    proxysql_read_groupid, proxysql_write_groupid = get_proxysql_group_id()

    proxysql_mysql_servers_info_backup(mysql_host=fail_host, mysql_port=fail_port, proxysql_config_dict=proxysql_config_dict)
    mysql_servers_info,runtime_mysql_servers_info = proxysql_mysql_servers_info_get(proxysql_config_dict)
    proxysql_replication_info = get_proxysql_replication_info(proxysql_config_dict=proxysql_config_dict,read_group_id=proxysql_read_groupid,write_group_id=proxysql_write_groupid)

    if not proxysql_replication_info:
        ## 检测是否可以配置了mysql_replication_hostgroups，没有配置则手动添加读组
        insert_sql = """insert into mysql_servers(hostgroup_id,hostname,port,max_replication_lag,max_connections,status) values({write_group_id},'{success_host}',{success_port},10,4000,'ONLINE')""".format(
            success_host=success_host, success_port=success_port, write_group_id=proxysql_write_groupid)
        sql_execute(sql_to_execute=insert_sql, mysql_config_dict=proxysql_config_dict)

    if command == "graceful-master-takeover":
        ## 手动切换 删除write组 旧主库
        delete_sql = """delete from mysql_servers where hostname = '{fail_host}' and port = {fail_port} and hostgroup_id in ({write_group_id}) and status = 'OFFLINE_SOFT'; """.format(
            fail_host=fail_host, fail_port=fail_port, write_group_id=proxysql_write_groupid)
        sql_execute(sql_to_execute=delete_sql, mysql_config_dict=proxysql_config_dict)

        ## 插入read组 旧主库
        replace_sql = """replace into mysql_servers(hostgroup_id,hostname,port,max_replication_lag,max_connections,status) values({read_group_id},'{fail_host}',{fail_port},10,4000,'ONLINE')""".format(fail_host=fail_host, fail_port=fail_port, read_group_id=proxysql_read_groupid)
        sql_execute(sql_to_execute=replace_sql, mysql_config_dict=proxysql_config_dict)

    else:
        ## 故障切换删除所有的 offline 机器
        offline_sql = """delete from mysql_servers where hostname = '{fail_host}' and port = {fail_port} and hostgroup_id in ({read_group_id},{write_group_id}); """.format(
            fail_host=fail_host, fail_port=fail_port, read_group_id=proxysql_read_groupid, write_group_id=proxysql_write_groupid)
        sql_execute(sql_to_execute=offline_sql, mysql_config_dict=proxysql_config_dict)

    if proxysql_read_group_master == 0:
        # 是否将写组也加入读组
        offline_read_master_sql = """delete from mysql_servers where hostname = '{success_host}' and port = {success_port} and hostgroup_id in ({read_group_id}); """.format(
            success_port=success_port, success_host=success_host, read_group_id=proxysql_read_groupid)
        sql_execute(sql_to_execute=offline_read_master_sql, mysql_config_dict=proxysql_config_dict)

    load_to_runtime_sql = "LOAD MYSQL SERVERS TO RUNTIME;"
    sql_execute(sql_to_execute=load_to_runtime_sql, mysql_config_dict=proxysql_config_dict)

    load_to_disk_sql = "SAVE MYSQL SERVERS TO DISK;"
    sql_execute(sql_to_execute=load_to_disk_sql, mysql_config_dict=proxysql_config_dict)

    time.sleep(proxysql_wait_time * 2)
    now_mysql_servers_info,now_runtime_mysql_servers_info = proxysql_mysql_servers_info_get(proxysql_config_dict)
    cluster_info = proxysql_cluster_info(proxysql_config_dict)

    message = '原始mysql_servers信息: \nmysql_servers: \n{mysql_servers_info}\nruntime_mysql_servers:\n{runtime_mysql_servers_info}\n' \
              '当前mysql_servers信息: \nmysql_servers: \n{now_mysql_servers_info}\nruntime_mysql_servers:\n{now_runtime_mysql_servers_info}\n' \
              '当前proxysql cluster信息: \n{cluster_info}'.format( mysql_servers_info = message_format(mysql_servers_info,[0,1,2,4]),
                                                                   runtime_mysql_servers_info = message_format(runtime_mysql_servers_info,[0,1,2,4]),
                                                                   now_mysql_servers_info = message_format(now_mysql_servers_info,[0,1,2,4]),
                                                                   now_runtime_mysql_servers_info=message_format(now_runtime_mysql_servers_info,[0,1,2,4]),
                                                                   cluster_info=message_format(cluster_info,[0,1,2,8]))
    return message


def main():
    mysql_fail_host ='172.29.28.193'
    mysql_fail_port ='3308'
    mysql_success_host = '172.29.28.194'
    mysql_success_port = '3308'
    local_host_ip = get_host_ip()
    log.info("command is %s" % command)
    log.info("Fail instance info :{mysql_fail_host}:{mysql_fail_port}".format(mysql_fail_host=mysql_fail_host,
                                                                              mysql_fail_port=mysql_fail_port))

    try:
        msg = mysql_route_down(fail_host=mysql_fail_host, fail_port=mysql_fail_port, success_host=mysql_success_host,
                         success_port=mysql_success_port)

        subject = "Orchestrator 更新ProxySql成功 {command}：".format(command=command)
        message = "故障Mysql HOST: {mysql_fail_host}:{mysql_fail_port} ! \n" \
                  "变更Mysql HOST: {mysql_success_host}:{mysql_success_port} !\n" \
                  "执行变更 HOST : {local_host_ip}\n\n" \
                  "Now start the the proxysql failover process.\n" \
                  "Please check log on {local_host_ip}: \n{log_name} \n\n\n\n".format(
                            mysql_fail_host=mysql_fail_host,
                            mysql_fail_port=mysql_fail_port,
                            mysql_success_host=mysql_success_host,
                            mysql_success_port=mysql_success_port,
                            local_host_ip=local_host_ip,
                            log_name=log_name)

        message += '----------------------------------------------------------\n' + msg
        send_alert(subject, message)
        log.info('Orchestrator 更新ProxySql成功')
    except Exception as e:
        log.error('Orchestrator 更新ProxySql失败')
        send_alert('Orchestrator 更新ProxySql失败', str(e))
        raise e

if __name__ == "__main__":
    sys.exit(main())
