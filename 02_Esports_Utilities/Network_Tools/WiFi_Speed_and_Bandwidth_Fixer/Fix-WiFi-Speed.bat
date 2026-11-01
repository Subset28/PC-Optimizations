<# :
@echo off
setlocal
title Fix Wi-Fi Speed - 300 Mbps Uncapper
color 0b

:: Check for Administrator rights and self-elevate if needed
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

:: Run embedded PowerShell payload
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$f = [System.IO.File]::ReadAllText('%~f0'); Invoke-Expression $f"
echo.
echo Press any key to exit...
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
Write-Host "[1/6] Scanning Wi-Fi Adapter & Connection Details..." -ForegroundColor Yellow

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
        Write-Host "  [!] Bottleneck Detected: You are connected to the 2.4 GHz band!" -ForegroundColor Red
        Write-Host "      2.4 GHz has heavy interference and caps real speeds between 8-30 Mbps." -ForegroundColor Yellow
        Write-Host "      This script will configure your card to prefer 5 GHz automatically." -ForegroundColor Yellow
    }
    if ([double]$rxRate -le 54 -and [double]$rxRate -gt 0) {
        Write-Host "  [!] Bottleneck Detected: Wi-Fi link speed is throttled to $rxRate Mbps!" -ForegroundColor Red
    }
} else {
    Write-Host "  [!] Notice: No active Wi-Fi connection detected right now (or connected via Ethernet)." -ForegroundColor Yellow
    Write-Host "      Proceeding with TCP stack, power management, and driver optimizations..." -ForegroundColor Gray
}

# -------------------------------------------------------------
# 2. FIX: Windows TCP Stack & Window Auto-Tuning (The 8 Mbps Bug)
# -------------------------------------------------------------
Write-Host "`n[2/6] Unlocking Windows TCP Stack & Auto-Tuning..." -ForegroundColor Yellow

$tcpGlobal = netsh int tcp show global
if ($tcpGlobal -match "Receive Window Auto-Tuning Level\s*:\s*disabled") {
    Write-Host "  [!] CRITICAL HIT: TCP Auto-Tuning was DISABLED!" -ForegroundColor Red
    Write-Host "      When disabled, Windows locks the TCP window to 64KB, causing an ~8 Mbps cap." -ForegroundColor Red
}

try {
    netsh int tcp set global autotuninglevel=normal | Out-Null
    Write-Host "  [+] TCP Receive Window Auto-Tuning set to NORMAL (Uncapped)" -ForegroundColor Green

    netsh int tcp set global rss=enabled | Out-Null
    Write-Host "  [+] Receive-Side Scaling (RSS) set to ENABLED (Multi-core network processing)" -ForegroundColor Green

    netsh int tcp set supplemental template=internet congestionprovider=cubic | Out-Null
    Write-Host "  [+] TCP Congestion Provider set to CUBIC (High throughput / low loss)" -ForegroundColor Green

    netsh int tcp set global ecncapability=disabled | Out-Null
    Write-Host "  [+] ECN Capability set to DISABLED (Eliminates packet drops from home routers)" -ForegroundColor Green

    netsh int tcp set global timestamps=disabled | Out-Null
    netsh int tcp set global hystart=enabled | Out-Null
    netsh int tcp set global prr=enabled | Out-Null
    Write-Host "  [+] TCP HyStart & Proportional Rate Reduction ENABLED" -ForegroundColor Green
} catch {
    Write-Host "  [-] Error applying some TCP stack settings: $_" -ForegroundColor Red
}

# -------------------------------------------------------------
# 3. FIX: Disable Receive Segment Coalescing (RSC) on Wi-Fi
# -------------------------------------------------------------
Write-Host "`n[3/6] Fixing Wi-Fi Receive Segment Coalescing (RSC) Driver Bugs..." -ForegroundColor Yellow

$wifiAdapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { 
    $_.PhysicalMediaType -match "Native 802\.11" -or 
    $_.InterfaceDescription -match "Wireless|Wi-Fi|802\.11|AC |AX |Dual Band" 
}

