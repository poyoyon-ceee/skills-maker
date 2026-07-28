# Install global skills from skills-pack.
#
# Layout (single source of truth per skill, no duplicates):
#   ~/.agents/skills/<skill-name>/    all portable skills, flattened
#                                     (read by Cursor, Codex, ChatGPT tooling)
#   ~/.cursor/skills/<skill-name>/    Cursor-only skills that hardcode Cursor
#                                     paths/UI ($cursorOnlySkills below)
#   ~/.cursor/hooks/                  session hook (Cursor-specific format)
#
# Category folders (playbooks/, superpowers/, github/, debug/) exist for
# organisation inside this pack only; they are stripped on install because
# Codex is not confirmed to recurse into nested skill directories.
#
# Run from: skills-maker/skills-pack/install.ps1

$ErrorActionPreference = "Stop"

$packageRoot = $PSScriptRoot
$agentsDst = Join-Path $env:USERPROFILE ".agents\skills"
$cursorDst = Join-Path $env:USERPROFILE ".cursor\skills"
$hooksDst = Join-Path $env:USERPROFILE ".cursor\hooks"
$hooksConfig = Join-Path $env:USERPROFILE ".cursor\hooks.json"
$hooksSrc = Join-Path $packageRoot "_hooks"

$skipTopLevel = @("_hooks", "_claude")

# These hardcode ~/.cursor paths, Cursor PowerShell script locations or Cursor
# UI flows, so they stay out of the shared ~/.agents tree.
$cursorOnlySkills = @("chat-handoff", "skill-creator", "promote-skill")

function Get-SkillName {
    param([string]$Path)
    $head = Get-Content $Path -TotalCount 15 -Encoding UTF8 -ErrorAction SilentlyContinue
    foreach ($line in $head) {
        if ($line -match '^name:\s*(.+)$') { return $Matches[1].Trim() }
    }
    return $null
}

function Get-PackSkills {
    $skills = @()
    Get-ChildItem -Path $packageRoot -Directory |
        Where-Object { $skipTopLevel -notcontains $_.Name } |
        ForEach-Object {
            Get-ChildItem $_.FullName -Recurse -Filter "SKILL.md" -File | ForEach-Object {
                $dir = $_.Directory
                $frontmatterName = Get-SkillName $_.FullName
                $name = if ($frontmatterName) { $frontmatterName } else { $dir.Name }
                $skills += [PSCustomObject]@{
                    Name   = $name
                    Leaf   = $dir.Name
                    Source = $dir.FullName
                }
            }
        }
    return $skills
}

function Copy-SkillTree {
    param([string]$Source, [string]$Dest)
    New-Item -ItemType Directory -Force -Path $Dest | Out-Null
    $copied = 0
    Get-ChildItem $Source -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($Source.Length).TrimStart('\', '/')
        $destFile = Join-Path $Dest $rel
        $destFileDir = Split-Path $destFile -Parent
        New-Item -ItemType Directory -Force -Path $destFileDir | Out-Null
        if ((Test-Path $destFile) -and
            ((Get-FileHash $destFile -Algorithm SHA256).Hash -eq (Get-FileHash $_.FullName -Algorithm SHA256).Hash)) {
            return
        }
        Copy-Item $_.FullName -Destination $destFile -Force
        $script:filesWritten++
        $copied++
    }
    return $copied
}

$script:filesWritten = 0
$packSkills = Get-PackSkills

$dupeNames = $packSkills | Group-Object Name | Where-Object { $_.Count -gt 1 }
if ($dupeNames) {
    Write-Host "ERROR: duplicate skill names inside skills-pack:" -ForegroundColor Red
    $dupeNames | ForEach-Object {
        Write-Host "  $($_.Name):"
        $_.Group | ForEach-Object { Write-Host "    $($_.Source)" }
    }
    exit 1
}

Write-Host "=== skills-pack install ==="
Write-Host "Package skills: $($packSkills.Count)"
Write-Host "  -> ~/.agents/skills : $(($packSkills | Where-Object { $cursorOnlySkills -notcontains $_.Name }).Count)"
Write-Host "  -> ~/.cursor/skills : $(($packSkills | Where-Object { $cursorOnlySkills -contains $_.Name }).Count) (Cursor-only)"
Write-Host ""

foreach ($skill in ($packSkills | Sort-Object Name)) {
    $isCursorOnly = $cursorOnlySkills -contains $skill.Name
    $root = if ($isCursorOnly) { $cursorDst } else { $agentsDst }
    $dest = Join-Path $root $skill.Name

    $changed = Copy-SkillTree -Source $skill.Source -Dest $dest
    $tag = if ($isCursorOnly) { "cursor" } else { "agents" }
    if ($changed -gt 0) {
        Write-Host "Installed [$tag]: $($skill.Name) ($changed file(s))"
    }
}

