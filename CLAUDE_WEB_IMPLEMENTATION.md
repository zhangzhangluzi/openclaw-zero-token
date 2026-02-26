# Claude Web 免费访问实现文档 / Claude Web Free Access Implementation

[中文](#中文文档) | [English](#english-documentation)

---

## 中文文档

### 📋 项目概述

本项目实现了通过浏览器 cookie 认证访问 Claude AI，绕过 API token 付费限制，实现免费使用 Claude。

**核心技术：**
- Playwright 浏览器自动化
- Chrome DevTools Protocol (CDP)
- Server-Sent Events (SSE) 流式响应解析
- 浏览器指纹伪装

### 🎯 实现目标

1. ✅ 绕过 Cloudflare 反爬虫检测
2. ✅ 使用浏览器 cookie 认证（无需 API token）
3. ✅ 支持流式响应
4. ✅ 兼容 OpenClaw Gateway
5. ✅ 提供命令行和 Web UI 两种使用方式

### 🏗️ 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                     用户 / User                              │
└───────────────┬─────────────────────────────────────────────┘
                │
                ├─────────────┐
                │             │
        ┌───────▼──────┐  ┌──▼──────────┐
        │   Web UI     │  │  CLI Tool   │
        │ (Browser)    │  │ (Terminal)  │
        └───────┬──────┘  └──┬──────────┘
                │            │
                └────────┬───┘
                         │
                ┌────────▼─────────┐
                │ OpenClaw Gateway │
                │   (Port 3001)    │
                └────────┬─────────┘
                         │
                ┌────────▼──────────────┐
                │ Claude Web Client     │
                │ (Browser Version)     │
                └────────┬──────────────┘
                         │
                ┌────────▼──────────────┐
                │    Playwright         │
                │  (CDP Connection)     │
                └────────┬──────────────┘
                         │
                ┌────────▼──────────────┐
                │  Chrome Debug Mode    │
                │    (Port 9222)        │
                └────────┬──────────────┘
                         │
                ┌────────▼──────────────┐
                │   Claude.ai API       │
                │ (Browser Context)     │
                └───────────────────────┘
```

### 🔄 工作流程

#### 1. 初始化阶段
```
用户运行首次配置流程
    ↓
启动 Chrome 调试模式 (端口 9222)
    ./start-chrome-debug.sh
    ↓
自动打开 Claude.ai 并登录
    ↓
启动 OpenClaw Gateway (端口 3001)
    ↓
Gateway 通过 Playwright 连接到 Chrome
```

#### 2. 请求处理流程
```
用户发送消息
    ↓
Gateway 接收请求
    ↓
ClaudeWebClientBrowser.ensureBrowser()
    ├─ 连接到 Chrome (CDP)
    ├─ 查找 Claude.ai 标签页
    └─ 获取浏览器上下文
    ↓
创建对话 (POST /chat_conversations)
    ↓
发送消息 (POST /completion)
    ├─ 在浏览器上下文中执行 fetch
    ├─ 使用浏览器的 cookie 和指纹
    └─ 接收 SSE 流式响应
    ↓
解析响应 (claude-web-stream.ts)
    ├─ 解析 event: message_start
    ├─ 解析 data: content_block_delta
    └─ 提取文本内容
    ↓
返回给用户
```


### 🔑 核心技术原理

#### 1. Cloudflare 绕过原理

**问题：** 直接使用 Node.js `fetch` 发送请求会被 Cloudflare 检测并返回 403。

**原因：**
- TLS 指纹不匹配（Node.js vs 真实浏览器）
- HTTP/2 指纹不匹配
- 缺少浏览器特征（User-Agent、sec-ch-ua 等）
- Cookie 中的 `cf_clearance` 与请求环境不匹配

**解决方案：**
```javascript
// 在真实浏览器上下文中执行 fetch
const responseData = await page.evaluate(async ({ url, body, deviceId }) => {
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Accept": "text/event-stream",
      "anthropic-client-platform": "web_claude_ai",
      "anthropic-device-id": deviceId,
    },
    body: JSON.stringify(body),
  });
  // ... 处理响应
}, { url, body, deviceId });
```

**优势：**
- 使用真实浏览器的 TLS 和 HTTP/2 指纹
- 自动携带浏览器的所有 cookie
- 完全模拟真实用户行为

#### 2. Chrome 调试模式连接

**启动 Chrome：**
```bash
chrome --remote-debugging-port=9222 \
       --user-data-dir="~/.config/chrome-openclaw-debug"
