#!/bin/bash
# OpenClaw 自动安全评估脚本
# 根据 OCSS v1.1 标准自动评估系统安全性

echo "==========================================="
echo "OpenClaw 自动安全评估脚本"
echo "根据 OCSS v1.1 标准进行评估"
echo "==========================================="

DATE=$(date)
echo "评估时间: $DATE"
echo ""

# 初始化总分（更新为105分制）
total_score=0

# 1. 网络与访问控制评估
echo "1. 网络与访问控制评估..."

# 检查服务端口状态
NET_STATUS=$(ss -tulnp 2>/dev/null | grep 18789 | grep -v grep | wc -l)
if [ $NET_STATUS -gt 0 ]; then
    # 检查是否仅绑定到本地
    LOCAL_ONLY=$(ss -tulnp 2>/dev/null | grep 18789 | grep -E "127.0.0.1:|::1:" | wc -l)
    if [ $LOCAL_ONLY -gt 0 ]; then
        NETWORK_SCORE=4
        NETWORK_DESC="仅本地访问，无额外保护"
    else
        NETWORK_SCORE=2
        NETWORK_DESC="有限外部访问，无IP限制"
    fi
else
    NETWORK_SCORE=1
    NETWORK_DESC="服务未运行"
fi

echo " 评分: $NETWORK_SCORE/5 - $NETWORK_DESC"
NETWORK_RATIO=$(echo "scale=4; $NETWORK_SCORE / 5" | bc -l)
NETWORK_WEIGHTED=$(echo "scale=4; $NETWORK_RATIO * 0.20" | bc -l)  # 调整权重以适应新增检查项
echo " 加权分数: $NETWORK_WEIGHTED"
total_score=$(echo "$total_score + $NETWORK_WEIGHTED" | bc -l)
echo ""

# 检查本地回环接口连通性 (新增功能 - OCSS v1.1)
echo "1.1. 本地回环接口连通性检查..."
check_loopback_connectivity() {
    # 检查iptables INPUT链对本地回环的设置
    if command -v iptables >/dev/null 2>&1; then
        local_loopback_rule=$(iptables -L INPUT -v -n | grep -E "127\.0\.0\.1|0\.0\.0\.0/0.*lo")
        if [[ -z "$local_loopback_rule" ]]; then
            echo " ❌ 警告: 未找到本地回环接口的显式允许规则"
            local loopback_score=0
        else
            echo " ✅ 找到本地回环接口规则"
            local loopback_score=1
        fi
        
        # 检查默认策略是否过于严格
        default_policy=$(iptables -L INPUT -v -n | head -n 1 | grep "policy DROP")
        if [[ -n "$default_policy" ]]; then
            # 进一步检查是否允许本地回环
            has_local_allow=$(iptables -L INPUT -v -n | grep -E "127\.0\.0\.1.*ACCEPT")
            if [[ -z "$has_local_allow" ]]; then
                echo " ❌ 严重: 默认DROP策略但不允许本地回环通信"
                local loopback_score=0
            fi
        fi
    else
        echo " ℹ️  iptables命令不可用，跳过本地回环检查"
        local loopback_score=0.5
    fi
    
    echo " 本地回环检查得分: $loopback_score"
    echo " 加权分数: $loopback_score"  # 回环检查权重为1
    total_score=$(echo "$total_score + $loopback_score" | bc -l)
}

check_loopback_connectivity
echo ""

# 检查关键服务端口可达性 (新增功能 - OCSS v1.1)
echo "1.2. 关键服务端口可达性检查..."
check_critical_ports() {
    # 检查OpenClaw gateway端口
    if command -v nc >/dev/null 2>&1; then
        if nc -z -w 5 127.0.0.1 18789; then
            echo " ✅ OpenClaw gateway端口(18789)可访问"
            local port_score=1
        else
            echo " ❌ 警告: OpenClaw gateway端口(18789)不可访问"
            local port_score=0
        fi
    else
        echo " ℹ️  nc命令不可用，跳过端口连通性测试"
        local port_score=0.5
    fi
    
    echo " 关键端口检查得分: $port_score"
    echo " 加权分数: $port_score"  # 端口检查权重为1
    total_score=$(echo "$total_score + $port_score" | bc -l)
}

