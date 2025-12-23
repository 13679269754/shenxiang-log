
### 说明本文内容提炼自mysql 文档

[MySQL :: MySQL Shell 9.4 :: 8.8 恢复和重启 InnoDB 集群 --- MySQL :: MySQL Shell 9.4 :: 8.8 Restoring and Rebooting an InnoDB Cluster](https://dev.mysql.com/doc/mysql-shell/9.4/en/troubleshooting-innodb-cluster.html)
### 一. 实例重新加入集群

```bash
Cluster.rejoinInstance(instance)
```

当server_uuid 发生变化时，例如重备份恢复的实例
 
 >tips：
 >	server_uuid 保存在$data目录的auto.cnf中

 执行 Cluster.rescan() 以使用新的 server_uuid 将实例添加到元数据中
 
 ```bash
cluster.removeInstance("root@instanceWithOldUUID:3306", {force: true})

cluster.rescan()
 ```

_`Cluster`_.removeInstance() 支持force 参数，当节点不可达是需要该参数


### 二. 从Quorum Loss(法定人数不足)中恢复集群


```bash
cluster.forceQuorumUsingPartitionOf("icadmin@ic-1:3306")
```

> **此操作可能非常危险，因为如果使用不当，可能会创建脑裂场景，应被视为最后的手段。务必确保该组中没有任何分区仍在网络中的某个地方运行，但无法从您的位置访问**。

如果实例没有自动添加到集群中，例如如果其设置未持久化，请使用 `Cluster.rejoinInstance()` 手动将实例添加回集群。

该操作根据 `instance` 上的元数据恢复集群，然后所有从给定实例定义的角度来看是 `ONLINE` 的实例都被添加到恢复后的集群中。

### 三. 从重大故障中重启集群

重大故障指集群全部节点不可访问
```bash
dba.rebootClusterFromCompleteOutage("【cluster_name】",{【primary: "127.0.0.1:4001",force:true,dryRun: true】})
```

请确保所有集群成员都已启动。如果任何集群成员不可达，则命令将失败。

force:true 强制启动，但是不可访问你的节点会处于不可访问状态，此时集群可能也是不可用的。
dryRun : 您可以通过使用 `dryRun` 选项来测试更改。

### 四. 重新扫描集群
```bash
Cluster.rescan()
```


不可访问的节点会被踢出集群。

### 五. 集群隔离
```text
<Cluster>.fenceWrites() : 停止对 ClusterSet 主集群的写流量。
<Cluster>.unfenceWrites() : 恢复写入流量。
<Cluster>.fenceAllTraffic() ：从所有流量中隔离一个集群。
```
