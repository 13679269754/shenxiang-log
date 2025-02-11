| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-Feb-18 | 2024-Feb-18  |
| ... | ... | ... |
---
# python 环境问题

[toc]

## python 安装 requests 后出现

```bash
ImportError: urllib3 v2 only supports OpenSSL 1.1.1+, currently the 'ssl' module is compiled with 'OpenSSL 1.0.2k-fips  26 Jan 2017'. See: https://github.com/urllib3/urllib3/issues/2168
```

```bash 
pip install urllib3==1.26.15
```

