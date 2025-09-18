Write-Host "Checking Kerberos Tickets..." -ForegroundColor Cyan
try {
    klist
} catch {
    Write-Host "Kerberos not configured or tickets missing." -ForegroundColor Red
}
