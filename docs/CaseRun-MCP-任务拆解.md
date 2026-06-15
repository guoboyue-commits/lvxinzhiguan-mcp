# CaseRun MCP 任务拆解

> 更新时间：2026-06-14  
> 上游 PRD：[CaseRun-MCP-连接器PRD.md](./CaseRun-MCP-连接器PRD.md)  
> 用途：作为后续 issue 拆分和工程推进清单。每一项都应可以转成独立任务。

## 0. 当前基线

已经具备：

- MCP 服务入口：`backend/cmd/caserun-mcp/main.go`
- MCP Server：`backend/internal/caserun/mcp_server.go`
- MCP 工具清单：`backend/internal/caserun/mcp_manifest.go`
- MCP 工具 Schema：`backend/internal/caserun/mcp_tool_schema.go`
- MCP Resources：`backend/internal/caserun/mcp_resources.go`
- HTTP JWT 鉴权：`backend/internal/caserun/mcp_auth.go`
- 写操作拦截：MCP 中非只读 Tool 返回 `write_requires_confirm`
- 确认卡底座：`backend/internal/caserun/pending_action.go`
- 写入执行底座：`backend/internal/caserun/write_exec.go`
- Web 确认卡 UI：`frontend/src/views/caserun/Index.vue`
- MCP smoke 脚本：`tests/scripts/caserun-mcp-smoke.ps1`

主要缺口：

- 没有个人 MCP Token。
- 没有律师侧“连接 AI 工具”页面。
- HTTP MCP 目前更像工程入口，不像用户可配置产品入口。
- MCP 写类 Tool 只拦截，没有生成确认草稿。
- Web 还没有确认链接直达 `pending_id` 的体验。
- 缺少 MCP 调用审计、最近连接时间和撤销闭环。
- 缺少 Codex 样板接入文档和试点手册。

## M0：现有 MCP 闭环复核

### MCP-001 复核当前 HTTP MCP 可运行

目标：确认当前代码里的 HTTP MCP 能启动、健康检查可用、基础鉴权可用。

产出：

- 本地启动命令记录。
- `/health` 通过。
- `/mcp` 未授权返回 401。
- 使用现有律师 JWT 可进入 MCP 会话。

验收：

- `tests/scripts/caserun-mcp-smoke.ps1` 通过。
- 补一条 HTTP 鉴权 smoke 记录。

### MCP-002 明确对外部署方式

目标：确定第一版 MCP 服务是独立端口、同域反代，还是挂到主后端。

建议：

- 第一阶段保留独立 `caserun-mcp` 服务。
- 生产通过网关暴露统一 HTTPS 地址。
- 对外路径使用 `/mcp`。

验收：

- 文档写清服务地址、反代路径、环境变量和启动方式。
- 运维知道如何重启和回滚。

### MCP-003 统一 MCP 返回结构

目标：让外部 AI 稳定理解工具返回。

范围：

- 只读成功结构。
- 确认草稿结构。
- 高风险拦截结构。
- 权限失败结构。

验收：

- 所有 MCP 工具返回包含 `ok`、`tool`、`status` 或 `summary_text`。
- 单测覆盖至少一个只读、一个写草稿、一个高风险拦截。

## M1：个人 MCP Token

### MCP-101 新增 Token 数据模型与迁移

目标：保存律师个人 MCP Token 的哈希和状态。

建议字段：

- `id`
- `user_id`
- `name`
- `token_prefix`
- `token_hash`
- `status`
- `last_used_at`
- `expires_at`
- `revoked_at`
- `created_at`
- `updated_at`

验收：

- 新增迁移 SQL。
- 新增 Go model。
- Token 明文不入库。

### MCP-102 Token 生成、列表、撤销 API

目标：给前端连接页面使用。

建议接口：

- `GET /api/v1/lawyer/caserun/mcp/tokens`
- `POST /api/v1/lawyer/caserun/mcp/tokens`
- `DELETE /api/v1/lawyer/caserun/mcp/tokens/:id`

验收：

- 生成时只返回一次明文 Token。
- 列表只返回前缀、名称、状态、创建时间、最近使用时间。
- 撤销后不可继续鉴权。

