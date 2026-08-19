# Report differences between skills-pack and the installed global skills.
# Read-only: prints drift, never writes.

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$packRoot = Join-Path $repoRoot "skills-pack"
$agentsDst = Join-Path $env:USERPROFILE ".agents\skills"
$cursorDst = Join-Path $env:USERPROFILE ".cursor\skills"

$skipTopLevel = @("_hooks", "_claude")
$cursorOnlySkills = @("chat-handoff", "skill-creator", "promote-skill")
# Generated at runtime, never part of the pack.
$excludePattern = '(^|\\)(__pycache__|\.pytest_cache|node_modules)(\\|$)'

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

function Get-TreeHashes {
    param([string]$Root)
    $set = @{}
    Get-ChildItem $Root -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($Root.Length).TrimStart('\', '/')
        if ($rel -match $excludePattern) { return }
        $set[$rel] = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
    }
    return $set
}

function Compare-Trees {
    param([hashtable]$Pack, [hashtable]$Installed)
    $onlyPack = @($Pack.Keys | Where-Object { -not $Installed.ContainsKey($_) })
    $onlyInst = @($Installed.Keys | Where-Object { -not $Pack.ContainsKey($_) })
    $changed = @($Pack.Keys | Where-Object { $Installed.ContainsKey($_) -and $Installed[$_] -ne $Pack[$_] })
    return [PSCustomObject]@{
        OnlyInPack      = $onlyPack
        OnlyInInstalled = $onlyInst
        Changed         = $changed
    }
}

$drift = 0
$missing = 0

Get-ChildItem -Path $packRoot -Directory |
    Where-Object { $skipTopLevel -notcontains $_.Name } |
    ForEach-Object {
        Get-ChildItem $_.FullName -Recurse -Filter "SKILL.md" -File | ForEach-Object {
            $srcDir = $_.Directory.FullName
            $name = Get-SkillName $_.FullName
            if (-not $name) { $name = $_.Directory.Name }

            $root = if ($cursorOnlySkills -contains $name) { $cursorDst } else { $agentsDst }
            $dest = Join-Path $root $name

            if (-not (Test-Path $dest)) {
                Write-Host "MISSING (not installed): $name -> $dest" -ForegroundColor Yellow
                $script:missing++
                return
            }

            $cmp = Compare-Trees (Get-TreeHashes $srcDir) (Get-TreeHashes $dest)
            $total = $cmp.OnlyInPack.Count + $cmp.OnlyInInstalled.Count + $cmp.Changed.Count
            if ($total -eq 0) { return }

            $script:drift++
            $packNewer = (Get-Item $srcDir).LastWriteTime -ge (Get-Item $dest).LastWriteTime
            Write-Host "DRIFT: $name (pack newer: $packNewer)" -ForegroundColor Cyan
            $cmp.Changed         | ForEach-Object { Write-Host "    changed:      $_" }
            $cmp.OnlyInPack      | ForEach-Object { Write-Host "    pack only:    $_" }
            $cmp.OnlyInInstalled | ForEach-Object { Write-Host "    global only:  $_" }
        }
    }

Write-Host ""
Write-Host "Skills with drift: $drift"
Write-Host "Skills missing from global: $missing"
if ($drift -eq 0 -and $missing -eq 0) { Write-Host "OK: pack matches global." }
