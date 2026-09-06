# 工业级 Telegram 分布式监控系统 — 生产部署指南

## 快速部署（一键）

```bash
# 将 deploy/ 目录上传到目标服务器后执行：
sudo bash deploy.sh
```

默认安装到 `/opt/monitor_bot`，如需自定义路径：
```bash
sudo bash deploy.sh /your/custom/path
```

---

## Docker 部署（推荐）

### 三行命令上线

```bash
# 1. 克隆并进入部署目录
git clone <your-repo-url> && cd deploy

# 2. 配置环境变量
cp .env.docker.example .env
nano .env  # 填入 TG_TOKEN 和 ADMIN_CHAT_ID

# 3. 一键启动（自动下载镜像、构建、启动 Redis）
chmod +x docker-deploy.sh && ./docker-deploy.sh up
```

### 常用 Docker 命令

```bash
# 查看实时日志
./docker-deploy.sh logs

# 重启服务
./docker-deploy.sh restart

# 停止并清理
./docker-deploy.sh down

# 清理所有数据（包括数据库）
./docker-deploy.sh clean
```

### Docker 架构

```
┌─────────────────────────────────────────────┐
│           monitor-bot (Python 3.11)         │
│  ├─ 异步并发巡检引擎                         │
│  ├─ Telegram Bot API                        │
│  ├─ SQLite 持久化 + Redis 缓冲队列           │
│  └─ Systemd 自愈机制                        │
└──────────────────┬──────────────────────────┘
                   │ redis://redis:6379
┌──────────────────▼──────────────────────────┐
│              redis:7-alpine                 │
│  ├─ 异步队列缓冲                           │
│  ├─ AOF 持久化                             │
│  └─ allkeys-lru 淘汰策略                   │
└─────────────────────────────────────────────┘
         ↓ 数据卷挂载 ↓
    /data (SQLite + Redis RDB)
    /logs (Bot 运行日志)
```

### Docker Compose 文件说明

| 服务 | 镜像 | 端口 | 说明 |
|------|------|------|------|
| `monitor-bot` | 本地构建 | 无外部端口 | 主程序，内存限制 512MB |
| `redis` | `redis:7-alpine` | 6379 (内部) | 缓冲队列，AOF 持久化 |

**网络隔离**：服务间通过 `monitor-net` 网桥通信，不暴露任何端口到宿主机。

---

## 部署后立即执行

