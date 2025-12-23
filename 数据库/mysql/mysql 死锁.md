# 死锁
[toc]

## 死锁场景

### 并发插入导致的死锁

参考：
- [mysql并发插入死锁](https://blog.csdn.net/qq_35425070/article/details/109782896)
- [mysql并发insert死锁问题——gap、插入意向锁冲突](https://blog.csdn.net/w892824196/article/details/103084100)

场景1: **插入意向锁导致的死锁**

多个insert并发(至少3个)，当插入的位置一样的时候，比如3个session都insert table id=x，其中第一个获得排他锁，其他两个session会产生duplicate-key error，当duplicate-key error发生时，两个session都会将锁变化为共享锁，下一步获取排他锁，然后第一个session rollback了，两个session互相持有共享锁，无法获得排他锁，导致死锁

s1 insert id =x 或者 s1 delete id = x

s2 insert id = x

s3 insert id = x

s1 rollback

replace和insert一样

INSERT … ON DUPLICATE KEY UPDATE与insert不一样，当遇到 duplicate-key时，对于primary key获取排他记录锁，对于unique index获取Next-key lock，不会死锁


### pt-osc 与 insert 并发导致死锁

[pt-osc 与 insert 并发导致死锁](https://blog.csdn.net/n88Lpo/article/details/106535930)