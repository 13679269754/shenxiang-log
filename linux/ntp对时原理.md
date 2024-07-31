   [NTP报文解析及对时原理](https://www.cnblogs.com/21summer/p/14819406.html "发布于 2021-05-27 19:14")
=======================================================================================

参考：[https://blog.csdn.net/dosthing/article/details/81588219](https://blog.csdn.net/dosthing/article/details/81588219)

### NTP(Network Time Protocol）网络时间协议基于UDP，默认端口为123。

### 1、NTP报文示例

其中192.10.10.189为NTP的server端，192.10.10.32为client端。  
![](https://img2020.cnblogs.com/blog/405122/202105/405122-20210527183525405-1901884869.png)
  
  
  
![](https://img2020.cnblogs.com/blog/405122/202105/405122-20210527184651679-1255178352.png)

### 2、NTP服务端与客户端的交互过程

![](https://img2020.cnblogs.com/blog/405122/202105/405122-20210527185720659-735344497.png)
  
客户端和服务端都有一个时间轴，分别代表着各自系统的时间，当客户端想要同步服务端的时间时，客户端会构造一个NTP协议包发送到NTP服务端，客户端会记下此时发送的时间t0，经过一段网络延时传输后，服务器在t1时刻收到数据包，经过一段时间处理后在t2时刻向客户端返回数据包，再经过一段网络延时传输后客户端在t3时刻收到NTP服务器数据包。t0和t3是客户端时间系统的时间、t1和t2是NTP服务端时间系统的时间，它们是有区别的。  
t0、t1、t2分别对应着server->cient NTP报文中的三个参数：  
t0：origin timestamp  
t1: receive timestamp  
t2: transmit timestamp  
t3为client收到回复报文时本地的时间。

### 3、延时和时间偏差计算

假设：客户端与服务端的时间系统的偏差定义为θ、网络的往/返延迟(单程延时)定义为δ。  
推导过程：  
1）根据交互原理，可以列出方程组：  
t0+θ+δ=t1  
t2-θ+δ=t3  
2）求解方程组，得到以下结果：  
θ=(t1-t0+t2-t3)/2  
δ=(t1-t0+t3-t2)/2  
记忆时可以采用极限法，分别假设延时和偏差为0.

### 4、client时间校准：

对于时间要求不那么精准设备，client端可把server端的返回时间t2固化为本地时间。但是作为一个标准的通信协议，必须计算上网络的传输延时，需要把t2+δ 固化为本地时间。  
以上client时间校准算法只为理解过程，不代表真实做法

### 5、报文中其他参数说明

#### mode：工作模式

服务器 / 客户模式（server / client）  
对等体模式（symmetric active / symmetric passive）  
广播模式（broadcast server / broadcast client）  
组播模式（multicast server / multicast client）

#### 关于NTP的层数

层数（取值范围 1-15）: 层数是NTP中一个比较重要的概念,它基本上可以说是代表了一个时钟的准确度,层数为1的时钟准确度最高,从1到15依次递减.