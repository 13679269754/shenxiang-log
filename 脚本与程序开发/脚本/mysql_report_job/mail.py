#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
mysql_report_job/

author: shen
date : 2024/5/24
comment : 提示信息
"""
import os
import smtplib
import time

from config import recipientAddrs, ip_filter
from log_format import log_decorator, logger
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders


@log_decorator
def report_mail(operator_obj, attachment_path):
    today = time.strftime("%Y%m%d", time.localtime())  # Get today's date in the format YYYYMMDD

    attachment_file_names = []
    for file_name in os.listdir(attachment_path):
        file_path = os.path.join(attachment_path, file_name)
        if os.path.isfile(file_path) and file_name.startswith(f"{ip_filter}") and file_name.endswith(".html"):
            file_date = file_name.split("_")[2]  # Extract the date part from the file name
            if file_date == today:
                attachment_file_names.append(file_path)

    attachment_file_names.sort()

    msg = MIMEMultipart()
    msg['From'] = 'localhost'
    msg['To'] = recipientAddrs
    msg['Subject'] = today + '数据库状态报告'

    html_msg = f"""{today}数据库状态报告"""

    msg.attach(MIMEText(html_msg, "html", "utf-8"))
    for file_path in attachment_file_names:
        attachment = open(file_path, 'rb')
        part = MIMEBase('application', 'octet-stream')
        part.set_payload(attachment.read())
        encoders.encode_base64(part)
        part.add_header('Content-Disposition', f'attachment; filename="{os.path.basename(file_path)}"')
        msg.attach(part)


    send = smtplib.SMTP('localhost')
    send.sendmail('localhost', recipientAddrs.split(','), msg.as_string())

    logger.info('------------- 发送备份报告成功 -------------')

    return True

