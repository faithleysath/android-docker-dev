# 使用Ubuntu作为基础镜像
FROM ubuntu:22.04

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 安装必要的工具
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    openjdk-17-jdk \
    wget \
    sudo \
    vim \
    openssh-client \
    locales \
    xz-utils \
    apt-utils \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 设置环境变量
ENV ANDROID_HOME /opt/android-sdk
ENV PATH ${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

# 创建目录
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools

# 下载Android命令行工具
RUN cd ${ANDROID_HOME}/cmdline-tools \
    && wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip \
    && unzip commandlinetools-linux-*_latest.zip \
    && rm commandlinetools-linux-*_latest.zip \
    && mkdir -p latest \
    && mv cmdline-tools/* latest/ || true

# 设置语言环境
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# 接受许可并安装必要的SDK组件
RUN yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --licenses
RUN ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-31" "build-tools;31.0.0" "extras;android;m2repository" "extras;google;m2repository"

# 添加普通用户
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# 切换到非root用户
USER $USERNAME
WORKDIR /home/$USERNAME/projects

# 为无线调试设置ADB服务
EXPOSE 5037
