| operator | createtime  | updatetime  |
| -------- | ----------- | ----------- |
| shenx    | 2024-10月-08 | 2024-10月-08 |
| ... | ... | ... |
---
# 使用 xtrabackup 进行MySQL数据库物理备份

[toc]

## 源文档

[使用 xtrabackup 进行MySQL数据库物理备份](https://cubox.pro/my/card?id=7243503799967418508&internal=1)

## xtrabackup的功能

能实现的功能：

非阻塞备份innodb等事务引擎数据库、

备份myisam表会阻塞(需要锁)、

支持全备、增量备份、压缩备份、

快速增量备份(xtradb，原理类似于oracle：tracking 上次备份之后发生修改的page.)、

percona支持归档redo log的备份、

percona5.6+支持轻量级的backup-lock替代原来重量级的FTWRL，此时即使备份非事务引擎表也不会阻塞innodb的DML语句了、

支持加密备份、流备份(备份到远程机器)、并行本地备份、并行压缩、并行加密、并行应用备份期间产生的redo日志、并行copy-back

支持部分备份，只备份某个库，某个表

支持部分恢复

支持备份单个表分区

支持备份速度限制，指备份产生的IO速度的限制

支持point-in-time恢复

支持compat备份，也即使不备份索引数据，索引在prepare时--rebuild-indexs

支持备份buffer pool

支持单表export, import到其它库

支持 rsync 来缩短备份非事务引擎表的锁定时间

## 物理备份需要的权限

使用innobackupex/xtrabackup进行备份，必须先配置好权限。需要的权限分为两部分：

1>系统层面的权限： 执行 innobackupex/xtrabackup 命令的Linux用户需要对mysql datadir和保存备份的目录有读写执行的权限，当然需要对这些命令要有执行权限；

2>mysqld层面的权限：innobackupex/xtrabackup --user=bkpuser 该用户bkpuser是指mysql.user表中的用户，不是系统层面的用户；需要一些基本的权限来执行备份过程：

最基本的权限：

**create user 'bkpuser'@'localhost' identified by 'xxx';**

**grant reload,lock tables,replication client on *.* to 'bkpuser'@'localhost';**

这些权限仅仅只能完成：全备，增量备份，恢复；

一般如果需要部分备份，export表，import表，还需要：**grant create tablespace on *.* to 'bkpuser'@'localhost';**

如果还需要对备份的过程中对锁进行一些优化，防止发生阻塞所有DML的情况，则还需要：

**grant process,super on *.* to 'bkpuser'@'localhost';**
```sql
(root@localhost)[(none)]mysql>show grants for 'bkpuser'@'localhost'G  *************************** 1. row *************************** 
Grants for bkpuser@localhost: GRANT RELOAD, PROCESS, SUPER, LOCK TABLES, REPLICATION CLIENT, CREATE TABLESPACE ON *.* TO 'bkpuser'@'localhost' IDENTIFIED BY PASSWORD '*BDC62F68AF8F0B8BFAE27FF782C5D8CE9F4BAFCB'
1 row in set (0.00 sec)
```
## innobackupex 命令选项

```bash
[root@localhost ~]# innobackupex --help
Open source backup tool for InnoDB and XtraDB
[... ...]
innobackupex - Non-blocking backup tool for InnoDB, XtraDB and HailDB databases

SYNOPOSIS(使用方法)


innobackupex [--compress] [--compress-threads=NUMBER-OF-THREADS]        [--compress-chunk-size=CHUNK-SIZE]  
             [--encrypt=ENCRYPTION-ALGORITHM]   [--encrypt-threads=NUMBER-OF-THREADS]   [--encrypt-chunk-size=CHUNK-SIZE]  
             [--encrypt-key=LITERAL-ENCRYPTION-KEY]   [--encryption-key-file=MY.KEY]  
             [--include=REGEXP] [--user=NAME]  
             [--password=WORD] [--port=PORT] [--socket=SOCKET]  
             [--no-timestamp] [--ibbackup=IBBACKUP-BINARY]  
             [--slave-info] [--galera-info] [--stream=tar|xbstream]  
             [--defaults-file=MY.CNF] [--defaults-group=GROUP-NAME]  
             [--databases=LIST] [--no-lock]  
             [--tmpdir=DIRECTORY] [--tables-file=FILE]  
             [--history=NAME]  
             [--incremental] [--incremental-basedir]  
             [--incremental-dir] [--incremental-force-scan]   [--incremental-lsn]  
             [--incremental-history-name=NAME]   [--incremental-history-uuid=UUID]  
             [--close-files] [--compact]  
             BACKUP-ROOT-DIR

innobackupex --apply-log [--use-memory=B]
             [--defaults-file=MY.CNF]
             [--export] [--redo-only] [--ibbackup=IBBACKUP-BINARY]
             BACKUP-DIR

innobackupex --copy-back [--defaults-file=MY.CNF] [--defaults-group=GROUP-NAME] BACKUP-DIR

innobackupex --move-back [--defaults-file=MY.CNF] [--defaults-group=GROUP-NAME] BACKUP-DIR

innobackupex [--decompress] [--decrypt=ENCRYPTION-ALGORITHM]
             [--encrypt-key=LITERAL-ENCRYPTION-KEY] | [--encryption-key-file=MY.KEY]
             [--parallel=NUMBER-OF-FORKS] BACKUP-DIR

DESCRIPTION

The first command line above makes a hot backup of a MySQL database. By default it creates a backup directory (named by the current date
        and time) in the given backup root directory.  With the --no-timestamp
option it does not create a time-stamped backup directory, but it puts
the backup in the given directory (which must not exist). This
command makes a complete backup of all MyISAM and InnoDB tables and
indexes in all databases or in all of the databases specified with the --databases option.  The created backup contains .frm, .MRG, .MYD,
.MYI, .MAD, .MAI, .TRG, .TRN, .ARM, .ARZ, .CSM, CSV, .opt, .par, and
InnoDB data and log files.  The MY.CNF options file defines the
location of the database. This command connects to the MySQL server
using the mysql client program, and runs xtrabackup as a child
process. The --apply-log command prepares a backup for starting a MySQL
server on the backup. This command recovers InnoDB data files as specified
in BACKUP-DIR/backup-my.cnf using BACKUP-DIR/xtrabackup_logfile, and creates new InnoDB log files as specified in BACKUP-DIR/backup-my.cnf. The BACKUP-DIR should be the path to a backup directory created by
xtrabackup. This command runs xtrabackup as a child process, but it does not connect to the database server. The --copy-back command copies data, index, and log files
from the backup directory back to their original locations. The MY.CNF options file defines the original location of the database. The BACKUP-DIR is the path to a backup directory created by xtrabackup. The --move-back command is similar to --copy-back with the only difference that
it moves files to their original locations rather than copies them. As this
option removes backup files, it must be used with caution. It may be useful in
cases when there is not enough free disk space to copy files. The --decompress --decrypt command will decrypt and/or decompress a backup made
with the --compress and/or --encrypt options. When decrypting, the encryption
algorithm and key used when the backup was taken MUST be provided via the
specified options. --decrypt and --decompress may be used together at the same time to completely normalize a previously compressed and encrypted backup. The --parallel option will allow multiple files to be decrypted and/or decompressed
simultaneously. In order to decompress, the qpress utility MUST be installed
and accessable within the path. This process will remove the original
compressed/encrypted files and leave the results in the same location. On success the exit code innobackupex is 0. A non-zero exit code
indicates an error. Usage: [innobackupex [--defaults-file=#] --backup | innobackupex [--defaults-file=#] --prepare] [OPTIONS]
  -v, --version       print xtrabackup version information -?, --help          This option displays a help screen and exits.
  --apply-log         Prepare a backup in BACKUP-DIR by applying the
                      transaction log file named "xtrabackup_logfile" located
                      in the same directory. Also, create new transaction logs. The InnoDB configuration is read from the file "backup-my.cnf".
  --redo-only         This option should be used when preparing the base full
                      backup and when merging all incrementals except the last one. This forces xtrabackup to skip the "rollback" phase
                      and do a "redo" only. This is necessary if the backup
                      will have incremental changes applied to it later. See
                      the xtrabackup documentation for details.
  --copy-back         Copy all the files in a previously made backup from the
                      backup directory to their original locations.
  --move-back         Move all the files in a previously made backup from the
                      backup directory to the actual datadir location. Use with
                      caution, as it removes backup files.
  --galera-info       This options creates the xtrabackup_galera_info file
                      which contains the local node state at the time of the
                      backup. Option should be used when performing the backup
                      of Percona-XtraDB-Cluster. Has no effect when backup
                      locks are used to create the backup.
  --slave-info        This option is useful when backing up a replication slave
                      server. It prints the binary log position and name of the
                      master server. It also writes this information to the "xtrabackup_slave_info" file as a "CHANGE MASTER" command. A new slave for this master can be set up by
                      starting a slave server on this backup and issuing a "CHANGE MASTER" command with the binary log position
                      saved in the "xtrabackup_slave_info" file.
  --incremental       This option tells xtrabackup to create an incremental
                      backup, rather than a full one. It is passed to the
                      xtrabackup child process. When this option is specified, either --incremental-lsn or --incremental-basedir can
                      also be given. If neither option is given, option --incremental-basedir is passed to xtrabackup by default, set to the first timestamped backup directory in the
                      backup base directory.
  --no-lock           Use this option to disable table lock with "FLUSH TABLES
                      WITH READ LOCK". Use it only if ALL your tables are
                      InnoDB and you DO NOT CARE about the binary log position
                      of the backup. This option shouldn't be used if there are
                      any DDL statements being executed or if any updates are
                      happening on non-InnoDB tables (this includes the system
                      MyISAM tables in the mysql database), otherwise it could
                      lead to an inconsistent backup. If you are considering to
                      use --no-lock because your backups are failing to acquire
                      the lock, this could be because of incoming replication
                      events preventing the lock from succeeding. Please try
                      using --safe-slave-backup to momentarily stop the
                      replication slave thread, this may help the backup to
                      succeed and you then don't need to resort to using this
                      option.
  --safe-slave-backup Stop slave SQL thread and wait to start backup until Slave_open_temp_tables in "SHOW STATUS" is zero. If there
                      are no open temporary tables, the backup will take place, otherwise the SQL thread will be started and stopped until there are no open temporary tables. The backup will
                      fail if Slave_open_temp_tables does not become zero after --safe-slave-backup-timeout seconds. The slave SQL thread
                      will be restarted when the backup finishes.
  --rsync             Uses the rsync utility to optimize local file transfers. When this option is specified, innobackupex uses rsync to
                      copy all non-InnoDB files instead of spawning a separate
                      cp for each file, which can be much faster for servers
                      with a large number of databases or tables. This option
                      cannot be used together with --stream.
  --force-non-empty-directories
                      This option, when specified, makes --copy-back or --move-back transfer files to non-empty directories. Note
                      that no existing files will be overwritten. If
                      --copy-back or --nove-back has to copy a file from the
                      backup directory which already exists in the destination
                      directory, it will still fail with an error.
  --no-timestamp      This option prevents creation of a time-stamped
                      subdirectory of the BACKUP-ROOT-DIR given on the command
                      line. When it is specified, the backup is done in
                      BACKUP-ROOT-DIR instead.
  --no-version-check  This option disables the version check which is enabled
                      by the --version-check option.
  --no-backup-locks   This option controls if backup locks should be used
                      instead of FLUSH TABLES WITH READ LOCK on the backup
                      stage. The option has no effect when backup locks are not
                      supported by the server. This option is enabled by
                      default, disable with --no-backup-locks.
  --decompress        Decompresses all files with the .qp extension in a backup
                      previously made with the --compress option.
  --user=name         This option specifies the MySQL username used when
                      connecting to the server, if that's not the current user.
                      The option accepts a string argument. See mysql --help
                      for details.
  --host=name         This option specifies the host to use when connecting to
                      the database server with TCP/IP.  The option accepts a
                      string argument. See mysql --help for details.
  --port=#            This option specifies the port to use when connecting to
                      the database server with TCP/IP.  The option accepts a
                      string argument. See mysql --help for details.
  --password=name     This option specifies the password to use when connecting
                      to the database. It accepts a string argument.  See mysql
                      --help for details.
  --socket=name       This option specifies the socket to use when connecting
                      to the local database server with a UNIX domain socket.
                      The option accepts a string argument. See mysql --help
                      for details.
  --incremental-history-name=name
                      This option specifies the name of the backup series
                      stored in the PERCONA_SCHEMA.xtrabackup_history history
                      record to base an incremental backup on. Xtrabackup will
                      search the history table looking for the most recent
                      (highest innodb_to_lsn), successful backup in the series
                      and take the to_lsn value to use as the starting lsn for
                      the incremental backup. This will be mutually exclusive
                      with --incremental-history-uuid, --incremental-basedir
                      and --incremental-lsn. If no valid lsn can be found (no
                      series by that name, no successful backups by that name)
                      xtrabackup will return with an error. It is used with the
                      --incremental option.
  --incremental-history-uuid=name
                      This option specifies the UUID of the specific history
                      record stored in the PERCONA_SCHEMA.xtrabackup_history to
                      base an incremental backup on.
                      --incremental-history-name, --incremental-basedir and
                      --incremental-lsn. If no valid lsn can be found (no
                      success record with that uuid) xtrabackup will return
                      with an error. It is used with the --incremental option.
  --decrypt=name      Decrypts all files with the .xbcrypt extension in a
                      backup previously made with --encrypt option.
  --ftwrl-wait-query-type=name
                      This option specifies which types of queries are allowed
                      to complete before innobackupex will issue the global
                      lock. Default is all.
  --kill-long-query-type=name
                      This option specifies which types of queries should be
                      killed to unblock the global lock. Default is "all".
  --history[=name]    This option enables the tracking of backup history in the
                      PERCONA_SCHEMA.xtrabackup_history table. An optional
                      history series name may be specified that will be placed
                      with the history record for the current backup being
                      taken.
  --include=name      This option is a regular expression to be matched against
                      table names in databasename.tablename format. It is
                      passed directly to xtrabackup's --tables option. See the
                      xtrabackup documentation for details.
  --databases=name    This option specifies the list of databases that
                      innobackupex should back up. The option accepts a string
                      argument or path to file that contains the list of
                      databases to back up. The list is of the form "databasename1[.table_name1] databasename2[.table_name2]
                      . . .". If this option is not specified, all databases
                      containing MyISAM and InnoDB tables will be backed up. Please make sure that --databases contains all of the
                      InnoDB databases and tables, so that all of the
                      innodb.frm files are also backed up. In case the list is
                      very long, this can be specified in a file, and the full
                      path of the file can be specified instead of the list. (See option --tables-file.) --kill-long-queries-timeout=#
 This option specifies the number of seconds innobackupex
                      waits between starting FLUSH TABLES WITH READ LOCK and
                      killing those queries that block it. Default is 0 seconds, which means innobackupex will not attempt to kill any queries.
  --ftwrl-wait-timeout=#
                      This option specifies time in seconds that innobackupex
                      should wait for queries that would block FTWRL before
                      running it. If there are still such queries when the
                      timeout expires, innobackupex terminates with an error. Default is 0, in which case innobackupex does not wait
                      for queries to complete and starts FTWRL immediately.
  --ftwrl-wait-threshold=#
                      This option specifies the query run time threshold which
                      is used by innobackupex to detect long-running queries
                      with a non-zero value of --ftwrl-wait-timeout. FTWRL is
                      not started until such long-running queries exist. This
                      option has no effect if --ftwrl-wait-timeout is 0. Default value is 60 seconds.
  --debug-sleep-before-unlock=#
                      This is a debug-only option used by the XtraBackup test
                      suite.
  --safe-slave-backup-timeout=#
                      How many seconds --safe-slave-backup should wait for Slave_open_temp_tables to become zero. (default 300) --close-files       Do not keep files opened. This option is passed directly
                      to xtrabackup. Use at your own risk.
  --compact           Create a compact backup with all secondary index pages
                      omitted. This option is passed directly to xtrabackup. See xtrabackup documentation for details.
  --compress[=name]   This option instructs xtrabackup to compress backup
                      copies of InnoDB data files. It is passed directly to the
                      xtrabackup child process. Try 'xtrabackup --help' for more details.
  --compress-threads=#
 This option specifies the number of worker threads that
                      will be used for parallel compression. It is passed
                      directly to the xtrabackup child process. Try 'xtrabackup
                      --help' for more details.
  --compress-chunk-size=#
                      Size of working buffer(s) for compression threads in
                      bytes. The default value is 64K.
  --encrypt=name      This option instructs xtrabackup to encrypt backup copies
                      of InnoDB data files using the algorithm specified in the
                      ENCRYPTION-ALGORITHM. It is passed directly to the
                      xtrabackup child process. Try 'xtrabackup --help' for more details.
  --encrypt-key=name  This option instructs xtrabackup to use the given
                      ENCRYPTION-KEY when using the --encrypt or --decrypt
                      options. During backup it is passed directly to the
                      xtrabackup child process. Try 'xtrabackup --help' for more details.
  --encrypt-key-file=name
                      This option instructs xtrabackup to use the encryption
                      key stored in the given ENCRYPTION-KEY-FILE when using
                      the --encrypt or --decrypt options.
  --encrypt-threads=# This option specifies the number of worker threads that
                      will be used for parallel encryption. It is passed
                      directly to the xtrabackup child process. Try 'xtrabackup
                      --help' for more details.
  --encrypt-chunk-size=#
 This option specifies the size of the internal working
                      buffer for each encryption thread, measured in bytes. It
                      is passed directly to the xtrabackup child process. Try 'xtrabackup --help' for more details.
  --export            This option is passed directly to xtrabackup's --export
                      option. It enables exporting individual tables for import
                      into another server. See the xtrabackup documentation for
                      details.
  --extra-lsndir=name This option specifies the directory in which to save an
                      extra copy of the "xtrabackup_checkpoints" file. The
                      option accepts a string argument. It is passed directly
                      to xtrabackup's --extra-lsndir option. See the xtrabackup
                      documentation for details.
  --incremental-basedir=name
                      This option specifies the directory containing the full
                      backup that is the base dataset for the incremental
                      backup.  The option accepts a string argument. It is used
                      with the --incremental option.
  --incremental-dir=name
                      This option specifies the directory where the incremental
                      backup will be combined with the full backup to make a
                      new full backup.  The option accepts a string argument. It is used with the --incremental option.
  --incremental-force-scan
                      This options tells xtrabackup to perform full scan of
                      data files for taking an incremental backup even if full
                      changed page bitmap data is available to enable the
                      backup without the full scan.
  --log-copy-interval=#
                      This option specifies time interval between checks done
                      by log copying thread in milliseconds.
  --incremental-lsn=name
                      This option specifies the log sequence number (LSN) to use for the incremental backup. The option accepts a
                      string argument. It is used with the --incremental
                      option. It is used instead of specifying --incremental-basedir. For databases created by MySQL and
                      Percona Server 5.0-series versions, specify the LSN as
                      two 32-bit integers in high:low format. For databases
                      created in 5.1 and later, specify the LSN as a single 64-bit integer.
  --parallel=# On backup, this option specifies the number of threads
                      the xtrabackup child process should use to back up files
                      concurrently.  The option accepts an integer argument. It
                      is passed directly to xtrabackup's --parallel option. See
                      the xtrabackup documentation for details.
  --rebuild-indexes   This option only has effect when used together with the
                      --apply-log option and is passed directly to xtrabackup.
                      When used, makes xtrabackup rebuild all secondary indexes
                      after applying the log. This option is normally used to
                      prepare compact backups. See the XtraBackup manual for
                      more information.
  --rebuild-threads=# Use this number of threads to rebuild indexes in a
                      compact backup. Only has effect with --prepare and
                      --rebuild-indexes.
  --stream=name       This option specifies the format in which to do the
                      streamed backup.  The option accepts a string argument.
                      The backup will be done to STDOUT in the specified
                      format. Currently, the only supported formats are tar and
                      xbstream. This option is passed directly to xtrabackup's --stream option.
  --tables-file=name  This option specifies the file in which there are a list
                      of names of the form database. The option accepts a
                      string argument.table, one per line. The option is passed
                      directly to xtrabackup's --tables-file option.
  --throttle=#        This option specifies a number of I/O operations (pairs
                      of read+write) per second.  It accepts an integer
                      argument.  It is passed directly to xtrabackup's --throttle option.
  -t, --tmpdir=name   This option specifies the location where a temporary
                      files will be stored. If the option is not specified, the
                      default is to use the value of tmpdir read from the
                      server configuration.
  --use-memory=# This option accepts a string argument that specifies the
                      amount of memory in bytes for xtrabackup to use for crash
                      recovery while preparing a backup. Multiples are
                      supported providing the unit (e.g. 1MB, 1GB). It is used
                      only with the option --apply-log. It is passed directly
                      to xtrabackup's --use-memory option. See the xtrabackup
                      documentation for details.

```

## 使用 innobackupex 备份

### **3.1 全备**

**(这里系统层面使用的root用户备份，msyql层面使用的是bkpuser用户，root需要对datadir /var/lib/mysql, 备份目录/backup/xtrabackup/full有读写执行权限；bkpuser也需在mysql中有相关权限)**

```bash
[[root@localhost](mailto:root@localhost) ~]#**innobackupex  /backup/xtrabackup/full **--user=bkpuser --password=digdeep****

[root@localhost ~]# innobackupex  /backup/xtrabackup/full --user=bkpuser --password=digdeep
151105 22:38:55 innobackupex: Starting the backup operation

IMPORTANT: Please check that the backup run completes successfully. At the end of a successful backup run innobackupex
           prints "completed OK!".

151105 22:38:55  version_check Connecting to MySQL server with DSN 'dbi:mysql:;mysql_read_default_group=xtrabackup;mysql_socket=/tmp/mysql.sock' as 'bkpuser'  (using password: YES).
151105 22:38:56 version_check Connected to MySQL server 151105 22:38:56  version_check Executing a version check against the server...
151105 22:38:56  version_check Done.
151105 22:38:56 Connecting to MySQL server host: localhost, user: bkpuser, password: set, port: 0, socket: /tmp/mysql.sock
Using server version 5.6.26-log innobackupex version 2.3.2 based on MySQL server 5.6.24 Linux (i686) (revision id: 306a2e0)
xtrabackup: uses posix_fadvise(). xtrabackup: cd to /var/lib/mysql
xtrabackup: open files limit requested 0, set to 10240 xtrabackup: using the following InnoDB configuration: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:12M:autoextend
xtrabackup:   innodb_log_group_home_dir = ./ xtrabackup:   innodb_log_files_in_group = 2 xtrabackup:   innodb_log_file_size = 50331648
151105 22:38:56 >> log scanned up to (731470240)
xtrabackup: Generating a list of tablespaces 151105 22:38:56 [01] Copying ./ibdata1 to /backup/xtrabackup/full/2015-11-05_22-38-55/ibdata1 151105 22:38:57 >> log scanned up to (731470240) 151105 22:38:58 >> log scanned up to (731470240) 151105 22:38:58 [01]        ...done 151105 22:38:58 [01] Copying ./mysql/slave_master_info.ibd to /backup/xtrabackup/full/2015-11-05_22-38-55/mysql/slave_master_info.ibd 151105 22:38:58 [01]        ...done 151105 22:38:58 [01] Copying ./mysql/innodb_index_stats.ibd to /backup/xtrabackup/full/2015-11-05_22-38-55/mysql/innodb_index_stats.ibd 151105 22:38:58 [01]        ...done
[... ...] 151105 22:38:59 [01] Copying ./aazj/group_union.ibd to /backup/xtrabackup/full/2015-11-05_22-38-55/aazj/group_union.ibd 151105 22:38:59 [01]        ...done 151105 22:38:59 [01] Copying ./aazj/SYS_PARAM.ibd to /backup/xtrabackup/full/2015-11-05_22-38-55/aazj/SYS_PARAM.ibd 151105 22:38:59 >> log scanned up to (731470240) 151105 22:38:59 [01]        ...done 151105 22:38:59 [01] Copying ./aazj/GroupBlog.ibd to /backup/xtrabackup/full/2015-11-05_22-38-55/aazj/GroupBlog.ibd 151105 22:38:59 [01]        ...done
[... ...] 151105 22:39:01 [01] Copying ./aazj/Accounting_paylog.ibd to /backup/xtrabackup/full/2015-11-05_22-38-55/aazj/Accounting_paylog.ibd 151105 22:39:01 [01]        ...done 151105 22:39:01 [01] Copying ./aazj/Customer.ibd to /backup/xtrabackup/full/2015-11-05_22-38-55/aazj/Customer.ibd 151105 22:39:01 [01]        ...done 151105 22:39:01 [01] Copying ./aazj/uuu.ibd to /backup/xtrabackup/full/2015-11-05_22-38-55/aazj/uuu.ibd 151105 22:39:02 >> log scanned up to (731634905) 151105 22:39:03 >> log scanned up to (731634905) 151105 22:39:04 >> log scanned up to (731634905) 151105 22:39:04 [01]        ...done 151105 22:39:04 [01] Copying ./aazj/Members.ibd to /backup/xtrabackup/full/2015-11-05_22-38-55/aazj/Members.ibd 151105 22:39:05 [01]        ...done 151105 22:39:05 [01] Copying ./aazj/tttt.ibd to /backup/xtrabackup/full/2015-11-05_22-38-55/aazj/tttt.ibd 151105 22:39:05 [01]        ...done 151105 22:39:05 [01] Copying ./aazj/uu_test.ibd to /backup/xtrabackup/full/2015-11-05_22-38-55/aazj/uu_test.ibd 151105 22:39:05 >> log scanned up to (731634905) 151105 22:39:06 >> log scanned up to (731685874) 151105 22:39:07 >> log scanned up to (731686008) 151105 22:39:08 >> log scanned up to (731686008) 151105 22:39:08 [01]        ...done 151105 22:39:08 [01] Copying ./aazj/Mess_Receive.ibd to /backup/xtrabackup/full/2015-11-05_22-38-55/aazj/Mess_Receive.ibd 151105 22:39:09 [01]        ...done
[... ...] 151105 22:39:09 >> log scanned up to (731686008)
Executing FLUSH NO_WRITE_TO_BINLOG TABLES...
151105 22:39:09 Executing FLUSH TABLES WITH READ LOCK...
151105 22:39:09 Starting to backup non-InnoDB tables and files 151105 22:39:09 [01] Copying ./mysql/columns_priv.frm to /backup/xtrabackup/full/2015-11-05_22-38-55/mysql/columns_priv.frm 151105 22:39:09 [01]        ...done 151105 22:39:09 [01] Copying ./mysql/user.MYI to /backup/xtrabackup/full/2015-11-05_22-38-55/mysql/user.MYI 151105 22:39:09 [01]        ...done
[... ...] 151105 22:39:10 [01] Copying ./mysql/help_category.frm to /backup/xtrabackup/full/2015-11-05_22-38-55/mysql/help_category.frm 151105 22:39:10 [01]        ...done 151105 22:39:10 >> log scanned up to (731686008) 151105 22:39:10 [01] Copying ./mysql/proc.MYD to /backup/xtrabackup/full/2015-11-05_22-38-55/mysql/proc.MYD 151105 22:39:10 [01]        ...done
[... ...] 151105 22:39:10 [01]        ...done 151105 22:39:10 [01] Copying ./mysql/proxies_priv.MYI to /backup/xtrabackup/full/2015-11-05_22-38-55/mysql/proxies_priv.MYI 151105 22:39:10 [01]        ...done 151105 22:39:10 [01] Copying ./aazj/model_order.frm to /backup/xtrabackup/full/2015-11-05_22-38-55/aazj/model_order.frm 151105 22:39:10 [01]        ...done 151105 22:39:10 [01] Copying ./aazj/Comment.frm to /backup/xtrabackup/full/2015-11-05_22-38-55/aazj/Comment.frm 151105 22:39:10 [01]        ...done
[... ...] 151105 22:39:11 [01] Copying ./performance_schema/events_waits_summary_by_host_by_event_name.frm to /backup/xtrabackup/full/2015-11-05_22-38-55/performance_schema/events_waits_summary_by_host_by_event_name.frm 151105 22:39:11 [01]        ...done
[... ...] 151105 22:39:11 [01] Copying ./performance_schema/events_statements_summary_by_account_by_event_name.frm to /backup/xtrabackup/full/2015-11-05_22-38-55/performance_schema/events_statements_summary_by_account_by_event_name.frm 151105 22:39:11 [01]        ...done 151105 22:39:11 [01] Copying ./t/city.frm to /backup/xtrabackup/full/2015-11-05_22-38-55/t/city.frm 151105 22:39:11 [01]        ...done 151105 22:39:11 [01] Copying ./t/db.opt to /backup/xtrabackup/full/2015-11-05_22-38-55/t/db.opt 151105 22:39:11 [01]        ...done 151105 22:39:11 [01] Copying ./t/t.frm to /backup/xtrabackup/full/2015-11-05_22-38-55/t/t.frm 151105 22:39:11 [01]        ...done 151105 22:39:11 Finished backing up non-InnoDB tables and files 151105 22:39:11 [00] Writing xtrabackup_binlog_info 151105 22:39:11 [00]        ...done 151105 22:39:11 Executing FLUSH NO_WRITE_TO_BINLOG ENGINE LOGS... xtrabackup: The latest check point (for incremental): '731686008' xtrabackup: Stopping log copying thread.
.151105 22:39:11 >> log scanned up to (731686008) 151105 22:39:11 Executing UNLOCK TABLES 151105 22:39:11 All tables unlocked 151105 22:39:11 Backup created in directory '/backup/xtrabackup/full/2015-11-05_22-38-55' MySQL binlog position: filename 'mysql-bin.000015', position '117940'
151105 22:39:11 [00] Writing backup-my.cnf 151105 22:39:11 [00]        ...done 151105 22:39:11 [00] Writing xtrabackup_info 151105 22:39:11 [00]        ...done
xtrabackup: Transaction log of lsn (731470240) to (731686008) was copied.
151105 22:39:11 completed OK!

View Code

**3.2 恢复**

1> 第一步prepare(两次prepare，第一次应用备份期间产生的redo log，进行前滚和回滚：replay在redo log中已经提交的事务，rollback没有提交的事务)

注意这里的路径，必须要包括最后那个timestamp目录，不然会下面的错误：

[![](https://assets.cnblogs.com/images/copycode.gif)
](javascript:void(0); "复制代码")

[root@localhost ~]# innobackupex --apply-log /backup/xtrabackup/full/ --user=bkpuser --password=digdeep
151106 10:41:48 innobackupex: Starting the apply-log operation

IMPORTANT: Please check that the apply-log run completes successfully. At the end of a successful apply-log run innobackupex
           prints "completed OK!". innobackupex version 2.3.2 based on MySQL server 5.6.24 Linux (i686) (revision id: 306a2e0)
xtrabackup: cd to /backup/xtrabackup/full
xtrabackup: Error: cannot open ./xtrabackup_checkpoints
xtrabackup: error: xtrabackup_read_metadata()
xtrabackup: This target seems not to have correct metadata...
2015-11-06 10:41:48 b771e6d0  InnoDB: Operating system error number 2 in a file operation. InnoDB: The error means the system cannot find the path specified. xtrabackup: Warning: cannot open ./xtrabackup_logfile. will try to find.
2015-11-06 10:41:48 b771e6d0  InnoDB: Operating system error number 2 in a file operation. InnoDB: The error means the system cannot find the path specified. xtrabackup: Fatal error: cannot find ./xtrabackup_logfile. xtrabackup: Error: xtrabackup_init_temp_log() failed.

[![](https://assets.cnblogs.com/images/copycode.gif)
](javascript:void(0); "复制代码")

--apply-log会调用 xtrabackup --prepare两次，第一次前滚和回滚，第二次生成iblogfile[0|1]

[[root@localhost](mailto:root@localhost) ~]# **innobackupex --apply-log /backup/xtrabackup/full/2015-11-05_22-38-55/ **--user=bkpuser --password=digdeep****

![](https://images.cnblogs.com/OutliningIndicators/ContractedBlock.gif)
![](https://images.cnblogs.com/OutliningIndicators/ExpandedBlockStart.gif)

[root@localhost ~]# innobackupex --apply-log /backup/xtrabackup/full/2015-11-05_22-38-55/ --user=bkpuser --password=digdeep 
151106 10:43:32 innobackupex: Starting the apply-log operation

IMPORTANT: Please check that the apply-log run completes successfully. At the end of a successful apply-log run innobackupex
           prints "completed OK!". innobackupex version 2.3.2 based on MySQL server 5.6.24 Linux (i686) (revision id: 306a2e0)
xtrabackup: cd to /backup/xtrabackup/full/2015-11-05_22-38-55/ xtrabackup: This target seems to be not prepared yet. xtrabackup: xtrabackup_logfile detected: size=2097152, start_lsn=(731470240)
xtrabackup: using the following InnoDB configuration for recovery: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:10M:autoextend
xtrabackup:   innodb_log_group_home_dir = ./ xtrabackup:   innodb_log_files_in_group = 1 xtrabackup:   innodb_log_file_size = 2097152 xtrabackup: using the following InnoDB configuration for recovery: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:10M:autoextend
xtrabackup:   innodb_log_group_home_dir = ./ xtrabackup:   innodb_log_files_in_group = 1 xtrabackup:   innodb_log_file_size = 2097152 xtrabackup: Starting InnoDB instance for recovery. xtrabackup: Using 104857600 bytes for buffer pool (set by --use-memory parameter)
InnoDB: Using atomics to ref count buffer pool pages
InnoDB: The InnoDB memory heap is disabled
InnoDB: Mutexes and rw_locks use GCC atomic builtins
InnoDB: Memory barrier is not used
InnoDB: Compressed tables use zlib 1.2.3 InnoDB: Not using CPU crc32 instructions
InnoDB: Initializing buffer pool, size = 100.0M
InnoDB: Completed initialization of buffer pool
InnoDB: Highest supported file format is Barracuda. InnoDB: Log scan progressed past the checkpoint lsn 731470240 InnoDB: Database was not shutdown normally! InnoDB: Starting crash recovery. InnoDB: Reading tablespace information from the .ibd files... InnoDB: Restoring possible half-written data pages
InnoDB: from the doublewrite buffer... InnoDB: Doing recovery: scanned up to log sequence number 731686008 (11%)
InnoDB: Starting an apply batch of log records to the database... InnoDB: Progress in percent: 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 InnoDB: Apply batch completed
InnoDB: 128 rollback segment(s) are active. InnoDB: Waiting for purge to start
InnoDB: 5.6.24 started; log sequence number 731686008 xtrabackup: Last MySQL binlog file position 117940, file name mysql-bin.000015 ()

xtrabackup: starting shutdown with innodb_fast_shutdown = 1 InnoDB: FTS optimize thread exiting. InnoDB: Starting shutdown... InnoDB: Shutdown completed; log sequence number 731724574 xtrabackup: using the following InnoDB configuration for recovery: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:10M:autoextend
xtrabackup:   innodb_log_group_home_dir = ./ xtrabackup:   innodb_log_files_in_group = 2 xtrabackup:   innodb_log_file_size = 50331648 InnoDB: Using atomics to ref count buffer pool pages
InnoDB: The InnoDB memory heap is disabled
InnoDB: Mutexes and rw_locks use GCC atomic builtins
InnoDB: Memory barrier is not used
InnoDB: Compressed tables use zlib 1.2.3 InnoDB: Not using CPU crc32 instructions
InnoDB: Initializing buffer pool, size = 100.0M
InnoDB: Completed initialization of buffer pool
InnoDB: Setting log file ./ib_logfile101 size to 48 MB
InnoDB: Setting log file ./ib_logfile1 size to 48 MB
InnoDB: Renaming log file ./ib_logfile101 to ./ib_logfile0
InnoDB: New log files created, LSN=731724574 InnoDB: Highest supported file format is Barracuda. InnoDB: 128 rollback segment(s) are active. InnoDB: Waiting for purge to start
InnoDB: 5.6.24 started; log sequence number 731724812 xtrabackup: starting shutdown with innodb_fast_shutdown = 1 InnoDB: FTS optimize thread exiting. InnoDB: Starting shutdown... InnoDB: Shutdown completed; log sequence number 731724822
151106 10:43:40 completed OK! [root@localhost ~]#
```

### 3.3 恢复 --copy-back

直接将上面prepare好的所有文件，复制到mysqld的datadir目录(会读取my.cnf中的配置信息)。

--copy--back的注意事项：

1> datadir必须是空的，或者使用--force-non-empty-directories选项；

2> mysqld必须关闭，如果是--import部分恢复，则不能关闭；

3> --copy-back完成之后，需要修改datadir目录下的文件权限：

```bash

 chown -R mysql:mysql /var/lib/mysql

[[root@localhost](mailto:root@localhost) ~]# mysqladmin -uroot -pxxx shutdown (关闭mysqld)

[[root@localhost](mailto:root@localhost) ~]# cd /var/lib/mysql

[[root@localhost](mailto:root@localhost) mysql]# ls

aazj         ib_logfile1         mysql-bin.000003  mysql-bin.000008  mysql-bin.000013  performance_schema

auto.cnf     localhost-slow.log  mysql-bin.000004  mysql-bin.000009  mysql-bin.000014  t

general.log  mysql               mysql-bin.000005  mysql-bin.000010  mysql-bin.000015  xtrabackup_binlog_pos_innodb

ibdata1      mysql-bin.000001    mysql-bin.000006  mysql-bin.000011  mysql-bin.000016  xtrabackup_info

ib_logfile0  mysql-bin.000002    mysql-bin.000007  mysql-bin.000012  mysql-bin.index

[[root@localhost](mailto:root@localhost) mysql]# mv * /backup/xtrabackup/  (进行清空)

[[root@localhost](mailto:root@localhost) mysql]# ls

[[root@localhost](mailto:root@localhost) mysql]# **innobackupex --copy-back /backup/xtrabackup/full/2015-11-05_22-38-55/ **--user=bkpuser --password=digdeep****

[![](https://assets.cnblogs.com/images/copycode.gif)
](javascript:void(0); "复制代码")

[root@localhost mysql]# innobackupex --copy-back /backup/xtrabackup/full/2015-11-05_22-38-55/ --user=bkpuser --password=digdeep 
151106 11:07:38 innobackupex: Starting the copy-back operation

IMPORTANT: Please check that the copy-back run completes successfully. At the end of a successful copy-back run innobackupex
           prints "completed OK!". innobackupex version 2.3.2 based on MySQL server 5.6.24 Linux (i686) (revision id: 306a2e0) 151106 11:07:38 [01] Copying ib_logfile0 to /var/lib/mysql/ib_logfile0 151106 11:07:40 [01]        ...done 151106 11:07:40 [01] Copying ib_logfile1 to /var/lib/mysql/ib_logfile1 151106 11:07:41 [01]        ...done 151106 11:07:41 [01] Copying ibdata1 to /var/lib/mysql/ibdata1 151106 11:07:45 [01]        ...done 151106 11:07:45 [01] Copying ./xtrabackup_info to /var/lib/mysql/xtrabackup_info 151106 11:07:45 [01]        ...done 151106 11:07:45 [01] Copying ./mysql/slave_master_info.ibd to /var/lib/mysql/mysql/slave_master_info.ibd 151106 11:07:45 [01]        ...done
[... ...] 151106 11:07:57 [01] Copying ./t/db.opt to /var/lib/mysql/t/db.opt 151106 11:07:57 [01]        ...done 151106 11:07:57 [01] Copying ./t/t.frm to /var/lib/mysql/t/t.frm 151106 11:07:57 [01]        ...done 151106 11:07:57 completed OK! [root@localhost mysql]# pwd
/var/lib/mysql
[root@localhost mysql]# ls
aazj  ibdata1  ib_logfile0  ib_logfile1  mysql  performance_schema  t  xtrabackup_binlog_pos_innodb  xtrabackup_info
```

可以看到恢复之后，没有 binlog 文件盒index文件

启动myqld之前需要修改权限：

```bash

[root@localhost mysql]# ls -l
total 176164 drwx------ 2 root  root      4096 Nov  6 11:07 aazj -rw-rw---- 1 mysql mysql      543 Nov  6 11:13 general.log
-rw-r----- 1 root  root  79691776 Nov  6 11:07 ibdata1 -rw-r----- 1 root  root  50331648 Nov  6 11:07 ib_logfile0 -rw-r----- 1 root  root  50331648 Nov  6 11:07 ib_logfile1 -rw-rw---- 1 mysql mysql      543 Nov  6 11:13 localhost-slow.log drwx------ 2 root  root      4096 Nov  6 11:07 mysql -rw-rw---- 1 mysql mysql        0 Nov  6 11:12 mysql-bin.index drwx------ 2 root  root      4096 Nov  6 11:07 performance_schema
drwx------ 2 root  root      4096 Nov  6 11:07 t -rw-r----- 1 root  root        24 Nov  6 11:07 xtrabackup_binlog_pos_innodb -rw-r----- 1 root  root       487 Nov  6 11:07 xtrabackup_info
[root@localhost mysql]# chown -R mysql:mysql /var/lib/mysql
[root@localhost mysql]# ls -l
total 176164 drwx------ 2 mysql mysql     4096 Nov  6 11:07 aazj -rw-rw---- 1 mysql mysql      543 Nov  6 11:13 general.log
-rw-r----- 1 mysql mysql 79691776 Nov  6 11:07 ibdata1 -rw-r----- 1 mysql mysql 50331648 Nov  6 11:07 ib_logfile0 -rw-r----- 1 mysql mysql 50331648 Nov  6 11:07 ib_logfile1 -rw-rw---- 1 mysql mysql      543 Nov  6 11:13 localhost-slow.log drwx------ 2 mysql mysql     4096 Nov  6 11:07 mysql -rw-rw---- 1 mysql mysql        0 Nov  6 11:12 mysql-bin.index drwx------ 2 mysql mysql     4096 Nov  6 11:07 performance_schema
drwx------ 2 mysql mysql     4096 Nov  6 11:07 t -rw-r----- 1 mysql mysql       24 Nov  6 11:07 xtrabackup_binlog_pos_innodb -rw-r----- 1 mysql mysql      487 Nov  6 11:07 xtrabackup_info

···
```bash
不然启动会在error.log中报错：

2015-11-06 11:13:55 3542 [ERROR] InnoDB: ./ibdata1 can't be opened in read-write mode

2015-11-06 11:13:55 3542 [ERROR] InnoDB: The system tablespace must be writable!

2015-11-06 11:13:55 3542 [ERROR] Plugin 'InnoDB' init function returned error.

2015-11-06 11:13:55 3542 [ERROR] Plugin 'InnoDB' registration as a STORAGE ENGINE failed.

2015-11-06 11:13:55 3542 [ERROR] Unknown/unsupported storage engine: InnoDB

2015-11-06 11:13:55 3542 [ERROR] Aborting

启动成功之后，datadir目录下各种文件都产生了：

[[root@localhost](mailto:root@localhost) mysql]# pwd

/var/lib/mysql

[[root@localhost](mailto:root@localhost) mysql]# ls

aazj      general.log  ib_logfile0  localhost-slow.log  mysql-bin.000001  performance_schema  xtrabackup_binlog_pos_innodb

auto.cnf  ibdata1      ib_logfile1  mysql               mysql-bin.index   t                   xtrabackup_info
```

### 3.4 innobackupex 增量备份

增量备份之前，必须建立一个全备，第一次增量备份是在全备的基础之上，第二次增量备份是在第一次增量备份的基础之上的，一次类推

全备：

```bash
[[root@localhost](mailto:root@localhost) mysql]# innobackupex --user=bkpuser --password=digdeep /backup/xtrabackup/full

[root@localhost mysql]# innobackupex --user=bkpuser --password=digdeep /backup/xtrabackup/full
第一次增量备份:
--incremental /backup/xtrabackup/incr1/ 指定增量备份的位置； --incremental-basedir=指定上一次的全备或者增量备份：
[root@localhost mysql]# innobackupex --incremental /backup/xtrabackup/incr1/ --incremental-basedir=/backup/xtrabackup/full/2015-11-06_11-29-51/ --user=bkpuser --password=digdeep 
151106 11:33:16 innobackupex: Starting the backup operation

IMPORTANT: Please check that the backup run completes successfully. At the end of a successful backup run innobackupex
           prints "completed OK!".

151106 11:33:16  version_check Connecting to MySQL server with DSN 'dbi:mysql:;mysql_read_default_group=xtrabackup;mysql_socket=/tmp/mysql.sock' as 'bkpuser'  (using password: YES).
151106 11:33:16 version_check Connected to MySQL server 151106 11:33:16  version_check Executing a version check against the server...
151106 11:33:16  version_check Done.
151106 11:33:16 Connecting to MySQL server host: localhost, user: bkpuser, password: set, port: 0, socket: /tmp/mysql.sock
Using server version 5.6.26-log innobackupex version 2.3.2 based on MySQL server 5.6.24 Linux (i686) (revision id: 306a2e0)
incremental backup from 731724832 is enabled. xtrabackup: uses posix_fadvise(). xtrabackup: cd to /var/lib/mysql
xtrabackup: open files limit requested 0, set to 10240 xtrabackup: using the following InnoDB configuration: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:12M:autoextend
xtrabackup:   innodb_log_group_home_dir = ./ xtrabackup:   innodb_log_files_in_group = 2 xtrabackup:   innodb_log_file_size = 50331648
151106 11:33:16 >> log scanned up to (732153217)
xtrabackup: Generating a list of tablespaces
xtrabackup: using the full scan for incremental backup 151106 11:33:17 [01] Copying ./ibdata1 to /backup/xtrabackup/incr1//2015-11-06_11-33-16/ibdata1.delta 151106 11:33:17 >> log scanned up to (732153217) 151106 11:33:18 [01]        ...done 151106 11:33:18 >> log scanned up to (732153217) 151106 11:33:18 [01] Copying ./mysql/slave_master_info.ibd to /backup/xtrabackup/incr1//2015-11-06_11-33-16/mysql/slave_master_info.ibd.delta 151106 11:33:18 [01]        ...done 151106 11:33:19 >> log scanned up to (732153217)
[... ...] 151106 11:33:30 [01] Copying ./aazj/Configuration.ibd to /backup/xtrabackup/incr1//2015-11-06_11-33-16/aazj/Configuration.ibd.delta 151106 11:33:30 [01]        ...done 151106 11:33:31 [01] Copying ./aazj/lx_test.ibd to /backup/xtrabackup/incr1//2015-11-06_11-33-16/aazj/lx_test.ibd.delta 151106 11:33:31 >> log scanned up to (732231774) 151106 11:33:32 [01]        ...done 151106 11:33:32 >> log scanned up to (732231774) 151106 11:33:32 [01] Copying ./aazj/Users.ibd to /backup/xtrabackup/incr1//2015-11-06_11-33-16/aazj/Users.ibd.delta 151106 11:33:32 [01]        ...done
[... ...] 151106 11:33:42 [01] Copying ./aazj/tttt.ibd to /backup/xtrabackup/incr1//2015-11-06_11-33-16/aazj/tttt.ibd.delta 151106 11:33:42 [01]        ...done 151106 11:33:42 >> log scanned up to (732501432) 151106 11:33:42 [01] Copying ./aazj/uu_test.ibd to /backup/xtrabackup/incr1//2015-11-06_11-33-16/aazj/uu_test.ibd.delta
[... ...] 151106 11:33:47 [01] Copying ./t/t.ibd to /backup/xtrabackup/incr1//2015-11-06_11-33-16/t/t.ibd.delta 151106 11:33:48 [01]        ...done 151106 11:33:48 >> log scanned up to (732501432)
Executing FLUSH NO_WRITE_TO_BINLOG TABLES...
151106 11:33:48 Executing FLUSH TABLES WITH READ LOCK...
151106 11:33:48 Starting to backup non-InnoDB tables and files 151106 11:33:48 [01] Copying ./mysql/columns_priv.frm to /backup/xtrabackup/incr1//2015-11-06_11-33-16/mysql/columns_priv.frm 151106 11:33:48 [01]        ...done
[... ...] 151106 11:33:51 [01] Copying ./t/t.frm to /backup/xtrabackup/incr1//2015-11-06_11-33-16/t/t.frm 151106 11:33:51 [01]        ...done 151106 11:33:51 Finished backing up non-InnoDB tables and files 151106 11:33:51 [00] Writing xtrabackup_binlog_info 151106 11:33:51 [00]        ...done 151106 11:33:51 Executing FLUSH NO_WRITE_TO_BINLOG ENGINE LOGS... xtrabackup: The latest check point (for incremental): '732501432' xtrabackup: Stopping log copying thread.
.151106 11:33:51 >> log scanned up to (732501432) 151106 11:33:51 Executing UNLOCK TABLES 151106 11:33:51 All tables unlocked 151106 11:33:51 Backup created in directory '/backup/xtrabackup/incr1//2015-11-06_11-33-16' MySQL binlog position: filename 'mysql-bin.000001', position '157893'
151106 11:33:51 [00] Writing backup-my.cnf 151106 11:33:51 [00]        ...done 151106 11:33:51 [00] Writing xtrabackup_info 151106 11:33:51 [00]        ...done
xtrabackup: Transaction log of lsn (732153217) to (732501432) was copied.
151106 11:33:51 completed OK! [root@localhost mysql]#

```

**第二次增量备份:**

```bash
[[root@localhost](mailto:root@localhost) mysql]# innobackupex **--incremental /backup/xtrabackup/incr2** **--incremental-basedir=/backup/xtrabackup/incr1/2015-11-06_11-33-16/** --user=bkpuser --password=digdeep



[root@localhost mysql]# innobackupex --incremental /backup/xtrabackup/incr2 --incremental-basedir=/backup/xtrabackup/incr1/2015-11-06_11-33-16/ --user=bkpuser --password=digdeep
151106 11:43:22 innobackupex: Starting the backup operation

IMPORTANT: Please check that the backup run completes successfully. At the end of a successful backup run innobackupex
           prints "completed OK!".

151106 11:43:22  version_check Connecting to MySQL server with DSN 'dbi:mysql:;mysql_read_default_group=xtrabackup;mysql_socket=/tmp/mysql.sock' as 'bkpuser'  (using password: YES).
151106 11:43:22 version_check Connected to MySQL server 151106 11:43:22  version_check Executing a version check against the server...
151106 11:43:22  version_check Done.
151106 11:43:22 Connecting to MySQL server host: localhost, user: bkpuser, password: set, port: 0, socket: /tmp/mysql.sock
Using server version 5.6.26-log innobackupex version 2.3.2 based on MySQL server 5.6.24 Linux (i686) (revision id: 306a2e0)
incremental backup from 732501432 is enabled. xtrabackup: uses posix_fadvise(). xtrabackup: cd to /var/lib/mysql
xtrabackup: open files limit requested 0, set to 10240 xtrabackup: using the following InnoDB configuration: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:12M:autoextend
xtrabackup:   innodb_log_group_home_dir = ./ xtrabackup:   innodb_log_files_in_group = 2 xtrabackup:   innodb_log_file_size = 50331648
151106 11:43:23 >> log scanned up to (732501432)
xtrabackup: Generating a list of tablespaces 151106 11:43:23 [01] Copying ./ibdata1 to /backup/xtrabackup/incr2/2015-11-06_11-43-22/ibdata1.delta 151106 11:43:23 [01]        ...done 151106 11:43:24 >> log scanned up to (732552856) 151106 11:43:24 [01] Copying ./mysql/slave_master_info.ibd to /backup/xtrabackup/incr2/2015-11-06_11-43-22/mysql/slave_master_info.ibd.delta 151106 11:43:24 [01]        ...done 151106 11:43:25 >> log scanned up to (732552974) 151106 11:43:25 [01] Copying ./mysql/innodb_index_stats.ibd to /backup/xtrabackup/incr2/2015-11-06_11-43-22/mysql/innodb_index_stats.ibd.delta 151106 11:43:25 [01]        ...done 151106 11:43:25 [01] Copying ./mysql/slave_relay_log_info.ibd to /backup/xtrabackup/incr2/2015-11-06_11-43-22/mysql/slave_relay_log_info.ibd.delta 151106 11:43:25 [01]        ...done 151106 11:43:26 >> log scanned up to (732552974) 151106 11:43:26 [01] Copying ./mysql/slave_worker_info.ibd to /backup/xtrabackup/incr2/2015-11-06_11-43-22/mysql/slave_worker_info.ibd.delta 151106 11:43:26 [01]        ...done 151106 11:43:26 [01] Copying ./mysql/innodb_table_stats.ibd to /backup/xtrabackup/incr2/2015-11-06_11-43-22/mysql/innodb_table_stats.ibd.delta 151106 11:43:26 [01]        ...done 151106 11:43:27 >> log scanned up to (732716925) 151106 11:43:27 [01] Copying ./aazj/u_test.ibd to /backup/xtrabackup/incr2/2015-11-06_11-43-22/aazj/u_test.ibd.delta 151106 11:43:27 [01]        ...done
[... ...] 151106 11:43:50 [01] Copying ./t/t.frm to /backup/xtrabackup/incr2/2015-11-06_11-43-22/t/t.frm 151106 11:43:50 [01]        ...done 151106 11:43:50 Finished backing up non-InnoDB tables and files 151106 11:43:50 [00] Writing xtrabackup_binlog_info 151106 11:43:50 [00]        ...done 151106 11:43:50 Executing FLUSH NO_WRITE_TO_BINLOG ENGINE LOGS... xtrabackup: The latest check point (for incremental): '732777035' xtrabackup: Stopping log copying thread.
.151106 11:43:50 >> log scanned up to (732777035) 151106 11:43:50 Executing UNLOCK TABLES 151106 11:43:50 All tables unlocked 151106 11:43:50 Backup created in directory '/backup/xtrabackup/incr2/2015-11-06_11-43-22' MySQL binlog position: filename 'mysql-bin.000001', position '254400'
151106 11:43:50 [00] Writing backup-my.cnf 151106 11:43:50 [00]        ...done 151106 11:43:50 [00] Writing xtrabackup_info 151106 11:43:50 [00]        ...done
xtrabackup: Transaction log of lsn (732501432) to (732777035) was copied.
151106 11:43:50 completed OK! [root@localhost mysql]#

View Code

**3.5 innobackupex 增量备份的恢复**

**1> 应用全备的redo log:**

[[root@localhost](mailto:root@localhost) ~]# **innobackupex --apply-log --redo-only /backup/xtrabackup/full/2015-11-06_11-29-51/ --user=bkpuser --password=digdeep**

![](https://images.cnblogs.com/OutliningIndicators/ContractedBlock.gif)
![](https://images.cnblogs.com/OutliningIndicators/ExpandedBlockStart.gif)

[root@localhost ~]# innobackupex --apply-log --redo-only /backup/xtrabackup/full/2015-11-06_11-29-51/ --user=bkpuser --password=digdeep
151106 14:48:26 innobackupex: Starting the apply-log operation

IMPORTANT: Please check that the apply-log run completes successfully. At the end of a successful apply-log run innobackupex
           prints "completed OK!". innobackupex version 2.3.2 based on MySQL server 5.6.24 Linux (i686) (revision id: 306a2e0)
xtrabackup: cd to /backup/xtrabackup/full/2015-11-06_11-29-51/ xtrabackup: This target seems to be not prepared yet. xtrabackup: xtrabackup_logfile detected: size=2097152, start_lsn=(731724832)
xtrabackup: using the following InnoDB configuration for recovery: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:10M:autoextend
xtrabackup:   innodb_log_group_home_dir = ./ xtrabackup:   innodb_log_files_in_group = 1 xtrabackup:   innodb_log_file_size = 2097152 xtrabackup: using the following InnoDB configuration for recovery: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:10M:autoextend
xtrabackup:   innodb_log_group_home_dir = ./ xtrabackup:   innodb_log_files_in_group = 1 xtrabackup:   innodb_log_file_size = 2097152 xtrabackup: Starting InnoDB instance for recovery. xtrabackup: Using 104857600 bytes for buffer pool (set by --use-memory parameter)
InnoDB: Using atomics to ref count buffer pool pages
InnoDB: The InnoDB memory heap is disabled
InnoDB: Mutexes and rw_locks use GCC atomic builtins
InnoDB: Memory barrier is not used
InnoDB: Compressed tables use zlib 1.2.3 InnoDB: Not using CPU crc32 instructions
InnoDB: Initializing buffer pool, size = 100.0M
InnoDB: Completed initialization of buffer pool
InnoDB: Highest supported file format is Barracuda. InnoDB: The log sequence numbers 731724822 and 731724822 in ibdata files do not match the log sequence number 731724832 in the ib_logfiles! InnoDB: Database was not shutdown normally! InnoDB: Starting crash recovery. InnoDB: Reading tablespace information from the .ibd files... InnoDB: Restoring possible half-written data pages
InnoDB: from the doublewrite buffer... xtrabackup: Last MySQL binlog file position 117940, file name mysql-bin.000015 xtrabackup: starting shutdown with innodb_fast_shutdown = 1 InnoDB: Starting shutdown... InnoDB: Shutdown completed; log sequence number 731724832
151106 14:48:28 completed OK!

```

**2> 应用第一次增量备份的redo log:**

[[root@localhost](mailto:root@localhost) ~]#**innobackupex --apply-log --redo-only /backup/xtrabackup/full/2015-11-06_11-29-51/ --incremental-dir=/backup/xtrabackup/incr1/2015-11-06_11-33-16/ --user=bkpuser --password=digdeep**

![](https://images.cnblogs.com/OutliningIndicators/ContractedBlock.gif)
![](https://images.cnblogs.com/OutliningIndicators/ExpandedBlockStart.gif)

[root@localhost ~]# innobackupex --apply-log --redo-only /backup/xtrabackup/full/2015-11-06_11-29-51/ --incremental-dir=/backup/xtrabackup/incr1/2015-11-06_11-33-16/ --user=bkpuser --password=digdeep
151106 14:51:08 innobackupex: Starting the apply-log operation

IMPORTANT: Please check that the apply-log run completes successfully. At the end of a successful apply-log run innobackupex
           prints "completed OK!". innobackupex version 2.3.2 based on MySQL server 5.6.24 Linux (i686) (revision id: 306a2e0)
incremental backup from 731724832 is enabled. xtrabackup: cd to /backup/xtrabackup/full/2015-11-06_11-29-51/ xtrabackup: This target seems to be already prepared with --apply-log-only. xtrabackup: xtrabackup_logfile detected: size=2097152, start_lsn=(732153217)
xtrabackup: using the following InnoDB configuration for recovery: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:10M:autoextend
xtrabackup:   innodb_log_group_home_dir = /backup/xtrabackup/incr1/2015-11-06_11-33-16/ xtrabackup:   innodb_log_files_in_group = 1 xtrabackup:   innodb_log_file_size = 2097152 xtrabackup: Generating a list of tablespaces
xtrabackup: page size for /backup/xtrabackup/incr1/2015-11-06_11-33-16//ibdata1.delta is 16384 bytes
Applying /backup/xtrabackup/incr1/2015-11-06_11-33-16//ibdata1.delta to ./ibdata1... xtrabackup: page size for /backup/xtrabackup/incr1/2015-11-06_11-33-16//mysql/innodb_index_stats.ibd.delta is 16384 bytes
[... ...]
xtrabackup: page size for /backup/xtrabackup/incr1/2015-11-06_11-33-16//aazj/tttt.ibd.delta is 16384 bytes
Applying /backup/xtrabackup/incr1/2015-11-06_11-33-16//aazj/tttt.ibd.delta to ./aazj/tttt.ibd... xtrabackup: page size for /backup/xtrabackup/incr1/2015-11-06_11-33-16//aazj/Users.ibd.delta is 16384 bytes
Applying /backup/xtrabackup/incr1/2015-11-06_11-33-16//aazj/Users.ibd.delta to ./aazj/Users.ibd... xtrabackup: page size for /backup/xtrabackup/incr1/2015-11-06_11-33-16//aazj/Gis.ibd.delta is 16384 bytes
Applying /backup/xtrabackup/incr1/2015-11-06_11-33-16//aazj/Gis.ibd.delta to ./aazj/Gis.ibd... [... ...]
xtrabackup: page size for /backup/xtrabackup/incr1/2015-11-06_11-33-16//t/t.ibd.delta is 16384 bytes
Applying /backup/xtrabackup/incr1/2015-11-06_11-33-16//t/t.ibd.delta to ./t/t.ibd... xtrabackup: using the following InnoDB configuration for recovery: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:10M:autoextend
xtrabackup:   innodb_log_group_home_dir = /backup/xtrabackup/incr1/2015-11-06_11-33-16/ xtrabackup:   innodb_log_files_in_group = 1 xtrabackup:   innodb_log_file_size = 2097152 xtrabackup: Starting InnoDB instance for recovery. xtrabackup: Using 104857600 bytes for buffer pool (set by --use-memory parameter)
InnoDB: Using atomics to ref count buffer pool pages
InnoDB: The InnoDB memory heap is disabled
InnoDB: Mutexes and rw_locks use GCC atomic builtins
InnoDB: Memory barrier is not used
InnoDB: Compressed tables use zlib 1.2.3 InnoDB: Not using CPU crc32 instructions
InnoDB: Initializing buffer pool, size = 100.0M
InnoDB: Completed initialization of buffer pool
InnoDB: Highest supported file format is Barracuda. InnoDB: Log scan progressed past the checkpoint lsn 732153217 InnoDB: Database was not shutdown normally! InnoDB: Starting crash recovery. InnoDB: Reading tablespace information from the .ibd files... InnoDB: Restoring possible half-written data pages
InnoDB: from the doublewrite buffer... InnoDB: Doing recovery: scanned up to log sequence number 732501432 (18%)
InnoDB: Starting an apply batch of log records to the database... InnoDB: Progress in percent: 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39   40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 8  6 87 88 89 90 91 92 93 94 95 96 97 98 99 InnoDB: Apply batch completed
xtrabackup: Last MySQL binlog file position 157893, file name mysql-bin.000001 xtrabackup: starting shutdown with innodb_fast_shutdown = 1 InnoDB: Starting shutdown... InnoDB: Shutdown completed; log sequence number 732501432
151106 14:51:12 [01] Copying /backup/xtrabackup/incr1/2015-11-06_11-33-16/mysql/columns_priv.frm to ./mysql/columns_priv.frm 151106 14:51:12 [01]        ...done 151106 14:51:12 [01] Copying /backup/xtrabackup/incr1/2015-11-06_11-33-16/mysql/user.MYI to ./mysql/user.MYI 151106 14:51:12 [01]        ...done 151106 14:51:12 [01] Copying /backup/xtrabackup/incr1/2015-11-06_11-33-16/mysql/general_log.frm to ./mysql/general_log.frm 151106 14:51:12 [01]        ...done
[... ...] 151106 14:51:14 [01] Copying /backup/xtrabackup/incr1/2015-11-06_11-33-16/t/city.frm to ./t/city.frm 151106 14:51:14 [01]        ...done 151106 14:51:14 [01] Copying /backup/xtrabackup/incr1/2015-11-06_11-33-16/t/db.opt to ./t/db.opt 151106 14:51:14 [01]        ...done 151106 14:51:14 [01] Copying /backup/xtrabackup/incr1/2015-11-06_11-33-16/t/t.frm to ./t/t.frm 151106 14:51:14 [01]        ...done 151106 14:51:14 completed OK!

View Code

**3> 应用第二次(最后一次)增量备份的redo log，****并且回滚进行崩溃恢复过程(没有--redo-only选项)****:**

[[root@localhost](mailto:root@localhost) ~]# **innobackupex --apply-log /backup/xtrabackup/full/2015-11-06_11-29-51/ --incremental-dir=/backup/xtrabackup/incr2/2015-1  1-06_11-43-22/ --user=bkpuser --password=digdeep**

![](https://images.cnblogs.com/OutliningIndicators/ContractedBlock.gif)
![](https://images.cnblogs.com/OutliningIndicators/ExpandedBlockStart.gif)

[root@localhost ~]# innobackupex --apply-log /backup/xtrabackup/full/2015-11-06_11-29-51/ --incremental-dir=/backup/xtrabackup/incr2/2015-1  1-06_11-43-22/ --user=bkpuser --password=digdeep
151106 14:55:43 innobackupex: Starting the apply-log operation

IMPORTANT: Please check that the apply-log run completes successfully. At the end of a successful apply-log run innobackupex
           prints "completed OK!". innobackupex version 2.3.2 based on MySQL server 5.6.24 Linux (i686) (revision id: 306a2e0)
incremental backup from 732501432 is enabled. xtrabackup: cd to /backup/xtrabackup/full/2015-11-06_11-29-51/ xtrabackup: This target seems to be already prepared with --apply-log-only. xtrabackup: xtrabackup_logfile detected: size=2097152, start_lsn=(732501432)
xtrabackup: using the following InnoDB configuration for recovery: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:10M:autoextend
xtrabackup:   innodb_log_group_home_dir = /backup/xtrabackup/incr2/2015-11-06_11-43-22/ xtrabackup:   innodb_log_files_in_group = 1 xtrabackup:   innodb_log_file_size = 2097152 xtrabackup: Generating a list of tablespaces
xtrabackup: page size for /backup/xtrabackup/incr2/2015-11-06_11-43-22//ibdata1.delta is 16384 bytes
Applying /backup/xtrabackup/incr2/2015-11-06_11-43-22//ibdata1.delta to ./ibdata1... xtrabackup: page size for /backup/xtrabackup/incr2/2015-11-06_11-43-22//mysql/innodb_index_stats.ibd.delta is 16384 bytes
Applying /backup/xtrabackup/incr2/2015-11-06_11-43-22//mysql/innodb_index_stats.ibd.delta to ./mysql/innodb_index_stats.ibd... [... ...]
Applying /backup/xtrabackup/incr2/2015-11-06_11-43-22//t/city.ibd.delta to ./t/city.ibd... xtrabackup: page size for /backup/xtrabackup/incr2/2015-11-06_11-43-22//t/t.ibd.delta is 16384 bytes
Applying /backup/xtrabackup/incr2/2015-11-06_11-43-22//t/t.ibd.delta to ./t/t.ibd... xtrabackup: using the following InnoDB configuration for recovery: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:10M:autoextend
xtrabackup:   innodb_log_group_home_dir = /backup/xtrabackup/incr2/2015-11-06_11-43-22/ xtrabackup:   innodb_log_files_in_group = 1 xtrabackup:   innodb_log_file_size = 2097152 xtrabackup: Starting InnoDB instance for recovery. xtrabackup: Using 104857600 bytes for buffer pool (set by --use-memory parameter)
InnoDB: Using atomics to ref count buffer pool pages
InnoDB: The InnoDB memory heap is disabled
InnoDB: Mutexes and rw_locks use GCC atomic builtins
InnoDB: Memory barrier is not used
InnoDB: Compressed tables use zlib 1.2.3 InnoDB: Not using CPU crc32 instructions
InnoDB: Initializing buffer pool, size = 100.0M
InnoDB: Completed initialization of buffer pool
InnoDB: Highest supported file format is Barracuda. InnoDB: Log scan progressed past the checkpoint lsn 732501432 InnoDB: Database was not shutdown normally! InnoDB: Starting crash recovery. InnoDB: Reading tablespace information from the .ibd files... InnoDB: Restoring possible half-written data pages
InnoDB: from the doublewrite buffer... InnoDB: Doing recovery: scanned up to log sequence number 732777035 (14%)
InnoDB: Starting an apply batch of log records to the database... InnoDB: Progress in percent: 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39   40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 8  6 87 88 89 90 91 92 93 94 95 96 97 98 99 InnoDB: Apply batch completed
InnoDB: 128 rollback segment(s) are active. InnoDB: Waiting for purge to start
InnoDB: 5.6.24 started; log sequence number 732777035 xtrabackup: Last MySQL binlog file position 254400, file name mysql-bin.000001 xtrabackup: starting shutdown with innodb_fast_shutdown = 1 InnoDB: FTS optimize thread exiting. InnoDB: Starting shutdown... InnoDB: Shutdown completed; log sequence number 732817046
151106 14:55:47 [01] Copying /backup/xtrabackup/incr2/2015-11-06_11-43-22/mysql/columns_priv.frm to ./mysql/columns_priv.frm 151106 14:55:47 [01]        ...done 151106 14:55:47 [01] Copying /backup/xtrabackup/incr2/2015-11-06_11-43-22/mysql/user.MYI to ./mysql/user.MYI 151106 14:55:47 [01]        ...done
[... ...] 151106 14:55:50 [01] Copying /backup/xtrabackup/incr2/2015-11-06_11-43-22/t/db.opt to ./t/db.opt 151106 14:55:50 [01]        ...done 151106 14:55:50 [01] Copying /backup/xtrabackup/incr2/2015-11-06_11-43-22/t/t.frm to ./t/t.frm 151106 14:55:50 [01]        ...done
xtrabackup: using the following InnoDB configuration for recovery: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:10M:autoextend
xtrabackup:   innodb_log_group_home_dir = /backup/xtrabackup/incr2/2015-11-06_11-43-22/ xtrabackup:   innodb_log_files_in_group = 2 xtrabackup:   innodb_log_file_size = 50331648 InnoDB: Using atomics to ref count buffer pool pages
InnoDB: The InnoDB memory heap is disabled
InnoDB: Mutexes and rw_locks use GCC atomic builtins
InnoDB: Memory barrier is not used
InnoDB: Compressed tables use zlib 1.2.3 InnoDB: Not using CPU crc32 instructions
InnoDB: Initializing buffer pool, size = 100.0M
InnoDB: Completed initialization of buffer pool
InnoDB: Setting log file /backup/xtrabackup/incr2/2015-11-06_11-43-22/ib_logfile101 size to 48 MB
InnoDB: Setting log file /backup/xtrabackup/incr2/2015-11-06_11-43-22/ib_logfile1 size to 48 MB
InnoDB: Renaming log file /backup/xtrabackup/incr2/2015-11-06_11-43-22/ib_logfile101 to /backup/xtrabackup/incr2/2015-11-06_11-43-22/ib_logfile0
InnoDB: New log files created, LSN=732817046 InnoDB: Highest supported file format is Barracuda. InnoDB: 128 rollback segment(s) are active. InnoDB: Waiting for purge to start
InnoDB: 5.6.24 started; log sequence number 732817420 xtrabackup: starting shutdown with innodb_fast_shutdown = 1 InnoDB: FTS optimize thread exiting. InnoDB: Starting shutdown... InnoDB: Shutdown completed; log sequence number 732817430
151106 14:55:54 completed OK!

View Code

[[root@localhost](mailto:root@localhost) ~]#

然后 --copy-back:

先关闭mysqld: mysqladmin -uroot -pxxx shutdown

[[root@localhost](mailto:root@localhost) mysql]# innobackupex --copy-back /backup/xtrabackup/full/2015-11-06_11-29-51/ --user=bkpuser --password=digdeep

![](https://images.cnblogs.com/OutliningIndicators/ContractedBlock.gif)
![](https://images.cnblogs.com/OutliningIndicators/ExpandedBlockStart.gif)

[root@localhost mysql]# innobackupex --copy-back /backup/xtrabackup/full/2015-11-06_11-29-51/ --user=bkpuser --password=digdeep
151106 15:10:23 innobackupex: Starting the copy-back operation

IMPORTANT: Please check that the copy-back run completes successfully. At the end of a successful copy-back run innobackupex
           prints "completed OK!". innobackupex version 2.3.2 based on MySQL server 5.6.24 Linux (i686) (revision id: 306a2e0) 151106 15:10:23 [01] Copying ibdata1 to /var/lib/mysql/ibdata1 151106 15:10:28 [01]        ...done 151106 15:10:28 [01] Copying ./xtrabackup_info to /var/lib/mysql/xtrabackup_info 151106 15:10:28 [01]        ...done
[... ...] 151106 15:10:41 [01]        ...done 151106 15:10:41 [01] Copying ./t/db.opt to /var/lib/mysql/t/db.opt 151106 15:10:41 [01]        ...done 151106 15:10:41 [01] Copying ./t/t.frm to /var/lib/mysql/t/t.frm 151106 15:10:41 [01]        ...done 151106 15:10:42 completed OK!

View Code

修改权限：

chown -R mysql:mysql /var/lib/mysql

启动：mysqld_safe --user=mysql &

最后验证还原成功。

**4. 部分备份**

需要启用 innodb_file_per_table，5.6默认启用。另外在还原时，prepare之后，并不能直接 --copy-back，而只能一个表一个表的import来还原。

[[root@localhost](mailto:root@localhost) xtrabackup]#**innobackupex --databases t /backup/xtrabackup/ --user=bkpuser --password=digdeep**


[root@localhost xtrabackup]# innobackupex --databases t /backup/xtrabackup/ --user=bkpuser --password=digdeep
151106 15:39:34 innobackupex: Starting the backup operation

IMPORTANT: Please check that the backup run completes successfully. At the end of a successful backup run innobackupex
           prints "completed OK!".

151106 15:39:35  version_check Connecting to MySQL server with DSN 'dbi:mysql:;mysql_read_default_group=xtrabackup;mysql_socket=/tmp/mysql.  sock' as 'bkpuser'  (using password: YES).
151106 15:39:35 version_check Connected to MySQL server 151106 15:39:35  version_check Executing a version check against the server...
151106 15:39:35  version_check Done.
151106 15:39:35 Connecting to MySQL server host: localhost, user: bkpuser, password: set, port: 0, socket: /tmp/mysql.sock
Using server version 5.6.26-log innobackupex version 2.3.2 based on MySQL server 5.6.24 Linux (i686) (revision id: 306a2e0)
xtrabackup: uses posix_fadvise(). xtrabackup: cd to /var/lib/mysql
xtrabackup: open files limit requested 0, set to 10240 xtrabackup: using the following InnoDB configuration: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:12M:autoextend
xtrabackup:   innodb_log_group_home_dir = ./ xtrabackup:   innodb_log_files_in_group = 2 xtrabackup:   innodb_log_file_size = 50331648
151106 15:39:35 >> log scanned up to (732817942)
xtrabackup: Generating a list of tablespaces 151106 15:39:35 [01] Copying ./ibdata1 to /backup/xtrabackup//2015-11-06_15-39-34/ibdata1 151106 15:39:36 >> log scanned up to (732817942) 151106 15:39:37 >> log scanned up to (732817942) 151106 15:39:38 [01]        ...done 151106 15:39:38 [01] Copying ./t/city.ibd to /backup/xtrabackup//2015-11-06_15-39-34/t/city.ibd 151106 15:39:38 [01]        ...done 151106 15:39:38 [01] Copying ./t/t.ibd to /backup/xtrabackup//2015-11-06_15-39-34/t/t.ibd 151106 15:39:38 [01]        ...done 151106 15:39:38 >> log scanned up to (732817942)
Executing FLUSH NO_WRITE_TO_BINLOG TABLES...
151106 15:39:38 Executing FLUSH TABLES WITH READ LOCK...
151106 15:39:38 Starting to backup non-InnoDB tables and files 151106 15:39:38 [01] Skipping ./mysql/slave_master_info.ibd.
151106 15:39:38 [01] Skipping ./mysql/columns_priv.frm. [... ...] 151106 15:39:38 [01] Skipping ./aazj/model_buyers_credit.ibd.
151106 15:39:38 [01] Skipping ./aazj/Users.frm.
151106 15:39:38 [01] Skipping ./aazj/model_recruiting_program.ibd.
151106 15:39:38 [01] Skipping ./aazj/model_model.ibd.
151106 15:39:38 [01] Skipping ./aazj/Customer.frm.
151106 15:39:38 [01] Skipping ./performance_schema/events_waits_summary_by_host_by_event_name.frm. [... ...] 151106 15:39:38 [01] Skipping ./performance_schema/events_statements_summary_by_account_by_event_name.frm.
151106 15:39:38 [01] Copying ./t/city.frm to /backup/xtrabackup//2015-11-06_15-39-34/t/city.frm 151106 15:39:38 [01]        ...done 151106 15:39:38 [01] Copying ./t/db.opt to /backup/xtrabackup//2015-11-06_15-39-34/t/db.opt 151106 15:39:38 [01]        ...done 151106 15:39:38 [01] Copying ./t/t.frm to /backup/xtrabackup//2015-11-06_15-39-34/t/t.frm 151106 15:39:38 [01]        ...done 151106 15:39:38 Finished backing up non-InnoDB tables and files 151106 15:39:38 [00] Writing xtrabackup_binlog_info 151106 15:39:38 [00]        ...done 151106 15:39:38 Executing FLUSH NO_WRITE_TO_BINLOG ENGINE LOGS... xtrabackup: The latest check point (for incremental): '732817942' xtrabackup: Stopping log copying thread.
.151106 15:39:38 >> log scanned up to (732817942) 151106 15:39:39 Executing UNLOCK TABLES 151106 15:39:39 All tables unlocked 151106 15:39:39 Backup created in directory '/backup/xtrabackup//2015-11-06_15-39-34' MySQL binlog position: filename 'mysql-bin.000001', position '120'
151106 15:39:39 [00] Writing backup-my.cnf 151106 15:39:39 [00]        ...done 151106 15:39:39 [00] Writing xtrabackup_info 151106 15:39:39 [00]        ...done
xtrabackup: Transaction log of lsn (732817942) to (732817942) was copied.
151106 15:39:39 completed OK!

View Code

数据库 t 中只有两个表：city, t 都被备份了。

下面我们来看如何还原：

**4.1 部分prepare:**

[[root@localhost](mailto:root@localhost) xtrabackup]#**innobackupex --apply-log --export /backup/xtrabackup/2015-11-06_15-39-34/ --user=bkpuser --password=digdeep**

![](https://images.cnblogs.com/OutliningIndicators/ContractedBlock.gif)
![](https://images.cnblogs.com/OutliningIndicators/ExpandedBlockStart.gif)

[root@localhost xtrabackup]# innobackupex --apply-log --export /backup/xtrabackup/2015-11-06_15-39-34/ --user=bkpuser --password=digdeep
151106 15:49:43 innobackupex: Starting the apply-log operation

IMPORTANT: Please check that the apply-log run completes successfully. At the end of a successful apply-log run innobackupex
           prints "completed OK!". innobackupex version 2.3.2 based on MySQL server 5.6.24 Linux (i686) (revision id: 306a2e0)
xtrabackup: auto-enabling --innodb-file-per-table due to the --export option
xtrabackup: cd to /backup/xtrabackup/2015-11-06_15-39-34/ xtrabackup: This target seems to be not prepared yet. xtrabackup: xtrabackup_logfile detected: size=2097152, start_lsn=(732817942)
xtrabackup: using the following InnoDB configuration for recovery: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:10M:autoextend
xtrabackup:   innodb_log_group_home_dir = ./ xtrabackup:   innodb_log_files_in_group = 1 xtrabackup:   innodb_log_file_size = 2097152 xtrabackup: using the following InnoDB configuration for recovery: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:10M:autoextend
xtrabackup:   innodb_log_group_home_dir = ./ xtrabackup:   innodb_log_files_in_group = 1 xtrabackup:   innodb_log_file_size = 2097152 xtrabackup: Starting InnoDB instance for recovery. xtrabackup: Using 104857600 bytes for buffer pool (set by --use-memory parameter)
InnoDB: Using atomics to ref count buffer pool pages
InnoDB: The InnoDB memory heap is disabled
InnoDB: Mutexes and rw_locks use GCC atomic builtins
InnoDB: Memory barrier is not used
InnoDB: Compressed tables use zlib 1.2.3 InnoDB: Not using CPU crc32 instructions
InnoDB: Initializing buffer pool, size = 100.0M
InnoDB: Completed initialization of buffer pool
InnoDB: Highest supported file format is Barracuda. InnoDB: The log sequence numbers 732817430 and 732817430 in ibdata files do not match the log sequence number 732817942 in the ib_logfiles! InnoDB: Database was not shutdown normally! InnoDB: Starting crash recovery. InnoDB: Reading tablespace information from the .ibd files... InnoDB: Restoring possible half-written data pages
InnoDB: from the doublewrite buffer... InnoDB: Table aazj/Accounting_journal in the InnoDB data dictionary has tablespace id 117, but tablespace with that id or name does not exi  st. Have you deleted or moved .ibd files? This may also be a table created with CREATE TEMPORARY TABLE whose .ibd and .frm files MySQL auto  matically removed, but the table still exists in the InnoDB internal data dictionary. InnoDB: It will be removed from the data dictionary. InnoDB: Please refer to
InnoDB: http://dev.mysql.com/doc/refman/5.6/en/innodb-troubleshooting-datadict.html
InnoDB: for how to resolve the issue. [... ...]
InnoDB: Table mysql/slave_relay_log_info in the InnoDB data dictionary has tablespace id 3, but tablespace with that id or name does not ex  ist. Have you deleted or moved .ibd files? This may also be a table created with CREATE TEMPORARY TABLE whose .ibd and .frm files MySQL aut  omatically removed, but the table still exists in the InnoDB internal data dictionary. InnoDB: It will be removed from the data dictionary. InnoDB: Please refer to
InnoDB: http://dev.mysql.com/doc/refman/5.6/en/innodb-troubleshooting-datadict.html
InnoDB: for how to resolve the issue. InnoDB: Table mysql/slave_worker_info in the InnoDB data dictionary has tablespace id 5, but tablespace with that id or name does not exist  . Have you deleted or moved .ibd files? This may also be a table created with CREATE TEMPORARY TABLE whose .ibd and .frm files MySQL automa  tically removed, but the table still exists in the InnoDB internal data dictionary. InnoDB: It will be removed from the data dictionary. InnoDB: Please refer to
InnoDB: http://dev.mysql.com/doc/refman/5.6/en/innodb-troubleshooting-datadict.html
InnoDB: for how to resolve the issue. InnoDB: 128 rollback segment(s) are active. InnoDB: Waiting for purge to start
InnoDB: 5.6.24 started; log sequence number 732817942 xtrabackup: export option is specified. xtrabackup: export metadata of table 't/city' to file `./t/city.exp` (2 indexes)
xtrabackup:     name=PRIMARY, id.low=267, page=3 xtrabackup:     name=PK_CITY, id.low=268, page=4 xtrabackup: export metadata of table 't/t' to file `./t/t.exp` (1 indexes)
xtrabackup:     name=GEN_CLUST_INDEX, id.low=131, page=3 xtrabackup: Last MySQL binlog file position 254400, file name mysql-bin.000001 xtrabackup: starting shutdown with innodb_fast_shutdown = 0 InnoDB: FTS optimize thread exiting. InnoDB: Starting shutdown... InnoDB: Shutdown completed; log sequence number 732957307 xtrabackup: using the following InnoDB configuration for recovery: xtrabackup:   innodb_data_home_dir = ./ xtrabackup:   innodb_data_file_path = ibdata1:10M:autoextend
xtrabackup:   innodb_log_group_home_dir = ./ xtrabackup:   innodb_log_files_in_group = 2 xtrabackup:   innodb_log_file_size = 50331648 InnoDB: Using atomics to ref count buffer pool pages
InnoDB: The InnoDB memory heap is disabled
InnoDB: Mutexes and rw_locks use GCC atomic builtins
InnoDB: Memory barrier is not used
InnoDB: Compressed tables use zlib 1.2.3 InnoDB: Not using CPU crc32 instructions
InnoDB: Initializing buffer pool, size = 100.0M
InnoDB: Completed initialization of buffer pool
InnoDB: Setting log file ./ib_logfile101 size to 48 MB
InnoDB: Setting log file ./ib_logfile1 size to 48 MB
InnoDB: Renaming log file ./ib_logfile101 to ./ib_logfile0
InnoDB: New log files created, LSN=732957307 InnoDB: Highest supported file format is Barracuda. InnoDB: 128 rollback segment(s) are active. InnoDB: Waiting for purge to start
InnoDB: 5.6.24 started; log sequence number 732957708 xtrabackup: starting shutdown with innodb_fast_shutdown = 0 InnoDB: FTS optimize thread exiting. InnoDB: Starting shutdown... InnoDB: Shutdown completed; log sequence number 732957718
151106 15:49:49 completed OK!

View Code

**4.2 下面我们将其 import 到一个新的数据库中：** 

([root@localhost](mailto:root@localhost))[t]mysql>create database partial;

([root@localhost](mailto:root@localhost))[t]mysql>use partial;

Database changed

([root@localhost](mailto:root@localhost))[partial]mysql>create table city like t.city;

([root@localhost](mailto:root@localhost))[partial]mysql>**alter table partial.city discard tablespace;**

然后将 city.exp 和 city.ibd 拷贝到 /var/lib/mysql/partial/ 目录下，并修改权限：

[[root@localhost](mailto:root@localhost) t]# cp city.exp city.ibd /var/lib/mysql/partial/

[[root@localhost](mailto:root@localhost) partial]# chown -R mysql:mysql /var/lib/mysql

然后 

([root@localhost](mailto:root@localhost))[aazj]mysql>**alter table partial.city import tablespace;**

Query OK, 0 rows affected, 1 warning (0.11 sec)

([root@localhost](mailto:root@localhost))[aazj]mysql>select count(*) from partial.city;

+----------+

| count(*) |

+----------+

|     3285 |

+----------+

1 row in set (0.01 sec)

可以看到import 成功了。部分恢复成功。

低于t表也同样操作就行了。

([root@localhost](mailto:root@localhost))[partial]mysql>select count(*) from t;

+----------+

| count(*) |

+----------+

|       11 |

+----------+

1 row in set (0.00 sec)

可以看到，这种部分备份/恢复，操作起来比较麻烦，步骤比较多，还需要一个表一个表的处理。对少数表处理还可以，如果很多表，就不方面了。

**4.3 部分备份恢复之备份/恢复一个或者多个数据库：** 

1）备份：

[root@localhost mysql]# innobackupex **--database="aazj t mysql information_schema performance_schema"** /backup/xtrabackup/partial/ --user=pkpuser --password=digdeep

注意这里 --database = "aazj t mysql performance_schema" 表示指定备份的数据库；还可以增加其他数据库，但是必须使用引号。  

2）恢复 prepare：

[root@localhost partial]# innobackupex --apply-log /backup/xtrabackup/partial/2015-11-11_15-22-56 --user=bkpuser --password=digdeep

然后 关闭 mysqld, 清空 datadir :

[root@localhost mysql]# pwd  
/var/lib/mysql

[root@localhost mysql]# rm -rf *

3）copy-back:

[root@localhost partial]# innobackupex --copy-back /backup/xtrabackup/partial/2015-11-11_15-22-56 --user=bkpuser --password=digdeep

然后修改权限：chown -R mysql:mysql /var/lib/mysql

然后启动mysqld，发现数据库 t 被恢复出来了。这里也可以一次备份多个数据库，但是一定要带上 mysql 数据库，不然恢复出来时，没有了数据字典，select读不出数据：

**Restoring Partial Backups：** 

**Restoring should be done by restoring individual tables in the partial backup to the server.  
It can also be done by copying back the prepared backup to a clean datadir (in that case, make sure to include the mysql database). System database can be created with: $ sudo mysql_install_db --user=mysql (摘自xtrabackup文档)**

部分恢复一般需要 export, 然后 import. 比较麻烦，但是我们也可以在一个空的 datadir 目录直接 --copy-back，这样的话，那么在备份的时候一定要带上mysql数据库，当然最好带上所有的系统数据库，不然的话，需要使用命令：mysql_install_db --user=mysql --basedir=... 重建那些系统数据库。这就是为什么在部分备份时带上了：mysql performance_schema(information_schema是系统视图，不需要带上，当然带上也是可以的)

4）如果你不想带上 performance_schema(mysql是一定要带上的)，那么就必须使用： mysql_install_db --user=mysql --basedir=/usr/local/mysql 来重新生成系统数据库mysql 和 performance_schema。那么此时在 --copy-back之前，必须先删除刚才生成的 和 我们要 --copy-back 重复的文件：

[root@localhost mysql]# rm ibdata1 ib_logfile0 ib_logfile1

[root@localhost mysql]# rm -rf mysql

另外 --copy-back 时要带上参数： **--force-non-empty-directories**

innobackupex **--copy-back --force-non-empty-directories** /backup/xtrabackup/partial/2015-11-11_16-17-11/ --user=pkpuser --password=digdeep

因为 datadir 目录非空，所以需要带上该参数：

 --force-non-empty-directories  
                      This option, when specified, makes --copy-back or  
                      --move-back transfer files to non-empty directories. Note  
                      that no existing files will be overwritten. If  
                      --copy-back or --nove-back has to copy a file from the  
                      backup directory which already exists in the destination  
                      directory, it will still fail with an error.  
即使带上了该参数，如果还存在重名的文件，还是会报错，需要先删除datadir中的重名文件。  

**5. point-in-time 恢复**

利用全备、增量备份最多只能恢复到全备完成时的那一刻，或者增量备份完成时的那一刻的数据。备份之后产生的数据，我们需要结合binlog，来恢复。我们可以从binlog中获得innobackupex最后一次备份完成时的position，它之后的所有的sql，应用完，这些sql，就能将数据库恢复到最新的状态，或者我们想要的某个时间的状态。

1> 先来一个全备：

[[root@localhost](mailto:root@localhost) xtrabackup]# innobackupex /backup/xtrabackup/full --user=bkpuser --password=digdeep

2> 再来一个增量：

将t表数据删除一行：delete from t where i=11;

[[root@localhost](mailto:root@localhost) xtrabackup]# innobackupex --incremental /backup/xtrabackup/incr1/ --incremental-basedir=/backup/xtrabackup/full/2015-11-06_16-26-08 --user=bkpuser --password=digdeep

3> 再来一个增量：

将t表数据删除一行：delete from t where i=10;

[[root@localhost](mailto:root@localhost) xtrabackup]# innobackupex --incremental /backup/xtrabackup/incr2/ --incremental-basedir=/backup/xtrabackup/incr1/2015-11-06_16-31-13/ --user=bkpuser --password=digdeep

4> 备份完成之后，我们再来操作 t 表：

([root@localhost](mailto:root@localhost))[t]mysql>delete from t where i>3;

此时的状态：

([root@localhost](mailto:root@localhost))[t]mysql>show binary logs;

+------------------+-----------+

| Log_name         | File_size |

+------------------+-----------+

| mysql-bin.000001 |       927 |

| mysql-bin.000002 |       688 |

+------------------+-----------+

2 rows in set (0.00 sec)

([root@localhost](mailto:root@localhost))[t]mysql>show master status;

+------------------+----------+--------------+------------------+-------------------+

 | File                       | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |

+------------------+----------+--------------+------------------+-------------------+

| mysql-bin.000002 |      688 |              |                  |                   |

+------------------+----------+--------------+------------------+-------------------+

1 row in set (0.00 sec)

假设此时数据库表数据所在的磁盘发生故障，但是 binlog 文件是好的。那么此时，我们就可以使用上面的全备、增量备份、还有binlog文件一起来将数据库恢复到磁盘发生故障那一刻的最新状态来。

5> 首先从全备、增量备份得到最后一次备份完成时的数据：

1）应用全备的redo log:

[[root@localhost](mailto:root@localhost) xtrabackup]# innobackupex --apply-log --redo-only /backup/xtrabackup/full/2015-11-06_16-26-08 --user=bkpuser --password=digdeep

2）应用第一次增量备份的redo log:

[[root@localhost](mailto:root@localhost) xtrabackup]# innobackupex --apply-log --redo-only /backup/xtrabackup/full/2015-11-06_16-26-08 --incremental-dir=/backup/xtr  abackup/incr1/2015-11-06_16-31-13/ --user=bkpuser --password=digdeep

3）应用第二次增量备份的 redo log，并且仅限回滚(去掉 --redo-only选项)：

[[root@localhost](mailto:root@localhost) xtrabackup]# innobackupex --apply-log /backup/xtrabackup/full/2015-11-06_16-26-08 --incremental-dir=/backup/xtrabackup/incr2/2015-11-06_16-33-57/ --user=bkpuser --password=digdeep

此时已经恢复到了最后一次备份完成时的状态了。

我们看一下最后一次增量备份时的 xtrabackup_binlog_info 文件信息：

[[root@localhost](mailto:root@localhost) xtrabackup]# cat incr2/2015-11-06_16-33-57/xtrabackup_binlog_info

mysql-bin.000002        482

可以看到对应的binlog postion为：mysql-bin.000002        482

而崩溃那一刻的binlog postion为： mysql-bin.000002      688

所以我们需要应用 mysql-bin.000002 文件的 482 到 688之间的sql：

4）先 --copy-back

[[root@localhost](mailto:root@localhost) mysql]# innobackupex --copy-back /backup/xtrabackup/full/2015-11-06_16-26-08 --user=bkpuser --password=digdeep

修改权限：

[[root@localhost](mailto:root@localhost) ~]# chown -R mysql:mysql /var/lib/mysql

启动msyqld:  mysqld_safe --user=mysql &

然后验证，t 表的数据，应该有i<10 & i>3 的数据：

([root@localhost](mailto:root@localhost))[t]mysql>select * from t;

+------+

| i    |

+------+

|    1 |

|    2 |

|    3 |

|    4 |

|    5 |

|    6 |

|    7 |

|    8 |

|    9 |

+------+

9 rows in set (0.00 sec)

如我们所期待的结果一样。说明到此时，前面的操作完全是正确的。

5）应用 mysql-bin.000002 文件的 482 到 688之间的sql

[[root@localhost](mailto:root@localhost) mysql]#  **mysqlbinlog /backup/xtrabackup/mysql-bin.000002 --start-position=482 > bin.sql**

([root@localhost](mailto:root@localhost))[(none)]mysql>source /var/lib/mysql/bin.sql

然后在查看 t 表数据：

([root@localhost](mailto:root@localhost))[t]mysql>select * from t;

+------+

| i    |

+------+

|    1 |

|    2 |

|    3 |

+------+

3 rows in set (0.00 sec)

一切完美完成，数据库被我们回复到了最新的状态。

**6. innobackupex 选项优化/最佳实践**

**6.1 优化FTWRL锁：** 

在备份非innodb数据库时，会使用：flush tables with read lock 全局锁锁住整个数据库。如果数据库中有一个长查询在运行，那么FTWRL就不能获得，会被阻塞，进而阻塞所有的DML操作。此时即使我们kill掉FTWRL全局锁也是无法从阻塞中恢复出来的。另外在我们成功的获得了FTWRL全局锁之后，在copy非事务因为的文件的过程中，整个数据库也是被锁住的。所以我们应该让FTWRL的过程尽量的短。(在copy非事务引擎数据的文件时，会阻塞innodb事务引擎。当然也会阻塞所有其他非事务引擎。)

1> 防止阻塞：

innobackupex 提供了多个选项来避免发生阻塞：

  --ftwrl-wait-timeout=# 替换 --lock-wait-timeout

                      This option specifies time in seconds that innobackupex

                      should wait for queries that would block FTWRL before

                      running it. If there are still such queries when the

                      timeout expires, innobackupex terminates with an error.

                      Default is 0, in which case innobackupex does not wait

                      for queries to complete and starts FTWRL immediately.

  --ftwrl-wait-threshold=# 替换 --lock-wait-threshold

                      This option specifies the query run time threshold which

                      is used by innobackupex to detect long-running queries

                      with a non-zero value of --ftwrl-wait-timeout. FTWRL is

                      not started until such long-running queries exist. This

                      option has no effect if --ftwrl-wait-timeout is 0.

                      Default value is 60 seconds.

--lock-wait-timeout=60 该选项表示：我们在FTWRL时，如果有长查询，那么我们可以最多等待60S的时间，如果60秒之内长查询执行完了，我们就可以成功执行FTWRL了，如果60秒之内没有执行完，那么就直接报错退出，放弃。默认值为0

--lock-wait-threshold=10 该选项表示运行了多久的时间的sql当做长查询；对于长查询最多再等待 --lock-wait-timeout 秒。

--kill-long-queries-timeout=10 该选项表示发出FTWRL之后，再等待多时秒，如果还有长查询，那么就将其kill掉。默认为0，not to kill.

--kill-long-query-type={all|select} 该选项表示我们仅仅kill select语句，还是kill所有其他的类型的长sql语句。

这几个选项，我们没有必要都是有，一般仅仅使用 --lock-wait-timeout=60 就行了。

注意 --lock-* 和 --kill-* 选项的不同，一个是等待多时秒再来执行FTWRL，如果还是不能成功执行就报错退出；一个是已经执行了FTWRL，超时就进行kill。

2> 缩短FTWRL全局锁的时间：

--rsync 使用该选项来缩短备份非事务引擎表的锁定时间，如果需要备份的数据库和表数量很多时，可以加快速度。

--rsync           Uses the rsync utility to optimize local file transfers.

                      When this option is specified, innobackupex uses rsync to

                      copy all non-InnoDB files instead of spawning a separate

                      cp for each file, which can be much faster for servers

                      with a large number of databases or tables.  This option

                      cannot be used together with --stream.

3> 并行优化：

  --parallel=# 在备份阶段，压缩/解压阶段，加密/解密阶段，--apply-log，--copy-back 阶段都可以并行       

                      On backup, this option specifies the number of threads

                      the xtrabackup child process should use to back up files

                      concurrently.  The option accepts an integer argument. It

                      is passed directly to xtrabackup's --parallel option. See

                      the xtrabackup documentation for details.

4> 内存优化：

  --use-memory=# 在crash recovery 阶段，也就是 --apply-log 阶段使用该选项

                      This option accepts a string argument that specifies the

                      amount of memory in bytes for xtrabackup to use for crash

                      recovery while preparing a backup. Multiples are

                      supported providing the unit (e.g. 1MB, 1GB). It is used

                      only with the option --apply-log. It is passed directly

                      to xtrabackup's --use-memory option. See the xtrabackup

                      documentation for details.

3> 备份slave:

--safe-slave-backup 

                      Stop slave SQL thread and wait to start backup until

                      Slave_open_temp_tables in "SHOW STATUS" is zero. If there

                      are no open temporary tables, the backup will take place,

                      otherwise the SQL thread will be started and stopped

                      until there are no open temporary tables. The backup will

                      fail if Slave_open_temp_tables does not become zero after

                      --safe-slave-backup-timeout seconds. The slave SQL thread

                      will be restarted when the backup finishes.

--safe-slave-backup-timeout=#

                      How many seconds --safe-slave-backup should wait for

                      Slave_open_temp_tables to become zero. (default 300)

--slave-info   This option is useful when backing up a replication slave

                      server. It prints the binary log position and name of the

                      master server. It also writes this information to the

                      "xtrabackup_slave_info" file as a "CHANGE MASTER"

                      command. A new slave for this master can be set up by

                      starting a slave server on this backup and issuing a

                      "CHANGE MASTER" command with the binary log position

                      saved in the "xtrabackup_slave_info" file.
```

### 7. 备份原理 

1）innobackupex 是perl写的脚本，它调用xtrabackup来备份innodb数据库。而xtrabackup是C语言写的程序，它调用了innodb的函数库和mysql客户端的函数库。innodb函数库提供了向数据文件应用的redo log的功能，而mysql客户端函数库提供了解析命令行参数的功能。innobackupex备份innodb数据库的功能，都是通过调用 xtrabackup --backup和xtrabackup --prepare来完成的。我们没有必要直接使用xtrabackup来备份，通过innobackupex更方便。xtrabakup 通过跳转到datadir目录，然后通过两个线程来完成备份过程：

1> log-copy thread: 备份开始时，该后台线程一直监控redo log(每秒check一次redo log)，将redo log的修改复制到备份之后的文件 **xtrabackup_logfile** 中。如果redo log生成极快时，有可能log-copy线程跟不上redo log的产生速度，那么在redo log文件切换进行覆盖时，xtrabakcup会报错。

2> data-file-copy thread:前后有一个复制data file的线程，注意这里并不是简单的复制，而是调用了innodb函数库，像innodb数据库那样打开数据文件，进行读取，然后每次复制一个page，然后对page进行验证，如果验证错误，会最多重复十次。

当数据文件复制完成时，xtrabackup 停止log-copy 线程，并建立一个文件 **xtrabackup_checkpoints**记录备份的类型，开始时的lsn和结束时的lsn等信息。

而备份生成的 **xtrabackup_binlog_info** 文件则含义备份完成时对应的binlog的position信息，类似于：mysql-bin.000002        120

在备份开始时记录下LSN，然后一个线程复制数据文件，一个线程监控redo log，复制在备份过程中新产生的redo log。虽然我们的到的数据文件显然不是一致性的，但是利用innodb的crash-recovery功能，应用备份过程中产生的redo log文件，就能得到备份完成时那一刻对应的一致性的数据。

注意复制数据文件分成了两个过程：

一个是复制innodb事务引擎的数据文件，是不需要持有锁的；另一个是复制非事务引擎的数据文件和table的定义文件.frm，复制这些文件时，是需要先通过FTWRL，然后在进行复制的，所以会导致整个数据库被阻塞。

增量备份时，是通过对表进行全扫描，比较LSN，如果该page的LSN大于上一次别分时的LSN，那么就将该page复制到table_name.ibd.delta文件中。回复时.delta会和redo log应用到全备是的数据文件中。

增量备份在恢复时，除了最后一次增量备份文件之外，其它的增量备份在应用时，只能前滚，不能执行回滚操作，因为没有提交的事务，可能在下一个增量备份中进行了提交，如果你在上一个增量备份时回滚了，那么下一个增量备份应用时，显然就报错了，因为他无法提交事务，该事务以及被回滚了。

**8. 总结：** 

1）权限：

备份需要两个层面的权限，Linux层面的权限，mysql层面的权限。

2）全备和恢复

**全备：** innobackupex  /backup/xtrabackup/full --user=bkpuser --password=digdeep

**应用日志进行prepare:** innobackupex --apply-log /backup/xtrabackup/full/2015-11-05_22-38-55/ --user=bkpuser --password=digdeep 

关闭mysqld:

**copy-back:** innobackupex --copy-back /backup/xtrabackup/full/2015-11-05_22-38-55/ --user=bkpuser --password=digdeep 

修改权限：chown -R mysql:mysql /var/lib/mysql

3）增量备份和恢复：

**全备：** 

innobackupex --user=bkpuser --password=digdeep /backup/xtrabackup/full

**第一次增量备份：** 

innobackupex --incremental /backup/xtrabackup/incr1/ --incremental-basedir=/backup/xtrabackup/full/2015-11-06_11-29-51/ 

--user=bkpuser --password=digdeep 

**第二次增量备份：** 

innobackupex --incremental /backup/xtrabackup/incr2 --incremental-basedir=/backup/xtrabackup/incr1/2015-11-06_11-33-16/ 

--user=bkpuser --password=digdeep

**恢复：** 

**应用全备redo log:**

innobackupex --apply-log --redo-only /backup/xtrabackup/full/2015-11-06_11-29-51/ --user=bkpuser --password=digdeep

**应用第一次增量备份的redo log:**

innobackupex --apply-log --redo-only /backup/xtrabackup/full/2015-11-06_11-29-51/ --incremental-dir=/backup/xtrabackup/incr1/2015-11-06_11-33-16/ 

--user=bkpuser --password=digdeep

**应用第二次(最后一次)增量备份的redo log:**

innobackupex --apply-log /backup/xtrabackup/full/2015-11-06_11-29-51/ --incremental-dir=/backup/xtrabackup/incr2/2015-11-06_11-43-22/ 

--user=bkpuser --password=digdeep

关闭mysqld,

innobackupex --copy-back /backup/xtrabackup/full/2015-11-06_11-29-51/ --user=bkpuser --password=digdeep

4）部分备份 

innobackupex --databases t /backup/xtrabackup/ --user=bkpuser --password=digdeep

innobackupex --apply-log --export /backup/xtrabackup/2015-11-06_15-39-34/ --user=bkpuser --password=digdeep

新建表结构：create table city like t.city;

alter table partial.city discard tablespace;

然后将 city.exp 和 city.ibd 拷贝到 /var/lib/mysql/partial/ 目录下，并修改权限：chown -R mysql:mysql /var/lib/mysql

alter table partial.city import tablespace;

5）point-in-time 恢复

在--copy-back之后，引用binlog文件

mysqlbinlog /backup/xtrabackup/mysql-bin.000002 --start-position=482 > bin.sql

([root@localhost](mailto:root@localhost))[(none)]mysql>source bin.sql

6） innobackupex 选项优化/最佳实践

--ftwrl-wait-timeout=60 防止发生阻塞

--rsync 减少FTWRL时间 缩短备份非事务引擎表的锁定时间

--parallel=4  开并行

--use-memory=4G crash recovery 期间使用的内存

