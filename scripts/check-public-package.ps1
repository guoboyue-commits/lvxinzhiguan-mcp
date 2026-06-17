$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$files = Get-ChildItem -Path $root -Recurse -File

$blockedNames = @(
    "config.yaml",
    "lvxinzhiguan.sql",
    "apiclient_key.pem",
    "apiclient_cert.pem",
    "auth.json"
)

$blockedExtensions = @(".pem", ".p12", ".pfx", ".key")
$blockedPatterns = @(
    "sk-[A-Za-z0-9_-]{16,}",
    "Bearer\s+[A-Za-z0-9._~+/=-]{16,}",
    "JWT_SECRET\s*=",
    "DB_PASS\s*="
)

$blockedPatterns += ("pass" + "word:\s*['""]?[^'""\r\n]+")

$violations = New-Object System.Collections.Generic.List[string]

foreach ($file in $files) {
    if ($blockedNames -contains $file.Name) {
        $violations.Add("Blocked file name: $($file.FullName)")
    }
    if ($blockedExtensions -contains $file.Extension.ToLowerInvariant()) {
        $violations.Add("Blocked secret-like extension: $($file.FullName)")
    }
    $text = ""
    try {
        $text = Get-Content -Raw -Path $file.FullName -Encoding UTF8
    } catch {
        continue
    }
    foreach ($pattern in $blockedPatterns) {
        if ($text -match $pattern) {
            $violations.Add("Blocked content pattern '$pattern' in $($file.FullName)")
        }
    }
    foreach ($line in ($text -split "`r?`n")) {
        if ($line -match '^\s*(?:\$env:)?CASERUN_MCP_TOKEN\s*=\s*(.+)$') {
            $value = $matches[1].Trim().Trim('"').Trim("'")
            $isPlaceholder = $value.StartsWith("<") -or $value.StartsWith("replace-with")
            if (-not $isPlaceholder) {
                $violations.Add("Blocked CASERUN_MCP_TOKEN value in $($file.FullName)")
            }
        }
    }
}

if ($violations.Count -gt 0) {
    $violations | ForEach-Object { Write-Error $_ }
    exit 1
}

[pscustomobject]@{
    overall = "pass"
    files_checked = $files.Count
    package_root = $root
} | ConvertTo-Json
