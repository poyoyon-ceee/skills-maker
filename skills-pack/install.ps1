# Install global skills from skills-pack.
#
# Layout (single source of truth per skill, no duplicates):
#   ~/.agents/skills/<skill-name>/    skills whose installTargets contain agents
#   ~/.cursor/skills/<skill-name>/    skills whose installTargets contain cursor
#   ~/.cursor/hooks/                  session hook (Cursor-specific format)
#
# Destination roots default to the current user profile. -AgentsDest and
# -CursorDest override them. -SkipHooks leaves hooks.json and the hooks
# directory untouched; omit it to install hooks as before.
#
# Category folders (playbooks/, superpowers/, github/, debug/) exist for
# organisation inside this pack only; they are stripped on install because
# Codex is not confirmed to recurse into nested skill directories.
#
# Run from: skills-maker/skills-pack/install.ps1

param(
    [string]$AgentsDest = "",
    [string]$CursorDest = "",
    [switch]$SkipHooks
)

$ErrorActionPreference = "Stop"

$packageRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($AgentsDest)) {
    $agentsDst = Join-Path $env:USERPROFILE ".agents\skills"
}
else {
    $agentsDst = $AgentsDest
}
if ([string]::IsNullOrWhiteSpace($CursorDest)) {
    $cursorDst = Join-Path $env:USERPROFILE ".cursor\skills"
}
else {
    $cursorDst = $CursorDest
}
$hooksDst = Join-Path $env:USERPROFILE ".cursor\hooks"
$hooksConfig = Join-Path $env:USERPROFILE ".cursor\hooks.json"
$hooksSrc = Join-Path $packageRoot "_hooks"

$skipTopLevel = @("_hooks", "_claude")

function Get-SkillName {
    param([string]$Path)
    $head = Get-Content $Path -TotalCount 15 -Encoding UTF8 -ErrorAction SilentlyContinue
    foreach ($line in $head) {
        if ($line -match '^name:\s*(.+)$') {
            $raw = $Matches[1].Trim()
            # Quoted YAML (name: "00") must install as folder 00, not "00".
            if ($raw -match '^[''"](.+)[''"]$') { return $Matches[1] }
            return $raw
        }
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

function Read-InstallTargetMap {
    param([string]$ManifestPath)
    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        Write-Host "ERROR: MANIFEST.json not found: $ManifestPath" -ForegroundColor Red
        exit 1
    }
    # Do not wrap ConvertFrom-Json in @(). Windows PowerShell passes the JSON
    # array as one pipeline object, and @() then nests it instead of enumerating.
    $rows = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $map = @{}
    foreach ($row in $rows) {
        $name = [string]$row.name
        $prop = $row.PSObject.Properties["installTargets"]
        $targets = @()
        if ($null -ne $prop -and $null -ne $prop.Value) {
            $targets = @($prop.Value | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
        }
        if ($targets.Count -eq 0) {
            Write-Host "ERROR: installTargets missing for '$name'" -ForegroundColor Red
            exit 1
        }
        if (($targets -contains "agents") -and ($targets -contains "cursor")) {
            Write-Host "ERROR: installTargets cannot contain both agents and cursor: $name" -ForegroundColor Red
            exit 1
        }
        if ($map.ContainsKey($name)) {
            Write-Host "ERROR: duplicate manifest name '$name'" -ForegroundColor Red
            exit 1
        }
        $map[$name] = @($targets)
    }
    return ,$map
}

$script:filesWritten = 0
$packSkills = Get-PackSkills
$targetMap = Read-InstallTargetMap (Join-Path $packageRoot "MANIFEST.json")

$dupeNames = $packSkills | Group-Object Name | Where-Object { $_.Count -gt 1 }
if ($dupeNames) {
    Write-Host "ERROR: duplicate skill names inside skills-pack:" -ForegroundColor Red
    $dupeNames | ForEach-Object {
        Write-Host "  $($_.Name):"
        $_.Group | ForEach-Object { Write-Host "    $($_.Source)" }
    }
    exit 1
}

foreach ($skill in $packSkills) {
    if (-not $targetMap.ContainsKey($skill.Name)) {
        Write-Host "ERROR: no MANIFEST installTargets for skill '$($skill.Name)'" -ForegroundColor Red
        exit 1
    }
}

$agentsCount = @($packSkills | Where-Object { @($targetMap[$_.Name]) -contains "agents" }).Count
$cursorCount = @($packSkills | Where-Object { @($targetMap[$_.Name]) -contains "cursor" }).Count

Write-Host "=== skills-pack install ==="
Write-Host "Package skills: $($packSkills.Count)"
Write-Host "  -> $agentsDst : $agentsCount"
Write-Host "  -> $cursorDst : $cursorCount"
Write-Host ""

foreach ($skill in ($packSkills | Sort-Object Name)) {
    $targets = @($targetMap[$skill.Name])
    if ($targets -contains "agents") {
        $root = $agentsDst
        $tag = "agents"
    }
    elseif ($targets -contains "cursor") {
        $root = $cursorDst
        $tag = "cursor"
    }
    else {
        continue
    }
    $dest = Join-Path $root $skill.Name

    $changed = Copy-SkillTree -Source $skill.Source -Dest $dest
    if ($changed -gt 0) {
        Write-Host "Installed [$tag]: $($skill.Name) ($changed file(s))"
    }
}

Write-Host ""
Write-Host "=== Cleaning stale copies ==="

# A cursor-targeted skill must not also live in the agents dest, and an
# agents-targeted skill must not linger in the cursor dest.
$removedStale = 0
$cursorKeep = @{}
foreach ($name in @($targetMap.Keys)) {
    $targets = @($targetMap[$name])
    if ($targets -contains "cursor") { $cursorKeep[$name] = $true }
    if (($targets -contains "cursor") -and -not ($targets -contains "agents")) {
        $strayInAgents = Join-Path $agentsDst $name
        if (Test-Path $strayInAgents) {
            Remove-Item $strayInAgents -Recurse -Force
            $removedStale++
            Write-Host "Removed from agents (cursor target): $name"
        }
    }
}

$backupRoot = Join-Path (Split-Path -Parent $cursorDst) "skills.bak"
if (Test-Path $cursorDst) {
    Get-ChildItem $cursorDst -Directory | ForEach-Object {
        $leaf = $_.Name
        if ($cursorKeep.ContainsKey($leaf)) { return }
        if (-not (Get-ChildItem $_.FullName -Recurse -Filter "SKILL.md" -File)) { return }

        New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
        $bakDest = Join-Path $backupRoot $leaf
        if (Test-Path $bakDest) { Remove-Item $bakDest -Recurse -Force }
        Move-Item $_.FullName $bakDest -Force
        $removedStale++
        Write-Host "Moved to skills.bak (now owned by agents dest): $leaf"
    }
}
if ($removedStale -eq 0) { Write-Host "(nothing stale)" }

if ($SkipHooks) {
    Write-Host ""
    Write-Host "Hooks skipped (-SkipHooks)."
}
else {
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
