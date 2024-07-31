在了解动态权限之前，我们先回顾下 MySQL 的权限列表。

权限列表大体分为服务级别和表级别，列级别以及大而广的角色（也是MySQL 8.0 新增）存储程序等权限。我们看到有一个特殊的 SUPER 权限，可以做好多个操作。比如 SET 变量，在从机重新指定相关主机信息以及清理二进制日志等。那这里可以看到，SUPER 有点太过强大，导致了仅仅想实现子权限变得十分困难，比如用户只能 SET 变量，其他的都不想要。那么 MySQL 8.0 之前没法实现，权限的细分不够明确，容易让非法用户钻空子。

那么 MySQL 8.0 把权限细分为静态权限和动态权限，**下面我画了两张详细的区分图，图 1 为静态权限，图 2 为动态权限。** 

![](https://mmbiz.qpic.cn/mmbiz_png/a4DRmyJYHOwibUfdxDibia4GO5JYiajS3EvsXJyibGNnhZ5tYGbibWIVYDLLiaSTrdPDbTgCAEEE7gyOibFSdrM5fle5rA/640?wx_fmt=png)

**图 1- MySQL 静态权限的权限管理图**  

![](https://mmbiz.qpic.cn/mmbiz_png/a4DRmyJYHOwibUfdxDibia4GO5JYiajS3Evsg4H80sFTaPn086nujYIAQR60WqWtm0VzJ7O1ybmEaNUbxUZRMI94Mg/640?wx_fmt=png)

**图 2-动态权限图**

那我们看到其实动态权限就是对 SUPER 权限的细分。 SUPER 权限在未来将会被废弃掉。

我们来看个简单的例子，

比如， 用户 'ytt2@localhost', 有 SUPER 权限。

```


1.  `mysql> show grants for ytt2@'localhost';`
    
2.  `+---------------------------------------------------------------------------------+`
    
3.  `|  Grants  for ytt2@localhost |`
    
4.  `+---------------------------------------------------------------------------------+`
    
5.  `| GRANT INSERT, UPDATE, DELETE, CREATE, ALTER, SUPER ON *.* TO ytt2@localhost |`
    
6.  `+---------------------------------------------------------------------------------+`
    
7.  `1 row in  set  (0.00 sec)`
    


```

但是现在我只想这个用户有 SUPER 的子集，设置变量的权限。那么单独给这个用户赋予两个能设置系统变量的动态权限，完了把 SUPER 给拿掉。

```


1.  `mysql> grant session_variables_admin,system_variables_admin on *.* to ytt2@'localhost';`
    
2.  `Query OK,  0 rows affected (0.03 sec)`
    
3.  `mysql> revoke super on *.*  from ytt2@'localhost';`
    
4.  `Query OK,  0 rows affected,  1 warning (0.02 sec)`
    


```

我们看到这个 WARNINGS 提示 SUPER 已经废弃了。

```


1.  `mysql> show warnings;`
    
2.  `+---------+------+----------------------------------------------+`
    
3.  `|  Level  |  Code  |  Message  |`
    
4.  `+---------+------+----------------------------------------------+`
    
5.  `|  Warning  |  1287  |  The SUPER privilege identifier is deprecated |`
    
6.  `+---------+------+----------------------------------------------+`
    
7.  ``1 row in  set  (0.00 sec)` ``
    

9.  `mysql> show grants for ytt2@'localhost';`
    
10.  `+-----------------------------------------------------------------------------------+`
    
11.  `| Grants for ytt2@localhost                                                         |`
    
12.  `+-----------------------------------------------------------------------------------+`
    
13.  `| GRANT INSERT, UPDATE, DELETE, CREATE, ALTER ON *.* TO ytt2@localhost          |`
    
14.  `| GRANT SESSION_VARIABLES_ADMIN,SYSTEM_VARIABLES_ADMIN ON *.* TO ytt2@localhost |`
    
15.  `+-----------------------------------------------------------------------------------+`
    
16.  `2 rows in set (0.00 sec)`
    


```
