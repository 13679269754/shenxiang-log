"""
######################################################################
##  Mysql 数据库自动还原脚本
##  前提条件：
##      1. 安装 Python 环境
##      2. 安装 Mysql 软件
##      3. 安全 qpress 软件
##         pip3 install paramiko
##         pip3 install colorlog
##
######################################################################
"""

import re,os,time,pwd,shutil
import argparse
import sys
import logging
import functools
import paramiko
import stat
import datetime
import random
import calendar
import pymysql
import traceback


######################################  定义参数 ##########################################
# 源备份文件
source_backup_dir='/usr/local/data/mysql_backup'
source_backup_host='172.29.29.41'
source_backup_user='root'
source_backup_passwd='dzj123,./'

# 目标备份文件
target_backup_dir='/usr/local/data/mysql_backup/mysql_target'

# 恢复目录
mysql_base_dir='/usr/local/data/mysql8023'
restore_base_dir='/usr/local/data/mysql_data/mysql_restore_data'


# 常用变量
mysql_restore_osuser='mysql'
mysql_restore_port=3206
change_port = 3406
log_level = logging.INFO
paraller = 4
log_dir=restore_base_dir

print_error_line = 0
auto_start=1
auto_switch=1

# 传递参数
run_type=-1
loop_type=-1
excute_day=''
restore_date=''
mysql_dir = ''
######################################  定义参数 ##########################################


# 创建ArgumentParser对象
parser = argparse.ArgumentParser(description='自动恢复脚本',
                                 epilog="以上便是如何使用 自动恢复脚本",
                                 formatter_class=argparse.RawTextHelpFormatter,)

# 添加互斥组
group = parser.add_mutually_exclusive_group()
# 给互斥组添加两个参数
# 给参数的action属性赋值store_true，程序默认为false,当你执行这个命令的时候，默认值被激活成True
group.add_argument('-r', '--restore', action='store_true', help='执行备份恢复并切换环境')
group.add_argument('-d', '--delete', action='store_true', help='手动删除过期备份')
group.add_argument('-i', '--init', action='store_true', help='手动启动备份数据库')
group.add_argument('-s', '--switch', action='store_true', help='手动切换备份数据库')


# 添加命令行参数
parser.add_argument("-l",
                    "--loop_type",
                    type=int,
                    metavar='int',
                    help="""执行周期：\n1  每月恢复1号前一天数据 excute_day 指定执行时间(每月第几天)  \n2  每周恢复上周日数据    excute_day 指定执行时间(每周第几天) \n3  每天恢复前一天数据    excute_day 为0 代表每天都执行 大于0 代表每月几号执行 \n4  每天恢复前一天数据    excute_day 为0 代表每天都执行 大于0 代表每周周几执行  \n11 模糊指定备份 \n12 精准指定备份"""
                    )
parser.add_argument("-c","--excute_day", type=str, metavar='str',help="""指定执行时间（多次指定以逗号分割）""")
parser.add_argument("-t","--restore_date", type=str, metavar='str',help="""需要恢复或删除的备份日期(格式：20230101 或者 备份目录全名)""")
parser.add_argument("-m","--mysql_dir", type=str, metavar='str', help="""启动备份 Mysql 时的 Mysql Base 目录（conf目录上一级）""")

parser.add_argument("-v","--version", action='version',version='%(prog)s 2.0')



# 解析命令行参数
args = parser.parse_args()

# 根据参数值判断其他参数必要性
if args.switch:
    run_type = 4
elif args.init:
    run_type = 3
    if not args.mysql_dir:
        parser.error('指定 --init 时，-m|--mysql_dir 参数是必需的')
    else:
        mysql_dir = args.mysql_dir
elif args.delete:
    run_type = 2
    if not args.restore_date:
        parser.error('指定 --delete 时，-t|--restore_date 参数是必需的')
    else:
        restore_date = args.restore_date
elif args.restore:
    run_type = 1
    if not args.loop_type:
        parser.error('指定 --restore 时，-l|--loop_type 参数是必需的')
    else:

        loop_type = args.loop_type
        if loop_type not in [1,2,3,4,11,12]:
            parser.error('请查看 -l|--loop_type 帮助文档')


    if loop_type in [11,12]:
        if not args.restore_date:
            parser.error('指定 --restore 时，-t|--restore_date 参数是必需的')
        else:
            restore_date = args.restore_date
    else:
        if not args.excute_day:
            parser.error('指定 --restore 时，-c|--excute_day 参数是必需的')
        else:
            excute_day = args.excute_day

