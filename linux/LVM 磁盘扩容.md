(源文档)[[LVM添加硬盘并扩容至已有分区]]
## 查看分区情况
![](https://ask.qcloudimg.com/http-save/yehe-1005774/fahp1lv120.png)
```bash
## 详细信息
pvdisplay
vgdisplay
lvdisplay

## 简单信息
pvs
vgs
lvs
```

## 为新硬盘创建分区
```bash
fdisk /dev/sdb 
# 输入 n → 创建新分区（默认主分区）→ 按回车确认起始扇区 → 输入 +50G（或直接回车用全部空间）
# 输入 t → 选择分区（默认 1）→ 输入 8e（LVM 类型）
# 输入 w → 保存分区表
```

## 添加到卷组

```bash
# 创建物理卷
pvcreate /dev/sdb1  # 若用整个硬盘则为 pvcreate /dev/sdb
pvs

#  扩展卷组
vgextend myvg /dev/sdb1 # myvg 是目标卷组名称，/dev/sdb1 是新 PV 路径 例vgextend  data /dev/vdc1
vgs

# 扩展逻辑卷
lvextend -l +100%FREE /dev/myvg/root
lvdisplay /dev/myvg/root
```

## 扩展文件系统
```bash
# ext4
# 卸载lv
unmount /dev/mapper/data-lv--data

# 先检查文件系统
e2fsck -f /dev/myvg/root # 需卸载 LV 或在线检查（部分系统支持）

# 扩展文件系统​
resize2fs /dev/myvg/root # 自动扩展至 LV 全尺寸



# XFS
# 确认挂载点（如 /）​
df -h /​

# 扩展文件系统（需指定挂载点）​
xfs_growfs / # 而非直接指定 LV 路径
```


### 文件系统检查有报错
```bash
# 修复文件体统错误
# 文件目录
# 修复文件系统
e2fsck -f -y -c /dev/dm-2

#-f：强制检查（即使文件系统显示 “干净”）；
#-y：自动修复所有可修复错误；
#-c：检测坏块并标记（避免后续使用坏块区域）
```

### 修复后挂载并验证数据文件

```bash
# 挂载
unmount /dev/mapper/data-lv--data /usr/local/data
```
![[mysql#数据文件校验 mysqlcheck]]

