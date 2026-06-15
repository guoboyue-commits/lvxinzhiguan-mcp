# Deployment Guide

## 前置条件

- 律信智管主项目已经升级到支持 CaseRun MCP Key 权限平台的版本。
- 本仓库只提供公开接入资料、SQL、部署样例和验收脚本，不包含主项目后端/前端私有实现源码。
- 主项目配置文件可以正常连接业务数据库。
- 已执行 `overlay/sql/caserun_mcp_v1_migration.sql`。
- 外网访问必须走 HTTPS。

## 构建验证

在主项目根目录执行：

```powershell
cd backend
go test ./api/controllers ./cmd/caserun-mcp ./internal/caserun -count=1
go build -o caserun-mcp ./cmd/caserun-mcp
```

前端构建：

```powershell
cd frontend
npm run build
```

## 启动 MCP HTTP 服务

示例：

```powershell
cd backend
$env:APP_CONFIG_PATH = "D:\deploy\lvxinzhiguan\config.yaml"
.\caserun-mcp.exe -transport http -addr :8091
```

Linux systemd 可参考 `deploy/caserun-mcp.service`。

## 反向代理

推荐外部只暴露：

```text
https://lvxinzhiguan.com/mcp
```

Nginx 样例见 `deploy/nginx.caserun-mcp.conf`。私有部署时把样例里的域名替换成自己的 HTTPS 域名。

主项目前端展示给律师的 MCP 地址由后端计算。生产环境建议显式配置：

```text
CASERUN_MCP_URL=https://lvxinzhiguan.com/mcp
FRONTEND_URL=https://lvxinzhiguan.com
```

## 本地验收

从本仓库运行脚本，并指向已部署的 MCP 地址：

```powershell
.\scripts\caserun-mcp-smoke.ps1 -MCPUrl https://lvxinzhiguan.com/mcp -Token lxzg_mcp_REPLACE_ME
```

如果在同一台机器上同时有主项目源码，也可以用脚本检查主项目约定结构：

```powershell
.\scripts\caserun-mcp-smoke.ps1 -ProjectRoot D:\code\IMPORTANT\lvxin\lvxinzhiguan -Http
```

## 回滚

1. 停止 `caserun-mcp` 服务。
2. 在前端隐藏或撤下 MCP 入口。
3. 撤销试点律师 Token。
4. 保留审计表，除非确认无需追溯。
