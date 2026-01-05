# DockerComposeTemplate
常用的docker的docker-compose模板



## 注意

1. 其中大部分容器的compose代码中都指定了networks，这项配置能够解决容器在docker重启后，容器ip地址改变的问题，若要使用此项配置，请提前运行以下命令

```shell
docker network create --subnet=172.100.0.0/16 --gateway=172.100.0.1 --ip-range=172.100.0.0/16 -d bridge container-network
```





## 列表

| 名称                | 版本   | 备注                                                         |
| ------------------- | ------ | ------------------------------------------------------------ |
| Nginx               | latest | *Nginx是*一款轻量级的Web服务器、反向代理服务器，由于它的内存占用少，启动极快，高并发能力强，在互联网项目中广泛应用。 |
| Tomcat              | 8.5.42 | *Tomcat*服务器是一个免费的开放源代码的Web应用服务器，属于轻量级应用服务器，在中小型系统和并发访问用户不是很多的场合下被普遍使用。 |
| Portainer           | latest | Portainer 是一个可视化的Docker 操作界面，提供状态显示面板、应用模板快速部署、容器镜像网络数据卷的基本操作...等功能。 |
| Redis               | 7.0.11 | Redis是一个开源的使用ANSI C语言编写、支持网络、可基于内存亦可持久化的日志型、Key-Value数据库，并提供多种语言的API。 |
| nginx proxy manager | latest | 一个基于Docker 的工具，提供简单而强大的界面来管理Nginx 代理主机。 |
| xxl-job-admin       | latest | XXL-JOB是一个分布式任务调度平台，admin是它的管理端           |
| xxl-job-executor    | latest | XXL-JOB是一个分布式任务调度平台，executor是它的执行端        |

