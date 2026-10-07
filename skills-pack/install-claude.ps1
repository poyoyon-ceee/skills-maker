# Install global Claude Code skills from skills-pack.
# Skills are flattened directly under ~/.claude/skills/<skill-name>/SKILL.md
# — category folders (playbooks/, superpowers/, github/, debug/) are stripped.
# Marketing skills live in skills-pack-marketing/ and are not installed here.
#
# ~/.agents/skills is NOT written here: install.ps1 owns that tree.
#
# Which skills are copied is MANIFEST.json installTargets: only entries that
# contain claude are installed. Names without claude are removed from the
# destination if they are already there.
#
# _claude/ holds Claude-specific overrides: after the base copy, any file in
# _claude/<skill-name>/ overwrites the installed skill (fixes Cursor-specific
# paths/instructions for the Claude Code environment).
#
# -ClaudeDest overrides the skills directory. Without it, the destination is
# %USERPROFILE%\.claude\skills and the Superpowers plugin is disabled in
# settings.json (pack is canonical). An explicit -ClaudeDest leaves
# settings.json alone.
#
# Run from: skills-maker/skills-pack/install-claude.ps1

param(
    [string]$ClaudeDest = ""
)

$ErrorActionPreference = "Stop"

$packageRoot = $PSScriptRoot
$overlayRoot = Join-Path $packageRoot "_claude"
$useDefaultClaudeDest = [string]::IsNullOrWhiteSpace($ClaudeDest)
if ($useDefaultClaudeDest) {
    $destRoots = @(
        (Join-Path $env:USERPROFILE ".claude\skills")
    )
}
else {
    $destRoots = @($ClaudeDest)
}

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

