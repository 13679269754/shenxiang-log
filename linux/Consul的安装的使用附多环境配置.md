| operator | createtime | updatetime |
| ---- | ---- | ---- |
| shenx | 2024-8月-13 | 2024-8月-13  |
| ... | ... | ... |
---

# Consul的安装的使用附多环境配置

[toc]

## 资料

[Consul的安装的使用附多环境配置](https://blog.csdn.net/weixin_46099455/article/details/126351145)

## 文章内容
### 一、概述

[Consul](https://so.csdn.net/so/search?q=Consul&spm=1001.2101.3001)
----------------------------------------------------------------------------

        Consul 是 HashiCorp 公司推出的开源工具，用于实现分布式系统的服务发现与配置。与其他分布式服务注册与发现的方案，Consul 的方案更“一站式”，内置了服务注册与发现框架、分布一致性协议实现、健康检查、Key/Value 存储、多数据中心方案，不再需要依赖其他工具（比如 ZooKeeper 等）。使用起来也较 为简单。Consul 使用 Go 语言编写，因此具有天然可移植性(支持Linux、windows和Mac OS X)；安装包仅包含一个可执行文件，方便部署，与 Docker 等轻量级容器可无缝配合。

![](https://i-blog.csdnimg.cn/blog_migrate/4ecc77cdf5e53ea90eeeac82ecdc84c9.png)

### 二、Consul功能

----------

![](https://i-blog.csdnimg.cn/blog_migrate/a4b4af368575c12278cc7598e785b086.png)

### 三、Consul角色

----------

**Service：** 

        服务端,保存配置信息,高可用集群,在局域网与本地客户端通讯,通过广域网与其他数据中心通讯,每个数据中心的Server数量推荐3个或者5个。

**Client：** 

客户端,无状态,将HTTP和DNS接口请求转发给局域网内的服务端集群。

### 四、使用Consul的优势 

--------------

*   使用 Raft 算法来保证一致性, Consul 保持了 CAP 中的 CP，保持了强一致性和分区容错性。
*   支持多数据中心。
*   支持健康检查。
*   使用go语言开发，启动速度和运行速度快。

### 五、Consul的安装和使用 

---------------

        打开Consul官网 [https://www.consul.io/](https://www.consul.io/ "https://www.consul.io/") 根据不同的操作系统选择最新的 Consul 版本，我们这里以 Windows 64 操作系统为例，可以看出 Consul 目前的最新版本为  1.13.1

![](https://i-blog.csdnimg.cn/blog_migrate/28722caffd79e90cc5035828629ed9ef.png)
**下载下来是一个压缩包，解压之后是一个consul.exe文件**

**然后在exe文件所在的目录cmd进入命令行，输入如下执行启动consul**

```null
 consul agent -dev 
```

 成功之后如图

![](https://i-blog.csdnimg.cn/blog_migrate/9c79010539622654238a344fc808ae94.png)

**启动成功之后访问：localhost:8500,就可以看到Consul的管理界面**

![](https://i-blog.csdnimg.cn/blog_migrate/374d6c6f97445bc38d52fad5f3165f70.png)

Consul 的 Web 管理界面有一些菜单，我们这里做一下简单的介绍：

**Services**，管理界面的默认页面，用来展示注册到 Consul 的服务，启动后默认会有一个 consul 服务，也就是它本身。

**Nodes**，在 Services 界面双击服务名就会来到 Services 对于的 Nodes 界面，Services 是按照服务的抽象来展示的，Nodes 展示的是此服务的具体节点信息。比如启动了两个订单服务实例，Services 界面会出现一个订单服务，Nodes 界面会展示两个订单服务的节点。

**Key/Value** ，如果有用到 Key/Value 存储，可以在界面进行配置、查询。

**ACL**，全称 Access Control List，为访问控制列表的展示信息。

**Intentions**，可以在页面配置请求权限。

 **此时，我们的consul就安装成功了**！

### 六、Consul的调用流程

-----------------

![](https://i-blog.csdnimg.cn/blog_migrate/e649ad48ea8a935dfb059e598e52c690.png)

**1、当 Producer 启动的时候，会向 Consul 发送一个 post 请求，告诉 Consul 自己的 IP 和 Port；**

**2、Consul 接收到 Producer 的注册后，每隔 10s（默认）会向 Producer 发送一个健康检查的请求，检验 Producer 是否健康；**

**3、当 Consumer 发送 GET 方式请求 /api/address 到 Producer 时，会先从 Consul 中拿到一个存储服务 IP 和 Port 的临时表，从表中拿到 Producer 的 IP 和 Port 后再发送 GET 方式请求 /api/address；**

**4、该临时表每隔 10s 会更新，只包含有通过了健康检查的 Producer。** 

* * *

      Spring Cloud Consul 项目是针对 Consul 的服务治理实现。Consul 是一个分布式高可用的系统，它包含多个组件，但是作为一个整体，在微服务架构中，为我们的基础设施提供服务发现和服务配置的工具。

### 补充：Consul多环境配置

--------------

#### Consul服务端

 1.在consul主页面进行添加对应的多环境配置Key/Value，对于不同的环境在后面用","分隔拼接

![](https://i-blog.csdnimg.cn/blog_migrate/d02e1ec07884829955e1a508004d9920.png)

    配置对应的信息，如下图

开发环境dev

![](https://i-blog.csdnimg.cn/blog_migrate/1e45a82977b23849fb4be5f8f3a6da38.png)

 生产环境prod

![](https://i-blog.csdnimg.cn/blog_migrate/d9c3b5076f4b371b76c92e5df9940a9c.png)

 测试环境test

![](https://i-blog.csdnimg.cn/blog_migrate/4bf880a25fec1b26c395e2402a5664f0.png)

#### Java实现代码

启动类

```null
public class ConsulApplication {public static void main(String[] args) {        SpringApplication.run( ConsulApplication.class,args );
```

配置类

```null
@ConfigurationProperties(prefix = "student")public class ConsulConfig {
```

测试控制器

```null
public class TestController {private ConsulConfig consulConfig;        System.out.println( consulConfig.getName()+"  "+consulConfig.getAge() );
```

bootstrap.yml配置文件

```null
        service-name: ${spring.application.name}        prefix: config  #默认读取config        # profile-separator: - # 环境的分隔符，默认是逗号，若设置为'-'则改为 mailer-dev，mailer-prod
```

其中的spring.profiles.active后的dev可以改成 test 和 prod ，对应不同的环境，从而实现多环境配置。

**测试结果：** 

1.dev环境

![](https://i-blog.csdnimg.cn/blog_migrate/c0cad4882dffc15d2fba0ac9d25f8079.png)

2.prod环境

![](https://i-blog.csdnimg.cn/blog_migrate/3742fe8e1b73406beaa2a1368fd0bad9.png)

 3.test环境

![](https://i-blog.csdnimg.cn/blog_migrate/5ebfe74e27e879f414b56f25d529f8a1.png)