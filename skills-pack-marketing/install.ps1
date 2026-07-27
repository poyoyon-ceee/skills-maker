# Opt-in install: marketing skills + playbook-lp-creative → ~/.cursor/skills only.
# Does NOT install to ~/.agents or ~/.claude (avoids Cursor double-catalog noise).
# Run from: skills-maker/skills-pack-marketing/install.ps1

$ErrorActionPreference = "Stop"

$packageRoot = $PSScriptRoot
$skillsDst = Join-Path $env:USERPROFILE ".cursor\skills"
$skipTopLevel = @()

function Get-SkillName {
    param([string]$Path)
    $head = Get-Content $Path -TotalCount 15 -Encoding UTF8 -ErrorAction SilentlyContinue
    foreach ($line in $head) {
        if ($line -match '^name:\s*(.+)$') { return $Matches[1].Trim() }
    }
    return $null
}

New-Item -ItemType Directory -Force -Path $skillsDst | Out-Null

Write-Host "=== skills-pack-marketing install (Cursor only) ==="
Write-Host "Target: $skillsDst"
Write-Host "Policy: do NOT install to ~/.agents or ~/.claude"
Write-Host ""

$copied = 0
Get-ChildItem -Path $packageRoot -Directory | Where-Object { $skipTopLevel -notcontains $_.Name -and $_.Name -notmatch '^\.' } | ForEach-Object {
    $srcDir = $_.FullName
    Get-ChildItem $srcDir -Recurse -File | ForEach-Object {
        $relFromTop = $_.FullName.Substring($packageRoot.Length).TrimStart('\', '/')
        $destFile = Join-Path $skillsDst $relFromTop
        $destDir = Split-Path $destFile -Parent
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        $srcHash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        if ((Test-Path $destFile) -and ((Get-FileHash $destFile -Algorithm SHA256).Hash -eq $srcHash)) {
            return
        }
        Copy-Item $_.FullName -Destination $destFile -Force
        $copied++
    }
    Write-Host "Installed: $($_.Name)"
}

Write-Host ""
Write-Host "Files copied/updated: $copied"
Write-Host "Done. Restart Cursor. Use /playbook-lp-creative as the entry point."
Write-Host "Skills stay disable-model-invocation (manual) unless you change them later."
Write-Host "See INSTALL.md for policy."
