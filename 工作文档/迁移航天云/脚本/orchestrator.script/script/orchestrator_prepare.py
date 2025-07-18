import logging
import os
import sys
import argparse
import datetime

py_path = sys.executable
basedir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, basedir)
GLOBAL_NOW_TIME = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

try:
    from .get_config_info import send_alert
    from .os_utils import get_host_ip
except Exception:
    from get_config_info import send_alert
    from os_utils import get_host_ip

log = logging.getLogger(__name__)
log_dir = "{basedir}/log".format(basedir=basedir)
if not os.path.exists(log_dir):
    os.makedirs(log_dir)

log_name = os.path.join(log_dir,"execute.log")
formatter = logging.basicConfig(filename=log_name,
                                level=logging.INFO,
                                format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                                datefmt='%a, %d %b %Y %H:%M:%S')


parser = argparse.ArgumentParser(description='mysql backup command line .',
                                 usage=None,
                                 add_help=True)
parser.add_argument('--hook_name', '-hn', type=str, help='hook name', required=True)
parser.add_argument('--fail_host', '-fi', type=str, help='host of mysql fail instance', required=True)
parser.add_argument('--fail_port', '-fp', type=int, help='port of mysql fail instance', required=True)
parser.add_argument('--success_host', '-si', type=str, help='host of mysql success instance', required=False)
parser.add_argument('--success_port', '-sp', type=int, help='port of mysql success instance', required=False)
parser.add_argument('--command', '-c', type=str, help='command', required=False, nargs='?', const='')

args = parser.parse_args()
mysql_fail_host = args.fail_host
mysql_fail_port = args.fail_port
command = args.command
hook_name = args.hook_name
mysql_success_host = args.success_host
mysql_success_port = args.success_port

hook_dict={
    'PreGracefulTakeoverProcesses':{'subject':'Orchestrator Trace Full Takeover 准备','Description':'Start Orchestrator Prepare Grace Full Takeover','Send':0, 'Grace_full_send':1,'other_execute':'{py_path} {basedir}/orchestrator_graceful_switch.py'.format(py_path=py_path,basedir=basedir)},
    'OnFailureDetectionProcesses':{'subject':'Orchestrator 发现故障','Description':'Discover Orchestrator Failover','Send':1, 'Grace_full_send':0, 'other_execute':''},
    'PreFailoverProcesses':{'subject':'Orchestrator 开始故障恢复','Description':'Start Orchestrator Failover','Send':0, 'Grace_full_send':0, 'other_execute':''},
    'PostMasterFailoverProcesses':{'subject':'Orchestrator Master 故障恢复成功','Description':'Orchestrator Master Failover Success','Send':0, 'Grace_full_send':0, 'other_execute':'{py_path} {basedir}/orchestrator_switch.py'.format(py_path=py_path,basedir=basedir)},
    'PostFailoverProcesses':{'subject':'Orchestrator 故障恢复成功','Description':'Orchestrator Failover Success','Send':1, 'Grace_full_send':0, 'other_execute':'{py_path} {basedir}/orchestrator_check.py -ss 0'.format(py_path=py_path,basedir=basedir)},
    'PostGracefulTakeoverProcesses':{'subject':'Orchestrator Trace Full Takeover 成功','Description':'Orchestrator Grace Full Takeover Success','Send':0, 'Grace_full_send':1, 'other_execute':'{py_path} {basedir}/orchestrator_check.py -ss 1'.format(py_path=py_path,basedir=basedir)},
    'PostIntermediateMasterFailoverProcesses':{'subject':'Orchestrator 中间库故障恢复成功','Description':'Orchestrator Intermediate Master Failover Success','Send':0, 'Grace_full_send':0, 'other_execute':''},
    'PostUnsuccessfulFailoverProcesses':{'subject':'Orchestrator 故障转移失败','Description':'Orchestrator Failover False','Send':1, 'Grace_full_send':1, 'other_execute':''},
}

def create_send_msg():
    local_host_ip = get_host_ip()
    subject = hook_dict.get(hook_name).get('subject') + ' {command}:'.format(command=command)
    if mysql_success_host:
        message = "故障Mysql HOST: {mysql_fail_host}:{mysql_fail_port} ! \n"\
                  "变更Mysql HOST: {mysql_success_host}:{mysql_success_port} !\n"\
                  "执行变更  Hook: {hook_name} !\n"\
                  "执行变更  HOST: {local_host_ip}\n\n".format(
                       hook_name=hook_name,
                       mysql_fail_host=mysql_fail_host,
                       mysql_fail_port=mysql_fail_port,
                       mysql_success_host=mysql_success_host,
                       mysql_success_port=mysql_success_port,
                       local_host_ip=local_host_ip)
    else:
        message = "故障Mysql HOST: {mysql_fail_host}:{mysql_fail_port} ! \n" \
                  "执行变更  Hook: {hook_name} !\n"\
                  "执行变更  HOST: {local_host_ip}\n\n".format(
                        hook_name=hook_name,
                        mysql_fail_host=mysql_fail_host,
                        mysql_fail_port=mysql_fail_port,
                        local_host_ip=local_host_ip)
    return subject,message

def main():
    if command == "graceful-master-takeover":
        send = hook_dict.get(hook_name).get('Grace_full_send')
    else:
        send = hook_dict.get(hook_name).get('Send')

    Description = hook_dict.get(hook_name).get('Description')
    other_execute = hook_dict.get(hook_name).get('other_execute')
    log.info("Now {hook_name} {Description} : {mysql_fail_host}:{mysql_fail_port}  ===>  {mysql_success_host}:{mysql_success_port}".format(
            hook_name = hook_name,
            Description=Description,
            mysql_fail_host=mysql_fail_host,
            mysql_fail_port=mysql_fail_port,
            mysql_success_host=mysql_success_host,
            mysql_success_port=mysql_success_port))

    if send == 1:
        subject, message = create_send_msg()
        send_alert(subject,message)

    if other_execute:
        log.info("Now {hook_name} execute script: {script}".format(hook_name=hook_name,script=other_execute))
        status = os.system(other_execute + ' -fi {mysql_fail_host} -fp {mysql_fail_port} -si {mysql_success_host} -sp {mysql_success_port} -c {command}'.format(mysql_fail_host= mysql_fail_host,mysql_fail_port = mysql_fail_port,mysql_success_host = mysql_success_host,mysql_success_port = mysql_success_port,command= command))
        if status != 0:
            log.info("Now {hook_name} execute script failed".format(hook_name=hook_name))
            send_alert("Now {hook_name} execute script failed".format(hook_name=hook_name),"execute script name: {other_execute}".format(other_execute=other_execute))
            sys.exit(1)
        log.info("Now {hook_name} execute script successed".format(hook_name=hook_name))

if __name__ == '__main__':
    sys.exit(main())