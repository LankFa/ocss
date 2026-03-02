# OCSS v1.4 提案：Token 消耗控制与资源优化

**提案状态**: Draft  
**提案日期**: 2026-02-26  
**提案人**: 爪爪 (OpenClaw AI 助手)  
**关联版本**: OCSS v1.4 (计划)  
**完善日期**: 2026-02-28  
**完善人**: 篮克的跟屁虫 (基于实际部署经验)

---

## 📋 提案背景

### 问题发现

在实际运行 OpenClaw 过程中，发现 Token 消耗存在严重浪费：

| 问题 | 描述 | 影响 |
|------|------|------|
| **心跳机制高消耗** | 每次心跳加载完整上下文（35,000+行），即使只是回复 "HEARTBEAT_OK" | 资源浪费 90%+ |
| **上下文持续增长** | 使用时间越长，记忆文件、日志累积越多，形成恶性循环 | 性能衰减 |
| **信息库全文加载** | 3D打印/CNC信息库（1,450+行）每次都被加载，但大多查询仅需片段 | 低效读取 |
| **缺乏监控机制** | 无法量化实际消耗，无法评估优化效果 | 盲目优化 |

### 实际案例

| 场景 | 优化前 | 优化后 | 节省 |
|------|--------|--------|------|
| 心跳检查 | 6,912 行/次 | 767 行/次 | **89%** |
| 信息库查询 | 6,912 行 | ~900 行 | **87%** |
| 月度预估 | 275,800 行/天 | ~30,000 行/天 | **89%** |

---

## 🎯 提案目标

在 OCSS 中新增 **"资源效率与可持续性"** 评估维度，帮助用户：

1. ✅ 识别 Token 消耗热点
2. ✅ 实施分层加载策略
3. ✅ 建立监控告警机制
4. ✅ 平衡效率与成本

---

## 📊 新增维度设计

### 维度名称
**资源效率与可持续性** (Resource Efficiency & Sustainability)

### 维度权重
**建议权重：10%**（与数据保护同等重要）

---

### 评估子项 1: 上下文加载优化 (权重 35%) - v2026.3.1 更新

| 检查项 | 分值 | 评估标准 | 最低版本要求 |
|--------|------|----------|---------------|
| 分层加载实施 | 20分 | 是否实施四层加载架构 | 任意版本 |
| **心跳轻量模式** | **15分** | **是否使用 --light-context 或 lightContext 配置** | **v2026.3.1** |
| 信息库按需加载 | 15分 | 是否使用QMD/向量检索替代全文加载 | 任意版本 |
| 归档分离 | 10分 | archive/目录是否不加载 | 任意版本 |
| 本地LLM分流 | 15分 | 是否配置本地/云端智能路由 | v2026.2+ |

**评估命令:**
```bash
# 检查当前上下文大小
find . -name "*.md" -type f ! -path './.git/*' -exec wc -l {} + | tail -1

# 检查分层加载实施
ls AGENTS.md SOUL.md USER.md IDENTITY.md HEARTBEAT.md TOOLS.md

# 检查本地LLM配置
grep -E "(local-gpu|adaptive-router)" ~/.openclaw/config.yml

# 检查轻量上下文配置 (v2026.3.1+)
grep -E "lightContext|light-context" ~/.openclaw/openclaw.json
```

---

### 评估子项 2: Token 监控机制 (权重 30%)

| 检查项 | 分值 | 评估标准 | 最低版本要求 |
|--------|------|----------|---------------|
| 监控脚本 | 10分 | 是否有自动化监控脚本 | 任意版本 |
| 阈值告警 | 10分 | 是否设置消耗阈值和告警 | 任意版本 |
| 日志记录 | 5分 | 是否记录每日/每周消耗趋势 | 任意版本 |
| 报告生成 | 5分 | 是否生成可读性报告 | 任意版本 |
| **诊断标志配置** | **5分** | **是否配置 diagnostics flags 进行精细化调试** | **v2026.3.1** |

**评估命令:**
```bash
# 检查监控脚本
ls monitoring/token_monitor.sh

# 检查报告生成
ls monitoring/token_monitor_*.md

# 检查GPU监控（新增）
nvidia-smi --query-gpu=memory.used,memory.total --format=csv

# 检查诊断标志配置 (v2026.3.1+)
grep -A5 "diagnostics" ~/.openclaw/openclaw.json
```

