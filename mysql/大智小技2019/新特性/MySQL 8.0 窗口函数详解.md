[MySQL 8.0 窗口函数详解](https://mp.weixin.qq.com/s?__biz=MzU2NzgwMTg0MA==&mid=2247484877&idx=1&sn=ed54962b29b550aa87306a0d75c0a359&ascene=4&devicetype=android-34&version=4.1.22.8029&abtest_cookie=AAACAA%3D%3D&lang=zh_CN&countrycode=CN&exportkey=n_ChQIAhIQlolyXy5Ufsz0I3ea5xmR6xLQAQIE97dBBAEAAAAAAE5kJuNJB8UAAAAOpnltbLcz9gKNyK89dVj0lbhVtyOjzSJh7%2FUL0qX8Okp6lyj24%2FxVBq1a9lsBiLdt%2BkdRm3N0HvItLS6Dw%2BKx%2Fb%2FurHP%2BvbupkYqT0xZqBBVKrX0RSvOEiF%2B5LoNeFHu0SAKzGiul2nxfd27XcN86eH1mKqqbXuOy%2BFU3xzkGYN9C3vRedFUMj6f%2FZMWi0pjH1zFtQCK%2BtqymOagocaT4iaHFqBPB38e%2B6E4d1WNx3uR3WCrWR1q1ZgM%3D&pass_ticket=%2B55mXRbs99T%2FVl0%2BFVGsT%2FypQn5N4xQYNV0RzuzcjjR40MgdzGsnfJZUn%2F%2FnLPXd&wx_header=3&from=industrynews&platform=win&nwr_flag=1#wechat_redirect)

**背景**
------

一直以来，MySQL 只有针对聚合函数的汇总类功能，比如MAX, AVG 等，没有从 SQL 层针对聚合类每组展开处理的功能。不过 MySQL 开放了 UDF 接口，可以用 C 来自己写UDF，这个就增加了功能行难度。

这种针对每组展开处理的功能就叫窗口函数，有的数据库叫分析函数。

在 MySQL 8.0 之前，我们想要得到这样的结果，就得用以下几种方法来实现：

**1\. session 变量**

**2\. group_concat 函数组合**

**3\. 自己写 store routines**

接下来我们用经典的 **学生/课程/成绩** 来做窗口函数演示

**准备**
------

**学生表**

```


1.  `mysql> show create table student \G`
    
2.  `*************************** 1. row ***************************`
    
3.   `Table: student`
    
4.  `Create  Table: CREATE TABLE student (`
    
5.   `sid int(10) unsigned NOT NULL,`
    
6.   `sname varchar(64) DEFAULT NULL,`
    
7.   `PRIMARY KEY (sid)`
    
8.  `) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci`
    
9.  `1 row in  set (0.00 sec)`
    


```

**课程表**

```


1.  `mysql> show create table course\G`
    
2.  `*************************** 1. row ***************************`
    
3.   `Table: course`
    
4.  ``Create  Table: CREATE TABLE `course` (``
    
5.   `` `cid`  int(10) unsigned NOT NULL,``
    
6.   `` `cname` varchar(64) DEFAULT NULL,``
    
7.   ``PRIMARY KEY (`cid`)``
    
8.  `) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci`
    
9.  `1 row in  set (0.00 sec)`
    


```

**成绩表**

```


1.  `mysql> show create table score\G`
    
2.  `*************************** 1. row ***************************`
    
3.   `Table: score`
    
4.  ``Create  Table: CREATE TABLE `score` (``
    
5.   `` `sid`  int(10) unsigned NOT NULL,``
    
6.   `` `cid`  int(10) unsigned NOT NULL,``
    
7.   `` `score` tinyint(3) unsigned DEFAULT NULL,``
    
8.   ``PRIMARY KEY (`sid`,`cid`)``
    
9.  `) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci`
    
10.  `1 row in  set (0.00 sec)`
    


```

**测试数据**

