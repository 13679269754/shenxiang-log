# InnoDB重做日志架构和innodb\_redo\_log\_capacity系统变量(译文)

[blog.csdn.net](https://blog.csdn.net/weixin_43424368/article/details/128506402)成就一亿技术人!

![在这里插入图片描述](https://image.cubox.pro/cardImg/2023100810355923347/73399.jpg?imageMogr2/quality/90/ignore-error/1)

说明：从MySQL 8.0.30开始，InnoDB的重做日志架构发生了重大变化，重做日志文件被固定为32个，并存放在一个专门的目录下面，用户可以使用系统变量innodb\_redo\_log\_capacity在线修改重做日志容量，原来的innodb\_log\_files\_in\_group和innodb\_log\_file\_size两个系统变量已经废弃。-
原文网址：https://lefred.be/content/dynamic-innodb-redo-log/ (有删节和修改)-
作者： Frédéric Descamps，Oracle公司MySQL社区经理，知名MySQL布道师 。-
![在这里插入图片描述](https://image.cubox.pro/cardImg/2023100810360016642/16534.jpg?imageMogr2/quality/90/ignore-error/1)-
译者，姚远：

## 系统变量innodb\_redo\_log\_capacity

从MySQL 8.0.30开始，InnoDB的重做日志架构发生了重大变化，之前官方MySQL的大部分更新都是变得更加像Oracle，但这次把挺像Oracle的重做日志给改的不像Oracle了。重做日志文件被固定为32个，并存放在一个专门的目录下面，用户可以使用系统变量innodb\_redo\_log\_capacity在线修改重做日志容量，原来的innodb\_log\_files\_in\_group和innodb\_log\_file\_size两个系统变量已经废弃，除非innodb\_redo\_log\_capacity没有设置。重做日志容量不；足会导致性能问题，但重做日志设置过大会浪费磁盘空间，并在崩溃恢复时增加恢复时间。

innodb\_redo\_log\_capacity默认为100MB，如果容量不够，在MySQL的错误日志中会有下面的提示：

> \[Warning\] \[MY-013865\] \[InnoDB\] Redo log writer is waiting for a new-
> redo log file. Consider increasing innodb\_redo\_log\_capacity.

可以使用下面的命令把日志容量设置为200MB：

    set global innodb_redo_log_capacity=200*1024*1024;
    
        

重做日志文件的位置也变了，不在是在数据目录（datadir）下面，现在存放在innodb\_log\_group\_home\_dir变量指定的目录下的#innodb\_redo（注意：前面的井号不是输入的错误）目录中，innodb\_log\_group\_home\_dir变量默认是数据目录（datadir）。检查这个目录内容如下：

    root@ubuntu:/var/lib/mysql/#innodb_redo# ls
    '#ib_redo50634'  '#ib_redo50638'      '#ib_redo50642_tmp'  '#ib_redo50646_tmp'  '#ib_redo50650_tmp'  '#ib_redo50654_tmp'  '#ib_redo50658_tmp'  '#ib_redo50662_tmp'
    '#ib_redo50635'  '#ib_redo50639'      '#ib_redo50643_tmp'  '#ib_redo50647_tmp'  '#ib_redo50651_tmp'  '#ib_redo50655_tmp'  '#ib_redo50659_tmp'  '#ib_redo50663_tmp'
    '#ib_redo50636'  '#ib_redo50640_tmp'  '#ib_redo50644_tmp'  '#ib_redo50648_tmp'  '#ib_redo50652_tmp'  '#ib_redo50656_tmp'  '#ib_redo50660_tmp'  '#ib_redo50664_tmp'
    '#ib_redo50637'  '#ib_redo50641_tmp'  '#ib_redo50645_tmp'  '#ib_redo50649_tmp'  '#ib_redo50653_tmp'  '#ib_redo50657_tmp'  '#ib_redo50661_tmp'  '#ib_redo50665_tmp'
    
        

这里有两类文件：

*   #ib\_redoXXX（其中XXX是一个序列号）：这些是活跃的重做日志文件，这里一共有6个。
*   #ib\_redoXXX\_tmp：那些是备用重做日志文件，这里一共26个。

InnoDB试图总共维护32个重做日志文件，每个文件的大小相等，并且是innodb\_redo\_log\_capacity的1/32。

## 新的重做日志架构

下面的图说明了重做日志的架构，图中有32个格子，每个代表一个重做日志文件。-
![在这里插入图片描述](https://image.cubox.pro/cardImg/2023100810360026530/47411.jpg?imageMogr2/quality/90/ignore-error/1)-
与重做日志相关的状态变量：

*   checkpoint\_lsn（状态变量Innodb\_redo\_log\_checkpoint\_lsn）：LSN的检查点，在这个点之前的所有更改都已写入到数据文件中，这个点之后的重做日志在进行崩溃恢复时有用。
*   flushed\_to\_disk\_lsn（状态变量Innodb\_redo\_log\_flushed\_to\_disk\_lsn）：重做日志中已刷新到磁盘的最后一个位置，但并不一定刷新到数据文件中。
*   current\_lsn（状态变量Innodb\_redo\_log\_current\_lsn）：重做日志中已刷新到操作系统缓存中的最后一个位置，但并不一定刷新到磁盘中。-
    ![在这里插入图片描述](https://image.cubox.pro/cardImg/2023100810360032277/75100.jpg?imageMogr2/quality/90/ignore-error/1)-
    当重做日志到达第31个文件的末尾时，日志文件管理器将执行一些清理，一些不再需要的活动文件将成为新的备用文件，图中表示方法是把虚线部分的格子被从左边移动到右边。-
    ![在这里插入图片描述](https://image.cubox.pro/cardImg/2023100810360036590/25699.jpg?imageMogr2/quality/90/ignore-error/1)
```sql
    SELECT file_id, start_lsn, end_lsn, 
           if(is_full=1,'100%',
              concat(round((((
                   select VARIABLE_VALUE 
                     from performance_schema.global_status 
                    where VARIABLE_NAME='Innodb_redo_log_current_lsn'
                   )-start_lsn)/(end_lsn-start_lsn)*100),2),'%')) full,
              concat(format_bytes(size_in_bytes)," / " ,
              format_bytes(@@innodb_redo_log_capacity) ) file_size, 
          (select VARIABLE_VALUE from performance_schema.global_status 
            where VARIABLE_NAME='Innodb_redo_log_checkpoint_lsn') checkpoint_lsn,
          (select VARIABLE_VALUE from performance_schema.global_status 
            where VARIABLE_NAME='Innodb_redo_log_current_lsn') current_lsn, 
          (select VARIABLE_VALUE from performance_schema.global_status 
            where VARIABLE_NAME='Innodb_redo_log_flushed_to_disk_lsn') flushed_to_disk_lsn,
          (select count from information_schema.INNODB_METRICS 
            where name like 'log_lsn_checkpoint_age') checkpoint_age 
    FROM performance_schema.innodb_redo_log_files;
```
        

![在这里插入图片描述](https://image.cubox.pro/cardImg/2023100810360184840/53278.jpg?imageMogr2/quality/90/ignore-error/1)

## 蛇的比喻

新的重做日志架构可以被视为一条蛇，这条蛇对应崩溃恢复时需要的重做日志信息，它分布在笼子上，每个笼子对应一个重做日志文件。这些笼子连续连接，这样蛇就可以持续前进。蛇的大小可以长得更长或缩小，当重做日志增加时，蛇的头部（current\_lsn）向右移动，当InnoDB将肮页从缓冲池刷新到数据文件中时，不需要的重做日志信息被截断，蛇的尾巴（checkpoint\_lsn）也向右移动。当蛇到达右边倒数第二个笼子的末端时，InnoDB从左边取出不再需要的笼子，把这些笼子放在右边。笼子的数量总是32个（除非非常特殊的情况）。

下面看看蛇的长度和负载的关系的例子，当没有负载时：-
![在这里插入图片描述](https://image.cubox.pro/cardImg/2023100810360164789/92303.jpg?imageMogr2/quality/90/ignore-error/1)-
![在这里插入图片描述](https://image.cubox.pro/cardImg/2023100810360111675/90159.jpg?imageMogr2/quality/90/ignore-error/1)-
在没有负载时，我们可以看到current\_lsn、checkpoint\_lsn和flushed\_to\_disk\_lsn具有相同的值。它们都在最后一个活动日志中(id 10844)。这是蛇的长度是最小值，512个字节。

有负载时：

![在这里插入图片描述](https://image.cubox.pro/cardImg/2023100810360240422/91092.jpg?imageMogr2/quality/90/ignore-error/1)-
![在这里插入图片描述](https://image.cubox.pro/cardImg/2023100810360290739/24842.jpg?imageMogr2/quality/90/ignore-error/1)-
这时蛇的长度是7.68Mib。

## 计算最佳InnoDB重做日志容量

可以根据Innodb\_redo\_log\_current\_lsn系统变量的变化计算出产生的InnoDB重做日志大小，在业务高峰期，您可以执行下面的4条SQL（放在一行中）计算InnoDB产生的重做日志的大小：
```sql
    select VARIABLE_VALUE from performance_schema.global_status 
     where VARIABLE_NAME='Innodb_redo_log_current_lsn' into @a;select sleep(60) into @garb ;select VARIABLE_VALUE from performance_schema.global_status 
     where VARIABLE_NAME='Innodb_redo_log_current_lsn' into @b;select 
     format_bytes(abs(@a - @b)) per_min, format_bytes(abs(@a - @b)*60) per_hour;
```    
        

![在这里插入图片描述](https://image.cubox.pro/cardImg/2023100810360279494/43724.jpg?imageMogr2/quality/90/ignore-error/1)-
经验是把重做日志容量设置到足以容纳1小时的日志，以免InnoDB在受到重做日志容量压力的情况下被迫把脏页刷新到磁盘，再大就没有必要了。

[托业890的Oracle ACE为您翻译国外大佬的雄文](https://blog.csdn.net/weixin_43424368/category_12247705.html)

[跳转到 Cubox 查看](https://cubox.pro/my/card?id=7110523654546393914)