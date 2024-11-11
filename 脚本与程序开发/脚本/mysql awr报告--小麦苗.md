
/* 脚本运行方式： 
/* mysql -f -s  <  DB_MySQL_HC_lhr_v7.0.0.sql > lhr_mysql_check.html */
/* mysql -uroot -plhr -h192.168.66.35 -P3317 -S/tmp/mysql.sock   -f --silent  <  DB_MySQL_HC_lhr_v7.0.0.sql > lhr_mysql_check.html */
/* mysql -uroot -plhr -S/tmp/mysql104103320.sock  -s -f <  DB_MySQL_HC_lhr_v7.0.0.sql  > lhr_mysql_check.html  */

/* set @dt=(SELECT DATE_FORMAT(now(),'%Y%m%d%H%i%s') dt); */






select  '<html lang="en"><head><title>MySQL Report</title> <style type="text/css">';
select  'body.awr {font:bold 10pt Consolas;color:black;background:White;}';
select  'table  {font:11px Consolas; color:Black; background:#FFFFCC; padding:1px; margin:0px 0px 0px 0px; cellspacing:0px;border-collapse:collapse;}';
select  'th  {font:bold 11px Consolas; color:White; background:#0066cc; padding:5px; cellspacing:0px;border-collapse:collapse;white-space: nowrap;}';
select  'td {font-family:Consolas; word-wrap: break-word; white-space: pre-wrap; }';
select  'tr:nth-child(odd){background:White;}';
select  'tr:hover   {background-color: yellow;}';
select  'th.awrbg   {font:bold 10pt Consolas; color:White; background:#0066CC;padding-left:0px; padding-right:0px;padding-bottom:0px}';
select  'th.awrnc   {font:9pt Consolas;color:black;background:White;}';
select  'th.awrc    {font:9pt Consolas;color:black;background:#FFFFCC;}';
select  'td.awrnc   {font:9pt Consolas;color:black;background:White;vertical-align:middle;padding:4;}';
select  'a.info:hover {background:#eee;color:#000000; position:relative;}';
select  'a.info span {display: none; }';
select  'a.info:hover span {font-size:11px!important; color:#000000; display:block;position:absolute;top:30px;left:40px;width:150px;border:1px solid #ff0000; background:#FFFF00; padding:1px 1px;text-align:left;word-wrap: break-word; white-space: pre-wrap;}';
select  'td.awrc    {font:9pt Consolas;color:black;background:#FFFFCC; vertical-align:middle;padding:4;}</style></head>';
select  '<body class="awr">';

select  '<Marquee  align="absmiddle" scrolldelay="100" behavior="alternate" direction="left" onmouseover="this.stop()" onmouseout="this.start()" bgcolor="#FFCC00"  height=18 width=100%  vspace="1" hspace="1"><font face="Consolas" color="#008B00" size="2"> <div style="font-weight:lighter">巡检人:小麦苗　QQ:646634621　微信公众号：DB宝　提供OCP、OCM、高可用（rac+dg）、PostgreSQL和MySQL培训　BLOG地址: <a target="_blank"  href=https://www.xmmup.com><font size="2">https://www.xmmup.com</font></a> 若需要脚本可私聊我</div></font></Marquee>';


select  '<center><font size=+3 color=darkgreen><b>MySQL数据库巡检报告</b></font></center>';



-- +----------------------------------------------------------------------------+
-- +----------------------------------------------------------------------------+
-- |                             - REPORT HEADER -                              |
-- +----------------------------------------------------------------------------+


select  '<a name=top></a>';
select  '<hr>';
select  '<div style="font-weight:lighter"><font face="Consolas" color="#336699">Copyright (c) 2015-2100 (https://www.xmmup.com) <a target="_blank" href="https://www.xmmup.com">lhrbest</a>. All rights reserved.</font></div>';
select  '<p>';
select  '<a style="font-weight:lighter">巡 检 人：小麦苗([QQ：646634621]   [微信公众号：DB宝]   [提供OCP、OCM、高可用、MySQL和PostgreSQL最实用的培训])</a></br>';
select  concat('<a style="font-weight:lighter">巡检时间：',DATE_FORMAT(now(),'%Y-%m-%d %H:%i:%s'));
select  ' </a></br>';
select  '<a style="font-weight:lighter">版 本 号：v7.0.0</a></br>';
select  '<a style="font-weight:lighter">修改日期：2023-2-16</a></br>';
select  '<p>';
select  '[<a class="noLink" href="#html_bottom_link"  style="font-weight:lighter">转到页底</a>]';
select  '<hr>';

 

select  '<a name="directory"><font size=+2 face="Consolas" color="#336699"><b>目录</b></font></a>';
select  '<hr>';

select  '<table width="100%" border="1" bordercolor="#000000" cellspacing="0px" style="border-collapse:collapse; margin-top:0.3cm;" align="center">';

select  '<tr>';
select  '<td style="background-color:#FFCC00" rowspan="2"  nowrap align="center" width="10%"><a class="info" href="#db_info_link"><font size=+0.5 face="Consolas" color="#000000"><b>总体概况</b><span> </span></font></a></td>';
select  '<td nowrap align="center" width="18%"  style="background-color:#FFFFCC" ><a class="info" href="#db_base_info"><font size=2.5 face="Consolas" color="#336699">数据库基本信息<span>数据库的总体概况、版本、主机情况、数据库负载情况、数据库属性等</span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#all_db_and_size"><font size=2.5 face="Consolas" color="#336699">所有数据库及其容量大小<span>当前数据库实例的所有数据库及其容量大小</span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#db_status"><font size=2.5 face="Consolas" color="#336699">查看数据库的运行状态<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#top10_tb_size"><font size=2.5 face="Consolas" color="#336699">占用空间最大的前10张大表<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#all_engines"><font size=2.5 face="Consolas" color="#336699">所有存储引擎列表<span>当前数据库实例的所有存储引擎列表</span></font></a></td>';
select  '</tr>'; 

select  '<tr>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#engines_db"><font size=2.5 face="Consolas" color="#336699">存储引擎和DB的数量关系<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#ALL_USES"><font size=2.5 face="Consolas" color="#336699">查询所有用户<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#ALL_character_set"><font size=2.5 face="Consolas" color="#336699">查询MySQL支持的所有字符集<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#IMPORTANT_INIT"><font size=2.5 face="Consolas" color="#336699">一些重要的参数<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#"><font size=2.5 face="Consolas" color="#336699"><span> </span></font></a></td>';
select  '</tr>';

select  '<tr>';
select  '<td style="background-color:#FFCC00" rowspan="1"  nowrap align="center" width="10%"><a class="info" href="#lOCK_INFO"><font size=+0.5 face="Consolas" color="#000000"><b>锁情况</b><span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#all_processlist"><font size=2.5 face="Consolas" color="#336699">查询所有线程<span>排除sleep线程</span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#all_processlist_sleep"><font size=2.5 face="Consolas" color="#336699">sleep线程TOP20<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#process_use"><font size=2.5 face="Consolas" color="#336699">有多少线程正在使用表<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#Innodb_running"><font size=2.5 face="Consolas" color="#336699">InnoDB存储引擎的运行时信息<span>查询InnoDB存储引擎的运行时信息，包括死锁的详细信息</span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#mdl_info"><font size=2.5 face="Consolas" color="#336699">元数据锁的相关信息<span> </span></font></a></td>';
select  '</tr>';

select  '<tr>';
select  '<td style="background-color:#FFCC00" rowspan="2"  nowrap align="center" width="10%"><a class="info" href="#sql_info"><font size=+0.5 face="Consolas" color="#000000"><b>SQL部分</b><span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#SQL_run_long"><font size=2.5 face="Consolas" color="#336699">跟踪长时间操作的进度<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="##SQL_run_long_95"><font size=2.5 face="Consolas" color="#336699">平均执行时间值大于95%的平均执行时间的语句<span>查看平均执行时间值大于95%的平均执行时间的语句（可近似地认为是平均执行时间超长的语句），默认情况下按照语句平均延迟(执行时间)降序排序</span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#sql_info_tmp"><font size=2.5 face="Consolas" color="#336699">使用了临时表的语句<span>查看使用了临时表的语句，默认情况下按照磁盘临时表数量和内存临时表数量进行降序排序</span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#sql_info_disk_sort"><font size=2.5 face="Consolas" color="#336699">查看执行了文件排序的语句<span>默认情况下按照语句总延迟时间（执行时间）降序排序</span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#sqL_cost_all"><font size=2.5 face="Consolas" color="#336699">查询SQL的整体消耗百分比<span> </span></font></a></td>';
select  '</tr>';

select  '<tr>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#sqL_exec_count_top10"><font size=2.5 face="Consolas" color="#336699">执行次数Top10<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#sqL_full_scan"><font size=2.5 face="Consolas" color="#336699">使用全表扫描的SQL语句<span>使用全表扫描的SQL语句</span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#sql_no_best_index"><font size=2.5 face="Consolas" color="#336699">没有使用到最优索引的语句<span>查看全表扫描或者没有使用到最优索引的语句（经过标准化转化的语句文本），默认情况下按照全表扫描次数与语句总次数百分比和语句总延迟时间(执行时间)降序排序</span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#sql_error_worings"><font size=2.5 face="Consolas" color="#336699">产生错误或警告的语句<span>查看产生错误或警告的语句，默认情况下，按照错误数量和警告数量降序排序</span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#"><font size=2.5 face="Consolas" color="#336699"><span> </span></font></a></td>';
select  '</tr>';

select  '<tr>';
select  '<td style="background-color:#FFCC00" rowspan="1"  nowrap align="center" width="10%"><a class="info" href="#index_info"><font size=+0.5 face="Consolas" color="#000000"><b>索引部分</b><span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#sql_redundant_indexes"><font size=2.5 face="Consolas" color="#336699">冗余索引<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#sql_unused_indexes"><font size=2.5 face="Consolas" color="#336699">无效索引（从未使用过的索引）<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#index_qfd"><font size=2.5 face="Consolas" color="#336699">索引区分度<span>区分度，越接近1，表示区分度越高，低于0.1，则说明区分度较差，开发者应该重新评估SQL语句涉及的字段，选择区分度高的多个字段创建索引</span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#spfile_contents"><font size=2.5 face="Consolas" color="#336699"><span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#statistics_level"><font size=2.5 face="Consolas" color="#336699"><span> </span></font></a></td>';
select  '</tr>';

select  '<tr>';
select  '<td style="background-color:#FFCC00" rowspan="1"  nowrap align="center" width="10%"><a class="info" href="#slave_info"><font size=+0.5 face="Consolas" color="#000000"><b>主从情况</b><span> MySQL Replication（MySQL主从复制）</span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#SLAVE_IMPORTANT_INIT"><font size=2.5 face="Consolas" color="#336699">主从复制涉及到的重要参数<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#slave_processlist"><font size=2.5 face="Consolas" color="#336699">主从库线程<span>主从库线程查询</span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#binary_bin_log"><font size=2.5 face="Consolas" color="#336699">二进制日志<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#master_info_status"><font size=2.5 face="Consolas" color="#336699">主库状态监测<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#slave_info_status"><font size=2.5 face="Consolas" color="#336699">备库状态监测<span> </span></font></a></td>';
select  '</tr>';

select  '<tr>';
select  '<td style="background-color:#FFCC00" rowspan="1"  nowrap align="center" width="10%"><a class="info" href="#db_performance_info"><font size=+0.5 face="Consolas" color="#000000"><b>数据库性能</b><span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#db_per_config_stats"><font size=2.5 face="Consolas" color="#336699">性能参数统计<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#"><font size=2.5 face="Consolas" color="#336699"><span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#"><font size=2.5 face="Consolas" color="#336699"><span></span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#"><font size=2.5 face="Consolas" color="#336699"><span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#"><font size=2.5 face="Consolas" color="#336699"><span> </span></font></a></td>';
select  '</tr>';

select  '<tr>';
select  '<td style="background-color:#FFCC00" rowspan="1"  nowrap align="center" width="10%"><a class="info" href="#others_info"><font size=+0.5 face="Consolas" color="#000000"><b>其它</b><span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#setup_consumers"><font size=2.5 face="Consolas" color="#336699">setup_consumers<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#Auto_increment"><font size=2.5 face="Consolas" color="#336699">自增ID的使用<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#no_pk"><font size=2.5 face="Consolas" color="#336699">无主键或唯一键的表<span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#"><font size=2.5 face="Consolas" color="#336699"><span> </span></font></a></td>';
select  '<td nowrap align="center" style="background-color:#FFFFCC" ><a class="info" href="#"><font size=2.5 face="Consolas" color="#336699"><span> </span></font></a></td>';
select  '</tr>';

select  '</table>';


select  '<br />';
select  '<hr>';
select  '<br />';



-- +----------------------------------------------------------------------------+
-- +----------------------------------------------------------------------------+
-- |                             - DATABASE OVERVIEW -                          |
-- +----------------------------------------------------------------------------+

-- 配置可以查询information_schema.GLOBAL_VARIABLES，8.0版本取消
-- set GLOBAL show_compatibility_56=1;
-- set GLOBAL show_compatibility_56=0;


select  '<a name="db_info_link"></a>';
select  '<font size="+2" color="00CCFF"><b>数据库总体概况</b></font><hr align="left" width="800">';



select  '<a name="db_base_info"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 数据库基本信息</b></font>';

