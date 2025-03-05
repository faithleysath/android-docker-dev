# Docker化的安卓开发环境

这是一个基于Docker容器的安卓开发环境，可以用于多个安卓项目的开发。此环境预装了JDK 17、Kotlin支持和Android SDK 31（兼容Android 12），并支持无线调试连接到真实设备。

## 环境特点

- 🐳 完全容器化，避免污染主机系统
- 🚀 支持多个项目共享同一开发环境
- 📱 支持无线调试连接到实际设备
- 🔄 缓存共享，提高构建速度
- 🛠️ 与VSCode集成，提供完整的IDE体验

## 开始使用

### 初次启动

1. 确保已安装并启动 Docker Desktop
2. 运行启动脚本：
   ```bash
   cd ~/android-docker-dev
   ./start-dev-env.sh start
   ```
3. 等待容器启动完成

### 连接到VSCode

1. 在VSCode中打开安卓项目所在目录：
   ```bash
   code ~/android-docker-dev
   ```
2. 点击VSCode左下角的绿色图标
3. 选择"在容器中重新打开"选项
4. VSCode将重新加载并连接到开发容器

### 连接安卓设备进行调试

1. 在安卓设备上启用开发者选项（在"设置"中点击"关于手机"中的"版本号"7次）
2. 启用USB调试
3. 确保手机和电脑连接到同一个WiFi网络
4. 在设备上查找IP地址（通常在"设置" > "关于手机" > "状态信息" > "IP地址"）

#### Android 11以下设备

1. 使用脚本直接连接设备：
   ```bash
   ./start-dev-env.sh connect 192.168.1.100  # 替换为您设备的IP地址
   ```

#### Android 11及以上设备（需要先配对）

1. 启用无线调试选项（在"设置" > "开发者选项" > "无线调试"）
2. 点击"使用配对码配对设备"选项
3. 记下显示的配对码和端口号
4. 使用脚本先配对设备：
   ```bash
   ./start-dev-env.sh pair 192.168.1.100 43211 123456  # 替换为您设备的IP、端口和配对码
   ```
5. 配对成功后，连接设备：
   ```bash
   ./start-dev-env.sh connect 192.168.1.100  # 使用默认端口5555连接
   ```
   
   注意：如果默认端口无法连接，您可能需要使用设备显示的特定端口（在"无线调试"界面查看）：
   ```bash
   ./start-dev-env.sh connect 192.168.1.100 37277  # 使用指定端口连接
   ```

#### Apple Silicon Mac专用连接方式

对于Apple Silicon Mac (M1/M2/M3)用户，如果在容器内配对和连接设备出现问题（例如看到 "rosetta error" 错误），可以尝试使用以下方法在主机上进行配对和连接：

1. 首先确保主机上已安装ADB工具：
   ```bash
   brew install android-platform-tools
   ```

2. 对于Android 11及以上设备，在主机上进行配对：
   ```bash
   ./start-dev-env.sh host-pair 192.168.1.100 43211 123456  # 替换为您设备的IP、端口和配对码
   ```

3. 然后在主机上连接设备：
   ```bash
   ./start-dev-env.sh host-connect 192.168.1.100  # 使用默认端口5555
   # 或者
   ./start-dev-env.sh host-connect 192.168.1.100 37277  # 使用指定端口
   ```

4. 连接成功后，您可以在容器内部使用ADB命令，设备连接由主机和容器共享。

## 项目管理

### 创建新项目

1. 在容器内打开终端（VSCode终端或使用`./start-dev-env.sh shell`）
2. 导航到projects目录：`cd /home/developer/projects`
3. 创建新项目：
   ```bash
   # 使用Android Studio命令行工具创建新项目
   kotlin -cp $ANDROID_HOME/cmdline-tools/latest/lib/kotlin-stdlib.jar:$ANDROID_HOME/cmdline-tools/latest/lib/kotlin-reflect.jar:$ANDROID_HOME/cmdline-tools/latest/lib/* com.android.tools.idea.wizard.template.impl.projects.NewAndroidProjectKt
   
   # 或者使用gradle
   gradle init --type kotlin-application
   ```

### 导入现有项目

只需将项目文件放到`~/android-docker-dev/projects/`目录下，然后在VSCode中打开。

## 常用命令

- 启动环境：`./start-dev-env.sh start`
- 停止环境：`./start-dev-env.sh stop`
- 查看状态：`./start-dev-env.sh status`
- 配对设备：`./start-dev-env.sh pair 设备IP 配对端口 配对码`（Android 11+）
- 连接设备：`./start-dev-env.sh connect 设备IP [端口]`
- 进入容器命令行：`./start-dev-env.sh shell`
- 重建容器：`./start-dev-env.sh build`
- 显示帮助：`./start-dev-env.sh help`

### Apple Silicon Mac专用命令

- 在主机上配对设备：`./start-dev-env.sh host-pair 设备IP 配对端口 配对码`
- 在主机上连接设备：`./start-dev-env.sh host-connect 设备IP [端口]`

## 文件结构

```
android-docker-dev/
├── docker/                 # Docker相关配置
│   ├── Dockerfile          # 容器定义
│   └── docker-compose.yml  # 容器编排配置
├── .devcontainer/          # VSCode容器开发配置
│   └── devcontainer.json   # VSCode集成配置
├── projects/               # 项目目录（可包含多个项目）
│   ├── project1/           # 示例项目1
│   └── project2/           # 示例项目2
├── start-dev-env.sh        # 环境管理脚本
└── README.md               # 说明文档
```

## 故障排除

### 连接设备失败

1. 确保设备和电脑在同一WiFi网络
2. 检查安卓设备的IP地址是否正确
3. 确保已在设备上启用开发者选项和USB调试
4. 对于Android 11+：
   - 确保已启用无线调试选项
   - 确保已使用 `pair` 命令正确配对设备
   - 配对码仅在短时间内有效，如果配对失败，请重新获取新的配对码
5. 在设备上接受调试连接提示
6. 重启ADB服务器：
   ```bash
   ./start-dev-env.sh shell
   adb kill-server
   adb start-server
   ```
7. 对于 Apple Silicon Mac (M1/M2/M3)：
   - 如果您看到类似 `rosetta error: failed to open elf at /lib64/ld-linux-x86-64.so.2` 的错误，这是由于在 ARM 架构上运行 x86_64 容器导致的
   - 在某些情况下这些错误可能导致配对和连接功能无法正常工作
   - 如果出现连接问题，请使用 `host-pair` 和 `host-connect` 命令在主机上直接配对和连接设备
   - 确保您的主机上已安装ADB工具（可通过 `brew install android-platform-tools` 安装）
   - 如果仍有问题，请尝试重启 Docker Desktop 或者重启电脑

### 容器无法启动

1. 确保Docker Desktop正在运行
2. 检查错误信息：`docker-compose logs`
3. 尝试重建容器：`./start-dev-env.sh build`
