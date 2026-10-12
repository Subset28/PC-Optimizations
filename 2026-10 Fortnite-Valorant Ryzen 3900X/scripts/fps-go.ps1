# fps-go.ps1 - run in an ADMIN PowerShell AFTER rebooting, then start/stay in a real match.
# Usage:  .\fps-go.ps1            (auto-detects Fortnite or Valorant, captures 60 s)
#         .\fps-go.ps1 -Seconds 120
param([int]$Seconds = 60)

function Row($name, $value, $want) {
    $ok = if ($want) { if ("$value" -match $want) { 'OK ' } else { 'CHECK' } } else { '    ' }
    "{0,-5} {1,-38} {2}" -f $ok, $name, $value
}

"=== State check ==="
Row 'HAGS (HwSchMode, want 2)'            (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers').HwSchMode '^2$'
Row 'Global timer resolution (want 1)'    (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel').GlobalTimerResolutionRequests '^1$'
Row 'Hypervisor present (want False)'     (Get-CimInstance Win32_ComputerSystem).HypervisorPresent 'False'
$dg = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard
Row 'VBS status (want 0)'                 $dg.VirtualizationBasedSecurityStatus '^0$'
Row 'Process Lasso governors (want 1)'    (Get-Process ProcessGovernor -ErrorAction SilentlyContinue | Measure-Object).Count '^1$'
Row 'Active power plan'                   ((powercfg /getactivescheme) -replace 'Power Scheme GUID: [0-9a-f-]+\s*','')
$gpuIrq = (Get-ItemProperty ("HKLM:\SYSTEM\CurrentControlSet\Enum\" + (Get-PnpDevice -Class Display -Status OK | Where-Object FriendlyName -match NVIDIA).InstanceId + "\Device Parameters\Interrupt Management\Affinity Policy") -ErrorAction SilentlyContinue).DevicePolicy
Row 'GPU interrupt policy (want 4)'       $gpuIrq '^4$'
Row 'NIC RSS base CPU (want 12)'          (Get-NetAdapterRss -Name Ethernet).BaseProcessorNumber '^12$'

"`n=== Single-thread boost test (12 s) ==="
$job = Start-Job { $e=(Get-Date).AddSeconds(12); $x=0; while((Get-Date) -lt $e){ for($i=0;$i -lt 200000;$i++){ $x+=[math]::Sqrt($i) } } }
Start-Sleep 3
$mhz = 1..5 | ForEach-Object {
    $c = (Get-Counter '\Processor Information(*)\% Processor Performance').CounterSamples | Where-Object InstanceName -notmatch '_total' | Sort-Object CookedValue -Descending | Select-Object -First 1
    [int]($c.CookedValue / 100 * 3800); Start-Sleep 1
}
Wait-Job $job -Timeout 20 | Out-Null; Remove-Job $job -Force
"Max single-core clock: {0} MHz   (was 4350 before the boost-override fix)" -f ($mhz | Measure-Object -Maximum).Maximum

"`n=== Match capture ==="
$game = @('FortniteClient-Win64-Shipping','VALORANT-Win64-Shipping') | Where-Object { Get-Process $_ -ErrorAction SilentlyContinue } | Select-Object -First 1
if (-not $game) { "No game running. Start a match, then rerun (or use -Seconds)."; return }
"Capturing $game for $Seconds s ... play normally."
$pm = (Get-Command presentmon).Source
$csv = Join-Path $env:TEMP "go_$game.csv"
Remove-Item $csv -ErrorAction SilentlyContinue
$ping = Start-Job { param($n) Test-Connection 1.1.1.1 -Count $n | Select-Object -ExpandProperty Latency } -ArgumentList ([Math]::Max(5, $Seconds - 5))
& $pm --process_name "$game.exe" --output_file $csv --timed $Seconds --terminate_after_timed --no_console_stats 2>&1 | Out-Null
$lat = Receive-Job $ping -Wait; Remove-Job $ping -Force
$ms = Import-Csv $csv | ForEach-Object { $v = 0.0; if ([double]::TryParse($_.MsBetweenPresents, [ref]$v) -and $v -gt 0) { $v } } | Sort-Object -Descending
$ms = $ms | Select-Object -Skip 20     # drop capture-start hitches
$n = $ms.Count
$avg = 1000 / (($ms | Measure-Object -Average).Average)
"{0}: {1} frames | avg {2:N0} fps | 1% low {3:N0} | 0.1% low {4:N0} | worst frame {5:N0} ms" -f $game, $n, $avg, (1000/$ms[[int]($n*0.01)]), (1000/$ms[[int]($n*0.001)]), $ms[0]
"frames at >=240 fps: {0:P0} | frames >16.7 ms: {1} | >33 ms: {2}" -f (($ms | Where-Object { $_ -le 4.1667 }).Count / $n), ($ms | Where-Object { $_ -gt 16.7 }).Count, ($ms | Where-Object { $_ -gt 33 }).Count
"ping to 1.1.1.1: avg {0:N1} ms, max {1} ms" -f ($lat | Measure-Object -Average).Average, ($lat | Measure-Object -Maximum).Maximum
"Baseline to beat (Fortnite, 2026-10-11): avg 188 | 1% low 113 | 0.1% low 47"
