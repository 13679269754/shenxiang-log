"""
mysql sql 执行

author: shen
"""
import logging as log
import threading
import time
from threading import Thread
import pymysql

DB_TARGET = {
    'host': '172.29.28.193',
    'port': 3306,
    'user': 'dzjroot',
    'password': '12345678',
    'database': 'new_db'
}

DB_CONFIG = {
    'host': '172.29.28.193',
    'port': 3306,
    'user': 'dzjroot',
    'password': '12345678',
}

database = 'merge_into'
table = 'merge_into_produce'
# 綫程并行度
max_thread = 4
# status 0：全量数据初始化，1：增量数据，2：更新_sql失败，3：跳过更新_sql，4：更新_sql运行中
run_status = (0, 1, 2, 3, 4)

# 日志配置
log.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        log.StreamHandler(),  # Output to console
        log.FileHandler('log_file.log')  # Output to file
    ],
    level=log.INFO)
main_logger = log.getLogger('MYSQL-ETF')


def connect(instants):
    """ 连接数据库

    :param instants: 数据库连接字符串
    :return: 数据库连接对象
    """
    try:
        con_comp = pymysql.connect(**instants)
    except pymysql.err.Error as e:
        connect_logger = log.getLogger('CONNECT-ERROR')
        connect_logger.exception(instants, str(e))
    return con_comp


# 自定义线程类
class DbMergeInto(Thread):
    """sql执行线程类

    :param sql_id: sql id
    :param sql_text: sql text
    :param conf_db: 数据库连接串
    :param last_time: 更新时间
    :param _run_status: sql状态 0,1
    """

    def __init__(self, sql_id, sql_text, conf_db, last_time, run_status, table_name):
        super().__init__()
        self._conf_db = conf_db
        self._sql_id = sql_id
        self._sql_text = sql_text
        self._last_time = last_time
        self._run_status = run_status
        self._table_name = table_name

    def run(self):
        """
        执行
        :return: sql 影响行数
        """
        with connect(self._conf_db) as _connect_db:
            try:
                _cursor = _connect_db.cursor()
                # format 更新时间 条件，增量更新
                if self._run_status == 0:
                    _cursor.execute(self._sql_text.format(MODIFY_DBA_TIME='1=1'))
                elif self._run_status != 0 and self._last_time:
                    _cursor.execute(self._sql_text.format(
                        MODIFY_DBA_TIME=f"""modify_dba_time is not null and modify_dba_time > '{self._last_time}'"""))
                else:

                    _cursor.execute(self._sql_text.format(MODIFY_DBA_TIME='1=1'))
                print(self._sql_text.format(MODIFY_DBA_TIME='1=1'))
            except pymysql.err.Error as e:
                threads_logger = log.getLogger('THREAD-ERROR')
                threads_logger.exception(self._sql_text, str(e))
                _connect_db.rollback()
            finally:
                global row_affect
                row_affect = _cursor.rowcount
                _connect_db.commit()
                main_logger.info(f"sql影响行数:{row_affect}")
                main_logger.info("{0:=^50}".format('sql:' + str(self.sql_id) + '执行完毕'))

    @property
    def table_name(self):
        return self._table_name

    @property
    def sql_id(self):
        return self._sql_id


