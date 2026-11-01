# Synthetic hitch detector: pins a spin-loop thread to one logical CPU and records every time it is interrupted.
# Compares: baseline vs. each suspect app started one at a time. Output: hitch-test-results.txt
param([int]$Cpu = 6, [int]$Seconds = 15, [string]$Only = '')
$out = Join-Path $env:USERPROFILE 'hitch-test-results.txt'
Add-Type -TypeDefinition @'
using System; using System.Diagnostics; using System.Runtime.InteropServices; using System.Threading;
public static class Hitch {
  [DllImport("kernel32.dll")] static extern IntPtr GetCurrentThread();
  [DllImport("kernel32.dll")] static extern UIntPtr SetThreadAffinityMask(IntPtr h, UIntPtr m);
  public static long[] Run(int cpu, int seconds, out double maxUs) {
    // buckets: >100us, >250us, >500us, >1ms, >5ms
    long[] b = new long[5]; double mx = 0;
    Thread t = new Thread(() => {
      SetThreadAffinityMask(GetCurrentThread(), new UIntPtr(1UL << cpu));
      Thread.CurrentThread.Priority = ThreadPriority.Highest;
      double f = 1e6 / Stopwatch.Frequency; long end = Stopwatch.GetTimestamp() + (long)seconds * Stopwatch.Frequency;
      long last = Stopwatch.GetTimestamp();
      while (true) {
        long now = Stopwatch.GetTimestamp();
        double gap = (now - last) * f; last = now;
        if (gap > 20) { b[0]++; if (gap > 50) b[1]++; if (gap > 100) b[2]++; if (gap > 500) b[3]++; if (gap > 1000) b[4]++; if (gap > mx) mx = gap; }
        if (now > end) break;
      }
    });
    t.Start(); t.Join(); maxUs = mx; return b;
  }
}
'@
function Measure-Hitch($label) {
  $mx = 0.0
  $b = [Hitch]::Run($Cpu, $Seconds, [ref]$mx)
  $line = "{0,-34} >20us:{1,6}  >50us:{2,5}  >100us:{3,5}  >500us:{4,4}  >1ms:{5,3}  max:{6,8:N0}us" -f $label, $b[0], $b[1], $b[2], $b[3], $b[4], $mx
  $line | Tee-Object -FilePath $out -Append
}
Remove-Item $out -ErrorAction SilentlyContinue
$me = Get-Process -Id $PID
$me.ProcessorAffinity = [IntPtr](1 -shl $Cpu)          # Process Lasso may re-pin this shell; verify below
$aff = '{0:X}' -f [int64](Get-Process -Id $PID).ProcessorAffinity
"affinity of test process: 0x$aff (want 0x$('{0:X}' -f (1 -shl $Cpu)))  cpu=$Cpu  ${Seconds}s per case" | Tee-Object -FilePath $out -Append
$apps = @(
  @{N='MSI Afterburner'; P='C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe'; A='/s'; Proc='MSIAfterburner'},
  @{N='FanControl';      P='C:\Program Files (x86)\FanControl\FanControl.exe'; A=''; Proc='FanControl'},
  @{N='NVIDIA Broadcast'; P='C:\Program Files\NVIDIA Corporation\NVIDIA Broadcast\NVIDIA Broadcast.exe'; A='--process-start-args --launch-hidden'; Proc='NVIDIA Broadcast'},
  @{N='Wallpaper Engine'; P='C:\Program Files (x86)\Steam\steamapps\common\wallpaper_engine\wallpaper64.exe'; A='-silent'; Proc='wallpaper64'}
)
if ($Only) { $apps = $apps | Where-Object { $_.N -eq $Only } }
foreach ($a in $apps) { Get-Process $a.Proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue }
Start-Sleep 3
Measure-Hitch 'BASELINE (all suspects off)'
if (-not $Only) { Measure-Hitch 'BASELINE again (noise floor)' }
foreach ($a in $apps) {
  if ($a.A) { Start-Process $a.P -ArgumentList $a.A -WindowStyle Hidden } else { Start-Process $a.P -WindowStyle Hidden }
  Start-Sleep 8
  Measure-Hitch ("+ " + $a.N)
  Get-Process $a.Proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep 3
}
'DONE' | Tee-Object -FilePath $out -Append