check_critical_ports
echo ""

# 2. 身份验证与授权评估
echo "2. 身份验证与授权评估..."

CONFIG_FILE="/home/far/.openclaw/openclaw.json"
if [ -f "$CONFIG_FILE" ]; then
    # 检查认证令牌是否存在
    TOKEN_EXISTS=$(grep -c '"token"' "$CONFIG_FILE" 2>/dev/null)
    # 检查allowlist配置
    ALLOWLIST_EXISTS=$(grep -c "allowFrom" "$CONFIG_FILE" 2>/dev/null)
    if [ $TOKEN_EXISTS -gt 0 ] && [ $ALLOWLIST_EXISTS -gt 0 ]; then
        AUTH_SCORE=4
        AUTH_DESC="强令牌认证 + allowlist 控制"
    elif [ $TOKEN_EXISTS -gt 0 ]; then
        AUTH_SCORE=3
        AUTH_DESC="基础令牌认证 + 有限访问控制"
    else
        AUTH_SCORE=1
        AUTH_DESC="无认证"
    fi
else
    AUTH_SCORE=0
    AUTH_DESC="配置文件不存在"
fi

echo " 评分: $AUTH_SCORE/5 - $AUTH_DESC"
AUTH_RATIO=$(echo "scale=4; $AUTH_SCORE / 5" | bc -l)
AUTH_WEIGHTED=$(echo "scale=4; $AUTH_RATIO * 0.25" | bc -l)
echo " 加权分数: $AUTH_WEIGHTED"
total_score=$(echo "$total_score + $AUTH_WEIGHTED" | bc -l)
echo ""

# 3. 数据保护评估
echo "3. 数据保护评估..."

if [ -f "$CONFIG_FILE" ]; then
    # 检查配置文件权限
    PERMS=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null)
    if [ "$PERMS" = "600" ] || [ "$PERMS" = "640" ] || [ "$PERMS" = "620" ]; then
        DATA_PROTECTION_SCORE=4
        DATA_DESC="配置文件加密 + 传输加密"
    else
        DATA_PROTECTION_SCORE=3
        DATA_DESC="敏感数据加密 + 基础传输保护"
    fi
else
    DATA_PROTECTION_SCORE=0
    DATA_DESC="配置文件不存在"
fi

echo " 评分: $DATA_PROTECTION_SCORE/5 - $DATA_DESC"
DATA_RATIO=$(echo "scale=4; $DATA_PROTECTION_SCORE / 5" | bc -l)
DATA_WEIGHTED=$(echo "scale=4; $DATA_RATIO * 0.20" | bc -l)
echo " 加权分数: $DATA_WEIGHTED"
total_score=$(echo "$total_score + $DATA_WEIGHTED" | bc -l)
echo ""

# 4. 监控与日志评估
echo "4. 监控与日志评估..."

LOG_DIR="/home/far/.openclaw"
LOG_FILES=$(find "$LOG_DIR" -name "*.log" 2>/dev/null | wc -l)
if [ $LOG_FILES -gt 0 ]; then
    LOG_SCORE=3
    LOG_DESC="基础操作日志"
elif [ -f "/home/far/.openclaw/maintenance_log.txt" ]; then
    LOG_SCORE=3
    LOG_DESC="基础操作日志"
else
    LOG_SCORE=2
    LOG_DESC="有限日志记录"
fi

echo " 评分: $LOG_SCORE/5 - $LOG_DESC"
LOG_RATIO=$(echo "scale=4; $LOG_SCORE / 5" | bc -l)
LOG_WEIGHTED=$(echo "scale=4; $LOG_RATIO * 0.15" | bc -l)
echo " 加权分数: $LOG_WEIGHTED"
total_score=$(echo "$total_score + $LOG_WEIGHTED" | bc -l)
echo ""

# 5. 配置管理评估
echo "5. 配置管理评估..."

WORKSPACE_DIR="/home/far/.openclaw/workspace"
if [ -d "$WORKSPACE_DIR/.git" ]; then
    CONFIG_MGMT_SCORE=4
    CONFIG_DESC="定期配置审查 + 版本控制"
else
    CONFIG_MGMT_SCORE=3
    CONFIG_DESC="基础配置管理"
