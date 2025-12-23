| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2025-1月-10 | 2025-1月-10 |
| ... | ... | ... |
---
# centos 系统修复.md

[toc]

## 原文
[Linux-使用镜像进入救援模式修复系统 - 风吹蛋生丶 - 博客园](https://www.cnblogs.com/xzj-blog/p/14155463.html) 

**遇到内核文件损坏或者是grub引导程序丢失等错误,出现截图的报错信息.**  
**当前修复的环境为vmware虚拟机, 系统版本为Centos7.4**

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-10%2017-28-08/8a7330d7-07ba-4b82-bd0a-59142516e7da.png?raw=true)

## 1.1. 挂载ISO镜像至虚拟机中
-----------------

> 此时虚拟机处于关闭状态

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-10%2017-28-08/8f5a2671-8aa2-4c45-8cf1-0b009e7275e7.png?raw=true)

## 1.2. 虚拟机设置启动项为CD-ROM
--------------------

> 虚拟机右键-->电源--> 打开时进入固件-->选择Boot--> 将CD-ROM Drive项调整至第一位 --> 按F10保存重启

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-10%2017-28-08/4a30d79b-45b3-4012-ba67-cb6daafb723f.png?raw=true)
  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-10%2017-28-08/d2f1f940-b022-4d96-a126-f5bd296ebdf0.png?raw=true)

## 1.3. 根据步骤进入救援模式
---------------

> Troublesbooting --> Rescure a CentOS system --> 等待一段时间 --> 按"1 continue继续进行"

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-10%2017-28-08/57f9ea9b-f77f-46ad-9128-859a0b1c725c.png?raw=true)
  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-10%2017-28-08/1c0ebf5c-2517-45ee-8b9d-4287ffdb3b3b.png?raw=true)
  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-10%2017-28-08/102ff641-ef3a-4fd0-b082-089a550f5632.png?raw=true)

## 1.4. 进行修复操作
-----------

```null

chroot /mnt/sysimage

mount  /dev/sr0    /mnt

rpm  -ivh /mnt/Packages/kernel-3.10.0-693.e17.x86__64.rpm --force

grub2-install /dev/sda


cd /boot/grub2
grub2-mkconfig -o grub.cfg


```

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-10%2017-28-08/4dfd3d32-9643-4ac5-b7f9-0bfb4ce438f5.png?raw=true)
  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-10%2017-28-08/beb0f91e-6ef4-4d1f-abe7-eb8529bb3d52.png?raw=true)
  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-10%2017-28-08/4383517b-864c-4684-98db-a8f50700634f.png?raw=true)

```null
> chroot /mnt/sysimage
you don't have any Linux partitions the system will reboot automatically when you exit from the shell

```

在切换根目录的时候报错导致无法继续修复内核和grub引导程序  
修复建议

```null

> lvm vgscan
> lvm lvscan
>lvm vgchange -ay 
> fsck /dev/centos/root -L

```

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-10%2017-28-08/8dd28d47-77de-4df6-b1b5-86c5a0f5a563.png?raw=true)
  
至此,系统正常打开.  
