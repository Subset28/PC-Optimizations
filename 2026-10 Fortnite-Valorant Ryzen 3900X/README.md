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

**After the hypervisor was finally turned off** (see the section below), six consecutive 60-second windows of a **live Battle Royale match**
(uncapped, so not directly comparable with the Creative-map column above):

| Window | Avg | 1% low | 0.1% low | Stutters (>2x median) | Big (>3x) | Worst frame |
|---|---|---|---|---|---|---|
| 1 | 269 | 125 | 73 | 256 | 45 | 17 ms |
| 2 | 273 | 146 | 105 | 140 | 3 | 11 ms |
| 3 | 256 | 110 | 30 | 257 | 129 | 34 ms |
| 4 | 312 | 30 | 23 | 655 | 478 | 100 ms |
| 5 | 229 | 47 | 30 | 559 | 374 | 34 ms |
| 6 | 253 | 148 | 108 | 65 | 0 | 11 ms |

Median frame time over the six windows was 3.44 ms (earlier Creative baseline 3.58 ms, about 4% faster). The best windows (2 and 6) match or beat the
baseline (1% low 146-148, almost no big stutters); windows 4 and 5 look like match transitions or heavy scenes. **Treat this as noisy and
inconclusive**: different scene every minute, and the capture tool cannot tell a loading screen from gameplay. It is not evidence that the
hypervisor change helped or hurt.

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
| 12 | RTSS uninstalled; Afterburner removed from startup (measured interrupt source) | RTSS `Uninstall.exe`, Task Scheduler | reinstall |
| 13 | GPU overclock returned to stock (game is CPU-bound; ran hotter, needed an extra tool) | Afterburner startup profile zeroed | re-apply your profile |
| 14 | Process Lasso: input processes (`ctfmon`, `textinputhost`, `searchhost`) taken off Idle priority so typing works with a game open | Process Lasso UI | re-add rule |
| 15 | Hypervisor / VBS **actually** off (the registry flag and `hypervisorlaunchtype` alone were not enough) | `scripts/disable-hypervisor-fully.ps1` | `scripts/undo-hypervisor.ps1` |
| 16 | Windows Hello PIN broke as a side effect, fixed by moving the stale container aside | `scripts/reset-hello-container.ps1` | n/a |

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
6. Not applied: Power Supply Idle Control -> Typical Current Idle, DF C-states -> Disabled. Memory timings and DDR4-3600 with a matching
   Infinity Fabric clock are the biggest remaining lever on Zen 2: **do those by hand in the BIOS menu**. SCEWIN stored memory timing
   values on this board but they were never applied (see `bios/README.md`).
7. Read `bios/README.md` before importing anything: it has the recovery procedure and the mistake to avoid (tokens repeat, so match name + token + offset).

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

## The hypervisor that wouldn't turn off

Symptom: `(Get-CimInstance Win32_ComputerSystem).HypervisorPresent` stayed **True** and VBS status stayed **2 (running)** even though
`reg/apply/02-disable-vbs-hvci.reg` was applied, `hypervisorlaunchtype` was Off and Memory Integrity was off.
A running hypervisor puts nested address translation under every memory access, which is why it was worth chasing for a CPU/memory-bound game thread.

What actually kept it on, found one layer at a time:

1. **`isolatedcontext Yes`** in the Windows 11 boot entry (loads the secure kernel) and `vsmlaunchtype` unset.
2. **Windows Hello "Enhanced Sign-in Security"**: `HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello\Enabled = 1`
   keeps VBS and the hypervisor running on its own, even with every other switch off.
3. **The Virtual Machine Platform feature** was enabled. Disabling it **resets `hypervisorlaunchtype`**, so the value has to be set to Off *again afterwards*
   (the first attempt silently lost it; a restart showed the hypervisor still running).
4. A second `isolatedcontext Yes` belongs to the *Resume from Hibernate* boot object and does not matter for a normal boot.

`scripts/disable-hypervisor-fully.ps1` does all of it in the right order, and `scripts/undo-hypervisor.ps1` reverses it. After the change `HypervisorPresent` was False,
VBS status 0 and `HvHost` stopped. **Use Restart, not Shut down**, to test it (Fast Startup can resume the old session).

