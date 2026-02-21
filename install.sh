#!/bin/bash

echo "=================================================="
echo " 🚀 开始从 Github 仓库一键部署 VLESS + Argo"
echo "=================================================="

# 1. 检查并安装 Node.js 环境 (适配 Debian/Ubuntu)
if ! command -v node > /dev/null 2>&1; then
    echo "[+] 未检测到 Node.js，正在自动安装 (Node.js 20.x)..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "[+] ✅ Node.js 已安装，版本: $(node -v)"
fi

# 2. 清理并创建工作目录
WORK_DIR="$HOME/test-gemini3"
echo "[+] 正在准备部署目录: $WORK_DIR"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit

# 3. 从你的 Github 仓库拉取最新代码
echo "[+] 正在下载核心代码..."
# 直接使用 raw.githubusercontent.com 拉取你仓库里的文件
curl -sO https://raw.githubusercontent.com/vyvyoldman/test-gemini3/main/index.js
curl -sO https://raw.githubusercontent.com/vyvyoldman/test-gemini3/main/package.json

# 4. 安装 Node.js 依赖
echo "[+] 正在安装依赖 (ws)..."
npm install --silent

# 5. 启动服务
echo "=================================================="
echo " ✅ 部署准备就绪！正在启动服务获取节点链接..."
echo " (提示: 按 Ctrl+C 可以停止运行)"
echo "=================================================="

# 直接在前台运行，方便你马上看到终端打印出的 vless:// 链接
node index.js
