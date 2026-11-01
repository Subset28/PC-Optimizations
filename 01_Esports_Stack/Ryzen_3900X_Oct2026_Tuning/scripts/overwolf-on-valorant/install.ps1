# Admin not required. Removes Overwolf's Windows autostart and installs the Valorant-triggered watcher.
# Undo: re-add the Run value (printed below) and Unregister-ScheduledTask -TaskName 'Overwolf-on-Valorant'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$old = (Get-ItemProperty $run -ErrorAction SilentlyContinue).Overwolf
"Previous Run value (for undo): $old"
Remove-ItemProperty -Path $run -Name Overwolf -ErrorAction SilentlyContinue
$action  = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument "//B //Nologo `"$dir\run-hidden.js`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$set     = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName 'Overwolf-on-Valorant' -Action $action -Trigger $trigger -Settings $set -Description 'Start Overwolf silently only while VALORANT runs' -Force | Out-Null
Start-ScheduledTask -TaskName 'Overwolf-on-Valorant'
