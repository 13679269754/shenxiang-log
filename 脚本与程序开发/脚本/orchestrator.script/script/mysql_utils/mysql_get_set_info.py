from .mysql_utils import sql_execute
from .mysql_utils import sql_execute_without_close
import logging as log



def set_instance_read_only(mysql_config_dict):
    log.info( "Now we set the demote master read_only to 1 , "
              "which to make sure the demote master can't write anything to maintain ")
    set_read_only_sql = "set global read_only = 1 ; "
    set_super_read_only_sql = "set global super_read_only = 1 ;"
    sql_execute(sql_to_execute=set_read_only_sql, mysql_config_dict=mysql_config_dict)
    sql_execute(sql_to_execute=set_super_read_only_sql, mysql_config_dict=mysql_config_dict)


def get_read_only_status(mysql_config_dict):
    get_super_read_only_sql = "show variables like 'super_read_only';"
    get_read_only = "show variables like 'read_only';"
    super_read_only_sql_status = sql_execute(sql_to_execute=get_super_read_only_sql, mysql_config_dict=mysql_config_dict)
    super_read_only_status_value = super_read_only_sql_status[0].get("Value")
    read_only_status = sql_execute(sql_to_execute=get_read_only, mysql_config_dict=mysql_config_dict)
    read_only_status_value = read_only_status[0].get("Value")
    return super_read_only_status_value, read_only_status_value


def restore_instance_read_only(mysql_config_dict, super_read_only_status, read_only_status):
    log.info("set global read_only and super_read_only to 0 . instance: {}".format(str(mysql_config_dict)))
    set_super_read_only_sql = "set global super_read_only = {super_read_only_status} ;".format(super_read_only_status=super_read_only_status)
    set_read_only_sql = "set global read_only = {read_only_status} ; ".format(read_only_status=read_only_status)
    sql_execute(sql_to_execute=set_read_only_sql, mysql_config_dict=mysql_config_dict)
    sql_execute(sql_to_execute=set_super_read_only_sql, mysql_config_dict=mysql_config_dict)


def get_transaction_from_meta(mysql_config_dict):
    log.info("Now we get the trancation")
    get_transaction_sql = """SELECT p.id ,p.User ,p.db , p.Host , p.time ,  p.state , p.info, trx_state ,trx_started   
    from information_schema.INNODB_TRX it, information_schema.PROCESSLIST p 
    where it.trx_mysql_thread_id = p.ID ; """
    transaction_result = sql_execute(sql_to_execute=get_transaction_sql, mysql_config_dict=mysql_config_dict)
    return transaction_result


def get_mysql_gtid(mysql_config_dict):
    get_mysql_gtid_sql = "show master status ; "
    mysql_master_status = sql_execute(sql_to_execute=get_mysql_gtid_sql, mysql_config_dict=mysql_config_dict)
    mysql_gtid_set = mysql_master_status[0].get('Executed_Gtid_Set')
    return mysql_gtid_set