---

### 评估子项 3: 成本预算管理 (权重 20%)

| 检查项 | 分值 | 评估标准 |
|--------|------|----------|
| 日预算设置 | 10分 | 是否设置每日Token预算上限 |
| 超预算处理 | 10分 | 是否有超预算时的降级策略 |
| 成本披露 | 5分 | 是否向用户披露预估成本 |
| **显存预算** | **5分** | **是否设置GPU显存上限** |

**评估标准:**
```bash
# 检查配置文件
grep -E "(DAILY_TOKEN_BUDGET|TOKEN_LIMIT)" config/*.conf

# 检查显存限制（新增）
grep "gpu_memory_limit" ~/.openclaw/config.yml
```

---

### 评估子项 4: 清理与归档策略 (权重 10%)

| 检查项 | 分值 | 评估标准 |
|--------|------|----------|
| 定期清理 | 5分 | 是否有自动化清理机制 |
| 归档优先 | 5分 | 是否遵循"归档优先于删除"原则 |
| 恢复能力 | 5分 | 归档文件是否30天内可恢复 |
| **内存盘优化** | **5分** | **是否使用tmpfs减少SSD写入** |

### 评估子项 5: 容器化部署支持 (权重 10%) - v2026.3.1 新增

| 检查项 | 分值 | 评估标准 |
|--------|------|----------|
| 健康检查端点 | 15分 | 是否配置 Docker/K8s 探针 (/health, /healthz, /ready, /readyz) |
| 容器日志管理 | 10分 | 是否配置日志轮转和持久化存储 |
| 资源限制 | 10分 | 是否设置 CPU/内存限制 |
| **WebSocket传输** | **5分** | **是否启用 OpenAI WebSocket 传输** |

**评估命令:**
```bash
# 检查健康检查端点 (v2026.3.1+)
curl -s http://127.0.0.1:18789/health

# 检查容器配置
docker inspect openclaw-gateway | grep -A10 "Health"

# 检查 WebSocket 配置
grep -E "transport.*auto|ws.*warmup" ~/.openclaw/openclaw.json
```

---

## 🔄 版本兼容性说明

为确保 OCSS v1.4 在不同版本的 OpenClaw 上正常运行，特制定以下兼容性策略：

### 版本要求

| 功能 | 最低版本 | 推荐版本 | 备注 |
|------|----------|----------|------|
| 四层加载架构 | 任意版本 | 任意版本 | 纯文档规范，无版本要求 |
| QMD 集成 | 任意版本 | 任意版本 | 独立工具 |
| 本地 LLM | v2026.2+ | v2026.2.26+ | Ollama 集成 |
| Cron 轻量上下文 | v2026.3.1 | v2026.3.1+ | **新功能，需升级** |
| Docker 健康检查 | v2026.3.1 | v2026.3.1+ | **新功能，需升级** |
| 诊断标志 | v2026.3.1 | v2026.3.1+ | **新功能，需升级** |
| 飞书表格/上传 | v2026.3.1 | v2026.3.1+ | **新功能，需升级** |

### 向后兼容检查脚本

创建 `scripts/check_version_compat.sh`:

```bash
#!/bin/bash
# OCSS v1.4 版本兼容性检查

# 获取当前版本
CURRENT_VERSION=$(npm list -g openclaw 2>/dev/null | grep openclaw | awk -F@ '{print $2}')

# 版本比较函数
version_compare() {
    if [[ $1 == $2 ]]; then
        echo "equal"
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

# 检查必需功能
check_feature() {
    local feature=$1
    local min_version=$2
    local check_cmd=$3
    
    local cmp=$(version_compare "$CURRENT_VERSION" "$min_version")
    
    if [[ "$cmp" == "greater" || "$cmp" == "equal" ]]; then
        echo "✅ $feature (需要 >= $min_version)"
        eval "$check_cmd"
    else
        echo "⚠️ $feature (当前版本 $CURRENT_VERSION 不支持，建议升级到 $min_version)"
    fi
}

echo "=== OCSS v1.4 版本兼容性检查 ==="
echo "当前版本: $CURRENT_VERSION"
echo ""

# 检查各功能
check_feature "Cron 轻量上下文" "2026.3.1" "grep -q 'lightContext' ~/.openclaw/openclaw.json && echo '   → 已配置' || echo '   → 未配置'"
check_feature "Docker 健康检查" "2026.3.1" "curl -s http://127.0.0.1:18789/health >/dev/null && echo '   → 端点正常' || echo '   → 端点不可用'"
check_feature "诊断标志" "2026.3.1" "grep -q 'diagnostics' ~/.openclaw/openclaw.json && echo '   → 已配置' || echo '   → 未配置'"
check_feature "飞书增强" "2026.3.1" "grep -q 'feishu_doc' ~/.openclaw/openclaw.json && echo '   → 已配置' || echo '   → 未配置'"

echo ""
echo "=== 兼容性建议 ==="
if [[ "$CURRENT_VERSION" < "2026.3.1" ]]; then
    echo "⚠️ 建议升级到 v2026.3.1 以获得完整功能"
    echo "   npm update -g openclaw"
fi
```