if not args.switch and not args.delete and not args.init and not args.restore:
    parser.error('指定 --switch|--delete|--init|--restore 参数是必需的')


print('run_type:     ' + str(run_type))
print('loop_type:    ' + str(loop_type))
print('excute_day:   ' + excute_day)
print('restore_date: ' + restore_date)
print('mysql_dir:    ' + mysql_dir)

current_min = datetime.datetime.now().strftime("%Y-%m-%d_%H%M")
current_day = datetime.datetime.now().strftime("%Y%m%d")


global logger
def set_logger(log_dir):

    # 定义日志格式
    try:
        import colorlog
        # 创建彩色日志格式
        formatter = colorlog.ColoredFormatter(
            '%(log_color)s%(asctime)s - %(filename)s[line:%(lineno)d] - %(levelname)s: %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S',
            log_colors={
                'DEBUG': 'cyan',
                'INFO': 'green',
                'WARNING': 'yellow',
                'ERROR': 'red',
                'CRITICAL': 'red,bg_white',
            }
        )
    except:
        formatter = logging.Formatter('%(asctime)s - %(filename)s[line:%(lineno)d] - %(levelname)s: %(message)s',datefmt='%Y-%m-%d %H:%M:%S')

    # 创建Logger对象
    logger = logging.getLogger()
    logger.setLevel(log_level)
    log_file = os.path.join(log_dir,f'mysql_auto_restore_{current_day}.log')
    # 创建文件处理器
    file_handler = logging.FileHandler(log_file)
    file_handler.setLevel(log_level)

    # 创建终端处理器
    console_handler = logging.StreamHandler()
    console_handler.setLevel(log_level)

    # 设置处理器的格式
    file_handler.setFormatter(formatter)
    console_handler.setFormatter(formatter)

    # 将处理器添加到Logger对象
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)

