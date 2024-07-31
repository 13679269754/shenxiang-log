                            新特性解读 | MySQL 8.0 新增 HINT 模式                                                                      

![](https://mmbiz.qlogo.cn/mmbiz_jpg/a4DRmyJYHOwBLsqY9O6WHwMP8KxB5ia2eGnY01RkUso7zl9QxIvOb8EEhIbaAswaFRxmzgnFIqdRiaT20aXNWDVA/0?wx_fmt=jpeg)

新特性解读 | MySQL 8.0 新增 HINT 模式
============================

[新特性解读 | MySQL 8.0 新增 HINT 模式--原页面](https://mp.weixin.qq.com/s?__biz=MzU2NzgwMTg0MA==&mid=2247484462&idx=1&sn=f224bd1d0f2285caf5356eacb95f16f0&ascene=4&devicetype=android-34&version=4.1.22.8029&abtest_cookie=AAACAA%3D%3D&lang=zh_CN&countrycode=CN&exportkey=n_ChQIAhIQVisbfhsqCiSC80jKLolarRLRAQIE97dBBAEAAAAAADRYAy3Kg0YAAAAOpnltbLcz9gKNyK89dVj04m8RiuCdB3tRewBdjeHtv2CEx3RNaDWkyN%2F8vPwgNEIJHdmpbroTAPFPBucDOEugGqbe%2BITZfoAJItAUhsyLDB0pn0n2OU%2BSVF6wxijAo%2BoNZSN12RbJGIlVTcxzLp%2FIjz2vBxjj6fcTDI1QNT9LRKtEPZyqCxpWDqmAqX88ifd2WhyzTvnpsrhFFGeIS4hMxPcq5Qk4rVkaVQlArzmIDCMoTSzNWOD9DFeQ&pass_ticket=jIHmDjE5%2FL9KVRKwrgLGF%2FrMLVm%2F8EDuoG7D6NvY%2BZKWxHEu5DxivFGOJzI3Q7TO&wx_header=3&from=industrynews&platform=win&nwr_flag=1#wechat_redirect)

**爱可生开源社区** 

微信号 ActiontechOSS

功能介绍 爱可生开源社区，提供稳定的MySQL企业级开源工具及服务，每年1024开源一款优良组件，并持续运营维护。

_2019-05-13 18:06_

在开始演示之前，我们先介绍下两个概念。

  

#### 概念一，数据的可选择性基数，也就是常说的cardinality值。

  

查询优化器在生成各种执行计划之前，得先从统计信息中取得相关数据，这样才能估算每步操作所涉及到的记录数，而这个相关数据就是cardinality。简单来说，就是每个值在每个字段中的唯一值分布状态。

  

比如表t1有100行记录，其中一列为f1。f1中唯一值的个数可以是100个，也可以是1个，当然也可以是1到100之间的任何一个数字。这里唯一值越的多少，就是这个列的可选择基数。

  

那看到这里我们就明白了，为什么要在基数高的字段上建立索引，而基数低的的字段建立索引反而没有全表扫描来的快。当然这个只是一方面，至于更深入的探讨就不在我这篇探讨的范围了。

  

  

#### 概念二，关于HINT的使用。

  

这里我来说下HINT是什么，在什么时候用。

  

HINT简单来说就是在某些特定的场景下人工协助MySQL优化器的工作，使她生成最优的执行计划。一般来说，优化器的执行计划都是最优化的，不过在某些特定场景下，执行计划可能不是最优化。

  

比如：表t1经过大量的频繁更新操作，（UPDATE,DELETE,INSERT），cardinality已经很不准确了，这时候刚好执行了一条SQL，那么有可能这条SQL的执行计划就不是最优的。为什么说有可能呢？

  

  

#### 来看下具体演示

  

**譬如，以下两条SQL，**

*   A：
    

```


1.  `select  *  from t1 where f1 =  20;`
    


```

*   B：
    

```


1.  `select  *  from t1 where f1 =  30;`
    


```

如果f1的值刚好频繁更新的值为30，并且没有达到MySQL自动更新cardinality值的临界值或者说用户设置了手动更新又或者用户减少了sample page等等，那么对这两条语句来说，可能不准确的就是B了。

这里顺带说下，**MySQL提供了自动更新和手动更新表cardinality值的方法**，因篇幅有限，需要的可以查阅手册。

  

那回到正题上，MySQL 8.0 带来了几个HINT，我今天就举个index_merge的例子。

**示例表结构：** 

```


1.  `mysql> desc t1;`
    
2.  `+------------+--------------+------+-----+---------+----------------+`
    
3.  `|  Field  |  Type  |  Null  |  Key  |  Default  |  Extra  |`
    
4.  `+------------+--------------+------+-----+---------+----------------+`
    
5.  `| id |  int(11)  | NO | PRI | NULL | auto_increment |`
    
6.  `| rank1 |  int(11)  | YES | MUL | NULL |  |`
    
7.  `| rank2 |  int(11)  | YES | MUL | NULL |  |`
    
8.  `| log_time | datetime | YES | MUL | NULL |  |`
    
9.  `| prefix_uid | varchar(100)  | YES |  | NULL |  |`
    
10.  `| desc1 | text | YES |  | NULL |  |`
    
11.  `| rank3 |  int(11)  | YES | MUL | NULL |  |`
    
12.  `+------------+--------------+------+-----+---------+----------------+`
    
13.  `7 rows in  set  (0.00 sec)`
    


```

**表记录数：**   

```


1.  `mysql>  select count(*)  from t1;`
    
2.  `+----------+`
    
3.  `| count(*)  |`
    
4.  `+----------+`
    
5.  `|  32768  |`
    
6.  `+----------+`
    
7.  `1 row in  set  (0.01 sec)`
    


```

**这里我们两条经典的SQL：** 

*   SQL C：
    

```sql

select  *  from t1 where rank1 =  1  or rank2 =  2  or rank3 =  2;
    

```

*   SQL D：
    

```sql


select  *  from t1 where rank1 =100  and rank2 =100  and rank3 =100;
    


```

表t1实际上在rank1,rank2,rank3三列上分别有一个二级索引。

  

**那我们来看SQL C的查询计划。** 

显然，没有用到任何索引，扫描的行数为32034，cost为3243.65。

```


1.  `mysql> explain  format=json select  *  from t1 where rank1 =1  or rank2 =  2  or rank3 =  2\G`
    
2.  `***************************  1. row ***************************`
    
3.  `EXPLAIN:  {`
    
4.   `"query_block":  {`
    
5.   `"select_id":  1,`
    
6.   `"cost_info":  {`
    
7.   `"query_cost":  "3243.65"`
    
8.   `},`
    
9.   `"table":  {`
    
10.   `"table_name":  "t1",`
    
11.   `"access_type":  "ALL",`
    
12.   `"possible_keys":  [`
    
13.   `"idx_rank1",`
    
14.   `"idx_rank2",`
    
15.   `"idx_rank3"`
    
16.   `],`
    
17.   `"rows_examined_per_scan":  32034,`
    
18.   `"rows_produced_per_join":  115,`
    
19.   `"filtered":  "0.36",`
    
20.   `"cost_info":  {`
    
21.   `"read_cost":  "3232.07",`
    
22.   `"eval_cost":  "11.58",`
    
23.   `"prefix_cost":  "3243.65",`
    
24.   `"data_read_per_join":  "49K"`
    
25.   `},`
    
26.   `"used_columns":  [`
    
27.   `"id",`
    
28.   `"rank1",`
    
29.   `"rank2",`
    
30.   `"log_time",`
    
31.   `"prefix_uid",`
    
32.   `"desc1",`
    
33.   `"rank3"`
    
34.   `],`
    
35.   ``"attached_condition":  "((`ytt`.`t1`.`rank1` = 1) or (`ytt`.`t1`.`rank2` = 2) or (`ytt`.`t1`.`rank3` = 2))"``
    
36.   `}`
    
37.   `}`
    
38.  `}`
    
39.  `1 row in  set,  1 warning (0.00 sec)`
    


```

  

**我们加上hint给相同的查询，再次看看查询计划。** 

这个时候用到了index_merge,union了三个列。扫描的行数为1103，cost为441.09，明显比之前的快了好几倍。

```


1.  `mysql> explain  format=json select  /*+ index_merge(t1) */  *  from t1 where rank1 =1  or rank2 =  2  or rank3 =  2\G`
    
2.  `***************************  1. row ***************************`
    
3.  `EXPLAIN:  {`
    
4.   `"query_block":  {`
    
5.   `"select_id":  1,`
    
6.   `"cost_info":  {`
    
7.   `"query_cost":  "441.09"`
    
8.   `},`
    
9.   `"table":  {`
    
10.   `"table_name":  "t1",`
    
11.   `"access_type":  "index_merge",`
    
12.   `"possible_keys":  [`
    
13.   `"idx_rank1",`
    
14.   `"idx_rank2",`
    
15.   `"idx_rank3"`
    
16.   `],`
    
17.   `"key":  "union(idx_rank1,idx_rank2,idx_rank3)",`
    
18.   `"key_length":  "5,5,5",`
    
19.   `"rows_examined_per_scan":  1103,`
    
20.   `"rows_produced_per_join":  1103,`
    
21.   `"filtered":  "100.00",`
    
22.   `"cost_info":  {`
    
23.   `"read_cost":  "330.79",`
    
24.   `"eval_cost":  "110.30",`
    
25.   `"prefix_cost":  "441.09",`
    
26.   `"data_read_per_join":  "473K"`
    
27.   `},`
    
28.   `"used_columns":  [`
    
29.   `"id",`
    
30.   `"rank1",`
    
31.   `"rank2",`
    
32.   `"log_time",`
    
33.   `"prefix_uid",`
    
34.   `"desc1",`
    
35.   `"rank3"`
    
36.   `],`
    
37.   ``"attached_condition":  "((`ytt`.`t1`.`rank1` = 1) or (`ytt`.`t1`.`rank2` = 2) or (`ytt`.`t1`.`rank3` = 2))"``
    
38.   `}`
    
39.   `}`
    
40.  `}`
    
41.  `1 row in  set,  1 warning (0.00 sec)`
    


```

  

**我们再看下SQL D的计划：** 

*   不加HINT，
    

```


1.  `mysql> explain format=json select  *  from t1 where rank1 =100  and rank2 =100  and rank3 =100\G`
    
2.  `***************************  1. row ***************************`
    
3.  `EXPLAIN:  {`
    
4.   `"query_block":  {`
    
5.   `"select_id":  1,`
    
6.   `"cost_info":  {`
    
7.   `"query_cost":  "534.34"`
    
8.   `},`
    
9.   `"table":  {`
    
10.   `"table_name":  "t1",`
    
11.   `"access_type":  "ref",`
    
12.   `"possible_keys":  [`
    
13.   `"idx_rank1",`
    
14.   `"idx_rank2",`
    
15.   `"idx_rank3"`
    
16.   `],`
    
17.   `"key":  "idx_rank1",`
    
18.   `"used_key_parts":  [`
    
19.   `"rank1"`
    
20.   `],`
    
21.   `"key_length":  "5",`
    
22.   `"ref":  [`
    
23.   `"const"`
    
24.   `],`
    
25.   `"rows_examined_per_scan":  555,`
    
26.   `"rows_produced_per_join":  0,`
    
27.   `"filtered":  "0.07",`
    
28.   `"cost_info":  {`
    
29.   `"read_cost":  "478.84",`
    
30.   `"eval_cost":  "0.04",`
    
31.   `"prefix_cost":  "534.34",`
    
32.   `"data_read_per_join":  "176"`
    
33.   `},`
    
34.   `"used_columns":  [`
    
35.   `"id",`
    
36.   `"rank1",`
    
37.   `"rank2",`
    
38.   `"log_time",`
    
39.   `"prefix_uid",`
    
40.   `"desc1",`
    
41.   `"rank3"`
    
42.   `],`
    
43.   ``"attached_condition":  "((`ytt`.`t1`.`rank3` = 100) and (`ytt`.`t1`.`rank2` = 100))"``
    
44.   `}`
    
45.   `}`
    
46.  `}`
    
47.  `1 row in  set,  1 warning (0.00 sec)`
    


```

*   加了HINT，
    

```


1.  `mysql> explain format=json select  /*+ index_merge(t1)*/  *  from t1 where rank1 =100  and rank2 =100  and rank3 =100\G`
    
2.  `***************************  1. row ***************************`
    
3.  `EXPLAIN:  {`
    
4.   `"query_block":  {`
    
5.   `"select_id":  1,`
    
6.   `"cost_info":  {`
    
7.   `"query_cost":  "5.23"`
    
8.   `},`
    
9.   `"table":  {`
    
10.   `"table_name":  "t1",`
    
11.   `"access_type":  "index_merge",`
    
12.   `"possible_keys":  [`
    
13.   `"idx_rank1",`
    
14.   `"idx_rank2",`
    
15.   `"idx_rank3"`
    
16.   `],`
    
17.   `"key":  "intersect(idx_rank1,idx_rank2,idx_rank3)",`
    
18.   `"key_length":  "5,5,5",`
    
19.   `"rows_examined_per_scan":  1,`
    
20.   `"rows_produced_per_join":  1,`
    
21.   `"filtered":  "100.00",`
    
22.   `"cost_info":  {`
    
23.   `"read_cost":  "5.13",`
    
24.   `"eval_cost":  "0.10",`
    
25.   `"prefix_cost":  "5.23",`
    
26.   `"data_read_per_join":  "440"`
    
27.   `},`
    
28.   `"used_columns":  [`
    
29.   `"id",`
    
30.   `"rank1",`
    
31.   `"rank2",`
    
32.   `"log_time",`
    
33.   `"prefix_uid",`
    
34.   `"desc1",`
    
35.   `"rank3"`
    
36.   `],`
    
37.   ``"attached_condition":  "((`ytt`.`t1`.`rank3` = 100) and (`ytt`.`t1`.`rank2` = 100) and (`ytt`.`t1`.`rank1` = 100))"``
    
38.   `}`
    
39.   `}`
    
40.  `}`
    
41.  `1 row in  set,  1 warning (0.00 sec)`
    


```

对比下以上两个，加了HINT的比不加HINT的cost小了100倍。

  

**总结下，就是说表的cardinality值影响这张的查询计划，如果这个值没有正常更新的话，就需要手工加HINT了。相信MySQL未来的版本会带来更多的HINT。** 

  