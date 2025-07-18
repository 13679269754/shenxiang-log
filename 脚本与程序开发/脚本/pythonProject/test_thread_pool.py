#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
pythonProject/

author: shen
date : 2024/4/16
comment : 提示信息
"""
import time
from concurrent.futures import ThreadPoolExecutor, as_completed, wait, ALL_COMPLETED, FIRST_COMPLETED

executor = ThreadPoolExecutor(max_workers=3)


def get_html(times):
    time.sleep(times)
    print("获取网页{}信息".format(times))
    return times


if __name__ == "__main__":
    urls = [1, 4, 3, 2]
    task_list = [executor.submit(get_html, url) for url in urls]
    wait(task_list, return_when=ALL_COMPLETED)  # 让主线程等待子线程结束，直到指定等待条件成立
    print('代码执行完毕')

