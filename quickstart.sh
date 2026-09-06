#!/usr/bin/env bash
# ==============================================================================
# 快速启动脚本 - 用于开发机直接运行测试（非 systemd）
# 用法：bash quickstart.sh
# ==============================================================================
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${DEPLOY_DIR}"

echo "⚡ 监控 Bot 快速启动模式（非守护进程）"
echo ""

if [[ ! -d "venv" ]]; then
    echo "📦 初始化虚拟环境..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -q -r requirements.txt
else
    source venv/bin/activate
fi

if [[ ! -f ".env" ]]; then
    cp .env.example .env
    echo "⚠️  已创建 .env 模板，请编辑并填入真实凭证！"
    echo "   编辑命令: nano .env"
fi

echo ""
echo "🚀 启动监控 Bot..."
echo "   Ctrl+C 停止"
echo ""
python3 monitor_bot_optimized.py