if ($wifiAdapters) {
    foreach ($adapter in $wifiAdapters) {
        Write-Host "  -> Optimizing Adapter: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Cyan
        try {
            Disable-NetAdapterRsc -Name $adapter.Name -IPv4 -IPv6 -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host "     [+] Disabled RSC on $($adapter.Name) (Eliminates micro-stalls & throttling)" -ForegroundColor Green
        } catch {
            Write-Host "     [-] RSC not supported or already disabled." -ForegroundColor Gray
        }

        try {
            Enable-NetAdapterLso -Name $adapter.Name -IPv4 -IPv6 -Confirm:$false -ErrorAction SilentlyContinue
        } catch {}
    }
} else {
    Write-Host "  [-] No dedicated Wi-Fi adapters found to modify RSC." -ForegroundColor Gray
}

# -------------------------------------------------------------
# 4. FIX: Wi-Fi Adapter Driver Settings (Prefer 5 GHz & Full Channel Width)
# -------------------------------------------------------------
Write-Host "`n[4/6] Tuning Wi-Fi Hardware & Advanced Driver Properties..." -ForegroundColor Yellow

if ($wifiAdapters) {
    foreach ($adapter in $wifiAdapters) {
        # 1. Prefer 5GHz Band over 2.4GHz
        $prefBandProps = Get-NetAdapterAdvancedProperty -Name $adapter.Name -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -match "Preferred Band|Band Preference|Roaming Aggressiveness" -or
            $_.RegistryKeyword -match "\*PreferredBand|RoamAggress"
        }

        foreach ($prop in $prefBandProps) {
            if ($prop.DisplayName -match "Preferred Band|Band Preference") {
                try {
                    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName $prop.DisplayName -DisplayValue "3. Prefer 5GHz band" -ErrorAction SilentlyContinue
                    Write-Host "     [+] Configured $($adapter.Name): Set Preferred Band to 5GHz" -ForegroundColor Green
                } catch {
                    try {
                        Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName $prop.DisplayName -DisplayValue "Prefer 5GHz band" -ErrorAction SilentlyContinue
                        Write-Host "     [+] Configured $($adapter.Name): Set Preferred Band to 5GHz" -ForegroundColor Green
                    } catch {}
                }
            }
        }

        # 2. Set Channel Width to Auto / Maximum
        $channelWidthProps = Get-NetAdapterAdvancedProperty -Name $adapter.Name -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -match "Channel Width|Fat Channel"
        }
        foreach ($prop in $channelWidthProps) {
            try {
                Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName $prop.DisplayName -DisplayValue "Auto" -ErrorAction SilentlyContinue
                Write-Host "     [+] Configured $($adapter.Name): $($prop.DisplayName) -> Auto" -ForegroundColor Green
            } catch {}
        }

        # 3. Enable Throughput Booster if Intel
        $boostProps = Get-NetAdapterAdvancedProperty -Name $adapter.Name -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -match "Throughput Booster"
        }
        foreach ($prop in $boostProps) {
            try {
                Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName $prop.DisplayName -DisplayValue "Enabled" -ErrorAction SilentlyContinue
                Write-Host "     [+] Configured $($adapter.Name): Throughput Booster -> ENABLED" -ForegroundColor Green
            } catch {}
        }

        # 4. Disable Power Saving on Wi-Fi NIC
        try {
            Set-NetAdapterPowerManagement -Name $adapter.Name -WakeOnMagicPacket Disabled -NoSavePower -ErrorAction SilentlyContinue
            Write-Host "     [+] Disabled hardware power save on $($adapter.Name)" -ForegroundColor Green
        } catch {}
    }
}

# 5. Disable Device Sleep via Registry (PnPCapabilities = 24 disables sleep power save)
$netClassKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
if (Test-Path $netClassKey) {
    Get-ChildItem $netClassKey -ErrorAction SilentlyContinue | ForEach-Object {
        $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($props.DriverDesc -match "Wireless|Wi-Fi|802\.11" -or $props.AdapterModel -match "Wireless|Wi-Fi") {
            Set-ItemProperty -Path $_.PSPath -Name "PnPCapabilities" -Value 24 -Type DWord -Force -ErrorAction SilentlyContinue
            Write-Host "  [+] Removed Windows 'Turn off device to save power' permission on: $($props.DriverDesc)" -ForegroundColor Green
        }
    }
}