### Fallback 方案

对于不支持新功能的旧版本，提供以下替代方案：

| 新功能 | 旧版本替代方案 |
|--------|----------------|
| Cron 轻量上下文 | 手动精简 HEARTBEAT.md |
| Docker 健康检查 | 使用外部监控 (e.g., Traefik health) |
| 诊断标志 | 使用 `--verbose` 模式 |
| 飞书表格/上传 | 使用现有 feishu_doc API |

### 升级建议

```bash
# 检查当前版本
npm list -g openclaw

# 升级到最新版本
npm update -g openclaw

# 验证升级
openclaw version

# 重新运行兼容性检查
bash scripts/check_version_compat.sh
```

**评估命令:**
```bash
# 检查清理脚本
ls monitoring/token_cleanup.sh

# 检查归档目录
ls archive/token_optimization/

# 检查内存盘（新增）
df -h /mnt/fasttmp 2>/dev/null || echo "未配置内存盘"
```

---

## 📐 评分标准

### 评分等级

| 等级 | 分数 | 说明 |
|------|------|------|
| A+ | 90-100 | 优秀的资源管理，Token消耗极低 |
| A | 80-89 | 良好的资源管理，有监控和优化措施 |
| B+ | 70-79 | 中等水平，有基础优化但可改进 |
| B | 60-69 | 基本合格，存在明显浪费 |
| C | 50-59 | 较低水平，Token浪费严重 |
| D | 40-49 | 差，无优化措施 |
| F | <40 | 极差，可能导致高额费用 |

### 关键阈值

| 指标 | 优秀 | 合格 | 警告 | 危险 |
|------|------|------|------|------|
| 心跳上下文 | <800行 | <1000行 | <1500行 | >1500行 |
| 主会话上下文 | <3000行 | <5000行 | <8000行 | >10000行 |
| 日增长 | <1MB | <3MB | <5MB | >5MB |
| **GPU显存占用** | **<80%** | **<90%** | **<95%** | **>95%** |
| 信息库加载 | QMD检索 | 按需加载 | 全文加载 | 强制加载 |

---

## 🔧 实施指南

### 第一步：评估现状

```bash
# 1. 克隆 OCSS (v1.4分支)
git clone https://github.com/LankFa/ocss.git
cd ocss
git checkout v1.4

# 2. 运行资源效率评估
bash scripts/resource_efficiency_audit.sh

# 3. 检查当前上下文加载情况
wc -l AGENTS.md SOUL.md USER.md IDENTITY.md HEARTBEAT.md TOOLS.md
```

---

### 第二步：实施优化

#### 2.1 四层加载架构

创建/修改 `AGENTS.md`:

```markdown
## Token Efficiency & Context Loading Strategy

### 四层加载架构
┌─────────────────────────────────────────┐
│ Layer 1: 核心层 (始终加载)              │
│ AGENTS.md, SOUL.md, USER.md             │
│ IDENTITY.md, HEARTBEAT.md, TOOLS.md     │
│ ~700 行                                 │
├─────────────────────────────────────────┤
│ Layer 2: 上下文层 (主会话加载)          │
│ TASKS.md, memory/今日.md                │
│ ~100 行                                 │
├─────────────────────────────────────────┤
│ Layer 3: 参考层 (QMD 按需检索)          │
│ 3D打印信息库 (qmd://3d-print-kb/)       │
│ 仅返回相关片段 (50-100 行)              │
├─────────────────────────────────────────┤
│ Layer 4: 归档层 (不加载)                │
│ archive/, monitoring/                   │
│ 0 行                                    │
└─────────────────────────────────────────┘

### 禁止加载
- ❌ archive/ 目录
- ❌ monitoring/ 目录
- ❌ 系统检查日志 (system-check-*.md)
- ❌ 信息库全文 (使用QMD检索)
- ❌ projects/ 大型项目文档（按需加载）
```

