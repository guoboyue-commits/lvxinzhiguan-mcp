# CaseRun MCP Server

**A Legal MCP Server for AI-era lawyers.** Connect your Lvxinzhiguan CaseRun workspace to AI tools through the Model Context Protocol, so your AI assistant can work with real cases, evidence, fees, progress notes, legal documents, and litigation calculations.

> Keywords: `legal mcp`, `lawyer mcp`, `law firm mcp`, `legal case management mcp`, `litigation mcp`, `evidence mcp`, `legal document mcp`, `legal workflow mcp`, `AI lawyer assistant`, `法律 MCP`, `律师 MCP`, `律所 MCP`, `案件管理 MCP`, `诉讼 MCP`, `证据 MCP`, `法律文书 MCP`

CaseRun MCP is built for lawyers who want AI to do more than chat. It gives supported AI clients a structured way to query authorized case data, read matter materials, search evidence, draft progress records, create cases, record fees, generate legal document drafts, and run common legal calculations.

## What It Helps Lawyers Do

- Prepare for a meeting, hearing, or client call with a case summary, evidence checklist, fee status, and next-step suggestions.
- Ask an AI tool to find clauses, payment terms, breach liability, chat records, transfer proofs, or delivery notices from case materials.
- Turn materials into a case progress draft without copying text between systems.
- Create a new case from natural language and let Lvxinzhiguan decide whether it needs confirmation or can be written directly.
- Record low-risk items such as case progress or expenses when the MCP Key has explicit permission.
- Calculate litigation fees, interest, penalties, deadlines, and holiday-aware dates.
- Generate legal document draft material using real case context.

## MCP Endpoint

```text
https://lvxinzhiguan.com/mcp
```

Transport:

```text
Streamable HTTP
```

Authentication:

```text
Authorization: Bearer lxzg_mcp_xxx
```

The server uses Streamable HTTP MCP. It is not a Codex-only plugin; it can be used by any AI client that supports HTTP MCP, such as Cursor, Claude Desktop, Codex, Cline, Cherry Studio, or similar tools.

## Quick Start

