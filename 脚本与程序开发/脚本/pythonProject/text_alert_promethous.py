"""
text_alert_promethous.py

author: shen
date : 2023/8/22
comment :
"""
# Corpid是企业号的标识
Corpid = "wwceb888aab4491588"

# Secret是管理组凭证密钥
Secret = "-kaDO7bryMhCxUVXeu7gKqdxHgHxWcMBxGKQD_F_Vbw"

# agentid
agent_id = (1000004,)

# token_file文件放置路径
token_file = r'/tmp/qywechat_token.txt'

def GetToken(Corpid, Secret):
    """获取access_token"""
    Url = "https://qyapi.weixin.qq.com/cgi-bin/gettoken"
    Data = {
        "corpid": Corpid,
        "corpsecret": Secret
    }
    r = requests.get(url=Url, params=Data, verify=False).json()
    c_time = int(time.time())
    if r.get('errcode') != 0:
        return False
    else:
        try:
            with open(token_file, 'r') as f:
                tokenlist = f.readlines()
                if len(tokenlist) == 2 and c_time < int(tokenlist[1].strip()):
                    token = tokenlist[0].strip()
                    expires = tokenlist[1].strip()
                else:
                    raise Exception
        except Exception:
            with open(token_file, 'w') as f:
                try:
                    token = r.get('access_token')
                    expires = int(r.get('expires_in', 0)) + c_time
                    f.write('%s\n%s' % (token, expires))
                except Exception as e:
                    print(e)
                    token = ''
        return token

def SendMessage(Subject, Content, Agentid):
    """发送消息"""
    # 获取token信息
    Token = GetToken(Corpid, Secret)
    # 发送消息
    Url = "https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=%s" % Token
    Data = {
        "msgtype": "text",
        "agentid": Agentid,
        "text": {"content": Subject + '\n----------------------------------------------------------\n' + Content},
        "touser":'@all',
        "safe": "0"
    }

    r = requests.post(url=Url, data=json.dumps(Data), verify=False)
    # 如果发送失败，将重试三次
    n = 1
    while r.json()['errcode'] != 0 and n < 4:
        n = n + 1
        Token = GetToken(Corpid, Secret)
        if Token:
            Url = "https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=%s" % Token
            r = requests.post(url=Url, data=json.dumps(Data), verify=False)
    return r.json()['errcode']

def send_msg(Subject, Content,  Agentid = agent_id):
    for agentid in Agentid:
        Status = SendMessage(Subject, Content, agentid)