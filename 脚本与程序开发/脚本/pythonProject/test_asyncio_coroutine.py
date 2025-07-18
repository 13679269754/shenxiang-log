#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
pythonProject/

author: shen
date : 2024/4/18
comment : 提示信息
"""
import asyncio


async def do_some_work(x):
    print("等待", x)
    await asyncio.sleep(x) # 模拟一个等待耗时操作
    return "Done after {}s".format(x)


if __name__ == "__main__":
    # 创建多个协程对象
    coro1 = do_some_work(1)
    coro2 = do_some_work(2)
    coro3 = do_some_work(3)

    # 将协程对象转换为task,并组成一个list
    tasks = [asyncio.ensure_future(coro1), asyncio.ensure_future(coro2), asyncio.ensure_future(coro3)]

    # 将task池注册到循环当中
    # 两种方法: asyncio.gather(*tasks)  asyncio.wait(tasks)
    loop = asyncio.get_event_loop()
    # wait方法直接接收列表作为参数
    loop.run_until_complete(asyncio.wait(tasks))

    for task in tasks:
        print('任务返回的结果是', task.result())