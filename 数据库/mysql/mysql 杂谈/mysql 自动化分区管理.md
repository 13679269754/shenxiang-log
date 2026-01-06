| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-7月-11 | 2025-7月-11  |
| ... | ... | ... |
---
# mysql 自动化分区管理

[toc]

### MySQL Partition Manager 的使用



在 MySQL 中，分区表是优化大数据量查询性能的重要手段，但手动管理分区（如按时间自动添加新分区）是一项繁琐且易出错的任务。以下是几个主流的开源工具和方案，可实现 MySQL 分区表的自动化管理：


### **一、pt-online-schema-change（Percona Toolkit）**
#### 1. **核心功能**
- 支持在线添加、删除分区，避免锁表。
- 通过触发器捕获数据变更，实现无缝分区切换。

#### 2. **示例：自动添加按月分区**
```bash
pt-online-schema-change \
  --alter "ADD PARTITION (PARTITION p202307 VALUES LESS THAN (TO_DAYS('2023-08-01')))" \
  --execute \
  D=db1,t=orders
```

#### 3. **特点**
- 成熟稳定，社区支持广泛。
- 对业务影响小，但需定期手动执行。


### **二、orchestrator（GitHub）**
#### 1. **核心功能**
- 自动化 MySQL 分区管理（需配合自定义脚本）。
- 支持分区表的自动创建、删除和合并。
0
#### 2. **配置示例**
```yaml
# orchestrator.conf.json
{
  "MySQLOrchestratorHost": "127.0.0.1",
  "MySQLOrchestratorPort": 3000,
  "AutoPartitioning": {
    "Enabled": true,
    "Tables": [
      {
        "Schema": "db1",
        "Table": "logs",
        "Type": "RANGE",
        "Expression": "TO_DAYS(log_date)",
        "IntervalDays": 30,
        "FuturePartitions": 2
      }
    ]
  }
}
```

#### 3. **特点**
- 与 MySQL 复制拓扑集成，可批量管理多节点分区表。
- 需一定开发能力，自定义脚本实现自动化逻辑。


### **三、MySQL Partition Manager（MPM）**
#### 1. **核心功能**
- 专为 MySQL 分区表设计的自动化管理工具。
- 支持按时间（天/周/月）自动创建和删除分区。

#### 2. **安装与使用**
```bash
# 安装
pip install mysql-partition-manager

# 配置（config.yaml）
databases:
  - host: localhost
    port: 3306
    user: root
    password: password
    databases:
      - db1
        tables:
          - name: orders
            partition_type: RANGE
            partition_expression: TO_DAYS(order_date)
            interval: 30  # 按30天分区
            retention: 90  # 保留90天数据

# 执行自动管理
mpm --config config.yaml --execute
```

#### 3. **特点**
- 轻量级，配置简单，适合中小规模环境。
- 支持分区清理策略（如保留最近90天数据）。


### **四、MyCat（开源数据库中间件）**
#### 1. **核心功能**
- 支持分布式分区表管理。
- 通过规则自动创建和路由分区。

#### 2. **配置示例**
```xml
<!-- schema.xml -->
<schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100">
  <table name="orders" dataNode="dn1,dn2,dn3" rule="auto-sharding-long">
    <tableRule name="auto-sharding-long">
      <rule>
        <columns>id</columns>
        <algorithm>rang-long</algorithm>
      </rule>
    </tableRule>
  </table>
</schema>

<!-- rule.xml -->
<function name="rang-long" class="io.mycat.route.function.AutoPartitionByLong">
  <property name="mapFile">autopartition-long.txt</property>
  <property name="defaultNode">0</property>
</function>
```

#### 3. **特点**
- 适合大规模分布式环境，支持跨节点分区。
- 学习成本较高，需理解中间件架构。


### **五、自定义脚本方案**
#### 1. **Python 脚本示例**
```python
import pymysql
from datetime import datetime, timedelta

def add_monthly_partition():
    conn = pymysql.connect(host='localhost', user='root', password='pass', db='test')
    with conn.cursor() as cursor:
        # 计算下个月的分区
        next_month = datetime.now() + timedelta(days=30)
        partition_name = f"p{next_month.strftime('%Y%m')}"
        partition_value = next_month.strftime('%Y-%m-01')
        
        # 检查分区是否存在
        cursor.execute(f"""
            SELECT COUNT(*) 
            FROM information_schema.partitions 
            WHERE table_name = 'orders' 
              AND partition_name = '{partition_name}'
        """)
        if cursor.fetchone()[0] == 0:
            # 添加新分区
            cursor.execute(f"""
                ALTER TABLE orders 
                ADD PARTITION (PARTITION {partition_name} VALUES LESS THAN (TO_DAYS('{partition_value}')))
            """)
            conn.commit()
            print(f"Added partition: {partition_name}")

# 定时任务（使用 cron 或 APScheduler）
add_monthly_partition()
```

#### 2. **特点**
- 高度定制化，可根据业务需求灵活调整。
- 需要自行维护和监控脚本运行。


### **六、工具选择矩阵**
| 工具               | 适合场景                | 复杂度 | 自动化程度 | 社区支持 |
|--------------------|-------------------------|--------|------------|----------|
| pt-online-schema-change | 中小规模，手动触发      | 低     | 中         | 高       |
| orchestrator       | 大规模集群，集成复制管理 | 高     | 高         | 中       |
| MySQL Partition Manager | 轻量级自动化需求      | 低     | 高         | 低       |
| MyCat              | 分布式环境              | 高     | 高         | 中       |
| 自定义脚本         | 特殊业务需求            | 中     | 自定义     | 无       |


### **七、最佳实践建议**
1. **监控与告警**：  
   - 定期检查分区数量和大小（如 `SHOW TABLE STATUS LIKE 'orders'`）。  
   - 设置告警（如分区数量超过阈值、分区创建失败）。

2. **测试与回滚**：  
   - 在开发环境验证分区策略，避免生产事故。  
   - 准备回滚方案（如 `ALTER TABLE DROP PARTITION`）。

3. **性能优化**：  
   - 避免单个分区数据过大（建议单分区不超过 1GB）。  
   - 对分区表使用 `EXPLAIN` 验证查询是否正确使用分区。

通过自动化工具管理分区表，可显著降低运维成本，同时确保查询性能稳定。建议根据业务规模和复杂度选择合适的工具，必要时结合自定义脚本实现精细化管理。