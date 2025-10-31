> `tls: failed to verify certificate: x509: certificate signed by unknown authority`

说明 **Harbor 的自签 CA 没有被 containerd 信任**。也就是说证书生成和 Harbor 配置没问题，但 **k8s 节点的运行时还不认识你的 CA**。我们来逐步排查：

---

## 🔍 排查要点

1. **确认证书目录结构**
    
    - 对于 **containerd**，必须是：
        
        ```
        /etc/containerd/certs.d/172.29.105.240/ca.crt
        ```
        
        注意：目录名必须和你访问 Harbor 的地址完全一致（这里是 `172.29.105.240`，不能写成 `https://172.29.105.240` 或带端口）。
2. **确认 ca.crt 内容**
    
    - 你放进去的 `ca.crt` 必须是 **根证书**（CA），而不是 `harbor.crt`。
    - 检查：
        
        ```bash
        openssl x509 -in /etc/containerd/certs.d/172.29.105.240/ca.crt -noout -text | grep "CA:TRUE"
        ```
        
        如果没有 `CA:TRUE`，说明你放错了文件。
3. **重启 containerd**
    
    ```bash
    systemctl restart containerd
    ```
    
4. **测试信任链** 在节点上执行：
    
    ```bash
    curl -v https://172.29.105.240/v2/ --cacert /etc/containerd/certs.d/172.29.105.240/ca.crt
    ```
    
    - 如果返回 `{}` → Harbor 证书链没问题，containerd 应该也能用。
    - 如果报错 → Harbor 证书或 SAN 配置有问题，需要重新生成。

---

## ⚡ 常见坑

- **SAN 没写 IP**：证书里必须有 `subjectAltName = IP:172.29.105.240`，否则验证失败。
- **节点访问地址不一致**：如果你用 `172.29.105.240` 生成证书，但 Pod 配置里写了 `https://harbor.local`，也会报错。
- **证书链不完整**：如果 Harbor 配置了 `harbor.crt`，但里面没包含中间 CA，需要把完整链（server cert + CA cert）拼在一起。

---

## ✅ 建议操作顺序

1. 确认 `/etc/containerd/certs.d/172.29.105.240/ca.crt` 是 **CA 根证书**。
2. 确认 Harbor 的 `harbor.crt` 里 SAN 包含 `IP:172.29.105.240`。
3. 重启 containerd。
4. 用 `curl --cacert` 测试。
5. 再用 `crictl pull` 测试。
