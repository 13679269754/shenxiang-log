| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-1月-09 | 2025-1月-09  |
| ... | ... | ... |
---
# xtrabackup全备恢复原理

[toc]



MySQL备份工具是种类繁多，大体可以分为**物理备份**和**逻辑备份**。物理备份直接包含了数据库的数据文件，适用于大数据量，需要快速恢复的数据库。逻辑备份包含的是一系列文本文件，其中是代表数据库中数据结构和内容的SQL语句，适用于较小数据量或是跨版本的数据库备份恢复。  

本篇图解的是其中一种备份工具---XtraBackup的全量备份的工作机制。XtraBackup是一种物理备份工具，**支持热备**，在备份时复制所有MySQL的数据文件以及一些事务日志信息，在还原时将复制的数据文件放回至MySQL数据目录，并应用日志保证数据一致。下面我们来解读其中的过程：

* * *

## **全量备份流程**

**全量备份流程：** 

**图1**

    1. 复制已有的redo log，然后监听redo log变化并持续复制

    **图2**

    2. 复制事务引擎数据文件 

**备份图1**

![](https://mmbiz.qpic.cn/mmbiz_jpg/ahNFRFeniaG8hljrJrJpn8wrsHibIVSjdQIp0C3oKjsa6NLCg6IsZYbW9XRIMsrCia6oXCXWJhSz30ic0d4ibQQzTTg/640?wx_fmt=jpeg)

**备份图2**

![](https://mmbiz.qpic.cn/mmbiz_jpg/ahNFRFeniaG8hljrJrJpn8wrsHibIVSjdQdmS1sickQO840rzmBAWebfyjZOCbhUHj5djJ9uymAPCJvDsSpNEDeAA/640?wx_fmt=jpeg)

**FAQ：** 

为什么要先复制redo log，而不是直接开始复制数据文件？

因为XtraBackup是基于InnoDB的**crash recovery**机制进行工作的。如上图2中的页2，由于是热备操作，在备份过程中可能有**持续的数据写入**，直接复制出来的数据文件可能有缺失或被修改的页，而redo log记录了InnoDB引擎的所有事务日志，可以**在还原时应用redo log来补全数据文件中缺失或修改的页**。所以为了确保redo log一定包含备份过程中涉及的数据页，需要首先开始复制redo log。

**全量备份流程：** 

**图3**

   3.等到数据文件复制完成

   4.加锁：全局读锁

   **图4**

   5. 备份非事务引擎数据文件及其他文件

   6. 获取binlog点位信息等元数据

**备份图3**

![](https://mmbiz.qpic.cn/mmbiz_jpg/ahNFRFeniaG8hljrJrJpn8wrsHibIVSjdQvwfVPJlGMJ4q72ayQ6LHs9Zic9lDPz0AwxymzR4KtMHblJn1wknZnQA/640?wx_fmt=jpeg)

**备份图4**

![](https://mmbiz.qpic.cn/mmbiz_jpg/ahNFRFeniaG8hljrJrJpn8wrsHibIVSjdQ12wkZAoBZv1DiahWDjHLdLAA3eNuhddQIJujYgO65s5A3icrLOXags2g/640?wx_fmt=jpeg)

**TIPS：** 

非事务引擎数据文件较多时，全局读锁的时间会较长。

**FAQ：** 

加全局读锁的作用？

因为要保证”非事务资源 自身的一致性“ 和 ”非事务资源与 事务资源的一致性“。在加锁期间，没有新数据写入，XtraBackup会复制此时的binlog位置信息，frm表结构，MyISAM等非事务表。

****全量**备份流程：** 

**图5**

   7. 停止复制redo log

   8. 解锁：全局读锁

   9. 复制buffer pool dump

   10. 备份完成

**备份图5**

![](https://mmbiz.qpic.cn/mmbiz_jpg/ahNFRFeniaG8hljrJrJpn8wrsHibIVSjdQKkEiafpQogsOZqNBv5WDNMKnW0WloYaiaVAqBjxpCafibnGCp07uouQbg/640?wx_fmt=jpeg)

**FAQ：** 

为什么要先停止复制redo log，再解锁全局读锁？

也是因为要保证“非事务资源与事务资源的一致性”，保证通过redo log回放后的InnoDB数据与非InnoDB数据都是处于读锁期间取得的位点。

**全量备份流程总结：** 

XtraBackup基于InnoDB的**crash recovery机制**，在备份还原时利用redo log得到完整的数据文件，并通过全局读锁，保证InnoDB数据与非InnoDB数据的一致性，最终完成备份还原的功能。

* * *

## **全备还原流程**

**全备还原流程：** 

   **图1 (xtrabackup--prepare)**

    1. 模拟MySQL进行recover，将redo log回放到数据文件中

    2. 等到recover完成  

    3. 重建redo log，为启动数据库做准备 

  **图2 (xtrabackup--copy-back/move-back )**

    4. 将数据文件复制回MySQL数据目录

    5. 还原完成

**还原图1**

![](https://mmbiz.qpic.cn/mmbiz_jpg/ahNFRFeniaG8hljrJrJpn8wrsHibIVSjdQOUjjdt74YANTws58bRiayKhUQjGFO4JZf7IOTNGosiaw6mQGI88xMxEA/640?wx_fmt=jpeg)

**还原图2**

![](https://mmbiz.qpic.cn/mmbiz_jpg/ahNFRFeniaG8hljrJrJpn8wrsHibIVSjdQvy92qE7LA1qhCEKVKM1SH84VBXcCicjJEst9nycJ4aFy4PicZcU97wDw/640?wx_fmt=jpeg)

**FAQ：** 

在recover完成后，InnoDB数据与非InnoDB数据是达成一致的吗？

InnoDB数据会被恢复至备份结束时(全局读锁时)的状态，而非InnoDB数据本身即是在全局读锁时被复制出来，它们的数据一致。

