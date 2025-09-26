| operator | createtime | updatetime |
| -------- | ---------- | ---------- |
| shenx    | 2025-5月-09 | 2025-5月-09 |
| ... | ... | ... |
---
# orientdb集群安装.md

[toc]

参考链接：[https://www.howtoing.com/how-to-configure-an-orientdb-cluster-on-ubuntu-16-04/](https://www.howtoing.com/how-to-configure-an-orientdb-cluster-on-ubuntu-16-04/)

orientD安装
---------

## 一、解压到/opt下
----------

```bash
tar -zxvf /opt/packs/orientdb-3.0.18.tar.gz -C /opt/
```

## 二、orientDB单机版安装
---------------

*   1、其实单机版直接启动就可以了，但是会提示输入root密码，并且保存到config/orientdb-server\-config.xml的users配置中。所以一般先进行密码设置，再启动。
    
    ```bash
    <user resources="*" password="rzx1218(这个随意，到时候登录界面需要的)" name="root"/><user resources="connect,server.listDatabases,server.dblist" password="rzx1218(这个随意，到时候登录界面需要的)" name="guest"/>
    ```
    
    如果不设置密码，启动会提示输入
    
    ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-5-9%2014-33-49/961d408d-e19e-4d8c-9ddf-b788073cbfe6.jpeg?raw=true)
    
*   2、服务启停
    

## 三、集群版安装
-------

集群配置需要修改三个文件：orientdb-server-config.xml、hazelcast.xml、default-distributed-db-config.json。

orientdb-server-config.xml开启分布式 ==> hazelcast.xml配置文件默认使用广播方式发现其他节点 ==> default-distributed-db-config.json来指定odb集群中节点的角色。

其实hazelcast.xml、default-distributed-db-config.json不是必须修改的，他们都有默认值，默认是用广播发现其他节点，并且将所有节点划分到一个odb集群。同样默认所有的节点角色为master，如果需要划分多个集群，则需要进行修改

###   1、vim config/orientdb-server-config.xml
    
修改com.orientechnologies.orient.server.hazelcast.OHazelcastPlugin开启分布式，会使用配置文件hazelcast.xml进行广播发现其他节点，最后要加上一行来指定nodeName，否则启动时会提示输入机器名称
    
```bash
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<orient-server>
    <handlers>
        <handler class="com.orientechnologies.orient.server.hazelcast.OHazelcastPlugin">
            <parameters>
                <parameter value="${distributed}" name="enabled"/>
                <parameter value="${ORIENTDB_HOME}/config/default-distributed-db-config.json" name="configuration.db.default"/>
                <parameter value="${ORIENTDB_HOME}/config/hazelcast.xml" name="configuration.hazelcast"/>
            </parameters>
        </handler>
        <handler class="com.orientechnologies.orient.server.handler.OJMXPlugin">
            <parameters>
                <parameter value="false" name="enabled"/>
                <parameter value="true" name="profilerManaged"/>
            </parameters>
        </handler>
        <handler class="com.orientechnologies.orient.server.handler.OAutomaticBackup">
            <parameters>
                <parameter value="false" name="enabled"/>
                <parameter value="${ORIENTDB_HOME}/config/automatic-backup.json" name="config"/>
            </parameters>
        </handler>
        <handler class="com.orientechnologies.orient.server.handler.OServerSideScriptInterpreter">
            <parameters>
                <parameter value="true" name="enabled"/>
                <parameter value="SQL" name="allowedLanguages"/>
            </parameters>
        </handler>
        <handler class="com.orientechnologies.orient.server.handler.OCustomSQLFunctionPlugin">
            <parameters>
                <parameter value="${ORIENTDB_HOME}/config/custom-sql-functions.json" name="config"/>
            </parameters>
        </handler>
    </handlers>
    <network>
        <sockets>
            <socket implementation="com.orientechnologies.orient.server.network.OServerTLSSocketFactory" name="ssl">
                <parameters>
                    <parameter value="false" name="network.ssl.clientAuth"/>
                    <parameter value="config/cert/orientdb.ks" name="network.ssl.keyStore"/>
                    <parameter value="password" name="network.ssl.keyStorePassword"/>
                    <parameter value="config/cert/orientdb.ks" name="network.ssl.trustStore"/>
                    <parameter value="password" name="network.ssl.trustStorePassword"/>
                </parameters>
            </socket>
            <socket implementation="com.orientechnologies.orient.server.network.OServerTLSSocketFactory" name="https">
                <parameters>
                    <parameter value="false" name="network.ssl.clientAuth"/>
                    <parameter value="config/cert/orientdb.ks" name="network.ssl.keyStore"/>
                    <parameter value="password" name="network.ssl.keyStorePassword"/>
                    <parameter value="config/cert/orientdb.ks" name="network.ssl.trustStore"/>
                    <parameter value="password" name="network.ssl.trustStorePassword"/>
                </parameters>
            </socket>
        </sockets>
        <protocols>
            <protocol implementation="com.orientechnologies.orient.server.network.protocol.binary.ONetworkProtocolBinary" name="binary"/>
            <protocol implementation="com.orientechnologies.orient.server.network.protocol.http.ONetworkProtocolHttpDb" name="http"/>
        </protocols>
        <listeners>
            <listener protocol="binary" socket="default" port-range="2424-2430" ip-address="0.0.0.0"/>
            <listener protocol="http" socket="default" port-range="2480-2490" ip-address="0.0.0.0">
                <commands>
                    <command implementation="com.orientechnologies.orient.server.network.protocol.http.command.get.OServerCommandGetStaticContent" pattern="GET|www GET|studio/ GET| GET|*.htm GET|*.html
 GET|*.xml GET|*.jpeg GET|*.jpg GET|*.png GET|*.gif GET|*.js GET|*.css GET|*.swf GET|*.ico GET|*.txt GET|*.otf GET|*.pjs GET|*.svg GET|*.json GET|*.woff GET|*.woff2 GET|*.ttf GET|*.svgz" stateful="fals
e">
                        <parameters>
                            <entry value="Cache-Control: no-cache, no-store, max-age=0, must-revalidate\r\nPragma: no-cache" name="http.cache:*.htm *.html"/>
                            <entry value="Cache-Control: max-age=120" name="http.cache:default"/>
                        </parameters>
                    </command>
                    <command implementation="com.orientechnologies.orient.server.network.protocol.http.command.get.OServerCommandGetGephi" pattern="GET|gephi/*" stateful="false"/>
                </commands>
                <parameters>
                    <parameter value="utf-8" name="network.http.charset"/>
                    <parameter value="true" name="network.http.jsonResponseError"/>
                </parameters>
            </listener>
        </listeners>
    </network>
    <storages/>
    <users>
        <user resources="*" password="{PBKDF2WithHmacSHA256}038E76D6C47E921151B975FE43BF78B6D6C90BBAF01FEDB4:E42D8ACB68111DD4B4AA5CEC0078C0131709EC181096E338:65536" name="root"/>
        <user resources="connect,server.listDatabases,server.dblist" password="{PBKDF2WithHmacSHA256}7CEFB28AC39E572D9D8CC97691072F23CF9A46413FB52CCA:256808492509DF3AD44D748DB5BC05B37545116C5FF51AA6:65
536" name="guest"/>
    </users>
    <properties>
        <entry value="false" name="profiler.enabled"/>
    </properties>
    <isAfterFirstTime>true</isAfterFirstTime>
</orient-server>
```
    