```


1.  `mysql> select * from student;`
    
2.  `+-----------+--------------+`
    
3.  `| sid       | sname        |`
    
4.  `+-----------+--------------+`
    
5.  `| 201910001 | 张三         |`
    
6.  `| 201910002 | 李四         |`
    
7.  `| 201910003 | 武松         |`
    
8.  `| 201910004 | 潘金莲       |`
    
9.  `| 201910005 | 菠菜         |`
    
10.  `| 201910006 | 杨发财       |`
    
11.  `| 201910007 | 欧阳修       |`
    
12.  `| 201910008 | 郭靖         |`
    
13.  `| 201910009 | 黄蓉         |`
    
14.  `| 201910010 | 东方不败     |`
    
15.  `+-----------+--------------+`
    
16.  `10 rows in  set (0.00 sec)`
    

18.  `mysql> select * from score;;`
    
19.  `+-----------+----------+-------+`
    
20.  `| sid       | cid      | score |`
    
21.  `+-----------+----------+-------+`
    
22.  `| 201910001 | 20192001 | 50 |`
    
23.  `| 201910001 | 20192002 | 88 |`
    
24.  `| 201910001 | 20192003 | 54 |`
    
25.  `| 201910001 | 20192004 | 43 |`
    
26.  `| 201910001 | 20192005 | 89 |`
    
27.  `| 201910002 | 20192001 | 79 |`
    
28.  `| 201910002 | 20192002 | 97 |`
    
29.  `| 201910002 | 20192003 | 82 |`
    
30.  `| 201910002 | 20192004 | 85 |`
    
31.  `| 201910002 | 20192005 | 80 |`
    
32.  `| 201910003 | 20192001 | 48 |`
    
33.  `| 201910003 | 20192002 | 98 |`
    
34.  `| 201910003 | 20192003 | 47 |`
    
35.  `| 201910003 | 20192004 | 41 |`
    
36.  `| 201910003 | 20192005 | 34 |`
    
37.  `| 201910004 | 20192001 | 81 |`
    
38.  `| 201910004 | 20192002 | 69 |`
    
39.  `| 201910004 | 20192003 | 67 |`
    
40.  `| 201910004 | 20192004 | 99 |`
    
41.  `| 201910004 | 20192005 | 61 |`
    
42.  `| 201910005 | 20192001 | 40 |`
    
43.  `| 201910005 | 20192002 | 52 |`
    
44.  `| 201910005 | 20192003 | 39 |`
    
45.  `| 201910005 | 20192004 | 74 |`
    
46.  `| 201910005 | 20192005 | 86 |`
    
47.  `| 201910006 | 20192001 | 42 |`
    
48.  `| 201910006 | 20192002 | 52 |`
    
49.  `| 201910006 | 20192003 | 36 |`
    
50.  `| 201910006 | 20192004 | 58 |`
    
51.  `| 201910006 | 20192005 | 84 |`
    
52.  `| 201910007 | 20192001 | 79 |`
    
53.  `| 201910007 | 20192002 | 43 |`
    
54.  `| 201910007 | 20192003 | 79 |`
    
55.  `| 201910007 | 20192004 | 98 |`
    
56.  `| 201910007 | 20192005 | 88 |`
    
57.  `| 201910008 | 20192001 | 45 |`
    
58.  `| 201910008 | 20192002 | 65 |`
    
59.  `| 201910008 | 20192003 | 90 |`
    
60.  `| 201910008 | 20192004 | 89 |`
    
61.  `| 201910008 | 20192005 | 74 |`
    
62.  `| 201910009 | 20192001 | 73 |`
    
63.  `| 201910009 | 20192002 | 42 |`
    
64.  `| 201910009 | 20192003 | 95 |`
    
65.  `| 201910009 | 20192004 | 46 |`
    
66.  `| 201910009 | 20192005 | 45 |`
    
67.  `| 201910010 | 20192001 | 58 |`
    
68.  `| 201910010 | 20192002 | 52 |`
    
69.  `| 201910010 | 20192003 | 55 |`
    
70.  `| 201910010 | 20192004 | 87 |`
    
71.  `| 201910010 | 20192005 | 36 |`
    
72.  `+-----------+----------+-------+`
    
73.  `50 rows in  set (0.00 sec)`
    

75.  `mysql> select * from course;`
    
76.  `+----------+------------+`
    
77.  `| cid      | cname      |`
    
78.  `+----------+------------+`
    
79.  `| 20192001 | mysql      |`
    
80.  `| 20192002 | oracle     |`
    
81.  `| 20192003 | postgresql |`
    
82.  `| 20192004 | mongodb    |`
    
83.  `| 20192005 | dble       |`
    
84.  `+----------+------------+`
    
85.  `5 rows in  set (0.00 sec)`
    


```

**MySQL 8.0 之前**
----------------

比如我们求成绩排名前三的学生排名，我来举个用 session 变量和 group_concat 函数来分别实现的例子：

**session 变量方式**

每组开始赋一个初始值序号和初始分组字段。

