# Jenkins on Kubernetes 部署指南

## 📋 概述

本项目提供了在 Kubernetes 集群上部署 Jenkins CI/CD 服务器的配置。
**配置方式**：通过 Jenkins Web 界面进行配置（非 JCasC 方式）。

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
├── jenkins-secret.yaml       # 敏感信息存储（可选）
├── jenkins-configmap.yaml    # JVM 和启动参数配置
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

---

## 🔧 首次启动配置指南

Jenkins 首次启动时会显示安装向导，请按以下步骤完成配置：

### 步骤 1：获取初始管理员密码

```bash
# 等待 Pod 运行
kubectl get pods -n jenkins -w

# 获取初始管理员密码
kubectl exec -n jenkins deployment/jenkins-controller -- cat /var/jenkins_home/secrets/initialAdminPassword
```

### 步骤 2：访问 Jenkins

- 通过 Ingress 访问: `https://jenkins.your-domain.com`
- 或通过 Port Forward: 
  ```bash
  kubectl port-forward -n jenkins svc/jenkins-service 8080:8080
  # 访问 http://localhost:8080
  ```

### 步骤 3：完成安装向导

1. 输入初始管理员密码
2. 选择 **"Install suggested plugins"** 或 **"Select plugins to install"**
3. 创建管理员账户
4. 配置 Jenkins URL

---

## ⚙️ Jenkins 界面配置详细指南

完成安装向导后，请按以下步骤配置 Jenkins：

### 1. 系统配置

**路径**: `Manage Jenkins` → `System`

#### 1.1 系统消息
| 配置项 | 推荐值 |
|--------|--------|
| System Message | `Welcome to Jenkins on Kubernetes` |

#### 1.2 执行器数量
| 配置项 | 推荐值 | 说明 |
|--------|--------|------|
| # of executors | `0` | 不在 Controller 上运行任务，全部使用 Agent |

#### 1.3 Jenkins Location
| 配置项 | 示例值 |
|--------|--------|
| Jenkins URL | `http://jenkins.example.com/` |
| System Admin e-mail address | `admin@example.com` |

#### 1.4 Git 全局配置
| 配置项 | 推荐值 |
|--------|--------|
| Global Config user.name | `Jenkins` |
| Global Config user.email | `jenkins@example.com` |

---

### 2. 安全配置

**路径**: `Manage Jenkins` → `Security`

#### 2.1 Security Realm（认证方式）
选择 **Jenkins' own user database**：
| 配置项 | 推荐值 |
|--------|--------|
| Allow users to sign up | ❌ 不勾选 |

#### 2.2 Authorization（授权策略）
选择 **Logged-in users can do anything**：
| 配置项 | 推荐值 |
|--------|--------|
| Allow anonymous read access | ❌ 不勾选 |

#### 2.3 Agent → Controller Security
| 配置项 | 推荐值 |
|--------|--------|
| Enable Agent → Controller Access Control | ✅ 勾选 |

---

### 3. Kubernetes Cloud 配置（重要）

**路径**: `Manage Jenkins` → `Clouds` → `New cloud` → `Kubernetes`

#### 3.1 Kubernetes Cloud 基础配置

| 配置项 | 值 | 说明 |
|--------|-----|------|
| Name | `kubernetes` | 云名称 |
| Kubernetes URL | `https://kubernetes.default.svc.cluster.local` | 集群内部地址 |
| Kubernetes Namespace | `jenkins` | Agent 运行的命名空间 |
| Jenkins URL | `http://jenkins-service:8080` | Controller 服务地址 |
| Jenkins tunnel | `jenkins-agent-service:50000` | Agent 连接地址 |
| Container Cap | `100` | 最大并发 Pod 数 |
| Max connections to Kubernetes API | `64` | API 最大连接数 |
| Connection Timeout | `10` | 连接超时（秒） |
| Read Timeout | `20` | 读取超时（秒） |

#### 3.2 Pod Template - Default Agent

点击 **"Add Pod Template"** 添加以下模板：

**基础配置**：
| 配置项 | 值 |
|--------|-----|
| Name | `default-agent` |
| Labels | `jenkins-agent` |
| Usage | `Use this node as much as possible` |
| Idle minutes | `30` |
| Active deadline | `3600` |

**Container - jnlp**：
| 配置项 | 值 |
|--------|-----|
| Name | `jnlp` |
| Docker image | `jenkins/inbound-agent:latest` |
| Working directory | `/home/jenkins/agent` |
| Allocate pseudo-TTY | ✅ |
| Request CPU | `200m` |
| Request Memory | `256Mi` |
| Limit CPU | `1000m` |
| Limit Memory | `1Gi` |

