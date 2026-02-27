# 模型切换指南 / Model Switching Guide

[English](#english) | [中文](#中文)

---

## English

### Quick Reference

#### Switch Models

Use the `/model` command in the Web UI chat interface:

```bash
# Switch to a provider (uses default model)
/model claude-web
/model doubao-web
/model deepseek-web

# Switch to a specific model
/model claude-web/claude-3-5-sonnet-20241022
/model doubao-web/doubao-seed-2.0
/model deepseek-web/deepseek-chat
```

#### View Available Models

Use the `/models` command to see all configured models:

```bash
/models
```

**Example Output:**
```
Model                                      Input      Ctx      Local Auth  Tags
doubao-web/doubao-seed-2.0                 text       63k      no    no    default,configured,alias:Doubao Browser
claude-web/claude-3-5-sonnet-20241022      text+image 195k     no    no    configured,alias:Claude Web
deepseek-web/deepseek-chat                 text       64k      no    no    configured
```

### Available Models

#### Claude Web
- `claude-3-5-sonnet-20241022` - Claude 3.5 Sonnet (Recommended)
- `claude-3-opus-20240229` - Claude 3 Opus
- `claude-3-haiku-20240307` - Claude 3 Haiku

#### Doubao Web
- `doubao-seed-2.0` - Doubao-Seed 2.0 (Supports reasoning)
- `doubao-pro` - Doubao Pro

#### DeepSeek Web
- `deepseek-chat` - DeepSeek Chat
- `deepseek-reasoner` - DeepSeek Reasoner (Supports reasoning)

### Tips

1. **Default Model**: Set in `.openclaw-state/openclaw.json` under `agents.defaults.model.primary`
2. **Model Aliases**: Friendly names shown in the UI (e.g., "Doubao Browser", "Claude Web")
3. **Session Persistence**: Model selection persists within the same chat session
4. **New Session**: New sessions use the default model from config

---

## 中文

### 快速参考

#### 切换模型

在 Web UI 聊天界面中使用 `/model` 命令：

```bash
# 切换到提供商（使用默认模型）
/model claude-web
/model doubao-web
/model deepseek-web

# 切换到具体模型
/model claude-web/claude-3-5-sonnet-20241022
/model doubao-web/doubao-seed-2.0
/model deepseek-web/deepseek-chat
```

#### 查看可用模型

使用 `/models` 命令查看所有已配置的模型：

```bash
/models
```

**示例输出：**
```
Model                                      Input      Ctx      Local Auth  Tags
doubao-web/doubao-seed-2.0                 text       63k      no    no    default,configured,alias:Doubao Browser
claude-web/claude-3-5-sonnet-20241022      text+image 195k     no    no    configured,alias:Claude Web
deepseek-web/deepseek-chat                 text       64k      no    no    configured
```

### 可用模型

#### Claude Web
- `claude-3-5-sonnet-20241022` - Claude 3.5 Sonnet（推荐）
- `claude-3-opus-20240229` - Claude 3 Opus
- `claude-3-haiku-20240307` - Claude 3 Haiku

#### Doubao Web（豆包）
- `doubao-seed-2.0` - Doubao-Seed 2.0（支持推理）
- `doubao-pro` - Doubao Pro

#### DeepSeek Web
- `deepseek-chat` - DeepSeek Chat
- `deepseek-reasoner` - DeepSeek Reasoner（支持推理）

### 使用技巧

1. **默认模型**：在 `.openclaw-state/openclaw.json` 的 `agents.defaults.model.primary` 中设置
2. **模型别名**：UI 中显示的友好名称（如 "Doubao Browser"、"Claude Web"）
3. **会话持久化**：模型选择在同一聊天会话中保持
4. **新会话**：新会话使用配置文件中的默认模型

---

## Configuration File Location

配置文件位置：`.openclaw-state/openclaw.json`

**Example / 示例：**

```json
{
  "models": {
    "providers": {
      "claude-web": {
        "baseUrl": "https://claude.ai",
        "api": "claude-web",
        "models": [...]
      },
      "doubao-web": {
        "baseUrl": "https://www.doubao.com",
        "api": "doubao-web",
        "models": [...]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "doubao-web/doubao-seed-2.0"
      }
    }
  }
}
```

---

## Troubleshooting / 故障排查

### Model Not Available / 模型不可用

**English:**
1. Check if the provider is configured: `/models`
2. Verify authentication: Check `.openclaw-state/agents/main/agent/auth-profiles.json`
3. Ensure Chrome debug mode is running (for web-based providers)
4. Restart Gateway: `./server.sh restart`

**中文：**
1. 检查提供商是否已配置：`/models`
2. 验证认证：检查 `.openclaw-state/agents/main/agent/auth-profiles.json`
3. 确保 Chrome 调试模式正在运行（对于基于浏览器的提供商）
4. 重启 Gateway：`./server.sh restart`

### No Response / 没有响应

**English:**
1. Switch to the correct model: `/model <provider>`
2. Check Gateway logs: `tail -50 /tmp/openclaw-gateway.log`
3. Verify browser is logged in (for web-based providers)
4. Run diagnostics: `./diagnose-doubao.sh` (for Doubao)

**中文：**
1. 切换到正确的模型：`/model <provider>`
2. 检查 Gateway 日志：`tail -50 /tmp/openclaw-gateway.log`
3. 验证浏览器已登录（对于基于浏览器的提供商）
4. 运行诊断：`./diagnose-doubao.sh`（针对豆包）

---

## See Also / 相关文档

- [README.md](README.md) - Main documentation
- [README_zh-CN.md](README_zh-CN.md) - 中文文档
- [DOUBAO_REFACTOR_SUMMARY.md](DOUBAO_REFACTOR_SUMMARY.md) - Doubao refactoring details
