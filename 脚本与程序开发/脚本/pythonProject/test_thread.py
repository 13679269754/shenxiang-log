#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
pythonProject/

author: shen
date : 2024/4/15
comment : 提示信息
"""

import threading
import time


# event = threading.Event()
## 重置event对象，使该evnet处于待命状态
# event.clear()
## 阻塞线程，等待event指令
# event.wait()
## 设置event对象，是所有设置该evnet事件的线程执行
# event.set()

# 性能测试 -- 集合点

class MyThread(threading.Thread):
    def __init__(self,event):
        super().__init__()
        self.event = event

    def run(self):
        print('线程{}已经初始化完成，随时准备启动……'.format(self.name))
        self.event.wait()
        time.sleep(2)
        print('线程{}已经启动……\n'.format(self.name))


if __name__ == '__main__':
    event = threading.Event()
    threads = []
    # 创建10个事件对象
    [threads.append(MyThread(event)) for i in range(1, 11)]

    event.clear()
    [t.start() for t in threads]
    event.set()
    [t.join() for t in threads]
