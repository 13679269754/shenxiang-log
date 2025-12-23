
# hadoop 安装

[toc]

## 前期工作

---

### 服务器的初始化

1. 标准化目录创建
2. 用户创建
3. root密码修改
4. iptables 脚本化管理
5. 磁盘挂载

### 安装文件上传

### jdk安装

### ssh免密配置

> 需要配置hadoop 用户的免密，不要使用root用户安装hadoop，会导致报错
```bash
su hadoop  
ssh-keygen  
ssh-copy-id hostname  
```
### hostname别名添加

haddoop 默认使用host解析，不使用hostname会报错
[使用ip配置hadoop报错解决方法](https://blog.csdn.net/lepton126/article/details/88342652)

`hostname -a [name]`

`vim /etc/hosts`

例:
```bash
10.10.1.12  hadoop1
10.10.1.15  hadoop2
10.10.1.209 hadoop3
```

---

### hadoop安装

*解压安装包到指定目录*
`tar -zxvf [安装包] -C /usr/local/data/`

*修改配置文件*
（1）默认配置文件：
要获取的默认文件
文件存放在 Hadoop 的 jar 包中的位置
| 文件名称 | 文件位置 |
| --- | --- |
| [core-default.xml] | hadoop-common-3.1.3.jar/core-default.xml |
| [hdfs-default.xml] | hadoop-hdfs-3.1.3.jar/hdfs-default.xml |
| [yarn-default.xml] | hadoop-yarn-common-3.1.3.jar/yarn-default.xml |
| [mapred-default.xml] | hadoop-mapreduce-client-core-3.1.3.jar/mapred-default.xml |

（2）自定义配置文件：
core-site.xml、hdfs-site.xml、yarn-site.xml、mapred-site.xml 四个配置文件存放在
$HADOOP_HOME/etc/hadoop 这个路径上，用户可以根据项目需求重新进行修改配置。

其中**自定义配置文件可以覆盖默认配置文件中的配置**

**core-default.xml**

```bash
<configuration>
    <!-- 指定namenode的hdfs协议的文件系统通信地址，默认是file:///本地文件系统  需要我们改成 hdfs://分布式文件存储系统 -->
    <!-- 可以指定一个主机+端口，也可以指定为一个namenode服务（这个服务内部可以有多台namenode实现ha的namenode服务） -->
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://hadoop1:9000</value>
    </property>

    <!-- 临时数据存放的位置 -->
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/usr/local/data/hadoop-data/tmp</value>
    </property>

    <!-- 缓冲区大小，实际工作中根据服务器性能动态调整 -->
    <property>
        <name>io.file.buffer.size</name>
        <value>4096</value>
    </property>
    
    <!--  开启hdfs的垃圾桶机制，删除掉的数据可以从垃圾桶中回收，单位分钟  10080 相当与7天  60*24*7-->
	<property>
		<name>fs.trash.interval</name>
		<value>10080</value>
	</property>

    <!-- 故障转移需要的zookeeper集群设置一下-->
    <property>
        <name>ha.zookeeper.quorum</name>
        <value>hadoop1:2181,hadoop2:2181,hadoop3:2181</value>
    </property>
    <!-- 配置 HDFS 网页登录使用的静态用户为 atguigu -->
    <property>
        <name>hadoop.http.staticuser.user</name>
        <value>sx</value>
    </property>
    
</configuration>
```

**hdfs-default.xml**
```bash
<configuration>
    <!-- NameNode 数据的存放地点。也就是namenode元数据存放的地方，记录了hdfs系统中文件的元数据-->
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/usr/local/data/hadoop_data-name_node</value>
    </property>

    <!-- NameNode 的访问地址 -->
    <property>
        <name>dfs.namenode.http-address</name>
        <value>hadoop1:50070</value>
    </property>
    
    <!-- DataNode 数据的存放地点。也就是block块存放的目录了-->
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/usr/local/data/hadoop_data-data_node</value>
    </property>

    <!-- HDFS 的副本数设置。也就是上传一个文件，其分割为block块后，每个block的冗余副本个数-->
    <property>
        <name>dfs.replication</name>
        <value>2</value>
    </property>
    
	<!-- HDFS 的权限控制 -->
	<property>
		<name>dfs.permissions</name>
		<value>false</value>
	</property>
    
    <!-- 文件存储的block块大小 -->
    <property>
        <name>dfs.blocksize</name>
        <value>134217728</value>  
    </property>
    
    <!-- secondary NameNode 的http通讯地址-->
    <property>
        <name>dfs.secondary.http.address</name>
        <value>hadoop1:50090</value>
    </property>
    
    <!-- secondary NameNode 的访问地址 -->
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>hadoop2:50090</value>
    </property>

	<!-- 元数据操作日志的存放位置 edits的存放位置 -->
	<property>
		<name>dfs.namenode.edits.dir</name>
		<value>file:///usr/local/data/hadoop-data/edits</value>
	</property>

	<!-- 元数据检查点保存的位置 -->
	<property>
		<name>dfs.namenode.checkpoint.dir</name>
		<value>file:///usr/local/data/hadoop-data/name</value>
	</property>

    <property>
        <!-- 开启hdfs的web访问接口。默认端口是50070 , 一般不配 , 使用默认值-->
        <name>dfs.webhdfs.enabled</name>
        <value>true</value>
    </property>
</configuration>
```

**yarn-default.xml**
```bash
<configuration>
    <!-- 指定mr框架为yarn方式,Hadoop二代MP也基于资源管理系统Yarn来运行 -->
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    
    <!-- 开启mapreduce的小任务模式，用于调优 -->
    <property>
        <name>mapreduce.job.ubertask.enable</name>
        <value>true</value>
    </property>
    
    <!-- 配置mapreduce的jobhistory内部通讯地址。可以查看我们所有运行完成的任务的一些情况 -->
    <property>	
        <name>mapreduce.jobhistory.address</name>
        <value>hadoop3:10020/jobhistory/logs</value>	
    </property>

    <!-- 配置mapreduce 的jobhistory的访问地址 -->
    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>hadoop3:19888</value>
    </property>
    
</configuration>

```

**mapred-default.xml**
```bash
<configuration>
    <!-- 指定我们的resourceManager运行在哪台机器上面 -->
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>hadoop3</value>
    </property>

    <!-- NodeManager的通信方式 -->
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>

    <!-- 日志的聚合功能，方便我们查看任务执行完成之后的日志记录 -->
    <property>
        <name>yarn.log-aggregation-enable</name>
        <value>true</value>
    </property>
    <!-- 设置日志聚集服务器地址 -->
    <property>
        <name>yarn.log.server.url</name>
        <value>http://hadoop3:19887/jobhistory/logs</value>
    </property>
    <!-- 设置日志保留时间为 7 天 -->
    <property>
        <name>yarn.log-aggregation.retain-seconds</name>
        <value>604800</value>
    </property>

    <!-- 聚合日志的保存时长 -->
    <property>
        <name>yarn.log-aggregation.retain-seconds</name>
        <value>604800</value>
    </property>

    <!--yarn总管理器的IPC通讯地址-->
    <property>
        <name>yarn.resourcemanager.address</name>
        <value>hadoop3:8032</value>
    </property>

    <!--yarn总管理器调度程序的IPC通讯地址-->
    <property>
        <name>yarn.resourcemanager.scheduler.address</name>
        <value>hadoop3:8030</value>
    </property>

    <!--yarn总管理器的IPC通讯地址-->
    <property>
        <name>yarn.resourcemanager.resource-tracker.address</name>
        <value>hadoop3:8031</value>
    </property>

    <!--yarn总管理器的IPC管理地址-->
    <property>
        <name>yarn.resourcemanager.admin.address</name>
        <value>hadoop3:8033</value>
    </property>

    <!--yarn总管理器的web http通讯地址-->
    <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>hadoop3:6088</value>
    </property>
    
</configuration>
```

### hadoop 简单使用

命令行

```bash
# 文件上传到 hdfs
hadoop fs -put [文件名] [hdfs中的目录]
# 查看文件夹
hadoop fs -ls  [hdfs中的目录]
```

页面下载报错
报错原因:
使用hadoop 集群中使用的hostname通信,而本地机器没有配置host，导致访问报错。
[hadoop web页面无法下载文件](https://blog.csdn.net/RONE321/article/details/98943282)

运行mapreduce 报错
Container exited with a non-zero exit code 1. Error file: prelaunch.err.
[hadoop classpath 导致报错，找不到](https://blog.csdn.net/l1682686/article/details/108364029)