SELECT '<table border=1><tr><th>now_date</th><th>user</th><th>CURRENT_USER1</th><th>CONNECTION_ID</th><th>db_name</th><th>Server_version</th><th>all_db_size_MB</th><th>all_datafile_size_MB</th><th>datadir</th><th>SOCKET</th><th>log_error</th><th>autocommit</th><th>log_bin</th><th>server_id</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',now_date,'</td><td>',user,'</td><td>',CURRENT_USER1,'</td><td>',CONNECTION_ID,'</td><td>',ifnull(db_name,''),'</td><td>',Server_version,'</td><td>',ifnull(all_db_size_MB,''),'</td><td>',ifnull(all_datafile_size_MB,''),'</td><td>',datadir,'</td><td>',SOCKET,'</td><td>',log_error,'</td><td>',autocommit,'</td><td>',log_bin,'</td><td>',server_id,'</td></tr>') 
from (SELECT  now() now_date,
	USER() user, -- USER()、 SYSTEM_USER()、 SESSION_USER()、 
	CURRENT_USER() CURRENT_USER1,
	CONNECTION_ID() CONNECTION_ID,
	DATABASE() db_name, -- SCHEMA(),
	version() Server_version,
	( SELECT sum( TRUNCATE ( ( data_length + index_length ) / 1024 / 1024, 2 ) ) AS 'all_db_size(MB)' FROM information_schema.TABLES b ) all_db_size_MB,
	(select truncate(sum(total_extents*extent_size)/1024/1024,2) from  information_schema.FILES b) all_datafile_size_MB,
	( SELECT @@datadir ) datadir,
	( SELECT @@SOCKET ) SOCKET,
	( SELECT @@log_error ) log_error,
	-- ( SELECT @@tx_isolation ) tx_isolation, -- SELECT @@transaction_isolation tx_isolation
	( SELECT @@autocommit ) autocommit,
	( SELECT @@log_bin ) log_bin,
	( SELECT @@server_id ) server_id ) V

UNION ALL 
SELECT '</table>' ; 




select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 版本信息</b></font>';

-- select  '</br><textarea style="width:600px;font-family:Consolas;font-size:11px;overflow:auto;background-color:#FFFFCC" -- rows="8">';
-- 
-- show variables like 'version_%';
-- 
-- select  '</textarea>';

-- -- mysql 5.7
-- SELECT '<table border=1><tr><th>VARIABLE_NAME</th><th>VARIABLE_VALUE</th></tr>'
-- UNION ALL
-- SELECT concat('<tr><td>',VARIABLE_NAME,'</td><td>',VARIABLE_VALUE,'</td></tr>') 
-- from (select * from performance_schema.global_variables where  VARIABLE_NAME like 'version_%') V
-- UNION ALL 
-- SELECT '</table>'
-- ;

-- -- mysql 5.5和5.6和mariadb
-- SELECT '<table border=1><tr><th>VARIABLE_NAME</th><th>VARIABLE_VALUE</th></tr>'
-- UNION ALL
-- SELECT concat('<tr><td>',VARIABLE_NAME,'</td><td>',VARIABLE_VALUE,'</td></tr>') 
-- from (select * from INFORMATION_SCHEMA.global_variables where  VARIABLE_NAME like  'version_%') V
-- UNION ALL 
-- SELECT '</table>'
-- ;





select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 插件信息</b></font>';
-- SELECT * FROM INFORMATION_SCHEMA.PLUGINS; -- SHOW PLUGINS;
SELECT '<table border=1><tr><th>PLUGIN_NAME</th><th>PLUGIN_VERSION</th><th>PLUGIN_STATUS</th><th>PLUGIN_TYPE</th><th>PLUGIN_TYPE_VERSION</th><th>PLUGIN_LIBRARY</th><th>PLUGIN_LIBRARY_VERSION</th><th>PLUGIN_AUTHOR</th><th>PLUGIN_DESCRIPTION</th><th>PLUGIN_LICENSE</th><th>LOAD_OPTION</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',PLUGIN_NAME,'</td><td>',PLUGIN_VERSION,'</td><td>',PLUGIN_STATUS,'</td><td>',PLUGIN_TYPE,'</td><td>',PLUGIN_TYPE_VERSION,'</td><td>',ifnull(PLUGIN_LIBRARY,''),'</td><td>',ifnull(PLUGIN_LIBRARY_VERSION,''),'</td><td>',PLUGIN_AUTHOR,'</td><td>',PLUGIN_DESCRIPTION,'</td><td>',PLUGIN_LICENSE,'</td><td>',LOAD_OPTION,'</td></tr>') 
from (SELECT * FROM INFORMATION_SCHEMA.PLUGINS) V

UNION ALL 
SELECT '</table>' 
;





select  '<a name="all_db_and_size"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 当前数据库实例的所有数据库及其容量大小</b></font>';
-- show databases;
SELECT '<table border=1><tr><th>SCHEMA_NAME</th><th>DEFAULT_CHARACTER_SET_NAME</th><th>DEFAULT_COLLATION_NAME</th><th>table_rows</th><th>data_size_mb</th><th>index_size_mb</th><th>all_size_mb</th><th>max_size_mb</th><th>free_size_mb</th><th>disk_size_mb</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',SCHEMA_NAME,'</td><td>',DEFAULT_CHARACTER_SET_NAME,'</td><td>',DEFAULT_COLLATION_NAME,'</td><td>',ifnull(table_rows,''),'</td><td>',ifnull(data_size_mb,''),'</td><td>',ifnull(index_size_mb,''),'</td><td>',ifnull(all_size_mb,''),'</td><td>',ifnull(max_size_mb,''),'</td><td>',ifnull(free_size_mb,''),'</td><td>',ifnull(disk_size_mb,''),'</td></tr>') 
from (

select a.SCHEMA_NAME, a.DEFAULT_CHARACTER_SET_NAME,a.DEFAULT_COLLATION_NAME,
sum(table_rows) as table_rows,
truncate(sum(data_length)/1024/1024, 2) as data_size_mb,
truncate(sum(index_length)/1024/1024, 2) as index_size_mb,
truncate(sum(data_length+index_length)/1024/1024, 2) as all_size_mb,
truncate(sum(max_data_length)/1024/1024, 2) as max_size_mb,
truncate(sum(data_free)/1024/1024, 2) as free_size_mb,
max(f.filesize_M)  as disk_size_mb
from INFORMATION_SCHEMA.SCHEMATA a
left outer join information_schema.tables b
on a.SCHEMA_NAME=b.TABLE_SCHEMA
left outer join 
    (select substring(b.file_name,3,locate('/',b.file_name,3)-3) as db_name,
			truncate(sum(total_extents*extent_size)/1024/1024,2) filesize_M
			from  information_schema.FILES b 
			group by substring(b.file_name,3,locate('/',b.file_name,3)-3)) f
on ( a.SCHEMA_NAME= f.db_name)
group by a.SCHEMA_NAME,  a.DEFAULT_CHARACTER_SET_NAME,a.DEFAULT_COLLATION_NAME
order by sum(data_length) desc, sum(index_length) DESC

) V

UNION ALL 
SELECT '</table>'
;






select  '<a name="all_db_objects"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 数据库对象</b></font>';


SELECT '<table border=1><tr><th>db_name</th><th>ob_type</th><th>sums</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',db_name,'</td><td>',ob_type,'</td><td>',sums,'</td></tr>') from 
(select db as db_name ,type as ob_type,cnt as sums from 
(select 'TABLE' type,table_schema db, count(*) cnt  from information_schema.`TABLES` a where table_type='BASE TABLE' group by table_schema
union all
select 'EVENTS' type,event_schema db,count(*) cnt from information_schema.`EVENTS` b group by event_schema
union all
select 'TRIGGERS' type,trigger_schema db,count(*) cnt from information_schema.`TRIGGERS` c group by trigger_schema
union all
select 'PROCEDURE' type,routine_schema db,count(*) cnt from information_schema.ROUTINES d where`ROUTINE_TYPE` = 'PROCEDURE' group by db
union all
select 'FUNCTION' type,routine_schema db,count(*) cnt  from information_schema.ROUTINES d where`ROUTINE_TYPE` = 'FUNCTION' group by db
union all
select 'VIEWS' type,TABLE_SCHEMA db,count(*) cnt  from information_schema.VIEWS f group by table_schema  ) t
order by db,type) V

UNION ALL 
SELECT '</table>' ;




select  '<a name="db_status"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查看数据库的运行状态</b></font>';
select  '<TABLE BORDER=1><tr><td style="background:#FFFFCC;font-family:Consolas; word-wrap: break-word; white-space: pre-wrap; white-space: -moz-pre-wrap">';

status;


select  '</TD></TR></TABLE>';




select  '<a name="top10_tb_size"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 占用空间最大的前10张大表</b></font>';

/* 
1、表和索引在同一个文件中，例如sbtest6.ibd文件中包括了索引和数据
2、主键索引的大小就是数据大小
3、SQL查询出来的总大小应该减去datafree才是真实的占用空间
*/


 
SELECT '<table border=1><tr><th>db_name</th><th>table_name</th><th>TABLE_TYPE</th><th>ENGINE</th><th>CREATE_TIME</th><th>UPDATE_TIME</th><th>TABLE_COLLATION</th><th>table_rows</th><th>tb_size_mb</th><th>index_size_mb</th><th>all_size_mb</th><th>free_size_mb</th><th>disk_size_mb</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',db_name,'</td><td>',table_name,'</td><td>',TABLE_TYPE,'</td><td>',ENGINE,'</td><td>',CREATE_TIME,'</td><td>',ifnull(UPDATE_TIME,''),'</td><td>',TABLE_COLLATION,'</td><td>',table_rows,'</td><td>',tb_size_mb,'</td><td>',index_size_mb,'</td><td>',all_size_mb,'</td><td>',free_size_mb,'</td><td>',ifnull(disk_size_mb,''),'</td></tr>') 
from (SELECT
	table_schema AS db_name,
	table_name AS table_name,
	a.TABLE_TYPE,
	a.`ENGINE`,
	a.CREATE_TIME,
	a.UPDATE_TIME,
	a.TABLE_COLLATION,
	table_rows AS table_rows,
	TRUNCATE(a.DATA_LENGTH / 1024 / 1024, 2 ) AS tb_size_mb,
	TRUNCATE( index_length / 1024 / 1024, 2 ) AS index_size_mb,
	TRUNCATE( ( data_length + index_length ) / 1024 / 1024, 2 ) AS all_size_mb,
  TRUNCATE( a.DATA_FREE / 1024 / 1024, 2 ) AS free_size_mb,
  truncate(f.filesize_M,2) AS disk_size_mb
FROM information_schema.TABLES a
left outer join 
    (select substring(b.file_name,3,locate('/',b.file_name,3)-3) as db_name,  
			substring(b.file_name,locate('/',b.file_name,3)+1,(LENGTH(b.file_name)-locate('/',b.file_name,3)-4)) as tb_name,
			b.file_name,
			(total_extents*extent_size)/1024/1024 filesize_M
			from  information_schema.FILES b 
			order by filesize_M desc limit 20 ) f
on ( a.TABLE_SCHEMA= f.db_name and a.TABLE_NAME=f.tb_name )
ORDER BY	( data_length + index_length ) DESC 
LIMIT 10) V

UNION ALL 
SELECT '</table>' 
;




select  '<a name="top10_tb_size"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 占用空间最大的前10个索引</b></font>';


SELECT '<table border=1><tr><th>database_name</th><th>table_name</th><th>index_name</th><th>SizeMB</th><th>NON_UNIQUE</th><th>INDEX_TYPE</th><th>COLUMN_NAME</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',database_name,'</td><td>',table_name,'</td><td>',index_name,'</td><td>',SizeMB,'</td><td>',NON_UNIQUE,'</td><td>',INDEX_TYPE,'</td><td>',COLUMN_NAME,'</td></tr>') from
(select 
iis.database_name, 
iis.table_name, 
iis.index_name, 
round((iis.stat_value*@@innodb_page_size)/1024/1024, 2) SizeMB, 
-- round(((100/(SELECT INDEX_LENGTH FROM INFORMATION_SCHEMA.TABLES t WHERE t.TABLE_NAME = iis.table_name and t.TABLE_SCHEMA = iis.database_name))*(stat_value*@@innodb_page_size)), 2) `Percentage`,
s.NON_UNIQUE,
s.INDEX_TYPE,
GROUP_CONCAT(s.COLUMN_NAME order by SEQ_IN_INDEX) COLUMN_NAME
from (select * from mysql.innodb_index_stats 
				WHERE index_name  not in ('PRIMARY','GEN_CLUST_INDEX') and stat_name='size' 
				order by (stat_value*@@innodb_page_size) desc limit 10
			) iis 
left join INFORMATION_SCHEMA.STATISTICS s
on (iis.database_name=s.TABLE_SCHEMA and iis.table_name=s.TABLE_NAME and iis.index_name=s.INDEX_NAME)
GROUP BY iis.database_name,iis.TABLE_NAME,iis.INDEX_NAME,(iis.stat_value*@@innodb_page_size),s.NON_UNIQUE,s.INDEX_TYPE
order by (stat_value*@@innodb_page_size) desc) V

UNION ALL 
SELECT '</table>' 
;


select  '<a name="all_engines"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 所有存储引擎列表</b></font>';
-- show engines;
-- SELECT * from information_schema.`ENGINES`;
SELECT '<table border=1><tr><th>ENGINE</th><th>SUPPORT</th><th>COMMENT</th><th>TRANSACTIONS</th><th>XA</th><th>SAVEPOINTS</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',ENGINE,'</td><td>',SUPPORT,'</td><td>',COMMENT,'</td><td>',ifnull(TRANSACTIONS,''),'</td><td>',ifnull(XA,''),'</td><td>',ifnull(SAVEPOINTS,''),'</td></tr>') 
from (SELECT * from information_schema.`ENGINES`) V

UNION ALL 
SELECT '</table>' 
;


select  '<a name="engines_db"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 存储引擎和DB的数量关系 </b></font>';


SELECT '<table border=1><tr><th>ENGINE</th><th>counts</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',ifnull(ENGINE,''),'</td><td>',counts,'</td></tr>') 
from (SELECT a.`ENGINE`,count( * ) counts 
FROM    information_schema.`TABLES` a 
GROUP BY a.`ENGINE`) V

UNION ALL 
SELECT '</table>' 
;


select  '<p>';
SELECT '<table border=1><tr><th>TABLE_SCHEMA</th><th>ENGINE</th><th>counts</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',TABLE_SCHEMA,'</td><td>',ifnull(ENGINE,''),'</td><td>',counts,'</td></tr>') 
from (SELECT  a.TABLE_SCHEMA,
	a.`ENGINE`,
	count( * ) counts 
FROM    information_schema.`TABLES` a 
GROUP BY  a.TABLE_SCHEMA,a.`ENGINE` 
ORDER BY a.TABLE_SCHEMA) V

