# Manifest

## Public Boundary

This repository is the partial open-source package for Lvxinzhiguan CaseRun MCP.
It publishes integration docs, deployment examples, client examples, SQL, and
acceptance scripts. It intentionally does not publish the proprietary
Lvxinzhiguan backend/frontend implementation.

## Database

- `overlay/sql/caserun_mcp_v1_migration.sql`: creates `caserun_mcp_token`
  and `caserun_mcp_audit`, including `permission_group` and
  `tool_permissions`.

## Docs And Operations

- `README.md`: public positioning, keywords, capability overview, and quick start.
- `SECURITY.md`: MCP Key boundary and recommended permission posture.
- `DEPLOYMENT.md`: deployment outline for the MCP service and reverse proxy.
- `deploy/`: systemd and Nginx examples.
- `examples/`: MCP client configuration examples.
- `scripts/caserun-mcp-smoke.ps1`: smoke test script for deployed MCP endpoint.
- `docs/`: PRD, task breakdown, and acceptance notes.
