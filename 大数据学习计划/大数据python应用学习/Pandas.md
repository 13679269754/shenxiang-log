## Series

```python

import numpy as np
import pandas as pd

### 创建

# 1
ser1 = pd.Series(data=[120, 380, 250, 360], index=['一季度', '二季度', '三季度', '四季度'])
# 2
ser2 = pd.Series({'一季度': 320, '二季度': 180, '三季度': 300, '四季度': 405})
# 3


### 索引运算
ser1[2] # 下标索引
ser1['三季度'] # 自定义索引
ser2[1:3] # 切片
ser2[['二季度', '四季度']] # 花式索引
ser2[ser2 >= 500] # 布尔索引

```

| 属性                 | 说明                                                 |
| -------------------- | ---------------------------------------------------- |
| dtype / dtypes       | 返回Series对象的数据类型                             |
| hasnans              | 判断Series对象中有没有空值                           |
| at / iat             | 通过索引访问Series对象中的单个值                     |
| loc / iloc           | 通过索引访问Series对象中的单个值或一组值             |
| index                | 返回Series对象的索引（Index对象）                    |
| is_monotonic         | 判断Series对象中的数据是否单调                       |
| is_monotonic_increasing | 判断Series对象中的数据是否单调递增                 |
| is_monotonic_decreasing | 判断Series对象中的数据是否单调递减                 |
| is_unique            | 判断Series对象中的数据是否独一无二                   |
| size                 | 返回Series对象中元素的个数                           |
| values               | 以ndarray的方式返回Series对象中的值（ndarray对象）   |

### Series统计相关

```python

print(ser2.count())   # 计数
print(ser2.sum())     # 求和
print(ser2.mean())    # 求平均
print(ser2.median())  # 找中位数
print(ser2.max())     # 找最大
print(ser2.min())     # 找最小
print(ser2.std())     # 求标准差
print(ser2.var())     # 求方差

ser2.describe()  # 因为`describe()`返回的也是一个`Series`对象
ser2.describe()['mean'] # 获取平均值

ser3 = pd.Series(data=['apple', 'banana', 'apple', 'pitaya', 'apple', 'pitaya', 'durian'])
ser3.value_counts() # 聚合计数
ser3.nunique()
ser3.mode()

ser4 = pd.Series(data=[10, 20, np.nan, 30, np.nan])
ser4.isna()
ser4.notna() 

ser4.fillna(value=40)

ser3.duplicated() # 找出重复的数据

ser3.drop_duplicates() # 删除重复数据

```

### Series.map与Series.apply

```python 

ser6.map('I am a {}'.format, na_action='ignore')

ser7.apply(np.square)
ser7.apply(lambda x, value: x - value, args=(5, ))

```

### 其他
```python 

ser8 = pd.Series(
    data=[35, 96, 12, 57, 25, 89], 
    index=['grape', 'banana', 'pitaya', 'apple', 'peach', 'orange']
)
ser8.sort_values()  # 按值从小到大排序
ser8.sort_index(ascending=False)  # 按索引从大到小排序
ser8.nlargest(3)  # 值最大的3个
ser8.nsmallest(2)  # 值最小的2个

```


## DataFrame

```

# 创建

## 二位数组创建
scores = np.random.randint(60, 101, (5, 3))
courses = ['语文', '数学', '英语']
stu_ids = np.arange(1001, 1006)
df1 = pd.DataFrame(data=scores, columns=courses, index=stu_ids)

## 字典创建
scores = {
    '语文': [62, 72, 93, 88, 93],
    '数学': [95, 65, 86, 66, 87],
    '英语': [66, 75, 82, 69, 82],
}
stu_ids = np.arange(1001, 1006)
df2 = pd.DataFrame(data=scores, index=stu_ids)

```

### 读取CSV文件创建DataFrame对象

可以通过`pandas` 模块的`read_csv`函数来读取 CSV 文件，`read_csv`函数的参数非常多，下面介绍几个比较重要的参数。

- `sep` / `delimiter`：分隔符，默认是`,`。
- `header`：表头（列索引）的位置，默认值是`infer`，用第一行的内容作为表头（列索引）。
- `index_col`：用作行索引（标签）的列。
- `usecols`：需要加载的列，可以使用序号或者列名。
- `true_values` / `false_values`：哪些值被视为布尔值`True` / `False`。
- `skiprows`：通过行号、索引或函数指定需要跳过的行。
- `skipfooter`：要跳过的末尾行数。
- `nrows`：需要读取的行数。
- `na_values`：哪些值被视为空值。
- `iterator`：设置为`True`，函数返回迭代器对象。
- `chunksize`：配合上面的参数，设置每次迭代获取的数据体量。

#### 读取关系数据库二维表创建DataFrame对象


