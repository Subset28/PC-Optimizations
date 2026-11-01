# Turns the Windows hypervisor / VBS fully OFF. ADMIN PowerShell, then RESTART (not Shut down).
# Why every step: on Windows 11 25H2 the three obvious switches were NOT enough on their own.
#   1. hypervisorlaunchtype Off          - not enough alone
#   2. DeviceGuard registry flags = 0    - not enough alone (see reg/apply/02)
#   3. Windows Hello "Enhanced Sign-in Security" (DeviceGuard\Scenarios\WindowsHello) keeps VBS running by itself
#   4. isolatedcontext / vsmlaunchtype in the boot entry
#   5. Disabling the Virtual Machine Platform feature RESETS hypervisorlaunchtype, so it must be set AGAIN afterwards.
# Security trade-off: Enhanced Sign-in Security and VBS-based protections are removed. Hello keys stay TPM-backed.
# Side effect: the Windows Hello PIN usually stops working; run scripts/reset-hello-container.ps1 and set a new PIN.
# Create a restore point first:  Checkpoint-Computer -Description "pre-hypervisor-fix" -RestorePointType MODIFY_SETTINGS
bcdedit /export "$env:USERPROFILE\bcd-backup-before-hypervisor-fix"
bcdedit /set '{current}' isolatedcontext No
bcdedit /set '{current}' vsmlaunchtype Off
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' EnableVirtualizationBasedSecurity 0 -Type DWord
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' Enabled 0 -Type DWord
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello' Enabled 0 -Type DWord
Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart   # skip if you use WSL2 / Windows Sandbox
bcdedit /set hypervisorlaunchtype off          # AFTER the feature removal (it resets this value)
bcdedit /set '{current}' hypervisorlaunchtype off
"Done. RESTART now, then check:  (Get-CimInstance Win32_ComputerSystem).HypervisorPresent  -> False   and VBS status 0"
