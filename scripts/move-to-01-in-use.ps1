# skills-maker を、リポジトリ親直下の 01_in-use/skills-maker へ移動する。
# パスは $PSScriptRoot から解決する（ドライブ文字付きの絶対パスは書かない）。
# Cursor / VS Code でこのリポジトリを開いていると「使用中」で失敗する。
# 手順: ワークスペースを閉じる → このスクリプト実行 → 新パスで開き直す。

$ErrorActionPreference = "Stop"
$src = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$parent = Split-Path -LiteralPath $src -Parent
$leaf = Split-Path -LiteralPath $src -Leaf
$dstParent = Join-Path $parent "01_in-use"
$dst = Join-Path $dstParent $leaf

if ((Split-Path -LiteralPath $parent -Leaf) -eq "01_in-use") {
    Write-Host "Already at destination: $src"
    exit 0
}

if (-not (Test-Path -LiteralPath $src)) {
    Write-Error "Source not found: $src"
}

if (Test-Path -LiteralPath $dst) {
    Write-Error "Destination already exists: $dst"
}

New-Item -ItemType Directory -Force -Path $dstParent | Out-Null
Move-Item -LiteralPath $src -Destination $dst
Write-Host "OK. Reopen workspace: $dst"
