bcdedit /set hypervisorlaunchtype auto
bcdedit /deletevalue disabledynamictick
Set-Service SysMain -StartupType Automatic
Start-Service SysMain
"Reboot to apply."
