#!/bin/bash
# 测试豆包连接

echo "=========================================="
echo "  测试豆包连接"
echo "=========================================="
echo ""

# 1. 检查 Chrome 调试模式是否运行
echo "1. 检查 Chrome 调试模式..."
if curl -s http://127.0.0.1:9222/json/version > /dev/null 2>&1; then
    VERSION_INFO=$(curl -s http://127.0.0.1:9222/json/version | jq -r '.Browser' 2>/dev/null || echo "未知版本")
    echo "✓ Chrome 调试模式正在运行"
    echo "  版本: $VERSION_INFO"
    echo ""
else
    echo "✗ Chrome 调试模式未运行"
    echo ""
    echo "请先启动 Chrome 调试模式："
    echo "  ./start-chrome-debug.sh"
    echo ""
    exit 1
fi

# 2. 检查豆包认证配置
echo "2. 检查豆包认证配置..."
if [ -f ".openclaw-state/agents/main/agent/auth-profiles.json" ]; then
    if grep -q "doubao-web:default" .openclaw-state/agents/main/agent/auth-profiles.json; then
        echo "✓ 豆包认证已配置"
        echo ""
    else
        echo "✗ 豆包认证未配置"
        echo ""
        echo "请先配置豆包认证："
        echo "  pnpm run openclaw onboard"
        echo "  选择 Doubao 提供商"
        echo ""
        exit 1
    fi
else
    echo "✗ 认证配置文件不存在"
    exit 1
fi

# 3. 检查主模型配置
echo "3. 检查主模型配置..."
if grep -q "doubao-web/doubao-seed-2.0" .openclaw-state/openclaw.json; then
    echo "✓ 主模型已设置为豆包"
    echo ""
else
    echo "⚠️  主模型未设置为豆包"
    echo ""
    echo "当前主模型:"
    grep "\"primary\"" .openclaw-state/openclaw.json | head -1
    echo ""
    echo "建议切换到豆包模型："
    echo "  在 Web UI 中切换模型，或者"
    echo "  手动编辑 .openclaw-state/openclaw.json"
    echo ""
fi

# 4. 测试发送消息
echo "4. 测试发送消息到豆包..."
echo ""

MESSAGE="${1:-你好，请用中文回复}"

echo "发送消息: $MESSAGE"
echo ""

# 使用 openclaw 命令发送消息
OPENCLAW_STATE_DIR=.openclaw-state node dist/index.mjs message send --model doubao-web/doubao-seed-2.0 "$MESSAGE"

echo ""
echo "=========================================="
echo "测试完成"
echo "=========================================="
