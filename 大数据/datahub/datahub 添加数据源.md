[元数据摄取简介 |数据中心](https://datahubproject.io/docs/metadata-ingestion/) 


| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2025-1月-13 | 2025-1月-13  |

---

# datahub添加数据源

[toc]

## 元数据摄取简介
=======

查找集成源

请参阅我们的**[集成页面](/integrations)**，浏览我们的摄取源并筛选其功能。

### 集成方法
-----------------------------------------------------------------

DataHub 提供三种数据摄取方法：

*   [UI 摄取](/docs/ui-ingestion) ： 通过 UI 轻松配置和执行元数据摄取管道。
*   [CLI 摄取指南](/docs/metadata-ingestion/cli-ingestion) ： 使用 YAML 配置摄取管道，并通过 CLI 执行。
*   基于 SDK 的摄取 ：使用 [Python 发射器](/docs/metadata-ingestion/as-a-library)或 [Java 发射器](/docs/metadata-integration/java/as-a-library)以编程方式控制摄取管道。

> 这里只看前两种方法，第三种明显比较麻烦；)


集成类型
-------------------------------------------------------------------

根据该方法，集成可以分为两个概念：

### 基于推送的集成

基于推送的集成允许您在元数据更改时直接从数据系统发出元数据。 基于推送的集成示例包括 [Airflow](/docs/lineage/airflow)、[Spark](/docs/metadata-integration/java/acryl-spark-lineage)、[Great Expectations](/docs/metadata-ingestion/integration_docs/great-expectations) 和 [Protobuf Schemas](/docs/metadata-integration/java/datahub-protobuf)。这允许您从数据生态系统中的“活动”代理获得低延迟元数据集成。

### 基于拉取的集成

基于拉取的集成允许您通过连接到数据系统并以批量或增量批处理方式提取元数据，从数据系统中“抓取”或“摄取”元数据。 基于拉取的集成示例包括 BigQuery、Snowflake、Looker、Tableau 等。

核心概念[](#core-concepts "Direct link to Core Concepts")
-----------------------------------------------------

以下是与引入相关的核心概念：

*   [source](/docs/metadata-ingestion/source_overview)：从中提取元数据的数据系统。（例如 BigQuery、MySQL）
*   [Sinks](/docs/metadata-ingestion/sink_overview)：元数据的目标（例如 File、DataHub）
*   [regcipe](/docs/metadata-ingestion/recipe_overview)：在表单或 .yaml 文件中摄取的主要配置

有关更高级的指南，请参阅以下内容：

*   [在 Metadata Ingestion 上进行开发](/docs/metadata-ingestion/developing)
*   [添加元数据摄取源](/docs/metadata-ingestion/adding-source)
*   [使用 Transformer](/docs/metadata-ingestion/docs/transformer/intro)

* * *


## CLI ingestion
 [CLI Ingestion | DataHub](https://datahubproject.io/docs/metadata-ingestion/cli-ingestion) 


批量摄取涉及从源系统中批量提取元数据。通常，这会在预定义的时间表上使用元数据摄取框架进行。 提取的元数据包括数据集、图表、仪表板、管道、用户、组、使用情况和任务元数据的特定时间点实例。

安装 DataHub 命令行工具（CLI）
---------------------

所需 Python 版本

安装 DataHub CLI 需要 Python 3.6 。

在您的终端中运行以下命令：

```
python3 -m pip install --upgrade pip wheel setuptools  
python3 -m pip install --upgrade acryl-datahub  
python3 -m datahub version  

```

成功执行这些命令后，您的命令行应返回 DataHub 的正确版本。

查看命令行界面安装指南以获取更多安装选项和故障排除提示。

安装连接器插件
-------

我们的命令行界面（CLI）采用插件架构。您必须单独为不同的数据源安装连接器。 有关所有受支持数据源的列表，请参阅开源文档。 找到您关心的连接器后，只需使用 `pip install` 安装它们即可。 例如，要安装 `mysql` 连接器，您可以运行

```
pip install --upgrade 'acryl-datahub[mysql]'  

```

查看其他安装选项以获取更多参考。

配置食谱
----

创建一个定义元数据源和接收器的 Recipe YAML 文件，如下所示。

```yml
# example-recipe.yml

# MySQL source configuration
source:
  type: mysql
  config:
    username: root
    password: password
    host_port: localhost:3306

# Recipe sink configuration.
sink:
  type: "datahub-rest"
  config:
    server: "https://<your domain name>.acryl.io/gms"
    token: <Your API key>
```

源配置块定义了从何处提取元数据。这可以是联机事务处理（OLTP）数据库系统、数据仓库，甚至可以简单到一个文件。每个源都有自定义配置，具体取决于从该源访问元数据所需的内容。要查看每个受支持源所需的配置，请参阅“源”文档。

“输出配置块定义了将元数据推送到何处。每种输出类型都需要特定的配置，其详细信息在“输出”文档中有详细说明。”

要将您的 DataHub 实例配置为摄取的目的地，请将您的配方中的“server”字段设置为指向您的 DataHub 云实例的域名，并在其后加上路径 `/gms`，如下所示。 从 MySQL 读取并写入 DataHub 实例的完整 DataHub 配方文件示例：

有关配置配方的更多信息和示例，请参阅“配方”。

### 使用带有身份验证的配方

在 DataHub 云部署中，仅支持 `datahub-rest` 沉淀，这仅仅意味着元数据将被推送到您的 DataHub 实例所暴露的 REST 端点。此沉淀所需的配置为

1.  服务器：您的 DataHub 实例所公开的 REST API 的位置
2.  令牌：用于对您的实例的 REST API 发出的请求进行身份验证的唯一 API 密钥

您可以通过以管理员身份登录来获取令牌。您可以前往“设置”页面并生成一个具有您期望的过期日期的个人访问令牌。

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/saas/home-(1).png)

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/saas/settings.png)