```

**Playwright 连接：**
```javascript
const wsUrl = await getChromeWebSocketUrl('http://127.0.0.1:9222');
const browser = await chromium.connectOverCDP(wsUrl);
const context = browser.contexts()[0];
const page = context.pages().find(p => p.url().includes('claude.ai'));
```

#### 3. 模型 ID 映射

Claude Web API 使用的模型 ID 与配置中的不同，系统会自动转换：

| 配置 ID（用户使用） | Claude Web API ID（内部转换） | 模型名称 | 推荐 |
|-------------------|----------------------------|---------|------|
| `claude-3-5-sonnet-20241022` | `claude-sonnet-4-6` | Claude 3.5 Sonnet | ✅ |
| `claude-3-opus-20240229` | `claude-opus-4-6` | Claude 3 Opus | - |
| `claude-3-haiku-20240307` | `claude-haiku-4-6` | Claude 3 Haiku | - |

**为什么需要映射？**
- 用户配置使用标准的 Anthropic 模型 ID（带日期后缀）
- Claude Web API 内部使用简化的版本号格式
- 自动映射确保用户体验一致，无需记忆两套 ID

**实现代码：**
```typescript
// src/providers/claude-web-client-browser.ts
let modelId = params.model || "claude-sonnet-4-6";
if (modelId.includes("claude-3-5-sonnet")) {
  modelId = "claude-sonnet-4-6";  // 自动转换
} else if (modelId.includes("claude-3-opus")) {
  modelId = "claude-opus-4-6";
} else if (modelId.includes("claude-3-haiku")) {
  modelId = "claude-haiku-4-6";
}
```

**使用示例：**
```bash
# 用户使用标准 ID
curl http://127.0.0.1:3001/v1/chat/completions \
  -d '{"model": "claude-web/claude-3-5-sonnet-20241022", ...}'

# 系统自动转换为 claude-sonnet-4-6 发送给 Claude Web API
```

#### 4. SSE 流式响应解析

**响应格式：**
```
event: message_start
data: {"type":"message_start","message":{...}}

event: content_block_start
data: {"type":"content_block_start","index":0,...}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"你好"}}

event: content_block_stop
data: {"type":"content_block_stop","index":0}

event: message_stop
data: {"type":"message_stop"}
```

**解析逻辑：**
```javascript
const processLine = (line: string) => {
  if (!line || !line.startsWith("data: ")) return;
  
  const data = JSON.parse(line.slice(6));
  
  if (data.type === "content_block_delta" && data.delta?.text) {
    const delta = data.delta.text;
    accumulatedContent += delta;
    stream.push({ type: "text_delta", delta, ... });
  }
};
```


### 📁 代码结构

```
openclaw-zero-token/
├── src/
│   ├── providers/
│   │   ├── claude-web-auth.ts              # Claude 登录认证
│   │   ├── claude-web-client.ts            # 原始客户端（fetch）
│   │   └── claude-web-client-browser.ts    # 浏览器版客户端（Playwright）⭐
│   ├── agents/
│   │   ├── claude-web-stream.ts            # 流式响应处理 ⭐
│   │   └── models-config.providers.ts      # 模型配置 ⭐
│   └── commands/
│       └── auth-choice.apply.claude-web.ts # 认证配置应用
├── .openclaw-state/
│   ├── openclaw.json                       # 主配置 ⭐
│   └── agents/main/agent/
│       └── auth-profiles.json              # 认证信息
├── start-chrome-debug.sh                   # Chrome 启动脚本 ⭐
├── test-chrome-connection.sh               # 连接测试
├── test-claude.sh                          # API 测试
├── server.sh                               # Gateway 管理

⭐ = 核心修改文件
```

### 🔧 关键代码修改

#### 1. `src/providers/claude-web-client-browser.ts`

**主要修改：**
- 支持 `attachOnly` 模式
- 自动查找 Claude.ai 标签页
- 模型 ID 映射
- 在浏览器上下文中执行请求

**关键代码：**
```typescript
private async ensureBrowser() {
  const browserConfig = resolveBrowserConfig(rootConfig.browser, rootConfig);
  
  if (browserConfig.attachOnly) {
    // 连接到已运行的 Chrome
    const wsUrl = await getChromeWebSocketUrl(profile.cdpUrl, 2000);
    this.browser = await chromium.connectOverCDP(wsUrl);
    
    // 查找 Claude.ai 标签页
    const pages = this.browser.pages();
    let claudePage = pages.find(p => p.url().includes('claude.ai'));
    
    if (claudePage) {
      this.page = claudePage;
    } else {
      this.page = await this.browser.newPage();
      await this.page.goto('https://claude.ai/new');
    }
  }
}
```

#### 2. `src/agents/claude-web-stream.ts`

**主要修改：**
- 导入 `ClaudeWebClientBrowser`
- 支持 `content_block_delta` 类型

**关键代码：**
```typescript
import { ClaudeWebClientBrowser } from "../providers/claude-web-client-browser.js";