`pandas`模块的`read_sql`函数可以通过 SQL 语句从数据库中读取数据创建`DataFrame`对象，该函数的第二个参数代表了需要连接的数据库。对于 MySQL 数据库，我们可以通过`pymysql`或`mysqlclient`来创建数据库连接（需要提前安装好三方库），得到一个`Connection` 对象，而这个对象就是`read_sql`函数需要的第二个参数，代码如下所示。

代码：

```python
import pymysql

# 创建一个MySQL数据库的连接对象
conn = pymysql.connect(
    host='101.42.16.8', port=3306,
    user='guest', password='Guest.618',
    database='hrs', charset='utf8mb4'
)
# 通过SQL从数据库二维表读取数据创建DataFrame
df5 = pd.read_sql('select * from tb_emp', conn, index_col='eno')
```


SQLAlchemy 方式访问数据库

```python
%pip install sqlalchemy

from sqlalchemy import create_engine

# 通过指定的URL（统一资源定位符）访问数据库
engine = create_engine('mysql+pymysql://guest:Guest.618@101.42.16.8:3306/hrs')
# 直接通过表名加载整张表的数据
df5 = pd.read_sql('tb_emp', engine, index_col='eno')

df6 = pd.read_sql('select dno, dname, dloc from tb_dept', engine, index_col='dno')

engine.connect().close()


```


### 基本属性和方法

```

from sqlalchemy import create_engine

engine = create_engine('mysql+pymysql://guest:Guest.618@101.42.16.8:3306/hrs')
dept_df = pd.read_sql_table('tb_dept', engine, index_col='dno')
emp_df = pd.read_sql_table('tb_emp', engine, index_col='eno')
emp2_df = pd.read_sql_table('tb_emp2', engine, index_col='eno')

emp_df.info()

emp_df.head() # 默认5行
emp_df.tail() # 默认5行

emp_df.iloc[1] # 索引下标
emp_df.loc[2056] # 设置的索引

emp_df[['ename', 'job']] # 多列

emp_df.loc[[2056, 7800, 3344]] # 多行

emp_df.loc[2056, 'job'] # 单元格 emp_df['job'][2056] or emp_df.loc[2056]['job']

emp_df[emp_df.sal > 3500] # 布尔索引

emp_df.query('sal > 3500 and dno == 20') # 多条件布尔索引


```

| 属性名        | 说明                    |
| ---------- | --------------------- |
| at / iat   | 通过标签获取DataFrame中的单个值。 |
| columns    | DataFrame对象列的索引       |
| dtypes     | DataFrame对象每一列的数据类型   |
| empty      | DataFrame对象是否为空       |
| loc / iloc | 通过标签获取DataFrame中的一组值。 |
| ndim       | DataFrame对象的维度        |
| shape      | DataFrame对象的形状（行数和列数） |
| size       | DataFrame对象中元素的个数     |
| values     | DataFrame对象的数据对应的二维数组 |


### 数据重塑

```

all_emp_df = pd.concat([emp_df, emp2_df]) # 拼接数据

all_emp_df.reset_index(inplace=True)

pd.merge(all_emp_df, dept_df, how='inner', on='dno') # merge方法合并数据 `left`、`right`、`inner`、`outer` 

```

### 数据清洗

#### 空值处理
```

emp_df.isnull() # 判空 emp_df.isna()


# 删除
emp_df.dropna() 
emp_df.dropna(axis=1)
# 空值填充
emp_df.fillna(value=0)
 
```

#### 重复值
```
# 该方法在不指定参数时默认判断行索引是否重复，我们也可以指定根据部门名称`dname`判断部门是否重复
dept_df.duplicated('dname')

dept_df.drop_duplicates('dname')
# 该方法的`keep`参数可以控制在遇到重复值时，保留第一项还是保留最后一项，或者多个重复项一个都不用保留，全部删除掉
dept_df.drop_duplicates('dname', keep='last')
# 添加了参数`inplace=True`,该方法不会返回新的`DataFrame`对象，而是在原来的`DataFrame`对象上直接删除
all_emp_df.drop_duplicates(['ename', 'job'], inplace=True)
```
#### 异常值
```python
# 检测异常值
# Z-score
def detect_outliers_zscore(data, threshold=3):
    avg_value = np.mean(data)
    std_value = np.std(data)
    z_score = np.abs((data - avg_value) / std_value)
    return data[z_score > threshold]
 
# IQR   
def detect_outliers_iqr(data, whis=1.5):
    q1, q3 = np.quantile(data, [0.25, 0.75])
    iqr = q3 - q1
    lower, upper = q1 - whis * iqr, q3 + whis * iqr
    return data[(data < lower) | (data > upper)]

# 删除
# 月薪低于`2000`或高于`8000`的是员工表中的异常值，可以用下面的代码删除对应的记录
emp_df.drop(emp_df[(emp_df.sal > 8000) | (emp_df.sal < 2000)].index)

# 月薪为`1800`和`9000`的替换为月薪的平均值，补贴为`800`的替换为`1000`
avg_sal = np.mean(emp_df.sal).astype(int)
emp_df.replace({'sal': [1800, 9000], 'comm': 800}, {'sal': avg_sal, 'comm': 1000})

```