```


1.  `SELECT` 
    
2.   `b.cname,`
    
3.   `a.sname,`
    
4.   `c.score, c.ranking_score`
    
5.  `FROM`
    
6.   `student a,`
    
7.   `course b,`
    
8.   `(`
    
9.   `SELECT`
    
10.   `c.*,`
    
11.   `IF(`
    
12.   `@cid = c.cid,`
    
13.   `@rn := @rn + 1,`
    
14.   `@rn := 1`
    
15.   `) AS ranking_score,`
    
16.   `@cid := c.cid AS tmpcid`
    
17.   `FROM`
    
18.   `(`
    
19.   `SELECT`
    
20.   `*`
    
21.   `FROM`
    
22.   `score`
    
23.   `ORDER BY cid,`
    
24.   `score DESC`
    
25.   `) c,`
    
26.   `(`
    
27.   `SELECT`
    
28.   `@rn := 0 rn,`
    
29.   `@cid := ''`
    
30.   `) initialize_table` 
    
31.   `) c`
    
32.  `WHERE a.sid = c.sid`
    
33.  `AND b.cid = c.cid`
    
34.  `AND c.ranking_score <= 3`
    
35.  `ORDER BY b.cname,c.ranking_score;`
    

37.  `+------------+-----------+-------+---------------+`
    
38.  `| cname      | sname     | score | ranking_score |`
    
39.  `+------------+-----------+-------+---------------+`
    
40.  `| dble       | 张三      | 89 | 1 |`
    
41.  `| dble       | 欧阳修    | 88 | 2 |`
    
42.  `| dble       | 菠菜      | 86 | 3 |`
    
43.  `| mongodb    | 潘金莲    | 99 | 1 |`
    
44.  `| mongodb    | 欧阳修    | 98 | 2 |`
    
45.  `| mongodb    | 郭靖      | 89 | 3 |`
    
46.  `| mysql      | 李四      | 100 | 1 |`
    
47.  `| mysql      | 潘金莲    | 81 | 2 |`
    
48.  `| mysql      | 欧阳修    | 79 | 3 |`
    
49.  `| oracle     | 武松      | 98 | 1 |`
    
50.  `| oracle     | 李四      | 97 | 2 |`
    
51.  `| oracle     | 张三      | 88 | 3 |`
    
52.  `| postgresql | 黄蓉      | 95 | 1 |`
    
53.  `| postgresql | 郭靖      | 90 | 2 |`
    
54.  `| postgresql | 李四      | 82 | 3 |`
    
55.  `+------------+-----------+-------+---------------+`
    
56.  `15 rows in  set, 5 warnings (0.01 sec)`
    


```

**group_concat 函数方式**

利用 findinset 内置函数来返回下标作为序号使用。

```


1.  `SELECT`
    
2.   `*`
    
3.  `FROM`
    
4.   `(`
    
5.   `SELECT`
    
6.   `b.cname,`
    
7.   `a.sname,`
    
8.   `c.score,`
    
9.   `FIND_IN_SET(c.score, d.gp) score_ranking`
    
10.   `FROM`
    
11.   `student a,`
    
12.   `course b,`
    
13.   `score c,`
    
14.   `(`
    
15.   `SELECT`
    
16.   `cid,`
    
17.   `GROUP_CONCAT(`
    
18.   `score`
    
19.   `ORDER BY score DESC SEPARATOR ','`
    
20.   `) gp`
    
21.   `FROM`
    
22.   `score`
    
23.   `GROUP BY cid`
    
24.   `ORDER BY score DESC`
    
25.   `) d`
    
26.   `WHERE a.sid = c.sid`
    
27.   `AND b.cid = c.cid`
    
28.   `AND c.cid = d.cid`
    
29.   `ORDER BY d.cid,`
    
30.   `score_ranking`
    
31.   `) ytt`
    
32.  `WHERE score_ranking <= 3；`
    

34.  `+------------+-----------+-------+---------------+`
    
35.  `| cname      | sname     | score | score_ranking |`
    
36.  `+------------+-----------+-------+---------------+`
    
37.  `| dble       | 张三      | 89 | 1 |`
    
38.  `| dble       | 欧阳修    | 88 | 2 |`
    
39.  `| dble       | 菠菜      | 86 | 3 |`
    
40.  `| mongodb    | 潘金莲    | 99 | 1 |`
    
41.  `| mongodb    | 欧阳修    | 98 | 2 |`
    
42.  `| mongodb    | 郭靖      | 89 | 3 |`
    
43.  `| mysql      | 李四      | 100 | 1 |`
    
44.  `| mysql      | 潘金莲    | 81 | 2 |`
    
45.  `| mysql      | 欧阳修    | 79 | 3 |`
    
46.  `| oracle     | 武松      | 98 | 1 |`
    
47.  `| oracle     | 李四      | 97 | 2 |`
    
48.  `| oracle     | 张三      | 88 | 3 |`
    
49.  `| postgresql | 黄蓉      | 95 | 1 |`
    
50.  `| postgresql | 郭靖      | 90 | 2 |`
    
51.  `| postgresql | 李四      | 82 | 3 |`
    
52.  `+------------+-----------+-------+---------------+`
    
53.  `15 rows in  set (0.00 sec)`
    


```

