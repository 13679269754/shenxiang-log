以下是对 MySQL 分区管理存储过程的详细注释，解释了其核心逻辑和工作原理：

```sql
-- 创建分区管理配置表
CREATE TABLE `partition_manager_settings` (
  `table` varchar(64) NOT NULL COMMENT '需要管理的表名',
  `column` varchar(64) NOT NULL COMMENT '用于分区的时间列（必须为数值类型）',
  `granularity` int(10) unsigned NOT NULL COMMENT '时间列的粒度（1=秒，60=分钟，3600=小时等）',
  `increment` int(10) unsigned NOT NULL COMMENT '每个分区覆盖的时间范围（秒）',
  `retain` int(10) unsigned NULL COMMENT '保留数据的时长（秒），NULL表示永久保留',
  `buffer` int(10) unsigned NULL COMMENT '预创建未来分区的时长（秒）',
  PRIMARY KEY (`table`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=Dynamic;

-- 主存储过程：管理所有表的分区
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `partition_manager`()
BEGIN
  DECLARE done TINYINT UNSIGNED;
  DECLARE p_table, p_column VARCHAR(64) CHARACTER SET latin1;
  DECLARE p_granularity, p_increment, p_retain, p_buffer INT UNSIGNED;
  DECLARE run_timestamp, current_val INT UNSIGNED;
  DECLARE partition_list TEXT CHARACTER SET latin1;

  -- 定义游标遍历所有配置表
  DECLARE cur_table_list CURSOR FOR 
    SELECT s.table, s.column, s.granularity, s.increment, s.retain, s.buffer 
    FROM partition_manager_settings s;
  
  -- 异常处理
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  -- 设置最大分组长度，避免SQL拼接截断
  SET SESSION group_concat_max_len = 65535;
  SET run_timestamp = UNIX_TIMESTAMP();

  -- 主循环：处理每个配置的表
  OPEN cur_table_list;
  manage_partitions_loop: LOOP
    SET done = 0;
    FETCH cur_table_list INTO p_table, p_column, p_granularity, p_increment, p_retain, p_buffer;
    
    IF done = 1 THEN
      LEAVE manage_partitions_loop;
    END IF;

    -- 验证表是否已分区，若未分区则创建初始分区
    SELECT IF(t.create_options LIKE '%partitioned%', NULL, CEIL(UNIX_TIMESTAMP()/IFNULL(p_increment,1))*IFNULL(p_increment,1))
    FROM information_schema.tables t
    WHERE t.table_schema = DATABASE()
      AND t.table_name = p_table
    INTO current_val;

    -- 如果表未分区，则创建初始分区结构
    IF current_val IS NOT NULL THEN
      SET partition_list = '';
      
      -- 根据保留策略生成历史分区
      IF p_retain IS NOT NULL THEN
        WHILE current_val > run_timestamp - p_retain DO
          SET current_val = current_val - p_increment;
          SET partition_list = CONCAT(
            'PARTITION p_', FLOOR(current_val/p_granularity), 
            ' VALUES LESS THAN (', FLOOR(current_val/p_granularity), '),', 
            partition_list
          );
        END WHILE;
      END IF;
      
      -- 执行分区创建SQL
      SET @sql = CONCAT(
        'ALTER TABLE ', p_table, 
        ' PARTITION BY RANGE (', p_column, ') (',
        'PARTITION p_START VALUES LESS THAN (0),',
        partition_list,
        'PARTITION p_END VALUES LESS THAN MAXVALUE)'
      );
      PREPARE stmt FROM @sql;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
    END IF;

    -- 添加未来分区（预创建空分区）
    IF p_buffer IS NOT NULL THEN
      -- 获取当前最大分区值
      SELECT IFNULL(MAX(p.partition_description)*p_granularity, FLOOR(UNIX_TIMESTAMP()/p_increment)*p_increment)
      FROM information_schema.partitions p
      WHERE p.table_schema = DATABASE()
        AND p.table_name = p_table
        AND p.partition_description > 0
      INTO current_val;
      
      SET partition_list = '';
      
      -- 生成未来分区列表
      WHILE current_val < run_timestamp + p_buffer DO
        SET current_val = current_val + p_increment;
        SET partition_list = CONCAT(
          partition_list, 
          'PARTITION p_', FLOOR(current_val/p_granularity), 
          ' VALUES LESS THAN (', FLOOR(current_val/p_granularity), '),'
        );
      END WHILE;
      
      -- 如果有新分区需要添加，则执行REORGANIZE
      IF partition_list > '' THEN
        SET @sql = CONCAT(
          'ALTER TABLE ', p_table, 
          ' REORGANIZE PARTITION p_END INTO (',
          partition_list,
          'PARTITION p_END VALUES LESS THAN MAXVALUE)'
        );
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END IF;
    END IF;

    -- 清理过期分区
    IF p_retain IS NOT NULL THEN
      SET partition_list = '';
      
      -- 获取所有需要删除的分区
      SELECT GROUP_CONCAT(p.partition_name SEPARATOR ',')
      FROM information_schema.partitions p
      WHERE p.table_schema = DATABASE()
        AND p.table_name = p_table
        AND p.partition_description <= FLOOR((run_timestamp - p_retain)/p_granularity)
        AND p.partition_description > 0
      INTO partition_list;
      
      -- 如果有过期分区，则执行删除
      IF partition_list > '' THEN
        SET @sql = CONCAT('ALTER TABLE ', p_table, ' DROP PARTITION ', partition_list);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END IF;
    END IF;
  END LOOP;
  CLOSE cur_table_list;

  -- 重新调度下一次执行（根据最小分区增量调整）
  CALL schedule_partition_manager();
END;;
DELIMITER ;

-- 事件：定时触发分区管理
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` EVENT `run_partition_manager` 
ON SCHEDULE EVERY 86400 SECOND 
STARTS '2000-01-01 00:00:00' 
ON COMPLETION PRESERVE ENABLE DO
BEGIN
  IF @@global.read_only = 0 THEN
    CALL partition_manager();
  END IF;
