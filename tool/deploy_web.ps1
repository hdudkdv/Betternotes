# Builds the Flutter web app and uploads it to both Firebase Hosting sites:
#   https://notis-notizbuecher.web.app
#   https://notis-2dee0.web.app  (also notis-2dee0.firebaseapp.com)
#
# Run from anywhere:
#   powershell -File tool/deploy_web.ps1
#
# Uses the local Firebase CLI login — no GitHub Action.

$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '..'))

function Assert-Command([string]$Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Missing command '$Name'. Install it and retry."
  }
}

Assert-Command flutter

Write-Host '>> flutter pub get'
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed ($LASTEXITCODE)" }

Write-Host '>> flutter build web --release --base-href /app/'
flutter build web --release --base-href /app/
if ($LASTEXITCODE -ne 0) { throw "flutter build web failed ($LASTEXITCODE)" }

Write-Host '>> copy build/web -> hosting/app'
if (Test-Path 'hosting/app') {
  Remove-Item -Recurse -Force 'hosting/app'
}
New-Item -ItemType Directory -Path 'hosting/app' | Out-Null
Copy-Item -Path 'build/web/*' -Destination 'hosting/app' -Recurse -Force

$firebaseArgs = @(
  'deploy',
  '--only', 'hosting:notis-notizbuecher,hosting:notis-2dee0',
  '--project', 'notis-2dee0',
  '--non-interactive'
)

if (Get-Command firebase -ErrorAction SilentlyContinue) {
  Write-Host '>> firebase deploy (both hosting sites)'
  & firebase @firebaseArgs
} else {
  Write-Host '>> npx firebase-tools deploy (both hosting sites)'
  Assert-Command npx
  & npx --yes firebase-tools@13 @firebaseArgs
}
if ($LASTEXITCODE -ne 0) { throw "firebase deploy failed ($LASTEXITCODE)" }

Write-Host ''
Write-Host 'Live:'
Write-Host '  https://notis-notizbuecher.web.app/app/'
Write-Host '  https://notis-2dee0.web.app/app/'
Write-Host '  https://notis-2dee0.firebaseapp.com/app/'
