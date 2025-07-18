"""
test_python_queue.py

author: shen
date : 2023/8/7
comment :
"""
import datetime
import math
import queue
import threading
import pymysql
from dbutils.pooled_db import PooledDB


# python 关于多进程与多线程且写入同一文件情况 http://sunsunsir.cn/deta

class processing:

    def __init__(self, write_file, host='172.29.28.193', user_name='dzjroot', password='12345678', db='sql_exec', maxconnections=5,
                 thread_num=5):
        # 创建数据库连接池
        self.pool = PooledDB(creator=pymysql, maxconnections=maxconnections, maxshared=maxconnections, host=host,
                             user=user_name,
                             passwd=password, db=db, port=3306, charset="utf8")
        # 线程数
        self.thread_num = thread_num

        # 写文件
        self.write_file = write_file

        # 锁
        self.lock = threading.Lock()

        # 结果队列
        self.res = queue.Queue(10)

        # 队列锁
        self.qlock = threading.Lock()

    # 每个线程运行:从数据库读取分页数据，对每条数据进行加工，写入同一个文件
    # begin,num 分页
    def thread_doing(self, begin, num):
        conn = self.pool.connection()
        cursor = conn.cursor(cursor=pymysql.cursors.DictCursor)
        cursor.execute('select * from sql_event limit %s,%s', [begin, num])
        c = 0
        while 1:
            rs = cursor.fetchone()
            if rs is None:
                break
            text = '[{},{}]id:{},item:{},time:{},nowtime:{}'.format(begin, num,
                                                                    rs['id'], rs['item'], rs['time'],
                                                                    datetime.datetime.now().strftime('%Y%m%d%H%M%S'))
            self.write(text)
            c = c + 1

        self.write_res(begin, num, c)
        cursor.close()
        conn.close()  # 将连接放回连接池

    # 并发写入指定文件并加锁:追加
    def write(self, text):
        self.lock.acquire()  # 加锁
        with open(self.write_file, 'a+') as fo:
            fo.write(text + '\n')
        self.lock.release()

    # 将运行结果写入队列
    def write_res(self, begin, num, c):
        res = '线程【{},{}】运行结束，写入总数：{}，结束时间：{}'.format(begin, num, c, datetime.datetime.now().strftime('%Y%m%d%H%M%S'))

        self.qlock.acquire()
        self.res.put(res)
        self.qlock.release()

    def test(self):
        start_time = datetime.datetime.now()
        print('开始时间：', start_time.strftime('%Y%m%d%H%M%S'))
        # 查找表中全部数据量
        conn = self.pool.connection()
        cursor = conn.cursor(cursor=pymysql.cursors.DictCursor)
        cursor.execute('select * from sql_event limit 0,10')
        while 1:
            rs = cursor.fetchone()
            if rs is None:
                break
            print(rs)
        cursor.close()
        conn.close()
        end_time = datetime.datetime.now()
        print('{} 完成！耗时：{} '.format(end_time.strftime('%Y%m%d%H%M%S'), end_time - start_time))

    def run(self):
        start_time = datetime.datetime.now()
        print('开始时间：', start_time.strftime('%Y%m%d%H%M%S'))
        # 查找表中全部数据量
        conn = self.pool.connection()
        cursor = conn.cursor(cursor=pymysql.cursors.DictCursor)
        cursor.execute('select count(*) count from sql_event')
        count = cursor.fetchone()['count']
        cursor.close()
        conn.close()
        # 分页，向上取整
        page = math.ceil(count / self.thread_num)
        print('表数据量：{}，线程数：{}，分页大小：{}'.format(count, self.thread_num, page))

        # 清空文件
        with open(self.write_file, 'w') as fo:
            fo.seek(0)
            fo.truncate()

        # 多线程
        global ths
        ths = []
        # 创建线程
        for i in range(self.thread_num):
            # print(page*i,',',page)
            ths.append(threading.Thread(target=self.thread_doing, args=(page * i, page,)))

        # 启动线程
        for i in range(self.thread_num):
            ths[i].start()
        print('等待中........')
        # 等待线程完成
        for i in range(self.thread_num):
            ths[i].join()

        end_time = datetime.datetime.now()
        print('{} 完成！耗时：{} '.format(end_time.strftime('%Y%m%d%H%M%S'), end_time - start_time))

        while not self.res.empty():
            print(self.res.get())


if __name__ == '__main__':
    p = processing('a.txt')
    # p.test()
    p.run()

    processing
