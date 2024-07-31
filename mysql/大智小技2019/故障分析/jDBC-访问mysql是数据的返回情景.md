| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-6月-03 | 2024-6月-03  |
| ... | ... | ... |
---
# jDBC-访问mysql是数据的返回情景

[toc]

## 参考资料
[深度分析 | JDBC与MySQL临时表空间的分析](https://mp.weixin.qq.com/s?__biz=MzU2NzgwMTg0MA==&mid=2247484111&idx=1&sn=33c8159f40d59a1dec3bb3b8a02c312b&ascene=4&devicetype=android-34&version=4.1.26.6014&abtest_cookie=AAACAA%3D%3D&lang=zh_CN&countrycode=CN&exportkey=n_ChQIAhIQayVvjX3%2FPhrc1gSB9b0vOBLiAQIE97dBBAEAAAAAAKZuOAoEz%2BYAAAAOpnltbLcz9gKNyK89dVj04Q5%2F9dSbywZYWzRv7jZK3j7%2FZXWDeFpVzJYye1okN6y92ATFN1%2BRe70jPDtGfr8tQcCCcoEADRqK0D1WnGptfmNJ4i0ra8hzUxf5s9qE%2Bz%2FIMePk69vQmy1%2FQbbnkCQZNq2tjVkMrnCVreJhYDNEw6qcIp%2F9J81t3OuarCh45NTFFL94Ujwtl3uPDNqTYjLA7YRLknaqP3Uk9TMiIYVq2TJvLSLzWKbFEaEIClpefRCaGNz9GCXyT1Qb6BY%3D&pass_ticket=80T1SncJW5yraAy76u3G92mpxYXaX2Q77XGoUEOVebxZ5y4f69wIDVLZ80iQwLrb&wx_header=3&from=industrynews&platform=win&nwr_flag=1#wechat_redirect)

* 总结 
> 1. 正常情况下，sql 执行过程中临时表大小达到 ibtmp 上限后会报错；  
> 2. 当JDBC设置 useCursorFetch=true，sql 执行过程中临时表大小达到 ibtmp 上限后不会报错。  

* 解决方案

> 1. 进一步了解到使用 useCursorFetch=true 是为了防止查询结果集过大撑爆 jvm； 
> 2. 但是使用 useCursorFetch=true 又会导致普通查询也生成临时表，造成临时表空间过大的问题；  
> 3. 临时表空间过大的解决方案是限制 ibtmp1 的大小，然而 useCursorFetch=true 又导致JDBC不返回错误。  
> 4. 所以需要使用其它方法来达到相同的效果，且 sql 报错后程序也要相应的报错。除了 useCursorFetch=true 这种段读取的方式外，还可以使用流读取的方式(经过我的学习，我发现这就是useCursorFetch + defaultfetchsize 的做法就是所谓的游标式读取的常用方法)。

## jdbc 的流式读取和段式读取
### JDBC流式读取配置：
JDBC流式读取是一种通过JDBC连接从数据库中逐行读取大量数据的方式。以下是配置流式读取的一般步骤：
1. **设置FetchSize**：通过设置`Statement`或`PreparedStatement`对象的`setFetchSize()`方法来指定每次从数据库检索的行数。
2. **使用ResultSet**：执行查询后，通过`ResultSet`对象逐行读取数据，以避免一次性加载所有数据到内存中。
3. **关闭资源**：在读取完数据后，记得及时关闭`ResultSet`、`Statement`和`Connection`对象。

### MySQL段式读取配置：
MySQL中的段式读取是一种优化大型查询的方式，通过限制每次读取的行数来减少内存使用。以下是配置段式读取的一般步骤：
1. **设置max_rows**：通过设置`max_rows`参数来限制每次查询返回的最大行数，以控制内存使用。
2. **使用LIMIT**：在查询中使用`LIMIT`子句来限制每次检索的行数，例如`SELECT * FROM table LIMIT offset, row_count`。
3. **使用游标**：在存储过程或函数中，可以使用游标来逐行处理查询结果，以避免一次性加载所有数据到内存中。

这些配置可以帮助优化大型数据集的读取和处理，以提高性能和减少内存占用。

### 问题：临时表空间与 tmpdir 对比
共享临时表空间用于存储非压缩InnoDB临时表(non-compressed InnoDB temporary tables)、关系对象(related objects)、回滚段(rollback segment)等数据；

tmpdir 用于存放指定临时文件(temporary files)和临时表(temporary tables)，与共享临时表空间不同的是，tmpdir存储的是compressed InnoDB temporary tables。

可通过如下语句测试：
```sql
CREATE TEMPORARY TABLE compress_table (id int, name char(255)) ROW_FORMAT=COMPRESSED;

CREATE TEMPORARY TABLE uncompress_table (id int, name char(255)) ;
```

经过测试mysql8.0 并不支持创建压缩临时表

我自己的理解 临时表空间表空间文件（ibtmp1）会被用来保存存储引擎为innodb 的临时表等信息(入上描述)
而tmpdir 会被用来保存非innodb 的临时表，入myisam等，这是系统级的临时表文件存放位置,innodb 有自己临时表所以不使用。

## 延伸阅读
[如何避免JDBC内存溢出问题](https://www.cnblogs.com/cnzz84/p/4098798.html)

[java中的resultset类详解](https://blog.csdn.net/qq_41517071/article/details/84615765)

[mysql压缩表,mysql行压缩与页压缩](https://www.cnblogs.com/gered/p/15251301.html)