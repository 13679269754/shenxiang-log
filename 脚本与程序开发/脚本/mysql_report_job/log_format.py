#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
mysql_report_job/

date : 2024/4/22
comment : 提示信息
"""
import functools
import subprocess

import nb_log
from config import log_path

logger = nb_log.get_logger('mysql_report_job',log_path=log_path,log_filename='mysql_report_job.log',error_log_filename='mysql_report_job_error.log')


def log_decorator(func):
    """提示输出，错误处理统一入口，用于所有函数调用"""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        logger.info(f'--------------- 开始执行函数 {func.__name__}')
        try:
            result = func(*args, **kwargs)
            if result:
                logger.info(f'--------------- {func.__name__} 执行成功')
            else:
                raise Exception(f'--------------- {func.__name__} 执行失败')
            return result
        except Exception as e:
            import traceback
            traceback.print_exc()
            logger.error(e)
            exit(0)
        except subprocess.CalledProcessError as e:
            import traceback
            traceback.print_exc()
            logger.error(e.stdout.decode('utf-8'))
            exit(0)
    return wrapper

// Place
your
全局
snippets
here.Each
snippet is defined
under
a
snippet
name and has
a
scope, prefix, body and
// description.Add
comma
separated
ids
of
the
languages
where
the
snippet is applicable in the
scope
field.If
scope
// is left
empty or omitted, the
snippet
gets
applied
to
all
languages.The
prefix is what is
// used
to
trigger
the
snippet and the
body
will
be
expanded and inserted.Possible
variables
are:
// $1, $2
for tab stops, $0 for the final cursor position, and ${1:label}, ${2: another}
for placeholders.
    // Placeholders
    with the same ids are connected.