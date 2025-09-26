import os
from copy import copy
import requests
import json
from urllib3 import encode_multipart_formdata
# file_path: e.g /root/data/test_file.xlsx
# 如果D:\\windows\\ 下面file_name的split需要调整一下
# upload_file 是为了生成 media_id， 供消息使用

wx_api_key = "c932d9df-3cb2-4611-bb24-e8bcb3bc08a1" # 这个地方写你自己的key
wx_upload_url = "https://qyapi.weixin.qq.com/cgi-bin/webhook/upload_media?key={}&type=file".format(wx_api_key)
wx_url = 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key={}'.format(wx_api_key)

def upload_file(file_path, wx_upload_url):
    file_name = file_path.split("/")[-1]
    with open(file_path, 'rb') as f:
        length = os.path.getsize(file_path)
        data = f.read()
    headers = {"Content-Type": "application/octet-stream"}
    params = {
        "filename": file_name,
        "filelength": length,
    }
    file_data = copy(params)
    file_data['file'] = (file_path.split('/')[-1:][0], data)
    encode_data = encode_multipart_formdata(file_data)
    file_data = encode_data[0]
    headers['Content-Type'] = encode_data[1]
    r = requests.post(wx_upload_url, data=file_data, headers=headers)
    print(r.text)
    media_id = r.json()['media_id']
    return media_id

def qi_ye_wei_xin_file(wx_url, media_id):
    headers = {"Content-Type": "text/plain"}
    data = {
        "msgtype": "file",
        "file": {
            "media_id": media_id
        }
    }
    r = requests.post(
        url=wx_url,
        headers=headers, json=data)
    print(r.text)

def send(file_name,content):
    wx_api_key = "c932d9df-3cb2-4611-bb24-e8bcb3bc08a1"  # 这个地方写你自己的key
    wx_upload_url = "https://qyapi.weixin.qq.com/cgi-bin/webhook/upload_media?key={}&type=file".format(wx_api_key)
    wx_url = 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key={}'.format(wx_api_key)

    """发送消息"""
    # 发送消息
    Url = wx_url
    Data = {
        "msgtype": "text",
        "text": {"content": content},
    }

    r = requests.post(url=Url, data=json.dumps(Data), verify=False)

    print(r.json()['errcode'])


    media_id = upload_file(file_name, wx_upload_url)
    qi_ye_wei_xin_file(wx_url, media_id)

if __name__ == '__main__':
    test_report = '/root/dolphie_hosts'
    send(test_report)

