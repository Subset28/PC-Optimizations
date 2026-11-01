# Starts Overwolf silently only while VALORANT is running. Never closes Overwolf.
# Run hidden at logon by the 'Overwolf-on-Valorant' scheduled task (see run-hidden.js).
param([string]$Target = 'VALORANT-Win64-Shipping')
$launcher = 'C:\Program Files (x86)\Overwolf\OverwolfLauncher.exe'
while ($true) {
  if ((Get-Process -Name $Target -ErrorAction SilentlyContinue) -and -not (Get-Process -Name 'Overwolf' -ErrorAction SilentlyContinue)) {
    if (Test-Path $launcher) { Start-Process -FilePath $launcher -ArgumentList '-overwolfsilent' -WindowStyle Hidden }
    Start-Sleep -Seconds 60   # give it time to come up before checking again
  }
  Start-Sleep -Seconds 5
}
