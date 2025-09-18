param(
    [string]$ProfilesFile = ".\profiles.json",
    [string]$DomainName = (Read-Host "Enter domain name (ex: corp.example.com)")
)

if (-not (Test-Path $ProfilesFile)) {
    Write-Error "Profiles file not found: $ProfilesFile"; exit 1
}
$profiles = Get-Content $ProfilesFile -Raw | ConvertFrom-Json

# helper mapping function (same as in setup script)
function Get-FileSystemRights { param($perm) switch ($perm.ToLower()) { "read" { return [System.Security.AccessControl.FileSystemRights]::ReadAndExecute } "modify" { return [System.Security.AccessControl.FileSystemRights]::Modify } "fullcontrol" { return [System.Security.AccessControl.FileSystemRights]::FullControl } default { return [System.Security.AccessControl.FileSystemRights]::ReadAndExecute } } }

foreach ($p in $profiles) {
    $shareName = $p.ShareName
    $sharePath = $p.Path
    $adGroup = $p.ADGroup
    $perm = $p.Permission

    Write-Host "Applying: $shareName -> $adGroup ($perm)" -ForegroundColor Cyan

    if (-not (Test-Path $sharePath)) { New-Item -ItemType Directory -Path $sharePath -Force | Out-Null }

    try {
        $acl = Get-Acl -Path $sharePath
        $identity = $adGroup
        $fsRight = Get-FileSystemRights -perm $perm
        $inheritanceFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit, [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
        $propagationFlags = [System.Security.AccessControl.PropagationFlags]::None
        $accessControlType = [System.Security.AccessControl.AccessControlType]::Allow

        # Remove any existing ACE for same identity
        $existing = $acl.Access | Where-Object { $_.IdentityReference -like "*$($identity.Split('\')[-1])" }
        foreach ($e in $existing) { $acl.RemoveAccessRule($e) | Out-Null }

        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, $fsRight, $inheritanceFlags, $propagationFlags, $accessControlType)
        $acl.AddAccessRule($rule)
        Set-Acl -Path $sharePath -AclObject $acl
        Write-Host "NTFS ACL applied" -ForegroundColor Green
    } catch {
        Write-Host "NTFS ACL error: $_" -ForegroundColor Red
    }

    # Ensure NFS share exists and grant permission
    try {
        if (-not (Get-NfsShare -Name $shareName -ErrorAction SilentlyContinue)) {
            New-NfsShare -Name $shareName -Path $sharePath -EnableUnmappedAccess $false -ErrorAction Stop
        }

        $permForNfs = if ($perm.ToLower() -eq "read") { "ReadOnly" } else { "ReadWrite" }
        Grant-NfsSharePermission -Name $shareName -Path $sharePath -ClientName "*" -ClientType "builtin" -Permission $permForNfs -ErrorAction SilentlyContinue
        Write-Host "NFS permission applied: $permForNfs" -ForegroundColor Green
    } catch {
        Write-Host "NFS permission warning: $_" -ForegroundColor Yellow
    }
}
