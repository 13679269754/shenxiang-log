| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2023-9月-24 | 2023-9月-24 |
| ... | ... | ... |
---
# yarn常用命令.md

## 任务命令
查看任务
yarn  application -list
yarn 任务状态查看
yarn application -list -appStates 

状态
> ALL、NEW、NEW_SAVING、SUBMITTED、ACCEPTED、RUNNING、FINISHED、FAILED、KILLED

yarn 任务杀死
yarn application -kill

---
### 尝试运行的命令查看
yarn applicationattempt -list [applicationId]

yarn applicationattempt -status [applicationattemptid]

---

## 日志命令
yarn log -applicationId [applicationid] -containerId [containerId]

---
## 容器命令
yarn container -list

yarn container -status [containerId]

## 节点状态信息

yarn node -list -all 

## yarn 状态更新(加载队列配置)

yarn rmadmin -refreshQueues

## 队列命令
yarn 
yarn queue -status [queue_name]