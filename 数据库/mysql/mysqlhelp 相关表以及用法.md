[源地址](https://cloud.tencent.com/developer/article/1760736)

# MySQL 的 help 命令你真的会用吗|全方位认识 mysql 系统库

[cloud.tencent.com](https://cloud.tencent.com/developer/article/1760736)老叶茶馆225篇文章

![](https://image.cubox.pro/cardImg/2023110116485174399/23178.jpg?imageMogr2/quality/90/ignore-error/1)

MySQL 的帮助信息重要吗？不太重要！有用吗？有！就好比你在家洗澡的时候，突然有人不停地按你家的门铃，能把你憋出心脏病来，嘿嘿。

我想，各位DBA同行们，在[数据库](https://cloud.tencent.com/solution/database?from_column=20065&from=20065)的日常维护过程中，如果突然忘记某个SQL或者说某个管理命令如何拼写的时候，一定首先想到的就是使用"help xxx" 语句来查看MySQL 自带的帮助信息。

但你一定或多或少能碰到这样的场景：记不清某个语句的具体拼写了，只能模糊的记得几个字母，或者说很清楚知道想要查什么帮助信息，但是却不知道用什么关键字来查询帮助信息（例如：想要查看解析relaylog的SQL语句）。这个时候怎么办呢？别慌，本文来告诉你答案！

要想知道怎么办，那得全面了解MySQL 提供的帮助系统，下面，我们将带领大家一窥庐山真面目！

### **01**

### **help 语句信息从哪里取的**

My[SQL Server](https://cloud.tencent.com/product/sqlserver?from_column=20065&from=20065)提供4张表用于保存服务端的帮助信息（使用help语法查看的帮助信息），这些表位于mysql 系统字典库下。help 语句就是从这些表中获取数据并返回给客户端，如下：

*   help\_category：关于帮助主题类别的信息
*   help\_keyword：与帮助主题相关的关键字信息
*   help\_relation：帮助关键字信息和主题信息之间的映射
*   help\_topic：帮助主题的详细内容

### **02**

### **help 语句信息何时产生的**

这些表在数据库初始化时通过加载share/fill\_help\_tables.sql文件创建，如果是在Unix上使用二进制或源代码发行版安装MySQL，则在初始化数据目录时会直接导入该文件对帮助表内容进行初始化。对于在Linux上的RPM分发版或Windows上的二进制发行版，帮助表的内容初始化是作为MySQL安装过程的一部分执行。

*   如果使用二进制发行版升级MySQL，则不会自动升级帮助表，但可以手动升级(手工加载share/fill\_help\_tables.sql文件），如：shell> mysql -u root mysql <fill\_help\_tables.sql
*   您可以随时获取最新的fill\_help\_tables.sql以升级您的帮助表。从http://dev.mysql.com/doc/index-other.html下载适用于您的MySQL版本的正确文件

### **03**

### **help 帮助信息存储表详解**

help 语法支持3种模式的匹配查询：查看所有主题顶层类别或子类别、查看帮助主题下的关键字、使用给定主题下的唯一关键字查看帮助信息，这些信息分表保存在 help\_category、help\_topic、help\_keyword表，help\_relation表存放help\_topic与help\_keyword表中信息的映射信息。下面将针对这几张表的基础知识进行简单的科普。

#### **（1）help\_category**

该表提供查询帮助主题的类别信息，每一个类别分别对应着N个帮助主题名或者主题子类别名，通过查询表中的信息我们也可以看出来，如下：

    root@localhost : mysql 01:10:59> select * from help_category;
    +------------------+-----------------------------------------------+--------------------+-----+
    | help_category_id | name                                          | parent_category_id | url |
    +------------------+-----------------------------------------------+--------------------+-----+
    |                1 | Geographic                                    |                  0 |     |
    |                2 | Polygon properties                            |                 35 |     |
    ......
    |               39 | Functions                                     |                 36 |     |
    |               40 | Data Definition                               |                 36 |     |
    +------------------+-----------------------------------------------+--------------------+-----+
    40 rows in set (0.00 sec)
    

表字段含义

*   help\_category\_id：帮助主题名称或子类别名称在表中的记录ID
*   name：帮助主题类别名称或字类别名称
*   parent\_category\_id：父主题类别名称在表中的记录ID，一些主题类别具有子主题类别，例如：绝大多数的主题类别其实是Contents类别的子类别（且是顶层类别，也是一级父类别），还有一部分是Geographic Features 类别的子类别（二级父类别），一部分是Functions的子类别（二级父类别）
*   url ：对应在MySQL 官方手册中的链接地址

#### **（2）help\_keyword**

该表提供查询与帮助主题相关的关键字字符串信息，如下：

    root@localhost : mysql 01:12:07> select * from help_keyword limit 5;
    +-----------------+---------+
    | help_keyword_id | name    |
    +-----------------+---------+
    |             681 | (JSON   |
    |             486 | ->      |
    |             205 | ->>     |
    |             669 | <>      |
    |             521 | ACCOUNT |
    +-----------------+---------+
    5 rows in set (0.00 sec)
    

表字段含义

*   help\_keyword\_id：帮助关键字名称在表中记录对应的ID
*   name：帮助关键字字符串

#### **（3）help\_relation**

该表提供查询帮助关键字信息和主题详细信息之间的映射，用于关联查询help\_keyword与help\_topic表，如下：

    root@localhost : mysql 01:13:09> select * from help_relation limit 5;
    +---------------+-----------------+
    | help_topic_id | help_keyword_id |
    +---------------+-----------------+
    |             0 |               0 |
    |           535 |               0 |
    |           294 |               1 |
    |           277 |               2 |
    |             2 |               3 |
    +---------------+-----------------+
    5 rows in set (0.00 sec)
    

表字段含义

*   help\_topic\_id：帮助主题详细信息ID，该ID值与help\_topic表中的help\_topic\_id相等
*   help\_keyword\_id：帮助主题关键字信息ID，该ID值与help\_keyword表中的help\_keyword\_id相等

#### **（4）help\_topic**

该表提供查询帮助主题给定关键字的详细内容（详细帮助信息），如下：

    root@localhost : mysql 01:13:31> select * from help_topic limit 1\G;
    *************************** 1. row ***************************
    help_topic_id: 0
            name: JOIN
    help_category_id: 28
     description: MySQL supports the following JOIN syntaxes for the table_references
    part of SELECT statements and multiple-table DELETE and UPDATE
    statements:
    table_references:
    escaped_table_reference [, escaped_table_reference] ...
    escaped_table_reference:
    table_reference
    | { OJ table_reference }
    ......
             url: http://dev.mysql.com/doc/refman/5.7/en/join.html
    1 row in set (0.00 sec)
    

表字段含义

*   help\_topic\_id：帮助主题详细信息在表记录中对应的ID
*   name：帮助主题给定的关键字名称，与help\_keyword表中的name字段值相等
*   help\_category\_id：帮助主题类别ID，与help\_category表中的help\_category\_id字段值相等
*   description：帮助主题的详细信息（这里就是我们通常查询帮助信息真正想看的内容，例如：告诉我们某某语句如何使用的语法与注意事项等）
*   example：帮助主题的示例信息（这里告诉我们某某语句如何使用的示例）
*   url：该帮助主题对应在MySQL官方在线手册中的URL链接地址

### **04**

### **help 语句用法示例**

前面我们提到过，help 语法支持3种模式的匹配查询。那么，回到文章开头我们抛出的问题，记不清某个语句的具体拼写了，只能模糊的记得几个字母，或者说很清楚知道想要查什么帮助信息，但是却不知道用什么关键字来查询帮助信息（例如：想要查看解析relaylog的SQL语句）。这个时候怎么办呢？

#### **（1）我只记得某几个字母怎么办**

MySQL 提供的帮助信息实际上可以直接给定一个主题关键字进行查询，不需要指定主题名称，如果你记录某个SQL子句关键字的其中的几个字母，那么可以使用这些字母多尝试几次，如下：

    root@localhost : performance_schema 10:43:40> help relay  # 尝试第一次
    Nothing found
    Please try to run 'help contents' for a list of all accessible topics
    root@localhost : performance_schema 10:44:00> help relay logs  # 尝试第二次
    Nothing found
    Please try to run 'help contents' for a list of all accessible topics
    root@localhost : performance_schema 10:44:06> help relaylogs  # 尝试第三次
    Nothing found
    Please try to run 'help contents' for a list of all accessible topics
    root@localhost : performance_schema 10:44:09> help relaylog  # 尝试第四次，oy，成功了
    Name: 'SHOW RELAYLOG EVENTS'
    Description:
    Syntax:
    SHOW RELAYLOG EVENTS
    [IN 'log_name'] [FROM pos] [LIMIT [offset,] row_count]  # 原来是这样用的
    Shows the events in the relay log of a replication slave. If you do not
    specify 'log_name', the first relay log is displayed. This statement
    has no effect on the master.
    URL: http://dev.mysql.com/doc/refman/5.7/en/show-relaylog-events.html
    

PS：这里实际上就相当于那help 语句给定的关键字去匹配help\_keyword表的name字段，如果有记录返回，则使用help\_category、help\_keyword、help\_relation、help\_topic四表做复杂的关联查询，右联结help\_topic表中的name字段，如果返回唯一记录就返回帮助信息，如果返回多行，则返回一个关键字列表，使用这些具体的关键字可查询到具体的帮助信息，例如：

    root@localhost : performance_schema 11:05:06> help where
    .....
    where <item> is one of the following
    topics:  # 使用where作为关键字返回了一个关键字列表，表示where还会与这三个关键字组合使用，where的详细用法从列表中随便挑选一个关键字即可看到
    DELETE
    HANDLER
    UPDATE
    root@localhost : performance_schema 11:09:05> help delete
    Name: 'DELETE'
    Description:
    Syntax:
    DELETE is a DML statement that removes rows from a table.
    Single-Table Syntax
    DELETE [LOW_PRIORITY] [QUICK] [IGNORE] FROM tbl_name
    [PARTITION (partition_name,...)]
    [WHERE where_condition]  # where关键字的用法在这里
    [ORDER BY ...]
    [LIMIT row_count]
    ......
    

#### **（2）我啥都不记得怎么办**

如果你啥都不记得，那就只能使用最笨的方法，地毯式查找

首先，我们就随便敲几个字母给help语句好了，例如：help xxx

    root@localhost : performance_schema 10:09:49> help xxx;
    Nothing found  # 这句告诉你帮助信息没找到
    # 不要紧，下面这句告诉你，用help contents语句来列出所有的可能的帮助主题信息
    Please try to run 'help contents' for a list of all accessible topics
    

然后，查看所有的主题类别

    root@localhost : performance_schema 10:31:47> help contents
    You asked for help about help category: "Contents"
    For more information, type 'help <item>', where <item> is one of the following
    categories:
    Account Management
    Administration  # 通过主题或主题类别名称，大致判定一下，查看relaylog事件内容的语句应该是属于管理语句
    Compound Statements
    Data Definition
    Data Manipulation
    Data Types
    Functions
    Functions and Modifiers for Use with GROUP BY
    Geographic Features
    Help Metadata
    Language Structure
    Plugins
    Procedures
    Storage Engines
    Table Maintenance
    Transactions
    User-Defined Functions
    Utility
    

使用help Administration 查看该帮助主题下的所有关键字

    root@localhost : performance_schema 10:37:27> help Administration
    ......
    SHOW PROCEDURE CODE
    SHOW PROCEDURE STATUS
    SHOW PROCESSLIST
    SHOW PROFILE
    SHOW PROFILES
    SHOW RELAYLOG EVENTS  # 找到了，在这里
    ......
    

使用SHOW RELAYLOG EVENTS语句来查看具体的帮助信息

    root@localhost : performance_schema 10:41:53> help SHOW RELAYLOG EVENTS
    Name: 'SHOW RELAYLOG EVENTS'
    Description:
    Syntax:
    SHOW RELAYLOG EVENTS
    [IN 'log_name'] [FROM pos] [LIMIT [offset,] row_count]  # 原来是这样用的
    Shows the events in the relay log of a replication slave. If you do not
    specify 'log_name', the first relay log is displayed. This statement
    has no effect on the master.
    URL: http://dev.mysql.com/doc/refman/5.7/en/show-relaylog-events.html
    

OK，现在相信你已经比较清晰地了解了MySQL 帮助系统的组成以及help 到底能给我们提供一些什么帮助信息了，下面给大家再补充点小知识：

*   HELP语句中给定的搜索关键字不区分大小写
*   搜索关键字可以包含通配符％和\_，效果与LIKE运算符执行的模式匹配操作含义相同。例如：HELP 'rep％'返回以rep开头的主题列表
*   如果帮助类别字符串、帮助主题字符串包含多个字符的，则可以使用引号引起来，也可以不使用引号，为避免歧义，最好使用引号引起来

### **05**

### **帮助信息表相关的注意事项**

对于参与复制的数据库实例，帮助表更新有一些注意事项。帮助表默认情况下会写入到binlog中（因为这些帮助表是跟版本匹配的，升级一个实例的版本，其他实例也有同步更新的必要），所以，你需要考虑是否需要在升级主库帮助表的时候同时把这些更新通过主库binlog同步更新到从库中。

*   如果主从库版本不同，那么主从库就需要单独升级帮助信息表
*   如果是MySQL 5.7.5之前的版本，则主从库分别升级帮助信息表使用命令：mysql --init-command="SET sql\_log\_bin=0" mysql < fill\_help\_tables.sql
*   如果是MySQL 5.7.5 及其之后的版本，则不需要使用--init-command="SET sql\_log\_bin=0" ，因为fill\_help\_tables.sql文件中包含了SET sql\_log\_bin=0，所以主从库只需要分别执行命令：mysql mysql < fill\_help\_tables.sql 即可
*   如果是主从版本相同，那么主从库可以通过在主库升级，通过复制来更新从库的帮助信息表
*   如果是MySQL 5.7.5之前的版本，则只需要在主库中执行命令：mysql mysql < fill\_help\_tables.sql 即可
*   如果是MySQL 5.7.5 及其之后的版本，则需要先在主库[服务器](https://cloud.tencent.com/act/pro/promotion-cvm?from_column=20065&from=20065)中修改ll\_help\_tables.sql 文件，去掉SET sql\_log\_bin=0，然后在主库执行命令：mysql mysql < fill\_help\_tables.sql 即可

**PS：**在MySQL 5.7.5之前这些表使用MyISAM，在这个版本之后改为InnoDB引擎

**| 作者简介**

### **罗小波·ScaleFlux数据库技术专家**

《千金良方——MySQL性能优化金字塔法则》、《数据生态：MySQL复制技术与生产实践》作者之一。

熟悉MySQL体系结构，擅长数据库的整体调优，喜好专研开源技术，并热衷于开源技术的推广，在线上线下做过多次公开的数据库专题分享，发表过近100篇数据库相关的研究文章。

全文完。

[跳转到 Cubox 查看](https://cubox.pro/my/card?id=7119302234797507155)