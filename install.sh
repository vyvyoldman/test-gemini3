#!/bin/bash

echo "=================================================="
echo " 🚀 开始部署 VLESS + Argo (PM2 后台常驻版)"
echo "=================================================="

# 1. 检查并安装 Node.js 环境
if ! command -v node > /dev/null 2>&1; then
    echo "[+] 未检测到 Node.js，正在为您自动安装 (Node.js 20.x)..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "[+] ✅ Node.js 已就绪，版本: $(node -v)"
fi

# 2. 安装 PM2 进程守护工具
if ! command -v pm2 > /dev/null 2>&1; then
    echo "[+] 正在全局安装 PM2..."
    sudo npm install -g pm2
else
    echo "[+] ✅ PM2 已安装"
fi

# 3. 清理并准备工作目录
WORK_DIR="$HOME/test-gemini3"
echo "[+] 正在初始化目录: $WORK_DIR"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit

# 4. 从你的 Github 仓库拉取最新代码
echo "[+] 正在下载核心配置文件..."
curl -sO https://raw.githubusercontent.com/vyvyoldman/test-gemini3/main/index.js
curl -sO https://raw.githubusercontent.com/vyvyoldman/test-gemini3/main/package.json

# 5. 安装依赖
echo "[+] 正在安装 WebSocket 依赖..."
npm install --silent

# 6. 使用 PM2 在后台拉起服务
echo "[+] 正在通过 PM2 后台启动节点..."
# 如果之前有同名进程，先删掉，确保是最新的
pm2 delete vless-argo > /dev/null 2>&1
pm2 start index.js --name "vless-argo"
pm2 save > /dev/null 2>&1

echo "=================================================="
echo " ✅ 部署并后台启动成功！关闭 SSH 连接也不会断开。"
echo " ⏳ Argo 隧道正在建立，大约需要 3~8 秒获取公网链接..."
echo "=================================================="

# 等待几秒钟让 cloudflared 跑起来，然后输出最新的日志
sleep 6
pm2 logs "vless-argo" --lines 30 --nostream

echo "=================================================="
echo "💡 日常运维必学命令 (随时可以在终端输入):"
echo "👉 查看你的节点链接 (看日志): pm2 logs vless-argo"
echo "👉 查看节点运行状态: pm2 status"
echo "👉 重启节点服务: pm2 restart vless-argo"
echo "👉 停止节点服务: pm2 stop vless-argo"
echo "=================================================="
