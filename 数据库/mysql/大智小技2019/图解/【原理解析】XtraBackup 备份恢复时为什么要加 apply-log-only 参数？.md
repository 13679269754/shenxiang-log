XtraBackup 在 MySQL 备份场景中被广泛使用，大家一定不陌生。我们也在之前的两篇文章中分享了其备份的原理。（详见
[原理解析XtraBackup全量备份还原](http://mp.weixin.qq.com/s?__biz=MzU2NzgwMTg0MA==&mid=2247484357&idx=1&sn=b11afc9f512afb04658c8abf0c995ae5&chksm=fc96e15acbe1684c27a6348e9ea420edc047c10c394007c050fbc744ba7ededb91ad2b766a74&scene=21#wechat_redirect) & [原理解析XtraBackup增量备份还原](http://mp.weixin.qq.com/s?__biz=MzU2NzgwMTg0MA==&mid=2247484425&idx=1&sn=a3c70d67676af1c8290b089887d8e4d3&chksm=fc96e696cbe16f80120fbebd0749362fa5501e7a33dbb34ab71c4a5947c57c28dd8496850c6b&scene=21#wechat_redirect)）

本文想要描述的是 XtraBackup 恢复时参数 apply-log-only 的作用，不知道大家有没有注意到，这个参数如果不设置，可能会产生数据不一致的惨剧。

使用 XtraBackup 对数据库做备份，实际上就是拷贝 MySQL 的数据文件，为了保证备份数据的最终一致，也会同时拷贝备份过程中的 Redo log。

![](https://mmbiz.qpic.cn/mmbiz_jpg/ahNFRFeniaGibicfgpHkiatUfTlNhibicsictKUJCDFBVOHmicxEkdjVGyTnVOGnGLwNYLLwshYfChvX6cNXPshSZeDqtg/640?wx_fmt=jpeg)

如图 1 所示，全备开始时，事务 2 尚未提交，Redo log 中仅有事务 2 的一部分数据(B->F)，XtraBackup 于是将这一部分数据拷贝到全备文件中。

![](https://mmbiz.qpic.cn/mmbiz_jpg/ahNFRFeniaGibicfgpHkiatUfTlNhibicsictKUBpTB7rZ9ibiaCvCoaHO0xE1ibng2YzMyuqo6YXUK5pcxet4Ofq1ico7tFA/640?wx_fmt=jpeg)

如图 2 所示，增备开始时，事务 2 已经提交，Redo log 中有了事务 2 的完整数据。XtraBackup 于是将事务 2 的后一部分数据拷贝了下来。

![](https://mmbiz.qpic.cn/mmbiz_jpg/ahNFRFeniaGibicfgpHkiatUfTlNhibicsictKU7eshNnvQoVsmZrevblicax409vLTwb5hdXjQ7Q8ic9oYNCo8Ro8fhqgw/640?wx_fmt=jpeg)

如图 3 所示，恢复时，首先恢复全备中的数据文件，然后回放全备中的 Redo log，回放过程中应用了一部分事务 2(B->F)，**如果没有设置 apply-log-only，XtraBackup 会在恢复最后一步应用 undo，将这一部分残缺的事务回滚(F->B)**，就此埋下了祸根。

![](https://mmbiz.qpic.cn/mmbiz_jpg/ahNFRFeniaGibicfgpHkiatUfTlNhibicsictKUVvJib5oTPrOlEWrcL48lFLAicQ0icBMiafakniansxuHNeCMw7q4pCDKqsg/640?wx_fmt=jpeg)

如图 4 所示，后续恢复增备文件时，继续回放了事务 2 的后一部分(E->G A->H)，导致最终的数据文件中丢失了事务 2 第一部分的数据(B->F)，惨剧就发生了。

![](https://mmbiz.qpic.cn/mmbiz_jpg/ahNFRFeniaGibicfgpHkiatUfTlNhibicsictKUjKWMOyV57fWpvONjZKS1OiaCfuldeiczfS9Zad16rH72K9O7icIibXeZdw/640?wx_fmt=jpeg)

如图 5 所示，**正确的做法应该是除了最后一个增备，所有的备份恢复都应该设置 apply-log-only 参数（only 指的就是只回放 redo log 阶段，跳过 undo 阶段），避免未完成事务的回滚**。如图所示，此时全备恢复后的数据文件才是完整的(包含了B->F)。所有增备恢复完成后的数据也是完整的。

**参考：** 

https://www.percona.com/doc/percona-xtrabackup/2.3/xtrabackup\_bin/xbk\_option_reference.html#cmdoption-xtrabackup-apply-log-only

![](https://mmbiz.qpic.cn/mmbiz_jpg/ahNFRFeniaGiba4ibXeLb9cyOj5xbkgEz1d3GpPJetlBhV7OBibrQhE7aIt6I7mfRDZkFZtRibbgopGxB5ktNI9zWuA/640?wx_fmt=jpeg)
  