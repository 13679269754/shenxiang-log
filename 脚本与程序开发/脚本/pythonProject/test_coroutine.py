#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
pythonProject/

author: shen
date : 2024/4/17
comment : 提示信息
"""


def consumer():
    r = 'hello'
    while True:
        n = yield r
        if not n:
            return
        print('[CONSUMER] Consuming %s...' % n)
        r = '200 OK'


def producer(c):  # 传入一个生成器
    c.send(None)
    n = 0
    while n < 5:
        n = n + 1
        print('[PRODUCER] Producing %s...' % n)
        r = c.send(n)
        print('[PRODUCER] Consumer return: %s' % r)
    c.close()


if __name__ == "__main__":
    c = consumer()
    producer(c)
