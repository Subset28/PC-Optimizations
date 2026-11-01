# ⚡ Armaan's Ultimate PC Optimization Guide (2026 Esports Edition)
**Maintained by Armaan Tech Tips** · *Battle-Tested for Locked 240+ FPS, Zero Bufferbloat, and Sub-Millisecond Input Latency*

[![Anti-Cheat Safe](https://img.shields.io/badge/Anti--Cheat-100%25%20Compliant%20(Vanguard%20%2B%20EAC)-00c853?style=for-the-badge&logo=shield)](file:///C:/Users/Armaa/Desktop/PC-Optimizations/2026_Esports_Stack/Verify-AntiCheat.ps1)
[![Windows 11 Verified](https://img.shields.io/badge/Windows%2011-Build%2026200%20Ready-0078d4?style=for-the-badge&logo=windows)](file:///C:/Users/Armaa/Desktop/PC-Optimizations/2026_Esports_Stack/Apply-EsportsTuning.ps1)
[![Benchmarks Verified](https://img.shields.io/badge/Intel%20PresentMon-%2B22%25%20FPS%20%7C%20%2B30.3%25%20Lows-ff6d00?style=for-the-badge&logo=intel)](file:///C:/Users/Armaa/Desktop/PC-Optimizations/2026_Esports_Stack/Benchmarks/Fortnite_Creative_Benchmark_Results.md)

Welcome to the modernized **2026 Edition** of my PC Optimization Guide. Over the past couple of years of competitive play, deep Windows kernel debugging, and network packet analysis, I've completely overhauled this repository. 

Gone are the days of blind registry sweeping that trips anti-cheats or breaks Windows Update. This guide delivers **proven, kernel-safe, hardware-level performance engineering** focused specifically on **Fortnite**, **Valorant**, and competitive esports titles.

---

## ⚙️ **Reference Rig Specifications**
The battleground where every tweak in this repository was benchmarked and proven:

| Component | Specification |
| :--- | :--- |
| **Operating System** | Windows 11 Pro, Version 24H2 (OS Build 26200) |
| **Processor (CPU)** | AMD Ryzen 9 3900X (12 Cores, 24 Threads, Dual-CCD Zen 2) |
| **Graphics (GPU)** | NVIDIA GeForce RTX 3070 Ti (8 GB GDDR6X, Driver 621.01) |
| **Memory (RAM)** | 32 GB DDR4-3200 (4x8 GB Quad-Channel, Low-Latency Timings) |
| **Storage (NVMe)** | 1 TB SanDisk Ultra 3D NVMe SSD (PCIe Gen 3 x4) |
| **Network (NIC)** | Realtek PCIe GbE Family Controller (1.0 Gbps Full Duplex) |
| **Primary Display** | Samsung Odyssey G7 (2560x1440 @ 240Hz, 1ms G-Sync Compatible) |
| **Secondary Display**| ASUS VS247 (1920x1080 @ 70Hz) |

---

## 🏆 **Real-World Benchmark Proof (Intel PresentMon 2.6.0)**
*Captured across 82,400+ frames during active 10-round Creative matches at 1440p (DXGI Hardware Independent Flip):*

| Metric | Pre-Optimization (Baseline) | Post-Optimization (2026 Stack) | Performance Gain |
| :--- | :--- | :--- | :--- |
| **Average FPS** | 232.7 FPS | **283.9 FPS** | **+51.2 FPS (+22.0% Overall Gain)** 🔥 |
| **Median FPS** | 258.6 FPS | **305.8 FPS** | **+47.2 FPS (+18.3% Core Rate)** 🔥 |
| **1% Low FPS** | 100.7 FPS | **131.3 FPS** | **+30.6 FPS (+30.3% Stutter Elimination)** 🔥 |
| **Median Frame Time** | 3.87 ms | **3.27 ms** | **-0.60 ms faster frame render** |
| **99th% Frame Time (1% Low)**| 9.93 ms | **7.62 ms** | **-2.31 ms frame-drop window** |
| **Frame Time Jitter (Std Dev)**| 4.06 ms | **3.11 ms** | **-23.4% frame-time variance reduction** |
| **Avg GPU Render Time** | 4.29 ms | **3.52 ms** | **-18.0% GPU pipeline latency** |
| **Avg CPU Draw-Call Time** | 3.93 ms | **3.21 ms** | **-18.3% CPU scheduling overhead** |

---

## 🚀 **The 2026 Optimization Breakthroughs**

### 1. 🛡️ 100% Anti-Cheat Safe (Riot Vanguard & Easy Anti-Cheat)
Many online optimization scripts use dangerous tweaks (like disabling Driver Signature Enforcement or toggling `testsigning on`) that immediately trigger **Riot Vanguard Error VAN 9003 / VAN 1067** or EAC game bans. 
- **Full Compliance:** Every optimization here runs natively within official Microsoft Windows HAL APIs.
- **Audited State:** UEFI Secure Boot, TPM 2.0, and Kernel Code Integrity remain active and 100% clean. Run `Verify-AntiCheat.ps1` to verify your machine.

### 2. ⚡ The `Blaster Boy 28` Power Plan + Dynamic Switching
- **The Problem:** Locking all 24 CPU threads at 100% clock speeds 24/7 wastes 40–60W at idle, pushes CPU temps 10–15°C higher, and creates unnecessary fan noise while doing daily tasks.
- **The Solution:** We implement **Dynamic Energy Switching**. The system idles cool and quiet on **Balanced**. Using Process Lasso's background engine (`processgovernor.exe`), the OS automatically snaps into **`Blaster Boy 28`** the millisecond Fortnite or Valorant launches, and drops back down upon exit.
- **The Plan Customizations:** Core parking minimum active cores locked to **100%**, Processor Boost Mode set to **Aggressive (2)**, PCIe Link State Power Management (ASPM) set to **Off (0)**, and Disk sleep disabled.

### 3. 🌐 Zero-Ping & Network Stack Engineering
- **Wi-Fi Dual-Homing Purged:** Having an active Wi-Fi radio on the same subnet as your Ethernet creates gateway route conflicts and **10–28 ms latency spikes** due to background channel scanning. Disabling the inactive wireless adapter locks local router ping to a flat **0.0 ms** (`<1ms`, 0.31 ms avg).
- **Silicon Hardware Checksum Offload:** Line-speed hardware ASIC offloading (`Rx & Tx Enabled`) for IPv4, TCP, and UDP offloads CRC calculations from your CPU.
- **Anti-Bufferbloat Ring Buffers:** Clamped Transmit Buffers to **128** and Receive Buffers to **512** to prevent outbound packets from waiting in driver queues. Set RSS profile to **`ClosestProcessor`** to keep network interrupts off the game's core.

### 4. 🧠 Dual-CCD AMD Ryzen Infinity Fabric Isolation
On dual-CCD processors (Ryzen 9 3900X, 5900X, 7900X, 7950X), cross-die thread migration across the Infinity Fabric adds ~75ns of cache latency penalty.
- **Hardware Isolation:** Network packet handling (RSS queues) is pinned to **CCD1 (Cores 12–22)**.
- **Game Priority:** Competitive render threads run on **CCD0 (Cores 0–11)**, guaranteeing that network packet processing never interrupts the frame delivery pipeline.

### 5. 🎯 Sub-Millisecond Input Queues (Mouse & Keyboard)
- Standard Windows buffers mouse and keyboard events up to 100 packets deep in `mouclass` and `kbdclass`.
- Clamped `MouseDataQueueSize` and `KeyboardDataQueueSize` to **32 packets**. Old movement data never lags behind live frames during high-DPI flick shots.
- Cleared Windows pointer acceleration thresholds (`MouseSpeed = 0`) for true 1:1 hardware sensor tracking.

### 6. 🛑 Micro-Stutter Root Cause Fixes
- **Audio Engine Starvation (`audiodg.exe`):** Never set `audiodg.exe` to Idle priority! That starves the Windows audio engine during gunfights, creating DPC latency stalls. Elevated Windows MMCSS Audio to **High Category / non-background**.
- **Control Flow Guard (CFG) Bypass:** Disabled CFG specifically for `FortniteClient-Win64-Shipping.exe` and `VALORANT-Win64-Shipping.exe`. Removes millions of CPU instruction validation checks per second in Unreal Engine 5.
- **GPU TDR Crash Prevention:** Set `TdrDelay` and `TdrDdiDelay` to **8 seconds** in `GraphicsDrivers`, completely preventing `DXGI_ERROR_DEVICE_REMOVED` crashes during heavy shader loads.
- **Cosmetic Streaming Hitching:** In Epic Games Launcher, checking **"Pre-download Streamed Assets"** stops Fortnite from downloading opponents' skins over the internet mid-fight.

---

## 🗂️ **Repository Structure**

```
PC-Optimizations/
├── 2026_Esports_Stack/                  # 🔥 The Modernized 2026 Tuning Suite
│   ├── Blaster_Boy_28.pow               # Standalone export of the Blaster Boy 28 power plan
│   ├── Apply-EsportsTuning.ps1          # 1-Click automated master tuning script
│   ├── Verify-AntiCheat.ps1             # Riot Vanguard & EAC compliance audit script
│   ├── GameConfigs/
│   │   ├── Fortnite-Competitive.ini     # Optimized GameUserSettings.ini (240 FPS / Zero Lumen)
│   │   └── Valorant-Competitive.ini     # Optimized GameUserSettings.ini (True Fullscreen / 0 DWM lag)
│   └── Benchmarks/
│       └── Fortnite_Creative_Benchmark_Results.md  # Full Intel PresentMon data breakdown
├── Alchemy Tweaks/                      # Advanced legacy DPC and timer registry tweaks
├── Ancel/                               # Network and performance batch files
├── Basic Settings/                      # Essential OS settings notes
├── Bios Change/                         # BIOS memory timings & SCEWIN scripts
├── MelodysLowLatencySoftware_v3/        # Standalone latency utilities
├── RIP Tweaks/                          # Fast-action system registry tweaks
└── Softwares/                           # Diagnostic tools (LatencyMon, nvidiaProfileInspector, ProcessExplorer)
```

---

## ⚡ **Quick Start: Applying the 2026 Stack**

### Step 1: Open PowerShell as Administrator
Right-click your Windows Start button and select **Terminal (Admin)** or **PowerShell (Admin)**.

### Step 2: Run the Automated Optimization Script
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
cd "$HOME\Desktop\PC-Optimizations\2026_Esports_Stack"
.\Apply-EsportsTuning.ps1
```
*The script will automatically create a Windows System Restore point before applying any changes.*

### Step 3: Verify Anti-Cheat Compliance
```powershell
.\Verify-AntiCheat.ps1
```
*Confirms your system is 100% ready for Riot Vanguard and Easy Anti-Cheat.*

### Step 4: Restart Your PC 🔄
A reboot is required for Windows kernel HAL timers (`disabledynamictick`), CPU quantum scheduling (`Win32PrioritySeparation`), and PCIe hardware interrupt priorities to engage.

---

## ⚠️ **Disclaimer**
These tweaks are rigorously tested and verified for my setup. While every script in the `2026_Esports_Stack` includes automatic backup and restore point creation, always proceed with care. 

⭐ **If this repository helped you hit your target FPS or lower your input delay, leave a star and share it with your squad!**
