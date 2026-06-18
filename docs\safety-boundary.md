# Safety Boundary

CaseRun MCP is designed as an authorized lawyer workspace bridge, not an unrestricted database API.

## Token Scope

Each MCP token belongs to one lawyer account. A token only represents that lawyer's authorized CaseRun access. It does not grant system-wide, law-firm-wide, or administrator access.

## Permission Groups

| Group | Recommended | Behavior |
| --- | --- | --- |
| `read_only` | For research clients | Read case, evidence, progress, fee, and calculator data only. |
| `draft_confirm` | Default recommendation | Read data and create pending write drafts that must be confirmed inside Lvxinzhiguan. |
| `low_risk_auto_write` | Only for trusted automation | Allows a small allowlist of low-risk writes and records full audit rows. |
| `high_risk_confirm` | Rare | Can prepare high-risk confirmation drafts, but still cannot auto-run high-risk operations. |

## Write Rules

- External AI clients should not directly mutate sensitive business data.
- Ordinary write actions return `draft_created` with a `pending_id` and `confirm_url`.
- Lvxinzhiguan must confirm or cancel the pending action.
- High-risk operations return `blocked_high_risk` unless a special high-risk-confirm workflow is explicitly used.
- Revoked tokens must be rejected by `/mcp` with HTTP 401.

## Audit Rules

The system records:

- MCP token creation and revocation.
- Tool name and status.
- Pending action ids for draft writes.
- Blocked high-risk attempts.
- Confirmation and cancellation outcomes.

## Public Repository Rules

This public package must not contain:

- `config.yaml` or production environment files.
- Real MCP tokens, JWTs, passwords, API keys, or database credentials.
- TLS certificates, payment certificates, or private keys.
- SQL database dumps.
- Uploaded client or case files.
- Private Lvxinzhiguan source code outside this MCP client package.
