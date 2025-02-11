[DataHub Quickstart Guide | DataHub](https://datahubproject.io/docs/quickstart) 

 DataHub云

本指南提供了在本地部署开源 DataHub 的说明。 如果您对托管版本感兴趣，Acryl Data 提供了一个完全托管的 DataHub 高级版本。

先决条件
----

*   为您的平台安装 Docker 和 Docker Compose v2。
    
    | 平台 | 应用程序 |
    | --- | --- |
    | 窗口 | [码头工人的桌面](https://www.docker.com/products/docker-desktop/) |
    | Mac | [码头工人的桌面](https://www.docker.com/products/docker-desktop/) |
    | Linux | 适用于 Linux 的 Docker 和 Docker Compose |
*   从命令行或桌面应用程序启动 Docker 引擎。
    
*   请确保已安装并配置好 Python 3.8。（使用 `python3 --version` 进行检查）
    

Docker 资源分配

请务必为 Docker 引擎分配足够的硬件资源。

安装 DataHub 命令行界面（CLI）
---------------------

*   皮普
*   诗歌

```
python3 -m pip install --upgrade pip wheel setuptools  
python3 -m pip install --upgrade acryl-datahub  
datahub version  

```

未找到命令

如果您看到 `command not found`，请尝试运行类似 `python3 -m datahub version` 的命令行指令。

Start DataHub[​](#start-datahub "Direct link to Start DataHub")
---------------------------------------------------------------

在您的终端中运行以下命令行界面（CLI）命令。

```
datahub docker quickstart  
```

这将使用 docker-compose 部署一个 DataHub 实例。 如果您好奇的话，`docker-compose.yaml` 文件会被下载到您的主目录下的 `.datahub/quickstart` 目录中。

如果一切顺利，您应该会看到如下所示的消息：

```
Fetching docker-compose file https://raw.githubusercontent.com/datahub-project/datahub/master/docker/quickstart/docker-compose-without-neo4j-m1.quickstart.yml from GitHub  
Pulling docker images...  
Finished pulling docker images!  
  
[+] Running 11/11  
⠿ Container zookeeper                  Running                                                                                                                                                         0.0s  
⠿ Container elasticsearch              Running                                                                                                                                                         0.0s  
⠿ Container broker                     Running                                                                                                                                                         0.0s  
⠿ Container schema-registry            Running                                                                                                                                                         0.0s  
⠿ Container elasticsearch-setup        Started                                                                                                                                                         0.7s  
⠿ Container kafka-setup                Started                                                                                                                                                         0.7s  
⠿ Container mysql                      Running                                                                                                                                                         0.0s  
⠿ Container datahub-gms                Running                                                                                                                                                         0.0s  
⠿ Container mysql-setup                Started                                                                                                                                                         0.7s  
⠿ Container datahub-datahub-actions-1  Running                                                                                                                                                         0.0s  
⠿ Container datahub-frontend-react     Running                                                                                                                                                         0.0s  
.......  
✔ DataHub is now running  
Ingest some demo data using `datahub docker ingest-sample-data`,  
or head to http://localhost:9002 (username: datahub, password: datahub) to play around with the frontend.  
Need support? Get in touch on Slack: https://slack.datahubproject.io/  

```

Mac M1/M2

在配备 Apple Silicon（如 M1、M2 等）的 Mac 电脑上，您可能会看到类似 `no matching manifest for linux/arm64/v8 in the manifest list entries` 的错误。 这通常意味着数据中心命令行界面（datahub cli）无法检测到您正在 Apple Silicon 上运行它。 要解决此问题，请通过输入 `datahub docker quickstart --arch m1` 来覆盖默认的架构检测。

### 登录

完成此步骤后，您应该能够在浏览器中导航至 DataHub 用户界面 http://localhost:9002 。 您可以使用以下默认凭据登录。

```
username: datahub  
password: datahub  

```

若要更改默认凭证，请参阅快速入门中的“更改数据仓库的默认用户”。

### 摄取样本数据

要导入示例元数据，请在终端中运行以下命令行界面（CLI）命令

```
datahub docker ingest-sample-data  

```

令牌认证

如果您已启用元数据服务身份验证，则需要在命令中使用 `--token <token>` 参数提供个人访问令牌。

就是这样！现在您可以随意使用 DataHub 了！

* * *

常用操作
----

### Stop DataHub[​](#stop-datahub "Direct link to Stop DataHub")

要停止 DataHub 的快速启动，您可以发出以下命令。

```
datahub docker quickstart --stop  

```

### Reset DataHub[​](#reset-datahub "Direct link to Reset DataHub")

要清除 DataHub 的所有状态（例如在导入您自己的数据之前），您可以使用 CLI 的 `nuke` 命令。

```
datahub docker nuke
```

### Upgrade DataHub[​](#upgrade-datahub "Direct link to Upgrade DataHub")

如果您一直在本地测试 DataHub，且 DataHub 发布了新版本，您想要尝试新版本，那么只需再次运行快速启动命令即可。它会拉取更新的镜像并重启您的实例，而不会丢失任何数据。

```
datahub docker quickstart  

```

### 自定义安装

如果您希望进一步自定义 DataHub 的安装，请下载命令行工具使用的  [docker-compose.yaml](https://raw.githubusercontent.com/datahub-project/datahub/master/docker/quickstart/docker-compose-without-neo4j-m1.quickstart.yml)文件，根据需要进行修改，然后通过传递下载的 docker-compose 文件来部署 DataHub：

```
datahub docker quickstart --quickstart-compose-file <path to compose file>  

```

### 备份DataHub

不过，如果您想要备份当前的快速入门状态（例如，您即将向公司演示，想要创建快速入门数据的副本以便日后恢复），您可以向快速入门提供 `--backup` 标志。

*   备份（默认）
*   备份到自定义目录

```
datahub docker quickstart --backup  

```

这将备份您的 MySQL 映像，并默认将其写入您的 `~/.datahub/quickstart/` 目录，文件名为 `backup.sql` 。

谨慎

请注意，快速入门备份不包含任何时间序列数据（数据集统计信息、配置文件等），因此如果您删除所有索引并从此备份中恢复，将会丢失这些信息。

### 恢复DataHub

正如您可能想象的那样，这些备份是可以恢复的。接下来的部分将介绍您恢复备份的几种不同选项。

*   一般恢复
*   仅恢复索引
*   仅恢复主分区

要还原之前的备份，请运行以下命令：

```
datahub docker quickstart --restore  

```

此命令将获取位于 `~/.datahub/quickstart` 下的 `backup.sql` 文件，并使用它来恢复您的主数据库以及 elasticsearch 索引。

若要提供特定的备份文件，请使用 `--restore-file` 选项。

```
datahub docker quickstart --restore --restore-file /home/my_user/datahub_backups/quickstart_backup_2002_22_01.sql  

```

* * *

下一个步骤
-----

*   [快速入门调试指南](https://datahubproject.io/docs/troubleshooting/quickstart)
*   [通过用户界面导入元数据](https://datahubproject.io/docs/ui-ingestion)
*   [通过命令行界面（CLI）导入元数据](https://datahubproject.io/docs/metadata-ingestion)
*   [将用户添加到数据中心](https://datahubproject.io/docs/authentication/guides/add-users)
*   [配置 OIDC 身份验证](https://datahubproject.io/docs/authentication/guides/sso/configure-oidc-react)
*   [配置 JaaS 身份验证](https://datahubproject.io/docs/authentication/guides/jaas)
*   在 DataHub 的后端配置身份验证。
*   [更改快速入门中的默认用户数据集](https://datahubproject.io/docs/authentication/changing-default-credentials#quickstart)

### 转向生产

谨慎

快速入门指南并非针对生产环境。我们建议使用 Kubernetes 将 DataHub 部署到生产环境。 我们提供了有用的 Helm Charts，可帮助您快速启动并运行。 请查看《将 DataHub 部署到 Kubernetes》以获取分步指南。

运行 DataHub 的 `quickstart` 方法旨在用于本地开发，是快速体验 DataHub 功能的一种便捷方式。 它不适合用于生产环境。此建议基于以下几点。

#### 默认凭证

`quickstart` 使用 Docker Compose 配置，其中包含 DataHub 及其底层先决条件数据存储（如 MySQL）的默认凭据。此外，其他组件默认情况下也是未认证的。这是为了使开发更简便而做出的设计选择，但在生产环境中并非最佳实践。

#### 暴露的港口

DataHub 的服务及其后端数据存储使用 Docker 的默认行为，即绑定到所有接口地址。这在开发过程中很有用，但在生产环境中不建议使用。

#### 绩效与管理

`quickstart` is limited by the resources available on a single host, there is no ability to scale horizontally. Rollout of new versions often requires downtime and the configuration is largely pre-determined and not easily managed. Lastly, by default, `quickstart` follows the most recent builds forcing updates to the latest released and unreleased builds.