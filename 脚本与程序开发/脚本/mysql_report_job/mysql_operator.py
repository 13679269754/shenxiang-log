#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
mysql_report_job/

date : 2024/4/22
comment : 提示信息
update : 24-05-24 去除这个runstat,这个字段不在起作用（用处不大，最初仅仅想用来标记问题sql,问题sql就不再执行了。但是会提升复杂度，并且多了与数据库的交互）
"""
import datetime
import json
import os
import traceback
from decimal import Decimal

import paramiko

import pandas as pd

pd.set_option('display.max_rows', None)
pd.set_option('display.max_columns', None)
pd.set_option('display.width', None)
pd.set_option('display.max_colwidth', None)

from pymysql.converters import conversions

from config import db_restore, html_path, split_report, sql_disk_status, col_add_button, metric_order, cell_count, \
    text_metric
import pymysql.cursors

from cryptography.fernet import Fernet

from metric_message import MetricMessage, QueryClass

from log_format import logger, log_decorator
from report_build import html_table_build_for_class, html_head, html_title, merge_values_to_list, html_service_title, \
    merge_values, html_goto_title, navigation_head, navigation_row_start, navigation_row_end, navigation_cell, \
    html_goto_catalogue, format_longdata, html_metric_type, text_box_html


class reporterOperator:
    def __init__(self):
        self.db_metric_object_list = [] # db_metric对象列表 在合并报告总保存全部的指标，分离报告中仅保存db相关指标
        self.os_metric_object_list = []  # os_metric对象列表
        self.query_object_list = [] # sql对象列表
        self.os_query_object_list = [] # os 相关指标的获取
        self.metric_report_format = {} # 将metric_object_list转化为二维字典，用于输出pandas生成表格
        self.html_body_dict = {} # 生成的html内容页面
        self.db_restore = db_restore
        self.db_restore_connect, self.db_restore_cursor = self.open(self.db_restore)
        self.db_reporter_list = self.get_reporter_list()
        self.os_reporter_list = self.get_os_reporter_list()

    @log_decorator
    def get_all_metric(self):
        # self.reset_runstat()
        self.get_metric()
        self.get_os_metric()
        return True

    @log_decorator
    def get_all_query(self):
        self.get_query()
        self.get_os_query()
        return True

    @log_decorator
    def insert_all_metric(self):
        self.insert_metric()
        self.insert_os_metric()
        return True

    def sort_metric(self):
        sql= """UPDATE mysql_report.metric_report_format a
                JOIN (
                    SELECT metric_class, metric_type, 
                           ROW_NUMBER() OVER (PARTITION BY metric_class ORDER BY metric_type) AS `rank`
                    FROM mysql_report.metric_report_format where deleted =0 
                ) b ON a.metric_class = b.metric_class AND a.metric_type = b.metric_type
                SET a.order_id = b.rank WHERE a.deleted = 0;"""
        success = self.update_one(self.db_restore_connect, sql, None)
        return True if success else False


    def get_reporter_list(self):
        db_restore_list=[]
        result=self.select_all(db_restore, 'select * from mysql_report.source_target where deleted = 0 and source_type = "db";',None)
        for value in result:
            db_target = {'host': value['host'], 'port': value['port'], 'user': decrypt_data(value['mysql_user']),
                         'password': decrypt_data(value['mysql_pass']), 'database': value['target_database'],'source_type': value['source_type']}
            db_restore_list.append(db_target)
        return db_restore_list


    def open(self, db_connect):
        conn = pymysql.connect(**db_connect,conv=conversions)
        cursor = conn.cursor(cursor=pymysql.cursors.DictCursor)
        return conn, cursor


    def close(self, cursor, conn):
        cursor.close()
        conn.close()


    def restore_execute(self, sql, args, isNeed=False):
        """
        执行
        :param isNeed 是否需要回滚
        """
        for value in self.db_reporter_list:
            conn, cursor = self.open(value)
            if isNeed:
                try:
                    cursor.execute(sql, args)
                    conn.commit()
                except:
                    conn.rollback()
            else:
                cursor.execute(sql, args)
                conn.commit()
            self.close(conn, cursor)


    def target_execute(self, db_connect, sql, args, isNeed=False):
        """
        执行
        :param isNeed 是否需要回滚
        """
        conn, cursor = self.open(db_connect)
        if isNeed:
            try:
                cursor.execute(sql, args)
                conn.commit()
            except Exception as err:
                logger.error(str(sql) + "\nerror:" + str(err))
                conn.rollback()
        else:
            cursor.execute(sql, args)
            conn.commit()
        self.close(conn, cursor)


    def select_one(self, db_connect, sql, *args):
        """查询单条数据"""
        conn, cursor = self.open(db_connect)
        cursor.execute(sql)
        result = cursor.fetchone()
        self.close(conn, cursor)
        return result

    def select_all(self, db_connect, sql, args):
        """查询多条数据"""
        conn, cursor = self.open(db_connect)
        cursor.execute(sql, args)
        result = cursor.fetchall()
        self.close(conn, cursor)
        return result

    def insert_one(self, db_connect, sql, args):
        """插入单条数据"""
        self.target_execute(db_connect, sql, args, isNeed=True)

    def insert_all(self, db_connect, sql, datas):
        """插入多条批量插入"""
        conn, cursor = self.open(db_connect)
        try:
            cursor.executemany(sql, datas)
            conn.commit()
            return {'result': True, 'id': int(cursor.lastrowid)}
        except Exception as err:
            conn.rollback()
            return {'result': False, 'err': err}

    def update_one(self, db_connect, sql, args):
        """更新数据"""
        self.target_execute(db_connect,sql, args, isNeed=True)

    def delete_one(self, db_connect, sql, *args):
        """删除数据"""
        self.target_execute(db_connect, sql, args, isNeed=True)

    def get_query(self):
        sql_result = self.select_all(self.db_restore,
                                 """select  a.name, a.run ,a.skip_instance, a.runstat, a.create_time, a.create_user, a.remark, a.deleted,b.metric_class, b.order_id ,b.navigation_name
                                        from mysql_report.report_sql a 
                                        left join  mysql_report.metric_report_format b  
                                        on  a.name = b.metric_type  
                                        where a.deleted = 0 and b.deleted = 0   
                                        order by metric_class, order_id;""", None)
        for db_info in self.db_reporter_list:
            for row_value in sql_result:
                if row_value['skip_instance']is not None and row_value['skip_instance'].find(str(db_info['host']) + ':' + str(db_info['port'])) != -1:
                    continue
                self.query_object_list.append(QueryClass(row_value, db_info))
        return self.query_object_list


    def get_metric(self):
        # 重置当天的sql运行状态
        for query_object in self.query_object_list:
            db_info = {'host': query_object.host, 'port': query_object.port, 'user': query_object.user, 'password': query_object.password, 'database': query_object.database}
            logger.debug('--------  开始执行：' + query_object.run + '  ---------')
            result=self.select_all(db_info, query_object.run,None)
            if result is not None:
                for row in result:
                    self.db_metric_object_list.append(MetricMessage(str(db_info['host']) + ':' + str(db_info['port']), query_object.query_class, query_object.name, row))
            else:
                self.db_metric_object_list.append(MetricMessage(str(db_info['host']) + ':' + str(db_info['port']), query_object.query_class, query_object.name, query_object.name))
            # self.update_runstat(query_object) --废弃
        return self.db_metric_object_list


    def insert_metric(self):
        for metric_obj in self.db_metric_object_list:
            try:
                metric_value_json = json.dumps(metric_obj.metric_value, default=custom_serializer).replace("'", "\\'").replace('\n', '\\n')
            except Exception as e:
                traceback.print_exc()
                print(metric_obj.metric_value)
            sql = f"""insert into  mysql_report.sql_result(host,metric_name,metric_type,metric_value) values ( '{metric_obj.host}', '{metric_obj.metric_class}', '{metric_obj.metric_type}', '{metric_value_json}' )"""
            self.insert_one(self.db_restore,sql,None)

    def metric_report_format(self):
        for metric_obj in self.db_metric_object_list:
            self.metric_report_format[metric_obj.host][metric_obj.metric_class] = metric_obj.metric_value
    # 废弃
    '''
    def update_runstat(self, metric_obj, metric_from='db'):
        if metric_from == 'db':
            sql = f"""update mysql_report.report_sql set runstat = '1' where name = '{metric_obj.name} and deleted=0 '"""
        elif metric_from == 'os':
            sql = f"""update mysql_report.report_os set runstat = '1' where name = '{metric_obj.name} and deleted=0 '"""
        else:
            sql = ''
        self.update_one(self.db_restore,sql,None)

    def reset_runstat(self):
        # 将上一次未执行成功的sql语句标记为执行失败，并不在参与后续执行 重置report_sql相关的信息
        sql = f"""update mysql_report.report_sql set runstat = '2' where runstat = '0' and deleted=0"""
        self.update_one(self.db_restore, sql, None)
        # 将上一次执行成功的sql语句执行状态重置
        sql = f"""update mysql_report.report_sql set runstat = '0' where runstat = '1' and deleted=0"""
        self.update_one(self.db_restore,sql,None)
        # 重置os_query_result相关的信息
        sql = f"""update mysql_report.report_os set runstat = '2' where runstat = '0' and deleted=0"""
        self.update_one(self.db_restore, sql, None)
        # 将上一次执行成功的os_query语句执行状态重置
        sql = f"""update mysql_report.report_os set runstat = '0' where runstat = '1' and deleted=0"""
        self.update_one(self.db_restore,sql,None)
    '''

    def html_table_build(self,reporter_list):
        """构建单个输出网页(分开版本)"""
        for db_info in reporter_list:
            html_body = ''
            sql = "select metric_class,remark,navigation_name from mysql_report.metric_report_format where deleted=0 group by metric_class,remark;"
            result = self.select_all(self.db_restore, sql, None)
            for index, value in enumerate(result):
                # 如果 remark 为null 就显示为 metric_class 的值,否则显示remark
                if value['remark'] is None or value['remark'] == '':
                    metric_class_name = value['metric_type']
                else:
                    metric_class_name = value['remark']
                # 获取单个指标的dataframe,需要根据host：port,class_name切分，分别进行dataframe表格的构建
                df_html = self.df_html_build(value['remark'],
                                             str(db_info['host']) + ':' + str(db_info['port']),metric_class_name)
                # 2024-06-05 添加导航栏跳转标签
                navigation_tag=html_goto_title.format(metric_name_for_goto=value['navigation_name'])
                html_body = html_body + navigation_tag + df_html
            self.html_body_dict[str(db_info['host']) + '_' + str(db_info['port'])] = html_body

    def html_table_merge_build(self):
        """构建单个输出网页（合并版本）"""
        reporter_list = self.os_reporter_list + self.db_reporter_list
        for db_info in reporter_list:
            html_body = html_service_title.format(host_port=str(db_info['host']) + ':' + str(db_info['port']))
            sql = f"""select metric_class , metric_type , source_type ,a.remark ,navigation_name ,b.navigation_1_name AS navigation_1_name , a.order_id as order_id from mysql_report.metric_report_format a 
                     left  join  mysql_report.navigation_table b on b.navigation_2_level =a.navigation_name  
                     WHERE a.deleted=0 AND b.deleted=0
                     group by metric_class, metric_type , source_type, remark ,navigation_name,navigation_1_name,order_id order by source_type DESC ,FIELD(metric_class, {metric_order}),order_id  ;"""
            result = self.select_all(self.db_restore, sql, None)

            # 记录上一次的指标类型和当前指标类型确认是否需要输出指标分类名称
            metric_class_old = None
            metric_class_now = None

            for index, value in enumerate(result):
                if value['remark'] is None or value['remark'] == '':
                    metric_class_name = value['metric_type']
                else:
                    metric_class_name = value['remark']
                # 对当前的metric_class_now 赋值
                metric_class_now = value['metric_class']
                if value['source_type'] == db_info['source_type']: # 仅仅才指标类型属于时才尝试获取这个属于这个source_type类型的metric_class
                    # 获取单个指标的dataframe,需要根据host：port,class_name切分，分别进行dataframe表格的构建
                    html_metric_class = ''
                    if metric_class_old != metric_class_now:
                        html_metric_class = html_metric_type.format(metric_type=value['navigation_1_name'])

                    # 对不需要表格化的仅仅显示数据结果采用text_box
                    df_html = self.df_html_build(value['metric_type'],
                                                 str(db_info['host']) + ':' + str(db_info['port']),metric_class_name)
                    # 2024-06-05 添加导航栏跳转标签
                    navigation_tag = html_goto_title.format(metric_name_for_goto=value['navigation_name'])
                    html_body = html_body + html_metric_class + navigation_tag  + df_html
                    # 将当前的指标类型赋值给上metric_class_old
                    metric_class_old = metric_class_now
            # 相同的host的service报告拼接，不同host 正常写入dict
            merge_values(self.html_body_dict, str(db_info['host']),html_body)

    @log_decorator
    def metric_result_html_format(self):
        """构建输出网页，并将输出到文件中"""
        if not split_report:
            # 合并report页面
            self.html_table_merge_build()
            self.write_html_file()
        else:
            # 分解report页面
            reporter_list = self.db_reporter_list
            self.html_table_build(reporter_list)
            reporter_list = self.os_reporter_list
            self.html_table_build(reporter_list)
            self.write_html_file()
        return True



    def write_html_file(self):
        """将输出到文件中
            2024-06-06 添加导航栏到html 大标题下
        """
        date = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
        for host, html_body in self.html_body_dict.items():
            html_css_title = "<html>\n" + html_head + html_title.format(host=host, date=date)
            # 2024-06-06 添加导航栏
            html_body = html_css_title + self.build_navigation() + html_body
            html_body = html_body + html_goto_catalogue
            # 目录和文件是否存在检查
            if not os.path.exists(html_path):
                os.makedirs(html_path)
            if split_report:
                if os.path.exists(f'{html_path}/{host}_report_{date}.html') :
                    raise Exception(f'{html_path}/{host}_report_%_{date}.html 已存在，不可重复创建')
                # 生成html文件
                with open(f'{html_path}/{host}_report_{date}.html', 'w') as file:
                    file.write(html_body)
            else :
                if os.path.exists(f'{html_path}/{host}_report_{date}.html'):
                    raise Exception(f'{html_path}/{host}_report_{date}.html 已存在，不可重复创建')
                # 生成html文件
                with open(f'{html_path}/{host}_report_{date}.html', 'w') as file:
                    file.write(html_body)


    def df_html_build(self,metric_class, host_port,metric_class_name):
        """
        metric_class 为指标类型，
        host_port 为指标类型的主机和端口，
        metric_class_name 为指标类型的名称 作为格式化html 页面的表格标题"""


        if metric_class_name is None or metric_class_name == '':
            metric_class_name = metric_class
        df_html_class = {}
        df_html = None
        is_muti_row = False
        muti_index = None
        for metric_obj in (self.db_metric_object_list + self.os_metric_object_list):
            # 构建二维字典
            if str(host_port) == str(metric_obj.host) and str(metric_obj.metric_type) == str(metric_class):
                # 处理指标名称已经有的数据行
                if metric_obj.metric_type in df_html_class:
                    merge_values_to_list(df_html_class, metric_obj.metric_type,metric_obj.metric_value)
                    is_muti_row = True
                    # 多行数据应该单独显示,不会与其他指标公用一个dataframe表格
                    muti_index = metric_obj.metric_type
                # 指标名称不存在的数据行的添加新的指标名称
                else :
                    # 如果指标是text_box 指标则不生成表格
                    if metric_obj.metric_type in text_metric:
                        return text_box_html(str(metric_obj.metric_value).replace('\\n','\n'),metric_class_name)
                    else :
                        df_html_class[metric_obj.metric_type] = metric_obj.metric_value


            else :
                continue



        # 生成DataFrame表格形式
        if  df_html_class and not is_muti_row:
            df = pd.DataFrame.from_dict(df_html_class, orient='index' )
            # 格式化长行的数据，对过长的列做处理，添加一个botton显示完整信息 --2024-06-17
            if any(col in df.columns for col in col_add_button):
                self.button_for_detall(df)

            df_html = df.to_html(escape=False,justify='center') # DataFrame数据转化为HTML表格形式
        # 一个metric_type多行结果的处理
        elif df_html_class and is_muti_row:
            df = pd.DataFrame(df_html_class[muti_index])
            # 添加一个新列作为行标题
            df[muti_index] = [muti_index] * len(df)

            # 设置 新列作为索引
            df.set_index(muti_index, inplace=True)

            # 格式化长行的数据，对过长的列做处理，添加一个botton显示完整信息 --2024-06-17
            if any(col in df.columns for col in col_add_button):
                self.button_for_detall(df)

            df_html = df.to_html(escape=False,justify='center') # DataFrame数据转化为HTML表格形式l

        return html_table_build_for_class(df_html,metric_class_name)

    # 添加一个botton显示完整信息 --2024-06-25
    def button_for_detall(self, df):
        for col in col_add_button:
            if  col in df.columns  and df[col] is not None:
                df[col] = df[col].apply(format_longdata)
        return True


    # os_query 相关方法
    def get_os_reporter_list(self):
        os_reporter_list = []
        sql_result = self.select_all(self.db_restore,
                                 """select * from mysql_report.source_target where deleted = 0 and source_type = "os";""", None)
        for value in sql_result:
            os_target = {'host': value['host'], 'port': value['port'], 'user': decrypt_data(value['mysql_user']),
                         'password': decrypt_data(value['mysql_pass']), 'database': value['target_database'],'source_type':value['source_type']}
            os_reporter_list.append(os_target)
        return os_reporter_list


    def get_os_query(self):
        sql_result = self.select_all(self.db_restore,
                                 """select  a.name, a.run ,a.skip_instance, a.runstat, a.create_time, a.create_user, a.remark, a.deleted,b.metric_class, b.order_id, a.calculate_fun
                                        from mysql_report.report_os a 
                                        left join  mysql_report.metric_report_format b  
                                        on  a.name = b.metric_type  
                                        where a.deleted = 0  
                                        order by metric_class, order_id;""", None)
        for os_info in self.os_reporter_list:
            for row_value in sql_result:
                if row_value['skip_instance']is not None and row_value['skip_instance'].find(str(os_info['host']) + ':' + str(os_info['port'])) != -1:
                    continue
                self.os_query_object_list.append(QueryClass(row_value, os_info))
        return self.os_query_object_list


    def get_os_metric(self):
        for os_query_object in self.os_query_object_list:
            create_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            os_info = {'host': os_query_object.host, 'port': os_query_object.port, 'user': os_query_object.user, 'password': os_query_object.password}
            output, error=exec_command(os_info,os_query_object.run)
            if output is not None:
                for row in output.split("\n"):
                    if row == '':
                        continue
                    self.os_metric_object_list.append(MetricMessage(str(os_info['host']) + ':' + str(os_info['port']) ,os_query_object.query_class, os_query_object.name ,json.loads(row) ))
            # runstat 的逻辑已经被放弃
            # self.update_runstat(os_query_object,metric_from='os')
        return self.os_metric_object_list


    def insert_os_metric(self):
        for metric_obj in self.os_metric_object_list:
            metric_value_json = json.dumps(metric_obj.metric_value).replace("'", "\\'").replace('\n', '\\n')
            sql = f"""insert into mysql_report.os_query_result(host,metric_name,metric_type,metric_value,create_time) values ( '{metric_obj.host}', '{metric_obj.metric_class}', '{metric_obj.metric_type}', '{metric_value_json}', '{metric_obj.create_time}');"""
            self.insert_one(self.db_restore,sql,None)

    # handle相关方法 -- 目前仅在os 相关变量中支持，数据库相关建议sql解决,如需与旧数据进行聚合等操作,请填充db_calculate_fun_handle方法
    def os_calculate_fun_handle(self):
        calculate_metric_list = []
        for query_obj in self.os_query_object_list:
            if query_obj.calculate_fun is not None:
                function_to_call = getattr(self, query_obj.calculate_fun, None)
                if function_to_call:
                    # os_query_object_list 会根据host 与 os_query组合,调用一次计算方法只会对单一的host进行计算，并对指标值进行处理
                    calculate_metric_list = calculate_metric_list  + function_to_call(query_obj)
        # 用处理过后的结果集取代未处理的结果集
        self.os_metric_object_list = calculate_metric_list

    def db_calculate_fun_handle(self):
        pass
        # calculate_metric_list = []
        # for query_obj in self.os_query_object_list:
        #     if query_obj.calculate_fun is not None:
        #         function_to_call = getattr(self, query_obj.calculate_fun, None)
        #         if function_to_call:
        #             # os_query_object_list 会根据host 与 os_query组合,调用一次计算方法只会对单一的host进行计算，并对指标值进行处理
        #             calculate_metric_list = calculate_metric_list  + function_to_call(query_obj)
        # # 用处理过后的结果集取代未处理的结果集
        # self.os_reporter_list = calculate_metric_list



    def disk_handle(self,query_obj):
        """

        :param query_obj 传入需要处理的sql指标,获取host,metric_type(name) 的值，用于对未计算 指标的替换:
        :return: 针对单一host的指标的重新计算结果,可与其他host的结果进行并集计算得到全部处理过后的指标

        该方法针对host的指标值进行处理,
        """
        # 获取新的计算结果集
        sql = sql_disk_status.format(host=(str(query_obj.host) + ':' + str(query_obj.port)))
        sql_result = self.select_all(self.db_restore, sql, None)
        if sql_result :
            # os metric 添加计算指标
            # 重新生成os_metric_object_list
            os_metric_object_calculated_list=[]
            os_metric_object_without_calculated_list = []
            for  index,os_metric in enumerate(self.os_metric_object_list):
                if os_metric.host.split(':')[0] == query_obj.host:
                    if os_metric.metric_type == query_obj.name :
                        # 需要计算值的指标数据不再直接写入结果集list中，在循环结束时，重新写入新的结果集
                        # 删除 -- 此处直接物理删除可能不太安全
                        sql = f"""delete from mysql_report.os_query_result  where metric_type = '{os_metric.metric_type}' and host = '{os_metric.host}' and metric_name = '{os_metric.metric_type}' and create_time = '{os_metric.create_time}'"""
                        self.update_one(self.db_restore, sql, None)
                    else :
                        os_metric_object_without_calculated_list.append(os_metric)
            for row in sql_result:
                os_metric_object_calculated_list.append(MetricMessage(str(query_obj.host)+ ':' + str(query_obj.port), query_obj.query_class, query_obj.name, row))

            for metric_obj in os_metric_object_calculated_list:
                try:
                    metric_value_json = json.dumps(metric_obj.metric_value, default=custom_serializer).replace("'",
                                                                                                               "\\'").replace(
                        '\n', '\\n')
                except Exception as e:
                    traceback.print_exc()
                    print(metric_obj.metric_value)
                sql = f"""insert into  mysql_report.os_query_result(host,metric_name,metric_type,metric_value) values ( '{metric_obj.host}', '{metric_obj.metric_class}', '{metric_obj.metric_type}', '{metric_value_json}' )"""
                logger.debug("计算指标写入sql:"+sql)
                self.insert_one(self.db_restore, sql, None)

            # 重新复制给os_metric_object_list
            return  os_metric_object_without_calculated_list + os_metric_object_calculated_list

        else :
            logger.error(f'{query_obj.name}计算结果为空，请检查计算sql是否正确：{sql}')


# 构建导航页
    def build_navigation(self):
        # 控制每行只保留5个cell,同一个标签的下多余5个的换下一行显示
        navigation_table = navigation_head
        sql_tr=f""" select navigation_1_level, CEIL(count(1) / 5) as rowspan,navigation_1_name  
                    FROM (
                    SELECT a.id,navigation_1_level,navigation_1_name
                        FROM mysql_report.navigation_table a
                        JOIN mysql_report.metric_report_format c 
                        ON c.navigation_name  = a.navigation_2_level
                        WHERE  a.deleted = 0 and c.deleted = 0 
                        GROUP BY a.id,navigation_1_level,navigation_1_name
                    ) t
                    group by navigation_1_level,navigation_1_name 
                    order by min(t.id);"""
        table_tr = self.select_all(self.db_restore, sql_tr, None)
        # 循环构架导航表格的每一行
        for row_tr in table_tr:
            now_cell_count=0
            navigation_table =navigation_table + navigation_row_start.format(rowspan = row_tr['rowspan'],href_link = row_tr['navigation_1_level'],row_title = row_tr['navigation_1_name'])
            sql_td=f"""
                    select 
                    navigation_1_level,
                    navigation_2_level,
                    case when a.navigation_2_name is NULL then max(c.remark) else a.navigation_2_name end as navigation_2_name, 
                    navigation_2_prompt
                    from mysql_report.navigation_table a 
                    JOIN mysql_report.metric_report_format c 
                    ON c.navigation_name  = a.navigation_2_level
                    where navigation_1_level = '{row_tr['navigation_1_level']}' and a.deleted = 0 and c.deleted = 0
                    GROUP BY navigation_1_level,navigation_2_level, a.navigation_2_name,navigation_2_prompt ORDER BY min(a.id); """
            table_td = self.select_all(self.db_restore, sql_td, None)
            # 循环构建导航表格的单元格
            for row in table_td:
                navigation_table = navigation_table + navigation_cell.format(navigation_2_level=row['navigation_2_level'],navigation_2_name=row['navigation_2_name'],cellspan=row['navigation_2_prompt'])
                now_cell_count += 1
                # 在一行中有5个cell时，换行
                if now_cell_count == cell_count:
                    navigation_table = navigation_table + "</tr><tr>"
                    now_cell_count = 0
            # 如果没有对应指标的补充空的cell
            while now_cell_count < cell_count:
                navigation_table = navigation_table + navigation_cell.format(navigation_2_level="",navigation_2_name="",cellspan="")
                now_cell_count += 1
            navigation_table = navigation_table + navigation_row_end
        navigation_table = navigation_table + '</table>'
        return navigation_table





def decrypt_data(encrypted_data):
    cipher = Fernet('pT8ZDjwCvnWkfPEYBm12q2p9srNkM-nWC6Ss9aAcMEw=')
    # 解密数据
    decrypted_data = cipher.decrypt(encrypted_data.encode()).decode()
    return decrypted_data


def encrypt_data(data):
    cipher = Fernet('pT8ZDjwCvnWkfPEYBm12q2p9srNkM-nWC6Ss9aAcMEw=')
    # 加密数据
    encrypted_data = cipher.encrypt(data.encode()).decode()
    return encrypted_data


def custom_serializer(obj):
    if isinstance(obj, datetime.datetime):
        return obj.strftime('%Y-%m-%d %H:%M:%S')
    if isinstance(obj, Decimal):
        return str(obj)
    if isinstance(obj, bytes):
        return obj.decode('utf-8')
    raise TypeError

def init_db(db_config):
    conn = pymysql.connect(**db_config)
    cursor=conn.cursor(cursor=pymysql.cursors.DictCursor)
    cursor.execute('select * from information_schema.tables WHERE table_schema ="mysql_report";')
    row_count = cursor.rowcount

    if row_count != 3:
        try:
            # 读取 SQL 脚本文件
            with open('init.sql', 'r') as file:
                sql_script = file.read()

            # 按照分号分割 SQL 语句并去除末尾可能的空行
            sql_commands = sql_script.split(';\n')
            sql_commands = [cmd.strip() for cmd in sql_commands if cmd.strip()]

            # 拼接分布在多行的 SQL 语句
            for i in range(len(sql_commands)):
                sql_commands[i] = ' '.join(sql_commands[i].split())

            # 逐条执行 SQL 语句
            for cmd in sql_commands:
                logger.debug(f'执行 SQL 语句：{cmd};')
                cursor.execute(cmd+';')
        except  pymysql.OperationalError as e:
            print(e)
    logger.info("初始化已经完成!")
    conn.commit()
    cursor.close()
    conn.close()

def exec_command(os_info, command):
    output = None
    error = None

    host = os_info['host']
    user = os_info['user']
    password = os_info['password']
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host, username=user, password=password)
    stdin, stdout, stderr = ssh.exec_command(command)
    output = stdout.read().decode()
    error = stderr.read().decode()
    ssh.close()

    return output, error


