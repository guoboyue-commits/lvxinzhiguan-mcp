param(
    [string]$ProjectRoot = "",
    [string]$MCPUrl = "",
    [string]$Token = "",
    [switch]$Http,
    [int]$Port = 8092
)

$ErrorActionPreference = "Stop"

function Get-HeaderValue {
    param(
        [Parameter(Mandatory = $true)]$Headers,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $value = $Headers[$Name]
    if ($value -is [array]) {
        return $value[0]
    }
    return $value
}

function Invoke-MCPJsonRpc {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][hashtable]$Body,
        [string]$BearerToken = "",
        [string]$SessionId = ""
    )

    $headers = @{
        "Accept"       = "application/json, text/event-stream"
        "Content-Type" = "application/json"
    }
    if (![string]::IsNullOrWhiteSpace($BearerToken)) {
        $headers["Authorization"] = "Bearer $BearerToken"
    }
    if (![string]::IsNullOrWhiteSpace($SessionId)) {
        $headers["Mcp-Session-Id"] = $SessionId
    }

    $json = $Body | ConvertTo-Json -Depth 20 -Compress
    return Invoke-WebRequest -Uri $Url -Method Post -Headers $headers -Body $json -UseBasicParsing -TimeoutSec 20
}

function Test-RemoteMCP {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$BearerToken
    )

    if ([string]::IsNullOrWhiteSpace($BearerToken)) {
        throw "Please pass -Token with a personal MCP token."
    }

    $initBody = @{
        jsonrpc = "2.0"
        id = 1
        method = "initialize"
        params = @{
            protocolVersion = "2025-06-18"
            capabilities = @{}
            clientInfo = @{
                name = "caserun-mcp-smoke"
                version = "1.0.0"
            }
        }
    }

    $init = Invoke-MCPJsonRpc -Url $Url -BearerToken $BearerToken -Body $initBody
    if ($init.StatusCode -lt 200 -or $init.StatusCode -ge 300) {
        throw "MCP initialize returned HTTP $($init.StatusCode)"
    }
    Write-Host "MCP initialize OK" -ForegroundColor Green

    $sessionId = Get-HeaderValue -Headers $init.Headers -Name "Mcp-Session-Id"

    $initializedBody = @{
        jsonrpc = "2.0"
        method = "notifications/initialized"
        params = @{}
    }
    try {
        Invoke-MCPJsonRpc -Url $Url -BearerToken $BearerToken -SessionId $sessionId -Body $initializedBody | Out-Null
    } catch {
        Write-Host "MCP initialized notification skipped: $($_.Exception.Message)" -ForegroundColor DarkYellow
    }

    $toolsBody = @{
        jsonrpc = "2.0"
        id = 2
        method = "tools/list"
        params = @{}
    }
    $tools = Invoke-MCPJsonRpc -Url $Url -BearerToken $BearerToken -SessionId $sessionId -Body $toolsBody
    if ($tools.StatusCode -lt 200 -or $tools.StatusCode -ge 300) {
        throw "MCP tools/list returned HTTP $($tools.StatusCode)"
    }
    if ($tools.Content -notmatch "tools") {
        Write-Host "MCP tools/list OK, but response did not include a plain tools field. Client may return SSE." -ForegroundColor DarkYellow
        return
    }
    Write-Host "MCP tools/list OK" -ForegroundColor Green
}

if (![string]::IsNullOrWhiteSpace($MCPUrl)) {
    Test-RemoteMCP -Url $MCPUrl -BearerToken $Token
    exit 0
}

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $candidate = Join-Path (Split-Path -Parent $PSScriptRoot) "..\lvxinzhiguan"
    if (Test-Path -LiteralPath $candidate) {
        $ProjectRoot = (Resolve-Path $candidate).Path
    } else {
        throw "Please pass -ProjectRoot pointing to the main lvxinzhiguan repository."
    }
}

$ProjectRoot = (Resolve-Path $ProjectRoot).Path
$BackendRoot = Join-Path $ProjectRoot "backend"
$ConfigPath = Join-Path $ProjectRoot "config.yaml"

if (!(Test-Path -LiteralPath $BackendRoot)) {
    throw "Backend directory not found: $BackendRoot"
}

Push-Location $BackendRoot
try {
    $OutPath = Join-Path ([System.IO.Path]::GetTempPath()) "caserun-mcp-smoke-$PID.exe"
    go build -o $OutPath ./cmd/caserun-mcp
    if ($LASTEXITCODE -ne 0) { throw "caserun-mcp build failed" }
    Write-Host "caserun-mcp build OK" -ForegroundColor Green
} finally {
    if ($OutPath -and (Test-Path -LiteralPath $OutPath)) {
        Remove-Item -LiteralPath $OutPath -Force -ErrorAction SilentlyContinue
    }
    Pop-Location
}

if (!$Http) {
    Write-Host "TIP: add -Http to start server and probe /health" -ForegroundColor DarkYellow
    exit 0
}

if (!(Test-Path -LiteralPath $ConfigPath)) {
    throw "Config file not found: $ConfigPath"
}

$job = Start-Job -ScriptBlock {
    param($backendRoot, $configPath, $port)
    Set-Location $backendRoot
    $env:APP_CONFIG_PATH = $configPath
    & go run ./cmd/caserun-mcp -transport http -addr ":$port"
} -ArgumentList $BackendRoot, $ConfigPath, $Port

Start-Sleep -Seconds 8
try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/health" -UseBasicParsing -TimeoutSec 5
    if ($r.StatusCode -ne 200) { throw "health not 200" }
    Write-Host "MCP HTTP /health OK" -ForegroundColor Green
} finally {
    Stop-Job $job -ErrorAction SilentlyContinue
    Remove-Job $job -Force -ErrorAction SilentlyContinue
}
