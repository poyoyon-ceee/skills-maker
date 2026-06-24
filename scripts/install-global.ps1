$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$src = Join-Path $repoRoot ".cursor\skills"
$dst = Join-Path $env:USERPROFILE ".cursor\skills"

if (-not (Test-Path $src)) {
    Write-Error "Skills source not found: $src"
}

New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item -Path (Join-Path $src "*") -Destination $dst -Recurse -Force

Write-Host "Installed skills from $src to $dst"
Write-Host "Restart Cursor if skills do not appear."
