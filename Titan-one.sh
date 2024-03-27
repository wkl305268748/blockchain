#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/Titan-one.sh"

# 自动设置快捷键的功能
function check_and_set_alias() {
    local alias_name="titanf"
    local shell_rc="$HOME/.bashrc"

    # 对于Zsh用户，使用.zshrc
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    fi

    # 检查快捷键是否已经设置
    if ! grep -q "$alias_name" "$shell_rc"; then
        echo "设置快捷键 '$alias_name' 到 $shell_rc"
        echo "alias $alias_name='bash $SCRIPT_PATH'" >> "$shell_rc"
        # 添加提醒用户激活快捷键的信息
        echo "快捷键 '$alias_name' 已设置。请运行 'source $shell_rc' 来激活快捷键，或重新打开终端。"
    else
        # 如果快捷键已经设置，提供一个提示信息
        echo "快捷键 '$alias_name' 已经设置在 $shell_rc。"
        echo "如果快捷键不起作用，请尝试运行 'source $shell_rc' 或重新打开终端。"
    fi
}

# 节点安装功能
function install_node() {

# 函数：检查命令是否存在
exists() {
  command -v "$1" >/dev/null 2>&1
}

# 函数：检查依赖项是否存在
exists() {
  command -v "$1" >/dev/null 2>&1
}

# 函数：安装依赖项（如果不存在）
install_dependencies() {
  local update_needed=0
  local to_install=()

  for dep in "$@"; do
    if ! exists "$dep"; then
      to_install+=("$dep")
      update_needed=1
    fi
  done

  if [ "$update_needed" -eq 1 ]; then
    echo "更新软件包索引..."
    sudo apt update -y
    echo "安装依赖项：${to_install[*]}"
    sudo apt install -y "${to_install[@]}"
  else
    echo "所有依赖项已安装。"
  fi
}

# 设置安装目录和发布 URL
INSTALL_DIR="${HOME}/titan-node"
RELEASE_URL="https://github.com/Titannet-dao/titan-node/releases/download/v0.1.15/titan_v0.1.15_linux_amd64.tar.gz"

# 创建安装目录并进入
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit

# 下载并解压发布包
wget -O titan_linux_amd64.tar.gz "$RELEASE_URL"
tar -xvzf titan_linux_amd64.tar.gz --strip-components=1



# 配置 systemd 服务文件
tee /etc/systemd/system/titan.service > /dev/null << EOF
[Unit]
Description=Titan Node Client
After=network.target
StartLimitIntervalSec=0
[Service]
User=root
ExecStart=/root/titan-node/titan-edge daemon start --init --url https://test-locator.titannet.io:5000/rpc/v0
Restart=always
RestartSec=120
[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable titan
sudo systemctl start titan.service

# 绑定身份码
read -p "请输入您身份码：" SECRET_SEED_PHRASE
./titan-edge bind --hash=$SECRET_SEED_PHRASE https://api-test1.container1.titannet.io/api/v2/device/binding

# 完成安装提示
echo ====================================== 安装完成 =========================================

}



# 查看Titan服务状态
function check_service_status() {
    systemctl status titan
}

# Titan 节点日志查询
function view_logs() {
    sudo journalctl -f -u availd.service 
}

# 查询节点匹配的钱包地址（建议安装好后，就查询钱包地址，如果日志过长，该功能可能会失效）
function check_wallet() {
    journalctl -u availd | grep address
}

# 主菜单
function main_menu() {
    clear
    echo "脚本Kenny制作"
    echo "================================================================"
    echo "请选择要执行的操作:"
    echo "1. 安装Titan"
    echo "2. 查看Titan服务状态"
    echo "3. 节点日志查询"
    echo "4. 查询节点匹配的钱包地址"
    echo "5. 设置快捷键的功能"
    read -p "请输入选项（1-5）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;
    3) view_logs ;;
    4) check_wallet ;;
    5) check_and_set_alias ;;  
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
