#!/bin/bash
# 诊断豆包连接问题

echo "=========================================="
echo "  豆包连接诊断"
echo "=========================================="
echo ""

# 1. Chrome 调试模式
echo "【1】Chrome 调试模式状态"
echo "----------------------------------------"
if curl -s http://127.0.0.1:9222/json/version > /dev/null 2>&1; then
    echo "✓ Chrome 调试模式正在运行"
    VERSION_INFO=$(curl -s http://127.0.0.1:9222/json/version | jq -r '.Browser' 2>/dev/null || echo "未知")
    echo "  版本: $VERSION_INFO"
    
    # 检查是否有豆包页面
    PAGES=$(curl -s http://127.0.0.1:9222/json/list)
    if echo "$PAGES" | grep -q "doubao.com"; then
        echo "✓ 检测到豆包页面"
    else
        echo "⚠️  未检测到豆包页面"
        echo "  建议: 在 Chrome 中打开 https://www.doubao.com/chat/"
    fi
else
    echo "✗ Chrome 调试模式未运行"
    echo "  解决: ./start-chrome-debug.sh"
fi
echo ""

# 2. 豆包认证配置
echo "【2】豆包认证配置"
echo "----------------------------------------"
if [ -f ".openclaw-state/agents/main/agent/auth-profiles.json" ]; then
    if grep -q "doubao-web:default" .openclaw-state/agents/main/agent/auth-profiles.json; then
        echo "✓ 豆包认证已配置"
        
        # 提取 sessionid
        SESSIONID=$(cat .openclaw-state/agents/main/agent/auth-profiles.json | grep -o '"sessionid":"[^"]*"' | head -1 | cut -d'"' -f4)
        if [ -n "$SESSIONID" ]; then
            echo "  sessionid: ${SESSIONID:0:20}..."
        fi
    else
        echo "✗ 豆包认证未配置"
        echo "  解决: pnpm run openclaw onboard"
    fi
else
    echo "✗ 认证配置文件不存在"
fi
echo ""

# 3. 主模型配置
echo "【3】主模型配置"
echo "----------------------------------------"
PRIMARY_MODEL=$(grep '"primary"' .openclaw-state/openclaw.json | head -1 | cut -d'"' -f4)
echo "当前主模型: $PRIMARY_MODEL"

if echo "$PRIMARY_MODEL" | grep -q "doubao-web"; then
    echo "✓ 主模型已设置为豆包"
else
    echo "⚠️  主模型不是豆包"
    echo "  建议: 在 Web UI 中切换到豆包模型"
fi
echo ""

# 4. 最近的错误
echo "【4】最近的错误日志"
echo "----------------------------------------"
if [ -f ".openclaw-state/agents/main/sessions/sessions.json" ]; then
    LATEST_SESSION=$(cat .openclaw-state/agents/main/sessions/sessions.json | jq -r '.sessions[0].id' 2>/dev/null)
    if [ -n "$LATEST_SESSION" ] && [ "$LATEST_SESSION" != "null" ]; then
        echo "最近会话: $LATEST_SESSION"
        
        if [ -f ".openclaw-state/agents/main/sessions/${LATEST_SESSION}.jsonl" ]; then
            ERRORS=$(grep '"stopReason":"error"' ".openclaw-state/agents/main/sessions/${LATEST_SESSION}.jsonl" | tail -3)
            if [ -n "$ERRORS" ]; then
                echo ""
                echo "最近的错误:"
                echo "$ERRORS" | jq -r '.message.errorMessage' 2>/dev/null || echo "$ERRORS"
            else
                echo "✓ 没有错误记录"
            fi
        fi
    fi
fi
echo ""

# 5. 浏览器配置
echo "【5】浏览器配置"
echo "----------------------------------------"
ATTACH_ONLY=$(grep '"attachOnly"' .openclaw-state/openclaw.json | head -1 | grep -o 'true\|false')
CDP_URL=$(grep '"cdpUrl"' .openclaw-state/openclaw.json | head -1 | cut -d'"' -f4)

echo "attachOnly: $ATTACH_ONLY"
echo "cdpUrl: $CDP_URL"

if [ "$ATTACH_ONLY" = "true" ]; then
    echo "✓ 配置为连接现有 Chrome"
else
    echo "⚠️  配置为启动新 Chrome"
fi
echo ""

# 6. 建议
echo "【6】问题排查建议"
echo "----------------------------------------"
echo "如果豆包没有回复，请按以下步骤检查："
echo ""
echo "1. 确保 Chrome 调试模式正在运行:"
echo "   ./start-chrome-debug.sh"
echo ""
echo "2. 在 Chrome 中打开豆包并登录:"
echo "   https://www.doubao.com/chat/"
echo ""
echo "3. 确认豆包认证已配置:"
echo "   pnpm run openclaw onboard"
echo "   选择 Doubao 提供商"
echo ""
echo "4. 在 Web UI 中切换到豆包模型:"
echo "   打开 http://localhost:3001"
echo "   点击模型选择器，选择 Doubao-Seed 2.0"
echo ""
echo "5. 测试发送消息:"
echo "   ./test-doubao.sh \"你好\""
echo ""
echo "=========================================="
