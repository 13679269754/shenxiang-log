import json
import logging as log
import urllib.request
import telnetlib
import sys

try:
    from urllib.parse import urlencode
    from urllib.request import Request, urlopen
except ImportError as e:
    from urllib.parse import urlencode
    from urllib.request import Request, urlopen

from qywechat_notify import send_msg
from info_config import proxysql_info

def message_format(body):
    try:
        # message = bytes.decode(body)
        message = str(body)
        # message1 = json.loads(message)
        message_eval = eval(message)
        for key, value in message_eval.items():
            if isinstance(value, bytes):
                message_eval.update({key: str(value, encoding="utf-8")})
        return message_eval
    except Exception as e:
        log.exception(str(e))
        return

def get_proxysql_host_info():
    '''
        获取proxysql信息
        :return: proxysql_host, proxysql_port
    '''
    proxysql_instance_list_info = proxysql_info
    if isinstance(proxysql_instance_list_info, dict) and len(proxysql_instance_list_info) > 0:
        proxysql_hosts = proxysql_instance_list_info.get("hosts")
        proxysql_port = proxysql_instance_list_info.get("admin_port")
        proxysql_host = None
        for host in proxysql_hosts:
            try:
                #  timeout单位s
                telnetlib.Telnet(host=host, port=proxysql_port, timeout=2)
                proxysql_host = host
                break
            except:
                log.warning("{host}:{port}  端口未开放".format(host = host,port = proxysql_port))
                continue
        return proxysql_host, proxysql_port
    else:
        return None, None

def get_proxysql_admin_password():
    '''
        获取proxysql密码
        :return: proxysql_password
    '''
    proxysql_instance_list_info = proxysql_info
    if isinstance(proxysql_instance_list_info, dict) and len(proxysql_instance_list_info) > 0:
        proxysql_username = proxysql_instance_list_info.get("admin_user")
        proxysql_password = proxysql_instance_list_info.get("admin_password")
        return proxysql_username,proxysql_password
    else:
        return None,None

def get_proxysql_group_id():
    proxysql_instance_list_info = proxysql_info
    if isinstance(proxysql_instance_list_info, dict) and len(proxysql_instance_list_info) > 0:
        proxysql_read_groupid = proxysql_instance_list_info.get("host_group_read_id")
        proxysql_write_groupid = proxysql_instance_list_info.get("host_group_write_id")
        return proxysql_read_groupid, proxysql_write_groupid
    else:
        return None, None


def get_proxysql_connect_dict(mysql_host, mysql_port):
    log.info("Now get the proxysql instance info.")
    proxysql_host, proxysql_port = get_proxysql_host_info()
    if proxysql_host is None or proxysql_port is None:
        log.error("Can't not find proxysql information of instance: {fail_host}:{fail_port}".format(fail_host=mysql_host,
                                                                                                    fail_port=mysql_port))
        sys.exit(1)
    log.info("Instance of proxysql :{proxysql_host}:{proxysql_port}".format(proxysql_host=proxysql_host, proxysql_port=proxysql_port))

    proxysql_username, proxysql_password = get_proxysql_admin_password()
    if proxysql_password is None or proxysql_username is None:
        log.error("Can't get password of proxysql instance: {proxysql_host}:{proxysql_port}".format(
            proxysql_host=proxysql_host, proxysql_port=proxysql_port))
        sys.exit(1)

    proxysql_config_dict = {
        "database_name": None,
        "host": proxysql_host,
        "port": proxysql_port,
        "password": proxysql_password,
        "username": proxysql_username
    }
    return proxysql_config_dict

def send_alert(subject, alert_message):
    '''
    发送告警
    :param subject: 告警标题
    :param alert_message: 告警内容
    :return: 告警结果
    '''
    Subject = subject
    Content = alert_message
    try:
        status = send_msg(Subject, Content)
    except Exception as e:
        status = -1
        print(e)
    return status

if __name__ == "__main__":
    proxysql_host, proxysql_port = get_proxysql_host_info()
    username, password = get_proxysql_admin_password()
    print(proxysql_host)
    print(proxysql_port)
    print(username)
    print(password)
    send_alert("Orchestrator 故障恢复：", "test")
