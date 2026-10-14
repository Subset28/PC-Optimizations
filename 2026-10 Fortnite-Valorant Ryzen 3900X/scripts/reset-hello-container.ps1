# Fixes "Windows Hello PIN won't set / PIN stopped working" after a firmware-TPM reset (CMOS clear) or after turning VBS off.
# Cause: a stale Hello container (its keys lived in the TPM or in VBS) blocks creating a new one.
# ADMIN PowerShell. The old folder is renamed, not deleted. Afterwards: Settings > Accounts > Sign-in options > PIN > "I forgot my PIN".
$ngc = 'C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc'
Stop-Service NgcCtnrSvc -Force; Stop-Service NgcSvc -Force -ErrorAction SilentlyContinue
takeown /f $ngc /r /d y | Out-Null
icacls $ngc /grant "*S-1-5-32-544:(OI)(CI)F" /t /c | Out-Null
Rename-Item $ngc ("{0}.old-{1}" -f $ngc, (Get-Date -Format yyyyMMdd-HHmmss))
Start-Service NgcSvc; Start-Service NgcCtnrSvc
"Done. Set a new PIN now."
