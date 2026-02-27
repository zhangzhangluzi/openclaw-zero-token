# 跨平台支持说明 / Platform Support

[English](#english) | [中文](#中文)

---

## 中文

### 支持的操作系统

| 平台 | 支持状态 | 说明 |
|------|---------|------|
| 🍎 macOS | ✅ 完全支持 | 有专门的设置指南 |
| 🐧 Linux | ✅ 完全支持 | 流程与 macOS 相同 |
| 🪟 Windows | ⚠️ 通过 WSL2 支持 | 推荐使用 WSL2 |

### macOS

**推荐指南：**
- 📖 [首次运行指南](SETUP_GUIDE_zh-CN.md) - 完整说明（跨平台）
- 🚀 [快速开始](QUICK_START_MAC.md) - 5 步配置

**特点：**
- 有专门的设置脚本和文档
- Chrome 路径：`/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`
- 用户目录：`/Users/username/`

### Linux

**推荐指南：**
- 📖 参考 [首次运行指南](SETUP_GUIDE_zh-CN.md)（流程完全相同）

**主要区别：**

1. **路径差异**
   ```bash
   # macOS
   /Users/username/Documents/openclaw-zero-token/
   
   # Linux
   /home/username/Documents/openclaw-zero-token/
   ```

2. **Chrome 路径**
   ```bash
   # 常见位置
   /usr/bin/google-chrome
   /opt/google/chrome/chrome
   /usr/bin/chromium
   
   # 查找 Chrome
   which google-chrome
   which chromium
   ```

3. **启动 Chrome 调试模式**
   ```bash
   # 修改 start-chrome-debug.sh 中的 Chrome 路径
   CHROME_PATH="/usr/bin/google-chrome"  # 或你的实际路径
   ```

4. **配置文件路径**
   ```json
   {
     "agents": {
       "defaults": {
         "workspace": "/home/username/Documents/openclaw-zero-token/.openclaw-state/workspace"
       }
     }
   }
   ```

**其他步骤完全相同！**

### Windows

**⚠️ 重要：不推荐在原生 Windows 上运行**

原生 Windows 可能遇到的问题：
- 路径分隔符不同（`\` vs `/`）
- 权限管理不同
- Shell 脚本不兼容
- Chrome CDP 连接可能不稳定

**推荐方案：使用 WSL2**

#### 安装 WSL2

1. **以管理员身份打开 PowerShell**

2. **运行安装命令**
   ```powershell
   wsl --install
   ```

3. **重启电脑**

4. **首次启动 WSL2**
   - 设置 Linux 用户名和密码
   - 更新系统：`sudo apt update && sudo apt upgrade`

5. **安装必需软件**
   ```bash
   # 安装 Node.js
   curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
   sudo apt-get install -y nodejs
   
   # 安装 pnpm
   npm install -g pnpm
   
   # 安装 Chrome
   wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
   sudo apt install ./google-chrome-stable_current_amd64.deb
   ```

6. **克隆项目并运行**
   ```bash
   git clone https://github.com/linuxhsj/openclaw-zero-token.git
   cd openclaw-zero-token
   pnpm install
   pnpm build
   ./onboard.sh
   ```

**WSL2 优势：**
- ✅ 完整的 Linux 环境
- ✅ 与 Windows 文件系统互通
- ✅ 性能接近原生 Linux
- ✅ 所有 Linux 工具都可用

**WSL2 资源：**
- 官方文档：https://docs.microsoft.com/zh-cn/windows/wsl/
- 安装指南：https://docs.microsoft.com/zh-cn/windows/wsl/install
- 常见问题：https://docs.microsoft.com/zh-cn/windows/wsl/faq

### 跨平台注意事项

#### 1. 路径配置

**macOS:**
```json
{
  "agents": {
    "defaults": {
      "workspace": "/Users/username/Documents/openclaw-zero-token/.openclaw-state/workspace"
    }
  }
}
```

**Linux / WSL2:**
```json
{
  "agents": {
    "defaults": {
      "workspace": "/home/username/Documents/openclaw-zero-token/.openclaw-state/workspace"
    }
  }
}
```

#### 2. Chrome 路径

修改 `start-chrome-debug.sh` 中的 Chrome 路径：

```bash
# macOS
CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Linux
CHROME_PATH="/usr/bin/google-chrome"

# 或自动检测
if [[ "$OSTYPE" == "darwin"* ]]; then
    CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
else
    CHROME_PATH=$(which google-chrome || which chromium)
fi
```

#### 3. 权限设置

所有平台都需要正确的权限：

```bash
# 设置目录权限
chmod 700 .openclaw-state/

# 设置配置文件权限
chmod 600 .openclaw-state/openclaw.json
```

#### 4. 端口检查

所有平台使用相同的命令：

```bash
# 检查端口占用
lsof -i:3001  # Gateway
lsof -i:9222  # Chrome CDP
```

---

## English

### Supported Operating Systems

| Platform | Support Status | Notes |
|----------|---------------|-------|
| 🍎 macOS | ✅ Fully Supported | Dedicated setup guides available |
| 🐧 Linux | ✅ Fully Supported | Same process as macOS |
| 🪟 Windows | ⚠️ Via WSL2 | WSL2 recommended |

### macOS

**Recommended Guides:**
- 📖 [Setup Guide](SETUP_GUIDE_zh-CN.md) - Complete instructions (Cross-platform)
- 🚀 [Quick Start](QUICK_START_MAC.md) - 5-step setup

**Characteristics:**
- Dedicated setup scripts and documentation
- Chrome path: `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`
- User directory: `/Users/username/`

### Linux

**Recommended Guide:**
- 📖 Refer to [Setup Guide](SETUP_GUIDE_zh-CN.md) (same process)

**Main Differences:**

1. **Path Differences**
   ```bash
   # macOS
   /Users/username/Documents/openclaw-zero-token/
   
   # Linux
   /home/username/Documents/openclaw-zero-token/
   ```

2. **Chrome Path**
   ```bash
   # Common locations
   /usr/bin/google-chrome
   /opt/google/chrome/chrome
   /usr/bin/chromium
   
   # Find Chrome
   which google-chrome
   which chromium
   ```

3. **Start Chrome Debug Mode**
   ```bash
   # Modify Chrome path in start-chrome-debug.sh
   CHROME_PATH="/usr/bin/google-chrome"  # or your actual path
   ```

4. **Config File Path**
   ```json
   {
     "agents": {
       "defaults": {
         "workspace": "/home/username/Documents/openclaw-zero-token/.openclaw-state/workspace"
       }
     }
   }
   ```

**All other steps are identical!**

### Windows

**⚠️ Important: Not recommended to run on native Windows**

Potential issues on native Windows:
- Different path separators (`\` vs `/`)
- Different permission management
- Shell script incompatibility
- Chrome CDP connection may be unstable

**Recommended Solution: Use WSL2**

#### Install WSL2

1. **Open PowerShell as Administrator**

2. **Run installation command**
   ```powershell
   wsl --install
   ```

3. **Restart computer**

4. **First WSL2 startup**
   - Set Linux username and password
   - Update system: `sudo apt update && sudo apt upgrade`

5. **Install required software**
   ```bash
   # Install Node.js
   curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
   sudo apt-get install -y nodejs
   
   # Install pnpm
   npm install -g pnpm
   
   # Install Chrome
   wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
   sudo apt install ./google-chrome-stable_current_amd64.deb
   ```

6. **Clone project and run**
   ```bash
   git clone https://github.com/linuxhsj/openclaw-zero-token.git
   cd openclaw-zero-token
   pnpm install
   pnpm build
   ./onboard.sh
   ```

**WSL2 Advantages:**
- ✅ Complete Linux environment
- ✅ Interoperability with Windows file system
- ✅ Performance close to native Linux
- ✅ All Linux tools available

**WSL2 Resources:**
- Official docs: https://docs.microsoft.com/en-us/windows/wsl/
- Installation guide: https://docs.microsoft.com/en-us/windows/wsl/install
- FAQ: https://docs.microsoft.com/en-us/windows/wsl/faq

### Cross-Platform Considerations

#### 1. Path Configuration

**macOS:**
```json
{
  "agents": {
    "defaults": {
      "workspace": "/Users/username/Documents/openclaw-zero-token/.openclaw-state/workspace"
    }
  }
}
```

**Linux / WSL2:**
```json
{
  "agents": {
    "defaults": {
      "workspace": "/home/username/Documents/openclaw-zero-token/.openclaw-state/workspace"
    }
  }
}
```

#### 2. Chrome Path

Modify Chrome path in `start-chrome-debug.sh`:

```bash
# macOS
CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Linux
CHROME_PATH="/usr/bin/google-chrome"

# Or auto-detect
if [[ "$OSTYPE" == "darwin"* ]]; then
    CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
else
    CHROME_PATH=$(which google-chrome || which chromium)
fi
```

#### 3. Permission Settings

All platforms require correct permissions:

```bash
# Set directory permissions
chmod 700 .openclaw-state/

# Set config file permissions
chmod 600 .openclaw-state/openclaw.json
```

#### 4. Port Checking

Same commands for all platforms:

```bash
# Check port usage
lsof -i:3001  # Gateway
lsof -i:9222  # Chrome CDP
```

---

## 总结 / Summary

- ✅ **macOS**: 开箱即用，有完整文档 / Ready to use with complete documentation
- ✅ **Linux**: 与 macOS 流程相同，只需调整路径 / Same as macOS, just adjust paths
- ⚠️ **Windows**: 必须使用 WSL2 / Must use WSL2