注意：nodeName如果不配置，启动的时候提示输入，输入后会将值增加到这个文件上面对应的位置，每次启动就不需要配置了
    
    ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-5-9%2014-33-49/14412996-857e-42d6-83c8-bfbdbc562ec5.jpeg?raw=true)
    
    修改users ==> 和单机版一样
    
###   2、vim config/hazelcast.xml
    
这个文件默认使用广播的方式发现其他节点，并把他们划为一个odb集群，如果想分为几个集群，则需要单独指定ip划分。
    
```bash
<?xml version="1.0" encoding="UTF-8"?>
<!-- ~ Copyright (c) 2008-2012, Hazel Bilisim Ltd. All Rights Reserved. ~
        ~ Licensed under the Apache License, Version 2.0 (the "License"); ~ you may
        not use this file except in compliance with the License. ~ You may obtain
        a copy of the License at ~ ~ http://www.apache.org/licenses/LICENSE-2.0 ~
        ~ Unless required by applicable law or agreed to in writing, software ~ distributed
        under the License is distributed on an "AS IS" BASIS, ~ WITHOUT WARRANTIES
        OR CONDITIONS OF ANY KIND, either express or implied. ~ See the License for
        the specific language governing permissions and ~ limitations under the License. -->

<hazelcast
                xsi:schemaLocation="http://www.hazelcast.com/schema/config hazelcast-config-3.3.xsd"
                xmlns="http://www.hazelcast.com/schema/config" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <group>
                <name>orientdb</name>
                <password>orientdb</password>
        </group>
        <properties>
                <property name="hazelcast.phone.home.enabled">false</property>
                <property name="hazelcast.mancenter.enabled">false</property>
                <property name="hazelcast.memcache.enabled">false</property>
                <property name="hazelcast.rest.enabled">false</property>
                <property name="hazelcast.wait.seconds.before.join">5</property>
                <property name="hazelcast.operation.thread.count">1</property>
                <property name="hazelcast.io.thread.count">1</property>
                <property name="hazelcast.operation.generic.thread.count">1</property>
                <property name="hazelcast.client.event.thread.count">1</property>
                <property name="hazelcast.event.thread.count">1</property>
                <property name="hazelcast.heartbeat.interval.seconds">5</property>
                <property name="hazelcast.max.no.heartbeat.seconds">30</property>
                <property name="hazelcast.merge.next.run.delay.seconds">15</property>
        </properties>
        <network>
                <port auto-increment="true">2434</port>
                <join>
                        <multicast enabled="true">
                                <multicast-group>235.1.1.1</multicast-group>
                                <multicast-port>2434</multicast-port>
                        </multicast>
                </join>
        </network>
        <executor-service>
                <pool-size>16</pool-size>
        </executor-service>
</hazelcast>

```
    
*   3、vim config/default-distributed-db-config.json
    
这个文件也可以不用修改，默认odb集群中所有odb节点都是master角色，如果需要单独指定角色，则单独修改
    
```bash

```
    
###   4、将本机本机配置好的orientDB发送到其他机器
    
```bash
      scp -r /opt/orientdb-3.0.18/ rzx169:/opt/  注意：一定要修改其他机器的config/orientdb-server-config.xml<parameter name="nodeName" value="本机名称"/>
```
    
###   5、防火墙开放如下端口
    2424
    2423
    2480


###   6、服务启停
    
```bash
      “Accepting socket connection from /10.10.160.21:34786 [TcpIpAcceptor]”  “Established socket connection between /10.10.160.23:2434 and /10.10.160.21:34786”  说明rzx168机器和rzx169机器已经相互通信了
```
    

转载于:https://my.oschina.net/liufukin/blog/2254017