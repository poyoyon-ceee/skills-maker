# Sync this PC's ~/.cursor/skills into skills-pack and regenerate MANIFEST.json
# Run from repo root: .\scripts\sync-skills-pack.ps1

$ErrorActionPreference = "Stop"

$src = Join-Path $env:USERPROFILE ".cursor\skills"
$dst = Join-Path (Split-Path $PSScriptRoot -Parent) "skills-pack"

if (-not (Test-Path $src)) {
    Write-Error "Global skills not found: $src"
}

Write-Host "Syncing $src -> $dst"

Get-ChildItem $src -Directory | ForEach-Object {
    $target = Join-Path $dst $_.Name
    robocopy $_.FullName $target /MIR /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) {
        Write-Error "Failed copying $($_.Name) (robocopy exit $LASTEXITCODE)"
    }
    Write-Host "Synced: $($_.Name)"
}

$manifest = @()
Get-ChildItem $dst -Recurse -Filter "SKILL.md" -File | ForEach-Object {
    $head = Get-Content $_.FullName -TotalCount 15 -Encoding UTF8
    $name = $null
    foreach ($line in $head) {
        if ($line -match '^name:\s*(.+)$') { $name = $Matches[1].Trim(); break }
    }
    if (-not $name) { return }
    $rel = $_.FullName.Substring($dst.Length).TrimStart('\', '/').Replace('\', '/')
    $manifest += [PSCustomObject]@{ name = $name; path = $rel }
}

$manifestPath = Join-Path $dst "MANIFEST.json"
$manifest | Sort-Object name | ConvertTo-Json -Depth 3 | Set-Content $manifestPath -Encoding UTF8

Write-Host ""
Write-Host "Done. Skills in pack: $($manifest.Count)"
Write-Host "Manifest: $manifestPath"
