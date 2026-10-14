param(
    [string]$ComposeFile = "docker-compose.production.yml"
)

$ErrorActionPreference = "Stop"

Write-Output "Validating production compose..."
docker compose -f $ComposeFile config --quiet

Write-Output "Building application image..."
docker compose -f $ComposeFile build api migrate

Write-Output "Run the database backup before continuing."
$confirmation = Read-Host "Type BACKUP_READY after completing the backup"
if ($confirmation -ne "BACKUP_READY") { throw "Deployment cancelled: backup confirmation missing" }

Write-Output "Applying controlled migrations and starting services..."
docker compose -f $ComposeFile up -d db
docker compose -f $ComposeFile run --rm migrate
docker compose -f $ComposeFile up -d api https
docker compose -f $ComposeFile ps
