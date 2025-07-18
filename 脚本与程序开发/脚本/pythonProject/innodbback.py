import subprocess
import logging

# 调用Shell命令并获取输出
result = subprocess.run('ls', shell=True, capture_output=True, text=True)

# 输出Shell命令的返回结果
print(result.stdout)


# 写一个 调用innodbbackup 备份mysql 的 例子
# mysql -uroot -p123456 -e "show databases;"       # 查看数据库列表
# mysql -uroot -p123456 -e "show tables;"           # 查看表
# innodbback.py


# 设置innodbbackup参数
innodbbackup_path = '/usr/local/bin/innodbbackup'
backup_dir = '/var/backups/mysql'

# 构建innodbbackup命令
innodbbackup_cmd = [innodbbackup_path, '--user', mysql_user, '--password', mysql_password, '--host', mysql_host, '--database', mysql_database, '--output-dir', backup_dir]

# 执行innodbbackup命令
subprocess.run(innodbbackup_cmd)
