#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
socket_test/

author: shen
date : 2024/4/10
comment : 提示信息
"""
from cryptography.fernet import Fernet

# 生成加密密钥

cipher = Fernet('pT8ZDjwCvnWkfPEYBm12q2p9srNkM-nWC6Ss9aAcMEw=')

def encrypt_data(data):
    # 加密数据
    encrypted_data = cipher.encrypt(data.encode()).decode()
    return encrypted_data

def decrypt_data(encrypted_data):
    # 解密数据
    decrypted_data = cipher.decrypt(encrypted_data.encode()).decode()
    return decrypted_data

# 测试加密解密方法
data_to_encrypt = "hello"
encrypted_data = encrypt_data(data_to_encrypt)
decrypted_data = decrypt_data(encrypted_data)



print("Original data:", data_to_encrypt)
print("Encrypted data:", encrypted_data)
print("Decrypted data:", decrypted_data)

