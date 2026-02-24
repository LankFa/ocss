# OpenClaw 安全评估标准 (OCSS) v1.3

[![版本](https://img.shields.io/badge/版本-v1.3-blue)](https://github.com/LankFa/ocss)
[![许可证](https://img.shields.io/badge/许可证-MIT-green)](LICENSE)
[![状态](https://img.shields.io/badge/状态-正式发布-green)](STATUS)

## 概述

OpenClaw 安全评估标准 (OpenClaw Security Standard, OCSS) 是一套标准化的框架，用于评估 OpenClaw 部署的安全性。该标准提供了一个系统性的方法来评估、比较和改进 OpenClaw 实例的安全配置。

## v1.3 更新说明

### 新增维度：信息发布安全 (5%)

v1.3 正式引入"信息发布安全"维度，重点关注 AI Agent 内容安全：

- **内容发布前审核机制**
- **免责声明自动附加**
- **数据真实性保障**
- **加密与隐私保护**

### 评估维度

| 维度 | 权重 |
|------|------|
| 1. 网络安全 | 15% |
| 2. 外来分析 | 15% |
| 3. 第三方插件 | 15% |
| 4. 代码安全 | 15% |
| 5. 账户安全 | 15% |
| 6. 系统维护 | 15% |
| 7. 数据保护 | 5% |
| 8. 信息发布安全 | 5% |

## 快速开始

### 运行安全评估

```bash
# 克隆仓库
git clone https://github.com/LankFa/ocss.git
cd ocss

# 运行评估
bash scripts/security_audit.sh
```

### 评分等级

- A+ (90-100): 极高安全性
- A (80-89): 高安全性  
- B+ (70-79): 中上安全性
- B (60-69): 中等安全性
- C (50-59): 较低安全性
- D (40-49): 低安全性
- F (<40): 极低安全性

## 文档

- [OCSS v1.3 提案](./ocss_v1.3_proposal.md) - 完整提案文档
- [OCSS v1.3 修订说明](./ocss_v1.3_revision_notes.md) - 修订详情
- [标准文档](./openclaw_security_standard.md) - 完整评估标准
- [使用指南](./docs/USAGE_GUIDE.md) - 详细使用说明
- [快速参考](./docs/ocss_quick_reference.md) - 快速上手指南

## 社区

- [发布论坛](https://discord.com/channel/OpenClaw?ref=ocss-release) - v1.3 发布讨论

## 许可证

MIT License
