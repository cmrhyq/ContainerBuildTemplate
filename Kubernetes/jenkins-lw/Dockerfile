# Jenkins 自定义镜像 - 内置 Python、Maven、Allure、Go 环境
# 适用于 4核4G 低配置服务器

FROM jenkins/jenkins:lts-jdk17

# 切换到 root 用户安装工具
USER root

# 环境变量配置
ENV MAVEN_VERSION=3.9.6
ENV MAVEN_HOME=/opt/maven
ENV ALLURE_VERSION=2.24.1
ENV ALLURE_HOME=/opt/allure
ENV GO_VERSION=1.22.0
ENV GOROOT=/usr/local/go
ENV GOPATH=/var/jenkins_home/go
ENV PYTHON_VERSION=3.12

# 配置 PATH
ENV PATH="${MAVEN_HOME}/bin:${ALLURE_HOME}/bin:${GOROOT}/bin:${GOPATH}/bin:${PATH}"

# 安装系统依赖和 Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    unzip \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 创建 python3 软链接
RUN ln -sf /usr/bin/python3 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip

# 安装常用 Python 包
RUN pip3 install --no-cache-dir --break-system-packages \
    pytest \
    pytest-html \
    requests \
    pyyaml \
    allure-pytest

# 安装 Maven
RUN wget -q https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -O /tmp/maven.tar.gz && \
    mkdir -p ${MAVEN_HOME} && \
    tar -xzf /tmp/maven.tar.gz -C ${MAVEN_HOME} --strip-components=1 && \
    rm -f /tmp/maven.tar.gz && \
    # 验证安装
    mvn --version

# 安装 Allure
RUN wget -q https://github.com/allure-framework/allure2/releases/download/${ALLURE_VERSION}/allure-${ALLURE_VERSION}.zip -O /tmp/allure.zip && \
    mkdir -p ${ALLURE_HOME} && \
    unzip -q /tmp/allure.zip -d /opt && \
    mv /opt/allure-${ALLURE_VERSION}/* ${ALLURE_HOME} && \
    rmdir /opt/allure-${ALLURE_VERSION} && \
    rm -f /tmp/allure.zip && \
    # 验证安装
    allure --version

# 安装 Go
RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz && \
    tar -xzf /tmp/go.tar.gz -C /usr/local && \
    rm -f /tmp/go.tar.gz && \
    # 创建 GOPATH 目录
    mkdir -p ${GOPATH}/src ${GOPATH}/bin ${GOPATH}/pkg && \
    # 验证安装
    go version

# 修复权限
RUN chown -R jenkins:jenkins ${MAVEN_HOME} ${ALLURE_HOME} && \
    chmod -R 755 ${MAVEN_HOME} ${ALLURE_HOME} ${GOROOT}

# 切换回 jenkins 用户
USER jenkins

# 设置工作目录
WORKDIR /var/jenkins_home

# 镜像标签
LABEL maintainer="DevOps Team" \
      description="Jenkins LTS with Python3, Maven, Allure, Go" \
      jenkins.version="lts-jdk17" \
      python.version="${PYTHON_VERSION}" \
      maven.version="${MAVEN_VERSION}" \
      allure.version="${ALLURE_VERSION}" \
      go.version="${GO_VERSION}"
