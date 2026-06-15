# 律信智管 CaseRun MCP

面向 AI 时代律师的办案连接层。让律师把自己的案件、材料、证据、费用、进度和办案动作安全接入支持 MCP 的 AI 工具。

> Keywords: legal mcp, lawyer mcp, law firm mcp, legal case management mcp, litigation mcp, evidence mcp, legal document mcp, legal workflow mcp, AI lawyer assistant, 法律 MCP, 律师 MCP, 律所 MCP, 案件管理 MCP, 诉讼 MCP, 证据 MCP, 法律文书 MCP

## 它不是一个普通插件

CaseRun MCP 的目标不是让 AI 多一个“查数据库”的按钮，而是让 AI 能围绕真实案件上下文协助律师工作：

- 开庭或会见前，快速整理案件事实、材料清单、证据重点和下一步建议。
- 客户临时追问时，直接查询案件进度、费用、材料和关键节点。
- 阅读合同、送达回证、聊天记录、转账凭证等材料后，生成进度草稿或文书起稿素材。
- 从一句自然语言开始新建案件、补记费用、登记进度，并按 Key 权限进入律信智管确认或写入。
- 做诉讼费、利息、违约金、日期期限等常用计算，把结果和案件关联起来。
- 帮律师减少反复复制粘贴、来回切系统、凭记忆找材料的时间。

一句话：把外部 AI 变成律师自己的 CaseRun 助理，而不是一个脱离业务系统的聊天窗口。

## 能帮律师做什么

| 场景 | 你可以这样问 AI | CaseRun MCP 能做的事 |
| --- | --- | --- |
| 案件盘点 | “帮我列出最近需要推进的案件，并说明原因。” | 查询本人授权案件、进度、费用和材料摘要。 |
| 会见准备 | “整理张三买卖合同纠纷的事实、证据和待问问题。” | 读取案件详情，检索材料和证据，输出结构化准备清单。 |
| 证据检索 | “找出合同里付款期限和违约责任相关条款。” | 在案件材料中检索证据片段，并返回来源。 |
| 进度登记 | “根据这份送达回证生成一条案件进度。” | 生成进度草稿，或在 Key 授权后写入低风险进度。 |
| 费用登记 | “给这个案子记一笔差旅费 500 元。” | 生成费用草稿，或在 Key 授权后写入费用台账。 |
| 新案录入 | “帮我创建一个案件，叫世界杯 7:1 惨案。” | 发起新建案件动作，并按 Key 设置确认或写入。 |
| 文书起稿 | “根据现有材料生成一份起诉状初稿要点。” | 读取案件上下文，调用文书生成能力输出草稿素材。 |
| 法律计算 | “标的额 10 万元，诉讼费大概多少？” | 调用诉讼费、利息、违约金、日期期限等计算工具。 |

## 能力地图

当前公开说明覆盖的工具能力包括：

- 案件查询：`case.list`、`case.detail`
- 进度查询与生成：`case.progress.query`、`case.progress.create`、`case.progress.analyze`
- 费用查询与登记：`case.fee.list`、`case.fee.create`
- 材料与证据：`case.file.list`、`case.evidence.read`、`case.evidence.search`
- 新建案件：`case.create`
- 法律文书：`legal.doc.list`、`legal.doc.generate`
- 常用计算：`tool.litigation_fee`、`tool.interest`、`tool.penalty`、`tool.date_calc`

所有只读操作面向当前律师本人授权数据。写入类操作由每个 MCP Key 的单项权限决定，可以不开放、生成确认单、或对低风险动作开启自动写入。高风险动作默认不开放；即使单独允许，也只进入律信智管确认流程。

## 从官网开始

