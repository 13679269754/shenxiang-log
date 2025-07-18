CREATE database if not exists mysql_report;

CREATE TABLE if not exists mysql_report.`metric_report_format` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `metric_class` varchar(100) DEFAULT NULL COMMENT '指标归类,run_status:运行状态类，db_config:配置类 db_baseinfo:基础信息类 os_status:操作系统信息类 innodb_engine_status:存储引擎的状态',
  `metric_type` varchar(100) DEFAULT NULL COMMENT '指标名称',
  `source_type` varchar(100) NOT NULL DEFAULT 'db' COMMENT '数据源名称, db ,os',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `UPDATE_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间，但是请不要手动修改，此处用于与创建时间做校队',
  `create_user` varchar(50) DEFAULT NULL,
  `remark` varchar(100) DEFAULT NULL,
  `deleted` tinyint(1) DEFAULT '0' COMMENT '0 不删除，1 删除',
  `order_id` int DEFAULT NULL COMMENT '指标排序规则',
  `navigation_name` varchar(100) NOT NULL DEFAULT '' COMMENT '目录中的表格导航名称',
  PRIMARY KEY (`id`),
  KEY `idx_metric_report_format_metric_class_metric_type` (`metric_class`,`metric_type`)
) ENGINE=InnoDB AUTO_INCREMENT=140 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='指标归类';


INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('base_os_status', 'disk_status', 'os', '2024-05-09 11:11:50', '2024-06-26 20:04:34', NULL, 'disk_status', 0, 1, 'disk_status');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('base_os_status', 'base_os_status_value', 'os', '2024-05-09 11:11:50', '2024-06-26 20:04:34', NULL, 'base_os_status_value', 0, 1, 'base_os_status_value');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('base_os_status', 'memory_top_3', 'os', '2024-05-09 11:21:28', '2024-06-26 20:04:34', NULL, 'memory_top_3', 0, 1, 'memory_top_3');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'db_baseinfo', 'db', '2024-05-24 10:54:25', '2024-06-26 17:02:23', NULL, '数据库基本信息', 0, 20, 'all_db_and_size');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'plugin_info', 'db', '2024-05-24 11:04:49', '2024-06-26 18:18:54', NULL, '插件信息', 0, 2, '');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'db_size', 'db', '2024-05-24 11:13:37', '2024-06-26 17:02:23', NULL, '当前数据库实例的所有数据库及其容量大小', 0, 26, 'all_db_objects');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'db_object_count', 'db', '2024-05-24 16:07:09', '2024-06-26 17:02:23', NULL, '数据库对象', 0, 24, 'db_status');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'disk_top_10_table', 'db', '2024-05-24 16:07:09', '2024-06-26 17:02:23', NULL, '占用空间最大的前10张大表', 0, 15, 'top10_tb_size');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'disk_top_10_index', 'db', '2024-05-24 16:07:09', '2024-06-26 17:02:23', NULL, '占用空间最大的前10个索引', 0, 16, 'top10_tb_size');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'engine_table_count', 'db', '2024-05-24 16:07:09', '2024-06-26 17:02:23', NULL, '存储引擎和table的数量关系', 0, 13, 'all_engines');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'db_engine_table_count', 'db', '2024-05-24 16:07:09', '2024-06-26 17:02:23', NULL, '存储引擎和DB的数量关系', 0, 22, 'engines_db');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'innodb_tablespace', 'db', '2024-05-24 16:07:09', '2024-06-26 17:02:23', NULL, 'innodb系统表空间', 0, 11, 'innodb_tablespaces');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'db_user', 'db', '2024-05-24 16:07:09', '2024-06-26 17:02:23', NULL, '查询所有用户', 0, 28, 'ALL_USES');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'character_set', 'db', '2024-05-24 16:07:09', '2024-06-26 17:02:23', NULL, '查询MySQL支持的所有字符集', 0, 17, 'ALL_character_set');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'user_connect_current', 'db', '2024-05-24 16:07:10', '2024-06-26 17:02:23', NULL, '查看当前连接到数据库的用户和Host', 0, 3, 'IMPORTANT_INIT');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'connect_current', 'db', '2024-05-24 16:07:10', '2024-06-26 17:02:23', NULL, '查看每个host的当前连接数和总连接数', 0, 18, 'ALL_link_user_host');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'login_user_info', 'db', '2024-05-24 16:07:10', '2024-06-26 17:02:23', NULL, '按照登录用户+数据库+登录服务器查看登录信息', 0, 9, 'ALL_link_user_host_per');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'thread_no_sleep', 'db', '2024-05-24 16:07:10', '2024-06-26 17:02:23', NULL, '查询所有线程(排除sleep线程)', 0, 7, 'ALL_link_user_host_info');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_base_info', 'thread_no_sleep_detail', 'db', '2024-05-24 16:07:10', '2024-06-26 17:02:23', NULL, '查询所有线程_详细(排除sleep线程)', 0, 5, 'ALL_link_user_host_info');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('lOCK_INFO', 'thread_sleep_top_20', 'db', '2024-05-24 16:07:10', '2024-06-26 19:49:48', NULL, 'sleep线程TOP20', 0, 4, 'all_processlist');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('lOCK_INFO', 'thread_sleep_top_20_detail', 'db', '2024-05-24 16:07:10', '2024-06-26 19:49:48', NULL, 'sleep线程TOP20细节', 0, 6, 'all_processlist_sleep');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('lOCK_INFO', 'open_tables_in_use', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '有多少线程正在使用表', 0, 3, 'process_use');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('lOCK_INFO', 'innodb_status', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, 'InnoDB存储引擎的运行时信息', 0, 2, 'Innodb_running');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('lOCK_INFO', 'innodb_lock_current', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '产生的InnoDB锁', 0, 1, 'mdl_info');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('lOCK_INFO', 'innodb_lock_wait_current', 'db', '2024-05-28 17:43:14', '2024-06-26 18:17:43', NULL, '产生的InnoDB锁等待', 0, 1, '');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('lOCK_INFO', 'active_transcation', 'db', '2024-05-28 17:43:14', '2024-06-26 18:17:43', NULL, '当前Innodb内核中的当前活跃（active）事务', 0, 1, '');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('lOCK_INFO', 'matedata_lock_detail_01', 'db', '2024-05-28 17:43:14', '2024-06-26 18:17:43', NULL, '元数据锁的相关信息_enable', 0, 1, '');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('lOCK_INFO', 'matedata_lock_detail_02', 'db', '2024-05-28 17:43:14', '2024-06-26 18:17:43', NULL, '元数据锁的相关信息_events_statements', 0, 1, '');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('lOCK_INFO', 'matedata_lock_detail_03', 'db', '2024-05-28 17:43:14', '2024-06-26 18:17:43', NULL, '元数据锁的相关信息-metadata_locks', 0, 1, '');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('sql_info', 'db_global_status', 'db', '2024-05-28 17:43:14', '2024-06-26 18:17:48', NULL, '查看服务器的状态', 0, 1, '');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('sql_info', 'events_stages_current', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '跟踪长时间操作的进度', 0, 8, 'SQL_run_long');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('sql_info', 'run_time_more_then_95th', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '查看平均执行时间值大于95%的平均执行时间的语句', 0, 1, 'SQL_run_long_95');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('sql_info', 'active_thread_schedule', 'db', '2024-05-28 17:43:14', '2024-06-26 18:17:55', NULL, '查看当前正在执行的语句进度信息', 0, 1, '');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('sql_info', 'done_thread_message', 'db', '2024-05-28 17:43:14', '2024-06-26 18:17:55', NULL, '查看已经执行完的语句相关统计信息', 0, 1, '');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('sql_info', 'extra_temp_sql', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '临时表sql', 0, 4, 'sql_info_tmp');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('sql_info', 'extra_temp_sql_top_10', 'db', '2024-05-28 17:43:14', '2024-06-26 18:17:55', NULL, '有临时表的前10条SQL语句', 0, 1, '');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('sql_info', 'extra_filesort_sql', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '文件排序的sql', 0, 7, 'sql_info_disk_sort');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('sql_info', 'extra_filesort_sql_cast_percent', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '查询SQL的整体消耗百分比', 0, 6, 'sqL_cost_all');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('sql_info', 'extra_filesort_sql_top_10', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '执行次数Top10', 0, 5, 'sqL_exec_count_top10');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('sql_info', 'full_table_scan_sql', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '使用全表扫描的SQL语句', 0, 3, 'sqL_full_scan');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('sql_info', 'full_table_scan_sql_order', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '全表扫描或者没有使用到最优索引的语句', 0, 2, 'sql_no_best_index');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('sql_info', 'error_or_warning_sql_order', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '错误的语句', 0, 9, 'sql_error_worings');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('index_info', 'unused_index', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '未使用的索引', 0, 2, 'sql_unused_indexes');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('index_info', 'index_cardinary_per_table', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '每张表的索引区分度', 0, 1, 'index_qfd');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('slave_info', 'global_variables_for_repl', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '主从复制涉及到的重要参数', 0, 1, 'SLAVE_IMPORTANT_INIT');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('slave_info', 'semi_repl_variables', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '半同步参数统计', 0, 5, 'db_rpl_semi_stats');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('slave_info', 'repl_thread', 'db', '2024-05-28 17:43:14', '2024-06-26 18:18:00', NULL, '主从库线程-THREAD', 0, 1, '');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('slave_info', 'repl_process', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '主从库线程-PROCESS', 0, 3, 'slave_processlist');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('slave_info', 'replication_group_members', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '主库端查看所有从库', 0, 4, 'master_info_status');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('slave_info', 'master_status', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '主库状态监测', 0, 2, 'master_info_status');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('slave_info', 'slave_status', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '从库状态监测（需要在从库执行才有数据）', 0, 6, 'slave_info_status');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('slave_info', 'slave_status_detail', 'db', '2024-05-28 17:43:14', '2024-06-26 18:18:07', NULL, '从库状态查询', 0, 1, '');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('db_performance_info', 'performance_variables', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '性能参数统计', 0, 1, 'db_per_config_stats');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('others_info', 'setup_consumers', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, 'PREFORMANCE_ENABLED', 0, 3, 'setup_consumers');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('others_info', 'auto_increament_id_top_20', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '自增ID的使用情况（前20条）', 0, 1, 'Auto_increment');
INSERT INTO mysql_report.metric_report_format (metric_class, metric_type, source_type, create_time, UPDATE_time, create_user, remark, deleted, order_id, navigation_name) VALUES('others_info', 'no_primery_or_unque_key_top_100', 'db', '2024-05-28 17:43:14', '2024-06-26 17:02:23', NULL, '无主键或唯一键的表（前100条）', 0, 2, 'no_pk');


CREATE TABLE if not exists mysql_report.`navigation_table` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `navigation_1_level` varchar(100) NOT NULL DEFAULT '' COMMENT '目录中的表格导航名称-一级',
  `navigation_2_level` varchar(100) NOT NULL DEFAULT '' COMMENT '目录中的表格导航名称-二级',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `UPDATE_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_user` varchar(50) DEFAULT NULL,
  `remark` varchar(100) DEFAULT NULL,
  `deleted` tinyint(1) DEFAULT '0' COMMENT '0 不删除，1删除',
  `navigation_1_name` varchar(100) NOT NULL DEFAULT '' COMMENT '导航栏的一级标题的名称',
  `navigation_2_name` varchar(100) NOT NULL DEFAULT '' COMMENT '导航栏的二级标题的名称',
  `navigation_2_prompt` varchar(100) NOT NULL DEFAULT '' COMMENT '导航栏的二级标题浮窗提示',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=67 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='导航表结构表';

INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('db_base_info', 'all_db_and_size', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '总体概况', '数据库基本信息', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('db_base_info', 'all_db_objects', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '总体概况', '当前数据库实例的所有数据库及其容量大小', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('db_base_info', 'db_status', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '总体概况', '数据库对象', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('db_base_info', 'top10_tb_size', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '总体概况', '占用空间最大的前10张大表', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('db_base_info', 'top10_tb_size', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '总体概况', '占用空间最大的前10张大表', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('db_base_info', 'all_engines', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '总体概况', '存储引擎和table的数量关系', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('db_base_info', 'engines_db', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '总体概况', '存储引擎和DB的数量关系', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('db_base_info', 'innodb_tablespaces', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '总体概况', 'innodb系统表空间', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('db_base_info', 'ALL_USES', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '总体概况', '查询所有用户', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('db_base_info', 'ALL_character_set', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '总体概况', '查询MySQL支持的所有字符集', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('db_base_info', 'IMPORTANT_INIT', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '总体概况', '查看当前连接到数据库的用户和Host', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('db_base_info', 'ALL_link_user_host', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '总体概况', '查看每个host的当前连接数和总连接数', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('db_base_info', 'ALL_link_user_host_per', '2024-06-05 16:03:36', '2024-06-26 14:09:04', NULL, NULL, 0, '总体概况', '用户登录信息统计', '按照登录用户+数据库+登录服务器查看登录信息');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('db_base_info', 'ALL_link_user_host_info', '2024-06-05 16:03:36', '2024-06-26 15:42:38', NULL, NULL, 0, '总体概况', '查询所有线程', '查询所有线程(排除sleep线程)');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('lOCK_INFO', 'all_processlist', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '锁情况', 'sleep线程TOP20', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('lOCK_INFO', 'all_processlist_sleep', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '锁情况', 'sleep线程TOP20细节', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('lOCK_INFO', 'process_use', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '锁情况', '有多少线程正在使用表', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('lOCK_INFO', 'Innodb_running', '2024-06-05 16:03:36', '2024-06-06 17:07:07', NULL, NULL, 0, '锁情况', '查询InnoDB存储引擎的运行时信息', '查询InnoDB存储引擎的运行时信息，包括死锁的详细信息');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('lOCK_INFO', 'mdl_info', '2024-06-05 16:03:36', '2024-06-06 17:07:07', NULL, NULL, 0, '锁情况', '查看当前状态产生的InnoDB锁', '查看当前状态产生的InnoDB锁，仅在有锁等待时有结果输出');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('sql_info', 'SQL_run_long', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, 'SQL部分', '跟踪长时间操作的进度', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('sql_info', 'SQL_run_long_95', '2024-06-05 16:03:36', '2024-06-26 15:42:49', NULL, NULL, 0, 'SQL部分', '大于95%的平均执行时间的语句', '查看平均执行时间值大于95%的平均执行时间的语句（可近似地认为是平均执行时间超长的语句），默认情况下按照语句平均延迟(执行时间)降序排序
');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('sql_info', 'sql_info_tmp', '2024-06-05 16:03:36', '2024-06-06 17:07:07', NULL, NULL, 0, 'SQL部分', '查看使用了临时表的语句', '查看使用了临时表的语句，默认情况下按照磁盘临时表数量和内存临时表数量进行降序排序');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('sql_info', 'sql_info_disk_sort', '2024-06-05 16:03:36', '2024-06-06 17:07:07', NULL, NULL, 0, 'SQL部分', '查看执行了文件排序的语句', '查看执行了文件排序的语句，默认情况下按照语句总延迟时间（执行时间）降序排序');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('sql_info', 'sqL_cost_all', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, 'SQL部分', '查询SQL的整体消耗百分比', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('sql_info', 'sqL_exec_count_top10', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, 'SQL部分', '执行次数Top10', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('sql_info', 'sqL_full_scan', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, 'SQL部分', '使用全表扫描的SQL语句', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('sql_info', 'sql_no_best_index', '2024-06-05 16:03:36', '2024-06-06 17:07:07', NULL, NULL, 0, 'SQL部分', '查看全表扫描或者没有使用到最优索引的语句', '查看全表扫描或者没有使用到最优索引的语句（经过标准化转化的语句文本），默认情况下按照全表扫描次数与语句总次数百分比和语句总延迟时间(执行时间)降序排序');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('sql_info', 'sql_error_worings', '2024-06-05 16:03:36', '2024-06-06 17:07:07', NULL, NULL, 0, 'SQL部分', '查看产生错误或警告的语句', '查看产生错误或警告的语句，默认情况下，按照错误数量和警告数量降序排序');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('index_info', 'sql_unused_indexes', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '索引部分', '未使用的索引', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('index_info', 'index_qfd', '2024-06-05 16:03:36', '2024-06-06 17:07:07', NULL, NULL, 0, '索引部分', '每张表的索引区分度', '每张表的索引区分度（前100条 -区分度越接近1，表示区分度越高；低于0.1，则说明区分度较差 ）');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('slave_info', 'SLAVE_IMPORTANT_INIT', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '主从情况', '主从复制涉及到的重要参数', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('slave_info', 'db_rpl_semi_stats', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '主从情况', '半同步参数统计', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('slave_info', 'slave_processlist', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '主从情况', '主从库线程-PROCESS', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('slave_info', 'master_info_status', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '主从情况', '主库端查看所有从库', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('slave_info', 'master_info_status', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '主从情况', '主库端查看所有从库', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('slave_info', 'slave_info_status', '2024-06-05 16:03:36', '2024-06-26 15:43:01', NULL, NULL, 0, '主从情况', '从库状态监测', '从库状态监测（需要在从库执行才有数据）');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('db_performance_info', 'db_per_config_stats', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '数据库性能', '性能参数统计', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('others_info', 'Auto_increment', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '其他', '自增ID的使用情况（前20条）', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('others_info', 'no_pk', '2024-06-05 16:03:36', '2024-06-06 17:04:34', NULL, NULL, 0, '其他', '无主键或唯一键的表（前100条）', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('base_os_status', 'disk_status', '2024-06-26 20:07:48', '2024-06-26 20:07:48', NULL, NULL, 0, '操作系统', '磁盘使用情况', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('base_os_status', 'base_os_status_value', '2024-06-26 20:07:48', '2024-06-26 20:08:47', NULL, NULL, 0, '操作系统', 'cpu以及内存', '');
INSERT INTO mysql_report.navigation_table (navigation_1_level, navigation_2_level, create_time, UPDATE_time, create_user, remark, deleted, navigation_1_name, navigation_2_name, navigation_2_prompt) VALUES('base_os_status', 'memory_top_3', '2024-06-26 20:07:48', '2024-06-26 20:08:47', NULL, NULL, 0, '操作系统', '内存使用排序', '');


CREATE TABLE if not exists mysql_report.`os_query_result` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `host` varchar(50) NOT NULL COMMENT '数据库ip',
  `metric_name` varchar(50) DEFAULT NULL COMMENT '查询名称',
  `metric_type` varchar(100) DEFAULT 'db' COMMENT '指标类型,db：通过查询数据库获得,os：通过系统命令获得',
  `metric_value` mediumtext COMMENT '指标值',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `UPDATE_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间，但是请不要手动修改，此处用于与创建时间做校队',
  `create_user` varchar(50) DEFAULT NULL,
  `remark` varchar(100) DEFAULT NULL,
  `deleted` tinyint(1) DEFAULT '0' COMMENT '0 不删除，1删除',
  PRIMARY KEY (`id`),
  KEY `funcidx_os_query_result_metric_value_mount_host` (`host`,(cast(json_extract(`metric_value`,_utf8mb4'$.mount') as char(100) charset utf8mb4)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='os查询指标值';



CREATE TABLE  if not exists mysql_report.`report_os` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL COMMENT '查询名称',
  `runstat` varchar(100) DEFAULT NULL COMMENT '运行状态',
  `run` varchar(2000) DEFAULT NULL COMMENT '运行的query',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `UPDATE_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_user` varchar(50) DEFAULT NULL,
  `remark` varchar(100) DEFAULT NULL,
  `deleted` tinyint(1) DEFAULT '0' COMMENT '0 不删除，1删除',
  `skip_instance` varchar(100) DEFAULT NULL COMMENT '指定不需要执行这个查询的实例[ip:port,] '',''分割',
  `calculate_fun` varchar(100) DEFAULT NULL COMMENT '需要计算的指标 由于计算需要多条数据，第一次执行不进行运行 : 暂时定的方法有 预期:expect 最大值:max 最小值:min',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='os执行的查询';

INSERT INTO mysql_report.report_os (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, skip_instance, calculate_fun) VALUES('disk_status', '1', 'df -h | awk ''NR>1 {print "{ \\"mount\\": \\""$6"\\", \\"total\\": \\""$2"\\", \\"available\\": \\""$4"\\", \\"usage\\": \\""$5"\\" }" }''', '2024-05-09 11:02:05', '2024-05-30 09:29:31', NULL, NULL, 0, NULL, 'disk_handle');
INSERT INTO mysql_report.report_os (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, skip_instance, calculate_fun) VALUES('base_os_status_value', '1', 'echo "{ \\"value\\": \\"cpu_load:$(uptime | awk -F''load average: '' ''{print $2}'' | awk ''{print $2}'')\\" }" | sed ''s/,"/"/''', '2024-05-09 11:02:05', '2024-06-26 14:07:15', NULL, 'cpu_load', 0, NULL, NULL);
INSERT INTO mysql_report.report_os (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, skip_instance, calculate_fun) VALUES('base_os_status_value', '1', 'echo "{ \\"value\\": \\"cpu_usage:$(top -bn1 | grep ''Cpu(s)'' | sed ''s/.*, *\\([0-9.]*\\)%* id.*/\\1/'' | awk ''{print 100 - $1"%"}'')\\" }"
', '2024-05-09 11:02:05', '2024-06-26 13:56:19', NULL, 'cpu_usage', 0, NULL, NULL);
INSERT INTO mysql_report.report_os (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, skip_instance, calculate_fun) VALUES('base_os_status_value', '1', 'echo "{ \\"value\\": \\"memory_usage:$(free | grep Mem | awk ''{print $3/$2 * 100"%"}'')\\" }"', '2024-05-09 11:02:05', '2024-06-26 13:56:19', NULL, 'memory_usage', 0, NULL, NULL);
INSERT INTO mysql_report.report_os (NAME, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, skip_instance, calculate_fun) VALUES('memory_top_3', '1', 'ps aux --sort=-%mem | head -n 4 | awk ''NR>1 {print "{ \\"pid\\": \\""$2"\\", \\"command\\": \\""$11"\\", \\"mem_usage\\": \\""$4"\\" }"}''', '2024-05-09 11:02:05', '2024-05-28 18:00:02', NULL, NULL, 0, NULL, NULL);


CREATE TABLE if not exists mysql_report.`report_sql` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL COMMENT '查询名称',
  `runstat` int DEFAULT '1' COMMENT '运行状态0 此处循环尚未运行sql 1 此处已经运行成功sql 2 此处已经运行过该sql但是失败了',
  `run` varchar(5000) DEFAULT NULL,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `UPDATE_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_user` varchar(50) DEFAULT NULL,
  `remark` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '控制输出的表格是否需要中文解释，如果没有则输出的表格指标直接显示指标名称',
  `deleted` tinyint(1) DEFAULT '0' COMMENT '0 不删除，1删除',
  `metric_type` varchar(100) DEFAULT 'db' COMMENT '指标类型,db：通过查询数据库获得,os：通过系统命令获得',
  `skip_instance` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '指定不需要执行这个查询的实例[ip:port,] '',''分割',
  `navigation_name` varchar(100) NOT NULL DEFAULT '' COMMENT '目录中的表格导航名称',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=99 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='执行的sql';


INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('db_baseinfo', 1, 'SELECT  `user` ,CURRENT_USER1 ,CONNECTION_ID ,ifnull(db_name,'''')  as db_name,Server_version ,ifnull(all_db_size_MB,'''') as all_db_size_MB ,ifnull(all_datafile_size_MB,'''') as all_datafile_size_MB,datadir ,SOCKET ,log_error ,autocommit ,log_bin ,server_id
from (SELECT
	USER() user,
	CURRENT_USER() CURRENT_USER1,
	CONNECTION_ID() CONNECTION_ID,
	DATABASE() db_name,
	version() Server_version,
	( SELECT sum( TRUNCATE ( ( data_length + index_length ) / 1024 / 1024, 2 ) ) AS ''all_db_size(MB)'' FROM information_schema.TABLES b ) all_db_size_MB,
	(select truncate(sum(total_extents*extent_size)/1024/1024,2) from  information_schema.FILES b) all_datafile_size_MB,
	( SELECT @@datadir ) datadir,
	( SELECT @@SOCKET ) SOCKET,
	( SELECT @@log_error ) log_error,
	( SELECT @@autocommit ) autocommit,
	( SELECT @@log_bin ) log_bin,
	( SELECT @@server_id ) server_id ) V;', '2024-05-24 10:53:48', '2024-06-04 18:22:34', NULL, '数据库基本信息', 0, 'db', NULL, 'all_db_and_size');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('plugin_info', 1, 'SELECT PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_STATUS, PLUGIN_TYPE, PLUGIN_TYPE_VERSION, ifnull(PLUGIN_LIBRARY,'''') as PLUGIN_LIBRARY, ifnull(PLUGIN_LIBRARY_VERSION,'''') as PLUGIN_LIBRARY_VERSION, PLUGIN_AUTHOR, PLUGIN_DESCRIPTION, PLUGIN_LICENSE, LOAD_OPTION
from (SELECT * FROM INFORMATION_SCHEMA.PLUGINS where LOAD_OPTION <> ''FORCE'') V;', '2024-05-24 11:02:16', '2024-05-29 10:03:51', NULL, '插件信息', 0, 'db', NULL, '');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('db_size', 1, 'SELECT SCHEMA_NAME, DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME, ifnull(table_rows,'''') as table_rows , ifnull(data_size_mb,'''') as data_size_mb, ifnull(index_size_mb,'''') as index_size_mb , ifnull(all_size_mb,'''') as  all_size_mb, ifnull(max_size_mb,'''') as max_size_mb, ifnull(free_size_mb,'''') as free_size_mb, ifnull(disk_size_mb,'''') as disk_size_mb
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
    (select substring(b.file_name,3,locate(''/'',b.file_name,3)-3) as db_name,
			truncate(sum(total_extents*extent_size)/1024/1024,2) filesize_M
			from  information_schema.FILES b
			group by substring(b.file_name,3,locate(''/'',b.file_name,3)-3)) f
on ( a.SCHEMA_NAME= f.db_name)
group by a.SCHEMA_NAME,  a.DEFAULT_CHARACTER_SET_NAME,a.DEFAULT_COLLATION_NAME
order by sum(data_length) desc, sum(index_length) DESC
) V;', '2024-05-24 11:12:21', '2024-06-04 18:22:34', NULL, '当前数据库实例的所有数据库及其容量大小', 0, 'db', NULL, 'all_db_objects');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('db_object_count', 1, 'SELECT db_name,ob_type,sums from
(select db as db_name ,type as ob_type,cnt as sums from
(select ''TABLE'' type,table_schema db, count(*) cnt  from information_schema.`TABLES` a where table_type=''BASE TABLE'' group by table_schema
union all
select ''EVENTS'' type,event_schema db,count(*) cnt from information_schema.`EVENTS` b group by event_schema
union all
select ''TRIGGERS'' type,trigger_schema db,count(*) cnt from information_schema.`TRIGGERS` c group by trigger_schema
union all
select ''PROCEDURE'' type,routine_schema db,count(*) cnt from information_schema.ROUTINES d where`ROUTINE_TYPE` = ''PROCEDURE'' group by db
union all
select ''FUNCTION'' type,routine_schema db,count(*) cnt  from information_schema.ROUTINES d where`ROUTINE_TYPE` = ''FUNCTION'' group by db
union all
select ''VIEWS'' type,TABLE_SCHEMA db,count(*) cnt  from information_schema.VIEWS f group by table_schema  ) t
order by db,type) V;', '2024-05-24 13:59:23', '2024-06-04 18:22:34', NULL, '数据库对象', 0, 'db', NULL, 'db_status');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('disk_top_10_table', 1, 'SELECT db_name, table_name, TABLE_TYPE, ENGINE, CREATE_TIME, ifnull(UPDATE_TIME,'''') as UPDATE_TIME, TABLE_COLLATION, table_rows, tb_size_mb, index_size_mb, all_size_mb, free_size_mb, ifnull(disk_size_mb,'''') as disk_size_mb
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
    (select substring(b.file_name,3,locate(''/'',b.file_name,3)-3) as db_name,
			substring(b.file_name,locate(''/'',b.file_name,3)+1,(LENGTH(b.file_name)-locate(''/'',b.file_name,3)-4)) as tb_name,
			b.file_name,
			(total_extents*extent_size)/1024/1024 filesize_M
			from  information_schema.FILES b
			order by filesize_M desc limit 20 ) f
on ( a.TABLE_SCHEMA= f.db_name and a.TABLE_NAME=f.tb_name )
ORDER BY	( data_length + index_length ) DESC
LIMIT 10) V;', '2024-05-24 14:05:55', '2024-06-04 18:22:34', NULL, '占用空间最大的前10张大表', 0, 'db', NULL, 'top10_tb_size');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('disk_top_10_index', 1, 'SELECT database_name, table_name, index_name, SizeMB, NON_UNIQUE, INDEX_TYPE, COLUMN_NAME from
(select
iis.database_name,
iis.table_name,
iis.index_name,
round((iis.stat_value*@@innodb_page_size)/1024/1024, 2) SizeMB,
s.NON_UNIQUE,
s.INDEX_TYPE,
GROUP_CONCAT(s.COLUMN_NAME order by SEQ_IN_INDEX) COLUMN_NAME
from (select * from mysql.innodb_index_stats
				WHERE index_name  not in (''PRIMARY'',''GEN_CLUST_INDEX'') and stat_name=''size''
				order by (stat_value*@@innodb_page_size) desc limit 10
			) iis
left join INFORMATION_SCHEMA.STATISTICS s
on (iis.database_name=s.TABLE_SCHEMA and iis.table_name=s.TABLE_NAME and iis.index_name=s.INDEX_NAME)
GROUP BY iis.database_name,iis.TABLE_NAME,iis.INDEX_NAME,(iis.stat_value*@@innodb_page_size),s.NON_UNIQUE,s.INDEX_TYPE
order by (stat_value*@@innodb_page_size) desc) V;', '2024-05-24 14:09:03', '2024-06-04 18:22:34', NULL, '占用空间最大的前10个索引', 0, 'db', NULL, 'top10_tb_size');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('engine_table_count', 1, 'SELECT ifnull(ENGINE,'''') as ENGINE, counts
from (SELECT a.`ENGINE`,count( * ) counts
FROM    information_schema.`TABLES` a
GROUP BY a.`ENGINE`) V', '2024-05-24 14:13:52', '2024-07-12 11:15:57', NULL, '存储引擎和table的数量关系', 1, 'db', NULL, 'all_engines');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('db_engine_table_count', 1, 'SELECT TABLE_SCHEMA, ifnull(ENGINE,'''') as ENGINE, counts
from (SELECT  a.TABLE_SCHEMA,
	a.`ENGINE`,
	count( * ) counts
FROM    information_schema.`TABLES` a
GROUP BY  a.TABLE_SCHEMA,a.`ENGINE`
ORDER BY a.TABLE_SCHEMA) V', '2024-05-24 14:13:52', '2024-07-12 11:15:57', NULL, '存储引擎和DB的数量关系', 1, 'db', NULL, 'engines_db');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('innodb_tablespace', 1, 'SELECT FILE_ID, FILE_NAME, FILE_TYPE, TABLESPACE_NAME, TABLE_CATALOG, ifnull(TABLE_SCHEMA,'''') as TABLE_SCHEMA, ifnull(TABLE_NAME,'''') as TABLE_NAME, ifnull(LOGFILE_GROUP_NAME,'''') as LOGFILE_GROUP_NAME, ifnull(LOGFILE_GROUP_NUMBER,'''') as LOGFILE_GROUP_NUMBER, ENGINE, ifnull(FULLTEXT_KEYS,'''') as FULLTEXT_KEYS , ifnull(DELETED_ROWS,'''') as DELETED_ROWS, ifnull(UPDATE_COUNT,'''') as UPDATE_COUNT, FREE_EXTENTS, TOTAL_EXTENTS, EXTENT_SIZE, ifnull(INITIAL_SIZE,'''') as INITIAL_SIZE, ifnull(MAXIMUM_SIZE,'''') as MAXIMUM_SIZE, ifnull(AUTOEXTEND_SIZE,'''') as AUTOEXTEND_SIZE, ifnull(CREATION_TIME,'''') as CREATION_TIME, ifnull(LAST_UPDATE_TIME,'''') as LAST_UPDATE_TIME, ifnull(LAST_ACCESS_TIME,'''') as LAST_ACCESS_TIME, ifnull(RECOVER_TIME,'''') as RECOVER_TIME, ifnull(TRANSACTION_COUNTER,'''') as TRANSACTION_COUNTER, ifnull(VERSION,'''') as VERSION, ifnull(ROW_FORMAT,'''') as ROW_FORMAT, ifnull(TABLE_ROWS,'''') as TABLE_ROWS, ifnull(AVG_ROW_LENGTH,'''') as AVG_ROW_LENGTH, ifnull(DATA_LENGTH,'''') as DATA_LENGTH, ifnull(MAX_DATA_LENGTH,'''') as MAX_DATA_LENGTH, ifnull(INDEX_LENGTH,'''') as INDEX_LENGTH, ifnull(DATA_FREE,'''') as DATA_FREE, ifnull(CREATE_TIME,'''') as CREATE_TIME, ifnull(UPDATE_TIME,'''') as UPDATE_TIME, ifnull(CHECK_TIME,'''') as CHECK_TIME, ifnull(CHECKSUM,'''') as CHECKSUM, ifnull(STATUS,'''') as STATUS, ifnull(EXTRA,'''') as EXTRA
from (SELECT * FROM INFORMATION_SCHEMA.FILES a WHERE FILE_TYPE <>''TABLESPACE'' or a.TABLESPACE_NAME in (''innodb_system'',''innodb_temporary'')) V;', '2024-05-24 14:57:36', '2024-06-04 18:22:34', NULL, 'innodb系统表空间', 0, 'db', NULL, 'innodb_tablespaces');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('db_user', 1, 'SELECT Host, User, Select_priv, Insert_priv, Update_priv, Delete_priv, Create_priv, Drop_priv, Reload_priv, Shutdown_priv, Process_priv, File_priv, Grant_priv, References_priv, Index_priv, Alter_priv, Show_db_priv, Super_priv, Create_tmp_table_priv, Lock_tables_priv, Execute_priv, Repl_slave_priv, Repl_client_priv, Create_view_priv, Show_view_priv, Create_routine_priv, Alter_routine_priv, Create_user_priv, Event_priv, Trigger_priv, Create_tablespace_priv, ssl_type, ssl_cipher, x509_issuer, x509_subject, max_questions, max_updates, max_connections, max_user_connections, plugin
from (select * from mysql.user) V', '2024-05-24 14:57:36', '2024-06-11 16:56:19', NULL, '查询所有用户', 1, 'db', NULL, 'ALL_USES');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('character_set', 1, 'SELECT CHARACTER_SET_NAME, DEFAULT_COLLATE_NAME, DESCRIPTION, MAXLEN
from (select * from information_schema.CHARACTER_SETS) V', '2024-05-24 14:57:36', '2024-06-11 16:56:19', NULL, '查询MySQL支持的所有字符集', 1, 'db', NULL, 'ALL_character_set');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('user_connect_current', 1, 'SELECT USER, HOST
from (SELECT DISTINCT USER,HOST FROM `information_schema`.`PROCESSLIST` P WHERE P.USER NOT in (''repl'',''system user'') limit 100) V;', '2024-05-24 15:10:32', '2024-06-11 16:56:08', NULL, '查看当前连接到数据库的用户和Host', 1, 'db', NULL, 'IMPORTANT_INIT');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('connect_current', 1, 'SELECT ifnull(HOST,'''') as HOST, CURRENT_CONNECTIONS, TOTAL_CONNECTIONS
from (SELECT * FROM performance_schema.hosts) V', '2024-05-24 15:10:32', '2024-06-04 18:22:34', NULL, '查看每个host的当前连接数和总连接数', 0, 'db', NULL, 'ALL_link_user_host');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('login_user_info', 1, 'SELECT ifnull(database_name,'''') as database_name, login_user, login_ip, login_count
from (SELECT  DB AS database_name,
	USER AS login_user,
	LEFT ( HOST, POSITION( '':'' IN HOST ) - 1 ) AS login_ip,
	count( 1 ) AS login_count
FROM  `information_schema`.`PROCESSLIST` P
GROUP BY DB,USER,LEFT(HOST, POSITION( '':'' IN HOST ) - 1 )) V;', '2024-05-24 15:10:32', '2024-06-04 18:22:34', NULL, '按照登录用户+数据库+登录服务器查看登录信息', 0, 'db', NULL, 'ALL_link_user_host_per');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('thread_no_sleep', 1, 'SELECT ID, USER, HOST, ifnull(DB,''''), COMMAND, TIME, STATE, ifnull(INFO,'''') as INFO
from (select * from information_schema.`PROCESSLIST`  a where a.command<>''Sleep'' and a.id<>CONNECTION_id() ) V;', '2024-05-24 15:38:44', '2024-06-26 15:44:20', NULL, '查询所有线程', 0, 'db', NULL, 'ALL_link_user_host_info');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('thread_no_sleep_detail', 1, 'SELECT THREAD_ID, NAME, TYPE, PROCESSLIST_ID, ifnull(PROCESSLIST_USER,'''') as PROCESSLIST_USER, ifnull(PROCESSLIST_HOST,'''') as PROCESSLIST_HOST, ifnull(PROCESSLIST_DB,'''') as PROCESSLIST_DB, PROCESSLIST_COMMAND, PROCESSLIST_TIME, PROCESSLIST_STATE, ifnull(PROCESSLIST_INFO,'''') as PROCESSLIST_INFO, PARENT_THREAD_ID, ifnull(ROLE,'''') as ROLE, INSTRUMENTED, HISTORY, ifnull(CONNECTION_TYPE,'''') as CONNECTION_TYPE, ifnull(THREAD_OS_ID,'''') as  THREAD_OS_ID
from (SELECT * FROM performance_schema.threads a where a.type!=''BACKGROUND'' and a.PROCESSLIST_COMMAND<>''Sleep''  and a.PROCESSLIST_ID<>CONNECTION_id() ) V;', '2024-05-24 15:38:44', '2024-07-12 14:01:54', NULL, '查询所有线程_detail', 0, 'db', NULL, '');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('thread_sleep_top_20', 1, 'SELECT ID, USER, HOST, ifnull(DB,'''') as DB, COMMAND, TIME, ifnull(STATE,'''') as STATE, ifnull(INFO,'''') as INFO
from (select * from information_schema.`PROCESSLIST`  a where a.command=''Sleep'' order by time desc limit 20 ) V;', '2024-05-24 15:38:44', '2024-06-04 18:22:34', NULL, 'sleep线程TOP20', 0, 'db', NULL, 'all_processlist');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('thread_sleep_top_20_detail', 1, 'SELECT THREAD_ID, NAME, TYPE, PROCESSLIST_ID, ifnull(PROCESSLIST_USER,'''') as PROCESSLIST_USER, ifnull(PROCESSLIST_HOST,'''') as PROCESSLIST_HOST, ifnull(PROCESSLIST_DB,'''') as PROCESSLIST_DB, PROCESSLIST_COMMAND, PROCESSLIST_TIME, PROCESSLIST_STATE, PARENT_THREAD_ID, ifnull(ROLE,'''') as ROLE, INSTRUMENTED, HISTORY, ifnull(CONNECTION_TYPE,'''') as CONNECTION_TYPE, ifnull(THREAD_OS_ID,'''') as  THREAD_OS_ID , ifnull(PROCESSLIST_INFO,'''') as PROCESSLIST_INFO
from (SELECT * FROM performance_schema.threads a where a.type!=''BACKGROUND'' and a.PROCESSLIST_COMMAND<>''Sleep''   order by a.PROCESSLIST_time desc limit 20) V;', '2024-05-24 15:38:44', '2024-06-26 17:35:39', NULL, 'sleep线程TOP20细节', 0, 'db', NULL, 'all_processlist_sleep');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('open_tables_in_use', 1, 'show open tables where in_use > 0;', '2024-05-28 11:04:32', '2024-06-04 18:22:34', NULL, '有多少线程正在使用表', 0, 'db', NULL, 'process_use');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('innodb_status', 1, 'show engine innodb status ;', '2024-05-28 11:04:32', '2024-06-25 16:51:37', NULL, '查询InnoDB存储引擎的运行时信息，包括死锁的详细信息', 0, 'db', NULL, 'Innodb_running');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('innodb_lock_current', 1, 'SELECT ENGINE_LOCK_ID,THREAD_ID,LOCK_MODE,LOCK_TYPE,OBJECT_NAME,INDEX_NAME,PARTITION_NAME,LOCK_STATUS,LOCK_DATA
from (select * from performance_schema.data_locks) V
', '2024-05-28 11:04:32', '2024-06-04 18:22:34', NULL, '查看当前状态产生的InnoDB锁，仅在有锁等待时有结果输出', 0, 'db', NULL, 'mdl_info');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('innodb_lock_wait_current', 1, 'SELECT  REQUESTING_THREAD_ID,REQUESTING_ENGINE_LOCK_ID,BLOCKING_THREAD_ID,BLOCKING_ENGINE_LOCK_ID FROM performance_schema.data_lock_waits;', '2024-05-28 11:04:32', '2024-06-04 18:25:31', NULL, '查看当前状态产生的InnoDB锁等待，仅在有锁等待时有结果输出', 0, 'db', NULL, '');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('active_transcation', 1, 'SELECT trx_id, trx_state, trx_started, trx_requested_lock_id, trx_wait_started, trx_weight, trx_mysql_thread_id, trx_query, trx_operation_state, trx_tables_in_use, trx_tables_locked, trx_lock_structs, trx_lock_memory_bytes, trx_rows_locked, trx_rows_modified, trx_concurrency_tickets, trx_isolation_level, trx_unique_checks, trx_foreign_key_checks, trx_last_foreign_key_error, trx_adaptive_hash_latched, trx_adaptive_hash_timeout, trx_is_read_only, trx_autocommit_non_locking
from (select * from information_schema.innodb_trx) V;', '2024-05-28 11:04:32', '2024-05-28 11:04:32', NULL, '当前Innodb内核中的当前活跃（active）事务', 0, 'db', NULL, '');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('matedata_lock', 1, 'SELECT NAME, ENABLED, TIMED
from (select * from performance_schema.setup_instruments WHERE name=''wait/lock/metadata/sql/mdl'') V;', '2024-05-28 11:04:32', '2024-06-26 18:17:14', NULL, '元数据锁的相关信息-enable', 1, 'db', NULL, '');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('matedata_lock_detail_01', 1, 'SELECT locked_schema, locked_table, locked_type, waiting_processlist_id, waiting_age, waiting_query, waiting_state, blocking_processlist_id, blocking_age, blocking_query, sql_kill_blocking_connection
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
            concat(''KILL '', d.PROCESSLIST_ID) AS sql_kill_blocking_connection
        from performance_schema.metadata_locks a
        JOIN performance_schema.metadata_locks b
		ON a.OBJECT_SCHEMA = b.OBJECT_SCHEMA
        AND a.OBJECT_NAME = b.OBJECT_NAME
        AND a.lock_status = ''PENDING''
        AND b.lock_status = ''GRANTED''
        AND a.OWNER_THREAD_ID <> b.OWNER_THREAD_ID
        AND a.lock_type = ''EXCLUSIVE''
        JOIN performance_schema.threads c ON a.OWNER_THREAD_ID = c.THREAD_ID
        JOIN performance_schema.threads d ON b.OWNER_THREAD_ID = d.THREAD_ID
    ) t1,
    (
        SELECT
            thread_id,
            group_concat(   CASE WHEN EVENT_NAME = ''statement/sql/begin'' THEN "transaction_begin" ELSE sql_text END ORDER BY event_id SEPARATOR ";" ) AS sql_text
        FROM
            performance_schema.events_statements_history
        GROUP BY thread_id
    ) t2
WHERE
    t1.granted_thread_id = t2.thread_id) V;', '2024-05-28 16:02:11', '2024-06-26 16:58:45', NULL, '元数据锁的相关信息-events_statements', 0, 'db', NULL, '');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('matedata_lock_detail_02', 1, 'SELECT thd_id, conn_id, user, db, command, state, time,  statement_latency, progress, lock_latency, rows_examined, rows_sent, rows_affected, tmp_tables, tmp_disk_tables, full_scan, last_statement, last_statement_latency, current_memory, last_wait, last_wait_latency, source, trx_latency, trx_state, trx_autocommit, pid, program_name, lock_summary ,current_statement
from (SELECT ps.*,  lock_summary.lock_summary  FROM sys.processlist ps  INNER JOIN (SELECT owner_thread_id,  GROUP_CONCAT(  DISTINCT CONCAT(mdl.LOCK_STATUS, '' '', mdl.lock_type, '' on '', IF(mdl.object_type=''USER LEVEL LOCK'', CONCAT(mdl.object_name, '' (user lock)''), CONCAT(mdl.OBJECT_SCHEMA, ''.'', mdl.OBJECT_NAME)))  ORDER BY mdl.object_type ASC, mdl.LOCK_STATUS ASC, mdl.lock_type ASC  SEPARATOR ''\\n''  ) as lock_summary FROM performance_schema.metadata_locks mdl GROUP BY owner_thread_id) lock_summary ON (ps.thd_id=lock_summary.owner_thread_id)) V;', '2024-05-28 16:02:11', '2024-06-26 17:47:03', NULL, '元数据锁的相关信息-metadata_locks', 0, 'db', NULL, '');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('matedata_lock_detail_03', 1, 'SELECT object_schema, object_name, waiting_thread_id, waiting_pid, waiting_account, waiting_lock_type, waiting_lock_duration, waiting_query, waiting_query_secs, waiting_query_rows_affected, waiting_query_rows_examined, blocking_thread_id, blocking_pid, blocking_account, blocking_lock_type, blocking_lock_duration, sql_kill_blocking_query, sql_kill_blocking_connection
from (select * from sys.schema_table_lock_waits) V;', '2024-05-28 16:02:11', '2024-06-26 16:55:14', NULL, '表锁信息', 0, 'db', NULL, '');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('db_global_status', 1, 'SELECT  VARIABLE_NAME, VARIABLE_VALUE
from (select * from performance_schema.global_status where  VARIABLE_NAME  like ''%lock%'') V;', '2024-05-28 16:02:11', '2024-05-28 16:14:38', NULL, '查看服务器的状态', 0, 'db', NULL, '');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('events_stages_current', 1, 'SELECT THREAD_ID, EVENT_ID, END_EVENT_ID, EVENT_NAME, SOURCE, TIMER_START, TIMER_END, TIMER_WAIT, WORK_COMPLETED, WORK_ESTIMATED, NESTING_EVENT_ID, NESTING_EVENT_TYPE
from (select * from performance_schema.events_stages_current) V;', '2024-05-28 16:02:11', '2024-06-04 18:26:03', NULL, '跟踪长时间操作的进度', 0, 'db', NULL, 'SQL_run_long');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('run_time_more_then_95th', 1, 'SELECT  digest, ifnull(db,'''') as db, full_scan, exec_count, err_count, warn_count, total_latency, max_latency, avg_latency, rows_sent, rows_sent_avg, rows_examined, rows_examined_avg, first_seen, last_seen, query
from (SELECT DIGEST_TEXT AS query,
  SCHEMA_NAME as db,
  IF(SUM_NO_GOOD_INDEX_USED > 0 OR SUM_NO_INDEX_USED > 0, ''*'', '''') AS full_scan,
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
WHERE last_seen > date_add(now(), INTERVAL -1 day)
;', '2024-05-28 16:02:11', '2024-07-12 14:51:05', NULL, '查看平均执行时间值大于95%的平均执行时间的语句（可近似地认为是平均执行时间超长的语句），默认情况下按照语句平均延迟(执行时间)降序排序
', 0, 'db', NULL, 'SQL_run_long_95');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('active_thread_schedule', 1, 'SELECT  thd_id, conn_id, user, db, command, state, time, statement_latency, progress, lock_latency, rows_examined, rows_sent, rows_affected, tmp_tables, tmp_disk_tables, full_scan, last_statement, last_statement_latency, current_memory, last_wait, last_wait_latency, source, trx_latency, trx_state, trx_autocommit, pid, program_name, current_statement from (select * from sys.session where conn_id!=connection_id() and trx_state=''ACTIVE'') V;', '2024-05-28 16:02:11', '2024-06-26 17:42:00', NULL, '查看当前正在执行的语句进度信息', 0, 'db', NULL, '');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('done_thread_message', 1, 'SELECT  thd_id, conn_id, user, ifnull(db,'''') as db, command, ifnull(state,'''') as state, time, ifnull(statement_latency,'''') as statement_latency, ifnull(progress,'''') as progress, lock_latency, rows_examined, rows_sent, rows_affected, tmp_tables, tmp_disk_tables, full_scan, last_statement, last_statement_latency, current_memory, ifnull(last_wait,'''') as last_wait, ifnull(last_wait_latency,'''') as last_wait_latency, ifnull(source,'''') as source, trx_latency, trx_state, trx_autocommit, pid, ifnull(program_name,'''') as program_name, ifnull(current_statement,'''') as current_statement  from (select * from sys.session where conn_id!=connection_id() and trx_state=''COMMITTED'') V;', '2024-05-28 16:02:11', '2024-06-26 17:42:50', NULL, '查看已经执行完的语句相关统计信息', 0, 'db', NULL, '');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('extra_temp_sql', 1, 'SELECT  digest, ifnull(db,'''') as db, exec_count, total_latency, memory_tmp_tables, disk_tmp_tables, avg_tmp_tables_per_query, tmp_tables_to_disk_pct, first_seen, last_seen, query
from (SELECT DIGEST_TEXT AS query,
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
WHERE last_seen > date_add(now(), INTERVAL -1 day)
;', '2024-05-28 16:02:11', '2024-07-12 15:39:52', NULL, '查看使用了临时表的语句，默认情况下按照磁盘临时表数量和内存临时表数量进行降序排序', 0, 'db', NULL, 'sql_info_tmp');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('extra_temp_sql_top_10', 1, 'SELECT  digest, ifnull(db,'''') as db, full_scan, exec_count, err_count, warn_count, total_latency, max_latency, avg_latency, lock_latency, rows_sent, rows_sent_avg, rows_examined, rows_examined_avg, rows_affected, rows_affected_avg, tmp_tables, tmp_disk_tables, rows_sorted, sort_merge_passes, query, first_seen, last_seen
from (SELECT * FROM sys.statement_analysis WHERE tmp_tables > 0 ORDER BY tmp_tables DESC LIMIT 10) V
WHERE last_seen > date_add(now(), INTERVAL -1 day)
;', '2024-05-28 16:02:11', '2024-07-12 15:40:02', NULL, '有临时表的前10条SQL语句', 0, 'db', NULL, '');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('extra_filesort_sql', 1, 'SELECT  digest, ifnull(db,'''') as db, exec_count, total_latency, sort_merge_passes, avg_sort_merges, sorts_using_scans, sort_using_range, rows_sorted, avg_rows_sorted, first_seen, last_seen, query
from (SELECT DIGEST_TEXT AS query,
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
WHERE last_seen > date_add(now(), INTERVAL -1 day)
;', '2024-05-28 16:02:11', '2024-07-12 15:40:12', NULL, '查看执行了文件排序的语句，默认情况下按照语句总延迟时间（执行时间）降序排序', 0, 'db', NULL, 'sql_info_disk_sort');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('extra_filesort_sql_cast_percent', 1, 'SELECT  state, total_r, pct_r, calls, `r/call`  from (select state,
       sum(duration) as total_r,
       round(100 * sum(duration) / (select sum(duration) from information_schema.profiling  where query_id = 1),2) as pct_r,
       count(*) as calls,
       sum(duration) / count(*) as "r/call"
  from information_schema.profiling
 where query_id = 1
 group by state
 order by total_r desc) V;', '2024-05-28 16:02:11', '2024-06-04 18:26:03', NULL, '查询SQL的整体消耗百分比', 0, 'db', NULL, 'sqL_cost_all');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('extra_filesort_sql_top_10', 1, 'SELECT  digest, ifnull(db,'''') as db, full_scan, exec_count, err_count, warn_count, total_latency, max_latency, avg_latency, lock_latency, rows_sent, rows_sent_avg, rows_examined, rows_examined_avg, rows_affected, rows_affected_avg, tmp_tables, tmp_disk_tables, rows_sorted, sort_merge_passes, query, first_seen, last_seen
from (SELECT * FROM sys.statement_analysis WHERE full_scan = ''*'' order by exec_count desc limit 10) V
WHERE last_seen > date_add(now(), INTERVAL -1 day)
;', '2024-05-28 16:02:11', '2024-07-12 15:40:21', NULL, '执行次数Top10', 0, 'db', NULL, 'sqL_exec_count_top10');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('full_table_scan_sql', 1, 'SELECT  object_schema, object_name, rows_full_scanned, latency  from (SELECT object_schema,
  object_name, -- 表名
  count_read AS rows_full_scanned,  -- 全表扫描的总数据行数
  sys.format_time(sum_timer_wait) AS latency -- 完整的表扫描操作的总延迟时间（执行时间）
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE index_name IS NULL
AND count_read > 0
ORDER BY count_read DESC limit 10) V;', '2024-05-28 16:02:11', '2024-06-04 18:26:03', NULL, '使用全表扫描的SQL语句', 0, 'db', NULL, 'sqL_full_scan');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('full_table_scan_sql_order', 1, 'SELECT  digest, ifnull(db,'''') as db, exec_count, total_latency, no_index_used_count, no_good_index_used_count, no_index_used_pct, rows_sent, rows_examined, rows_sent_avg, rows_examined_avg, query, first_seen, last_seen
from (SELECT DIGEST_TEXT AS query,
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
AND DIGEST_TEXT NOT LIKE ''SHOW%''
ORDER BY no_index_used_pct DESC, total_latency DESC limit 10) V
WHERE last_seen > date_add(now(), INTERVAL -1 day)
;', '2024-05-28 16:02:11', '2024-07-12 15:40:30', NULL, '查看全表扫描或者没有使用到最优索引的语句（经过标准化转化的语句文本），默认情况下按照全表扫描次数与语句总次数百分比和语句总延迟时间(执行时间)降序排序', 0, 'db', NULL, 'sql_no_best_index');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('error_or_warning_sql_order', 1, 'SELECT  digest, ifnull(db,'''') as db, exec_count, errors, error_pct, warnings, warning_pct, query, first_seen, last_seen
from (SELECT DIGEST_TEXT AS query,
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
ORDER BY SUM_ERRORS DESC, SUM_WARNINGS DESC limit 10) V
WHERE last_seen > date_add(now(), INTERVAL -1 day)
;', '2024-05-28 16:05:12', '2024-07-12 15:40:44', NULL, '查看产生错误的语句，默认情况下，按照错误数量和警告数量降序排序', 0, 'db', NULL, 'sql_error_worings');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('unused_index', 1, 'SELECT  object_schema, object_name, index_name
from (select * from sys.schema_unused_indexes WHERE object_schema NOT IN (''performance_schema'',''sys'',''information_schema'',''mysql'') ) V;', '2024-05-28 16:05:12', '2024-06-11 18:08:36', NULL, '未使用的索引', 0, 'db', NULL, 'sql_unused_indexes');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('index_cardinary_per_table', 1, 'SELECT  ASdb, AStable, ASindex_name, AScols, ASdefferRows, ASROWS, sel_persent  from (SELECT
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
WHERE i.index_name != ''PRIMARY'' AND i.stat_name LIKE ''%n_diff_pfx%''
and ROUND(((i.stat_value / IFNULL(IF(t.n_rows < i.stat_value,i.stat_value,t.n_rows),0.01))),2)<0.1
and t.n_rows !=0
and i.stat_value !=0
and i.database_name not in (''mysql'', ''information_schema'', ''sys'', ''performance_schema'')
limit 100) V;', '2024-05-28 16:05:12', '2024-06-04 18:26:03', NULL, '每张表的索引区分度（前100条 -区分度越接近1，表示区分度越高；低于0.1，则说明区分度较差 ）', 0, 'db', NULL, 'index_qfd');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('global_variables_for_repl', 1, 'SELECT  VARIABLE_NAME, VARIABLE_VALUE
from (select * from performance_schema.global_variables where  VARIABLE_NAME  in ( ''server_id'',''server_uuid'',''log_bin'',''log_bin_basename'',''sql_log_bin'',''log_bin_index'',''log_slave_updates'',''read_only'',''slave_skip_errors'',''max_allowed_packet'',''slave_max_allowed_packet'',''auto_increment_increment'',''auto_increment_offset'',''sync_binlog'',''binlog_format'',''expire_logs_days'',''max_binlog_size'',''slave_skip_errors'',''sql_slave_skip_counter'',''slave_exec_mode'',''rpl_semi_sync_master_enabled'',''rpl_semi_sync_master_timeout'',''rpl_semi_sync_master_trace_level'',''rpl_semi_sync_master_wait_for_slave_count'',''rpl_semi_sync_master_wait_no_slave'',''rpl_semi_sync_master_wait_point'',''rpl_semi_sync_slave_enabled'',''rpl_semi_sync_slave_trace_level'')) V;', '2024-05-28 16:05:12', '2024-06-04 18:26:03', NULL, '主从复制涉及到的重要参数', 0, 'db', NULL, 'SLAVE_IMPORTANT_INIT');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('semi_repl_variables', 1, 'SELECT  VARIABLE_NAME, VARIABLE_VALUE
from (select * from performance_schema.global_status where  VARIABLE_NAME  like ''rpl_semi%'') V;', '2024-05-28 16:05:12', '2024-06-04 18:26:03', NULL, '半同步参数统计', 0, 'db', NULL, 'db_rpl_semi_stats');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('repl_thread', 1, 'SELECT  THREAD_ID, NAME, TYPE, PROCESSLIST_ID, PROCESSLIST_USER, PROCESSLIST_HOST, ifnull(PROCESSLIST_DB,''''), PROCESSLIST_COMMAND, PROCESSLIST_TIME, PROCESSLIST_STATE, ifnull(PROCESSLIST_INFO,''''), ifnull(PARENT_THREAD_ID,''''), ifnull(ROLE,''''), INSTRUMENTED, HISTORY, ifnull(CONNECTION_TYPE,''''), THREAD_OS_ID  from
(SELECT *
FROM performance_schema.threads a
WHERE a.`NAME` IN ( ''thread/sql/slave_IO'', ''thread/sql/slave_sql'',''thread/sql/slave_worker''
                   ,''thread/sql/replica_io'',''thread/sql/replica_sql'',''thread/sql/replica_worker'' )
 or a.PROCESSLIST_COMMAND in (''Binlog Dump'',''Binlog Dump GTID'') ) V;', '2024-05-28 16:05:27', '2024-05-28 16:37:26', NULL, '主从库线程-THREAD', 0, 'db', NULL, '');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('repl_process', 1, 'SELECT  ID, USER, HOST, ifnull(DB,''''), COMMAND, TIME, STATE, ifnull(INFO,'''')
from (SELECT * FROM information_schema.`PROCESSLIST` a where a.USER=''system user'' or a.command in (''Binlog Dump'',''Binlog Dump GTID'') ) V;', '2024-05-28 16:05:27', '2024-06-04 18:26:03', NULL, '主从库线程-PROCESS', 0, 'db', NULL, 'slave_processlist');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('replication_group_members', 1, 'SELECT  CHANNEL_NAME, MEMBER_ID, MEMBER_HOST, MEMBER_PORT, MEMBER_STATE
from (SELECT * FROM performance_schema.replication_group_members) V;', '2024-05-28 16:05:27', '2024-06-04 18:26:44', NULL, '主库端查看所有从库', 0, 'db', NULL, 'master_info_status');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('master_status', 1, 'show master status ;', '2024-05-28 16:05:27', '2024-06-04 18:26:44', NULL, '主库状态监测', 0, 'db', NULL, 'master_info_status');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('slave_status', 1, 'show slave status ;', '2024-05-28 16:05:27', '2024-06-04 18:26:44', NULL, '从库状态监测（需要在从库执行才有数据）', 0, 'db', NULL, 'slave_info_status');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('slave_status_detail', 1, 'SELECT  CHANNEL_NAME, HOST, PORT, USER, CONNECTION_RETRY_COUNT, CONNECTION_RETRY_INTERVAL, SOURCE_UUID, THREAD_ID, SERVICE_STATE, COUNT_RECEIVED_HEARTBEATS, LAST_HEARTBEAT_TIMESTAMP, LAST_ERROR_NUMBER, LAST_ERROR_MESSAGE, LAST_ERROR_TIMESTAMP  from
(select rcc.CHANNEL_NAME,rcc.`HOST`,rcc.`PORT`,rcc.`USER`,rcc.CONNECTION_RETRY_COUNT,rcc.CONNECTION_RETRY_INTERVAL,
rcs.SOURCE_UUID,rcs.THREAD_ID,rcs.SERVICE_STATE,rcs.COUNT_RECEIVED_HEARTBEATS,rcs.LAST_HEARTBEAT_TIMESTAMP,rcs.LAST_ERROR_NUMBER,rcs.LAST_ERROR_MESSAGE,rcs.LAST_ERROR_TIMESTAMP
from performance_schema.replication_connection_configuration rcc,
     performance_schema.replication_connection_status rcs
where rcc.CHANNEL_NAME=rcs.CHANNEL_NAME) V;', '2024-05-28 16:05:27', '2024-05-28 16:40:25', NULL, '从库状态查询', 0, 'db', NULL, '');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('performance_variables', 1, 'SELECT  VARIABLE_NAME, VARIABLE_VALUE
from (select * from performance_schema.global_status where  VARIABLE_NAME  in ( ''connections'',''uptime'',''com_select'',''com_insert'',''com_delete'',''slow_queries'',''Created_tmp_tables'',''Created_tmp_files'',''Created_tmp_disk_tables'',''table_cache'',''Handler_read_rnd_next'',''Table_locks_immediate'',''Table_locks_waited'',''Open_files'',''Opened_tables'',''Sort_merge_passes'',''Sort_range'',''Sort_rows'',''Sort_scan'')) V;', '2024-05-28 16:05:27', '2024-06-04 18:26:44', NULL, '性能参数统计', 0, 'db', NULL, 'db_per_config_stats');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('setup_consumers', 1, 'SELECT  NAME, ENABLED
from (SELECT * FROM performance_schema.setup_consumers) V;', '2024-05-28 16:08:49', '2024-06-25 18:28:53', NULL, 'PREFORMANCE_ENABLED', 1, 'db', NULL, 'setup_consumers');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('auto_increament_id_top_20', 1, 'SELECT  table_schema, table_name, engine, Auto_increment
from (SELECT table_schema,table_name,engine, Auto_increment
 FROM information_schema.tables a
 where TABLE_SCHEMA not in (''mysql'', ''information_schema'', ''sys'', ''performance_schema'')
 and  a.Auto_increment<>''''
 order by a.AUTO_INCREMENT desc
limit 20 ) V;', '2024-05-28 16:08:49', '2024-06-04 18:26:44', NULL, '自增ID的使用情况（前20条）', 0, 'db', NULL, 'Auto_increment');
INSERT INTO mysql_report.report_sql (name, runstat, run, create_time, UPDATE_time, create_user, remark, deleted, metric_type, skip_instance, navigation_name) VALUES('no_primery_or_unque_key_top_100', 1, 'SELECT  table_schema, table_name
from (select table_schema, table_name
 from information_schema.tables
where table_type=''BASE TABLE''
 and  (table_schema, table_name) not in ( select /*+ subquery(materialization) */ a.TABLE_SCHEMA,a.TABLE_NAME
           from information_schema.TABLE_CONSTRAINTS a
		   where a.CONSTRAINT_TYPE in (''PRIMARY KEY'',''UNIQUE'')
		   and table_schema not in    (''mysql'', ''information_schema'', ''sys'', ''performance_schema'')	)
 AND table_schema not in  (''mysql'', ''information_schema'', ''sys'', ''performance_schema'')
limit 100 ) V;', '2024-05-28 16:08:49', '2024-06-04 18:26:44', NULL, '无主键或唯一键的表（前100条）', 0, 'db', NULL, 'no_pk');


CREATE TABLE if not exists mysql_report.`source_target` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL COMMENT '数据库名称',
  `host` varchar(50) NOT NULL COMMENT '数据库ip',
  `port` int NOT NULL COMMENT '数据库端口',
  `mysql_user` varchar(100) NOT NULL COMMENT '数据库用户',
  `mysql_pass` varchar(200) NOT NULL COMMENT '数据库用户密码',
  `target_database` varchar(100) DEFAULT NULL COMMENT '目标数据库',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `UPDATE_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_user` varchar(50) DEFAULT NULL,
  `remark` varchar(100) DEFAULT NULL,
  `deleted` tinyint(1) DEFAULT '0' COMMENT '0 不删除，1删除',
  `source_type` varchar(100) NOT NULL COMMENT '数据源名称, db ,os',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='目标数据库';


INSERT INTO mysql_report.source_target (name, host, port, mysql_user, mysql_pass, target_database, create_time, UPDATE_time, create_user, remark, deleted, source_type) VALUES('db_test', '172.29.29.100', 3303, 'gAAAAABmJ3xIEhT9eq4709DtLEirqd-6F7PrSAbd5bCcYxR2MRTsqZ32cgtchdpebHiMG7YYySZFC4F40LDxNd5CH2B3T0u9VQ==', 'gAAAAABmJxpd8abbsmDiNNYyIoWa0eJzrN3NpUgsPOQntsnRi0NvSANpBf_Nn9XKn3byqAWT12dTuXyn0FHR13yclWoOi5ozmg==', 'mysql_report', '2024-04-24 11:11:26', '2024-05-09 16:41:53', 'shenxiang', NULL, 0, 'db');
INSERT INTO mysql_report.source_target (name, host, port, mysql_user, mysql_pass, target_database, create_time, UPDATE_time, create_user, remark, deleted, source_type) VALUES('db_conf', '172.29.29.100', 3306, 'gAAAAABmJ3xIEhT9eq4709DtLEirqd-6F7PrSAbd5bCcYxR2MRTsqZ32cgtchdpebHiMG7YYySZFC4F40LDxNd5CH2B3T0u9VQ==', 'gAAAAABmJxpd8abbsmDiNNYyIoWa0eJzrN3NpUgsPOQntsnRi0NvSANpBf_Nn9XKn3byqAWT12dTuXyn0FHR13yclWoOi5ozmg==', 'mysql_report', '2024-04-29 15:06:23', '2024-05-09 16:41:53', 'shenxiang', NULL, 0, 'db');
INSERT INTO mysql_report.source_target (name, host, port, mysql_user, mysql_pass, target_database, create_time, UPDATE_time, create_user, remark, deleted, source_type) VALUES('os_test', '172.29.29.100', 22, 'gAAAAABmPIpf8rgRf7t_T43YyOy4g0c6BRDoSND_DwrIXd5f9Wzs9r5iJOveUZCPUmcbSVg1Fgj6aKu1pZfidtqIbaBiPiAyFw==', 'gAAAAABmPIp7mE1S8okHWs8tgJJwxLJ9FxyWyq-srcA224Q1V6lkdF1RjBCfCklt9zGl-IUWtT_2RD0l75eDc70OH00Q4Ymuhg==', NULL, '2024-05-09 16:37:31', '2024-05-10 10:56:34', 'shenxiang', NULL, 0, 'os');
INSERT INTO mysql_report.source_target (name, host, port, mysql_user, mysql_pass, target_database, create_time, UPDATE_time, create_user, remark, deleted, source_type) VALUES('os_sx_test', '172.29.29.102', 22, 'gAAAAABmPIpf8rgRf7t_T43YyOy4g0c6BRDoSND_DwrIXd5f9Wzs9r5iJOveUZCPUmcbSVg1Fgj6aKu1pZfidtqIbaBiPiAyFw==', 'gAAAAABmPIp7mE1S8okHWs8tgJJwxLJ9FxyWyq-srcA224Q1V6lkdF1RjBCfCklt9zGl-IUWtT_2RD0l75eDc70OH00Q4Ymuhg==', NULL, '2024-05-09 16:37:31', '2024-05-10 10:56:34', 'shenxiang', NULL, 0, 'os');


CREATE TABLE if not exists mysql_report.`sql_result` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `host` varchar(50) NOT NULL COMMENT '数据库ip',
  `metric_name` varchar(50) DEFAULT NULL COMMENT '查询名称',
  `metric_type` varchar(100) DEFAULT NULL COMMENT '指标名称',
  `metric_value` mediumtext COMMENT '指标值',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `UPDATE_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间，但是请不要手动修改，此处用于与创建时间做校队',
  `create_user` varchar(50) DEFAULT NULL,
  `remark` varchar(100) DEFAULT NULL,
  `deleted` tinyint(1) DEFAULT '0' COMMENT '0 不删除，1删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='指标值';

-- 处理不查询，但是会显示指标标题的问题
UPDATE  mysql_report.metric_report_format b JOIN `mysql_report`.`report_sql`  a ON a.name=b.metric_type  SET  b.deleted =1  WHERE a.deleted = 1  AND b.deleted =0 ;




