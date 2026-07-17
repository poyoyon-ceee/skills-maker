# Regenerate skills catalog outputs from skills一覧.md
# Usage: .\scripts\update-skills-catalog.ps1
#        .\scripts\update-skills-catalog.ps1 -Excel   # include Excel

param(
    [switch]$Excel
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

Write-Host "==> PDF catalog (System Atlas)" -ForegroundColor Cyan
python "$PSScriptRoot\generate_skills_catalog_pdf.py"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($Excel) {
    Write-Host "==> Excel spreadsheet" -ForegroundColor Cyan
    python "$PSScriptRoot\export_skills_to_xlsx.py"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "  PDF : $Root\catalog\skills-catalog-system-atlas.pdf"
if ($Excel) {
    Write-Host "  XLSX: $Root\skills一覧.xlsx"
}
