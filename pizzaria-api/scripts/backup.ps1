param(
    [string]$DatabaseUrl = $env:DATABASE_URL,
    [string]$OutputDirectory = ".\backups"
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) { throw "DATABASE_URL is required" }

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$output = Join-Path $OutputDirectory "pizzaria-$timestamp.dump"
pg_dump $DatabaseUrl --format=custom --file=$output
Write-Output "Backup created: $output"
