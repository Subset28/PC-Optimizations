# Run in an ADMIN PowerShell. Create a restore point first (see README).
# Undo: scripts/undo-boot-and-services.ps1
bcdedit /set hypervisorlaunchtype off     # no bare hypervisor underneath Windows (pair with reg/apply/02)
bcdedit /set disabledynamictick yes       # stable timer tick
Set-Service SysMain -StartupType Disabled # NVMe doesn't need background prefetch
Stop-Service SysMain -Force -ErrorAction SilentlyContinue
"Done. Reboot to apply the boot settings."
