#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
pythonProject/

author: shen
date : 2024/4/17
comment : 提示信息
"""

def demo():
    print('hello')
    t = yield 5  # return 5
    print('world')
    print(t)


def ccountdown(n):
    print('conting down from ',n)
    while n>= 0:
        newvalue = yield n
        if newvalue is not None:
            n = newvalue
        else:
            n -= 1
    print('done')


if __name__ == "__main__":

    # 协程调用
    c = ccountdown(10)
    for i in c:
        print(i)
        if i == 10:
            c.send(10)