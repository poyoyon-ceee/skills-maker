# Sync installed global skills back into skills-pack and regenerate MANIFEST.json.
#
# Reads from both global roots (see install.ps1 for the layout):
#   ~/.agents/skills/<name>/   portable skills
#   ~/.cursor/skills/<name>/   Cursor-only skills
#
# Skills are matched to their existing pack folder by frontmatter name, so the
# pack keeps its category folders (playbooks/, superpowers/, ...) even though
# the installed layout is flat. A skill that has no pack folder is reported and
# skipped - add it with /promote-skill so the category is chosen deliberately.
#
# Run from repo root: .\scripts\sync-skills-pack.ps1 [-WhatIf]

param(
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$packRoot = Join-Path $repoRoot "skills-pack"
$globalRoots = @(
    (Join-Path $env:USERPROFILE ".agents\skills"),
    (Join-Path $env:USERPROFILE ".cursor\skills")
)
$skipTopLevel = @("_hooks", "_claude")
# Generated at runtime, never part of the pack.
$excludeDirs = @("__pycache__", ".pytest_cache", "node_modules")

function Get-SkillName {
    param([string]$Path)
    $head = Get-Content $Path -TotalCount 15 -Encoding UTF8 -ErrorAction SilentlyContinue
    foreach ($line in $head) {
        if ($line -match '^name:\s*(.+)$') { return $Matches[1].Trim() }
    }
    return $null
}

$packDirs = @{}
Get-ChildItem -Path $packRoot -Directory |
    Where-Object { $skipTopLevel -notcontains $_.Name } |
    ForEach-Object {
        Get-ChildItem $_.FullName -Recurse -Filter "SKILL.md" -File | ForEach-Object {
            $name = Get-SkillName $_.FullName
            if (-not $name) { $name = $_.Directory.Name }
            $packDirs[$name] = $_.Directory.FullName
        }
    }

$synced = 0
$unchanged = 0
$unknown = @()

foreach ($root in $globalRoots) {
    if (-not (Test-Path $root)) { continue }

    Get-ChildItem $root -Directory | ForEach-Object {
        $skillMd = Join-Path $_.FullName "SKILL.md"
        if (-not (Test-Path $skillMd)) { return }

        $name = Get-SkillName $skillMd
        if (-not $name) { $name = $_.Name }

        if (-not $packDirs.ContainsKey($name)) {
            $unknown += "$name ($($_.FullName))"
            return
        }

        $target = $packDirs[$name]
        $robocopyArgs = @($_.FullName, $target, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS", "/NP")
        foreach ($ex in $excludeDirs) { $robocopyArgs += @("/XD", $ex) }

        if ($WhatIf) {
            $robocopyArgs += "/L"
        }

        robocopy @robocopyArgs | Out-Null
        $exit = $LASTEXITCODE
        if ($exit -ge 8) {
            Write-Error "Failed copying $name (robocopy exit $exit)"
        }
        if ($exit -eq 0) {
            $unchanged++
        }
        else {
            $synced++
            Write-Host "Synced: $name -> $($target.Substring($packRoot.Length).TrimStart('\'))"
        }
    }
}

Write-Host ""
Write-Host "Synced: $synced, unchanged: $unchanged"

if ($unknown.Count -gt 0) {
    Write-Host ""
    Write-Host "Not in pack (skipped - use /promote-skill to add):" -ForegroundColor Yellow
    $unknown | Sort-Object | ForEach-Object { Write-Host "  $_" }
}

if ($WhatIf) {
    Write-Host ""
    Write-Host "(WhatIf: no files were written, MANIFEST not regenerated)"
    return
}

& (Join-Path $PSScriptRoot "generate-manifest.ps1")