**MySQL 8.0 窗口函数**
------------------

MySQL 8.0 后提供了原生的窗口函数支持，语法和大多数数据库一样，比如还是之前的例子：

用 row_number() over () 直接来检索排名。

```


1.  `mysql>` 
    
2.  `SELECT`
    
3.   `*`
    
4.  `FROM`
    
5.   `(`
    
6.   `SELECT`
    
7.   `b.cname,`
    
8.   `a.sname,`
    
9.   `c.score,`
    
10.   `row_number() over (`
    
11.   `PARTITION BY b.cname`
    
12.   `ORDER BY c.score DESC`
    
13.   `) score_rank`
    
14.   `FROM`
    
15.   `student AS a,`
    
16.   `course AS b,`
    
17.   `score AS c`
    
18.   `WHERE a.sid = c.sid`
    
19.   `AND b.cid = c.cid`
    
20.   `) ytt`
    
21.  `WHERE score_rank <= 3;`
    

23.  `+------------+-----------+-------+------------+`
    
24.  `| cname      | sname     | score | score_rank |`
    
25.  `+------------+-----------+-------+------------+`
    
26.  `| dble       | 张三      | 89 | 1 |`
    
27.  `| dble       | 欧阳修    | 88 | 2 |`
    
28.  `| dble       | 菠菜      | 86 | 3 |`
    
29.  `| mongodb    | 潘金莲    | 99 | 1 |`
    
30.  `| mongodb    | 欧阳修    | 98 | 2 |`
    
31.  `| mongodb    | 郭靖      | 89 | 3 |`
    
32.  `| mysql      | 李四      | 100 | 1 |`
    
33.  `| mysql      | 潘金莲    | 81 | 2 |`
    
34.  `| mysql      | 欧阳修    | 79 | 3 |`
    
35.  `| oracle     | 武松      | 98 | 1 |`
    
36.  `| oracle     | 李四      | 97 | 2 |`
    
37.  `| oracle     | 张三      | 88 | 3 |`
    
38.  `| postgresql | 黄蓉      | 95 | 1 |`
    
39.  `| postgresql | 郭靖      | 90 | 2 |`
    
40.  `| postgresql | 李四      | 82 | 3 |`
    
41.  `+------------+-----------+-------+------------+`
    
42.  `15 rows in  set (0.00 sec)`
    


```

那我们再找出课程 MySQL 和 DBLE 里不及格的倒数前两名学生名单。

```


1.  `mysql>` 
    
2.  `SELECT`
    
3.   `*`
    
4.  `FROM`
    
5.   `(`
    
6.   `SELECT`
    
7.   `b.cname,`
    
8.   `a.sname,`
    
9.   `c.score,`
    
10.   `row_number () over (`
    
11.   `PARTITION BY b.cid`
    
12.   `ORDER BY c.score ASC`
    
13.   `) score_ranking`
    
14.   `FROM`
    
15.   `student AS a,`
    
16.   `course AS b,`
    
17.   `score AS c`
    
18.   `WHERE a.sid = c.sid`
    
19.   `AND b.cid = c.cid`
    
20.   `AND b.cid IN (20192005, 20192001)`
    
21.   `AND c.score < 60`
    
22.   `) ytt`
    
23.  `WHERE score_ranking < 3;`
    

25.  `+-------+--------------+-------+---------------+`
    
26.  `| cname | sname        | score | score_ranking |`
    
27.  `+-------+--------------+-------+---------------+`
    
28.  `| mysql | 菠菜         | 40 | 1 |`
    
29.  `| mysql | 杨发财       | 42 | 2 |`
    
30.  `| dble  | 武松         | 34 | 1 |`
    
31.  `| dble  | 东方不败     | 36 | 2 |`
    
32.  `+-------+--------------+-------+---------------+`
    
33.  `4 rows in  set (0.00 sec)`
    


```

到此为止，我们只是演示了row_number() over() 函数的使用方法，其他的函数有兴趣的朋友可以自己体验体验，方法都差不多。  