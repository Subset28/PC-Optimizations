# Fortnite + Valorant at 240 Hz: Ryzen 9 3900X / RTX 3070 Ti (October 2026)

A documented, reversible tuning pass on a Windows 11 25H2 gaming PC (2560x1440 @ 240 Hz). Both games are
**CPU-bound on one hot thread** (GPU ~30%), so everything here is about the CPU, scheduling, interrupts and timers,
not graphics settings.

> Use at your own risk. Create a restore point first (`Checkpoint-Computer -Description "before tuning"`),
> and keep the BIOS export described below. Every registry/script change has an undo file next to it.

## Hardware

Ryzen 9 3900X (Zen 2, 2 chiplets x 2 CCX), RTX 3070 Ti, MSI B450 Gaming Plus Max, 4x8 GB Ballistix 3200 CL16 (Micron Rev.E),
NVMe SSD, Realtek 1 GbE (wired), Windows 11 25H2 (build 26200).

## Results (Fortnite, PresentMon via CapFrameX-style metrics)

| | Start of session | After scheduling fixes | After BIOS boost + interrupt pinning + reboot |
|---|---|---|---|
| Average fps | 108 | 188 | **271** (uncapped) |
| 1% low | 20 | 113 | **147** |
| 0.1% low | 47 (best earlier) | 47 | **111** |
| Frames >= 240 fps | n/a | n/a | 85% |

Caveats, stated plainly:
- The last column is **one 90-second capture in a Creative map with the frame cap removed**. A 100-player Battle Royale
  match is heavier, so expect less there. Treat 271 as a best case, not a promise.
- Several changes landed together with a reboot, so the individual contribution of each is **not** measured.
- Valorant has only an older baseline (avg 228-239, 1% low ~138). It hasn't been re-captured yet.
- The biggest single win by far was removing a Process Lasso power-plan rule (108 -> 188). Everything after is smaller.

## What was changed

| # | Change | Where | Undo |
|---|---|---|---|
| 1 | Hardware GPU scheduling on, global 1 ms timer requests | `reg/apply/01-graphics-timer.reg` | `reg/undo/01-...` |
| 2 | Virtualization-based security + memory integrity off, hypervisor off | `reg/apply/02-disable-vbs-hvci.reg` + `scripts/apply-boot-and-services.ps1` | `reg/undo/02-...` + `scripts/undo-boot-and-services.ps1` |
| 3 | Kernel/drivers kept in RAM (`DisablePagingExecutive`) | `reg/apply/03-kernel-in-ram.reg` | `reg/undo/03-...` |
| 4 | Fortnite: no forced "maximized windowed" (true fullscreen) | `reg/apply/04-fortnite-fullscreen-flags.reg` | `reg/undo/04-...` |
| 5 | Game Mode on, Game DVR off | `reg/apply/05-game-mode.reg` | `reg/undo/05-...` |
| 6 | Dynamic tick off, SysMain off | `scripts/apply-boot-and-services.ps1` | `scripts/undo-boot-and-services.ps1` |
| 7 | GPU, USB and network-card interrupts moved to chiplet 1 (CPUs 12-15) | `scripts/set-interrupt-affinity.ps1` | `scripts/undo-interrupt-affinity.ps1` |
| 8 | Games on CPUs 2-11, background apps on 12-23, input/helper priorities fixed | `process-lasso/README.md` | Process Lasso UI |
| 9 | BIOS: **CPU Boost Clock Override** Disabled -> Enabled | `bios/change-boost-override-only.txt` | re-import your own original export |
| 10 | Bloat removed: PC Manager, Phone Link, Cross Device, Edge Game Assist, Adobe notifier | `Get-AppxPackage <name> \| Remove-AppxPackage` | reinstall from Store |
| 11 | Fortnite: grass off, true fullscreen, frame cap 240 | in-game / `GameUserSettings.ini` | in-game |

Already tuned beforehand (verified, no change needed): NIC power saving/offloads off, Nagle off (`TcpAckFrequency=1`,
`TCPNoDelay=1`), receive coalescing off, Cloudflare DNS, MPO off (`OverlayTestMode=5`), `Win32PrioritySeparation=38`,
gaming power plan with core parking off and USB selective suspend / PCIe link power management off.

