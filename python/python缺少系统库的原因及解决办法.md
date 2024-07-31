| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-1月-04 | 2024-1月-04  |
| ... | ... | ... |
---
# python缺少系统库的原因及解决办法

[toc]

## 问题出现场景

系统:
> CentOS Linux release 7.9.2009 (Core)

python：
> 原有python3.6.编译安装python3.9 语句为`./configure --prefix=/usr/local/python3 && make && make install `  
> 编译安装3.9后，python3 指向了3.9 

## 问题描述
python3
```python
import ssl
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/usr/local/lib/python3.9/ssl.py", line 98, in <module>
    import _ssl             # if we can't import it, let the error propagate
ModuleNotFoundError: No module named '_ssl'
```

其他系统库如压缩库from lzma import LZMAFile, LZMAError 也会失败

## 问题原因
```bash
[root@iZuf6eln68v4o2rbtx2zr9Z ~]# python3 -m site --user-site
/root/.local/lib/python3.9/site-packages
```

发现pip3 安装的包并不在这个路径下而是在python的主路径
`/usr/local/python3/lib/python3.9/site-packages`

## 问题处理
```bash
export PYTHONUSERBASE=/usr/local/python3 
export PATH=$PYTHONUSERBASE/bin:$PATH
```

使其可以将这个添加到/etc/profile 中在进入系统时生效

