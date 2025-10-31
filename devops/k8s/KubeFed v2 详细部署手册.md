以下是Federation v2（Kubernetes Cluster Federation v2）** 的详细部署手册，包含环境准备、控制平面部署、成员集群加入及功能验证的完整步骤。本手册基于 KubeFed v0.9.0（目前较稳定版本），适用于 Kubernetes 1.20+ 集群。


### 一、环境准备
#### 1. 集群要求
- **至少 2 个独立的 Kubernetes 集群**：
  - 1 个作为 **主机集群（Host Cluster）**：部署 KubeFed 控制平面，需具备管理员权限。
  - 1+ 个作为 **成员集群（Member Cluster）**：加入联邦，由 KubeFed 管理资源。
- **Kubernetes 版本**：所有集群版本需 ≥ 1.16，推荐 1.20-1.24（参考 [KubeFed 兼容性矩阵](https://github.com/kubernetes-sigs/kubefed#compatibility-matrix)）。
- **网络要求**：
  - 主机集群的 API Server 可访问所有成员集群的 API Server（需网络互通）。
  - 所有集群需能拉取 KubeFed 镜像（默认从 Docker Hub 拉取）。

#### 2. 工具准备
- **kubectl**：版本需与集群版本兼容（推荐与主机集群版本一致）。
- **kubefedctl**：KubeFed 命令行工具，用于部署控制平面和管理成员集群。
  ```bash
  # 下载适合的版本（以 v0.9.0 为例，根据系统架构选择）
  wget https://github.com/kubernetes-sigs/kubefed/releases/download/v0.9.0/kubefedctl-v0.9.0-linux-amd64.tgz
  tar -zxvf kubefedctl-v0.9.0-linux-amd64.tgz
  chmod +x kubefedctl
  sudo mv kubefedctl /usr/local/bin/

  # 验证安装
  kubefedctl version
  # 输出示例：v0.9.0
  ```

#### 3. kubeconfig 配置
- 为所有集群准备 `kubeconfig` 文件（主机集群和成员集群），确保：
  - 主机集群的 `kubeconfig` 有管理员权限（可创建 Namespace、Deployment 等）。
  - 主机集群通过 `kubeconfig` 能访问成员集群的 API Server。
- 建议将各集群的 `kubeconfig` 合并到一个文件（如 `~/.kube/federation-kubeconfig.yaml`），并通过 `context` 区分：
  ```bash
  # 查看当前 kubeconfig 中的集群和上下文
  kubectl config get-clusters
  kubectl config get-contexts

  # 若需合并，可使用 kubectl config use-context 和 kubectl config view --raw 导出后合并
  ```


### 二、部署 KubeFed 控制平面（主机集群）
KubeFed 控制平面需部署在主机集群，包含控制器管理器、 admission webhook 等组件。

#### 1. 选择部署命名空间
默认使用 `kubefed-system` 命名空间，也可自定义（需全程保持一致）：
```bash
export KUBEFED_NAMESPACE=kubefed-system
kubectl create namespace $KUBEFED_NAMESPACE
```

#### 2. 部署控制平面组件
使用 `kubefedctl deploy` 命令部署，需指定主机集群的上下文（`--cluster-name`）和 `kubeconfig`：
```bash
# 导出主机集群的上下文名称（从 kubeconfig 中获取）
export HOST_CLUSTER_CONTEXT=host-cluster-context  # 替换为实际上下文名
export KUBECONFIG=~/.kube/federation-kubeconfig.yaml  # 替换为你的 kubeconfig 路径

# 部署 KubeFed 控制平面
kubefedctl deploy \
  --cluster-name host-cluster \  # 主机集群在联邦中的名称（自定义）
  --kubeconfig $KUBECONFIG \
  --context $HOST_CLUSTER_CONTEXT \
  --namespace $KUBEFED_NAMESPACE
```

#### 3. 验证控制平面部署
```bash
# 查看命名空间中的 Pod（确保所有组件 Running）
kubectl get pods -n $KUBEFED_NAMESPACE --context $HOST_CLUSTER_CONTEXT

# 输出示例（3 个核心组件）：
NAME                                          READY   STATUS    RESTARTS   AGE
kubefed-admission-webhook-7f9d658b4d-2xqzk    1/1     Running   0          5m
kubefed-controller-manager-6d7f9876c4-5rjkp   1/1     Running   0          5m
kubefed-webhook-service-84d7f9b65-9v7k2       1/1     Running   0          5m
```

#### 4. 部署联邦自定义资源（CRDs）
KubeFed 依赖多个 CRD（如 `FederatedDeployment`、`KubeFedCluster`），部署控制平面时会自动创建，验证：
```bash
kubectl get crds | grep kubefed.io

# 输出示例（部分 CRD）：
federatedconfigmaps.types.kubefed.io          2025-10-15T08:00:00Z
federateddeployments.types.kubefed.io         2025-10-15T08:00:00Z
kubefedclusters.core.kubefed.io               2025-10-15T08:00:00Z
```


### 三、将成员集群加入联邦
需为每个成员集群创建访问凭证，并通过 `kubefedctl join` 加入联邦。

#### 1. 准备成员集群的访问凭证
将成员集群的 `kubeconfig` 存储为 Secret，供主机集群访问：
```bash
# 导出成员集群的上下文名称（从 kubeconfig 中获取）
export MEMBER_CLUSTER_NAME=member-cluster-1  # 成员集群在联邦中的名称（自定义）
export MEMBER_CLUSTER_CONTEXT=member-context-1  # 成员集群的实际上下文名

# 创建 Secret（存储成员集群的 kubeconfig）
kubectl create secret generic ${MEMBER_CLUSTER_NAME}-secret \
  --from-file=kubeconfig=<(kubectl config view --context $MEMBER_CLUSTER_CONTEXT --raw) \
  -n $KUBEFED_NAMESPACE \
  --context $HOST_CLUSTER_CONTEXT
```

#### 2. 加入成员集群
```bash
kubefedctl join $MEMBER_CLUSTER_NAME \
  --cluster-context $HOST_CLUSTER_CONTEXT \  # 主机集群上下文
  --host-cluster-context $HOST_CLUSTER_CONTEXT \
  --secret-name ${MEMBER_CLUSTER_NAME}-secret \  # 上面创建的 Secret 名称
  --secret-namespace $KUBEFED_NAMESPACE \
  --kubeconfig $KUBECONFIG
```

#### 3. 验证成员集群状态
```bash
kubectl get kubefedclusters -n $KUBEFED_NAMESPACE --context $HOST_CLUSTER_CONTEXT

# 输出示例（STATUS 为 Ready 表示加入成功）：
NAME               READY   AGE
host-cluster       True    10m  # 主机集群默认也会作为成员集群加入
member-cluster-1   True    5m
```

#### 4. 重复步骤加入更多成员集群
若有多个成员集群，重复上述 1-3 步，替换 `MEMBER_CLUSTER_NAME` 和 `MEMBER_CLUSTER_CONTEXT` 即可。


### 四、部署联邦资源（验证跨集群同步）
通过创建 `FederatedDeployment` 验证资源是否能同步到指定成员集群。

#### 1. 创建联邦 Deployment
创建 `federated-nginx.yaml` 文件：
```yaml
apiVersion: types.kubefed.io/v1beta1
kind: FederatedDeployment
metadata:
  name: nginx-federated
  namespace: default  # 需在所有成员集群中存在该命名空间（或提前同步 Namespace）
spec:
  template:  # 基础 Deployment 模板（与普通 Deployment 一致）
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: nginx
            image: nginx:1.25.3
            ports:
            - containerPort: 80
  placement:  # 指定同步到哪些成员集群
    clusters:
    - name: member-cluster-1  # 成员集群名称（与 join 时指定的一致）
    # - name: member-cluster-2  # 可添加更多集群
  overrides:  # 可选：为特定集群设置差异化配置
  - clusterName: member-cluster-1
    clusterOverrides:
    - path: spec.replicas  # 覆盖副本数
      value: 3  # 该集群部署 3 个副本（覆盖 template 中的 2 个）
```

#### 2. 应用联邦资源
```bash
kubectl apply -f federated-nginx.yaml --context $HOST_CLUSTER_CONTEXT
```

#### 3. 验证同步结果
- **在主机集群查看联邦资源**：
  ```bash
  kubectl get federateddeployments -n default --context $HOST_CLUSTER_CONTEXT
  # 输出：
  NAME               AGE
  nginx-federated   2m
  ```

- **在成员集群查看同步的 Deployment**：
  ```bash
  # 切换到成员集群上下文
  kubectl config use-context $MEMBER_CLUSTER_CONTEXT

  # 查看是否创建了 Deployment
  kubectl get deployments -n default
  # 输出（副本数应为 3，匹配 overrides 配置）：
  NAME               READY   UP-TO-DATE   AVAILABLE   AGE
  nginx-federated   3/3     3            3           2m

  # 查看 Pod（确认正常运行）
  kubectl get pods -n default -l app=nginx
  ```


### 五、卸载 KubeFed
若需清理环境，执行以下步骤：
1. 删除所有联邦资源（避免成员集群残留资源）：
   ```bash
   kubectl delete federateddeployments nginx-federated -n default --context $HOST_CLUSTER_CONTEXT
   ```

2. 将成员集群从联邦中移除：
   ```bash
   kubefedctl unjoin member-cluster-1 \
     --cluster-context $HOST_CLUSTER_CONTEXT \
     --kubeconfig $KUBECONFIG
   ```

3. 删除 KubeFed 控制平面：
   ```bash
   kubectl delete namespace $KUBEFED_NAMESPACE --context $HOST_CLUSTER_CONTEXT
   ```


### 六、常见问题排查
1. **成员集群加入失败（STATUS 为 NotReady）**：
   - 检查主机集群是否能访问成员集群的 API Server（网络连通性）。
   - 验证成员集群的 Secret 凭证是否正确：`kubectl describe secret <secret-name> -n $KUBEFED_NAMESPACE`。

2. **联邦资源同步失败**：
   - 查看 KubeFed 控制器日志：`kubectl logs -n $KUBEFED_NAMESPACE <kubefed-controller-manager-pod> -f`。
   - 确保成员集群中存在联邦资源的命名空间（如 `default`），否则需先同步 Namespace。

3. **镜像拉取失败**：
   - 若集群无法访问 Docker Hub，可配置私有镜像仓库，并通过 `--image-repository` 参数指定：
     ```bash
     kubefedctl deploy --image-repository your-registry/kubefed ...
     ```


通过以上步骤，即可完成 KubeFed v2 的部署和基本使用。如需更复杂的场景（如跨集群服务发现、配置同步），可参考 [KubeFed 官方文档](https://github.com/kubernetes-sigs/kubefed) 扩展配置。