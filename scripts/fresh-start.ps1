# Fresh local dev: wipe DB, run migrations, start stack - NO demo flight seed.
# Book tickets on the web app first; Flutter stays empty until you log in with that account.
#
# Usage (from repo root):
#   .\scripts\fresh-start.ps1
#   .\scripts\fresh-start.ps1 -SkipWeb
#   .\scripts\fresh-start.ps1 -FlutterDevice windows
#   .\scripts\fresh-start.ps1 -ClearUploads

param(
    [switch]$SkipWeb,
    [switch]$SkipFlutter,
    [switch]$ClearUploads,
    [string]$FlutterDevice = "chrome"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

Write-Host ""
Write-Host "=== Mosafer fresh start (empty trips, no demo seed) ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/4] Stopping Docker and removing database volumes..." -ForegroundColor Yellow
docker compose down -v
if ($LASTEXITCODE -ne 0) {
    throw "docker compose down failed"
}

if ($ClearUploads) {
    Write-Host "[1b] Clearing local upload artifacts..." -ForegroundColor Yellow
    @("uploads\ticket_qr", "uploads\ticket_attachments", "uploads\passport_images") | ForEach-Object {
        $path = Join-Path $Root $_
        if (Test-Path $path) {
            Get-ChildItem $path -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "[2/4] Building and starting API + DB + Redis (migrations run once)..." -ForegroundColor Yellow
docker compose up -d --build
if ($LASTEXITCODE -ne 0) {
    throw "docker compose up failed"
}

Write-Host "[3/4] Waiting for API health..." -ForegroundColor Yellow
$healthy = $false
for ($i = 0; $i -lt 90; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8001/api/v1/health" -UseBasicParsing -TimeoutSec 3
        if ($response.StatusCode -eq 200) {
            $healthy = $true
            break
        }
    }
    catch {
        # API still starting
    }
    Start-Sleep -Seconds 2
}
if (-not $healthy) {
    throw "API did not become healthy on http://localhost:8001. Check: docker logs mosafer_api_dev"
}

Write-Host ""
Write-Host "Database is fresh. Demo Istanbul trips were NOT seeded." -ForegroundColor Green
Write-Host '  API:  http://localhost:8001/docs' -ForegroundColor Gray
Write-Host '  Web:  http://localhost:3000/en - register, search, buy a ticket' -ForegroundColor Gray
Write-Host '  Flutter: empty My Trips until you log in with the same web account.' -ForegroundColor Gray
Write-Host ""
Write-Host "Do NOT run scripts/seed_istanbul_review.py if you want zero preloaded flights." -ForegroundColor DarkYellow
Write-Host ""

if (-not $SkipWeb) {
    Write-Host "[4a] Starting Next.js web app in a new window..." -ForegroundColor Yellow
    $webDir = Join-Path $Root "web"
    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "Set-Location '$webDir'; if (-not (Test-Path node_modules)) { npm install }; npm run dev"
    ) | Out-Null
}
else {
    Write-Host "[4a] Skipped web (-SkipWeb)" -ForegroundColor DarkGray
}

if (-not $SkipFlutter) {
    Write-Host ("Step 4b: Launching Flutter on {0}..." -f $FlutterDevice) -ForegroundColor Yellow
    $flutterDir = Join-Path $Root "Flutter\app"
    Set-Location $flutterDir
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw "flutter pub get failed"
    }
    flutter run -d $FlutterDevice --dart-define=API_BASE_URL=http://localhost:8001/api/v1
}
else {
    Write-Host "Step 4b: Skipped Flutter (-SkipFlutter)" -ForegroundColor DarkGray
    Write-Host '  Manual: cd Flutter/app; flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8001/api/v1' -ForegroundColor Gray
}
