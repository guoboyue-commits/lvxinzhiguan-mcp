# Lvxin CaseRun MCP

Public client package for the Lvxinzhiguan CaseRun MCP service.

This package is intentionally small. It contains connection examples, tool documentation, safety rules, and smoke-test scripts for the hosted MCP endpoint:

```text
https://lvxinzhiguan.com/mcp
```

It does not contain the private Lvxinzhiguan application source code, production configuration, database dumps, certificates, upload files, or real MCP tokens.

## What This MCP Does

CaseRun MCP lets an authorized lawyer connect their own Lvxinzhiguan CaseRun workspace to MCP-capable AI clients. The AI client can inspect case data, read authorized materials, search evidence, run legal calculators, and prepare draft write actions.

Write safety is part of the product boundary:

- Read tools return only data authorized for the current lawyer token.
- Draft-confirm write tools create pending actions that must be confirmed inside Lvxinzhiguan.
- High-risk operations such as case deletion are blocked by default.
- Token use, draft creation, confirmation, cancellation, and revocation are audited.
- Never commit real tokens to GitHub, issue trackers, logs, screenshots, or example config files.

## Codex Setup

Codex CLI can connect to the hosted streamable HTTP MCP endpoint without storing the token in `config.toml`:

```powershell
codex mcp add lvxin-caserun --url https://lvxinzhiguan.com/mcp --bearer-token-env-var CASERUN_MCP_TOKEN
```

Then start Codex with a token in the process environment:

```powershell
$env:CASERUN_MCP_TOKEN = "<your personal MCP token>"
codex
```

The resulting Codex MCP config should look like this:

```toml
[mcp_servers.lvxin-caserun]
url = "https://lvxinzhiguan.com/mcp"
bearer_token_env_var = "CASERUN_MCP_TOKEN"
```

## Generic MCP Client Config

Some clients accept JSON-style MCP configuration:

```json
{
  "mcpServers": {
    "lvxin-caserun": {
      "type": "streamable-http",
      "url": "https://lvxinzhiguan.com/mcp",
      "headers": {
        "Authorization": "Bearer <your personal MCP token>"
      }
    }
  }
}
```

Prefer environment-variable based token injection when the client supports it.

## Smoke Test

Use the included PowerShell smoke script with a temporary personal MCP token:

```powershell
$env:CASERUN_MCP_URL = "https://lvxinzhiguan.com/mcp"
$env:CASERUN_MCP_TOKEN = "<temporary personal MCP token>"
$env:CASERUN_PILOT_CASE_ID = "<authorized case id>"
.\scripts\caserun-mcp-smoke.ps1
```

The smoke script verifies:

- `/mcp` rejects missing authorization.
- MCP `initialize` succeeds with the token.
- `tools/list` exposes the expected CaseRun tools.
- Representative read tools can be called for the supplied case.
- `case.delete` is blocked as a high-risk action.

## Documentation

- [Tool Catalog](docs/tool-catalog.md)
- [Safety Boundary](docs/safety-boundary.md)
- [Deployment Notes](docs/deployment-notes.md)
- [Acceptance Evidence](docs/acceptance-evidence.md)

## License

This public package is licensed under the MIT License. The private Lvxinzhiguan application and production infrastructure are not included in this package.
