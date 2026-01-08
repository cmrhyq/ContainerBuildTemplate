# Jenkins on K3s 部署指南（低配置服务器优化版）

## 📋 概述

本项目提供了在 **K3s 单节点集群**上部署 Jenkins CI/CD 服务器的配置。
专门针对 **4核4G** 低配置服务器进行了优化。

### 内置开发工具

| 工具 | 版本 | 路径 |
|------|------|------|
| Java | 17 (OpenJDK) | 系统自带 |
| Maven | 3.9.6 | `/opt/tools/maven` |
| Allure | 2.24.1 | `/opt/tools/allure` |
| Go | 1.22.0 | `/opt/tools/go` |
| Python | 3.x | 系统自带 |

### 资源占用说明

| 组件 | CPU 请求 | CPU 限制 | 内存请求 | 内存限制 |
|------|---------|---------|---------|---------|
| Jenkins Controller | 200m | 2000m | 512Mi | 1536Mi |
| 工具安装（Init） | 200m | 1000m | 256Mi | 1Gi |
| 插件安装（Init） | 200m | 500m | 512Mi | 1Gi |
| 动态 Agent Pod | 100m | 500m | 256Mi | 512Mi |

**总内存占用估算**：Jenkins 运行时约 1-1.5G，系统预留约 1G，剩余约 1.5G 可用于 Agent。

## 🏗️ 架构说明

```
┌─────────────────────────────────────────────────────────────┐
│                    K3s Single Node (4C4G)                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  Jenkins Namespace                     │  │
│  │                                                        │  │
│  │  ┌─────────────┐    ┌─────────────┐    ┌───────────┐  │  │
│  │  │  Traefik    │───▶│   Service   │───▶│ Controller│  │  │
│  │  │  Ingress    │    │  (NodePort) │    │   Pod     │  │  │
│  │  └─────────────┘    └─────────────┘    └─────┬─────┘  │  │
│  │                                              │        │  │
│  │                          ┌───────────────────┘        │  │
│  │                          ▼                            │  │
│  │  ┌─────────────┐    ┌─────────────┐                   │  │
│  │  │  Agent Svc  │◀───│ Dynamic     │ (按需创建)        │  │
│  │  │  (50000)    │    │ Agent Pod   │                   │  │
│  │  └─────────────┘    └─────────────┘                   │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │              Persistent Volumes                  │  │  │
│  │  │  • jenkins-home-pvc (10Gi) - 配置和构建历史      │  │  │
│  │  │  • jenkins-tools-pvc (3Gi) - Maven/Allure/Go    │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 📁 文件结构

```
jenkins/
├── jenkins-namespace.yaml    # 命名空间定义
├── jenkins-rbac.yaml         # RBAC 权限配置
├── jenkins-secret.yaml       # 敏感信息存储（可选）
├── jenkins-configmap.yaml    # JVM 和启动参数配置（已优化）
├── jenkins-pvc.yaml          # 持久卷声明（Home 10Gi + Tools 3Gi）
├── jenkins-deployment.yaml   # 主控制器部署（内置开发工具）
├── jenkins-service.yaml      # 服务暴露
├── jenkins-ingress.yaml      # Traefik Ingress 配置
├── Dockerfile                # 自定义镜像构建（可选）
├── kustomization.yaml        # Kustomize 配置
└── README.md                 # 本文档
```

## 🚀 快速部署

### 前置条件

- K3s 集群已安装（单节点即可）
- kubectl 已配置
- 服务器配置：最低 4核4G

### 部署步骤

```bash
# 1. 克隆或进入项目目录
cd Kubernetes/jenkins

# 2. 使用 Kustomize 部署所有资源
kubectl apply -k .

# 3. 查看部署状态
kubectl get all -n jenkins

