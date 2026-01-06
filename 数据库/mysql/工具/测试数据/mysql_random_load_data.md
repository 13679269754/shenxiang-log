| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-7月-02 | 2025-7月-02  |
| ... | ... | ... |
---
# mysql_random_load_data.md

[toc]

[MySQL随机数据填充工具 mysql_random_data_load-腾讯云开发者社区-腾讯云](https://cloud.tencent.com/developer/article/1986727) 

 
percona出品的小工具，用于随机生成测试数据。

mysql\_random\_data\_load 将加载（插入）“n”条记录到源表，并根据数据类型用随机数据填充它。所以这个工具不会像 sysbench 那样确定预定义的表列或数据类型。它将根据列数据类型将数据插入表中。因此，我们可以根据我们的自定义需求生成随机数据。表格可以有任意数量的不同数据类型的列，此工具将根据列的数据类型生成数据并插入数据。

如果字段大小小于10，程序将生成一个随机的“名字” 如果字段大小大于10且小于30，程序将生成一个随机的“全名” 如果字段大小>30，程序将生成一个“lorem ipsum”段落，最多包含100个字符。

该程序可以检测一个字段是否接受 NULL，如果接受，它将随机生成 NULL（约 10% 的值）。

示例：

创建一个测试的空表

代码语言：javascript

代码运行次数：0

运行

AI代码解释

复制

```
create database test;
use test;
CREATE TABLE `t3` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tcol01` tinyint DEFAULT NULL,
  `tcol02` smallint DEFAULT NULL,
  `tcol03` mediumint DEFAULT NULL,
  `tcol04` int DEFAULT NULL,
  `tcol05` bigint DEFAULT NULL,
  `tcol06` float DEFAULT NULL,
  `tcol07` double DEFAULT NULL,
  `tcol08` decimal(10,2) DEFAULT NULL,
  `tcol09` date DEFAULT NULL,
  `tcol10` datetime DEFAULT NULL,
  `tcol11` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `tcol12` time DEFAULT NULL,
  `tcol13` year DEFAULT NULL,
  `tcol14` varchar(100) DEFAULT NULL,
  `tcol15` char(2) DEFAULT NULL,
  `tcol16` blob,
  `tcol17` text,
  `tcol18` mediumtext,
  `tcol19` mediumblob,
  `tcol20` longblob,
  `tcol21` longtext,
  `tcol22` mediumtext,
  `tcol23` varchar(3) DEFAULT NULL,
  `tcol24` varbinary(10) DEFAULT NULL,
  `tcol25` enum('a','b','c') DEFAULT NULL,
  `tcol26` set('red','green','blue') DEFAULT NULL,
  `tcol27` float(5,3) DEFAULT NULL,
  `tcol28` double(4,2) DEFAULT NULL
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
```

开始造数据

代码语言：javascript

代码运行次数：0

运行

AI代码解释

复制

```sql
usage： mysql_random_data_load <database> <table> <number of rows> [options...]

需要先人工创建 test.t3 这个表， mysql_random_data_load不关心这个表有哪些列，它都能自动进行填充。

# 如果要看详细过程，可以再加上参数 --debug
./mysql_random_data_load test t3 100000 --user=dts --password=dts --port=3316  --max-threads=4 --bulk-size=1000 --host=192.168.31.181  

填充后效果：
test> select count(*) from t3;                                                                                          
+----------+
| count(*) |
+----------+
| 100000   |
+----------+
1 row in set

test> select * from t3 order by id desc limit 1\G                                                                       
***************************[ 1. row ]***************************
id     | 100000
tcol01 | 13
tcol02 | 65
tcol03 | 479465
tcol04 | 589922315
tcol05 | 1258706440113351142
tcol06 | 2.77057
tcol07 | 0.599966
tcol08 | 5.42
tcol09 | 2022-04-23
tcol10 | 2021-08-22 07:07:54
tcol11 | 2021-06-10 03:07:50
tcol12 | 3:17:07
tcol13 | 2022
tcol14 | aut quam excepturi quidem corporis suscipit illum!
tcol15 | Sh
tcol16 | adipisci ipsam iste a.
tcol17 | adipisci rerum ut sapiente laudantium velit.
tcol18 | eos est est nam eius aspernatur.
tcol19 | sapiente est dicta error iure ipsum blanditiis.
tcol20 | voluptas velit assumenda dignissimos laboriosam a.
tcol21 | iure id nesciunt modi aut.
tcol22 | sit earum soluta alias aperiam accusantium!
tcol23 | Tin
tcol24 | Julie
tcol25 | c
tcol26 | blue
tcol27 | 0.47
tcol28 | 0.0

其他：
--print参数： 输出日志，但不执行插入操作
./mysql_random_data_load test t3 10000 --user=dts --password=dts --port=3316  --max-threads=4 --host=192.168.31.181 --bulk-size=1000 --print
```
