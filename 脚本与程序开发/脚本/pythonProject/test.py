# import random
# import string
# from os.path import join
#
# arrRes = ['2', '1', '10', '4', '3']
# arrRes.sort(key=int)
# print(arrRes)
# # ['学生1', '学生2', '学生3', '学生4', '学生10']
#
# a = '你 干 嘛 '
#
# print(a.capitalize())
# print(a.title())
# print(a.upper())
# print(a.lower())
#
# print(a.zfill(20))
# print(a.center(50))
# print(a.rjust(50))
# print(a.ljust(50))
# print(a.strip())
# print(a.lstrip())
# print(a.rstrip())
#
# print(a.split(' '))
# print(a.encode('gbk'))
# print(a.encode('gbk').decode('gbk'))
#
# B = '1234567890'
# table = str.maketrans('1234567890', '0987654321')
#
# print(B.translate(table))
#
# all_chars = string.ascii_letters + string.digits
# print(random.choice(all_chars))
# selected = random.sample(all_chars, 10)
# print(selected)
# print(''.join(selected))
# print(random.sample(all_chars, 10))
#
# # 字面量语法
# dict1 = {'a': 1, 'b': 2, 'c': 3}
#
# # 构造器语法
# print(dict1)
# dict2 = dict(a=1, b=2, c=3)
# print(dict2)
# dict3 = dict(zip([-2, 2, 1], [3, 2, 1]))
# print(dict2)
#
# # 生成式语法
# print('生成式语法')
# dict4 = {i: i*2 for i in ['a', 'b', 'c']}
# print(dict4)
# tuple1 = tuple(zip(dict3.values(), dict3.keys()))
# print(tuple1)
#
# print(max(tuple1))
#
# from dbutils.pooled_db import PooledDB
#
#
# def start_conn():
#     try:
#         # maxshared 允许的最大共享连接数，默认0/None表示所有连接都是专用的
#         # 当线程关闭不再共享的连接时，它将返回到空闲连接池中，以便可以再次对其进行回收。
#         # mincached 连接池中空闲连接的初始连接数，实验证明没啥用
#         self.__pool = PooledDB(creator=pymysql,
#                                mincached=1, # mincached 连接池中空闲连接的初始连接数，但其实没用
#                                maxcached=4,  # 连接池中最大空闲连接数
#                                maxshared=3, #允许的最大共享连接数
#                                maxconnections=2,  # 允许的最大连接数
#                                blocking=False,  # 设置为true，则阻塞并等待直到连接数量减少，false默认情况下将报告错误。
#                                host=self.host,
#                                port=self.port,
#                                user=self.user,
#                                passwd=self.passwd,
#                                db=self.db_name,
#                                charset=self.charset
#                                )
#         print("0 start_conn连接数:%s " % (self.__pool._connections))
#         self.conn = self.__pool.connection()
#         print('connect success')
#         print("1 start_conn连接数:%s " % (self.__pool._connections))
#
#         self.conn2 = self.__pool.connection()
#         print("2 start_conn连接数:%s " % (self.__pool._connections))
#         db3 = self.__pool.connection()
#         print("3 start_conn连接数:%s " % (self.__pool._connections))
#         db4 = self.__pool.connection()
#         print("4 start_conn连接数:%s " % (self.__pool._connections))
#         db5 = self.__pool.connection()
#         print("5 start_conn连接数:%s " % (self.__pool._connections))
#         # self.conn.close()
#         print("6 start_conn连接数:%s " % (self.__pool._connections))
#         return True
#     except:
#         print('connect failed')
#         return False
#
# start_conn()
#

class student():

    __isinstance = False # 保存我们已经创建和好的实例
    def __new__(cls, *args, **kwargs):
        if not cls.__isinstance:
            cls.__isinstance = object.__new__(cls)  # 没有实例则创建
        return cls.__isinstance # 有就返回有的实例

    def __init__(self, name, age):
        print(f"我是{name}")
        self.name = name
        self.age = age


stu1 = student('zhangsan', 18)
stu2 = student('lisi', 19)
print(stu1)
print(stu2)