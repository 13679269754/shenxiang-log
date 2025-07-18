#!/usr/bin/env python
# -*- coding:utf-8 -*-
import datetime
import nb_log
# 当前支持的服务列表,不要修改
service_list = ['mysql', 'proxysql', 'redis', 'mongodb', 'elasticsearch', 'postgresql']

##############################################
# 环境名称
cluster_name='CLUSTER_UAT'

# server-config
mysql_user='dzjroot'
mysql_pass='Dzj_pwd_2022'

proxysql_user='dzjroot'
proxysql_pass='Dzj_pwd_2022'

mongodb_user='dzjroot'
mongodb_pass='Dzj_pwd_2022'

postgresql_user='dzjroot'
postgresql_pass='Dzj_pwd_2022'

redis_pass='123456'

elasticsearch_user='elastic'
elasticsearch_pass='elastic'

neo4j_user='neo4j'
neo4j_pass='12345678'

influxdb_user='influxdb'
influxdb_pass='influxdb'

# 服务默认端口
default_port={
    'mysql':'3306',
    'redis':'6379',
    'elasticsearch':'9200',
    'proxysql':'6033',
    'postgresql':'5432',
    'mongodb':'27017',
    'neo4j':'7474',
    'influxdb':'8086',
    'redis_exporter':'9121',
    'elasticsearch_exporter':'9114'
}
##############################################


# date
date_time = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')

# rsync_server
rsync_host = '172.29.29.102'
rsync_user = 'sync_user'
rsync_pass = '123456'
rsync_module = 'pmm_script'
rsync_passwd_file = '/etc/rsyncd.passwd'

# path
local_package_path = '/usr/local/data/pmm/package/'
exporter_path = '/usr/local/data/pmm/exporter/'

# log_path
log_path = '/usr/local/data/pmm/log/'

# logger-config
logger = nb_log.get_logger('pmm_agent_manage',log_path=log_path,log_filename='pmm_agent_manage.log',error_log_filename='pmm_agent_manage_error.log')

# pmm_server
# pmm_user = 'shenxiang'
# pmm_pass = 'Sx1204180109'
pmm_user = 'admin'
pmm_pass = '123456'
pmm_server_address = '172.29.29.102'
pmm_server_port = '443'

# 执行成功后是否重置配置文件中有关服务密码的配置项目 1,是；0否
service_pass_reset = 1
# 是否在配置文件中保存加密后的密码 1,是；0,否
save_encrypted_pass = 0



