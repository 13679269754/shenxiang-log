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

# 第二中方法，通过asyncio 自带的添加回调函数的功能来实现


# print(isinstance(coro, Generator))
# print(isinstance(coro, Coroutine))
# print(isinstance(coro2, Coroutine))
# #
# loop = asyncio.get_event_loop()
# tasks = [hello(), hello()]
# loop.run_until_complete(asyncio.wait(tasks))
# loop.close()
