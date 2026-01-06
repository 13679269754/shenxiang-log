| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-8月-14 | 2024-8月-14  |
| ... | ... | ... |
---
# 快速掌握 MySQL 8.0 认证插件的使用

[toc]

## 资料

[快速掌握 MySQL 8.0 认证插件的使用](https://cloud.tencent.com/developer/article/1598318)

[得物技术浅谈MySQL 8.0：新的身份验证插件（caching_sha2_password）](https://segmentfault.com/a/1190000040733952)

## 一、认证插件 caching_sha2_password

### 优势（相对于 sha256_password）

*caching_sha2_password 认证插件在 MySQL 服务端进行缓存认证条目，对于之前认证过的用户，可以提升二次认证的速度。

* 不管与 MySQL 链接的 SSL 库如何，都可以使用基于 RSA 的密码交换

* 提供了对使用 Unix 套接字文件和共享内存协议的客户端连接的支持


### 缓存管理

* 当删除用户、修改用户名、修改用户密码、修改认证方式会清理相对应的缓存条目
* Flush Privileges 会清除所有的缓存条目
* 数据库关闭时会清除所有缓存条目

### 限制
通过 caching_sha2_password 认证的用户访问数据库，只能通过加密的安全连接或者使用支持 RSA 密钥对进行密码交换的非加密连接进行访问。


## 二、caching_sha2_password 插件使用 RSA 秘钥对

### 2.1 秘钥对生成方式

1)自动生成  
参数 caching_sha2_password_auto_generate_rsa_keys 默认是开启，数据库在启动时自动生成相对应的公钥和私钥。  
2)手动生成  
通过 mysql_ssl_rsa_setup 指定目录生成 SSL 相关的私钥和证书以及 RSA 相关的公钥和私钥。   

### 2.2 查看 RSA 公钥值的方式 

通过状态变量 Caching_sha2_password_rsa_public_key 可以查看 caching_sha2_password 身份验证插件使用的 RSA 公钥值 

### 2.3 使用 RSA 键值对的注意事项

1)拥有 MySQL 服务器上 RSA 公钥的客户端，可以在连接过程中与服务器进行基于 RSA 密钥对的密码交换    
2)对于通过使用 caching_sha2_password 和基于 RSA 密钥对的密码交换进行身份验证的帐户，默认情况下，MySQL 服务端不会将 RSA 公钥发送给客户端，获取 RSA 公钥的方式有以下两种：  
    a) 客户端从服务端拷贝相应的 RSA 公钥；  
    b) 客户端发起访问时，请求获取 RSA 公钥。 
在 RSA 公钥文件可靠性能够保证的前提下，拷贝 RSA 公钥跟请求获取 RSA 公钥相比，由于减少了 C/S之间的通信，相对而言更安全。在网络安全前提下，后者相对来说会更方便。  

### 2.4 命令行客户端通过 RSA 秘钥对进行访问

1)通过拷贝方式获取 RSA 公钥，在通过命令行客户端进行访问时，需要在命令行指定`--server-public-key-path` 选项来进行访问。 
2)通过请求获取 RSA 公钥的方式，在通过命令行客户端进行访问时，需要在命令行中指定-`-get-server-public-key` 选项来进行访问。 
选项 `--server-public-key-path` 优于 `--get-server-public-key`