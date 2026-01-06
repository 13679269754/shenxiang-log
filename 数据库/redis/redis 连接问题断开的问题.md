| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-2月-12 | 2025-2月-12  |
| ... | ... | ... |
---
# redis 连接问题断开的问题

[toc]

## redis 配置超时时间
在 Redis 里，`timeout` 相关设置主要涉及客户端连接超时和键的过期时间，下面为你分别介绍查看它们的方法。

  

客户端连接超时时间指的是当客户端和 Redis 服务器建立连接后，如果在指定时间内没有任何操作，服务器就会主动关闭该连接。

  

Redis 的配置文件（通常是 `redis.conf`）里有 `timeout` 配置项，你可以通过以下命令查看配置文件中的默认设置：

  

```
grep "timeout" /path/to/redis.conf 
```

例如，若配置文件在 `/etc/redis/redis.conf`，则命令为：

  

```
grep "timeout" /etc/redis/redis.conf 
```

配置文件里的 `timeout` 后面跟着的数字代表超时时间（单位是秒），若设置为 `0` 则表示禁用连接超时。

  

你也能在 Redis 客户端使用 `CONFIG GET timeout` 命令来查看当前运行时的客户端连接超时设置：

  

```
127.0.0.1:6379> CONFIG GET timeout
1) "timeout"
2) "0" 
```

这里返回结果中的第二个值就是当前的客户端连接超时时间（单位为秒），`0` 意味着禁用连接超时。

  

在 Redis 里，你可以给键设置过期时间，到时间后键会自动被删除。可以使用以下命令查看键的过期时间：

  

`TTL` 命令用于返回键的剩余生存时间（单位是秒）。

  

```
127.0.0.1:6379> SET mykey "Hello"
OK
127.0.0.1:6379> EXPIRE mykey 60
(integer) 1
127.0.0.1:6379> TTL mykey
(integer) 58 
```

  

*   若返回值为 `-1`，表示该键没有设置过期时间。
*   若返回值为 `-2`，表示该键不存在。

  

`PTTL` 命令和 `TTL` 类似，但它返回的剩余生存时间单位是毫秒，能提供更精确的时间信息。

  

```
127.0.0.1:6379> SET mykey "Hello"
OK
127.0.0.1:6379> PEXPIRE mykey 5000
(integer) 1
127.0.0.1:6379> PTTL mykey
(integer) 4998 
```

通过上述方法，你可以查看 Redis 中客户端连接超时时间以及键的过期时间。

  

Redis 连接断开机制主要涉及客户端主动断开、服务器主动断开以及网络异常导致的断开，以下是详细介绍：

  
  
## redis 连接断开的机制

*   **原理**：客户端应用程序在完成与 Redis 服务器的交互后，根据自身的业务逻辑决定关闭与 Redis 的连接。这种情况通常是由开发者在代码中显式调用关闭连接的方法来实现的。
*   **示例（Python 使用 Redis-py 库）**：

  

```
import redis


r = redis.Redis(host='localhost', port=6379, db=0)

r.set('key', 'value')

r.connection_pool.disconnect() 
```

  
  
  

*   **原理**：Redis 服务器可以配置一个超时时间（`timeout` 参数），当客户端与服务器建立连接后，如果在指定的时间内没有任何操作（即处于空闲状态），服务器会主动关闭该连接。默认情况下，`timeout` 配置为 0，表示禁用空闲超时断开机制。
*   **配置与查看**：
    
    *   可以在 `redis.conf` 配置文件中设置 `timeout` 参数，例如 `timeout 300` 表示空闲 300 秒后断开连接。
    *   也可以在运行时使用 `CONFIG SET timeout 300` 命令动态修改该参数，使用 `CONFIG GET timeout` 命令查看当前配置。
    
      
    

  
  

*   **原理**：当 Redis 服务器的内存使用达到一定阈值（由 `maxmemory` 和 `maxmemory-policy` 配置）时，为了释放内存，服务器可能会采取一些策略，其中包括断开部分客户端连接。
*   **示例配置**：
    
    *   在 `redis.conf` 中设置 `maxmemory 100mb` 表示 Redis 最多使用 100MB 内存。
    *   `maxmemory-policy` 可以设置不同的内存淘汰策略，如 `volatile-lru`（删除最近最少使用的过期键）等。当内存达到上限且无法通过淘汰键释放足够内存时，可能会断开连接。
    
      
    

  
  
  

