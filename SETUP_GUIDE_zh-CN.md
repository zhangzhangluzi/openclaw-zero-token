# OpenClaw Zero Token - 首次运行指南（跨平台）

本指南适用于在 macOS、Linux 和 Windows (WSL2) 上首次运行 OpenClaw Zero Token 项目。

> **平台说明：**
> - 🍎 **macOS 用户**: 本指南的主要示例基于 macOS
> - 🐧 **Linux 用户**: 基本流程与 Mac 相同，主要区别：
>   - 路径使用 `/home/username/` 而非 `/Users/username/`
>   - Chrome 路径可能不同（通常在 `/usr/bin/google-chrome` 或 `/opt/google/chrome/chrome`）
>   - 不需要使用 `launchctl`（使用 `systemctl` 或直接 `pkill`）
>   - 其他步骤完全相同
> - 🪟 **Windows 用户**: 强烈推荐使用 WSL2
>   - 安装 WSL2: `wsl --install`（PowerShell 管理员模式）
>   - 安装后在 WSL2 中按 Linux 流程操作
>   - WSL2 指南: https://docs.microsoft.com/zh-cn/windows/wsl/install

## 前置要求

- **操作系统**: macOS、Linux 或 Windows (WSL2)
- Node.js >= 22.12.0
- pnpm >= 9.0.0
- Google Chrome 浏览器

## 重要注意事项

### 1. 必需的目录和文件

以下目录和文件需要存在，否则项目无法正常运行：

```
.openclaw-state/          # 状态目录（会自动创建）
docs/                     # 文档目录（需要提交到 Git）
```

**检查方法：**
```bash
# 检查 docs 目录
ls -la docs/

# 如果不存在，创建它
mkdir -p docs/reference/templates
```

### 2. 配置文件路径问题

配置文件 `.openclaw-state/openclaw.json` 中的路径在不同系统上不同：

- **Linux**: `/home/username/Documents/openclaw-zero-token/...`
- **macOS**: `/Users/username/Documents/openclaw-zero-token/...`

**首次运行前需要修改的配置：**

编辑 `.openclaw-state/openclaw.json`，将以下路径改为 Mac 路径：

```json
{
  "agents": {
    "defaults": {
      "workspace": "/Users/你的用户名/Documents/openclaw-zero-token/.openclaw-state/workspace"
    }
  }
}
```

### 3. 停止系统级 OpenClaw 服务

如果你之前安装过系统级的 OpenClaw，需要先停止它以避免端口冲突。

**什么是系统级 OpenClaw？**
- 通过 `npm install -g openclaw` 或其他方式全局安装的 OpenClaw
- 作为系统后台服务运行（macOS 使用 launchd，Linux 使用 systemd）
- 占用端口 3001（Gateway）和 18792/9222（Chrome CDP）

**推荐停止方法（按优先级）：**

```bash
# 方法 1: 使用 openclaw 命令（推荐，跨平台）
# 如果系统已安装 openclaw 命令，这是最简单的方式
openclaw gateway stop

# 方法 2: 使用系统服务管理工具（如果方法 1 不可用）
# macOS:
launchctl stop ai.openclaw.gateway
# Linux (如果配置了 systemd):
systemctl stop openclaw-gateway

# 方法 3: 直接杀掉进程（最后手段，跨平台）
pkill -f openclaw-gateway
```

**检查是否成功停止：**

```bash
# 检查系统服务（macOS）
launchctl list | grep openclaw

# 检查系统服务（Linux）
systemctl status openclaw-gateway

# 检查进程（跨平台）
ps aux | grep openclaw | grep -v grep

# 检查端口占用（跨平台）
lsof -i:3001
lsof -i:18792
lsof -i:9222
```

**常见端口冲突：**
- 端口 3001: Gateway 服务（HTTP API）
- 端口 18792: Chrome CDP 调试端口（DeepSeek/Doubao 使用）
- 端口 9222: Chrome CDP 调试端口（Claude Web 使用）

