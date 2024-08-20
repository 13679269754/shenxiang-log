| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-8月-14 | 2024-8月-14  |
| ... | ... | ... |
---

# 新增 DML 语句(TABLE & VALUES)

[toc]

## 资料

[新增 DML 语句(TABLE & VALUES)](https://cloud.tencent.com/developer/article/1605177)

[进阶SQL-递归查询（with recursive）](https://www.cnblogs.com/REN-Murphy/p/17895024.html)

## 原文摘录

### 应用场景

1. TABLE 语句

   * 具体用在小表的全表扫描，比如路由表、配置类表、简单的映射表等。

   * 用来替换是被当做子查询的这类小表的 SELECT 语句。

2. VALUES 语句

   * VALUES 类似于其他数据库的 ROW 语句，造数据时非常有用。

### 语法使用  

#### TABLE 语句具体语法：
`TABLE table_name [ORDER BY column_name] [LIMIT number [OFFSET number]]`


```sql
create table t1 (r1 int,r2 int);

insert into t1
with recursive aa(a,b) as (
select 1,1
union all
select a+1,ceil(rand()*20) from aa where a < 10
) select * from aa;

-- 例一
explain table t1 order by r1 limit 2;

-- 例二
create table t2 like t1;

insert into t2 table t1;

select * from t2 where (r1,r2) in (table t1);

```

**那其实从上面简单的例子可以看到 TABLE 在内部被转成了普通的 SELECT 来处理。** 


#### VALUES 语句 

```sql
VALUES row_constructor_list
[ORDER BY column_designator]
[LIMIT BY number] row_constructor_list:
    ROW(value_list)[, ROW(value_list)][, ...]
value_list:
    value[, value][, ...]
column_designator:
    column_index

-- 例一
create table t3 (r1 varchar(100),r2 varchar(100),r3 varchar(100));

insert into t3 values row(100,200,300), \
row('2020-03-10 12:14:15','mysql','test'), \
row(16.22,TRUE,b'1'),\
row(left(uuid(),8),'{"name":"lucy","age":"28"}',hex('dble'));

-- 例二
values row(1,2,3),row(10,9,8) union all values row(-1,-2,0),row(10,29,30),row(100,20,-9) order by 1 desc ;


```