保护API密钥

请妥善保管您的 API 密钥，切勿与他人分享。 如果您使用的是 DataHub 云服务，且您的密钥因任何原因遭到泄露，请通过 support@acryl.io 联系 Acryl 团队。

最后一步需要调用 DataHub CLI，根据您的配方配置文件导入元数据。 为此，只需运行 `datahub ingest` 并指向您的 YAML 配方文件即可：

```
datahub ingest -c <path/to/recipe.yml>  

```

安排摄取
----

摄取操作既可以由系统管理员以临时方式运行，也可以安排定期执行。最常见的情况是每天执行一次摄取操作。 要安排您的摄取任务，我们建议使用像 Apache Airflow 这样的作业调度程序。对于较简单的部署，也可以在一台始终运行的机器上安排一个 CRON 作业。 请注意，每个源系统都需要一个单独的配方文件。这使您可以独立或一起安排来自不同源的摄取操作。 有关安排摄取操作的更多信息，请参阅《安排摄取操作指南》。

参考
--

请参阅以下页面获取有关命令行界面（CLI）摄取的高级指南。

*   [`datahub ingest` 命令的参考说明](https://datahubproject.io/docs/cli#ingest)
*   [UI摄入指南](https://datahubproject.io/docs/ui-ingestion)

兼容性

>DataHub 服务器采用三位数的版本号方案，而命令行界面（CLI）则采用四位数的方案。例如，如果您正在使用 DataHub 服务器版本 0.10.0，那么您应该使用 CLI 版本 0.10.0.x，其中 x 是补丁版本。 我们这样做是因为 CLI 的发布频率远高于服务器，通常每几天发布一次，而服务器大约每月两次。
>
>对于摄取源，任何重大更改都会在发行说明中突出显示。当字段被弃用或以其他方式更改时，我们将尽力在两个服务器版本（约 4 至 6 周）内保持向后兼容性。命令行界面（CLI）在使用已弃用选项时也会打印警告。


## UI ingestion
--

从版本 `0.8.25` 开始，DataHub 支持通过 DataHub 用户界面创建、配置、安排和执行批量元数据摄取。这使得将元数据引入 DataHub 更加容易，减少了操作自定义集成管道所需的开销。

本文件将介绍在用户界面中配置、安排和执行元数据摄取所需的步骤。

### 先决条件

要查看和管理基于用户界面的元数据摄取，您的账户必须被分配 `Manage Metadata Ingestion` 和 `Manage Secrets` 权限。这些权限可以通过平台策略授予。

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/ingestion-privileges.png)

一旦您获得了这些权限，就可以通过导航到 DataHub 中的“摄取”选项卡来开始管理摄取操作。

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/ingestion-tab.png)

在此页面上，您将看到活动数据源的列表。数据源是从 Snowflake、Redshift 或 BigQuery 等外部来源导入到 DataHub 的元数据的唯一来源。

