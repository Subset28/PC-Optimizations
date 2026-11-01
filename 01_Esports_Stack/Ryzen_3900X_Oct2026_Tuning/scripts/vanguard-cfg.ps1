# Vanguard (VAN9002) requires Control Flow Guard. Run as admin.
# Enables CFG system-wide, and explicitly for the Valorant game binary.
# Undo: Set-ProcessMitigation -System -Remove -Enable CFG
#       Set-ProcessMitigation -Name VALORANT-Win64-Shipping.exe -Remove
Set-ProcessMitigation -System -Enable CFG
Set-ProcessMitigation -Name VALORANT-Win64-Shipping.exe -Enable CFG
"System CFG: " + (Get-ProcessMitigation -System).CFG.Enable
"Valorant CFG: " + (Get-ProcessMitigation -Name VALORANT-Win64-Shipping.exe).CFG.Enable
