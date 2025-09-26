
[(19 封私信 / 10 条消息) 相较于RocketMQ的事务消息，本地消息表才是真正的王者 - 知乎](https://zhuanlan.zhihu.com/p/590834427)
**1\. 概览**
----------

在[分布式系统](https://zhida.zhihu.com/search?content_id=219430301&content_type=Article&match_order=1&q=%E5%88%86%E5%B8%83%E5%BC%8F%E7%B3%BB%E7%BB%9F&zhida_source=entity)中，系统间的通信除了大家所熟知的 RPC 外，基于 MQ 的异步通信也越来越流行，已经成为基础设施的重要组成部分。而 MQ 的引入对系统间的数据一致性提出了新的挑战，逐渐成为系统稳定性的一大隐患。

### **1.1. 背景**

### **1.1.1. 业务挑战**

> 未接触过分布式的同学可能对其没有概念，当我们引入 MQ 后，MQ 与数据库操作存在一致性要求。

举个简单例子，一个业务操作中存在 “更新DB” 和 “发送 MQ” 两个动作，具体如下：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-9-26%2015-06-15/c8e523e6-257f-490d-8b55-60e63b66a3a9.png?raw=true)

如果流程正常结束，变更保存到 DB，Message 成功发送至 MQ，就不存在不一致的情况。但，如果中间发生异常，一致性就没有了保障。

比如在如下这个示例：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-9-26%2015-06-15/5a59c4cf-273f-4813-a1c0-c8c4982ee52d.png?raw=true)

1.  更新 DB 和 发送 MQ 被包在一个数据库事务；
2.  如果在事务提交前，发送 MQ 之后出现了异常，将触发数据库事务回滚，此时

*   DB 变更被回滚
*   MQ 无法回滚

*   结果便是 Consumer 成功获取 Message 并进行业务处理，而 DB 回滚业务操作已经失败，下游处理了一个本不存在的变更。

那我们换个思路，数据库事务只对 DB 更新进行保护，示例如下：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-9-26%2015-06-15/a5773578-efe1-4a33-bd8a-c8f4294599da.png?raw=true)

1.  仅将 数据库变更 包在一个数据库事务里；
2.  如果在事务提交后，发送MQ 前出现了异常，此时

*   数据库变更已经成功持久化到 DB
*   而MQ发送失败，下游业务无法获取变更消息

*   最终导致丢失变更，未成功触发下游的正常业务；

当然还有更复杂的场景，示例如下：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-9-26%2015-06-15/f713b653-80d3-4471-9041-ff962430a0e2.png?raw=true)

数据库变更 和 发送MQ 交替出现，又该如何保障其一致性呢？

### **1.1.2. [事务消息](https://zhida.zhihu.com/search?content_id=219430301&content_type=Article&match_order=1&q=%E4%BA%8B%E5%8A%A1%E6%B6%88%E6%81%AF&zhida_source=entity)**

> 众所周知，RocketMQ 提供事务消息机制，以完成业务操作与消息发送的一致性。但在实际使用过程中，复杂的 API 将逻辑切分的稀碎，增加了业务理解的难度，在实际开发中很少使用。

事务消息整体流程如下：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-9-26%2015-06-15/b3e6cc20-34ac-4874-9f85-bcc8c78318f9.png?raw=true)

核心流程如下：

1.  生产者将半事务消息发送至 RocketMQ Broker。
2.  RocketMQ Broker 将消息持久化成功之后，向生产者返回 Ack 确认消息已经发送成功，此时消息暂不能投递，为半事务消息。
3.  生产者开始执行本地事务逻辑。
4.  生产者根据本地事务执行结果向服务端提交二次确认结果（Commit或是Rollback），服务端收到确认结果后处理逻辑如下：

*   二次确认结果为Commit：服务端将半事务消息标记为可投递，并投递给消费者。
*   二次确认结果为Rollback：服务端将回滚事务，不会将半事务消息投递给消费者。