def log_decorator(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        logging.info(f"Calling function {func.__name__}")
        logging.info(f"{func.__doc__}".strip())
        try:
            result = func(*args, **kwargs)
        except Exception as e:
            logging.error(f"Function {func.__name__} executed failed")
            logging.error(f"{e}")
            if print_error_line:
                traceback.print_exc()
            sys.exit(0)
        logging.info(f"Function {func.__name__} executed successfully")
        return result
    return wrapper

@log_decorator
def create_restore_dir(restore_dir,restore_date):
    """
    创建恢复目录
    """
    restore_db_dir = os.path.join(restore_dir, f"{current_min}_{datetime.datetime.strptime(restore_date,'%Y%m%d').strftime('%Y-%m-%d')}",'dbmysql')
    restore_db_dir_dict={
        'restore_db_dir' : restore_db_dir,
        'restore_db_log_dir': os.path.join(restore_db_dir,'log'),
        'restore_db_conf_dir': os.path.join(restore_db_dir,'conf'),
        'restore_db_tmp_dir': os.path.join(restore_db_dir,'tmp'),
        'restore_db_run_dir': os.path.join(restore_db_dir,'run'),
        'restore_db_data_dir': os.path.join(restore_db_dir,'data'),
    }

    if not os.path.exists(restore_db_dir):
        os.makedirs(restore_db_dir_dict['restore_db_dir'])
        os.makedirs(restore_db_dir_dict['restore_db_log_dir'])
        os.makedirs(restore_db_dir_dict['restore_db_conf_dir'])
        os.makedirs(restore_db_dir_dict['restore_db_tmp_dir'])
        os.makedirs(restore_db_dir_dict['restore_db_run_dir'])
        os.makedirs(restore_db_dir_dict['restore_db_data_dir'])
        logging.info(f'创建恢复目录 {restore_db_dir} 成功')

    else:
        raise Exception(f'创建恢复目录 {restore_db_dir} 失败，请检查目录是否已经存在')

    return restore_db_dir_dict


def get_restore_date():
    "获取需要恢复的备份日期 type : 1 每月恢复1号前一天 excute_day指定执行时间  2 每周恢复 excute_day指定执行时间 3 每天恢复前一天 excute_day 为0 代表每天都执行 大于0 代表每月几号执行 4 每天恢复前一天 excute_day 为0 代表每天都执行 大于0 代表每月周几执行  11 模糊指定备份 12 精准指定备份"
    if loop_type in (11,12):
        return restore_date

    # 获取当前日期和时间
    now = datetime.datetime.now()
    # 获取当前日期的年份和月份
    year = now.year
    month = now.month
    day = now.day
    weekday = now.weekday() + 1

    # 获取该月的最后一天
    last_day = calendar.monthrange(year, month)[1]
    excute_day_list = [min(int(i), last_day) for i in excute_day.split(',')]


    if loop_type == 1:
        # 获取当前时间的每个月的1号
        first_of_month = now.replace(day=1) - datetime.timedelta(days=1)
        if day in excute_day_list:
            return first_of_month.strftime('%Y%m%d')
        else:
            return False

    if loop_type == 2:
        # 获取当前时间的每周的星期天
        sunday = now - datetime.timedelta(days=now.weekday()) - datetime.timedelta(days=1)
        if day in excute_day_list:
            return sunday.strftime('%Y%m%d')
        else:
            return False

    if loop_type == 3:
        if 0 in excute_day_list:
            yestorday = now - datetime.timedelta(days=1)
            return yestorday.strftime('%Y%m%d')
        else:
            if day in excute_day_list:
                yestorday = now - datetime.timedelta(days=1)
                return yestorday.strftime('%Y%m%d')
            else:
                return False

    if loop_type == 4:
        excute_day_list = [min(int(i), 7) for i in excute_day.split(',')]
        if 0 in excute_day_list:
            yestorday = now - datetime.timedelta(days=1)
            return yestorday.strftime('%Y%m%d')
        else:
            if weekday in excute_day_list:
                yestorday = now - datetime.timedelta(days=1)
                return yestorday.strftime('%Y%m%d')
            else:
                return False




def get_all_files_in_remote_dir(sftp, remote_dir):
    """
    获取远端linux主机上指定目录及其子目录下的所有文件
    """
    # 保存所有文件的列表
    all_files = list()

    # 去掉路径字符串最后的字符'/'，如果有的话
    if remote_dir[-1] == '/':
        remote_dir = remote_dir[0:-1]
        print(remote_dir)

    # 获取当前指定目录下的所有目录及文件，包含属性值
    files = sftp.listdir_attr(remote_dir)
    for x in files:
        # remote_dir目录中每一个文件或目录的完整路径
        filename = remote_dir + '/' + x.filename
        # 如果是目录，则递归处理该目录，这里用到了stat库中的S_ISDIR方法，与linux中的宏的名字完全一致
        if stat.S_ISDIR(x.st_mode):
            all_files.extend(get_all_files_in_remote_dir(sftp, filename))
        else:
            all_files.append(filename)
    return all_files

@log_decorator
def sync_backup_file(source_dir,source_user,source_host,source_passwd,target_dir,restore_date):
    """
    传递备份文件
    """
    # 创建ssh访问
    try:
        ssh = paramiko.SSHClient()
        ssh.load_system_host_keys()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())  # 允许连接不在know_hosts文件中的主机
        ssh.connect(source_host, port=22, username=source_user, password=source_passwd)  # 远程访问的服务器信息

        filedir_name_cmd = f"ls -afl {source_dir}| grep {restore_date} | sort | tail -n 1 |awk ' {{print $9}}'"
        stdin, stdout, stderr = ssh.exec_command(filedir_name_cmd)
        if stderr.read().decode('utf-8').strip():
            ssh.close()
            raise Exception(f"源备份文件查询失败，请检查相关语句：{filedir_name_cmd}\n{stderr.read().decode('utf-8').strip()}")
        else:
            source_file_name = stdout.read().decode('utf-8').strip()



        if source_file_name:
            logging.info(f"源备份文件查询为 {source_file_name}")
            source_file_dir = os.path.join(source_dir, source_file_name)
            target_file_dir = os.path.join(target_dir, source_file_name)

            if target_file_dir[-1] == '/':
                target_file_dir = target_file_dir[0:-1]

            if not os.path.exists(target_file_dir):
                os.makedirs(target_file_dir)

            target_file_time = datetime.datetime.strptime(target_file_dir.split('/')[-1],'%Y%m%d_%H_%M_%S').strftime('%Y-%m-%d_%H_%M_%S')

            if not os.path.exists(os.path.join(target_file_dir,'Sync_Successed.txt')):

                logging.info(f"需要传输的源备份目录：{source_file_dir}")
                logging.info(f"需要传输的目标备份目录：{target_file_dir}")
                try:
                    # 创建scp,下载文件
                    sftp = paramiko.SFTPClient.from_transport(ssh.get_transport())
                    all_files = get_all_files_in_remote_dir(sftp, source_file_dir)

                    # 依次get每一个文件
                    for x in all_files:
                        filename = x.replace(source_file_dir,'')
                        target_filename = target_file_dir + filename

                        dir = os.path.dirname(target_filename)
                        if not os.path.exists(dir):
                            os.makedirs(dir, exist_ok=False)
                        logging.info(f'Get文件 {x} 传输至 {target_filename} ...')
                        sftp.get(x, target_filename)

                    with open(os.path.join(target_file_dir,'Sync_Successed.txt'),'w') as f:
                        f.write('sync successed')
                except Exception as e:
                    raise e
                finally:
                    sftp.close()
                    ssh.close()
            else:
                logging.warning(f"源备份目录：{source_file_dir} 已经传输成功，不需要重新传输")
            ssh.close()
            return os.path.join(target_file_dir, target_file_time)
        else:
            logging.warning("未查询到源备份文件....")
            sys.exit(0)
    except Exception as e:
        raise e
    finally:
        ssh.close()