Write-Host ""
Write-Host "=== Cleaning stale copies ==="

# A Cursor-only skill must not also live in ~/.agents, and a portable skill must
# not linger in ~/.cursor - either case makes the same name resolve twice.
$removedStale = 0
foreach ($name in $cursorOnlySkills) {
    $strayInAgents = Join-Path $agentsDst $name
    if (Test-Path $strayInAgents) {
        Remove-Item $strayInAgents -Recurse -Force
        $removedStale++
        Write-Host "Removed from agents (Cursor-only): $name"
    }
}

$backupRoot = Join-Path $env:USERPROFILE ".cursor\skills.bak"
if (Test-Path $cursorDst) {
    Get-ChildItem $cursorDst -Directory | ForEach-Object {
        $leaf = $_.Name
        if ($cursorOnlySkills -contains $leaf) { return }
        if (-not (Get-ChildItem $_.FullName -Recurse -Filter "SKILL.md" -File)) { return }

        New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
        $bakDest = Join-Path $backupRoot $leaf
        if (Test-Path $bakDest) { Remove-Item $bakDest -Recurse -Force }
        Move-Item $_.FullName $bakDest -Force
        $removedStale++
        Write-Host "Moved to skills.bak (now owned by ~/.agents): $leaf"
    }
}
if ($removedStale -eq 0) { Write-Host "(nothing stale)" }

if (-not (Test-Path $hooksSrc)) {
    Write-Error "Hooks source not found: $hooksSrc"
}

New-Item -ItemType Directory -Force -Path $hooksDst | Out-Null
Copy-Item (Join-Path $hooksSrc "session-start.ps1") -Destination $hooksDst -Force
Write-Host ""
Write-Host "Hook: session-start.ps1 -> $hooksDst"

if (Test-Path $hooksConfig) {
    $existing = Get-Content $hooksConfig -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $existing.hooks) {
        $existing | Add-Member -NotePropertyName hooks -NotePropertyValue ([PSCustomObject]@{})
    }
    if (-not $existing.hooks.sessionStart) {
        $existing.hooks | Add-Member -NotePropertyName sessionStart -NotePropertyValue @() -Force
    }
    $hasSessionStart = $false
    foreach ($hook in $existing.hooks.sessionStart) {
        if ($hook.command -eq "./hooks/session-start.ps1") {
            $hasSessionStart = $true
            break
        }
    }
    if (-not $hasSessionStart) {
        $existing.hooks.sessionStart = @(
            @{ command = "./hooks/session-start.ps1" }
        ) + @($existing.hooks.sessionStart)
    }
    if (-not $existing.version) {
        $existing | Add-Member -NotePropertyName version -NotePropertyValue 1 -Force
    }
    $existing | ConvertTo-Json -Depth 6 | Set-Content $hooksConfig -Encoding UTF8
}
else {
    @{
        version = 1
        hooks   = @{
            sessionStart = @(
                @{ command = "./hooks/session-start.ps1" }
            )
        }
    } | ConvertTo-Json -Depth 6 | Set-Content $hooksConfig -Encoding UTF8
}

function Get-InstalledNames {
    param([string]$Root)
    $names = @()
    if (-not (Test-Path $Root)) { return $names }
    Get-ChildItem $Root -Recurse -Filter "SKILL.md" -File | ForEach-Object {
        $n = Get-SkillName $_.FullName
        if ($n) { $names += $n }
    }
    return $names
}

$agentsNames = Get-InstalledNames $agentsDst
$cursorNames = Get-InstalledNames $cursorDst
$allNames = @($agentsNames) + @($cursorNames)
$dupesLeft = $allNames | Group-Object | Where-Object { $_.Count -gt 1 }

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Files written: $script:filesWritten"
Write-Host "~/.agents/skills: $($agentsNames.Count)"
Write-Host "~/.cursor/skills: $($cursorNames.Count)"
Write-Host "Total unique:     $(($allNames | Sort-Object -Unique).Count)"
if ($dupesLeft) {
    Write-Host "WARNING: duplicate names remain:" -ForegroundColor Yellow
    $dupesLeft | ForEach-Object { Write-Host "  $($_.Name): $($_.Count)" }
}
else {
    Write-Host "OK: no duplicate skill names."
}
Write-Host ""
Write-Host "Done. Restart Cursor, then check Customize -> Skills and Hooks."
Write-Host "See INSTALL.md in this folder for details."