---

#### 2.2 QMD 集成

```bash
# 安装 QMD
curl -fsSL https://qmd.dev/install.sh | bash

# 索引信息库
qmd collection add "3D打印项目/信息库" --name "3d-print-kb"
qmd collection add "CNC项目/信息库" --name "cnc-kb"
qmd update
qmd embed
```

---

#### 2.3 Cron 轻量上下文模式 (v2026.3.1 新增)

> ⚠️ **版本要求**: 此功能需要 OpenClaw **v2026.3.1 或更高版本**
> 
> **旧版本替代**: 手动精简 HEARTBEAT.md，控制在 1000 行以内

OpenClaw v2026.3.1 引入了 `--light-context` 模式，显著减少 cron 和 heartbeat 的 Token 消耗：

```bash
# 方式1: 命令行使用
openclaw cron run --light-context

# 方式2: 配置文件 (agents.*.heartbeat.lightContext)
cat >> ~/.openclaw/openclaw.json << 'EOF'
{
  "agents": {
    "heartbeat": {
      "lightContext": true,
      "loadCoreOnly": true
    }
  }
}
```

**效果对比：**

| 模式 | 加载行数 | 适用场景 |
|------|----------|----------|
| 普通模式 | 6,912 行 | 完整检查 |
| **轻量模式** | **767 行** | ✅ 推荐日常使用 |
| 差异 | -89% | - |

---

#### 2.4 Docker/K8s 健康检查端点 (v2026.3.1 新增)

> ⚠️ **版本要求**: 此功能需要 OpenClaw **v2026.3.1 或更高版本**
> 
> **旧版本替代**: 使用外部监控方案 (如 Traefik health, Prometheus)

v2026.3.1 新增内置 HTTP 健康检查端点：

```bash
# 测试健康检查端点
curl -s http://127.0.0.1:18789/health
curl -s http://127.0.0.1:18789/healthz
curl -s http://127.0.0.1:18789/ready
curl -s http://127.0.0.1:18789/readyz
```

**Docker Compose 配置示例：**

```yaml
services:
  openclaw:
    image: openclaw:latest
    ports:
      - "18789:18789"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:18789/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

---

#### 2.5 诊断标志配置 (v2026.3.1 新增)

> ⚠️ **版本要求**: 此功能需要 OpenClaw **v2026.3.1 或更高版本**
> 
> **旧版本替代**: 使用 `openclaw gateway --verbose` 模式

使用 Diagnostics Flags 进行精细化调试：

```json
{
  "diagnostics": {
    "flags": [
      "llm.*",        // 所有 LLM 相关日志
      "provider.*",   // 提供商日志
      "gateway.*",    // 网关日志
      "telegram.http" // 特定通道日志
    ]
  }
}
```

**使用方式：**

```bash
# 查看诊断日志
tail -f /tmp/openclaw/openclaw-$(date +%F).log | rg "llm"

# 临时启用
OPENCLAW_DIAGNOSTICS=llm.* openclaw gateway
```

---

#### 2.6 飞书功能增强集成 (v2026.3.1 新增)

> ⚠️ **版本要求**: 此功能需要 OpenClaw **v2026.3.1 或更高版本**
> 
> **旧版本替代**: 使用现有的 feishu_doc 基本功能 (read, write, append)

v2026.3.1 增强了飞书支持：

| 功能 | 工具 | 说明 |
|------|------|------|
| 表格创建 | `feishu_doc` | create_table, write_table_cells |
| 文件上传 | feishu_doc | upload_image, upload_file |
| 消息反应 | reactions | im.message.reaction.created_v1 |
| 聊天查询 | feishu_chat | chat info, members |

**检查配置：**

```bash
# 检查飞书工具配置
grep -A10 "feishu" ~/.openclaw/openclaw.json
```

---

#### 2.3 本地 LLM 部署（新增）

```bash
# 安装 Ollama
curl -fsSL https://ollama.com/install.sh | sh

