# Nginx K3s 部署配置

本目录包含在 K3s 集群中部署 Nginx 所需的所有 Kubernetes 资源配置文件。

## 文件说明

| 文件名 | 说明 |
|--------|------|
| `nginx-namespace.yaml` | 命名空间定义 |
| `nginx-pvc.yaml` | 持久卷（PV）和持久卷声明（PVC）定义 |
| `nginx-configmap.yaml` | Nginx 配置文件（ConfigMap） |
| `nginx-deployment.yaml` | Deployment 和 Service 定义 |
| `nginx-hpa.yaml` | 水平自动扩缩容（HPA）配置 |
| `default.conf` | Nginx 默认站点配置（参考文件） |
| `kustomization.yaml` | Kustomize 配置文件 |

## 部署前准备

### 1. 创建主机目录

在 K3s 节点上创建持久化存储目录：

```bash
sudo mkdir -p /opt/k3s/app/nginx/{config,html,logs,ssl}
sudo chmod -R 755 /opt/k3s/app/nginx
```

### 2. 准备默认 HTML 文件（可选）

```bash
echo '<h1>Welcome to Nginx on K3s!</h1>' | sudo tee /opt/k3s/app/nginx/html/index.html
```

### 3. 准备 SSL 证书（可选）

如果需要 HTTPS，将证书放入 SSL 目录：

```bash
sudo cp your-cert.crt /opt/k3s/app/nginx/ssl/tls.crt
sudo cp your-key.key /opt/k3s/app/nginx/ssl/tls.key
```

## 部署方式

### 方式一：使用 Kustomize（推荐）

```bash
# 预览将要部署的资源
kubectl kustomize .

# 部署所有资源
kubectl apply -k .
```

### 方式二：按顺序手动部署

```bash
# 1. 创建命名空间
kubectl apply -f nginx-namespace.yaml

# 2. 创建存储资源
kubectl apply -f nginx-pvc.yaml

# 3. 创建配置
kubectl apply -f nginx-configmap.yaml

# 4. 部署应用
kubectl apply -f nginx-deployment.yaml

# 5. 配置自动扩缩容（可选）
kubectl apply -f nginx-hpa.yaml
```

## 验证部署

```bash
# 查看 Pod 状态
kubectl get pods -n develop -l app=nginx

# 查看 Service
kubectl get svc -n develop -l app=nginx

# 查看 PVC 绑定状态
kubectl get pvc -n develop

# 查看 HPA 状态
kubectl get hpa -n develop

# 查看 Pod 日志
kubectl logs -n develop -l app=nginx --tail=100

# 测试健康检查
kubectl exec -n develop -it $(kubectl get pod -n develop -l app=nginx -o jsonpath='{.items[0].metadata.name}') -- curl -s localhost/health
```

## 访问服务

### LoadBalancer 方式

```bash
# 获取外部 IP
kubectl get svc nginx-service -n develop -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# 或者获取 NodePort
kubectl get svc nginx-service -n develop -o jsonpath='{.spec.ports[0].nodePort}'
```

### 端口转发（本地测试）

```bash
kubectl port-forward svc/nginx-service -n develop 8080:80
# 然后访问 http://localhost:8080
```

## 配置更新

### 更新 Nginx 配置

```bash
# 编辑 ConfigMap
kubectl edit configmap nginx-config -n develop

# 或者重新应用配置文件
kubectl apply -f nginx-configmap.yaml

# 重启 Pod 以应用新配置
kubectl rollout restart deployment/nginx-deployment -n develop
```

### 扩缩容

```bash
# 手动扩容
kubectl scale deployment/nginx-deployment -n develop --replicas=3

# 查看 HPA 自动扩缩容状态
kubectl describe hpa nginx-hpa -n develop
```

## 清理资源

```bash
# 使用 Kustomize 删除
kubectl delete -k .

# 或手动删除（按相反顺序）
kubectl delete -f nginx-hpa.yaml
kubectl delete -f nginx-deployment.yaml
kubectl delete -f nginx-configmap.yaml
kubectl delete -f nginx-pvc.yaml
kubectl delete -f nginx-namespace.yaml
```

## 故障排查

### 常见问题

1. **Pod 无法启动**
   ```bash
   kubectl describe pod -n develop -l app=nginx
   kubectl logs -n develop -l app=nginx --previous
   ```

2. **PVC 未绑定**
   ```bash
   kubectl get pv,pvc -n develop
   kubectl describe pvc -n develop
   ```

3. **配置未生效**
   ```bash
   # 检查 ConfigMap 内容
   kubectl get configmap nginx-config -n develop -o yaml
   
   # 进入容器检查配置
   kubectl exec -n develop -it <pod-name> -- cat /etc/nginx/nginx.conf
   ```

4. **健康检查失败**
   ```bash
   kubectl exec -n develop -it <pod-name> -- nginx -t
   kubectl exec -n develop -it <pod-name> -- curl -v localhost/health
   ```

## 注意事项

- Dashboard 代理地址 `134.175.168.219:9090` 需要根据实际环境修改
- 生产环境建议启用 HTTPS 并配置有效的 SSL 证书
- HPA 需要集群安装 metrics-server 才能正常工作
- hostPath 类型的 PV 仅适用于单节点集群，多节点请使用 NFS 或其他分布式存储

