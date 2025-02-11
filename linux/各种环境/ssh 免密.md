[SSH的免密登录详细步骤（注释+命令+图）_ssh 免密登录-CSDN博客](https://blog.csdn.net/SXY16044314/article/details/90605069) 

   
### 需求

为了保证一台Linux主机的安全，所以我们每个主机登录的时候一般我们都设置账号密码登录。但是很多时候为了操作方便，我们都通过设置SSH免密码登录。  
在这里我对本地机器Cloud10和目标机器Cloud11、Cloud12进行免密登录

### 大致的三步

1.本地机器生成公[私钥](https://so.csdn.net/so/search?q=%E7%A7%81%E9%92%A5&spm=1001.2101.3001.7020)  
2.上传公钥到目标机器  
3.测试免密登录

### 具体操作

**1.准备工作**

*   使用root权限分别修改每台机器的hosts，添加每台机器所对应的IP和主机名（我这里分布式集群是3台机器组成的，所以配置3台，习惯将自己的ip和主机名放在第一行）  
    `sudo vim /etc/hosts`  
    删除文件里内容后添加如下内容  
    ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-22%2009-44-27/345fdf06-87de-4f68-ac8d-f87bebd7d9b1.png?raw=true)
    
*   查看本地机器的隐藏文件 .ssh  
    `ll -a`  
    ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-22%2009-44-27/ce5cc795-fa39-4658-9f0e-c0e0a5fb9fe1.png?raw=true)
      
    **2.在本地机器用ssh-keygen 生成一个公私钥对**  
    在ssh目录下进行，输入三个回车  
    进入.ssh目录 `cd .ssh`
*   发起公钥请求 `ssh-keygen -t rsa`  
    ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-22%2009-44-27/be087694-1997-49b9-aaec-2bd885bb7043.png?raw=true)
    
*   在.ssh/目录下，会新生成两个文件：id\_rsa.pub和 id\_rsa

![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-22%2009-44-27/173a8713-249a-4b32-a82b-03a73f5bbd39.png?raw=true)
  
**3.上传公钥到目标机器**  
`ssh-copy-id hduser@192.168.157.146`  
`ssh-copy-id hduser@Cloud12`  
注意：（@前边是接受公钥机器的用户名，后边是接受放的ip，因为配置了映射所以ip可以用主机名代替）  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-22%2009-44-27/9f39844a-2fb2-4e00-9055-ea31bcc5e14c.png?raw=true)
  
![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-22%2009-44-27/e31b100e-b6a5-4655-9e24-2c4e5efb1449.png?raw=true)

*   查看远程从节点主机上是否接收到 authorized\_keys文件  
    ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-22%2009-44-27/e806fd71-b9dd-428f-b971-ec30908ef2e0.png?raw=true)
      
    ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-22%2009-44-27/5e54a702-c490-41f0-ae6d-31f484a49be8.png?raw=true)
    
*   这个时候Cloud10的公钥文件内容会追加写入到Cloud11的 .ssh/authorized\_keys  
    **文件中查看Cloud11下的authorized\_keys文件与Cloud10下的id\_rsa.pub中内容是一样的,如下图所示**  
    ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-22%2009-44-27/3808f037-f121-4ef9-9879-b69d96940e71.png?raw=true)
      
    ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-22%2009-44-27/ebe2edb7-420a-42e5-a0be-ae5c1282de52.png?raw=true)
    
*   重启 SSH服务命令使其生效:（3台机器都要重启)  
    `sudo service sshd restart`  
    ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-22%2009-44-27/83826160-fec8-429b-bbf4-9d3eabe25aac.png?raw=true)
      
    `另外我们要注意，`  
    .ssh目录的权限为700，其下文件authorized\_keys和私钥的权限为600。否则会因为权限问题导致无法免密码登录。我们可以看到登陆后会有known\_hosts文件生成。  
    `chmod -R 700 .ssh/`  
    `sudo chmod 600 .ssh/authorized_keys`  
    **4.测试免密登录**  
    使用IP免密登录（用户名相同时，ssh+主机名；如果不同，登录方式就是 ssh+用户名@IP地址）  
    `ssh Cloud10`  
    `ssh Cloud11`  
    `ssh Cloud12`  
    ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-22%2009-44-27/d3a0c12f-b66c-4342-b3ee-a8b5c0ebc81a.png?raw=true)
    
*   退出免密登录  
    `exit`  
    ![](https://github.com/13679269754/shenxiang-log/blob/main/image-cubox/2025-1-22%2009-44-27/8d57d155-c251-45de-8341-68014f440c8c.png?raw=true)
    

### 注意事项

*   免密码登录的处理是用户对用户的，切换其他用户后，仍然需要输入密码
*   远程机器的.ssh目录需要700权限，authorized\_keys文件需要600权限  
    否则配置是不成功的（每次登录都得重新去输入密码的）

 