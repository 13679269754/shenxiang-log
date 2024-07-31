from .mysql_utils import sql_execute
from .mysql_utils import sql_execute_without_close
import logging as log


def set_proxysql_offline_soft(proxysql_config_dict, host, port):
    log.info("Now we set the demote master proxysql status to offline soft")
    set_offline_soft = "update mysql_servers set status = 'OFFLINE_SOFT' where hostname='{host}' and port = '{port}' and status = 'ONLINE'".format(host=host,port=port)
    sql_execute(sql_to_execute=set_offline_soft, mysql_config_dict=proxysql_config_dict)

    load_to_runtime_sql = "LOAD MYSQL SERVERS TO RUNTIME;"
    sql_execute(sql_to_execute=load_to_runtime_sql, mysql_config_dict=proxysql_config_dict)

    load_to_disk_sql = "SAVE MYSQL SERVERS TO DISK;"
    sql_execute(sql_to_execute=load_to_disk_sql, mysql_config_dict=proxysql_config_dict)


def restore_proxysql_offline_soft(proxysql_config_dict, host, port):
    log.info("Now we set the demote master proxysql status to online ")
    set_offline_soft = "update mysql_servers set status = 'ONLINE' where hostname='{host}' and port = '{port}' and status = 'OFFLINE_SOFT' ".format(host=host, port=port)
    sql_execute(sql_to_execute=set_offline_soft, mysql_config_dict=proxysql_config_dict)

    load_to_runtime_sql = "LOAD MYSQL SERVERS TO RUNTIME;"
    sql_execute(sql_to_execute=load_to_runtime_sql, mysql_config_dict=proxysql_config_dict)

    load_to_disk_sql = "SAVE MYSQL SERVERS TO DISK;"
    sql_execute(sql_to_execute=load_to_disk_sql, mysql_config_dict=proxysql_config_dict)


def get_proxysql_replication_info(proxysql_config_dict, read_group_id, write_group_id):
    log.info("Now we get runtime_mysql_replication_hostgroups")
    sql = "select * from runtime_mysql_replication_hostgroups where writer_hostgroup = {writer_hostgroup} and reader_hostgroup = {reader_hostgroup};".format(writer_hostgroup =read_group_id ,reader_hostgroup=write_group_id)
    data = sql_execute(sql_to_execute=sql, mysql_config_dict=proxysql_config_dict)
    if data:
        log.info("ProxySql will auto get read group")
        return True
    else:
        log.info("ProxySql will not auto get read group")
        return False
