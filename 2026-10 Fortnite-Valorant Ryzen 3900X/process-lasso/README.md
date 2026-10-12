# Process Lasso setup

Process Lasso keeps the games on their own cores and everything else out of the way. The rules below are the
relevant lines from `prolasso.ini` (the file is UTF-16; edit it with Process Lasso's own UI or a UTF-16-aware editor).

## Core layout (Ryzen 9 3900X, 12 cores / 24 threads)

| Logical CPUs | Used for |
|---|---|
| 0-1 | Left alone for Windows. Core 0 takes ~4x the DPC load of any other core (timer/driver work), so games stay off it. |
| 2-11 | Fortnite / Valorant / CoD. All inside one chiplet, so no cross-chiplet latency. |
| 12-13 | GPU interrupts + network card (RSS) |
| 14-15 | USB (mouse/keyboard) interrupts |
| 12-23 | Every background app (Discord, Chrome, Firefox, Spotify, Wallpaper Engine, NVIDIA Broadcast, Afterburner, launchers, terminals) |

## Rules

```ini
; CPU sets are SOFT affinity (scheduler preference). Preferred over hard affinity masks.
CPUSets=valorant-win64-shipping.exe,(2-11),fortniteclient-win64-shipping.exe,(2-11)

; Hard affinity for background apps -> chiplet 1  (format: exe,group,cpus)
DefaultAffinitiesEx=cod.exe,0,2-11,fortniteclient-win64-shipping.exe,0,2-11,wallpaper64.exe,0,12-23,discord.exe,0,12-23,firefox.exe,0,12-23,chrome.exe,0,12-23,spotify.exe,0,12-23,msiafterburner.exe,0,12-23,nvidia broadcast.exe,0,12-23,riotclientservices.exe,0,12-23,nvcontainer.exe,0,12-23
```


Priorities used: games `High` (Valorant `Real time` by user choice), most background apps `Idle`.

## Things that went wrong (so you don't repeat them)

1. **Be careful hard-pinning `audiodg.exe` (cause not proven).** After a reboot with `audiodg.exe` hard-pinned by a
   rule, Fortnite froze on the loading screen at `FAudioMixerWasapiRenderStream::InitializeHardware`, and the
   Windows Audio service hung while stopping. Killing `audiodg` (so Windows restarted it with default settings)
   and removing the rule cleared it. **That was a single event, not a controlled test:** the pin and a USB
   interrupt-affinity change were both active at the time of the freeze, and the USB change stayed active
   when the game later loaded fine. That points away from the USB change, but a random hung audio engine after
   boot isn't ruled out either. If you want audio helpers off the game's cores, use a *CPU set* (soft) and test
   one change at a time.
2. **Don't leave input-path processes at Idle priority.** `ctfmon.exe`, `textinputhost.exe`, `searchhost.exe` and
   `startmenuexperiencehost.exe` at Idle starve while a game runs: typing in the Start menu search stops working.
3. **Two config files.** The boot-time engine (`ProcessGovernor.exe`, run by a scheduled task) reads
   `C:\ProgramData\ProcessLasso\config\prolasso.ini`; the GUI edits `%LOCALAPPDATA%\ProcessLasso\config\prolasso.ini`.
   If the ProgramData copy is stale, none of your rules run at boot. Edit both (or copy local over ProgramData), then
   restart exactly **one** governor.
4. **A power-plan rule can cost a lot of fps.** A rule like `DefaultPowerSchemes=claude.exe;power saver` forces the
   Power saver plan whenever that app runs. Removing it took Fortnite from 108 to 188 fps average.
5. **Easy Anti-Cheat (Fortnite) blocks outside tools from setting its affinity/priority.** Those rules don't apply to
   the real game process. Per-game *power plan* switching still works. Valorant's rules do apply.
6. **Startup plan:** set `StartWithPowerPlan=Balanced` and let Process Lasso switch to your gaming plan when a game
   starts. Energy Saver kicking in after 20 idle minutes is expected.
