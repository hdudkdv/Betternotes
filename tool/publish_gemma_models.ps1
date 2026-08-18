# Downloads official Gemma LiteRT files (needs HF token + accepted license),
# then uploads them to Firebase Storage for every Notis install.
#
#   $env:HUGGINGFACE_TOKEN = "hf_..."
#   .\tool\publish_gemma_models.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root "tool\gemma_models"
$bucket = "notis-2dee0.firebasestorage.app"
$token = $env:HUGGINGFACE_TOKEN
if ([string]::IsNullOrWhiteSpace($token)) {
  throw "Set HUGGINGFACE_TOKEN first (do not put it in git)."
}

New-Item -ItemType Directory -Force -Path $out | Out-Null

$files = @(
  @{
    Name = "gemma3-270m-it-q8.litertlm"
    Url  = "https://huggingface.co/litert-community/gemma-3-270m-it/resolve/main/gemma3-270m-it-q8.litertlm"
  },
  @{
    Name = "Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm"
    Url  = "https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm"
  },
  @{
    Name = "gemma-3n-E2B-it-int4.litertlm"
    Url  = "https://huggingface.co/google/gemma-3n-E2B-it-litert-lm/resolve/main/gemma-3n-E2B-it-int4.litertlm"
  }
)

foreach ($file in $files) {
  $dest = Join-Path $out $file.Name
  if (-not (Test-Path $dest) -or (Get-Item $dest).Length -lt 1MB) {
    Write-Host "Downloading $($file.Name) ..."
    curl.exe -L --fail --retry 5 -H "Authorization: Bearer $token" -o $dest $file.Url
  } else {
    Write-Host "Already have $($file.Name)"
  }
  Write-Host "Uploading $($file.Name) to gs://$bucket/gemma/ ..."
  gsutil -m cp $dest "gs://$bucket/gemma/$($file.Name)"
}

Write-Host "Done. Deploy storage rules if you have not: firebase deploy --only storage"
