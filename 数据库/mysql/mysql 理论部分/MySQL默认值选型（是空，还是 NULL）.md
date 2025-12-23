[技术分享 | MySQL默认值选型（是空，还是 NULL）](https://mp.weixin.qq.com/s?search_click_id=476317016237844579-1719996273682-8440597327&__biz=MzI3MTAxMTY5OA==&mid=2671915284&idx=1&sn=7007bd5f81b3c4470db1a3983bfc3e73&chksm=f07ecb09c709421ffff84258437e16ccbc60bede5378ca00e586b1719a4df1cf78ac243dada7&scene=7&subscene=10000&sessionid=1719994190&clicktime=1719996273&enterid=1719996273&ascene=65&fasttmpl_type=0&fasttmpl_fullversion=7278183-zh_CN-zip&fasttmpl_flag=0&realreporttime=1719996273726&devicetype=android-34&version=4.1.26.6024&nettype=cmnet&abtest_cookie=AAACAA%3D%3D&lang=zh_CN&countrycode=CN&exportkey=n_ChQIAhIQkygIF5mkQotQIYuiNho%2FMRLiAQIE97dBBAEAAAAAAP56AztL0EgAAAAOpnltbLcz9gKNyK89dVj0Yj3sU%2FWb6HdffCS5J5BXvxzLDdXAQ0GDihONrf4IUFhXOcOdTd%2BHyyQ9GLhwwlKMRQDJGaH6WU%2FkiKgxDRC%2FpNXVR0eyha%2BkMhjPPPFHXZ1rGhcX9m%2FLx0oH8O5iyTQ36CaE0myRRbPZMSW1C%2B1wkB%2BtnTRsBbqUqHfpfsF9GIePajZmLnLfmp90Zl3DrKnYmpNjuf7tEEV%2FiXqaN08q9jOmNJO4TTen3rLcpcUjh1DVP3UDPFxB%2BOJqi8U%3D&pass_ticket=uqKrb9ghhPnmE7bQ7sKYxJjQl86wEJ3B8i5RRJxjyomNRW5HYIHBF%2Bn9qCrlBrdS&wx_header=3&from=industrynews&platform=win&nwr_flag=1#wechat_redirect)

# 技术分享 | MySQL默认值选型（是空，还是 NULL）

如果对一个字段没有过多要求，是使用“”还是使用 NULL，一直是个让人困惑的问题。即使有前人留下的开发规范，但是能说清原因的也没有几个。NULL 是“”吗？在辨别 NULL 是不是空的这个问题上，感觉就像是在证明 1 + 1 是不是等于 2。

在 MySQL 中的 NULL 是一种特殊的数据。一个字段是否允许为 NULL，字段默认值是否为 NULL。  

主要有如下几种情况：

| 字段类型 | 表定义中设置方式 | 字段值 |
| --- | --- | --- |
| 数值类型 (INT/BIGINT) | Default NULL / Default 0 | NULL / NUM |
| 字符类型 (CHAR/VARCHAR) | Default NULL / Default '' / Default 'ab' | NULL / '' / String |

**1\. NULL 与空字符存储上的区别**

表中如果允许字段为 NULL，会为每行记录分配 NULL 标志位。NULL 除了在每行的行首存有 NULL 标志位，实际存储不占有任何空间。如果表中所有字段都是非 NULL，就不存在这个标示位了。网上有一些验证 MySQL 中 NULL 存储方式的文章，可以参考下。

**2\. NULL使用上的一些问题。** 

数值类型，对一个允许为NULL的字段进行min、max、sum、加减、order by、group by、distinct 等操作的时候。字段值为非 NULL 值时，操作很明确。如果使用 NULL， 需要清楚的知道如下规则：

**数值类型，以 INT 列为例**

**1) 在 min / max / sum / avg 中 NULL 值会被直接忽略掉，如下是测试结果，可能 min / max / sum 还比较可以理解，但 avg 真的是你想要的结果吗？**

   

```
1.   CREATE TABLE  t1  (  
    
2.     id   int(16) NOT NULL AUTO_INCREMENT,  
    
3.     name  varchar(20) DEFAULT NULL,  
    
4.     number   int(11) DEFAULT NULL,  
    
5.   PRIMARY KEY ( id )  
    
6.  ) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8; 
    

8.  select * from t1; 
    
9.  +------+----------+--------+ 
    
10.  | id   | name     | number | 
    
11.  +------+----------+--------+ 
    
12.  | 1 | zhangsan |   NULL | 
    
13.  | 2 | lisi     |   NULL | 
    
14.  | 3 | wangwu   | 0 | 
    
15.  | 4 | zhangliu | 4 | 
    
16.  +------+----------+--------+ 
    

18.  select max(number) from t1; 
    
19.  +-------------+ 
    
20.  | max(number) | 
    
21.  +-------------+ 
    
22.  | 4 | 
    
23.  +-------------+ 
    
24.  select min(number) from t1; 
    
25.  +-------------+ 
    
26.  | min(number) | 
    
27.  +-------------+ 
    
28.  | 0 | 
    
29.  +-------------+ 
    
30.  select sum(number) from t1; 
    
31.  +-------------+ 
    
32.  | sum(number) | 
    
33.  +-------------+ 
    
34.  | 4 | 
    
35.  +-------------+ 
    
36.  select avg(number) from t1; 
    
37.  +-------------+ 
    
38.  | avg(number) | 
    
39.  +-------------+ 
    
40.  | 2.0000 | 
    
41.  +-------------+ 
```    


   

