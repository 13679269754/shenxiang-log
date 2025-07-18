./dumpling -h172.29.105.51 -P3106 -udzjroot -pxxxxxx -Bresearch --filetype sql -o /home/mysql/research/ -t 8 -r 200000 -F 256MiB


[tidb@localhost ~]$ cat tidb-lightning.toml 
[lightning]
# 日志
level = "info"
file = "tidb-lightning.log"
max-size = 128 # MB
max-days = 28
max-backups = 14

# 启动之前检查集群是否满足最低需求。
check-requirements = true

[mydumper]
# 本地源数据目录或外部存储 URI。关于外部存储 URI 详情可参考 https://docs.pingcap.com/zh/tidb/v6.6/backup-and-restore-storages#uri-%E6%A0%BC%E5%BC%8F。
data-source-dir = "/home/tidb/research"

[tikv-importer]
# 导入模式配置，设为 tidb 即使用逻辑导入模式
backend = "tidb"

[tidb]
# 目标集群的信息。tidb-server 的地址，填一个即可。
host = "172.29.104.60"
port = 4000
user = "root"
# 设置连接 TiDB 的密码，可为明文或 Base64 编码。
password = ""
# tidb-lightning 引用了 TiDB 库，并生成产生一些日志。
# 设置 TiDB 库的日志等级。
log-level = "error"

tidb-lightning -config tidb-lightning.toml