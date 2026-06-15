# Security Notes

## 不要提交

- `config.yaml`
- `.env`
- 数据库备份
- 上传文件
- 构建产物
- 真实 Token
- 真实律师账号密码

## MCP Key 边界

- MCP Key 只代表当前律师本人。
- MCP Key 明文只在创建时返回一次。
- 数据库只保存 `token_hash` 和 `token_prefix`。
- 撤销后，外部 AI 立即无法继续访问。
- 每个 Key 可以配置单项操作权限，不需要把所有写入能力一次性打开。

## 操作权限

- 所有只读工具默认可用：案件查询、材料读取、证据检索、费用/日期/利息等计算。
- 写入工具按 Key 的 `tool_permissions` 单项配置。
- `confirm_draft` 会生成 `pending_id` 和确认草稿。
- `auto_write` 只适用于白名单低风险动作，例如 `case.create`、`case.progress.create`、`case.fee.create`。
- `high_risk_confirm` 只生成高风险确认单，不自动执行。
- `disabled` 表示该 Key 不能发起对应写入动作。

推荐默认配置：

- 普通试用：只读 + `case.create` / 进度 / 费用发确认单。
- 可信个人工具：对少量低风险动作开启 `auto_write`。
- 删除、批量、敏感动作：单独评估，不作为默认配置。

## 审计

所有 MCP 调用都应记录到 `caserun_mcp_audit`，至少包含：

- 用户
- Token
- 工具名
- 案件 ID
- 状态
- 错误码
- pending ID
- 耗时

上线后建议每天查看异常状态和高频调用。
