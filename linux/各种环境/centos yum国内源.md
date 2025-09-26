
| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2025-7月-03 | 2025-7月-03 |

---
# centos yum国内源

[toc]

```bash
[base]
name=CentOS-$releasever - base - mirrors.tuna.tsinghua.edu.cn
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/centos/$releasever/os/$basearch/
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/RPM-GPG-KEY-CentOS-7

[updates]
name=CentOS-$releasever - updates - mirrors.tuna.tsinghua.edu.cn
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/centos/$releasever/updates/$basearch/
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/RPM-GPG-KEY-CentOS-7

[extras]
name=CentOS-$releasever - extras - mirrors.tuna.tsinghua.edu.cn
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/centos/$releasever/extras/$basearch/
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/RPM-GPG-KEY-CentOS-7

[centosplus]
name=CentOS-$releasever - centosplus - mirrors.tuna.tsinghua.edu.cn
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/centos/$releasever/centosplus/$basearch/
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/RPM-GPG-KEY-CentOS-7

[fasttrack]
name=CentOS-$releasever - fasttrack - mirrors.tuna.tsinghua.edu.cn
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/centos/$releasever/fasttrack/$basearch/
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/RPM-GPG-KEY-CentOS-7

[atomic]
name=CentOS-$releasever - atomic - mirrors.tuna.tsinghua.edu.cn
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/centos/$releasever/atomic/$basearch/
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/RPM-GPG-KEY-CentOS-7

[dotnet]
name=CentOS-$releasever - dotnet - mirrors.tuna.tsinghua.edu.cn
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/centos/$releasever/dotnet/$basearch/
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/RPM-GPG-KEY-CentOS-7

[rt]
name=CentOS-$releasever - rt - mirrors.tuna.tsinghua.edu.cn
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/centos/$releasever/rt/$basearch/
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/RPM-GPG-KEY-CentOS-7

[sclo-rh]
name=CentOS-$releasever - sclo-rh - mirrors.tuna.tsinghua.edu.cn
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/centos/$releasever/sclo/$basearch/rh/
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/RPM-GPG-KEY-CentOS-7

[sclo-sclo]
name=CentOS-$releasever - sclo-sclo - mirrors.tuna.tsinghua.edu.cn
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/centos/$releasever/sclo/$basearch/sclo/
enabled=0
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/RPM-GPG-KEY-CentOS-7
```