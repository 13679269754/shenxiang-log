| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-2月-20 | 2025-2月-20  |
| ... | ... | ... |
---
# mysql innodb_flush_method.md

[toc]

[使用O_DIRECT_NO_FSYNC来提升MySQL性能 - 知乎](https://zhuanlan.zhihu.com/p/134669835) 

 这篇文章很短，但很有价值~

* * *

MySQL下[InnoDB存储引擎](https://zhida.zhihu.com/search?content_id=118057982&content_type=Article&match_order=1&q=InnoDB%E5%AD%98%E5%82%A8%E5%BC%95%E6%93%8E&zhida_source=entity)有个innodb\_flush\_method只读参数，用户设置InnoDB的数据和[redo日志文件](https://zhida.zhihu.com/search?content_id=118057982&content_type=Article&match_order=1&q=redo%E6%97%A5%E5%BF%97%E6%96%87%E4%BB%B6&zhida_source=entity)flush行为。

> defines the method used to [flush](https://link.zhihu.com/?target=https%3A//dev.mysql.com/doc/refman/8.0/en/glossary.html%23glos_flush) data to`InnoDB`[data files](https://link.zhihu.com/?target=https%3A//dev.mysql.com/doc/refman/8.0/en/glossary.html%23glos_data_files) and [log files](https://link.zhihu.com/?target=https%3A//dev.mysql.com/doc/refman/8.0/en/glossary.html%23glos_log_file), which can affect I/O throughput.

这是一个对性能和数据可靠性有较大影响的参数，在此拿出之前测试的一张性能对比图：

![](https://pic4.zhimg.com/v2-fa4b980dfce57d97b8e859a23b6b060d_1440w.jpg)

可以看到，该参数从fsync到[O\_DIRECT](https://zhida.zhihu.com/search?content_id=118057982&content_type=Article&match_order=1&q=O_DIRECT&zhida_source=entity)再到O\_DIRECT\_NO\_FSYNC，性能分别有明显的提升。一般在Linux下，我们会将该参数设置为O\_DIRECT，即数据文件IO走direct\_io模式，redo日志文件走系统缓存（linux page cache）模式，在IO完成后均使用fsync()进行持久化。不过redo日志是否调用fsync()还依赖[innodb\_flush\_log\_at\_trx\_commit](https://zhida.zhihu.com/search?content_id=118057982&content_type=Article&match_order=1&q=innodb_flush_log_at_trx_commit&zhida_source=entity)参数。

> `O_DIRECT`or`4`:`InnoDB`uses`O_DIRECT`(or`directio()`on Solaris) to open the data files, and uses`fsync()`to flush both the data and log files.

而O\_DIRECT\_NO\_FSYNC选项的意思是，使用O\_DIRECT完成IO后，不调用fsync()刷盘。

这里简单说下，为什么采用direct\_io模式绕过page cache直接写磁盘文件，还需要调用fsync()刷盘，原因就是还存在文件系统元数据缓存，包括vfs中的inode cache和dentry cache等，以及具体文件系统元数据，如对于[ext4](https://zhida.zhihu.com/search?content_id=118057982&content_type=Article&match_order=1&q=ext4&zhida_source=entity)还包括[inode block bitmap](https://zhida.zhihu.com/search?content_id=118057982&content_type=Article&match_order=1&q=inode+block+bitmap&zhida_source=entity)，[data block bitmap](https://zhida.zhihu.com/search?content_id=118057982&content_type=Article&match_order=1&q=data+block+bitmap&zhida_source=entity)等。

比如往一个新文件写入数据，除了将数据写入指定的文件系统数据block中，还需要确保文件系统的磁盘元数据上有对应的文件名和文件路径，而且还需要将对应的数据block标记为已使用状态，需要将保存文件id（其实是inode）的inode block也标记为已使用状态。

但并不是每次IO操作都会导致文件系统元数据的更新，比如单纯修改一条记录的值，可能就不会。因此，某些IO操作需要采用O\_DIRECT模式，另一些IO操作可以采用O\_DIRECT\_NO\_FSYNC模式。如果能够区分这些不同的IO操作类型，那么就可以提升IO性能。

这就是本文要说的内容。先看下面一段话：

> `**O_DIRECT_NO_FSYNC**`: `InnoDB` uses `O_DIRECT` during flushing I/O, but skips the `fsync()` system call after each write operation.  
> Prior to MySQL 8.0.14, this setting is not suitable for file systems such as XFS and EXT4, which require an `fsync()` system call to synchronize file system metadata changes. If you are not sure whether your file system requires an `fsync()` system call to synchronize file system metadata changes, use `O_DIRECT` instead.  
> As of MySQL 8.0.14, `fsync()` is called after creating a new file, after increasing file size, and after closing a file, to ensure that file system metadata changes are synchronized. The `fsync()` system call is still skipped after each write operation.

从MySQL 8.0.14开始，社区版本就已经为我们做了这样的事情。因此，现在O\_DIRECT\_NO\_FSYNC是可以取代O\_DIRECT的。而MySQL也已经这么做了，虽然没有直接修改该参数默认值（fsync），但在专用的MySQL服务器上，推荐值已经变了。详见[innodb-dedicated-server](https://link.zhihu.com/?target=https%3A//dev.mysql.com/doc/refman/8.0/en/innodb-dedicated-server.html)，简单例举如下：

> `**[innodb_flush_method](https://link.zhihu.com/?target=https%3A//dev.mysql.com/doc/refman/8.0/en/innodb-parameters.html%23sysvar_innodb_flush_method)**`  
> The flush method is set to `**O_DIRECT_NO_FSYNC**` when `[innodb_dedicated_server](https://link.zhihu.com/?target=https%3A//dev.mysql.com/doc/refman/8.0/en/innodb-parameters.html%23sysvar_innodb_dedicated_server)` is enabled. If the `O_DIRECT_NO_FSYNC` setting is not available, the default `[innodb_flush_method](https://link.zhihu.com/?target=https%3A//dev.mysql.com/doc/refman/8.0/en/innodb-parameters.html%23sysvar_innodb_flush_method)` setting is used.

现在已经是MySQL 8.0.19了，应该说，在该版本上，大家可以放心使用O\_DIRECT\_NO\_FSYNC了，能够有更好的性能（从上面的测试结果看，性能至少提升了20%+），干嘛不用呢。