function Install-ToRoot {
    param([string]$skillsDst)

    New-Item -ItemType Directory -Force -Path $skillsDst | Out-Null

    Write-Host "=== skills-pack install -> $skillsDst ==="

    $skillDirs = Get-ChildItem -Path $packageRoot -Directory |
        Where-Object { $skipTopLevel -notcontains $_.Name } |
        ForEach-Object {
            Get-ChildItem $_.FullName -Recurse -Filter "SKILL.md" -File
        } | ForEach-Object { $_.Directory }

    Write-Host "Found skills: $($skillDirs.Count)"
    Write-Host ""

    $copied = 0
    $updated = 0
    $excluded = 0
    $nameConflicts = @{}

    foreach ($srcDir in $skillDirs) {
        $skillMd = Join-Path $srcDir.FullName "SKILL.md"
        $frontmatterName = Get-SkillName $skillMd
        $leafName = $srcDir.Name
        $name = if ($frontmatterName) { $frontmatterName } else { $leafName }

        if (-not $targetMap.ContainsKey($name)) {
            Write-Host "ERROR: no MANIFEST installTargets for skill '$name'" -ForegroundColor Red
            exit 1
        }
        $targets = @($targetMap[$name])
        if ($targets -notcontains "claude") {
            $excluded++
            Write-Host "Skipped (no claude target): $name"
            continue
        }

        if ($nameConflicts.ContainsKey($name)) {
            Write-Host "WARNING: duplicate skill name '$name' at $($srcDir.FullName) (already installed from $($nameConflicts[$name])) - skipped"
            continue
        }
        $nameConflicts[$name] = $srcDir.FullName

        $dstDir = Join-Path $skillsDst $name
        New-Item -ItemType Directory -Force -Path $dstDir | Out-Null

        Get-ChildItem $srcDir.FullName -Recurse -File | ForEach-Object {
            $rel = $_.FullName.Substring($srcDir.FullName.Length).TrimStart('\', '/')
            if (Test-Path (Join-Path $overlayRoot (Join-Path $name $rel))) {
                return # the _claude/ overlay owns this file; don't copy the base version
            }
            $destFile = Join-Path $dstDir $rel
            $destFileDir = Split-Path $destFile -Parent
            New-Item -ItemType Directory -Force -Path $destFileDir | Out-Null

            if ((Test-Path $destFile) -and ((Get-FileHash $destFile -Algorithm SHA256).Hash -eq (Get-FileHash $_.FullName -Algorithm SHA256).Hash)) {
                return
            }
            $existed = Test-Path $destFile
            Copy-Item $_.FullName -Destination $destFile -Force
            if ($existed) { $updated++ } else { $copied++ }
        }

        Write-Host "Installed: $name"
    }

    Write-Host ""
    Write-Host "=== Removing skills without a claude target ==="
    $removedExcluded = 0
    foreach ($manifestName in @($targetMap.Keys)) {
        if (@($targetMap[$manifestName]) -contains "claude") { continue }
        $path = Join-Path $skillsDst $manifestName
        if (Test-Path $path) {
            Remove-Item $path -Recurse -Force
            $removedExcluded++
            Write-Host "Removed: $manifestName"
        }
    }
    if ($removedExcluded -eq 0) { Write-Host "(none present)" }

    Write-Host ""
    Write-Host "=== Applying Claude-specific overrides (_claude/) ==="
    $overlaid = 0
    if (Test-Path $overlayRoot) {
        Get-ChildItem $overlayRoot -Directory | ForEach-Object {
            $name = $_.Name
            $dstDir = Join-Path $skillsDst $name
            if (-not (Test-Path $dstDir)) {
                Write-Host "WARNING: overlay '$name' has no installed base skill - skipped"
                return
            }
            $changed = 0
            Get-ChildItem $_.FullName -Recurse -File | ForEach-Object {
                $rel = $_.FullName.Substring((Join-Path $overlayRoot $name).Length).TrimStart('\', '/')
                $destFile = Join-Path $dstDir $rel
                $destFileDir = Split-Path $destFile -Parent
                New-Item -ItemType Directory -Force -Path $destFileDir | Out-Null
                if ((Test-Path $destFile) -and ((Get-FileHash $destFile -Algorithm SHA256).Hash -eq (Get-FileHash $_.FullName -Algorithm SHA256).Hash)) {
                    return
                }
                Copy-Item $_.FullName -Destination $destFile -Force
                $changed++
            }
            $overlaid++
            Write-Host "Overlay applied: $name ($changed file(s) changed)"
        }
    }
    else {
        Write-Host "(no _claude/ folder)"
    }

    Write-Host ""
    Write-Host "=== Summary ($skillsDst) ==="
    Write-Host "Files copied (new): $copied"
    Write-Host "Files updated: $updated"
    Write-Host "Skipped (no claude target): $excluded (removed locally: $removedExcluded)"
    Write-Host "Overlays applied: $overlaid"
    Write-Host "Unique skills installed: $($nameConflicts.Count)"
    Write-Host ""
}

function Disable-SuperpowersPlugin {
    $settingsPath = Join-Path $env:USERPROFILE ".claude\settings.json"
    $pluginId = "superpowers@superpowers-marketplace"

    Write-Host "=== Disabling Superpowers plugin (pack is canonical) ==="

    if (-not (Test-Path $settingsPath)) {
        Write-Host "WARNING: $settingsPath not found - skipped"
        return
    }

    $raw = Get-Content -Path $settingsPath -Raw -Encoding UTF8
    $settings = $raw | ConvertFrom-Json

    if ($null -eq $settings.enabledPlugins) {
        Write-Host "enabledPlugins missing - skipped"
        return
    }

    $ep = $settings.enabledPlugins
    if ($ep.PSObject.Properties.Name -notcontains $pluginId) {
        Write-Host "Plugin key '$pluginId' not present - skipped"
        return
    }

    $current = $ep.$pluginId
    $isEnabled = $false
    if ($current -is [bool]) {
        $isEnabled = [bool]$current
    }
    elseif ("$current" -eq "True" -or "$current" -eq "true") {
        $isEnabled = $true
    }

    if (-not $isEnabled) {
        Write-Host "Plugin already disabled - skipped"
        return
    }

    $bakPath = Join-Path (Split-Path $settingsPath -Parent) "settings.json.bak"
    Copy-Item -Path $settingsPath -Destination $bakPath -Force
    Write-Host "Backup: $bakPath"

    $ep.$pluginId = $false
    $json = $settings | ConvertTo-Json -Depth 20
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($settingsPath, ($json.TrimEnd() + [Environment]::NewLine), $utf8NoBom)
    Write-Host "Set enabledPlugins['$pluginId'] = false"
}

$targetMap = Read-InstallTargetMap (Join-Path $packageRoot "MANIFEST.json")

foreach ($root in $destRoots) {
    Install-ToRoot -skillsDst $root
}

if ($useDefaultClaudeDest) {
    Disable-SuperpowersPlugin
}
else {
    Write-Host "Note: -ClaudeDest set; left Claude settings.json unchanged."
}

Write-Host "Note: Claude Code hooks are not installed by this script (different format from Cursor's hooks.json)."
Write-Host "Note: ~/.agents/skills is installed by install.ps1, not here."
Write-Host "Done. Restart Claude Code and check that skills are listed."
