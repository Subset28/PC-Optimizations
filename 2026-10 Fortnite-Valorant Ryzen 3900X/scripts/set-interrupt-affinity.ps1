# Pins hardware-interrupt handling for the GPU, USB host controllers and (via RSS) the network card
# to a chosen set of logical CPUs, so a game thread never shares a core with them.
# ADMIN PowerShell. Reboot afterwards. Undo: scripts/undo-interrupt-affinity.ps1
#
# Ryzen 9 3900X layout: logical CPUs 0-11 = chiplet 0, 12-23 = chiplet 1 (2 threads per core).
# Here the game gets chiplet 0 (cores 2-11, via Process Lasso) and devices get chiplet 1.
param(
  [int[]]$GpuCpus = @(12,13),
  [int[]]$UsbCpus = @(14,15),
  [int]$NicBaseCpu = 12,
  [int]$NicMaxProcessors = 2,
  [string]$NicName = 'Ethernet'
)
function Set-IrqAffinity([string]$InstanceId, [int[]]$Cpus) {
  [uint64]$mask = 0; foreach ($c in $Cpus) { $mask = $mask -bor ([uint64]1 -shl $c) }
  $bytes = [BitConverter]::GetBytes($mask)
  $len = [Math]::Ceiling(([Math]::Max(($Cpus | Measure-Object -Maximum).Maximum, 0) + 1) / 8)
  $key = "HKLM:\SYSTEM\CurrentControlSet\Enum\$InstanceId\Device Parameters\Interrupt Management\Affinity Policy"
  New-Item $key -Force | Out-Null
  Set-ItemProperty $key DevicePolicy 4 -Type DWord                       # 4 = run on the specified processors
  Set-ItemProperty $key AssignmentSetOverride ([byte[]]$bytes[0..($len - 1)]) -Type Binary
  "{0}  ->  CPUs {1}" -f $InstanceId, ($Cpus -join ',')
}
Get-PnpDevice -Class Display -Status OK | Where-Object FriendlyName -match 'NVIDIA|AMD|Radeon' |
  ForEach-Object { Set-IrqAffinity $_.InstanceId $GpuCpus }
Get-PnpDevice -Class USB -Status OK | Where-Object FriendlyName -match 'xHCI|eXtensible|Host Controller' |
  ForEach-Object { Set-IrqAffinity $_.InstanceId $UsbCpus }
Set-NetAdapterRss -Name $NicName -BaseProcessorNumber $NicBaseCpu -MaxProcessors $NicMaxProcessors
"NIC '$NicName' RSS -> base CPU $NicBaseCpu, $NicMaxProcessors processors. Reboot to apply the device interrupts."
