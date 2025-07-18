#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
pythonProject/

author: shen
date : 2024/4/17
comment : 提示信息
"""


class Employee:
    def __init__(self, employee):
        self.employee = employee

    def __getitem__(self, item):  # item是解释器帮我们维护的索引值，当在for循环中时，自动从0开始计数
        return self.employee[item]


emp = Employee(['张三', '李四', '王五'])

if __name__ == "__main__":
    for i in emp:
        print(i)