如果您刚刚开始，您将没有任何数据源。在接下来的部分中，我们将介绍如何创建您的第一个数据摄取源。

### 创建数据摄取源

*   UI
*   CLI
*   GraphQL

在摄取任何元数据之前，您需要创建一个新的摄取源。首先点击“创建新源”。

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/create-new-ingestion-source-button.png)

#### 步骤 1：选择一个平台模板

在第一步中，选择与您想要从中提取元数据的源类型相对应的“配方模板”。从原生支持的多种集成中进行选择，包括 Snowflake、Postgres 和 Kafka 等。 选择 `Custom` 从头开始构建一个摄取配方。

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/select-platform-template.png)

接下来，您将配置一个摄取配方，该配方定义了从源系统中提取的内容以及提取方式。

#### 第 2 步：配置配方

接下来，您将使用 YAML 定义一个摄取“配方”。配方是一组配置，用于 DataHub 从第三方系统提取元数据。它通常由以下部分组成：

1.  源类型：您希望从中提取元数据的系统类型（例如 Snowflake、MySQL、Postgres）。如果您选择了原生模板，此选项将已为您填充。 要查看当前支持的完整类型列表，请查看此列表。

2.  源配置：针对源类型的特定配置集。大多数源支持以下类型的配置值：

3.  一种接收器类型：一种用于从源类型中提取的元数据进行路由的接收器类型。DataHub 官方支持的接收器类型为 `datahub-rest` 和 `datahub-kafka` 。

4.  接收器配置：将元数据发送到所提供的接收器类型所需的配置。例如，DataHub 的坐标和凭证。

在下面的图片中可以找到一个完整的示例配方，该配方已配置为从 MySQL 中摄取元数据。

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/example-mysql-recipe.png)

每种数据源类型的详细配置示例和文档都可以在 DataHub 文档网站上找到。

##### 创建秘密

对于生产用例，敏感配置值（例如数据库用户名和密码）应在您的摄取配方中隐藏起来，不直接显示。要实现这一点，您可以创建并嵌入“机密”。机密是经过加密并存储在 DataHub 存储层中的命名值。

要创建一个密钥，请先转到“密钥”选项卡。然后点击 `+ Create new secret` 。

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/create-secret.png)

_创建一个密钥来存储 MySQL 数据库的用户名_

在表单内，为密钥提供一个唯一的名称以及要加密的值，并可选添加描述。完成后点击“创建”。 这将创建一个密钥，您可以在摄取配方中通过其名称进行引用。

##### 提及秘密

一旦创建了机密信息，您就可以在配方中使用变量替换的方式引用它。例如，要在配方中用机密信息替换 MySQL 的用户名和密码，您的配方应定义如下：

```
source:  
 type: mysql config: host_port:  'localhost:3306' database: my_db username: ${MYSQL_USERNAME} password: ${MYSQL_PASSWORD} include_tables:  true include_views:  true profiling: enabled:  truesink:  
 type: datahub-rest config: server:  'http://datahub-gms:8080'
```

_从食谱定义中引用 DataHub 机密信息_

当使用此配方的摄取源执行时，DataHub 将尝试“解析”在 YAML 中找到的“密钥”。如果可以解析密钥，则在执行前会将其引用替换为解密后的值。 密钥值在执行时间之外不会持久保存到磁盘，并且绝不会在 DataHub 之外传输。

> 注意：任何被授予 `Manage Secrets` 平台权限的 DataHub 用户都将能够通过 GraphQL API 检索明文密钥值。

#### 第 3 步：安排执行

接下来，您可以选择为新的数据摄取源配置执行计划。这使您能够根据组织的需求，以每月、每周、每日或每小时的频率安排元数据提取。 计划使用 CRON 格式进行定义。

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/schedule-ingestion.png)

_一个每天洛杉矶时间上午 9 点 15 分执行的摄取源_

若要详细了解 CRON 定时格式，请查看维基百科的相关概述。

如果您打算临时执行数据摄取操作，可以点击“跳过”完全跳过计划设置步骤。别担心——您随时可以回来更改此设置。

#### 第 4 步：完成收尾工作

最后，给您的数据源起一个名称。

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/name-ingestion-source.png)

当您对配置满意后，点击“完成”以保存您的更改。

##### 高级摄取配置：

DataHub 的托管摄取用户界面默认配置为使用与服务器兼容的最新版本的 DataHub 命令行界面（acryl-datahub）。不过，您可以通过“高级”源配置覆盖默认的软件包版本。

