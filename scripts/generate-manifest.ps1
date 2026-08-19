# Regenerate skills-pack/MANIFEST.json from the pack contents.
# Usage: .\scripts\generate-manifest.ps1 [-PackName skills-pack]

param(
    [string]$PackName = "skills-pack"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$packRoot = Join-Path $repoRoot $PackName
if (-not (Test-Path $packRoot)) { throw "Pack not found: $packRoot" }

$skipTopLevel = @("_hooks", "_claude")
$cursorOnlySkills = @("chat-handoff", "skill-creator", "promote-skill")

function Get-SkillName {
    param([string]$Path)
    $head = Get-Content $Path -TotalCount 15 -Encoding UTF8 -ErrorAction SilentlyContinue
    foreach ($line in $head) {
        if ($line -match '^name:\s*(.+)$') {
            $raw = $Matches[1].Trim()
            if ($raw -match '^[''"](.+)[''"]$') { return $Matches[1] }
            return $raw
        }
    }
    return $null
}

$entries = @()
Get-ChildItem -Path $packRoot -Directory |
    Where-Object { $skipTopLevel -notcontains $_.Name } |
    ForEach-Object {
        Get-ChildItem $_.FullName -Recurse -Filter "SKILL.md" -File | ForEach-Object {
            $name = Get-SkillName $_.FullName
            if (-not $name) { $name = $_.Directory.Name }
            $rel = $_.FullName.Substring($packRoot.Length).TrimStart('\', '/').Replace('\', '/')
            $target = if ($cursorOnlySkills -contains $name) { "~/.cursor/skills" } else { "~/.agents/skills" }
            $entries += [PSCustomObject][ordered]@{
                name          = $name
                path          = $rel
                installTarget = "$target/$name/"
            }
        }
    }

$dupes = $entries | Group-Object name | Where-Object { $_.Count -gt 1 }
if ($dupes) {
    Write-Host "ERROR: duplicate skill names in pack:" -ForegroundColor Red
    $dupes | ForEach-Object {
        Write-Host "  $($_.Name)"
        $_.Group | ForEach-Object { Write-Host "    $($_.path)" }
    }
    exit 1
}

$sorted = $entries | Sort-Object name
$manifestPath = Join-Path $packRoot "MANIFEST.json"
$sorted | ConvertTo-Json -Depth 4 | Set-Content $manifestPath -Encoding UTF8

$agents = @($sorted | Where-Object { $_.installTarget -like "*/.agents/*" }).Count
$cursor = @($sorted | Where-Object { $_.installTarget -like "*/.cursor/*" }).Count

Write-Host "Wrote $manifestPath"
Write-Host "  total:  $($sorted.Count)"
Write-Host "  agents: $agents"
Write-Host "  cursor: $cursor"