#### 3.3 Pod Template - Maven Agent

**基础配置**：
| 配置项 | 值 |
|--------|-----|
| Name | `maven-agent` |
| Labels | `maven` |
| Usage | `Only build jobs with label expressions matching this node` |
| Idle minutes | `60` |
| Active deadline | `7200` |

**Container 1 - jnlp**：
| 配置项 | 值 |
|--------|-----|
| Name | `jnlp` |
| Docker image | `jenkins/inbound-agent:latest` |
| Working directory | `/home/jenkins/agent` |
| Allocate pseudo-TTY | ✅ |
| Request CPU | `100m` |
| Request Memory | `256Mi` |

**Container 2 - maven**：
| 配置项 | 值 |
|--------|-----|
| Name | `maven` |
| Docker image | `maven:3.9-eclipse-temurin-17` |
| Working directory | `/home/jenkins/agent` |
| Allocate pseudo-TTY | ✅ |
| Command to run | `sleep` |
| Arguments | `infinity` |
| Request CPU | `500m` |
| Request Memory | `1Gi` |
| Limit CPU | `2000m` |
| Limit Memory | `4Gi` |

**Volume（可选）**：
| 类型 | 配置 |
|------|------|
| Persistent Volume Claim | Claim: `maven-repo-pvc`, Mount path: `/root/.m2/repository` |

#### 3.4 Pod Template - Node.js Agent

**基础配置**：
| 配置项 | 值 |
|--------|-----|
| Name | `nodejs-agent` |
| Labels | `nodejs node` |
| Usage | `Only build jobs with label expressions matching this node` |
| Idle minutes | `30` |
| Active deadline | `3600` |

**Container 1 - jnlp**：
| 配置项 | 值 |
|--------|-----|
| Name | `jnlp` |
| Docker image | `jenkins/inbound-agent:latest` |
| Working directory | `/home/jenkins/agent` |
| Allocate pseudo-TTY | ✅ |
| Request CPU | `100m` |
| Request Memory | `256Mi` |

**Container 2 - nodejs**：
| 配置项 | 值 |
|--------|-----|
| Name | `nodejs` |
| Docker image | `node:20-alpine` |
| Working directory | `/home/jenkins/agent` |
| Allocate pseudo-TTY | ✅ |
| Command to run | `sleep` |
| Arguments | `infinity` |
| Request CPU | `500m` |
| Request Memory | `512Mi` |
| Limit CPU | `2000m` |
| Limit Memory | `2Gi` |

#### 3.5 Pod Template - Python Agent

**基础配置**：
| 配置项 | 值 |
|--------|-----|
| Name | `python-agent` |
| Labels | `python python3` |
| Usage | `Only build jobs with label expressions matching this node` |
| Idle minutes | `30` |
| Active deadline | `3600` |

**Container 1 - jnlp**：
| 配置项 | 值 |
|--------|-----|
| Name | `jnlp` |
| Docker image | `jenkins/inbound-agent:latest` |
| Working directory | `/home/jenkins/agent` |
| Allocate pseudo-TTY | ✅ |
| Request CPU | `100m` |
| Request Memory | `256Mi` |

**Container 2 - python**：
| 配置项 | 值 |
|--------|-----|
| Name | `python` |
| Docker image | `python:3.12-slim` |
| Working directory | `/home/jenkins/agent` |
| Allocate pseudo-TTY | ✅ |
| Command to run | `sleep` |
| Arguments | `infinity` |
| Request CPU | `500m` |
| Request Memory | `512Mi` |
| Limit CPU | `2000m` |
| Limit Memory | `2Gi` |

**Volume（可选）**：
| 类型 | 配置 |
|------|------|
| Persistent Volume Claim | Claim: `pip-cache-pvc`, Mount path: `/root/.cache/pip` |

#### 3.6 Pod Template - Python Data Science Agent

**基础配置**：
| 配置项 | 值 |
|--------|-----|
| Name | `python-ds-agent` |
| Labels | `python-ds datascience ml` |
| Usage | `Only build jobs with label expressions matching this node` |
| Idle minutes | `60` |
| Active deadline | `7200` |

**Container 1 - jnlp**：
| 配置项 | 值 |
|--------|-----|
| Name | `jnlp` |
| Docker image | `jenkins/inbound-agent:latest` |
| Working directory | `/home/jenkins/agent` |
| Allocate pseudo-TTY | ✅ |
| Request CPU | `100m` |
| Request Memory | `256Mi` |

