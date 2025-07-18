#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
mysql_report_job/

date : 2024/4/23
comment : 提示信息
"""
import json
import subprocess

from config import create_time
from log_format import logger


class QueryClass(object):
    def __init__(self,row_data,db_info):
        """
        初始化对象
        :param row_data: sql相关数据，来自report_sql表,该表保存需要在目标库执行的sql语句信息
        :param db_info: 数据库相关数据，来自目标库配置表

        """
        self.mysql_runstat=row_data['runstat']
        self.run=row_data['run']
        self.name=row_data['name']
        self.create_time=row_data['create_time']
        self.create_user=row_data['create_user']
        self.remark=row_data['remark']
        self.deleted=row_data['deleted']
        self.host=db_info['host']if db_info['host'] else '127.0.0.1'
        self.port=db_info['port']if db_info['port'] else 3306
        self.user=db_info['user']if db_info['user'] else 'root'
        self.password=db_info['password']if db_info['password'] else '123456'
        self.database=db_info['database']if db_info['database'] else 'mysql'
        self.query_class=row_data['metric_class']
        # 针对指标需要执行的计算方法 -- 一般为聚合,需要结合多日的数据
        self.calculate_fun=row_data['calculate_fun'] if 'calculate_fun' in row_data.keys() else None
        # 导航页名称
        self.nagavition_name=row_data['nagavition_name'] if 'nagavition_name' in row_data.keys() else None




class MetricMessage(object):
    def __init__(self,host, metric_class, metric_type, metric_value):
        self.host=host
        self.metric_class=metric_class
        self.metric_type=metric_type
        self.metric_value=metric_value
        self.create_time=create_time