# 4. 等待 Pod 启动（低配服务器可能需要 5-10 分钟）
kubectl get pods -n jenkins -w
```

### 逐个部署（可选）

```bash
kubectl apply -f jenkins-namespace.yaml
kubectl apply -f jenkins-rbac.yaml
kubectl apply -f jenkins-secret.yaml
kubectl apply -f jenkins-configmap.yaml
kubectl apply -f jenkins-pvc.yaml
kubectl apply -f jenkins-deployment.yaml
kubectl apply -f jenkins-service.yaml
kubectl apply -f jenkins-ingress.yaml
```

---

## 🔧 首次启动配置

### 步骤 1：获取初始管理员密码

```bash
# 等待 Pod 运行
kubectl get pods -n jenkins -w

# 获取初始管理员密码
kubectl exec -n jenkins deployment/jenkins-controller -- cat /var/jenkins_home/secrets/initialAdminPassword
```

### 步骤 2：访问 Jenkins

**方式一：通过 NodePort 访问（推荐）**
```bash
# 访问地址：http://<服务器IP>:30080
```

**方式二：通过 Port Forward 访问**
```bash
kubectl port-forward -n jenkins svc/jenkins-service 8080:8080 --address=0.0.0.0
# 访问 http://<服务器IP>:8080
```

**方式三：通过 Traefik Ingress 访问**
- 配置 hosts 文件：`<服务器IP> jenkins.local`
- 访问 `http://jenkins.local`

### 步骤 3：完成安装向导

1. 输入初始管理员密码
2. 选择 **"Select plugins to install"** - 建议只安装必要插件
3. 创建管理员账户
4. 配置 Jenkins URL

---

## 🔧 全局工具配置

完成安装向导后，配置内置的开发工具：

**路径**: `Manage Jenkins` → `Tools`

### Maven 配置

| 配置项 | 值 |
|--------|-----|
| Name | `Maven-3.9` |
| MAVEN_HOME | `/opt/tools/maven` |
| Install automatically | ❌ 不勾选 |

### Allure 配置

| 配置项 | 值 |
|--------|-----|
| Name | `Allure-2.24` |
| Installation directory | `/opt/tools/allure` |
| Install automatically | ❌ 不勾选 |

### Go 配置

| 配置项 | 值 |
|--------|-----|
| Name | `Go-1.22` |
| GOROOT | `/opt/tools/go` |
| Install automatically | ❌ 不勾选 |

### JDK 配置

| 配置项 | 值 |
|--------|-----|
| Name | `JDK-17` |
| JAVA_HOME | `/opt/java/openjdk` |
| Install automatically | ❌ 不勾选 |

---

## ⚙️ 低配服务器 Kubernetes Cloud 配置

完成安装向导后，配置 Kubernetes Cloud 以支持动态 Agent：

**路径**: `Manage Jenkins` → `Clouds` → `New cloud` → `Kubernetes`

### Kubernetes Cloud 基础配置

| 配置项 | 值 | 说明 |
|--------|-----|------|
| Name | `kubernetes` | 云名称 |
| Kubernetes URL | `https://kubernetes.default.svc.cluster.local` | 集群内部地址 |
| Kubernetes Namespace | `jenkins` | Agent 运行的命名空间 |
| Jenkins URL | `http://jenkins-service:8080` | Controller 服务地址 |
| Jenkins tunnel | `jenkins-agent-service:50000` | Agent 连接地址 |
| Container Cap | `3` | **重要：限制最大并发 Pod 数，避免资源耗尽** |
| Max connections to Kubernetes API | `32` | 减少 API 连接数 |

### Pod Template - 轻量级 Agent（推荐）

**基础配置**：
| 配置项 | 值 |
|--------|-----|
| Name | `lightweight-agent` |
| Labels | `jenkins-agent lightweight` |
| Usage | `Use this node as much as possible` |
| Idle minutes | `10` |
| Active deadline | `1800` |

**Container - jnlp**：
| 配置项 | 值 |
|--------|-----|
| Name | `jnlp` |
| Docker image | `jenkins/inbound-agent:latest-alpine` |
| Working directory | `/home/jenkins/agent` |
| Allocate pseudo-TTY | ✅ |
| Request CPU | `100m` |
| Request Memory | `256Mi` |
| Limit CPU | `500m` |
| Limit Memory | `512Mi` |