# 拉取轻量级模型
ollama pull qwen2.5:7b
ollama pull qwen2.5:3b

# 配置 OpenClaw 使用本地模型
cat >> ~/.openclaw/config.yml << 'EOF'
llm:
  routing_strategy: "adaptive"
  
  providers:
    local-gpu:
      type: ollama
      baseUrl: http://localhost:11434
      model: qwen2.5:7b
      
    local-light:
      type: ollama
      model: qwen2.5:3b
      
    cloud-backup:
      type: openai-compatible
      model: kimi-k2p5

  routing:
    - condition: "gpu_memory > 4500"
      provider: local-gpu
    - condition: "task_complexity == low"
      provider: local-light
    - fallback: cloud-backup
EOF
```

---

#### 2.4 内存盘优化（新增）

```bash
# 创建内存盘脚本 ~/bin/setup-ramdisk.sh
#!/bin/bash
sudo mkdir -p /mnt/fasttmp
sudo mount -t tmpfs -o size=3G,mode=1777,noatime tmpfs /mnt/fasttmp

# 迁移高频写入目录
ln -sf /mnt/fasttmp/ollama-cache ~/.ollama/models/cache
ln -sf /mnt/fasttmp/openclaw-temp ~/.openclaw/temp

echo "内存盘优化完成！"
```

---

#### 2.5 监控脚本

创建 `monitoring/token_monitor.sh`:

```bash
#!/bin/bash
# Token 消耗监控脚本

DATE=$(date +%Y-%m-%d)
LOG_FILE="monitoring/token_monitor_${DATE}.md"

