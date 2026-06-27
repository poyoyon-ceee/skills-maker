# Install all global Cursor skills + Superpowers session hook from this package folder.
# Run from: skills-maker/skills/install.ps1

$ErrorActionPreference = "Stop"

$packageRoot = $PSScriptRoot
$skillsDst = Join-Path $env:USERPROFILE ".cursor\skills"
$hooksDst = Join-Path $env:USERPROFILE ".cursor\hooks"
$hooksConfig = Join-Path $env:USERPROFILE ".cursor\hooks.json"
$hooksSrc = Join-Path $packageRoot "_hooks"

$skipNames = @("_hooks")

New-Item -ItemType Directory -Force -Path $skillsDst | Out-Null

Get-ChildItem -Path $packageRoot -Directory | Where-Object { $skipNames -notcontains $_.Name } | ForEach-Object {
    $target = Join-Path $skillsDst $_.Name
    Copy-Item -Path $_.FullName -Destination $target -Recurse -Force
    Write-Host "Skill: $($_.Name) -> $target"
}

if (-not (Test-Path $hooksSrc)) {
    Write-Error "Hooks source not found: $hooksSrc"
}

New-Item -ItemType Directory -Force -Path $hooksDst | Out-Null
Copy-Item (Join-Path $hooksSrc "session-start.ps1") -Destination $hooksDst -Force
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

Write-Host ""
Write-Host "Done. Restart Cursor, then check Customize -> Skills and Hooks."
Write-Host "See INSTALL.md in this folder for details."
