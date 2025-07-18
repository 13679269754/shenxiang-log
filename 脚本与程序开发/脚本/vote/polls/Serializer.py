#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
vote/

author: shen
date : 2023/11/10
comment : 提示信息
"""

from rest_framework import serializers

from polls.models import Subject, Teacher


class SubjectSerializer(serializers.ModelSerializer):

    class Meta:
        model = Subject
        fields = '__all__'


class TeacherSerializer(serializers.ModelSerializer):

    class Meta:
        model = Teacher
        exclude = ('subject', )
