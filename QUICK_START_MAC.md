# OpenClaw Zero Token - Mac 快速开始

## 一键检查环境
```bash
./check-mac-setup.sh
```

## 首次运行（4 步）

### 0️⃣ 停止系统级 OpenClaw（如果已安装）
```bash
# 三选一，按优先级
openclaw gateway stop                      # ✅ 推荐
launchctl stop ai.openclaw.gateway         # 备选
pkill -f openclaw-gateway                  # 最后手段
```

### 1️⃣ 安装和编译
```bash
pnpm install
pnpm build
```

### 2️⃣ 启动 Chrome 调试模式
```bash
./start-chrome-debug.sh
# 等待 Chrome 打开，登录 Claude
```

**⚠️ 重要：这是独立的调试 Chrome**
- 看不到你的书签、历史记录
- 不影响日常 Chrome 使用
- 只在配置时需要，日常使用不需要

### 3️⃣ 配置项目（新终端）
```bash
./onboard.sh
# 选择: Claude Web -> Automated Login
```

### 4️⃣ 启动服务
```bash
./server.sh start
```

### 5️⃣ 测试和访问
```bash
./test-claude.sh "你好"
open http://127.0.0.1:3001
```

---

## 常用命令

### 服务管理
```bash
./server.sh start      # 启动
./server.sh stop       # 停止
./server.sh restart    # 重启
./server.sh status     # 状态
```

### 测试
```bash
./test-chrome-connection.sh           # 测试 Chrome 连接
./test-claude.sh "你的问题"           # 测试 Claude
```

### 重新配置
```bash
./onboard.sh
```

---

## 端口说明

| 端口 | 用途 | 检查命令 |
|------|------|----------|
| 3001 | Gateway HTTP API | `lsof -i:3001` |
| 9222 | Chrome CDP (Claude) | `lsof -i:9222` |
| 18792 | Chrome CDP (DeepSeek/Doubao) | `lsof -i:18792` |

---

## 故障排查

### 🎯 首次运行：使用配置向导

```bash
./onboard.sh
```

**自动创建所有文件和目录！**

### 🔧 修复问题：使用诊断命令

```bash
node dist/index.mjs doctor
```

**只修复目录和权限问题**
- ✅ 创建缺失的目录
- ✅ 修复文件权限
- ❌ 不创建配置文件

**配置文件缺失？重新运行：**
```bash
./onboard.sh
```

### Chrome 端口冲突
```bash
pkill -f "chrome.*remote-debugging-port"
./start-chrome-debug.sh
```

### Gateway 端口冲突
```bash
# 停止系统级 OpenClaw
openclaw gateway stop

# 或者查找并杀掉占用进程
lsof -i:3001
kill <PID>
```

### 认证失败
```bash
# 检查认证文件
cat .openclaw-state/agents/main/agent/auth-profiles.json

# 重新配置
./onboard.sh
```

---

## 文件位置

```
.openclaw-state/
├── openclaw.json                          # 主配置
└── agents/main/agent/
    └── auth-profiles.json                 # 认证凭证（敏感）
```

---

## 详细文档

- 📖 [完整设置指南](SETUP_GUIDE_zh-CN.md)（跨平台）
- 📖 [项目 README](README_zh-CN.md)
- 📖 [Claude Web 技术细节](CLAUDE_WEB_IMPLEMENTATION.md)

---

## 获取帮助

```bash
# 查看日志
tail -50 /tmp/openclaw-gateway.log

# 查看进程
ps aux | grep openclaw

# 查看端口
lsof -i:3001
lsof -i:9222
```
