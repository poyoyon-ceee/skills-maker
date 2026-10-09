# Sync skills from the four incoming boxes into the pack, global homes,
# MANIFEST, and skills list. PDF and Excel run unless -SkipPdf is set.
# Usage: .\scripts\sync-incoming.ps1 [-RepoRoot path] [-HomeRoot path] [-SkipPdf]

param(
    [string]$RepoRoot = "",
    [string]$HomeRoot = "",
    [switch]$SkipPdf
)

$ErrorActionPreference = "Stop"
[Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
}
if ([string]::IsNullOrWhiteSpace($HomeRoot)) {
    $HomeRoot = $env:USERPROFILE
}

$env:PYTHONPATH = $RepoRoot
if (-not $env:PYTHONIOENCODING) { $env:PYTHONIOENCODING = "utf-8" }
if (-not $env:PYTHONUTF8) { $env:PYTHONUTF8 = "1" }

$boxes = @("agents-claude", "agents-only", "claude-only", "cursor-only")
$incomingRoot = Join-Path $RepoRoot "incoming"
$manifestPath = Join-Path $RepoRoot "skills-pack\MANIFEST.json"
$catalogPath = Join-Path $RepoRoot ("skills" + [char]0x4E00 + [char]0x89A7 + ".md")
$generateManifest = Join-Path $PSScriptRoot "generate-manifest.ps1"

$pyTargets = @'
import json
import sys
from pathlib import Path
from scripts.incoming_lib import targets_for_box, validate_targets

spec = json.loads(Path(__import__("os").environ["SYNC_SPEC"]).read_text(encoding="utf-8-sig"))
try:
    print(json.dumps(validate_targets(targets_for_box(spec["box"]))))
except Exception as exc:
    print(str(exc), file=sys.stderr)
    sys.exit(1)
'@

$pyManifest = @'
import json
from pathlib import Path

spec = json.loads(Path(__import__("os").environ["SYNC_SPEC"]).read_text(encoding="utf-8-sig"))
path = Path(spec["manifest"])
raw = path.read_text(encoding="utf-8-sig").strip() if path.exists() else ""
data = json.loads(raw) if raw else []
if isinstance(data, dict):
    data = [data]
name = spec["name"]
targets = json.loads(spec["targets_json"])
found = False
for row in data:
    if row.get("name") == name:
        row["installTargets"] = targets
        found = True
        break
if not found:
    data.append({
        "name": name,
        "path": name + "/SKILL.md",
        "installTargets": targets,
        "installTarget": "",
    })
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
'@

$pyCatalog = @'
import json
from pathlib import Path
from scripts.incoming_lib import upsert_catalog_row

spec = json.loads(Path(__import__("os").environ["SYNC_SPEC"]).read_text(encoding="utf-8-sig"))
path = Path(spec["catalog"])
text = path.read_text(encoding="utf-8-sig")
out = upsert_catalog_row(
    text,
    int(spec["section"]),
    spec["command"],
    spec["summary"],
    spec["when"],
)
path.write_text(out, encoding="utf-8")
'@

function New-SpecFile {
    param($Object)
    $path = Join-Path $env:TEMP ("sync-incoming-spec-" + [guid]::NewGuid().ToString("n") + ".json")
    $json = $Object | ConvertTo-Json -Compress -Depth 6
    [System.IO.File]::WriteAllText($path, $json, [System.Text.UTF8Encoding]::new($false))
    return $path
}

function Invoke-Py {
    param([string]$Code)
    $id = [guid]::NewGuid().ToString("n")
    $py = Join-Path $env:TEMP "sync-incoming-$id.py"
    $stdoutFile = Join-Path $env:TEMP "sync-incoming-$id.out"
    $stderrFile = Join-Path $env:TEMP "sync-incoming-$id.err"
    [System.IO.File]::WriteAllText($py, $Code, [System.Text.UTF8Encoding]::new($false))
    $proc = Start-Process -FilePath "python" -ArgumentList @($py) -WorkingDirectory $RepoRoot -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile
    $out = ""
    $err = ""
    if (Test-Path -LiteralPath $stdoutFile) { $out = [System.IO.File]::ReadAllText($stdoutFile) }
    if (Test-Path -LiteralPath $stderrFile) { $err = [System.IO.File]::ReadAllText($stderrFile) }
    Remove-Item -LiteralPath $py, $stdoutFile, $stderrFile -Force -ErrorAction SilentlyContinue
    if ($null -eq $proc -or $proc.ExitCode -ne 0) {
        $code = if ($proc) { $proc.ExitCode } else { -1 }
        throw "python exit ${code}: $err $out"
    }
    return $out.Trim()
}

