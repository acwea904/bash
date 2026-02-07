#!/bin/bash

TOKEN="${1:-NFkkNzB76cs6XF8wJyRQnL/lx2QdF/9AbmWYFfUupbs=}"

# --- 1. 检查 Docker 是否安装 ---
if command -v docker >/dev/null 2>&1; then
    echo "✅ Docker 已安装。"
else
    echo "⏳ 未检测到 Docker，正在安装..."
    if [ -f /sbin/apk ]; then
        apk update && apk add docker docker-compose
        rc-update add docker boot
        service docker start
    elif command -v apt-get >/dev/null 2>&1; then
        curl -fsSL https://get.docker.com | bash -s docker
        systemctl enable --now docker
    else
        echo "❌ 错误: 无法识别的系统，请手动安装 Docker。"
        exit 1
    fi
fi

# --- 2. 核心修复：确保 Docker 守护进程真正可用 ---
echo "🔄 正在检查 Docker 服务状态..."
MAX_RETRIES=10
COUNT=0
while [ ! -S /var/run/docker.sock ]; do
    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo "❌ 错误: Docker 服务启动超时，请检查系统日志。"
        exit 1
    fi
    service docker start 2>/dev/null || systemctl start docker 2>/dev/null
    echo "⏳ 等待 Docker 守护进程启动 ($(($COUNT+1))/$MAX_RETRIES)..."
    sleep 2
    ((COUNT++))
done
echo "✅ Docker 守护进程已就绪！"

# --- 3. 检查并运行容器 ---
CONTAINER_NAME="tm"
if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "🚀 TraffMonetizer 已经在运行中。"
elif [ "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "⚠️ 容器存在但未启动，正在重新启动..."
    docker start $CONTAINER_NAME
else
    echo "🆕 正在创建并运行新容器..."
    docker run -d \
        --name $CONTAINER_NAME \
        --restart always \
        traffmonetizer/cli_v2 start accept --token "$TOKEN"
fi

echo "------------------------------------------------"
echo "部署成功！"
docker ps
echo "------------------------------------------------"