UNION ALL 
SELECT '</table>' 
;


select  '<a name="innodb_tablespaces"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● InnoDB 系统表空间</b></font>';
-- select * from information_schema.innodb_tablespaces where space_type<>'Single';
-- select  '<p>';


SELECT '<table border=1><tr><th>FILE_ID</th><th>FILE_NAME</th><th>FILE_TYPE</th><th>TABLESPACE_NAME</th><th>TABLE_CATALOG</th><th>TABLE_SCHEMA</th><th>TABLE_NAME</th><th>LOGFILE_GROUP_NAME</th><th>LOGFILE_GROUP_NUMBER</th><th>ENGINE</th><th>FULLTEXT_KEYS</th><th>DELETED_ROWS</th><th>UPDATE_COUNT</th><th>FREE_EXTENTS</th><th>TOTAL_EXTENTS</th><th>EXTENT_SIZE</th><th>INITIAL_SIZE</th><th>MAXIMUM_SIZE</th><th>AUTOEXTEND_SIZE</th><th>CREATION_TIME</th><th>LAST_UPDATE_TIME</th><th>LAST_ACCESS_TIME</th><th>RECOVER_TIME</th><th>TRANSACTION_COUNTER</th><th>VERSION</th><th>ROW_FORMAT</th><th>TABLE_ROWS</th><th>AVG_ROW_LENGTH</th><th>DATA_LENGTH</th><th>MAX_DATA_LENGTH</th><th>INDEX_LENGTH</th><th>DATA_FREE</th><th>CREATE_TIME</th><th>UPDATE_TIME</th><th>CHECK_TIME</th><th>CHECKSUM</th><th>STATUS</th><th>EXTRA</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',FILE_ID,'</td><td>',FILE_NAME,'</td><td>',FILE_TYPE,'</td><td>',TABLESPACE_NAME,'</td><td>',TABLE_CATALOG,'</td><td>',ifnull(TABLE_SCHEMA,''),'</td><td>',ifnull(TABLE_NAME,''),'</td><td>',ifnull(LOGFILE_GROUP_NAME,''),'</td><td>',ifnull(LOGFILE_GROUP_NUMBER,''),'</td><td>',ENGINE,'</td><td>',ifnull(FULLTEXT_KEYS,''),'</td><td>',ifnull(DELETED_ROWS,''),'</td><td>',ifnull(UPDATE_COUNT,''),'</td><td>',FREE_EXTENTS,'</td><td>',TOTAL_EXTENTS,'</td><td>',EXTENT_SIZE,'</td><td>',ifnull(INITIAL_SIZE,''),'</td><td>',ifnull(MAXIMUM_SIZE,''),'</td><td>',ifnull(AUTOEXTEND_SIZE,''),'</td><td>',ifnull(CREATION_TIME,''),'</td><td>',ifnull(LAST_UPDATE_TIME,''),'</td><td>',ifnull(LAST_ACCESS_TIME,''),'</td><td>',ifnull(RECOVER_TIME,''),'</td><td>',ifnull(TRANSACTION_COUNTER,''),'</td><td>',ifnull(VERSION,''),'</td><td>',ifnull(ROW_FORMAT,''),'</td><td>',ifnull(TABLE_ROWS,''),'</td><td>',ifnull(AVG_ROW_LENGTH,''),'</td><td>',ifnull(DATA_LENGTH,''),'</td><td>',ifnull(MAX_DATA_LENGTH,''),'</td><td>',ifnull(INDEX_LENGTH,''),'</td><td>',ifnull(DATA_FREE,''),'</td><td>',ifnull(CREATE_TIME,''),'</td><td>',ifnull(UPDATE_TIME,''),'</td><td>',ifnull(CHECK_TIME,''),'</td><td>',ifnull(CHECKSUM,''),'</td><td>',ifnull(STATUS,''),'</td><td>',ifnull(EXTRA,''),'</td></tr>') 
from (SELECT * FROM INFORMATION_SCHEMA.FILES a WHERE FILE_TYPE <>'TABLESPACE' or a.TABLESPACE_NAME in ('innodb_system','innodb_temporary')) V

UNION ALL 
SELECT '</table>' 
;






select  '<a name="ALL_USES"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查询所有用户</b></font>';

SELECT '<table border=1><tr><th>Host</th><th>User</th><th>Select_priv</th><th>Insert_priv</th><th>Update_priv</th><th>Delete_priv</th><th>Create_priv</th><th>Drop_priv</th><th>Reload_priv</th><th>Shutdown_priv</th><th>Process_priv</th><th>File_priv</th><th>Grant_priv</th><th>References_priv</th><th>Index_priv</th><th>Alter_priv</th><th>Show_db_priv</th><th>Super_priv</th><th>Create_tmp_table_priv</th><th>Lock_tables_priv</th><th>Execute_priv</th><th>Repl_slave_priv</th><th>Repl_client_priv</th><th>Create_view_priv</th><th>Show_view_priv</th><th>Create_routine_priv</th><th>Alter_routine_priv</th><th>Create_user_priv</th><th>Event_priv</th><th>Trigger_priv</th><th>Create_tablespace_priv</th><th>ssl_type</th><th>ssl_cipher</th><th>x509_issuer</th><th>x509_subject</th><th>max_questions</th><th>max_updates</th><th>max_connections</th><th>max_user_connections</th><th>plugin</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',Host,'</td><td>',User,'</td><td>',Select_priv,'</td><td>',Insert_priv,'</td><td>',Update_priv,'</td><td>',Delete_priv,'</td><td>',Create_priv,'</td><td>',Drop_priv,'</td><td>',Reload_priv,'</td><td>',Shutdown_priv,'</td><td>',Process_priv,'</td><td>',File_priv,'</td><td>',Grant_priv,'</td><td>',References_priv,'</td><td>',Index_priv,'</td><td>',Alter_priv,'</td><td>',Show_db_priv,'</td><td>',Super_priv,'</td><td>',Create_tmp_table_priv,'</td><td>',Lock_tables_priv,'</td><td>',Execute_priv,'</td><td>',Repl_slave_priv,'</td><td>',Repl_client_priv,'</td><td>',Create_view_priv,'</td><td>',Show_view_priv,'</td><td>',Create_routine_priv,'</td><td>',Alter_routine_priv,'</td><td>',Create_user_priv,'</td><td>',Event_priv,'</td><td>',Trigger_priv,'</td><td>',Create_tablespace_priv,'</td><td>',ssl_type,'</td><td>',ssl_cipher,'</td><td>',x509_issuer,'</td><td>',x509_subject,'</td><td>',max_questions,'</td><td>',max_updates,'</td><td>',max_connections,'</td><td>',max_user_connections,'</td><td>',plugin,'</td><tr>') 
from (select * from mysql.user) V

UNION ALL 
SELECT '</table>' 
;



select  '<a name="ALL_character_set"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查询MySQL支持的所有字符集 </b></font>';
-- show character set;
SELECT '<table border=1><tr><th>CHARACTER_SET_NAME</th><th>DEFAULT_COLLATE_NAME</th><th>DESCRIPTION</th><th>MAXLEN</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',CHARACTER_SET_NAME,'</td><td>',DEFAULT_COLLATE_NAME,'</td><td>',DESCRIPTION,'</td><td>',MAXLEN,'</td></tr>') 
from (select * from information_schema.CHARACTER_SETS) V

UNION ALL 
SELECT '</table>' 
;



select  '<a name="IMPORTANT_INIT"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 一些重要的参数 </b></font>';


-- select  '</br><textarea style="width:1100px;font-family:Consolas;font-size:11px;overflow:auto;background-color:#FFFFCC" rows="40">';
-- 
-- show global VARIABLES where  VARIABLE_NAME in ('datadir','SQL_MODE','socket','TIME_ZONE','tx_isolation','transaction_isolation','autocommit','innodb_lock_wait_timeout','max_connections','max_user_connections','slow_query_log','log_output','slow_query_log_file','long_query_time','log_queries_not_using_indexes','log_throttle_queries_not_using_indexes','log_throttle_queries_not_using_indexes','pid_file','log_error','lower_case_table_names','innodb_buffer_pool_size','innodb_flush_log_at_trx_commit','read_only', 'log_slave_updates','innodb_io_capacity','query_cache_type','query_cache_size','max_connect_errors','server_id','innodb_file_per_table') ;
-- 
-- select  '</textarea>';


-- -- mysql 5.7
-- SELECT '<table border=1><tr><th>VARIABLE_NAME</th><th>VARIABLE_VALUE</th></tr>'
-- UNION ALL
-- SELECT concat('<tr><td>',VARIABLE_NAME,'</td><td>',VARIABLE_VALUE,'</td></tr>') 
-- from (select * from performance_schema.global_variables where  VARIABLE_NAME  in ( 'datadir','SQL_MODE','socket','TIME_ZONE','tx_isolation','transaction_isolation','autocommit','innodb_lock_wait_timeout','max_connections','max_user_connections','slow_query_log','log_output','slow_query_log_file','long_query_time','log_queries_not_using_indexes','log_throttle_queries_not_using_indexes','log_throttle_queries_not_using_indexes','pid_file','log_error','lower_case_table_names','innodb_buffer_pool_size','innodb_flush_log_at_trx_commit','read_only', 'log_slave_updates','innodb_io_capacity','query_cache_type','query_cache_size','max_connect_errors','server_id','innodb_file_per_table')) V
-- UNION ALL 
-- SELECT '</table>'
-- ;

-- -- mysql 5.5和5.6和mariadb
-- SELECT '<table border=1><tr><th>VARIABLE_NAME</th><th>VARIABLE_VALUE</th></tr>'
-- UNION ALL
-- SELECT concat('<tr><td>',VARIABLE_NAME,'</td><td>',VARIABLE_VALUE,'</td></tr>') 
-- from (select * from INFORMATION_SCHEMA.global_variables where  VARIABLE_NAME  in ( 'datadir','SQL_MODE','socket','TIME_ZONE','tx_isolation','transaction_isolation','autocommit','innodb_lock_wait_timeout','max_connections','max_user_connections','slow_query_log','log_output','slow_query_log_file','long_query_time','log_queries_not_using_indexes','log_throttle_queries_not_using_indexes','log_throttle_queries_not_using_indexes','pid_file','log_error','lower_case_table_names','innodb_buffer_pool_size','innodb_flush_log_at_trx_commit','read_only', 'log_slave_updates','innodb_io_capacity','query_cache_type','query_cache_size','max_connect_errors','server_id','innodb_file_per_table')) V
-- UNION ALL 
-- SELECT '</table>'
-- ;



select  '<a name="ALL_link_user_host"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查看当前连接到数据库的用户和Host </b></font>';

SELECT '<table border=1><tr><th>USER</th><th>HOST</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',USER,'</td><td>',HOST,'</td></tr>') 
from (SELECT DISTINCT USER,HOST FROM `information_schema`.`PROCESSLIST` P WHERE P.USER NOT in ('repl','system user') limit 100) V

UNION ALL 
SELECT '</table>' ;



select  '<a name="ALL_link_user_host_per"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查看每个host的当前连接数和总连接数 </b></font>';
-- 系统表performance_schema.hosts在MySQL 5.6.3版本中引入，用来保存MySQL服务器启动后的连接情况。

SELECT '<table border=1><tr><th>HOST</th><th>CURRENT_CONNECTIONS</th><th>TOTAL_CONNECTIONS</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',ifnull(HOST,''),'</td><td>',CURRENT_CONNECTIONS,'</td><td>',TOTAL_CONNECTIONS,'</td></tr>') 
from (SELECT * FROM performance_schema.hosts) V

UNION ALL 
SELECT '</table>' 
;


select  '<a name="ALL_link_user_host_info"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 按照登录用户+登录服务器查看登录信息 </b></font>';

SELECT '<table border=1><tr><th>login_user</th><th>login_ip</th><th>login_count</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',login_user,'</td><td>',login_ip,'</td><td>',login_count,'</td></tr>') 
from (SELECT USER AS login_user,
	LEFT ( HOST, POSITION( ':' IN HOST ) - 1 ) AS login_ip,
	count( 1 ) AS login_count 
FROM `information_schema`.`PROCESSLIST` P 
-- WHERE P.USER NOT IN ( 'root', 'repl', 'system user' ) 
GROUP BY USER,LEFT ( HOST, POSITION( ':' IN HOST ) - 1 )) V

UNION ALL 
SELECT '</table>' 
;





select  '<a name="ALL_link_user_host_info"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 按照登录用户+数据库+登录服务器查看登录信息 </b></font>';

SELECT '<table border=1><tr><th>database_name</th><th>login_user</th><th>login_ip</th><th>login_count</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',ifnull(database_name,''),'</td><td>',login_user,'</td><td>',login_ip,'</td><td>',login_count,'</td></tr>') 
from (SELECT  DB AS database_name,
	USER AS login_user,
	LEFT ( HOST, POSITION( ':' IN HOST ) - 1 ) AS login_ip,
	count( 1 ) AS login_count 
FROM  `information_schema`.`PROCESSLIST` P 
-- WHERE P.USER NOT IN ( 'root', 'repl', 'system user' ) 
GROUP BY DB,USER,LEFT(HOST, POSITION( ':' IN HOST ) - 1 )) V

UNION ALL 
SELECT '</table>' 
;




select  '<center>[<a class="noLink" href="#directory">回到目录</a>]</center><p></hr>';
select  '<hr><p><p>';



-- +----------------------------------------------------------------------------+
-- |                           - Lock info -                                    |
-- +----------------------------------------------------------------------------+


select  '<a name="lOCK_INFO"></a>';
select  '<font size="+2" color="00CCFF"><b>锁情况</b></font><hr align="left" width="800">';



select  '<a name="all_processlist"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查询所有线程（排除sleep线程）</b></font>';
-- show full processlist;
-- SELECT * FROM information_schema.`PROCESSLIST`;

