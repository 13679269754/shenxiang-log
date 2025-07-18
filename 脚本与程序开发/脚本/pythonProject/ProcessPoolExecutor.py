#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
pythonProject/

author: shen
date : 2024/4/16
comment : 提示信息
"""
import multiprocessing
import time


def get_html(times):
    time.sleep(times)
    print("获取网页{}信息".format(times))
    return times


if __name__ == "__main__":
    # 通过cpu_count获取当前主机的核心数
    pool = multiprocessing.Pool(multiprocessing.cpu_count())
    # result = pool.apply_async(get_html, args=(3,))
    for result in pool.imap(get_html, [4, 2, 3]):
        print('{}休眠执行成功！'.format(result))

    # pool.close()  # 必须在join 前调用
    # pool.join()
    #
    # print(result.get())
    # print("程序结束")
