
| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2024-4月-16 | 2024-4月-16 |

---
# python进阶教程--协程(迭代器与生成器)

[toc]

## 可迭代对象与迭代器

### 可迭代对象

python对象中，只要定义了可以返回一个迭代器的__iter__方法，或者定义了可以支持下标索引的__getitem__方法，name他就是一个**可迭代对象**，通俗的讲就是可以通过for循环进行遍历了。

tips :  
dir([object]) 可以打印列表中的所有实现的方法  
isinstance() 判断对象类型  
isinstance([],Iterable)  判断是否是可迭代对象  
hasattr([],'__getitem__')  判断是否是可迭代对象  
type(counter)  获取对象的类型  

判断是否是可迭代对象  
可以使用   
isinstance + iterable  
hasattr + \_\_getitem\_\_  

创建一个可迭代对象  
```python
class Employee:
    def __init__(self, employee):
        self.employee = employee

    def __getitem__(self, item):  # item是解释器帮我们维护的索引值，当在for循环中时，自动从0开始计数
        return self.employee[item]


emp = Employee(['张三', '李四', '王五'])

if __name__ == "__main__":
    for i in emp:
        print(i)
```

### 迭代器  
实现了__next__ 和__iter__ 方法(缺一不可)的对象就是**迭代器**。其中__iter__ 方法返回迭代器自身，  
__next__方法不断返回迭代器中的下一个值，直到容器中没有更多元素时抛出StopIteration异常，以终止迭代。  

**为什么有了可迭代对象，还要有迭代器?**
* 工厂模式，节约内存  
    迭代器没有len 属性

**常用的一个迭代器itertools.count**
```python
from itertools import count
from collections import Iterator
counter = count(start=10)
print(isinstance(counter,Iterator))  # 判断一个对象是否是可迭代对象
```

**将可迭代对象变成迭代器对象**  

使用iter() 强制转换
```python
a = [1,2,3,4,5,6]
a_iter = iter(a) # 将a 这个可迭代对象变为迭代器对象
print(type(a_iter))
print(dir(a_iter))
```

**迭代器的遍历**
```pytyhon
a = [1,2,3,4,5,6]
a_iter = iter(a) # 将a 这个可迭代对象变为迭代器对象
print(type(a_iter))
print(dir(a_iter))

print(next(a_iter)) # 迭代器迭代一遍将去除元素，元素就不在迭代器中了

for item in a_iter: # 如果重复迭代迭代器，无法获得结果
    print(item)

```

## 生成器对象

生成器其实是一种特殊的迭代器，不过这种迭代器更加优雅，它不需要再想上面的类一样写__iter__和__next__方法，只需要一个yield 关键字，也就是说。如果一个函数包含yield 关键字， 这个函数就是变成了一个生成器。

```python
def demo():
    print('hello')
    yield 5
    print('world')


if __name__ == "__main__":
    print(type(demo())) # <class 'generator'>
    print(dir(demo())) # ……__iter__……__next__……
    # 生成器调用
    c = demo()
    next(c)
```

**生成器知识点**

1. 生成器中的yield 关键字的作用
   * 程序每次在代码中遇到yield 关键字后，会返回结果
   * 保留当前函数的运行状态，等待下一次调用，下一次调用时从上一次放回yield 的语句处开始执行

2. 预激活生成器(第一次调用)除了可以使用next(),还可以使用send()
   * send 方法在调用生成器时，还可以同时给生成器传递参数，预激活时**不能传递非空的参数**

    ```python
    def demo():
	    print('hello')
	    t = yield 5  # return 5 ，send 方法闯入的参数会被赋给t
	    print('world')
	    print(t)


    if __name__ == "__main__":
	    print(type(demo())) # <class 'generator'>
	    print(dir(demo())) # ……__iter__……__next__……
	
	    # 生成器调用
	    c = demo()
	    next(c)
	    c.send('test') # send方法调用生成器并且吧test字符串传入到生成器
    ```

3. 生成器的创建与使用

生成器的执行过程

   ```python
def ccountdown(n):  
    print('conting down from ', n)  
    while n >= 0:  
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
   ```


4. 使用生成式生成的元组是一个生成器
```python
a = (i for i in range(10))
b = [i for i in range(10)]

print(type(a))
print(type(b))

print(next(a))
print(next(b))
```


### 协程
yield 关键字的两个作用：   
一. 每次遇到yield 关键字后返回相应结果。  
二. 保留当前函数的运行状态，等待下一次调用，下一次调用时继续执行之后的语句。  

这以为意味着程序的控制权的转移是临时的，我们的函数还会收回来控制权。这也是yield 和 return 最大的区别。  

协程定义：  
协程又被称为微线程，是一种用户态的轻量级线程。在同一个线程中,不同的子程序可以中断去执行其他的子程序，并且中断回来后,从中断处继续执行。  

协程拥有自己的寄存器上下文和栈。  

**使用协程实现消费者-生产者模式**
```python 
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
```

#### 协程的演进(协程章节总结)
可迭代对象

迭代器

生成器

协程

asyncio 框架