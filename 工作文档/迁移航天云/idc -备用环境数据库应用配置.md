| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-6月-24 | 2025-6月-24  |
| ... | ... | ... |
---
# idc -备用环境数据库应用配置


| 类型 | ip | port | 用途 | 用户名-应用运维用 | 密码-应用运维用 |
| -- | -- | -- | -- | -- | -- |
| redis | 172.30.70.71 | 6100 | 后端redis |  | bTcAsV3mTJzZGanZJaJt |
| redis | 172.30.70.72 | 6100 | 后端redis |  | bTcAsV3mTJzZGanZJaJt |
| redis | 172.30.70.71 | 26100 | 后端redis-sentinel |  | bTcAsV3mTJzZGanZJaJt |  
| redis | 172.30.70.72 | 26100 | 后端redis-sentinel |
| redis | 172.30.70.34 | 26100 | 后端redis-sentinel |
| redis | 172.30.70.71 | 6000 | 算法redis |  | 1hpAACExDKv5yZhN |
| redis | 172.30.70.72 | 6000 | 算法redis |
| mysql | 172.30.70.42 | 3106 | 后端mysql |  
| mysql | 172.30.70.43 | 3106 | 后端mysql |
| mysql | 172.30.70.44 | 3106 | 后端mysql |
| mysql | 172.30.70.45 | 3106 | 备份mysql |
| mysql | 172.30.72.21 | 3106 | 大数据取数mysql |
| mysql | 172.30.2.198 | 3106 | 大专家算法数据转换数据库 |
| mysql | 172.30.72.22 | 3106 | 大专家算法数据转换数据库 |
| proxysql | 172.30.70.31 | 6033 | proxysql-server1 | app_dzj_rwuser | 航天云同 |
| proxysql | 172.30.70.32 | 6033 | proxysql-server2 |
| proxysql | 172.30.70.33 | 6033 | proxysql-server3 |
| elasticsearch | 172.30.70.61 | 9200 | elasticsearch1 | dzj_user | pXyCKVyyX6V3VoA8nH |
| elasticsearch | 172.30.70.62 | 9200 | elasticsearch2 |
| elasticsearch | 172.30.70.63 | 9200 | elasticsearch3 |
| influxdb | 172.30.70.73 | 8086 | influxdb | dzj_user |  bx8NQKi_DP94m8PUG_JwUxXvxHkixvd4LQMcbKktQZ9irF7B1ADiG07o53h_sFm5bqXeFlnmztNVAYtYzLMlRg== |
| neo4j | 172.30.70.73 | 7474 |  neo4j | neo4j | ibBJhXYunogomjP0 |
| orentdb | 172.30.2.179 | 2424 | orentdb1 | writer | UpZnQ5PAewwRGfeju |
| orentdb | 172.30.2.180 | 2424 | orentdb2 |
| orentdb | 172.30.2.181 | 2424 | orentdb3 |