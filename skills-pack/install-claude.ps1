# Install global Claude Code skills from skills-pack.
# Skills are flattened directly under ~/.claude/skills/<skill-name>/SKILL.md
# — category folders (playbooks/, superpowers/, github/, debug/) are stripped.
# Marketing skills live in skills-pack-marketing/ and are not installed here.
#
# ~/.agents/skills is NOT written here: install.ps1 owns that tree. Installing
# both would fight over the same folders, and $excludeSkills below would delete
# skills that install.ps1 legitimately puts there (docx, using-superpowers, ...).
#
# _claude/ holds Claude-specific overrides: after the base copy, any file in
# _claude/<skill-name>/ overwrites the installed skill (fixes Cursor-specific
# paths/instructions for the Claude Code environment).
#
# $excludeSkills are never installed and are removed if present.
#   Official plugins: docx, pdf, pptx, xlsx, skill-creator
#   Claude native: requesting-code-review, receiving-code-review (/code-review),
#                  using-git-worktrees (worktree support)
# Superpowers is canonical from this pack, not the marketplace plugin.
# using-superpowers is installed here. The plugin is disabled in settings.json
# (see Disable-SuperpowersPlugin) — do not /add-plugin superpowers on Claude.
# verification-before-completion is NOT excluded: no matching Claude Code
# built-in was found on-device; install the real skill instead.
#
# Run from: skills-maker/skills-pack/install-claude.ps1

$ErrorActionPreference = "Stop"

$packageRoot = $PSScriptRoot
$overlayRoot = Join-Path $packageRoot "_claude"
$destRoots = @(
    (Join-Path $env:USERPROFILE ".claude\skills")
)

$skipTopLevel = @("_hooks", "_claude")
$excludeSkills = @(
    "docx", "pdf", "pptx", "xlsx", "skill-creator",
    "requesting-code-review", "receiving-code-review",
    "using-git-worktrees"
)

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

        if (($excludeSkills -contains $name) -or ($excludeSkills -contains $leafName)) {
            $excluded++
            Write-Host "Excluded (duplicates Claude built-in): $name"
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
    Write-Host "=== Removing excluded skills if present ==="
    $removedExcluded = 0
    foreach ($name in $excludeSkills) {
        $path = Join-Path $skillsDst $name
        if (Test-Path $path) {
            Remove-Item $path -Recurse -Force
            $removedExcluded++
            Write-Host "Removed: $name"
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
    Write-Host "Excluded skills (duplicate Claude built-ins): $excluded (removed locally: $removedExcluded)"
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

foreach ($root in $destRoots) {
    Install-ToRoot -skillsDst $root
}

Disable-SuperpowersPlugin

Write-Host "Note: Claude Code hooks are not installed by this script (different format from Cursor's hooks.json)."
Write-Host "Note: ~/.agents/skills is installed by install.ps1, not here."
Write-Host "Done. Restart Claude Code and check that skills are listed."
