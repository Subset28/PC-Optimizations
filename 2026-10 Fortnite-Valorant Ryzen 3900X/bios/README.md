# BIOS notes (SCEWIN / AMISCE on an MSI B450 Gaming Plus Max)

## What is in this folder

- `change-boost-override-only.txt`: a one-setting import file (`CPU Boost Clock Override`, Disabled -> Enabled).
  It is specific to this board and BIOS version. Do not import it elsewhere.
- **No full BIOS export is published here, on purpose.** An export can contain serial numbers and other identifiers.
  Make your own and keep it somewhere private.

## Before you touch anything

1. Create a Windows restore point (it does not cover the BIOS, but covers the rest).
2. Export your BIOS: `SCEWIN_64.exe /O /S nvram-original.txt`. Keep it, plus a copy **off the PC** (USB stick or private cloud).
3. After each change, export again and diff against the previous export. Only the setting you meant to change
   (plus the header/checksum lines) should differ.

## Recovery if the PC won't show a picture or won't boot

1. Clear CMOS (board jumper/button, or battery out for ~2 minutes with the PSU switched off). That resets the BIOS to defaults.
2. Boot into Windows. Use one monitor on the GPU output; try the other output if there is no picture.
3. Import your saved export: `SCEWIN_64.exe /I /S nvram-known-good.txt`, then do a full power cycle.
   You never need to see the BIOS screen to restore settings this way.

## Lessons (these cost real time)

- **Tokens are not unique.** In one export, token `35` is both "PWM Ramping" and "Tfaw Ctrl". If you build an import file by
  token number alone you will edit the wrong setting. Always match **name + token + offset** together, and check every
  entry against your live export before importing. Only import files you have checked line by line.
- **Writing a value is not the same as it being used.** On this board, SCEWIN stored memory timing values
  (tFAW, switched to Manual, with Memory Fast Boot disabled) and a re-export showed them, yet ZenTimings still showed the old
  timing after several reboots. Treat the *live* readout (ZenTimings, `fps-go.ps1`) as the truth, not the export.
  The cause was not isolated (candidates: needs a cold power cycle, or the board only honours changes made through its own
  menu). Memory timings are safer to change by hand in the BIOS menu.
- **Each setting duplicates.** Many timings exist in several copies (per memory channel, a legacy set and a newer set), each with
  its own Auto/Manual switch. A value in a copy whose switch is on Auto is only a stored placeholder.
- A readback diff is the safety net: if it shows anything beyond the intended lines, stop and restore from your export.

## What was verified

- `CPU Boost Clock Override` reads `Enabled` in a fresh export, and nothing else differs from the original export
  (after reverting the memory experiments). A single-thread clock test was **inconclusive**: it was run under the Balanced power plan,
  while earlier numbers were taken under the gaming plan, so they aren't comparable.