### Pod Template - Maven Agent（低配版）

**基础配置**：
| 配置项 | 值 |
|--------|-----|
| Name | `maven-agent` |
| Labels | `maven` |
| Usage | `Only build jobs with label expressions matching this node` |
| Idle minutes | `5` |
| Active deadline | `3600` |

**Container 1 - jnlp**：
| 配置项 | 值 |
|--------|-----|
| Name | `jnlp` |
| Docker image | `jenkins/inbound-agent:latest-alpine` |
| Working directory | `/home/jenkins/agent` |
| Request CPU | `50m` |
| Request Memory | `128Mi` |

**Container 2 - maven**：
| 配置项 | 值 |
|--------|-----|
| Name | `maven` |
| Docker image | `maven:3.9-eclipse-temurin-17-alpine` |
| Working directory | `/home/jenkins/agent` |
| Command to run | `sleep` |
| Arguments | `infinity` |
| Request CPU | `200m` |
| Request Memory | `512Mi` |
| Limit CPU | `1000m` |
| Limit Memory | `1Gi` |

---

## 📝 Pipeline 示例

### 简单构建任务

```groovy
pipeline {
    agent {
        kubernetes {
            label 'lightweight'
        }
    }
    stages {
        stage('Hello') {
            steps {
                sh 'echo "Hello from K3s Jenkins!"'
                sh 'cat /etc/os-release'
            }
        }
    }
}
```

### Maven 构建任务

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
                    sh 'mvn --version'
                    // sh 'mvn clean package -DskipTests'
                }
            }
        }
    }
}
```

### 使用内置工具（在 Controller 上运行）

```groovy
pipeline {
    agent any
    
    environment {
        MAVEN_HOME = '/opt/tools/maven'
        ALLURE_HOME = '/opt/tools/allure'
        GOROOT = '/opt/tools/go'
        GOPATH = '/var/jenkins_home/go'
        PATH = "${MAVEN_HOME}/bin:${ALLURE_HOME}/bin:${GOROOT}/bin:${GOPATH}/bin:${env.PATH}"
    }
    
    stages {
        stage('Check Tools') {
            steps {
                sh '''
                    echo "=== Java ==="
                    java -version
                    
                    echo "=== Maven ==="
                    mvn --version
                    
                    echo "=== Allure ==="
                    allure --version
                    
                    echo "=== Go ==="
                    go version
                    
                    echo "=== Python ==="
                    python3 --version || echo "Python not available in base image"
                '''
            }
        }
    }
}
```

### Maven + Allure 测试报告

```groovy
pipeline {
    agent any
    
    environment {
        MAVEN_HOME = '/opt/tools/maven'
        ALLURE_HOME = '/opt/tools/allure'
        PATH = "${MAVEN_HOME}/bin:${ALLURE_HOME}/bin:${env.PATH}"
    }
    
    stages {
        stage('Build & Test') {
            steps {
                sh 'mvn clean test'
            }
        }
        
        stage('Allure Report') {
            steps {
                allure([
                    includeProperties: false,
                    jdk: '',
                    results: [[path: 'target/allure-results']]
                ])
            }
        }
    }
}
```

### Go 项目构建

```groovy
pipeline {
    agent any
    
    environment {
        GOROOT = '/opt/tools/go'
        GOPATH = '/var/jenkins_home/go'
        PATH = "${GOROOT}/bin:${GOPATH}/bin:${env.PATH}"
    }
    
    stages {
        stage('Build') {
            steps {
                sh '''
                    go version
                    go mod download
                    go build -o app ./...
                '''
            }
        }
        
        stage('Test') {
            steps {
                sh 'go test -v ./...'
            }
        }
    }
}
```

### 使用内联 Pod 模板（更灵活）

```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: shell
    image: alpine:latest
    command:
    - sleep
    args:
    - infinity
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 256Mi
'''
        }
    }
    stages {
        stage('Run') {
            steps {
                container('shell') {
                    sh 'echo "Running in Alpine container"'
                    sh 'apk add --no-cache curl'
                    sh 'curl --version'
                }
            }
        }
    }
}
```

```groovy
// Maven 构建
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: maven
    image: maven:3.9-eclipse-temurin-17
    command: [sleep, infinity]
    resources:
      limits:
        memory: 1Gi
        cpu: 1000m
'''
        }
    }
    stages {
        stage('Build') {
            steps {
                container('maven') {
                    sh 'mvn --version'
                    sh 'mvn clean package'
                }
            }
        }
    }
}
```

```groovy
// Go 构建
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: golang
    image: golang:1.22
    command: [sleep, infinity]
