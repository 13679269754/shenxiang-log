| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2024-4月-16 | 2024-4月-16 |
| ... | ... | ... |
---
# python 进阶教程 -- 进程池

[toc]

## 进程池
## 使用pool 类来实现进程池


## 使用concurrent_futures模块提供的 ProcessPoolExecutor 来实现进程池

与线程池threadPoolExecutor 类似。[线程池](python进阶教程--线程高级应用.md) (**推荐使用**)

### apply_async
```python 
import multiprocessing
import time


def get_html(times):
    time.sleep(times)
    print("获取网页{}信息".format(times))
    return times


if __name__ == "__main__":
    # 通过cpu_count获取当前主机的核心数
    pool = multiprocessing.Pool(multiprocessing.cpu_count())
    result = pool.apply_async(get_html, args=(3,))

    pool.close()  # 必须在join 前调用
    pool.join()

    print(result.get())
    print("程序结束")

```


### map
```python 
import multiprocessing
import time


def get_html(times):
    time.sleep(times)
    print("获取网页{}信息".format(times))
    return times


if __name__ == "__main__":
    # 通过cpu_count获取当前主机的核心数
    pool = multiprocessing.Pool(multiprocessing.cpu_count())
    for result in pool.imap(get_html, [4, 2, 3]): # 会保证按照进程开始的时间顺序打印（执行后续代码）
    # for result in pool.imap_unorderd(get_html, [4, 2, 3]) 就不会按照开始的时间顺序打印了
        print('{}休眠执行成功！'.format(result))

```

