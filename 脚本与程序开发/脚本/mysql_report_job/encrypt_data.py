#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
mysql_report_job/

author: shen
date : 2024/4/23
comment : 提示信息
"""
from cryptography.fernet import Fernet
from log_format import logger


def encrypt_data(data):
    cipher = Fernet('pT8ZDjwCvnWkfPEYBm12q2p9srNkM-nWC6Ss9aAcMEw=')
    # 加密数据
    encrypted_data = cipher.encrypt(data.encode()).decode()
    return encrypted_data

def decrypt_data(encrypted_data):
    cipher = Fernet('pT8ZDjwCvnWkfPEYBm12q2p9srNkM-nWC6Ss9aAcMEw=')
    # 解密数据
    decrypted_data = cipher.decrypt(encrypted_data.encode()).decode()
    return decrypted_data

if __name__ == '__main__':
    # encrypt_str = input("请输入要加密的数据:")
    # logger.info(encrypt_data(encrypt_str))

    encrypt_str = input("请输入要解密的数据:")
    logger.info(decrypt_data(encrypt_str))