'''
        }
    }
    stages {
        stage('Build') {
            steps {
                container('golang') {
                    sh 'go version'
                    sh 'go build ./...'
                }
            }
        }
    }
}
```

```groovy
// Python + Allure 测试
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: python
    image: python:3.12
    command: [sleep, infinity]
  - name: allure
    image: frankescobar/allure-docker-service
    command: [sleep, infinity]
'''
        }
    }
    stages {
        stage('Test') {
            steps {
                container('python') {
                    sh 'pip install pytest allure-pytest'
                    sh 'pytest --alluredir=allure-results'
                }
            }
        }
    }
}
```

---

## 📊 监控与调试

### 查看资源使用情况

```bash
# 查看 Jenkins Pod 资源使用
kubectl top pod -n jenkins

# 查看节点资源使用
kubectl top node
```

### 查看日志

```bash
# Controller 日志
kubectl logs -n jenkins deployment/jenkins-controller -f

# 查看 Agent Pod 日志
kubectl logs -n jenkins <agent-pod-name> -c jnlp
```

### 进入容器调试

```bash
kubectl exec -it -n jenkins deployment/jenkins-controller -- /bin/bash
```

---

## ⚠️ 低配服务器注意事项

### 1. 限制并发构建

在 `Manage Jenkins` → `System` 中设置：
- **# of executors**: `0`（不在 Controller 上运行任务）

在 Kubernetes Cloud 配置中：
- **Container Cap**: `2-3`（限制同时运行的 Agent Pod 数量）

### 2. 减少插件安装

避免安装以下重量级插件：
- Blue Ocean（占用大量内存）
- SonarQube Scanner
- 大型 IDE 集成插件

### 3. 定期清理

```bash
# 清理旧的构建历史
# 在 Jenkins 中配置：Manage Jenkins → System → 设置构建历史保留策略

# 清理未使用的 Docker 镜像（如果使用 Docker-in-Docker）
kubectl exec -n jenkins <pod> -- docker system prune -af
```

### 4. 监控内存使用

如果 Jenkins 频繁 OOM，可以进一步降低 JVM 内存：

```bash
# 编辑 ConfigMap
kubectl edit configmap jenkins-config -n jenkins

# 将 -Xmx1024m 改为 -Xmx768m
```

---

## 🗑️ 卸载

```bash
# 使用 Kustomize 卸载
kubectl delete -k .

# 或删除整个命名空间
kubectl delete namespace jenkins
```

---

## ❓ 常见问题

### Q: Jenkins 启动很慢？

A: 低配服务器首次启动可能需要 5-10 分钟，这是正常的。可以通过以下命令查看启动进度：
```bash
kubectl logs -n jenkins deployment/jenkins-controller -f
```

### Q: Agent Pod 启动失败？

A: 检查资源是否足够：
```bash
kubectl describe pod -n jenkins <agent-pod-name>
kubectl top node
```

### Q: 内存不足导致 Pod 被杀？

A: 减少 Container Cap 或降低单个 Agent 的内存限制。

### Q: 构建任务卡住？

A: 可能是资源不足，尝试：
1. 减少并发构建数
2. 增加构建超时时间
3. 使用更轻量的 Agent 镜像

---

## 📚 参考资料

- [K3s 官方文档](https://docs.k3s.io/)
- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [Jenkins 内存优化指南](https://www.jenkins.io/doc/book/scaling/architecting-for-scale/)