**Container 2 - python-ds**：
| 配置项 | 值 |
|--------|-----|
| Name | `python-ds` |
| Docker image | `python:3.12` |
| Working directory | `/home/jenkins/agent` |
| Allocate pseudo-TTY | ✅ |
| Command to run | `sleep` |
| Arguments | `infinity` |
| Request CPU | `1000m` |
| Request Memory | `2Gi` |
| Limit CPU | `4000m` |
| Limit Memory | `8Gi` |

> **说明**：使用完整的 `python:3.12` 镜像（非 slim），便于安装 numpy、pandas、scikit-learn 等需要编译的库。

**Volume（可选）**：
| 类型 | 配置 |
|------|------|
| Persistent Volume Claim | Claim: `pip-cache-pvc`, Mount path: `/root/.cache/pip` |

#### 3.7 Pod Template - Docker Agent

**基础配置**：
| 配置项 | 值 |
|--------|-----|
| Name | `docker-agent` |
| Labels | `docker dind` |
| Usage | `Only build jobs with label expressions matching this node` |
| Idle minutes | `30` |
| Active deadline | `7200` |

**Container 1 - jnlp**：
| 配置项 | 值 |
|--------|-----|
| Name | `jnlp` |
| Docker image | `jenkins/inbound-agent:latest` |
| Working directory | `/home/jenkins/agent` |
| Allocate pseudo-TTY | ✅ |
| Request CPU | `100m` |
| Request Memory | `256Mi` |

**Container 2 - docker**：
| 配置项 | 值 |
|--------|-----|
| Name | `docker` |
| Docker image | `docker:24-dind` |
| Working directory | `/home/jenkins/agent` |
| Allocate pseudo-TTY | ✅ |
| Run in privileged mode | ✅ |
| Request CPU | `500m` |
| Request Memory | `1Gi` |
| Limit CPU | `2000m` |
| Limit Memory | `4Gi` |

**Environment Variable**：
| Key | Value |
|-----|-------|
| DOCKER_TLS_CERTDIR | （留空） |

**Volume**：
| 类型 | 配置 |
|------|------|
| Empty Dir Volume | Mount path: `/var/lib/docker` |

---

### 4. 全局工具配置

**路径**: `Manage Jenkins` → `Tools`

#### 4.1 Git
| 配置项 | 值 |
|--------|-----|
| Name | `Default` |
| Path to Git executable | `git` |

#### 4.2 JDK（可选）
| 配置项 | 值 |
|--------|-----|
| Name | `JDK17` |
| JAVA_HOME | `/opt/java/openjdk` |

#### 4.3 Maven（可选）
| 配置项 | 值 |
|--------|-----|
| Name | `Maven3` |
| MAVEN_HOME | `/opt/maven` |

---

### 5. 插件管理

**路径**: `Manage Jenkins` → `Plugins`

#### 推荐安装的插件

| 插件名称 | 用途 |
|---------|------|
| Kubernetes | Kubernetes 动态 Agent |
| Pipeline | Pipeline 支持 |
| Git | Git 集成 |
| GitHub | GitHub 集成 |
| GitHub Branch Source | GitHub 多分支 Pipeline |
| Credentials Binding | 凭据绑定 |
| Timestamper | 构建时间戳 |
| Workspace Cleanup | 工作空间清理 |
| Pipeline Stage View | Pipeline 阶段视图 |
| Blue Ocean | 现代化 UI |
| Docker Pipeline | Docker 支持 |
| Matrix Authorization Strategy | 矩阵授权 |
| Build Timeout | 构建超时 |
| Email Extension | 邮件通知 |
| SSH Agent | SSH 代理 |
| Pipeline Utility Steps | Pipeline 工具步骤 |
| Job DSL | Job DSL 支持 |
| Locale | 语言本地化 |

---

## 📝 Pipeline 示例

### 使用 Maven Agent

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

### 使用 Node.js Agent

```groovy
pipeline {
    agent {
        kubernetes {
            label 'nodejs'
        }
    }
    stages {
        stage('Build') {
            steps {
                container('nodejs') {
                    sh 'npm install'
                    sh 'npm run build'
                }
            }
        }
    }
}
```

### 使用 Docker Agent

```groovy
pipeline {
    agent {
        kubernetes {
            label 'docker'
        }
    }
    stages {
        stage('Build Image') {
            steps {
                container('docker') {
                    sh 'docker build -t myapp:latest .'
                }
            }
        }
    }
}
```

