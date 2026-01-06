
```bash
# 创建别名
mc alias set  hty-minio http://10.159.65.137:9000  NMryuVx7TXOEQzQB YRslkWPyIZyHaWiQWCIEtMbBf09MNaa1 --api S3v4

mc alias set  idc-minio http://172.30.2.226:9000  zv4CRduS5CxMVmlq ZYPvTl7nsBsRwR4URKUd0QACobsCkAh5  --api S3v4

mc alias set  dzj_backup-minio http://172.29.28.7:9000  l3fxpcpHIv684Fkrqo00 AoUclFkitozLHChqsdF6WlisuBGHEKvYd16coCg0  --api S3v4

# 源minio -> 目标minio
mc mirror --overwrite hty-minio/hty-es-snapshot-bucket idc-minio/hty-es-snapshot-bucket (全量覆盖)
mc mirror hty-minio/hty-es-snapshot-bucket idc-minio/hty-es-snapshot-bucket (增量不覆盖)

# 源minio -> 目标文件目录
 mc cp -r dzj_backup-minio/hty-es-snapshot-bucket/ hty-es-snapshot-bucket/  d


# 源文件目录 -> 目标minio  
 mc cp -r hty-es-snapshot-bucket/  dzj_backup-minio/hty-es-snapshot-bucket/
 
```