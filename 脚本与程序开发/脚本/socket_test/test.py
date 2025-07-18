#!/usr/bin/env python
# -*- coding:utf-8 -*-

from cryptography.fernet import Fernet

"""
socket_test/

author: shen
date : 2024/4/10
comment : 提示信息
"""
save_encrypted_pass = 1
cipher = Fernet("pT8ZDjwCvnWkfPEYBm12q2p9srNkM-nWC6Ss9aAcMEw=")


def encrypt_data(data, encrypted_flag=save_encrypted_pass):
    # 加密数据
    if encrypted_flag == str(0):
        return data
    else:
        encrypted_data = cipher.encrypt(data.encode()).decode()
        print(encrypted_data)
        return encrypted_data


def decrypt_data(encrypted_data, encrypted_flag=save_encrypted_pass):
    # 解密数据
    if encrypted_flag == str(0):
        return encrypted_data
    else:
        decrypted_data = cipher.decrypt(encrypted_data)
        return decrypted_data


# 测试用例
def test_encrypt_data():
    assert encrypt_data("hello") != "hello"
    # print(encrypt_data("hello"))
    # print(decrypt_data(encrypt_data("hello")))
    assert decrypt_data(encrypt_data("hello")) == "hello"


def test_decrypt_data():
    encrypted_data = encrypt_data("hello")
    decrypted_data = decrypt_data(encrypted_data)
    assert decrypted_data == "hello"


if __name__ == "__main__":
    # 运行测试
    test_encrypt_data()
    test_decrypt_data()
