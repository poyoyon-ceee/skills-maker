# Install global Claude Code skills from skills-pack.
# Unlike install.ps1 (Cursor), Claude Code expects skills flattened directly
# under ~/.claude/skills/<skill-name>/SKILL.md — category folders
# (marketingskills/, playbooks/, superpowers/, github/, debug/) are stripped.
#
# _claude/ holds Claude-specific overrides: after the base copy, any file in
# _claude/<skill-name>/ overwrites the installed skill (fixes Cursor-specific
# paths/instructions for the Claude Code environment).
#
# $excludeSkills are never installed and are removed if present: they duplicate
# Claude Code built-ins (official docx/pdf/pptx/xlsx/skill-creator plugins,
# /code-review, /verify, worktree support) and only cause ambiguous triggering.
#
# Run from: skills-maker/skills-pack/install-claude.ps1

$ErrorActionPreference = "Stop"

$packageRoot = $PSScriptRoot
$skillsDst = Join-Path $env:USERPROFILE ".claude\skills"
$overlayRoot = Join-Path $packageRoot "_claude"

$skipTopLevel = @("_hooks", "_claude")
$excludeSkills = @(
    "docx", "pdf", "pptx", "xlsx", "skill-creator",
    "using-superpowers",
    "requesting-code-review", "receiving-code-review",
    "verification-before-completion", "using-git-worktrees"
)

function Get-SkillName {
    param([string]$Path)
    $head = Get-Content $Path -TotalCount 15 -Encoding UTF8 -ErrorAction SilentlyContinue
    foreach ($line in $head) {
        if ($line -match '^name:\s*(.+)$') { return $Matches[1].Trim() }
    }
    return $null
}

New-Item -ItemType Directory -Force -Path $skillsDst | Out-Null

Write-Host "=== skills-pack install (Claude Code) ==="

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
        if ($existed) { $script:updated++ } else { $script:copied++ }
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
        $script:changed = 0
        Get-ChildItem $_.FullName -Recurse -File | ForEach-Object {
            $rel = $_.FullName.Substring((Join-Path $overlayRoot $name).Length).TrimStart('\', '/')
            $destFile = Join-Path $dstDir $rel
            $destFileDir = Split-Path $destFile -Parent
            New-Item -ItemType Directory -Force -Path $destFileDir | Out-Null
            if ((Test-Path $destFile) -and ((Get-FileHash $destFile -Algorithm SHA256).Hash -eq (Get-FileHash $_.FullName -Algorithm SHA256).Hash)) {
                return
            }
            Copy-Item $_.FullName -Destination $destFile -Force
            $script:changed++
        }
        $script:overlaid++
        Write-Host "Overlay applied: $name ($script:changed file(s) changed)"
    }
}
else {
    Write-Host "(no _claude/ folder)"
}

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Files copied (new): $copied"
Write-Host "Files updated: $updated"
Write-Host "Excluded skills (duplicate Claude built-ins): $excluded (removed locally: $removedExcluded)"
Write-Host "Overlays applied: $overlaid"
Write-Host "Unique skills installed: $($nameConflicts.Count)"
Write-Host ""
Write-Host "Note: Claude Code hooks are not installed by this script (different format from Cursor's hooks.json)."
Write-Host "Done. Restart Claude Code and check that skills are listed."
