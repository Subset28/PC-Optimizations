# Captures the running game in repeated 60 s windows and appends one line per window to fps-watch-results.txt.
# Each line is tagged MENU / LOADING/LOW / MATCH so lobby captures can't be mistaken for gameplay.
$out = Join-Path $env:USERPROFILE 'fps-watch-results.txt'
$pm  = (Get-Command presentmon).Source
$win = 60
while ($true) {
  $g = @('FortniteClient-Win64-Shipping','VALORANT-Win64-Shipping') | Where-Object { Get-Process $_ -EA SilentlyContinue } | Select-Object -First 1
  if (-not $g) { Start-Sleep 10; continue }
  $csv = Join-Path $env:TEMP ("watch_{0}_{1}.csv" -f $g, (Get-Date -Format 'HHmmss'))
  & $pm --process_name "$g.exe" --output_file $csv --timed $win --terminate_after_timed --no_console_stats 2>&1 | Out-Null
  if (Test-Path $csv) {
    $ms = Import-Csv $csv | ForEach-Object { $v = 0.0; if ([double]::TryParse($_.MsBetweenPresents, [ref]$v) -and $v -gt 0) { $v } } | Sort-Object -Descending | Select-Object -Skip 20
    $n = $ms.Count
    if ($n -gt 500) {
      $med  = $ms[[int]($n / 2)]
      $near = ($ms | Where-Object { $_ -gt 7.5 -and $_ -lt 9.5 }).Count / $n           # 120 fps menu cap
      $kind = if ($near -gt 0.7) { 'MENU' } elseif ($n -lt 0.6 * $win * 60) { 'LOADING/LOW' } else { 'MATCH' }
      $avg  = 1000 / (($ms | Measure-Object -Average).Average)
      $name = $g -replace 'FortniteClient-Win64-Shipping','Fortnite' -replace 'VALORANT-Win64-Shipping','Valorant'
      "{0:HH:mm:ss} {1,-11} {2}: avg {3:N0} | 1% low {4:N0} | 0.1% low {5:N0} | >=240fps {6:P0} | median {7:N2}ms | stutters(>2x med) {8} | big(>3x) {9} | worst {10:N0}ms | RAM used {11:N1} GB, commit {12:N1} GB" -f (Get-Date), $kind, $name, $avg, (1000/$ms[[int]($n*0.01)]), (1000/$ms[[int]($n*0.001)]), (($ms | Where-Object { $_ -le 4.1667 }).Count / $n), $med, ($ms | Where-Object { $_ -gt 2*$med }).Count, ($ms | Where-Object { $_ -gt 3*$med }).Count, $ms[0], ((Get-CimInstance Win32_OperatingSystem | % { ($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / 1MB })), ((Get-Counter '\Memory\Committed Bytes').CounterSamples[0].CookedValue / 1GB) | Add-Content $out
    }
    Remove-Item $csv -EA SilentlyContinue
  }
  Start-Sleep 15
}
