# 🖥️ Windows 11 Esports & Gaming Optimization Guide

A comprehensive, step-by-step manual configuration guide for Windows 11 systems tuned for ultra-low latency, maximum sustained framerates, and zero micro-stutter in competitive esports titles (*Fortnite*, *Valorant*, *Call of Duty*).

---

## 1. 🎮 Windows Gaming Settings

Navigate to **Windows Settings (`Win + I`) > Gaming**:

* **Xbox Game Bar:**
  * Toggle **OFF**: `Settings > Gaming > Xbox Game Bar`.
  * *Reason:* Prevents background DVR overlay hooks and DWM injection that can cause frame pacing variance.
* **Captures:**
  * Toggle **OFF**: `Settings > Gaming > Captures > Record what happened`.
  * Set **Max recording length** to minimum or disable background recording.
* **Game Mode:**
  * Toggle **ON**: `Settings > Gaming > Game Mode`.
  * *Reason:* Windows prioritizes CPU thread allocation to the foreground game process and suppresses Windows Update driver installations during gameplay.

---

## 2. ⚡ Graphics & Display Settings

Navigate to **Windows Settings > System > Display > Graphics > Default Graphics Settings**:

* **Hardware-Accelerated GPU Scheduling (HAGS):**
  * Toggle **ON**.
  * *Reason:* Offloads high-frequency scheduling tasks directly to the RTX GPU's dedicated scheduling processor, reducing CPU draw-call latency and enabling NVIDIA Reflex low-latency modes.
* **Optimizations for Windowed Games:**
  * Toggle **ON**.
  * *Reason:* Upgrades legacy DX10/DX11 borderless windowed presentation queues to the modern DX12 Independent Flip (`DirectFlip`) model, giving windowed games true fullscreen latency.
* **Variable Refresh Rate (VRR):**
  * Toggle **ON** (if using a G-Sync Compatible or FreeSync high-refresh-rate monitor).

---

## 3. 🏎️ System Performance Options

Open the Run dialog (`Win + R`), type **`sysdm.cpl`**, press Enter, click the **Advanced** tab, and click **Settings** under *Performance*:

* Select **Custom** and disable heavy graphical animations while preserving readability:
  * ✅ *Show thumbnails instead of icons* (keeps image previews fast)
  * ✅ *Smooth edges of screen fonts* (keeps in-game overlay and desktop text crisp)
  * ❌ Uncheck *Animate windows when minimizing and maximizing*
  * ❌ Uncheck *Animations in the taskbar*
  * ❌ Uncheck *Fade or slide menus into view*
  * ❌ Uncheck *Show shadows under windows*

---

## 4. 🧹 Storage Sense & Disk Hygiene

Navigate to **Windows Settings > System > Storage**:

* **Storage Sense:**
  * Toggle **ON**.
  * Click into **Storage Sense** and configure it to run monthly or when free disk space is low.
  * Ensures temporary caches, error reports, and outdated Windows installation files (`Windows.old`) are automatically cleaned without requiring 3rd-party cleaners.
