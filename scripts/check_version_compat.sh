#!/bin/bash
# OCSS v1.4 版本兼容性检查脚本
# 基于 OpenClaw v2026.3.1

set -e

echo "=========================================="
echo "🔍 OCSS v1.4 版本兼容性检查"
echo "=========================================="

# 获取当前版本
CURRENT_VERSION=$(npm list -g openclaw 2>/dev/null | grep openclaw | awk -F@ '{print $2}')

if [ -z "$CURRENT_VERSION" ]; then
    echo "❌ 无法获取 OpenClaw 版本"
    exit 1
fi

echo "📌 当前版本: $CURRENT_VERSION"
echo ""

# 版本比较函数
version_compare() {
    if [[ $1 == $2 ]]; then
        echo "equal"
        return
    fi
    
    local IFS=.
    local i ver1=($1) ver2=($2)
    
    for ((i=0; i<${#ver1[@]} || i<${#ver2[@]}; i++)); do
        local num1=${ver1[i]:-0}
        local num2=${ver2[i]:-0}
        
        if ((10#$num1 > 10#$num2)); then
            echo "greater"
            return
        elif ((10#$num1 < 10#$num2)); then
            echo "less"
            return
        fi
    done
    echo "equal"
}

# 检查功能
check_feature() {
    local feature=$1
    local min_version=$2
    local check_cmd=$3
    
    echo "---"
    echo "📋 $feature"
    echo "   最低版本要求: $min_version"
    
    local cmp=$(version_compare "$CURRENT_VERSION" "$min_version")
    
    if [[ "$cmp" == "greater" || "$cmp" == "equal" ]]; then
        echo "   ✅ 当前版本支持"
        if [ -n "$check_cmd" ]; then
            eval "$check_cmd" 2>/dev/null || echo "   ⚠️ 检查命令执行失败"
        fi
    else
        echo "   ❌ 当前版本 $CURRENT_VERSION 不支持"
        echo "   💡 建议升级到 $min_version 或更高版本"
    fi
}

echo "=== 功能兼容性检查 ==="
echo ""

# 检查各功能
check_feature "Cron 轻量上下文 (--light-context)" "2026.3.1" \
    "grep -q 'lightContext' ~/.openclaw/openclaw.json && echo '   ✓ 已配置 lightContext' || echo '   ○ 未配置 (可选)'"

check_feature "Docker 健康检查端点 (/health)" "2026.3.1" \
    "curl -s http://127.0.0.1:18789/health >/dev/null 2>&1 && echo '   ✓ 端点响应正常' || echo '   ⚠️ 端点不可用 (Gateway 可能未运行)'"

check_feature "诊断标志 (diagnostics.flags)" "2026.3.1" \
    "grep -q 'diagnostics' ~/.openclaw/openclaw.json && echo '   ✓ 已配置 diagnostics' || echo '   ○ 未配置 (可选)'"

check_feature "飞书表格创建 (feishu_doc)" "2026.3.1" \
    "grep -q 'feishu' ~/.openclaw/openclaw.json && echo '   ✓ 飞书已配置' || echo '   ○ 飞书未配置'"

check_feature "OpenAI WebSocket 传输" "2026.3.1" \
    "grep -q 'transport.*auto' ~/.openclaw/openclaw.json && echo '   ✓ WebSocket 传输已启用' || echo '   ○ 默认配置 (推荐)'"

echo ""
echo "=== 兼容性建议 ==="
echo ""

cmp=$(version_compare "$CURRENT_VERSION" "2026.3.1")
if [[ "$cmp" == "less" ]]; then
    echo "⚠️ 建议升级到 v2026.3.1 以获得完整功能"
    echo ""
    echo "升级命令:"
    echo "  npm update -g openclaw"
    echo ""
    echo "或使用腾讯镜像:"
    echo "  npm config set registry https://mirrors.tencent.com/npm/"
    echo "  npm update -g openclaw"
else
    echo "✅ 当前版本 ($CURRENT_VERSION) 已满足 OCSS v1.4 要求"
fi

echo ""
echo "=== OCSS v1.4 评估检查 ==="
echo ""

# 评估检查
echo "📊 资源效率评估 (v1.4 新增):"

# 检查分层加载
CORES=0
if [ -f "$HOME/.openclaw/workspace/AGENTS.md" ]; then
    for f in AGENTS.md SOUL.md USER.md IDENTITY.md HEARTBEAT.md TOOLS.md; do
        [ -f "$HOME/.openclaw/workspace/$f" ] && CORES=$((CORES+1))
    done
    echo "   核心文件: $CORES/6"
fi

# 检查轻量上下文
if grep -q 'lightContext.*true' ~/.openclaw/openclaw.json 2>/dev/null; then
    echo "   轻量上下文: ✅ 已配置"
else
    echo "   轻量上下文: ○ 未配置 (可选)"
fi

# 检查监控
if [ -f "$HOME/.openclaw/workspace/scripts/token_monitor.sh" ]; then
    echo "   监控脚本: ✅ 已部署"
else
    echo "   监控脚本: ❌ 未部署"
fi

# 检查本地 LLM
if grep -q 'local-gpu' ~/.openclaw/config.yml 2>/dev/null; then
    echo "   本地 LLM: ✅ 已配置"
else
    echo "   本地 LLM: ○ 未配置 (可选)"
fi

echo ""
echo "=========================================="
echo "检查完成"
echo "=========================================="
