"""
mail.py

author: shen
date : 2023/8/16
comment :
"""
# -*- coding:utf-8 -*-
import smtplib
import email
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.utils import formataddr

'''~~~smtp认证使用的邮箱帐号密码~~~'''
username = ''
password = ''

'''~~~定义发件地址~~~'''
From = formataddr(['',''])  #昵称(邮箱没有设置外发指定自定义昵称时有效)+发信地址(或代发)
replyto = ''  #回信地址

'''定义收件对象'''
to = ','.join(['', ''])  #收件人
cc = ','.join(['', ''])  #抄送
bcc = ','.join(['', ''])  #密送
rcptto = [to,cc,bcc]  #完整的收件对象

'''定义主题'''
Subject = ''

'''~~~开始构建message~~~'''
msg = MIMEMultipart('alternative')
'''1.1 收发件地址、回信地址、Message-id、发信时间、邮件主题'''
msg['From'] = From
msg['Reply-to'] = replyto
msg['TO'] = to
msg['Cc'] = cc
# msg['Bcc'] = bcc  #建议密送地址在邮件头中隐藏
msg['Message-id'] = email.utils.make_msgid()
msg['Date'] = email.utils.formatdate()
msg['Subject'] = Subject
''''1.2 正文text/plain部分'''
textplain = MIMEText('正文内容', _subtype='plain', _charset='UTF-8')
msg.attach(textplain)
'''1.3 封装附件'''
file = r'C:\Users\yourname\Desktop\某文件夹\123.pdf'   #指定本地文件，请换成自己实际需要的文件全路径。
att = MIMEText(open(file, 'rb').read(), 'base64', 'utf-8')
att["Content-Type"] = 'application/octet-stream'
att.add_header("Content-Disposition", "attachment", filename='123.pdf')
msg.attach(att)

'''~~~开始连接验证服务~~~'''
try:
    client = smtplib.SMTP_SSL('smtp.qiye.aliyun.com', 465)
    print('smtp_ssl----连接服务器成功，现在开始检查帐号密码')
except Exception as e1:
    client = smtplib.SMTP('smtp.qiye.aliyun.com', 25, timeout=5)
    print('smtp----连接服务器成功，现在开始检查账号密码')
except Exception as e2:
    print('抱歉，连接服务超时')
    exit(1)
try:
    client.login(username, password)
    print('帐密验证成功')
except:
    print('抱歉，帐密验证失败')
    exit(1)

'''~~~发送邮件并结束任务~~~'''
client.sendmail(username, (','.join(rcptto)).split(','), msg.as_string())
client.quit()
print('邮件发送成功')


#
# An example Name Service Switch config file. This file should be
# sorted with the most-used services at the beginning.
#
# The entry '[NOTFOUND=return]' means that the search for an
# entry should stop if the search in the previous entry turned
# up nothing. Note that if the search failed due to some other reason
# (like no NIS server responding) then the search continues with the
# next entry.
#
# Valid entries include:
