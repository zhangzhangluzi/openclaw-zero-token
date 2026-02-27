# Chrome 调试模式说明

## 什么是 Chrome 调试模式？

当你运行 `./start-chrome-debug.sh` 时，会启动一个**独立的 Chrome 实例**，专门用于调试和自动化。

## 重要特性

### ✅ 优点

1. **完全隔离**：不影响你的日常 Chrome 使用
2. **独立配置**：使用独立的用户数据目录
3. **调试能力**：可以通过 CDP (Chrome DevTools Protocol) 自动化控制
4. **安全性**：不会泄露你的日常浏览数据

### ❌ 缺点

1. **看不到书签**：这是一个全新的 Chrome 实例
2. **看不到历史记录**：没有你的浏览历史
3. **看不到已保存的密码**：需要重新登录网站
4. **看不到扩展程序**：没有安装任何扩展

## 为什么需要调试模式？

OpenClaw 需要通过 Chrome DevTools Protocol (CDP) 来：

1. **自动捕获认证凭证**：
   - 监听网络请求
   - 提取 Claude sessionKey
   - 自动保存到配置文件

2. **绕过 Cloudflare 检测**：
   - 使用真实浏览器上下文
   - 保持完整的浏览器指纹
   - 避免被识别为机器人

3. **保持会话活跃**：
   - 自动刷新 token
   - 处理会话过期
   - 重新认证

## 使用场景

### 场景 1：首次配置（需要调试模式）

```bash
# 1. 启动调试 Chrome
./start-chrome-debug.sh

# 2. 在打开的 Chrome 中登录 Claude
# （即使看不到书签，也要完成登录）

# 3. 运行配置向导
./onboard.sh

# 4. 系统自动捕获认证凭证
```

**这个场景必须使用调试 Chrome！**

### 场景 2：日常使用（不需要调试模式）

```bash
# 1. 启动 Gateway 服务
./server.sh start

# 2. 使用 Web UI 或 API
open http://127.0.0.1:3001

# 不需要保持 Chrome 调试模式运行
```

**日常使用时可以关闭调试 Chrome！**

### 场景 3：重新配置认证（需要调试模式）

```bash
# 1. 重新启动调试 Chrome
./start-chrome-debug.sh

# 2. 重新运行配置向导
./onboard.sh

# 3. 完成后可以关闭调试 Chrome
```

**只有在认证过期或需要重新配置时才需要！**

## 如何看到自己的书签？

如果你想在调试 Chrome 中看到自己的书签和数据，有两种方法：

### 方法 1：使用日常 Chrome 预先登录（推荐）

```bash
# 1. 在日常 Chrome 中登录 Claude
# 打开你的日常 Chrome 浏览器
# 访问 https://claude.ai
# 完成登录并保存登录状态

# 2. 启动调试 Chrome
./start-chrome-debug.sh

# 3. 调试 Chrome 可能会自动登录（如果 Chrome 同步了登录状态）
```

**注意**：这依赖于 Chrome 的账号同步功能，不一定总是有效。

### 方法 2：手动模式（不需要调试 Chrome）

```bash
# 1. 在日常 Chrome 中访问 Claude
# 打开你的日常 Chrome
# 访问 https://claude.ai 并登录

# 2. 手动提取 sessionKey
# 按 F12 打开开发者工具
# Application → Cookies → 找到 sessionKey
# 复制 sessionKey 的值（sk-ant-sid02-...）

# 3. 运行配置向导并选择手动模式
./onboard.sh
# 选择: Claude Web → Manual Paste
# 粘贴 sessionKey

# 4. 不需要启动调试 Chrome
```

**这种方法完全不需要调试 Chrome！**

### 方法 3：临时关闭调试模式（不推荐）

```bash
# 1. 关闭调试 Chrome
pkill -f "chrome.*remote-debugging-port=9222"

# 2. 使用日常 Chrome
# 现在你可以使用日常 Chrome，看到所有书签

# 3. 但是无法自动捕获认证凭证
# 需要使用手动模式（方法 2）
```

**缺点**：失去了自动化能力，每次都要手动操作。

## 技术细节

### 调试 Chrome 的启动参数

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --user-data-dir="$HOME/.openclaw-chrome-debug" \
  --no-first-run \
  --no-default-browser-check \
  https://claude.ai/new
```

**关键参数说明：**

- `--remote-debugging-port=9222`：启用 CDP 调试端口
- `--user-data-dir`：使用独立的用户数据目录（这就是为什么看不到书签）
- `--no-first-run`：跳过首次运行向导
- `--no-default-browser-check`：不检查默认浏览器

### 用户数据目录位置

```bash
# 调试 Chrome 的数据目录
~/.openclaw-chrome-debug/

# 日常 Chrome 的数据目录
~/Library/Application Support/Google/Chrome/
```

**这两个目录完全独立！**

### CDP 连接方式

```typescript
// OpenClaw 连接到调试 Chrome
const browser = await puppeteer.connect({
  browserURL: 'http://127.0.0.1:9222',
  defaultViewport: null,
});
```

## 常见问题

### Q1: 为什么看不到我的书签？

**A**: 因为调试 Chrome 使用独立的用户数据目录（`~/.openclaw-chrome-debug/`），与你的日常 Chrome（`~/Library/Application Support/Google/Chrome/`）完全隔离。

**解决方案**：
- 使用方法 1（预先登录）或方法 2（手动模式）
- 或者接受这个限制，只在配置时使用调试 Chrome

### Q2: 可以使用日常 Chrome 吗？

**A**: 不推荐。如果使用日常 Chrome 的数据目录：
- 可能会干扰你的日常使用
- 可能会导致数据冲突
- 安全风险更高

**推荐做法**：
- 配置时使用调试 Chrome（即使看不到书签）
- 日常使用时不需要 Chrome（只需要 Gateway 服务）

### Q3: 每次都要重新登录 Claude 吗？

**A**: 不一定。
- 如果 Chrome 同步了登录状态，可能会自动登录
- 如果没有同步，需要重新登录
- 登录一次后，sessionKey 会保存到配置文件，之后不需要 Chrome

### Q4: 日常使用需要保持调试 Chrome 运行吗？

**A**: 不需要！
- 配置完成后，可以关闭调试 Chrome
- Gateway 服务会使用保存的 sessionKey
- 只有在重新配置时才需要再次启动调试 Chrome

### Q5: 如何检查调试 Chrome 是否在运行？

```bash
# 检查进程
ps aux | grep "chrome.*remote-debugging-port=9222" | grep -v grep

# 检查端口
lsof -i:9222

# 测试连接
curl http://127.0.0.1:9222/json/version
```

### Q6: 如何关闭调试 Chrome？

```bash
# 方法 1: 直接关闭窗口（推荐）
# 点击 Chrome 窗口的关闭按钮

# 方法 2: 使用命令行
pkill -f "chrome.*remote-debugging-port=9222"

# 方法 3: 查找并杀掉进程
ps aux | grep "chrome.*remote-debugging-port=9222" | grep -v grep
kill <PID>
```

## 最佳实践

### ✅ 推荐做法

1. **首次配置**：
   - 使用调试 Chrome（即使看不到书签）
   - 完成自动化配置
   - 配置完成后关闭调试 Chrome

2. **日常使用**：
   - 只运行 Gateway 服务
   - 不需要 Chrome
   - 使用 Web UI 或 API

3. **重新配置**：
   - 只在认证过期时重新启动调试 Chrome
   - 完成配置后立即关闭

### ❌ 不推荐做法

1. **不要**一直保持调试 Chrome 运行（浪费资源）
2. **不要**使用日常 Chrome 的数据目录（安全风险）
3. **不要**在调试 Chrome 中进行日常浏览（数据不会保存）

## 总结

| 场景 | 是否需要调试 Chrome | 能否看到书签 | 推荐方法 |
|------|-------------------|-------------|---------|
| 首次配置 | ✅ 需要 | ❌ 看不到 | 接受限制，完成配置 |
| 日常使用 | ❌ 不需要 | N/A | 只运行 Gateway |
| 重新配置 | ✅ 需要 | ❌ 看不到 | 快速完成，立即关闭 |
| 手动配置 | ❌ 不需要 | ✅ 可以看到 | 使用日常 Chrome 手动提取 |

**核心理念**：调试 Chrome 是一个临时工具，只在配置时使用，日常使用不需要它！
