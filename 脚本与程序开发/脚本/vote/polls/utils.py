#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
vote/

author: shen
date : 2023/11/8
comment : 提示信息
"""

import hashlib
import random
from django.http import HttpResponse, HttpRequest
import polls.Captcha as Captcha


def gen_md5_digest(content):
    return hashlib.md5(content.encode()).hexdigest()


ALL_CHARS = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'


def gen_random_code(length=4):
    return ''.join(random.choices(ALL_CHARS, k=length))


def get_captcha(request: HttpRequest) -> HttpResponse:
    """验证码"""
    captcha_text = gen_random_code()
    request.session['captcha'] = captcha_text
    image_data = Captcha.instance().generate(captcha_text)
    return HttpResponse(image_data, content_type='image/png')