# Restores the defaults (hypervisor + VBS back on). ADMIN PowerShell, then restart.
bcdedit /set '{current}' isolatedcontext Yes
bcdedit /deletevalue '{current}' vsmlaunchtype
bcdedit /set hypervisorlaunchtype auto
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello' Enabled 1 -Type DWord
Remove-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' EnableVirtualizationBasedSecurity -ErrorAction SilentlyContinue
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
"Restart to apply."