### 使用 Python Agent

```groovy
pipeline {
    agent {
        kubernetes {
            label 'python'
        }
    }
    stages {
        stage('Setup') {
            steps {
                container('python') {
                    sh 'pip install -r requirements.txt'
                }
            }
        }
        stage('Test') {
            steps {
                container('python') {
                    sh 'python -m pytest tests/ -v'
                }
            }
        }
        stage('Lint') {
            steps {
                container('python') {
                    sh 'pip install flake8'
                    sh 'flake8 src/ --count --select=E9,F63,F7,F82 --show-source --statistics'
                }
            }
        }
    }
}
```

### 使用 Python Data Science Agent

```groovy
pipeline {
    agent {
        kubernetes {
            label 'python-ds'
        }
    }
    stages {
        stage('Setup') {
            steps {
                container('python-ds') {
                    sh '''
                        pip install numpy pandas scikit-learn matplotlib
                        pip install -r requirements.txt
                    '''
                }
            }
        }
        stage('Train Model') {
            steps {
                container('python-ds') {
                    sh 'python train.py'
                }
            }
        }
        stage('Evaluate') {
            steps {
                container('python-ds') {
                    sh 'python evaluate.py'
                }
            }
        }
    }
}
```

### 完整 Python CI/CD Pipeline 示例

```groovy
pipeline {
    agent {
        kubernetes {
            label 'python'
        }
    }
    
    environment {
        PYTHONDONTWRITEBYTECODE = '1'
        PYTHONUNBUFFERED = '1'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup Virtual Environment') {
            steps {
                container('python') {
                    sh '''
                        python -m venv venv
                        . venv/bin/activate
                        pip install --upgrade pip
                        pip install -r requirements.txt
                        pip install pytest pytest-cov flake8 black
                    '''
                }
            }
        }
        
        stage('Code Quality') {
            parallel {
                stage('Lint') {
                    steps {
                        container('python') {
                            sh '''
                                . venv/bin/activate
                                flake8 src/ tests/ --max-line-length=120
                            '''
                        }
                    }
                }
                stage('Format Check') {
                    steps {
                        container('python') {
                            sh '''
                                . venv/bin/activate
                                black --check src/ tests/
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Unit Tests') {
            steps {
                container('python') {
                    sh '''
                        . venv/bin/activate
                        pytest tests/ -v --cov=src --cov-report=xml --cov-report=html
                    '''
                }
            }
            post {
                always {
                    publishHTML(target: [
                        reportDir: 'htmlcov',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
            }
        }
        
        stage('Build Package') {
            steps {
                container('python') {
                    sh '''
                        . venv/bin/activate
                        pip install build
                        python -m build
                    '''
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
```

---

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

---

## 🔐 安全最佳实践

1. **创建管理员账户后删除初始密码文件**
2. **启用 HTTPS**，配置有效的 TLS 证书
3. **限制 RBAC 权限**，仅授予必要的权限
4. **定期更新** Jenkins 和插件版本
5. **启用审计日志** 记录用户操作
6. **配置备份策略** 保护 Jenkins 数据

---

## 🔄 升级指南

```bash
# 1. 备份数据
kubectl exec -n jenkins deployment/jenkins-controller -- tar czf /tmp/backup.tar.gz /var/jenkins_home

# 2. 更新镜像版本
kubectl set image deployment/jenkins-controller jenkins=jenkins/jenkins:lts-jdk17 -n jenkins

# 3. 验证升级
kubectl rollout status deployment/jenkins-controller -n jenkins
```

---

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

---

## ❓ 常见问题

### Q: Jenkins 启动缓慢？

A: 首次启动需要下载插件，可能需要 5-10 分钟。检查启动探针配置是否足够宽松。

### Q: Agent Pod 无法连接？

A: 检查以下配置：
- `jenkins-agent-service` 是否正常运行
- Kubernetes Cloud 中的 `Jenkins tunnel` 配置是否正确
- RBAC 权限是否足够

### Q: PVC 绑定失败？

A: 确认：
- StorageClass 存在且可用
- 存储配额足够
- 访问模式与存储类兼容

### Q: 如何查看初始管理员密码？

A: 运行以下命令：
```bash
kubectl exec -n jenkins deployment/jenkins-controller -- cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## 📚 参考资料

- [Jenkins 官方文档](https://www.jenkins.io/doc/)
- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [Kubernetes 最佳实践](https://kubernetes.io/docs/concepts/configuration/overview/)
