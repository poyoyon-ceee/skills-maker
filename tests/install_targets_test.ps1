# Installer routing tests. Destinations are always under $env:TEMP.
# Never points AgentsDest/CursorDest/ClaudeDest at the real profile.
$ErrorActionPreference = "Stop"
[Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding

$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param([string]$Message)
    $script:failures.Add($Message)
    Write-Host "FAIL: $Message"
}

function Test-UnderTemp {
    param([string]$Path)
    $tempRoot = [System.IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
    $full = [System.IO.Path]::GetFullPath($Path)
    if (-not $full.EndsWith('\')) { $full += '\' }
    return $full.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-SkillPresence {
    param([string]$Path)
    $skill = Join-Path $Path "SKILL.md"
    if (Test-Path -LiteralPath $skill) {
        return (Get-FileHash -LiteralPath $skill -Algorithm SHA256).Hash
    }
    if (Test-Path -LiteralPath $Path) { return "DIR_NO_SKILL" }
    return "ABSENT"
}

function Assert-Path {
    param([string]$Path, [bool]$ShouldExist)
    $exists = Test-Path -LiteralPath $Path
    if ($ShouldExist -and -not $exists) { Add-Failure "missing: $Path" }
    if (-not $ShouldExist -and $exists) { Add-Failure "unexpected: $Path" }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$pack = Join-Path $repoRoot "skills-pack"
$installPs1 = Join-Path $pack "install.ps1"
$installClaude = Join-Path $pack "install-claude.ps1"
$installSh = Join-Path $pack "install.sh"

$realProfile = $env:USERPROFILE
$realPaths = @(
    (Join-Path $realProfile ".agents\skills\youtube-music-playlist"),
    (Join-Path $realProfile ".cursor\skills\youtube-music-playlist"),
    (Join-Path $realProfile ".claude\skills\youtube-music-playlist"),
    (Join-Path $realProfile ".cursor\hooks\session-start.ps1"),
    (Join-Path $realProfile ".cursor\hooks.json"),
    (Join-Path $realProfile ".claude\settings.json")
)
$before = @{}
foreach ($path in $realPaths) {
    if ($path -like "*\youtube-music-playlist") {
        $before[$path] = Get-SkillPresence $path
    }
    elseif (Test-Path -LiteralPath $path) {
        $before[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    }
    else {
        $before[$path] = "ABSENT"
    }
}

$work = Join-Path $env:TEMP ("skills-maker-install-targets-" + [guid]::NewGuid().ToString("n"))
$fakeHome = Join-Path $work "home"
$agentsDest = Join-Path $work "AgentsDest"
$cursorDest = Join-Path $work "CursorDest"
$claudeDest = Join-Path $work "ClaudeDest"

foreach ($dir in @($fakeHome, $agentsDest, $cursorDest, $claudeDest)) {
    if (-not (Test-UnderTemp $dir)) { throw "Refusing dest outside TEMP: $dir" }
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

foreach ($name in @("docx", "model-router-gpt", "skill-creator")) {
    $dir = Join-Path $claudeDest $name
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Set-Content -LiteralPath (Join-Path $dir "SKILL.md") -Value "---`nname: $name`n---`n" -Encoding utf8
}

foreach ($pair in @(
        @{ Root = $agentsDest; Name = "skill-creator" },
        @{ Root = $agentsDest; Name = "promote-skill" },
        @{ Root = $cursorDest; Name = "youtube-music-playlist" }
    )) {
    $dir = Join-Path $pair.Root $pair.Name
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Set-Content -LiteralPath (Join-Path $dir "SKILL.md") -Value "---`nname: $($pair.Name)`n---`n" -Encoding utf8
}

function Invoke-ChildInstaller {
    param(
        [string]$ScriptPath,
        [string[]]$InstallerArgs
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $parts = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ScriptPath) + $InstallerArgs
    $psi.Arguments = (($parts | ForEach-Object {
                if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '`"') + '"' } else { $_ }
            }) -join " ")
    # Unknown dest switches are ignored by the current scripts, so the child
    # profile must not be the real user profile.
    $psi.EnvironmentVariables["USERPROFILE"] = $fakeHome
    $psi.EnvironmentVariables["HOME"] = $fakeHome
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    [void]$process.Start()
    $outTask = $process.StandardOutput.ReadToEndAsync()
    $errTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(180000)) {
        try { $process.Kill() } catch {}
        throw "Timed out: $ScriptPath"
    }
    return [PSCustomObject]@{
        ExitCode = $process.ExitCode
        Stdout   = $outTask.Result
        Stderr   = $errTask.Result
    }
}

Write-Host "work=$work"
Write-Host "=== install.ps1 ==="
$psResult = Invoke-ChildInstaller -ScriptPath $installPs1 -InstallerArgs @(
    "-AgentsDest", $agentsDest,
    "-CursorDest", $cursorDest,
    "-SkipHooks"
)
Write-Host "install.ps1 exit=$($psResult.ExitCode)"
if ($psResult.ExitCode -ne 0) {
    Add-Failure "install.ps1 exit $($psResult.ExitCode)"
    if ($psResult.Stderr) { Write-Host $psResult.Stderr }
    if ($psResult.Stdout) { Write-Host $psResult.Stdout }
}

Write-Host "=== install-claude.ps1 ==="
$claudeResult = Invoke-ChildInstaller -ScriptPath $installClaude -InstallerArgs @(
    "-ClaudeDest", $claudeDest
)
Write-Host "install-claude.ps1 exit=$($claudeResult.ExitCode)"
if ($claudeResult.ExitCode -ne 0) {
    Add-Failure "install-claude.ps1 exit $($claudeResult.ExitCode)"
    if ($claudeResult.Stderr) { Write-Host $claudeResult.Stderr }
    if ($claudeResult.Stdout) { Write-Host $claudeResult.Stdout }
}

$fakeYtmp = Join-Path $fakeHome ".agents\skills\youtube-music-playlist\SKILL.md"
$fakeHook = Join-Path $fakeHome ".cursor\hooks\session-start.ps1"
Write-Host ("diag fakeHome agents youtube-music-playlist=" + (Test-Path -LiteralPath $fakeYtmp))
Write-Host ("diag AgentsDest youtube-music-playlist=" + (Test-Path -LiteralPath (Join-Path $agentsDest "youtube-music-playlist\SKILL.md")))
Write-Host ("diag fakeHome hook=" + (Test-Path -LiteralPath $fakeHook))

Assert-Path (Join-Path $agentsDest "youtube-music-playlist\SKILL.md") $true
Assert-Path (Join-Path $cursorDest "youtube-music-playlist\SKILL.md") $false
Assert-Path (Join-Path $cursorDest "skill-creator\SKILL.md") $true
Assert-Path (Join-Path $agentsDest "skill-creator\SKILL.md") $false
Assert-Path (Join-Path $cursorDest "promote-skill\SKILL.md") $true
Assert-Path (Join-Path $agentsDest "promote-skill\SKILL.md") $false
Assert-Path (Join-Path $claudeDest "youtube-music-playlist\SKILL.md") $true
Assert-Path (Join-Path $claudeDest "promote-skill\SKILL.md") $true
Assert-Path (Join-Path $claudeDest "docx\SKILL.md") $false
Assert-Path (Join-Path $claudeDest "model-router-gpt\SKILL.md") $false
Assert-Path (Join-Path $claudeDest "skill-creator\SKILL.md") $false

if (Test-Path -LiteralPath $fakeHook) {
    Add-Failure "SkipHooks did not prevent hook copy: $fakeHook"
}
$fakeHooksJson = Join-Path $fakeHome ".cursor\hooks.json"
if (Test-Path -LiteralPath $fakeHooksJson) {
    Add-Failure "SkipHooks did not prevent hooks.json write: $fakeHooksJson"
}

foreach ($file in @($installPs1, $installClaude, $installSh)) {
    $text = Get-Content -LiteralPath $file -Raw -Encoding UTF8
    foreach ($needle in @('$cursorOnlySkills', '$excludeSkills', 'CURSOR_ONLY')) {
        if ($text.Contains($needle)) {
            Add-Failure "$(Split-Path -Leaf $file) still contains $needle"
        }
    }
}

foreach ($path in $realPaths) {
    if ($path -like "*\youtube-music-playlist") {
        $after = Get-SkillPresence $path
    }
    elseif (Test-Path -LiteralPath $path) {
        $after = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    }
    else {
        $after = "ABSENT"
    }
    if ($after -ne $before[$path]) {
        Add-Failure "real profile changed: $path before=$($before[$path]) after=$after"
    }
}

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "FAILED ($($failures.Count))"
    exit 1
}

Write-Host ""
Write-Host "PASS"
exit 0
