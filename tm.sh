#!/bin/bash

TOKEN="${1:-NFkkNzB76cs6XF8wJyRQnL/lx2QdF/9AbmWYFfUupbs=}"

# --- 1. 检查并安装 Docker ---
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

# --- 2. 确保 Docker 守护进程就绪 ---
echo "🔄 检查 Docker 服务..."
while [ ! -S /var/run/docker.sock ]; do
    service docker start 2>/dev/null || systemctl start docker 2>/dev/null
    sleep 2
done

# --- 3. 强制清理冲突的镜像和容器 ---
echo "🧹 正在清理旧容器和错误的架构镜像..."
docker rm -f tm 2>/dev/null
# 这一步非常关键：删除本地缓存的错误的 amd64 镜像
docker rmi -f traffmonetizer/cli_v2:latest 2>/dev/null

# --- 4. 部署 ARM64 容器 ---
echo "🆕 正在强制拉取 linux/arm64 镜像并启动..."
# 使用 --platform 强制拉取并运行
docker run -d \
    --name tm \
    --restart always \
    --privileged \
    --platform linux/arm64 \
    traffmonetizer/cli_v2:latest start accept --token "$TOKEN"

echo "------------------------------------------------"
if [ "$(docker ps -q -f name=^/tm$)" ]; then
    echo "✅ 部署成功！容器正在运行。"
    docker ps -f name=^/tm$
else
    echo "❌ 部署失败，请检查上方报错信息。"
fi
echo "------------------------------------------------"
