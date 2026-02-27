#!/bin/bash
# Mac 环境检查脚本 - 首次运行前使用

echo "=========================================="
echo "  OpenClaw Zero Token - Mac 环境检查"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# 检查 Node.js 版本
echo "1. 检查 Node.js 版本..."
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
    echo "   ✗ Node.js 未安装"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 检查 pnpm
echo "2. 检查 pnpm..."
if command -v pnpm &> /dev/null; then
    PNPM_VERSION=$(pnpm --version)
    echo "   ✓ pnpm $PNPM_VERSION"
else
    echo "   ✗ pnpm 未安装"
    echo "      安装命令: npm install -g pnpm"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 检查 Chrome
echo "3. 检查 Google Chrome..."
CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if [ -f "$CHROME_PATH" ]; then
    echo "   ✓ Chrome 已安装"
else
    echo "   ✗ Chrome 未找到: $CHROME_PATH"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 检查必需目录
echo "4. 检查必需目录..."
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
echo "5. 检查项目编译状态..."
if [ -d "dist" ] && [ -f "dist/index.mjs" ]; then
    echo "   ✓ 项目已编译"
else
    echo "   ⚠ 项目未编译"
    echo "      运行命令: pnpm build"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 检查端口占用
echo "6. 检查端口占用..."
if lsof -i:3001 > /dev/null 2>&1; then
    echo "   ⚠ 端口 3001 已被占用（Gateway 端口）"
    lsof -i:3001 | grep LISTEN
    WARNINGS=$((WARNINGS + 1))
else
    echo "   ✓ 端口 3001 可用"
fi

if lsof -i:9222 > /dev/null 2>&1; then
    echo "   ⚠ 端口 9222 已被占用（Chrome CDP 端口）"
    lsof -i:9222 | grep LISTEN
    WARNINGS=$((WARNINGS + 1))
else
    echo "   ✓ 端口 9222 可用"
fi
echo ""

# 检查系统级 OpenClaw 服务
echo "7. 检查系统级 OpenClaw 服务..."
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

# 检查配置文件
echo "8. 检查配置文件..."
if [ -f ".openclaw-state/openclaw.json" ]; then
    echo "   ✓ 配置文件存在"
    
    # 检查路径是否为 Mac 路径
    if grep -q "/Users/" ".openclaw-state/openclaw.json"; then
        echo "   ✓ 配置文件使用 Mac 路径"
    elif grep -q "/home/" ".openclaw-state/openclaw.json"; then
        echo "   ⚠ 配置文件使用 Linux 路径，需要修改"
        echo "      请编辑 .openclaw-state/openclaw.json"
        echo "      将 /home/xxx 改为 /Users/xxx"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # 检查是否有认证凭证
    if [ -f ".openclaw-state/agents/main/agent/auth-profiles.json" ]; then
        echo "   ✓ 认证凭证文件存在"
    else
        echo "   ⚠ 认证凭证文件不存在（需要运行 onboard.sh）"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "   ⚠ 配置文件不存在（首次运行时会自动创建）"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 总结
echo "=========================================="
echo "  检查完成"
echo "=========================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✓ 所有检查通过！可以开始运行项目。"
    echo ""
    echo "下一步："
    echo "  1. 如果未编译: pnpm build"
    echo "  2. 启动 Chrome: ./start-chrome-debug.sh"
    echo "  3. 配置项目: ./onboard.sh"
    echo "  4. 启动服务: ./server.sh start"
elif [ $ERRORS -eq 0 ]; then
    echo "⚠ 发现 $WARNINGS 个警告，但可以继续。"
    echo ""
    echo "建议操作："
    if [ ! -d "dist" ]; then
        echo "  - 编译项目: pnpm build"
    fi
    if lsof -i:3001 > /dev/null 2>&1 || lsof -i:9222 > /dev/null 2>&1; then
        echo "  - 停止占用端口的进程"
    fi
    if launchctl list | grep -q "openclaw"; then
        echo "  - 停止系统级 OpenClaw: launchctl stop ai.openclaw.gateway"
    fi
else
    echo "✗ 发现 $ERRORS 个错误，$WARNINGS 个警告。"
    echo ""
    echo "请先解决错误后再运行项目。"
fi

echo ""
echo "详细指南: cat MAC_SETUP_GUIDE.md"
echo ""
echo "💡 提示："
echo "   首次运行: ./onboard.sh（自动创建所有文件）"
echo "   修复问题: node dist/index.mjs doctor（只修复目录和权限）"
echo "=========================================="
