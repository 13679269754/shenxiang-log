| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-4月-22 | 2025-4月-22  |
| ... | ... | ... |
---
# ansible安装redis

[toc]

## 开源项目地址

[ansible-redis](https://github.com/DavidWittman/ansible-redis)

## ansible 安装

[ansible安装redis](ansible安装redis.md)

## 节点清单与playbook 编写

节点清单  
`vim inventory.ini`
```bash
[redis]
172.29.29.101
172.29.29.102
172.29.29.103

[redis-sentinel]
172.29.29.101 redis_sentinel=True
172.29.29.102 redis_sentinel=True
172.29.29.103 redis_sentinel=True

```

使用了别人的role  
`vim redis_pb.yaml`
```bash
---
- name: configure the master redis server
  hosts: 172.29.29.101
  vars:
    - redis_bind: 172.29.29.101
      redis_version: 6.2.11
      redis_tarball: /root/soft/redis-6.2.11.tar.gz
  roles:
    - davidwittman.redis

- name: configure redis slaves1
  hosts: 172.29.29.102
  vars:
    - redis_bind: 172.29.29.102
    - redis_slaveof: 172.29.29.101 6379
      redis_version: 6.2.11
      redis_tarball: /root/soft/redis-6.2.11.tar.gz
  roles:
    - davidwittman.redis

- name: configure redis slaves2
  hosts: 172.29.29.103
  vars:
    - redis_bind: 172.29.29.103
    - redis_slaveof: 172.29.29.101 6379
      redis_version: 6.2.11
      redis_tarball: /root/soft/redis-6.2.11.tar.gz
  roles:
    - davidwittman.redis
```

```bash
ansible-playbook -i inventory.ini playbook.yml
```

## ansible 问题处理


### Could not match supplied host

**报错**
```bash
[WARNING]: Could not match supplied host pattern, ignoring: 172.29.29.101
```

**处理**
排查 inventory.ini 确定inventory.ini 中写入的的是主机名,还ip
inventory.ini 中定义了映射,playbook中的host就应该用主机名例如

```bash
[redis]
redis-server1 ansible_host=172.29.29.101
```

### host's fingerprint

**报错**
```bash
fatal: [172.29.29.101]: FAILED! => {"msg": "Using a SSH password instead of a key is not possible because Host Key checking is enabled and sshpass does not support this.  Please add this host's fingerprint to your known_hosts file to manage this host."}
```

**处理**