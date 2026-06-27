$ErrorActionPreference = "Stop"
$installer = Join-Path (Split-Path $PSScriptRoot -Parent) "skills\install.ps1"
if (-not (Test-Path $installer)) {
    Write-Error "Installer not found: $installer"
}
& $installer