*   在断网或者是生产者应用重启的特殊情况下，若服务端未收到发送者提交的二次确认结果，或服务端收到的二次确认结果为Unknown未知状态，经过固定时间后，服务端将对消息生产者即生产者集群中任一生产者实例发起消息回查。
*   生产者收到消息回查后，需要检查对应消息的本地事务执行的最终结果。
*   生产者根据检查得到的本地事务的最终状态再次提交二次确认，服务端仍按照步骤4对半事务消息进行处理。

为了确保一致性，整个流程变得好复杂，不仅仅是流程，API 使用也晦涩难懂，示例代码如下：

```java
public class TransactionProducer {
    public static void main(String[] args) throws MQClientException, InterruptedException {
        // 通过监听器在本地事务中处理业务逻辑，对异常发现进行检测并恢复状态
        TransactionListener transactionListener = new TransactionListenerImpl();
        TransactionMQProducer producer = new TransactionMQProducer("please_rename_unique_group_name");
        // 为 Producer 设置监听器
        producer.setTransactionListener(transactionListener);
        producer.start();

        String[] tags = new String[] {"TagA", "TagB", "TagC", "TagD", "TagE"};
        for (int i = 0; i < 10; i++) {
            try {
                Message msg =
                    new Message("TopicTest", tags[i % tags.length], "KEY" + i,
                        ("Hello RocketMQ " + i).getBytes(RemotingHelper.DEFAULT_CHARSET));
                // 发送事务消息
                SendResult sendResult = producer.sendMessageInTransaction(msg, null);
                System.out.printf("%s%n", sendResult);

                Thread.sleep(10);
            } catch (MQClientException | UnsupportedEncodingException e) {
                e.printStackTrace();
            }
        }

        for (int i = 0; i < 100000; i++) {
            Thread.sleep(1000);
        }
        producer.shutdown();
    }

    static class TransactionListenerImpl implements TransactionListener {
        private AtomicInteger transactionIndex = new AtomicInteger(0);

        private ConcurrentHashMap<String, Integer> localTrans = new ConcurrentHashMap<>();
        
        // 在本地事务中执行业务逻辑，根据返回结果决定二次确认结果
        @Override
        public LocalTransactionState executeLocalTransaction(Message msg, Object arg) {
            int value = transactionIndex.getAndIncrement();
            int status = value % 3;
            localTrans.put(msg.getTransactionId(), status);
            return LocalTransactionState.UNKNOW;
        }

        // 网络出现异常后，未收到二次确认，对业务进行fan'cha
        @Override
        public LocalTransactionState checkLocalTransaction(MessageExt msg) {
            Integer status = localTrans.get(msg.getTransactionId());
            if (null != status) {
                switch (status) {
                    case 0:
                        return LocalTransactionState.UNKNOW;
                    case 1:
                        return LocalTransactionState.COMMIT_MESSAGE;
                    case 2:
                        return LocalTransactionState.ROLLBACK_MESSAGE;
                    default:
                        return LocalTransactionState.COMMIT_MESSAGE;
                }
            }
            return LocalTransactionState.COMMIT_MESSAGE;
        }
    }
}

```

单看代码很难理解，简单画了张图，具体如下：

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-9-26%2015-06-15/31d84e9e-2b6d-4ba4-aa58-64166cf28c8b.png?raw=true)

其核心部分就是 `TransactionListener` 实现，其他部分与正常的消息发送基本一致，`TransactionListener` 主要完成：

1.  执行本地事务，也就是业务操作；
2.  执行结果检测，通过反查业务数据，决定消息的后续处理策略；

为了使用事务消息，我们不得不在`TransactionListener`中编写进行大量的适配逻辑，增加研发成本，同时由于逻辑被拆分到多处，也增加了代码的理解成本。

> RocketMQ 的事务消息通过回查方式对消息进行补充，是一个非常好的设计理念。但，其 API 过于复杂，在实际开发中很少使用。

### **1.2. 目标**

