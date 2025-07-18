#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
pythonProject/

author: shen
date : 2024/4/16
comment : 提示信息
"""
import threading
import time

sem = threading.Semaphore(value=4)


class HtmlSpider(threading.Thread):
    def __init__(self, url=0):
        super().__init__()
        self.url = url

    def run(self):
        time.sleep(2)  # 模拟网络等待
        print("获取网页{}信息\n".format(self.url))
        sem.release()  # 信号量加1


class UrlProducer(threading.Thread):
    def run(self):
        for i in range(20):
            sem.acquire()
            html_thread = HtmlSpider(f'http://www.baidu.com/{i}')
            html_thread.start()


if __name__ == "__main__":
    url_producer = UrlProducer()
    url_producer.start()
