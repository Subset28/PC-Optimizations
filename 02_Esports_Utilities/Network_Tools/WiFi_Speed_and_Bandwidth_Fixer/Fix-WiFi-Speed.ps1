pause >nul
exit /b
#>

Clear-Host
$Host.UI.RawUI.WindowTitle = "Ultra Wi-Fi Speed & Bandwidth Repair Suite"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "       ULTRA WI-FI SPEED & BANDWIDTH REPAIR SUITE            " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Diagnosing and fixing low speed caps (e.g. 8 Mbps on 300 Mbps plan)...`n" -ForegroundColor Gray

# -------------------------------------------------------------
# 1. DIAGNOSTICS: Inspect Live Wi-Fi Connection
# -------------------------------------------------------------
Write-Host "[1/5] Scanning Wi-Fi Adapter & Connection Details..." -ForegroundColor Yellow

$wlanInfo = netsh wlan show interfaces
$wifiConnected = $false
$ssid = "N/A"
$radioType = "N/A"
$band = "N/A"
$channel = "N/A"
$rxRate = "N/A"
$txRate = "N/A"
$signal = "N/A"

if ($wlanInfo -match "State\s*:\s*connected") {
    $wifiConnected = $true
    foreach ($line in $wlanInfo) {
        if ($line -match "SSID\s*:\s*(.+)$" -and $line -notmatch "BSSID") { $ssid = $matches[1].Trim() }
        if ($line -match "Radio type\s*:\s*(.+)$") { $radioType = $matches[1].Trim() }
        if ($line -match "Band\s*:\s*(.+)$") { $band = $matches[1].Trim() }
        if ($line -match "Channel\s*:\s*(.+)$") { $channel = $matches[1].Trim() }
        if ($line -match "Receive rate \(Mbps\)\s*:\s*(.+)$") { $rxRate = $matches[1].Trim() }
        if ($line -match "Transmit rate \(Mbps\)\s*:\s*(.+)$") { $txRate = $matches[1].Trim() }
        if ($line -match "Signal\s*:\s*(.+)$") { $signal = $matches[1].Trim() }
    }
}

if ($wifiConnected) {
    Write-Host "  -> Connected SSID : $ssid" -ForegroundColor Cyan
    Write-Host "  -> Radio Protocol: $radioType" -ForegroundColor Cyan
    Write-Host "  -> Frequency Band: $band" -ForegroundColor $(if ($band -match "2\.4") { "Red" } else { "Green" })
    Write-Host "  -> Signal Quality: $signal" -ForegroundColor Cyan
    Write-Host "  -> Negotiated Rx : $rxRate Mbps" -ForegroundColor $(if ([double]$rxRate -lt 54) { "Red" } else { "Green" })
    Write-Host "  -> Negotiated Tx : $txRate Mbps" -ForegroundColor $(if ([double]$txRate -lt 54) { "Red" } else { "Green" })

    if ($band -match "2\.4") {
        Write-Host "  [!] Bottleneck Detected: Connected to 2.4 GHz band." -ForegroundColor Red
        Write-Host "      2.4 GHz has heavy interference and caps real speeds between 8-30 Mbps." -ForegroundColor Yellow
        Write-Host "      Configuring Wi-Fi adapter to prioritize 5 GHz..." -ForegroundColor Yellow
    }
    if ([double]$rxRate -le 54 -and [double]$rxRate -gt 0) {
        Write-Host "  [!] Bottleneck Detected: Link rate is throttled to $rxRate Mbps!" -ForegroundColor Red
    }
} else {
    Write-Host "  [!] Notice: No active Wi-Fi connection detected right now (or connected via Ethernet)." -ForegroundColor Yellow
    Write-Host "      Proceeding with TCP stack, power management, and driver optimizations..." -ForegroundColor Gray
}

# -------------------------------------------------------------
# 2. FIX: Windows TCP Stack & Window Auto-Tuning (The 8 Mbps Bug)
# -------------------------------------------------------------
Write-Host "`n[2/5] Unlocking Windows TCP Stack & Auto-Tuning..." -ForegroundColor Yellow

