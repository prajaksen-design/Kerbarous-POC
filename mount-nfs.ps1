$DriveLetter = "C:"  # Must be A-Z
$ServerIP = "172.22.106.127"
$Share = "/export/nfsdata"

# Convert NFS path to UNC format for Windows
$UNCPath = "\\$ServerIP\$($Share.TrimStart('/').Replace('/', '$'))"

# Mount the NFS share
try {
    New-PSDrive -Name $DriveLetter.TrimEnd(':') -PSProvider FileSystem -Root $UNCPath -Persist
    Write-Host "Mount successful at $DriveLetter" -ForegroundColor Green
} catch {
    Write-Host "Failed to mount NFS share. $_" -ForegroundColor Red
}