### MCP-103 HTTP MCP 支持个人 Token 鉴权

目标：`Authorization: Bearer <mcp_token>` 可映射到律师个人身份。

要求：

- 保留现有 JWT 鉴权作为开发兼容。
- 优先识别个人 MCP Token。
- 鉴权成功后更新 `last_used_at`。
- 角色与权限仍按用户身份加载。

验收：

- Token 可访问本人案件。
- Token 不可访问他人案件。
- 撤销 Token 返回 401。

### MCP-104 Token 安全测试

目标：确保 Token 生命周期可靠。

验收用例：

- 空 Token 拒绝。
- 错误 Token 拒绝。
- 已撤销 Token 拒绝。
- 哈希匹配成功。
- 明文 Token 不出现在数据库。

## M2：连接 AI 工具页面

### MCP-201 新增“连接 AI 工具”入口

目标：律师不需要理解底层协议也能完成连接。

位置建议：

- CaseRun 页面设置区。
- 或律师个人设置页。

页面内容：

- MCP 服务地址。
- Token 管理。
- 配置示例。
- 连接状态。
- 安全说明。

验收：

- 律师能生成 Token。
- 生成后能复制 Token。
- 刷新页面后明文 Token 不再显示。
- 可以撤销 Token。

### MCP-202 Codex 样板配置

目标：让第一批律师能照着配置。

内容：

- 服务 URL。
- Bearer Token 填写位置。
- 连接成功后如何测试 `case.list`。
- 失败时如何检查 Token 和服务地址。

验收：

- 非研发同学按文档可以完成连接。

### MCP-203 连接测试

目标：页面内告诉律师“能不能连上”。

验收：

- 未生成 Token 时提示先生成。
- 服务可用时返回成功。
- Token 撤销后测试失败。

## M3：只读工具强化

### MCP-301 案件权限复核

目标：确保所有只读工具都不会越权。

范围：

- `case.list`
- `case.detail`
- `case.progress.query`
- `case.fee.list`
- `case.messages.query`
- `case.file.list`
- `case.evidence.read`
- `case.evidence.search`

验收：

- 每个工具至少有一个权限测试。
- 越权案件 ID 返回明确错误。

### MCP-302 材料读取与检索可解释

目标：外部 AI 引用材料时能说明来源。

返回建议：

- 文件名。
- 页码或段落编号。
- 摘录。
- 抽取时间。

验收：

- `case.evidence.search` 返回命中来源。
- 没有材料时给出可行动提示。

### MCP-303 只读工具结果适配律师语言

目标：不仅返回原始 JSON，也返回可直接给律师看的摘要。

验收：

- 每个核心只读工具都有 `summary_text`。
- 外部 AI 不需要猜字段含义也能回答。

### MCP-304 Resource 入口补齐验收

目标：`case://{case_id}/summary` 和 `case://{case_id}/evidence` 可作为外部上下文资源使用。

验收：

- 有权限时可读。
- 无权限时拒绝。
- 空材料时返回明确提示。

## M4：确认草稿闭环

### MCP-401 建立 MCP 写操作风险矩阵

目标：每个非只读 Tool 都有明确处理策略。

分类：

- `draft_allowed`：可生成确认草稿。
- `blocked_high_risk`：只引导回系统。
- `not_supported_yet`：第一版暂不支持。

验收：

- 风险矩阵写入代码或测试固定数据。
- 单测覆盖所有非只读 Tool。

### MCP-402 MCP 写类 Tool 生成 pending_action

目标：中低风险写动作不再只返回 `write_requires_confirm`，而是生成确认草稿。

第一批支持：

- `case.progress.create`
- `case.progress.update`
- `case.fee.create`
- `case.fee.update`
- `case.progress.analyze`
- `case.export.pdf`
- `legal_doc.generate`

验收：

- 调用后数据库出现 pending。
- 业务数据尚未写入。
- 返回 `pending_id`、`preview`、`risk_level`、`expires_at`、`confirm_url`。

### MCP-403 高风险动作拦截

目标：删除和对外展示类高风险动作不能由外部 AI 发起。

第一批拦截：

- `case.delete`
- `case.progress.delete`
- `case.fee.delete`
- 大改律师名片。
- 发布、下架、批量修改服务产品。