要执行此操作，只需点击“高级”，然后将“CLI 版本”文本框更改为要使用的 DataHub CLI 的确切版本。

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/custom-ingestion-cli-version.png)

_将命令行界面（CLI）版本固定为版本 `0.8.23.2`_

其他高级选项包括在运行时指定环境变量、DataHub 插件或 Python 包。

一旦您对所做的更改感到满意，只需点击“完成”即可保存。

### 运行摄取源

创建好您的数据摄取源后，可以通过点击“执行”来运行它。不久之后，您应该会看到该摄取源的“最后状态”列从 `N/A` 变为 `Running`。这意味着执行摄取的请求已成功被 DataHub 摄取执行器获取。

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/running-ingestion.png)

如果摄取操作成功执行，您应该会看到其状态以绿色显示为 `Succeeded` 。

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/successful-ingestion.png)

### 取消摄取运行

如果您的数据摄取任务卡住了，可能是摄取源存在错误，或者存在其他持续性问题，比如超时时间呈指数级增长。遇到这些情况，您可以点击有问题的任务中的“取消”来取消数据摄取。

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/cancelled-ingestion.png)

一旦取消，您可以通过点击“详情”查看摄取运行的输出。

### 调试失败的数据摄取运行

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/failed-ingestion.png)

导致摄取运行失败的原因多种多样。常见的失败原因包括：

1.  配方配置错误：某个配方未提供数据摄取源所需的或预期的配置。您可以参考元数据摄取框架源文档，以了解您的源类型所需的配置详情。
2.  无法解析秘密：如果DataHub无法找到您的Recipe配置引用的秘密，则摄取运行将失败。 验证配方中引用的秘密的名称是否与已创建的名称匹配。
3.  连接性/网络可达性：如果 DataHub 无法访问数据源，例如由于 DNS 解析失败，元数据摄取将会失败。请确保部署 DataHub 的网络能够访问您尝试访问的数据源。
4.  身份验证：如果您已启用元数据服务身份验证，则需要在配方配置中提供个人访问令牌。为此，请将接收器配置中的“token”字段设置为包含个人访问令牌：

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/ingestion-with-token.png)

每次运行的输出结果都会被捕获，并可在用户界面中查看，以便更轻松地进行调试。要查看输出日志，请点击相应数据摄取运行的“详细信息”。

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/ingestion-logs.png)

常见问题解答
------

### 我尝试在运行“datahub docker quickstart”之后导入元数据，但导入操作因“连接失败”错误而失败。我该怎么办？请提供您需要翻译的英文原文。

如果不是上述原因之一导致的，这可能是因为运行摄取操作的执行器无法使用默认配置连接到 DataHub 的后端。请尝试更改您的摄取配方，使 `sink.config.server` 变量指向 `datahub-gms` Pod 的 Docker DNS 名称：

![](https://raw.githubusercontent.com/datahub-project/static-assets/main/imgs/quickstart-ingestion-config.png)

### 当我尝试运行数据摄取时，看到的是“不适用”。我该怎么办？请提供您需要翻译的英文原文。

如果您看到“N/A”，并且摄取运行状态从未变为“正在运行”，这可能意味着您的执行器（`datahub-actions`）容器已停止运行。

此容器负责在请求到达时执行摄取操作，无论是按需执行还是按照特定的时间表执行。您可以使用 `docker ps` 来验证容器的运行状况。此外，您可以通过查找 `datahub-actions` 容器的容器 ID 并运行 `docker logs <container-id>` 来查看容器日志。

### 我什么时候不应该使用 UI 采集？请提供您需要翻译的英文原文。

在没有基于用户界面的元数据摄取调度程序的情况下，存在摄取元数据的有效用例。例如，

*   您编写了一个自定义的摄取源。
*   您的数据源在 DataHub 部署的网络中无法访问。DataHub 云用户可以使用远程执行器进行基于远程 UI 的数据摄取。
*   您的数据摄取源需要来自本地文件系统的上下文（例如输入文件）。
*   您希望在多个生产者/环境中分配元数据摄取任务。

### 如何将策略附加到操作 Pod 上，以授予其从各种来源提取元数据的权限？请提供您需要翻译的英文原文。

这取决于底层平台。对于 AWS，请参考此指南。

演示
--

点击此处查看 UI 采集功能的完整演示。
