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

## Memory-timing experiment: full results (2026-10-12)

Goal: tighten tFAW 34 -> 24, tRC 74 -> 58, tRFC 560 -> 440 on Micron Rev.E kit at DDR4-3200 (4 single-rank sticks).
**Outcome: the values were written and kept, but never applied.** ZenTimings still read 34 / 74 / 560 after every boot. Everything was reverted.

What was tried, in order, and what each ruled out:

| Attempt | Result |
|---|---|
| Wrote the newer-style entries (one pair per channel) | Stored, ignored |
| Switched the legacy "Ctrl" entries to Manual and set hex values | Stored, ignored |
| Disabled Memory Fast Boot (to force retraining) | No change |
| Set **every** copy at once (7 for tFAW, 7 for tRC, 9 for tRFC, matched on name + token + offset) | Stored, ignored |
| Turned the A-XMP profile **off** to see if it was overriding | **No change in any timing, not even the other secondaries**, so XMP is not what supplies them |
| Set **DRAM Latency Enhance = Enabled** on both copies (not the "msi Setting" option), with Memory Fast Boot off | Stored, **no timing changed at all** (tFAW, tRC, tRFC, tREFI, tRRDL, tWTRL all identical), so it is not the missing "apply" switch |
| Diagnostic: set **Power Down Enable = Enabled** on all 5 copies (a plain on/off controller option that ZenTimings displays) | The BIOS kept Enabled across the reboot, but **ZenTimings still showed PowerDown = Disabled on all four sticks** |

Things worth remembering from this:

- **There are several copies of each timing, and only some are live.** In this export there are three groups of memory entries (around
  offsets 4B0-4F8, 5F4-630 and 6D4-712) plus two older legacy sets. In "Link" timing mode the first group is the one the BIOS menu edits.
  Groups two and three are per-channel pages. Setting all of them is the safe way to be consistent.
- **Some labels are live readouts.** A label such as `tFAW   34` shows the value the memory is running **right now**, and it changes on
  every boot. SCEWIN refuses to import an entry whose label doesn't match the current one (`Unmatched question... prompt: tFAW 28`).
  If you rebuild an import file, copy those labels from an export taken **after the last boot**, not before.
- **What SCEWIN does and doesn't apply here (refined by the last two tests):** DRAM frequency, XMP selection and DRAM voltage **do** take effect
  (a full restore after a CMOS clear took memory from 2667 to 3200 MT/s), and CPU-side settings (PBO limits, boost override) and boot mode stored fine.
  But **everything else on the memory-controller page is stored and ignored**: the timing numbers, DRAM Latency Enhance, and even a plain
  Power Down on/off option. So this is not about timing syntax or missing duplicates; the live memory configuration simply isn't rebuilt from SCEWIN writes.
- Gating switches that were checked and were all correct: `DRAM Timing Mode` = Link, `Memory Try It` = Disabled, `DRAM Latency Enhance`
  = Disabled, `Overclock` = Enabled, `OC Mode` = Customized, `Memory Fast Boot` = Disabled during the test.
- **Not proven:** the likely reason is that the board only turns memory-controller fields into a live memory configuration when they are saved from the BIOS
  menu. That is a theory, not a measured fact. **Conclusion for now: stop using SCEWIN for memory timings and options** and do them from the BIOS menu
  (one change at a time, phone photos and a saved OC profile first). That test has not been done yet.

### Next attempt (plan)

1. Take phone photos of the OC pages, and save an OC profile in the BIOS if it offers one.
2. Do the changes in the BIOS menu, one timing at a time, and check ZenTimings after each. Never touch `DRAM Latency Enhance`.
3. Stress test with TestMem5 (anta777 "Absolut"), several full cycles, and check Windows' WHEA hardware-error log.
4. tREFI is **not exposed** in this BIOS (there is no entry in the export), so don't plan around it.

### What a CMOS clear costs

If a bad change forces a CMOS clear: re-import your saved export (`SCEWIN_64.exe /I /S`), do a full power cycle, and expect two side effects.
Windows Hello PINs stop working because the clear also wipes the firmware TPM. The fix is to move the stale container aside
(stop `NgcSvc`/`NgcCtnrSvc`, rename `C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc` after taking ownership, restart the services)
and set a new PIN. Secure Boot and the UEFI-only/CSM-off boot settings also reset, which matters for games with kernel anti-cheat.

## What was verified

- `CPU Boost Clock Override` reads `Enabled` in a fresh export, and nothing else differs from the original export
  (after reverting the memory experiments). A single-thread clock test was **inconclusive**: it was run under the Balanced power plan,
  while earlier numbers were taken under the gaming plan, so they aren't comparable.
