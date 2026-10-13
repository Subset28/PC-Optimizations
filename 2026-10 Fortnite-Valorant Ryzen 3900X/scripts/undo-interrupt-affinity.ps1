# Deletes the Affinity Policy keys this repo created (back to Windows default placement).
Get-PnpDevice -Status OK | Where-Object { $_.Class -in 'Display','USB' } | ForEach-Object {
  $key = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($_.InstanceId)\Device Parameters\Interrupt Management\Affinity Policy"
  if (Test-Path $key) { Remove-Item $key -Recurse -Force; "removed: $($_.InstanceId)" }
}
Set-NetAdapterRss -Name Ethernet -BaseProcessorNumber 0 -MaxProcessors 4
"Reboot to apply."
