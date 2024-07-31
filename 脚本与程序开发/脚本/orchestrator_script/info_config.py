proxysql_wait_time=3
proxysql_read_group_master=1
proxysql_info={
    'hosts':['172.29.28.195'],
    'admin_port':6032,
    'admin_user':'cluster_demo',
    'admin_password':'admin',
    'host_group_read_id':30,
    'host_group_write_id':10
}

mysql_topology_user='orchestrator'
mysql_topology_password='orchestrator'

check_transaction_option=1
retry_get_transaction=3
get_transaction_count_interval=3

compare_gtid=1
compare_gtid_type=1
gtid_check_time=3
gtid_check_interval=3

orchestrator_http_auth_user='Orchestrator'
orchestrator_http_auth_password='Orchestrator'
orchestrator_url='http://172.29.28.195:3000/'

