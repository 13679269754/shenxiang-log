| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2025-6月-13 | 2025-6月-13 |

---
# JDK17 安装

[toc]

## 手动安装

```bash
wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8%2B7/OpenJDK17U-jdk_x64_linux_hotspot_17.0.8_7.tar.gz

sudo mkdir -p /usr/local/data/java
sudo tar -zxvf OpenJDK17U-jdk_x64_linux_hotspot_17.0.8_7.tar.gz -C  /usr/local/data/java
```

```bash
echo 'export JAVA_HOME=/usr/local/data/java/jdk-17.0.8+7' | sudo tee -a /etc/profile
echo 'export PATH=$JAVA_HOME/bin:$PATH' | sudo tee -a /etc/profile
source /etc/profile
```