官网地址：[https://lvxinzhiguan.com](https://lvxinzhiguan.com)

1. 登录律信智管。
2. 进入 `CaseRun`。
3. 打开 `MCP 接入与个人 Token` 页面。也可以在浏览器地址栏进入：

```text
https://lvxinzhiguan.com/lawyer/caserun/mcp
```

如果 `CaseRun` 里还看不到这个入口，说明当前律信智管版本还没有部署 CaseRun MCP Key 平台，需要先升级主项目。

4. 在 `新建个人 Token` 区域点击 `生成 Token`。
5. 填写 Token 名称，例如 `Cursor 工作电脑`、`Claude 桌面端`、`Codex 测试`。
6. 选择权限模板：
   - `只读查询`：适合先试用，只能查案件、读材料、做计算。
   - `草稿确认`：推荐默认项，写入动作会回到律信智管生成确认单。
   - `低风险自动写入`：适合自己的可信工具，可允许新建案件、进度、费用等低风险动作直接写入。
   - `高风险确认`：仅生成高风险确认单，不让外部 AI 自动执行。
7. 在 `单项操作权限` 中按工具逐项调整，例如只允许 `case.create` 发确认单，允许 `case.fee.create` 自动写入。
8. 点击生成 Token。Token 明文只展示一次，请立刻复制到你的 AI 工具。
9. 点击页面上的 `检查连接`，确认 `/mcp` 可以访问。

如果 AI 返回 `pending_action`，回到律信智管的 `CaseRun` 或 `MCP 接入与个人 Token` 页面，在最近调用记录中打开对应确认入口处理。

## MCP 客户端怎么填

MCP 服务地址：

```text
https://lvxinzhiguan.com/mcp
```

认证方式：

```text
Authorization: Bearer lxzg_mcp_xxx
```

通用配置示例：

```json
{
  "mcpServers": {
    "lvxin-caserun": {
      "type": "streamable-http",
      "url": "https://lvxinzhiguan.com/mcp",
      "headers": {
        "Authorization": "Bearer lxzg_mcp_REPLACE_ME"
      }
    }
  }
}
```

不同 AI 工具的字段名称可能略有差异，但核心只需要两件事：MCP HTTP 地址和 Bearer Token。Codex 配置可参考 `examples/codex-config.toml`。本项目不是 Codex 专用插件，Cursor、Claude Desktop、Codex、Cline、Cherry Studio 或其他支持 Streamable HTTP MCP 的 AI 工具都可以接入。

## 第一次怎么试

建议先用 `只读查询` 或 `草稿确认` Token 试下面几句：

```text
帮我列出最近 10 个案件，并找出本周需要推进的案件。
```

```text
读取张三买卖合同纠纷的合同材料，列出关键证据和来源。
```

```text
根据送达回证给这个案件生成一条进度草稿。
```

```text
帮我创建一个案件，叫世界杯 7:1 惨案。
```

```text
给这个案件记一笔差旅费 500 元。
```

试用时可以在官网 MCP 页面观察三类结果：

- 只读工具能否返回真实授权数据。
- 写入动作是否按 Key 权限生成确认单或写入。
- 审计记录中是否能看到调用工具、状态、耗时和 pending ID。

## 安全模型

- MCP Key 只代表当前律师本人，不是全律所共享 Token。
- Token 明文只在创建时展示一次，数据库只保存 hash 和 prefix。
- 律师可以随时撤销某个 Key，撤销后外部 AI 立即失去访问权限。
- 所有只读工具默认可用，但只能读取当前律师有权访问的数据。
- 写入操作按 Key 的 `tool_permissions` 逐项控制。
- `confirm_draft` 会生成 `pending_action`，交回律信智管处理。
- `auto_write` 只适用于显式授权的低风险动作。
- 删除、批量、敏感动作不作为默认开放能力。
- Token 创建、撤销、工具调用、阻断、确认草稿和自动写入都应进入审计。

## 仓库边界

这个仓库是部分开源的 CaseRun MCP 接入包，适合律师试点、集成评估、部署对照和公开说明。

它公开：

- 产品定位与接入指引。
- SQL 迁移脚本。
- Nginx / systemd 部署样例。
- MCP 客户端配置样例。
- 冒烟验收脚本。
- PRD、任务拆解和上线验收文档。

它不公开：

- 律信智管主系统后端源码。
- 律信智管主系统前端源码。
- 真实生产配置、数据库备份、上传材料、律师账号或真实 Token。

公开仓库结构：

```text
overlay/sql/             数据库迁移 SQL
deploy/                  systemd / nginx 部署样例
examples/                MCP 客户端配置样例
scripts/                 部署后冒烟验收脚本
docs/                    PRD、任务拆解、上线验收文档
```

## 部署与验收

部署说明见 `DEPLOYMENT.md`。

本地或服务器部署后，可以运行：

```powershell
.\scripts\caserun-mcp-smoke.ps1 -MCPUrl https://lvxinzhiguan.com/mcp -Token lxzg_mcp_REPLACE_ME
```

验收重点：

- 官网能创建、撤销个人 Token。
- `/mcp` 能被支持 MCP 的 AI 工具连接。
- 只读工具能返回当前律师授权数据。
- 写入工具符合 Key 权限设置。
- 高风险动作不会被外部 AI 直接执行。
- 审计记录可查。