const processLine = (line: string) => {
  const data = JSON.parse(dataStr);
  
  // 新 API 格式
  if (data.type === "content_block_delta" && data.delta?.text) {
    const delta = data.delta.text;
    contentParts[contentIndex].text += delta;
    stream.push({ type: "text_delta", delta, ... });
  }
  // 旧 API 格式（兼容）
  else if (data.type === "completion" && data.completion) {
    // ...
  }
};
```

#### 3. `.openclaw-state/openclaw.json`

**主要修改：**
```json
{
  "browser": {
    "attachOnly": true,
    "defaultProfile": "my-chrome",
    "profiles": {
      "my-chrome": {
        "cdpUrl": "http://127.0.0.1:9222",
        "color": "#4285F4"
      }
    }
  }
}
```


### 🧪 测试方法

#### 方法 1：一键测试（推荐）

```bash
# 手动测试流程
# 1. 启动 Chrome 调试模式
./start-chrome-debug.sh

# 2. 配置 Claude Web（在另一个终端）
./onboard.sh

# 3. 启动 Gateway
./server.sh start

# 4. 测试 API
./test-claude.sh "你好，Claude！"
```

#### 方法 2：分步测试

```bash
# 1. 启动 Chrome 调试模式
./start-chrome-debug.sh

# 2. 启动 Gateway
./server.sh start

# 3. 测试 API
./test-claude.sh "你的问题"

# 4. 或使用 Web UI
# 浏览器访问：http://127.0.0.1:3001/#token=62b791625fa441be036acd3c206b7e14e2bb13c803355823
```

#### 方法 3：命令行快速测试

```bash
# 编译并重启
pnpm build && ./server.sh restart && sleep 5

# 测试
./test-claude.sh "$(shuf -n 1 test-messages.txt)"
```

### 📊 测试验证

**成功标志：**
```
✓ Chrome 调试端口响应正常
✓ 检测到 1 个 Claude 标签页
✓ Gateway 已启动
✓ 成功！完整响应：
Claude 回复：[实际的回复内容]
```

**日志验证：**
```bash
tail -50 /tmp/openclaw-gateway.log | grep "Claude Web Browser"

# 应该看到：
# [Claude Web Browser] Connecting to existing Chrome at http://127.0.0.1:9222
# [Claude Web Browser] Found existing Claude page: https://claude.ai/new
# [Claude Web Browser] Connected to existing Chrome successfully
# [Claude Web Browser] Message response: 200
# [Claude Web Browser] Response data length: 1732 bytes
```

### ⚠️ 常见问题

#### 1. Chrome 连接失败

**症状：** `Failed to connect to Chrome at http://127.0.0.1:9222`

**解决：**
```bash
# 检查 Chrome 是否运行
ps aux | grep "chrome.*9222"

# 重启 Chrome
pkill -f "chrome.*9222"
./start-chrome-debug.sh
```

#### 2. 模型不可用 (403)

**症状：** `model_not_available`

**原因：** 模型 ID 不匹配

**解决：** 已在代码中自动映射，确保使用最新代码

#### 3. 无响应 (No response)

**症状：** `No response from OpenClaw`

**原因：** Gateway 未完全启动

**解决：** 增加等待时间（建议等待 5 秒后再测试）


### 🎯 性能优化

1. **连接复用**：Playwright 连接保持，避免重复连接
2. **标签页查找**：优先使用已存在的 Claude 标签页
3. **独立用户目录**：避免与日常 Chrome 冲突
4. **随机测试消息**：避免重复请求被检测

### 🔒 安全考虑

1. **Cookie 安全**：Cookie 存储在本地，不上传到服务器
2. **独立实例**：使用独立的 Chrome 实例，不影响日常浏览
3. **本地运行**：所有请求在本地执行，不经过第三方服务器
4. **随机化**：测试消息随机化，模拟真实用户行为

---

## English Documentation

### 📋 Project Overview

