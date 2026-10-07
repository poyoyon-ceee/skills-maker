# Regenerate skills-pack/MANIFEST.json from the pack contents.
# Usage: .\scripts\generate-manifest.ps1 [-PackName skills-pack] [-RepoRoot path]
# -RepoRoot defaults to the parent of this script's directory.

param(
    [string]$PackName = "skills-pack",
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
}
$packRoot = Join-Path $repoRoot $PackName
if (-not (Test-Path $packRoot)) { throw "Pack not found: $packRoot" }

$env:PYTHONPATH = $repoRoot

$skipTopLevel = @("_hooks", "_claude")

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

function Normalize-ManifestName {
    param([string]$Name)
    if ($Name -match '^[''"](.+)[''"]$') { return $Matches[1] }
    return $Name
}

function Get-ExistingInstallTargetsByName {
    param([string]$ManifestPath)
    $map = @{}
    if (-not (Test-Path $ManifestPath)) { return $map }
    $raw = Get-Content $ManifestPath -Raw -Encoding UTF8
    if ($raw.Length -gt 0 -and [int][char]$raw[0] -eq 0xFEFF) {
        $raw = $raw.Substring(1)
    }
    $existing = $raw | ConvertFrom-Json
    foreach ($e in $existing) {
        if (-not $e.installTargets) { continue }
        $key = Normalize-ManifestName $e.name
        $map[$key] = @($e.installTargets)
    }
    return $map
}

function Resolve-InstallTargets {
    param(
        [string]$Name,
        [hashtable]$ExistingByName
    )
    if ($ExistingByName.ContainsKey($Name)) {
        return ,@($ExistingByName[$Name])
    }
    $prevErr = $ErrorActionPreference
    $ErrorActionPreference = "Stop"
    try {
        $env:SKILL_NAME = $Name
        $json = python -c "import os; from scripts.incoming_lib import migration_targets; import json; print(json.dumps(migration_targets(os.environ['SKILL_NAME'])))"
        return ,@(($json | ConvertFrom-Json))
    } catch {
        Write-Host "incoming sync required; refusing to guess installTargets ($Name)" -ForegroundColor Red
        exit 1
    } finally {
        $ErrorActionPreference = $prevErr
        Remove-Item Env:SKILL_NAME -ErrorAction SilentlyContinue
    }
}

function Get-LegacyInstallTarget {
    param(
        [string[]]$Targets,
        [string]$Name
    )
    $env:SKILL_NAME = $Name
    $env:TARGETS_JSON = (ConvertTo-Json -InputObject @($Targets) -Compress)
    try {
        return python -c "import json, os; from scripts.incoming_lib import legacy_install_target; print(legacy_install_target(json.loads(os.environ['TARGETS_JSON']), os.environ['SKILL_NAME']))"
    } finally {
        Remove-Item Env:SKILL_NAME -ErrorAction SilentlyContinue
        Remove-Item Env:TARGETS_JSON -ErrorAction SilentlyContinue
    }
}

$manifestPath = Join-Path $packRoot "MANIFEST.json"
$existingByName = Get-ExistingInstallTargetsByName -ManifestPath $manifestPath

$entries = @()
Get-ChildItem -Path $packRoot -Directory |
    Where-Object { $skipTopLevel -notcontains $_.Name } |
    ForEach-Object {
        Get-ChildItem $_.FullName -Recurse -Filter "SKILL.md" -File | ForEach-Object {
            $name = Get-SkillName $_.FullName
            if (-not $name) { $name = $_.Directory.Name }
            $rel = $_.FullName.Substring($packRoot.Length).TrimStart('\', '/').Replace('\', '/')
            $installTargets = Resolve-InstallTargets -Name $name -ExistingByName $existingByName
            $installTarget = Get-LegacyInstallTarget -Targets $installTargets -Name $name
            $entries += [PSCustomObject][ordered]@{
                name           = $name
                path           = $rel
                installTargets = $installTargets
                installTarget  = $installTarget
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
$sorted | ConvertTo-Json -Depth 4 | Set-Content $manifestPath -Encoding UTF8

$agents = @($sorted | Where-Object { $_.installTargets -contains "agents" }).Count
$cursor = @($sorted | Where-Object { $_.installTargets -contains "cursor" }).Count
$claude = @($sorted | Where-Object { $_.installTargets -contains "claude" }).Count

Write-Host "Wrote $manifestPath"
Write-Host "  total:  $($sorted.Count)"
Write-Host "  agents: $agents"
Write-Host "  cursor: $cursor"
Write-Host "  claude: $claude"
