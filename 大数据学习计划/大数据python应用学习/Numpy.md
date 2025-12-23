
## 一. ndarray  对象

```
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# 创建数组对象




```



## 二. 数组对象方法

```
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


array1 = np.random.randint(1, 100, 10)

print(array1)

# **计算总和、均值和中位数**

# **极值、全距和四分位距离**

# **方差、标准差和变异系数**

# scipy的方法 几何平均值、调和平均值、去尾平均值、众数、变异系数、偏态、峰度等
```

## 三. 数组的运算

# 表1：通用一元函数
| 函数 | 说明 |
| ---- | ---- |
| abs / fabs | 求绝对值的函数 |
| sqrt | 求平方根的函数，相当于array ** 0.5 |
| square | 求平方的函数，相当于array ** 2 |
| exp | 计算e^x的函数 |
| log / log10 / log2 | 对数函数（e为底 / 10为底 / 2为底） |
| sign | 符号函数（1 - 正数；0 - 零；-1 - 负数） |
| ceil / floor | 上取整 / 下取整 |
| isnan | 返回布尔数组，NaN对应True，非NaN对应False |
| isfinite / isinf | 判断数值是否为无穷大的函数 |
| cos / cosh / sin | 三角函数 |
| sinh / tan / tanh | 三角函数 |
| arccos / arccosh / arcsin | 反三角函数 |
| arcsinh / arctan / arctanh | 反三角函数 |
| rint / round | 四舍五入函数 |

# 表2：通用二元函数
| 函数                             | 说明                                                                              |
| ------------------------------ | ------------------------------------------------------------------------------- |
| add(x, y) / subtract(x, y)     | 加法函数 / 减法函数                                                                     |
| multiply(x, y) / divide(x, y)  | 乘法函数 / 除法函数                                                                     |
| floor_divide(x, y) / mod(x, y) | 整除函数 / 求模函数                                                                     |
| allclose(x, y)                 | 检查数组x和y元素是否几乎相等                                                                 |
| power(x, y)                    | 数组x的元素$x_i$和数组y的元素$y_i$，计算$x_i^{y_i}$                                           |
| maximum(x, y) / fmax(x, y)     | 两两比较元素获取最大值 / 获取最大值（忽略NaN）                                                      |
| minimum(x, y) / fmin(x, y)     | 两两比较元素获取最小值 / 获取最小值（忽略NaN）                                                      |
| dot(x, y)                      | 点积运算（数量积，通常记为$\cdot$，用于欧几里得空间（Euclidean space））                                 |
| inner(x, y)                    | 内积运算（内积的含义要高于点积，点积相当于是内积在欧几里得空间$\mathbb{R}^n$的特例，而内积可以推广到赋范向量空间，只要它满足平行四边形法则即可） |
| cross(x, y)                    | 叉积运算（向量积，通常记为$\times$，运算结果是一个向量）                                                |
| outer(x, y)                    | 外积运算（张量积，通常记为$\bigotimes$，运算结果通常是一个矩阵）                                          |
| intersect1d(x, y)              | 计算x和y的交集，返回这些元素构成的有序数组                                                          |
| union1d(x, y)                  | 计算x和y的并集，返回这些元素构成的有序数组                                                          |
| in1d(x, y)                     | 返回由判断x的元素是否在y中得到的布尔值构成的数组                                                       |
| setdiff1d(x, y)                | 计算x和y的差集，返回这些元素构成的数组                                                            |
| setxor1d(x, y)                 | 计算x和y的对称差，返回这些元素构成的数组                                                           |