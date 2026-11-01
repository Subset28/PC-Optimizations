# Wi-Fi Speed & Bandwidth Repair Suite (300+ Mbps Uncapper)

An automated Windows network diagnostics and optimization suite engineered to resolve severe throughput bottlenecks (e.g., paying for 300–1000 Mbps broadband but only receiving 8–15 Mbps on Wi-Fi).

---

## ⚡ The Common Problem: Capped at ~8 Mbps

When a PC achieves only ~8 Mbps on high-speed internet, it is almost never an ISP throttling issue. In 95% of cases on Windows 10 and Windows 11, it is caused by one of the following root causes:

### 1. Windows TCP Window Auto-Tuning Clamped to 64 KB
If Windows TCP Window Auto-Tuning has been disabled (`netsh int tcp set global autotuninglevel=disabled`) by outdated optimization utilities or corrupted registry keys, Windows locks the TCP receive window (RWIN) to a maximum of 65,535 bytes (64 KB).

$$\text{Max Throughput} = \frac{\text{TCP Receive Window}}{\text{Round-Trip Latency (RTT)}} = \frac{65{,}535 \times 8 \text{ bits}}{0.065 \text{ seconds}} \approx \mathbf{8.06\text{ Mbps}}$$

This mathematical barrier hard-caps throughput around 8 Mbps regardless of having 300 Mbps or 1000 Mbps broadband.

### 2. 2.4 GHz Band Sticking & Clamping
Many modern ISP gateways broadcast 2.4 GHz and 5 GHz under a single combined SSID. Without explicit band preference configured, Windows often negotiates connection to the congested 2.4 GHz band on legacy 802.11g/n protocols with 20 MHz channel widths, resulting in ~8–25 Mbps real-world payload throughput.

### 3. Windows Wi-Fi Receive Segment Coalescing (RSC) Driver Flaw
Receive Segment Coalescing on Wi-Fi miniport drivers (especially Intel AX200/AX201/AX210 and Realtek 8821/8822/8852 chips) is infamous for causing severe packet coalescence timing errors, micro-drops, and throughput throttling on Windows.

### 4. Hardware Power Saving / Green Wi-Fi
Windows Power Plans and Device Manager power management frequently throttle the Wi-Fi card's Transmit/Receive link rates to conserve power on laptops and desktops alike.

---

## 🛠️ Automated Fixes Applied

The script automatically executes the following remediations with full elevation:

| Component | Setting Applied | Purpose |
| :--- | :--- | :--- |
| **TCP Auto-Tuning** | `autotuninglevel=normal` | Removes 64 KB RWIN limit; restores dynamic TCP window scaling. |
| **Congestion Control** | `congestionprovider=cubic` | Sets modern loss-based high-throughput congestion control. |
| **Offload & Scaling** | `rss=enabled`, `ecncapability=disabled` | Enables multi-core network distribution and prevents router drop issues. |
| **Wi-Fi RSC** | `Disable-NetAdapterRsc` | Disables Wi-Fi packet coalescing driver bugs to eliminate micro-stalls. |
| **Band Preference** | `*PreferredBand = 5GHz` | Forces Wi-Fi card to prioritize 5 GHz / 6 GHz over crowded 2.4 GHz. |
| **Channel Width** | `Channel Width = Auto` | Unlocks 40/80/160 MHz channel bonding for maximum data rates. |
| **Power Management** | `Max Performance` & `PnPCapabilities=24` | Disables power-saving downclocking on wireless adapters. |
| **Bandwidth Caps** | `DOMaxDownloadBandwidth=0` | Removes Windows Delivery Optimization background throttles. |
| **Network Throttling** | `NetworkThrottlingIndex=0xffffffff` | Disables Windows Multimedia Network Throttling. |
| **Network Stack Reset** | `flushdns`, `winsock reset`, `int ip reset` | Flushes DNS cache, repairs Winsock catalog, and resets IP routes. |

---

## 🚀 How to Run

1. Open the folder:
   ```text
   02_Esports_Utilities\Network_Tools\WiFi_Speed_and_Bandwidth_Fixer\
   ```
2. Double-click **`Fix-WiFi-Speed.bat`** (or right-click $\rightarrow$ **Run as Administrator**).
3. The script will inspect your current negotiated link speed, apply all TCP and adapter optimizations, and restart the Wi-Fi adapter.
4. **Reboot your PC** to finalize the TCP/IP stack initialization.
5. Run a speed test at [speedtest.net](https://www.speedtest.net) or [fast.com](https://fast.com).

---

## 📡 Router Recommendation
If your router combines 2.4 GHz and 5 GHz into a single Wi-Fi name, log into your router's administration portal (usually `192.168.1.1` or `192.168.0.1`) and separate the network names (e.g., `HomeWiFi` and `HomeWiFi_5G`). Ensure your gaming PC connects directly to the `_5G` network.
