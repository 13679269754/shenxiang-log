[万答#18，MySQL8.0 如何快速回收膨胀的UNDO表空间 - GreatSQL - 博客园](https://www.cnblogs.com/greatsql/p/15722154.html) 

 > 欢迎来到 GreatSQL社区分享的MySQL技术文章，如有疑问或想学习的内容，可以在下方评论区留言，看到后会进行解答

*   GreatSQL社区原创内容未经授权不得随意使用，转载请联系小编并注明来源。

在项目选型中，在KVM(16c 16G ssd160G )的 Linux7.6 系统上部署了MYSQL MGR 集群 (GreatSQL 8.0.25)。

使用 sysbench 创建了100仓数据，且针对表创建为 partition 表，进行连续12小时的稳定下压测，来评估对应的架构的能够支撑的业务并发数，以及最高的TPS/QPS是多少。

在使用256并发，连续压测进行了12个小时之后，发现节点的SSD磁盘空间使用率达到 95% 以上，当时第一时间去查看 log 目录，log目录已经达到 100G+，以为是 binlog 设置的时间太长导致的 binlog 没有及时清理造成的，去清理 binlogbinlog 过期时间设置的 1800s，实际 binlog 和 MGR 的 relay-group 空间占用在11G左右而 du -sh \* 查看到的日志文件大小时，发现其中undo大小1个是71G另一个4.1G，且MGR的3个节点的undo均是这个情况，急需释放空间。

但是MySQL8.0是否支持类型oracle的undo在线的替换来进行收缩呢，答案是肯定的，而且有些类似。

oracle/mysql undo 表空间设置自动扩展，如果业务上有跑批量或者大表的DML操作时，引起大事物，或针对多张大表关联更新时间较长，可能短时间内会将undo"撑大"，oracle 我们可以通过创建一个新的 undo，通过在线的替换的方式，将膨胀的 undo 使用 drop 删除以释放空间。

mysql 8.0同样可以使用这种方式来处理，因大事物或长事物引起的undo过大占用空间较多的情况。

*   1、添加新的undo文件undo003。mysql8.0中默认innodb\_undo\_tablespace为2个，不足2个时，不允许设置为inactive，且默认创建的undo受保护，不允许删除。
    
*   2、将膨胀的 undo 临时设置为inactive，以及 innodb\_undo\_log\_truncate=on，自动 truncate 释放膨胀的undo空间。
    
*   3、重新将释放空间之后的undo设置为active，可重新上线使用。
    

```null
[greatdb@mysql ~]$ mysql -ugreatsql -pgreatsql -h172.16.130.15 -P3307    mysql: [Warning] Using a password on the command line interface can be insecure.Welcome to the MySQL monitor.  Commands end with ; or \g.Your MySQL connection id is 74Server version: 8.0.25-15 GreatSQL, Release 15, Revision c7feae175e0 Copyright (c) 2000, 2019, Oracle and/or its affiliates. All rights reserved. Oracle is a registered trademark of Oracle Corporation and/or itsaffiliates. Other names may be trademarks of their respectiveowners. Type 'help;' or '\h' for help. Type '\c' to clear the current input statement. mysql[(none)]> show variables like '%undo%';+--------------------------+-----------------------------+| Variable_name            | Value                       |+--------------------------+-----------------------------+| innodb_max_undo_log_size | 4294967296                  || innodb_undo_directory    | /app/dbdata/sqlnode3306/log || innodb_undo_log_encrypt  | OFF                         || innodb_undo_log_truncate | ON                          || innodb_undo_tablespaces  | 2                           |+--------------------------+-----------------------------+5 rows in set (0.01 sec)
```

1、查看undo大小

```null
mysql[(none)]> system du -sh  /app/dbdata/datanode3307/log/undo*4.1G /app/dbdata/datanode3307/log/undo_00171G /app/dbdata/datanode3307/log/undo_002       -----12小时连续稳定性压测，导致节点undo过大，达到71G
```

2、添加新的undo表空间undo003。系统默认是2个undo，大小设置4G

```null
mysql[(none)]> mysql[(none)]> create undo tablespace undo003 add datafile '/app/dbdata/datanode3307/log/undo003.ibu';Query OK, 0 rows affected (0.21 sec)注意：创建添加新的undo必须以.ibu结尾，否则触发如下错误提示mysql[(none)]> create undo tablespace undo003 add datafile '/app/dbdata/datanode3307/log/undo_003.' ;ERROR 3121 (HY000): The ADD DATAFILE filepath must end with '.ibu'.
```

3、查看系统中的undo表空间信息，如下：

```null
mysql[(none)]> select * from information_schema.INNODB_TABLESPACES where  name like '%undo%';+------------+-----------------+------+------------+-----------+---------------+------------+---------------+-------------+----------------+-----------------+----------------+---------------+------------+--------+| SPACE      | NAME            | FLAG | ROW_FORMAT | PAGE_SIZE | ZIP_PAGE_SIZE | SPACE_TYPE | FS_BLOCK_SIZE | FILE_SIZE   | ALLOCATED_SIZE | AUTOEXTEND_SIZE | SERVER_VERSION | SPACE_VERSION | ENCRYPTION | STATE  |+------------+-----------------+------+------------+-----------+---------------+------------+---------------+-------------+----------------+-----------------+----------------+---------------+------------+--------+| 4294967279 | innodb_undo_001 |    0 | Undo       |     16384 |             0 | Undo       |          4096 |  4311744512 |     4311764992 |               0 | 8.0.25         |             1 | N          | active || 4294967278 | innodb_undo_002 |    0 | Undo       |     16384 |             0 | Undo       |          4096 | 76067897344 |    76068229120 |               0 | 8.0.25         |             1 | N          | active || 4294967277 | undo003         |    0 | Undo       |     16384 |             0 | Undo       |          4096 |    16777216 |       16777216 |               0 | 8.0.25         |             1 | N          | active |+------------+-----------------+------+------------+-----------+---------------+------------+---------------+-------------+----------------+-----------------+----------------+---------------+------------+--------+3 rows in set (0.03 sec)
```

4、查看到上述视图中 innodb\_undo\_002 大小达到76067897344 （约71G）其状态state为active。手动将其设置为 inactive，使其自动触发 innodb\_undo\_log\_truncate 回收。

```null
mysql[(none)]> alter undo tablespace innodb_undo_002 set inactive;Query OK, 0 rows affected (0.00 sec)
```

5、查看对应视图如下

```null
mysql[(none)]> select * from information_schema.INNODB_TABLESPACES where  name like '%undo%';+------------+-----------------+------+------------+-----------+---------------+------------+---------------+------------+----------------+-----------------+----------------+---------------+------------+--------+| SPACE      | NAME            | FLAG | ROW_FORMAT | PAGE_SIZE | ZIP_PAGE_SIZE | SPACE_TYPE | FS_BLOCK_SIZE | FILE_SIZE  | ALLOCATED_SIZE | AUTOEXTEND_SIZE | SERVER_VERSION | SPACE_VERSION | ENCRYPTION | STATE  |+------------+-----------------+------+------------+-----------+---------------+------------+---------------+------------+----------------+-----------------+----------------+---------------+------------+--------+| 4294967279 | innodb_undo_001 |    0 | Undo       |     16384 |             0 | Undo       |          4096 | 4311744512 |     4311764992 |               0 | 8.0.25         |             1 | N          | active || 4294967151 | innodb_undo_002 |    0 | Undo       |     16384 |             0 | Undo       |          4096 |   16777216 |        2179072 |               0 | 8.0.25         |             1 | N          | empty  || 4294967277 | undo003         |    0 | Undo       |     16384 |             0 | Undo       |          4096 |   16777216 |       16777216 |               0 | 8.0.25         |             1 | N          | active |+------------+-----------------+------+------------+-----------+---------------+------------+---------------+------------+----------------+-----------------+----------------+---------------+------------+--------+3 rows in set (0.01 sec)
```

此时可以查看对应操作系统目录中的 undo\_002大小，innodb\_undo\_002 FILE\_SIZE 16777216 默认大小 2179072 ，STATE 为 empty

```null
mysql[(none)]> system du -sh  /app/dbdata/datanode3307/log/undo*4.1G /app/dbdata/datanode3307/log/undo_0012.1M /app/dbdata/datanode3307/log/undo_00216M /app/dbdata/datanode3307/log/undo003.ibu
```

6、重新将其设置为active状态

```null
mysql[(none)]> alter undo tablespace innodb_undo_002 set active;Query OK, 0 rows affected (0.01 sec)
```

```null
mysql[(none)]> select * from information_schema.INNODB_TABLESPACES where  name like '%undo%';+------------+-----------------+------+------------+-----------+---------------+------------+---------------+------------+----------------+-----------------+----------------+---------------+------------+--------+| SPACE      | NAME            | FLAG | ROW_FORMAT | PAGE_SIZE | ZIP_PAGE_SIZE | SPACE_TYPE | FS_BLOCK_SIZE | FILE_SIZE  | ALLOCATED_SIZE | AUTOEXTEND_SIZE | SERVER_VERSION | SPACE_VERSION | ENCRYPTION | STATE  |+------------+-----------------+------+------------+-----------+---------------+------------+---------------+------------+----------------+-----------------+----------------+---------------+------------+--------+| 4294967279 | innodb_undo_001 |    0 | Undo       |     16384 |             0 | Undo       |          4096 | 4311744512 |     4311764992 |               0 | 8.0.25         |             1 | N          | active || 4294967151 | innodb_undo_002 |    0 | Undo       |     16384 |             0 | Undo       |          4096 |   16777216 |        2195456 |               0 | 8.0.25         |             1 | N          | active || 4294967277 | undo003         |    0 | Undo       |     16384 |             0 | Undo       |          4096 |   16777216 |       16777216 |               0 | 8.0.25         |             1 | N          | active |+------------+-----------------+------+------------+-----------+---------------+------------+---------------+------------+----------------+-----------------+----------------+---------------+------------+--------+3 rows in set (0.01 sec)
```

7、有人说，为什么直接不能直接针对膨胀的undo设置为inactive，系统默认创建的undo表空间默认2个，处于active小于2个时，会有如下提示：

```null
mysql[(none)]> mysql[(none)]> show variables like 'innodb_undo_tablespaces';+--------------------------+-----------------------------+| Variable_name            | Value                       |+--------------------------+-----------------------------+| innodb_undo_tablespaces  | 2                           |+--------------------------+-----------------------------+5 rows in set (0.01 sec)mysql[(none)]> alter undo tablespace innodb_undo_002 set inactive;ERROR 3655 (HY000): Cannot set innodb_undo_002 inactive since there would be less than 2 undo tablespaces left active.mysql[(none)]> 
```

8、新创建添加的可以正常设置为inactive之后，使用drop方式删除，如下：

```null
mysql[(none)]> alter undo tablespace undo003 set inactive;Query OK, 0 rows affected (0.00 sec)
```

```null
mysql[(none)]> drop undo tablespace undo003;Query OK, 0 rows affected (0.01 sec)
```

```null
mysql[(none)]> select * from information_schema.INNODB_TABLESPACES where  name like '%undo%';+------------+-----------------+------+------------+-----------+---------------+------------+---------------+------------+----------------+-----------------+----------------+---------------+------------+--------+| SPACE      | NAME            | FLAG | ROW_FORMAT | PAGE_SIZE | ZIP_PAGE_SIZE | SPACE_TYPE | FS_BLOCK_SIZE | FILE_SIZE  | ALLOCATED_SIZE | AUTOEXTEND_SIZE | SERVER_VERSION | SPACE_VERSION | ENCRYPTION | STATE  |+------------+-----------------+------+------------+-----------+---------------+------------+---------------+------------+----------------+-----------------+----------------+---------------+------------+--------+| 4294967279 | innodb_undo_001 |    0 | Undo       |     16384 |             0 | Undo       |          4096 | 4311744512 |     4311764992 |               0 | 8.0.25         |             1 | N          | active || 4294967151 | innodb_undo_002 |    0 | Undo       |     16384 |             0 | Undo       |          4096 |   16777216 |        2244608 |               0 | 8.0.25         |             1 | N          | active |+------------+-----------------+------+------------+-----------+---------------+------------+---------------+------------+----------------+-----------------+----------------+---------------+------------+--------+2 rows in set (0.01 sec)
```

通过以上操作我们就可以针对unod因遇到大事务，undo持续增长的情况下，通过新增临时undo，手动释放系统默认的2个undo表空间 大小。

当然截断 UNDO 表空间文件对数据库性能是有一定的影响的，尽量在相对空闲时间进行。

当UNDO表空间被截断时，UNDO表空间中的回滚段将被停用。其他UNDO表空间中的活动回滚段负责整个系统负载，这可能会导致性能略有下降。性能受影响的程度取决于许多因素:

*   1、UNDO表空间的数量
*   2、UNDO记录日志的数据量
*   3、UNDO表空间大小
*   4、磁盘I/O系统的速度
*   5、现有长期运行的事务

那么避免潜在性能影响的最简单的方法:

*   1、就是通过 create undo tablespace undo\_XXX add datafile '/path/undo\_xxx.ibu';多添加几个UNDO表空间。
*   2、磁盘上如果条件允许采用高性能的SSD来存储数据，存储REDO,UNDO等。
*   引起UNDO过度膨胀的原因大多数是因为基础数据量大，业务并发高，表关联操作较频繁，出现大且长的事物操作，导致UNDO一直处于active状态，不能及时释放回滚段等原因，大事物引起的问题由来已久，即使我们能规避99%的大事物，但实际业务遇到那1%的大事物刚性需求发过来时，这还要我们的MySQL各种场景，各种架构和业务层好好磨合磨合。

Enjoy GreatSQL 😃
