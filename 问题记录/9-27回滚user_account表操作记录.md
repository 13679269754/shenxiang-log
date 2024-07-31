| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2023-9月-27 | 2023-9月-27  |
| ... | ... | ... |
---
# 9-27回滚user_account表操作记录

[toc]

**日期**：23-09-27
**时间**：20:18 
**问题发现**：运营发现自己的账号手机号登录后数据丢失，让我们查看数据库user信息。经过查看新加一条用户数据，原有用户数据cellphone字段内容为 NULL。


**时间** ： 20:50
**问题定位**：1.通过archery 查看binlog 定位到有对user_account 表的cellphone字段批量置为 NULL 的操作。
         2.与开发核实，确实有对 user_account 表 进行过数据迁移的操作，并对部分数据清空cellphone字段。
         3.经过讨论确定，清空字段的操作，逻辑不对。需要回滚数据。

**时间** ： 21:15
**问题处理**：决定回滚这部分操作
binlog 处理过程如下

binlog 解析
```bash
/usr/local/data/mysql/bin/mysqlbinlog --database=user_data --base64-output=decode-rows -v --start-datetime='2023-09-26 18:00:00'  mysql-bin.001608 > /root/mysql_binlog.txt
/usr/local/data/mysql/bin/mysqlbinlog --database=user_data --base64-output=decode-rows -v --start-datetime='2023-09-26 18:00:00'  mysql-bin.001609 > /root/mysql_binlog_2.txt
```


获取对应事务日志：
```bash
cat mysql_binlog.txt |grep -A 61  'Update_rows: table id 8046' |grep -A 60  'UPDATE `user_data`.`uses_account`'  > ROLLBACK_0926.SQL
cat mysql_binlog_2.txt |grep -A 61  'Update_rows: table id 8046' |grep -A 60  'UPDATE `user_data`.`uses_account`'  > ROLLBACK_0926_2.SQL
```


得到如下 事务日志
```bash
### UPDATE `user_data`.`uses_account`
### WHERE
###   @1=31827812951441408
###   @2='ac31827812942004224'
###   @3='user31827812923129856'
###   @4='***'
###   @5='***'
###   @6='130****8051'
###   @7='21218cca77804d2ba1922c33e0151105'
###   @8='214D1B5E6F90CF6183D0E4AFBC0A9FB9'
###   @9=NULL
###   @10='2023-09-04 16:29:28'
###   @11=10
###   @12=NULL
###   @13=0
###   @14=NULL
###   @15=NULL
###   @16=NULL
###   @17='340000'
###   @18='341500'
###   @19='341503'
###   @20='341503101'
###   @21='222403201206'
###   @22=NULL
###   @23=NULL
###   @24=NULL
###   @25='2023-09-04 16:29:28'
###   @26=NULL
###   @27=NULL
###   @28='2023-09-04 16:29:28'
###   @29=0
### SET
###   @1=31827812951441408
###   @2='ac31827812942004224'
###   @3='user31827812923129856'
###   @4='***'
###   @5='***'
###   @6='130****8051'
###   @7='21218cca77804d2ba1922c33e0151105'
###   @8=NULL
###   @9=NULL
###   @10='2023-09-04 16:29:28'
###   @11=10
###   @12=NULL
###   @13=0
###   @14=NULL
###   @15=NULL
###   @16=NULL
###   @17='340000'
###   @18='341500'
###   @19='341503'
###   @20='341503101'
###   @21='222403201206'
###   @22=NULL
###   @23=NULL
###   @24=NULL
###   @25='2023-09-04 16:29:28'
###   @26=NULL
###   @27=NULL
###   @28='2023-09-04 16:29:28'
###   @29=0
--

```


vi 修改对应日志(删除不需要的字段，并将where，set 语句格式化)
vi 命令行
删除不需要的行
```bash
g/###   @2/d
g/###   @3/d
g/###   @4/d
g/###   @5/d
g/###   @6/d
g/###   @7/d
g/###   @9/d
g/###   @11/d
g/###   @12/d
g/###   @13/d
g/###   @14/d
g/###   @15/d
g/###   @16/d
g/###   @17/d
g/###   @18/d
g/###   @19/d
```


得到
```bash
### UPDATE `user_data`.`uses_account`
### WHERE
###   @1=31827812951441408
###   @8='214D1B5E6F90CF6183D0E4AFBC0A9FB9'
### SET
###   @1=31827812951441408
###   @8=NULL
--
```


格式化where 与set 
```bash
1,$ s/### WHERE/set/g
1,$ s/### SET/where/g
1,$ s/###   @1=/id=/g
1,$ s/###   @8=/,cellphone=/g
1,$ S/--/;/g
1,$ S/### UPDATE `user_data`.`uses_account`/UPDATE `user_data`.`uses_account`/g
```


得到
```bash
UPDATE `user_data`.`uses_account`
set
id=31827812951441408
，cellphone='214D1B5E6F90CF6183D0E4AFBC0A9FB9'
where
id=31827812951441408
，cellphone=NULL
;
```

`1,$ s/,cellphone=NULL/AND  cellphone=/g`

得到如下
```bash
UPDATE `user_data`.`uses_account`
set
id=31827812951441408
，cellphone='214D1B5E6F90CF6183D0E4AFBC0A9FB9'
where
id=31827812951441408
and  cellphone=NULL
;
```


保存退出得到：
ROLLBACK_0926.SQL
ROLLBACK_0926_2.SQL

```bash
chown mysql. ROLLBACK_0926*.SQL
mv ROLLBACK_0926*.SQL  /home/mysql/
```

进过测试语句无误，可以执行回滚。


登录mysql命令行
```bash
mysql> source  /home/mysql/ROLLBACK_0926.SQL
...
mysql> source  /home/mysql/ROLLBACK_0926_2.SQL
```

**执行完成**：查看更改结果，发现有一条数据没有修改过来，经过查看发现这条数据的主键为'1'，推测可能是人为不小心修改了数据的主键（这条数据为发现问题那条数据，经过了几次修改，排查问题）。将数据修改为原来的id,手工执行变更，将cellphone找回。

排查其他数据，没有发现问题。

binlog **回滚完毕**。

**时间**：23:00