**为什么需要停止？**
- 本项目和系统级 OpenClaw 会竞争相同的端口
- 两个服务同时运行会导致端口冲突错误
- 本项目使用独立的配置目录（`.openclaw-state/`），不会影响系统级配置

## 完整安装步骤

### 步骤 0: 停止系统级 OpenClaw（如果已安装）

**如果你之前安装过系统级 OpenClaw，必须先停止它！**

```bash
# 方法 1: 使用 openclaw 命令（推荐，最简单，跨平台）
openclaw gateway stop

# 方法 2: 使用系统服务管理工具（如果方法 1 不可用）
# macOS:
launchctl stop ai.openclaw.gateway
# Linux:
systemctl stop openclaw-gateway

# 方法 3: 直接杀掉进程（最后手段，跨平台）
pkill -f openclaw-gateway
```

**验证是否停止：**
```bash
# 检查进程
ps aux | grep openclaw | grep -v grep

# 检查端口（应该都是空的）
lsof -i:3001
lsof -i:18792
lsof -i:9222
```

**如果没有安装过系统级 OpenClaw，跳过此步骤。**

### 步骤 1: 安装依赖

```bash
cd openclaw-zero-token
pnpm install
```

### 步骤 2: 编译项目

```bash
pnpm build
```

### 步骤 3: 启动 Chrome 调试模式

**这一步非常重要！** 因为配置使用了 `attachOnly: true`，系统不会自动启动浏览器。

```bash
./start-chrome-debug.sh
```

**这个脚本会：**
1. 检查是否已有 Chrome 调试模式在运行
2. 启动 Chrome（端口 9222）
3. 自动打开 https://claude.ai/new
4. 等待你登录 Claude

**⚠️ 关于 Chrome 调试模式的重要说明：**

这个 Chrome 是**独立的调试实例**，与你日常使用的 Chrome 完全隔离：

- ✅ **优点**：不会影响你的日常浏览器使用
- ❌ **缺点**：看不到你的书签、历史记录、已保存的密码等

**如果你想看到自己的书签和数据：**

1. **关闭调试 Chrome**：
   ```bash
   pkill -f "chrome.*remote-debugging-port=9222"
   ```

2. **使用日常 Chrome 登录 Claude**：
   - 打开你的日常 Chrome
   - 访问 https://claude.ai 并登录
   - 保存登录状态

3. **重新启动调试 Chrome**：
   ```bash
   ./start-chrome-debug.sh
   ```
   - 这次应该会自动登录（因为 Chrome 会同步登录状态）

**⚠️ 重要权衡：**

- **使用调试 Chrome**：可以自动捕获认证凭证，但看不到书签
- **关闭调试模式**：可以使用日常 Chrome，但无法自动捕获凭证
- **每次重新配置**：如果关闭了调试 Chrome，下次需要重新运行 `./onboard.sh`

**推荐做法：**

1. 首次配置时使用调试 Chrome（即使看不到书签）
2. 完成配置后，可以关闭调试 Chrome
3. 日常使用时，只需要 Gateway 服务运行即可（不需要调试 Chrome）
4. 只有在重新配置认证时才需要再次启动调试 Chrome

**重要提示：**
- 保持这个 Chrome 窗口打开（配置期间）
- 在 Claude 页面完成登录
- 如果之前登录过，应该会自动登录

### 步骤 4: 运行配置向导

在另一个终端窗口运行：

```bash
./onboard.sh
```

**配置流程：**
1. 选择 AI 提供商：`Claude Web`
2. 选择认证模式：`Automated Login (Recommended)`
3. 系统会自动连接到 Chrome（端口 9222）
4. 自动捕获 Claude 登录凭证（sessionKey）
5. 保存到 `.openclaw-state/agents/main/agent/auth-profiles.json`

