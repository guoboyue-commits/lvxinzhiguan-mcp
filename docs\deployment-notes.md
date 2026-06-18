# Deployment Notes

The production endpoint currently used by clients is:

```text
https://lvxinzhiguan.com/mcp
```

The hosted endpoint is protected by bearer-token authentication. A request without `Authorization: Bearer <token>` must return HTTP 401.

## Health Checks

Public checks that do not require a token:

```powershell
curl.exe -i https://lvxinzhiguan.com/deploy-info.json
curl.exe -i https://lvxinzhiguan.com/mcp-health
```

Expected results:

- `deploy-info.json` returns HTTP 200 and identifies the active frontend build.
- `mcp-health` returns HTTP 200 with body `ok`.
- `/mcp` without authorization returns HTTP 401.

## Database Migration

Production requires the token permission-group migration in:

```text
sql/caserun_mcp_permission_group_migration.sql
```

The migration is idempotent. It adds `caserun_mcp_token.permission_group`, defaults existing tokens to `draft_confirm`, and creates an index for permission filtering.

## Nginx Shape

The public `/mcp` location should forward authorization headers to the internal MCP service and keep streaming responses unbuffered:

```nginx
location /mcp {
    proxy_pass http://127.0.0.1:8864/mcp;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header Authorization $http_authorization;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
    proxy_read_timeout 300s;
    proxy_send_timeout 300s;
    proxy_buffering off;
}
```

The internal port may differ by deployment. Keep the public URL stable.