SELECT '<table border=1><tr><th>ID</th><th>USER</th><th>HOST</th><th>DB</th><th>COMMAND</th><th>TIME</th><th>STATE</th><th>INFO</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',ID,'</td><td>',USER,'</td><td>',HOST,'</td><td>',ifnull(DB,''),'</td><td>',COMMAND,'</td><td>',TIME,'</td><td>',STATE,'</td><td>',ifnull(INFO,''),'</td></tr>') 
from (select * from information_schema.`PROCESSLIST`  a where a.command<>'Sleep' and a.id<>CONNECTION_id() ) V

UNION ALL 
SELECT '</table>' ;



select  '<p>';
SELECT '<table border=1><tr><th>THREAD_ID</th><th>NAME</th><th>TYPE</th><th>PROCESSLIST_ID</th><th>PROCESSLIST_USER</th><th>PROCESSLIST_HOST</th><th>PROCESSLIST_DB</th><th>PROCESSLIST_COMMAND</th><th>PROCESSLIST_TIME</th><th>PROCESSLIST_STATE</th><th>PROCESSLIST_INFO</th><th>PARENT_THREAD_ID</th><th>ROLE</th><th>INSTRUMENTED</th><th>HISTORY</th><th>CONNECTION_TYPE</th><th>THREAD_OS_ID</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',THREAD_ID,'</td><td>',NAME,'</td><td>',TYPE,'</td><td>',PROCESSLIST_ID,'</td><td>',ifnull(PROCESSLIST_USER,''),'</td><td>',ifnull(PROCESSLIST_HOST,''),'</td><td>',ifnull(PROCESSLIST_DB,''),'</td><td>',PROCESSLIST_COMMAND,'</td><td>',PROCESSLIST_TIME,'</td><td>',PROCESSLIST_STATE,'</td><td>',ifnull(PROCESSLIST_INFO,''),'</td><td>',PARENT_THREAD_ID,'</td><td>',ifnull(ROLE,''),'</td><td>',INSTRUMENTED,'</td><td>',HISTORY,'</td><td>',ifnull(CONNECTION_TYPE,''),'</td><td>',ifnull(THREAD_OS_ID,''),'</td></tr>') 
from (SELECT * FROM performance_schema.threads a where a.type!='BACKGROUND' and a.PROCESSLIST_COMMAND<>'Sleep'  and a.PROCESSLIST_ID<>CONNECTION_id() ) V

UNION ALL 
SELECT '</table>' 
;



select  '<a name="all_processlist_sleep"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● sleep线程TOP20</b></font>';
-- select * from information_schema.`PROCESSLIST`  a where a.command='Sleep' order by time desc limit 20 ;
-- select id,user,host,db,concat('<textarea style="width:600px;font-family:Consolas;font-size:11px;overflow:auto" rows="3">',info,'</textarea>') info from information_schema.`PROCESSLIST`;
SELECT '<table border=1><tr><th>ID</th><th>USER</th><th>HOST</th><th>DB</th><th>COMMAND</th><th>TIME</th><th>STATE</th><th>INFO</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',ID,'</td><td>',USER,'</td><td>',HOST,'</td><td>',ifnull(DB,''),'</td><td>',COMMAND,'</td><td>',TIME,'</td><td>',ifnull(STATE,''),'</td><td>',ifnull(INFO,''),'</td></tr>') 
from (select * from information_schema.`PROCESSLIST`  a where a.command='Sleep' order by time desc limit 20 ) V

UNION ALL 
SELECT '</table>' ;



select  '<p>';
SELECT '<table border=1><tr><th>THREAD_ID</th><th>NAME</th><th>TYPE</th><th>PROCESSLIST_ID</th><th>PROCESSLIST_USER</th><th>PROCESSLIST_HOST</th><th>PROCESSLIST_DB</th><th>PROCESSLIST_COMMAND</th><th>PROCESSLIST_TIME</th><th>PROCESSLIST_STATE</th><th>PROCESSLIST_INFO</th><th>PARENT_THREAD_ID</th><th>ROLE</th><th>INSTRUMENTED</th><th>HISTORY</th><th>CONNECTION_TYPE</th><th>THREAD_OS_ID</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',THREAD_ID,'</td><td>',NAME,'</td><td>',TYPE,'</td><td>',PROCESSLIST_ID,'</td><td>',ifnull(PROCESSLIST_USER,''),'</td><td>',ifnull(PROCESSLIST_HOST,''),'</td><td>',ifnull(PROCESSLIST_DB,''),'</td><td>',PROCESSLIST_COMMAND,'</td><td>',PROCESSLIST_TIME,'</td><td>',PROCESSLIST_STATE,'</td><td>',ifnull(PROCESSLIST_INFO,''),'</td><td>',PARENT_THREAD_ID,'</td><td>',ifnull(ROLE,''),'</td><td>',INSTRUMENTED,'</td><td>',HISTORY,'</td><td>',ifnull(CONNECTION_TYPE,''),'</td><td>',ifnull(THREAD_OS_ID,''),'</td></tr>') 
from (SELECT * FROM performance_schema.threads a where a.type!='BACKGROUND' and a.PROCESSLIST_COMMAND='Sleep'   order by a.PROCESSLIST_time desc limit 20) V

UNION ALL 
SELECT '</table>' 
;



select  '<a name="process_use"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 有多少线程正在使用表</b></font>';

select  '</br><textarea style="width:600px;font-family:Consolas;font-size:11px;overflow:auto;background-color:#FFFFCC" rows="5">';

show open tables where in_use > 0;

select  '</textarea>';




select  '<a name="Innodb_running"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查询InnoDB存储引擎的运行时信息，包括死锁的详细信息</b></font>';
select  '</br><textarea style="width:800px;font-family:Consolas;font-size:11px;overflow:auto;background-color:#FFFFCC" rows="20">';

show engine innodb status \G

select  '</textarea>';




select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查看当前状态产生的InnoDB锁，仅在有锁等待时有结果输出</b></font>';

-- 锁在MySQL 8.0中的变为
-- innodb_locks表在8.0.13版本中由performance_schema.data_locks表所代替，innodb_lock_waits表则由performance_schema.data_lock_waits表代替。
-- select * from performance_schema.data_locks;
-- select * from performance_schema.data_lock_waits;
/*

SELECT '<table border=1><tr><th>lock_id</th><th>lock_trx_id</th><th>lock_mode</th><th>lock_type</th><th>lock_table</th><th>lock_index</th><th>lock_space</th><th>lock_page</th><th>lock_rec</th><th>lock_data</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',lock_id,'</td><td>',lock_trx_id,'</td><td>',lock_mode,'</td><td>',lock_type,'</td><td>',lock_table,'</td><td>',lock_index,'</td><td>',lock_space,'</td><td>',lock_page,'</td><td>',lock_rec,'</td><td>',lock_data,'</td></tr>') 
from (select * from information_schema.innodb_locks) V
*/
SELECT '<TABLE border=1><tr><th>ENGINE_LOCK_ID</th><th>THREAD_ID</th><th>LOCK_MODE</th><th>LOCK_TYPE</th><th>OBJECT_NAME</th><th>INDEX_NAME</th><th>PARTITION_NAME</th><th>LOCK_STATUS</th><th>lock_data</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',ENGINE_LOCK_ID,'</td><td>',THREAD_ID,'</td><td>',LOCK_MODE,'</td><td>',LOCK_TYPE,'</td><td>',OBJECT_NAME,'</td><td>',INDEX_NAME,'</td><td>',PARTITION_NAME,'</td><td>',LOCK_STATUS,'</td><td>',LOCK_DATA,'</td></tr>') 
from (select * from performance_schema.data_locks) V


UNION ALL 
SELECT '</table>' 
;



select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查看当前状态产生的InnoDB锁等待，仅在有锁等待时有结果输出</b></font>';

SELECT '<table border=1><tr><th>REQUESTING_THREAD_ID</th><th>REQUESTING_ENGINE_LOCK_ID</th><th>BLOCKING_THREAD_ID</th><th>BLOCKING_ENGINE_LOCK_ID</th></tr>'

UNION ALL 
/*
SELECT concat('<tr><td>',requesting_trx_id,'</td><td>',requested_lock_id,'</td><td>',blocking_trx_id,'</td><td>',blocking_lock_id,'</td></tr>') 
from (select * from information_schema.innodb_lock_waits) V
*/

SELECT  concat('<tr><td>',REQUESTING_THREAD_ID,'</td><td>',REQUESTING_ENGINE_LOCK_ID,'</td><td>',BLOCKING_THREAD_ID,'</td><td>',BLOCKING_ENGINE_LOCK_ID,'</td></tr>') FROM performance_schema.data_lock_waits

UNION ALL 
SELECT '</table>' 
;


select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 当前Innodb内核中的当前活跃（active）事务 </b></font>';

SELECT '<table border=1><tr><th>trx_id</th><th>trx_state</th><th>trx_started</th><th>trx_requested_lock_id</th><th>trx_wait_started</th><th>trx_weight</th><th>trx_mysql_thread_id</th><th>trx_query</th><th>trx_operation_state</th><th>trx_tables_in_use</th><th>trx_tables_locked</th><th>trx_lock_structs</th><th>trx_lock_memory_bytes</th><th>trx_rows_locked</th><th>trx_rows_modified</th><th>trx_concurrency_tickets</th><th>trx_isolation_level</th><th>trx_unique_checks</th><th>trx_foreign_key_checks</th><th>trx_last_foreign_key_error</th><th>trx_adaptive_hash_latched</th><th>trx_adaptive_hash_timeout</th><th>trx_is_read_only</th><th>trx_autocommit_non_locking</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',trx_id,'</td><td>',trx_state,'</td><td>',trx_started,'</td><td>',trx_requested_lock_id,'</td><td>',trx_wait_started,'</td><td>',trx_weight,'</td><td>',trx_mysql_thread_id,'</td><td>',trx_query,'</td><td>',trx_operation_state,'</td><td>',trx_tables_in_use,'</td><td>',trx_tables_locked,'</td><td>',trx_lock_structs,'</td><td>',trx_lock_memory_bytes,'</td><td>',trx_rows_locked,'</td><td>',trx_rows_modified,'</td><td>',trx_concurrency_tickets,'</td><td>',trx_isolation_level,'</td><td>',trx_unique_checks,'</td><td>',trx_foreign_key_checks,'</td><td>',trx_last_foreign_key_error,'</td><td>',trx_adaptive_hash_latched,'</td><td>',trx_adaptive_hash_timeout,'</td><td>',trx_is_read_only,'</td><td>',trx_autocommit_non_locking,'</td></tr>') 
from (select * from information_schema.innodb_trx) V

UNION ALL 
SELECT '</table>' 
;


/*
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 锁详情 </b></font>';


SELECT '<table border=1><tr><th>trx_isolation_level</th><th>waiting_trx_id</th><th>waiting_trx_thread</th><th>waiting_trx_state</th><th>waiting_trx_lock_mode</th><th>waiting_trx_lock_type</th><th>waiting_trx_lock_table</th><th>waiting_trx_lock_index</th><th>waiting_trx_query</th><th>blocking_trx_id</th><th>blocking_trx_thread</th><th>blocking_trx_state</th><th>blocking_trx_lock_mode</th><th>blocking_trx_lock_type</th><th>blocking_trx_lock_table</th><th>blocking_trx_lock_index</th><th>blocking_query</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',trx_isolation_level,'</td><td>',waiting_trx_id,'</td><td>',waiting_trx_thread,'</td><td>',waiting_trx_state,'</td><td>',waiting_trx_lock_mode,'</td><td>',waiting_trx_lock_type,'</td><td>',waiting_trx_lock_table,'</td><td>',waiting_trx_lock_index,'</td><td>',waiting_trx_query,'</td><td>',blocking_trx_id,'</td><td>',blocking_trx_thread,'</td><td>',blocking_trx_state,'</td><td>',blocking_trx_lock_mode,'</td><td>',blocking_trx_lock_type,'</td><td>',blocking_trx_lock_table,'</td><td>',blocking_trx_lock_index,'</td><td>',blocking_query,'</td></tr>') 
from (select r.trx_isolation_level,
       r.trx_id              waiting_trx_id,
       r.trx_mysql_thread_id waiting_trx_thread,
       r.trx_state           waiting_trx_state,
       lr.lock_mode          waiting_trx_lock_mode,
       lr.lock_type          waiting_trx_lock_type,
       lr.lock_table         waiting_trx_lock_table,
       lr.lock_index         waiting_trx_lock_index,
       r.trx_query           waiting_trx_query,
       b.trx_id              blocking_trx_id,
       b.trx_mysql_thread_id blocking_trx_thread,
       b.trx_state           blocking_trx_state,
       lb.lock_mode          blocking_trx_lock_mode,
       lb.lock_type          blocking_trx_lock_type,
       lb.lock_table         blocking_trx_lock_table,
       lb.lock_index         blocking_trx_lock_index,
       b.trx_query           blocking_query
  from information_schema.innodb_lock_waits w
 inner join information_schema.innodb_trx b
    on b.trx_id = w.blocking_trx_id
 inner join information_schema.innodb_trx r
    on r.trx_id = w.requesting_trx_id
 inner join information_schema.innodb_locks lb
    on lb.lock_trx_id = w.blocking_trx_id
 inner join information_schema.innodb_locks lr
    on lr.lock_trx_id = w.requesting_trx_id) V


UNION ALL 
SELECT '</table>' 


;
*/

select  '<a name="mdl_info"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 元数据锁的相关信息 </b></font>';
-- 临时：UPDATE performance_schema.setup_instruments SET ENABLED = 'YES', TIMED = 'YES' WHERE NAME = 'wait/lock/metadata/sql/mdl';
-- 永久：[mysqld]performance-schema-instrument='wait/lock/metadata/sql/mdl=ON'

SELECT '<table border=1><tr><th>NAME</th><th>ENABLED</th><th>TIMED</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',NAME,'</td><td>',ENABLED,'</td><td>',TIMED,'</td></tr>') 
from (select * from performance_schema.setup_instruments WHERE name='wait/lock/metadata/sql/mdl') V

