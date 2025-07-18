#!/usr/bin/env python
# -*- coding:utf-8 -*-


"""
mysql_report_job/

date : 2024/4/22
comment : 提示信息
"""
import datetime
import os
# 统一的创建时间戳
create_time=datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

local_path =os.path.dirname(os.path.abspath(__file__))

log_path = f'{local_path}/logs/'

html_path = f'{local_path}/html/'

# 输出html的方式
split_report = False # True表示os指标与db指标分开生成html页面，False表示生成合并页面

db_restore = {
    'host': '127.0.0.1',
    'port': 3306,
    'user': 'dzjroot',
    'password': 'Dzj_pwd_2022',
    # 'database': 'mysql_report'  # 请勿修改
}

# 邮件相关参数
# 匹配文件前缀，匹配上则输出
ip_filter = ""  # 一个字符串或一个元组
# 邮件接收人
recipientAddrs = 'shenxiang@dazhuanjia.com'
# recipientAddrs = 'shenxiang@dazhuanjia.com'
# recipientAddrs = 'DBA@dazhuanjia.com,shenxiang@dazhuanjia.com,caohang@dazhuanjia.com'


sql_disk_status = """
                -- 7日内的值会被用来计算
                -- 磁盘使用量吴变化时，预计使用时间和最大时间使用时间固定为3650天
                WITH CTE_os_query_result_disk_rn AS
                (
                SELECT 
                        host,
                        mount,
                        `USAGE`,
                        CASE WHEN substr(trim( '"' FROM available),-1) ='G' THEN  CAST(substr(trim( '"' FROM available),1,CHAR_LENGTH(trim( '"' FROM available)) - 1) AS DECIMAL(10.2)) * 1024 * 1024
                             WHEN substr(trim( '"' FROM available),-1) ='M' THEN  CAST(substr(trim( '"' FROM available),1,CHAR_LENGTH(trim( '"' FROM available)) - 1) AS DECIMAL(10.2)) * 1024 
                        END AS available_KB,
                        available,
                        create_time,
                        row_number() OVER (PARTITION BY host,mount ORDER BY create_time DESC ) AS rn 
                        FROM 
                            (
                                SELECT host,json_unquote(CAST(JSON_EXTRACT(metric_value,'$.mount')AS char(100) )) AS mount,
                                JSON_EXTRACT(metric_value,'$.available')  AS available,
                                json_unquote(CAST(JSON_EXTRACT(metric_value,'$.usage')AS char(100) )) AS `USAGE`,
                                create_time  
                                FROM  mysql_report.os_query_result
                                WHERE metric_type = 'disk_status' AND host='{host}' ORDER BY create_time )b
                )
                SELECT 
                mount,
                `USAGE`,
                trim( '"' FROM available) as available,
                CAST(max_disk_change AS SIGNED) as max_disk_change,
                CAST(avg_disk_change AS SIGNED) as avg_disk_change,
                CASE WHEN avg_disk_change=0 THEN 3650 ELSE CAST(available_KB DIV avg_disk_change AS SIGNED)END AS 'min_used_days', -- 最小可用时间(天)
                CASE WHEN max_disk_change=0 THEN 3650 ELSE CAST(available_KB DIV max_disk_change  AS SIGNED) END AS 'avg_used_days'-- 预期可用时间(天)
                FROM 
                (
                    SELECT 
                    host,
                    mount,
                    avg(CASE WHEN disk_change  < 0 and pre_disk_change < 0 THEN 0
                    		 WHEN disk_change  < 0 AND pre_disk_change >0 THEN pre_disk_change
                    		 WHEN disk_change  > 0 THEN disk_change
                    	end ) AS avg_disk_change, -- 平均变化量 (处理变化量为负数的情况，一般为手动释放空间口出现, 将变化量置为昨天的变化量, 昨天也小于0 ,则置为0)
                    max(disk_change) AS max_disk_change -- 最大变化量
                    FROM 
                    (
                        SELECT 
                        host,
                        mount,
                        available,
                        create_time,
                        available_KB ,
                        rn,
                        available_KB - LEAD(available_KB) OVER (PARTITION BY host,mount ORDER BY rn DESC ) AS disk_change, -- 磁盘变化量
                        LEAD(available_KB,2,0) OVER (PARTITION BY host,mount ORDER BY rn DESC ) - LEAD(available_KB,1,0) OVER (PARTITION BY host,mount ORDER BY rn DESC ) AS pre_disk_change -- 昨天的磁盘变化量
                        FROM
                            CTE_os_query_result_disk_rn
                        WHERE rn <=7 -- 取最近7天的数据用于计算
                    )c
                    GROUP BY host,mount
                )d
                JOIN 
                    (SELECT * FROM CTE_os_query_result_disk_rn WHERE rn =1)e
                USING(host,mount)
                ORDER BY mount"""


# html 格式化相关配置
# 行缩写
col_add_button = ["query", "lock_summary"]
# 配置metric_class 在html 页面展示的顺序
metric_order="'base_os_status','db_base_info','lOCK_INFO','sql_info','index_info','slave_info','db_performance_info','others_info'"
# 导航栏每一行显示几个列
cell_count = 5
# text_box 展示的metric
text_metric='innodb_status'




