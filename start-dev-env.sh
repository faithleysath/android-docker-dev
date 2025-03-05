#!/bin/bash

# 切换到项目根目录
cd "$(dirname "$0")"

# 颜色变量
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 检测是否为Apple Silicon Mac
is_apple_silicon() {
  if [[ "$(uname)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
    return 0 # true
  else
    return 1 # false
  fi
}

# 显示帮助信息
show_help() {
  echo -e "${YELLOW}安卓开发环境管理脚本${NC}"
  echo "用法: $0 [命令]"
  echo ""
  echo "命令:"
  echo "  start          启动开发环境容器"
  echo "  stop           停止开发环境容器"
  echo "  status         查看容器状态"
  echo "  pair           配对安卓设备 (需要设备IP地址和配对端口及配对码)"
  echo "  connect        连接到安卓设备 (需要设备IP地址，可选端口号)"
  echo "  host-pair      在主机上配对安卓设备 (Apple Silicon Mac专用)"
  echo "  host-connect   在主机上连接安卓设备 (Apple Silicon Mac专用)"
  echo "  shell          进入容器命令行"
  echo "  build          重新构建容器"
  echo "  help           显示此帮助信息"
  echo ""
  echo "示例:"
  echo "  $0 start"
  echo "  $0 pair 192.168.1.100 43211 123456    # 配对设备 (Android 11+)"
  echo "  $0 connect 192.168.1.100              # 使用默认端口5555连接设备"
  echo "  $0 connect 192.168.1.100 37277        # 使用指定端口连接设备"
  
  if is_apple_silicon; then
    echo -e ""
    echo -e "${BLUE}Apple Silicon Mac专用命令:${NC}"
    echo "  $0 host-pair 192.168.1.100 43211 123456    # 在主机上配对设备"
    echo "  $0 host-connect 192.168.1.100 [端口]        # 在主机上连接设备"
  fi
}

# 检查 Docker 是否运行
check_docker() {
  if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}错误: Docker 未运行。请先启动 Docker Desktop。${NC}"
    exit 1
  fi
}

# 启动开发环境
start_env() {
  check_docker
  echo -e "${GREEN}启动安卓开发环境...${NC}"
  cd docker && docker-compose up -d
  echo -e "${GREEN}✓ 开发环境已启动${NC}"
  echo -e "您可以:"
  echo -e "  • 在 VSCode 中打开项目文件夹，点击左下角绿色图标，然后选择 '${YELLOW}在容器中重新打开${NC}'"
  echo -e "  • 使用 '${YELLOW}$0 shell${NC}' 进入容器命令行"
  echo -e "  • 使用 '${YELLOW}$0 connect [设备IP]${NC}' 连接到安卓设备"
}

# 停止开发环境
stop_env() {
  check_docker
  echo -e "${GREEN}停止安卓开发环境...${NC}"
  cd docker && docker-compose down
  echo -e "${GREEN}✓ 开发环境已停止${NC}"
}

# 查看容器状态
check_status() {
  check_docker
  echo -e "${GREEN}容器状态:${NC}"
  docker ps --filter "name=android-development" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# 配对安卓设备 (针对Android 11及以上版本)
pair_device() {
  check_docker
  if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo -e "${RED}错误: 请提供设备IP地址、配对端口和配对码${NC}"
    echo -e "用法: $0 pair 192.168.1.100 43211 123456"
    exit 1
  fi
  
  echo -e "${GREEN}正在配对IP为 $1 端口为 $2 的安卓设备...${NC}"
  echo -e "${YELLOW}请确保:${NC}"
  echo -e " 1. 设备已启用开发者选项"
  echo -e " 2. 已启用USB调试"
  echo -e " 3. 设备与电脑在同一Wi-Fi网络"
  echo -e " 4. 在设备上已启用无线调试 (设置 > 系统 > 开发者选项 > 无线调试)"
  echo -e " 5. 已从设备上的无线调试菜单中获取配对码和配对端口"
  
  docker exec -it android-development adb start-server
  docker exec -it android-development adb pair $1:$2 $3
  
  echo -e "${GREEN}配对完成后，请使用 '$0 connect $1' 连接设备${NC}"
  
  # 添加关于Rosetta错误的说明
  echo -e "${YELLOW}注意: 如果您看到 'rosetta error' 相关信息，通常这不影响配对功能，可继续进行连接操作。${NC}"
}

# 连接到安卓设备
connect_device() {
  check_docker
  if [ -z "$1" ]; then
    echo -e "${RED}错误: 请提供设备IP地址${NC}"
    echo -e "用法: $0 connect 192.168.1.100 [端口]"
    exit 1
  fi
  
  # 设置端口，如果未提供则默认为5555
  PORT=${2:-5555}
  
  echo -e "${GREEN}连接到IP为 $1 端口为 $PORT 的安卓设备...${NC}"
  echo -e "${YELLOW}请确保:${NC}"
  echo -e " 1. 设备已启用开发者选项"
  echo -e " 2. 已启用USB调试"
  echo -e " 3. 设备与电脑在同一Wi-Fi网络"
  echo -e " 4. 在设备上已启用无线调试 (Android 11以上)"
  echo -e " 5. 如果是Android 11及以上设备，已使用 '$0 pair' 完成配对"
  
  docker exec -it android-development adb start-server
  docker exec -it android-development adb connect $1:$PORT
  
  echo -e "${GREEN}执行 'docker exec -it android-development adb devices' 检查设备是否已连接${NC}"
  
  # 添加关于Rosetta错误的说明
  echo -e "${YELLOW}注意: 如果您看到 'rosetta error' 相关信息，通常这不影响连接功能。${NC}"
}

# 进入容器命令行
enter_shell() {
  check_docker
  echo -e "${GREEN}进入开发环境容器...${NC}"
  docker exec -it android-development bash
}

# 重新构建容器
rebuild_container() {
  check_docker
  echo -e "${GREEN}重新构建安卓开发环境...${NC}"
  cd docker && docker-compose build --no-cache
  echo -e "${GREEN}✓ 重建完成${NC}"
}

# 在主机上配对设备 (针对Apple Silicon Mac)
host_pair_device() {
  if ! is_apple_silicon; then
    echo -e "${RED}此命令仅适用于Apple Silicon Mac${NC}"
    exit 1
  fi
  
  if ! command -v adb &> /dev/null; then
    echo -e "${RED}错误: 主机上未安装ADB工具${NC}"
    echo -e "请通过Homebrew安装ADB: ${YELLOW}brew install android-platform-tools${NC}"
    exit 1
  fi
  
  if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo -e "${RED}错误: 请提供设备IP地址、配对端口和配对码${NC}"
    echo -e "用法: $0 host-pair 192.168.1.100 43211 123456"
    exit 1
  fi
  
  echo -e "${GREEN}在主机上配对IP为 $1 端口为 $2 的安卓设备...${NC}"
  echo -e "${YELLOW}请确保:${NC}"
  echo -e " 1. 设备已启用开发者选项"
  echo -e " 2. 已启用USB调试"
  echo -e " 3. 设备与电脑在同一Wi-Fi网络"
  echo -e " 4. 在设备上已启用无线调试 (设置 > 系统 > 开发者选项 > 无线调试)"
  echo -e " 5. 已从设备上的无线调试菜单中获取配对码和配对端口"
  
  adb start-server
  adb pair $1:$2 $3
  
  echo -e "${GREEN}配对完成后，请使用 '$0 host-connect $1' 连接设备${NC}"
}

# 在主机上连接设备 (针对Apple Silicon Mac)
host_connect_device() {
  if ! is_apple_silicon; then
    echo -e "${RED}此命令仅适用于Apple Silicon Mac${NC}"
    exit 1
  fi
  
  if ! command -v adb &> /dev/null; then
    echo -e "${RED}错误: 主机上未安装ADB工具${NC}"
    echo -e "请通过Homebrew安装ADB: ${YELLOW}brew install android-platform-tools${NC}"
    exit 1
  fi
  
  if [ -z "$1" ]; then
    echo -e "${RED}错误: 请提供设备IP地址${NC}"
    echo -e "用法: $0 host-connect 192.168.1.100 [端口]"
    exit 1
  fi
  
  # 设置端口，如果未提供则默认为5555
  PORT=${2:-5555}
  
  echo -e "${GREEN}在主机上连接到IP为 $1 端口为 $PORT 的安卓设备...${NC}"
  echo -e "${YELLOW}请确保:${NC}"
  echo -e " 1. 设备已启用开发者选项"
  echo -e " 2. 已启用USB调试"
  echo -e " 3. 设备与电脑在同一Wi-Fi网络"
  echo -e " 4. 在设备上已启用无线调试 (Android 11以上)"
  echo -e " 5. 如果是Android 11及以上设备，已使用 '$0 host-pair' 完成配对"
  
  adb start-server
  adb connect $1:$PORT
  
  echo -e "${GREEN}连接后，您可以在容器内部使用ADB命令。您的设备连接到了主机，但容器可共享此连接。${NC}"
  echo -e "${GREEN}执行 'adb devices' 检查设备是否已连接${NC}"
}

# 主函数
main() {
  case "$1" in
    start)
      start_env
      ;;
    stop)
      stop_env
      ;;
    status)
      check_status
      ;;
    pair)
      pair_device "$2" "$3" "$4"
      ;;
    connect)
      connect_device "$2" "$3"
      ;;
    host-pair)
      host_pair_device "$2" "$3" "$4"
      ;;
    host-connect)
      host_connect_device "$2" "$3"
      ;;
    shell)
      enter_shell
      ;;
    build)
      rebuild_container
      ;;
    help|--help|-h|"")
      show_help
      ;;
    *)
      echo -e "${RED}错误: 未知命令 '$1'${NC}"
      show_help
      exit 1
      ;;
  esac
}

# 执行主函数
main "$@"
