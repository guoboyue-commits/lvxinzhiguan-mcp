# CaseRun MCP v1 上线验收

> 版本日期：2026-06-14  
> 上游文档：`CaseRun-产品战略与MCP路线.md`、`CaseRun-MCP-连接器PRD.md`、`CaseRun-MCP-任务拆解.md`

## 1. 上线边界

v1 面向第一批愿意主动使用 AI 工具的律师，不面向全所统一开放。

本版本提供：

- 个人 MCP Token：明文只展示一次，数据库只保存哈希。
- HTTP MCP：外部 AI 工具使用 URL + Bearer Token 接入。
- 广覆盖只读：案件、进度、费用、材料、卷宗、模板、计算器等查询优先可用。
- 确认草稿：进度、费用、材料解析进度、卷宗 PDF 导出、法律文书生成等中低风险动作只创建 `pending_action`。
- 高风险阻断：删除、批量改动、名片/服务公开信息大改不由外部 AI 发起。
- 审计：记录 MCP token 创建/撤销、工具调用、状态、错误码、pending_id、耗时。

## 2. 部署步骤

1. 执行数据库迁移：

```sql
source sql/caserun_mcp_v1_migration.sql;
```

2. 配置对外 MCP 地址：

```bash
CASERUN_MCP_URL=https://your-domain.example/mcp
```

3. 启动 MCP HTTP 服务：

```bash
cd backend
go run ./cmd/caserun-mcp -transport http -addr :8091
```

4. 网关暴露：

- 对外路径建议固定为 `/mcp`。
- 必须使用 HTTPS。
- `/health` 可用于运维存活探测。
- `/mcp` 必须要求 `Authorization: Bearer <个人 Token>`。

## 3. 产品验收

上线前逐项验证：

- 律师能在 CaseRun 页面打开“连接 AI 工具”。
- 页面展示 MCP 服务地址、配置示例、安全说明。
- 能生成个人 Token，明文只在生成后展示一次。
- 刷新页面后只展示 Token 前缀、状态、创建时间、最近使用时间。
- 点击“检查 Token”能校验刚生成的 Token。
- 撤销 Token 后，下一次外部 MCP 请求失败。
- `tools/list` 能看到 CaseRun 工具清单。
- `case.list`、`case.detail`、`case.progress.query`、`case.fee.list`、`case.evidence.search` 能返回真实有权数据。
- 访问无权案件返回失败，不泄露案件内容。
- `case.progress.create`、`case.fee.create` 返回 `draft_created` 和 `confirm_url`，业务数据不直接落库。
- 打开 `confirm_url` 后 Web CaseRun 能展示对应确认卡。
- 确认后数据写入，取消后不写入。
- `case.delete`、`case.progress.delete`、`case.fee.delete` 返回 `blocked_high_risk`，不生成 pending。
- 只读工具的文本内容和 `structuredContent` 都按 `ok/status/summary_text/data/sources/warnings/next_actions` 返回。
- MCP HTTP 短时间高频请求会返回 429，不影响正常人工使用节奏。
- `caserun_mcp_audit` 有对应调用记录，且不保存 Token 明文或材料正文。

## 4. 试点律师准备

不要让律师从空系统开始试。每名试点律师至少准备：

- 5-10 个在办案件。
- 每案 2-5 条进度。
- 若干费用记录。
- 若干附件或已抽取材料文本。
- 至少一个“材料解析为进度草稿”的演示场景。

## 5. 自动化验证

后端最小验证：

```bash
cd backend
go test ./internal/caserun ./api/controllers ./api/routes ./cmd/caserun-mcp -count=1
```

前端最小验证：

```bash
cd frontend
npm run build
```

MCP 冒烟验证：

```powershell
tests/scripts/caserun-mcp-smoke.ps1
```

如果冒烟脚本需要真实 Token，使用试点律师新生成的个人 MCP Token，不要使用后台数据库里的哈希。

## 6. 试点记录

7 天内记录：

- 律师原始问题。
- 使用入口：内置 CaseRun / MCP。
- 成功或失败。
- 是否生成草稿。
- 是否确认写入。
- 失败原因：Token、地址、权限、空数据、工具不支持、AI 理解错误。
- 律师评价：如果下周不能用了，会不会想念。

## 7. 回滚

如需暂停外部 MCP：

- 网关下线 `/mcp`。
- 或撤销试点律师个人 Token。
- 或停止 `caserun-mcp` HTTP 服务。

已创建的 pending_action 仍按原 CaseRun 规则过期、取消或确认，不需要额外清理。
