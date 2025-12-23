| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-10月-21 | 2024-10月-21  |
| ... | ... | ... |
---
# proxysql 审计日志

[toc]

## 源文档

[Audit log](https://proxysql.com/documentation/audit-log/)

Overview  
概述
-------------

Audit Log was introduced in ProxySQL since version 2.0.5 .  
自2.0.5版起，在ProxySQL中引入了审核日志。

This feature allows to track certain connection activities. Since ProxySQL is often used as the single point of access for the whole database infrastructure, it is often very important to monitor access to ProxySQL and the database setup behind ProxySQL itself. ProxySQL Audit Log solves exactly this requirement.  
此功能允许跟踪某些连接活动。由于ProxySQL通常用作整个数据库基础设施的单一访问点，因此监视对ProxySQL的访问以及ProxySQL本身背后的数据库设置通常非常重要。ProxySQL审计日志正好解决了这一需求。

To enable this feature, the variable `[mysql-auditlog_filename](https://proxysql.com/documentation/global-variables/mysql-variables/#mysql-auditlog_filename)` needs to be configured to specify a file where the logging will be performed. The default value of this variable is an empty string: no logging is enabled by default.  
要启用此功能，需要配置变量`[mysql-auditlog_filename](https://proxysql.com/documentation/global-variables/mysql-variables/#mysql-auditlog_filename)`以指定将执行日志记录的文件。此变量的默认值是空字符串：默认情况下不启用日志记录。

When enabled, the following events are logged:  
启用后，将记录以下事件：

*   on MySQL Module:MySQL Module：
    *   successful authentication成功认证
    *   failed authentication失败的认证
    *   graceful disconnect优雅断开
    *   closed connection关闭的连接
    *   change of schema (COM\_INIT\_DB)更改架构（COM\_INIT\_DB）
*   on Admin Module:管理模块：
    *   successful authentication成功认证
    *   failed authentication失败的认证
    *   graceful disconnect优雅断开
    *   closed connection关闭的连接

Further extensions are expected in the future, specifically:  
预计今后将进一步扩大，具体而言：

*   support for change of user (COM\_CHANGE\_USER) on MySQL Module  
    支持在MySQL模块上更改用户（COM\_CHANGE\_USER）
*   support for events on SQLite3 Server Module  
    支持SQLite3服务器模块上的事件
*   support for events on ClickHouse Module支持ClickHouse模块上的事件

Variables  
变量
--------------

*   `[mysql-auditlog_filename](https://proxysql.com/documentation/global-variables/mysql-variables/#mysql-auditlog_filename)` : this variable defines the base name of the audit log where audit events are logged. The filename of the log file will be the base name followed by an 8 digits progressive number.The default value is an empty string (“).  
    `[mysql-auditlog_filename](https://proxysql.com/documentation/global-variables/mysql-variables/#mysql-auditlog_filename)`：此变量定义记录审核事件的审核日志的基本名称。日志文件的文件名将是基名称，后跟一个8位数的渐进数字。默认值为空字符串（“）。
*   `[mysql-auditlog_filesize](https://proxysql.com/documentation/global-variables/mysql-variables/#mysql-auditlog_filesize)` : this variable defines the maximum file size of the audit log when the current file will be closed and a new file will be created.The default value is `104857600` (100MB).  
    `[mysql-auditlog_filesize](https://proxysql.com/documentation/global-variables/mysql-variables/#mysql-auditlog_filesize)`：这个变量定义了当当前文件将被关闭并创建一个新文件时，审核日志的最大文件大小。2默认值是`104857600`（100MB）。

Logging format  
日志记录格式
-----------------------

The current implementation supports only one logging format: JSON.  
当前的实现只支持一种日志格式：JSON。

Attributes:属性：

*   `client_addr` : address (IP:port) of the client connecting to ProxySQL  
    `client_addr`：客户端连接到ProxySQL的地址（IP：端口）
*   `proxy_addr` : address (IP:port) of the bind interface where ProxySQL was listening (available only for MySQL module)  
    `proxy_addr`：ProxySQL监听的绑定接口的地址（IP：port）（仅适用于MySQL模块）
*   `event`: type of event. Current possible values:：事件类型。当前可能值：
    *   `MySQL_Client_Connect_OK` : successful connection to MySQL Module  
        `MySQL_Client_Connect_OK`：成功连接到MySQL模块
    *   `MySQL_Client_Connect_ERR` : failed connection to MySQL Module  
        `MySQL_Client_Connect_ERR`：连接到MySQL模块失败
    *   `MySQL_Client_Close` : MySQL Session being closed  
        `MySQL_Client_Close`：MySQL Session正在关闭
    *   `MySQL_Client_Quit` : client sending an explicit `COM_QUIT` to MySQL Module  
        `MySQL_Client_Quit`：客户端向MySQL Module发送显式的`COM_QUIT`
    *   `MySQL_Client_Init_DB` : client sending an explicit `COM_INIT_DB` to MySQL Module  
        `MySQL_Client_Init_DB`：客户端向MySQL Module发送显式的`COM_INIT_DB`
    *   `Admin_Connect_OK` : successful connection to Admin Module  
        `Admin_Connect_OK`：成功连接到管理模块
    *   `Admin_Connect_ERR` : failed connection to Admin Module  
        `Admin_Connect_ERR`：连接到管理模块失败
    *   `Admin_Close` : Admin Session being closed  
        `Admin_Close`：Admin Session正在关闭
    *   `Admin_Quit` : client sending an explicit `COM_QUIT` to Admin Module  
        `Admin_Quit`：客户端向管理模块发送显式`COM_QUIT`
*   `time` : human readable time of when the event happened, with milliseconds granularity  
    `time`：人类可读的事件发生时间，以毫秒为粒度
*   `timestamp` : epoch time in milliseconds  
    `timestamp`：epoch time（毫秒）
*   `ssl` : boolean value that specifies if SSL is being used or not  
    `ssl`：指定是否使用SSL的布尔值
*   `schemaname`: the current schema for successful and established connection  
    `schemaname`：成功和已建立连接的当前模式
*   `username`: client’s username  
    `username`：客户端的用户名
*   `thread_id`: the thread\_id (session ID) assigned to the client  
    `thread_id`：分配给客户端的thread\_id（会话ID）
*   `creation_time` : when the session was created, information available only when the session is closed  
    `creation_time`：创建会话时，仅当会话关闭时信息可用
*   `duration` : time in milliseconds since the session was created, information available only when the session is closed  
    `duration`：自会话创建以来的时间（以毫秒为单位），仅当会话关闭时信息才可用
*   `extra_info` : attribute that provides additional information. Currently only used to describe in which part of the code the session is closed.  
    `extra_info`：提供附加信息的属性。当前仅用于描述会话在代码的哪一部分关闭。

Audit Log example  
审核日志示例
--------------------------

Below are some audit log examples.以下是一些审计日志示例。

**Detailed example #1:详细示例#1：** 

In the above example below, at the specified time (`"time":"2019-05-20 18:48:47.631","timestamp":1558342127631`) a client (`"client_addr":"127.0.0.1:39954"`) failed to connect to Admin (`"event":"Admin_Connect_ERR"`), without using SSL (`"ssl":false`) using username “admin” (`"username":"admin"`). To the connection was given an internal `thread_id` of `2` (`"thread_id":2`) .  
在下面的上述示例中，在指定的时间（`"time":"2019-05-20 18:48:47.631","timestamp":1558342127631`），客户端（`"client_addr":"127.0.0.1:39954"`）无法连接到Admin（`"event":"Admin_Connect_ERR"`），而没有使用SSL（`"ssl":false`）使用用户名“admin”（`"username":"admin"`）。对于连接，给出了`thread_id`（`2`）的内部`"thread_id":2`。

```
{
 "client_addr":"127.0.0.1:39954",
 "event":"Admin_Connect_ERR",
 "schemaname":"",
 "ssl":false,
 "thread_id":2,
 "time":"2019-05-20 18:48:47.631",
 "timestamp":1558342127631,
 "username":"admin"
}
```

Next, the same connection described above is disconnected (`"event":"Admin_Close"`) immediately after (`"duration":"0.000ms"`) . Extra information is also provided: `"extra_info":"MySQL_Thread.cpp:2652:~MySQL_Thread()"`.  
接着，在（`"event":"Admin_Close"`）之后立即断开上述相同的连接（`"duration":"0.000ms"`）。还提供了额外的信息：`"extra_info":"MySQL_Thread.cpp:2652:~MySQL_Thread()"`。

```
{
  "client_addr":"127.0.0.1:39954",
  "creation_time":"2019-05-20 18:48:47.631",
  "duration":"0.000ms",
  "event":"Admin_Close",
  "extra_info":"MySQL_Thread.cpp:2652:~MySQL_Thread()",
  "schemaname":"",
  "ssl":false,
  "thread_id":2,
  "time":"2019-05-20 18:48:47.631",
  "timestamp":1558342127631,
  "username":"admin"
}
```

**Detailed example #2:详细示例#2：** 

In the following output we can identify a successful login on Admin module (`"event":"Admin_Connect_OK"`) from `"client_addr":"127.0.0.1:43266"` , without SSL (`"ssl":false`) with username `admin`.  
在下面的输出中，我们可以从`"event":"Admin_Connect_OK"`中识别出在Admin模块（`"client_addr":"127.0.0.1:43266"`）上的成功登录，没有SSL（`"ssl":false`），用户名为`admin`。

```
{
  "client_addr":"127.0.0.1:43266",
  "event":"Admin_Connect_OK",
  "schemaname":"main",
  "ssl":false,
  "thread_id":3,
  "time":"2019-05-20 19:16:53.313",
  "timestamp":1558343813313,
  "username":"admin"
}
```

Next, the client listed above explicitly sends a `COM_QUIT` command (`"event":"Admin_Quit"`) .  
接下来，上面列出的客户端显式发送`COM_QUIT`命令（`"event":"Admin_Quit"`）。

```
{
  "client_addr":"127.0.0.1:43266",
  "event":"Admin_Quit",
  "schemaname":"main",
  "ssl":false,
  "thread_id":3,
  "time":"2019-05-20 19:16:56.513",
  "timestamp":1558343816513,
  "username":"admin"
}
```

Finally, the session from the above client is closed (`"event":"Admin_Close"`) after ~3.2 seconds (`"duration":"3200.191ms"`) the client connection was created.  
最后，在创建客户端连接约3.2秒（`"event":"Admin_Close"`）后，关闭来自上述客户端的会话（`"duration":"3200.191ms"`）。

```
{
  "client_addr":"127.0.0.1:43266",
  "creation_time":"2019-05-20 19:16:53.313",
  "duration":"3200.191ms", "event":"Admin_Close",
  "extra_info":"MySQL_Thread.cpp:2652:~MySQL_Thread()",
  "schemaname":"main",
  "ssl":false,
  "thread_id":3,
  "time":"2019-05-20 19:16:56.513",
  "timestamp":1558343816513,
  "username":"admin"
}
```

**Detailed example #3:详细示例#3：** 

In this example, a client (`"client_addr":"127.0.0.1:40822"`) successfully connects to MySQL module (`"event":"MySQL_Client_Connect_OK"`) on a given bind interface (`"proxy_addr":"0.0.0.0:6033"`) , without SSL (`"ssl":false`). Username (`"username":"sbtest"`) and schemaname (`"schemaname":"mysql"`) are logged.  
在本例中，客户端（`"client_addr":"127.0.0.1:40822"`）在给定的绑定接口（`"event":"MySQL_Client_Connect_OK"`）上成功连接到MySQL模块（`"proxy_addr":"0.0.0.0:6033"`），而不使用SSL（`"ssl":false`）。日志记录了schemaname（`"username":"sbtest"`）和schemaname（`"schemaname":"mysql"`）。

```
{
  "client_addr":"127.0.0.1:40822",
  "event":"MySQL_Client_Connect_OK",
  "proxy_addr":"0.0.0.0:6033",
  "schemaname":"mysql",
  "ssl":false,
  "thread_id":4,
  "time":"2019-05-20 19:20:26.668",
  "timestamp":1558344026668,
  "username":"sbtest"
}
```

Few seconds after, the same client issues a `COM_INIT_DB` (`"event":"MySQL_Client_Init_DB"`), switching schemaname (`"schemaname":"sbtest"`) . This will be recorded:  
几秒钟后，同一个客户端发出`COM_INIT_DB`（`"event":"MySQL_Client_Init_DB"`），切换schemaname（`"schemaname":"sbtest"`）。这将被记录：

```
{
  "client_addr":"127.0.0.1:40822",
  "event":"MySQL_Client_Init_DB",
  "proxy_addr":"0.0.0.0:6033",
  "schemaname":"sbtest",
  "ssl":false,
  "thread_id":4,
  "time":"2019-05-20 19:20:29.902",
  "timestamp":1558344029902,
  "username":"sbtest"
}
```

In the same example, after few more seconds the client issues a `COM_QUIT` (`"event":"MySQL_Client_Quit"`). This will be recorded:  
在同一个例子中，几秒钟后，客户端发出`COM_QUIT`（`"event":"MySQL_Client_Quit"`）。这将被记录：

```
{
  "client_addr":"127.0.0.1:40822",
  "event":"MySQL_Client_Quit",
  "proxy_addr":"0.0.0.0:6033",
  "schemaname":"sbtest",
  "ssl":false,
  "thread_id":4,
  "time":"2019-05-20 19:20:35.759",
  "timestamp":1558344035759,
  "username":"sbtest"
}
```

Finally, proxysql terminates the session (`"event":"MySQL_Client_Close"`), that lasted ~9 seconds (`"duration":"9091.966ms"`).  
最后，MySQL终止会话（`"event":"MySQL_Client_Close"`），持续了约9秒（`"duration":"9091.966ms"`）。

```
{
  "client_addr":"127.0.0.1:40822",
  "creation_time":"2019-05-20 19:20:26.668",
  "duration":"9091.966ms",
  "event":"MySQL_Client_Close",
  "extra_info":"MySQL_Thread.cpp:3733:process_all_sessions()",
  "proxy_addr":"0.0.0.0:6033",
  "schemaname":"sbtest",
  "ssl":false,
  "thread_id":4,
  "time":"2019-05-20 19:20:35.760",
  "timestamp":1558344035760,
  "username":"sbtest"
}
```

## 实践

[ProxySQL 审计](https://www.cnblogs.com/hahaha111122222/p/16394114.html)


