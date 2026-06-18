# Acceptance Evidence

Latest verified production pilot:

```text
Report: tests/reports/caserun-mcp-pilot-live-20260618-065836.json
Overall: pass
Endpoint: https://lvxinzhiguan.com/mcp
Environment: production-public-mcp-codex-20260618-resume
```

Verified checks:

- Lawyer login succeeded.
- Pilot case was created.
- Pilot evidence text was seeded.
- Personal MCP token was created.
- External MCP endpoint was ready and rejected missing authorization.
- MCP tool calls completed for read tools and draft-write checks.
- `case.progress.create` produced a pending action and was confirmed.
- `case.fee.create` produced a pending action and was canceled.
- Confirmed progress was visible in the case.
- Revoked token was rejected by `/mcp` with HTTP 401.
- Audit rows were found for token creation, read calls, draft writes, high-risk blocking, and token revocation.

Direct local Codex verification was also performed with a temporary token:

- Codex connected to `lvxin-caserun`.
- Codex called `case.detail`, `case.fee.list`, `case.progress.query`, and `case.delete`.
- `case.delete` returned `blocked_high_risk`.
- The temporary token was revoked and then rejected by `/mcp` with HTTP 401.

Real tokens and JWTs are intentionally excluded from this public package.
