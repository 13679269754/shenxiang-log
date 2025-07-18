#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
pythonProject/

author: shen
date : 2024/4/15
comment : 提示信息
"""

import threading

# 新建一个condition对象
# cond = threading.Condition()


class kongbai(threading.Thread):
    def __init__(self, cond, name):
        threading.Thread.__init__(self, name=name)
        self.cond = cond

    def run(self):
        self.cond.acquire()  # 获取锁
        print(self.getName() + '：一只穿云箭')
        self.cond.notify()  # 唤醒其他wait状态线程
        self.cond.wait()  # 等待其他线程唤醒,其他线程notify通知

        print(self.getName() + '：山无棱，天地合，乃敢与君绝')
        self.cond.notify()  # 唤醒其他wait状态线程
        self.cond.wait()  # 等待其他线程唤醒,其他线程notify通知

        print(self.getName() + '：紫薇')
        self.cond.notify()  # 唤醒其他wait状态线程
        self.cond.wait()  # 等待其他线程唤醒,其他线程notify通知

        print(self.getName() + '：是你')
        self.cond.notify()  # 唤醒其他wait状态线程
        self.cond.wait()  # 等待其他线程唤醒,其他线程notify通知

        print(self.getName() + '：有钱吗,借点')
        self.cond.notify()  # 唤醒其他wait状态线程
        self.cond.release()  # 等待其他线程唤醒,其他线程notify通知


class ximi(threading.Thread):
    def __init__(self, cond, name):
        threading.Thread.__init__(self, name=name)
        self.cond = cond

    def run(self):
        self.cond.acquire()  # 获取锁
        self.cond.wait()  # 等待其他线程唤醒,其他线程notify通知

        print(self.getName() + '：千军万马来相见')
        self.cond.notify()  # 唤醒其他wait状态线程
        self.cond.wait()  # 等待其他线程唤醒,其他线程notify通知

        print(self.getName() + '：海可枯，石可烂，激情永不散')
        self.cond.notify()  # 唤醒其他wait状态线程
        self.cond.wait()  # 等待其他线程唤醒,其他线程notify通知

        print(self.getName() + '：尔康')
        self.cond.notify()  # 唤醒其他wait状态线程
        self.cond.wait()  # 等待其他线程唤醒,其他线程notify通知

        print(self.getName() + '：是我')
        self.cond.notify()  # 唤醒其他wait状态线程
        self.cond.wait()  # 等待其他线程唤醒,其他线程notify通知

        print(self.getName() + '：滚')
        self.cond.notify()  # 唤醒其他wait状态线程
        self.cond.release()  # 等待其他线程唤醒,其他线程notify通知


if __name__=='__main__':
    cond = threading.Condition()
    t1 = kongbai(cond, 'kongbai')
    t2 = ximi(cond, 'ximi')
    t2.start()
    t1.start()