### 1. 配置 Bot 凭证
```bash
# 原生部署
sudo nano /opt/monitor_bot/.env

# Docker 部署
nano .env
```
替换以下两项：
- `TG_TOKEN=YOUR_BOT_TOKEN_HERE` → 从 [@BotFather](https://t.me/BotFather) 获取
- `ADMIN_CHAT_ID=YOUR_ADMIN_CHAT_ID_NUMBER` → 你的 Telegram 数字 ID

### 2. 重启服务使配置生效
```bash
# 原生部署
sudo systemctl restart monitor-bot

# Docker 部署
./docker-deploy.sh restart
```

### 3. 验证运行
```bash
# 原生部署
sudo systemctl status monitor-bot
sudo journalctl -u monitor-bot -f

# Docker 部署
./docker-deploy.sh logs
```

### 4. 在 Telegram 与 Bot 对话
找到你的 Bot，发送 `/start` 指令，即可使用控制面板。

---

## 常用运维命令

| 操作 | 原生部署 | Docker 部署 |
|------|----------|-------------|
| 查看状态 | `sudo systemctl status monitor-bot` | `docker ps \| grep monitor` |
| 实时日志 | `sudo journalctl -u monitor-bot -f` | `./docker-deploy.sh logs` |
| 重启服务 | `sudo systemctl restart monitor-bot` | `./docker-deploy.sh restart` |
| 停止服务 | `sudo systemctl stop monitor-bot` | `./docker-deploy.sh down` |
| 启动服务 | `sudo systemctl start monitor-bot` | `./docker-deploy.sh up` |
| 开机自启 | `sudo systemctl enable monitor-bot` | 已内置 `restart: unless-stopped` |
| 查看主日志 | `sudo tail -f /opt/monitor_bot/bot.log` | `./docker-deploy.sh logs` |
| 清理旧数据 | `sudo systemctl restart monitor-bot` | `./docker-deploy.sh clean` |

---

## 可选：启用 Redis 缓冲队列（提升高并发写入性能）

```bash
# 原生部署
sudo systemctl enable --now redis-server

# Docker 部署（已内置，无需额外配置）
# Redis 容器会自动启动
```

> 不启用 Redis 不影响核心功能，数据直接写入 SQLite。

---

## 文件结构

### 原生部署 (`/opt/monitor_bot/`)
```
/opt/monitor_bot/
├── venv/                   # Python 虚拟环境
├── monitor_bot_optimized.py  # 主程序
├── .env                    # 环境变量配置 ⚠️ 不要提交到 Git
├── requirements.txt        # Python 依赖
├── monitored_sites.json    # 监控网站列表（运行时自动生成）
├── monitored_services.json # 监控服务列表（运行时自动生成）
├── monitor_history.db      # SQLite 历史数据库
├── monitor_history.db-wal  # SQLite WAL 预写日志
├── bot.log                 # 运行日志（轮转，最多 12MB）
├── report_chart_*.png      # 生成的图表（运行时自动生成）
└── SourceHanSans-Regular.ttf  # 中文字体
```

### Docker 部署 (项目根目录)
```
deploy/
├── docker-compose.yml      # 编排配置
├── Dockerfile              # 多阶段构建
├── .env.docker.example     # 环境变量模板
├── docker-deploy.sh        # 快捷脚本
├── data/                   # 数据卷（gitignore）
├── logs/                   # 日志卷（gitignore）
└── ...
```

---

## 安全须知

- `.env` 文件包含 Bot Token，**请勿上传至公开 Git 仓库**
- systemd 服务已配置 `NoNewPrivileges=true` 和 `PrivateTmp=true`
- Docker 部署不暴露任何端口到宿主机
- 建议限制 `.env` 权限：`sudo chmod 600 /opt/monitor_bot/.env`
- 建议定期备份数据库：`cp /opt/monitor_bot/monitor_history.db /backup/`

---

## 故障排查

### 服务无法启动
```bash
# 查看详细错误日志
sudo journalctl -u monitor-bot -n 50 --no-pager
# 测试 Python 环境
sudo -u root /opt/monitor_bot/venv/bin/python3 -c "import telegram; print('OK')"

# Docker 方式
docker compose -f docker-compose.yml logs --tail=50
docker compose -f docker-compose.yml exec monitor-bot python3 -c "import telegram; print('OK')"
```

### 图表中文显示方块
系统缺少中文字体，执行：
```bash
# Debian/Ubuntu
sudo apt-get install -y fonts-wqy-microhei fonts-wqy-zenhei
# CentOS/RHEL
sudo yum install -y wqy-microhei-fonts wqy-zenhei-fonts
# 重启服务
sudo systemctl restart monitor-bot
```

### Telegram 收不到消息
检查 `.env` 中的 `TG_TOKEN` 和 `ADMIN_CHAT_ID` 是否正确，Bot 是否已在 Telegram 中启动。

---

## 参数调优

编辑 `/opt/monitor_bot/.env` 或 `.env`（Docker），修改后重启服务：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `CHECK_INTERVAL` | 300 | 巡检间隔（秒），越低越频繁，建议 60~600 |
| `MAX_FAILURES` | 2 | 连续失败几次才告警，防误报 |
| `CONCURRENT_LIMIT` | 10 | 最大并发探测数，服务器性能差可降到 5 |
| `MAX_RETENTION_DAYS` | 31 | 历史数据保留天数 |
| `REDIS_URL` | 留空跳过 | 启用 Redis 缓冲队列，高吞吐场景推荐 |

---

## 卸载

### 原生部署
```bash
sudo systemctl stop monitor-bot
sudo systemctl disable monitor-bot
sudo rm /etc/systemd/system/monitor-bot.service
sudo rm -rf /opt/monitor_bot
sudo systemctl daemon-reload
```

### Docker 部署
```bash
./docker-deploy.sh clean
docker system prune -f  # 清理悬空镜像
```
