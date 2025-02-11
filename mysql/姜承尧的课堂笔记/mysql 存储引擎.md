[MySQL下FEDERATED引擎的开启和使用-腾讯云开发者社区-腾讯云](https://cloud.tencent.com/developer/article/2076061) 

 在实际工作中，我们可能会遇到需要操作其他[数据库](https://cloud.tencent.com/developer/tools/blog-entry?target=https%3A%2F%2Fwww.xgss.net%2Ftag%2F%25e6%2595%25b0%25e6%258d%25ae%25e5%25ba%2593&objectId=2076061&objectType=1&isNewArticle=undefined)实例的部分表，但又不想系统连接多库。此时我们就需要用到数据表映射。如同[Oracle](https://cloud.tencent.com/developer/tools/blog-entry?target=https%3A%2F%2Fwww.xgss.net%2Ftag%2Foracle&objectId=2076061&objectType=1&isNewArticle=undefined)中的DBlink一般，使用过[Oracle](https://cloud.tencent.com/developer/tools/blog-entry?target=https%3A%2F%2Fwww.xgss.net%2Ftag%2Foracle&objectId=2076061&objectType=1&isNewArticle=undefined) DBlink[数据库](https://cloud.tencent.com/developer/tools/blog-entry?target=https%3A%2F%2Fwww.xgss.net%2Ftag%2F%25e6%2595%25b0%25e6%258d%25ae%25e5%25ba%2593&objectId=2076061&objectType=1&isNewArticle=undefined)链接的人都知道可以跨实例来进行数据查询，同样的，[MySQL](https://cloud.tencent.com/developer/tools/blog-entry?target=https%3A%2F%2Fwww.xgss.net%2Ftag%2Fmysql&objectId=2076061&objectType=1&isNewArticle=undefined)自带的FEDERATED引擎完美的帮我们解决了该问题。本篇文章介绍FEDERATED引擎的开启和使用。

1.开启FEDERATED引擎

若需要创建FEDERATED引擎表，则目标端实例要开启FEDERATED引擎。从[MySQL](https://cloud.tencent.com/developer/tools/blog-entry?target=https%3A%2F%2Fwww.xgss.net%2Ftag%2Fmysql&objectId=2076061&objectType=1&isNewArticle=undefined)5.5开始FEDERATED引擎默认安装 只是没有启用，进入命令行输入  show engines  ;  FEDERATED行状态为NO。

```
mysql> show engines;
+--------------------+---------+----------------------------------------------------------------+--------------+------+------------+
| Engine             | Support | Comment                                                        | Transactions | XA   | Savepoints |
+--------------------+---------+----------------------------------------------------------------+--------------+------+------------+
| PERFORMANCE_SCHEMA | YES     | Performance Schema                                             | NO           | NO   | NO         |
| MRG_MYISAM         | YES     | Collection of identical MyISAM tables                          | NO           | NO   | NO         |
| CSV                | YES     | CSV storage engine                                             | NO           | NO   | NO         |
| BLACKHOLE          | YES     | /dev/null storage engine (anything you write to it disappears) | NO           | NO   | NO         |
| MyISAM             | YES     | MyISAM storage engine                                          | NO           | NO   | NO         |
| InnoDB             | DEFAULT | Supports transactions, row-level locking, and foreign keys     | YES          | YES  | YES        |
| ARCHIVE            | YES     | Archive storage engine                                         | NO           | NO   | NO         |
| MEMORY             | YES     | Hash based, stored in memory, useful for temporary tables      | NO           | NO   | NO         |
| FEDERATED          | NO      | Federated MySQL storage engine                                 | NULL         | NULL | NULL       |
+--------------------+---------+----------------------------------------------------------------+--------------+------+------------+
9 rows in set (0.00 sec)
```

2.使用CONNECTION创建FEDERATED表

使用CONNECTION创建FEDERATED引擎表通用模型：

```
CREATE TABLE (......) 
ENGINE =FEDERATED CONNECTION='mysql://username:password@hostname:port/database/tablename'
```

简单创建测试：

```
# 源端表结构及数据
mysql> show create table test_table\G
*************************** 1. row ***************************
       Table: test_table
Create Table: CREATE TABLE `test_table` (
  `increment_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `stu_id` int(11) NOT NULL COMMENT '学号',
  `stu_name` varchar(20) DEFAULT NULL COMMENT '学生姓名',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`increment_id`),
  UNIQUE KEY `uk_stu_id` (`stu_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COMMENT='学生表'
1 row in set (0.00 sec)
mysql> select * from test_table;
+--------------+--------+----------+---------------------+---------------------+
| increment_id | stu_id | stu_name | create_time         | update_time         |
+--------------+--------+----------+---------------------+---------------------+
|            1 |   1001 | wang     | 2019-06-21 10:52:03 | 2019-06-21 10:52:03 |
|            2 |   1002 | dfsfd    | 2019-06-21 10:52:03 | 2019-06-21 10:52:03 |
|            3 |   1003 | fdgfg    | 2019-06-21 10:52:03 | 2019-06-21 10:52:03 |
|            4 |   1004 | sdfsdf   | 2019-06-21 10:52:03 | 2019-06-21 10:52:03 |
|            5 |   1005 | dsfsdg   | 2019-06-21 10:52:03 | 2019-06-21 10:52:03 |
|            6 |   1006 | fgd      | 2019-06-21 10:52:03 | 2019-06-21 10:52:03 |
+--------------+--------+----------+---------------------+---------------------+
6 rows in set (0.00 sec)
# 目标端建表及查询
# 注意ENGINE=FEDERATED CONNECTION后为源端地址 避免使用带@的密码
mysql> CREATE TABLE `test_table` (
    ->   `increment_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
    ->   `stu_id` int(11) NOT NULL COMMENT '学号',
    ->   `stu_name` varchar(20) DEFAULT NULL COMMENT '学生姓名',
    ->   `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    ->   `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    ->   PRIMARY KEY (`increment_id`),
    ->   UNIQUE KEY `uk_stu_id` (`stu_id`)
    -> ) ENGINE=FEDERATED DEFAULT CHARSET=utf8 COMMENT='学生表' CONNECTION='mysql://root:root@10.50.60.212:3306/source/test_table';
Query OK, 0 rows affected (0.01 sec)
mysql> select * from test_table;
+--------------+--------+----------+---------------------+---------------------+
| increment_id | stu_id | stu_name | create_time         | update_time         |
+--------------+--------+----------+---------------------+---------------------+
|            1 |   1001 | wang     | 2019-06-21 10:52:03 | 2019-06-21 10:52:03 |
|            2 |   1002 | dfsfd    | 2019-06-21 10:52:03 | 2019-06-21 10:52:03 |
|            3 |   1003 | fdgfg    | 2019-06-21 10:52:03 | 2019-06-21 10:52:03 |
|            4 |   1004 | sdfsdf   | 2019-06-21 10:52:03 | 2019-06-21 10:52:03 |
|            5 |   1005 | dsfsdg   | 2019-06-21 10:52:03 | 2019-06-21 10:52:03 |
|            6 |   1006 | fgd      | 2019-06-21 10:52:03 | 2019-06-21 10:52:03 |
+--------------+--------+----------+---------------------+---------------------+
6 rows in set (0.00 sec)
```

3.使用CREATE SERVER创建FEDERATED表

如果要在同一[服务器](https://cloud.tencent.com/product/cvm/?from_column=20065&from=20065)上创建多个FEDERATED表，或者想简化创建FEDERATED表的过程，则可以使用该CREATE SERVER语句定义服务器连接参数，这样多个表可以使用同一个server。

CREATE SERVER创建的格式是：

```
CREATE SERVER fedlink
FOREIGN DATA WRAPPER mysql
OPTIONS (USER 'fed_user', PASSWORD '123456', HOST 'remote_host', PORT 3306, DATABASE 'federated');
```

之后创建FEDERATED表可采用如下格式：

```
CREATE TABLE (......) 
ENGINE =FEDERATED CONNECTION='test_link/tablename'
```

示例演示：

```
# 目标端创建指向源端的server
mysql> CREATE SERVER test_link
    ->   FOREIGN DATA WRAPPER mysql
    ->   OPTIONS (USER 'root', PASSWORD 'root',HOST '10.50.60.212',PORT 3306,DATABASE 'source');
Query OK, 1 row affected (0.00 sec)
mysql> select * from mysql.servers\G
*************************** 1. row ***************************
Server_name: test_link
       Host: 10.50.60.212
         Db: source
   Username: root
   Password: root
       Port: 3306
     Socket: 
    Wrapper: mysql
      Owner: 
1 row in set (0.00 sec)
# 目标端创建FEDERATED表
mysql> CREATE TABLE `s1` (
    ->   `increment_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
    ->   `stu_id` int(11) NOT NULL COMMENT '学号',
    ->   `stu_name` varchar(20) DEFAULT NULL COMMENT '学生姓名',
    ->   `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    ->   `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    ->   PRIMARY KEY (`increment_id`),
    ->   UNIQUE KEY `uk_stu_id` (`stu_id`)
    -> ) ENGINE=FEDERATED DEFAULT CHARSET=utf8 COMMENT='学生表' CONNECTION='test_link/s1';
Query OK, 0 rows affected (0.01 sec)
mysql> CREATE TABLE `s2` (
    ->   `increment_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
    ->   `stu_id` int(11) NOT NULL COMMENT '学号',
    ->   `stu_name` varchar(20) DEFAULT NULL COMMENT '学生姓名',
    ->   `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    ->   `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    ->   PRIMARY KEY (`increment_id`),
    ->   UNIQUE KEY `uk_stu_id` (`stu_id`)
    -> ) ENGINE=FEDERATED DEFAULT CHARSET=utf8 COMMENT='学生表' CONNECTION='test_link/s2';
Query OK, 0 rows affected (0.01 sec)
```

4.FEDERATED使用总结

*   基于MySQL5.7.23版本，笔者在源端及目标端实验了多种DDL及DML，现简单总结如下，有兴趣的同学可以试试看。
*   目标端建表结构可以与源端不一样 推荐与源端结构一致
*   源端DDL语句更改表结构 目标端不会变化
*   源端DML语句目标端查询会同步
*   源端drop表 目标端结构还在但无法查询
*   目标端不能执行DDL语句
*   目标端执行DML语句 源端数据也会变化
*   目标端truncate表 源端表数据也会被清空
*   目标端drop表对源端无影响

5.FEDERATED引擎最佳实践目前FEDERATED引擎使用范围还不多，若确实有跨实例访问的需求，建议做好规范，个人总结最佳实践如下：

*   源端专门创建只读权限的用户来供目标端使用。
*   目标端建议用CREATE SERVER方式创建FEDERATED表。
*   FEDERATED表不宜太多，迁移时要特别注意。
*   目标端应该只做查询使用，禁止在目标端更改FEDERATED表。
*   建议目标端表名及结构和源端保持一致。
*   源端表结构变更后 目标端要及时删除重建。

