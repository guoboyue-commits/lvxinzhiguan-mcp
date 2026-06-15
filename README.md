# Lvxinzhiguan CaseRun MCP Connector

> Keywords: `legal mcp`, `lawyer mcp`, `law firm mcp`, `legal case management mcp`, `legal workflow mcp`, `legal ai mcp`, `case management mcp`, `litigation mcp`, `evidence mcp`, `legal document mcp`, `AI lawyer assistant`, `Model Context Protocol`, `法律 MCP`, `律师 MCP`, `律所 MCP`, `案件管理 MCP`, `证据检索 MCP`, `法律文书 MCP`

这是律信智管 CaseRun 的 MCP 增量包，为 AI 时代的律师设计。它把律师本人的 CaseRun 工作台连接到支持 Model Context Protocol 的外部 AI 工具，让 AI 可以在真实办案上下文里查案件、读材料、检索证据、计算费用、创建案件、生成进度/费用草稿和辅助文书起草。

当前仓库不是完整主项目，也不是可单独运行的 SaaS 服务。它是部分开源接入包：公开产品说明、SQL、部署样例、客户端配置、验收脚本和接入指引；律信智管后端/前端实现代码不在本仓库公开。

## 能做什么

- `case.list` / `case.detail`: 查询律师本人授权案件。
- `case.evidence.read` / `case.evidence.search`: 读取材料正文、检索证据摘录并返回来源。
- `case.create`: 按 MCP Key 权限创建案件确认单或执行被授权的低风险写入。
- `case.progress.create` / `case.progress.analyze`: 新增进度，或根据材料生成进度草稿。
- `case.fee.create`: 登记案件费用。
- `legal.doc.generate`: 基于案件上下文生成法律文书草稿。
- `tool.litigation_fee` / `tool.interest` / `tool.penalty` / `tool.date_calc`: 常用法律计算。

## MCP Key 权限平台

所有只读操作默认可用。写入动作由每个 MCP Key 的单项操作权限控制：

- `disabled`: 不开放该写入动作。
- `confirm_draft`: 生成 `pending_action`，由律信智管平台确认。
- `auto_write`: 对白名单低风险动作允许自动写入，并记录审计。
- `high_risk_confirm`: 高风险动作只生成系统确认单，不自动执行。

因此你可以给同一个 Key 配置成：查询全部可用、`case.create` 发确认单、`case.fee.create` 自动写入、删除类保持不开放。

数据库中 `caserun_mcp_token.permission_group` 保存权限模板，`caserun_mcp_token.tool_permissions` 保存每个 MCP tool 的单项权限 JSON。

## 已验证范围

- HTTP MCP Server: `/mcp` 使用 Bearer Token 鉴权。
- 个人 Token: 明文只展示一次，数据库只保存 hash、prefix、权限模板和工具级权限矩阵。
- 只读工具: 外部 AI 可以查询 CaseRun 中已授权律师自己的案件数据、材料和证据。
- 写入策略: 每个写入工具按 Key 单项权限执行，支持确认单、低风险自动写入和高风险确认。
- 高风险保护: 删除类工具默认 `blocked_high_risk`，显式授权后也只走高风险确认单。
- 审计: token 创建、撤销、工具调用、确认草稿都会进入 `caserun_mcp_audit`。

## 仓库结构

```text
overlay/sql/             数据库迁移 SQL
deploy/                  systemd / nginx 部署样例
examples/                MCP 客户端配置样例
scripts/                 面向主项目的本地验收脚本
docs/                    PRD、任务拆解、上线验收文档
```

## 集成方式

1. 在主项目数据库执行 `overlay/sql/caserun_mcp_v1_migration.sql`。
2. 将律信智管主项目升级到支持 CaseRun MCP Key 权限平台的版本。
3. 在主项目中运行后端测试和前端构建。
4. 部署 `caserun-mcp` HTTP 服务，并通过反向代理暴露 `/mcp`。
5. 律师在 CaseRun MCP 接入页生成个人 Token，配置单项操作权限，再粘贴到 MCP 客户端。

## 客户端连接

MCP 地址示例：

```text
https://your-domain.example/mcp
```

认证方式：

```text
Authorization: Bearer lxzg_mcp_xxx
```

Codex 配置可参考 `examples/codex-config.toml`。不同 MCP 客户端的字段名可能不同，但核心只有两件事：HTTP MCP 地址和 Bearer Token。本项目不是 Codex 专用插件，任何支持 Streamable HTTP MCP 的 AI 工具都可以接入。

## 典型提示

- “帮我查询最近 10 个案件，并找出本周需要推进的案子。”
- “读取张三买卖合同纠纷的合同材料，列出关键证据。”
- “帮我创建一个案件，叫世界杯 7:1 惨案。”
- “根据这份送达回证生成一条案件进度草稿。”
- “给这个案件记一笔差旅费 500 元。”

## 下一步

这个仓库适合作为先进用户试点和上架材料沉淀。如果后续要做成真正独立开源包，需要再做一层 API Client，把它从主项目内部模型、权限、插件注册表里抽离出来。