UNION ALL 
SELECT '</table>' 
;
/*
SELECT '<table border=1><tr><th>NAME</th><th>ENABLED</th><th>TIMED</th><th>PROPERTIES</th><th>VOLATILITY</th><th>DOCUMENTATION</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',NAME,'</td><td>',ENABLED,'</td><td>',TIMED,'</td><td>',PROPERTIES,'</td><td>',VOLATILITY,'</td><td>',IFNULL(DOCUMENTATION,''),'</td></tr>') 
from (select * from performance_schema.setup_instruments WHERE name='wait/lock/metadata/sql/mdl') V

UNION ALL 
SELECT '</table>' 
;
*/

select  '<p>';
-- 从5.7开始
SELECT '<table border=1><tr><th>locked_schema</th><th>locked_table</th><th>locked_type</th><th>waiting_processlist_id</th><th>waiting_age</th><th>waiting_query</th><th>waiting_state</th><th>blocking_processlist_id</th><th>blocking_age</th><th>blocking_query</th><th>sql_kill_blocking_connection</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',locked_schema,'</td><td>',locked_table,'</td><td>',locked_type,'</td><td>',waiting_processlist_id,'</td><td>',waiting_age,'</td><td>',waiting_query,'</td><td>',waiting_state,'</td><td>',blocking_processlist_id,'</td><td>',blocking_age,'</td><td>',blocking_query,'</td><td>',sql_kill_blocking_connection,'</td></tr>') 
from (SELECT
    locked_schema,
    locked_table,
    locked_type,
    waiting_processlist_id,
    waiting_age,
    waiting_query,
    waiting_state,
    blocking_processlist_id,
    blocking_age,
    substring_index(sql_text,"transaction_begin;" ,-1) AS blocking_query,
    sql_kill_blocking_connection
FROM
    (
        SELECT
            b.OWNER_THREAD_ID AS granted_thread_id,
            a.OBJECT_SCHEMA AS locked_schema,
            a.OBJECT_NAME AS locked_table,
            "Metadata Lock" AS locked_type,
            c.PROCESSLIST_ID AS waiting_processlist_id,
            c.PROCESSLIST_TIME AS waiting_age,
            c.PROCESSLIST_INFO AS waiting_query,
            c.PROCESSLIST_STATE AS waiting_state,
            d.PROCESSLIST_ID AS blocking_processlist_id,
            d.PROCESSLIST_TIME AS blocking_age,
            d.PROCESSLIST_INFO AS blocking_query,
            concat('KILL ', d.PROCESSLIST_ID) AS sql_kill_blocking_connection
        from performance_schema.metadata_locks a
        JOIN performance_schema.metadata_locks b 
		ON a.OBJECT_SCHEMA = b.OBJECT_SCHEMA
        AND a.OBJECT_NAME = b.OBJECT_NAME
        AND a.lock_status = 'PENDING'
        AND b.lock_status = 'GRANTED'
        AND a.OWNER_THREAD_ID <> b.OWNER_THREAD_ID
        AND a.lock_type = 'EXCLUSIVE'
        JOIN performance_schema.threads c ON a.OWNER_THREAD_ID = c.THREAD_ID
        JOIN performance_schema.threads d ON b.OWNER_THREAD_ID = d.THREAD_ID
    ) t1,
    (
        SELECT
            thread_id,
            group_concat(   CASE WHEN EVENT_NAME = 'statement/sql/begin' THEN "transaction_begin" ELSE sql_text END ORDER BY event_id SEPARATOR ";" ) AS sql_text
        FROM
            performance_schema.events_statements_history
        GROUP BY thread_id
    ) t2
WHERE
    t1.granted_thread_id = t2.thread_id) V

UNION ALL 
SELECT '</table>' 
;



select  '<p>';
-- 从5.7开始
SELECT '<table border=1><tr><th>locked_schema</th><th>locked_table</th><th>locked_type</th><th>waiting_processlist_id</th><th>waiting_age</th><th>waiting_query</th><th>waiting_state</th><th>blocking_processlist_id</th><th>blocking_age</th><th>blocking_query</th><th>sql_kill_blocking_connection</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',locked_schema,'</td><td>',locked_table,'</td><td>',locked_type,'</td><td>',waiting_processlist_id,'</td><td>',waiting_age,'</td><td>',waiting_query,'</td><td>',waiting_state,'</td><td>',blocking_processlist_id,'</td><td>',blocking_age,'</td><td>',blocking_query,'</td><td>',sql_kill_blocking_connection,'</td></tr>') 
from (SELECT
    a.OBJECT_SCHEMA AS locked_schema,
    a.OBJECT_NAME AS locked_table,
    "Metadata Lock" AS locked_type,
    c.PROCESSLIST_ID AS waiting_processlist_id,
    c.PROCESSLIST_TIME AS waiting_age,
    c.PROCESSLIST_INFO AS waiting_query,
    c.PROCESSLIST_STATE AS waiting_state,
    d.PROCESSLIST_ID AS blocking_processlist_id,
    d.PROCESSLIST_TIME AS blocking_age,
    d.PROCESSLIST_INFO AS blocking_query,
    concat('KILL ', d.PROCESSLIST_ID) AS sql_kill_blocking_connection
FROM
    performance_schema.metadata_locks a
JOIN performance_schema.metadata_locks b ON a.OBJECT_SCHEMA = b.OBJECT_SCHEMA
AND a.OBJECT_NAME = b.OBJECT_NAME
AND a.lock_status = 'PENDING'
AND b.lock_status = 'GRANTED'
AND a.OWNER_THREAD_ID <> b.OWNER_THREAD_ID
AND a.lock_type = 'EXCLUSIVE'
JOIN performance_schema.threads c ON a.OWNER_THREAD_ID = c.THREAD_ID
JOIN performance_schema.threads d ON b.OWNER_THREAD_ID = d.THREAD_ID) V

UNION ALL 
SELECT '</table>' 
;

select  '<p>';

SELECT '<table border=1><tr><th>thd_id</th><th>conn_id</th><th>user</th><th>db</th><th>command</th><th>state</th><th>time</th><th>current_statement</th><th>statement_latency</th><th>progress</th><th>lock_latency</th><th>rows_examined</th><th>rows_sent</th><th>rows_affected</th><th>tmp_tables</th><th>tmp_disk_tables</th><th>full_scan</th><th>last_statement</th><th>last_statement_latency</th><th>current_memory</th><th>last_wait</th><th>last_wait_latency</th><th>source</th><th>trx_latency</th><th>trx_state</th><th>trx_autocommit</th><th>pid</th><th>program_name</th><th>lock_summary</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',thd_id,'</td><td>',conn_id,'</td><td>',user,'</td><td>',db,'</td><td>',command,'</td><td>',state,'</td><td>',time,'</td><td>',current_statement,'</td><td>',statement_latency,'</td><td>',progress,'</td><td>',lock_latency,'</td><td>',rows_examined,'</td><td>',rows_sent,'</td><td>',rows_affected,'</td><td>',tmp_tables,'</td><td>',tmp_disk_tables,'</td><td>',full_scan,'</td><td>',last_statement,'</td><td>',last_statement_latency,'</td><td>',current_memory,'</td><td>',last_wait,'</td><td>',last_wait_latency,'</td><td>',source,'</td><td>',trx_latency,'</td><td>',trx_state,'</td><td>',trx_autocommit,'</td><td>',pid,'</td><td>',program_name,'</td><td>',lock_summary,'</td></tr>') 
from (SELECT ps.*,  lock_summary.lock_summary  FROM sys.processlist ps  INNER JOIN (SELECT owner_thread_id,  GROUP_CONCAT(  DISTINCT CONCAT(mdl.LOCK_STATUS, ' ', mdl.lock_type, ' on ', IF(mdl.object_type='USER LEVEL LOCK', CONCAT(mdl.object_name, ' (user lock)'), CONCAT(mdl.OBJECT_SCHEMA, '.', mdl.OBJECT_NAME)))  ORDER BY mdl.object_type ASC, mdl.LOCK_STATUS ASC, mdl.lock_type ASC  SEPARATOR '\n'  ) as lock_summary FROM performance_schema.metadata_locks mdl GROUP BY owner_thread_id) lock_summary ON (ps.thd_id=lock_summary.owner_thread_id)) V

UNION ALL 
SELECT '</table>'
;
 


select  '<p>';

SELECT '<table border=1><tr><th>object_schema</th><th>object_name</th><th>waiting_thread_id</th><th>waiting_pid</th><th>waiting_account</th><th>waiting_lock_type</th><th>waiting_lock_duration</th><th>waiting_query</th><th>waiting_query_secs</th><th>waiting_query_rows_affected</th><th>waiting_query_rows_examined</th><th>blocking_thread_id</th><th>blocking_pid</th><th>blocking_account</th><th>blocking_lock_type</th><th>blocking_lock_duration</th><th>sql_kill_blocking_query</th><th>sql_kill_blocking_connection</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',object_schema,'</td><td>',object_name,'</td><td>',waiting_thread_id,'</td><td>',waiting_pid,'</td><td>',waiting_account,'</td><td>',waiting_lock_type,'</td><td>',waiting_lock_duration,'</td><td>',waiting_query,'</td><td>',waiting_query_secs,'</td><td>',waiting_query_rows_affected,'</td><td>',waiting_query_rows_examined,'</td><td>',blocking_thread_id,'</td><td>',blocking_pid,'</td><td>',blocking_account,'</td><td>',blocking_lock_type,'</td><td>',blocking_lock_duration,'</td><td>',sql_kill_blocking_query,'</td><td>',sql_kill_blocking_connection,'</td></tr>') 
from (select * from sys.schema_table_lock_waits) V

UNION ALL 
SELECT '</table>';



select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查看服务器的状态</b></font>';
-- show status like '%lock%';
-- select  '</br><textarea style="width:600px;font-family:Consolas;font-size:11px;overflow:auto;background-color:#FFFFCC" -- rows="20">';
-- 
-- show status like '%lock%';
-- 
-- select  '</textarea>';


-- mysql 5.7
SELECT '<table border=1><tr><th>VARIABLE_NAME</th><th>VARIABLE_VALUE</th></tr>'
UNION ALL
SELECT concat('<tr><td>',VARIABLE_NAME,'</td><td>',VARIABLE_VALUE,'</td></tr>') 
from (select * from performance_schema.global_status where  VARIABLE_NAME  like '%lock%') V
UNION ALL 
SELECT '</table>'
;

/*
-- mysql 5.5和5.6和mariadb
SELECT '<table border=1><tr><th>VARIABLE_NAME</th><th>VARIABLE_VALUE</th></tr>'
UNION ALL
SELECT concat('<tr><td>',VARIABLE_NAME,'</td><td>',VARIABLE_VALUE,'</td></tr>') 
from (select * from INFORMATION_SCHEMA.global_status where  VARIABLE_NAME like '%lock%') V
UNION ALL 
SELECT '</table>'
;
*/

select  '<center>[<a class="noLink" href="#directory">回到目录</a>]</center><p>';
select  '<hr><p><p>';




-- +----------------------------------------------------------------------------+
-- |                           - SQL info -                                     |
-- +----------------------------------------------------------------------------+


select  '<a name="sql_info"></a>';
select  '<font size="+2" color="00CCFF"><b>SQL部分</b></font><hr align="left" width="800">';





select  '<a name="SQL_run_long"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 跟踪长时间操作的进度 </b></font>';

SELECT '<table border=1><tr><th>THREAD_ID</th><th>EVENT_ID</th><th>END_EVENT_ID</th><th>EVENT_NAME</th><th>SOURCE</th><th>TIMER_START</th><th>TIMER_END</th><th>TIMER_WAIT</th><th>WORK_COMPLETED</th><th>WORK_ESTIMATED</th><th>NESTING_EVENT_ID</th><th>NESTING_EVENT_TYPE</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',THREAD_ID,'</td><td>',EVENT_ID,'</td><td>',END_EVENT_ID,'</td><td>',EVENT_NAME,'</td><td>',SOURCE,'</td><td>',TIMER_START,'</td><td>',TIMER_END,'</td><td>',TIMER_WAIT,'</td><td>',WORK_COMPLETED,'</td><td>',WORK_ESTIMATED,'</td><td>',NESTING_EVENT_ID,'</td><td>',NESTING_EVENT_TYPE,'</td></tr>') 
from (select * from performance_schema.events_stages_current) V

UNION ALL 
SELECT '</table>' ;



select  '<a name="SQL_run_long_95"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查看平均执行时间值大于95%的平均执行时间的语句（可近似地认为是平均执行时间超长的语句），默认情况下按照语句平均延迟(执行时间)降序排序 </b></font>';



SELECT '<table border=1><tr><th>query</th><th>db</th><th>full_scan</th><th>exec_count</th><th>err_count</th><th>warn_count</th><th>total_latency</th><th>max_latency</th><th>avg_latency</th><th>rows_sent</th><th>rows_sent_avg</th><th>rows_examined</th><th>rows_examined_avg</th><th>first_seen</th><th>last_seen</th><th>digest</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',query,'</td><td>',ifnull(db,''),'</td><td>',full_scan,'</td><td>',exec_count,'</td><td>',err_count,'</td><td>',warn_count,'</td><td>',total_latency,'</td><td>',max_latency,'</td><td>',avg_latency,'</td><td>',rows_sent,'</td><td>',rows_sent_avg,'</td><td>',rows_examined,'</td><td>',rows_examined_avg,'</td><td>',first_seen,'</td><td>',last_seen,'</td><td>',digest,'</td></tr>') 
from (SELECT sys.format_statement(DIGEST_TEXT) AS query,
  SCHEMA_NAME as db,
  IF(SUM_NO_GOOD_INDEX_USED > 0 OR SUM_NO_INDEX_USED > 0, '*', '') AS full_scan,
  COUNT_STAR AS exec_count,
  SUM_ERRORS AS err_count,
  SUM_WARNINGS AS warn_count,
  sys.format_time(SUM_TIMER_WAIT) AS total_latency,
  sys.format_time(MAX_TIMER_WAIT) AS max_latency,
  sys.format_time(AVG_TIMER_WAIT) AS avg_latency,
  SUM_ROWS_SENT AS rows_sent,
  ROUND(IFNULL(SUM_ROWS_SENT / NULLIF(COUNT_STAR, 0), 0)) AS rows_sent_avg,
  SUM_ROWS_EXAMINED AS rows_examined,
  ROUND(IFNULL(SUM_ROWS_EXAMINED / NULLIF(COUNT_STAR, 0), 0)) AS rows_examined_avg,
  FIRST_SEEN AS first_seen,
  LAST_SEEN AS last_seen,
  DIGEST AS digest
FROM performance_schema.events_statements_summary_by_digest stmts
JOIN sys.x$ps_digest_95th_percentile_by_avg_us AS top_percentile
ON ROUND(stmts.avg_timer_wait/1000000) >= top_percentile.avg_us
ORDER BY AVG_TIMER_WAIT DESC limit 10) V