This project implements free access to Claude AI using browser cookie authentication, bypassing the paid API token requirement.

**Core Technologies:**
- Playwright browser automation
- Chrome DevTools Protocol (CDP)
- Server-Sent Events (SSE) streaming response parsing
- Browser fingerprint spoofing

### 🎯 Implementation Goals

1. ✅ Bypass Cloudflare anti-bot detection
2. ✅ Use browser cookie authentication (no API token required)
3. ✅ Support streaming responses
4. ✅ Compatible with OpenClaw Gateway
5. ✅ Provide both CLI and Web UI interfaces

### 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        User                                  │
└───────────────┬─────────────────────────────────────────────┘
                │
                ├─────────────┐
                │             │
        ┌───────▼──────┐  ┌──▼──────────┐
        │   Web UI     │  │  CLI Tool   │
        │ (Browser)    │  │ (Terminal)  │
        └───────┬──────┘  └──┬──────────┘
                │            │
                └────────┬───┘
                         │
                ┌────────▼─────────┐
                │ OpenClaw Gateway │
                │   (Port 3001)    │
                └────────┬─────────┘
                         │
                ┌────────▼──────────────┐
                │ Claude Web Client     │
                │ (Browser Version)     │
                └────────┬──────────────┘
                         │
                ┌────────▼──────────────┐
                │    Playwright         │
                │  (CDP Connection)     │
                └────────┬──────────────┘
                         │
                ┌────────▼──────────────┐
                │  Chrome Debug Mode    │
                │    (Port 9222)        │
                └────────┬──────────────┘
                         │
                ┌────────▼──────────────┐
                │   Claude.ai API       │
                │ (Browser Context)     │
                └───────────────────────┘
```

### 🔄 Workflow

#### 1. Initialization Phase
```
User runs first-time setup
    ↓
Start Chrome in debug mode (port 9222)
    ./start-chrome-debug.sh
    ↓
Auto-open Claude.ai and login
    ↓
Start OpenClaw Gateway (port 3001)
    ↓
Gateway connects to Chrome via Playwright
```

#### 2. Request Processing Flow
```
User sends message
    ↓
Gateway receives request
    ↓
ClaudeWebClientBrowser.ensureBrowser()
    ├─ Connect to Chrome (CDP)
    ├─ Find Claude.ai tab
    └─ Get browser context
    ↓
Create conversation (POST /chat_conversations)
    ↓
Send message (POST /completion)
    ├─ Execute fetch in browser context
    ├─ Use browser's cookies and fingerprint
    └─ Receive SSE streaming response
    ↓
Parse response (claude-web-stream.ts)
    ├─ Parse event: message_start
    ├─ Parse data: content_block_delta
    └─ Extract text content
    ↓
Return to user
```


### 🔑 Core Technical Principles

#### 1. Cloudflare Bypass Principle

**Problem:** Direct Node.js `fetch` requests are detected by Cloudflare and return 403.

**Reasons:**
- TLS fingerprint mismatch (Node.js vs real browser)
- HTTP/2 fingerprint mismatch
- Missing browser characteristics (User-Agent, sec-ch-ua, etc.)
- `cf_clearance` cookie doesn't match request environment

**Solution:**
```javascript
// Execute fetch in real browser context
const responseData = await page.evaluate(async ({ url, body, deviceId }) => {
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Accept": "text/event-stream",
      "anthropic-client-platform": "web_claude_ai",
      "anthropic-device-id": deviceId,
    },
    body: JSON.stringify(body),
  });
  // ... handle response
}, { url, body, deviceId });
```

**Advantages:**
- Uses real browser's TLS and HTTP/2 fingerprints
- Automatically carries all browser cookies
- Fully simulates real user behavior

#### 2. Chrome Debug Mode Connection

**Start Chrome:**
```bash
chrome --remote-debugging-port=9222 \
       --user-data-dir="~/.config/chrome-openclaw-debug"
