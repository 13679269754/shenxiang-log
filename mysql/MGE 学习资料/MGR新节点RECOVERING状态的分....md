# MGR新节点RECOVERING状态的分析与解决：caching\_sha2\_password验证插件的影响

[mp.weixin.qq.com](https://mp.weixin.qq.com/s/l6mJlmASEQtkMyhrVs_eUg)KAiTO 老叶茶馆

\*GreatSQL社区原创内容未经授权不得随意使用，转载请联系小编并注明来源。

## 起因

在GreatSQL社区上有一位用户提出了“手工构建MGR碰到的次节点一直处于recovering状态”，经过排查后，发现了是因为新密码验证插件`caching_sha2_password`导致的从节点一直无法连接主节点，帖子地址：➥[caching_sha2_password](https://greatsql.cn/thread-420-2-1.html)

## 复现

### 环境介绍

本文验证环境，以及本文所采用数据库为`GreatSQL 8.0.32-24`

`$cat/etc/system-release
RedHatEnterpriseLinuxServerrelease7.9(Maipo)
$uname-a
Linuxgip3.10.0-1160.el7.x86_64#1SMPTueAug1814:50:17EDT2020x86_64x86_64x86_64GNU/Linux
`

部署准备：

采用的是单机多实例的部署方式，如何部署单机多实例可以前往➥https://gitee.com/GreatSQL/GreatSQL-Manual/blob/master/6-oper-guide/6-6-multi-instances.md



| IP |	端口 |	角色 |
| :----: | :----: | :----: |
|172.17.139.77 | 3306 |	mgr01 |
|172.17.139.77 | 3307 |	mgr02 |


MGR有关配置参数：

```bash
#mgrsettings
loose-plugin_load_add='mysql_clone.so'
loose-plugin_load_add='group_replication.so'
loose-group_replication_group_name="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1"
loose-group_replication_group_seeds='172.17.139.77:33061,172.17.139.77:33071'
loose-group_replication_start_on_boot=ON
loose-group_replication_bootstrap_group=OFF
loose-group_replication_exit_state_action=READ_ONLY
loose-group_replication_flow_control_mode="DISABLED"
loose-group_replication_single_primary_mode=ON
loose-group_replication_communication_max_message_size=10M
loose-group_replication_transaction_size_limit=3G
loose-group_replication_arbitrator=0
loose-group_replication_single_primary_fast_mode=0
loose-group_replication_request_time_threshold=20000
report_host="172.17.139.77"
```

MGR01节点配置如下：

```bash
[mysqld@mgr01]
datadir=/data/GreatSQL/mgr01
socket=/data/GreatSQL/mgr01/mysql.sock
port=3306
server_id=103306
log-error=/data/GreatSQL/mgr01/error.log
loose-group_replication_local_address="172.17.139.77:33061"
```

MGR02节点配置如下：

```bash
[mysqld@mgr02]
datadir=/data/GreatSQL/mgr02
socket=/data/GreatSQL/mgr02/mysql.sock
port=3307
server_id=103317
log-error=/data/GreatSQL/mgr02/error.log
loose-group_replication_local_address="172.17.139.77:33071"
```

启动MGR01实例、MGR02实例，并修改密码

```bash
#启动两个实例
$systemctlrestartgreatsql@mgr01&
$systemctlrestartgreatsql@mgr02&
# 获取初始化密码
$greproot/data/GreatSQL/mgr01/error.log
$greproot/data/GreatSQL/mgr02/error.log
# 登录数据库并修改密码
$mysql-S/data/GreatSQL/mgr01/mysql.sock-uroot-p
greatsql>alteruserroot@'localhost'identifiedby'GreatSQL@666';
$mysql-S/data/GreatSQL/mgr02/mysql.sock-uroot-p
greatsql>alteruserroot@'localhost'identifiedby'GreatSQL@666';
```

检查两个实例是否正确加载`group_replicaiton` 插件

```sql
greatsql>show plugins;
+----------------------------------+----------+--------------------+----------------------+---------+
|Name|Status|Type|Library|License|
+----------------------------------+----------+--------------------+----------------------+---------+
|group_replication|ACTIVE|GROUPREPLICATION|group_replication.so|GPL|
+----------------------------------+----------+--------------------+----------------------+---------+
```

没有加载的话可以手动加载这个plugin

```sql
greatsql>install plugin group_replication soname 'group_replication.so';
```

### 搭建MGR

接下来就可以手工搭建MGR，流程如下可参考`安装部署MGR集群 | 深入浅出MGR`➥https://gitee.com/GreatSQL/GreatSQL-Doc/blob/master/deep-dive-mgr/deep-dive-mgr-03.md

MGR01实例操作：

`greatsql> set session sql_log_bin=0;`
_特别注意下面因为8.0.4版本开始使用的默认是“caching_sha2_password”，所以这样创建会采用最新的身份认证插件_
```sql
greatsql>create user repl@'%' identified by 'GreatSQL@666';
greatsql>GRANT BACKUP_ADMIN,REPLICATIONSLAVEON *.* TO `repl`@`%`;
greatsql>set session sql_log_bin=1;
greatsql>CHANGE MASTER TO MASTER_USER='repl',MASTER_PASSWORD='GreatSQL@666' FORCHANNEL 'group_replication_recovery';
```

接下来即可启动MGR集群：

```sql
greatsql>set global group_replication_bootstrap_group=ON;
greatsql>start group_replication;
greatsql>select * from performance_schema.replication_group_members\G
***************************1.row***************************
CHANNEL_NAME:group_replication_applier
MEMBER_ID:2920447e-35bf-11ee-89a5-00163e566da1
MEMBER_HOST:172.17.139.77
MEMBER_PORT:3306
MEMBER_STATE:ONLINE
MEMBER_ROLE:PRIMARY
MEMBER_VERSION:8.0.32
MEMBER_COMMUNICATION_STACK:XCom
```

MGR02实例操作：

```sql
greatsql>set session sql_log_bin=0;
greatsql>create user repl@'%'identifiedby'GreatSQL@666';
greatsql>GRANT BACKUP_ADMIN,REPLICATION SLAVE ON *.* TO `repl`@`%`;
greatsql>set session sql_log_bin=1;
greatsql>CHANGE MASTER T OMASTER_USER='repl',MASTER_PASSWORD='GreatSQL@666' FORCHANNEL 'group_replication_recovery';
greatsql>start group_replication;
QueryOK,0rowsaffected(5.39sec)
```

此时创建的用户采用的都是`caching_sha2_password`身份认证插件

```sql
greatsql>SELECT USER,PLUGIN FROM mysql.`user`;
+------------------+-----------------------+
|USER|PLUGIN|
+------------------+-----------------------+
|repl|caching_sha2_password|
|mysql.infoschema|caching_sha2_password|
|mysql.session|caching_sha2_password|
|mysql.sys|caching_sha2_password|
|root|caching_sha2_password|
+------------------+-----------------------+
```

虽然启动MGR成功，但是查看下节点状态：

```sql
greatsql>select * from performance_schema.replication_group_members\G
***************************1.row***************************
CHANNEL_NAME:group_replication_applier
MEMBER_ID:2920447e-35bf-11ee-89a5-00163e566da1
MEMBER_HOST:172.17.139.77
MEMBER_PORT:3306
MEMBER_STATE:ONLINE
MEMBER_ROLE:PRIMARY
MEMBER_VERSION:8.0.32
MEMBER_COMMUNICATION_STACK:XCom
***************************2.row***************************
CHANNEL_NAME:group_replication_applier
MEMBER_ID:2a4f068b-35bf-11ee-9504-00163e566da1
MEMBER_HOST:172.17.139.77
MEMBER_PORT:3307
MEMBER_STATE:RECOVERING
MEMBER_ROLE:SECONDARY
MEMBER_VERSION:8.0.32
MEMBER_COMMUNICATION_STACK:XCom
2rowsinset(0.00sec)
```

此时节点一直处于`RECOVERING`状态，查看mgr02实例的错误日志如下：

`2023-08-08T08:00:47.034870Z42[ERROR][MY-010584][Repl]SlaveI/Oforchannel'group_replication_recovery':errorconnectingtomaster'repl@172.17.139.77:3306'-retry-time:60retries:1message:Authenticationplugin'caching_sha2_password'reportederror:Authenticationrequiressecureconnection.Error_code:MY-002061
2023-08-08T08:00:47.037631Z35[ERROR][MY-011582][Repl]Plugingroup_replicationreported:'Therewasanerrorwhenconnectingtothedonorserver.Pleasecheckthatgroup_replication_recoverychannelcredentialsandallMEMBER_HOSTcolumnvaluesofperformance_schema.replication_group_memberstablearecorrectandDNSresolvable.'
2023-08-08T08:00:47.037671Z35[ERROR][MY-011583][Repl]Plugingroup_replicationreported:'Fordetailspleasecheckperformance_schema.replication_connection_statustableanderrorlogmessagesofSlaveI/Oforchannelgroup_replication_recovery.'
`

这是由于`caching_sha2_password` 是 MySQL 8.0.4 引入的一个新的身份验证插件，`caching_sha2_password` 对密码安全性要求更高，要求用户认证过程中在网络传输的密码是加密的，所以导致的这个问题的出现，`caching_sha2_password`的介绍可以看社区文章“[浅谈 MySQL 新的身份验证插件 caching\_sha2\_password](http://mp.weixin.qq.com/s?__biz=MzkzMTIzMDgwMg==&mid=2247497560&idx=1&sn=817760966383baa42700654b0fa6a02c&chksm=c26c9265f51b1b736b5e1b0b3e0f6842600db38f9960af1ec7bfa3b96289aa8bf22fd604d19a&scene=21#wechat_redirect)”

## 解决方式

### 1、采用旧密码验证插件

旧的身份验证插件`mysql_native_password`，`mysql_native_password`的特点是不需要加密的连接。该插件验证速度特别快，但是不够安全，只需要更改创建用户的语句

`createuserrepl@'%'identifiedwithmysql_native_passwordby'GreatSQL@666';
`

旧密码验证插件容易被破解，如果有 GreatSQL 服务要公网上使用，建议还是尽量使用 `caching_sha2_password`作为认证插件

### 2、启用group\_replication\_recovery\_get\_public\_key

设置 `group_replication_recovery_get_public_key=ON` 可以确保从节点在连接到主节点时能够获取所需的公钥，从而允许安全连接并成功进行身份验证，避免了连接错误和身份验证问题。

手册中也有明确说明：

>18.6.3.1.1ReplicationUserWithTheCachingSHA-2AuthenticationPlugin
Bydefault,userscreatedinMySQL8useSection6.4.1.2,“CachingSHA-2PluggableAuthentication”.IfthereplicationuseryouconfigurefordistributedrecoveryusesthecachingSHA-2authenticationplugin,andyouarenotusingSSLfordistributedrecoveryconnections,RSAkey-pairsareusedforpasswordexchange.FormoreinformationonRSAkey-pairs,seeSection6.3.3,“CreatingSSLandRSACertificatesandKeys”.

>Inthissituation,youcaneithercopythepublickeyofthetothejoiningmember,orconfigurethedonorstoprovidethepublickeywhenrequested.Themoresecureapproachistocopythepublickeyofthereplicationuseraccounttothejoiningmember.Thenyouneedtoconfigurethegroup_replication_recovery_public_key_pathsystemvariableonthejoiningmemberwiththepathtothepublickeyforthereplicationuseraccount.rpl_user

>Thelesssecureapproachistosetgroup_replication_recovery_get_public_key=ONondonorssothattheyprovidethepublickeyofthereplicationuseraccounttojoiningmembers.Thereisnowaytoverifytheidentityofaserver,thereforeonlysetgroup_replication_recovery_get_public_key=ONwhenyouaresurethereisnoriskofserveridentitybeingcompromised,forexamplebyaman-in-the-middleattack.


可以看到，当确认环境安全以及没人任何人攻击集群时，如果不配置ssl，可以最低配置`group_replication_recovery_get_public_key=ON`来在请求复制用户密钥时给公钥

### 3、为组复制通道启用SSL支持

> 以下操作方法仅使用于 **GreatSQL/MySQL 8.0.27**版本及以上

更安全的方法是将repl用户所需的公钥文件复制到joiner节点的Server所在主机中。然后，在joiner节点的Server中配置`group_replication_recovery_public_key_path`系统变量，指定rpl\_user用户所需的公钥文件路径。

使用`caching_sha2_password` 插件身份验证会在数据目录下生成如下两个RSA文件：

`private_key.pem
public_key.pem
`

*   `private_key.pem`：RSA私钥
    
*   `public_key.pem`：RSA公钥
    

对于 MGR ，如果设置 `group_replication_ssl_mode=DISABLED` 必须使用下面的变量来指定 RSA 公钥，否则报错：

*   `group_replication_recovery_get_public_key` ：向服务端请求 RSA 公钥；
    
*   `group_replication_recovery_public_key_path` ：指定本地 RSA 公钥文件；
    

指定本地RSA公钥，首先需要全局MGR配置开启SSL

```bash
[mysqld]
# _开启use_ssl，指定组成员之间的组复制分布式恢复连接是否应使用SSL_
loose-group_replication_recovery_use_ssl=ON
```

进入MGR01实例配置

```sql
greatsql>set session sql_log_bin=0;
#_此时就可以使用“caching_sha2_password”身份认证插件_
greatsql>create user repl@'%' identified by 'GreatSQL@666';
greatsql>GRANT BACKUP_ADMIN,REPLICATION SLAVE ON *.* TO`repl`@`%`;
greatsql>set session sql_log_bin=1;
greatsql>CHANGE MASTER TO MASTER_USER='repl',MASTER_PASSWORD='GreatSQL@666' FOR CHANNEL 'group_replication_recovery';
```

启动MGR01实例的MGR集群

```sql
greatsql>setglobalgroup_replication_bootstrap_group=ON;
greatsql>startgroup_replication;
greatsql>select*fromperformance_schema.replication_group_members\G
***************************1.row***************************
CHANNEL_NAME:group_replication_applier
MEMBER_ID:35b653d2-3658-11ee-93c9-00163e566da1
MEMBER_HOST:172.17.139.77
MEMBER_PORT:3306
MEMBER_STATE:ONLINE
MEMBER_ROLE:PRIMARY
MEMBER_VERSION:8.0.32
MEMBER_COMMUNICATION_STACK:XCom
```

启动成功后，需要把MGR01节点的`RSA公钥`拷贝到MGR02节点上,因为MGR02也会生成此公钥，所以最好创建一个文件夹

```bash 
$mkdir mgr01_key
$chown mysql:mysql mgr01_key/
#将public_key.pem移动到MGR02
$mv/data/GreatSQL/mgr01/public_key.pem /data/GreatSQL/mgr02/mgr01_key/
```

> 当然，如果有多个节点，也需要把主节点的RSA公钥移动到各个节点上

MGR02节点操作

```sql
greatsql>set session sql_log_bin=0;
greatsql>create user repl@'%' identified by'GreatSQL@666';
greatsql>GRANT BACKUP_ADMIN,REPLICATION SLAVE ON *.* TO `repl`@`%`;
greatsql>set session sql_log_bin=1;
greatsql>CHANGE MASTER TO MASTER_USER='repl',MASTER_PASSWORD='GreatSQL@666' FOR CHANNEL 'group_replication_recovery';

#_此命令设置完成后，最好写进my.cnf文件中持久化_
greatsql>set global group_replication_recovery_public_key_path="/data/GreatSQL/mgr02/mgr01key/public_key.pem";

greatsql>start group_replication;
greatsql>select * from performance_schema.replication_group_members\G
***************************1.row***************************
CHANNEL_NAME:group_replication_applier
MEMBER_ID:35b653d2-3658-11ee-93c9-00163e566da1
MEMBER_HOST:172.17.139.77
MEMBER_PORT:3306
MEMBER_STATE:ONLINE
MEMBER_ROLE:PRIMARY
MEMBER_VERSION:8.0.32
MEMBER_COMMUNICATION_STACK:XCom
***************************2.row***************************
CHANNEL_NAME:group_replication_applier
MEMBER_ID:aa031fb9-365a-11ee-9925-00163e566da1
MEMBER_HOST:172.17.139.77
MEMBER_PORT:3307
MEMBER_STATE:ONLINE
MEMBER_ROLE:SECONDARY
MEMBER_VERSION:8.0.32
MEMBER_COMMUNICATION_STACK:XCom

```

可以看到双节点`ONLINE`，新加入的节点不会一直是`RECOVERING`状态

## 总结

新身份验证插件`caching_sha2_password`安全度相比其他的身份验证插件，既解决安全性问题又解决性能问题，建议使用新密码验证插件。

也感谢社区用户指出GreatSQL社区文档中的不足，并给予用户金币奖励，同时欢迎大家来GreatSQL社区捉虫~

EnjoyGreatSQL:）

* * *

《深入浅出MGR》视频课程

戳此小程序即可直达B站

**https://www.bilibili.com/medialist/play/1363850082?business=space\_collection&business\_id=343928&desc=0**

* * *

**文章推荐：**

*   [图文结合丨玩转MySQL Shell for GreatSQL](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653940680&idx=1&sn=c3978e634c8776b95dfa6cc66d15972b&chksm=bd3b71a28a4cf8b4f7af2da6aa82a50f09c6db9b43b4e2942f0fd068e66fffdce3a3b29e4eac&scene=21#wechat_redirect)
    
*   [野路子mysqld\_safe玩法搞死mysqld进程](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653940665&idx=1&sn=1d1db5f2f809a3cae32b47188e1ebcbd&chksm=bd3b71d38a4cf8c5810338be84121bd5db8f375de0f211b802782cdfd7045e03c87768851cdb&scene=21#wechat_redirect)
    
*   [MTS性能监控你知道多少](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653940641&idx=1&sn=9dcff98e032e3722ab82e251fac72116&chksm=bd3b71cb8a4cf8dd0e3cfd66390d5d512656e6878f2fa31e77918997549d35072e8ee3e53836&scene=21#wechat_redirect)
    

*   [MySQL 8.0.29 instant DDL 数据腐化问题分析](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653940548&idx=1&sn=51e886409787423676099bbd56beed89&chksm=bd3b712e8a4cf838f17c1cea634f4ba0078c0cff205f8504be0195121b5ec2f594755aad8cd4&scene=21#wechat_redirect)
    
*   [GreatSQL删除表分区特别慢的原因分析](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653940497&idx=1&sn=74c186e42eadb913a9e8c239939431a3&chksm=bd3b717b8a4cf86d0d2eb0bc37ef98d5cb69d938e37be7004e27f9244d57e3f95955202a9527&scene=21#wechat_redirect)
    
*   [MySQL对derived table的优化处理与使用限制](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653940469&idx=1&sn=91a9e69e86c518357976e2c1e7cc3732&chksm=bd3b709f8a4cf989d70e722c321785b036e514068168623cdabad0f491bc7cdf813c590a3f7d&scene=21#wechat_redirect)
    
*   [MySQL一次大量内存消耗的跟踪](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653940423&idx=1&sn=ce2f3b595ee413ef80815d45a55a1a2e&chksm=bd3b70ad8a4cf9bb3a89e942f97b0c18fa6d88436fea706e01f0129da1b249ee0bab97413c11&scene=21#wechat_redirect)
    
*   [MySQL运行时的可观测性](https://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653940337&idx=1&sn=c6d88bea92069d4b9347939a6c8c2615&scene=21#wechat_redirect)
    
*   [Myloader导入更快吗？并没有。。。](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653940336&idx=1&sn=5e1bb7a231269616e8c5afb62e4a0764&chksm=bd3b701a8a4cf90cf4b56a778ef9f59adde73ea4862a00903ff7746439b4bf90c47b008ac339&scene=21#wechat_redirect)
    

*   [自打有了GIPKs，DBA和开发再也不用battle了](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653940287&idx=1&sn=1501ec1febbb79cf961e8fe4ccaa0d7c&chksm=bd3b70558a4cf9436088b315e46b8271efb9843c548c4359c2563d4a9dea9cf0ee212578a226&scene=21#wechat_redirect)
    
*   [重现一条简单SQL的优化过程](http://mp.weixin.qq.com/s?__biz=MjM5NzAzMTY4NQ==&mid=2653940146&idx=1&sn=a30454cda2a6a822dd22b0e56428f6f8&chksm=bd3b73d88a4cface35eb6d22559934cb7d8ba738d5a5e969b92669f2586498c2cc55b29a758d&scene=21#wechat_redirect)
    

想看更多技术好文，点个“**在看”**吧！

[跳转到 Cubox 查看](https://cubox.pro/my/card?id=7110538658347749194)