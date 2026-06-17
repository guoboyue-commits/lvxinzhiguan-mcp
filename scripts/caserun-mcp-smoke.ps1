# CaseRun MCP public smoke test.
# Requires a temporary personal MCP token with access to CASERUN_PILOT_CASE_ID.
$ErrorActionPreference = "Stop"

function Get-EnvText {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Default = ""
    )
    $value = [Environment]::GetEnvironmentVariable($Name)
    if ($null -eq $value) { return $Default }
    $trimmed = $value.Trim()
    if ($trimmed -eq "" -and $Default -ne "") { return $Default }
    return $trimmed
}

function New-RpcJson {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        $Params = $null,
        $ID = $null
    )
    $body = [ordered]@{ jsonrpc = "2.0" }
    if ($null -ne $ID) { $body.id = $ID }
    $body.method = $Method
    if ($null -ne $Params) { $body.params = $Params }
    return $body | ConvertTo-Json -Depth 30 -Compress
}

function Convert-McpResponse {
    param([string]$Content, [string]$ContentType)
    $payload = ($Content + "").Trim()
    if ($payload -eq "") { return $null }
    if (($ContentType + "") -match "text/event-stream") {
        $items = @()
        foreach ($line in ($payload -split "`r?`n")) {
            if ($line.StartsWith("data:")) {
                $items += $line.Substring(5).TrimStart()
            }
        }
        $payload = ($items -join "`n").Trim()
    }
    if ($payload -eq "") { return $null }
    return $payload | ConvertFrom-Json
}

function Invoke-Mcp {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        $Params = $null,
        [switch]$NoAuth
    )
    $script:NextID += 1
    $headers = @{
        Accept = "application/json, text/event-stream"
    }
    if (-not $NoAuth) {
        $headers.Authorization = "Bearer $script:Token"
    }
    if ($script:SessionID -ne "") {
        $headers["Mcp-Session-Id"] = $script:SessionID
        $headers["MCP-Protocol-Version"] = $script:ProtocolVersion
    }
    $response = Invoke-WebRequest -Uri $script:MCPUrl -Method Post -Headers $headers -Body (New-RpcJson -Method $Method -Params $Params -ID $script:NextID) -ContentType "application/json" -UseBasicParsing -TimeoutSec 30
    $session = $response.Headers["Mcp-Session-Id"]
    if ($script:SessionID -eq "" -and $null -ne $session) {
        $script:SessionID = [string]$session
    }
    $parsed = Convert-McpResponse -Content $response.Content -ContentType ([string]$response.Headers["Content-Type"])
    if ($null -ne $parsed -and $null -ne $parsed.error) {
        throw "MCP $Method error: $($parsed.error.code) $($parsed.error.message)"
    }
    return $parsed
}

function Invoke-Tool {
    param([string]$Name, [hashtable]$Arguments = @{})
    return Invoke-Mcp -Method "tools/call" -Params @{
        name = $Name
        arguments = $Arguments
    }
}

function Get-ToolJson {
    param($Result)
    if ($null -eq $Result -or $null -eq $Result.result) { return $null }
    foreach ($item in @($Result.result.content)) {
        $text = [string]$item.text
        if ($text.Trim().StartsWith("{") -or $text.Trim().StartsWith("[")) {
            return $text | ConvertFrom-Json
        }
    }
    return $null
}

$script:MCPUrl = Get-EnvText "CASERUN_MCP_URL" "https://lvxinzhiguan.com/mcp"
$script:Token = Get-EnvText "CASERUN_MCP_TOKEN"
$caseIDText = Get-EnvText "CASERUN_PILOT_CASE_ID"
$script:ProtocolVersion = "2025-06-18"
$script:SessionID = ""
$script:NextID = 0

if ($script:Token -eq "") {
    throw "Set CASERUN_MCP_TOKEN to a temporary personal MCP token."
}
if ($caseIDText -eq "") {
    throw "Set CASERUN_PILOT_CASE_ID to an authorized case id."
}
$caseID = [int64]$caseIDText

$checks = New-Object System.Collections.Generic.List[object]

try {
    Invoke-Mcp -Method "initialize" -Params @{
        protocolVersion = $script:ProtocolVersion
        capabilities = @{}
        clientInfo = @{ name = "caserun-public-smoke"; version = "1.0.0" }
    } -NoAuth | Out-Null
    $checks.Add([pscustomobject]@{ name = "token_required"; status = "fail"; evidence = "/mcp accepted missing Authorization" })
} catch {
    $status = 0
    try { $status = [int]$_.Exception.Response.StatusCode } catch {}
    if ($status -eq 401) {
        $checks.Add([pscustomobject]@{ name = "token_required"; status = "pass"; evidence = "/mcp rejected missing Authorization with HTTP 401" })
    } else {
        $checks.Add([pscustomobject]@{ name = "token_required"; status = "fail"; evidence = "Expected HTTP 401, got HTTP $status" })
    }
}

Invoke-Mcp -Method "initialize" -Params @{
    protocolVersion = $script:ProtocolVersion
    capabilities = @{}
    clientInfo = @{ name = "caserun-public-smoke"; version = "1.0.0" }
} | Out-Null
$checks.Add([pscustomobject]@{ name = "initialize"; status = "pass"; evidence = "MCP initialize succeeded" })

$tools = Invoke-Mcp -Method "tools/list"
$toolNames = @($tools.result.tools | ForEach-Object { $_.name })
$required = @("case.detail", "case.fee.list", "case.progress.query", "case.evidence.search", "case.delete")
$missing = @($required | Where-Object { $toolNames -notcontains $_ })
if ($missing.Count -eq 0) {
    $checks.Add([pscustomobject]@{ name = "tools_list"; status = "pass"; evidence = "Required tools exposed" })
} else {
    $checks.Add([pscustomobject]@{ name = "tools_list"; status = "fail"; evidence = "Missing tools: $($missing -join ', ')" })
}

Invoke-Tool -Name "case.detail" -Arguments @{ case_id = $caseID } | Out-Null
Invoke-Tool -Name "case.fee.list" -Arguments @{ case_id = $caseID } | Out-Null
Invoke-Tool -Name "case.progress.query" -Arguments @{ case_id = $caseID } | Out-Null
$checks.Add([pscustomobject]@{ name = "case_reads"; status = "pass"; evidence = "case.detail, case.fee.list, case.progress.query returned for case_id=$caseID" })

$delete = Get-ToolJson (Invoke-Tool -Name "case.delete" -Arguments @{ case_id = $caseID; session_id = "public-smoke" })
if ($null -ne $delete -and $delete.status -eq "blocked_high_risk") {
    $checks.Add([pscustomobject]@{ name = "risk_block"; status = "pass"; evidence = "case.delete returned blocked_high_risk" })
} else {
    $checks.Add([pscustomobject]@{ name = "risk_block"; status = "fail"; evidence = "case.delete was not blocked_high_risk" })
}

$overall = "pass"
if (@($checks | Where-Object { $_.status -eq "fail" }).Count -gt 0) {
    $overall = "fail"
}

$report = [ordered]@{
    overall = $overall
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    mcp_url = $script:MCPUrl
    case_id = $caseID
    checks = $checks
}

$report | ConvertTo-Json -Depth 20
if ($overall -ne "pass") { exit 1 }
