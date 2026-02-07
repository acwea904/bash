cat << 'EOF' > tm_install.sh
#!/bin/bash

TOKEN="NFkkNzB76cs6XF8wJyRQnL/lx2QdF/9AbmWYFfUupbs="

# --- 1. 检查 Docker 是否安装 ---
if command -v docker >/dev/null 2>&1; then
    echo "✅ Docker 已安装，跳过安装。"
else
    echo "⏳ 未检测到 Docker，正在安装..."
    if [ -f /sbin/apk ]; then
        apk update && apk add docker docker-compose
        rc-update add docker boot
        service docker start
    elif [ -x "$(command -v apt-get)" ]; then
        curl -fsSL https://get.docker.com | bash -s docker
        systemctl enable --now docker
    else
        echo "❌ 错误: 无法识别的系统环境，请手动安装 Docker。"
        exit 1
    fi
fi

# --- 2. 检查 Docker 服务是否响应 ---
if ! docker info >/dev/null 2>&1; then
    echo "🔄 正在启动 Docker 服务..."
    service docker start 2>/dev/null || systemctl start docker 2>/dev/null
fi

# --- 3. 检查 TraffMonetizer 容器是否已在运行 ---
if [ "$(docker ps -q -f name=^tm$)" ]; then
    echo "🚀 TraffMonetizer 已经在运行中，无需操作。"
    docker ps -f name=^tm$
elif [ "$(docker ps -aq -f name=^tm$)" ]; then
    echo "⚠️ 检测到名为 tm 的容器已存在但未启动，正在尝试拉起..."
    docker start tm
else
    echo "🆕 未检测到运行中的容器，开始部署..."
    docker run -d --name tm --restart always traffmonetizer/cli_v2 start accept --token "$TOKEN"
fi

echo "------------------------------------------------"
echo "任务完成！使用 'docker logs -f tm' 查看实时日志。"
echo "------------------------------------------------"
EOF

# 执行脚本
bash tm_install.sh
