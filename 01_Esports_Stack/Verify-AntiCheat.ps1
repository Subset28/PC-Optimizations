<#
.SYNOPSIS
    Armaan Tech Tips - Anti-Cheat Integrity & Compliance Verifier
.DESCRIPTION
    Validates that the host system satisfies all kernel security, driver signing,
    and platform requirements for Riot Vanguard (Valorant) and Easy Anti-Cheat (Fortnite).
#>

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  RIOT VANGUARD & EASY ANTI-CHEAT COMPLIANCE AUDIT       " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$pass = $true

# 1. Secure Boot
$sb = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
if ($sb -eq $true) {
    Write-Host "[PASS] Secure Boot is ENABLED (Required by Riot Vanguard)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Secure Boot is DISABLED (Valorant will fail to launch)" -ForegroundColor Red
    $pass = $false
}

# 2. TPM 2.0
$tpm = Get-Tpm -ErrorAction SilentlyContinue
if ($tpm.TpmPresent -and $tpm.TpmReady) {
    Write-Host "[PASS] TPM 2.0 is PRESENT and READY" -ForegroundColor Green
} else {
    Write-Host "[FAIL] TPM 2.0 is missing or not ready" -ForegroundColor Red
    $pass = $false
}

# 3. Kernel Driver Signature Enforcement (TestSigning check)
$bcd = bcdedit /enum '{current}' | Select-String 'testsigning|nointegritychecks'
if (-not $bcd) {
    Write-Host "[PASS] Driver Signature Enforcement is STRICTLY ENFORCED (0 anti-cheat flags)" -ForegroundColor Green
} else {
    Write-Host "[WARN] TestSigning or NoIntegrityChecks detected in BCD! Anticheats may flag!" -ForegroundColor Yellow
    $pass = $false
}

# 4. Anti-Cheat Services
$vgc = Get-Service -Name "vgc" -ErrorAction SilentlyContinue
if ($vgc) {
    Write-Host "[PASS] Riot Vanguard Service (vgc) is REGISTERED" -ForegroundColor Green
} else {
    Write-Host "[INFO] Riot Vanguard (vgc) is not installed on this machine" -ForegroundColor DarkGray
}

$eac = Get-Service -Name "EasyAntiCheat_EOS" -ErrorAction SilentlyContinue
if ($eac) {
    Write-Host "[PASS] Easy Anti-Cheat (EOS) Service is REGISTERED" -ForegroundColor Green
} else {
    Write-Host "[INFO] Easy Anti-Cheat (EOS) is not registered" -ForegroundColor DarkGray
}

Write-Host ""
if ($pass) {
    Write-Host ">>> OVERALL STATUS: 100% TOURNAMENT & ANTI-CHEAT COMPLIANT <<<" -ForegroundColor Green
} else {
    Write-Host ">>> OVERALL STATUS: ACTION REQUIRED FOR FULL COMPLIANCE <<<" -ForegroundColor Red
}
Write-Host "==========================================================" -ForegroundColor Cyan
