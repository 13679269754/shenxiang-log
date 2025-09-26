| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2025-2月-12 | 2025-2月-12 |
| ...      | ...        | ...        |


# mysql 存储过程一些规范

[toc]



## 重建存储过程

### 步骤一：删除存储过程


使用 `DROP PROCEDURE` 语句删除现有的存储过程。语法如下：

```sql
DROP PROCEDURE IF EXISTS procedure_name; 
```

  

*   `IF EXISTS` 是一个可选的关键字，用于避免在存储过程不存在时抛出错误。
*   `procedure_name` 是你要删除的存储过程的名称。

  

### 步骤二：重新创建存储过程

  

使用 `CREATE PROCEDURE` 语句重新创建存储过程。以下是一个简单的示例：

  
```sql
-- 修改语句结束符，避免存储过程中的分号干扰
DELIMITER //

CREATE PROCEDURE procedure_name()
BEGIN
    -- 存储过程的主体逻辑
    SELECT 'This is a sample procedure';
END //

-- 将语句结束符改回默认的分号
DELIMITER ; 
```

  

在上述示例中：

  

*   `DELIMITER` 用于临时改变语句结束符，因为存储过程内部可能包含多个以分号结尾的 SQL 语句。
*   `procedure_name` 是存储过程的名称，你可以根据实际需求修改。
*   `BEGIN` 和 `END` 之间是存储过程的主体逻辑，你可以编写更复杂的 SQL 语句。

  

## 修改存储过程
---

### 修改存储过程的部分属性

使用 `ALTER PROCEDURE` 语句可以修改存储过程的一些属性，如权限相关的属性等，但不能修改存储过程的主体逻辑。语法如下：



```sql
ALTER PROCEDURE procedure_name
    [characteristic ...]

characteristic:
    { CONTAINS SQL | NO SQL | READS SQL DATA | MODIFIES SQL DATA }
  | SQL SECURITY { DEFINER | INVOKER }
  | COMMENT 'string' 
```

  

*   `procedure_name` 是要修改的存储过程的名称。
*   `characteristic` 是要修改的属性，例如：
    
    *   `CONTAINS SQL`：表示存储过程包含 SQL 语句，但不包含读写数据的语句。
    *   `NO SQL`：表示存储过程不包含 SQL 语句。
    *   `READS SQL DATA`：表示存储过程包含读取数据的语句。
    *   `MODIFIES SQL DATA`：表示存储过程包含修改数据的语句。
    *   `SQL SECURITY { DEFINER | INVOKER }`：用于指定存储过程的安全上下文。
    *   `COMMENT 'string'`：用于为存储过程添加注释。

```sql
ALTER PROCEDURE procedure_name
    SQL SECURITY INVOKER
    COMMENT 'This is a modified procedure'; 
```

### 修改存储过程的主体逻辑

如果需要修改存储过程的主体逻辑，只能先删除该存储过程，然后重新创建，具体操作参考前面 “重建存储过程” 的步骤。

## 总结

*   若要修改存储过程的属性（如安全上下文、注释等），可以使用 `ALTER PROCEDURE` 语句。
*   若要修改存储过程的主体逻辑，需要先使用 `DROP PROCEDURE` 删除原存储过程，再使用 `CREATE PROCEDURE` 重新创建。

  

## SQL SECURITY DEFINER


### 含义

  

当使用 `SQL SECURITY DEFINER` 时，存储过程在执行时会以定义该存储过程的用户（即定义者）的权限来执行，而不是调用该存储过程的用户的权限。也就是说，无论谁调用这个存储过程，它都会使用定义者的权限去访问数据库中的资源。

  

### 示例

  

以下是一个创建使用 `SQL SECURITY DEFINER` 的存储过程的示例：


```sql

DELIMITER //

CREATE PROCEDURE definer_procedure()
SQL SECURITY DEFINER
BEGIN
    -- 这里可以是需要特定权限才能执行的 SQL 语句
    SELECT * FROM sensitive_table;
END //

DELIMITER ; 
```

  

假设 `sensitive_table` 是一个只有特定用户（如定义者）才能访问的表。当其他用户调用 `definer_procedure` 时，存储过程会以定义者的权限执行，从而可以访问 `sensitive_table`。

  

### 使用场景

  

*   **权限管理**：当需要让普通用户能够执行一些需要特殊权限的操作，但又不想直接给这些用户授予这些特殊权限时，可以使用 `DEFINER` 安全上下文。通过将存储过程的定义者设置为具有相应权限的用户，普通用户可以通过调用存储过程来间接执行这些操作。
*   **数据隔离**：确保某些敏感数据只能通过特定的存储过程来访问，而这些存储过程以具有访问权限的定义者的身份执行。

  

## SQL SECURITY INVOKER

  

### 含义

  

当使用 `SQL SECURITY INVOKER` 时，存储过程在执行时会以调用该存储过程的用户（即调用者）的权限来执行。这意味着调用者必须拥有执行存储过程中 SQL 语句所需的相应权限，否则会因权限不足而执行失败。

  

### 示例

  

以下是一个创建使用 `SQL SECURITY INVOKER` 的存储过程的示例：


```sql
DELIMITER //

CREATE PROCEDURE invoker_procedure()
SQL SECURITY INVOKER
BEGIN
    SELECT * FROM public_table;
END //

DELIMITER ; 
```

当用户调用 `invoker_procedure` 时，存储过程会以调用者的权限执行。如果调用者没有访问 `public_table` 的权限，那么该存储过程将无法正常执行。

  

### 使用场景


*   **权限控制严格**：当需要严格控制用户对数据库资源的访问权限时，使用 `INVOKER` 安全上下文可以确保每个用户只能执行其自身权限范围内的操作，即使是通过存储过程调用也不例外。
*   **多用户环境**：在多用户环境中，为了保证数据的安全性和完整性，避免用户通过存储过程绕过自身的权限限制，可以使用 `INVOKER` 安全上下文。


## 总结


*   `SQL SECURITY DEFINER` 以定义者的权限执行存储过程，适合在需要普通用户执行特殊权限操作的场景。
*   `SQL SECURITY INVOKER` 以调用者的权限执行存储过程，适合在需要严格控制用户权限的场景。
