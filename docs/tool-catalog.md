# CaseRun MCP Tool Catalog

The hosted CaseRun MCP endpoint exposes business-data tools for the current lawyer token.

## Core Case Tools

| Tool | Mode | Purpose |
| --- | --- | --- |
| `case.list` | read | List authorized cases for the current lawyer. |
| `case.detail` | read | Read one authorized case. |
| `case.create` | write | Create a case through the configured write policy. |
| `case.update` | write | Update case metadata through the configured write policy. |
| `case.delete` | high risk | Blocked by default; never auto-deletes through ordinary MCP tokens. |
| `tool.case_meta` | read | Read case type and stage dictionaries. |

## Progress And Fee Tools

| Tool | Mode | Purpose |
| --- | --- | --- |
| `case.progress.query` | read | Read case progress records. |
| `case.progress.create` | write | Create a pending progress draft, or auto-write only for explicitly allowed low-risk tokens. |
| `case.progress.update` | write | Update progress through the configured write policy. |
| `case.progress.delete` | write/high risk | Restricted by permission and risk rules. |
| `case.fee.list` | read | Read case fee ledger data. |
| `case.fee.create` | write | Create a pending fee draft, or auto-write only for explicitly allowed low-risk tokens. |
| `case.fee.update` | write | Update a fee item through the configured write policy. |
| `case.fee.delete` | write/high risk | Restricted by permission and risk rules. |

## Evidence, Files, And Exports

| Tool | Mode | Purpose |
| --- | --- | --- |
| `case.file.list` | read | List case files. |
| `case.evidence.read` | read | Read authorized OCR/extracted evidence text. |
| `case.evidence.search` | read | Search authorized evidence text by keyword. |
| `case.export.list` | read | List export records. |
| `case.export.pdf` | write | Prepare a case bundle PDF action through confirmation. |

## Legal Document And Lawyer Tools

| Tool | Mode | Purpose |
| --- | --- | --- |
| `legal.doc.list` | read | List available legal document templates. |
| `legal.doc.generate` | write | Prepare legal document generation through confirmation. |
| `case.messages.query` | read | Query case messages where enabled. |
| `case.party.manage` | mixed | List or manage case parties according to action and permission. |
| `lawyer.profile.manage` | mixed | View statistics or manage profile fields according to action and permission. |
| `service.manage` | mixed | View or manage lawyer service items according to action and permission. |

## Calculator Tools

| Tool | Mode | Purpose |
| --- | --- | --- |
| `tool.litigation_fee` | read | Calculate litigation fees. |
| `tool.interest` | read | Calculate interest. |
| `tool.penalty` | read | Calculate penalty interest. |
| `tool.date_calc` | read | Calculate dates and deadlines. |
| `tool.holiday` | read | Check holiday information for a date. |

## Common Arguments

Most case-scoped tools accept either:

- `case_id`: numeric case id, preferred after calling `case.list`.
- `case_keyword`: text used by the system to resolve an authorized case.

Evidence search requires:

- `query`: keyword or phrase to search inside authorized case evidence.

Write draft tools usually accept:

- `case_id`
- `user_text`, `description`, or `content`
- tool-specific fields such as `amount`, `item_name`, or `stage`
- optional `session_id` for audit correlation
