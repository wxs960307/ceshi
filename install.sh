#!/bin/bash

# ========= 色彩定义 =========
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'

# ========= 项目路径 =========
NCK_DIR="$HOME/nockchain"

# ========= 横幅与署名 =========
function show_banner() {
  clear
  echo -e "${BOLD}${BLUE}"
  echo "               ╔═╗╔═╦╗─╔╦═══╦═══╦═══╦═══╗"
  echo "               ╚╗╚╝╔╣║─║║╔══╣╔═╗║╔═╗║╔═╗║"
  echo "               ─╚╗╔╝║║─║║╚══╣║─╚╣║─║║║─║║"
  echo "               ─╔╝╚╗║║─║║╔══╣║╔═╣╚═╝║║─║║"
  echo "               ╔╝╔╗╚╣╚═╝║╚══╣╚╩═║╔═╗║╚═╝║"
  echo "               ╚═╝╚═╩═══╩═══╩═══╩╝─╚╩═══╝"
  echo -e "${RESET}"
  echo "-----------------------------------------------"
  echo ""
}

# ========= 安装系统依赖 =========
function install_dependencies() {
  echo -e "[*] 安装系统依赖..."
  sudo apt-get update && sudo apt-get upgrade -y
  sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev  -y
  sudo apt install screen
  echo -e "${GREEN}[+] 依赖安装完成。${RESET}"
  pause_and_return
}

# ========= 安装 Rust =========
function install_rust() {
  echo -e "[*] 安装 Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
  echo -e "${GREEN}[+] Rust 安装完成。${RESET}"
  pause_and_return
}

# ========= 克隆或更新仓库 =========
function setup_repository() {
  echo -e "[*] 检查 nockchain 仓库..."
  if [ -d "$NCK_DIR" ]; then
    echo -e "${YELLOW}[?] 已存在 nockchain 目录，是否删除重新克隆？(y/n)${RESET}"
    read -r confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
      rm -rf "$NCK_DIR"
      git clone https://github.com/zorp-corp/nockchain "$NCK_DIR"
    else
      cd "$NCK_DIR" && git pull
    fi
  else
    git clone https://github.com/zorp-corp/nockchain "$NCK_DIR"
  fi
  echo -e "${GREEN}[+] 仓库设置完成。${RESET}"
  pause_and_return
}

# ========= 编译项目 =========
function build_project() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain 目录不存在，请先设置仓库！${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || exit 1
  echo -e "[*] 编译核心组件..."
  make install-hoonc
  make build
  make install-nockchain-wallet
  make install-nockchain
  echo -e "${GREEN}[+] 编译完成。${RESET}"
  pause_and_return
}


# ========= 生成钱包 =========
function generate_wallet() {
  cd "$NCK_DIR" || exit 1
  echo 'export PATH="$PATH:$HOME/nockchain/target/release"' 
  echo -e "[*] 创建钱包..."
  nockchain-wallet keygen
  echo 'nano Makefile' 
  echo -e "${GREEN}[+] 钱包生成完成,请将您的钱包替换公钥。${RESET}"
  pause_and_return
}

# ========= 设置挖矿公钥 =========
function configure_mining_key() {
  read -p "[?] 输入你的挖矿公钥 / Enter your mining public key: " key
  sed -i "s|^export MINING_PUBKEY :=.*$|export MINING_PUBKEY := $key|" "$NCK_DIR/Makefile"
  echo -e "${GREEN}[+] 挖矿公钥已设置 / Mining key updated.${RESET}"
  pause_and_return
}


# ========= 启动 Leader 节点 =========
function start_leader_node() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain 目录不存在，请先设置仓库！${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || exit 1
  echo -e "[*] 启动 Leader 节点..."
  screen -S leader -dm bash -c "make run-nockchain-leader"
  echo -e "${GREEN}[+] Leader 节点运行中。${RESET}"
  echo -e "${YELLOW}[!] 正在进入日志界面，按 Ctrl+A+D 可退出。${RESET}"
  sleep 2
  screen -r leader
  pause_and_return
}

# ========= 启动 Follower 节点 =========
function start_follower_node() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain 目录不存在，请先设置仓库！${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || exit 1
  echo -e "[*] 启动 Follower 节点..."
  screen -S follower -dm bash -c "make run-nockchain-follower"
  echo -e "${GREEN}[+] Follower 节点运行中。${RESET}"
  echo -e "${YELLOW}[!] 正在进入日志界面，按 Ctrl+A+D 可退出。${RESET}"
  sleep 2
  screen -r follower
  pause_and_return
}

# ========= 等待任意键继续 =========
function pause_and_return() {
  echo ""
  read -n1 -r -p "按任意键返回主菜单..." key
  main_menu
}

# ========= 主菜单 =========
function main_menu() {
  show_banner
  echo "请选择操作:"
  echo "  1) 安装系统依赖"
  echo "  2) 安装 Rust"
  echo "  3) 设置仓库"
  echo "  4) 编译项目"
  echo "  5) 生成钱包"
  echo "  6) 设置挖矿公钥"
  echo "  7) 启动 Leader 节点"
  echo "  8) 启动 Follower 节点"
  echo "  0) 退出"
  echo ""
  read -p "请输入编号: " choice

  case "$choice" in
    1) install_dependencies ;;
    2) install_rust ;;
    3) setup_repository ;;
    4) build_project ;;
    5) generate_wallet ;;
    6) configure_mining_key ;;
    7) start_leader_node ;;
    8) start_follower_node ;;
    0) echo "已退出。"; exit 0 ;;
    *) echo -e "${RED}[-] 无效选项。${RESET}"; pause_and_return ;;
  esac
}

# ========= 启动主程序 =========
main_menu
