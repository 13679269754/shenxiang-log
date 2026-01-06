
## 需求
当前mysql 数据库数据目录所在磁盘需要下线(/usr/local/data，2tb的机械盘)。需要释放当前磁盘，重新挂载一块1TB的ssd 上去。

## 1.安装必要的环境


```bash

## 数据传输 - 需要限速 可以使用pv 或者rsync 。 推荐可能使用rsync更好
yum install pv

yum install rsync

```

## 2. 磁盘创建（分盘，lvm创建，格式化）
```bash
## 分盘
fdisk /dev/vdc

## lvm
pvcreate  /dev/vdc1

vgextend vg_data  /dev/vdc1

lvcreate -l 100%VG -n lv_data_1 vg_data

## 格式化
mkfs.xfs  /dev/vg_data/lv_data_1 

```

## 3. 文件传输

```bash

mkdir -p /usr/local/data1

mount /dev/vg_data/lv_data_1 /usr/local/data1

tar -cf - data | pv -L 1000M | tar -xf - -C /usr/local/data1

```

## 4. 重新挂载

```bash
umount /usr/local/data

umount /usr/local/data1

mount /dev/vg_data/lv_data_1 /usr/local/data
```

## 5.释放需要下线的磁盘的LV，VG, PV

```bash
lvremove /dev/mapper/vg_data-lv_data

# 如果没有想释放lvm 的配置就下线了磁盘，会导致pv变成unname的 用一下语句补救
# vgreduce --removemissing --force --verbose vg_data

vgreduce vg_data /dev/vdb1

pvremove /dev/vdb1

```

## 6. 修改开机挂载配置
```bash
vim /etc/fstab

将 /dev/mapper/vg_data-lv_data /usr/local/data/  ext4 defaults        0 0
改为 /dev/mapper/vg_data-lv_data_1 /usr/local/data/  xfs defaults        0 0

```

tip 开机挂载失败报错信息:
```bash
12月 03 09:49:02 dzjmysql4 kernel: ppdev: user-space parallel port driver
12月 03 09:49:02 dzjmysql4 lvm[624]: Couldn't find device with uuid IAagdg-e6zC-4BSN-1nxK-kq4A-Fckp-i1dJ0X.
12月 03 09:49:02 dzjmysql4 lvm[624]: 2 logical volume(s) in volume group "centos" monitored
12月 03 09:49:02 dzjmysql4 lvm[624]: WARNING: Device for PV IAagdg-e6zC-4BSN-1nxK-kq4A-Fckp-i1dJ0X not found or rejected by a filter.
12月 03 09:49:02 dzjmysql4 systemd[1]: Started Monitoring of LVM2 mirrors, snapshots etc. using dmeventd or progress polling.
-- Subject: Unit lvm2-monitor.service has finished start-up

```



## 相关内容
[[LVM 磁盘扩容]]
[[LVM 已有配置拓展原有磁盘]]
[[LVM添加硬盘并扩容至已有分区]]