## How to apply

1. Restore point + **export your BIOS** first (see BIOS section).
2. Double-click the `.reg` files in `reg/apply/` (admin). Review each one; they are short.
3. Admin PowerShell: `scripts/apply-boot-and-services.ps1`, then `scripts/set-interrupt-affinity.ps1`
   (adjust the CPU numbers for your chip: check which logical CPUs belong to which chiplet first).
4. Set up Process Lasso per `process-lasso/README.md`.
5. Reboot, play a few matches, then measure with `scripts/fps-go.ps1` or `scripts/fps-watch.ps1`.

## BIOS (SCEWIN / AMISCE), with a recovery route

1. Export first: `SCEWIN_64.exe /O /S nvram-original.txt` and keep that file safe. **Do not publish your export**: it
   can contain serial numbers and other identifiers. That's why only the one-setting change file is in this repo.
2. The import file here changes one setting: `CPU Boost Clock Override` (token 70) `Disabled -> Enabled`. The `*`
   marks the selected option, and it must sit on `[01]Enabled`.
3. Apply: `SCEWIN_64.exe /I /S change-boost-override-only.txt`. It reports "Script file imported successfully";
   some controls need a power cycle.
4. **Verify** by exporting again and diffing against the original: only that option (plus the header/checksum) should differ.
5. This file is for a MSI B450 Gaming Plus Max BIOS. Tokens/offsets are board- and BIOS-specific. Do not import it on
   a different board. Recovery if anything misbehaves: clear CMOS, boot, re-import your original export.
6. Not applied yet (prepared): Power Supply Idle Control -> Typical Current Idle, DF C-states -> Disabled, and the
   biggest remaining lever on Zen 2: DDR4-3600 with a matching Infinity Fabric clock (do that by hand in the BIOS).

## Findings worth knowing

- **VBS/HVCI off is a security trade-off.** It removes a layer that protects against some kernel-level attacks. It's the
  user's call on a dedicated gaming PC; revert with the undo files if you'd rather keep it.
- **Curve Optimizer is Zen 3+ only.** There's none on a 3900X; don't go looking.
- **Easy Anti-Cheat blocks affinity/priority changes on Fortnite**, so Lasso's per-process rules for it don't stick.
- **Hardware IDs differ per machine.** The interrupt script finds devices by class and name instead of
  hard-coding IDs.
- **Network floor:** about 8 ms to the nearest AWS region (us-east-1). The rest is the ISP's first hop (median 5 ms,
  spikes to ~58 ms). Nothing on the PC changes that.
- **Placebo tweaks skipped on purpose:** mouse/keyboard queue sizes, AFD UDP threshold, disabling the HPET device,
  Fortnite `Engine.ini` console variables (Easy Anti-Cheat risk).
- **One unexplained freeze.** After the reboot that applied the BIOS change and the USB interrupt pinning, Fortnite froze
  on the loading screen while opening the audio device, and the Windows Audio service hung while stopping. Killing
  `audiodg.exe` fixed it. Two changes were active at that moment (a Process Lasso hard-pin on `audiodg.exe` and the USB
  interrupt move), and the root cause was **not isolated**. The USB change stayed active when the game later loaded
  fine, which makes it the weaker suspect, but one event proves nothing. If you copy this setup and hit the same freeze,
  test one change at a time. Use `scripts/undo-interrupt-affinity.ps1` to rule the USB change out.
- **Process Lasso pitfalls** (stale boot config, Idle priority on input processes, the `audiodg` pin) are in
  `process-lasso/README.md`.

## Measuring

- `scripts/fps-go.ps1` (admin PowerShell): checks the state above, runs a single-thread boost test, then captures 60 s
  of the running game with PresentMon and prints average / 1% / 0.1% lows, share of frames >= 240 fps, and ping.
- `scripts/fps-watch.ps1`: leave it running hidden. It waits for Fortnite or Valorant, lets the match run 3 minutes,
  captures 90 s and appends the result to `fps-watch-results.txt` in your profile folder.
  PresentMon needs admin rights or membership in the **Performance Log Users** group (sign out/in after adding yourself).
- Capture in a real match, not the lobby, and lift or keep the frame cap consistently between runs.
