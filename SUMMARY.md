# Telegram Monitor Bot - 生产环境部署包

## 📦 文件清单

| 文件 | 说明 |
|------|------|
| `deploy.sh` | **一键部署脚本**，自动完成环境搭建 |
| `quickstart.sh` | 开发机快速启动脚本（非守护模式） |
| `monitor_bot_optimized.py` | 监控 Bot 主程序（52KB，全功能版） |
| `monitor-bot.service` | Systemd 守护服务单元 |
| `requirements.txt` | Python 依赖列表 |
| `.env.example` | 环境变量模板（复制为 `.env` 后填写） |
| `README.md` | 完整运维手册 |

---

## 🚀 三行命令上线

```bash
# 1. 上传 deploy/ 目录到服务器
scp -r deploy/ root@your-server:/tmp/

# 2. 在服务器上执行一键部署
sudo bash /tmp/deploy/deploy.sh

# 3. 编辑配置并重启
sudo nano /opt/monitor_bot/.env
sudo systemctl restart monitor-bot
```

---

## ✅ 验证上线

```bash
# 查看服务状态
sudo systemctl status monitor-bot

# 实时查看日志
sudo journalctl -u monitor-bot -f

# 测试 Bot
# 在 Telegram 中找到你的 Bot，发送 /start
```

---

## 📋 系统要求

- Linux 服务器（Ubuntu 20.04+/Debian 10+/CentOS 7+）
- 2GB+ RAM 推荐（含图表渲染）
- 公网 IP 或可访问 Telegram API
- 可选：Redis（提升高并发写入性能）

---

## 🔧 参数调优

编辑 `/opt/monitor_bot/.env`：

```bash
CHECK_INTERVAL=300      # 巡检间隔（秒），越低越频繁
MAX_FAILURES=2          # 连续失败几次才告警
CONCURRENT_LIMIT=10     # 最大并发探测数
MAX_RETENTION_DAYS=31   # 历史数据保留天数
REDIS_URL=redis://...   # Redis 连接（可选）
```

---

## 🗑️ 完全卸载

```bash
sudo systemctl stop monitor-bot
sudo systemctl disable monitor-bot
sudo rm /etc/systemd/system/monitor-bot.service
sudo rm -rf /opt/monitor_bot
sudo systemctl daemon-reload
```
