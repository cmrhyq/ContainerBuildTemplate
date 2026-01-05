# Jenkins on Kubernetes 部署指南

## 📋 概述

本项目提供了在 Kubernetes 集群上部署 Jenkins CI/CD 服务器的最佳实践配置。

## 🏗️ 架构说明

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  Jenkins Namespace                     │  │
│  │  ┌─────────────┐    ┌─────────────┐    ┌───────────┐  │  │
│  │  │   Ingress   │───▶│   Service   │───▶│ Controller│  │  │
│  │  │  (HTTPS)    │    │  (ClusterIP)│    │   Pod     │  │  │
│  │  └─────────────┘    └─────────────┘    └─────┬─────┘  │  │
│  │                                              │        │  │
│  │                          ┌───────────────────┘        │  │
│  │                          ▼                            │  │
│  │  ┌─────────────┐    ┌─────────────┐                   │  │
│  │  │  Agent Svc  │◀───│ Dynamic     │                   │  │
│  │  │  (50000)    │    │ Agent Pods  │                   │  │
│  │  └─────────────┘    └─────────────┘                   │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │              Persistent Volumes                 │  │  │
│  │  │  • jenkins-home-pvc (50Gi)                      │  │  │
│  │  │  • maven-repo-pvc (20Gi)                        │  │  │
│  │  │  • npm-cache-pvc (10Gi)                         │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 📁 文件结构

```
jenkins/
├── jenkins-namespace.yaml    # 命名空间定义
├── jenkins-rbac.yaml         # RBAC 权限配置
├── jenkins-secret.yaml       # 敏感信息存储
├── jenkins-configmap.yaml    # 配置文件 (JCasC)
├── jenkins-pvc.yaml          # 持久卷声明
├── jenkins-deployment.yaml   # 主控制器部署
├── jenkins-service.yaml      # 服务暴露
├── jenkins-ingress.yaml      # Ingress 配置
├── kustomization.yaml        # Kustomize 配置
└── README.md                 # 本文档
```

## 🚀 快速部署

### 前置条件

- Kubernetes 集群 (v1.25+)
- kubectl 已配置
- StorageClass 可用
- Ingress Controller 已部署 (Nginx/Traefik)

### 方式一：使用 Kustomize（推荐）

```bash
# 预览将要部署的资源
kubectl kustomize jenkins/

# 部署所有资源
kubectl apply -k jenkins/

# 查看部署状态
kubectl get all -n jenkins
```

### 方式二：逐个部署

```bash
# 按顺序部署
kubectl apply -f jenkins/jenkins-namespace.yaml
kubectl apply -f jenkins/jenkins-rbac.yaml
kubectl apply -f jenkins/jenkins-secret.yaml
kubectl apply -f jenkins/jenkins-configmap.yaml
kubectl apply -f jenkins/jenkins-pvc.yaml
kubectl apply -f jenkins/jenkins-deployment.yaml
kubectl apply -f jenkins/jenkins-service.yaml
kubectl apply -f jenkins/jenkins-ingress.yaml
```

## ⚙️ 配置说明

### 1. 修改管理员凭据

编辑 `jenkins-secret.yaml`：

```yaml
stringData:
  jenkins-admin-user: "your-admin-username"
  jenkins-admin-password: "your-secure-password"
```

### 2. 配置域名

编辑 `jenkins-ingress.yaml`：

```yaml
spec:
  tls:
    - hosts:
        - jenkins.your-domain.com
      secretName: jenkins-tls-secret
  rules:
    - host: jenkins.your-domain.com
```

### 3. 调整资源限制

编辑 `jenkins-deployment.yaml`：

```yaml
resources:
  requests:
    cpu: 500m
    memory: 2Gi
  limits:
    cpu: 4000m
    memory: 8Gi
```

### 4. 配置存储类

编辑 `jenkins-pvc.yaml`，取消注释并修改：

```yaml
storageClassName: your-storage-class
```

## 🔧 JCasC 配置

Jenkins Configuration as Code (JCasC) 配置位于 `jenkins-configmap.yaml`。

### 预配置的 Agent 模板

| 模板名称 | 标签 | 用途 |
|---------|------|------|
| default-agent | jenkins-agent | 通用构建任务 |
| maven-agent | maven | Java/Maven 项目 |
| nodejs-agent | nodejs, node | Node.js 项目 |
| docker-agent | docker, dind | 需要 Docker 的构建 |

### 在 Pipeline 中使用

```groovy
pipeline {
    agent {
        kubernetes {
            label 'maven'
        }
    }
    stages {
        stage('Build') {
            steps {
                container('maven') {
                    sh 'mvn clean package'
                }
            }
        }
    }
}
```

## 📊 监控与日志

### 查看 Pod 状态

```bash
kubectl get pods -n jenkins -w
```

### 查看日志

```bash
# Controller 日志
kubectl logs -n jenkins deployment/jenkins-controller -f

# 查看特定 Pod 日志
kubectl logs -n jenkins <pod-name> -c jenkins
```

### 进入容器调试

```bash
kubectl exec -it -n jenkins deployment/jenkins-controller -- /bin/bash
```

## 🔐 安全最佳实践

1. **使用 External Secrets Operator** 管理敏感信息
2. **启用 HTTPS**，配置有效的 TLS 证书
3. **限制 RBAC 权限**，仅授予必要的权限
4. **定期更新** Jenkins 和插件版本
5. **启用审计日志** 记录用户操作
6. **配置备份策略** 保护 Jenkins 数据

## 🔄 升级指南

```bash
# 1. 备份数据
kubectl exec -n jenkins deployment/jenkins-controller -- tar czf /tmp/backup.tar.gz /var/jenkins_home

# 2. 更新镜像版本
kubectl set image deployment/jenkins-controller jenkins=jenkins/jenkins:lts-jdk17 -n jenkins

# 3. 验证升级
kubectl rollout status deployment/jenkins-controller -n jenkins
```

## 🗑️ 卸载

```bash
# 使用 Kustomize 卸载
kubectl delete -k jenkins/

# 或逐个删除
kubectl delete -f jenkins/jenkins-ingress.yaml
kubectl delete -f jenkins/jenkins-service.yaml
kubectl delete -f jenkins/jenkins-deployment.yaml
kubectl delete -f jenkins/jenkins-pvc.yaml
kubectl delete -f jenkins/jenkins-configmap.yaml
kubectl delete -f jenkins/jenkins-secret.yaml
kubectl delete -f jenkins/jenkins-rbac.yaml
kubectl delete -f jenkins/jenkins-namespace.yaml
```

## ❓ 常见问题

### Q: Jenkins 启动缓慢？

A: 首次启动需要下载插件，可能需要 5-10 分钟。检查启动探针配置是否足够宽松。

### Q: Agent Pod 无法连接？

A: 检查以下配置：
- `jenkins-agent-service` 是否正常运行
- JCasC 中的 `jenkinsTunnel` 配置是否正确
- RBAC 权限是否足够

### Q: PVC 绑定失败？

A: 确认：
- StorageClass 存在且可用
- 存储配额足够
- 访问模式与存储类兼容

## 📚 参考资料

- [Jenkins 官方文档](https://www.jenkins.io/doc/)
- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [JCasC 配置参考](https://github.com/jenkinsci/configuration-as-code-plugin)
- [Kubernetes 最佳实践](https://kubernetes.io/docs/concepts/configuration/overview/)


