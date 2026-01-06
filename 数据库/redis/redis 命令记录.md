| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-3月-25 | 2024-3月-25  |
| ... | ... | ... |
---
# redis 命令记录

[toc]

## redis 批量操作

UAT
```bash
redis-cli -p 6600 -a HqGKZDcO6onuAigHtu -n 3 NOKEYS "*RESEARCH:SAMPLE:JSON_CONTENT*"  | xargs redis-cli -p 6600 -a HqGKZDcO6onuAigHtu -n 3 DEL

## 清除历史记录
history -c 
```