import pymysql
import logging as log

def get_database_connect(**kwargs):
    database_name = kwargs.get("database_name")
    host = kwargs.get("host")
    username = kwargs.get("username")
    password = kwargs.get("password")
    port = kwargs.get("port")

    connect_db = pymysql.connect(host=host, port=port, user=username, passwd=password, db=database_name, charset='utf8')
    return connect_db

def sql_execute_without_close(sql_to_execute, mysql_config_dict):
    database_connect = get_database_connect(**mysql_config_dict)
    cursor = database_connect.cursor(cursor=pymysql.cursors.DictCursor)
    cursor.execute(sql_to_execute, )
    log.info("Now execute sql({sql_to_execute}) on : {host}:{port} ".format(sql_to_execute=sql_to_execute,
                                                                            host=mysql_config_dict.get('host'),
                                                                            port=mysql_config_dict.get('port')
                                                                            ))
    # database_connect.close()
    return database_connect


def sql_execute(sql_to_execute, mysql_config_dict):
    database_connect = get_database_connect(**mysql_config_dict)
    cursor = database_connect.cursor(cursor=pymysql.cursors.DictCursor)
    cursor.execute(sql_to_execute, )
    log.info("Now execute sql on : {host}:{port}".format(host=mysql_config_dict.get('host'), port=mysql_config_dict.get('port')))
    log.info("sql: {sql_to_execute}".format(sql_to_execute=sql_to_execute))
    execute_data = cursor.fetchall()
    log.debug("Result of sql : {result}".format(result=(str(execute_data))))
    database_connect.close()
    return execute_data

if __name__ == "__main__":
    # main()
    sql = """select * from  runtime_mysql_servers ;"""
    mysql_config_dict1 = {"database_name": None, "host": "172.29.29.31", "port": 6032, "password": "123456", "username": "cluster_admin"}
    data = sql_execute(sql_to_execute=sql, mysql_config_dict=mysql_config_dict1)
    print(data)
