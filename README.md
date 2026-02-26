# OpenClaw Zero Token

**Use AI Models Without API Tokens** - Access DeepSeek, Doubao, Claude, ChatGPT and more for free via browser login authentication.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

English | [简体中文](README_zh-CN.md)

---

## Overview

OpenClaw Zero Token is a fork of [OpenClaw](https://github.com/openclaw/openclaw) with a core mission: **eliminate API token costs** by capturing session credentials through browser automation, enabling free access to major AI platforms.

### Why Zero Token?

| Traditional Approach | Zero Token Approach |
|---------------------|---------------------|
| Requires purchasing API tokens | **Completely free** |
| Pay per API call | No usage limits |
| Credit card binding required | Only web login needed |
| Potential token leakage | Credentials stored locally |

### Supported Platforms

| Platform | Status | Models |
|----------|--------|--------|
| DeepSeek | ✅ **Currently Supported** | deepseek-chat, deepseek-reasoner |
| Doubao (豆包) | ✅ **Currently Supported** | doubao-seed-2.0, doubao-pro |
| Claude Web | ✅ **Currently Supported** | claude-3-5-sonnet-20241022, claude-3-opus-20240229, claude-3-haiku-20240307 |
| ChatGPT Web | 🔜 Coming Soon | - |

> **Note:** All web-based providers use browser automation (Playwright) for authentication and API access.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              OpenClaw Zero Token                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   Web UI    │    │  CLI/TUI    │    │   Gateway   │    │  Channels   │  │
│  │  (Lit 3.x)  │    │             │    │  (Port API) │    │ (Telegram…) │  │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘  │
│         │                  │                  │                  │          │
│         └──────────────────┴──────────────────┴──────────────────┘          │
│                                    │                                         │
│                           ┌────────▼────────┐                               │
│                           │   Agent Core    │                               │
│                           │  (PI-AI Engine) │                               │
│                           └────────┬────────┘                               │
│                                    │                                         │
│  ┌─────────────────────────────────┼─────────────────────────────────────┐  │
│  │                          Provider Layer                               │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │  │
│  │  │ DeepSeek Web │  │  Doubao Web  │  │   OpenAI     │  │ Anthropic   │  │  │
│  │  │ (Zero Token) │  │ (Zero Token) │  │   (Token)    │  │  (Token)    │  │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## How It Works

### Zero Token Authentication Flow

```
┌────────────────────────────────────────────────────────────────────────────┐
│                     DeepSeek Web Authentication Flow                        │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. Launch Browser                                                          │
│     ┌─────────────┐                                                        │
│     │ openclaw    │ ──start──▶ Chrome (CDP Port: 18892)                    │
│     │ gateway     │             with user data directory                   │
│     └─────────────┘                                                        │
│                                                                             │
│  2. User Login                                                              │
│     ┌─────────────┐                                                        │
│     │ User logs in│ ──visit──▶ https://chat.deepseek.com                   │
│     │  browser    │             scan QR / password login                    │
│     └─────────────┘                                                        │
│                                                                             │
│  3. Capture Credentials                                                     │
│     ┌─────────────┐                                                        │
│     │ Playwright  │ ──listen──▶ Network requests                           │
│     │ CDP Connect │              Intercept Authorization Header            │
│     └─────────────┘              Extract Cookies                            │
│                                                                             │
│  4. Store Credentials                                                       │
│     ┌─────────────┐                                                        │
│     │ auth.json   │ ◀──save── { cookie, bearer, userAgent }               │
│     └─────────────┘                                                        │
│                                                                             │
│  5. API Calls                                                               │
│     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐               │
│     │ DeepSeek    │ ──▶ │ DeepSeek    │ ──▶ │ chat.deep-  │               │
│     │ WebClient   │     │ Web API     │     │ seek.com    │               │
│     └─────────────┘     └─────────────┘     └─────────────┘               │
│         Using stored Cookie + Bearer Token                                  │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

### Key Technical Components

| Component | Implementation |
|-----------|----------------|
| **Browser Automation** | Playwright CDP connection to Chrome |
| **Credential Capture** | Network request interception, Authorization Header extraction |
| **PoW Challenge** | WASM SHA3 computation for anti-bot bypass |
| **Streaming Response** | SSE parsing + custom tag parser |

---

## Doubao Web Usage

Doubao integration uses **browser automation** (Playwright) for authentication and API access, similar to Claude Web.

### How It Works

```
Browser Login (Playwright)
    ↓
Capture sessionid & ttwid (Cookies)
    ↓
Keep Browser Connection Open
    ↓
Execute Requests in Browser Context (page.evaluate)
    ↓
Doubao API Response (SSE Stream)
```

**Key Features:**
- ✅ **No Proxy Required**: Direct browser-based access
- ✅ **Automatic Parameter Handling**: Browser generates dynamic parameters (msToken, a_bogus, fp, etc.)
- ✅ **Cloudflare Bypass**: Requests sent in real browser context
- ✅ **Simple Authentication**: Only needs sessionid and ttwid
- ✅ **Streaming Support**: Real-time response streaming

### Quick Start

```bash
# Step 1: Start Chrome in debug mode
./start-chrome-debug.sh

# Step 2: Configure Doubao (in another terminal)
./onboard.sh
# Select: Doubao -> Automated Login

# Step 3: Start Gateway
./server.sh start

# Step 4: Test
./test-doubao.sh "你好"

# Or open Web UI
open http://127.0.0.1:3001
```

### Available Models

| Model ID | Name | Features |
|----------|------|----------|
| `doubao-seed-2.0` | Doubao-Seed 2.0 | Supports reasoning |
| `doubao-pro` | Doubao Pro | Standard model |

### Configuration

The configuration is stored in `.openclaw-state/openclaw.json`:

```json
{
  "browser": {
    "attachOnly": true,
    "defaultProfile": "my-chrome",
    "profiles": {
      "my-chrome": {
        "cdpUrl": "http://127.0.0.1:9222"
      }
    }
  },
  "models": {
    "providers": {
      "doubao-web": {
        "baseUrl": "https://www.doubao.com",
        "api": "doubao-web",
        "models": [
          {
            "id": "doubao-seed-2.0",
            "name": "Doubao-Seed 2.0 (Web)"
          }
        ]
      }
    }
  }
}
```

### Troubleshooting

**Chrome connection failed:**
```bash
# Check if Chrome is running
ps aux | grep "chrome.*9222"

# Restart Chrome
pkill -f "chrome.*9222"
./start-chrome-debug.sh
```

**No response from Doubao:**
- Ensure Chrome window is open with Doubao.com loaded
- Check Gateway logs: `tail -50 /tmp/openclaw-gateway.log`
- Run diagnostics: `./diagnose-doubao.sh`
- Restart Gateway: `./server.sh restart`

**Session expired:**
- Re-run onboarding: `./onboard.sh`
- Select Doubao and login again

### Technical Details

For detailed technical documentation, see [DOUBAO_REFACTOR_SUMMARY.md](DOUBAO_REFACTOR_SUMMARY.md):
- Browser-based implementation following Claude's architecture
- Simplified authentication (only sessionid + ttwid)
- Code structure and modifications

---

## Quick Start

> **Platform Support:**
> - 🍎 **macOS**: 
>   - 🚀 [Quick Start Guide](QUICK_START_MAC.md) - 5-step setup
>   - 📖 [Detailed Setup Guide](SETUP_GUIDE_zh-CN.md) - Complete instructions (Cross-platform)
>   - 🔍 [Chrome Debug Mode Explained](CHROME_DEBUG_MODE_EN.md) - Why can't I see my bookmarks?
>   - ✅ Environment check: `./check-mac-setup.sh` or `./check-setup.sh`
> - 🐧 **Linux**: Follow the same process as macOS (use `/home/` instead of `/Users/` for paths)
>   - ✅ Environment check: `./check-setup.sh`
> - 🪟 **Windows**: Recommended to use WSL2 (Windows Subsystem for Linux), then follow Linux process
>   - WSL2 installation: `wsl --install` (one command, one reboot)
>   - WSL2 guide: https://docs.microsoft.com/en-us/windows/wsl/install
>   - ✅ Environment check: `./check-setup.sh`
> - 📖 [Platform Support Details](PLATFORM_SUPPORT.md)

### Requirements

- Node.js >= 22.12.0
- pnpm >= 9.0.0
- Chrome Browser
- **OS**: macOS, Linux, or Windows (WSL2)

### Script Overview

This project provides several helper scripts for different use cases:

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Script Relationships                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  First Time Setup:                                                  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ 1. pnpm install && pnpm build    # Install & compile         │  │
│  │ 2. start-chrome-debug.sh         # Start Chrome debug mode   │  │
│  │ 3. onboard.sh                    # Configuration wizard      │  │
│  │ 4. server.sh start               # Start Gateway             │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Claude Web Usage:                                                  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ 1. start-chrome-debug.sh   # Start Chrome debug mode        │  │
│  │ 2. onboard.sh              # Configure Claude Web auth      │  │
│  │ 3. server.sh start         # Start Gateway                  │  │
│  │ 4. test-claude.sh "test"   # Test Claude API                │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Daily Usage:                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ server.sh [start|stop|restart|status]                        │  │
│  │    └─→ Manage Gateway service                                │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Script Comparison:**

| Script | Purpose | When to Use | Requires Build |
|--------|---------|-------------|----------------|
| `check-mac-setup.sh` | Environment check | Before first run | ❌ No build needed |
| `start-chrome-debug.sh` | Start Chrome debug | For Claude Web | ❌ No build needed |
| `onboard.sh` | Configuration wizard | Initial config or reconfigure | ❌ Build first |
| `server.sh` | Manage Gateway service | Daily start/stop/restart | ❌ Build & configure first |
| `test-claude.sh` | Test Claude API | Verify functionality | ❌ Configure first |
| `test-chrome-connection.sh` | Test Chrome connection | Troubleshooting | ❌ No build needed |

### Installation

```bash
# Clone the repository
git clone https://github.com/linuxhsj/openclaw-zero-token.git
cd openclaw-zero-token

# Install dependencies
pnpm install
```

### Installation Steps

#### Step 1: Build

```bash
pnpm build
```

#### Step 2: Configure Authentication

```bash
# Run setup wizard
./onboard.sh

# Or use the compiled version
node openclaw.mjs onboard

# Select authentication method
? Auth provider: DeepSeek (Browser Login)

# Choose login mode
? DeepSeek Auth Mode: 
  > Automated Login (Recommended)  # Auto-capture credentials
    Manual Paste                   # Manually paste credentials
```

#### Step 3: Start Gateway

```bash
# Using helper script (recommended)
./server.sh start

# Or directly
node openclaw.mjs gateway

# Access Web UI
open http://127.0.0.1:3001
```

---

## Usage

### Web UI

Visit `http://127.0.0.1:3001` and start chatting with AI models directly.

#### Switching Models

You can switch between different AI models using the `/model` command in the chat interface:

```bash
# Switch to Claude Web
/model claude-web

# Switch to Doubao
/model doubao-web

# Switch to DeepSeek
/model deepseek-web

# Or specify a specific model
/model claude-web/claude-3-5-sonnet-20241022
/model doubao-web/doubao-seed-2.0
/model deepseek-web/deepseek-chat
```

#### Viewing Available Models

To see all configured models, use the `/models` command:

```bash
/models
```

This will display:
- All available providers (claude-web, doubao-web, deepseek-web, etc.)
- Models under each provider
- Current active model
- Model aliases and configurations

**Example output:**
```
Model                                      Input      Ctx      Local Auth  Tags
doubao-web/doubao-seed-2.0                 text       63k      no    no    default,configured,alias:Doubao Browser
claude-web/claude-3-5-sonnet-20241022      text+image 195k     no    no    configured,alias:Claude Web
deepseek-web/deepseek-chat                 text       64k      no    no    configured
```

### API Calls

```bash
# Call via Gateway Token
curl http://127.0.0.1:3001/v1/chat/completions \
  -H "Authorization: Bearer YOUR_GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-web/deepseek-chat",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### CLI Mode

```bash
# Interactive terminal
node openclaw.mjs tui
```

---

## Claude Web Usage

> **Note:** Before testing Claude Web, make sure you have completed the initial setup using `onboard.sh` to configure Claude Web authentication. See [Script Overview](#script-overview) for the relationship between different scripts.

### Quick Start (Manual Setup)

```bash
# Step 1: Start Chrome in debug mode
./start-chrome-debug.sh

# Step 2: Wait for Chrome to open and login to Claude

# Step 3: Configure (in another terminal)
./onboard.sh
# Select: Claude Web -> Automated Login

# Step 4: Start Gateway
./server.sh start

# Step 5: Test
./test-claude.sh "Hello, Claude!"

# Or open Web UI
open http://127.0.0.1:3001
```

### Manual Setup

#### Step 1: Start Chrome Debug Mode

```bash
# Start Chrome with remote debugging
./start-chrome-debug.sh

# Chrome will open with:
# - Debug port: 9222
# - Separate user profile (won't affect your daily Chrome)
# - Auto-navigate to https://claude.ai/new
```

#### Step 2: Login to Claude

1. Wait for Claude.ai to load in the opened Chrome window
2. Login with your Claude account (should auto-login if previously logged in)
3. Keep this Chrome window open

#### Step 3: Start Gateway

```bash
# Start the gateway server
./server.sh start

# Or manually:
node dist/index.mjs gateway
```

#### Step 4: Test

```bash
# Test via CLI
./test-claude.sh "Hello, Claude!"

# Or open Web UI
# Browser: http://127.0.0.1:3001/#token=62b791625fa441be036acd3c206b7e14e2bb13c803355823
```

### How It Works

**Architecture:**
```
User Request
    ↓
OpenClaw Gateway (Port 3001)
    ↓
ClaudeWebClientBrowser (Playwright)
    ↓
Chrome Debug Mode (Port 9222)
    ↓
Claude.ai API (Browser Context)
    ↓
Response (SSE Stream)
```

**Key Features:**
- ✅ **Cloudflare Bypass**: Requests sent in real browser context
- ✅ **Cookie Authentication**: Uses browser's session cookies
- ✅ **No API Token**: Completely free, no credit card required
- ✅ **Streaming Support**: Real-time response streaming
- ✅ **Separate Instance**: Independent Chrome profile, won't affect daily usage

### Configuration

The configuration is stored in `.openclaw-state/openclaw.json`:

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
  },
  "models": {
    "providers": {
      "claude-web": {
        "baseUrl": "https://claude.ai",
        "api": "claude-web",
        "models": [
          {
            "id": "claude-3-5-sonnet-20241022",
            "name": "Claude 3.5 Sonnet (Web)"
          }
        ]
      }
    }
  }
}
```

### API Calls

```bash
# Call via Gateway Token
curl http://127.0.0.1:3001/v1/chat/completions \
  -H "Authorization: Bearer YOUR_GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-web/claude-3-5-sonnet-20241022",
    "messages": [{"role": "user", "content": "Hello, Claude!"}]
  }'
```

### Available Models

Claude Web supports the following models with automatic ID mapping:

| Configuration ID | Claude Web API ID | Model Name | Recommended |
|------------------|-------------------|------------|-------------|
| `claude-3-5-sonnet-20241022` | `claude-sonnet-4-6` | Claude 3.5 Sonnet | ✅ Yes |
| `claude-3-opus-20240229` | `claude-opus-4-6` | Claude 3 Opus | - |
| `claude-3-haiku-20240307` | `claude-haiku-4-6` | Claude 3 Haiku | - |

**How it works:**
- You use the standard Anthropic model ID (e.g., `claude-3-5-sonnet-20241022`) in your configuration and API calls
- The system automatically converts it to Claude Web's internal format (e.g., `claude-sonnet-4-6`)
- This ensures compatibility with standard Anthropic API naming conventions

**Example:**
```bash
# You call with standard ID
curl http://127.0.0.1:3001/v1/chat/completions \
  -H "Authorization: Bearer YOUR_GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-web/claude-3-5-sonnet-20241022",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'

# System automatically converts to: claude-sonnet-4-6
```

### Testing Scripts

```bash
# Test Chrome connection
./test-chrome-connection.sh

# Test Claude API with custom message
./test-claude.sh "Your question here"
```

### Troubleshooting

**First Time Setup: Use Configuration Wizard**

```bash
./onboard.sh
```

**The configuration wizard will automatically create all required files and directories!**

---

**Fix Issues: Use Diagnostic Command**

**If the project has been run before but you encounter issues, run the diagnostic command:**

```bash
node dist/index.mjs doctor
```

**The diagnostic command will automatically:**
- ✅ Check all required directories
- ✅ Create missing directories
- ✅ Fix file permission issues
- ✅ Check config file integrity
- ✅ Detect multiple state directory conflicts
- ✅ Provide detailed repair suggestions

**⚠️ Important Limitations:**
- ❌ `doctor` command will **NOT** create config files (`openclaw.json`)
- ❌ `doctor` command will **NOT** create auth files (`auth-profiles.json`)
- ✅ If config files are missing or corrupted, re-run `./onboard.sh`

**When to use:**
- Directories accidentally deleted
- "Permission denied" errors
- Verify environment is normal
- Session history lost
- **NOT for first-time setup** (use `onboard.sh` instead)

**For detailed instructions:** See [Setup Guide - Troubleshooting](SETUP_GUIDE_zh-CN.md#common-issues)

---

**Chrome connection failed:**
```bash
# Check if Chrome is running
ps aux | grep "chrome.*9222"

# Restart Chrome
pkill -f "chrome.*9222"
./start-chrome-debug.sh
```

**No response from Claude:**
- Ensure Chrome window is open with Claude.ai loaded
- Check Gateway logs: `tail -50 /tmp/openclaw-gateway.log`
- Restart Gateway: `./server.sh restart`

**Model not available (403):**
- Model IDs are automatically mapped, no action needed
- If issue persists, check your Claude account subscription

### Technical Details

For detailed technical documentation, see [CLAUDE_WEB_IMPLEMENTATION.md](CLAUDE_WEB_IMPLEMENTATION.md):
- System architecture
- Cloudflare bypass principles
- SSE streaming response parsing
- Code structure and modifications

### CLI Mode

```bash
# Interactive terminal with Claude
node openclaw.mjs tui
```

---

## Configuration

### openclaw.json

```json
{
  "auth": {
    "profiles": {
      "deepseek-web:default": {
        "provider": "deepseek-web",
        "mode": "api_key"
      }
    }
  },
  "models": {
    "providers": {
      "deepseek-web": {
        "baseUrl": "https://chat.deepseek.com",
        "api": "deepseek-web",
        "models": [
          {
            "id": "deepseek-chat",
            "name": "DeepSeek Chat",
            "contextWindow": 64000,
            "maxTokens": 4096
          },
          {
            "id": "deepseek-reasoner",
            "name": "DeepSeek Reasoner",
            "reasoning": true,
            "contextWindow": 64000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "gateway": {
    "port": 3001,
    "auth": {
      "mode": "token",
      "token": "your-gateway-token"
    }
  }
}
```

---

## Roadmap

### Current Focus
- ✅ DeepSeek Web authentication (stable)
- ✅ Doubao Web browser-based authentication (stable)
- ✅ Claude Web authentication (stable)
- 🔧 Improving credential capture reliability
- 📝 Documentation improvements

### Planned Features
- 🔜 ChatGPT Web authentication support
- 🔜 Auto-refresh for expired sessions

---

## Adding New Platforms

To add support for a new platform, create the following files:

### 1. Authentication Module (`src/providers/{platform}-web-auth.ts`)

```typescript
export async function loginPlatformWeb(params: {
  onProgress: (msg: string) => void;
  openUrl: (url: string) => Promise<boolean>;
}): Promise<{ cookie: string; bearer: string; userAgent: string }> {
  // Browser automation login, capture credentials
}
```

### 2. API Client (`src/providers/{platform}-web-client.ts`)

```typescript
export class PlatformWebClient {
  constructor(options: { cookie: string; bearer?: string }) {}
  
  async chatCompletions(params: ChatParams): Promise<ReadableStream> {
    // Call platform Web API
  }
}
```

### 3. Stream Handler (`src/agents/{platform}-web-stream.ts`)

```typescript
export function createPlatformWebStreamFn(credentials: string): StreamFn {
  // Handle platform-specific response format
}
```

---

## Project Structure

```
openclaw-zero-token/
├── src/
│   ├── providers/
│   │   ├── deepseek-web-auth.ts      # DeepSeek login capture
│   │   └── deepseek-web-client.ts    # DeepSeek API client
│   ├── agents/
│   │   └── deepseek-web-stream.ts    # Streaming response handler
│   ├── commands/
│   │   └── auth-choice.apply.deepseek-web.ts  # Authentication flow
│   └── browser/
│       └── chrome.ts                 # Chrome automation
├── ui/                               # Web UI (Lit 3.x)
├── .openclaw-state/                  # Local state (not committed)
│   ├── openclaw.json                 # Configuration
│   └── agents/main/agent/
│       └── auth.json                 # Credentials (sensitive)
└── .gitignore                        # Includes .openclaw-state/
```

---

## Security Notes

1. **Credential Storage**: Cookies and Bearer tokens are stored locally in `auth.json`, **never committed to Git**
2. **Session Expiry**: Web sessions may expire and require periodic re-login
3. **Rate Limits**: Web APIs may have rate limits, not suitable for high-frequency calls
4. **Compliance**: For personal learning and research only, please comply with platform terms of service

---

## Syncing with Upstream

This project is based on OpenClaw. Sync upstream updates with:

```bash
# Add upstream repository
git remote add upstream https://github.com/openclaw/openclaw.git

# Sync upstream updates
git fetch upstream
git merge upstream/main
```

---

## Contributing

Contributions are welcome, especially:
- New platform Web authentication support (Doubao, Claude, ChatGPT, etc.)
- Bug fixes
- Documentation improvements

---

## License

[MIT License](LICENSE)

---

## Acknowledgments

- [OpenClaw](https://github.com/openclaw/openclaw) - The original project
- [DeepSeek](https://deepseek.com) - Excellent AI models

---

## Disclaimer

This project is for learning and research purposes only. When using this project to access any third-party services, please ensure compliance with that service's terms of use. The developers are not responsible for any issues arising from the use of this project.
