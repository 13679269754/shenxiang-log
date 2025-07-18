#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
pythonProject/

author: shen
date : 2024/4/16
comment : 提示信息
"""

import threading

local_name = threading.local()

local_name.name = 'local_data'


class mythread(threading.Thread):
    def run(self):
        print('修改前的thread.local:{}'.format(local_name.__dict__))
        local_name.name = self.getName()
        print('修改前的thread.local:{}'.format(local_name.__dict__))


if __name__ == "__main__":
    print('主进程打印运行后的thread.local:', local_name.__dict__, 'started')
    t1 = mythread()
    t1.start()
    t1.join()

    t2 = mythread()
    t2.start()
    t2.join()
    print('主进程打印运行前的thread.local:', local_name.__dict__, 'started')
