| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-4月-15 | 2024-4月-15  |
| ... | ... | ... |
---
# python 进阶教程 -- 线程高级应用

[toc]

## 消息队列

## event 时间对象

集合点的使用

```python
import threading
import time


# event = threading.Event()
## 重置event对象，使该evnet处于待命状态
# event.clear()
## 阻塞线程，等待event指令
# event.wait()
## 设置event对象，是所有设置该evnet事件的线程执行
# event.set()

# 性能测试 -- 集合点

class MyThread(threading.Thread):
    def __init__(self,event):
        super().__init__()
        self.event = event

    def run(self):
        print('线程{}已经初始化完成，随时准备启动……'.format(self.name))
        self.event.wait()
        time.sleep(2)
        print('线程{}已经启动……\n'.format(self.name))


if __name__ == '__main__':
    event = threading.Event()
    threads = []
    # 创建10个事件对象
    [threads.append(MyThread(event)) for i in range(1, 11)]

    event.clear()
    [t.start() for t in threads]
    event.set()
    [t.join() for t in threads]
```

## condition 条件对象

适合在线程间有某种依赖关系，需要简体执行的情况

```python
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
```

## 消息隔离local

local_data= thread.local()

使用场景: 需要一个在每个线程中能使用的变量，而不让变量互相影响。

```python
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
```

## 线程池
concurrent.futures 中的ThreadPoolExcutor
* 主线程可以获得某一线程或任务的状态，以及返回值
* 当一个线程完成时，主线程可以立即知道
* 多线程与多进程编码接近

```python
import time
from concurrent.futures import ThreadPoolExecutor

executor = ThreadPoolExecutor(max_workers=3)


def get_html(times):
    time.sleep(times)
    print("获取网页{}信息".format(times))
    return times


if __name__ == "__main__":
    # 通过submit方法执行的函数到线程池中，submit函数会立即返回，不阻塞主线程
    task3 = executor.submit(get_html, 1)
    task2 = executor.submit(get_html, 2)
    task1 = executor.submit(get_html, 3)
    task4 = executor.submit(get_html, 3)

```

### 线程池句柄

```python 
task1.done() # 检查任务是否完成，并返回结果
task2.cancel() # 取消任务执行，该任务**没有放入线程池**中才能取消成功 False
task4.cancel() True
task1.result() # 拿到这个任务的执行结果，是**阻塞**的
```

### 线程池常用方法

**as_completed** 任务结束后的生成器
```python
import time
from concurrent.futures import ThreadPoolExecutor,as_completed

executor = ThreadPoolExecutor(max_workers=3)


def get_html(times):
    time.sleep(times)
    print("获取网页{}信息".format(times))
    return times


if __name__ == "__main__":
    urls = [1, 4, 3, 2]
    task_list = [executor.submit(get_html, url) for url in urls]
    for item in as_completed(task_list):
        data = item.result()
        print(f'主线程中获取任务的返回值是{data}')
```


**map** (方法映射)生成器

```python
import time
from concurrent.futures import ThreadPoolExecutor

executor = ThreadPoolExecutor(max_workers=3)


def get_html(times):
    time.sleep(times)
    print("获取网页{}信息".format(times))
    return times


if __name__ == "__main__":
    urls = [1, 4, 3, 2]

    for item in executor.map(get_html,urls):
        print(f'主线程中获取任务的返回值是{item}')
```

> map 与 as_completed 的 区别
> as_completed 的结束顺序会按照任务的的结束顺序，输出任务结果
> 而 map 会按照任务开始顺序，输出任务结果

**wait** 阻塞主线程
```python
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
```
return_when 两个常用取值 ALL_COMPLETED ， FIRST_COMPLETED(顾名思义)

### 线程同步信号量 semaphore
semaphore 线程同步信号量

```python
import threading
import time

sem = threading.Semaphore(value=4)


class HtmlSpider(threading.Thread):
    def __init__(self, url=0):
        super().__init__()
        self.url = url

    def run(self):
        time.sleep(2)  # 模拟网络等待
        print("获取网页{}信息\n".format(self.url))
        sem.release()  # 信号量加1


class UrlProducer(threading.Thread):
    def run(self):
        for i in range(20):
            sem.acquire()
            html_thread = HtmlSpider(f'http://www.baidu.com/{i}')
            html_thread.start()


if __name__ == "__main__":
    url_producer = UrlProducer()
    url_producer.start()

```