**2) 对 NULL 做加减操作,如 1 + NULL，结果仍是 NULL**

   

```
1.  select  1+NULL; 
    
2.  +--------+ 
    
3.  | 1+NULL | 
    
4.  +--------+ 
    
5.  |   NULL | 
    
6.  +--------+ 
```    


   

**3) order by 以升序检索字段的时候 NULL 会排在最前面（倒序相反）**

   

```
1.  select * from t1 order by number; 
    
2.  +----+----------+--------+ 
    
3.  | id | name     | number | 
    
4.  +----+----------+--------+ 
    
5.  | 1 | zhangsan |   NULL | 
    
6.  | 2 | lisi     |   NULL | 
    
7.  | 3 | wangwu   | 0 | 
    
8.  | 4 | zhangliu | 4 | 
    
9.  +----+----------+--------+ 
    
10.  select * from t1 order by number desc; 
    
11.  +----+----------+--------+ 
    
12.  | id | name     | number | 
    
13.  +----+----------+--------+ 
    
14.  | 4 | zhangliu | 4 | 
    
15.  | 3 | wangwu   | 0 | 
    
16.  | 1 | zhangsan |   NULL | 
    
17.  | 2 | lisi     |   NULL | 
    
18.  +----+----------+--------+ 
```    


   

#### **4) group by / distinct 时，NULL 值被视为相同的值**

   

```
1.  select distinct(number) from t1; 
    
2.  +--------+ 
    
3.  | number | 
    
4.  +--------+ 
    
5.  |   NULL | 
    
6.  | 0 | 
    
7.  | 4 | 
    
8.  +--------+ 
    
9.  select number,count(*) from t1 group  by number; 
    
10.  +--------+----------+ 
    
11.  | number | count(*) | 
    
12.  +--------+----------+ 
    
13.  |   NULL | 2 | 
    
14.  | 0 | 1 | 
    
15.  | 4 | 1 | 
    
16.  +--------+----------+ 
```    


   

**字符类型，在使用 NULL 值的时候，也需要格外注意**

****1)**字段是字符时，你无法一目了然的区分这个值到底是 NULL ，还是字符串 'NULL'**

```
1.  insert into t1 (name,number) values ('NULL',5); 
2.  insert into t1 (number) values (6); 
4.  select * from t1 where number in (5,6); 
5.  +----+------+--------+ 
6.  | id | name | number | 
7.  +----+------+--------+ 
8.  | 5 | NULL | 5 | 
9.  | 6 | NULL | 6 | 
10.  +----+------+--------+ 
11.  select name is NULL from t1 where number=5; 
12.  +--------------+ 
13.  | name is NULL | 
14.  +--------------+ 
15.  | 0 | 
16.  +--------------+ 
17.  select name is NULL from t1 where number=6; 
18.  +--------------+ 
19.  | name is NULL | 
20.  +--------------+ 
21.  | 1 | 
22.  +--------------+ 
```    
   

**2) 统计包含 NULL 字段的值，NULL 值不包括在里面**

   

```
1.  select count(*) from t1; 
    
2.  +----------+ 
    
3.  | count(*) | 
    
4.  +----------+ 
    
5.  | 6 | 
    
6.  +----------+ 
    
7.  select count(name)from t1; 
    
8.  +-------------+ 
    
9.  | count(name) | 
    
10.  +-------------+ 
    
11.  | 5 | 
    
12.  +-------------+ 
    
13.  select * from t1 where name is  null; 
    
14.  +----+------+--------+ 
    
15.  | id | name | number | 
    
16.  +----+------+--------+ 
    
17.  | 6 | NULL | 6 | 
    
18.  +----+------+--------+ 
```    


   

**3) 如果你用 length 去统计一个 VARCHAR 的长度时，NULL 返回的将不是数字**

   

```
1.  select length(name) from t1 where name is  null; 
    
2.  +--------------+ 
    
3.  | length(name) | 
    
4.  +--------------+ 
    
5.  |         NULL | 
    
6.  +--------------+ 
```    


   

**总结：** 

NULL 本身是一个特殊值，MySQL 采用特殊的方法来处理 NULL 值。从理解肉眼判断，操作符运算等操作上，可能和我们预期的效果不一致。可能会给我们项目上的操作不符合预期。

你必须要使用 IS NULL / IS NOT NULL 这种与普通 SQL 大相径庭的方式去处理 NULL。

尽管在存储空间上，在索引性能上可能并不比空值差，但是为了避免其身上特殊性，给项目带来不确定因素，**因此建议默认值不要使用 NULL**。

![](https://mmbiz.qpic.cn/mmbiz_gif/q2OyEbfuqCvjeRVU61hhCDnnfO8yJWHPuTXjrCJy1JCxweeibVqPKicHrnVLKdC1h0WuRrFFOS4z1kowx8ulib6Sg/640?wx_fmt=gif)