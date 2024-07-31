| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-3月-18 | 2024-3月-18  |
| ... | ... | ... |
---
# mysql8.0字符串函数

[toc]

## 字符串函数与运算符
[字符创函数与运算符](https://dev.mysql.com/doc/refman/8.0/en/string-functions.html)  
ascii or ord  
bin  
bin_length  
char  
char_length  
character_length  
concat  
concat_ws  
elt   
field  
find_in_set  
from_bash64  and  to_base64  
insert  
instr  
lcase or lower  and  upper or ucase  
left  
length  
load_file  
ltrim rtrim trim  
oct  
position  or locate  
quote  
repeat  
replace  
reverse  
right  
rpad and lpad  
substr  substring  
substring_index  
hex and unhex  
weight_string  
conv  转换进制  

## 字符串比较
like  通配符:  
* _ 匹配单个字符  
* % 匹配0-n个字符  

not like  
strcmp 字符串对比

## Regular Expressions

| function | USING |
| :----: | :----: |
| not_regexp | Negation of REGEXP |
| regexp | Whether string matches regular expression |
| REGEXP_INSTR | Starting index of substring matching regular expression |
| REGEXP_LIKE | Whether string matches regular expression |
| REGEXP_REPLACE | Replace substrings matching regular expression |
| REGEXP_SUBSTR | Return substring matching regular expression |
| RLIKE | Whether string matches regular expression |


## convert() and case() 与 binary
[Cast Functions and Operators](https://dev.mysql.com/doc/refman/8.0/en/cast-functions.html)

BINARY expr  
CAST(expr AS type [ARRAY])  
CONVERT(expr USING transcoding_name)  
CONVERT(expr,type)  
```sql 
SELECT CONVERT('test', CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_bin;
```

