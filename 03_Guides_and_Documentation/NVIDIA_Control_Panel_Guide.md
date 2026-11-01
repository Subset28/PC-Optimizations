# 🟢 NVIDIA Control Panel Competitive Esports Guide

A verified, latency-optimized configuration guide for NVIDIA GeForce RTX graphics cards tuned specifically for competitive esports titles (*Fortnite*, *Valorant*, *Apex Legends*).

---

## 🛠️ Step-by-Step Configuration

1. Right-click your desktop and open **NVIDIA Control Panel**.
2. Under **3D Settings**, select **Manage 3D Settings** > **Global Settings** tab.
3. Apply the following competitive profile settings:

| Setting Name | Recommended Value | Technical Reason |
| :--- | :--- | :--- |
| **Image Scaling** | **Off** | Eliminates GPU scaling overhead and preserves native display resolution. |
| **Anisotropic Filtering** | **Application-controlled** | Allows the game engine to decide texture filtering without driver overrides. |
| **Antialiasing - FXAA** | **Off** | Blurs screen edges and adds unnecessary post-processing latency. |
| **Antialiasing - Gamma Correction** | **On** | Zero performance penalty; maintains correct color luminance. |
| **Antialiasing - Mode** | **Application-controlled** | Controlled within in-game competitive settings. |
| **Background Application Max Frame Rate**| **20 - 30 FPS** | Drops GPU usage to near 0% when alt-tabbed. |
| **Low Latency Mode** | **Ultra** (or **On**) | Clamps pre-rendered frame queue to 0–1 frames. (*Note: Games with NVIDIA Reflex enable this automatically*). |
| **Max Frame Rate** | **Off** (or monitor Hz - 3) | If using G-Sync + V-Sync, cap 3 FPS below monitor refresh (e.g. 237 for 240Hz). Otherwise, cap in-game. |
| **OpenGL GDI Compatibility** | **Auto** | Native driver default. |
| **OpenGL Rendering GPU** | **GeForce RTX [Your GPU]** | Explicitly forces the discrete graphics card. |
| **Power Management Mode** | **Prefer Maximum Performance** | Prevents GPU clocks from downclocking to idle P-states during matches. |
| **Preferred Refresh Rate** | **Highest Available** | Ensures the monitor runs at its maximum certified Hz (e.g. 240Hz, 360Hz). |
| **Shader Cache Size** | **10 GB** (or **Unlimited**) | Prevents DirectX 12 / Unreal Engine 5 shader eviction and compilation micro-stutter. |
| **Texture Filtering - Anisotropic Sample Optimization** | **On** | Minor FPS boost with imperceptible visual difference. |
| **Texture Filtering - Negative LOD Bias** | **Allow** | Allows game engines to handle mipmapping sharpness properly. |
| **Texture Filtering - Quality** | **High Performance** | Disables heavy anisotropic filtering passes for maximum raw framerates. |
| **Texture Filtering - Trilinear Optimization** | **On** | Improves bilinear/trilinear filtering throughput. |
| **Threaded Optimization** | **Auto** (or **On**) | Enables multi-threaded CPU driver submission across all available cores. |
| **Triple Buffering** | **Off** | Eliminates input buffer latency (only applies to legacy OpenGL, keep Off). |
| **Vertical Sync** | **Off** | Prevents frame holding latency in competitive play unless pairing with G-Sync. |

---

## 🖥️ Display Configuration

1. In the left navigation pane, open **Display** > **Change resolution**:
   * Select your primary monitor.
   * Verify the **Refresh rate** is set to your monitor's maximum (e.g. **240 Hz**).
   * Under *Apply the following settings*, choose **Use NVIDIA color settings**:
     * Output color format: **RGB**
     * Output dynamic range: **Full** (0-255)
2. Open **Display** > **Adjust desktop size and position**:
   * Select **No scaling** (or **Aspect ratio**).
   * Perform scaling on: **Display** (bypasses GPU scaler latency if your monitor has a fast scalar).
   * Check **Override the scaling mode set by games and programs**.
