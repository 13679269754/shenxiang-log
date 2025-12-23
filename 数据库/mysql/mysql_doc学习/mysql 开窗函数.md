| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-3月-05 | 2024-3月-05  |
| ... | ... | ... |
---
# mysql 开窗函数.md


[MySQL开窗函数](https://blog.csdn.net/mr__sun__/article/details/124257213)

函数：运行时的函数
聚合函数：COUNT,SUM,MIN,MAX,AVG
  - 内置窗口函数：
    - 取值
      - FIRST_VALUE：取窗口第一个值；
      - LAST_VALUE：取窗口最后一个值；
    - 串行
      - LEAD:窗口内 向下 第n行的值；
      - LAG：窗口内 向上 第n行的值；
    - 排序
      - NTILE：把数据平均分配 指定 N个桶 ，如果不能平均分配 ，优先分配到 编号 -小的里面；
      - RANK: 从1 开始 ， 按照顺序 相同会重复 名次会留下 空的位置 生成组内的记录编号；
      - ROW_NUMBER： 从1 开始 ， 按照顺序 生成组内的记录编号;
      - DENSE_RANK：从1 开始 ， 按照顺序 生成组内的记录编号 相同会重复 名次不会会留下空的位置；
      - CUME_DIST
      - PERCENT_RANK


---