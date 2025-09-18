<#
.SYNOPSIS
    Kerberos NFS Server Setup with Profile-based Permissions
.DESCRIPTION
    Sets up NFS server environment with AD group integration for the PoC
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ProfilesFile = ".\profiles.json",
    
    [string]$DefaultShareRoot = "C:\NFS",
    
    [string]$DomainName = "arya.ai"
)

Write-Host "=== KERBEROS NFS SERVER SETUP (Profile-based) ===" -ForegroundColor Green
Write-Host "Domain: $DomainName" -ForegroundColor Yellow
Write-Host "Share Root: $DefaultShareRoot" -ForegroundColor Yellow

# Ensure admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

# Create default root directory
if (!(Test-Path $DefaultShareRoot)) {
    Write-Host "Creating share root directory: $DefaultShareRoot" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $DefaultShareRoot -Force | Out-Null
}

# Verify profiles file exists
if (-not (Test-Path $ProfilesFile)) {
    Write-Error "Profiles file not found: $ProfilesFile"
    exit 1
}

# Load profiles
Write-Host "Loading profiles from: $ProfilesFile" -ForegroundColor Cyan
$profiles = Get-Content $ProfilesFile -Raw | ConvertFrom-Json

# Create log file
$logFile = Join-Path $DefaultShareRoot "demo-log.txt"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
@"
=== Kerberos NFS Server Setup Log ===
Timestamp: $timestamp
Domain: $DomainName
Profiles Loaded: $($profiles.Count)

"@ | Out-File $logFile -Force

# Function to map permissions
function Get-FileSystemRights {
    param($perm)
    switch ($perm.ToLower()) {
        "read" { return [System.Security.AccessControl.FileSystemRights]::ReadAndExecute }
        "modify" { return [System.Security.AccessControl.FileSystemRights]::Modify }
        "fullcontrol" { return [System.Security.AccessControl.FileSystemRights]::FullControl }
        default { return [System.Security.AccessControl.FileSystemRights]::ReadAndExecute }
    }
}

# Process each profile
foreach ($profile in $profiles) {
    $shareName = $profile.ShareName
    $sharePath = $profile.Path
    $adGroup = $profile.ADGroup
    $permission = $profile.Permission
    
    Write-Host "`nProcessing: $shareName" -ForegroundColor Cyan
    Write-Host "  Path: $sharePath" -ForegroundColor Gray
    Write-Host "  Group: $adGroup" -ForegroundColor Gray
    Write-Host "  Permission: $permission" -ForegroundColor Gray
    
    # Create share directory
    if (!(Test-Path $sharePath)) {
        New-Item -ItemType Directory -Path $sharePath -Force | Out-Null
        Write-Host "  ✅ Directory created" -ForegroundColor Green
    } else {
        Write-Host "  ✅ Directory exists" -ForegroundColor Green
    }
    
    # Create sample files for demo
    switch ($shareName.ToLower()) {
        "finance" {
            $sampleContent = @"
FINANCE DEPARTMENT - CONFIDENTIAL
================================
Budget Report Q4 2024
Revenue: $2.5M
Expenses: $1.8M
Profit: $0.7M

Access restricted to Finance-Users group only.
"@
            $sampleContent | Out-File (Join-Path $sharePath "budget_report.txt") -Force
        }
        
        "hr" {
            $sampleContent = @"
HUMAN RESOURCES - CONFIDENTIAL
==============================
Employee Handbook 2024
Policy Updates:
- Remote work guidelines updated
- PTO policy revised
- Security training mandatory

Access restricted to HR-Users group only.
"@
            $sampleContent | Out-File (Join-Path $sharePath "employee_handbook.txt") -Force
        }
        
        "public" {
            $sampleContent = @"
PUBLIC SHARE - READ ONLY
========================
Welcome to the public information share.
This area contains:
- Company announcements
- General policies  
- Public documents

All domain users have read access.
"@
            $sampleContent | Out-File (Join-Path $sharePath "README.txt") -Force
        }
    }
    
    # Log the setup
    $logEntry = "[$timestamp] SETUP: $shareName -> $sharePath | Group: $adGroup | Permission: $permission"
    $logEntry | Out-File $logFile -Append
}

# Simulate Kerberos configuration
Write-Host "`n🔐 Kerberos Configuration (Simulated):" -ForegroundColor Cyan
Write-Host "  Realm: $($DomainName.ToUpper())" -ForegroundColor Green
Write-Host "  KDC: kdc.$DomainName" -ForegroundColor Green
Write-Host "  Service Principal: nfs/$(hostname)@$($DomainName.ToUpper())" -ForegroundColor Green
Write-Host "  Encryption: AES256 (krb5p)" -ForegroundColor Green

# Simulate NFS service status
Write-Host "`n📡 NFS Service Status (Simulated):" -ForegroundColor Cyan
Write-Host "  Server Status: Running" -ForegroundColor Green
Write-Host "  Authentication: Kerberos Required" -ForegroundColor Green
Write-Host "  Security: krb5p (Privacy/Encryption)" -ForegroundColor Green

# Show detected Windows features
$hasNfs = (Get-Command Get-NfsShare -ErrorAction SilentlyContinue) -ne $null
$hasSmb = (Get-Command Get-SmbShare -ErrorAction SilentlyContinue) -ne $null

Write-Host "`n🛠️ Windows Features:" -ForegroundColor Cyan
Write-Host "  NFS Server cmdlets: $(if($hasNfs){'Available'}else{'Not Available'})" -ForegroundColor $(if($hasNfs){'Green'}else{'Yellow'})
Write-Host "  SMB Server cmdlets: $(if($hasSmb){'Available'}else{'Not Available'})" -ForegroundColor $(if($hasSmb){'Green'}else{'Yellow'})

if (-not $hasNfs -and -not $hasSmb) {
    Write-Host "  Note: Install NFS or SMB features for full functionality" -ForegroundColor Yellow
}

Write-Host "`n📊 Setup Summary:" -ForegroundColor Cyan
Write-Host "  Shares configured: $($profiles.Count)" -ForegroundColor Green
Write-Host "  Log file: $logFile" -ForegroundColor Green
Write-Host "  Ready for permission application" -ForegroundColor Green

Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Run: .\apply-permission.ps1 -DomainName $DomainName" -ForegroundColor White
Write-Host "  2. Test: .\demo-user-access.ps1 -UserType finance" -ForegroundColor White
Write-Host "  3. Demo: .\run-full-demo.ps1" -ForegroundColor White

Write-Host "`n=== SERVER SETUP COMPLETE ===" -ForegroundColor Green