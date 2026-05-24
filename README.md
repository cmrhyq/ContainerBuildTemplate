# ContainerBuildTemplate

容器化部署模板集合，包含 Docker Compose 和 Kubernetes 两大类常用服务的部署配置文件，开箱即用。

---

## 项目结构

```
ContainerBuildTemplate/
├── Docker/                         # Docker Compose 部署模板
│   ├── mysql/                      # MySQL 数据库
│   ├── nginx/                      # Nginx Web 服务器
│   ├── nginx proxy manager/        # Nginx 代理管理面板
│   ├── portainer/                  # Docker 可视化管理工具
│   ├── redis/                      # Redis 缓存数据库
│   ├── tomcat/                     # Tomcat 应用服务器
│   └── xxl-job/                    # XXL-JOB 分布式任务调度
│
├── Kubernetes/                     # Kubernetes 部署模板
│   ├── chromadb/                   # ChromaDB 向量数据库
│   ├── dashboard/                  # Kubernetes Dashboard
│   ├── jenkins/                    # Jenkins CI/CD（标准版）
│   ├── jenkins-lw/                 # Jenkins CI/CD（低配优化版，4C4G）
│   ├── nginx/                      # Nginx（含 HPA 自动扩缩）
│   └── system/                     # 集群系统组件（DNS、镜像清理等）
│
└── README.md
```

---

## Docker Compose 模板

### 前置条件

大部分 Compose 配置中指定了自定义网络以固定容器 IP，避免 Docker 重启后 IP 变化。使用前请先创建网络：

```bash
docker network create \
  --subnet=172.100.0.0/16 \
  --gateway=172.100.0.1 \
  --ip-range=172.100.0.0/16 \
  -d bridge \
  container-network
```

### 服务列表

| 服务 | 版本 | 说明 | 目录 |
|------|------|------|------|
| MySQL | - | 关系型数据库，含环境变量配置 | `Docker/mysql/` |
| Nginx | latest | 轻量级 Web 服务器、反向代理 | `Docker/nginx/` |
| Nginx Proxy Manager | latest | 可视化 Nginx 代理管理面板，支持 SSL 证书自动申请 | `Docker/nginx proxy manager/` |
| Portainer | latest | Docker 可视化管理界面，支持容器、镜像、网络管理 | `Docker/portainer/` |
| Redis | 7.0.11 | 高性能 Key-Value 内存数据库，含自定义 redis.conf | `Docker/redis/` |
| Tomcat | 8.5.42 | Java Web 应用服务器 | `Docker/tomcat/` |
| XXL-JOB Admin | latest | 分布式任务调度平台 - 管理端 | `Docker/xxl-job/` |
| XXL-JOB Executor | latest | 分布式任务调度平台 - 执行端 | `Docker/xxl-job/` |

### 使用方式

```bash
cd Docker/<服务目录>

# 启动服务
docker compose up -d

# 查看状态
docker compose ps

# 停止服务
docker compose down
```

---

## Kubernetes 部署模板

### 服务列表

| 服务 | 说明 | 部署方式 | 目录 |
|------|------|---------|------|
| ChromaDB | AI 向量数据库 | Kustomize | `Kubernetes/chromadb/` |
| Dashboard | Kubernetes 集群管理面板 | kubectl apply | `Kubernetes/dashboard/` |
| Jenkins | CI/CD 服务器（标准版，含完整开发工具） | Kustomize | `Kubernetes/jenkins/` |
| Jenkins LW | CI/CD 服务器（低配优化版，适用 4C4G） | Kustomize | `Kubernetes/jenkins-lw/` |
| Nginx | Web 服务器（含 HPA 自动扩缩、ConfigMap） | Kustomize | `Kubernetes/nginx/` |
| System | 集群运维组件（NodeLocal DNS、镜像清理 CronJob） | kubectl apply | `Kubernetes/system/` |

### 使用方式

```bash
cd Kubernetes/<服务目录>

# Kustomize 部署（推荐）
kubectl apply -k .

# 查看资源状态
kubectl get all -n <namespace>

# 卸载
kubectl delete -k .
```

---

## 快速导航

- [Jenkins 低配版部署指南（K3s 4C4G 优化）](Kubernetes/jenkins-lw/README.md)
- [Jenkins 标准版部署指南](Kubernetes/jenkins/README.md)
- [Nginx Kubernetes 部署指南](Kubernetes/nginx/README.md)

---

## 使用建议

- **开发/测试环境**：优先使用 Docker Compose 模板，部署简单快速
- **生产环境**：推荐使用 Kubernetes 模板，支持高可用、自动扩缩、滚动更新
- **低配服务器**（4C4G）：使用 `jenkins-lw` 版本，已针对资源限制做专项优化

---

## License

本项目仅供学习和内部使用参考。