@log_decorator
def restore_decompress_db(target_backup_dir):
    decompress_log_file = os.path.join(target_backup_dir, 'backup_decompress.log')
    uncompress_cmd = f"xtrabackup --decompress --parallel={paraller} --target-dir={target_backup_dir} 2> {decompress_log_file}"

    if os.path.exists(decompress_log_file):
        with open(decompress_log_file, 'r') as f:
            lines =  f.readlines()
            if lines:
                last_line = lines[-1].strip()
            else:
                last_line = 'Failed'

        if re.search('completed OK',last_line):
            logging.warning("decompress 已经执行成果，无需再次执行")
            execute_code = 0
        else:
            execute_code = 1
    else:
        execute_code = 1


    if execute_code == 1:
        logging.info(f"开始执行 decompress 脚本：{uncompress_cmd}")
        exit_code  = os.system(uncompress_cmd)

        with open(decompress_log_file, 'r') as f:
            lines =  f.readlines()
            if lines:
                last_line = lines[-1].strip()
            else:
                last_line = 'Failed'

        if exit_code > 0 or not re.search('completed OK', last_line):
            raise Exception(f"执行 decompress 脚本错误：{uncompress_cmd}")
        logging.info(f"执行 decompress 脚本完成")

@log_decorator
def restore_prepare_db(target_backup_dir):

    prepare_log_file = os.path.join(target_backup_dir, 'backup_prepare.log')
    prepare_cmd = f"xtrabackup --prepare --target-dir={target_backup_dir} 2> {prepare_log_file}"

    if os.path.exists(prepare_log_file):
        with open(prepare_log_file, 'r') as f:
            lines = f.readlines()
            if lines:
                last_line = lines[-1].strip()
            else:
                last_line = 'Failed'

        if re.search('completed OK', last_line):
            logging.warning("prepare 已经执行成果，无需再次执行")
            execute_code = 0
        else:
            execute_code = 1
    else:
        execute_code = 1

    if execute_code == 1:
        logging.info(f"开始执行 prepare 脚本：{prepare_cmd}")
        exit_code = os.system(prepare_cmd)

        with open(prepare_log_file, 'r') as f:
            lines =  f.readlines()
            if lines:
                last_line = lines[-1].strip()
            else:
                last_line = 'Failed'

        if exit_code > 0 or not re.search('completed OK', last_line):
            raise Exception(f"执行 prepare 脚本错误：{prepare_cmd}")
        logging.info(f"执行 prepare 脚本完成")

@log_decorator
def restore_copyback_db(restore_db_dir_dict, target_backup_dir):
    copyback_log_file = os.path.join(restore_db_dir_dict['restore_db_dir'], 'backup_copy_back.log')
    copy_back_cmd = f"xtrabackup --defaults-file={os.path.join(restore_db_dir_dict['restore_db_conf_dir'], f'my.cnf')} --copy-back --target-dir={target_backup_dir} 2> {copyback_log_file}"
    logging.info(f"开始执行 copyback 脚本：{copy_back_cmd}")
    exit_code = os.system(copy_back_cmd)

    with open(copyback_log_file, 'r') as f:
        lines = f.readlines()
        if lines:
            last_line = lines[-1].strip()
        else:
            last_line = 'Failed'

    if exit_code > 0 or not re.search('completed OK', last_line):
        raise Exception(f"执行 copyback 脚本错误：{copy_back_cmd}")
    logging.info(f"执行 copyback 脚本完成")

    logging.info(f"更改目录权限组")
    os.system(f"chown -R {mysql_restore_osuser}. {restore_db_dir_dict['restore_db_dir']}")

