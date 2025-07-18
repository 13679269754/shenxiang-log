| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-3月-17 | 2025-3月-17  |
| ... | ... | ... |
---
# ES 清除当前用户名密码并重新设置

[toc]

## 1.去除当前密码认证要求(如果忘记了密码)

备注掉如下配置：
```bash
    ## security
    #xpack.security.enabled: true
    #xpack.license.self_generated.type: basic
    #xpack.security.transport.ssl.enabled: true
    #xpack.security.transport.ssl.verification_mode: certificate
    #xpack.security.transport.ssl.client_authentication: required
    #xpack.security.transport.ssl.keystore.path: certs/elastic-certificates.p12
    #xpack.security.transport.ssl.truststore.path: certs/elastic-certificates.p12
    #xpack.security.http.ssl.enabled: true
    #xpack.security.http.ssl.keystore.path: certs/elastic-certificates.p12
    #xpack.security.http.ssl.truststore.path: certs/elastic-certificates.p1
```
重要  
**#xpack.security.enabled: true**
**#xpack.security.http.ssl.enabled: true**

## 2.重启elasticsearch

## 3.清除elasticsearch 安全认证索引

```bash
    curl -X DELETE  "http://127.0.0.1:9200/.security-7"
```
## 4.清除keystore.seed
./bin/elasticsearch-keystore remove keystore.seed

## 5.去除第一步的注释，重启elasticsearch

## 6.重新初始化密码

```bash
    ./bin/elasticsearch-keystore create 
    ./bin/elasticsearch-setup-passwords interactive
```

xpack.security.http.ssl.keystore.secure_password
xpack.security.http.ssl.truststore.secure_password
xpack.security.transport.ssl.keystore.secure_password
xpack.security.transport.ssl.truststore.secure_password


