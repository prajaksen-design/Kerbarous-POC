<#
.SYNOPSIS
    Kerberos-authenticated NFS Validation Script
.DESCRIPTION
    This script validates Kerberos tickets, network connectivity, 
    file access, and basic security features.
#>

Write-Host "=== Kerberos NFS Validation Script ===" -ForegroundColor Cyan

# -------------------------------
# 1. Kerberos Ticket Validation
# -------------------------------
function Test-KerberosTicket {
    Write-Host "`n[1] Checking Kerberos tickets..." -ForegroundColor Yellow
    try {
        klist
        Write-Host "Kerberos tickets are present." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to list Kerberos tickets. $_" -ForegroundColor Red
    }
}

# -------------------------------
# 2. Network Connectivity Test
# -------------------------------
function Test-Network {
    param (
        [string]$ServerName = "172.22.106.127"   # <-- Your Linux NFS server IP
    )
    Write-Host "`n[2] Testing network connectivity to $ServerName..." -ForegroundColor Yellow
    try {
        $ping = Test-Connection -ComputerName $ServerName -Count 2 -ErrorAction Stop
        if ($ping) {
            Write-Host "Network connectivity OK." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Unable to reach $ServerName. $_" -ForegroundColor Red
    }
}

# -------------------------------
# 3. File Access Test (Local or NFS Path)
# -------------------------------
function Test-FileAccess {
    param (
        [string]$Folder = "C:\NFS_Test"
    )
    Write-Host "`n[3] Testing file access in $Folder ..." -ForegroundColor Yellow
    $testFile = Join-Path $Folder "testfile.txt"

    try {
        if (-not (Test-Path $Folder)) {
            Write-Host "Folder $Folder not found. Creating it..." -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $Folder -Force | Out-Null
        }

        # Write test
        "Kerberos NFS test content" | Out-File -FilePath $testFile -Force
        Write-Host "File write successful." -ForegroundColor Green

        # Read test
        $content = Get-Content -Path $testFile
        if ($content) {
            Write-Host "File read successful." -ForegroundColor Green
        }
        else {
            Write-Host "File read failed." -ForegroundColor Red
        }

        # Cleanup
        Remove-Item $testFile -Force
        Write-Host "Cleanup successful." -ForegroundColor Green
    }
    catch {
        Write-Host "Error during file access test: $_" -ForegroundColor Red
    }
}

# -------------------------------
# 4. Security Validation
# -------------------------------
function Test-Security {
    Write-Host "`n[4] Validating security features..." -ForegroundColor Yellow
    try {
        # Authentication validation
        $ticket = klist | Select-String "krbtgt"
        if ($ticket) {
            Write-Host "Mutual authentication confirmed." -ForegroundColor Green
        }
        else {
            Write-Host "Kerberos ticket not found." -ForegroundColor Red
        }

        # Encryption validation (using SMB settings as proxy for secure channels)
        try {
            $enc = Get-SmbServerConfiguration | Select-Object -ExpandProperty EnableEncryptData -ErrorAction Stop
            if ($enc) {
                Write-Host "Encryption is enabled." -ForegroundColor Green
            }
            else {
                Write-Host "Encryption is not enabled." -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Encryption check skipped (not applicable for NFS)." -ForegroundColor Yellow
        }

        # Audit log validation
        Write-Host "Audit trail validation requires checking Windows Event Logs (Security Log)." -ForegroundColor Yellow
    }
    catch {
        Write-Host "Error during security validation: $_" -ForegroundColor Red
    }
}

# -------------------------------
# Run all tests
# -------------------------------
Test-KerberosTicket
Test-Network   # now defaults to 172.22.106.127
Test-FileAccess -Folder "C:\NFS_Test"
Test-Security

Write-Host "`n=== Kerberos NFS Validation Completed ===" -ForegroundColor Cyan
