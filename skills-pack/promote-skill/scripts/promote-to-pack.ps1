# Promote ONE installed skill into a verified skills-maker pack.
# Looks in ~/.agents/skills, then ~/.cursor/skills, then ~/.claude/skills.
# NEVER creates skills-maker root. NEVER writes if validation fails.
#
# Usage:
#   .\promote-to-pack.ps1 -SkillFolderName "my-skill" -SkillsMakerRoot "C:\Dev-App\skills-maker"
#   .\promote-to-pack.ps1 -SkillFolderName "my-skill" -SkillsMakerRoot "..." -PackName "skills-pack-marketing"

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SkillFolderName,

    [Parameter(Mandatory = $true)]
    [string]$SkillsMakerRoot,

    [ValidateSet("skills-pack", "skills-pack-marketing")]
    [string]$PackName = "skills-pack",

    [switch]$Force
)

$ErrorActionPreference = "Stop"

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
$cursorOnlySkills = @("chat-handoff", "skill-creator", "promote-skill")
$manifest = @()
Get-ChildItem $packRoot -Recurse -Filter "SKILL.md" -File | ForEach-Object {
    $head = Get-Content $_.FullName -TotalCount 15 -Encoding UTF8
    $name = $null
    foreach ($line in $head) {
        if ($line -match '^name:\s*(.+)$') { $name = $Matches[1].Trim(); break }
    }
    if (-not $name) { return }
    $rel = $_.FullName.Substring($packRoot.Length).TrimStart('\', '/').Replace('\', '/')
    # skip installer-only / non-skill trees if any
    if ($rel -match '^(_hooks|_claude)/') { return }
    $target = if ($cursorOnlySkills -contains $name) { "~/.cursor/skills" } else { "~/.agents/skills" }
    $manifest += [PSCustomObject][ordered]@{
        name          = $name
        path          = $rel
        installTarget = "$target/$name/"
    }
}

$manifestPath = Join-Path $packRoot "MANIFEST.json"
$manifest | Sort-Object name | ConvertTo-Json -Depth 4 | Set-Content $manifestPath -Encoding UTF8

Write-Host ""
Write-Host "OK. Copied skill and refreshed MANIFEST ($($manifest.Count) entries)."
Write-Host "Manifest: $manifestPath"
Write-Host "Commit separately if desired — this script does not commit."
