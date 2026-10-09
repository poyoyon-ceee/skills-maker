# Promote ONE installed skill into a verified skills-maker pack.
# Looks in ~/.agents/skills, then ~/.cursor/skills, then ~/.claude/skills.
# NEVER creates skills-maker root. NEVER writes if validation fails.
#
# 登録経路ではない。新規・更新は incoming 4箱と scripts/sync-incoming.ps1。
# このスクリプトは global から pack への直コピーなので、通常はここで止める。
# どうしても直コピーするときだけ -AllowDirectCopy。
#
# Usage:
#   .\promote-to-pack.ps1 -SkillFolderName "my-skill" -SkillsMakerRoot "<skills-maker リポジトリ>" -AllowDirectCopy
#   .\promote-to-pack.ps1 -SkillFolderName "my-skill" -SkillsMakerRoot "..." -PackName "skills-pack-marketing" -AllowDirectCopy

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SkillFolderName,

    [Parameter(Mandatory = $true)]
    [string]$SkillsMakerRoot,

    [ValidateSet("skills-pack", "skills-pack-marketing")]
    [string]$PackName = "skills-pack",

    [switch]$Force,

    [switch]$AllowDirectCopy
)

$ErrorActionPreference = "Stop"

if (-not $AllowDirectCopy) {
    Write-Host "ERROR: promote-to-pack は登録経路ではない。incoming の4箱に置いて scripts/sync-incoming.ps1 を使え。直コピーが必要なときだけ -AllowDirectCopy を付ける。" -ForegroundColor Red
    exit 1
}

function Test-SkillsMakerRoot {
    param([string]$Root, [string]$ExpectedPack)
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return @{ Ok = $false; Reason = "Root directory does not exist: $Root" }
    }
    $pack = Join-Path $Root $ExpectedPack
    if (-not (Test-Path -LiteralPath $pack -PathType Container)) {
        return @{ Ok = $false; Reason = "Pack directory missing (will not create): $pack" }
    }
    $markers = @("install.ps1", "install.sh", "MANIFEST.json", "引き継ぎ.md", "INSTALL.md")
    $found = $false
    foreach ($m in $markers) {
        if (Test-Path -LiteralPath (Join-Path $pack $m)) { $found = $true; break }
    }
    if (-not $found) {
        return @{
            Ok     = $false
            Reason = "Pack exists but has no install/MANIFEST/引き継ぎ markers — refusing to treat as skills-maker: $pack"
        }
    }
    return @{ Ok = $true; Reason = "ok"; Pack = $pack }
}

# Normalize skill folder name (no path traversal)
if ($SkillFolderName -match '[\\/]' -or $SkillFolderName -eq '.' -or $SkillFolderName -eq '..') {
    Write-Error "SkillFolderName must be a single folder name, not a path: $SkillFolderName"
}

$globalRoots = @(
    (Join-Path $env:USERPROFILE ".agents\skills"),
    (Join-Path $env:USERPROFILE ".cursor\skills"),
    (Join-Path $env:USERPROFILE ".claude\skills")
)
$src = $null
foreach ($root in $globalRoots) {
    $candidate = Join-Path $root $SkillFolderName
    if (Test-Path -LiteralPath $candidate -PathType Container) { $src = $candidate; break }
}
if (-not $src) {
    Write-Error "Global skill not found in ~/.agents/skills, ~/.cursor/skills, or ~/.claude/skills (run Gate 1 first): $SkillFolderName"
}
$skillMd = Join-Path $src "SKILL.md"
if (-not (Test-Path -LiteralPath $skillMd -PathType Leaf)) {
    Write-Error "SKILL.md missing in source: $skillMd"
}

$check = Test-SkillsMakerRoot -Root $SkillsMakerRoot -ExpectedPack $PackName
if (-not $check.Ok) {
    Write-Error "Refusing to write. $($check.Reason)"
}

$packRoot = $check.Pack
$dst = Join-Path $packRoot $SkillFolderName

if ((Test-Path -LiteralPath $dst) -and -not $Force) {
    Write-Error "Destination already exists (pass -Force to overwrite): $dst"
}

Write-Host "Source:      $src"
Write-Host "Destination: $dst"
Write-Host "Pack:        $PackName"

New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
if (Test-Path -LiteralPath $dst) {
    Remove-Item -LiteralPath $dst -Recurse -Force
}
Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force

# Regenerate MANIFEST.json for this pack only
# Keep this in sync with scripts/generate-manifest.ps1
$env:PYTHONPATH = $SkillsMakerRoot

function Get-SkillNameFromMd {
    param([string]$Path)
    $head = Get-Content $Path -TotalCount 15 -Encoding UTF8 -ErrorAction SilentlyContinue
    foreach ($line in $head) {
        if ($line -match '^name:\s*(.+)$') {
            $raw = $Matches[1].Trim()
            $quote = $raw[0]
            if ($raw.Length -ge 2 -and ($quote -eq [char]34 -or $quote -eq [char]39) -and $raw[$raw.Length - 1] -eq $quote) {
                return $raw.Substring(1, $raw.Length - 2)
            }
            return $raw
        }
    }
    return $null
}

function Normalize-ManifestName {
    param([string]$Name)
    if ([string]::IsNullOrEmpty($Name)) { return $Name }
    $quote = $Name[0]
    if ($Name.Length -ge 2 -and ($quote -eq [char]34 -or $quote -eq [char]39) -and $Name[$Name.Length - 1] -eq $quote) {
        return $Name.Substring(1, $Name.Length - 2)
    }
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
        Write-Host "incoming sync required; refusing to guess installTargets" -ForegroundColor Red
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

$manifest = @()
Get-ChildItem $packRoot -Recurse -Filter "SKILL.md" -File | ForEach-Object {
    $name = Get-SkillNameFromMd $_.FullName
    if (-not $name) { return }
    $rel = $_.FullName.Substring($packRoot.Length).TrimStart('\', '/').Replace('\', '/')
    if ($rel -match '^(_hooks|_claude)/') { return }
    $installTargets = Resolve-InstallTargets -Name $name -ExistingByName $existingByName
    $installTarget = Get-LegacyInstallTarget -Targets $installTargets -Name $name
    $manifest += [PSCustomObject][ordered]@{
        name           = $name
        path           = $rel
        installTargets = $installTargets
        installTarget  = $installTarget
    }
}

$manifest | Sort-Object name | ConvertTo-Json -Depth 4 | Set-Content $manifestPath -Encoding UTF8

Write-Host ""
Write-Host "OK. Copied skill and refreshed MANIFEST ($($manifest.Count) entries)."
Write-Host "Manifest: $manifestPath"
Write-Host "Commit separately if desired — this script does not commit."
