# Install global Cursor skills from skills-pack with duplicate-safe merge.
# Run from: skills-maker/skills-pack/install.ps1

$ErrorActionPreference = "Stop"

$packageRoot = $PSScriptRoot
$skillsDst = Join-Path $env:USERPROFILE ".cursor\skills"
$hooksDst = Join-Path $env:USERPROFILE ".cursor\hooks"
$hooksConfig = Join-Path $env:USERPROFILE ".cursor\hooks.json"
$hooksSrc = Join-Path $packageRoot "_hooks"

$skipTopLevel = @("_hooks")
$legacyRemove = @(
    "writing-plans\writing-plans",
    "grill-me\grill-me",
    "webapp-testing\webapp-testing",
    "debug\debug",
    "github\github",
    "git-in-clone",
    "test-driven-development\test-driven-development",
    "brainstorming\brainstorming"
)

function Get-SkillName {
    param([string]$Path)
    $head = Get-Content $Path -TotalCount 15 -Encoding UTF8 -ErrorAction SilentlyContinue
    foreach ($line in $head) {
        if ($line -match '^name:\s*(.+)$') { return $Matches[1].Trim() }
    }
    return $null
}

function Get-SkillsIndex {
    param([string]$Root)
    $index = @{}
    if (-not (Test-Path $Root)) { return $index }
    Get-ChildItem $Root -Recurse -Filter "SKILL.md" -File | ForEach-Object {
        $name = Get-SkillName $_.FullName
        if (-not $name) { return }
        $rel = $_.FullName.Substring($Root.Length).TrimStart('\', '/')
        $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        if (-not $index.ContainsKey($name)) { $index[$name] = @() }
        $index[$name] += [PSCustomObject]@{ Rel = $rel; Hash = $hash; Full = $_.FullName }
    }
    return $index
}

function Get-CanonicalRels {
    param([string]$Root)
    $rels = @{}
    Get-ChildItem $Root -Recurse -Filter "SKILL.md" -File | ForEach-Object {
        $name = Get-SkillName $_.FullName
        if (-not $name) { return }
        $rel = $_.FullName.Substring($Root.Length).TrimStart('\', '/')
        $rels[$name] = $rel
    }
    return $rels
}

New-Item -ItemType Directory -Force -Path $skillsDst | Out-Null

$canonical = Get-CanonicalRels $packageRoot
$beforeIndex = Get-SkillsIndex $skillsDst

Write-Host "=== skills-pack install ==="
Write-Host "Package skills: $($canonical.Count)"
Write-Host "Target before:  $(($beforeIndex.Keys | Measure-Object).Count) unique names"
Write-Host ""

$skippedIdentical = 0
$copied = 0
$updated = 0

Get-ChildItem -Path $packageRoot -Directory | Where-Object { $skipTopLevel -notcontains $_.Name } | ForEach-Object {
    $srcDir = $_.FullName
    $dstDir = Join-Path $skillsDst $_.Name

    Get-ChildItem $srcDir -Recurse -Filter "SKILL.md" -File | ForEach-Object {
        $relFromTop = $_.FullName.Substring($packageRoot.Length).TrimStart('\', '/')
        $name = Get-SkillName $_.FullName
        $srcHash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        $destFile = Join-Path $skillsDst $relFromTop
        $destDir = Split-Path $destFile -Parent

        if ($name -and $beforeIndex.ContainsKey($name)) {
            $existing = $beforeIndex[$name]
            $sameHashElsewhere = $existing | Where-Object { $_.Hash -eq $srcHash }
            $samePath = $existing | Where-Object { $_.Rel -ieq $relFromTop }
            if ($sameHashElsewhere -and -not $samePath) {
                $skippedIdentical++
                return
            }
        }

        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        if ((Test-Path $destFile) -and ((Get-FileHash $destFile -Algorithm SHA256).Hash -eq $srcHash)) {
            return
        }
        Copy-Item $_.FullName -Destination $destFile -Force
        if (Test-Path $destFile) {
            if ((Get-Item $destFile).LastWriteTimeUtc -eq (Get-Item $_.FullName).LastWriteTimeUtc) { $copied++ } else { $updated++ }
        }
    }

    Get-ChildItem $srcDir -Recurse -File | Where-Object { $_.Name -ne "SKILL.md" } | ForEach-Object {
        $relFromTop = $_.FullName.Substring($packageRoot.Length).TrimStart('\', '/')
        $destFile = Join-Path $skillsDst $relFromTop
        $destDir = Split-Path $destFile -Parent
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        if (-not (Test-Path $destFile) -or ((Get-FileHash $destFile -Algorithm SHA256).Hash -ne (Get-FileHash $_.FullName -Algorithm SHA256).Hash)) {
            Copy-Item $_.FullName -Destination $destFile -Force
        }
    }

    Write-Host "Installed: $($_.Name)"
}

Write-Host ""
Write-Host "=== Removing known legacy duplicate folders ==="
foreach ($rel in $legacyRemove) {
    $path = Join-Path $skillsDst $rel
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force
        Write-Host "Deleted legacy: $rel"
    }
}

$srcGit = Join-Path $skillsDst "github\github\git-in-clone"
$dstGit = Join-Path $skillsDst "github\git-in-clone"
if ((Test-Path $srcGit) -and -not (Test-Path $dstGit)) {
    Move-Item $srcGit $dstGit
    Write-Host "Moved: github\github\git-in-clone -> github\git-in-clone"
}

Write-Host ""
Write-Host "=== Resolving duplicate skill names (keep skills-pack path) ==="
$afterIndex = Get-SkillsIndex $skillsDst
$removedDupes = 0
foreach ($name in ($afterIndex.Keys | Sort-Object)) {
    $items = $afterIndex[$name]
    if ($items.Count -le 1) { continue }

    $keepRel = $null
    if ($canonical.ContainsKey($name)) {
        $keepRel = $canonical[$name]
    }
    else {
        $keepRel = ($items | Sort-Object Rel | Select-Object -First 1).Rel
    }

    foreach ($item in $items) {
        if ($item.Rel -ieq $keepRel) { continue }
        if (Test-Path $item.Full) {
            Remove-Item $item.Full -Force
            $removedDupes++
            Write-Host "Removed duplicate [$name]: $($item.Rel)"
        }
    }
}

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

$finalIndex = Get-SkillsIndex $skillsDst
$dupesLeft = @($finalIndex.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 })

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Skipped identical (already on this PC): $skippedIdentical"
Write-Host "Removed duplicate paths: $removedDupes"
Write-Host "Unique skill names now: $(($finalIndex.Keys | Measure-Object).Count)"
if ($dupesLeft.Count -gt 0) {
    Write-Host "WARNING: duplicate names remain:"
    $dupesLeft | ForEach-Object { Write-Host "  $($_.Name): $($_.Value.Count)" }
}
else {
    Write-Host "OK: no duplicate skill names."
}
Write-Host ""
Write-Host "Done. Restart Cursor, then check Customize -> Skills and Hooks."
Write-Host "See INSTALL.md in this folder for details."