*   **原理**：网络中的各种故障，如网络中断、路由器故障、电缆损坏等，都可能导致客户端与 Redis 服务器之间的连接中断。这种情况下，连接的两端（客户端和服务器）都会检测到连接异常，并将连接标记为断开状态。

  
  

*   **原理**：防火墙或代理设备可能会根据自身的规则关闭 Redis 连接。例如，防火墙可能会限制某个 IP 地址的访问，或者代理设备可能会因为超时、资源耗尽等原因中断连接。

  

为了避免因网络抖动或空闲超时导致的连接断开影响业务，客户端通常会实现心跳机制和重连策略：

  

*   **心跳机制**：客户端定期向 Redis 服务器发送一些简单的命令（如 `PING` 命令），以保持连接的活跃状态，防止因空闲超时被服务器断开。
*   **重连策略**：当客户端检测到连接断开时，会尝试重新建立连接。重连策略可以包括重试次数、重试间隔等配置，以确保在网络恢复后能够尽快恢复与 Redis 的通信。

例如，在 Python 的 Redis-py 库中，连接池会自动处理部分重连逻辑，开发者也可以自定义重连策略：

  

```
import redis
import time

r = redis.Redis(host='localhost', port=6379, db=0)

while True:
    try:
        r.ping()
        print("Connection is alive.")
    except redis.exceptions.ConnectionError:
        print("Connection lost. Trying to reconnect...")
        while True:
            try:
                r = redis.Redis(host='localhost', port=6379, db=0)
                r.ping()
                print("Reconnected successfully.")
                break
            except redis.exceptions.ConnectionError:
                time.sleep(1)  
    time.sleep(5) 
```

  

## 如果redis没有配置timeout,后端程序重启以后redis的连接会如何断开，

如果 Redis 没有配置 `timeout`（即 `timeout` 为 0，禁用空闲超时断开机制），后端程序重启时 Redis 连接的断开情况受多种因素影响，下面从不同角度详细分析：

  
  

*   **主动关闭连接**：当后端程序正常重启时，通常会有相应的关闭逻辑来释放资源，其中就包括主动关闭与 Redis 的连接。以 Python 的 `redis-py` 库为例，程序退出时会自动关闭连接，释放底层的套接字资源：

  

```
import redis


r = redis.Redis(host='localhost', port=6379, db=0)

r.set('key', 'value') 
```

  

*   **服务器感知连接关闭**：当后端程序主动关闭连接时，Redis 服务器会收到连接关闭的信号，从而将该连接标记为已断开，并释放相关资源。

  
  

*   **连接未正常关闭**：如果后端程序因为崩溃、断电等异常情况重启，与 Redis 的连接可能来不及正常关闭。此时，Redis 服务器不会立即知道连接已经中断，因为没有收到客户端主动发送的关闭信号。
*   **连接处于半开状态**：连接可能会处于半开状态，Redis 服务器仍然认为连接是有效的，但实际上客户端已经无法正常通信。不过，这种状态不会持续太久，因为网络协议本身有一些机制来检测连接是否正常。
*   **TCP 协议的保活机制**：大多数操作系统支持 TCP 保活机制，即使 Redis 没有配置 `timeout`，TCP 层的保活机制可以检测到长时间没有数据传输的连接是否仍然有效。当 TCP 保活机制检测到连接异常时，会通知 Redis 服务器关闭该连接。在 Linux 系统中，可以通过修改 `/proc/sys/net/ipv4/tcp_keepalive_time`、`/proc/sys/net/ipv4/tcp_keepalive_probes` 和 `/proc/sys/net/ipv4/tcp_keepalive_intvl` 等参数来调整 TCP 保活机制的行为。

  
  

*   **自动重连机制**：很多 Redis 客户端库都提供了自动重连机制。当后端程序重启后，客户端会尝试重新建立与 Redis 服务器的连接。例如，在 Java 中使用 Jedis 客户端：

  

```
import redis.clients.jedis.Jedis;

public class RedisReconnectExample {
    public static void main(String[] args) {
        Jedis jedis = new Jedis("localhost", 6379);
        try {
            
            throw new RuntimeException("Simulate crash");
        } catch (Exception e) {
            
            jedis = new Jedis("localhost", 6379);
            System.out.println("Reconnected to Redis");
        } finally {
            jedis.close();
        }
    }
} 
```

  

*   **重连策略**：客户端的重连策略可能包括重试次数、重试间隔等。如果在一定次数的重试后仍然无法连接到 Redis 服务器，客户端可能会抛出连接异常，需要开发者进行相应的处理。