 
可以配置该定时任务(对应的不应该被提升为主的服务器上配置)
 ```bash
  source /etc/bashrc && source /root/.bash_profile && /usr/bin/perl -le 'sleep rand 10' && /usr/local/bin/orchestrator-client -c register-candidate -i 10.159.65.156:3106 --promotion-rule must_not >/dev/null 2>&1
 ```

配置orchestrator集群
```bash
tee /root/.bash_profile <<EOF
export ORCHESTRATOR_API="http://10.159.65.79:3000/api http://10.159.65.80:3000/api http://10.159.65.81:3000/api"

export ORCHESTRATOR_AUTH_USER=Orchestrator
export ORCHESTRATOR_AUTH_PASSWORD=Dzj_pwd_2022
EOF
```

生效结果 
![[Pasted image 20250918141846.png]]