Side effects and trade-offs, stated plainly:
- It removes Enhanced Sign-in Security and VBS-based protections (Hello keys stay TPM-backed). That is a deliberate security trade-off for a dedicated gaming PC.
- **The Windows Hello PIN stopped working** (the container's keys were protected by the virtualization layer). `scripts/reset-hello-container.ps1` fixes it.
- WSL2, Windows Sandbox and other hypervisor-based tools stop working. None were installed on this machine.
- Expected size of the benefit: a few percent at best (median frame 3.58 -> 3.44 ms in the captures above is consistent with that, but the data is noisy).

## Stutter investigation (what I measured, not what I assumed)

Capture (uncapped Fortnite, ~24k frames): median frame 3.58 ms, p99 6.9 ms, **187 spikes over 7 ms (about 2 per second)**, plus one 212 ms hitch.
Every one of those spikes was the game's own CPU thread running long (20-35 ms); the GPU was never the cause (about 1.7 ms of GPU
work per frame vs about 3.4 ms of CPU). Presentation was already ideal (Independent Flip on every frame, input-to-photon median 1.3 ms).
Capping at 240 gave visibly steadier frame times than running uncapped.

- Windows reported Fortnite's CPU set as exactly cores 2-11, but one hot game thread still ran on a core outside it. That is
  the engine setting its own thread affinity, which a soft CPU set and Process Lasso can't override.
- **Synthetic test** (`scripts/hitch-test.ps1`): a spin-loop thread pinned to a game core counts how often it gets interrupted.
  Interruptions above 100 us per 15 s: baseline 0-3 (noise up to about 130 on some runs), **FanControl 829-1,372**, **MSI Afterburner 232-335**,
  Wallpaper Engine 86, NVIDIA Broadcast 0. All were under 0.5 ms, so they add frame-time jitter but cannot explain 20-35 ms stalls.
  Trimming FanControl's sensor modules or slowing Afterburner's polling did not help, so I reverted both.
- Actions taken from that: RTSS uninstalled, Afterburner removed from startup. Fan control stays with FanControl; the cost is a
  trade-off the owner chose (fans under one tool vs a small jitter). Setting curves in the BIOS and closing FanControl while gaming would remove it.
- A GPU overclock (+175 MHz core, +750 MHz memory, raised voltage and power limit, custom V/F curve) was **returned to stock**: both games are CPU-bound,
  so it bought no frames, and it ran the card hotter and needed an extra tool running. The overclock persists after Afterburner exits,
  until a reboot or driver reset.
- The remaining hitches are the engine's own main-thread work. The most likely lever left is memory latency (see below).

## Memory (Micron Rev.E 3200 CL16 x4, single-rank)

ZenTimings showed XMP active (1.35 V, CL16-18-18-36) with **loose motherboard-default secondary timings**
(tRFC 560 / 350 ns, tREFI 12480, tFAW 34, tRC 74, tRRDL 8, tWTRL 12, Gear Down on). Rev.E is a good tuning die, so tighter secondaries at 3200,
then 3466/3600 with FCLK 1800, is the next real lever. Four sticks (two per channel) make the higher speeds harder than two. Test with
TestMem5 (anta777 "Absolut" config) and check Windows' WHEA events.

**Status: not done.** An attempt to apply tFAW 24 / tRC 58 / tRFC 440 through SCEWIN (every duplicate copy set, gating switches checked, XMP
switched off to test an override) wrote the values but the board never applied them, so everything was reverted. Two follow-up tests (DRAM Latency Enhance = Enabled, and a Power Down Enable on/off diagnostic) were also stored but ignored, so on this board SCEWIN reaches DRAM frequency/XMP/voltage but not the other memory-controller settings. Details, dead ends and the
plan for the next attempt (do it from the BIOS menu, with a saved profile and phone photos first) are in `bios/README.md`.
A bad BIOS change also forced a CMOS clear once, which wiped the firmware TPM and broke the Windows Hello PIN; the fix is documented there too.

## Tools worth having

ZenTimings (live memory timings/voltage/FCLK), TestMem5 (memory stress), PresentMon (frame data). Download from each project's official
GitHub release and verify the checksum when one is published.

## Measuring

- `scripts/fps-go.ps1` (admin PowerShell): checks the state above, runs a single-thread boost test, then captures 60 s
  of the running game with PresentMon and prints average / 1% / 0.1% lows, share of frames >= 240 fps, and ping.
- `scripts/fps-watch.ps1`: leave it running hidden. While Fortnite or Valorant runs, it captures repeated 60 s windows and appends one line per window
  to `fps-watch-results.txt` in your profile folder. Each line is tagged `MENU` (flat lobby cap), `LOADING/LOW` or `MATCH`, and includes median frame time,
  the count of frames over 2x and 3x the median ("stutters"), the worst frame, and RAM used/committed. Only trust `MATCH` lines.
  (An earlier version captured 3 minutes after launch, which landed in the lobby and produced a misleading result.)
  PresentMon needs admin rights or membership in the **Performance Log Users** group (sign out/in after adding yourself).
- `scripts/hitch-test.ps1`: synthetic interference test (see Stutter investigation). `-Only "FanControl"` tests a single tool.
- Capture in a real match, not the lobby, and lift or keep the frame cap consistently between runs.