$tcpGlobal = netsh int tcp show global
if ($tcpGlobal -match "Receive Window Auto-Tuning Level\s*:\s*disabled") {
    Write-Host "  [!] CRITICAL HIT: TCP Auto-Tuning was DISABLED!" -ForegroundColor Red
    Write-Host "      When disabled, Windows locks the TCP window to 64KB, causing an ~8 Mbps cap." -ForegroundColor Red
}

try {
    netsh int tcp set global autotuninglevel=normal | Out-Null
    Write-Host "  [+] TCP Receive Window Auto-Tuning set to NORMAL (Uncapped)" -ForegroundColor Green

    netsh int tcp set global rss=enabled | Out-Null
    Write-Host "  [+] Receive-Side Scaling (RSS) set to ENABLED (Multi-core network distribution)" -ForegroundColor Green

    netsh int tcp set supplemental template=internet congestionprovider=cubic | Out-Null
    Write-Host "  [+] TCP Congestion Provider set to CUBIC (High throughput / low loss)" -ForegroundColor Green

    netsh int tcp set global ecncapability=disabled | Out-Null
    Write-Host "  [+] ECN Capability set to DISABLED (Prevents router packet drops)" -ForegroundColor Green

    netsh int tcp set global rsc=disabled | Out-Null
    Write-Host "  [+] Global TCP RSC set to DISABLED (Eliminates packet drops & micro-stalls)" -ForegroundColor Green

    netsh int tcp set global timestamps=disabled | Out-Null
    netsh int tcp set global hystart=enabled | Out-Null
    netsh int tcp set global prr=enabled | Out-Null
    Write-Host "  [+] TCP HyStart & Proportional Rate Reduction ENABLED" -ForegroundColor Green
} catch {
    Write-Host "  [-] Error applying TCP stack settings: $_" -ForegroundColor Red
}

# -------------------------------------------------------------
# 3. FIX: Wi-Fi Hardware & Registry Driver Tuning (Instantaneous & Non-Blocking)
# -------------------------------------------------------------
Write-Host "`n[3/5] Tuning Wi-Fi Hardware & Driver Properties (Direct Registry Injection)..." -ForegroundColor Yellow

$netClassKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
$tunedCount = 0

if (Test-Path $netClassKey) {
    Get-ChildItem $netClassKey -ErrorAction SilentlyContinue | ForEach-Object {
        $p = $_.PSPath
        $props = Get-ItemProperty $p -ErrorAction SilentlyContinue
        $desc = $props.DriverDesc
        $model = $props.AdapterModel

        if (($desc -and ($desc -match "Wireless|Wi-Fi|802\.11|AC |AX |Dual Band|Realtek|Intel|MediaTek|Qualcomm")) -or
            ($model -and ($model -match "Wireless|Wi-Fi|802\.11|AC |AX |Dual Band"))) {
            
            # 1. Force 5 GHz Band Preference (Intel: RoamingPreferredBandType=3, Realtek/Broadcom: *PreferredBand=3)
            Set-ItemProperty -Path $p -Name "RoamingPreferredBandType" -Value "3" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $p -Name "*PreferredBand" -Value "3" -Type String -Force -ErrorAction SilentlyContinue

            # 2. Unlock Channel Width to Auto / Maximum
            Set-ItemProperty -Path $p -Name "ChannelWidth24" -Value "1" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $p -Name "ChannelWidth52" -Value "1" -Type String -Force -ErrorAction SilentlyContinue

            # 3. Enable Throughput Booster & Disable Fat Channel Intolerance
            Set-ItemProperty -Path $p -Name "ThroughputBoosterEnabled" -Value "1" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $p -Name "FatChannelIntolerant" -Value "0" -Type String -Force -ErrorAction SilentlyContinue

            # 4. Disable Wi-Fi RSC in Driver Directly (Fixes Intel AX200/Realtek drops)
            Set-ItemProperty -Path $p -Name "*WdiRscIPv4" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $p -Name "*WdiRscIPv6" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $p -Name "*RscIPv4" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $p -Name "*RscIPv6" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            # 5. Disable Device Sleep / Power Savings (PnPCapabilities = 24 disables sleep power down)
            Set-ItemProperty -Path $p -Name "PnPCapabilities" -Value 24 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $p -Name "MIMOPowerSaveMode" -Value "0" -Type String -Force -ErrorAction SilentlyContinue

            Write-Host "  [+] Configured NIC: $desc" -ForegroundColor Green
            Write-Host "      -> Preferred Band: 5 GHz | Channel Width: Auto | Throughput Booster: ON | Power Save: OFF" -ForegroundColor Gray
            $tunedCount++
        }
    }
}

