#!/bin/bash
# 跨平台环境检查脚本 - 首次运行前使用
# Cross-platform environment check script

# 检测操作系统
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_NAME="macOS"
    CHROME_PATHS=(
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    )
    USER_DIR_PREFIX="/Users"
elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "linux"* ]]; then
    OS_NAME="Linux"
    CHROME_PATHS=(
        "/usr/bin/google-chrome"
        "/usr/bin/google-chrome-stable"
        "/usr/bin/chromium"
        "/usr/bin/chromium-browser"
        "/opt/google/chrome/chrome"
        "/opt/apps/cn.google.chrome-pre/files/google/chrome/google-chrome"
    )
    USER_DIR_PREFIX="/home"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    OS_NAME="Windows (Git Bash/Cygwin)"
    echo "=========================================="
    echo "  ⚠️  检测到 Windows 环境"
    echo "=========================================="
    echo ""
    echo "强烈推荐使用 WSL2 (Windows Subsystem for Linux)"
    echo ""
    echo "安装 WSL2："
    echo "  1. 以管理员身份打开 PowerShell"
    echo "  2. 运行: wsl --install"
    echo "  3. 重启电脑"
    echo "  4. 在 WSL2 中运行此脚本"
    echo ""
    echo "WSL2 指南: https://docs.microsoft.com/zh-cn/windows/wsl/install"
    echo ""
    read -p "是否继续检查当前环境? [y/N]: " continue_check
    if [[ ! "$continue_check" =~ ^[Yy]$ ]]; then
        exit 0
    fi
    CHROME_PATHS=(
        "/c/Program Files/Google/Chrome/Application/chrome.exe"
        "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"
    )
    USER_DIR_PREFIX="/c/Users"
else
    OS_NAME="Unknown ($OSTYPE)"
    CHROME_PATHS=()
    USER_DIR_PREFIX="$HOME"
fi

echo "=========================================="
echo "  OpenClaw Zero Token - 环境检查"
echo "  Environment Check"
echo "=========================================="
echo ""
echo "操作系统 / OS: $OS_NAME"
echo ""

ERRORS=0
WARNINGS=0

# 检查 Node.js 版本
echo "1. 检查 Node.js 版本 / Checking Node.js version..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version | sed 's/v//')
    REQUIRED_VERSION="22.12.0"
    
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$NODE_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
        echo "   ✓ Node.js $NODE_VERSION (满足要求 >= $REQUIRED_VERSION)"
    else
        echo "   ✗ Node.js $NODE_VERSION (需要 >= $REQUIRED_VERSION)"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ✗ Node.js 未安装 / Node.js not installed"
    echo "      安装指南 / Installation: https://nodejs.org/"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 检查 pnpm
echo "2. 检查 pnpm / Checking pnpm..."
if command -v pnpm &> /dev/null; then
    PNPM_VERSION=$(pnpm --version)
    echo "   ✓ pnpm $PNPM_VERSION"
else
    echo "   ✗ pnpm 未安装 / pnpm not installed"
    echo "      安装命令 / Install: npm install -g pnpm"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 检查 Chrome
echo "3. 检查 Google Chrome / Checking Chrome..."
CHROME_FOUND=false
CHROME_PATH_FOUND=""

for path in "${CHROME_PATHS[@]}"; do
    if [ -f "$path" ] || command -v "$(basename "$path")" &> /dev/null; then
        CHROME_FOUND=true
        CHROME_PATH_FOUND="$path"
        break
    fi
done

if [ "$CHROME_FOUND" = true ]; then
    echo "   ✓ Chrome 已安装 / Chrome installed"
    echo "      路径 / Path: $CHROME_PATH_FOUND"
else
    echo "   ✗ Chrome 未找到 / Chrome not found"
    echo "      请安装 Chrome / Please install Chrome"
    if [[ "$OS_NAME" == "Linux" ]]; then
        echo "      Ubuntu/Debian: sudo apt install google-chrome-stable"
        echo "      或下载 / Or download: https://www.google.com/chrome/"
    elif [[ "$OS_NAME" == "macOS" ]]; then
        echo "      下载 / Download: https://www.google.com/chrome/"
    fi
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 检查必需目录
echo "4. 检查必需目录 / Checking required directories..."
if [ -d "docs" ]; then
    echo "   ✓ docs/ 目录存在"
else
    echo "   ⚠ docs/ 目录不存在（将自动创建）"
    mkdir -p docs/reference/templates
    echo "   ✓ 已创建 docs/ 目录"
    WARNINGS=$((WARNINGS + 1))
fi

if [ -d ".openclaw-state" ]; then
    echo "   ✓ .openclaw-state/ 目录存在"
else
    echo "   ⚠ .openclaw-state/ 目录不存在（首次运行时会自动创建）"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 检查编译输出
echo "5. 检查项目编译状态 / Checking build status..."
if [ -d "dist" ] && [ -f "dist/index.mjs" ]; then
    echo "   ✓ 项目已编译 / Project built"
else
    echo "   ⚠ 项目未编译 / Project not built"
    echo "      运行命令 / Run: pnpm build"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 检查端口占用
