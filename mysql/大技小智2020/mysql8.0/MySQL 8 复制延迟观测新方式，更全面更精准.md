| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-8月-14 | 2024-8月-14  |
| ... | ... | ... |
---

# MySQL 8 复制延迟观测新方式，更全面更精准.md

[toc]

## 资料

[MySQL 8 复制延迟观测新方式，更全面更精准](https://cloud.tencent.com/developer/article/1598331)

## 原文

如何观测事务复制过程中在不同位置的延迟，A 是 Master 节点，C 是中继 Slave 节点，D 是 Slave 节点。

![](https://ask.qcloudimg.com/http-save/yehe-7053949/12fks7u4pe.jpeg)

**位置 1：事务从主节点 A 到从节点 D 回放完的延迟，最常用的查看事务完整的同步延迟**

```
SELECT LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP - LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP
FROM performance_schema.replication_applier_status_by_worker
```

事务从中继节点 C 到从节点 D 回放完的延迟，与上面类似，若没有中继节点效果和上面一样，也是事务完整的同步延迟

```
SELECT LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP - LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP
FROM performance_schema.replication_applier_status_by_worker
```

**位置 2：当前已调度完的事务到开始回放的延迟**

```
SELECT APPLYING_TRANSACTION_START_APPLY_TIMESTAMP - APPLYING_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP
FROM performance_schema.replication_applier_status_by_worker
```

**位置3：已调度完的事务等待回放的延迟，MTS 开启**

```
SELECT LAST_PROCESSED_TRANSACTION_END_BUFFER_TIMESTAMP - LAST_PROCESSED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP
FROM performance_schema.replication_applier_status_by_coordinator
```

**位置 4：当前已同步到中继日志的事务，等待开始调度的延迟，MTS 开启**

```
SELECT PROCESSING_TRANSACTION_START_BUFFER_TIMESTAMP - PROCESSING_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP
FROM performance_schema.replication_applier_status_by_coordinator
```

**位置 5：事务同步到从机中继日志的延迟**

```
SELECT LAST_QUEUED_TRANSACTION_END_QUEUE_TIMESTAMP - LAST_QUEUED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP
FROM performance_schema.replication_connection_status
```

**位置 6：当前同步事务的网络传输延迟**

```
SELECT QUEUEING_TRANSACTION_START_QUEUE_TIMESTAMP - QUEUEING_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP
FROM performance_schema.replication_connection_status
```

MySQL 8 从根源上解决了过往版本缺少事务提交时间且无法传递的问题，PS 视图暴露更多观测点简化了观测方式，帮助工程师更精准的诊断复制延迟问题。
