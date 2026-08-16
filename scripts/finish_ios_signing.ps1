# After Apple issues the .cer and you download the App Store profile:
#   1) Save the certificate as build/signing/ios_distribution.cer
#   2) Save the profile as build/signing/Notis_AppStore.mobileprovision
#   3) Run: powershell -File scripts/finish_ios_signing.ps1

$ErrorActionPreference = "Stop"
$openssl = "C:\Program Files\Git\usr\bin\openssl.exe"
$dir = Join-Path (Split-Path $PSScriptRoot -Parent) "build\signing"
$key = Join-Path $dir "ios_distribution.key"
$cer = Join-Path $dir "ios_distribution.cer"
$pem = Join-Path $dir "ios_distribution.pem"
$p12 = Join-Path $dir "ios_distribution.p12"
$profile = Get-ChildItem $dir -Filter "*.mobileprovision" | Select-Object -First 1

if (-not (Test-Path $key)) { throw "Missing $key" }
if (-not (Test-Path $cer)) { throw "Put the downloaded certificate at $cer" }
if (-not $profile) { throw "Put the App Store .mobileprovision in $dir" }

$password = -join ((48..57 + 65..90 + 97..122) | Get-Random -Count 20 | ForEach-Object { [char]$_ })
& $openssl x509 -inform DER -in $cer -out $pem
if ($LASTEXITCODE -ne 0) {
  & $openssl x509 -inform PEM -in $cer -out $pem
}
& $openssl pkcs12 -export -inkey $key -in $pem -out $p12 -passout "pass:$password" -legacy
if ($LASTEXITCODE -ne 0) {
  & $openssl pkcs12 -export -inkey $key -in $pem -out $p12 -passout "pass:$password"
}

$certB64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($p12))
$profileB64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($profile.FullName))
$certB64 | gh secret set BUILD_CERTIFICATE_BASE64
$profileB64 | gh secret set BUILD_PROVISION_PROFILE_BASE64
$password | gh secret set P12_PASSWORD
Write-Host "GitHub secrets updated. Re-run Deploy iOS App Store."
