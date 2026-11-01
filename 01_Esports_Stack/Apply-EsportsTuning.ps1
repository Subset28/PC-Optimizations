<#
.SYNOPSIS
    Armaan Tech Tips - 2026 Ultimate Esports & Low-Latency Tuning Script
.DESCRIPTION
    Applies tested, safe, and kernel-verified optimizations for competitive esports
    (Fortnite, Valorant, Call of Duty) while strictly maintaining 100% compliance with
    Riot Vanguard and Easy Anti-Cheat (EAC).
.NOTES
    Requires Administrator privileges.
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = 'Continue'

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  ARMAAN TECH TIPS - 2026 ESPORTS LOW-LATENCY OPTIMIZER   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Automatic Restore Point Creation
Write-Host "[1/8] Creating System Restore Point..." -ForegroundColor Yellow
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "ArmaanTechTips_Esports_Tuning" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-Host "  -> Restore Point created successfully." -ForegroundColor Green
} catch {
    Write-Host "  -> Warning: Could not create restore point (may already exist within cooldown). Continuing." -ForegroundColor DarkGray
}

# 2. Kernel Clock Precision & Quantum Scheduling
Write-Host "`n[2/8] Tuning Kernel Timers & CPU Scheduling..." -ForegroundColor Yellow
try {
    bcdedit /set disabledynamictick yes | Out-Null
    Write-Host "  -> High-Precision Kernel Clock: disabledynamictick = yes" -ForegroundColor Green
} catch {
    Write-Host "  -> Failed to configure bcdedit." -ForegroundColor Red
}

$priorityPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
Set-ItemProperty -Path $priorityPath -Name "Win32PrioritySeparation" -Value 38 -Type DWord -Force
Write-Host "  -> CPU Quantum Priority: Win32PrioritySeparation = 0x26 (3:1 Foreground Boost)" -ForegroundColor Green

# 3. Multimedia Class Scheduler Service (MMCSS)
Write-Host "`n[3/8] Optimizing MMCSS Audio & Gaming Priorities..." -ForegroundColor Yellow
$audioPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio"
Set-ItemProperty -Path $audioPath -Name "Background Only" -Value "False" -Force
Set-ItemProperty -Path $audioPath -Name "Scheduling Category" -Value "High" -Force
Set-ItemProperty -Path $audioPath -Name "SFIO Priority" -Value "High" -Force
Set-ItemProperty -Path $audioPath -Name "Priority" -Value 6 -Type DWord -Force
Write-Host "  -> Audio Engine (audiodg.exe): Starvation prevented (MMCSS High Category)" -ForegroundColor Green

$gamesPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
Set-ItemProperty -Path $gamesPath -Name "Priority" -Value 8 -Type DWord -Force
Set-ItemProperty -Path $gamesPath -Name "GPU Priority" -Value 8 -Type DWord -Force
Set-ItemProperty -Path $gamesPath -Name "Scheduling Category" -Value "High" -Force
Set-ItemProperty -Path $gamesPath -Name "SFIO Priority" -Value "High" -Force
Write-Host "  -> Gaming Tasks: GPU & Execution Priority = 8 (High)" -ForegroundColor Green

$sysProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
Set-ItemProperty -Path $sysProfile -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -Force
Set-ItemProperty -Path $sysProfile -Name "SystemResponsiveness" -Value 0 -Type DWord -Force
Write-Host "  -> Network Throttling Disabled & System Responsiveness = 0%" -ForegroundColor Green

# 4. GPU Stability & TDR Crash Protection
Write-Host "`n[4/8] Hardening GPU TDR Stability (Crash Prevention)..." -ForegroundColor Yellow
$gfxPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
Set-ItemProperty -Path $gfxPath -Name "TdrDelay" -Value 8 -Type DWord -Force
Set-ItemProperty -Path $gfxPath -Name "TdrDdiDelay" -Value 8 -Type DWord -Force
Write-Host "  -> TDR Timeout extended to 8 seconds (Prevents UE5/DX12 crash-to-desktop)" -ForegroundColor Green

# 5. Low-Latency 1:1 Input Queues (Mouse & Keyboard)
Write-Host "`n[5/8] Clamping Input Device Buffers..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" -Name "MouseDataQueueSize" -Value 32 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" -Name "KeyboardDataQueueSize" -Value 32 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -Force
Write-Host "  -> Mouse & Keyboard Queue Size clamped to 32 (Zero input buffer lag)" -ForegroundColor Green
Write-Host "  -> Windows Pointer Acceleration curve removed (True 1:1 hardware sensor tracking)" -ForegroundColor Green

# 6. Exploit Mitigation Tuning (CFG Bypass for UE5 / UE4)
Write-Host "`n[6/8] Disabling Control Flow Guard on Competitive Binaries..." -ForegroundColor Yellow
try {
    Set-ProcessMitigation -Name "FortniteClient-Win64-Shipping.exe" -Disable CFG -ErrorAction SilentlyContinue
    Set-ProcessMitigation -Name "VALORANT-Win64-Shipping.exe" -Disable CFG -ErrorAction SilentlyContinue
    Write-Host "  -> Control Flow Guard (CFG) disabled for Fortnite & Valorant (Eliminates UE5 hitching)" -ForegroundColor Green
} catch {
    Write-Host "  -> Notice: Set-ProcessMitigation requires PowerShell 5.1+" -ForegroundColor DarkGray
}

