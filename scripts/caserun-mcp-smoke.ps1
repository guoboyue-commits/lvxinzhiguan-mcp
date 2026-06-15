param(
    [string]$ProjectRoot = "",
    [switch]$Http,
    [int]$Port = 8092
)

$ErrorActionPreference = "Stop"

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