def init_configdb():
    with connect(DB_CONFIG) as CONN:
        _cursor = CONN.cursor()
        sql_init = ["CREATE DATABASE IF NOT EXISTS merge_into;",
                    "USE merge_into;",
                    """CREATE TABLE IF NOT EXISTS merge_into_produce
                    (id INT PRIMARY KEY AUTO_INCREMENT COMMENT '自增主键',
                    run_status INT COMMENT 'sql状态',
                    table_schema varchar(255) COMMENT '目标库名',
                    table_name varchar(255) COMMENT '目标表明',
                    comment varchar(255) COMMENT '更新_sql注释',
                    start_time datetime COMMENT '更新_sql开始时间',
                    end_time datetime COMMENT '更新_sql结束时间',
                    sql_text text COMMENT '更新_sql名称',
                    UNIQUE KEY `uk_child_comment_code`(`table_schema`,`table_name`,`comment`) USING BTREE);""",
                    """create table if NOT EXISTS etl_threads (id INT primary key auto_increment COMMENT '自增主键',
                    thread_id INT COMMENT '线程id',
                    sql_id text COMMENT '更新_sql_id',
                    start_time datetime COMMENT '更新_sql开始时间',
                    end_time datetime COMMENT '更新_sql结束时间'
                    ) ;"""
                    ]
        for sql in sql_init:
            try:
                _cursor.execute(sql)
            except pymysql.err.Error as e:
                main_logger.exception(sql, str(e))
            return


def sql_table_check(conf_db):
    """ sql 表检查

    :param conf_db: sql配置数据库连接
    :return:
    """
    _cursor = conf_db.cursor()
    # 获取表merge_into.merge_into_produce 中的数据,以threads作为并行度
    _cursor.execute("select count(*) from merge_into.merge_into_produce where run_status  in (0,1)")
    counts = _cursor.fetchone()
    if counts[0] > 0:
        main_logger.info(f'需要调用存储更新_sql : {counts[0]} 个')
        return _cursor
    else:
        main_logger.info('没有sql需要执行')
        raise RuntimeError('没有sql需要执行')


# 全局线程数
global thread_count
# 全局线程对象列表
global threads
# sql影响行数
global row_affect
threads = []


def _run_sql():
    """sql 执行

    :return:  None
    """
    with connect(DB_TARGET) as _conn:
        cursor = sql_table_check(_conn)
        cursor.execute("""select id,sql_text,date_add(start_time,INTERVAL -1  MINUTE ) , run_status ,concat(table_schema,'.',
        table_name)from merge_into.merge_into_produce where run_status  in (0,1)""")
        etl_procedures = cursor.fetchall()
        for rowInfo in etl_procedures:
            # 创建线程
            try:
                _thread_count = len(threading.enumerate()[3:]) if threading.enumerate()[3:] else 0
                if _thread_count <= max_thread:
                    # 创建sql线程
                    _thread_sql = DbMergeInto(rowInfo[0], rowInfo[1], DB_TARGET, rowInfo[2], rowInfo[3], rowInfo[4])
                    main_logger.info("{0:=^50}".format('sql:' + str(rowInfo[0]) + '开始执行'))
                    # 添加到线程列表
                    threads.append(_thread_sql)
                    # 启动线程
                    _thread_sql.daemon = True
                    _thread_sql.start()
                    _thread_count = len(threads)
            except Exception as e:
                main_logger.exception(f"""error: sql_id:{rowInfo[0]}- {rowInfo[3]} """
                                      , str(e))
            finally:
                time.sleep(1)
        is_thread_run(_threads=threads, process_on_run=thread_running_print)
        is_thread_run(_threads=threads, process_on_run=Thread.join)
    return


def thread_running_print(thread=None):
    """输出当前线程执行信息

    :param thread:
    """
    if thread:
        thread_id = threads.index(thread) + 1
        table_name, sql_id = thread.table_name, thread.sql_id
        main_logger.info(f'当前线程id：{thread_id},位于表名{table_name}的sql{sql_id} 执行中......')
    else:
        main_logger.exception('thread_running_print 参数获取失败.')
    time.sleep(1)


def is_thread_run(*, _threads, process_on_run, **kwargs):
    """线程运行中执行的过程

    :param _threads: 线程列表
    :param process_on_run: 需要在线程执行过程中执行的方法
    :param kwargs: process_on_run 命名参数列表
    :return:
    """
    # 获取当前全部子线程
    while _threads:
        for thread in _threads:
            if thread.is_alive():
                process_on_run(thread)
            else:
                _threads.remove(thread)


def main():
    # 初始化配置表
    init_configdb()

    _run_sql()


if __name__ == '__main__':
    main()