> 不要 RocketMQ 的复杂性，还要 RocketMQ 的一致性，另一个优秀的替代方案便是[本地消息表](https://zhida.zhihu.com/search?content_id=219430301&content_type=Article&match_order=1&q=%E6%9C%AC%E5%9C%B0%E6%B6%88%E6%81%AF%E8%A1%A8&zhida_source=entity)。

1.  保障消息发送与业务操作之间的强一致；
2.  提供简单通用 API，降低使用门槛；
3.  提供简洁配置方法，降低接入成本；
4.  提供补偿策略，保障至少一次发送；

**2\. 快速入门**
------------

### **2.1. 环境准备**

首先，在 pom 中引入 lego-starter

```text
<dependency>
 <groupId>com.geekhalo.lego</groupId>
 <artifactId>lego-starter</artifactId>
 <version>0.1.12-reliable_message_sender-SNAPSHOT</version>
</dependency>

```

然后，在数据库中新增本地消息表，具体sql如下：

```java
create table test_message
(
    id           bigint auto_increment primary key,

    orderly      tinyint      not null comment '是否为顺序消息',

    topic        varchar(64)  not null comment 'MQ topic',
    sharding_key varchar(128) not null comment 'ShardingKey，用于选择不同的 partition',
    tag          varchar(128) not null comment 'Message Tag 信息',

    msg_id       varchar(64)  not null comment 'Msg ID 只有发送成功后才有数据',
    msg_key      varchar(64)  not null comment 'MSG Key，用于查询数据',
    msg          longtext     not null comment '要发送的消息',

    retry_time   tinyint      not null comment '重试次数',
    status       tinyint      not null comment '发送状态:0-初始化，1-发送成功，2-发送失败',

    create_time  datetime     not null,
    update_time  datetime     not null,

    index idx_update_time_status(update_time, status)
);

```

需要一个执行消息发送逻辑的 `MessageSender`，为了测试方便，先进行 Mock，具体如下：

```java
@Component
@Getter
@Slf4j
public class TestMessageSender implements MessageSender {
    private boolean error = false;
    private List<Message> messages = Lists.newArrayList();

    @Override
    public String send(Message message) {
        log.info("receive message {}", message);
        if (this.error){
            throw new RuntimeException();
        }
        this.messages.add(message);
        return String.valueOf(RandomUtils.nextLong());
    }

    public void clean(){
        this.messages.clear();
    }

    public void markError() {
        this.error = true;
    }

    public void cleanError(){
        this.error = false;
    }
}

```

最后，新建 `LocalTableBasedReliableMessageConfiguration` 对本地消息表进行配置，具体如下：

```java
@Configuration
@Slf4j
public class LocalTableBasedReliableMessageConfiguration
        extends LocalTableBasedReliableMessageConfigurationSupport {

    @Autowired
    private DataSource dataSource;

    @Autowired
    private MessageSender messageSender;

    @Override
    protected DataSource dataSource() {
        return this.dataSource;
    }

    @Override
    protected String messageTable() {
        return "test_message";
    }

    @Override
    protected MessageSender createMessageSend() {
        return this.messageSender;
    }
}

```

其中，包括：

1.  继承自 `LocalTableBasedReliableMessageConfigurationSupport`，由父类完成基本配置；
2.  实现 `DataSource dataSource()` 方法，返回业务数据源（备注：必须与业务使用同一个数据源）
3.  实现 `String messageTable()` 方法，配置本地消息表表名；
4.  实现 `MessageSender createMessageSend()` 方法，返回 `MessageSender` 实例，执行真正的消费发送；

至此，完成了所有配置工作，可以使用相关API进行消息处理：

1.  `ReliableMessageSender#send` 在业务方法中使用，执行可靠消息发送；
2.  `ReliableMessageCompensator#compensate` 周期性调度，对未发送或发送失败的消息进行补充；

### **2.2. 正常发送**

使用 `reliableMessageSender` 的 send 方法执行可靠消息发送，具体如下：

```java
@Transactional
public void testSuccess(){
    // 业务逻辑
    Message message = buildMessage();
    // 业务逻辑
    this.reliableMessageSender.send(message);
}

```

`@Transactional` 注解保障 业务逻辑 和 消费发送 在同一个事物中进行处理。

测试用例如下：

```java
@Test
public void testTestSuccess() {
    this.testMessageSenderService.testSuccess();

    List<Message> messages = this.testMessageSender.getMessages();
    Assertions.assertTrue(CollectionUtils.isNotEmpty(messages));
}

```

在方法成功执行后，`TestMessageSender` 收到消息。

### **2.3. 异常回滚**

业务执行失败，事务自动发生回滚，不会触发消息发送。

```java
@Transactional
public void testError(){
    // 业务逻辑
    Message message = buildMessage();
    // 业务逻辑
    this.reliableMessageSender.send(message);
    throw new RuntimeException();
}

```

逻辑和 `testSuccess` 基本一致，只是在执行最后抛出 `RuntimeException`，触发事务回滚。

测试代码如下：

```java
@Test
public void testTestError() {
    boolean error = false;
    try {
        this.testMessageSenderService.testError();
    }catch (Exception e){
        error = true;
    }

    Assertions.assertTrue(error);

    List<Message> messages = this.testMessageSender.getMessages();
    Assertions.assertTrue(CollectionUtils.isEmpty(messages));
}

```

事务回滚，`TestMessageSender` 未收到消息。

### **2.4. 直接发送（不建议）**

如果 `ReliableMessageSender#send` 未运行在事务内，方法调用时会直接发送消息，不能做到业务操作和消息发送的强一致。

```java
public void testNoTransaction(){
    // 业务逻辑
    Message message = buildMessage();
    this.reliableMessageSender.send(message);
}

public void testNoTransactionError(){
    // 业务逻辑
    Message message = buildMessage();
    this.reliableMessageSender.send(message);
    throw new RuntimeException();
}

```

与之前代码相比，只是移除了 `@Transaction` 注解，导致方法无法受到事务的保护。 测试代码如下：

```java
@Test
public void testNoTransaction(){
    this.testMessageSenderService.testNoTransaction();

    {
        List<Message> messages = this.testMessageSender.getMessages();
        Assertions.assertTrue(CollectionUtils.isNotEmpty(messages));
    }

    this.testMessageSender.clean();
    boolean error = false;
    try {
        this.testMessageSenderService.testNoTransactionError();
    }catch (Exception e){
        error = true;
    }

    Assertions.assertTrue(error);

    {
        List<Message> messages = this.testMessageSender.getMessages();
        Assertions.assertTrue(CollectionUtils.isNotEmpty(messages));
    }
}

```

无论成功还是失败，`TestMessageSender` 都收到了消息。

### **2.5. 消息补偿**

由于 MQ 服务器不可用导致消息发送失败，不应该影响正常的业务逻辑。而是周期性对未发送或发送失败的消息进行补充，及执行重新发送逻辑。

测试代码如下：

```java
@Test
public void loadAndSend() throws InterruptedException {
    // 处理消费表中待发送数据
    this.reliableMessageCompensator.compensate(DateUtils.addSeconds(new Date(), -120), 1000);

    // 进行 error 标记， MessageSender 发送请求直接失败
    this.testMessageSender.markError();
    for (int i = 0; i<10;i++){
        // 执行业务逻辑，业务逻辑不受影响
        this.testMessageSenderService.testSuccess();
    }
    // 清理 error 标记，MessageSender 正常发送
    this.testMessageSender.cleanError();


    {
        // 检测消息表中存在待处理的任务
        List<LocalMessage> localMessages = localMessageRepository.loadNotSuccessByUpdateGt(DateUtils.addSeconds(new Date(), -60), 100);
        Assertions.assertEquals(10, localMessages.size());
    }

    // 对消息进行补充处理
    this.reliableMessageCompensator.compensate(DateUtils.addSeconds(new Date(), -60), 5);

    {
        //  由于时间限制，未处理消息表的任务
        List<LocalMessage> localMessages = localMessageRepository.loadNotSuccessByUpdateGt(DateUtils.addSeconds(new Date(), -60), 100);
        Assertions.assertEquals(10, localMessages.size());
    }

    // 等待时间超时
    TimeUnit.SECONDS.sleep(15);

    this.testMessageSender.clean();
    // 对消息进行补充处理
    this.reliableMessageCompensator.compensate(DateUtils.addSeconds(new Date(), -60), 50);

    {
        //  成功处理消息表的待处理任务
        List<LocalMessage> localMessages = localMessageRepository.loadNotSuccessByUpdateGt(DateUtils.addSeconds(new Date(), -60), 100);
        Assertions.assertEquals(0, localMessages.size());

        List<Message> messages = this.testMessageSender.getMessages();
        Assertions.assertTrue(CollectionUtils.isNotEmpty(messages));
    }
}

```

从测试用例中可以得出几个结论：

1.  消息发送异常不影响正常的业务逻辑；
2.  未避免刚插入的消息被补偿逻辑消费，近10秒内的消息不会进行自动补充；
3.  消息成功发送后，消息表状态被更新，从而避免重复发送；

**3\. 设计&扩展**
-------------

### **3.1. 核心设计**

**整体架构如下：** 

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-9-26%2015-06-15/d185e533-7148-4ed4-90ab-e20f7b08b28d.png?raw=true)

