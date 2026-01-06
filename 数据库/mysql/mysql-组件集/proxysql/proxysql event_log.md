| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-22 | 2024-10月-22  |
| ... | ... | ... |
---
# proxysql event_log.md

[toc]

## 源资料

[Query Logging](https://proxysql.com/Documentation/Query-Logging/)


###  Query Logging

ProxySQL is able to log queries that pass through: optionally, you can set it up to save to disk all the SQL statements (or specific types of them) that are processed by the query processor and sent to backend hostgroups.  
ProxySQL能够记录通过的查询：可选地，您可以将其设置为将由查询处理器处理并发送到后端主机组的所有SQL语句（或特定类型的SQL语句）保存到磁盘。

Before version 2.0.6 , logging is configured with Query Rules using `mysql_query_rules.log`: this allows very broad or granular logging.  
From version 2.0.6 , a new global variable was added: `mysql-eventslog_default_log` .  
If no matching rule specifies a value `mysql_query_rules.log` , `mysql-eventslog_default_log` applies.  
the default value for `mysql-eventslog_default_log` is `0`, and the possible values are `0` and `1` .  
在2.0.6版本之前，日志记录是使用`mysql_query_rules.log`通过查询规则配置的：这允许非常广泛或粒度的日志记录。  
从2.0.6版本开始，添加了一个新的全局变量：`mysql-eventslog_default_log`。  
如果没有匹配的规则指定值`mysql_query_rules.log`，则应用`mysql-eventslog_default_log`。  
`mysql-eventslog_default_log`的默认值是`0`，可能的值是`0`和`1`。

### Setup  
----------

First, enable logging globally首先，启用全局日志记录

```sql
SET mysql-eventslog_filename='queries.log';

```

The variable needs to be loaded at runtime, and eventually saved to disk:  
变量需要在运行时加载，并最终保存到磁盘：

```sql
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;

```

If you did not change the variable `mysql-eventslog_format` from its default setting of `1` (logging queries in binary format) and you would like to log ALL queries, you do not need additional query rules for it to take effect, but you need to enable the global variable `mysql-eventslog_default_log`.  
如果您没有更改变量`mysql-eventslog_format`的默认设置`1`（以二进制格式记录查询），并且您希望记录所有查询，则不需要其他查询规则即可使其生效，但需要启用全局变量`mysql-eventslog_default_log`。

**Note:**  not all queries are processed by the query processor. Some special queries like `commit`, `rollback` and `set autocommit` are handled before the query processor. If you want to log also such queries it is required to enable logging globally.  
注意：并非所有查询都由查询处理器处理。一些特殊的查询如`commit`、`rollback`和`set autocommit`在查询处理器之前处理。如果您还想记录此类查询，则需要启用全局日志记录。

```sql
SET mysql-eventslog_default_log=1;
```

The variable needs to be loaded at runtime, and eventually saved to disk:  
变量需要在运行时加载，并最终保存到磁盘：

```sql
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
```

If you changed the variable `mysql-eventslog_format` to `2` (logging queries in JSON format, see below), and/or you would only like to log queries matching certain criteria, you need additional query rules in the following manner:  
如果您将变量`mysql-eventslog_format`更改为`2`（以JSON格式记录查询，请参阅下文），和/或您只想记录匹配某些条件的查询，则您需要以以下方式添加额外的查询规则：

If you don’t trust Bob, you can log all of Bob’s queries:  
如果你不信任Bob，你可以记录Bob的所有查询：

```sql
INSERT INTO mysql_query_rules (rule_id, active, username, log, apply) VALUES (1, 1, 'Bob', 1, 0);

```

If you want to log all `INSERT` statements against table `tableX`:  
如果你想记录表`INSERT`的所有`tableX`语句：

```sql
INSERT INTO mysql_query_rules (rule_id, active, match_digest, log, apply) VALUES (1, 1, 'INSERT.*tableX', 1, 0);

```

Now, make the rules active and persistent:  
现在，让规则活跃并持久化：

```SQL
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

### Query Logging Format before 2.0.6  
2.0.6之前的查询日志格式
--------------------------------------------------

Before version 2.0.6 , the queries are logged in binary format. There is a sample app included in source that can read the binary files and output plain text. The sample app is not included in the binary distribution.  
在2.0.6版本之前，查询以二进制格式记录。源代码中包含一个示例应用程序，可以读取二进制文件并输出纯文本。示例应用程序不包含在二进制发行版中。

```bash
$ ./tools/eventslog_reader_sample /var/lib/proxysql/file1.log.00001258
ProxySQL LOG QUERY: thread_id="2" username="root" schemaname=information_schema" client="127.0.0.1:58307" HID=0 server="127.0.0.1:3306" starttime="2016-10-23 12:34:37.132509" endtime="2016-10-23 12:34:38.347527" duration=1215018us digest="0xC5C3C490CA0825C1"
select sleep(1)
ProxySQL LOG QUERY: thread_id="2" username="root" schemaname=information_schema" client="127.0.0.1:58307" HID=0 server="127.0.0.1:3306" starttime="2016-10-23 12:41:38.604244" endtime="2016-10-23 12:41:38.813587" duration=209343us digest="0xE9D6D71A620B328F"
SELECT DATABASE()
ProxySQL LOG QUERY: thread_id="2" username="root" schemaname=test" client="127.0.0.1:58307" HID=0 server="127.0.0.1:3306" starttime="2016-10-23 12:42:38.511849" endtime="2016-10-23 12:42:38.712609" duration=200760us digest="0x524DB8D7A9B4C132"
select aaaaaaa

```

[https://github.com/sysown/proxysql/tree/v2.0.5/tools](https://github.com/sysown/proxysql/tree/v2.0.5/tools)

To build the sample app:要构建示例应用程序，请执行以下操作：

*   Clone the repo / Download the source克隆存储库/下载源代码
*   Change to tools directory更改为工具目录
*   execute `make`  
    执行`make`

Query Logging Format from 2.0.6  
从2.0.6开始查询日志记录格式
--------------------------------------------------

In version 2.0.6 a new variable controls the query logging format: `mysql-eventslog_format`.  
Possible values:  
在2.0.6版中，一个新变量控制查询日志记录格式：`mysql-eventslog_format`。  
可能的值：

*   `1` : this is the default: queries are logged in binary format (like before 2.0.6)  
    Note that in version 2.0.6 were introduced better support for prepared statements and the logging of `rows_affected` and `rows_sent`. For this reason make sure to use an updated `eventslog_reader_sample` to read these files.  
    `1`：这是默认值：查询以二进制格式记录（如2.0.6之前）  
    请注意，在2.0.6版本中，引入了对预处理语句的更好支持以及`rows_affected`和`rows_sent`的日志记录。因此，请确保使用更新的`eventslog_reader_sample`来读取这些文件。
*   `2` : the queries are logged in JSON format.  
    `2`：查询以JSON格式记录。

### JSON format logging  
JSON格式日志记录

To enable logging in JSON format it is required to set `mysql-eventslog_format=2`.  
要启用JSON格式的日志记录，需要设置`mysql-eventslog_format=2`。

```sql
SET mysql-eventslog_format=2;
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;

```

Example of JSON logging:JSON logging的例子：

```
~/proxysql/tools$ cat /var/lib/proxysql/events.00000001
{"client":"127.0.0.1:39840","digest":"0x226CD90D52A2BA0B","duration_us":0,"endtime":"2019-07-14 18:04:28.595961","endtime_timestamp_us":1563091468595961,"event":"COM_QUERY","hostgroup_id":-1,"query":"select @@version_comment limit 1","rows_affected":0,"rows_sent":0,"schemaname":"information_schema","starttime":"2019-07-14 18:04:28.595961","starttime_timestamp_us":1563091468595961,"thread_id":2,"username":"sbtest"}
{"client":"127.0.0.1:39840","digest":"0x1E092DAEFFBBF262","duration_us":8570,"endtime":"2019-07-14 18:04:34.400688","endtime_timestamp_us":1563091474400688,"event":"COM_QUERY","hostgroup_id":0,"query":"select 1","rows_affected":0,"rows_sent":1,"schemaname":"information_schema","server":"127.0.0.1:3306","starttime":"2019-07-14 18:04:34.392118","starttime_timestamp_us":1563091474392118,"thread_id":2,"username":"sbtest"}
{"client":"127.0.0.1:39840","digest":"0x620B328FE9D6D71A","duration_us":552,"endtime":"2019-07-14 18:04:46.129106","endtime_timestamp_us":1563091486129106,"event":"COM_QUERY","hostgroup_id":0,"query":"SELECT DATABASE()","rows_affected":0,"rows_sent":1,"schemaname":"information_schema","server":"127.0.0.1:3306","starttime":"2019-07-14 18:04:46.128554","starttime_timestamp_us":1563091486128554,"thread_id":2,"username":"sbtest"}
{"client":"127.0.0.1:39840","digest":"0x02033E45904D3DF0","duration_us":3412,"endtime":"2019-07-14 18:04:46.136484","endtime_timestamp_us":1563091486136484,"event":"COM_QUERY","hostgroup_id":0,"query":"show databases","rows_affected":0,"rows_sent":2,"schemaname":"test","server":"127.0.0.1:3306","starttime":"2019-07-14 18:04:46.133072","starttime_timestamp_us":1563091486133072,"thread_id":2,"username":"sbtest"}
{"client":"127.0.0.1:39840","digest":"0x99531AEFF718C501","duration_us":580,"endtime":"2019-07-14 18:04:46.137842","endtime_timestamp_us":1563091486137842,"event":"COM_QUERY","hostgroup_id":0,"query":"show tables","rows_affected":0,"rows_sent":2,"schemaname":"test","server":"127.0.0.1:3306","starttime":"2019-07-14 18:04:46.137262","starttime_timestamp_us":1563091486137262,"thread_id":2,"username":"sbtest"}
{"client":"127.0.0.1:39840","digest":"0xF434DBD7D158BC81","duration_us":10921,"endtime":"2019-07-14 18:05:05.769079","endtime_timestamp_us":1563091505769079,"event":"COM_QUERY","hostgroup_id":0,"query":"update test1 set id2=3 where id%2=0","rows_affected":2050,"rows_sent":0,"schemaname":"test","server":"127.0.0.1:3306","starttime":"2019-07-14 18:05:05.758158","starttime_timestamp_us":1563091505758158,"thread_id":2,"username":"sbtest"}
{"client":"127.0.0.1:39840","digest":"0xB99A00381BD4F14D","duration_us":5560,"endtime":"2019-07-14 18:05:15.773149","endtime_timestamp_us":1563091515773149,"event":"COM_QUERY","hostgroup_id":0,"query":"select * from test1","rows_affected":0,"rows_sent":4099,"schemaname":"test","server":"127.0.0.1:3306","starttime":"2019-07-14 18:05:15.767589","starttime_timestamp_us":1563091515767589,"thread_id":2,"username":"sbtest"}
{"client":"127.0.0.1:39840","digest":"0xF7E581BFC13DA7A4","duration_us":1783,"endtime":"2019-07-14 18:05:27.185155","endtime_timestamp_us":1563091527185155,"event":"COM_QUERY","hostgroup_id":0,"query":"SELECT * from test1 LIMIT 1000","rows_affected":0,"rows_sent":1000,"schemaname":"test","server":"127.0.0.1:3306","starttime":"2019-07-14 18:05:27.183372","starttime_timestamp_us":1563091527183372,"thread_id":2,"username":"sbtest"}
{"client":"127.0.0.1:39958","digest":"0x1E180DC9CAA12D69","duration_us":252,"endtime":"2019-07-14 18:06:03.283974","endtime_timestamp_us":1563091563283974,"event":"COM_STMT_PREPARE","hostgroup_id":0,"query":"SELECT id,id2 FROM test1 WHERE id= ?","rows_affected":0,"rows_sent":0,"schemaname":"test","server":"127.0.0.1:3306","starttime":"2019-07-14 18:06:03.283722","starttime_timestamp_us":1563091563283722,"thread_id":3,"username":"sbtest"}
{"client":"127.0.0.1:39958","digest":"0x1E180DC9CAA12D69","duration_us":186,"endtime":"2019-07-14 18:06:03.284413","endtime_timestamp_us":1563091563284413,"event":"COM_STMT_EXECUTE","hostgroup_id":0,"query":"SELECT id,id2 FROM test1 WHERE id= ?","rows_affected":0,"rows_sent":0,"schemaname":"test","server":"127.0.0.1:3306","starttime":"2019-07-14 18:06:03.284227","starttime_timestamp_us":1563091563284227,"thread_id":3,"username":"sbtest"}
{"client":"127.0.0.1:39958","digest":"0x98A2503010E9E4C8","duration_us":366,"endtime":"2019-07-14 18:06:03.285029","endtime_timestamp_us":1563091563285029,"event":"COM_STMT_PREPARE","hostgroup_id":0,"query":"SELECT id,id2 FROM test1 WHERE id < ?","rows_affected":0,"rows_sent":0,"schemaname":"test","server":"127.0.0.1:3306","starttime":"2019-07-14 18:06:03.284663","starttime_timestamp_us":1563091563284663,"thread_id":3,"username":"sbtest"}
{"client":"127.0.0.1:39958","digest":"0x98A2503010E9E4C8","duration_us":1491,"endtime":"2019-07-14 18:06:03.286928","endtime_timestamp_us":1563091563286928,"event":"COM_STMT_EXECUTE","hostgroup_id":0,"query":"SELECT id,id2 FROM test1 WHERE id < ?","rows_affected":0,"rows_sent":4099,"schemaname":"test","server":"127.0.0.1:3306","starttime":"2019-07-14 18:06:03.285437","starttime_timestamp_us":1563091563285437,"thread_id":3,"username":"sbtest"}
{"client":"127.0.0.1:39960","digest":"0x1E180DC9CAA12D69","duration_us":0,"endtime":"2019-07-14 18:06:04.011205","endtime_timestamp_us":1563091564011205,"event":"COM_STMT_PREPARE","hostgroup_id":-1,"query":"SELECT id,id2 FROM test1 WHERE id= ?","rows_affected":0,"rows_sent":0,"schemaname":"test","starttime":"2019-07-14 18:06:04.011205","starttime_timestamp_us":1563091564011205,"thread_id":4,"username":"sbtest"}
{"client":"127.0.0.1:39960","digest":"0x1E180DC9CAA12D69","duration_us":240,"endtime":"2019-07-14 18:06:04.011697","endtime_timestamp_us":1563091564011697,"event":"COM_STMT_EXECUTE","hostgroup_id":0,"query":"SELECT id,id2 FROM test1 WHERE id= ?","rows_affected":0,"rows_sent":0,"schemaname":"test","server":"127.0.0.1:3306","starttime":"2019-07-14 18:06:04.011457","starttime_timestamp_us":1563091564011457,"thread_id":4,"username":"sbtest"}
{"client":"127.0.0.1:39960","digest":"0x98A2503010E9E4C8","duration_us":0,"endtime":"2019-07-14 18:06:04.011912","endtime_timestamp_us":1563091564011912,"event":"COM_STMT_PREPARE","hostgroup_id":-1,"query":"SELECT id,id2 FROM test1 WHERE id < ?","rows_affected":0,"rows_sent":0,"schemaname":"test","starttime":"2019-07-14 18:06:04.011912","starttime_timestamp_us":1563091564011912,"thread_id":4,"username":"sbtest"}
{"client":"127.0.0.1:39960","digest":"0x98A2503010E9E4C8","duration_us":1492,"endtime":"2019-07-14 18:06:04.013779","endtime_timestamp_us":1563091564013779,"event":"COM_STMT_EXECUTE","hostgroup_id":0,"query":"SELECT id,id2 FROM test1 WHERE id < ?","rows_affected":0,"rows_sent":4099,"schemaname":"test","server":"127.0.0.1:3306","starttime":"2019-07-14 18:06:04.012287","starttime_timestamp_us":1563091564012287,"thread_id":4,"username":"sbtest"}

```