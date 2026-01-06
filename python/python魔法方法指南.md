# Python魔法方法指南

#### 文章目录

*   *   1 简介
    *   2 构造方法
    *   3 操作符
    *   *   3.1 比较操作符
        *   3.2 数值操作符
        *   *   3.2.1 一元操作符
            *   3.2.2 常见算数操作符
            *   3.2.3 反射算数运算符
            *   3.2.4 增强赋值运算符
            *   3.2.5 类型转换操作符
    *   4 类的表示
    *   5 访问控制
    *   6 自定义序列
    *   *   6.1. 预备知识
        *   6.2 容器背后的魔法方法
    *   7 可调用的对象
    *   8 上下文管理器
    *   9 附录：如何调用魔法方法

### 1 简介

什么是魔法方法呢？它们在面向对象的 [Python](https://so.csdn.net/so/search?q=Python&spm=1001.2101.3001.7020) 的处处皆是。它们是一些可以让你对类添加“魔法”的特殊方法。 它们经常是两个下划线包围来命名的（比如 __init__ ， __lt__ ）。但是现在没有很好的文档来解释它们。 所有的魔法方法都会在Python的官方文档中找到，但是它们组织松散。而且很少会有示例（有的是无聊的语法描述， 语言参考）。

所以，为了修复我感知的 Python 文档的缺陷，我开始提供更为通俗的，有示例支持的 Python 魔法方法指南。我一开始 写了一些博文，现在我把这些博文总起来成为一篇指南。

希望你喜欢这篇指南，一篇友好，通俗易懂的 Python 魔法方法指南！

### 2 构造方法

我们最为熟知的基本的魔法方法就是 __init__ ，我们可以用它来指明一个对象初始化的行为。然而，当我们调用 x = SomeClass() 的时候， __init__ 并不是第一个被调用的方法。事实上，第一个被调用的是 __new__ ，这个方法才真正地创建了实例。当这个对象的生命周期结束的时候， __del__ 会被调用。让我们近一步理解这三个方法：

*   __new__(cls,\[…)
    
    __new__ 是对象实例化时第一个调用的方法，它只取下 cls 参数，并把其他参数传给 __init__ 。 __new__ 很少使用，但是也有它适合的场景，尤其是当类继承自一个像元组或者字符串这样不经常改变的类型的时候。我不打算深入讨论 __new__ ，因为它并不是很有用， Python 文档中有详细的说明。
    
*   __init__(self,\[…\])
    
    类的初始化方法。它获取任何传给构造器的参数（比如我们调用 x = SomeClass(10, ‘foo’) ， __init__ 就会接到参数 10 和 ‘foo’ 。 __init__ 在 Python 的类定义中用的最多。
    
*   __del__(self)
    
    __new__ 和 __init__ 是对象的构造器， __del__ 是对象的销毁器。它并非实现了语句 del x (因此该语句不等同于 x.__del__())。而是定义了当对象被垃圾回收时的行为。 当对象需要在销毁时做一些处理的时候这个方法很有用，比如 socket 对象、文件对象。但是需要注意的是，当 Python 解释器退出但对象仍然存活的时候， __del__ 并不会 执行。 所以养成一个手工清理的好习惯是很重要的，比如及时关闭连接。
    

这里有个 __init__ 和 __del__ 的例子:

    from os.path import join
    
    
    class FileObject(object):
        '''文件对象的装饰类，用来保证文件被删除时能够正确关闭。'''
    
        def __init__(self, filepath='~', filename='sample.txt'):
            # 使用读写模式打开filepath中的filename文件
            self.file = open(join(filepath, filename), 'r+')
    
        def __del__(self):
            self.file.close()
            del self.file
    
    
        

### 3 操作符

使用 Python 魔法方法的一个巨大优势就是可以构建一个拥有 Python 内置类型行为的对象。这意味着你可以避免使用非标准的、丑陋的方式来表达简单的操作。 在一些语言中，这样做很常见:

    if instance.equals(other_instance):
        # do something
    
        

你当然可以在 Python 也这么做，但是这样做让代码变得冗长而混乱。不同的类库可能对同一种比较操作采用不同的方法名称，这让使用者需要做很多没有必要的工作。运用魔法方法的魔力，我们可以定义方法 __eq__

    if instance == other_instance:
        # do something
    
        

这是魔法力量的一部分，这样我们就可以创建一个像内建类型那样的对象了！

#### 3.1 比较操作符

Python 包含了一系列的魔法方法，用于实现对象之间直接比较，而不需要采用方法调用。同样也可以重载 Python 默认的比较方法，改变它们的行为。下面是这些方法的列表：

*   __eq__(self, other)-
    定义等于操作符(=)的行为。
    
*   __ne__(self, other)-
    定义不等于操作符(!=)的行为。
    
*   __lt__(self, other)-
    定义小于操作符(<)的行为。
    
*   __gt__(self, other)-
    定义大于操作符(>)的行为。
    
*   __le__(self, other)-
    定义小于等于操作符(<)的行为。
    
*   __ge__(self, other)-
    定义大于等于操作符(>)的行为。
    

举个例子，假如我们想用一个类来存储单词。我们可能想按照字典序（字母顺序）来比较单词，字符串的默认比较行为就是这样。我们可能也想按照其他规则来比较字符串，像是长度，或者音节的数量。在这个例子中，我们使用长度作为比较标准，下面是一种实现：

    class Word(str):
        '''单词类，按照单词长度来定义比较行为'''
    
        def __new__(cls, word):
            # 注意，我们只能使用 __new__ ，因为str是不可变类型
            # 所以我们必须提前初始化它（在实例创建时）
            if ' ' in word:
                print("Value contains spaces. Truncating to first space.")
                word = word[:word.index(' ')]
                # Word现在包含第一个空格前的所有字母
            return str.__new__(cls, word)
    
        def __eq__(self, other):
            return len(self) == len(other)
    
        def __ne__(self, other):
            return len(self) != len(other)
    
        def __gt__(self, other):
            return len(self) > len(other)
    
        def __lt__(self, other):
            return len(self) < len(other)
    
        def __ge__(self, other):
            return len(self) >= len(other)
    
        def __le__(self, other):
            return len(self) <= len(other)
    
    
    word1 = Word("abcd")
    word2 = Word("bcd")
    word3 = Word("cde")
    print(word1 > word2)
    print(word2 == word3)
    
        

其实不需要实现所有的比较魔法方法，就可以使用丰富的比较操作。标准库还在 functools 模块中提供了一个类装饰器，只要我们定义 __eq__ 和另外一个操作符（ __gt__, __lt__ 等），它就可以帮我们实现比较方法。这个特性只在 Python 2.7 中可用。当它可用时，它能帮助我们节省大量的时间和精力。要使用它，只需要它 @total_ordering 放在类的定义之上就可以了

#### 3.2 数值操作符

就像你可以使用比较操作符来比较类的实例，你也可以定义数值操作符的行为。固定好你的安全带，这样的操作符真的有很多。看在组织的份上，我把它们分成了五类：一元操作符，常见算数操作符，反射算数操作符（后面会涉及更多），增强赋值操作符，和类型转换操作符。

##### 3.2.1 一元操作符

一元操作符只有一个操作符。

*   __pos__(self)-
    实现取正操作，例如 +some_object。
*   __neg__(self)-
    实现取负操作，例如 -some_object。
*   __abs__(self)-
    实现内建绝对值函数 abs() 操作。
*   __invert__(self)-
    实现取反操作符 ~。
*   __round__(self， n)-
    实现内建函数 round() ，n 是近似小数点的位数。
*   __floor__(self)-
    实现 math.floor() 函数，即向下取整。
*   __ceil__(self)-
    实现 math.ceil() 函数，即向上取整。
*   __trunc__(self)-
    实现 math.trunc() 函数，即距离零最近的整数。

简单演示一下上面提到的一元操作符

    import math
    
    
    class Foo(object):
        def __pos__(self):
            return "__pos__"
    
        def __neg__(self):
            return "__neg__"
    
        def __abs__(self):
            return "__abs__"
    
        def __invert__(self):
            return "__invert__"
    
        def __round__(self, n=None):
            return "__round__"
    
        def __floor__(self):
            return "__floor__"
    
        def __ceil__(self):
            return "__ceil__"
    
        def __trunc__(self):
            return "__trunc__"
    
    if __name__ == "__main__":
        fun = Foo()
        print(+fun)
        print(-fun)
        print(abs(fun))
        print(~fun)
        print(round(fun))
        print(math.floor(fun))
        print(math.ceil(fun))
        print(math.trunc(fun))
    
        

##### 3.2.2 常见算数操作符

现在，我们来看看常见的二元操作符（和一些函数），像+，-，\*之类的，它们很容易从字面意思理解。

*   __add__(self, other)-
    实现加法操作。
    
*   __sub__(self, other)-
    实现减法操作。
    
*   __mul__(self, other)-
    实现乘法操作。
    
*   __floordiv__(self, other)-
    实现使用 // 操作符的整数除法。
    
*   __div__(self, other)-
    实现使用 / 操作符的除法。
    
*   __truediv__(self, other)-
    实现 _true_ 除法，这个函数只有使用 from __future__ import division 时才有作用。
    
*   __mod__(self, other)-
    实现 % 取余操作。
    
*   __divmod__(self, other)-
    实现 divmod 内建函数。
    
*   __pow__-
    实现 \*\* 操作符。
    
*   __lshift__(self, other)-
    实现左移位运算符 << 。
    
*   __rshift__(self, other)-
    实现右移位运算符 >> 。
    
*   __and__(self, other)-
    实现按位与运算符 & 。
    
*   __or__(self, other)-
    实现按位或运算符 | 。
    
*   __xor__(self, other)-
    实现按位异或运算符 ^ 。
    
*   example
    

    class Vector(object):
        def __init__(self, x):
            self.x = x
    
        def __add__(self, other):
            return [a + b for a, b in zip(self.x, other.x)]
    
        def __sub__(self, other):
            return [a - b for a, b in zip(self.x, other.x)]
    
        def __mul__(self, other):
            return [a * b for a, b in zip(self.x, other.x)]
    
        def __floordiv__(self, other):
            return [a // b for a, b in zip(self.x, other.x)]
    
        def __mod__(self, other):
            return [a % b for a, b in zip(self.x, other.x)]
    
        def __lshift__(self, other):
            return [a << b for a, b in zip(self.x, other.x)]
    
        def __rshift__(self, other):
            return [a >> b for a, b in zip(self.x, other.x)]
    
        def __and__(self, other):
            return [a & b for a, b in zip(self.x, other.x)]
    
        def __or__(self, other):
            return [a | b for a, b in zip(self.x, other.x)]
    
        def __xor__(self, other):
            return [a ^ b for a, b in zip(self.x, other.x)]
    
    
    if __name__ == "__main__":
        v1 = Vector([1, 2, 3])
        v2 = Vector([1, 2, 3])
        print(v1 + v2)
        print(v1 - v2)
        print(v1 * v2)
        print(v1 // v2)
        print(v1 % v2)
        print("{:*^10}".format("==="))
        print(v1 << v2)
        print(v1 >> v2)
        print(v1 & v2)
        print(v1 | v2)
        print(v1 ^ v2)
    
        

##### 3.2.3 反射算数运算符

还记得刚才我说会谈到反射运算符吗？可能你会觉得它是什么高端霸气上档次的概念，其实这东西挺简单的，下面举个例子:

    some_object + other
    
        

这是“常见”的加法，反射是一样的意思，只不过是运算符交换了一下位置:

    other + some_object
    
        

所有反射运算符魔法方法和它们的常见版本做的工作相同，只不过是处理交换连个操作数之后的情况。绝大多数情况下，反射运算和正常顺序产生的结果是相同的，所以很可能你定义 __radd__ 时只是调用一下 __add__。注意一点，操作符左侧的对象（也就是上面的 other ）一定不要定义（或者产生 NotImplemented 异常） 操作符的非反射版本。例如，在上面的例子中，只有当 other 没有定义 __add__ 时 some_object.__radd__ 才会被调用。

*   __radd__(self, other)-
    实现反射加法操作。
    
*   __rsub__(self, other)-
    实现反射减法操作。
    
*   __rmul__(self, other)-
    实现反射乘法操作。
    
*   __rfloordiv__(self, other)-
    实现使用 // 操作符的整数反射除法。
    
*   __rdiv__(self, other)-
    实现使用 / 操作符的反射除法。
    
*   __rtruediv__(self, other)-
    实现 _true_ 反射除法，这个函数只有使用 from __future__ import division 时才有作用。
    
*   __rmod__(self, other)-
    实现 % 反射取余操作符。
    
*   __rdivmod__(self, other)-
    实现调用 divmod(other, self) 时 divmod 内建函数的操作。
    
*   __rpow__-
    实现 \*\* 反射操作符。
    
*   __rlshift__(self, other)-
    实现反射左移位运算符 << 的作用。
    
*   __rshift__(self, other)-
    实现反射右移位运算符 >> 的作用。
    
*   __rand__(self, other)-
    实现反射按位与运算符 & 。
    
*   __ror__(self, other)-
    实现反射按位或运算符 | 。
    
*   __rxor__(self, other)-
    实现反射按位异或运算符 ^ 。
    
*   example
    

    class A:
    ...     def __add__(self, other):
    ...         print("A __add__")
    ... 
    ...     def __radd__(self, other):
    ...         print("A __radd__")
    ... 
    ... class B:
    ... 	pass
    ... 
    a = A()
    b = B()
    a+b
    A __add__
    b+a
    A __radd__
    c = B()
    b+c
    Traceback (most recent call last):
      File "<input>", line 1, in <module>
    TypeError: unsupported operand type(s) for +: 'B' and 'B'
    
        


##### 3.2.4 增强赋值运算符

Python 同样提供了大量的魔法方法，可以用来自定义增强赋值操作的行为。或许你已经了解增强赋值，它融合了“常见”的操作符和赋值操作，如果你还是没听明白，看下面的例子:

    x = 5
    x += 1 # 也就是 x = x + 1
    
        

这些方法都应该返回左侧操作数应该被赋予的值（例如， a += b   __iadd__ 也许会返回 a + b ，这个结果会被赋给 a ）,下面是方法列表：

*   __iadd__(self, other)-
    实现加法赋值操作。
    
*   __isub__(self, other)-
    实现减法赋值操作。
    
*   __imul__(self, other)-
    实现乘法赋值操作。
    
*   __ifloordiv__(self, other)-
    实现使用 //= 操作符的整数除法赋值操作。
    
*   __idiv__(self, other)-
    实现使用 /= 操作符的除法赋值操作。
    
*   __itruediv__(self, other)-
    实现 _true_ 除法赋值操作，这个函数只有使用 from __future__ import division 时才有作用。
    
*   __imod__(self, other)-
    实现 %= 取余赋值操作。
    
*   __ipow__-
    实现 \*\*= 操作。
    
*   __ilshift__(self, other)-
    实现左移位赋值运算符 <<= 。
    
*   __irshift__(self, other)-
    实现右移位赋值运算符 >>= 。
    
*   __iand__(self, other)-
    实现按位与运算符 &= 。
    
*   __ior__(self, other)-
    实现按位或赋值运算符 | 。
    
*   __ixor__(self, other)-
    实现按位异或赋值运算符 ^= 。
    
*   example
    

    class Vector(object):
        def __init__(self, x):
            self.x = x
    
        def __iadd__(self, other):
            return [a + b for a, b in zip(self.x, other.x)]
    
    
    if __name__ == "__main__":
        v1 = Vector([1, 2, 3])
        v2 = Vector([1, 2, 3])
        v1 += v2
        print(v1)
    
        

##### 3.2.5 类型转换操作符

Python 也有一系列的魔法方法用于实现类似 float() 的内建类型转换函数的操作。它们是这些：

*   __int__(self)-
    实现到 int 的类型转换。
    
*   __long__(self)-
    实现到 long 的类型转换。
    
*   __float__(self)-
    实现到 float 的类型转换。
    
*   __complex__(self)-
    实现到 complex 的类型转换。
    
*   __oct__(self)-
    实现到八进制数的类型转换。
    
*   __hex__(self)-
    实现到十六进制数的类型转换。
    
*   __index__(self)-
    实现当对象用于切片表达式时到一个整数的类型转换。如果你定义了一个可能会用于切片操作的数值类型，你应该定义 __index__。
    
*   __trunc__(self)-
    当调用 math.trunc(self) 时调用该方法， __trunc__ 应该返回 self 截取到一个整数类型（通常是long类型）的值。
    

### 4 类的表示

使用字符串来表示类是一个相当有用的特性。在 Python 中有一些内建方法可以返回类的表示，相对应的，也有一系列魔法方法可以用来自定义在使用这些内建函数时类的行为。

*   __str__(self)-
    定义对类的实例调用 str() 时的行为。
*   __repr__(self)-
    定义对类的实例调用 repr() 时的行为。 str() 和 repr() 最主要的差别在于“目标用户”。 repr() 的作用是产生机器可读的输出（大部分情况下，其输出可以作为有效的Python代码），而 str() 则产生人类可读的输出。
*   __format__(self)-
    定义当类的实例用于新式字符串格式化时的行为，例如， “Hello, 0:abc!”.format(a) 会导致调用 a.__format__(“abc”) 。当定义你自己的数值类型或字符串类型时，你可能想提供某些特殊的格式化选项，这种情况下这个魔法方法会非常有用。
*   __hash__(self)-
    定义对类的实例调用 hash() 时的行为。它必须返回一个整数，其结果会被用于字典中键的快速比较。同时注意一点，实现这个魔法方法通常也需要实现 __eq__ ，并且遵守如下的规则： a == b 意味着 hash(a) == hash(b)。
*   __bool__(self)-
    定义对类的实例调用 bool() 时的行为，根据你自己对类的设计，针对不同的实例，这个魔法方法应该相应地返回 True 或 False。
*   __dir__(self)-
    定义对类的实例调用 dir() 时的行为，这个方法应该向调用者返回一个属性列表。一般来说，没必要自己实现 __dir__ 。但是如果你重定义了 __getattr__ 或者 __getattribute__ （下个部分会介绍），乃至使用动态生成的属性，以实现类的交互式使用，那么这个魔法方法是必不可少的。

到这里，我们基本上已经结束了魔法方法指南中无聊并且例子匮乏的部分。既然我们已经介绍了较为基础的魔法方法，是时候涉及更高级的内容了。

### 5 访问控制

很多从其他语言转向 Python 的人都抱怨 Python 的类缺少真正意义上的封装（即没办法定义私有属性然后使用公有的 getter 和 setter）。然而事实并非如此。实际上 Python 不是通过显式定义的字段和方法修改器，而是通过魔法方法实现了一系列的封装。

*   __getattr__(self, name)-
    当用户试图访问一个根本不存在（或者暂时不存在）的属性时，你可以通过这个魔法方法来定义类的行为。这个可以用于捕捉错误的拼写并且给出指引，使用废弃属性时给出警告（如果你愿意，仍然可以计算并且返回该属性），以及灵活地处理AttributeError。**只有当试图访问不存在的属性时它才会被调用**，所以这不能算是一个真正的封装的办法。
    
*   __setattr__(self, name, value)-
    和 __getattr__ 不同， __setattr__ 可以用于真正意义上的封装。它允许你自定义某个属性的赋值行为，不管这个属性存在与否，也就是说你可以对任意属性的任何变化都定义自己的规则。然后，一定要小心使用 __setattr__ ，这个列表最后的例子中会有所展示。
    
*   __delattr__(self, name)-
    这个魔法方法和 __setattr__ 几乎相同，只不过它是用于处理删除属性时的行为。和 _setattr__ 一样，使用它时也需要多加小心，防止产生无限递归（在 __delattr__ 的实现中调用 del self.name 会导致无限递归）。
    
*   __getattribute__(self, name)
    
    __getattribute__ 是属性访问拦截器，就是当这个类的属性被访问时，会自动调用类的 __getattribute__ 方法。即在上面代码中，当我调用实例对象aa的name属性时，不会直接打印，而是把name的值作为实参传进__getattribute__方法中（参数obj是我随便定义的，可任意起名），经过一系列操作后，再把name的值返回。Python中只要定义了继承object的类，就默认存在属性拦截器，只不过是拦截后没有进行任何操作，而是直接返回。所以我们可以自己改写__getattribute__方法来实现相关功能，比如查看权限、打印log日志等。如下代码，简单理解即可：
    

example

    # coding=utf-8
    class Rectangle:
        def __init__(self, width, height):
            self.width = width
            self.height = height
    
        def __setattr__(self, name, value):
            print("----设置%s属性----" % name)
            if name == "size":
                self.width, self.height = value
            else:
                self.__dict__[name] = value
    
        def __getattr__(self, name):
            print('----读取%s属性----' % name)
            if name == "size":
                return self.width, self.height
            else:
                raise AttributeError
    
        def __delattr__(self, name):
            print("----删除%s属性----" % name)
            if name == "size":
                self.__dict__['width'] = 0
                self.__dict__['height'] = 0
    
    
    rect = Rectangle(3, 4)
    print(rect.size)
    rect.size = 6, 8
    print(rect.width)
    del rect.size
    print(rect.size)
    
        

    ----设置width属性----
    ----设置height属性----
    ----读取size属性----
    (3, 4)
    ----设置size属性----
    ----设置width属性----
    ----设置height属性----
    6
    ----删除size属性----
    ----读取size属性----
    (0, 0)
    
        

自定义这些控制属性访问的魔法方法很容易导致问题，考虑下面这个例子:

    def __setattr__(self, name, value):
        self.name = value
        # 因为每次属性幅值都要调用 __setattr__()，所以这里的实现会导致递归
        # 这里的调用实际上是 self.__setattr('name', value)。因为这个方法一直
        # 在调用自己，因此递归将持续进行，直到程序崩溃
    
    
    def __setattr__(self, name, value):
        self.__dict__[name] = value  # 使用 __dict__ 进行赋值
        # 定义自定义行为
    
        

__getattribute__ 是属性访问拦截器，访问属性时被自动访问。下面看一个例子

    class Tree(object):
        def __init__(self, name):
            self.name = name
            self.cate = "plant"
    
        def __getattribute__(self, *args, **kwargs):
            if args[0] == "大树":
                print("log 大树")
                return "我爱大树"
            else:
                return object.__getattribute__(self, *args, **kwargs)
    
    
    tree = Tree("大树")
    print(tree.name)
    print(tree.cate)
    
        

当调用实例对象 aa 的 name 属性时，不会直接打印，而是把 name 的值作为实参传进 __getattribute__ 方法中。只要定义了继承 object 的类，就默认存在属性拦截器，默认拦截后没有进行任何操作，直接返回。所以我们可以自己改写 __getattribute__ 方法来实现相关功能，比如查看权限、打印log日志等。

**另外，注意注意：**-
使用 `__getattribute__`方法时，容易栽进无限递归的坑，直接看代码：

    class Tree(object):
        def __init__(self, name):
            self.name = name
            self.cate = "plant"
    
        def __getattribute__(self, obj):
            if obj.endswith("e"):
                return object.__getattribute__(self, obj)
            else:
                return self.call_wind()
    
        def call_wind(self):
            return "树大招风"
    
    
    tree = Tree("大树")
    print(tree.name)  # 因为name是以e结尾，所以返回的还是name，所以打印出"大树"
    print(tree.wind)  # 先调用__getattribute__方法，经过判断后，它返回的是self.call_wind()，又调用__getattribute__，无限递归
    
        

执行tree.wind时，先调用 __getattribute__ 方法，经判断返回 self.call_wind()，调用 call_wind 时，又要去调用__getattribute__ 方法，反反复复，无限递归，最终程序就挂了！

__getattr__ 与 __getattribute__ 的关系

*   优先级：__getattribute__ > __getattr__，只要定义了 __getattribute__方法，不管你访问一个存在的还是不存在的属性，都由这个方法返回。
    
*   如果定义了 __getattribute__，那么无论访问什么属性，都是通过这个函数获取，包括方法，t.f() 这种也是访问的这个函数，此时这个函数应该放回一个方法，如果返回一个数字，你会获得一个 TypeError: ‘int’ object is not callable 错误
    

### 6 自定义序列

有许多办法可以让你的 Python 类表现得像是内建序列类型（字典，元组，列表，字符串等）。这些魔法方式是目前为止我最喜欢的。它们给了你难以置信的控制能力，可以让你的类与一系列的全局函数完美结合。在了解激动人心的内容之前，首先你需要掌握一些预备知识。

#### 6.1. 预备知识

既然讲到创建自己的序列类型，就不得不说一说协议了。协议类似某些语言中的接口，里面包含的是一些必须实现的方法。在Python中，协议完全是非正式的，也不需要显式的声明，事实上，它们更像是一种参考标准。

为什么我们要讲协议？因为在 Python 中实现自定义容器类型需要用到一些协议。首先，不可变容器类型有如下协议：想实现一个不可变容器，你需要定义 __len__ 和 __getitem__。可变容器的协议除了上面提到的两个方法之外，还需要定义 __setitem__ 和 __delitem__ 。最后，如果你想让你的对象可以迭代，你需要定义 __iter__ ，这个方法返回一个迭代器。迭代器必须遵守迭代器协议，需要定义 __iter__ （返回它自己）和 next 方法。

#### 6.2 容器背后的魔法方法

- __len__(self)-
返回容器的长度，可变和不可变类型都需要实现。

*   __getitem__(self, key)-
    定义对容器中某一项使用 self\[key\] 的方式进行读取操作时的行为。这也是可变和不可变容器类型都需要实现的一个方法。它应该在键的类型错误式产生 TypeError 异常，同时在没有与键值相匹配的内容时产生 KeyError 异常。
    
*   __setitem__(self, key)-
    定义对容器中某一项使用 self\[key\] 的方式进行赋值操作时的行为。它是可变容器类型必须实现的一个方法，同样应该在合适的时候产生 KeyError 和 TypeError 异常。
    
*   __iter__(self, key)-
    它应该返回当前容器的一个迭代器。迭代器以一连串内容的形式返回，最常见的是使用 iter() 函数调用，以及在类似 for x in container: 的循环中被调用。迭代器是他们自己的对象，需要定义 __iter__ 方法并在其中返回自己。
    
*   __reversed__(self)-
    定义了对容器使用 reversed() 内建函数时的行为。它应该返回一个反转之后的序列。当你的序列类是有序时，类似列表和元组，再实现这个方法，
    
*   __contains__(self, item)-
    __contains__ 定义了使用 in 和 not in 进行成员测试时类的行为。你可能好奇为什么这个方法不是序列协议的一部分，原因是，如果 __contains__ 没有定义，Python就会迭代整个序列，如果找到了需要的一项就返回 True 。
    
*   __missing__(self ,key)-
    __missing__ 在字典的子类中使用，它定义了当试图访问一个字典中不存在的键时的行为（目前为止是指字典的实例，例如我有一个字典 d ， “george” 不是字典中的一个键，当试图访问 d\[“george’\] 时就会调用 d.__missing__(“george”) ）。
    

example：

    class FunctionalList(object):
        '''一个列表的封装类，实现了一些额外的函数式
        方法，例如head, tail, init, last, drop和take。'''
    
        def __init__(self, values=None):
            if values is None:
                self.values = []
            else:
                self.values = values
    
        def __len__(self):
            return len(self.values)
    
        def __getitem__(self, key):
            # 如果键的类型或值不合法，列表会返回异常
            return self.values[key]
    
        def __setitem__(self, key, value):
            self.values[key] = value
    
        def __delitem__(self, key):
            del self.values[key]
    
        def __iter__(self):
            return iter(self.values)
    
        def __reversed__(self):
            return reversed(self.values)
    
        def append(self, value):
            self.values.append(value)
    
        def head(self):
            # 取得第一个元素
            return self.values[0]
    
        def tail(self):
            # 取得除第一个元素外的所有元素
            return self.valuse[1:]
    
        def init(self):
            # 取得除最后一个元素外的所有元素
            return self.values[:-1]
    
        def last(self):
            # 取得最后一个元素
            return self.values[-1]
    
        def drop(self, n):
            # 取得除前n个元素外的所有元素
            return self.values[n:]
    
        def take(self, n):
            # 取得前n个元素
            return self.values[:n]
    
    
        

上面的例子展示了如何实现自己的序列。

### 7 可调用的对象

一个类实例要变成一个可调用对象，只需要实现一个特殊方法__call__()。允许一个类的实例像函数一样被调用。实质上说，这意味着 x() 与 x.__call__() 是相同的。注意 __call__ 参数可变。这意味着你可以定义 __call__ 为其他你想要的函数，无论有多少个参数。

__call__ 在那些类的实例经常改变状态的时候会非常有效。调用这个实例是一种改变这个对象状态的直接和优雅的做法。

    class Person(object):
        def __init__(self, name, age):
            self.name = name
            self.age = age
    
        def __call__(self, name, age):
            print('original Persion: name is %s, age is %s' % (self.name, self.age))
            self.name, self.age = name, age
            print('new Persion: name is %s, age is %s' % (self.name, self.age))
    
    
    per = Person("Tom", 20)
    per("Jerry", 18)
    
        

### 8 上下文管理器

在 python 中实现了__enter__ 和 __exit__方法，即支持上下文管理器协议。上下文管理器就是支持上下文管理器协议的对象，它是为了 with 而生。当 with 语句在开始运行时，会在上下文管理器对象上调用 __enter__方法。with ；语句运行结束后，会在上下文管理器对象上调用 __exit__ 方法

*   __enter__(self)-
    定义使用 with 声明创建的语句块最开始上下文管理器应该做些什么。注意 __enter__ 的返回值会赋给 with 声明的目标，也就是 as 之后的东西。
    
*   __exit__(self, exception_type, exception_value, traceback)-
    定义当 with 声明语句块执行完毕（或终止）时上下文管理器的行为。它可以用来处理异常，进行清理，或者做其他应该在语句块结束之后立刻执行的工作。如果语句块顺利执行， exception_type , exception_value 和 traceback 会是 None。
    

example

    class Log(object):
        def __init__(self, filename):
            self.filename = filename
            self.fp = None
    
        def logging(self, text):
            self.fp.write(text + '\n')
    
        def __enter__(self):
            print("__enter__")
            self.fp = open(self.filename, "a+")
            return self
    
        def __exit__(self, exc_type, exc_val, exc_tb):
            print("__exit__")
            self.fp.close()
    
        def __del__(self):
            print("__del__")
    
    
    with Log("sample.txt") as logfile:
        print("Main")
        logfile.logging("Test1")
        logfile.logging("Test2")
    
        

执行结果

    __enter__
    Main
    __exit__
    __del__
    
    Test1
    Test2
    

### 9 附录：如何调用魔法方法
|魔法方法|什么时候被调用|解释|
| ---- | ---- | ---- |
|__new__(cls [,…])|instance = MyClass(arg1, arg2)|__new__在实例创建时调用|
|__init__(self [,…])|instance = MyClass(arg1,arg2)|__init__在实例创建时调用|
|__pos__(self)|+self|一元加法符号|
|__neg__(self)|-self|一元减法符号|
|__invert__(self)|~self|按位取反|
|__index__(self)|x[self]|当对象用于索引时|
|__bool__(self)|bool(self)|对象的布尔值|
|__getattr__(self, name)|self.name #name不存在|访问不存在的属性|
|__setattr__(self, name)|self.name = val|给属性赋值|
|__delattr_(self, name)|del self.name|删除属性|
|__getattribute__(self,name)|self.name|访问任意属性|
|__getitem__(self, key)|self[key]|使用索引访问某个元素|
|__setitem__(self, key)|self[key] = val|使用索引给某个元素赋值|
|__delitem__(self, key)|del self[key]|使用索引删除某个对象|
|__iter__(self)|for x in self|迭代|
|__contains__(self, value)|value in self, value not in self|使用in进行成员测试|
|__call__(self [,…])|self(args)|“调用”一个实例|
|__enter__(self)|with self as x:|with声明的上下文管理器|
|__exit__(self, exc, val, trace)|with self as x:|with声明的上下文管理器|

[跳转到 Cubox 查看](https://cubox.pro/my/card?id=7121396858391364105)