#### 预处理

**读取**
```
sales_df = pd.read_excel(
    'data/2020年销售数据.xlsx',
    usecols=['销售日期', '销售区域', '销售渠道', '品牌', '销售额']
)
sales_df.info()
```


**日期处理**
```
sales_df['月份'] = sales_df['销售日期'].dt.month
sales_df['季度'] = sales_df['销售日期'].dt.quarter
sales_df['星期'] = sales_df['销售日期'].dt.weekday
```

**数据预览**
```
jobs_df.head()
```

**数据筛选**
```
jobs_df = jobs_df[jobs_df.positionName.str.contains('数据分析')]
jobs_df.shape
```

**数据转换计算**
```
temp_df = jobs_df.salary.str.extract(r'(\d+)[kK]?-(\d+)[kK]?').applymap(int)
temp_df.apply(np.mean, axis=1)
```

**数据分箱**
```
bins = np.arange(90, 126, 5)
pd.cut(luohu_df.score, bins, right=False)

# **说明**：`cut`函数的`right`参数默认值为`True`，表示箱子左开右闭；修改为`False`可以让箱子右边界为开区间，左边界为闭区间，大家看看下面的输出就明白了。


id
1       [120, 125)
2       [120, 125)
3       [115, 120)
4       [115, 120)
5       [115, 120)
           ...                                                                                                                                                                                                                                                   
6015      [90, 95)
6016      [90, 95)
6017      [90, 95)
6018      [90, 95)
6019      [90, 95)
Name: score, Length: 6019, dtype: category
Categories (7, interval[int64, left]): [[90, 95) < [95, 100) < [100, 105) < [105, 110) < [110, 115) < [115, 120) < [120, 125)]

````

### 数据透视

```
# 平均值
df.mean()
df.mean(axis=1)

# 方差
df.var()

# 统计值
df.describe()

        语文        数学         英语
count   5.000000	5.000000	5.000000
mean    86.200000	69.400000	78.200000
std     12.696456	19.488458	16.300307
min     72.000000	51.000000	54.000000
25%     74.000000	54.000000	73.000000
50%     89.000000	70.000000	79.000000
75%     96.000000	72.000000	88.000000
max     100.000000	100.000000	97.000000
```

#### 排序和取头部值
```
# 排序
df.sort_values(by='语文', ascending=False)

# 头尾数据
df.nlargest(3, '语文')

df.nsmallest(3, '数学')
```

#### 分组聚合

```
df = pd.read_excel('data/2020年销售数据.xlsx')
df.head()
```

```
# 分组求和
df.groupby('销售区域').销售额.sum()

# 如果我们要统计每个月的销售总额，我们可以将“销售日期”作为groupby`方法的参数，当然这里需要先将“销售日期”处理成月，代码和结果如下所示。

df.groupby(df['销售日期'].dt.month).销售额.sum()
```


```
df.groupby('销售区域')[['销售额', '销售数量']].agg({
    '销售额': 'sum', '销售数量': ['max', 'min']
})

           销售额  销售数量    
           sum    max min
销售区域                   
上海    11610489  100  10
北京    12477717  100  10
安徽      895463   98  16
广东     1617949   98  10
江苏     2304380  100  11
浙江      687862   95  20
福建    10178227  100  10

```

#### 透视表和交叉表

**透视表**

```
df['月份'] = df['销售日期'].dt.month
pd.pivot_table(df, index=['销售区域', '月份'], values='销售额', aggfunc='sum')


# 上面的操作结果是一个`DataFrame`，但也是一个长长的“窄表”，如果希望做成一个行比较少列比较多的“宽表”，可以将`index`参数中的列放到`columns`参数中，代码如下所示。
pd.pivot_table(df, index='销售区域', columns='月份', values='销售额', aggfunc='sum', fill_value=0)

```

**交叉表**

```

sales_area, sales_month, sales_amount = df['销售区域'], df['月份'], df['销售额']

# 使用`crosstab`函数生成交叉表。
pd.crosstab(index=sales_area, columns=sales_month, values=sales_amount, aggfunc='sum').fillna(0).astype('i8')

# 上面的代码使用了`DataFrame`对象的`fillna`方法将空值处理为0，再使用`astype`方法将数据类型处理成整数。

```


### 数据呈现

### 计算同比环比

### 窗口计算

### 相关性判定

### 范围索引

范围索引是由具有单调性的整数构成的索引，我们可以通过`RangeIndex`构造器来创建范围索引

### 分类索引

### 多级索引

### 间隔索引

### 日期时间索引