```

**Playwright Connection:**
```javascript
const wsUrl = await getChromeWebSocketUrl('http://127.0.0.1:9222');
const browser = await chromium.connectOverCDP(wsUrl);
const context = browser.contexts()[0];
const page = context.pages().find(p => p.url().includes('claude.ai'));
```

#### 3. Model ID Mapping

Claude Web API uses different model IDs than configuration, with automatic conversion:

| Config ID (User-Facing) | Claude Web API ID (Internal) | Model Name | Recommended |
|-------------------------|------------------------------|------------|-------------|
| `claude-3-5-sonnet-20241022` | `claude-sonnet-4-6` | Claude 3.5 Sonnet | ✅ |
| `claude-3-opus-20240229` | `claude-opus-4-6` | Claude 3 Opus | - |
| `claude-3-haiku-20240307` | `claude-haiku-4-6` | Claude 3 Haiku | - |

**Why mapping is needed:**
- User configuration uses standard Anthropic model IDs (with date suffix)
- Claude Web API internally uses simplified version format
- Automatic mapping ensures consistent user experience without memorizing two ID systems

**Implementation:**
```typescript
// src/providers/claude-web-client-browser.ts
let modelId = params.model || "claude-sonnet-4-6";
if (modelId.includes("claude-3-5-sonnet")) {
  modelId = "claude-sonnet-4-6";  // Auto-convert
} else if (modelId.includes("claude-3-opus")) {
  modelId = "claude-opus-4-6";
} else if (modelId.includes("claude-3-haiku")) {
  modelId = "claude-haiku-4-6";
}
```

**Usage Example:**
```bash
# User calls with standard ID
curl http://127.0.0.1:3001/v1/chat/completions \
  -d '{"model": "claude-web/claude-3-5-sonnet-20241022", ...}'

# System automatically converts to claude-sonnet-4-6 for Claude Web API
```

#### 4. SSE Streaming Response Parsing

**Response Format:**
```
event: message_start
data: {"type":"message_start","message":{...}}

event: content_block_start
data: {"type":"content_block_start","index":0,...}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}

event: content_block_stop
data: {"type":"content_block_stop","index":0}

event: message_stop
data: {"type":"message_stop"}
```

**Parsing Logic:**
```javascript
const processLine = (line: string) => {
  if (!line || !line.startsWith("data: ")) return;
  
  const data = JSON.parse(line.slice(6));
  
  if (data.type === "content_block_delta" && data.delta?.text) {
    const delta = data.delta.text;
    accumulatedContent += delta;
    stream.push({ type: "text_delta", delta, ... });
  }
};
```

### 🧪 Testing Methods

#### Method 1: One-Click Test (Recommended)

```bash
# Manual testing process
# 1. Start Chrome debug mode
./start-chrome-debug.sh

# 2. Configure Claude Web (in another terminal)
./onboard.sh

# 3. Start Gateway
./server.sh start

# 4. Test API
./test-claude.sh "Hello, Claude!"
```

#### Method 2: Step-by-step Testing

```bash
# 1. Start Chrome debug mode
./start-chrome-debug.sh

# 2. Start Gateway
./server.sh start

# 3. Test API
./test-claude.sh "Your question"

# 4. Or use Web UI
# Browser: http://127.0.0.1:3001/#token=62b791625fa441be036acd3c206b7e14e2bb13c803355823
```

### 📊 Test Verification

**Success Indicators:**
```
✓ Chrome debug port responding normally
✓ Detected 1 Claude tab
✓ Gateway started
✓ Success! Complete response:
Claude reply: [actual reply content]
```

**Log Verification:**
```bash
tail -50 /tmp/openclaw-gateway.log | grep "Claude Web Browser"

# Should see:
# [Claude Web Browser] Connecting to existing Chrome at http://127.0.0.1:9222
# [Claude Web Browser] Found existing Claude page: https://claude.ai/new
# [Claude Web Browser] Connected to existing Chrome successfully
# [Claude Web Browser] Message response: 200
# [Claude Web Browser] Response data length: 1732 bytes
```

### 🎯 Performance Optimization

1. **Connection Reuse**: Playwright connection persists, avoiding repeated connections
2. **Tab Finding**: Prioritize existing Claude tabs
3. **Separate User Directory**: Avoid conflicts with daily Chrome usage
4. **Random Test Messages**: Avoid repeated requests being detected

### 🔒 Security Considerations

1. **Cookie Security**: Cookies stored locally, not uploaded to servers
2. **Isolated Instance**: Uses separate Chrome instance, doesn't affect daily browsing
3. **Local Execution**: All requests executed locally, no third-party servers
4. **Randomization**: Test messages randomized to simulate real user behavior

---

## 📝 Summary

Successfully implemented free Claude AI access using browser cookie authentication, completely bypassing Cloudflare anti-bot detection. The solution works with both Web UI and CLI, providing a seamless user experience.

**Key Achievements:**
- ✅ Zero API token cost
- ✅ Cloudflare bypass
- ✅ Streaming response support
- ✅ Production-ready implementation

