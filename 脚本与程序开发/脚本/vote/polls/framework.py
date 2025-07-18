#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
vote/

author: shen
date : 2023/11/10
comment : 提示信息
"""

from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.http import HttpResponse, HttpRequest

from polls.Serializer import SubjectSerializer
from polls.models import Subject


@api_view(('GET', ))
def show_subjects(request: HttpRequest) -> HttpResponse:
    subjects = Subject.objects.all().order_by('no')
    # 创建序列化器对象并指定要序列化的模型
    serializer = SubjectSerializer(subjects, many=True)
    # 通过序列化器的data属性获得模型对应的字典并通过创建Response对象返回JSON格式的数据
    return Response(serializer.data)