UNION ALL 
SELECT '</table>' 
;

select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查看当前正在执行的语句进度信息 </b></font>';


SELECT '<table border=1><tr><th>thd_id</th><th>conn_id</th><th>user</th><th>db</th><th>command</th><th>state</th><th>time</th><th>current_statement</th><th>statement_latency</th><th>progress</th><th>lock_latency</th><th>rows_examined</th><th>rows_sent</th><th>rows_affected</th><th>tmp_tables</th><th>tmp_disk_tables</th><th>full_scan</th><th>last_statement</th><th>last_statement_latency</th><th>current_memory</th><th>last_wait</th><th>last_wait_latency</th><th>source</th><th>trx_latency</th><th>trx_state</th><th>trx_autocommit</th><th>pid</th><th>program_name</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',thd_id,'</td><td>',conn_id,'</td><td>',user,'</td><td>',db,'</td><td>',command,'</td><td>',state,'</td><td>',time,'</td><td>',current_statement,'</td><td>',statement_latency,'</td><td>',progress,'</td><td>',lock_latency,'</td><td>',rows_examined,'</td><td>',rows_sent,'</td><td>',rows_affected,'</td><td>',tmp_tables,'</td><td>',tmp_disk_tables,'</td><td>',full_scan,'</td><td>',last_statement,'</td><td>',last_statement_latency,'</td><td>',current_memory,'</td><td>',last_wait,'</td><td>',last_wait_latency,'</td><td>',source,'</td><td>',trx_latency,'</td><td>',trx_state,'</td><td>',trx_autocommit,'</td><td>',pid,'</td><td>',program_name,'</td></tr>') from (select * from sys.session where conn_id!=connection_id() and trx_state='ACTIVE') V

UNION ALL 
SELECT '</table>' 
;



select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查看已经执行完的语句相关统计信息 </b></font>';

SELECT '<table border=1><tr><th>thd_id</th><th>conn_id</th><th>user</th><th>db</th><th>command</th><th>state</th><th>time</th><th>current_statement</th><th>statement_latency</th><th>progress</th><th>lock_latency</th><th>rows_examined</th><th>rows_sent</th><th>rows_affected</th><th>tmp_tables</th><th>tmp_disk_tables</th><th>full_scan</th><th>last_statement</th><th>last_statement_latency</th><th>current_memory</th><th>last_wait</th><th>last_wait_latency</th><th>source</th><th>trx_latency</th><th>trx_state</th><th>trx_autocommit</th><th>pid</th><th>program_name</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',thd_id,'</td><td>',conn_id,'</td><td>',user,'</td><td>',ifnull(db,''),'</td><td>',command,'</td><td>',ifnull(state,''),'</td><td>',time,'</td><td>',ifnull(current_statement,''),'</td><td>',ifnull(statement_latency,''),'</td><td>',ifnull(progress,''),'</td><td>',lock_latency,'</td><td>',rows_examined,'</td><td>',rows_sent,'</td><td>',rows_affected,'</td><td>',tmp_tables,'</td><td>',tmp_disk_tables,'</td><td>',full_scan,'</td><td>',last_statement,'</td><td>',last_statement_latency,'</td><td>',current_memory,'</td><td>',ifnull(last_wait,''),'</td><td>',ifnull(last_wait_latency,''),'</td><td>',ifnull(source,''),'</td><td>',trx_latency,'</td><td>',trx_state,'</td><td>',trx_autocommit,'</td><td>',pid,'</td><td>',ifnull(program_name,''),'</td></tr>') from (select * from sys.session where conn_id!=connection_id() and trx_state='COMMITTED') V

UNION ALL 
SELECT '</table>' 
;


select  '<a name="sql_info_tmp"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查看使用了临时表的语句，默认情况下按照磁盘临时表数量和内存临时表数量进行降序排序 </b></font>';
 
SELECT '<table border=1><tr><th>query</th><th>db</th><th>exec_count</th><th>total_latency</th><th>memory_tmp_tables</th><th>disk_tmp_tables</th><th>avg_tmp_tables_per_query</th><th>tmp_tables_to_disk_pct</th><th>first_seen</th><th>last_seen</th><th>digest</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',query,'</td><td>',ifnull(db,''),'</td><td>',exec_count,'</td><td>',total_latency,'</td><td>',memory_tmp_tables,'</td><td>',disk_tmp_tables,'</td><td>',avg_tmp_tables_per_query,'</td><td>',tmp_tables_to_disk_pct,'</td><td>',first_seen,'</td><td>',last_seen,'</td><td>',digest,'</td></tr>') 
from (SELECT sys.format_statement(DIGEST_TEXT) AS query,
  SCHEMA_NAME as db,
  COUNT_STAR AS exec_count,
  sys.format_time(SUM_TIMER_WAIT) as total_latency,
  SUM_CREATED_TMP_TABLES AS memory_tmp_tables,
  SUM_CREATED_TMP_DISK_TABLES AS disk_tmp_tables,
  ROUND(IFNULL(SUM_CREATED_TMP_TABLES / NULLIF(COUNT_STAR, 0), 0)) AS avg_tmp_tables_per_query,
  ROUND(IFNULL(SUM_CREATED_TMP_DISK_TABLES / NULLIF(SUM_CREATED_TMP_TABLES, 0), 0) * 100) AS tmp_tables_to_disk_pct,
  FIRST_SEEN as first_seen,
  LAST_SEEN as last_seen,
  DIGEST AS digest
FROM performance_schema.events_statements_summary_by_digest
WHERE SUM_CREATED_TMP_TABLES > 0
ORDER BY SUM_CREATED_TMP_DISK_TABLES DESC, SUM_CREATED_TMP_TABLES DESC limit 10) V

UNION ALL 
SELECT '</table>' 
;



select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 有临时表的前10条SQL语句</b></font>';

SELECT '<table border=1><tr><th>query</th><th>db</th><th>full_scan</th><th>exec_count</th><th>err_count</th><th>warn_count</th><th>total_latency</th><th>max_latency</th><th>avg_latency</th><th>lock_latency</th><th>rows_sent</th><th>rows_sent_avg</th><th>rows_examined</th><th>rows_examined_avg</th><th>rows_affected</th><th>rows_affected_avg</th><th>tmp_tables</th><th>tmp_disk_tables</th><th>rows_sorted</th><th>sort_merge_passes</th><th>digest</th><th>first_seen</th><th>last_seen</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',query,'</td><td>',ifnull(db,''),'</td><td>',full_scan,'</td><td>',exec_count,'</td><td>',err_count,'</td><td>',warn_count,'</td><td>',total_latency,'</td><td>',max_latency,'</td><td>',avg_latency,'</td><td>',lock_latency,'</td><td>',rows_sent,'</td><td>',rows_sent_avg,'</td><td>',rows_examined,'</td><td>',rows_examined_avg,'</td><td>',rows_affected,'</td><td>',rows_affected_avg,'</td><td>',tmp_tables,'</td><td>',tmp_disk_tables,'</td><td>',rows_sorted,'</td><td>',sort_merge_passes,'</td><td>',digest,'</td><td>',first_seen,'</td><td>',last_seen,'</td></tr>') 
from (SELECT * FROM sys.statement_analysis WHERE tmp_tables > 0 ORDER BY tmp_tables DESC LIMIT 10) V

UNION ALL 
SELECT '</table>' 
;



select  '<a name="sql_info_disk_sort"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查看执行了文件排序的语句，默认情况下按照语句总延迟时间（执行时间）降序排序 </b></font>';
 

SELECT '<table border=1><tr><th>query</th><th>db</th><th>exec_count</th><th>total_latency</th><th>sort_merge_passes</th><th>avg_sort_merges</th><th>sorts_using_scans</th><th>sort_using_range</th><th>rows_sorted</th><th>avg_rows_sorted</th><th>first_seen</th><th>last_seen</th><th>digest</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',query,'</td><td>',ifnull(db,''),'</td><td>',exec_count,'</td><td>',total_latency,'</td><td>',sort_merge_passes,'</td><td>',avg_sort_merges,'</td><td>',sorts_using_scans,'</td><td>',sort_using_range,'</td><td>',rows_sorted,'</td><td>',avg_rows_sorted,'</td><td>',first_seen,'</td><td>',last_seen,'</td><td>',digest,'</td></tr>') 
from (SELECT sys.format_statement(DIGEST_TEXT) AS query,
  SCHEMA_NAME db,
  COUNT_STAR AS exec_count,
  sys.format_time(SUM_TIMER_WAIT) AS total_latency,
  SUM_SORT_MERGE_PASSES AS sort_merge_passes,
  ROUND(IFNULL(SUM_SORT_MERGE_PASSES / NULLIF(COUNT_STAR, 0), 0)) AS avg_sort_merges,
  SUM_SORT_SCAN AS sorts_using_scans,
  SUM_SORT_RANGE AS sort_using_range,
  SUM_SORT_ROWS AS rows_sorted,
  ROUND(IFNULL(SUM_SORT_ROWS / NULLIF(COUNT_STAR, 0), 0)) AS avg_rows_sorted,
  FIRST_SEEN as first_seen,
  LAST_SEEN as last_seen,
  DIGEST AS digest
FROM performance_schema.events_statements_summary_by_digest
WHERE SUM_SORT_ROWS > 0
ORDER BY SUM_TIMER_WAIT DESC limit 10) V

UNION ALL 
SELECT '</table>' 
;


select  '<a name="sqL_cost_all"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查询SQL的整体消耗百分比 </b></font>';


SELECT '<table border=1><tr><th>state</th><th>total_r</th><th>pct_r</th><th>calls</th><th>r/call</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',state,'</td><td>',total_r,'</td><td>',pct_r,'</td><td>',calls,'</td><td>',`r/call`,'</td></tr>') from (select state,
       sum(duration) as total_r,
       round(100 * sum(duration) / (select sum(duration) from information_schema.profiling  where query_id = 1),2) as pct_r,
       count(*) as calls,
       sum(duration) / count(*) as "r/call"
  from information_schema.profiling
 where query_id = 1
 group by state
 order by total_r desc) V

UNION ALL 
SELECT '</table>' 
;





select  '<a name="sqL_exec_count_top10"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 执行次数Top10</b></font>';

SELECT '<table border=1><tr><th>query</th><th>db</th><th>full_scan</th><th>exec_count</th><th>err_count</th><th>warn_count</th><th>total_latency</th><th>max_latency</th><th>avg_latency</th><th>lock_latency</th><th>rows_sent</th><th>rows_sent_avg</th><th>rows_examined</th><th>rows_examined_avg</th><th>rows_affected</th><th>rows_affected_avg</th><th>tmp_tables</th><th>tmp_disk_tables</th><th>rows_sorted</th><th>sort_merge_passes</th><th>digest</th><th>first_seen</th><th>last_seen</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',query,'</td><td>',ifnull(db,''),'</td><td>',full_scan,'</td><td>',exec_count,'</td><td>',err_count,'</td><td>',warn_count,'</td><td>',total_latency,'</td><td>',max_latency,'</td><td>',avg_latency,'</td><td>',lock_latency,'</td><td>',rows_sent,'</td><td>',rows_sent_avg,'</td><td>',rows_examined,'</td><td>',rows_examined_avg,'</td><td>',rows_affected,'</td><td>',rows_affected_avg,'</td><td>',tmp_tables,'</td><td>',tmp_disk_tables,'</td><td>',rows_sorted,'</td><td>',sort_merge_passes,'</td><td>',digest,'</td><td>',first_seen,'</td><td>',last_seen,'</td></tr>') 
from (SELECT * FROM sys.statement_analysis WHERE full_scan = '*' order by exec_count desc limit 10) V

UNION ALL 
SELECT '</table>' 
;




select  '<a name="sqL_full_scan"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 使用全表扫描的SQL语句</b></font>';

SELECT '<table border=1><tr><th>object_schema</th><th>object_name</th><th>rows_full_scanned</th><th>latency</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',object_schema,'</td><td>',object_name,'</td><td>',rows_full_scanned,'</td><td>',latency,'</td></tr>') from (SELECT object_schema,
  object_name, -- 表名
  count_read AS rows_full_scanned,  -- 全表扫描的总数据行数
  sys.format_time(sum_timer_wait) AS latency -- 完整的表扫描操作的总延迟时间（执行时间）
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE index_name IS NULL
AND count_read > 0
ORDER BY count_read DESC limit 10) V

UNION ALL 
SELECT '</table>' 
;


select  '<a name="sql_no_best_index"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查看全表扫描或者没有使用到最优索引的语句（经过标准化转化的语句文本），默认情况下按照全表扫描次数与语句总次数百分比和语句总延迟时间(执行时间)降序排序 </b></font>';