**业务操作流程如下：** 

1.  应用程序接收外部业务请求；
2.  开启本地事务
3.  执行业务逻辑，将业务对象变更保存的业务表；
4.  构建事件对象，将事件对象插入到本地消息表；
5.  提交本地事务
6.  触发发送流程，调用 MQ 的发送接口，发送消息；
7.  消息成功发送后，更新消息表的状态，并补写 msgId；

**最终结果：** 

1.  本地事务提交失败，业务表和消息表的变更被回滚，不会触发发送逻辑；
2.  本地事务提交成功，消息发送失败，后台定时器会进行自动补偿；

**补偿流程如下：** 

1.  Timer 周期性触发补偿逻辑；
2.  从消息表中加载未发送或发送失败的消息；
3.  调用发送接口，将消息发送至 MQ；
4.  系统发送成功后，更新消息表的状态；

### **3.2. 合理使用 TransactionSynchronizationManager**

`TransactionSynchronizationManager` 是 Spring 框架提供的一种 事务同步机制，通过 `registerSynchronization` 方法可以向 `TransactionSynchronizationManager` 注册自定义逻辑，在事务操作的不同阶段调用不同的回调函数。

lego 就是通过该机制重写 `afterCommit` 方法，在事务成功提交后，触发消息发送逻辑。

