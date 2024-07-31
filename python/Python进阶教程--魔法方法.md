| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-4月-19 | 2024-4月-19  |
| ... | ... | ... |
---
# Python进阶教程--魔法方法

[toc]


\_\_repr\_\_ 定义打印的输出

\_\_del\_\_ 定制对象的析构方法

\_\_new\_\_ 负责创建类的实例  return object.__new__(cls)
* 可以用来实现类的单例模式

\_\_init\_\_  负责初始化类实例

\_\_dir\_\_ 查看对象的方法和属性名字
* dir() 方法会对返回值进行排序，并包装为列表。

\_\_dict\_\_ 是一个字典
作用于类时： 储存所有实例共享的变量和函数
作用于对象时：存储该对象多有的属性和值
一般用于**动态读取和设置对象属性**。


\_\_getattribute\_\_ 访问对象任意属性是被自动调用

\_\_getattr\_\_ 访问对象的xxx属性且该属性不存在时被调用

\_\_setattr\_\_ 当属性被赋值时调用

* 可以对要设置属性的时候可以添加限制，可特殊处理

```python
def __setaddr__(self,key,value):
    if key == 'age':
        if value < 18:
            raise Exception('age的值必须大于等于18')
        else：
            self.__dict__[key] = value # 这一句必须要写，保证当属性的值正确是，可以赋值给对应属性
    else：
        self.__dict__[key] = value
```

\_\_delattr\_\_ 当删除对象的xxx属性是被调用

**python中的反射**

\_\_hasattr\_\_ 输入一个字符串，判断对象有没这个方法或属性,返回bool
\_\_getattr\_\_ 获取对象属性值或方法的引用。如果是方法,则返回方法的引用;如果是属性，直接返回属性值。方法不存在，抛出异常
\_\_setattr\_\_ 动态添加一个方法或属性
\_\_delattr\_\_ 东塔伤处一个方法或属性