SELECT '<table border=1><tr><th>query</th><th>db</th><th>exec_count</th><th>total_latency</th><th>no_index_used_count</th><th>no_good_index_used_count</th><th>no_index_used_pct</th><th>rows_sent</th><th>rows_examined</th><th>rows_sent_avg</th><th>rows_examined_avg</th><th>first_seen</th><th>last_seen</th><th>digest</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',query,'</td><td>',ifnull(db,''),'</td><td>',exec_count,'</td><td>',total_latency,'</td><td>',no_index_used_count,'</td><td>',no_good_index_used_count,'</td><td>',no_index_used_pct,'</td><td>',rows_sent,'</td><td>',rows_examined,'</td><td>',rows_sent_avg,'</td><td>',rows_examined_avg,'</td><td>',first_seen,'</td><td>',last_seen,'</td><td>',digest,'</td></tr>') 
from (SELECT sys.format_statement(DIGEST_TEXT) AS query,
  SCHEMA_NAME as db,
  COUNT_STAR AS exec_count,
  sys.format_time(SUM_TIMER_WAIT) AS total_latency,
  SUM_NO_INDEX_USED AS no_index_used_count,
  SUM_NO_GOOD_INDEX_USED AS no_good_index_used_count,
  ROUND(IFNULL(SUM_NO_INDEX_USED / NULLIF(COUNT_STAR, 0), 0) * 100) AS no_index_used_pct,
  SUM_ROWS_SENT AS rows_sent,
  SUM_ROWS_EXAMINED AS rows_examined,
  ROUND(SUM_ROWS_SENT/COUNT_STAR) AS rows_sent_avg,
  ROUND(SUM_ROWS_EXAMINED/COUNT_STAR) AS rows_examined_avg,
  FIRST_SEEN as first_seen,
  LAST_SEEN as last_seen,
  DIGEST AS digest
FROM performance_schema.events_statements_summary_by_digest
WHERE (SUM_NO_INDEX_USED > 0
OR SUM_NO_GOOD_INDEX_USED > 0)
AND DIGEST_TEXT NOT LIKE 'SHOW%'
ORDER BY no_index_used_pct DESC, total_latency DESC limit 10) V

UNION ALL 
SELECT '</table>' 
;



select  '<a name="sql_error_worings"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 查看产生错误或警告的语句，默认情况下，按照错误数量和警告数量降序排序 </b></font>';



SELECT '<table border=1><tr><th>query</th><th>db</th><th>exec_count</th><th>errors</th><th>error_pct</th><th>warnings</th><th>warning_pct</th><th>first_seen</th><th>last_seen</th><th>digest</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',query,'</td><td>',ifnull(db,''),'</td><td>',exec_count,'</td><td>',errors,'</td><td>',error_pct,'</td><td>',warnings,'</td><td>',warning_pct,'</td><td>',first_seen,'</td><td>',last_seen,'</td><td>',digest,'</td></tr>') 
from (SELECT sys.format_statement(DIGEST_TEXT) AS query,
  SCHEMA_NAME as db,
  COUNT_STAR AS exec_count,
  SUM_ERRORS AS errors,
  IFNULL(SUM_ERRORS / NULLIF(COUNT_STAR, 0), 0) * 100 as error_pct,
  SUM_WARNINGS AS warnings,
  IFNULL(SUM_WARNINGS / NULLIF(COUNT_STAR, 0), 0) * 100 as warning_pct,
  FIRST_SEEN as first_seen,
  LAST_SEEN as last_seen,
  DIGEST AS digest
FROM performance_schema.events_statements_summary_by_digest
WHERE SUM_ERRORS > 0
OR SUM_WARNINGS > 0
ORDER BY SUM_ERRORS DESC, SUM_WARNINGS DESC limit 10) V

UNION ALL 
SELECT '</table>' ;



select  '<center>[<a class="noLink" href="#directory">回到目录</a>]</center><p>';
select  '<hr><p><p>';




-- +----------------------------------------------------------------------------+
-- |                           - Index info -                                   |
-- +----------------------------------------------------------------------------+



select  '<a name="index_info"></a>';
select  '<font size="+2" color="00CCFF"><b>索引部分</b></font><hr align="left" width="800">';





select  '<a name="sql_redundant_indexes"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 冗余索引</b></font>';
-- 若库很大，这个视图可能查询不出结果，可以摁一次“ctrl+c”跳过这个SQL
-- select * from sys.schema_redundant_indexes;




select  '<a name="sql_unused_indexes"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 无效索引（从未使用过的索引）</b></font>';

SELECT '<table border=1><tr><th>object_schema</th><th>object_name</th><th>index_name</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',object_schema,'</td><td>',object_name,'</td><td>',index_name,'</td></tr>') 
from (select * from sys.schema_unused_indexes) V

UNION ALL 
SELECT '</table>' 
;




select  '<a name="index_qfd"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 每张表的索引区分度（前100条）</b></font>';
select  '<p><font size="2px" face="Consolas">● 区分度越接近1，表示区分度越高；低于0.1，则说明区分度较差，开发者应该重新评估SQL语句涉及的字段，选择区分度高的多个字段创建索引</font>';



SELECT '<table border=1><tr><th>ASdb</th><th>AStable</th><th>ASindex_name</th><th>AScols</th><th>ASdefferRows</th><th>ASROWS</th><th>sel_persent</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',ASdb,'</td><td>',AStable,'</td><td>',ASindex_name,'</td><td>',AScols,'</td><td>',ASdefferRows,'</td><td>',ASROWS,'</td><td>',sel_persent,'</td></tr>') from (SELECT 
i.database_name ASdb, 
i.table_name AStable, 
i.index_name ASindex_name, 
i.stat_description AScols, 
i.stat_value ASdefferRows, 
t.n_rows ASROWS, 
ROUND(((i.stat_value / IFNULL(IF(t.n_rows < i.stat_value,i.stat_value,t.n_rows),0.01))),2) AS sel_persent 
FROM mysql.innodb_index_stats i 
INNER JOIN mysql.innodb_table_stats t 
ON i.database_name = t.database_name AND i.table_name= t.table_name 
WHERE i.index_name != 'PRIMARY' AND i.stat_name LIKE '%n_diff_pfx%'
and ROUND(((i.stat_value / IFNULL(IF(t.n_rows < i.stat_value,i.stat_value,t.n_rows),0.01))),2)<0.1
and t.n_rows !=0
and i.stat_value !=0
and i.database_name not in ('mysql', 'information_schema', 'sys', 'performance_schema')
limit 100) V

UNION ALL 
SELECT '</table>' ;


select  '<center>[<a class="noLink" href="#directory">回到目录</a>]</center><p>';
select  '<hr><p><p>';







-- +----------------------------------------------------------------------------+
-- |                           - MySQL Replication -                            |
-- +----------------------------------------------------------------------------+


select  '<a name="slave_info"></a>';
select  '<font size="+2" color="00CCFF"><b>主从情况</b></font><hr align="left" width="800">';




select  '<a name="SLAVE_IMPORTANT_INIT"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 主从复制涉及到的重要参数 </b></font>';
-- select  '</br><textarea style="width:600px;font-family:Consolas;font-size:11px;overflow:auto;background-color:#FFFFCC" rows="20">';
-- 
-- show global VARIABLES where  VARIABLE_NAME in  ('server_id','server_uuid','log_bin','log_bin_basename','sql_log_bin','log_bin_index','log_slave_updates','read_only','slave_skip_errors','max_allowed_packet','slave_max_allowed_packet','auto_increment_increment','auto_increment_offset','sync_binlog','binlog_format','expire_logs_days','max_binlog_size','slave_skip_errors','sql_slave_skip_counter','slave_exec_mode','rpl_semi_sync_master_enabled','rpl_semi_sync_master_timeout','rpl_semi_sync_master_trace_level','rpl_semi_sync_master_wait_for_slave_count','rpl_semi_sync_master_wait_no_slave','rpl_semi_sync_master_wait_point','rpl_semi_sync_slave_enabled','rpl_semi_sync_slave_trace_level') ;
-- 
-- select  '</textarea>';

-- mysql 5.7
SELECT '<table border=1><tr><th>VARIABLE_NAME</th><th>VARIABLE_VALUE</th></tr>'
UNION ALL
SELECT concat('<tr><td>',VARIABLE_NAME,'</td><td>',VARIABLE_VALUE,'</td></tr>') 
from (select * from performance_schema.global_variables where  VARIABLE_NAME  in ( 'server_id','server_uuid','log_bin','log_bin_basename','sql_log_bin','log_bin_index','log_slave_updates','read_only','slave_skip_errors','max_allowed_packet','slave_max_allowed_packet','auto_increment_increment','auto_increment_offset','sync_binlog','binlog_format','expire_logs_days','max_binlog_size','slave_skip_errors','sql_slave_skip_counter','slave_exec_mode','rpl_semi_sync_master_enabled','rpl_semi_sync_master_timeout','rpl_semi_sync_master_trace_level','rpl_semi_sync_master_wait_for_slave_count','rpl_semi_sync_master_wait_no_slave','rpl_semi_sync_master_wait_point','rpl_semi_sync_slave_enabled','rpl_semi_sync_slave_trace_level')) V
UNION ALL 
SELECT '</table>'
;


/*
-- mysql 5.5和5.6和mariadb
SELECT '<table border=1><tr><th>VARIABLE_NAME</th><th>VARIABLE_VALUE</th></tr>'
UNION ALL
SELECT concat('<tr><td>',VARIABLE_NAME,'</td><td>',VARIABLE_VALUE,'</td></tr>') 
from (select * from INFORMATION_SCHEMA.global_variables where  VARIABLE_NAME  in ( 'server_id','server_uuid','log_bin','log_bin_basename','sql_log_bin','log_bin_index','log_slave_updates','read_only','slave_skip_errors','max_allowed_packet','slave_max_allowed_packet','auto_increment_increment','auto_increment_offset','sync_binlog','binlog_format','expire_logs_days','max_binlog_size','slave_skip_errors','sql_slave_skip_counter','slave_exec_mode','rpl_semi_sync_master_enabled','rpl_semi_sync_master_timeout','rpl_semi_sync_master_trace_level','rpl_semi_sync_master_wait_for_slave_count','rpl_semi_sync_master_wait_no_slave','rpl_semi_sync_master_wait_point','rpl_semi_sync_slave_enabled','rpl_semi_sync_slave_trace_level')) V
UNION ALL 
SELECT '</table>'
;
*/





-- 分别在主从安装插件
-- 主： INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';
-- 从： INSTALL PLUGIN rpl_semi_sync_slave SONAME 'semisync_slave.so';

select  '<a name="db_rpl_semi_stats"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 半同步参数统计</b></font>';


-- select  '</br><textarea style="width:600px;font-family:Consolas;font-size:11px;overflow:auto;background-color:#FFFFCC" rows="20">';
-- 
-- show global status like 'rpl_semi%';
-- 
-- select  '</textarea>'; 

-- mysql 5.7
SELECT '<table border=1><tr><th>VARIABLE_NAME</th><th>VARIABLE_VALUE</th></tr>'
UNION ALL
SELECT concat('<tr><td>',VARIABLE_NAME,'</td><td>',VARIABLE_VALUE,'</td></tr>') 
from (select * from performance_schema.global_status where  VARIABLE_NAME  like 'rpl_semi%') V
UNION ALL 
SELECT '</table>'
;

/*
-- mysql 5.5和5.6和mariadb
SELECT '<table border=1><tr><th>VARIABLE_NAME</th><th>VARIABLE_VALUE</th></tr>'
UNION ALL
SELECT concat('<tr><td>',VARIABLE_NAME,'</td><td>',VARIABLE_VALUE,'</td></tr>') 
from (select * from INFORMATION_SCHEMA.global_status where  VARIABLE_NAME like 'rpl_semi%') V
UNION ALL 
SELECT '</table>'
;

*/


select  '<a name="slave_processlist"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 主从库线程</b></font>';
-- show full processlist;
-- SELECT * FROM information_schema.`PROCESSLIST`;

SELECT '<table border=1><tr><th>THREAD_ID</th><th>NAME</th><th>TYPE</th><th>PROCESSLIST_ID</th><th>PROCESSLIST_USER</th><th>PROCESSLIST_HOST</th><th>PROCESSLIST_DB</th><th>PROCESSLIST_COMMAND</th><th>PROCESSLIST_TIME</th><th>PROCESSLIST_STATE</th><th>PROCESSLIST_INFO</th><th>PARENT_THREAD_ID</th><th>ROLE</th><th>INSTRUMENTED</th><th>HISTORY</th><th>CONNECTION_TYPE</th><th>THREAD_OS_ID</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',THREAD_ID,'</td><td>',NAME,'</td><td>',TYPE,'</td><td>',PROCESSLIST_ID,'</td><td>',PROCESSLIST_USER,'</td><td>',PROCESSLIST_HOST,'</td><td>',ifnull(PROCESSLIST_DB,''),'</td><td>',PROCESSLIST_COMMAND,'</td><td>',PROCESSLIST_TIME,'</td><td>',PROCESSLIST_STATE,'</td><td>',ifnull(PROCESSLIST_INFO,''),'</td><td>',ifnull(PARENT_THREAD_ID,''),'</td><td>',ifnull(ROLE,''),'</td><td>',INSTRUMENTED,'</td><td>',HISTORY,'</td><td>',ifnull(CONNECTION_TYPE,''),'</td><td>',THREAD_OS_ID,'</td></tr>') from 
(SELECT *
FROM performance_schema.threads a 
WHERE a.`NAME` IN ( 'thread/sql/slave_IO', 'thread/sql/slave_sql','thread/sql/slave_worker'
                   ,'thread/sql/replica_io','thread/sql/replica_sql','thread/sql/replica_worker' ) 
 or a.PROCESSLIST_COMMAND in ('Binlog Dump','Binlog Dump GTID') ) V

UNION ALL 
SELECT '</table>' 
;




select  '<p>';

SELECT '<table border=1><tr><th>ID</th><th>USER</th><th>HOST</th><th>DB</th><th>COMMAND</th><th>TIME</th><th>STATE</th><th>INFO</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',ID,'</td><td>',USER,'</td><td>',HOST,'</td><td>',ifnull(DB,''),'</td><td>',COMMAND,'</td><td>',TIME,'</td><td>',STATE,'</td><td>',ifnull(INFO,''),'</td></tr>') 
from (SELECT * FROM information_schema.`PROCESSLIST` a where a.USER='system user' or a.command in ('Binlog Dump','Binlog Dump GTID') ) V

UNION ALL 
SELECT '</table>' 
;



select  '<a name="binary_bin_log"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 二进制日志</b></font>';