END;;
DELIMITER ;

-- 存储过程：动态调整事件调度频率
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `schedule_partition_manager`()
BEGIN
  DECLARE min_increment INT UNSIGNED;
  
  -- 获取所有表中最小的分区增量
  SELECT MIN(s.increment)
  FROM partition_manager_settings s
  INTO min_increment;
  
  -- 根据最小增量调整事件触发频率
  IF min_increment IS NOT NULL THEN
    ALTER DEFINER='root'@'localhost' EVENT run_partition_manager 
    ON SCHEDULE EVERY min_increment SECOND 
    STARTS '2000-01-01 00:00:00' 
    ENABLE;
  END IF;
END;;
DELIMITER ;

-- 安装/升级存储过程
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `install_partition_manager`()
BEGIN
  -- 创建临时表（用于升级场景）
  CREATE TABLE `partition_manager_settings_new` (
    `table` varchar(64) NOT NULL COMMENT 'table name',
    `column` varchar(64) NOT NULL COMMENT 'numeric column with time info',
    `granularity` int(10) unsigned NOT NULL COMMENT 'granularity of column',
    `increment` int(10) unsigned NOT NULL COMMENT 'seconds per partition',
    `retain` int(10) unsigned NULL COMMENT 'seconds of data to retain',
    `buffer` int(10) unsigned NULL COMMENT 'seconds of future partitions',
    PRIMARY KEY (`table`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=Dynamic;
  
  -- 迁移现有配置（如果存在）
  SET @sql = NULL;
  SELECT CONCAT(
    'INSERT INTO partition_manager_settings_new (',
    GROUP_CONCAT(CONCAT('`', cn.column_name, '`')),
    ') SELECT ',
    GROUP_CONCAT(CONCAT('so.', cn.column_name)),
    ' FROM partition_manager_settings so'
  )
  FROM information_schema.columns cn
  JOIN information_schema.columns co 
    ON co.table_schema = cn.table_schema AND co.column_name = cn.column_name
  WHERE cn.table_name = 'partition_manager_settings_new'
    AND co.table_name = 'partition_manager_settings'
  INTO @sql;
  
  IF @sql IS NOT NULL THEN
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
  
  -- 替换旧表
  DROP TABLE IF EXISTS partition_manager_settings;
  RENAME TABLE partition_manager_settings_new TO partition_manager_settings;
  
  -- 重新调度事件
  CALL schedule_partition_manager();
END;;
DELIMITER ;

-- 执行安装并清理临时对象
CALL install_partition_manager;
DROP PROCEDURE IF EXISTS install_partition_manager;
```


### **核心功能解析**
1. **分区策略配置**  
   - 通过 `partition_manager_settings` 表定义分区规则
   - 支持按时间（秒/分/时/天）自动创建和删除分区

2. **动态分区管理**  
   - **初始化**：对未分区表自动创建初始分区结构
   - **预创建**：根据 `buffer` 参数提前创建未来分区（避免锁表）
   - **自动清理**：根据 `retain` 参数自动删除过期分区

3. **智能调度**  
   - 自动根据最小分区增量调整事件触发频率
   - 支持读写分离环境（只读实例不执行分区操作）

4. **平滑升级**  
   - 通过 `install_partition_manager` 存储过程支持配置无损升级


### **使用示例**
1. **配置按天分区，保留30天数据，预创建7天分区**  
   ```sql
   INSERT INTO partition_manager_settings 
   VALUES ('logs', 'log_time', 86400, 86400, 2592000, 604800);
   ```

2. **配置按小时分区，保留7天数据，预创建24小时分区**  
   ```sql
   INSERT INTO partition_manager_settings 
   VALUES ('metrics', 'create_time', 3600, 3600, 604800, 86400);
   ```


### **注意事项**
1. **时间列类型**：必须为数值类型（如 `UNIX_TIMESTAMP()` 返回值）
2. **权限要求**：需 `SUPER` 权限创建事件和存储过程
3. **性能影响**：分区操作会产生锁，建议在低峰期执行
4. **兼容性**：仅支持 MySQL 5.6.29+ / 5.7.11+（修复了事件调度器的 Bug）

这个分区管理系统通过自动化减少了人工维护成本，同时确保了分区策略的一致性和正确性。