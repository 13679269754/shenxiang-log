
## 说明
与[[LVM添加硬盘并扩容至已有分区]]和[[LVM 磁盘扩容]]所描述的内容不同，以上文件都是新加磁盘。
而本文需要进行的操作是，原有磁盘已经被作为lvm挂载。添加磁盘时直接在扩展磁盘的大小的情况。

与新加磁盘不同点
1. 新加磁盘不影响原有磁盘，不需要对原有磁盘进行umount。
2. 由于磁盘已经被加入到lvm,导致磁盘即使umount以后，依然被lvm占用，此时需要对原有的lvm进行调整

## 步骤一：解除 LVM 绑定并释放磁盘
### 1. 卸载逻辑卷（LV）的挂载点
若 LV 正在挂载使用，需先卸载（否则无法停用卷组）：
```bash
# 替换 /data 为实际挂载点（从 mount 命令中获取）
umount /data
```

若卸载失败（提示“设备忙”），终止占用进程后重试：
```bash
# 查找占用 LV 的进程
fuser -m /data

# 终止进程（替换 PID 为实际编号）
kill -9 <PID>

# 再次卸载
umount /data
```


### 2. 停用卷组（VG）
```bash
# 替换 <vg_name> 为卷组名（如 vg_data）
vgchange -a n <vg_name>
```
- `-a n` 表示“停用卷组中的所有逻辑卷”，释放对物理卷的占用。


### 3. 从卷组（VG）中移除物理卷（PV）
```bash
# 替换 <vg_name> 和 /dev/vdb2 为实际名称
vgreduce <vg_name> /dev/vdb2
```
- 此操作将 `/dev/vdb2` 从卷组中移除，解除关联。


### 4. 删除物理卷（PV）
```bash
pvremove /dev/vdb2
```
- 彻底删除 `/dev/vdb2` 的 LVM 物理卷标识，释放磁盘。


## 步骤二：分区磁盘 
完成 LVM 解绑后，再次尝试刷新分区表：
```bash

# 对磁盘新加部分进行分区
fdisk  /dev/vdb

# 若提示
Calling ioctl() to re-read partition table.

WARNING: Re-reading the partition table failed with error 16: 设备或资源忙.
The kernel still uses the old table. The new table will be used at
the next reboot or after you run partprobe(8) or kpartx(8)

# 强制内核重新读取分区表
partprobe /dev/vdb

# 若仍提示“设备忙”，执行 kpartx
kpartx -u /dev/vdb
```


### 验证结果
```bash
# 1. 确认 LVM 已不占用 /dev/vdb2
pvs | grep /dev/vdb2  # 无输出即成功

# 2. 确认分区表已更新（无 /dev/vdb2）
fdisk -l /dev/vdb
```

## 步骤三: 添加新的磁盘
![[LVM 磁盘扩容]]