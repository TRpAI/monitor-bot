#!/bin/bash
# ==============================================================================
# Docker 部署快捷脚本
# 用法：./docker-deploy.sh [up|down|logs|restart|clean]
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
PROJECT_NAME="${PROJECT_NAME:-monitor-bot}"

case "${1:-up}" in
    up)
        echo "🚀 启动监控系统（含 Redis）..."
        cd "${SCRIPT_DIR}"
        docker compose -f "${COMPOSE_FILE}" up -d --build
        echo ""
        echo "✅ 部署完成！"
        echo "   查看日志: docker compose -f ${COMPOSE_FILE} logs -f"
        echo "   状态检查: docker ps | grep monitor"
        ;;
    down)
        echo "🛑 停止并清理容器..."
        cd "${SCRIPT_DIR}"
        docker compose -f "${COMPOSE_FILE}" down
        ;;
    logs)
        echo "📋 实时日志..."
        cd "${SCRIPT_DIR}"
        docker compose -f "${COMPOSE_FILE}" logs -f
        ;;
    restart)
        echo "🔄 重启服务..."
        cd "${SCRIPT_DIR}"
        docker compose -f "${COMPOSE_FILE}" restart
        ;;
    clean)
        echo "🧹 清理所有数据（包括数据库）..."
        read -p "⚠️  此操作将删除所有数据，确认？(yes/no): " confirm
        if [[ "${confirm}" == "yes" ]]; then
            cd "${SCRIPT_DIR}"
            docker compose -f "${COMPOSE_FILE}" down -v
            rm -rf data/ logs/
            echo "✓ 清理完成"
        else
            echo "✓ 已取消"
        fi
        ;;
    *)
        echo "用法: $0 {up|down|logs|restart|clean}"
        exit 1
        ;;
esac