@log_decorator
def start_restore_mysql(restore_db_dir):
    "启动 restore mysql 并修改用户密码"

    restore_process_info_socket, restore_process_info_cnf = get_mysql_socket_by_port(mysql_restore_port)
    if not restore_process_info_socket == None:
        raise Exception(f"Mysql 端口 {mysql_restore_port} 存在")

    start_cmd = f"{mysql_base_dir}/bin/mysqld_safe --defaults-file={os.path.join(restore_db_dir,'conf')}/my.cnf --user={mysql_restore_osuser} &2>&1 > /dev/null"

    if not os.path.exists(f"{os.path.join(restore_db_dir,'log')}/alert.log"):
        touch_alert_log_cmd =f"touch {os.path.join(restore_db_dir,'log')}/alert.log && chown -R {mysql_restore_osuser}. {os.path.join(restore_db_dir,'log')}"

        exec_code = os.system(touch_alert_log_cmd)
        if exec_code > 0:
            raise Exception(f"创建 restore mysql alert.log 失败")

    exec_code = os.system(start_cmd)
    if exec_code > 0:
        raise Exception(f"启动 restore mysql 失败")

    time.sleep(10)

    retry_count = 1
    # 创建一个MySQL连接
    while True:
        try:
            connection = pymysql.connect(
                unix_socket=f"{os.path.join(restore_db_dir,'run')}/mysql{mysql_restore_port}.sock",
                user='root',
                password=''
            )
            logging.warning(f"重试数据库连接第 {retry_count} 次成功")
            break
        except:
            logging.warning(f"重试数据库连接第 {retry_count} 次失败")

        if retry_count <= 3:
            retry_count = retry_count + 1
            time.sleep(10)
            continue
        else:
            raise Exception(f"数据库连接失败")

    # 创建一个游标对象
    cursor = connection.cursor()

    # 执行SQL查询
    cursor.execute("""SELECT CONCAT('alter user ',USER,'@','''',HOST,'''',' identified by ''','dzj_',USER,'_pwd''') FROM mysql.user WHERE USER NOT IN ('mysql.infoschema','mysql.session','mysql.sys','root')""")

    # 获取查询结果
    result = cursor.fetchall()

    # 打印查询结果
    for row in result:
        cursor.execute(row[0])

    # 关闭游标和连接
    cursor.close()
    connection.close()


import psutil

@log_decorator
def get_mysql_socket_by_port(port):
    for proc in psutil.process_iter(['pid', 'name']):
        try:
            conn = proc.connections()
            for c in conn:
                if c.status == 'LISTEN' and c.laddr.port == port:
                    pid = proc.info['pid']
                    proc = psutil.Process(pid)
                    cmdline = proc.cmdline()
                    socket_file = None
                    cnf_file = None
                    for arg in cmdline:
                        match = re.search(r'--socket=(.*)', arg)
                        if match:
                            socket_file = match.group(1)

                        match = re.search(r'--defaults-file=(.*)', arg)
                        if match:
                            cnf_file = match.group(1)
                    logging.info(f"Mysql {port} cnf文件目录：{cnf_file}")
                    logging.info(f"Mysql {port} socket文件目录：{socket_file}")
                    return socket_file,cnf_file
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass

    return None,None

