| operator | createtime  | updatetime  |
| -------- | ----------- | ----------- |
| shenx    | 2024-12月-23 | 2024-12月-23 |
| ... | ... | ... |
---
# mysql create table on update的触发机制

[toc]

## mysql create table on update

> `ON UPDATE`很多人都用过，但什么时候不触发更新、更新有什么坏处等细节，却不一定都清楚。  
> 读完本文，您将掌握`ON UPDATE`的用法、新版本特性、使用陷阱和优缺点。

### 作用

若一个时间列设置了自动更新`ON UPDATE`，当数据行发生更新时，数据库自动设置该列的值为当前时间[1](#fn1)。

### 支持的字段类型

从`MySQL 5.6.5`开始，`TIMESTAMP`和`DATETIME`列都支持自动更新，且一个表可设置多个自动更新列。

在`MySQL 5.6.5`之前:

*   只有`TIMESTAMP`支持自动更新
*   每个表**只能有一个**自动更新的时间列
*   不允许同时存在两个列：其中一个设置了`DEFAULT CURRENT_TIMESTAMP`，另一个设置了`ON UPDATE CURRENT_TIMESTAMP`

下面主要介绍`MySQL 5.6.5`及之后版本的自动更新列用法。

### 语法

```
col DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
col2 TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP


```

### 注意

#### 自动更新的触发时机

注意[时间戳](https://so.csdn.net/so/search?q=%E6%97%B6%E9%97%B4%E6%88%B3&spm=1001.2101.3001.7020)列“自动更新”的时机：

*   插入时如未指定该列值时。
*   当该行数据其他列有值变化时，如`update`。
    *   如果有更新操作、但其他列值并未变化，不会触发。此时要更新时间戳，需在SQL中指定新值给它（例如`CURRENT_TIMESTAMP`）
        
        > 如`update table set column_tmt = CURRENT_TIMESTAMP`
        
    *   如果更新时不想触发，可显式设置时间戳列为当前值。
        
        > 如`update table set column_a = 'xxx', column_tmt = column_tmt`
        

#### 自动更新的时间值

`CURRENT_TIMESTAMP`还可以替换为任何等价标识符，如`CURRENT_TIMESTAMP()`、`NOW()`、`LOCALTIME`等（所有获取当前时间的标识符，可参考[《MySQL日期与时间函数（日期/时间格式化、增减、对比、时区、UTC和UNIX时间）》](https://learn.blog.csdn.net/article/details/102598667)）

自动更新值时，`CURRENT_TIMESTAMP`表示的是SQL执行时的时间。如果要写入实际每行数据发生变更的时间，需要执行SQL时手工设置自动更新列值为`SYSDATE()`，自动更新列的声明中、`CURRENT_TIMESTAMP()`不能替换为`SYSDATE()`。

#### `DEFAULT`设置

`DEFAULT CURRENT_TIMESTAMP`为该列设置默认值。

`DEFAULT`后的`CURRENT_TIMESTAMP`可替换为常量值，如`2019-11-20 22:21:00`；

如果未设置`DEFAULT`，自动更新仍然生效，只是没有默认值而已。`TIMESTAMP`的默认值为0、除非声明为`NULL`才会默认`NULL`，而`DATETIME`默认为`NULL`、设置为`NOT NULL`时默认值为0.

> 系统变量`explicit_defaults_for_timestamp`会影响默认值情况。

为了避免一些不必要的疏忽，建议自动更新列设置`DEFAULT CURRENT_TIMESTAMP`。

#### 精度

与`TIMESTAMP`/`DATETIME`类型、及`TIMESTAMP()`函数一样，支持最多6位小数位。

> *   各时间类型的精度，可参考[《MySQL字段长度、取值范围、存储开销（5.6/5.7/8.x的主要类型，区分显示宽度/有无符号/定点浮点、不同时间类型）》](https://learn.blog.csdn.net/article/details/90675967)中的“日期与时间”部分
> *   时间函数相关，可参考[《MySQL日期与时间函数（日期/时间格式化、增减、对比、时区、UTC和UNIX时间）》](https://learn.blog.csdn.net/article/details/102598667)）

设置小数位时，各部分的精度必需保持一致，如：

```
col DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6)`

```

如果精度不一致、或部分设置了精度部分未设置，会报错`ERROR 1067 (42000): Invalid default value for 'tmt'`。

### 总结

自动更新列有好处也有不足：  
**好处**：无需依赖业务实现时间戳，所有的db操作都会自动记录，便于排查问题。  
**不足**：数据库服务器和业务服务器可能存在时间差，导致业务变动的时间与数据库时间戳存在差异，给实际维护和使用带来障碍。只能尽可能的校准服务器时间，但不能绝对避免该问题。

尽管如此，数据库设计时仍建议增加一个自动更新列作为时间戳，忠实反映数据库的最后变化时间。
