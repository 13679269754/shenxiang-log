#! /usr/bin/python
# ! coding=utf-8

import random
import pymysql
from faker import Faker
from datetime import datetime, timedelta

# 创建Faker实例
fake = Faker()

# MySQL连接参数
db_params = {
    'host': '121.37.193.208',
    'user': 'dzjroot',
    'password': 'Dzj_pwd_2022',
    'db': 'test',
    'port': 3306
}

# 连接数据库
connection = pymysql.connect(**db_params)

# 创建一个新的Cursor实例
cursor = connection.cursor()

# 生成并插入数据
for i in range(5000):
    id = (i + 1)
    first_name = fake.first_name()
    last_name = fake.last_name()
    sex = random.choice(['M', 'F'])
    age = random.randint(20, 60)
    birth_date = fake.date_between(start_date='-60y', end_date='-20y')
    hire_date = fake.date_between(start_date='-30y', end_date='today')

    query = f"""INSERT INTO employees (id, first_name, last_name, sex, age, birth_date, hire_date)
                VALUES ('{id}', '{first_name}', '{last_name}', '{sex}', {age}, '{birth_date}', '{hire_date}');"""

    cursor.execute(query)

    # 每1000提交一次事务
    if (i + 1) % 1000 == 0:
        connection.commit()

# 最后提交事务
connection.commit()

# 关闭连接
cursor.close()
connection.close()