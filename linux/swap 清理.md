| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-2月-18 | 2025-2月-18  |
| ... | ... | ... |
---
# swap 清理

[toc]

在 Linux 系统中，Swap 是交换空间，当物理内存不足时，系统会将部分不常用的内存数据交换到 Swap 空间。如果想要释放被使用的 Swap 空间，可参考以下几种方法：

  
## 关闭 Swap

这种方法通过先关闭 Swap，然后再重新启用的方式来释放已使用的 Swap 空间。在操作前，确保系统有足够的物理内存来容纳当前所有正在运行的程序，否则可能会导致系统性能下降甚至崩溃。

  

```
 sudo swapoff -a

sudo swapon -a 
```

  

*   `swapoff -a`：`swapoff` 命令用于关闭 Swap 空间，`-a` 选项表示关闭所有已启用的 Swap 分区或文件。
*   `swapon -a`：`swapon` 命令用于启用 Swap 空间，`-a` 选项表示启用 `/etc/fstab` 文件中定义的所有 Swap 分区或文件。


## swap 取值调整

`swappiness` 是一个内核参数，其取值范围为 0 - 100，它表示系统将数据从物理内存交换到 Swap 空间的倾向程度。值越高，系统越倾向于使用 Swap 空间；值越低，系统越倾向于使用物理内存。将 `swappiness` 的值调低，可以减少系统对 Swap 空间的使用。

  

```
 sudo sysctl vm.swappiness=10

echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.conf

sudo sysctl -p 
```

  

*   `sysctl vm.swappiness=10`：临时修改 `swappiness` 参数为 10，系统重启后该设置会恢复为默认值。
*   `echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.conf`：将 `swappiness` 的值永久设置为 10，`/etc/sysctl.conf` 是系统启动时加载的内核参数配置文件。
*   `sysctl -p`：重新加载 `/etc/sysctl.conf` 文件中的配置，使新的 `swappiness` 值生效。

## 杀掉占用进程

如果系统中存在一些不必要的进程占用了大量的内存，导致系统使用 Swap 空间，可以通过终止这些进程来释放内存，从而减少对 Swap 空间的使用。

  

```
 ps -eo pid,user,%mem,args --sort=-%mem | head

sudo kill -9 <pid> 
```

  

*   `ps -eo pid,user,%mem,args --sort=-%mem | head`：显示占用内存最多的前 10 个进程，`-e` 表示显示所有进程，`-o` 用于指定输出格式，`--sort=-%mem` 按内存使用率降序排序。
*   `kill -9 <pid>`：强制终止指定进程，`-9` 表示发送强制终止信号（SIGKILL），`<pid>` 是要终止的进程 ID。

## 采用上述方法1，方法2 swap未释放可能原因

**1. 物理内存不足**  
当你执行 swapoff -a 时，系统需要将 Swap 中的数据重新加载到物理内存中。如果物理内存不足，无法容纳 Swap 中的所有数据，系统会拒绝禁用 Swap，从而导致 swapoff 操作失败。 
解决办法：可以先关闭一些占用大量内存的进程，确保物理内存有足够的空间来容纳 Swap 中的数据，再尝试执行 swapoff -a 和 swapon -a。  

**2. 进程锁定内存**  
有些进程可能使用了 mlock() 或 mlockall() 系统调用将部分或全部内存锁定，使其不能被交换到 Swap 空间。在这种情况下，即使物理内存不足，这些锁定的内存也不会被交换出去，而且可能会影响 swapoff 操作。