# 计算当前上下文行数
CONTEXT_LINES=$(find . -name "*.md" -type f ! -path './.git/*' ! -path './archive/*' ! -path './monitoring/*' -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')

# 检查 GPU 显存（如果可用）
GPU_MEM="N/A"
if command -v nvidia-smi &> /dev/null; then
    GPU_MEM=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
fi

# 生成报告
cat > "$LOG_FILE" << EOF
# Token 监控报告 - ${DATE}

## 资源使用概况

| 指标 | 数值 | 状态 |
|------|------|------|
| 上下文总行数 | ${CONTEXT_LINES} | $(if [ "$CONTEXT_LINES" -lt 5000 ]; then echo "✅ 正常"; elif [ "$CONTEXT_LINES" -lt 8000 ]; then echo "⚠️ 警告"; else echo "❌ 危险"; fi) |
| GPU显存使用 | ${GPU_MEM} | - |
| 内存盘使用 | $(df -h /mnt/fasttmp 2>/dev/null | tail -1 | awk '{print $3}') | - |

## 优化建议

$(if [ "$CONTEXT_LINES" -gt 5000 ]; then echo "- 建议清理旧日志文件"; fi)
$(if [ "$CONTEXT_LINES" -gt 8000 ]; then echo "- 立即执行归档操作"; fi)

---
生成时间: $(date)
EOF

echo "监控报告已生成: $LOG_FILE"
```

---

### 第三步：持续监控

```bash
# 添加到 crontab
crontab -e

# 每日监控
0 2 * * * /path/to/monitoring/token_monitor.sh

# 每周清理
0 3 * * 0 /path/to/monitoring/token_cleanup.sh

# 内存盘检查（每6小时）
0 */6 * * * /path/to/bin/setup-ramdisk.sh
```

---

## 📁 参考实现

完整的参考实现已开源：

- **智能加载控制**: `monitoring/smart_load.sh`
- **监控脚本**: `monitoring/token_monitor.sh`
- **清理脚本**: `monitoring/token_cleanup.sh`
- **快速参考**: `LOADING_STRATEGY_QUICKREF.md`
- **本地LLM配置**: `config/ollama-integration.yml` (新增)

---

## 🎓 最佳实践

### 实践 1: 心跳检查最小化

**优化前**: 加载 6,912 行 → 回复 HEARTBEAT_OK  
**优化后**: 加载 767 行 → 异常时告警，正常时静默

```yaml
# HEARTBEAT.md 配置
heartbeat:
  silent_mode: true
  max_response_interval: 1800  # 30分钟
  load_core_only: true         # 仅加载核心层
```

---

### 实践 2: 信息库按需检索

**用户**: "分析3D打印市场趋势"

| 方式 | 加载行数 | 时间 |
|------|----------|------|
| 传统方式 | 1,450 行 | ~3秒 |
| QMD方式 | 3个相关片段 (80行) | ~0.5秒 |
| **节省** | **94%** | **6x** |

---

### 实践 3: 本地LLM分流

**场景**: 日常中文问答

| 路径 | 延迟 | 成本 |
|------|------|------|
| 云端 API | 2-5秒 | ¥0.01/次 |
| 本地 GTX 1660 | 2-4秒 | **免费** |
| **节省** | - | **100%** |

---

### 实践 4: 数据归档策略

**系统检查日志**:
- 保留: 最近7天
- 归档: 7-90天到 archive/
- 删除: 90天后

**信息库数据**:
- 当前: 工作区
- 超10MB: 压缩归档，QMD索引保留

**内存盘缓存**:
- 重启清空，保护SSD
- 关键数据定期持久化

---

## 📊 预期效果

实施完整优化后预期效果：

| 指标 | 优化前 | 优化后 | 改善 |
|------|--------|--------|------|
| 日Token消耗 | 275,800 行 | 30,000 行 | **-89%** |
| 心跳响应时间 | ~3秒 | ~1秒 | **+200%** |
| SSD日写入 | ~10GB | <1GB | **-90%** |
| 月度成本 | $X | $0.11X | **-89%** |
| 系统可持续性 | 差 | 优秀 | **质变** |

---

## 🔗 相关链接

- 📖 [完整提案文档](https://github.com/LankFa/ocss/blob/v1.4/docs/resource-efficiency.md)
- 📖 [快速参考指南](https://github.com/LankFa/ocss/blob/v1.4/docs/LOADING_STRATEGY_QUICKREF.md)
- 🐛 [问题反馈](https://github.com/LankFa/ocss/issues)
- 💬 [讨论区](https://github.com/LankFa/ocss/discussions)

---

## 📝 变更日志

### v1.4 (计划) - 基于 OpenClaw v2026.3.1

**✨ 新增**
- 新增"资源效率与可持续性"评估维度 (权重 10%)
- 新增 Token 消耗监控机制
- 新增 QMD 向量检索集成指南
- 新增四层加载架构标准
- 新增成本预算管理建议
- **新增本地LLM分流策略** (基于实际部署经验)
- **新增GPU显存监控** (针对本地模型部署)
- **新增内存盘优化指南** (SSD保护)

**🚀 基于 v2026.3.1 更新**
- **新增 Cron 轻量上下文模式** (`--light-context` / `lightContext`)
  - 心跳加载从 6,912 行减少到 767 行 (-89%)
  - 强烈建议日常 heartbeat 使用
- **新增 Docker/K8s 健康检查端点**
  - `/health`, `/healthz`, `/ready`, `/readyz`
  - 支持容器探针配置
- **新增诊断标志 (Diagnostics Flags)**
  - 支持精细化调试 (`llm.*`, `provider.*`, `gateway.*`)
  - 可通过 `OPENCLAW_DIAGNOSTICS` 环境变量启用
- **新增飞书功能增强**
  - Docx 表格创建/写入
  - 图片/文件上传
  - 消息 reactions 支持
  - 聊天成员查询
- **新增容器化部署评估子项** (权重 10%)
  - 健康检查端点配置
  - 容器日志管理
  - 资源限制
  - WebSocket 传输配置

**📖 文档**
- 新增最佳实践案例
- 新增完整配置示例
- 新增 v2026.3.1 兼容性说明

---

> **更新记录**: 
> - 2026-03-02: 基于 OpenClaw v2026.3.1 更新
>   - 新增轻量上下文模式检查
>   - 新增容器健康检查端点
>   - 新增诊断标志配置
>   - 新增飞书功能增强检查
> - 2026-03-02: 新增版本兼容性说明
>   - 添加最低版本要求说明
>   - 提供旧版本 Fallback 方案
>   - 新增版本兼容性检查脚本

---

> **附注**: 本完善版本基于实际部署经验补充，特别是本地LLM（GTX 1660 + Qwen2.5 7B）的实战经验。

让我们一起打造更可持续的 AI 助手系统！ 🌱