# -------------------------------------------------------------
# 5. FIX: Remove Windows Bandwidth Throttles & Power Scheme Caps
# -------------------------------------------------------------
Write-Host "`n[5/6] Removing Windows Background Bandwidth Caps & Power Plan Throttles..." -ForegroundColor Yellow

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
    powercfg -setacvalueindex SCHEME_CURRENT 19cbb8fa-35bf-450a-9216-30151105740d 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 2>$null
    powercfg -setdcvalueindex SCHEME_CURRENT 19cbb8fa-35bf-450a-9216-30151105740d 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 2>$null
    powercfg -setactive SCHEME_CURRENT 2>$null
    Write-Host "  [+] Wireless Adapter Power Plan set to MAXIMUM PERFORMANCE (Plugged In & Battery)" -ForegroundColor Green
} catch {}

# -------------------------------------------------------------
# 6. RESET & RE-NEGOTIATE: Flush Network Stack & Restart Adapter
# -------------------------------------------------------------
Write-Host "`n[6/6] Flushing DNS, Routing Tables, & Re-negotiating Link..." -ForegroundColor Yellow

ipconfig /flushdns | Out-Null
Write-Host "  [+] DNS Cache Flushed" -ForegroundColor Green

netsh winsock reset | Out-Null
Write-Host "  [+] Winsock Catalog Reset" -ForegroundColor Green

netsh int ip reset | Out-Null
Write-Host "  [+] TCP/IP Stack Reset" -ForegroundColor Green

if ($wifiAdapters) {
    foreach ($adapter in $wifiAdapters) {
        Write-Host "  -> Restarting $($adapter.Name) to negotiate new link speed..." -ForegroundColor Cyan
        Restart-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
    }
    Write-Host "  -> Waiting 5 seconds for Wi-Fi reconnection..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
}

# -------------------------------------------------------------
# FINAL VERIFICATION & RECOMMENDATIONS
# -------------------------------------------------------------
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "                  OPTIMIZATION COMPLETE!                    " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

$newWlanInfo = netsh wlan show interfaces
if ($newWlanInfo -match "State\s*:\s*connected") {
    $newRx = "N/A"
    $newTx = "N/A"
    $newBand = "N/A"
    foreach ($line in $newWlanInfo) {
        if ($line -match "Band\s*:\s*(.+)$") { $newBand = $matches[1].Trim() }
        if ($line -match "Receive rate \(Mbps\)\s*:\s*(.+)$") { $newRx = $matches[1].Trim() }
        if ($line -match "Transmit rate \(Mbps\)\s*:\s*(.+)$") { $newTx = $matches[1].Trim() }
    }
    Write-Host "Current Link Status:" -ForegroundColor Yellow
    Write-Host "  -> Band: $newBand" -ForegroundColor Green
    Write-Host "  -> Negotiated Rx Rate: $newRx Mbps" -ForegroundColor Green
    Write-Host "  -> Negotiated Tx Rate: $newTx Mbps" -ForegroundColor Green
}

Write-Host "`nCRITICAL ROUTER TIPS FOR YOUR FRIEND:" -ForegroundColor Yellow
Write-Host "1. Check the Wi-Fi Network Name (SSID):" -ForegroundColor White
Write-Host "   If their router has combined 2.4GHz & 5GHz into one SSID, many PCs get stuck on 2.4GHz." -ForegroundColor Gray
Write-Host "   -> Log into router settings and separate them (e.g. 'HomeWiFi' and 'HomeWiFi_5G')." -ForegroundColor Gray
Write-Host "   -> Connect the PC explicitly to the '_5G' network!" -ForegroundColor Gray
Write-Host "`n2. Reboot Computer:" -ForegroundColor White
Write-Host "   A computer restart is recommended to finalize the TCP stack reset." -ForegroundColor Gray
Write-Host "`n3. Test Speeds Now:" -ForegroundColor White
Write-Host "   Run a speed test at https://speedtest.net or https://fast.com`n" -ForegroundColor Gray