if ($tunedCount -eq 0) {
    Write-Host "  [-] No active Wi-Fi drivers found in registry." -ForegroundColor Gray
}

# -------------------------------------------------------------
# 4. FIX: Remove Windows Bandwidth Throttles & Power Scheme Caps
# -------------------------------------------------------------
Write-Host "`n[4/5] Removing Windows Background Bandwidth Caps & Power Plan Throttles..." -ForegroundColor Yellow

$doKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
if (-not (Test-Path $doKey)) { New-Item -Path $doKey -Force | Out-Null }
Set-ItemProperty -Path $doKey -Name "DOMaxDownloadBandwidth" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $doKey -Name "DOMinBackgroundQos" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Write-Host "  [+] Removed Delivery Optimization bandwidth restrictions" -ForegroundColor Green

$netThrottlingKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
if (Test-Path $netThrottlingKey) {
    Set-ItemProperty -Path $netThrottlingKey -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $netThrottlingKey -Name "SystemResponsiveness" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] Disabled Windows Multimedia Network Throttling Index (0xffffffff)" -ForegroundColor Green
}

try {
    # 19cbb8fa-35bf-450a-9216-30151105740d = SUB_WIFI, 12bbebe6-58d6-4636-95bb-3217ef867c1a = Max Performance (0)
    powercfg -setacvalueindex SCHEME_CURRENT 19cbb8fa-35bf-450a-9216-30151105740d 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 2>$null
    powercfg -setdcvalueindex SCHEME_CURRENT 19cbb8fa-35bf-450a-9216-30151105740d 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 2>$null
    powercfg -setactive SCHEME_CURRENT 2>$null
    Write-Host "  [+] Wireless Adapter Power Plan set to MAXIMUM PERFORMANCE" -ForegroundColor Green
} catch {}

# -------------------------------------------------------------
# 5. RESET & FLUSH: Flush Network Stack
# -------------------------------------------------------------
Write-Host "`n[5/5] Flushing DNS, Routing Tables, & Winsock..." -ForegroundColor Yellow

ipconfig /flushdns | Out-Null
Write-Host "  [+] DNS Cache Flushed" -ForegroundColor Green

netsh winsock reset | Out-Null
Write-Host "  [+] Winsock Catalog Reset" -ForegroundColor Green

netsh int ip reset | Out-Null
Write-Host "  [+] TCP/IP Stack Reset" -ForegroundColor Green

# -------------------------------------------------------------
# FINAL INSTRUCTIONS
# -------------------------------------------------------------
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "                  OPTIMIZATION COMPLETE!                    " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

Write-Host "`nNEXT STEPS FOR FULL SPEED:" -ForegroundColor Yellow
Write-Host "1. REBOOT YOUR PC NOW (CRITICAL):" -ForegroundColor White
Write-Host "   A computer restart is required for Windows to reload the Wi-Fi driver" -ForegroundColor Gray
Write-Host "   and engage the 5 GHz band preference and uncapped TCP window." -ForegroundColor Gray

Write-Host "`n2. CHECK YOUR WI-FI ROUTER (IF STILL LOW AFTER REBOOT):" -ForegroundColor White
Write-Host "   If your home router broadcasts 2.4 GHz and 5 GHz under the EXACT same name," -ForegroundColor Gray
Write-Host "   log into your router admin page (e.g. 192.168.1.1) and separate them" -ForegroundColor Gray
Write-Host "   (e.g., 'HomeWiFi' and 'HomeWiFi_5G'). Connect your PC directly to the 5G network!" -ForegroundColor Gray

Write-Host "`n3. TEST SPEEDS:" -ForegroundColor White
Write-Host "   After rebooting, test at https://speedtest.net or https://fast.com`n" -ForegroundColor Gray
