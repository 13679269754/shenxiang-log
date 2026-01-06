| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2024-7月-25 | 2024-7月-25 |
| ... | ... | ... |
---
# python smtplib 模块收发邮件报错

[toc]

## 报错内容

```bash
"/root/mysql_report_job/log_format.py:34" - wrapper - ERROR - (553, b'5.5.4 <localhost>... Domain name required for sender address localhost', 'localhost')
```

## 疑惑

1. 同样的代码在本地机器上可以正常运行，并能正常发送。
2. 修改部分邮件的构建顺序后，能发送出去，但是发生了退信。
阿里云邮箱：`reason: 502 Mailfrom account is a local account shenxiang@dazhuanjia.com`
3. 在反复确认邮件内容没有问题的情况下，还是依然报错。
4. 按照往上查来的修改邮件最大大小也不行。
5. 反复确认了本地和报错机器的python版本，pip3 list 的包的版本。并没有问题。
6. 发现本地使用了postsix 来发送邮件。而报错机器使用的是sendmail,问题解决

## 具体步骤

### 一. 安装 postfix

```bash
yum  install  postfix

systemctl status postfix

systemctl start  postfix
```

### 二. 关闭sendmail

`systemctl stop sendmail`

### 三.允许 本地发送
配置本地邮件服务器（如 Postfix 或 Sendmail）以允许使用 localhost 作为发件人地址发送邮件可能涉及一些系统配置和步骤。以下是一个简单的示例配置步骤：

1. 安装 Postfix  
   `sudo apt-get update`  
   `sudo apt-get install postfix`
1. 在 Postfix 配置文件中设置允许 localhost 作为发件人地址：  
编辑 Postfix 主配置文件：  
`sudo nano /etc/postfix/main.cf`  
1. 添加或修改以下行：  
`myorigin = localhost`    
`myhostname = localhost`  
1. 重新加载 Postfix 配置：  
`sudo postfix reload`  
1. 确保邮件服务正在运行：  
`sudo systemctl start postfix`  



### 四. 发送邮件，此时还会报错

```bash

Jul 24 18:10:07 Archery postfix/local[917]: 92B21405A1D: to=<root@Archery.localdomain>, relay=local, delay=0.11, delays=0.05/0.05/0/0.01, dsn=5.2.2, status=bounced (cannot update mailbox /var/mail/root for user root. error writing message: File too large)

```

参考文章
[error writing messa ge: File too large](https://blog.csdn.net/ITzhangdaopin/article/details/110410449)

`postconf -e mailbox_size_limit=0`