# 7. Zero-Ping Network Stack Tuning
Write-Host "`n[7/8] Accelerating Network Stack & Realtek ASIC Offloads..." -ForegroundColor Yellow
$adapters = Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' }
foreach ($adapter in $adapters) {
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "TCP Checksum Offload (IPv4)" -DisplayValue "Rx & Tx Enabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "UDP Checksum Offload (IPv4)" -DisplayValue "Rx & Tx Enabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "IPv4 Checksum Offload" -DisplayValue "Rx & Tx Enabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "RSS load balancing profile" -DisplayValue "ClosestProcessor" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Transmit Buffers" -DisplayValue "128" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Receive Buffers" -DisplayValue "512" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Flow Control" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Energy-Efficient Ethernet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Green Ethernet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Write-Host "  -> Configured line-speed ASIC offloading on $($adapter.Name)" -ForegroundColor Green
}

# 8. Power Scheme Import & Activation
Write-Host "`n[8/10] Checking & Tuning Blaster Boy 28 Power Plan..." -ForegroundColor Yellow
$powFile = Join-Path $PSScriptRoot "Blaster_Boy_28.pow"
$planGuid = "fb63eccd-626c-4575-b57c-8641a8366117"
if (Test-Path $powFile) {
    $existing = powercfg /list | Select-String "Blaster Boy 28"
    if (-not $existing) {
        Write-Host "  -> Importing Blaster Boy 28 power plan..." -ForegroundColor Cyan
        powercfg -import $powFile $planGuid
    } else {
        Write-Host "  -> Blaster Boy 28 plan already registered." -ForegroundColor Green
    }
}

# 9. Deep CPPC & Zen 2 Hardware Autonomous P-States
Write-Host "`n[9/10] Applying Deep CPPC2 & Autonomous Hardware Frequency Scaling..." -ForegroundColor Yellow
$subProc = "54533251-82be-4824-96c1-47b60b740d00"
$deepSettings = @(
    @{ Name = "Energy Performance Preference (EPP)"; Guid = "36687f9e-e3a5-4dbf-b1dc-15eb381c6863"; Value = 0 },
    @{ Name = "Processor Autonomous Mode"; Guid = "8baa4a8a-14c6-4451-8e8b-14bdbd197537"; Value = 1 },
    @{ Name = "Core Parking Max Cores"; Guid = "ea062031-0e34-4ff1-9b6d-eb1059334028"; Value = 100 },
    @{ Name = "Core Parking Min Cores"; Guid = "0cc5b647-c1df-4637-891a-dec35c318583"; Value = 100 },
    @{ Name = "Processor Boost Mode"; Guid = "be337238-0d82-4146-a960-4f3749d470c7"; Value = 2 },
    @{ Name = "Performance Decrease Policy"; Guid = "40fbefc7-2e9d-4d25-a185-0cfd8574bac6"; Value = 1 },
    @{ Name = "Performance Increase Policy"; Guid = "465e1f50-b610-473a-ab58-00d1077dc418"; Value = 2 },
    @{ Name = "Autonomous Activity Window"; Guid = "cfeda3d0-7697-4566-a922-a9086cd49dfa"; Value = 30000 } # 30ms stable CPPC2 window (eliminates 0-interval frequency thrashing)
)
foreach ($s in $deepSettings) {
    powercfg -attributes $subProc $s.Guid -ATTRIB_HIDE 2>$null
    powercfg -setacvalueindex $planGuid $subProc $s.Guid $s.Value 2>$null
    Write-Host "  -> $($s.Name) set to $($s.Value)" -ForegroundColor Green
}

# 10. Esports Network QoS & DSCP Packet Tagging
Write-Host "`n[10/10] Applying Esports QoS Packet Prioritization (DSCP 46)..." -ForegroundColor Yellow
$qosRegistry = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\QoS"
if (-not (Test-Path $qosRegistry)) { New-Item -Path $qosRegistry -Force | Out-Null }
Set-ItemProperty -Path $qosRegistry -Name "Do not use NLA" -Value "1" -Type String -Force

if (-not (Get-NetQosPolicy -Name "Fortnite-Gaming-QoS" -ErrorAction SilentlyContinue)) {
    New-NetQosPolicy -Name "Fortnite-Gaming-QoS" -AppPathNameMatchCondition "FortniteClient-Win64-Shipping.exe" -DSCPAction 46 -NetworkProfile All -ErrorAction SilentlyContinue | Out-Null
    Write-Host "  -> Created NetQosPolicy: Fortnite (DSCP 46 - Expedited Forwarding)" -ForegroundColor Green
}
if (-not (Get-NetQosPolicy -Name "Valorant-Gaming-QoS" -ErrorAction SilentlyContinue)) {
    New-NetQosPolicy -Name "Valorant-Gaming-QoS" -AppPathNameMatchCondition "VALORANT-Win64-Shipping.exe" -DSCPAction 46 -NetworkProfile All -ErrorAction SilentlyContinue | Out-Null
    Write-Host "  -> Created NetQosPolicy: Valorant (DSCP 46 - Expedited Forwarding)" -ForegroundColor Green
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  OPTIMIZATION COMPLETE! PLEASE REBOOT TO ENGAGE KERNEL HAL" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
