# Kerberos NFS Client Setup Script
# Run as Administrator on Windows Client

param(
    [Parameter(Mandatory=$true)]
    [string]$NFSServer,
    
    [Parameter(Mandatory=$true)]
    [string]$DomainName,
    
    [string]$ShareName = "SecureShare",
    [string]$MountPoint = "Z:"
)

Write-Host "=== Kerberos NFS Client Setup ===" -ForegroundColor Green

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

# Install NFS Client feature
Write-Host "Installing NFS Client features..." -ForegroundColor Yellow
Enable-WindowsOptionalFeature -Online -FeatureName ServicesForNFS-ClientOnly -All
Enable-WindowsOptionalFeature -Online -FeatureName ClientForNFS-Infrastructure -All

# Configure NFS client for Kerberos
Write-Host "Configuring NFS client for Kerberos authentication..." -ForegroundColor Yellow
Set-NfsClientConfiguration -Authentication Krb5,Krb5i,Krb5p -DefaultAccessMode 755

# Start NFS client services
Write-Host "Starting NFS client services..." -ForegroundColor Yellow
Start-Service -Name NfsClnt
Start-Service -Name RpcSs
Set-Service -Name NfsClnt -StartupType Automatic
Set-Service -Name RpcSs -StartupType Automatic

# Get Kerberos ticket
Write-Host "Obtaining Kerberos ticket..." -ForegroundColor Yellow
klist purge
kinit

# Mount NFS share with Kerberos authentication
Write-Host "Mounting NFS share with Kerberos authentication..." -ForegroundColor Yellow
$nfsPath = "$NFSServer`:/$ShareName"

try {
    # Unmount if already mounted
    if (Get-PSDrive -Name $MountPoint.TrimEnd(':') -ErrorAction SilentlyContinue) {
        Remove-PSDrive -Name $MountPoint.TrimEnd(':') -Force
    }
    
    # Mount with Kerberos authentication
    Mount-NfsShare -RemotePath $nfsPath -LocalPath $MountPoint -Authentication Krb5 -Persist
    
    Write-Host "Successfully mounted $nfsPath to $MountPoint" -ForegroundColor Green
    
    # Test access
    Write-Host "Testing file access..." -ForegroundColor Yellow
    Get-ChildItem $MountPoint
    
} catch {
    Write-Error "Failed to mount NFS share: $($_.Exception.Message)"
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Verify Kerberos ticket: klist" -ForegroundColor White
    Write-Host "2. Check NFS server accessibility: ping $NFSServer" -ForegroundColor White
    Write-Host "3. Verify domain membership and time sync" -ForegroundColor White
}

Write-Host "=== NFS Client Setup Complete ===" -ForegroundColor Green
Write-Host "Mounted: $nfsPath -> $MountPoint" -ForegroundColor Cyan
Write-Host "Authentication: Kerberos" -ForegroundColor Cyan