echo "6. 检查端口占用 / Checking ports..."
if command -v lsof &> /dev/null; then
    if lsof -i:3001 > /dev/null 2>&1; then
        echo "   ⚠ 端口 3001 已被占用 / Port 3001 in use (Gateway port)"
        lsof -i:3001 | grep LISTEN
        WARNINGS=$((WARNINGS + 1))
    else
        echo "   ✓ 端口 3001 可用 / Port 3001 available"
    fi

    if lsof -i:9222 > /dev/null 2>&1; then
        echo "   ⚠ 端口 9222 已被占用 / Port 9222 in use (Chrome CDP port)"
        lsof -i:9222 | grep LISTEN
        WARNINGS=$((WARNINGS + 1))
    else
        echo "   ✓ 端口 9222 可用 / Port 9222 available"
    fi
else
    echo "   ⚠ lsof 命令不可用，跳过端口检查"
    echo "      Linux: sudo apt install lsof"
fi
echo ""

# 检查系统级 OpenClaw 服务（仅 macOS 和 Linux）
if [[ "$OS_NAME" == "macOS" ]]; then
    echo "7. 检查系统级 OpenClaw 服务 / Checking system OpenClaw..."
    if launchctl list | grep -q "openclaw"; then
        echo "   ⚠ 检测到系统级 OpenClaw 服务正在运行"
        launchctl list | grep openclaw
        echo ""
        echo "      建议停止系统服务以避免冲突（按优先级）："
        echo "      1. openclaw gateway stop          # 推荐，最简单"
        echo "      2. launchctl stop ai.openclaw.gateway  # 备选方案"
        echo "      3. pkill -f openclaw-gateway      # 最后手段"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "   ✓ 无系统级 OpenClaw 服务冲突"
    fi
    echo ""
elif [[ "$OS_NAME" == "Linux" ]]; then
    echo "7. 检查系统级 OpenClaw 服务 / Checking system OpenClaw..."
    if systemctl is-active --quiet openclaw 2>/dev/null || pgrep -f "openclaw.*gateway" > /dev/null; then
        echo "   ⚠ 检测到系统级 OpenClaw 服务正在运行"
        echo "      建议停止系统服务："
        echo "      sudo systemctl stop openclaw"
        echo "      或: pkill -f openclaw-gateway"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "   ✓ 无系统级 OpenClaw 服务冲突"
    fi
    echo ""
fi

# 检查配置文件
echo "8. 检查配置文件 / Checking config files..."
if [ -f ".openclaw-state/openclaw.json" ]; then
    echo "   ✓ 配置文件存在 / Config file exists"
    
    # 检查路径是否正确
    if grep -q "$USER_DIR_PREFIX/" ".openclaw-state/openclaw.json"; then
        echo "   ✓ 配置文件使用正确的路径 / Config uses correct paths"
    else
        echo "   ⚠ 配置文件路径可能需要调整"
        echo "      应该使用 / Should use: $USER_DIR_PREFIX/username/..."
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # 检查是否有认证凭证
    if [ -f ".openclaw-state/agents/main/agent/auth-profiles.json" ]; then
        echo "   ✓ 认证凭证文件存在 / Auth file exists"
    else
        echo "   ⚠ 认证凭证文件不存在（需要运行 onboard.sh）"
        echo "      Need to run: ./onboard.sh"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "   ⚠ 配置文件不存在（首次运行时会自动创建）"
    echo "      Will be created on first run"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 总结
echo "=========================================="
echo "  检查完成 / Check Complete"
echo "=========================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✓ 所有检查通过！可以开始运行项目。"
    echo "✓ All checks passed! Ready to run."
    echo ""
    echo "下一步 / Next steps:"
    echo "  1. 如果未编译 / If not built: pnpm build"
    echo "  2. 启动 Chrome / Start Chrome: ./start-chrome-debug.sh"
    echo "  3. 配置项目 / Configure: ./onboard.sh"
    echo "  4. 启动服务 / Start service: ./server.sh start"
elif [ $ERRORS -eq 0 ]; then
    echo "⚠ 发现 $WARNINGS 个警告，但可以继续。"
    echo "⚠ Found $WARNINGS warning(s), but can continue."
    echo ""
    echo "建议操作 / Recommended actions:"
    if [ ! -d "dist" ]; then
        echo "  - 编译项目 / Build: pnpm build"
    fi
    if lsof -i:3001 > /dev/null 2>&1 || lsof -i:9222 > /dev/null 2>&1; then
        echo "  - 停止占用端口的进程 / Stop processes using ports"
    fi
else
    echo "✗ 发现 $ERRORS 个错误，$WARNINGS 个警告。"
    echo "✗ Found $ERRORS error(s), $WARNINGS warning(s)."
    echo ""
    echo "请先解决错误后再运行项目。"
    echo "Please fix errors before running the project."
fi

echo ""
echo "详细指南 / Detailed guides:"
echo "  - Mac: cat MAC_SETUP_GUIDE.md"
echo "  - 跨平台 / Cross-platform: cat PLATFORM_SUPPORT.md"
echo ""
echo "💡 提示 / Tips:"
echo "   首次运行 / First run: ./onboard.sh（自动创建所有文件）"
echo "   修复问题 / Fix issues: node dist/index.mjs doctor（只修复目录和权限）"
echo "=========================================="
