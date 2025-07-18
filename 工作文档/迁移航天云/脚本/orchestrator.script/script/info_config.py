proxysql_wait_time=3
proxysql_read_group_master=0
proxysql_info={
    'hosts':('171.29.28.193','172.29.28.194','172.29.28.195'),
    'admin_port':6032,
    'admin_user':'cluster_demo',
    'admin_password':'admin',
    'host_group_read_id':30,
    'host_group_write_id':10
}

mysql_topology_user='orchestrator'
mysql_topology_password='orch_backend_password'

check_transaction_option=1
retry_get_transaction=3
get_transaction_count_interval=3

compare_gtid=1
compare_gtid_type=1
gtid_check_time=3
gtid_check_interval=3

orchestrator_http_auth_user=''
orchestrator_http_auth_password=''
orchestrator_url='http://127.0.0.1:3000/'