@log_decorator
def switch_restore_mysql(new_port):


    # 根据端口获取进程信息
    if change_port:
        old_process_info_socket,old_process_info_cnf = get_mysql_socket_by_port(change_port)
        if not old_process_info_socket == None:
            shutdown_cmd = f'{mysql_base_dir}/bin/mysql -S {old_process_info_socket} -e "shutdown;"'
            exec_code = os.system(shutdown_cmd)
            if exec_code > 0:
                raise Exception(f"关闭 Mysql 端口 {change_port} 失败，socket文件: {old_process_info_socket}")
            logging.info(f"关闭 Mysql 端口 {change_port} 成功，socket文件: {old_process_info_socket}")
        else:
            logging.warning(f"Mysql 端口 {change_port} 不存在")


    new_process_info_socket,new_process_info_cnf = get_mysql_socket_by_port(new_port)
    if not new_process_info_socket == None:
        sed_cmd = f'sed -i s/{new_port}/{change_port}/g {new_process_info_cnf}'
        exec_code = os.system(sed_cmd)
        if exec_code > 0:
            raise Exception(f"restore mysql {new_process_info_cnf} 替换端口失败")
        logging.info(f"restore mysql {new_process_info_cnf} 替换端口成功")

        shutdown_cmd = f'{mysql_base_dir}/bin/mysql -S {new_process_info_socket} -e "shutdown;"'
        exec_code = os.system(shutdown_cmd)
        if exec_code > 0:
            raise Exception(f"关闭 mysql端口 {new_port} 失败，socket文件: {new_process_info_socket}")
        logging.info(f"关闭 mysql端口 {new_port} 成功，socket文件: {new_process_info_socket}")
        time.sleep(10)

        start_cmd = f"{mysql_base_dir}/bin/mysqld_safe --defaults-file={new_process_info_cnf} --user={mysql_restore_osuser} &2>&1 > /dev/null"
        exec_code = os.system(start_cmd)
        if exec_code > 0:
            raise Exception(f"启动 restore mysql {change_port} 失败")
        logging.info(f"启动 restore mysql {change_port} 成功")
    else:
        raise Exception(f"Mysql 端口 {new_port} 不存在，请检查")

@log_decorator
def delete_backup_dir(delete_date,target_backup_dir):
    dir_list = os.listdir(target_backup_dir)
    for i in dir_list:
        dir_date = i.split('_')[0]
        if int(dir_date) < int(delete_date):
            delete_dir = os.path.join(target_backup_dir,i)
            logging.warning(f'开始删除 {delete_dir} .....')
            shutil.rmtree(delete_dir)

def run():
    set_logger(log_dir)
    if run_type == 1:
        restore_cur_date = get_restore_date()
        if restore_cur_date:
            logging.info(f"当前时间符合恢复策略,开始恢复 {restore_cur_date} 的备份")
            restore_db_dir_dict = create_restore_dir(restore_base_dir,restore_cur_date)
            create_conf(conf_tmp,mysql_restore_port,restore_db_dir_dict['restore_db_dir'],mysql_base_dir)
            backup_dir = sync_backup_file(source_backup_dir,source_backup_user,source_backup_host,source_backup_passwd,target_backup_dir,restore_cur_date)
            restore_decompress_db(backup_dir)
            restore_prepare_db(backup_dir)
            restore_copyback_db(restore_db_dir_dict, backup_dir)
            if loop_type not in [11,12]:
                delete_backup_dir(restore_cur_date,target_backup_dir)

            if auto_start:
                start_restore_mysql(restore_db_dir_dict['restore_db_dir'])

            if auto_switch:
                switch_restore_mysql(mysql_restore_port)
        else:
            logging.warning("当前时间不符合恢复策略")
    elif run_type == 2:
        logging.info(f"手动清理无用备份：备份日期小于 {restore_date} 则全部被清除")
        delete_backup_dir(restore_date, target_backup_dir)
    elif run_type == 3:
        logging.info(f"手动启动已恢复备份")
        if mysql_dir:
            start_restore_mysql(mysql_dir)
        else:
            logging.error(f"请检查 {mysql_dir} 目录是否存在")
    elif run_type == 4:
        logging.info(f"手动切换环境")
        switch_restore_mysql(mysql_restore_port)

