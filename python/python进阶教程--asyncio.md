| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2024-4月-17 | 2024-4月-17 |
| ... | ... | ... |
---
# python进阶教程--asyncio.md

[toc]

## 同步io与异步io
同步io 是指io操作开始后，线程必须等待io操作结束后拿到结果。
异步io 是指io操作开始后，线程不必等待io操作的结果，而是等io操作结束后由系统通知io操作结束，再回来处理结果。

为什么要使用asyncio?
web -- Django、Flask
爬虫 -- Scrapy

使用asyncio来定义协程  
* 基于@asyncio.corontine装饰器来定义协程
```python
import asyncio

# 使用装饰器定义协程只是将函数对象标记为协程
# 实际上还是一个生成器，但是可以当做一个协程来使用
@asyncio.coroutine
def hello():
    pass

loop = asyncio.get_event_loop()
tasks = [hello(), hello()]
loop.run_until_complete(asyncio.wait(tasks))
loop.close()
```

* 使用asyncio 原生协议定义  

> async 关键字代表当前定义的对象是一个协程对象
```python
from typing import Coroutine, Generator, Awaitable
@asyncio.coroutine
# "@coroutine" decorator is deprecated since Python 3.8, use "async def" instead
def hello():
    pass

async def hello2():
    print('hello')


coro = hello() # 生成器对象
coro2 = hello2() # 协程对象

print(isinstance(coro, Generator))
print(isinstance(coro, Coroutine))
print(isinstance(coro2, Coroutine))
```

### 协程装饰器和原生协程之间的区别
有
装饰器的方式：没实现__iter__ and__next__ 的方法。

## 理解asyncio 

**event_loop**: 
    asyncio 开启一个无限循环事件。在满足条件时，去调用响应的协程对象。我们只需要将协程对象注册到该事件循环对象上即可。

**coroutine**（协程）: 
    通过async 定义的原生的协程。它在调用时不会立即执行，而是返回一个协程对象。协程对象需要注册到事件循环中，由事件循环进行调用。

**future** 对象: 
    代表将来执行或没有任务执行的结果,与task没有本质区别

**task** 对象: 
    一个协程对象就是一个可以被挂起的函数，而任务则是对协程的进一步封装，其中包含任务的各种状态。task 是future的子类。它可以将coroutine和future联系在一起，将coroutine 封装为一个future对象。

**async/await**: 
    python 3.5 之后用于定义协程的关键字，async 用于定义协程，await 用于挂起阻塞的异步调用接口，作用类似于yield。


### asyncio协程的调用逻辑

1. 定义创建协程对象
2. 定义事件循环对象容器
3. 将协程转为task任务
4. 将task扔进事件循环对象中触发

```python
import asyncio
# 使用装饰器定义协程只是将函数对象标记为协程
# 实际上还是一个生成器，但是可以当做一个生成器来使用

async def hello(name):
    print('hello',name)

coro = hello("world") # 协程对象

# 获取事件对象容器
loop = asyncio.get_event_loop()

# 将协程对象转化为task
# task = loop.create_task(coro)
task = asyncio.ensure_future(coro)

# 将task添加到事件循环对象中触发
loop.run_until_complete(task)
```

**回调方法**  

```python
import asyncio


# 使用装饰器定义协程只是将函数对象标记为协程
# 实际上还是一个生成器，但是可以当做一个生成器来使用

async def hello(x):
    # time.sleep(1) # 这是一个同步方法，无法达到异步的结果
    await asyncio.sleep(x)
    return x


def callback(future):
    sum = 10 + future.result()
    print('回调返回值是', sum)


coro = hello(3)  # 协程对象

# 获取事件对象容器
loop = asyncio.get_event_loop()

# 将协程对象转化为task
# task = loop.create_task(coro)
task = asyncio.ensure_future(coro)
task.add_done_callback(callback)

# 将task添加到事件循环对象中触发
loop.run_until_complete(task)

print('返回结果'.format(task.result()))

```

### 在协程中的并发

```python 
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
```