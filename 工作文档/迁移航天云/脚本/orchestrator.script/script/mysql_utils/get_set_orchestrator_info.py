import os.path

import requests
import logging as log
import json
from urllib.parse import urljoin

def get_orchestrator_mysql_info(orchestrator_username, orchestrator_password, orchestrator_url, mysql_host, mysql_port):
    url =  urljoin(orchestrator_url,"/api/instance/{mysql_host}/{mysql_port}".format(mysql_host=mysql_host,mysql_port=str(mysql_port)))
    orchestrator_instance_info_types = requests.get(url, auth=(orchestrator_username, orchestrator_password)).content
    orchestrator_instance_info_str = str(orchestrator_instance_info_types, encoding="utf-8")
    orchestrator_instance_info = json.loads(orchestrator_instance_info_str)
    if isinstance(orchestrator_instance_info, dict):
        return orchestrator_instance_info
    return

def get_mysql_all_slave(orchestrator_username, orchestrator_password, orchestrator_url, mysql_host, mysql_port):
    orchestrator_instance_info = get_orchestrator_mysql_info(orchestrator_username, orchestrator_password, orchestrator_url, mysql_host, mysql_port)
    if isinstance(orchestrator_instance_info, dict):
        slave_list = orchestrator_instance_info.get('SlaveHosts')
        return slave_list
    return

if __name__ == '__main__':
    orchestrator_username = ''
    orchestrator_password = ''
    orchestrator_url = 'http://172.29.29.20:3000/'
    mysql_host = '172.29.29.32'
    mysql_port = 3306
    slave_list = get_mysql_all_slave(orchestrator_username,orchestrator_password,orchestrator_url,mysql_host,mysql_port)
    print(slave_list)