conf_tmp="""
[mysqld_safe]
pid-file=/usr/local/data/mysql_data/db3106/run/mysqld3106.pid

[mysql]
port=3106
prompt=\\u@\\d \\r:\\m:\\s>
default-character-set=utf8mb4
no-auto-rehash

[client]
port=3106
socket=/usr/local/data/mysql_data/db3106/run/mysql3106.sock
default_character_set=utf8mb4

[mysqld]
#####dir#####
basedir=/usr/local/data/mysql
lc_messages_dir=/usr/local/data/mysql/share
datadir=/usr/local/data/mysql_data/db3106/data/
tmpdir=/tmp
socket=/usr/local/data/mysql_data/db3106/run/mysql3106.sock

#####log#####
log-error=/usr/local/data/mysql_data/db3106/log/alert.log
slow_query_log_file=/usr/local/data/mysql_data/db3106/log/slow.log
general_log_file=/usr/local/data/mysql_data/db3106/log/general.log
slow_query_log=1
long_query_time=1
log_slow_admin_statements=1
general_log=0
log_error_verbosity=2

#####binlog#####
log-bin=/usr/local/data/mysql_data/db3106/log/mysql-bin
binlog_cache_size=64M
max_binlog_cache_size=2G
max_binlog_size=512M
binlog-format=ROW
sync_binlog=100
log-slave-updates=1
expire_logs_days=7

#####innodb#####
#server
default_authentication_plugin=mysql_native_password
default-storage-engine=INNODB
character-set-server=utf8mb4
transaction-isolation=READ-COMMITTED
innodb_rollback_on_timeout=0
lower_case_table_names=1
local-infile=1
open_files_limit=65535
safe-user-create
explicit_defaults_for_timestamp=true

innodb_open_files=60000
innodb_file_per_table=1
innodb_flush_method=O_DIRECT
innodb_change_buffering=inserts
innodb_adaptive_flushing=1
innodb_old_blocks_time=1000
innodb_stats_on_metadata=0
innodb_use_native_aio=0
innodb_strict_mode=1

innodb_data_home_dir=/usr/local/data/mysql_data/db3106/data
innodb_data_file_path=ibdata1:16M;ibdata2:16M:autoextend


#performance
performance_schema=1

#redo
innodb_log_group_home_dir=/usr/local/data/mysql_data/db3106/data
innodb_log_files_in_group=3
innodb_log_file_size=512M
innodb_log_buffer_size=20M
innodb_flush_log_at_trx_commit=1

#undo
innodb_undo_directory=/usr/local/data/mysql_data/db3106/data
innodb_undo_tablespaces=4
innodb_max_undo_log_size=800M
innodb_undo_log_truncate=1

#lock
innodb_lock_wait_timeout=5
innodb_print_all_deadlocks=1
skip-external-locking


#buffer
innodb_buffer_pool_size=1G
innodb_buffer_pool_instances=4
innodb_max_dirty_pages_pct=60
innodb_read_ahead_threshold=64

table_definition_cache=65536
thread_stack=512K
thread_cache_size=256
read_rnd_buffer_size=128K
sort_buffer_size=256K
join_buffer_size=128K
read_buffer_size=128K
max_heap_table_size=128M
key_buffer_size=128M      
tmp_table_size=128M

#thread
innodb_io_capacity=4000
innodb_thread_concurrency=16
innodb_read_io_threads=16
innodb_write_io_threads=16
innodb_purge_threads=1

max_connections=4500
max_user_connections=4000
max_connect_errors=10000
max_allowed_packet=128M
connect_timeout=8
net_read_timeout=30
net_write_timeout=60

#####myisam#####
myisam_sort_buffer_size=64M
concurrent_insert=2
delayed_insert_timeout=300

#####replication#####
master-info-file=/usr/local/data/mysql_data/db3106/log/master.info
relay-log=/usr/local/data/mysql_data/db3106/log/relaylog
relay_log_info_file=/usr/local/data/mysql_data/db3106/log/relay-log.info
relay-log-index=/usr/local/data/mysql_data/db3106/log/mysqld-relay-bin.index
slave_load_tmpdir=/usr/local/data/mysql_data/db3106/tmp
slave_type_conversions="ALL_NON_LOSSY"
slave_net_timeout=4
skip-slave-start
sync_master_info=1000
sync_relay_log_info=1000
relay_log_recovery=1
relay_log_purge=1

#####gtid#####
gtid_mode=on
enforce_gtid_consistency=on

#####other#####
port=3106
back_log=1024
skip-name-resolve
skip-ssl
#read_only=1
"""

@log_decorator
def create_conf(conf_tmp,dbport,restore_dir,server_dir):
    """生成 Mysql 配置文件"""
    conf_file = os.path.join(restore_dir,f'conf/my.cnf')
    with open(conf_file,'w') as f:
        f.write(conf_tmp.replace('basedir=/usr/local/data/mysql',f'basedir={server_dir}')
                .replace('lc_messages_dir=/usr/local/data/mysql/share',f'lc_messages_dir={server_dir}/share')
                .replace('/usr/local/data/mysql_data/db3106',restore_dir)
                .replace('3106',str(dbport)))
        server_id = random.randint(10000, 99999)
        f.write(f'server_id = {server_id}\n')

    logging.info(f"生成Mysql配置文件成功：{conf_file}")


if __name__=='__main__':
    run()