function Invoke-PySpec {
    param([string]$Code, $Spec)
    $specPath = New-SpecFile $Spec
    try {
        $env:SYNC_SPEC = $specPath
        return Invoke-Py $Code
    }
    finally {
        Remove-Item Env:SYNC_SPEC -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $specPath -Force -ErrorAction SilentlyContinue
    }
}

function Read-Frontmatter {
    param([string]$Path)
    $text = [System.IO.File]::ReadAllText($Path)
    if ($text.Length -gt 0 -and [int][char]$text[0] -eq 0xFEFF) { $text = $text.Substring(1) }
    $match = [regex]::Match($text, "(?s)\A---\r?\n(.*?)\r?\n---")
    $map = @{}
    if (-not $match.Success) { return $map }
    foreach ($line in ($match.Groups[1].Value -split "\r?\n")) {
        $lineMatch = [regex]::Match($line, "^([A-Za-z0-9_-]+):\s*(.*)$")
        if ($lineMatch.Success) {
            $map[$lineMatch.Groups[1].Value] = $lineMatch.Groups[2].Value.Trim()
        }
    }
    return $map
}

function Get-FrontmatterScalar {
    param([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return "" }
    $v = $Raw.Trim()
    if ($v.Length -ge 2) {
        $q0 = $v[0]
        $q1 = $v[$v.Length - 1]
        if (($q0 -eq '"' -and $q1 -eq '"') -or ($q0 -eq "'" -and $q1 -eq "'")) {
            return $v.Substring(1, $v.Length - 2)
        }
    }
    return $v
}

function Get-BoxTargets {
    param([string]$Box)
    # Emit one token per pipeline object. ConvertFrom-Json plus @() nests a
    # two-element array into a single "agents claude" string on Windows PowerShell 5.1.
    $json = (Invoke-PySpec $script:pyTargets @{ box = $Box }).Trim()
    if ($json.StartsWith("[")) { $json = $json.Substring(1) }
    if ($json.EndsWith("]")) { $json = $json.Substring(0, $json.Length - 1) }
    foreach ($part in ($json -split ",")) {
        $token = $part.Trim().Trim('"')
        if (-not [string]::IsNullOrWhiteSpace($token)) { $token }
    }
}

function Format-TargetJson {
    param([string[]]$Targets)
    $parts = foreach ($token in @($Targets)) { '"' + $token + '"' }
    return "[" + ($parts -join ",") + "]"
}

function Get-GlobalDest {
    param([string]$Token, [string]$SkillName)
    switch ($Token) {
        "agents" { return Join-Path $HomeRoot ".agents\skills\$SkillName" }
        "cursor" { return Join-Path $HomeRoot ".cursor\skills\$SkillName" }
        "claude" { return Join-Path $HomeRoot ".claude\skills\$SkillName" }
        default { throw "unknown target token: $Token" }
    }
}

function Copy-SkillFolder {
    param([string]$Source, [string]$Dest)
    $parent = Split-Path -Parent $Dest
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    if (Test-Path -LiteralPath $Dest) {
        Remove-Item -LiteralPath $Dest -Recurse -Force
    }
    Copy-Item -LiteralPath $Source -Destination $Dest -Recurse -Force
}

function New-DirSnap {
    param([string]$Path, [string]$BackupRoot)
    $backup = Join-Path $BackupRoot ([guid]::NewGuid().ToString("n"))
    $existed = Test-Path -LiteralPath $Path
    if ($existed) {
        New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
        Copy-Item -LiteralPath $Path -Destination $backup -Recurse -Force
    }
    return [PSCustomObject]@{ Kind = "dir"; Path = $Path; Existed = [bool]$existed; Backup = $backup }
}

function New-FileSnap {
    param([string]$Path, [string]$BackupRoot)
    $backup = Join-Path $BackupRoot ([guid]::NewGuid().ToString("n"))
    $existed = Test-Path -LiteralPath $Path
    if ($existed) {
        New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
        Copy-Item -LiteralPath $Path -Destination $backup -Force
    }
    return [PSCustomObject]@{ Kind = "file"; Path = $Path; Existed = [bool]$existed; Backup = $backup }
}

function Restore-Snap {
    param($Snap)
    if ($Snap.Existed) {
        if (Test-Path -LiteralPath $Snap.Path) {
            Remove-Item -LiteralPath $Snap.Path -Recurse -Force
        }
        $parent = Split-Path -Parent $Snap.Path
        if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Force -Path $parent | Out-Null
        }
        if ($Snap.Kind -eq "dir") {
            Copy-Item -LiteralPath $Snap.Backup -Destination $Snap.Path -Recurse -Force
        }
        else {
            Copy-Item -LiteralPath $Snap.Backup -Destination $Snap.Path -Force
        }
    }
    elseif (Test-Path -LiteralPath $Snap.Path) {
        Remove-Item -LiteralPath $Snap.Path -Recurse -Force
    }
}

