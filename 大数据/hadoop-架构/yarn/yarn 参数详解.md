| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2023-9月-24 | 2023-9月-24  |
| ... | ... | ... |
---
# yarn 参数详解.md

[toc]


| 参数类型 | 参数 | 备注 |
| :----: | :----:| :----: |
| ResourceManager | yarn.resourcemanager.scheduler.class | 配置调度器，默认容量 |
| ResourceManager |yarn.resourcemanager.scheduler.client.thread-count | ResourceManager处理调度器请求的线程数量，默认50 |
||||
| NodeManager | yarn.nodemanager.resource.detect-hardware-capabilities | 是否让yarn自己检测硬件进行配置，默认false |
| NodeManager | yarn.nodemanager.resource.count-logical-processors-as-cores | 是否将虚拟核数当作CPU核数，默认false |
| NodeManager | yarn.nodemanager.resource.pcores-vcores-multiplier |虚拟核数和物理核数乘数，例如：4核8线程，该参数就应设为2，默认1.0 |
| NodeManager | yarn.nodemanager.resource.memory-mb | NodeManager使用内存，默认8G |
| NodeManager | yarn.nodemanager.resource.system-reserved-memory-mb NodeManager | 为系统保留多少内存以上二个参数配置一个即可 |
| NodeManager | yarn.nodemanager.resource.cpu-vcores | NodeManager使用CPU核数，默认8个 |
| NodeManager | yarn.nodemanager.pmem-check-enabled | 是否开启物理内存检查限制container，默认打开 |
| NodeManager | yarn.nodemanager.vmem-check-enabled | 是否开启虚拟内存检查限制container，默认打开 **建议关闭** *java 使用虚拟内存的方式与centos间间有冲突，有浪费*|
| NodeManager | yarn.nodemanager.vmem-pmem-ratio | 虚拟内存物理内存比例，默认2.1 |
||||
| Container | yarn.scheduler.minimum-allocation-mb | 容器最最小内存，默认1G |
| Container | yarn.scheduler.maximum-allocation-mb | 容器最最大内存，默认8G |
| Container | yarn.scheduler.minimum-allocation-vcores | 容器最小CPU核数，默认1个 |
| Container | yarn.scheduler.maximum-allocation-vcores | 容器最小CPU核数，默认1个 |