# DBT3 自动化脚本

[runebook.dev](https://runebook.dev/zh/docs/mariadb/dbt3-automation-scripts/index)

DBT-3 (OSDL Database Test 3) 是 OSDL (Open Source Development Labs, inc) 基于事务性能处理委员会 (TPC). 提供的 TPC-H 开发的 Linux 内核工作负载工具

DBT-3, 与 TPC-H, 一样，模拟实际的决策支持系统，并对执行数据处理作业以做出更好的业务决策的复杂业务分析应用程序进行建模。通过运行DBT-3模拟的工作负载，可以在实际的决策支持系统中验证和测量Linux内核的性能。

DBT-3 使用“比例因子 (SF)"”作为系统的压力指示器。通过改变 SF,，可以使数据库的大小等于 SF 乘以其大小。

DBT-3 执行的测试包括下列三项测试。DBT-3获取这三个测试的执行时间以及系统状态信息和数据库统计信息。

1.  **Load test**
    *   将用于功率和吞吐量测试的数据输入到数据库中。将与比例因子对应的巨大 CSV 数据批量插入数据库中。

1.  **Power test**
    *   执行 22 个复杂查询。

1.  **Throughput test**
    *   在多个进程中同时执行与 Power 测试中相同的 22 个查询。

出于此任务的目的，仅在具有各种比例因子的初步准备的数据库上执行功率测试。每个查询执行的时间将被测量并存储到数据库中。稍后，所有 22 个查询的整个测试的结果将呈现为直方图图形，并将其与不同的配置进行比较。

## 基准环境准备

### sudo rights

将运行基准测试的用户必须在计算机上拥有 sudo 权限。

为了在查询运行之间清除系统缓存，自动化脚本使用以下命令：

sudo /sbin/sysctl vm.drop\_caches=3 

该命令必须以超级用户权限运行。即使用户向 sudo 提供密码，该密码也会在一段时间后过期。为了使该命令无需密码即可运行，应将以下行添加到 sudoers 文件中（使用 `"sudo visudo"` command): 进行编辑）

'your\_username' ALL\=NOPASSWD:/sbin/sysctl 

...where `'your_username'` 是将运行基准测试的用户。

### Required software

自动 DBT3 基准测试需要以下软件：

