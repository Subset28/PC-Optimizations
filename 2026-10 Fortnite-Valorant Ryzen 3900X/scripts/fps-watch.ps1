# Waits for Fortnite/Valorant, waits 3 min into the match, captures 90 s, writes summary to fps-watch-results.txt
$out=Join-Path $env:USERPROFILE "fps-watch-results.txt"
$pm=(Get-Command presentmon).Source
while($true){
  $g=@('FortniteClient-Win64-Shipping','VALORANT-Win64-Shipping')|?{Get-Process $_ -EA SilentlyContinue}|select -first 1
  if($g){
    Start-Sleep 180
    if(-not (Get-Process $g -EA SilentlyContinue)){continue}
    $csv="$env:TEMP\watch_$g.csv"; Remove-Item $csv -EA SilentlyContinue
    & $pm --process_name "$g.exe" --output_file $csv --timed 90 --terminate_after_timed --no_console_stats 2>&1|Out-Null
    if(Test-Path $csv){
      $ms=Import-Csv $csv|%{$v=0.0;if([double]::TryParse($_.MsBetweenPresents,[ref]$v)-and $v-gt 0){$v}}|sort -desc|select -skip 20
      $n=$ms.Count
      if($n -gt 100){
        $avg=1000/(($ms|measure -Average).Average)
        "{0} {1}: avg {2:N0} | 1% low {3:N0} | 0.1% low {4:N0} | >=240fps {5:P0} | >16.7ms {6}" -f (Get-Date),$g,$avg,(1000/$ms[[int]($n*0.01)]),(1000/$ms[[int]($n*0.001)]),(($ms|?{$_ -le 4.1667}).Count/$n),($ms|?{$_ -gt 16.7}).Count|Add-Content $out
      } else {"$(Get-Date) $g capture failed/too few frames ($n)"|Add-Content $out}
    } else {"$(Get-Date) $g no csv (presentmon needs admin?)"|Add-Content $out}
    while(Get-Process $g -EA SilentlyContinue){Start-Sleep 30}
  }
  Start-Sleep 15
}
