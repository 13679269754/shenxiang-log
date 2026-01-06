# mysql大表迁移数据库

[toc]

## 一、背景

某天晚上 20:00 左右开发人员找到我，要求把 pre-prod 环境上的某张表导入到 prod ，第二天早上 07:00 上线要用。

该表有数亿条数据，压缩后 ibd 文件大约 25G 左右，表结构比较简单：

```sql
CREATE TABLE `t` (
 `UNIQUE_KEY` varchar(32) NOT NULL,
 `DESC` varchar(64) DEFAULT NULL ,
 `NUM_ID` int(10) DEFAULT '0' ,
PRIMARY KEY (`UNIQUE_KEY`),
KEY `index_NumID` (`NUM_ID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPRESSED
```

MySQL 版本：pre-prod 和 prod 都采用 5.7.25 ，单向主从结构。

## 二、解决方案

最简单的方法是采用 mysqldump + source ，但是该表数量比较多，之前测试的时候至少耗时 4h+ ，这次任务时间窗口比较短，如果中间执行失败再重试，可能会影响业务正式上线。采用 select into outfile + load infile 会快一点，但是该方案有个致命问题：该命令在主库会把所有数据当成单个事务执行，只有把数据全部成功插入后，才会将 binlog 复制到从库，这样会造成从库严重延迟，而且生成的单个 binlog 大小严重超标，在磁盘空间不足时可能会把磁盘占满。

经过比较，最终采用了可传输表空间方案，MySQL 5.6 借鉴 Oracle 引入该技术，允许在 2 个不同实例间快速的 copy innodb 大表。该方案规避了昂贵的 sql 解析和 B+tree 叶节点分裂，目标库可直接重用其他实例已有的 ibd 文件，只需同步一下数据字典，并对 ibd 文件页进行一下校验，即可完成数据同步操作。

具体操作步骤如下：

* 1. 目标库，创建表结构，然后执行 ALTER TABLE t DISCARD TABLESPACE ，此时表t只剩下 frm 文件
* 2. 源库，开启 2 个会话
  session1：执行 FLUSH TABLES t FOR EXPORT ，该命令会对 t 加锁，将t的脏数据从 buffer pool 同步到表文件，同时新生成 1 个文件 t.cfg ，该文件存储了表的数据字典信息
  session2：保持 session1 打开状态，此时将 t.cfg 和 t.ibd 远程传输到目标库的数据目录，如果目标库是主从结构，需要分别传输到主从两个实例，传输完毕后修改属主为 mysql:mysql
* 3. 源库，session1 执行 unlock tables ，解锁表 t ，此时 t 恢复正常读写
* 4. 目标库，执行 ALTER TABLE t IMPORT TABLESPACE ，如果是主从结构，只需要在主库执行即可

## 三、实测

针对该表，执行 ALTER TABLE ... IMPORT TABLESPACE 命令只需要 6 分钟完成，且 IO 消耗和主从延迟都被控制到合理范围。原本需要数个小时的操作，只需 10 多分钟完成（算上数据传输耗时）。如果线上有空表需要一次性加载大量数据，可以考虑先将数据导入到测试环境，然后通过可传输表空间技术同步到线上，可节约大量执行时间和服务器资源。

## 四、总结

可传输表空间，有如下使用限制：

* 源库和目标库版本一致
* 只适用于 innodb 引擎表
* 源库执行 flush tables t for export 时，该表会不可写