**如果自动捕获失败：**
- 检查 Chrome 是否在端口 9222 运行：`lsof -i:9222`
- 检查是否已登录 Claude
- 尝试手动模式：选择 `Manual Paste`，然后：
  1. 在 Chrome 中访问 https://claude.ai
  2. 按 F12 打开开发者工具
  3. Application → Cookies → 复制 `sessionKey` 的值
  4. 粘贴到配置向导

### 步骤 5: 启动 Gateway 服务

```bash
./server.sh start
```

**验证服务启动：**
```bash
# 检查服务状态
./server.sh status

# 检查端口
lsof -i:3001
```

### 步骤 6: 测试 Claude Web

```bash
# 测试 Chrome 连接
./test-chrome-connection.sh

# 测试 Claude API
./test-claude.sh "你好，Claude！"
```

### 步骤 7: 访问 Web UI

打开浏览器访问：
```
http://127.0.0.1:3001
```

使用 Gateway Token（在 `.openclaw-state/openclaw.json` 中查看）：
```json
{
  "gateway": {
    "auth": {
      "token": "你的token"
    }
  }
}
```

## 常见问题排查

### 首次运行：直接使用配置向导

**如果是首次运行项目，不需要运行 `doctor` 命令，直接运行：**

```bash
./onboard.sh
```

**配置向导会自动创建所有必需的文件和目录！**

### 修复问题：使用诊断命令

**如果项目已经运行过，但遇到问题，运行诊断命令：**

```bash
node dist/index.mjs doctor
```

**诊断命令功能：**
- ✅ 自动检查所有必需的目录
- ✅ 自动创建缺失的目录
- ✅ 修复文件权限问题（chmod 700/600）
- ✅ 检查配置文件完整性
- ✅ 检查会话文件状态
- ✅ 检测多个状态目录冲突
- ✅ 提供详细的修复建议

**⚠️ 重要限制：**
- ❌ `doctor` 命令**不会**创建配置文件（`openclaw.json`）
- ❌ `doctor` 命令**不会**创建认证文件（`auth-profiles.json`）
- ✅ 如果配置文件缺失或损坏，需要重新运行 `./onboard.sh`

**示例输出：**
```
State integrity
- CRITICAL: state directory missing (~/.openclaw-state)
? Create ~/.openclaw-state now? (Y/n) Y

- CRITICAL: Sessions dir missing (~/.openclaw-state/agents/main/sessions)
? Create Sessions dir at ~/.openclaw-state/agents/main/sessions? (Y/n) Y

- State directory permissions are too open (~/.openclaw-state)
? Tighten permissions on ~/.openclaw-state to 700? (Y/n) Y

Doctor changes
- Created ~/.openclaw-state
- Created Sessions dir: ~/.openclaw-state/agents/main/sessions
- Created OAuth dir: ~/.openclaw-state/credentials
- Tightened permissions on ~/.openclaw-state to 700
- Tightened permissions on ~/.openclaw-state/openclaw.json to 600
```

**何时使用 `doctor` 命令：**
- ✅ 目录被意外删除
- ✅ 遇到"权限被拒绝"错误
- ✅ 验证环境是否正常
- ✅ 会话历史丢失
- ❌ **不适合**首次运行（应该用 `onboard.sh`）
- ❌ **不适合**配置文件缺失（应该用 `onboard.sh`）

### 问题 1: Chrome CDP 端口冲突

**错误信息：**
```
Error: Failed to start Chrome CDP on port 18792 for profile "chrome"
```

**解决方案：**
```bash
# 检查端口占用
lsof -i:18792
lsof -i:9222

# 停止占用进程
pkill -f "chrome.*remote-debugging-port"

# 重新启动
./start-chrome-debug.sh
```

### 问题 2: 没有自动打开 Claude

**原因：**
- Chrome 调试模式未启动
- 配置文件中 `attachOnly: true` 但没有运行的 Chrome