select  '<TABLE BORDER=1><tr><td style="background:#FFFFCC;font-family:Consolas; word-wrap: break-word; white-space: pre-wrap; white-space: -moz-pre-wrap">';

show binary logs; -- show master logs;


select  '</TD></TR></TABLE>';


select  '<a name="master_info_status"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 主库端查看所有从库</b></font>';

select  '</br><textarea style="width:600px;font-family:Consolas;font-size:11px;overflow:auto;background-color:#FFFFCC" rows="20">';

show slave hosts \G

select  '</textarea>';




select  '<a name="master_info_status"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● MGR详情</b></font>';

SELECT '<table border=1><tr><th>CHANNEL_NAME</th><th>MEMBER_ID</th><th>MEMBER_HOST</th><th>MEMBER_PORT</th><th>MEMBER_STATE</th><th>MEMBER_ROLE</th><th>MEMBER_VERSION</th><th>MEMBER_COMMUNICATION_STACK</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',CHANNEL_NAME,'</td><td>',MEMBER_ID,'</td><td>',MEMBER_HOST,'</td><td>',MEMBER_PORT,'</td><td>',MEMBER_STATE,'</td></tr>') 
from (SELECT * FROM performance_schema.replication_group_members) V

UNION ALL 
SELECT '</table>' 
;
/*
SELECT '<table border=1><tr><th>CHANNEL_NAME</th><th>MEMBER_ID</th><th>MEMBER_HOST</th><th>MEMBER_PORT</th><th>MEMBER_STATE</th><th>MEMBER_ROLE</th><th>MEMBER_VERSION</th><th>MEMBER_COMMUNICATION_STACK</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',CHANNEL_NAME,'</td><td>',MEMBER_ID,'</td><td>',MEMBER_HOST,'</td><td>',MEMBER_PORT,'</td><td>',MEMBER_STATE,'</td><td>',MEMBER_ROLE,'</td><td>',MEMBER_VERSION,'</td><td>',MEMBER_COMMUNICATION_STACK,'</td></tr>') 
from (SELECT * FROM performance_schema.replication_group_members) V

UNION ALL 
SELECT '</table>' 
;
*/


select  '<a name="master_info_status"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 主库状态监测</b></font>';

select  '</br><textarea style="width:600px;font-family:Consolas;font-size:11px;overflow:auto;background-color:#FFFFCC" rows="20">';

show master status \G

select  '</textarea>';



select  '<a name="slave_info_status"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 从库状态监测（需要在从库执行才有数据）</b></font>';

select  '</br><textarea style="width:800px;font-family:Consolas;font-size:11px;overflow:auto;background-color:#FFFFCC" rows="40">';

show slave status \G

select  '</textarea>';

select  '<p><b>● 从库状态查询</b></font>';
select  '<p>';
SELECT '<table border=1><tr><th>CHANNEL_NAME</th><th>HOST</th><th>PORT</th><th>USER</th><th>CONNECTION_RETRY_COUNT</th><th>CONNECTION_RETRY_INTERVAL</th><th>SOURCE_UUID</th><th>THREAD_ID</th><th>SERVICE_STATE</th><th>COUNT_RECEIVED_HEARTBEATS</th><th>LAST_HEARTBEAT_TIMESTAMP</th><th>LAST_ERROR_NUMBER</th><th>LAST_ERROR_MESSAGE</th><th>LAST_ERROR_TIMESTAMP</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',CHANNEL_NAME,'</td><td>',HOST,'</td><td>',PORT,'</td><td>',USER,'</td><td>',CONNECTION_RETRY_COUNT,'</td><td>',CONNECTION_RETRY_INTERVAL,'</td><td>',SOURCE_UUID,'</td><td>',THREAD_ID,'</td><td>',SERVICE_STATE,'</td><td>',COUNT_RECEIVED_HEARTBEATS,'</td><td>',LAST_HEARTBEAT_TIMESTAMP,'</td><td>',LAST_ERROR_NUMBER,'</td><td>',LAST_ERROR_MESSAGE,'</td><td>',LAST_ERROR_TIMESTAMP,'</td></tr>') from 
(select rcc.CHANNEL_NAME,rcc.`HOST`,rcc.`PORT`,rcc.`USER`,rcc.CONNECTION_RETRY_COUNT,rcc.CONNECTION_RETRY_INTERVAL,
rcs.SOURCE_UUID,rcs.THREAD_ID,rcs.SERVICE_STATE,rcs.COUNT_RECEIVED_HEARTBEATS,rcs.LAST_HEARTBEAT_TIMESTAMP,rcs.LAST_ERROR_NUMBER,rcs.LAST_ERROR_MESSAGE,rcs.LAST_ERROR_TIMESTAMP
from performance_schema.replication_connection_configuration rcc, 
     performance_schema.replication_connection_status rcs
where rcc.CHANNEL_NAME=rcs.CHANNEL_NAME) V

UNION ALL 
SELECT '</table>' 
;



-- MySQL 8.0才有
/*
-- 可选（只有MySQL 8.0才有） -- 我们未安装这两个插件
-- INSTALL PLUGIN group_replication SONAME 'group_replication.so';
-- INSTALL PLUGIN clone SONAME 'mysql_clone.so';

select  '<a name="master_info_status"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 克隆进度和状态</b></font>';

SELECT '<table border=1><tr><th>ID</th><th>PID</th><th>STATE</th><th>BEGIN_TIME</th><th>END_TIME</th><th>SOURCE</th><th>DESTINATION</th><th>ERROR_NO</th><th>ERROR_MESSAGE</th><th>BINLOG_FILE</th><th>BINLOG_POSITION</th><th>GTID_EXECUTED</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',ID,'</td><td>',PID,'</td><td>',STATE,'</td><td>',BEGIN_TIME,'</td><td>',END_TIME,'</td><td>',SOURCE,'</td><td>',DESTINATION,'</td><td>',ERROR_NO,'</td><td>',ERROR_MESSAGE,'</td><td>',BINLOG_FILE,'</td><td>',BINLOG_POSITION,'</td><td>',GTID_EXECUTED,'</td></tr>') 
from (SELECT * FROM performance_schema.clone_status ) V

UNION ALL 
SELECT '</table>'
;

select  '<p>';
SELECT '<table border=1><tr><th>stage</th><th>state</th><th>START TIME</th><th>FINISH TIME</th><th>DURATION</th><th>Estimate</th><th>Done(%)</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',stage,'</td><td>',state,'</td><td>',`START TIME`,'</td><td>',`FINISH TIME`,'</td><td>',DURATION,'</td><td>',Estimate,'</td><td>',`Done(%)`,'</td></tr>') 
from (select
stage,
state,
cast(begin_time as DATETIME) as "START TIME",
cast(end_time as DATETIME) as "FINISH TIME",
lpad(sys.format_time(power(10,12) * (unix_timestamp(end_time) - unix_timestamp(begin_time))), 10, ' ') as DURATION,
lpad(concat(format(round(estimate/1024/1024,0), 0), "MB"), 16, ' ') as "Estimate",
case when begin_time is NULL then LPAD('%0', 7, ' ')
when estimate > 0 then
lpad(concat(round(data*100/estimate, 0), "%"), 7, ' ')
when end_time is NULL then lpad('0%', 7, ' ')
else lpad('100%', 7, ' ')
end as "Done(%)"
from performance_schema.clone_progress) V

UNION ALL 
SELECT '</table>'
;


*/





-- select  '<a name="slave_event_info"></a>';
-- select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 二进制日志事件</b></font>';
-- show binlog events limit 2,60 ;
-- show binlog events in 'rhel6lhr-bin.000003';




select  '<center>[<a class="noLink" href="#directory">回到目录</a>]</center><p>';
select  '<hr><p><p>';




-- +----------------------------------------------------------------------------+
-- |                           - db performance info -                                   |
-- +----------------------------------------------------------------------------+



select  '<a name="db_performance_info"></a>';
select  '<font size="+2" color="00CCFF"><b>数据库性能</b></font><hr align="left" width="800">';




select  '<a name="db_per_config_stats"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 性能参数统计</b></font>';


-- select  '</br><textarea style="width:600px;font-family:Consolas;font-size:11px;overflow:auto;background-color:#FFFFCC" -- rows="20">';
-- 
-- show global status where  VARIABLE_NAME  in ( -- 'connections','uptime','com_select','com_insert','com_delete','slow_queries','Created_tmp_tables','Created_tmp_files',' Created_tmp_disk_tables','table_cache','Handler_read_rnd_next','Table_locks_immediate','Table_locks_waited','Open_files','Opened_tables','Sort_merge_passes','Sort_range','Sort_rows','Sort_scan');
-- 
-- select  '</textarea>'; 



-- mysql 5.7
SELECT '<table border=1><tr><th>VARIABLE_NAME</th><th>VARIABLE_VALUE</th></tr>'
UNION ALL
SELECT concat('<tr><td>',VARIABLE_NAME,'</td><td>',VARIABLE_VALUE,'</td></tr>') 
from (select * from performance_schema.global_status where  VARIABLE_NAME  in ( 'connections','uptime','com_select','com_insert','com_delete','slow_queries','Created_tmp_tables','Created_tmp_files','Created_tmp_disk_tables','table_cache','Handler_read_rnd_next','Table_locks_immediate','Table_locks_waited','Open_files','Opened_tables','Sort_merge_passes','Sort_range','Sort_rows','Sort_scan')) V
UNION ALL 
SELECT '</table>'
;

-- mysql 5.5和5.6和mariadb
SELECT '<table border=1><tr><th>VARIABLE_NAME</th><th>VARIABLE_VALUE</th></tr>'
UNION ALL
SELECT concat('<tr><td>',VARIABLE_NAME,'</td><td>',VARIABLE_VALUE,'</td></tr>') 
from (select * from INFORMATION_SCHEMA.global_status where  VARIABLE_NAME  in ( 'connections','uptime','com_select','com_insert','com_delete','slow_queries','Created_tmp_tables','Created_tmp_files','Created_tmp_disk_tables','table_cache','Handler_read_rnd_next','Table_locks_immediate','Table_locks_waited','Open_files','Opened_tables','Sort_merge_passes','Sort_range','Sort_rows','Sort_scan')) V
UNION ALL 
SELECT '</table>'
;



select  '<center>[<a class="noLink" href="#directory">回到目录</a>]</center><p>';
select  '<hr><p><p>';






-- +----------------------------------------------------------------------------+
-- |                           - others info -                                   |
-- +----------------------------------------------------------------------------+


select  '<a name="others_info"></a>';
select  '<font size="+2" color="00CCFF"><b>其它</b></font><hr align="left" width="800">';





select  '<a name="setup_consumers"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● setup_consumers</b></font>';


SELECT '<table border=1><tr><th>NAME</th><th>ENABLED</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',NAME,'</td><td>',ENABLED,'</td></tr>') 
from (SELECT * FROM performance_schema.setup_consumers) V

UNION ALL 
SELECT '</table>' 
;



select  '<a name="Auto_increment"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 自增ID的使用情况（前20条）</b></font>';


SELECT '<table border=1><tr><th>table_schema</th><th>table_name</th><th>engine</th><th>Auto_increment</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',table_schema,'</td><td>',table_name,'</td><td>',engine,'</td><td>',Auto_increment,'</td></tr>') 
from (SELECT table_schema,table_name,engine, Auto_increment
 FROM information_schema.tables a
 where TABLE_SCHEMA not in ('mysql', 'information_schema', 'sys', 'performance_schema')
 and  a.Auto_increment<>''
 order by a.AUTO_INCREMENT desc
limit 20 ) V

UNION ALL 
SELECT '</table>' 
;



select  '<a name="no_pk"></a>';
select  '<p><font size="+1" face="Consolas" color="#336699"><b>● 无主键或唯一键的表（前100条）</b></font>';


SELECT '<table border=1><tr><th>table_schema</th><th>table_name</th></tr>'

UNION ALL 
SELECT concat('<tr><td>',table_schema,'</td><td>',table_name,'</td></tr>') 
from (select table_schema, table_name
 from information_schema.tables
where table_type='BASE TABLE'
 and  (table_schema, table_name) not in ( select /*+ subquery(materialization) */ a.TABLE_SCHEMA,a.TABLE_NAME 
           from information_schema.TABLE_CONSTRAINTS a 
		   where a.CONSTRAINT_TYPE in ('PRIMARY KEY','UNIQUE')
		   and table_schema not in    ('mysql', 'information_schema', 'sys', 'performance_schema')	)
 AND table_schema not in  ('mysql', 'information_schema', 'sys', 'performance_schema')
limit 100 ) V

UNION ALL 
SELECT '</table>' ;

-- /*  
-- select table_schema, table_name
--  from information_schema.tables
-- where table_type='BASE TABLE'
-- and   (table_schema,table_name) not in (select /*+ subquery(materialization) */ table_schema, table_name
--                            from information_schema.columns
--                           where column_key in ( 'PRI','UNI') )
--   AND table_schema not in    ('mysql', 'information_schema', 'sys', 'performance_schema')
--   and table_schema not in    ('mysql', 'information_schema', 'sys', 'performance_schema')	
-- limit 100 ;
-- */
   


select  '<a name="html_bottom_link"></a>';
select  '<center>[<a class="noLink" href="#directory">回到目录</a>]</center><p>';
select  '<hr><p><p>';







quit



/*
SELECT 
     concat(replace(concat(
		 'SELECT ''<table border=1><tr><th>', 
     GROUP_CONCAT(concat(d.column_name,'</th><th>') ORDER BY d.ordinal_position Separator '') ,'lhrth',''''),'<th>lhrth','</tr>'),
		 char(10),char(13),'UNION ALL ',char(13),
		 (replace(concat(
		 'SELECT concat(''<tr><td>''', 
     GROUP_CONCAT(concat(',',d.column_name,',''</td><td>''') ORDER BY d.ordinal_position Separator ''),'lhrtd) from () V'),'<td>''lhrtd','</tr>''' )),
		 char(10),char(13),'UNION ALL ',char(13),
		 ('SELECT ''</table>''') ) as results
FROM information_schema.COLUMNS d
WHERE d.table_name='ABC';
*/


