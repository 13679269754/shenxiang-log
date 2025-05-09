| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-8月-12 | 2024-8月-12  |
| ... | ... | ... |
---
# Linux——让程序在后台运行（四种方法+使用推荐）.md

[toc]

## 资料

[Linux——让程序在后台运行（四种方法+使用推荐）](https://blog.csdn.net/Pan_peter/article/details/128875714)

## 文章内容


### **一、第一种方法（加“&”符号）**
-------------------

> **如果想让程序在后台运行，执行程序的时候，命令的最后面加“&”符号。** 
> 
> **注意：这种方法，查看运行日志很不方便（不推荐）**

### **二、第二种方法（nohup命令）**
--------------------

> ```null
> nohup python -u test.py > test.log 2>&1 & 
> ```
> 
> **参数说明：  
> `test.py`: 你需要后台运行的程序  
> `>`: 日志文件追加到文件中  
> `test.log`: 运行的日志，或你的文件的输出内容**
> 
> * * *
> 
> **& 是一个描述符，如果1或2前不加&，会被当成一个普通文件。** 
> 
> **1>&2 意思是把标准输出重定向到标准错误.**
> 
> **2>&1 意思是把标准错误输出重定向到标准输出。** 
> 
> **&>filename 意思是把标准输出和标准错误输出都重定向到文件filename中**
> 
> ```null
> # 1、原因：在run.py的目录默认直接生成了nohup.out文件
> ```
> 
> ```null
> nohup sudo python -u test.py > test.log2>&1 &
> ```

### **三、第三种方法（screen命令）**
---------------------

> **Screen是一个全屏窗口管理器，**
> 
> **它在多个进程（通常是交互式shell）之间多路传输物理终端。** 

> **快捷键：** 

> ```null
> Ctrl+a 0-9 ：在第0个窗口和第9个窗口之间切换Ctrl+a K(大写) ：关闭当前窗口，并且切换到下一个窗口（当退出最后一个窗口时，该终端自动终止，并且退回到原始shell状态）（当退出最后一个窗口时，该终端自动终止，并且退回到原始shell状态）Ctrl+a d ：退出当前终端，返回加载screen前的shell命令状态
> ```

### **四、第四种方法（systemctl命令）**
------------------------

> **[详情请看： http://t.csdn.cn/XoHUS](http://t.csdn.cn/XoHUS "详情请看： http://t.csdn.cn/XoHUS")**
> 
> **因为systemctl比较复杂，所以这里贴上链接**
> 
> **注意：systemctl设置好之后，可以一劳永逸！**

### **五、总结**
--------

> *使用推荐**
> 
> *   **第一种方法不推荐使用**
> *   **第二种方法——在需要查看日志的情况下，建议使用（无需在关闭的那种）**
> *   **第三种方法——在开启后，还需要关闭或还需要输入一些命令的时候下****（推荐）**
> *   **第四种方法——虽然需要学习的时间比前面几种长，但是学会之后，会很方便**

* * *

### **六、实用操作（重点）**
--------------

> **因为以上单个操作，都会一些弊端**
> 
> **1、如果让进程在后台运行，并输出日志（nohup命令），就不方便手动停止进程（需要用ps命令查看进程）**
> 
> **2、如果让进程在后台运行，并方便停止（screen命令），就不方便查看程序输出的日志**
> 
> * * *
> 
> **因此，我们可以使用组合技！（下面有例子）**

> **1、安装screen**
> 
> **2、新建窗口**
> 
> **3、执行文件**
> 
> ```null
> python test.py > output.log 2>&1
> ```
> 
> **4、退出该窗口**
> 
> **5、查看程序输出文件（output.log）**
> 
> ![](https://i-blog.csdnimg.cn/blog_migrate/a6dfbf343ff185ed19be91b02280f79c.png)
> 
> * * *
> 
> **6、停止程序**
> 
> ![](https://i-blog.csdnimg.cn/blog_migrate/bba05be247f4ab907013f116c39d03f7.png)
> 
> **实在不行，就查看程序的运行状态，也可以通过 `ps` 命令来查看程序是否在运行**