*   **[Perl](http://www.perl.org/)**
    *   **Project home:**[http://www.perl.org/](http://www.perl.org/)

*   **[mariadb-tools](https://launchpad.net/mariadb-tools)**
    *   **Project home:**[https://launchpad.net/mariadb-tools](https://launchpad.net/mariadb-tools)
    *   该项目文件夹名为“ `dbt3_benchmark` ”，位于 `mariadb-tools` 下。

*   **[dbt3-1.9](http://sourceforge.net/projects/osdldbt/files/dbt3/)**
    *   **Download location:**[http://sourceforge.net/projects/osdldbt/files/dbt3/](http://sourceforge.net/projects/osdldbt/files/dbt3/)

*   [Gnuplot 4.4](http://www.gnuplot.info/) — 图形输出程序。
    *   **Project home:**[http://www.gnuplot.info/](http://www.gnuplot.info/)

*   [Config::Auto](http://search.cpan.org/~simon/Config-Auto-0.03/Auto.pm) — 读取配置文件的 Perl 模块。要安装它，请使用以下命令：
    
    sudo cpan Config::Auto 
    

*   [DBD::mysql](http://search.cpan.org/~capttofu/DBD-mysql-4.020/lib/DBD/mysql.pm) — 连接到 MariaDB/MySQL 和 PostgreSQL. 的 Perl 模块 要安装它，请使用以下命令：
    
    sudo cpan DBD::mysql 
    

NOTE: 您可能会收到一条错误消息，指出 CPAN 找不到 `mysql_config` 。在这种情况下你必须安装mysql客户端开发library。在 OpenSuse 中，命令为：

sudo zypper install libmysqlclient-devel 

或者，可以按照以下步骤手动安装此模块：

1.  从 [http://search.cpan.org/~capttofu/DBD-mysql-4.020/lib/DBD/mysql.pm](http://search.cpan.org/~capttofu/DBD-mysql-4.020/lib/DBD/mysql.pm) 下载 DBD-mysql-4.020.tar.gz 并解压

1.  在解压目录下运行 perl 脚本 PerlMake.pl：
    
    perl Makefile.PL --mysql\_config=/path/to/some/mysql\_binary\_distribution/bin/mysql\_config 
    

1.  运行 `make` 编译 `DBD::mysql` ：
    
    make 
    

1.  添加必要的路径以运行 `DBD::mysql` ：
    
    export PERL5LIB="/path/to/unzipped\_DBD\_mysql/DBD-mysql-4.020/lib" export LD\_LIBRARY\_PATH="/path/to/unzipped\_DBD\_mysql/DBD-mysql-4.020/blib/arch/auto/DBD/mysql/:/path/to/some/mysql\_binary\_distribution/lib/" 
    

### Tested DBMS

*   **[MySQL 5.5.x](http://dev.mysql.com/downloads/mysql/#downloads)**
    *   下载位置： [http://dev.mysql.com/downloads/mysql/#downloads](http://dev.mysql.com/downloads/mysql/#downloads) → 普遍可用的 (GA) 版本 → Linux - 通用 2.6（x86、64-bit), 压缩 TAR 存档 - 下载 mysql-5.5.x-linux2.6-x86\_64.tar.gz - 适用于 Linux x86 的 gzipped tar 文件

*   **[MySQL 5.6.x](http://dev.mysql.com/downloads/mysql/#downloads)**
    *   下载位置： [http://dev.mysql.com/downloads/mysql/#downloads](http://dev.mysql.com/downloads/mysql/#downloads) → 开发版本 → Linux - Generic 2.6（x86、64-bit), 压缩 TAR 存档 - 下载 mysql-5.6.x-m5-linux2.6-x86\_64.tar.gz - Linux x86 的 gzipped tar 文件

*   **[MariaDB 5.3.x](https://launchpad.net/maria/5.3)**
    *   下载位置： [https://launchpad.net/maria/5.3](https://launchpad.net/maria/5.3) ，用Bazaar下载：
        
        bzr branch lp:maria/5.3 
        

*   **[MariaDB 5.5.x](https://launchpad.net/maria/5.3)**
    *   下载位置： [https://launchpad.net/maria/5.5](https://launchpad.net/maria/5.5) ，用Bazaar下载：
        
        bzr branch lp:maria/5.5 
        

*   **[PostgreSQL](http://www.postgresql.org/ftp/source/v9.1rc1/)**
    *   **Download location:**[http://www.postgresql.org/ftp/source/v9.1rc1/](http://www.postgresql.org/ftp/source/v9.1rc1/)

NOTE: DBT3 基准测试需要大量磁盘空间（例如，比例因子为 30 的 MySQL 5.5.x + MyISAM 数据库大约需要 50 GB). 另外，某些查询需要利用传递给 `mysqld` 的 `--tmpdir` 启动参数设置的目录下的临时表。准备好的配置文件中，临时目录指向二进制发行版的 `mysql` 系统目录，但应该确保临时目录有足够的可用空间。

## Installation instructions

NOTE: 将下载或安装所有文件的目录将称为 `$PROJECT_HOME` 。例如，这可以是 `~/benchmark/dbt3` 。

### Download **[mariadb-tools](https://launchpad.net/mariadb-tools)**

1.  Go 到您的项目文件夹
    
    cd $PROJECT\_HOME 
    
2.  通过 Bazaar 获取 LaunchPad 的最新分支：
    
    bzr branch lp:mariadb-tools 
    

现在 dbt3 基准测试的项目将位于以下目录中：

$PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/ 

项目 `dbt3_benchmark` 具有以下目录和文件：

*   config—存放MariaDB, MySQL和PostgreSQL配置文件的文件夹。它们分为名为“ `sXX` ”的子文件夹，其中 `XX` 是比例因子。
*   dbt3\_mysql — 包含准备 DBT3 数据库以及 MySQL 和 MariaDB 测试查询所需的所有文件的文件夹
*   测试 - 存储不同测试配置的文件夹。它包含以下目录：
    *   db\_conf—这里存储数据库配置文件
    *   queries\_conf—这里存储不同的查询配置文件
    *   results\_db\_conf—这里存储结果数据库的配置
    *   test\_conf—这是测试配置
    *   launcher.pl — 一个自动执行测试的 perl 脚本。有关此文件的调用和功能的详细信息将在本页后面列出。

### 准备基准工作负载和查询

为了进行 [DBT3-1.9](http://sourceforge.net/projects/osdldbt/files/dbt3/) 基准测试，我们只需要 DBGEN 和 QGEN。DBGEN 是生成测试工作负载的工具，QGEN 是生成用于测试的查询的工具。

1.  Go 至 [http://sourceforge.net/projects/osdldbt/files/dbt3/](http://sourceforge.net/projects/osdldbt/files/dbt3/)

1.  将 DBT3 1.9 的存档下载到项目文件夹 $PROJECT\_HOME 中

1.  将存档解压到您的项目文件夹中
    
    cd $PROJECT\_HOME tar -zxf dbt3-1.9.tar.gz 
    

1.  将文件 tpcd.h 复制到 dbt3 文件夹中。此步骤包括构建查询时 MySQL/MariaDB 所需的标签。
    
    cp $PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/dbt3\_mysql/tpcd.h $PROJECT\_HOME/dbt3-1.9/src/dbgen/ 
    

1.  将 `$PROJECT_HOME/mariadb-tools/dbt3_benchmark/dbt3_mysql/` 下的文件Makefile复制到dbt3文件夹中

*   NOTE: 仅当您想要覆盖 PostgreSQL 设置的默认行为时才执行此步骤。复制此 Makefile 并构建项目后，QGEN 将被设置为生成 MariaDB/MySQL. 的查询。如果跳过此步骤，QGEN 将默认生成 PostgreSQL 的查询。
    
    cp $PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/dbt3\_mysql/Makefile $PROJECT\_HOME/dbt3-1.9/src/dbgen/ 
    

1.  Go 至 $PROJECT\_HOME/dbt3-1.9/src/dbgen 并构建项目
    
    cd $PROJECT\_HOME/dbt3-1.9/src/dbgen make 
    

1.  将变量 DSS\_QUERY 设置为包含 MariaDB/MySQL 或 PostgreSQL 模板查询的文件夹
    1.  如果要构建适合 MariaDB/MySQL 方言的查询，请执行以下命令：
        
        export DSS\_QUERY=$PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/dbt3\_mysql/mysql\_queries/ 
        
    2.  如果要使用默认的 PostgreSQL 模板，请执行以下命令：
        
        export DSS\_QUERY=$PROJECT\_HOME/dbt3-1.9/queries/pgsql/ 
        

1.  创建一个目录来存储生成的查询
    
    mkdir $PROJECT\_HOME/gen\_query 
    

1.  生成查询

NOTE: 示例使用比例因子 30。如果需要不同的比例，请更改 `-s` 参数的值

*   cd $PROJECT\_HOME/dbt3-1.9/src/dbgen ./qgen -s 30 1 > $PROJECT\_HOME/gen\_query/s30-m/1.sql ./qgen -s 30 2 > $PROJECT\_HOME/gen\_query/s30-m/2.sql ./qgen -s 30 3 > $PROJECT\_HOME/gen\_query/s30-m/3.sql ./qgen -s 30 4 > $PROJECT\_HOME/gen\_query/s30-m/4.sql ./qgen -s 30 5 > $PROJECT\_HOME/gen\_query/s30-m/5.sql ./qgen -s 30 6 > $PROJECT\_HOME/gen\_query/s30-m/6.sql ./qgen -s 30 7 > $PROJECT\_HOME/gen\_query/s30-m/7.sql ./qgen -s 30 8 > $PROJECT\_HOME/gen\_query/s30-m/8.sql ./qgen -s 30 9 > $PROJECT\_HOME/gen\_query/s30-m/9.sql ./qgen -s 30 10 > $PROJECT\_HOME/gen\_query/s30-m/10.sql ./qgen -s 30 11 > $PROJECT\_HOME/gen\_query/s30-m/11.sql ./qgen -s 30 12 > $PROJECT\_HOME/gen\_query/s30-m/12.sql ./qgen -s 30 13 > $PROJECT\_HOME/gen\_query/s30-m/13.sql ./qgen -s 30 14 > $PROJECT\_HOME/gen\_query/s30-m/14.sql ./qgen -s 30 15 > $PROJECT\_HOME/gen\_query/s30-m/15.sql ./qgen -s 30 16 > $PROJECT\_HOME/gen\_query/s30-m/16.sql ./qgen -s 30 17 > $PROJECT\_HOME/gen\_query/s30-m/17.sql ./qgen -s 30 18 > $PROJECT\_HOME/gen\_query/s30-m/18.sql ./qgen -s 30 19 > $PROJECT\_HOME/gen\_query/s30-m/19.sql ./qgen -s 30 20 > $PROJECT\_HOME/gen\_query/s30-m/20.sql ./qgen -s 30 21 > $PROJECT\_HOME/gen\_query/s30-m/21.sql ./qgen -s 30 22 > $PROJECT\_HOME/gen\_query/s30-m/22.sql 
    

1.  生成解释查询
    
    ./qgen -s 30 -x 1 > $PROJECT\_HOME/gen\_query/s30-m/1\_explain.sql ./qgen -s 30 -x 2 > $PROJECT\_HOME/gen\_query/s30-m/2\_explain.sql ./qgen -s 30 -x 3 > $PROJECT\_HOME/gen\_query/s30-m/3\_explain.sql ./qgen -s 30 -x 4 > $PROJECT\_HOME/gen\_query/s30-m/4\_explain.sql ./qgen -s 30 -x 5 > $PROJECT\_HOME/gen\_query/s30-m/5\_explain.sql ./qgen -s 30 -x 6 > $PROJECT\_HOME/gen\_query/s30-m/6\_explain.sql ./qgen -s 30 -x 7 > $PROJECT\_HOME/gen\_query/s30-m/7\_explain.sql ./qgen -s 30 -x 8 > $PROJECT\_HOME/gen\_query/s30-m/8\_explain.sql ./qgen -s 30 -x 9 > $PROJECT\_HOME/gen\_query/s30-m/9\_explain.sql ./qgen -s 30 -x 10 > $PROJECT\_HOME/gen\_query/s30-m/10\_explain.sql ./qgen -s 30 -x 11 > $PROJECT\_HOME/gen\_query/s30-m/11\_explain.sql ./qgen -s 30 -x 12 > $PROJECT\_HOME/gen\_query/s30-m/12\_explain.sql ./qgen -s 30 -x 13 > $PROJECT\_HOME/gen\_query/s30-m/13\_explain.sql ./qgen -s 30 -x 14 > $PROJECT\_HOME/gen\_query/s30-m/14\_explain.sql ./qgen -s 30 -x 15 > $PROJECT\_HOME/gen\_query/s30-m/15\_explain.sql ./qgen -s 30 -x 16 > $PROJECT\_HOME/gen\_query/s30-m/16\_explain.sql ./qgen -s 30 -x 17 > $PROJECT\_HOME/gen\_query/s30-m/17\_explain.sql ./qgen -s 30 -x 18 > $PROJECT\_HOME/gen\_query/s30-m/18\_explain.sql ./qgen -s 30 -x 19 > $PROJECT\_HOME/gen\_query/s30-m/19\_explain.sql ./qgen -s 30 -x 20 > $PROJECT\_HOME/gen\_query/s30-m/20\_explain.sql ./qgen -s 30 -x 21 > $PROJECT\_HOME/gen\_query/s30-m/21\_explain.sql ./qgen -s 30 -x 22 > $PROJECT\_HOME/gen\_query/s30-m/22\_explain.sql 
    

现在，为 MariaDB/MySQL 测试生成的查询已准备就绪，并存储到文件夹 `$PROJECT_HOME/gen_query/s30-m/` 中（-m 表示 MariaDB/MySQL）。

目录的额外重组由用户决定。

1.  为生成的工作负载创建目录
    
    mkdir $PROJECT\_HOME/gen\_data/s30 
    

1.  将变量 DSS\_PATH 设置为包含生成的表数据的文件夹。测试的生成工作负载将在那里生成。
    
    export DSS\_PATH=$PROJECT\_HOME/gen\_data/s30/ 
    

1.  生成表数据

*   NOTE: 该示例使用比例因子 = `30` 。如果你想改变它，你应该改变参数 `-s` 。
    
    ./dbgen -vfF -s 30 
    

*   现在生成的数据加载存储到 `$DSS_PATH = $PROJECT_HOME/gen_data/` 中设置的文件夹中

出于本基准测试的目的，这些步骤已针对比例因子 30 执行，并存储在 facebook-maria1 的以下位置：

*   `/benchmark/dbt3/gen_data/s30` — 比例因子 30 的数据负载
*   `/benchmark/dbt3/gen_query/s30-m` — 为 MariaDB/MySQL 生成的查询，比例因子为 30
*   `/benchmark/dbt3/gen_query/s30-p` — 为比例因子为 30 的 PostgreSQL 生成查询

请参阅 [DBT3 example preparation time](https://runebook.dev/zh/docs/mariadb/dbt3-example-preparation-time/index) 以了解准备测试数据库需要多长时间。

### 下载 [MySQL 5.5.x](http://dev.mysql.com/downloads/mysql/#downloads)

1.  例如，将 tar.gz 文件下载到项目文件夹 `$PROJECT_HOME/bin/` 中

1.  使用以下命令解压缩存档：
    
    gunzip < mysql-5.5.x-linux2.6-x86\_64.tar.gz |tar xf - 
    

现在可以使用以下命令启动服务器：

$PROJECT\_HOME/bin/mysql-5.5.x-linux2.6-x86\_64/bin/mysqld\_safe --datadir=some/data/dir & 

### 下载 [MySQL 5.6.x](http://dev.mysql.com/downloads/mysql/#downloads)

1.  例如，将 tar.gz 文件下载到项目文件夹 `$PROJECT_HOME/bin/` 中

1.  使用以下命令解压缩存档：
    
    gunzip < mysql-5.6.x-m5-linux2.6-x86\_64.tar.gz |tar xf - 
    

现在可以使用以下命令启动服务器：

$PROJECT\_HOME/bin/mysql-5.6.x-m5-linux2.6-x86\_64/bin/mysqld\_safe --datadir=some/data/dir & 

### 下载并构建 [MariaDB 5.3](https://runebook.dev/zh/docs/mariadb/what-is-mariadb-53/index) .x / [MariaDB 5.5](https://runebook.dev/zh/docs/mariadb/what-is-mariadb-55/index) .x

NOTE: 这些步骤与 [MariaDB 5.5](https://runebook.dev/zh/docs/mariadb/what-is-mariadb-55/index) .x 相同，并正确替换了版本号

1.  使用 Bazaar 下载 [mariadb 5.3](https://runebook.dev/zh/docs/mariadb/what-is-mariadb-53/index) 项目
    
    bzr branch lp:maria/5.3 mv 5.3/ mariadb-5.3 
    

1.  Build MariaDB
    
    cd mariadb-5.3/ ./BUILD/compile-amd64-max 
    

1.  构建二进制发行版 tar.gz 文件
    
    ./scripts/make\_binary\_distribution 
    

1.  移动生成的 tar.gz 文件并将其解压缩到 $PROJECT\_HOME/bin，自动化脚本将在其中使用该文件
    
    mv mariadb-5.3.x-beta-linux-x86\_64.tar.gz $PROJECT\_HOME/bin/ cd $PROJECT\_HOME/bin/ tar -xf mariadb-5.3.x-beta-linux-x86\_64.tar.gz 
    

现在可以使用以下命令启动服务器：

$PROJECT\_HOME/bin/mariadb-5.3.x-beta-linux-x86\_64/bin/mysqld\_safe --datadir=some/data/dir & 

### 为基准准备数据库

NOTE: 这些说明与 MariaDB, MySQL 5.5.x 和 MySQL 5.6.x 相同，仅更改数据库主文件夹，此处标记为 $DB\_HOME（例如，对于 MySQL 5.5.x $DB\_HOME 为 `$PROJECT_HOME/bin/mysql-5.5.x-linux2.6-x86_64` ）。您还可以准备InnoDB存储引擎测试数据库。有关准备 PostgreSQL 的说明，请参阅本页后面的下载、构建和准备 PostgreSQL 部分。

1.  打开文件 `$PROJECT_HOME/mariadb-tools/dbt3_benchmark/dbt3_mysql/make-dbt3-db_innodb.sql` 并编辑调用 sql 命令的值，如下所示：
    
    LOAD DATA INFILE '/some/path/to/gen\_data/nation.tbl' into table nation fields terminated by '|'; 
    

*   它们看起来都一样，但使用不同的表进行操作。

*   将 "/some/path/to/gen\_data/" 替换为存储生成的数据负载的正确目录。最后，相同的命令可能如下所示：
    
    LOAD DATA INFILE '~/benchmark/dbt3/gen\_data/s30/nation.tbl' into table nation fields terminated by '|'; 
    

1.  在将用于基准测试的文件夹中创建一个空的 MySQL 数据库
    
    cd $DB\_HOME ./scripts/mysql\_install\_db --defaults-file=$PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/config/s30/load\_mysql\_myisam\_my.cnf --basedir=$DB\_HOME --datadir=$PROJECT\_HOME/db\_data/myisam-s30/ 
    

*   NOTE: 对于 InnoDB，将默认文件更改为 `load_mysql_innodb_my.cnf` 。

1.  启动mysqld进程 `./bin/mysqld_safe --defaults-file=$PROJECT_HOME/mariadb-tools/dbt3_benchmark/config/s30/load_mysql_myisam_my.cnf --tmpdir=$PROJECT_HOME/temp/ --socket=$PROJECT_HOME/temp/mysql.sock --datadir=$PROJECT_HOME/db_data/myisam-s30/ &`

*   NOTE: 对于 InnoDB，将默认文件更改为 `load_mysql_innodb_my.cnf` 。还要确保参数 `--tmpdir` 设置的目录中有足够的空间，因为加载数据库可能会占用大量临时空间。

1.  通过执行文件 `make-dbt3-db_pre_create_PK.sql` （对于 InnoDB) 或 `make-dbt3-db_post_create_PK.sql` （对于 MyISAM) `./bin/mysql -u root -S $PROJECT_HOME/temp/mysql.sock < $PROJECT_HOME/mariadb-tools/dbt3_benchmark/dbt3_mysql/make-dbt3-db_post_create_PK.sql`

*   NOTE: 为了加快创建速度，建议使用 `make-dbt3-db_pre_create_PK.sql` 加载InnoDB，使用 `make-dbt3-db_post_create_PK.sql` 加载MyISAM数据库。

1.  关闭数据库服务器：
    
    ./bin/mysqladmin --user=root --socket=$PROJECT\_HOME/temp/mysql.sock shutdown 0 
    

现在你有一个加载了scale 30的数据库。它的datadir是 `$PROJECT_HOME/db_data/myisam-s30/`

对于不同的比例因子和不同的存储引擎，可以重复相同的步骤。

### 下载、构建并准备 [PostgreSQL](http://www.postgresql.org/ftp/source/v9.1rc1/)

1.  Go 至 [http://www.postgresql.org/ftp/source/v9.1rc1/](http://www.postgresql.org/ftp/source/v9.1rc1/)

1.  下载链接 postgresql-9.1rc1.tar.gz 下的文件

1.  将存档解压到您的项目文件夹
    
    gunzip < postgresql-9.1rc1.tar.gz |tar xf - 
    

1.  在 shell 中执行以下命令来安装 PostgreSQL:
    
    mkdir $PROJECT\_HOME/PostgreSQL\_bin cd $PROJECT\_HOME/postgresql-9.1rc1 ./configure --prefix=$PROJECT\_HOME/bin/PostgreSQL\_bin make make install 
    

*   NOTE: 配置脚本可能找不到以下 libraries：readline 和 zlib。在这种情况下，您可以通过在命令行中添加以下参数来运行没有这些 libraries 的配置： `--without-readline --without-zlib`

1.  准备数据库进行测试：
    
    mkdir $PROJECT\_HOME/db\_data/postgre\_s30 cd $PROJECT\_HOME/bin/PostgreSQL\_bin ./bin/initdb -D $PROJECT\_HOME/db\_data/postgre\_s30 
    

1.  启动服务器：
    
    ./bin/postgres -D $PROJECT\_HOME/db\_data/postgre\_s30 -p 54322 & 
    

1.  将数据加载到数据库中
    
    ./bin/createdb -O {YOUR\_USERNAME} dbt3 -p 54322 ./bin/psql -p 54322 -d dbt3 -f $PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/dbt3\_mysql/make-dbt3-db\_pg.sql 
    

*   NOTE: 您应该在 `{YOUR_USERNAME}` 下放置数据库所有者。

1.  停止服务器：

./bin/pg\_ctl -D $PROJECT\_HOME/db\_data/postgre\_s30/ -p 54322 stop 

已经为 MariaDB, MySQL 和 PostgreSQL. 准备了在 facebook-maria1 上进行基准测试的工作负载的步骤。以下是在 facebook-maria1 上准备的不同 DBMS, 存储引擎和比例因子的目录：

*   `~/benchmark/dbt3/db_data/myisam_s30` — MariaDB/MySQL + MyISAM 的数据目录，比例因子为 30

*   `~/benchmark/dbt3/db_data/innodb_mariadb_s30` — MariaDB + InnoDB 的数据目录，比例因子为 30 (TODO)

*   `~/benchmark/dbt3/db_data/innodb_mysql_s30` — MySQL + InnoDB 的数据目录，比例因子为 30 (TODO)

*   `~/benchmark/dbt3/db_data/postgre_s30` — PostgreSQL 的数据目录，比例因子为 30 (TODO)

### 准备结果数据库

基准测试的结果将存储在由 [MariaDB 5.3](https://runebook.dev/zh/docs/mariadb/what-is-mariadb-53/index) .x 运行的单独数据库中。

NOTE: 在 DBT3 基准测试项目的未来版本中，结果数据库可能会发生变化。

该数据库由文件 `$PROJECT_HOME/mariadb-tools/dbt3_benchmark/dbt3_mysql/make-results-db.sql` 创建。在该文件中，您可以找到有关数据库中每个表和列的详细信息。

要准备数据库以供工作，请按照下列步骤操作：

1.  Go 到 [MariaDB 5.3](https://runebook.dev/zh/docs/mariadb/what-is-mariadb-53/index) .x 安装目录
    
    cd $PROJECT\_HOME/bin/mariadb-5.3.x-beta-linux-x86\_64 
    

1.  将系统数据库表安装到数据目录中以获取结果（例如 `$PROJECT_HOME/db_data/dbt3_results_db` ）
    
    ./scripts/mysql\_install\_db --datadir=$PROJECT\_HOME/db\_data/dbt3\_results\_db 
    

1.  启动 mysqld 以获取结果数据库
    
    ./bin/mysqld\_safe --defaults-file=$PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/config/results\_mariadb\_my.cnf --port=12340 --socket=$PROJECT\_HOME/temp/mysql\_results.sock --datadir=$PROJECT\_HOME/db\_data/dbt3\_results\_db/ & 
    

1.  安装数据库
    
    ./bin/mysql -u root -P 12340 -S $PROJECT\_HOME/temp/mysql\_results.sock < $PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/dbt3\_mysql/make-results-db.sql 
    

1.  关闭结果数据库服务器：
    
    ./bin/mysqladmin --user=root --port=12340 --socket=$PROJECT\_HOME/temp/mysql\_results.sock shutdown 0 
    

## Automation script

### 配置并运行基准测试

为了运行基准测试，人们应该：

*   5个配置文件：
    1.  DBMS 服务器配置（请参阅 #dbms-server-configuration ）
    2.  测试配置（参见 #test-configuration ）
    3.  查询配置（参见 #queries-configuration ）
    4.  结果数据库配置（请参阅 #results-database-configuration ）
    5.  结合了上述所有内容的顶级配置文件（请参阅 #top-level-configuration ）
*   可以在 `mariadb-tools/dbt3_benchmark/` 下找到的自动化脚本 `launcher.pl`
*   应传递给自动化脚本的启动参数（请参阅 #script-startup-parameters ）。

以下各节给出了有关其中每一项的详细信息。

每个基准测试都是由一组配置文件配置的。您可以在 'mariadb-tools/dbt3\_benchmark/tests'. 目录下找到示例（默认）配置文件 每个配置文件都有一个“ini”配置语法，并由带有 CPAN 模块 [Config::Auto](http://search.cpan.org/~simon/Config-Auto-0.03/Auto.pm) 的 perl 自动化脚本进行解析

#### Configuration keywords

每个配置文件都可以包含关键字，这些关键字将被脚本替换为特定值。当您想让配置文件在为基准测试准备的环境中更通用时，可以使用它们以方便使用。这些关键词是：

*   `$PROJECT_HOME` — 用作项目‘ `mariadb-tools` ’所在的目录或作为整个项目的基本路径 (e.g. " `DBMS_HOME = $PROJECT_HOME/bin/mariadb-5.3.x-beta-linux-x86_64` "). 被传递给 launcher.pl, 的启动参数 'project-home' 设置的值替换

*   `$DATADIR_HOME` — 用作基准 (e.g. 的 datadir 文件夹所在目录“ `$DATADIR_HOME/myisam-s30` "). 它被传递给 launcher.pl. 的启动参数“datadir-home”设置的值替换

*   `$QUERIES_HOME` — 用作查询所在的目录 (e.g. " `$QUERIES_HOME/s30-m` " — 查询 MariaDB/MySQL 的比例因子 30). 它被传递给 launcher.pl. 的启动参数“queries-home”设置的值替换

*   `$SCALE_FACTOR` — 将使用的比例因子。它通常是 datadir 目录 (e.g. " `$DATADIR_HOME/myisam-s$SCALE_FACTOR` "), 查询目录 (e.g. " `$QUERIES_HOME/s$SCALE_FACTOR-m` ") 或数据库配置目录 (e.g. `$PROJECT_HOME/mariadb-tools/dbt3_benchmark/config/s$SCALE_FACTOR` ) 名称的一部分。它被替换为通过启动参数 'scale-factor' 设置的值至 launcher.pl.

请注意，如果任何配置文件包含此类关键字，则传递给 launcher.pl 的相应启动参数将成为必需的。

#### Top-level configuration

顶级配置文件提供测试、DBMS, 查询和结果数据库配置文件的路径

目录 `mariadb-tools/dbt3_benchmark/tests/` 中有默认配置文件，包含以下设置：

Parameter

Description

`RESULTS_DB_CONFIG`

结果数据库设置的配置文件

`TEST_CONFIG`

测试设置的配置文件

`QUERIES_CONFIG`

查询设置的配置文件

`DB_CONFIG`

DBMS服务器设置的配置文件

该文件具有以下格式：

\[common\] RESULTS\_DB\_CONFIG = $PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/tests/results\_db\_conf/results\_db.conf TEST\_CONFIG = $PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/tests/test\_conf/test\_myisam.conf \[mariadb\_5\_3\] QUERIES\_CONFIG = $PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/tests/queries\_conf/queries.conf DB\_CONFIG = $PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/tests/db\_conf/db\_mariadb\_5\_3\_myisam.conf \[mysql\_5\_5\] QUERIES\_CONFIG = $PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/tests/queries\_conf/queries\_mysql.conf DB\_CONFIG = $PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/tests/db\_conf/db\_mysql\_5\_5\_myisam.conf ... 

NOTE: 设置 `RESULTS_DB_CONFIG` 和 `TEST_CONFIG` 应在 `[common]` 部分下设置。它们在整个测试中很常见（尽管 `TEST_CONFIG` 中的某些设置可能会在 `QUERIES_CONFIG` file). 中被覆盖。所有结合 `QUERIES_CONFIG` 和 `DB_CONFIG` 的设置应位于单独的部分 (e.g. `[mariadb_5_3]` 中）。

测试配置作为输入参数传递到带有参数 `--test=/path/to/some_test_configuration.conf` 的自动化脚本（请参阅 #script-startup-parameters ）

#### DBMS服务器配置

这些配置文件包含描述基准 DBMS. 的设置，它们通常包含在文件夹 `mariadb-tools/dbt3_benchmark/tests/db_conf` 中。

以下是可以设置到此配置文件中的参数列表：

Parameter

Description

`DBMS_HOME`

MariaDB / MySQL / PostgreSQL的安装文件夹所在位置。

NOTE: 自动化脚本使用“ `./bin/mysqld_safe` ”启动 `mysqld` 进程。所以MariaDB和MySQL的版本应该是“二进制发行版”的版本。

`DBMS_USER`

将使用的数据库用户。

`CONFIG_FILE`

mysqld 或 postgres 启动时将使用的配置文件

`SOCKET`

将用于启动服务器的套接字

`PORT`

服务器将启动的端口

`HOST`

服务器所在主机

`DATADIR`

mysqld 或 postgres 的 datadir 所在位置

`TMPDIR`

排序和分组时将在其中创建临时表。

`DBNAME`

基准表所在的数据库（架构）名称。

`KEYWORD`

该文本将作为关键字存储到结果数据库中。还将用作包含结果和统计信息的子文件夹的名称。

`DBMS`

将使用的数据库管理系统。可能的值："MySQL", "MariaDB" 和 "PostgreSQL"

`STORAGE_ENGINE`

使用的存储引擎 (MyISAM, InnoDB, etc.)

`STARTUP_PARAMS`

启动 mysqld 进程或 postgres 进程时将使用的任何启动参数。与命令行上给出的格式相同。

`GRAPH_HEADING`

该特定测试的图形标题。

`MYSQL_SYSTEM_DIR`

请参阅下面的“ `MYSQL_SYSTEM_DIR` 注释”。

`READ_ONLY`

如果设置为 1，mysqld 进程将以“ `--read-only` ”启动参数启动

`PRE_RUN_SQL`

每次查询运行之前运行的 SQL 命令

`POST_RUN_SQL`

SQL 每次查询运行后运行的命令

`PRE_TEST_SQL`

SQL 使用该数据库设置在整个测试之前运行的命令

`POST_TEST_SQL`

使用该数据库设置进行整个测试后运行的 SQL 命令

**`MYSQL_SYSTEM_DIR` note:**

当您想要节省时间和磁盘空间来为不同的 DBMS（和不同版本）生成数据库并为所有这些数据库使用单个数据目录时，添加此选项是为了方便。当在单个数据目录上运行不同版本的 MariaDB/MySQL 时，应运行 [mysql-upgrade](http://dev.mysql.com/doc/refman/5.5/en/mysql-upgrade.html) 以修复系统表。因此，在一个数据目录中，您可以为不同的MariaDB/MySQL系统目录准备以下目录：

*   `mysql_mysql_5_5` — 由 MySQL 5.5.x 升级的系统目录“ `mysql` ”的副本
*   `mysql_mariadb_5_3` — 由 [MariaDB 5.3](https://runebook.dev/zh/docs/mariadb/what-is-mariadb-53/index) .x 升级的系统目录“ `mysql` ”的副本
*   `mysql_mariadb_5_5` — 由 [MariaDB 5.5](https://runebook.dev/zh/docs/mariadb/what-is-mariadb-55/index) .x 升级的系统目录“ `mysql` ”的副本

如果 `MYSQL_SYSTEM_DIR` 设置为这些目录之一，自动化脚本将取消当前系统目录“mysql”的链接，并使用该名称与设置中的目录创建一个新的符号链接。

下面是将要执行的命令示例：-

unlink /path/to/datadir/mysql ln -s /path/to/value/in/MYSQL\_SYSTEM\_DIR/mysql\_mariadb\_5\_3 /path/to/datadir/mysql 

-
NOTE: 此方法适用于 MyISAM 测试。

配置文件如下所示：

\[db\_settings\] DBMS\_HOME = $PROJECT\_HOME/bin/mariadb-5.3.2-beta-linux-x86\_64 DBMS\_USER = root ... 

请注意， `[db_settings]` 部分是自动化脚本正确解析文件所必需的。

#### Test configuration

这些配置文件包含描述测试的设置。它们通常包含在文件夹 mariadb-tools/dbt3\_benchmark/tests/test\_conf 中。

以下是可以设置到此配置文件中的参数列表：

Parameter

Description

`QUERIES_AT_ONCE`

如果设置为 `1` ，则所有查询将按顺序执行，无需重新启动服务器或清除查询之间的缓存。

`CLEAR_CACHES`

如果设置为 `1` ，则在每次查询测试之前都会清除磁盘缓存。

`WARMUP`

在运行查询之前执行预热运行。

`EXPLAIN`

在运行查询之前运行解释命令。解释结果将存储在结果输出目录下的文件中。

`RUN`

进行实际测试

`ANALYZE_EXPLAIN`

一种结果提取机制，仅测量最佳执行计划（ `EXPLAIN` select 的结果）。它设计用于对 InnoDB 存储引擎进行基准测试，其中执行计划在服务器重新启动之间发生变化（请参阅 #results-extraction-mechanisms ）。

`MIN_MAX_OUT_OF_N`

结果提取机制，其中 `N` （由参数 `NUM_TESTS` 设置）测试中的最小值和最大值作为结果。这可以在测试 InnoDB 存储引擎时使用（请参阅 #results-extraction-mechanisms ）。

`SIMPLE_AVERAGE`

一种结果提取机制，其中最终结果是测试所花费的平均时间。每个查询的测试数量由 NUM\_TESTS 参数设置。请注意，即使一项测试超时，结果也是“超时”。这在测试 MyISAM 存储引擎时使用，因为执行计划是恒定的（请参阅 #results-extraction-mechanisms ）。

`NUM_TESTS`

每个查询应执行多少次测试。当 ANALYZE\_EXPLAIN 设置时，该值可以设置为 0，这意味着测试将继续，直到提取足够的结果（请参阅设置 `CLUSTER_SIZE` ）。当选择 `MIN_MAX_OUT_OF_N` 或 `SIMPLE_AVERAGE` 时，该参数非常重要。

`MAX_SKIPPED_TESTS`

当设置 ANALYZE\_EXPLAIN 并选择较慢的执行计划时，将跳过查询的执行并重新启动服务器以更改执行计划。如果服务器重新启动次数超过 `MAX_SKIPPED_TESTS` ，则显然不再有不同的执行计划，并且脚本将继续执行下一个查询基准。

`WARMUPS_COUNT`

在实际基准测试运行之前将执行多少次预热运行。

`CLUSTER_SIZE`

为了提取最终结果，包含查询结果的集群应该有多大。当选择 `ANALYZE_EXPLAIN` 作为结果提取方法时使用。

`MAX_QUERY_TIME`

测试一个查询的最长时间。目前仅在选择 `ANALYZE_EXPLAIN` 时适用。

`TIMEOUT`

一个查询可以运行的最长时间。目前超时仅适用于 MySQL 和 MariaDB.

`OS_STATS_INTERVAL`

提取 CPU, 内存等操作系统统计信息之间的时间间隔是多少？

`PRE_RUN_OS`

每次查询运行之前应执行的操作系统命令

`POST_RUN_OS`

每次查询运行后应执行的操作系统命令

`PRE_TEST_OS`

整个测试之前应执行的操作系统命令

`POST_TEST_OS`

整个测试完成后应执行的操作系统命令

配置文件如下所示：

QUERIES\_AT\_ONCE = 0 CLEAR\_CACHES = 1 WARMUP = 0 ... 

#### Queries configuration

这些配置文件包含将针对每个数据库进行基准测试的所有查询的列表。 `DBMS server configuration` 和 `Test configuration` 中的某些设置可以覆盖到 `Queries configuration` 文件中。包含此类配置的文件夹是 `mariadb-tools/dbt3_benchmark/tests/queries_conf` 。

以下是可以设置到此配置文件中的参数列表：

Parameter

Description

`QUERIES_HOME`

查询位于磁盘上的位置。该值与 `QUERY` 设置连接，形成特定查询的路径。NOTE: 此设置应在 `[queries_settings]` 部分下设置。

`CONFIG_FILE`

这将覆盖 DMBS 服务器配置文件中的启动设置 `CONFIG_FILE` 并设置所使用的数据库配置文件。如果应为此特定查询配置文件设置一些没有任何优化的配置文件，则可以使用它。

NOTE: 该设置应在 `[queries_settings]` 部分下设置。

`QUERY`

查询的名称位于 `QUERIES_HOME` 文件夹中。例如"1.sql"

`EXPLAIN_QUERY`

`QUERIES_HOME` 文件夹中解释查询的名称。例如"1\_explain.sql"

`TMPDIR`

这会覆盖 `DMBS server` 配置中的设置 TMPDIR。

`STARTUP_PARAMS`

这会覆盖 `DMBS server` 配置中的设置 `STARTUP_PARAMS` 。使用此设置可以更改数据库服务器的特定启动参数（例如优化和缓冲区）。

`PRE_RUN_SQL`

这会覆盖 DMBS 服务器配置中的设置 `PRE_RUN_SQL` 。

`POST_RUN_SQL`

这会覆盖 DMBS 服务器配置中的设置 `POST_RUN_SQL` 。

`RUN`

这会覆盖测试配置中的设置 `RUN` 。

`EXPLAIN`

这会覆盖测试配置中的设置 `EXPLAIN` 。

`TIMEOUT`

这会覆盖测试配置中的设置 `TIMEOUT` 。

`NUM_TESTS`

这会覆盖测试配置中的设置 `NUM_TESTS` 。

`MAX_SKIPPED_TESTS`

这会覆盖测试配置中的设置 `MAX_SKIPPED_TESTS` 。

`WARMUP`

这会覆盖测试配置中的设置 `WARMUP` 。

`WARMUPS_COUNT`

这会覆盖测试配置中的设置 `WARMUPS_COUNT` 。

`MAX_QUERY_TIME`

这会覆盖测试配置中的设置 `MAX_QUERY_TIME` 。

`CLUSTER_SIZE`

这会覆盖测试配置中的设置 `CLUSTER_SIZE` 。

`PRE_RUN_OS`

这会覆盖测试配置中的设置 `PRE_RUN_OS` 。

`POST_RUN_OS`

这会覆盖测试配置中的设置 `POST_RUN_OS` 。

`OS_STATS_INTERVAL`

这会覆盖测试配置中的设置 `OS_STATS_INTERVAL` 。

查询配置文件可能如下所示：

\[queries\_settings\] QUERIES\_HOME = /path/to/queries \[query1\] QUERY=1.sql EXPLAIN\_QUERY=1\_explain.sql STARTUP\_PARAMS= \[query2\] QUERY=2.sql EXPLAIN\_QUERY=2\_explain.sql STARTUP\_PARAMS=--optimizer\_switch='mrr=on' --mrr\_buffer\_size=8M --some\_startup\_parmas ... 

例如，...where“ `QUERIES_HOME = /path/to/queries` ”可以替换为“ `QUERIES_HOME = $QUERIES_HOME/s$SCALE_FACTOR-m` ”，因此 `$QUERIES_HOME` 和$SCALE\_FACTOR将被传递给 `launcher.pl` 的脚本启动参数替换（参见 #script-startup-parameters ）

NOTE: 需要 `[queries_settings]` 节才能正确解析配置文件。此外，每个查询设置都应在唯一命名的配置节下设置（(e.g. `[query1]` 或 `[1.sql]` ）

#### 结果数据库配置

这些配置文件包含有关存储结果的数据库的设置。它们通常包含在文件夹 `mariadb-tools/dbt3_benchmark/tests/results_db_conf` 中。

以下是可以设置到此配置文件中的参数列表：

Parameter

Description

`DBMS_HOME`

数据库目录所在的位置。例如“ `$PROJECT_HOME/mariadb-5.3.x-beta-linux-x86_64` ”。这应该是 MariaDB 或 MySQL. 的二进制发行版

`DBMS_USER`

DBMS 将使用的用户

`DATADIR`

结果数据库的数据目录所在的位置

`CONFIG_FILE`

数据库使用的配置文件是什么。

`SOCKET`

结果数据库将使用的套接字。这应该与为测试数据库提供的套接字不同。

`PORT`

结果数据库将使用的端口。这应该与为测试数据库提供的端口不同。

`STARTUP_PARAMS`

启动服务器时应设置的任何启动参数。

`DBNAME`

要使用的数据库名称。

`HOST`

结果数据库所在的主机。

结果数据库配置可能如下所示：

DBMS\_HOME = $PROJECT\_HOME/mariadb-5.3.x-beta-linux-x86\_64 DBMS\_USER = root ... 

#### 脚本启动参数

`launcher.pl` 可以接受以“ `--some-param` ”方式调用的启动参数。请注意，这些启动参数区分大小写。当覆盖某些配置文件中的设置时使用大写字母。

以下是启动参数列表：

Parameter

Description

`test`

将运行的顶级基准测试配置文件。这是必需的启动参数。

`results-output-dir`

基准测试结果的存储位置。时间戳会自动附加到目录名称，以便跟踪基准测试的时间和日期。这是一个必需的参数。

`dry-run`

如果设置，则不会执行基准测试。相反，只会显示有关要执行的操作的消息。

`project-home`

如果任何配置文件使用变量“ `$PROJECT_HOME` ”，则为必需。如果所有配置文件都使用绝对路径，则不使用。

`datadir-home`

此参数中的值将替换配置文件中出现的任何字符串“ `$DATADIR_HOME` ”。如果没有出现这种情况，则它不是必需的参数。

`queries-home`

此参数中的值将替换配置文件中出现的任何字符串“ `$QUERIES_HOME` ”。如果没有出现这种情况，则它不是必需的参数。

`scale-factor`

此参数中的值将替换配置文件中出现的任何字符串“ `$SCALE_FACTOR` ”。如果没有出现这种情况，则它不是必需的参数。

`CLEAR_CACHES`

如果设置的话。这会覆盖测试配置文件中设置的默认设置。

`QUERIES_AT_ONCE`

如果设置的话。这会覆盖测试配置文件中设置的默认设置。

`RUN`

如果设置的话。这会覆盖测试配置文件中设置的默认设置。

`EXPLAIN`

如果设置的话。这会覆盖测试配置文件中设置的默认设置。

`TIMEOUT`

如果设置的话。这会覆盖测试配置文件中设置的默认设置。

`NUM_TESTS`

如果设置的话。这会覆盖测试配置文件中设置的默认设置。

`MAX_SKIPPED_TESTS`

如果设置的话。这会覆盖测试配置文件中设置的默认设置。

`WARMUP`

如果设置的话。这会覆盖测试配置文件中设置的默认设置。

`WARMUPS_COUNT`

如果设置的话。这会覆盖测试配置文件中设置的默认设置。

`MAX_QUERY_TIME`

如果设置的话。这会覆盖测试配置文件中设置的默认设置。

`CLUSTER_SIZE`

如果设置的话。这会覆盖测试配置文件中设置的默认设置。

`PRE_RUN_OS`

如果设置的话。这会覆盖测试配置文件中设置的默认设置。

`POST_RUN_OS`

如果设置的话。这会覆盖测试配置文件中设置的默认设置。

`OS_STATS_INTERVAL`

如果设置的话。这会覆盖测试配置文件中设置的默认设置。

### 结果提取机制

存在三种可能的结果提取机制。它们由测试配置文件中设置的参数设置：

*   `ANALYZE_EXPLAIN`
*   `MIN_MAX_OUT_OF_N`
*   `SIMPLE_AVERAGE`

其中只有一个应设置为 true (1).

`ANALYZE_EXPLAIN` 用于对 InnoDB 存储引擎进行基准测试，其中当服务器重新启动时，同一查询的执行计划可能会发生变化。它旨在仅以最快的执行计划运行查询。这意味着如果证明当前执行计划比另一个执行计划慢，则服务器将重新启动。最终结果是查询计划的结果是最快的，并且对该查询至少进行了 `CLUSTER_SIZE` 测试。通过设置配置参数 `NUM_TESTS` ，您可以设置最大测试运行时间，达到该最大测试运行时间后将获得最佳集群的平均时间（即使它小于 `CLUSTER_SIZE` ）。此外，当达到该查询 ( `MAX_QUERY_TIME` ) 超时时，评分机制将返回最佳可用集群结果。

`MIN_MAX_OUT_OF_N` 还用于对 InnoDB 存储引擎进行基准测试。结果是存储最快和最慢运行的值。假设当执行计划改变时，它有不同的执行计划，我们只对最短和最长时间感兴趣。

`SIMPLE_AVERAGE` 用于对存储引擎进行基准测试，这些引擎不会像 MyISAM. 那样在重新启动之间更改执行计划。最终结果是查询的所有测试运行的平均执行时间。

### Results graphics

每次查询测试运行后，结果都会存储到 `{RESULTS_OUTPUT_DIR}` 中名为 results.dat 的文件中。该文件被设计为易于被绘图程序 Gnuplot 4.4. 读取。它被分为多个块，并由几行新行分隔。每个块都以注释行开头，其中包含当前结果块的详细信息。

已超时的查询的值为 `100000` ，因此它们会耗尽图形并被切断。其他查询的实际时间（以秒为单位）从 `0` 开始。图形在y轴上被切断的时间最长的是 `completed test + 20%` 。例如，如果最长时间为 `100` 秒，则图形将截止到 `120` 秒。因此，超时查询将被此限制截断，并且看起来确实超时。

在测试运行期间，会生成一个gnuplot脚本文件，其中包含自动生成图形所需的参数。每次查询测试运行完成后，都会重新生成图形，以便用户可以在整个基准测试完成之前看到当前结果。该文件名为 `gnuplot_script.txt` ，位于 `{RESULTS_OUTPUT_DIR}` 中。测试完成后，用户可以对其进行编辑以微调参数或标题，以便获得 he/she 想要的最终结果的外观和感觉。

### Script output

#### Benchmark output

在参数{RESULTS\_OUTPUT\_DIR}设置的目录中（例如： `/benchmark/dbt3/results/myisam_test_2011-12-08_191427/` ）有以下files/directories:

*   每个测试的目录，命名为测试配置中的参数 {KEYWORD} （示例： `mariadb-5-3-2` ）
*   cpu\_info.txt— “ `/bin/cat /proc/cpuinfo` ”操作系统命令的输出
*   uname.txt— “ `uname -a` ”操作系统命令的输出
*   results.dat—一个文件中每个查询执行的结果。该文件将用作 gnuplot 脚本的数据文件。它还包含当前测试与第一个测试之间的比率。
*   gnuplot\_script.txt — 渲染图形的 Gnuplot 脚本。
*   graphics.jpeg—输出图形
*   从 `mariadb-tools/dbt3_benchmark/tests/` 复制的基准配置文件（例如： `myisam_test_mariadb_5_3_mysql_5_5_mysql_5_6.conf` ）
*   从 `mariadb-tools/dbt3_benchmark/tests/results_db_conf/` 复制的结果数据库配置文件（示例： `results_db.conf` ）
*   从 `mariadb-tools/dbt3_benchmark/tests/test_conf/` 复制的测试配置文件（例如： `test_myisam.conf` ）

#### Test output

在由参数 {KEYWORD} 设置的特定测试的子目录中（例如： `/benchmark/dbt3/results/myisam_test_2011-12-08_191427/mariadb-5-3-2/` ），有以下文件：

*   pre\_test\_os\_resutls.txt - 在该测试的第一个查询运行之前执行的操作系统命令（如果有）的输出
*   pre\_test\_sql\_resutls.txt - 在该测试的第一个查询运行之前执行的 SQL 命令（如果有）的输出
*   post\_test\_os\_resutls.txt - 在该测试的最后一个查询运行后执行的操作系统命令（如果有）的输出
*   post\_test\_sql\_resutls.txt - 在该测试的最后一个查询运行后执行的 SQL 命令（如果有）的输出
*   all\_explains.txt - 包含所有解释查询、基准测试的启动参数和解释结果的文件
*   传递给 mysqld 或 postgres 的配置文件 (my.cnf) （例如： `mariadb_myisam_my.cnf` ）从 `mariadb-tools/dbt3_benchmark/config/s$SCALE_FACTOR/` 复制
*   查询配置文件（示例：从 `mariadb-tools/dbt3_benchmark/tests/queries_conf/` 复制的 ''queries-mariadb.conf'')
*   数据库配置文件（示例：从 `mariadb-tools/dbt3_benchmark/tests/db_conf/` 复制的 ''db\_mariadb\_5\_3\_myisam.conf'')

#### Query output

对于每个查询执行，自动化脚本都会输出多个文件。它们都保存在参数 `{KEYWORD}` 设置的子目录下：

*   解释结果 - 名为“{query\_name}\_{number\_of\_query\_run}\_results.txt”的文件（例如：“1\_explain.sql\_1\_results.txt”—1\_explain.sql) 的第一次测试
*   预运行操作系统命令 - 在实际查询运行之前执行的操作系统命令。输出是一个名为“pre\_run\_os\_q\_{query\_name}\_no\_{number\_of\_query\_run}\_results.txt”的文件（例如：“pre\_run\_os\_q\_1.sql\_no\_2\_results.txt”——查询 1.sql) 的第二次测试
*   预运行 SQL 命令 - 在实际查询运行之前执行的 SQL 命令。输出是一个名为“pre\_run\_sql\_q\_{query\_name}\_no\_{number\_of\_query\_run}\_results.txt”的文件。
*   运行后操作系统命令 - 实际查询运行后执行的操作系统命令。输出是一个名为“post\_run\_os\_q\_{query\_name}\_no\_{number\_of\_query\_run}\_results.txt”的文件。
*   运行后 SQL 命令 - 在实际查询运行后执行的 SQL 命令。输出是一个名为“post\_run\_sql\_q\_{query\_name}\_no\_{number\_of\_query\_run}\_results.txt”的文件。
*   CPU 利用率统计数据：“{query\_name}\_no\_{number\_of\_query\_run}\_sar\_u.txt”
*   I/O 和传输速率统计：'{query\_name}\_no\_{number\_of\_query\_run}\_sar\_b.txt'
*   内存利用率统计信息：“{query\_name}\_no\_{number\_of\_query\_run}\_sar\_r.txt”

### Hooks

自动化脚本提供了挂钩，允许用户在每次测试之前和之后添加 SQL 和操作系统命令。以下是所有可能的钩子的列表：

*   预测试SQL钩子：用参数 `PRE_TEST_SQL` 设置。包含在首次运行之前针对整个测试配置运行一次的 SQL 命令。(Example:“ `use dbt3; select version(); show variables; show engines; show table status;` ”）
*   测试后 SQL 挂钩：通过参数 `POST_TEST_SQL` 设置。包含上次运行后针对整个测试配置运行一次的 SQL 命令。
*   预测试OS钩子：通过参数 `PRE_TEST_OS` 设置。包含首次运行之前针对整个测试配置运行一次的操作系统命令。
*   测试后操作系统挂钩：通过参数 `POST_TEST_OS` 设置。包含上次运行后针对整个测试配置运行一次的操作系统命令。
*   预运行SQL钩子：通过参数 `PRE_RUN_SQL` 设置。包含在每次查询运行之前运行的 SQL 命令。(Example:“ `flush status; set global userstat=on;` ”）
*   运行后 SQL 钩子：通过参数 `POST_RUN_SQL` 设置。包含每次查询运行后运行的 SQL 命令。(Example:“ `show status; select * from information_schema.TABLE_STATISTICS;` ”）
*   预运行操作系统挂钩：通过参数 `PRE_RUN_OS` 设置。包含每次查询运行之前运行一次的操作系统命令。
*   运行后操作系统挂钩：通过参数 `POST_RUN_OS` 设置。包含每次查询运行后运行一次的操作系统命令。

这些命令的结果存储在 `{RESULTS_OUTPUT_DIR}/{KEYWORD}` 文件夹中（请参阅 #script-output ）

### Activities

以下是该脚本执行的主要活动：

1.  解析配置文件并检查输入参数 - 如果缺少任何必需的参数，脚本将停止并导致错误。
2.  收集硬件信息 - 收集有关运行基准测试的机器的硬件信息。目前收集 `cpuinfo` 和 `uname` 。这些命令的结果存储到设置为输入参数的结果输出目录中
3.  循环遍历已通过的测试配置
    
    对于每个通过的测试配置，脚本执行以下操作：
    
    1.  启动结果数据库服务器。测试结果存储在该数据库中。
    2.  清除服务器上的缓存
        
        清除缓存是通过以下命令完成的：
        
        sudo /sbin/sysctl vm.drop\_caches=3 
        
        *   NOTE: 为了清除缓存，用户需要具有 sudo 权限，并且应将以下行添加到 `sudoers` 文件中（使用“ `sudo vusudo` ”进行编辑 command):
            
            {your\_username} ALL\=NOPASSWD:/sbin/sysctl 
            
    3.  启动数据库服务器
    4.  执行预测试 SQL 命令。结果存储在 `results_output_dir/{KEYWORD}` 文件夹下，称为 `pre_test_sql_results.txt` 。 `{KEYWORD}` 是当前数据库配置的唯一关键字。
    5.  执行预测试操作系统命令。结果存储在 `results_output_dir/{KEYWORD}` 文件夹下，称为 `pre_test_os_results.txt` 。
        *   NOTE: 如果在测试配置中，QUERIES\_AT\_ONCE 设置为 0，则服务器会在每次查询运行之间重新启动。因此，步骤 3.2, 3.3, 3.4 和 3.5 仅在步骤 3.6.2. 之前执行一次
    6.  读取所有查询配置并为每个配置执行以下操作：
        1.  检查测试配置参数。如果某些必需参数有问题，程序将退出并导致错误。
        2.  如果这是第一次运行查询，则获取服务器版本
        3.  在 shell 中执行预运行操作系统命令。这些查询的结果存储在 `results_output_dir/{KEYWORD}` 下名为 `pre_run_os_q_{QUERY}_no_{RUN_NO}_results.txt` 的文件中，其中 `{QUERY}` 是查询名称（例如： `1.sql` ）， `{RUN_NO}` 是顺序运行编号， `{KEYWORD}` 是特定测试配置的唯一关键字。
        4.  执行预运行 SQL 查询。这些查询的结果存储在 `results_output_dir/{KEYWORD}` 下名为 `pre_run_sql_q_{QUERY}_no_{RUN_NO}_results.txt` 的文件中，其中 `{QUERY}` 是查询名称（例如： `1.sql` ）， `{RUN_NO}` 是顺序运行编号， `{KEYWORD}` 是特定测试配置的唯一关键字。
        5.  如果设置到测试配置文件中，则执行预热运行
        6.  进行实际测试运行并测量时间。
            *   在此步骤中，将创建一个新的子进程，以测量 OS. 的统计信息。当前收集的统计信息是：
                *   CPU利用率统计。执行此操作的命令是：
                    
                    sar -u 0 2\>null 
                    
                *   I/O和传输速率统计。执行此操作的命令是：
                    
                    sar -b 0 2\>null 
                    
                *   内存利用率统计。执行此操作的命令是：
                    
                    sar -r 0 2\>null 
                    
            *   这些统计数据每 N 秒测量一次，其中 `N` 使用 `OS_STATS_INTERVAL` 测试配置参数进行设置。
            *   MariaDB和MySQL的测试运行实现了超时时切断的机制。它由 `TIMEOUT` 测试参数控制。目前 PostgreSQL 没有这样的功能，应该在未来的版本中实现。
        7.  执行该查询的“解释”语句。
            *   NOTE: 使用 MySQL 先前版本 5.6.3 运行 `EXPLAIN` 查询可能会导致查询长时间运行，因为当其中存在嵌套选择时，MySQL 必须执行整个查询。对于MariaDB和PostgreSQL则不存在此问题。长时间运行的解释查询适用于查询 #7、8、9、13 和 15。因此，在 MySQL 之前的版本 5.6.3 中，对于这些查询，不应执行 `EXPLAIN` 选择。
        8.  执行运行后 SQL 查询
        9.  在 shell 中执行运行后操作系统命令
        10.  将结果记录到结果数据库中
        11.  使用 Gnuplot 生成具有当前结果的图形
    7.  关闭数据库服务器。
    8.  执行测试后 SQL 命令。结果存储在 `results_output_dir/{KEYWORD}` 文件夹下，称为 `post_test_sql_results.txt` 。
    9.  执行测试后操作系统命令。结果存储在 `results_output_dir/{KEYWORD}` 文件夹下，称为 `post_test_os_results.txt` 。
    10.  停止结果数据库服务器

### 脚本调用示例

*   比例因子 30 和超时 10 分钟的 MyISAM 测试调用示例：
    
    perl launcher.pl \\ --project-home=/path/to/project/home/ \\ --results-output-dir=/path/to/project/home/results/myisam\_test \\ --datadir=/path/to/project/home/db\_data/ \\ --test=/path/to/project/home/mariadb-tools/dbt3\_benchmark/tests/myisam\_test\_mariadb\_5\_3\_mysql\_5\_5\_mysql\_5\_6.conf \\ --queries-home=/path/to/project/home/gen\_query/ \\ --scale-factor=30 \\ --TIMEOUT\=600 
    

...where `/path/to/project/home` 是 `mariadb-tools` 项目所在的位置。这将替换配置文件中所有出现的字符串 "$PROJECT\_HOME"（例如：“ `TMPDIR = $PROJECT_HOME/temp/` ”将变为“ `TMPDIR = /path/to/project/home/temp/` ").

`--TIMEOUT` 将测试配置文件中的超时设置覆盖为 10 分钟。

*   比例因子 30 的 InnoDB 测试示例，每个查询超时 2 小时，每个查询运行 3 次：
    
    perl launcher.pl \\ --project-home=/path/to/project/home/ \\ --results-output-dir=/path/to/project/home/results/innodb\_test \\ --datadir=/path/to/project/home/db\_data/ \\ --test=/path/to/project/home/mariadb-tools/dbt3\_benchmark/tests/innodb\_test\_mariadb\_5\_3\_mysql\_5\_5\_mysql\_5\_6.conf \\ --queries-home=/path/to/project/home/gen\_query/ \\ --scale-factor=30 \\ --TIMEOUT\=7200 \\ --NUM\_TESTS\=3 
    

*   如果有更新版本的 [MariaDB 5.5](https://runebook.dev/zh/docs/mariadb/what-is-mariadb-55/index) 可用：
    *   复制或编辑 DMBS 服务器配置文件 `mariadb-tools/dbt3_benchmark/tests/db_conf/db_mariadb_5_5_myisam.conf` 并将参数 `DBMS_HOME` 更改为新的二进制发行版。您还可以编辑 `KEYWORD` 和 `GRAPH_HEADING`

*   如果您想在 [MariaDB 5.3](https://runebook.dev/zh/docs/mariadb/what-is-mariadb-53/index) 的 MyISAM 基准测试中添加额外的测试，但使用另一个默认文件 (my.cnf):
    *   复制或编辑DMBS服务器配置文件 `mariadb-tools/dbt3_benchmark/tests/db_conf/db_mariadb_5_3_myisam.conf` 并将参数CONFIG\_FILE更改为新的my.cnf
    *   复制或编辑测试配置文件 `mariadb-tools/dbt3_benchmark/tests/myisam_test_mariadb_5_3_mysql_5_5_mysql_5_6.conf` 并添加新的配置设置：
        
        \[mariadb\_5\_3\_new\_configuration\] QUERIES\_CONFIG = $PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/tests/queries\_conf/queries-mariadb.conf DB\_CONFIG = $PROJECT\_HOME/mariadb-tools/dbt3\_benchmark/tests/db\_conf/db\_mariadb\_5\_3\_myisam\_new\_configuration.conf 
        

*   例如，如果要为 MariaDB 的查询 6 添加其他启动参数：
    *   复制或编辑文件 `mariadb-tools/dbt3_benchmark/tests/queries_conf/queries-mariadb.conf` 并添加参数“ `STARTUP_PARAMS=--optimizer_switch='mrr=on' --mrr_buffer_size=96M` ”，例如查询 6 的部分。
    *   复制或编辑测试配置文件 `mariadb-tools/dbt3_benchmark/tests/myisam_test_mariadb_5_3_mysql_5_5_mysql_5_6.conf` 以包含新的查询配置文件

## Results

### MyISAM test

DBT3 基准测试的配置如下：

*   [MariaDB 5.3.2](https://mariadb.com/kb/en/mariadb-532-release-notes/) 测试版 + MyISAM
*   [MariaDB 5.5.18](https://mariadb.com/kb/en/mariadb-5518-release-notes/) + MyISAM
*   MySQL 5.5.19 + MyISAM
*   MySQL 5.6.4 + MyISAM

结果页： [DBT3 benchmark results MyISAM](https://runebook.dev/zh/docs/mariadb/dbt3-benchmark-results-myisam/index)

### InnoDB test

DBT3 基准测试的配置如下：

*   [MariaDB 5.3.2](https://mariadb.com/kb/en/mariadb-532-release-notes/) 测试版 + XtraDB
*   [MariaDB 5.5.18](https://mariadb.com/kb/en/mariadb-5518-release-notes/) + XtraDB
*   MySQL 5.5.19 + InnoDB
*   MySQL 5.6.4 + InnoDB

结果页： [DBT3 benchmark results InnoDB](https://runebook.dev/zh/docs/mariadb/dbt3-benchmark-results-innodb/index)

### PostgreSQL test

DBT3 基准测试的配置如下：

*   [MariaDB 5.3.2](https://mariadb.com/kb/en/mariadb-532-release-notes/) 测试版 + XtraDB
*   MySQL 5.6.4 + InnoDB
*   PostgreSQL

结果页面：(TODO)

[跳转到 Cubox 查看](https://cubox.pro/my/card?id=7111712186229066439)