1. Open [https://lvxinzhiguan.com](https://lvxinzhiguan.com) and log in.
2. Go to `CaseRun`.
3. Open `MCP 接入与个人 Token`, or visit:

```text
https://lvxinzhiguan.com/lawyer/caserun/mcp
```

4. Create a personal MCP Token.
5. Choose a permission template:
   - `只读查询`: query cases, read materials, search evidence, and use calculators.
   - `草稿确认`: recommended default; write actions create `pending_action` items for Lvxinzhiguan confirmation.
   - `低风险自动写入`: explicitly allows selected low-risk writes such as case creation, progress records, or fee records.
   - `高风险确认`: can create high-risk confirmation items, but external AI still cannot execute high-risk actions directly.
6. Adjust per-tool permissions under `单项操作权限`.
7. Copy the token. It is shown only once.
8. Add the MCP endpoint and Bearer token to your AI client.
9. Run a simple prompt such as “列出我最近 10 个案件，并标出需要推进的事项”.

## Client Config

Generic JSON-style config:

```json
{
  "mcpServers": {
    "caserun": {
      "type": "streamable-http",
      "url": "https://lvxinzhiguan.com/mcp",
      "headers": {
        "Authorization": "Bearer lxzg_mcp_REPLACE_ME"
      }
    }
  }
}
```

Codex-style TOML example:

```toml
[mcp_servers.caserun]
url = "https://lvxinzhiguan.com/mcp"
headers = { Authorization = "Bearer lxzg_mcp_REPLACE_ME" }
```

Never paste a real MCP Token into GitHub, screenshots, shared prompts, issues, logs, or public config files.

## Tools

Tool names are stable and intentionally business-oriented. Read tools return authorized case data and source-backed context. Write tools return either a business result, a `pending_action`, or a permission message depending on the MCP Key settings.

### Cases

| Tool | Purpose |
| --- | --- |
| `case.list` | List authorized cases for the current lawyer. |
| `case.detail` | Read case details, status, parties, key fields, and context. |
| `case.create` | Create a case through confirmation or explicitly allowed low-risk write. |

### Materials And Evidence

| Tool | Purpose |
| --- | --- |
| `case.file.list` | List case files and uploaded materials. |
| `case.evidence.read` | Read extracted text from case materials. |
| `case.evidence.search` | Search evidence snippets and return source-backed hits. |

### Progress And Fees

| Tool | Purpose |
| --- | --- |
| `case.progress.query` | Query case progress records. |
| `case.progress.create` | Draft or write a new case progress record. |
| `case.progress.analyze` | Generate a progress draft from materials or user-provided text. |
| `case.fee.list` | Query case fee ledger. |
| `case.fee.create` | Draft or write a new fee record. |

### Legal Documents And Calculators

| Tool | Purpose |
| --- | --- |
| `legal.doc.list` | List available legal document templates. |
| `legal.doc.generate` | Generate legal document draft material from case context. |
| `tool.litigation_fee` | Calculate litigation or court acceptance fees. |
| `tool.interest` | Calculate interest. |
| `tool.penalty` | Calculate penalty or liquidated damages. |
| `tool.date_calc` | Calculate dates, deadlines, and periods. |

## Permission Model

Each MCP Key belongs to one lawyer and can be revoked at any time. Read tools are available for the lawyer's authorized data. Write tools are controlled per operation.

Per-tool write actions:

| Action | Meaning |
| --- | --- |
| `disabled` | The MCP Key cannot start this write action. |
| `confirm_draft` | The tool creates a `pending_action`; Lvxinzhiguan handles final confirmation. |
| `auto_write` | A selected low-risk action can be written directly by Lvxinzhiguan backend with audit logging. |
| `high_risk_confirm` | The tool can create a high-risk confirmation item, but cannot execute it directly. |

Typical setup:

- First trial: `只读查询`.
- Normal lawyer workflow: `草稿确认`.
- Trusted personal AI client: selected `auto_write` only for low-risk tools.
- Sensitive or destructive work: keep disabled unless you deliberately need `high_risk_confirm`.

## Example Prompts

```text
帮我列出最近 10 个案件，并找出本周需要推进的案件。
```

```text
读取张三买卖合同纠纷的合同材料，列出付款期限、违约责任和证据来源。
```

```text
根据这份送达回证，为这个案件生成一条进度草稿。
```

```text
帮我创建一个案件：世界杯 7:1 惨案，类型先设为一般民事纠纷。
```

```text
给这个案件记一笔差旅费 500 元，备注为去法院阅卷。
```

```text
标的额 10 万元，帮我估算诉讼费，并说明计算过程。
```

## Troubleshooting

| Symptom | What To Check |
| --- | --- |
| AI client cannot connect | Confirm the URL is `https://lvxinzhiguan.com/mcp` and the client supports Streamable HTTP MCP. |
| Unauthorized | Regenerate the MCP Token and make sure the header is `Authorization: Bearer <token>`. |
| Tool returns no cases | Confirm the logged-in lawyer has authorized CaseRun data. |
| Write tool says permission denied | Open `MCP 接入与个人 Token` and enable that specific operation under `单项操作权限`. |
| You see `pending_action` | Return to Lvxinzhiguan CaseRun and confirm or reject the generated action. |
| High-risk action is blocked | This is expected unless the Key explicitly allows high-risk confirmation. Direct high-risk execution is not exposed to MCP clients. |

## Expected Write Responses

When a write tool is called, the AI client should expect one of these response shapes:

```json
{
  "ok": true,
  "status": "draft_created",
  "pending_id": "pending_xxx",
  "confirm_url": "https://lvxinzhiguan.com/lawyer/caserun?pending_id=pending_xxx"
}
```

```json
{
  "ok": true,
  "status": "auto_written",
  "message": "Low-risk action was written by Lvxinzhiguan backend according to token permission and audit policy."
}
```

```json
{
  "ok": false,
  "status": "permission_denied",
  "message": "This MCP Key is not allowed to call case.create."
}
```

## Security Notes

- MCP Tokens are personal. Do not share one token across a whole firm.
- Token plaintext is shown only once when created.
- Revoke a token immediately if it might have leaked.
- Read access follows the current lawyer's authorization.
- Write access is controlled by each Key's per-tool permission settings.
- Important business writes are either audited or routed back to Lvxinzhiguan confirmation.
