# 基础镜像：官方Jenkins LTS（基于Debian系统，兼容性更好）
FROM jenkins/jenkins:lts

# 切换到root用户，用于安装系统依赖和各类工具（Jenkins默认jenkins用户无管理员权限）
USER root

# 环境变量配置（指定Java安装目录、Nodejs版本、Allure版本，便于后续维护）
ENV JAVA17_HOME=/usr/local/java17
ENV JAVA21_HOME=/usr/local/java21
ENV NODE_VERSION=20.19.0
ENV ALLURE_VERSION=2.24.1
ENV ALLURE_HOME=/usr/local/allure
# 配置全局PATH，让系统识别所有工具的可执行命令
ENV PATH=$JAVA17_HOME/bin:$JAVA21_HOME/bin:$PATH:/usr/local/python3.12/bin:/usr/local/nodejs/bin:$ALLURE_HOME/bin

# 第一步：安装系统依赖（编译工具、依赖库、解压工具等，为后续安装提供支持）
RUN apt update && apt upgrade -y && \
    apt install -y --no-install-recommends \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libffi-dev \
    wget \
    curl \
    llvm \
    libbz2-dev \
    unzip \
    ca-certificates && \
    # 清理apt缓存，减小镜像体积
    rm -rf /var/lib/apt/lists/*

# 第二步：安装Python 3.12（源码编译方式，稳定可靠，避免系统自带版本冲突）
RUN wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz && \
    tar -zxvf Python-3.12.0.tgz && \
    cd Python-3.12.0 && \
    # 配置编译参数，开启优化，指定安装路径
    ./configure --enable-optimizations --prefix=/usr/local/python3.12 && \
    # 多核编译，加快安装速度
    make -j$(nproc) && \
    make install && \
    # 清理源码包和编译目录，减小镜像体积
    cd / && \
    rm -rf Python-3.12.0.tgz Python-3.12.0 && \
    # 创建软链接，方便直接使用python3.12和pip3.12命令
    ln -s /usr/local/python3.12/bin/python3.12 /usr/bin/python3.12 && \
    ln -s /usr/local/python3.12/bin/pip3.12 /usr/bin/pip3.12

# 第三步：安装Java 17（Eclipse Temurin版，开源稳定，适配Jenkins和测试工具）
RUN wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.9%2B9/OpenJDK17U-jdk_x64_linux_hotspot_17.0.9_9.tar.gz && \
    # 创建Java 17安装目录
    mkdir -p $JAVA17_HOME && \
    # 解压到指定目录
    tar -zxvf OpenJDK17U-jdk_x64_linux_hotspot_17.0.9_9.tar.gz --strip-components=1 -C $JAVA17_HOME && \
    # 清理压缩包
    rm -rf OpenJDK17U-jdk_x64_linux_hotspot_17.0.9_9.tar.gz && \
    # 配置Java 17软链接（可选，便于切换默认Java版本）
    ln -s $JAVA17_HOME/bin/java /usr/bin/java17 && \
    ln -s $JAVA17_HOME/bin/javac /usr/bin/javac17

# 第四步：安装Java 21（Eclipse Temurin版，与Java17目录分离，互不冲突）
RUN wget https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.1%2B12/OpenJDK21U-jdk_x64_linux_hotspot_21.0.1_12.tar.gz && \
    # 创建Java 21安装目录
    mkdir -p $JAVA21_HOME && \
    # 解压到指定目录
    tar -zxvf OpenJDK21U-jdk_x64_linux_hotspot_21.0.1_12.tar.gz --strip-components=1 -C $JAVA21_HOME && \
    # 清理压缩包
    rm -rf OpenJDK21U-jdk_x64_linux_hotspot_21.0.1_12.tar.gz && \
    # 配置Java 21软链接（可选，便于切换默认Java版本）
    ln -s $JAVA21_HOME/bin/java /usr/bin/java21 && \
    ln -s $JAVA21_HOME/bin/javac /usr/bin/javac21

# 第五步：安装Node.js 20.19.0（官方二进制包，无需编译，快速安装）
RUN wget https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz && \
    # 创建Nodejs安装目录
    mkdir -p /usr/local/nodejs && \
    # 解压到指定目录
    tar -xJvf node-v$NODE_VERSION-linux-x64.tar.xz --strip-components=1 -C /usr/local/nodejs && \
    # 清理压缩包
    rm -rf node-v$NODE_VERSION-linux-x64.tar.xz && \
    # 创建软链接，系统全局可调用node和npm
    ln -s /usr/local/nodejs/bin/node /usr/bin/node && \
    ln -s /usr/local/nodejs/bin/npm /usr/bin/npm && \
    ln -s /usr/local/nodejs/bin/npx /usr/bin/npx && \
    # 验证npm并升级到最新版（可选）
    npm install -g npm@latest

# 第六步：安装Allure测试报告工具（2.24.1稳定版）
RUN wget https://repo.maven.apache.org/maven2/io/qameta/allure/allure-commandline/$ALLURE_VERSION/allure-commandline-$ALLURE_VERSION.zip && \
    # 创建Allure安装目录
    mkdir -p $ALLURE_HOME && \
    # 解压到指定目录
    unzip allure-commandline-$ALLURE_VERSION.zip -d /usr/local && \
    # 移动解压后的文件到ALLURE_HOME
    mv /usr/local/allure-$ALLURE_VERSION/* $ALLURE_HOME && \
    # 清理压缩包和临时目录
    rm -rf allure-commandline-$ALLURE_VERSION.zip /usr/local/allure-$ALLURE_VERSION && \
    # 创建软链接，系统全局可调用allure命令
    ln -s $ALLURE_HOME/bin/allure /usr/bin/allure

# 修复文件权限（确保jenkins用户可访问所有安装的工具目录）
RUN chown -R jenkins:jenkins \
    /usr/local/python3.12 \
    $JAVA17_HOME \
    $JAVA21_HOME \
    /usr/local/nodejs \
    $ALLURE_HOME \
    /var/jenkins_home

# 切换回jenkins用户（遵循Jenkins官方最佳实践，避免权限过大带来的安全风险）
USER jenkins

# 镜像标签说明（可选，便于识别镜像内容）
LABEL maintainer="自定义维护者信息" \
      description="Jenkins LTS镜像，内置Python3.12、Java17、Java21、Nodejs20.19、Allure2.24.1" \
      version="1.0"