#!/bin/bash

# 可用磁盘
disk='/dev/vda'
# 挂载目录
mount_dir='/usr/local/data'
lv_name='data'

# 物理盘分盘
echo -e "n\np\n1\n\n\np\nw\n" | fdisk /dev/vda
# 虚拟磁盘卷命名
data_disk=/dev/vda\2
vg_path=vg_$lv_name\_2
lv_path=lv_$lv_name\_2

# 创建物理卷
pvcreate $data_disk
# 创建卷组
vgcreate $vg_path $data_disk    vg_data_3
# 创建虚拟卷
lvcreate -l 100%VG -n $lv_path $vg_path lv_data_3  vg_data_3
# 格式化磁盘
mkfs.xfs /dev/$vg_path/$lv_path  /dev/vg_data_3/lv_data_3

# 挂到指定目录
mkdir -p $mount_dir
mount /dev/$vg_path/$lv_path $mount_dir

# 开机挂载
echo "/dev/mapper/$vg_path-$lv_path $mount_dir   xfs   defaults        0 0" >> /etc/fstab


echo "/dev/mapper/vg_data_3-lv_data_3 /usr/local/data   xfs   defaults        0 0" >> /etc/fstab