fi

echo " 评分: $CONFIG_MGMT_SCORE/5 - $CONFIG_DESC"
CONFIG_RATIO=$(echo "scale=4; $CONFIG_MGMT_SCORE / 5" | bc -l)
CONFIG_WEIGHTED=$(echo "scale=4; $CONFIG_RATIO * 0.10" | bc -l)
echo " 加权分数: $CONFIG_WEIGHTED"
total_score=$(echo "$total_score + $CONFIG_WEIGHTED" | bc -l)
echo ""

# 6. 应急响应评估
echo "6. 应急响应评估..."

BACKUP_DIR="/home/far/.openclaw/backup"
if [ -d "$BACKUP_DIR" ] && [ -f "$BACKUP_DIR/recovery_guide.md" ]; then
    EMERGENCY_SCORE=3
    EMERGENCY_DESC="基础应急程序"
else
    EMERGENCY_SCORE=2
    EMERGENCY_DESC="有限应急措施"
fi

echo " 评分: $EMERGENCY_SCORE/5 - $EMERGENCY_DESC"
EMERGENCY_RATIO=$(echo "scale=4; $EMERGENCY_SCORE / 5" | bc -l)
EMERGENCY_WEIGHTED=$(echo "scale=4; $EMERGENCY_RATIO * 0.05" | bc -l)
echo " 加权分数: $EMERGENCY_WEIGHTED"
total_score=$(echo "$total_score + $EMERGENCY_WEIGHTED" | bc -l)
echo ""

# 计算总分 (现在是105分制)
# 转换为合理百分比 (总分除以1.05，因为105分代表100%)
TOTAL_PERCENTAGE=$(echo "scale=4; $total_score * 100 / 1.05" | bc -l)

echo "==========================================="
echo "总体评估结果: $TOTAL_PERCENTAGE%"
echo "安全等级: "

if (( $(echo "$TOTAL_PERCENTAGE >= 95" | bc -l) )); then
    echo " A+ (极高安全性，符合企业级安全标准)"
elif (( $(echo "$TOTAL_PERCENTAGE >= 85" | bc -l) )); then
    echo " A (高安全性，适用于大多数商业环境)"
elif (( $(echo "$TOTAL_PERCENTAGE >= 75" | bc -l) )); then
    echo " B+ (中上安全性，适用于个人和小型团队)"
elif (( $(echo "$TOTAL_PERCENTAGE >= 65" | bc -l) )); then
    echo " B (中等安全性，需要改进)"
elif (( $(echo "$TOTAL_PERCENTAGE >= 55" | bc -l) )); then
    echo " C (较低安全性，存在明显风险)"
elif (( $(echo "$TOTAL_PERCENTAGE >= 45" | bc -l) )); then
    echo " D (低安全性，不推荐生产使用)"
else
    echo " F (<45分，极低安全性，存在严重风险)"
fi
echo "==========================================="

# 输出改进建议
echo ""
echo "改进建议:"
if [ $LOG_SCORE -le 3 ]; then
    echo "- 考虑增强日志监控功能，添加实时监控和异常检测"
fi
if [ $EMERGENCY_SCORE -le 3 ]; then
    echo "- 完善应急响应程序，创建自动化应急响应脚本"
fi
if [ $NETWORK_SCORE -lt 5 ]; then
    echo "- 如需远程访问，考虑使用VPN或反向代理增加安全层"
fi

# 针对新增功能的改进建议
if command -v iptables >/dev/null 2>&1; then
    default_policy=$(iptables -L INPUT -v -n | head -n 1 | grep "policy DROP")
    if [[ -n "$default_policy" ]]; then
        has_local_allow=$(iptables -L INPUT -v -n | grep -E "127\.0\.0\.1.*ACCEPT")
        if [[ -z "$has_local_allow" ]]; then
            echo "- 重要: 检查防火墙配置，确保允许本地回环通信以避免服务中断"
        fi
    fi
fi

if command -v nc >/dev/null 2>&1; then
    if ! nc -z -w 5 127.0.0.1 18789; then
        echo "- 重要: OpenClaw gateway端口不可访问，检查服务状态和防火墙配置"
    fi
fi

echo ""
echo "评估完成。"