验收：

- 返回 `blocked_high_risk`。
- 不生成 pending。
- 不写入业务数据。

### MCP-404 Web 支持 pending_id 确认链接

目标：律师从外部 AI 点击确认链接后能看到对应确认卡。

建议路由：

- `/lawyer/caserun?pending_id=<id>`

验收：

- 有效 pending 展示确认卡。
- 已确认 pending 展示已处理。
- 已取消 pending 展示已取消。
- 已过期 pending 展示过期提示。

### MCP-405 确认后沿用 write_exec

目标：MCP 草稿确认后和内置 CaseRun 一样落库。

验收：

- 确认新增进度后案件进度出现新记录。
- 取消后不落库。
- 结果写回 pending 状态。

## M5：审计与安全

### MCP-501 MCP 调用审计

目标：出现问题时能查到谁、何时、用哪个工具、结果如何。

建议记录：

- `user_id`
- `token_id`
- `tool`
- `case_id`
- `status`
- `error_code`
- `pending_id`
- `duration_ms`
- `created_at`

验收：

- 每次 MCP 工具调用都有审计记录。
- 不记录完整敏感材料正文。

### MCP-502 速率限制与超时

目标：防止外部 AI 工具误调用造成压力。

验收：

- 单 Token 基础限流。
- 材料读取有超时。
- 大结果分页或截断。

### MCP-503 Token 撤销立即生效

目标：律师撤销后外部 AI 立即失去访问权限。

验收：

- 撤销后下一次 MCP 请求返回 401。
- 页面显示撤销状态。

### MCP-504 敏感信息检查

目标：避免无意泄露 Token、内部错误栈或多租户信息。

验收：

- 错误响应不包含数据库连接、SQL、Token 明文。
- 日志不打印 Token 明文。

## M6：试点准备

### MCP-601 试点律师初始化

目标：避免律师第一次使用时系统里没有可用数据。

准备：

- 每名律师 5-10 个在办案件。
- 每案若干进度。
- 若干费用记录。
- 若干附件或证据摘录。
- 至少一个材料转进度草稿场景。

验收：

- 每名试点律师有可演示数据。

### MCP-602 7 天试点记录表

目标：收集真实使用证据。

记录：

- 提问原文。
- 使用入口。
- 成功或失败。
- 生成草稿次数。
- 确认次数。
- 用户评价。

验收：

- 试点结束后可整理成产品改进清单。

### MCP-603 演示脚本

目标：形成可复制的对外演示。

脚本建议：

1. 在 Codex 中查询最近案件。
2. 追问某案进度。
3. 检索某份材料。
4. 让 AI 拟一条进度。
5. 打开律信智管确认。
6. 回到案件查看新进度。

验收：

- 10 分钟内可完整演示。

## M7：发布与文档

### MCP-701 对外使用指南

目标：给试点律师一份简单说明。

内容：

- 什么能做。
- 什么不能做。
- 如何连接。
- 如何撤销。
- 写入为什么要确认。

验收：

- 非研发律师能读懂。

### MCP-702 内部排障指南

目标：销售、实施、研发能快速定位问题。

内容：

- Token 无效。
- 服务地址错误。
- 工具列表为空。
- 案件查不到。
- 草稿打不开。
- 确认失败。

验收：

- 每类问题都有检查路径。

### MCP-703 自动化测试集

目标：MCP 后续迭代不破坏核心闭环。

最小测试：

- Token 鉴权。
- 工具列表。
- 只读查询。
- 越权拒绝。
- 草稿生成。
- 确认落库。
- 取消不落库。
- 高风险拦截。

## 第一批建议开工顺序

建议先做这 5 张票：

1. MCP-101：个人 Token 数据模型与迁移。
2. MCP-102：Token 生成、列表、撤销 API。
3. MCP-103：HTTP MCP 支持个人 Token 鉴权。
4. MCP-201：连接 AI 工具页面。
5. MCP-402：MCP 写类 Tool 生成 pending_action。

理由：

- 前三项让先进律师真正能接入。
- 第四项降低第一次使用门槛。
- 第五项把“只读 MCP”升级成“能办事但不越权”的产品体验。
