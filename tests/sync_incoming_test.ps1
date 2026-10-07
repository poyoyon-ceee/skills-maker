# Sync-incoming integration test.
# Fixtures live under $env:TEMP. Never points RepoRoot or HomeRoot at the real repo or profile.
# $HOME is an automatic variable; this file must not assign it.
$ErrorActionPreference = "Stop"
[Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding
chcp 65001 | Out-Null

$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param([string]$Message)
    $script:failures.Add($Message)
    Write-Host "FAIL: $Message"
}

function Assert-UnderTemp {
    param([string]$Path)
    $tempRoot = [System.IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
    $full = [System.IO.Path]::GetFullPath($Path)
    if (-not $full.EndsWith('\')) { $full += '\' }
    if (-not $full.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing path outside TEMP: $Path"
    }
}

function Assert-NotRealRepo {
    param([string]$Path)
    $prod = [System.IO.Path]::GetFullPath($productionRepo).TrimEnd('\')
    $full = [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
    if ($full.Equals($prod, [System.StringComparison]::OrdinalIgnoreCase) -or
        $full.StartsWith($prod + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing RepoRoot inside the real repo: $Path"
    }
}

function Assert-NotRealSkillHome {
    param([string]$Path)
    $real = [System.IO.Path]::GetFullPath($realProfile).TrimEnd('\')
    $full = [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
    if ($full.Equals($real, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing HomeRoot equal to the real profile: $Path"
    }
    foreach ($leaf in @(".agents", ".cursor", ".claude")) {
        $blocked = [System.IO.Path]::GetFullPath((Join-Path $real $leaf)).TrimEnd('\')
        if ($full.Equals($blocked, [System.StringComparison]::OrdinalIgnoreCase) -or
            $full.StartsWith($blocked + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing HomeRoot under a real skill home: $Path"
        }
    }
}

function U {
    param([int[]]$Codes)
    return -join ($Codes | ForEach-Object { [char]$_ })
}

function Get-CountLabel {
    param([int]$Count)
    # fullwidth parentheses + ken
    return ([char]0xFF08) + [string]$Count + ([char]0x4EF6) + ([char]0xFF09)
}

function Write-Utf8 {
    param([string]$Path, [string]$Text)
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Write-Catalog {
    param([string]$Path)
    $lp = [char]0xFF08
    $ken = [char]0x4EF6
    $rp = [char]0xFF09
    $cmd = U 0x30B3, 0x30DE, 0x30F3, 0x30C9
    $desc = U 0x8AAC, 0x660E
    $when = U 0x4F7F, 0x3044, 0x3069, 0x3053, 0x308D
    $text = "## 5. section$lp" + "0$ken$rp" + "`n`n| $cmd | $desc | $when |`n|----------|------|-----------|`n"
    Write-Utf8 $Path $text
}

function Write-SkillMd {
    param(
        [string]$Dir,
        [string]$Name,
        [string]$Body,
        [switch]$Catalog,
        [string]$Summary = "summary",
        [string]$When = "when to use"
    )
    New-Item -ItemType Directory -Force -Path $Dir | Out-Null
    $lines = @("---", "name: $Name", "description: fixture")
    if ($Catalog) {
        $lines += "catalog-section: 5"
        $lines += "catalog-summary: $Summary"
        $lines += "catalog-when: $When"
    }
    $lines += "---"
    $lines += ""
    $lines += $Body
    Write-Utf8 (Join-Path $Dir "SKILL.md") (($lines -join "`n") + "`n")
}

function Install-IncomingLib {
    param([string]$Repo)
    $dest = Join-Path $Repo "scripts"
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item -LiteralPath (Join-Path $productionRepo "scripts\incoming_lib.py") -Destination (Join-Path $dest "incoming_lib.py") -Force
    Write-Utf8 (Join-Path $dest "__init__.py") ""
}

function Read-JsonArray {
    param([string]$Path)
    $raw = [System.IO.File]::ReadAllText($Path)
    if ($raw.Length -gt 0 -and [int][char]$raw[0] -eq 0xFEFF) { $raw = $raw.Substring(1) }
    $raw = $raw.Trim()
    if (-not $raw -or $raw -eq "[]") { return @() }
    $parsed = $raw | ConvertFrom-Json
    if ($null -eq $parsed) { return @() }
    return @($parsed)
}

function Get-ManifestRow {
    param($Rows, [string]$Name)
    foreach ($row in @($Rows)) {
        if ($row.name -eq $Name) { return $row }
    }
    return $null
}

function Assert-Targets {
    param($Rows, [string]$Name, [string[]]$Expected)
    $row = Get-ManifestRow $Rows $Name
    if ($null -eq $row) {
        Add-Failure "$Name missing from manifest"
        return
    }
    $got = @($row.installTargets)
    $exp = @($Expected)
    $ok = ($got.Count -eq $exp.Count)
    if ($ok) {
        for ($i = 0; $i -lt $exp.Count; $i++) {
            if ([string]$got[$i] -ne [string]$exp[$i]) { $ok = $false }
        }
    }
    if (-not $ok) {
        Add-Failure "$Name installTargets got=[$($got -join ', ')] expected=[$($exp -join ', ')]"
    }
}

function Assert-Exists {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path -LiteralPath $Path)) { Add-Failure "missing: $Label" }
}

function Assert-Absent {
    param([string]$Path, [string]$Label)
    if (Test-Path -LiteralPath $Path) { Add-Failure "unexpected: $Label" }
}

function Assert-FileContains {
    param([string]$Path, [string]$Needle, [string]$Label)
    if (-not (Test-Path -LiteralPath $Path)) {
        Add-Failure "missing file: $Label"
        return
    }
    $text = [System.IO.File]::ReadAllText($Path)
    if (-not $text.Contains($Needle)) { Add-Failure "$Label does not contain [$Needle]" }
}

function Assert-FileNotContains {
    param([string]$Path, [string]$Needle, [string]$Label)
    if (-not (Test-Path -LiteralPath $Path)) {
        Add-Failure "missing file: $Label"
        return
    }
    $text = [System.IO.File]::ReadAllText($Path)
    if ($text.Contains($Needle)) { Add-Failure "$Label should not contain [$Needle]" }
}

function Get-PresenceLabel {
    param([string]$Path)
    $skill = Join-Path $Path "SKILL.md"
    if (Test-Path -LiteralPath $skill) { return "SKILL" }
    if (Test-Path -LiteralPath $Path) { return "DIR" }
    return "ABSENT"
}

function Get-TreeFingerprint {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "ABSENT" }
    $files = @(Get-ChildItem -LiteralPath $Path -Recurse -File -Force | Sort-Object FullName)
    if ($files.Count -eq 0) { return "EMPTY_DIR" }
    $parts = foreach ($file in $files) {
        $rel = $file.FullName.Substring($Path.Length).TrimStart('\')
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        "$rel=$hash"
    }
    return ($parts -join "`n")
}

function Invoke-PythonFile {
    param([string]$Code, [hashtable]$EnvMap)
    $py = Join-Path $env:TEMP ("skills-maker-sync-py-" + [guid]::NewGuid().ToString("n") + ".py")
    Assert-UnderTemp $py
    Write-Utf8 $py $Code
    $saved = @{}
    foreach ($key in $EnvMap.Keys) {
        $saved[$key] = [Environment]::GetEnvironmentVariable($key, "Process")
        [Environment]::SetEnvironmentVariable($key, [string]$EnvMap[$key], "Process")
    }
    $output = & python $py 2>&1 | Out-String
    $code = $LASTEXITCODE
    foreach ($key in $EnvMap.Keys) {
        [Environment]::SetEnvironmentVariable($key, $saved[$key], "Process")
    }
    Remove-Item -LiteralPath $py -Force -ErrorAction SilentlyContinue
    return [PSCustomObject]@{ ExitCode = $code; Output = $output }
}

function Invoke-Sync {
    param(
        [string]$ScriptPath,
        [string[]]$ScriptArgs
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $utf8 = New-Object System.Text.UTF8Encoding $false
    $psi.StandardOutputEncoding = $utf8
    $psi.StandardErrorEncoding = $utf8
    $psi.WorkingDirectory = $env:TEMP
    $parts = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ScriptPath) + $ScriptArgs
    $psi.Arguments = (($parts | ForEach-Object {
                if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '`"') + '"' } else { $_ }
            }) -join " ")
    $psi.EnvironmentVariables["PYTHONIOENCODING"] = "utf-8"
    $psi.EnvironmentVariables["PYTHONUTF8"] = "1"
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    [void]$process.Start()
    $outTask = $process.StandardOutput.ReadToEndAsync()
    $errTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(180000)) {
        try { $process.Kill() } catch {}
        try { $process.WaitForExit() } catch {}
        return [PSCustomObject]@{ ExitCode = -2; Stdout = ""; Stderr = "Timed out" }
    }
    try { $process.WaitForExit() } catch {}
    return [PSCustomObject]@{
        ExitCode = $process.ExitCode
        Stdout   = $outTask.Result
        Stderr   = $errTask.Result
    }
}

function Show-Result {
    param([string]$Label, $Result)
    Write-Host "$Label exit=$($Result.ExitCode)"
    if ($Result.Stdout) { Write-Host $Result.Stdout }
    if ($Result.Stderr) { Write-Host $Result.Stderr }
}

function Home-Skill {
    param([string]$Root, [string]$Token, [string]$Name)
    switch ($Token) {
        "agents" { return Join-Path $Root ".agents\skills\$Name" }
        "cursor" { return Join-Path $Root ".cursor\skills\$Name" }
        "claude" { return Join-Path $Root ".claude\skills\$Name" }
        default { throw "unknown token $Token" }
    }
}

$productionRepo = Split-Path -Parent $PSScriptRoot
$realProfile = $env:USERPROFILE
$syncScript = Join-Path $productionRepo "scripts\sync-incoming.ps1"
$realManifest = Join-Path $productionRepo "skills-pack\MANIFEST.json"
$realCatalog = Join-Path $productionRepo ("skills" + [char]0x4E00 + [char]0x89A7 + ".md")
$realPdf = Join-Path $productionRepo "catalog\skills-catalog-system-atlas.pdf"
$realLib = Join-Path $productionRepo "scripts\incoming_lib.py"
$sampleSummary = U 0x30B5, 0x30F3, 0x30D7, 0x30EB

$fileGuards = @(
    $realManifest,
    $realCatalog,
    $realPdf,
    $realLib,
    (Join-Path $productionRepo "scripts\generate-manifest.ps1")
)
$guardSnap = @{}
foreach ($path in $fileGuards) {
    if (Test-Path -LiteralPath $path) {
        $item = Get-Item -LiteralPath $path
        $guardSnap[$path] = [PSCustomObject]@{
            Existed = $true
            Mtime   = $item.LastWriteTimeUtc.Ticks
            Hash    = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
            Backup  = $null
        }
        $backup = Join-Path $env:TEMP ("skills-maker-sync-guard-" + [guid]::NewGuid().ToString("n"))
        Copy-Item -LiteralPath $path -Destination $backup -Force
        $guardSnap[$path].Backup = $backup
    }
    else {
        $guardSnap[$path] = [PSCustomObject]@{ Existed = $false; Mtime = 0; Hash = "ABSENT"; Backup = $null }
    }
}

$ytPaths = @(
    (Join-Path $realProfile ".agents\skills\youtube-music-playlist"),
    (Join-Path $realProfile ".cursor\skills\youtube-music-playlist"),
    (Join-Path $realProfile ".claude\skills\youtube-music-playlist")
)
$ytBefore = @{}
$ytBackup = @{}
foreach ($path in $ytPaths) {
    $ytBefore[$path] = Get-TreeFingerprint $path
    Write-Host ("youtube " + (Split-Path (Split-Path (Split-Path $path -Parent) -Parent) -Leaf) + " before=" + (Get-PresenceLabel $path))
    if ($ytBefore[$path] -ne "ABSENT") {
        $dest = Join-Path $env:TEMP ("skills-maker-yt-guard-" + [guid]::NewGuid().ToString("n"))
        Copy-Item -LiteralPath $path -Destination $dest -Recurse -Force
        $ytBackup[$path] = $dest
    }
}

function Restore-RealSideEffects {
    foreach ($path in @($fileGuards)) {
        $snap = $guardSnap[$path]
        $exists = Test-Path -LiteralPath $path
        $changed = $false
        if ($snap.Existed -ne $exists) {
            $changed = $true
        }
        elseif ($exists) {
            $mtime = (Get-Item -LiteralPath $path).LastWriteTimeUtc.Ticks
            $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
            if ($mtime -ne $snap.Mtime -or $hash -ne $snap.Hash) { $changed = $true }
        }
        if (-not $changed) { continue }
        Add-Failure "real file changed during sync test: $path"
        if ($exists -and -not $snap.Existed) {
            Remove-Item -LiteralPath $path -Force
        }
        elseif ($snap.Existed) {
            Copy-Item -LiteralPath $snap.Backup -Destination $path -Force
            (Get-Item -LiteralPath $path).LastWriteTimeUtc = [DateTime]::new([long]$snap.Mtime)
        }
    }
    foreach ($path in $ytPaths) {
        $after = Get-TreeFingerprint $path
        $leaf = Split-Path (Split-Path (Split-Path $path -Parent) -Parent) -Leaf
        Write-Host "youtube $leaf after=$(Get-PresenceLabel $path)"
        if ($after -eq $ytBefore[$path]) { continue }
        Add-Failure "real youtube-music-playlist changed: $path"
        if ($path -notlike "*\youtube-music-playlist") { throw "refusing to restore unexpected path: $path" }
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force }
        if ($ytBackup.ContainsKey($path)) {
            $parent = Split-Path -Parent $path
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
            Copy-Item -LiteralPath $ytBackup[$path] -Destination $path -Recurse -Force
        }
    }
}

try {
    Write-Host "=== catalog fixture preflight ==="
    $preDir = Join-Path $env:TEMP ("skills-maker-sync-preflight-" + [guid]::NewGuid().ToString("n"))
    Assert-UnderTemp $preDir
    New-Item -ItemType Directory -Force -Path $preDir | Out-Null
    $preCatalog = Join-Path $preDir "catalog.md"
    Write-Catalog $preCatalog
    $pre = Invoke-PythonFile -EnvMap @{
        PYTHONPATH   = $productionRepo
        CATALOG_PATH = $preCatalog
    } -Code @'
import os, sys
from pathlib import Path
from scripts.incoming_lib import upsert_catalog_row
text = Path(os.environ["CATALOG_PATH"]).read_text(encoding="utf-8-sig")
try:
    upsert_catalog_row(text, 5, "preflight-skill", "sum", "when")
except Exception as exc:
    print(exc)
    sys.exit(1)
sys.exit(0)
'@
    Remove-Item -LiteralPath $preDir -Recurse -Force -ErrorAction SilentlyContinue
    if ($pre.ExitCode -ne 0) {
        Add-Failure "catalog fixture preflight failed: $($pre.Output)"
    }
    else {
        Write-Host "preflight ok"
    }

    Write-Host "=== migration map guard ==="
    $mig = Invoke-PythonFile -EnvMap @{ PYTHONPATH = $productionRepo } -Code @'
import sys
from scripts.incoming_lib import migration_targets
names = [
    "sample-skill",
    "overwrite-skill",
    "kept-skill",
    "pdf-old-skill",
    "pdf-new-skill",
    "tail-skill",
    "bare-skill",
    "ignored-skill",
    "stale-root-skill",
    "inbox-wrong-name",
    "canonical-skill-name",
    "after-name-mismatch-skill",
    "kept-sibling",
    "categorized-fail-skill",
]
bad = []
for name in names:
    try:
        migration_targets(name)
    except ValueError:
        continue
    bad.append(name)
if bad:
    print(",".join(bad))
    sys.exit(1)
sys.exit(0)
'@
    if ($mig.ExitCode -ne 0) {
        Add-Failure "fixture names must stay out of migration_targets: $($mig.Output)"
    }
    else {
        Write-Host "migration guard ok"
    }

    if (-not (Test-Path -LiteralPath $syncScript)) {
        $probe = Join-Path $env:TEMP ("skills-maker-sync-probe-" + [guid]::NewGuid().ToString("n"))
        Assert-UnderTemp $probe
        $attempt = Invoke-Sync -ScriptPath $syncScript -ScriptArgs @(
            "-RepoRoot", $probe,
            "-HomeRoot", (Join-Path $probe "home"),
            "-SkipPdf"
        )
        Show-Result "missing-script" $attempt
        Add-Failure "scripts/sync-incoming.ps1 is missing (exit=$($attempt.ExitCode))"
    }
    else {
        Write-Host "=== scenario A: success, overwrite, ignore extra ==="
        $workA = Join-Path $env:TEMP ("skills-maker-sync-A-" + [guid]::NewGuid().ToString("n"))
        $repoA = Join-Path $workA "repo"
        $homeA = Join-Path $workA "home"
        Assert-UnderTemp $repoA
        Assert-UnderTemp $homeA
        Assert-NotRealRepo $repoA
        Assert-NotRealSkillHome $homeA
        New-Item -ItemType Directory -Force -Path $repoA, $homeA | Out-Null
        Install-IncomingLib $repoA
        foreach ($box in @("agents-claude", "agents-only", "claude-only", "cursor-only")) {
            New-Item -ItemType Directory -Force -Path (Join-Path $repoA "incoming\$box") | Out-Null
        }
        Write-Catalog (Join-Path $repoA "skills$([char]0x4E00)$([char]0x89A7).md")
        $catalogA = Join-Path $repoA ("skills" + [char]0x4E00 + [char]0x89A7 + ".md")
        Write-SkillMd -Dir (Join-Path $repoA "skills-pack\kept-skill") -Name "kept-skill" -Body "KEPT-BODY"
        Write-SkillMd -Dir (Join-Path $repoA "skills-pack\overwrite-skill") -Name "overwrite-skill" -Body "OLD-MARKER"
        Write-Utf8 (Join-Path $repoA "skills-pack\overwrite-skill\old.txt") "OLD-FILE`n"
        Write-Utf8 (Join-Path $repoA "skills-pack\MANIFEST.json") @'
[
  {
    "name": "kept-skill",
    "path": "kept-skill/SKILL.md",
    "installTargets": ["claude"],
    "installTarget": "~/.claude/skills/kept-skill/"
  },
  {
    "name": "overwrite-skill",
    "path": "overwrite-skill/SKILL.md",
    "installTargets": ["cursor"],
    "installTarget": "~/.cursor/skills/overwrite-skill/"
  }
]
'@
        Write-SkillMd -Dir (Join-Path $repoA "incoming\agents-claude\sample-skill") -Name "sample-skill" -Body "BODY-SAMPLE" -Catalog -Summary $sampleSummary -When "sync test"
        Write-Utf8 (Join-Path $repoA "incoming\agents-claude\sample-skill\extra.txt") "EXTRA-SAMPLE`n"
        Write-SkillMd -Dir (Join-Path $repoA "incoming\agents-only\overwrite-skill") -Name "overwrite-skill" -Body "NEW-MARKER" -Catalog -Summary "replaced summary" -When "replace same name"
        Write-Utf8 (Join-Path $repoA "incoming\agents-only\overwrite-skill\new.txt") "NEW-FILE`n"
        Write-SkillMd -Dir (Join-Path $repoA "incoming\extra\ignored-skill") -Name "ignored-skill" -Body "IGNORED-BODY" -Catalog -Summary "ignored" -When "outside the four boxes"
        Write-Utf8 (Join-Path $repoA "incoming\notes.txt") "NOT-A-SKILL`n"
        Write-Utf8 (Join-Path $repoA "incoming\agents-claude\not-a-skill\readme.txt") "NO-SKILL-MD`n"
        Write-Host "workA=$workA"
        $resultA = Invoke-Sync -ScriptPath $syncScript -ScriptArgs @("-RepoRoot", $repoA, "-HomeRoot", $homeA, "-SkipPdf")
        Show-Result "scenario-A" $resultA
        if ($resultA.ExitCode -ne 0) { Add-Failure "scenario A exit $($resultA.ExitCode)" }
        $blobA = [string]$resultA.Stdout + "`n" + [string]$resultA.Stderr
        if ($blobA.Contains($realManifest)) { Add-Failure "scenario A output mentions the real MANIFEST" }

        Assert-Exists (Join-Path (Home-Skill $homeA "agents" "sample-skill") "SKILL.md") "agents sample-skill"
        Assert-Exists (Join-Path (Home-Skill $homeA "claude" "sample-skill") "SKILL.md") "claude sample-skill"
        Assert-Absent (Home-Skill $homeA "cursor" "sample-skill") "cursor sample-skill"
        Assert-FileContains (Join-Path $repoA "skills-pack\sample-skill\SKILL.md") "BODY-SAMPLE" "pack sample-skill"
        Assert-FileContains (Join-Path $repoA "skills-pack\sample-skill\extra.txt") "EXTRA-SAMPLE" "pack sample extra"
        Assert-FileContains (Join-Path (Home-Skill $homeA "agents" "sample-skill") "extra.txt") "EXTRA-SAMPLE" "agents sample extra"
        Assert-FileContains (Join-Path (Home-Skill $homeA "claude" "sample-skill") "extra.txt") "EXTRA-SAMPLE" "claude sample extra"
        Assert-Absent (Join-Path $repoA "incoming\agents-claude\sample-skill") "sample-skill inbox"
        Assert-FileContains $catalogA "/sample-skill" "catalog sample command"
        Assert-FileContains $catalogA $sampleSummary "catalog sample summary"
        Assert-FileContains $catalogA (Get-CountLabel 2) "catalog count after A"

        $rowsA = Read-JsonArray (Join-Path $repoA "skills-pack\MANIFEST.json")
        Assert-Targets $rowsA "sample-skill" @("agents", "claude")
        Assert-Targets $rowsA "kept-skill" @("claude")
        Assert-Targets $rowsA "overwrite-skill" @("agents")
        $sampleRow = Get-ManifestRow $rowsA "sample-skill"
        if ($null -eq $sampleRow -or [string]$sampleRow.installTarget -ne "~/.agents/skills/sample-skill/") {
            Add-Failure "sample-skill installTarget was not regenerated"
        }
        $overRow = Get-ManifestRow $rowsA "overwrite-skill"
        if ($null -eq $overRow -or [string]$overRow.installTarget -ne "~/.agents/skills/overwrite-skill/") {
            Add-Failure "overwrite-skill installTarget was not replaced"
        }
        Assert-FileContains (Join-Path $repoA "skills-pack\overwrite-skill\SKILL.md") "NEW-MARKER" "pack overwrite"
        Assert-FileNotContains (Join-Path $repoA "skills-pack\overwrite-skill\SKILL.md") "OLD-MARKER" "pack overwrite old body"
        Assert-FileContains (Join-Path $repoA "skills-pack\overwrite-skill\new.txt") "NEW-FILE" "pack overwrite new file"
        Assert-Absent (Join-Path $repoA "skills-pack\overwrite-skill\old.txt") "pack overwrite old file"
        Assert-FileContains (Join-Path (Home-Skill $homeA "agents" "overwrite-skill") "SKILL.md") "NEW-MARKER" "agents overwrite"
        Assert-Absent (Home-Skill $homeA "cursor" "overwrite-skill") "cursor overwrite"
        Assert-Absent (Home-Skill $homeA "claude" "overwrite-skill") "claude overwrite"
        Assert-Absent (Join-Path $repoA "incoming\agents-only\overwrite-skill") "overwrite inbox"
        Assert-FileContains (Join-Path $repoA "skills-pack\kept-skill\SKILL.md") "KEPT-BODY" "kept skill"
        Assert-FileContains (Join-Path $repoA "incoming\extra\ignored-skill\SKILL.md") "IGNORED-BODY" "ignored inbox"
        Assert-Absent (Join-Path $repoA "skills-pack\ignored-skill") "ignored pack"
        Assert-FileContains (Join-Path $repoA "incoming\notes.txt") "NOT-A-SKILL" "loose incoming file"
        Assert-FileContains (Join-Path $repoA "incoming\agents-claude\not-a-skill\readme.txt") "NO-SKILL-MD" "dir without SKILL.md"
        Assert-Absent (Join-Path $repoA "skills-pack\not-a-skill") "not-a-skill pack"
        Assert-FileContains $catalogA "/overwrite-skill" "catalog overwrite"
        Assert-FileNotContains $catalogA "/ignored-skill" "catalog ignored"

        if ($resultA.ExitCode -eq 0) {
            Write-Host "=== scenario B: missing catalog stays, later skill continues ==="
            Write-SkillMd -Dir (Join-Path $repoA "incoming\agents-claude\bare-skill") -Name "bare-skill" -Body "BARE-BODY"
            Write-SkillMd -Dir (Join-Path $repoA "incoming\cursor-only\tail-skill") -Name "tail-skill" -Body "TAIL-BODY" -Catalog -Summary "continues after failure" -When "another skill is invalid"
            $resultB = Invoke-Sync -ScriptPath $syncScript -ScriptArgs @("-RepoRoot", $repoA, "-HomeRoot", $homeA, "-SkipPdf")
            Show-Result "scenario-B" $resultB
            if ($resultB.ExitCode -eq 0) { Add-Failure "scenario B should exit non-zero" }
            $blobB = [string]$resultB.Stdout + "`n" + [string]$resultB.Stderr
            if ($blobB.Contains($realManifest)) { Add-Failure "scenario B output mentions the real MANIFEST" }
            Assert-FileContains (Join-Path $repoA "incoming\agents-claude\bare-skill\SKILL.md") "BARE-BODY" "bare inbox"
            Assert-Absent (Join-Path $repoA "skills-pack\bare-skill") "bare pack"
            Assert-Absent (Home-Skill $homeA "agents" "bare-skill") "bare agents"
            Assert-Absent (Home-Skill $homeA "cursor" "bare-skill") "bare cursor"
            Assert-Absent (Home-Skill $homeA "claude" "bare-skill") "bare claude"
            Assert-FileNotContains $catalogA "/bare-skill" "catalog bare"
            Assert-Absent (Join-Path $repoA "incoming\cursor-only\tail-skill") "tail inbox"
            Assert-FileContains (Join-Path $repoA "skills-pack\tail-skill\SKILL.md") "TAIL-BODY" "pack tail"
            Assert-FileContains (Join-Path (Home-Skill $homeA "cursor" "tail-skill") "SKILL.md") "TAIL-BODY" "cursor tail"
            Assert-Absent (Home-Skill $homeA "agents" "tail-skill") "agents tail"
            Assert-Absent (Home-Skill $homeA "claude" "tail-skill") "claude tail"
            Assert-FileContains $catalogA "/tail-skill" "catalog tail"
            Assert-FileContains $catalogA (Get-CountLabel 3) "catalog count after B"
            $rowsB = Read-JsonArray (Join-Path $repoA "skills-pack\MANIFEST.json")
            Assert-Targets $rowsB "tail-skill" @("cursor")
            Assert-Targets $rowsB "sample-skill" @("agents", "claude")
            $bareRow = Get-ManifestRow $rowsB "bare-skill"
            if ($null -ne $bareRow) { Add-Failure "bare-skill should not be in the manifest" }
        }

        Write-Host "=== scenario C: PDF failure restores pack and global ==="
        $workC = Join-Path $env:TEMP ("skills-maker-sync-C-" + [guid]::NewGuid().ToString("n"))
        $repoC = Join-Path $workC "repo"
        $homeC = Join-Path $workC "home"
        Assert-UnderTemp $repoC
        Assert-UnderTemp $homeC
        Assert-NotRealRepo $repoC
        Assert-NotRealSkillHome $homeC
        New-Item -ItemType Directory -Force -Path $repoC, $homeC | Out-Null
        Install-IncomingLib $repoC
        foreach ($box in @("agents-claude", "agents-only", "claude-only", "cursor-only")) {
            New-Item -ItemType Directory -Force -Path (Join-Path $repoC "incoming\$box") | Out-Null
        }
        $catalogC = Join-Path $repoC ("skills" + [char]0x4E00 + [char]0x89A7 + ".md")
        Write-Catalog $catalogC
        Write-SkillMd -Dir (Join-Path $repoC "skills-pack\pdf-old-skill") -Name "pdf-old-skill" -Body "OLD-PDF"
        Write-SkillMd -Dir (Home-Skill $homeC "claude" "pdf-old-skill") -Name "pdf-old-skill" -Body "OLD-PDF"
        Write-Utf8 (Join-Path $repoC "skills-pack\MANIFEST.json") @'
[
  {
    "name": "pdf-old-skill",
    "path": "pdf-old-skill/SKILL.md",
    "installTargets": ["claude"],
    "installTarget": "~/.claude/skills/pdf-old-skill/"
  }
]
'@
        Write-SkillMd -Dir (Join-Path $repoC "incoming\claude-only\pdf-old-skill") -Name "pdf-old-skill" -Body "NEW-PDF" -Catalog -Summary "pdf old" -When "pdf failure restores"
        Write-SkillMd -Dir (Join-Path $repoC "incoming\agents-only\pdf-new-skill") -Name "pdf-new-skill" -Body "NEW-PDF-SKILL" -Catalog -Summary "pdf new" -When "pdf failure deletes new copies"
        Write-Utf8 (Join-Path $repoC "home-path.txt") ($homeC + "`n")
        Write-Utf8 (Join-Path $repoC "scripts\generate_skills_catalog_pdf.py") @'
from pathlib import Path
import sys

root = Path(__file__).resolve().parent.parent
home = Path((root / "home-path.txt").read_text(encoding="utf-8").strip())

def flag(path, needle):
    if not path.exists():
        return "ABSENT"
    text = path.read_text(encoding="utf-8")
    if needle in text:
        return "NEW"
    return "OLD"

parts = [
    "pack-old=" + flag(root / "skills-pack" / "pdf-old-skill" / "SKILL.md", "NEW-PDF"),
    "global-old=" + flag(home / ".claude" / "skills" / "pdf-old-skill" / "SKILL.md", "NEW-PDF"),
    "agents-old=" + flag(home / ".agents" / "skills" / "pdf-old-skill" / "SKILL.md", "NEW-PDF"),
    "cursor-old=" + flag(home / ".cursor" / "skills" / "pdf-old-skill" / "SKILL.md", "NEW-PDF"),
    "pack-new=" + flag(root / "skills-pack" / "pdf-new-skill" / "SKILL.md", "NEW-PDF-SKILL"),
    "global-new=" + flag(home / ".agents" / "skills" / "pdf-new-skill" / "SKILL.md", "NEW-PDF-SKILL"),
    "cursor-new=" + flag(home / ".cursor" / "skills" / "pdf-new-skill" / "SKILL.md", "NEW-PDF-SKILL"),
]
with (root / "pdf-was-called.txt").open("a", encoding="utf-8") as handle:
    handle.write(" ".join(parts) + "\n")
sys.exit(1)
'@
        $manifestC = Join-Path $repoC "skills-pack\MANIFEST.json"
        $hashManifestC = (Get-FileHash -LiteralPath $manifestC -Algorithm SHA256).Hash
        $hashCatalogC = (Get-FileHash -LiteralPath $catalogC -Algorithm SHA256).Hash
        Write-Host "workC=$workC"
        $resultC = Invoke-Sync -ScriptPath $syncScript -ScriptArgs @("-RepoRoot", $repoC, "-HomeRoot", $homeC)
        Show-Result "scenario-C" $resultC
        if ($resultC.ExitCode -eq 0) { Add-Failure "scenario C should exit non-zero" }
        $blobC = [string]$resultC.Stdout + "`n" + [string]$resultC.Stderr
        if ($blobC.Contains($realManifest)) { Add-Failure "scenario C output mentions the real MANIFEST" }
        $pdfLog = Join-Path $repoC "pdf-was-called.txt"
        Assert-FileContains $pdfLog "pack-old=NEW" "pdf log pack old copied"
        Assert-FileContains $pdfLog "global-old=NEW" "pdf log global old copied"
        Assert-FileContains $pdfLog "pack-new=NEW" "pdf log pack new copied"
        Assert-FileContains $pdfLog "global-new=NEW" "pdf log global new copied"
        Assert-FileNotContains $pdfLog "agents-old=NEW" "pdf log agents old"
        Assert-FileNotContains $pdfLog "cursor-old=NEW" "pdf log cursor old"
        Assert-FileNotContains $pdfLog "cursor-new=NEW" "pdf log cursor new"
        Assert-FileContains (Join-Path $repoC "skills-pack\pdf-old-skill\SKILL.md") "OLD-PDF" "pack pdf-old restored"
        Assert-FileNotContains (Join-Path $repoC "skills-pack\pdf-old-skill\SKILL.md") "NEW-PDF" "pack pdf-old new body"
        Assert-FileContains (Join-Path (Home-Skill $homeC "claude" "pdf-old-skill") "SKILL.md") "OLD-PDF" "global pdf-old restored"
        Assert-FileNotContains (Join-Path (Home-Skill $homeC "claude" "pdf-old-skill") "SKILL.md") "NEW-PDF" "global pdf-old new body"
        Assert-Absent (Join-Path $repoC "skills-pack\pdf-new-skill") "pack pdf-new removed"
        Assert-Absent (Home-Skill $homeC "agents" "pdf-new-skill") "global pdf-new removed"
        Assert-Absent (Home-Skill $homeC "claude" "pdf-new-skill") "claude pdf-new"
        Assert-Absent (Home-Skill $homeC "cursor" "pdf-new-skill") "cursor pdf-new"
        Assert-Absent (Home-Skill $homeC "agents" "pdf-old-skill") "agents pdf-old"
        Assert-FileContains (Join-Path $repoC "incoming\claude-only\pdf-old-skill\SKILL.md") "NEW-PDF" "pdf-old inbox"
        Assert-FileContains (Join-Path $repoC "incoming\agents-only\pdf-new-skill\SKILL.md") "NEW-PDF-SKILL" "pdf-new inbox"
        $hashManifestAfter = (Get-FileHash -LiteralPath $manifestC -Algorithm SHA256).Hash
        $hashCatalogAfter = (Get-FileHash -LiteralPath $catalogC -Algorithm SHA256).Hash
        if ($hashManifestAfter -ne $hashManifestC) { Add-Failure "scenario C manifest was not restored" }
        if ($hashCatalogAfter -ne $hashCatalogC) { Add-Failure "scenario C catalog was not restored" }

        Write-Host "=== scenario D: stale global root removed after box change ==="
        $workD = Join-Path $env:TEMP ("skills-maker-sync-D-" + [guid]::NewGuid().ToString("n"))
        $repoD = Join-Path $workD "repo"
        $homeD = Join-Path $workD "home"
        Assert-UnderTemp $repoD
        Assert-UnderTemp $homeD
        Assert-NotRealRepo $repoD
        Assert-NotRealSkillHome $homeD
        New-Item -ItemType Directory -Force -Path $repoD, $homeD | Out-Null
        Install-IncomingLib $repoD
        foreach ($box in @("agents-claude", "agents-only", "claude-only", "cursor-only")) {
            New-Item -ItemType Directory -Force -Path (Join-Path $repoD "incoming\$box") | Out-Null
        }
        $catalogD = Join-Path $repoD ("skills" + [char]0x4E00 + [char]0x89A7 + ".md")
        Write-Catalog $catalogD
        Write-SkillMd -Dir (Join-Path $repoD "skills-pack\stale-root-skill") -Name "stale-root-skill" -Body "PACK-BEFORE"
        Write-SkillMd -Dir (Home-Skill $homeD "claude" "stale-root-skill") -Name "stale-root-skill" -Body "CLAUDE-STALE" -Catalog -Summary "was claude" -When "stale root"
        Write-Utf8 (Join-Path (Home-Skill $homeD "claude" "stale-root-skill") "claude-only.txt") "CLAUDE-ONLY-FILE`n"
        Write-Utf8 (Join-Path $repoD "skills-pack\MANIFEST.json") @'
[
  {
    "name": "stale-root-skill",
    "path": "stale-root-skill/SKILL.md",
    "installTargets": ["claude"],
    "installTarget": "~/.claude/skills/stale-root-skill/"
  }
]
'@
        Write-SkillMd -Dir (Join-Path $repoD "incoming\agents-only\stale-root-skill") -Name "stale-root-skill" -Body "AGENTS-ONLY-BODY" -Catalog -Summary "agents only now" -When "remove claude root"
        Write-Utf8 (Join-Path $repoD "incoming\agents-only\stale-root-skill\agents-extra.txt") "AGENTS-EXTRA`n"
        Write-Host "workD=$workD"
        $resultD = Invoke-Sync -ScriptPath $syncScript -ScriptArgs @("-RepoRoot", $repoD, "-HomeRoot", $homeD, "-SkipPdf")
        Show-Result "scenario-D" $resultD
        if ($resultD.ExitCode -ne 0) { Add-Failure "scenario D exit $($resultD.ExitCode)" }
        Assert-Absent (Home-Skill $homeD "claude" "stale-root-skill") "claude stale-root-skill removed"
        Assert-Exists (Join-Path (Home-Skill $homeD "agents" "stale-root-skill") "SKILL.md") "agents stale-root-skill"
        Assert-FileContains (Join-Path (Home-Skill $homeD "agents" "stale-root-skill") "SKILL.md") "AGENTS-ONLY-BODY" "agents stale body"
        Assert-FileContains (Join-Path (Home-Skill $homeD "agents" "stale-root-skill") "agents-extra.txt") "AGENTS-EXTRA" "agents stale extra"
        Assert-Absent (Home-Skill $homeD "cursor" "stale-root-skill") "cursor stale-root-skill"
        Assert-FileContains (Join-Path $repoD "skills-pack\stale-root-skill\SKILL.md") "AGENTS-ONLY-BODY" "pack stale-root-skill updated"
        Assert-Absent (Join-Path $repoD "incoming\agents-only\stale-root-skill") "stale-root inbox"
        $rowsD = Read-JsonArray (Join-Path $repoD "skills-pack\MANIFEST.json")
        Assert-Targets $rowsD "stale-root-skill" @("agents")

        Write-Host "=== scenario E: name mismatch only ==="
        $workE0 = Join-Path $env:TEMP ("skills-maker-sync-E0-" + [guid]::NewGuid().ToString("n"))
        $repoE0 = Join-Path $workE0 "repo"
        $homeE0 = Join-Path $workE0 "home"
        Assert-UnderTemp $repoE0
        Assert-UnderTemp $homeE0
        Assert-NotRealRepo $repoE0
        Assert-NotRealSkillHome $homeE0
        New-Item -ItemType Directory -Force -Path $repoE0, $homeE0 | Out-Null
        Install-IncomingLib $repoE0
        foreach ($box in @("agents-claude", "agents-only", "claude-only", "cursor-only")) {
            New-Item -ItemType Directory -Force -Path (Join-Path $repoE0 "incoming\$box") | Out-Null
        }
        Write-Catalog (Join-Path $repoE0 ("skills" + [char]0x4E00 + [char]0x89A7 + ".md"))
        Write-SkillMd -Dir (Join-Path $repoE0 "incoming\agents-only\inbox-wrong-name") -Name "canonical-skill-name" -Body "MISMATCH-BODY" -Catalog -Summary "wrong folder" -When "name mismatch"
        $resultE0 = Invoke-Sync -ScriptPath $syncScript -ScriptArgs @("-RepoRoot", $repoE0, "-HomeRoot", $homeE0, "-SkipPdf")
        Show-Result "scenario-E0" $resultE0
        if ($resultE0.ExitCode -eq 0) { Add-Failure "scenario E0 should exit non-zero" }
        Assert-FileContains (Join-Path $repoE0 "incoming\agents-only\inbox-wrong-name\SKILL.md") "MISMATCH-BODY" "mismatch inbox"
        Assert-Absent (Join-Path $repoE0 "skills-pack\canonical-skill-name") "mismatch pack"
        Assert-Absent (Home-Skill $homeE0 "agents" "canonical-skill-name") "mismatch agents"

        Write-Host "=== scenario E: name mismatch stays, valid skill continues ==="
        Write-SkillMd -Dir (Join-Path $repoE0 "incoming\cursor-only\after-name-mismatch-skill") -Name "after-name-mismatch-skill" -Body "AFTER-MISMATCH" -Catalog -Summary "continues after name mismatch" -When "valid after mismatch"
        $catalogE0 = Join-Path $repoE0 ("skills" + [char]0x4E00 + [char]0x89A7 + ".md")
        $resultE1 = Invoke-Sync -ScriptPath $syncScript -ScriptArgs @("-RepoRoot", $repoE0, "-HomeRoot", $homeE0, "-SkipPdf")
        Show-Result "scenario-E1" $resultE1
        if ($resultE1.ExitCode -eq 0) { Add-Failure "scenario E1 should exit non-zero" }
        Assert-FileContains (Join-Path $repoE0 "incoming\agents-only\inbox-wrong-name\SKILL.md") "MISMATCH-BODY" "mismatch inbox after partial sync"
        Assert-Absent (Join-Path $repoE0 "skills-pack\canonical-skill-name") "mismatch pack after partial sync"
        Assert-Absent (Join-Path $repoE0 "incoming\cursor-only\after-name-mismatch-skill") "after-name-mismatch inbox"
        Assert-FileContains (Join-Path $repoE0 "skills-pack\after-name-mismatch-skill\SKILL.md") "AFTER-MISMATCH" "pack after-name-mismatch"
        Assert-FileContains (Join-Path (Home-Skill $homeE0 "cursor" "after-name-mismatch-skill") "SKILL.md") "AFTER-MISMATCH" "cursor after-name-mismatch"
        Assert-FileContains $catalogE0 "/after-name-mismatch-skill" "catalog after-name-mismatch"
        Assert-FileNotContains $catalogE0 "/canonical-skill-name" "catalog mismatch name"

        Write-Host "=== scenario F: categorized pack copy becomes flat; claude overlay ==="
        $workF = Join-Path $env:TEMP ("skills-maker-sync-F-" + [guid]::NewGuid().ToString("n"))
        $repoF = Join-Path $workF "repo"
        $homeF = Join-Path $workF "home"
        Assert-UnderTemp $repoF
        Assert-UnderTemp $homeF
        Assert-NotRealRepo $repoF
        Assert-NotRealSkillHome $homeF
        New-Item -ItemType Directory -Force -Path $repoF, $homeF | Out-Null
        Install-IncomingLib $repoF
        foreach ($box in @("agents-claude", "agents-only", "claude-only", "cursor-only")) {
            New-Item -ItemType Directory -Force -Path (Join-Path $repoF "incoming\$box") | Out-Null
        }
        $catalogF = Join-Path $repoF ("skills" + [char]0x4E00 + [char]0x89A7 + ".md")
        Write-Catalog $catalogF
        Write-SkillMd -Dir (Join-Path $repoF "skills-pack\superpowers\sample-skill") -Name "sample-skill" -Body "OLD-CAT-BODY"
        Write-SkillMd -Dir (Join-Path $repoF "skills-pack\superpowers\kept-sibling") -Name "kept-sibling" -Body "SIBLING-BODY"
        Write-SkillMd -Dir (Join-Path $repoF "skills-pack\_claude\sample-skill") -Name "sample-skill" -Body "OVERLAY-SKILL-TEXT"
        Write-Utf8 (Join-Path $repoF "skills-pack\_claude\sample-skill\overlay-only.txt") "OVERLAY-ONLY`n"
        Write-Utf8 (Join-Path $repoF "skills-pack\MANIFEST.json") @'
[
  {
    "name": "kept-sibling",
    "path": "superpowers/kept-sibling/SKILL.md",
    "installTargets": ["agents", "claude"],
    "installTarget": "~/.agents/skills/kept-sibling/"
  },
  {
    "name": "sample-skill",
    "path": "superpowers/sample-skill/SKILL.md",
    "installTargets": ["claude"],
    "installTarget": "~/.claude/skills/sample-skill/"
  }
]
'@
        Write-SkillMd -Dir (Join-Path $repoF "incoming\agents-claude\sample-skill") -Name "sample-skill" -Body "BASE-SKILL-TEXT" -Catalog -Summary "flat replace" -When "categorized skill becomes flat"
        Write-Utf8 (Join-Path $repoF "incoming\agents-claude\sample-skill\extra.txt") "BASE-EXTRA`n"
        Write-Host "workF=$workF"
        $resultF = Invoke-Sync -ScriptPath $syncScript -ScriptArgs @("-RepoRoot", $repoF, "-HomeRoot", $homeF, "-SkipPdf")
        Show-Result "scenario-F" $resultF
        if ($resultF.ExitCode -ne 0) { Add-Failure "scenario F exit $($resultF.ExitCode)" }
        $blobF = [string]$resultF.Stdout + "`n" + [string]$resultF.Stderr
        if ($blobF.Contains($realManifest)) { Add-Failure "scenario F output mentions the real MANIFEST" }
        Assert-Absent (Join-Path $repoF "skills-pack\superpowers\sample-skill") "categorized sample-skill removed"
        Assert-FileContains (Join-Path $repoF "skills-pack\superpowers\kept-sibling\SKILL.md") "SIBLING-BODY" "sibling skill kept"
        Assert-FileContains (Join-Path $repoF "skills-pack\sample-skill\SKILL.md") "BASE-SKILL-TEXT" "flat sample-skill"
        Assert-FileNotContains (Join-Path $repoF "skills-pack\sample-skill\SKILL.md") "OLD-CAT-BODY" "flat sample-skill old body"
        Assert-FileNotContains (Join-Path $repoF "skills-pack\sample-skill\SKILL.md") "OVERLAY-SKILL-TEXT" "flat sample-skill is not the overlay"
        Assert-FileContains (Join-Path $repoF "skills-pack\sample-skill\extra.txt") "BASE-EXTRA" "flat sample extra"
        Assert-FileContains (Join-Path $repoF "skills-pack\_claude\sample-skill\SKILL.md") "OVERLAY-SKILL-TEXT" "overlay source kept"
        Assert-Absent (Join-Path $repoF "incoming\agents-claude\sample-skill") "sample-skill inbox after F"
        Assert-FileContains (Join-Path (Home-Skill $homeF "agents" "sample-skill") "SKILL.md") "BASE-SKILL-TEXT" "agents base skill text"
        Assert-FileNotContains (Join-Path (Home-Skill $homeF "agents" "sample-skill") "SKILL.md") "OVERLAY-SKILL-TEXT" "agents is not overlay"
        Assert-FileContains (Join-Path (Home-Skill $homeF "agents" "sample-skill") "extra.txt") "BASE-EXTRA" "agents base extra"
        Assert-Absent (Join-Path (Home-Skill $homeF "agents" "sample-skill") "overlay-only.txt") "agents overlay-only file"
        Assert-FileContains (Join-Path (Home-Skill $homeF "claude" "sample-skill") "SKILL.md") "OVERLAY-SKILL-TEXT" "claude overlay skill text"
        Assert-FileNotContains (Join-Path (Home-Skill $homeF "claude" "sample-skill") "SKILL.md") "BASE-SKILL-TEXT" "claude overlay replaced base"
        Assert-FileContains (Join-Path (Home-Skill $homeF "claude" "sample-skill") "extra.txt") "BASE-EXTRA" "claude kept base extra"
        Assert-FileContains (Join-Path (Home-Skill $homeF "claude" "sample-skill") "overlay-only.txt") "OVERLAY-ONLY" "claude overlay-only file"
        Assert-Absent (Home-Skill $homeF "cursor" "sample-skill") "cursor sample-skill"
        $rowsF = Read-JsonArray (Join-Path $repoF "skills-pack\MANIFEST.json")
        $sampleRowsF = @($rowsF | Where-Object { $_.name -eq "sample-skill" })
        if ($sampleRowsF.Count -ne 1) {
            Add-Failure "sample-skill manifest count $($sampleRowsF.Count)"
        }
        else {
            if ([string]$sampleRowsF[0].path -ne "sample-skill/SKILL.md") {
                Add-Failure "sample-skill path $($sampleRowsF[0].path)"
            }
            if ([string]$sampleRowsF[0].installTarget -ne "~/.agents/skills/sample-skill/") {
                Add-Failure "sample-skill installTarget was not regenerated"
            }
        }
        Assert-Targets $rowsF "sample-skill" @("agents", "claude")
        Assert-Targets $rowsF "kept-sibling" @("agents", "claude")
        $siblingRowsF = @($rowsF | Where-Object { $_.name -eq "kept-sibling" })
        if ($siblingRowsF.Count -ne 1) {
            Add-Failure "kept-sibling manifest count $($siblingRowsF.Count)"
        }
        elseif ([string]$siblingRowsF[0].path -ne "superpowers/kept-sibling/SKILL.md") {
            Add-Failure "kept-sibling path $($siblingRowsF[0].path)"
        }
        Assert-FileContains $catalogF "/sample-skill" "catalog sample after F"
        Assert-FileNotContains $catalogF "/kept-sibling" "catalog sibling not added by this sync"

        Write-Host "=== scenario G: failure restores categorized dir and flat dest ==="
        $workG = Join-Path $env:TEMP ("skills-maker-sync-G-" + [guid]::NewGuid().ToString("n"))
        $repoG = Join-Path $workG "repo"
        $homeG = Join-Path $workG "home"
        Assert-UnderTemp $repoG
        Assert-UnderTemp $homeG
        Assert-NotRealRepo $repoG
        Assert-NotRealSkillHome $homeG
        New-Item -ItemType Directory -Force -Path $repoG, $homeG | Out-Null
        Install-IncomingLib $repoG
        foreach ($box in @("agents-claude", "agents-only", "claude-only", "cursor-only")) {
            New-Item -ItemType Directory -Force -Path (Join-Path $repoG "incoming\$box") | Out-Null
        }
        $catalogG = Join-Path $repoG ("skills" + [char]0x4E00 + [char]0x89A7 + ".md")
        Write-Catalog $catalogG
        Write-SkillMd -Dir (Join-Path $repoG "skills-pack\superpowers\categorized-fail-skill") -Name "categorized-fail-skill" -Body "OLD-CAT"
        Write-SkillMd -Dir (Join-Path $repoG "skills-pack\superpowers\kept-sibling") -Name "kept-sibling" -Body "SIBLING-BODY"
        Write-Utf8 (Join-Path $repoG "skills-pack\MANIFEST.json") @'
[
  {
    "name": "kept-sibling",
    "path": "superpowers/kept-sibling/SKILL.md",
    "installTargets": ["claude"],
    "installTarget": "~/.claude/skills/kept-sibling/"
  },
  {
    "name": "categorized-fail-skill",
    "path": "superpowers/categorized-fail-skill/SKILL.md",
    "installTargets": ["claude"],
    "installTarget": "~/.claude/skills/categorized-fail-skill/"
  }
]
'@
        Write-SkillMd -Dir (Join-Path $repoG "incoming\claude-only\categorized-fail-skill") -Name "categorized-fail-skill" -Body "NEW-FAIL" -Catalog -Summary "fail restore" -When "pdf failure restores categorized copy"
        Write-Utf8 (Join-Path $repoG "home-path.txt") ($homeG + "`n")
        Write-Utf8 (Join-Path $repoG "scripts\generate_skills_catalog_pdf.py") @'
from pathlib import Path
import sys

root = Path(__file__).resolve().parent.parent
home = Path((root / "home-path.txt").read_text(encoding="utf-8").strip())

def flag(path, needle):
    if not path.exists():
        return "ABSENT"
    text = path.read_text(encoding="utf-8")
    if needle in text:
        return "NEW"
    return "OLD"

cat = root / "skills-pack" / "superpowers" / "categorized-fail-skill" / "SKILL.md"
flat = root / "skills-pack" / "categorized-fail-skill" / "SKILL.md"
sib = root / "skills-pack" / "superpowers" / "kept-sibling" / "SKILL.md"
global_skill = home / ".claude" / "skills" / "categorized-fail-skill" / "SKILL.md"
parts = [
    "cat=" + ("ABSENT" if not cat.exists() else "PRESENT"),
    "flat=" + flag(flat, "NEW-FAIL"),
    "sib=" + flag(sib, "SIBLING-BODY"),
    "global=" + flag(global_skill, "NEW-FAIL"),
]
(root / "pdf-was-called.txt").write_text(" ".join(parts) + "\n", encoding="utf-8")
sys.exit(1)
'@
        $manifestG = Join-Path $repoG "skills-pack\MANIFEST.json"
        $hashManifestG = (Get-FileHash -LiteralPath $manifestG -Algorithm SHA256).Hash
        $hashCatalogG = (Get-FileHash -LiteralPath $catalogG -Algorithm SHA256).Hash
        Write-Host "workG=$workG"
        $resultG = Invoke-Sync -ScriptPath $syncScript -ScriptArgs @("-RepoRoot", $repoG, "-HomeRoot", $homeG)
        Show-Result "scenario-G" $resultG
        if ($resultG.ExitCode -eq 0) { Add-Failure "scenario G should exit non-zero" }
        $blobG = [string]$resultG.Stdout + "`n" + [string]$resultG.Stderr
        if ($blobG.Contains($realManifest)) { Add-Failure "scenario G output mentions the real MANIFEST" }
        $pdfLogG = Join-Path $repoG "pdf-was-called.txt"
        Assert-FileContains $pdfLogG "cat=ABSENT" "pdf log categorized removed before failure"
        Assert-FileContains $pdfLogG "flat=NEW" "pdf log flat copied before failure"
        Assert-FileContains $pdfLogG "sib=NEW" "pdf log sibling still present"
        Assert-FileContains $pdfLogG "global=NEW" "pdf log claude copied before failure"
        Assert-FileContains (Join-Path $repoG "skills-pack\superpowers\categorized-fail-skill\SKILL.md") "OLD-CAT" "categorized restored"
        Assert-FileNotContains (Join-Path $repoG "skills-pack\superpowers\categorized-fail-skill\SKILL.md") "NEW-FAIL" "categorized restored without new body"
        Assert-Absent (Join-Path $repoG "skills-pack\categorized-fail-skill") "flat dest deleted after failure"
        Assert-FileContains (Join-Path $repoG "skills-pack\superpowers\kept-sibling\SKILL.md") "SIBLING-BODY" "sibling after failed sync"
        Assert-Absent (Home-Skill $homeG "claude" "categorized-fail-skill") "claude restored away"
        Assert-Absent (Home-Skill $homeG "agents" "categorized-fail-skill") "agents fail skill"
        Assert-Absent (Home-Skill $homeG "cursor" "categorized-fail-skill") "cursor fail skill"
        Assert-FileContains (Join-Path $repoG "incoming\claude-only\categorized-fail-skill\SKILL.md") "NEW-FAIL" "fail skill inbox"
        $hashManifestGAfter = (Get-FileHash -LiteralPath $manifestG -Algorithm SHA256).Hash
        $hashCatalogGAfter = (Get-FileHash -LiteralPath $catalogG -Algorithm SHA256).Hash
        if ($hashManifestGAfter -ne $hashManifestG) { Add-Failure "scenario G manifest was not restored" }
        if ($hashCatalogGAfter -ne $hashCatalogG) { Add-Failure "scenario G catalog was not restored" }
    }
}
catch {
    Add-Failure ("test harness error: " + $_.Exception.Message)
    Write-Host $_.ScriptStackTrace
}
finally {
    Restore-RealSideEffects
    foreach ($path in @($fileGuards)) {
        $backup = $guardSnap[$path].Backup
        if ($backup) { Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue }
    }
    foreach ($path in @($ytBackup.Keys)) {
        Remove-Item -LiteralPath $ytBackup[$path] -Recurse -Force -ErrorAction SilentlyContinue
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
