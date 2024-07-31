## MySQL 8.0：字符集从 utf8 转换成 utf8mb4

[MySql迁移升级字符集处理](https://mp.weixin.qq.com/s?__biz=MzU2NzgwMTg0MA==&mid=2247486190&idx=1&sn=ac97dc60ffe06b7218e55cfe2d9a356f&ascene=4&devicetype=android-34&version=4.1.22.8029&abtest_cookie=AAACAA%3D%3D&lang=zh_CN&countrycode=CN&exportkey=n_ChQIAhIQheKYm76axG8Bi6RclRX4kBLiAQIE97dBBAEAAAAAAJi5GOxMeGwAAAAOpnltbLcz9gKNyK89dVj0q3ljIypWsF2WcIy5V7w3k4%2FNYSTMbnoOSI%2FNxhZlWI9c88YgL5%2FulZs%2FgFGJ5NqP2RJsCN5AK37W9oLqrqSyP1tPxTVqs1xFWhuAC%2Bv7U1PxDJNh2ejkEnLHCx8byUwPLM7gaDqOTGwA1AvjVe9XTH7ZkfOYDbgsEOh0fyia5ig%2FSxTnvAtLuvjSC%2FS0r%2BX00kX3qG5gw0qkH62PzuL%2F6uINPZFWcNBKTCxyA98qc%2F0h07OyGEaEHV9N7c4%3D&pass_ticket=NW25143PqXs4PlgBERfbFeGC%2BBV%2BMy%2Bbnpqh2pG8y9kbwMcIlqbRC3u3EbAzPRc9&wx_header=3&from=industrynews&platform=win&nwr_flag=1#wechat_redirect)

**整理 MySQL 8.0 文档时发现一个变更：** 

默认字符集由 latin1 变为 utf8mb4。想起以前整理过字符集转换文档，升级到 MySQL 8.0 后大概率会有字符集转换的需求，在此正好分享一下。

**当时的需求背景是：** 

部分系统使用的字符集是 utf8，但 utf8 最多只能存 3 字节长度的字符，不能存放 4 字节的生僻字或者表情符号，因此打算迁移到 utf8mb4。

**迁移方案一**

**1\. 准备新的数据库实例，修改以下参数：** 

```


1.  `[mysqld]`
    
2.  `## Character Settings`
    
3.  `init_connect='SET NAMES utf8mb4'`
    
4.  `#连接建立时执行设置的语句，对super权限用户无效`
    
5.  `character-set-server = utf8mb4`
    
6.  `collation-server = utf8mb4_general_ci`
    
7.  `#设置服务端校验规则，如果字符串需要区分大小写，设置为utf8mb4_bin`
    
8.  `skip-character-set-client-handshake`
    
9.  `#忽略应用连接自己设置的字符编码，保持与全局设置一致`
    
10.  `## Innodb Settings`
    
11.  `innodb_file_format = Barracuda`
    
12.  `innodb_file_format_max = Barracuda`
    
13.  `innodb_file_per_table = 1`
    
14.  `innodb_large_prefix = ON`
    
15.  `#允许索引的最大字节数为3072（不开启则最大为767字节，对于类似varchar(255)字段的索引会有问题，因为255*4大于767）`
    


```

**2\. 停止应用，观察，确认不再有数据写入**

可通过 show master status 观察 GTID 或者 binlog position，没有变化则没有写入。

**3\. 导出数据**

先导出表结构：

```


1.  `mysqldump -u -p --no-data --default-character-set=utf8mb4 --single-transaction --set-gtid-purged=OFF --databases testdb > /backup/testdb.sql`
    


```

后导出数据：

```


1.  `mysqldump -u -p --no-create-info --master-data=2 --flush-logs --routines --events --triggers --default-character-set=utf8mb4 --single-transaction --set-gtid-purged=OFF --database testdb > /backup/testdata.sql`
    


```

**4\. 修改建表语句**

修改导出的表结构文件，将表、列定义中的 utf8 改为 utf8mb4

**5\. 导入数据**

先导入表结构：

```


1.  `mysql -u -p testdb < /backup/testdb.sql`
    


```

后导入数据：

```


1.  `mysql -u -p testdb < /backup/testdata.sql`
    


```

**6\. 建用户**

查出旧环境的数据库用户，在新数据库中创建

**7\. 修改新数据库端口，启动应用进行测试**

关闭旧数据库，修改新数据库端口重启，启动应用

**迁移方案二**

**1\. 修改表的字符编码会锁表，建议先停止应用**

**2\. 停止 mysql，备份数据目录（也可以其他方式进行全备）**

**3\. 修改配置文件，重启数据库**

```


1.  `[mysqld]`
    
2.  `## Character Settings`
    
3.  `init_connect='SET NAMES utf8mb4'`
    
4.  `#连接建立时执行设置的语句，对super权限用户无效`
    
5.  `character-set-server = utf8mb4`
    
6.  `collation-server = utf8mb4_general_ci`
    
7.  `#设置服务端校验规则，如果字符串需要区分大小写，设置为utf8mb4_bin`
    
8.  `skip-character-set-client-handshake`
    
9.  `#忽略应用连接自己设置的字符编码，保持与全局设置一致`
    
10.  `## Innodb Settings`
    
11.  `innodb_file_format = Barracuda`
    
12.  `innodb_file_format_max = Barracuda`
    
13.  `innodb_file_per_table = 1`
    
14.  `innodb_large_prefix = ON`
    
15.  `#允许索引的最大字节数为3072（不开启则最大为767字节，对于类似varchar(255) 字段的索引会有问题，因为255*4大于767）`
    


```

**4\. 查看所有表结构，包括字段、修改库和表结构，如果字段有定义字符编码，也需要修改字段属性，sql 语句如下：** 

修改表的字符集：

```


1.  `alter table t convert to character set utf8mb4;`
    


```

影响：拷贝全表，速度慢，会加锁，阻塞写操作

修改字段的字符集（utf8mb4 每字符占 4 字节，注意字段类型的最大字节数与字符长度关系）：

```


1.  `alter table t modify a char CHARACTER SET utf8mb4;`
    


```

影响：拷贝全表，速度慢，会加锁，阻塞写操作

修改 database 的字符集：

```


1.  `alter database sbtest CHARACTER SET utf8mb4;`
    


```

影响：只需修改元数据，速度很快