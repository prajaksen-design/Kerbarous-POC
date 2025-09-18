<#
.SYNOPSIS
    Complete Kerberos NFS PoC Demo Runner
.DESCRIPTION
    Sets up the entire PoC environment and runs validation tests
#>

param(
    [string]$DomainName = "arya.ai",
    [string]$ShareRoot = "C:\NFS"
)

$ErrorActionPreference = "Continue"

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "🚀 KERBEROS NFS POC - COMPLETE DEMO SETUP" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "Domain: $DomainName" -ForegroundColor Yellow
Write-Host "Share Root: $ShareRoot" -ForegroundColor Yellow
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Yellow

# Check admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ ERROR: Must run as Administrator" -ForegroundColor Red
    exit 1
}

Write-Host "`nStep 1: Server Setup..." -ForegroundColor Green
try {
    .\setup-nfs-server.ps1 -ProfilesFile ".\profiles.json" -DefaultShareRoot $ShareRoot
    Write-Host "✅ Server setup completed" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Server setup warning: $_" -ForegroundColor Yellow
}

Write-Host "`nStep 2: Applying Permissions..." -ForegroundColor Green
try {
    .\apply-permission.ps1 -ProfilesFile ".\profiles.json" -DomainName $DomainName
    Write-Host "✅ Permissions applied" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Permission warning: $_" -ForegroundColor Yellow
}

Write-Host "`nStep 3: Running Validation Tests..." -ForegroundColor Green
try {
    .\test-kerberos-nfs.ps1 -ServerName "localhost" -TestFolder "$ShareRoot\Finance"
    Write-Host "✅ Validation completed" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Validation warning: $_" -ForegroundColor Yellow
}

Write-Host "`nStep 4: Demo Environment Ready!" -ForegroundColor Green

# Show created structure
Write-Host "`nCreated Share Structure:" -ForegroundColor Cyan
try {
    Get-ChildItem $ShareRoot -Recurse | Format-Table Name, Mode, Length, LastWriteTime -AutoSize
} catch {
    Write-Host "Share structure will be visible after running user demos" -ForegroundColor Yellow
}

# Show profile configuration
Write-Host "`nProfile Configuration:" -ForegroundColor Cyan
try {
    Get-Content ".\profiles.json" | ConvertFrom-Json | Format-Table ShareName, ADGroup, Permission -AutoSize
} catch {
    Write-Host "Unable to display profiles.json" -ForegroundColor Yellow
}

Write-Host "`nDEMO COMMANDS:" -ForegroundColor Yellow
Write-Host "Run these to demonstrate different user access levels:" -ForegroundColor White
Write-Host ""
Write-Host "Finance User (Full Access):    .\demo-user-access.ps1 -UserType finance" -ForegroundColor Green
Write-Host "HR User (Full Access):         .\demo-user-access.ps1 -UserType hr" -ForegroundColor Green  
Write-Host "ReadOnly User (Limited):       .\demo-user-access.ps1 -UserType readonly" -ForegroundColor Green
Write-Host ""
Write-Host "View Audit Logs:               Get-Content $ShareRoot\demo-log.txt" -ForegroundColor Cyan
Write-Host "View NTFS Permissions:         Get-Acl $ShareRoot\Finance | Select -ExpandProperty Access" -ForegroundColor Cyan

Write-Host "`nMANAGER DEMO SCRIPT:" -ForegroundColor Yellow
Write-Host "# 1. Show configuration" -ForegroundColor White
Write-Host "Get-Content .\profiles.json | ConvertFrom-Json | Format-Table" -ForegroundColor White
Write-Host ""
Write-Host "# 2. Demo Finance user (success)" -ForegroundColor White
Write-Host ".\demo-user-access.ps1 -UserType finance" -ForegroundColor White
Write-Host ""
Write-Host "# 3. Demo ReadOnly user (restricted)" -ForegroundColor White
Write-Host ".\demo-user-access.ps1 -UserType readonly" -ForegroundColor White
Write-Host ""
Write-Host "# 4. Show audit trail" -ForegroundColor White
Write-Host "Get-Content $ShareRoot\demo-log.txt" -ForegroundColor White

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "🎉 POC SETUP COMPLETE - READY FOR DEMONSTRATION!" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Cyan