```java
private void addCallbackOrRunTask(SendMessageTask sendMessageTask) {
    if (TransactionSynchronizationManager.isSynchronizationActive()) {
        // 添加监听器，在事务提交后触发后续任务
        TransactionSynchronization transactionSynchronization = new TransactionSynchronizationAdapter(){
            @Override
            public void afterCommit() {
                sendMessageTask.run();
            }
        };
        TransactionSynchronizationManager.registerSynchronization(transactionSynchronization);
        log.info("success to register synchronization for message {}", sendMessageTask.getLocalMessage());
    }else {
        // 没有可以事务，直接触发后续任务
        log.info("No Transaction !!! begin to run task for message {}", sendMessageTask.getLocalMessage());
        sendMessageTask.run();
        log.info("No Transaction !!! success to run task for message {}", sendMessageTask.getLocalMessage());
    }
}

```

**4\. 项目信息**
------------

项目仓库地址：

[https://gitee.com/litao851025/lego](https://link.zhihu.com/?target=https%3A//gitee.com/litao851025/lego)

项目文档地址：

[https://gitee.com/litao851025/lego/wikis/support/reliable-message](https://link.zhihu.com/?target=https%3A//gitee.com/litao851025/lego/wikis/support/reliable-message)

> 来源：geekhalo

Java面试题
-------