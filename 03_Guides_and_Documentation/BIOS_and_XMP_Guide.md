# ⚡ BIOS Memory Overclocking: XMP / DOCP / EXPO Guide

Extreme Memory Profile (**XMP** on Intel / older AMD boards), Direct Over Clock Profile (**DOCP** on ASUS AMD boards), and Extended Profiles for Overclocking (**EXPO** on AMD AM5) are factory-certified memory profiles.

---

## ❓ Why You Must Enable XMP / DOCP

* When you purchase DDR4-3200, DDR4-3600, or DDR5-6000 RAM, your motherboard will default to baseline JEDEC specifications (usually **DDR4-2133** or **DDR5-4800**) until you enable the profile in BIOS.
* Running at JEDEC speeds starves your CPU memory controller and Infinity Fabric, causing **15–25% lower 1% low framerates** and severe micro-stuttering in high-framerate esports titles.
* **XMP is NOT dangerous overclocking:** It is applying the tested, rated factory voltage, clock frequency, and primary subtimings guaranteed by Corsair, G.Skill, Kingston, or Crucial.

---

## 🛠️ How to Enable XMP / DOCP

1. **Reboot your PC** and repeatedly tap the **`Del`** (Delete) or **`F2`** key during the motherboard splash screen until the UEFI BIOS interface appears.
2. Locate the memory profile setting based on your motherboard brand:
   * **MSI Motherboards:**
     * Look at the top banner in EZ Mode: Click the **XMP Profile 1** button (turns red when enabled).
     * Or go to **OC (Overclocking)** tab > **DRAM Setting** > **A-XMP** > Set to **Profile 1**.
   * **ASUS Motherboards:**
     * In EZ Mode, find the **X.M.P.** or **D.O.C.P.** dropdown on the left side and select **Profile 1** / **Enabled**.
     * Or press `F7` for Advanced Mode > **Ai Tweaker** tab > **Ai Overclock Tuner** > Set to **XMP I** or **DOCP Standard**.
   * **Gigabyte / AORUS Motherboards:**
     * In Advanced Mode, navigate to **Tweaker** > **Extreme Memory Profile (X.M.P.)** > Set to **Profile 1**.
   * **ASRock Motherboards:**
     * Go to **OC Tweaker** > **DRAM Configuration** > **Load XMP Setting** > Select **XMP 2.0 Profile 1**.
3. **Save and Exit:**
   * Press **`F10`** on your keyboard, confirm **Save Changes & Reset**, and let Windows boot normally.
4. **Verification:**
   * Open **Task Manager** (`Ctrl + Shift + Esc`) > **Performance** tab > **Memory**.
   * Verify the reported **Speed** matches your RAM's rated speed (e.g. **3200 MHz**).
