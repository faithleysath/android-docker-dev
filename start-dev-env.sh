#!/bin/bash

# 切换到项目根目录
cd "$(dirname "$0")"

# 颜色变量
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 显示帮助信息
show_help() {
  echo -e "${YELLOW}安卓开发环境管理脚本${NC}"
  echo "用法: $0 [命令]"
  echo ""
  echo "命令:"
  echo "  start          启动开发环境容器"
  echo "  stop           停止开发环境容器"
  echo "  status         查看容器状态"
  echo "  connect        连接到安卓设备 (需要设备IP地址)"
  echo "  shell          进入容器命令行"
  echo "  build          重新构建容器"
  echo "  help           显示此帮助信息"
  echo ""
  echo "示例:"
  echo "  $0 start"
  echo "  $0 connect 192.168.1.100"
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

# 连接到安卓设备
connect_device() {
  check_docker
  if [ -z "$1" ]; then
    echo -e "${RED}错误: 请提供设备IP地址${NC}"
    echo -e "用法: $0 connect 192.168.1.100"
    exit 1
  fi
  
  echo -e "${GREEN}连接到IP为 $1 的安卓设备...${NC}"
  echo -e "${YELLOW}请确保:${NC}"
  echo -e " 1. 设备已启用开发者选项"
  echo -e " 2. 已启用USB调试"
  echo -e " 3. 设备与电脑在同一Wi-Fi网络"
  echo -e " 4. 在设备上已启用无线调试 (Android 11以上)"
  
  docker exec -it android-development adb start-server
  docker exec -it android-development adb connect $1:5555
  
  echo -e "${GREEN}执行 'docker exec -it android-development adb devices' 检查设备是否已连接${NC}"
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
    connect)
      connect_device "$2"
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
