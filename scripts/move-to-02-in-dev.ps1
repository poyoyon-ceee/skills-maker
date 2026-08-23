# skills-maker を C:\Dev-App\02_in-dev\skills-maker へ移動する。
# Cursor / VS Code でこのリポジトリを開いていると「使用中」で失敗する。
# 手順: ワークスペースを閉じる → このスクリプト実行 → 新パスで開き直す。

$ErrorActionPreference = "Stop"
$src = "C:\Dev-App\skills-maker"
$dstParent = "C:\Dev-App\02_in-dev"
$dst = Join-Path $dstParent "skills-maker"

if (-not (Test-Path -LiteralPath $src)) {
    if (Test-Path -LiteralPath $dst) {
        Write-Host "Already at destination: $dst"
        exit 0
    }
    Write-Error "Source not found: $src"
}

if (Test-Path -LiteralPath $dst) {
    Write-Error "Destination already exists: $dst"
}

New-Item -ItemType Directory -Force -Path $dstParent | Out-Null
Move-Item -LiteralPath $src -Destination $dst
Write-Host "OK. Reopen workspace: $dst"