**解决方案：**
```bash
# 1. 先启动 Chrome
./start-chrome-debug.sh

# 2. 等待 Chrome 打开并登录 Claude

# 3. 再运行 onboard
./onboard.sh
```

### 问题 3: 认证凭证未保存

**检查文件：**
```bash
# 应该存在这个文件
cat .openclaw-state/agents/main/agent/auth-profiles.json
```

**如果文件不存在或为空：**
- onboard 过程可能失败
- 重新运行 `./onboard.sh`
- 或使用手动模式粘贴 sessionKey

### 问题 4: Gateway 启动失败

**检查日志：**
```bash
tail -50 /tmp/openclaw-gateway.log
```

**常见原因：**
- 端口 3001 被占用
- 配置文件路径错误
- 缺少认证凭证

## 文件结构说明

```
openclaw-zero-token/
├── .openclaw-state/                    # 本地状态目录（不提交到 Git）
│   ├── openclaw.json                   # 主配置文件
│   ├── agents/
│   │   └── main/
│   │       └── agent/
│   │           └── auth-profiles.json  # 认证凭证（敏感信息）
│   └── workspace/                      # 工作空间
├── docs/                               # 文档目录（需要提交）
├── dist/                               # 编译输出（不提交）
├── start-chrome-debug.sh               # Chrome 调试模式启动脚本
├── onboard.sh                          # 配置向导脚本
├── server.sh                           # Gateway 服务管理脚本
└── test-claude.sh                      # Claude 测试脚本
```

## 认证原理说明

### Claude Web 认证流程

1. **浏览器启动**：
   - 启动 Chrome 调试模式（CDP 端口 9222）
   - 使用独立的用户数据目录，不影响日常使用

2. **凭证捕获**：
   - 连接到 Chrome CDP
   - 打开 https://claude.ai
   - 监听网络请求
   - 捕获 `sessionKey` cookie（格式：`sk-ant-sid02-...`）

3. **凭证存储**：
   - 将 sessionKey + userAgent + organizationId 序列化为 JSON
   - 存储到 `auth-profiles.json`：
   ```json
   {
     "profiles": {
       "claude-web:default": {
         "type": "api_key",
         "provider": "claude-web",
         "key": "{\"sessionKey\":\"sk-ant-sid02-...\",\"userAgent\":\"...\"}"
       }
     }
   }
   ```

4. **API 调用**：
   - Gateway 读取 `auth-profiles.json`
   - 使用 sessionKey 调用 Claude Web API
   - 通过真实浏览器上下文绕过 Cloudflare 检测

## 日常使用

### 启动服务
```bash
./server.sh start
```

### 停止服务
```bash
./server.sh stop
```

### 重启服务
```bash
./server.sh restart
```

### 查看状态
```bash
./server.sh status
```

### 重新配置
```bash
./onboard.sh
```

## 安全注意事项

1. **敏感文件**：
   - `.openclaw-state/` 目录已在 `.gitignore` 中
   - 不要提交 `auth-profiles.json` 到 Git
   - sessionKey 是敏感信息，不要分享

2. **会话过期**：
   - Claude sessionKey 会定期过期
   - 过期后需要重新运行 `./onboard.sh`

3. **端口安全**：
   - Gateway 默认绑定 `loopback`（仅本机访问）
   - 不要将 Gateway Token 分享给他人

## 获取帮助

如果遇到问题：
1. 查看日志：`tail -50 /tmp/openclaw-gateway.log`
2. 检查进程：`ps aux | grep openclaw`
3. 检查端口：`lsof -i:3001` 和 `lsof -i:9222`
4. 查看配置：`cat .openclaw-state/openclaw.json`

## 参考文档

- [README.md](README.md) - 项目总体说明
- [README_zh-CN.md](README_zh-CN.md) - 中文说明
- [CLAUDE_WEB_IMPLEMENTATION.md](CLAUDE_WEB_IMPLEMENTATION.md) - Claude Web 技术细节