function Restore-All {
    param($Snaps)
    # Windows PowerShell 5.1 throws on @($genericList). Enumerate the list itself.
    $errors = New-Object System.Collections.Generic.List[string]
    foreach ($snap in $Snaps) {
        try { Restore-Snap $snap }
        catch { [void]$errors.Add($_.Exception.Message) }
    }
    if ($errors.Count -gt 0) {
        throw ("restore failed: " + ($errors -join "; "))
    }
}

function Test-SameDirectory {
    param([string]$Left, [string]$Right)
    $a = [System.IO.Path]::GetFullPath($Left).TrimEnd('\')
    $b = [System.IO.Path]::GetFullPath($Right).TrimEnd('\')
    return $a.Equals($b, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-DirectoryInside {
    param([string]$Parent, [string]$Child)
    if (Test-SameDirectory $Parent $Child) { return $false }
    $root = [System.IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    $full = [System.IO.Path]::GetFullPath($Child).TrimEnd('\') + '\'
    return $full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-MatchingSkillDirectories {
    param([string]$PackRoot, [string]$SkillName)
    if (-not (Test-Path -LiteralPath $PackRoot)) { return }
    $seen = @{}
    $skip = @("_hooks", "_claude")
    foreach ($top in @(Get-ChildItem -LiteralPath $PackRoot -Force -Directory)) {
        if ($skip -contains $top.Name) { continue }
        foreach ($file in @(Get-ChildItem -LiteralPath $top.FullName -Recurse -Filter "SKILL.md" -File -Force)) {
            $fm = Read-Frontmatter $file.FullName
            $declared = Get-FrontmatterScalar ([string]$fm["name"])
            if (-not [string]::Equals($declared, $SkillName, [System.StringComparison]::OrdinalIgnoreCase)) {
                continue
            }
            $dir = $file.Directory.FullName
            $key = [System.IO.Path]::GetFullPath($dir).TrimEnd('\').ToLowerInvariant()
            if ($seen.ContainsKey($key)) { continue }
            $seen[$key] = $true
            $dir
        }
    }
}

function Copy-ClaudeOverlay {
    param([string]$Source, [string]$Dest)
    if (-not (Test-Path -LiteralPath $Source)) { return }
    $prefix = [System.IO.Path]::GetFullPath($Source)
    if (-not $prefix.EndsWith('\')) { $prefix = $prefix + '\' }
    foreach ($file in @(Get-ChildItem -LiteralPath $Source -Recurse -File -Force)) {
        $full = [System.IO.Path]::GetFullPath($file.FullName)
        if (-not $full.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "overlay file escaped source: $($file.FullName)"
        }
        $rel = $full.Substring($prefix.Length)
        $destFile = Join-Path $Dest $rel
        $destParent = Split-Path -Parent $destFile
        if ($destParent -and -not (Test-Path -LiteralPath $destParent)) {
            New-Item -ItemType Directory -Force -Path $destParent | Out-Null
        }
        Copy-Item -LiteralPath $file.FullName -Destination $destFile -Force
    }
}

$anyFailure = $false
if (Test-Path -LiteralPath $incomingRoot) {
    foreach ($box in $boxes) {
        $boxDir = Join-Path $incomingRoot $box
        if (-not (Test-Path -LiteralPath $boxDir)) { continue }
        foreach ($skillDir in @(Get-ChildItem -LiteralPath $boxDir -Force -Directory)) {
            $skillMd = Join-Path $skillDir.FullName "SKILL.md"
            if (-not (Test-Path -LiteralPath $skillMd)) { continue }

            $backupRoot = Join-Path $env:TEMP ("sync-incoming-bak-" + [guid]::NewGuid().ToString("n"))
            $snaps = $null
            $committed = $false
            try {
                $fm = Read-Frontmatter $skillMd
                $declaredName = Get-FrontmatterScalar ([string]$fm["name"])
                if ([string]::IsNullOrWhiteSpace($declaredName)) {
                    throw "missing or empty frontmatter name"
                }
                if ($skillDir.Name -ne $declaredName) {
                    throw ("inbox folder name must match SKILL.md name: folder=" + $skillDir.Name + " name=" + $declaredName)
                }
                $missing = @()
                foreach ($key in @("catalog-section", "catalog-summary", "catalog-when")) {
                    if (-not $fm.ContainsKey($key) -or [string]::IsNullOrWhiteSpace([string]$fm[$key])) {
                        $missing += $key
                    }
                }
                if ($missing.Count -gt 0) {
                    throw ("missing catalog frontmatter: " + ($missing -join ", "))
                }
                if ([string]$fm["catalog-section"] -notmatch '^\d+$') {
                    throw "catalog-section is not an integer"
                }
                $section = [int]$fm["catalog-section"]
                $skillName = $declaredName
                $targets = @(Get-BoxTargets $box)
                if ($targets.Count -lt 1) { throw "no install targets for $box" }

                $snaps = New-Object System.Collections.Generic.List[object]
                $packRoot = Join-Path $RepoRoot "skills-pack"
                $packDest = Join-Path $packRoot $skillName
                $snaps.Add((New-DirSnap -Path $packDest -BackupRoot $backupRoot))
                foreach ($token in $targets) {
                    $snaps.Add((New-DirSnap -Path (Get-GlobalDest -Token $token -SkillName $skillName) -BackupRoot $backupRoot))
                }
                $snaps.Add((New-FileSnap -Path $manifestPath -BackupRoot $backupRoot))
                $snaps.Add((New-FileSnap -Path $catalogPath -BackupRoot $backupRoot))

                # Same-name copies under a category make generate-manifest exit 1.
                # Snapshot and remove those skill folders only; leave sibling skills.
                $matchedDirs = @(Get-MatchingSkillDirectories -PackRoot $packRoot -SkillName $skillName)
                foreach ($oldDir in $matchedDirs) {
                    if ([string]::IsNullOrWhiteSpace($oldDir)) { continue }
                    if (Test-SameDirectory $oldDir $packDest) { continue }
                    if (-not (Test-DirectoryInside -Parent $packRoot -Child $oldDir)) {
                        throw "refusing to remove skill dir outside skills-pack: $oldDir"
                    }
                    $insideOther = $false
                    foreach ($other in $matchedDirs) {
                        if (Test-DirectoryInside -Parent $other -Child $oldDir) { $insideOther = $true; break }
                    }
                    if ((Test-DirectoryInside -Parent $packDest -Child $oldDir) -or $insideOther) { continue }
                    $snaps.Add((New-DirSnap -Path $oldDir -BackupRoot $backupRoot))
                    Remove-Item -LiteralPath $oldDir -Recurse -Force
                }

                Copy-SkillFolder -Source $skillDir.FullName -Dest $packDest
                $targetJson = Format-TargetJson -Targets $targets
                Invoke-PySpec $script:pyManifest @{
                    manifest     = $manifestPath
                    name         = $skillName
                    targets_json = $targetJson
                } | Out-Null
                & $generateManifest -RepoRoot $RepoRoot
                if (-not $?) { throw "generate-manifest failed (exit $LASTEXITCODE)" }
                foreach ($token in $targets) {
                    $globalDest = Get-GlobalDest -Token $token -SkillName $skillName
                    Copy-SkillFolder -Source $skillDir.FullName -Dest $globalDest
                    if ($token -eq "claude") {
                        Copy-ClaudeOverlay -Source (Join-Path $packRoot "_claude\$skillName") -Dest $globalDest
                    }
                }
                foreach ($token in @("agents", "cursor", "claude")) {
                    if ($targets -contains $token) { continue }
                    $staleDest = Get-GlobalDest -Token $token -SkillName $skillName
                    if (Test-Path -LiteralPath $staleDest) {
                        $snaps.Add((New-DirSnap -Path $staleDest -BackupRoot $backupRoot))
                        Remove-Item -LiteralPath $staleDest -Recurse -Force
                    }
                }
                Invoke-PySpec $script:pyCatalog @{
                    catalog = $catalogPath
                    section = $section
                    command = $skillName
                    summary = [string]$fm["catalog-summary"]
                    when    = [string]$fm["catalog-when"]
                } | Out-Null
                if (-not $SkipPdf) {
                    $pdf = Join-Path $RepoRoot "scripts\generate_skills_catalog_pdf.py"
                    $pdfProc = Start-Process -FilePath "python" -ArgumentList @($pdf) -WorkingDirectory $RepoRoot -Wait -PassThru -WindowStyle Hidden
                    if ($null -eq $pdfProc -or $pdfProc.ExitCode -ne 0) {
                        $pdfCode = if ($pdfProc) { $pdfProc.ExitCode } else { -1 }
                        throw "PDF generation failed (exit $pdfCode)"
                    }
                    $xlsx = Join-Path $RepoRoot "scripts\export_skills_to_xlsx.py"
                    $xlsxProc = Start-Process -FilePath "python" -ArgumentList @($xlsx) -WorkingDirectory $RepoRoot -Wait -PassThru -WindowStyle Hidden
                    if ($null -eq $xlsxProc -or $xlsxProc.ExitCode -ne 0) {
                        $xlsxCode = if ($xlsxProc) { $xlsxProc.ExitCode } else { -1 }
                        throw "Excel generation failed (exit $xlsxCode)"
                    }
                }
                $committed = $true
            }
            catch {
                $detail = $_.Exception.Message
                if ($_.InvocationInfo -and $_.InvocationInfo.ScriptLineNumber) {
                    $detail += " (line " + $_.InvocationInfo.ScriptLineNumber + ")"
                }
                if ($null -ne $snaps) {
                    try { Restore-All $snaps }
                    catch { $detail += " | restore: " + $_.Exception.Message }
                }
                Write-Host ("ERROR: " + $skillDir.Name + ": " + $detail) -ForegroundColor Red
                $anyFailure = $true
            }
            finally {
                if (Test-Path -LiteralPath $backupRoot) {
                    Remove-Item -LiteralPath $backupRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
            if ($committed) {
                try {
                    Remove-Item -LiteralPath $skillDir.FullName -Recurse -Force
                    Write-Host ("synced " + $skillDir.Name)
                }
                catch {
                    Write-Host ("ERROR: " + $skillDir.Name + ": failed to remove inbox: " + $_.Exception.Message) -ForegroundColor Red
                    $anyFailure = $true
                }
            }
        }
    }
}

if ($anyFailure) {
    Write-Host "sync-incoming failed"
    exit 1
}
Write-Host "sync-incoming ok"
exit 0
