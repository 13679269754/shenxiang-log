# ESXi怎么克隆虚拟机的三种方法与操作详解！

[www.abackup.com](https://www.abackup.com/enterprise-backup/how-to-clone-a-virtual-machine-in-esxi-6540.html)

在虚拟化环境中，VMware的ESXi是一款广泛使用的虚拟化平台，为用户提供了强大的虚拟化功能。本文将深入探讨ESXi怎么克隆虚拟机的方法，包括克隆的理由和具体的操作步骤。

## 为什么要ESXi克隆虚拟机？

**快速部署：** 克隆虚拟机是快速部署相似系统的有效方式。通过克隆，您可以在短时间内复制并配置一个相似的虚拟机，节省了配置和安装操作系统的时间。

**开发和测试：** 在开发环境中，克隆虚拟机可提供相同的开发和测试环境，确保团队成员在相似的系统上进行工作，避免了由于环境不同而导致的问题。

**灾难恢复：** 克隆虚拟机作为灾难恢复的一部分，可以在系统发生故障时快速替代，降低系统中断的风险。

**资源隔离：** 不同应用程序或服务可能需要不同的资源配置。通过克隆虚拟机，可以将它们隔离在各自的虚拟环境中，防止资源冲突。

## ESXi虚拟机克隆虚拟机的方法

ESXi怎么克隆虚拟机？可以使用不同的工具实现，下面分享了3种方法。

### 方法1：使用vCenter Server进行克隆

1\. **打开vCenter Server：** 使用vSphere客户端连接到vCenter Server。

2\. **选择虚拟机：** 在vSphere客户端中，导航到**“主页”**或**“虚拟机和模板”**视图，选择要克隆的虚拟机。

3\. **右键点击选择克隆：** 右键点击选中的虚拟机，然后选择**“克隆”->“克隆到虚拟机”**选项。

![1](https://www.abackup.com/enterprise-backup/image6540/virtual-machine/clone%20-to-virtual-machine.png)

4\. **配置克隆选项：** 在克隆向导中，配置虚拟机的名称、位置、存储和其他设置。

5\. **选择网络配置：** 根据需要配置虚拟机的网络设置，确保网络连接的正确性。

6\. **选择数据存储：** 选择虚拟机克隆的存储位置。

![2](https://www.abackup.com/enterprise-backup/image6540/virtual-machine/select-storage-location.png)

7\. **选择克隆模板：** 如果有可用的模板，可以在这一步选择合适的模板。

8\. **完成克隆：** 完成所有配置后，点击**“完成”**来启动克隆过程。等待克隆完成，验证新克隆的虚拟机。

### 方法2：使用ESXi主机进行克隆

使用怎么克隆虚拟机？步骤如下。

1\. **连接到ESXi主机：** 登录到ESXi主机网页端口。

2\. **打开数据存储浏览器：**

![3](https://www.abackup.com/enterprise-backup/image6540/virtual-machine/storage-datastore-browser.png)

3\. **创建存放文件的目录：**点击**“创建目录”**，然后在弹出的窗口种输入目录名称。

![4](https://www.abackup.com/enterprise-backup/image6540/virtual-machine/create-directory.png)

4\. 复制需要克隆的虚拟机中的WINdows2012R2.vmdk和WINdows2012R2.vmx这两个文件到新建的文件夹上。

5\. **注册虚拟机：**点击新建的目录，然后选择**“注册虚拟机”**。

!\[\](https://www.abackup.com/enterprise-backup/image6540/virtual-machine/register-virtual-machine.png)

### 方法3：专业虚拟机备份工具克隆虚拟机

专业的虚拟机备份工具—[傲梅企业备份旗舰版](https://www.abackup.com/cyber-backup.html)可以批量备份还原以安装多台正在运行的虚拟机，包括由vCenter Server管理或在单独的ESXi主机上管理虚拟机。可以创建独立的虚拟机映像备份并设置自动备份任务以及即时的灾难恢复。您可以使用其灵活的策略备份多个虚拟机。

**无代理映像备份：**为VMware ESXi和Hyper-V虚拟机创建独立的基于映像的备份。

**自动备份：**根据每日/每周/每月计划[自动备份](https://www.abackup.com/enterprise-backup/esxi-automatic-backup-of-virtual-machines-666.html)，以自动运行备份任务，无需人工干预。

**集中备份：**在中控制台中批量备份虚拟机，而无需在每个虚拟机上安装代理。

**兼容性强：**支持Windows PC与Server操作系统，支持备份Hyper-V或VMware虚拟机。

**支持免费ESXi：**支持付费和免费版本的VMware ESXi。

**多种备份方式：**除了完整备份，您还可以执行VM[增量或差异备份](https://www.abackup.com/easybackup-tutorials/incremental-vs-differential-backup-666.html)以捕获更改的数据并节省存储空间。

使用这个工具ESXi怎么克隆虚拟机？您可以进入傲梅官网访问[下载中心](https://www.abackup.com/download.html)获取并安装傲梅企业备份旗舰版，然后通过备份需要克隆的虚拟机，再批量还原到需要安装的主机或虚拟机中，下面是详细操作步骤。

1\. **添加设备：**访问**“设备”>>“VMware”>>“添加设备”**，然后输入需要克隆的ESXi信息。

![](https://www.abackup.com/enterprise-backup/image6540/entbackupcyber/VM/add-vmware-esxi.png)

2\. 单击**“备份任务”>>“+新建任务”**以自动执行VMware虚拟机备份，然后将其作为多个虚拟机的模板。

![](https://www.abackup.com/enterprise-backup/image6540/entbackupcyber/task/create-new-backup-task.png)

• **设备名称：**选择主机上的一个或多个虚拟机。

![](https://www.abackup.com/enterprise-backup/image6540/entbackupcyber/task/select-virtual-machine-vcenter.png)

• **备份目标：**指定存储虚拟机备份的位置，例如网络共享或本地位置。

![](https://www.abackup.com/enterprise-backup/image6540/entbackupcyber/task/add-network-target.png)

• **备份计划（可选）：**选择完全备份/增量备份，设置备份频率为天/周/月。

![](https://www.abackup.com/enterprise-backup/image6540/entbackupcyber/task/schedule-backup.png)

• **版本清理（可选）：**指定将自动删除不需要的备份的保留期。

![](https://www.abackup.com/enterprise-backup/image6540/entbackupcyber/task/backup-cleanup.png)

3\. **开始备份：**选择**“添加定时任务并立即开始备份”**或**“仅添加定时任务”**。

4\. 然后就可以还原备份任务了以让[VMware创建多个虚拟机](https://www.abackup.com/enterprise-backup/vmware-batch-deployment-of-vms-666.html)。点击**“备份管理”**，然后选择**“还原记录”**，再点击**“新建还原”**选择要迁移的内容，然后选择**“还原到新位置”**。系统将要求您命名新虚拟机，选择目标主机和数据存储。

5\. 设置完成后，单击**“开始还原”**以执行该操作。完成后，所选虚拟机的所选版本将迁移到您指定的数据存储中。

![](https://www.abackup.com/enterprise-backup/image6540/entbackupcyber/task/restore-to-new-location.png)

## 总结

学会上面分享了ESXi怎么克隆虚拟机的三种方法，您可以轻松在ESXi环境中进行虚拟机的克隆，提高系统的灵活性和可维护性。在实际应用中，选择适用于您需求的方法，并根据需要进行定制化配置，以满足不同场景下的需求。

[跳转到 Cubox 查看](https://cubox.pro/my/card?id=7147179662173537937)