# WRONG WAY — PHASE 14: ANDROID & WINDOWS PLATFORM COMPATIBILITY AUDIT

**Document ID:** `audit/14_PLATFORM_COMPATIBILITY_AUDIT.md`  
**Classification:** Cross-Platform Input, OS Windowing, Lifecycle & Packaging Review  
**Audit Date:** 2026-11-06  
**Auditor:** Senior Android & Windows Compatibility Engineer  
**Godot Engine Version:** Godot v4.7.2.stable.official.ed1daf0bf  
**Target Presets:**
- **Android:** Preset 0 (`build/wrong-way.apk`, package: `com.asror.wrongway`)
- **Windows Desktop:** Preset 1 (`build/windows/WrongWay.exe`, x86_64 embedded PCK)

---

## 1. EXECUTIVE COMPATIBILITY SUMMARY

The project was constructed with cross-platform operation as a foundational design requirement. Both Android touch devices and Windows desktop keyboard/mouse setups are supported through abstracted input maps and adaptive UI scaling.

However, critical differences in platform toolchains and SDK integrations require immediate attention:
- **Windows Desktop:** Functions near flawlessly. Keyboard, mouse, window resizing, fullscreen toggling, audio, and local persistence operate with zero friction.
- **Android Mobile:** While touch controls, viewport letterboxing, and safe area insets work correctly, **the Android build pipeline is broken with respect to native plugins (BUG-001 and BUG-008)** due to `use_gradle_build=false`.

---

## 2. ANDROID PLATFORM AUDIT

### 2.1. Touch Input & Multi-Touch Support
- **Virtual Control Architecture:**
  Virtual on-screen touch buttons (Left, Right, Jump, Dash) are instantiated inside `CanvasLayer/TouchControls`.
- **Multi-Touch Concurrency:**
  Because each on-screen touch button uses an independent `TouchScreenButton` or `Control` event filter, simultaneous inputs (e.g. holding Move Right with the left thumb while tapping Jump and Dash with the right thumb) function seamlessly without event blocking.
- **Custom Touch Layout Customization:**
  `SaveManager.set_touch_pos()` and `control_customizer.gd` allow users to drag and reposition virtual buttons to fit their hand size, persisting positions to `user://save_data.cfg`.

### 2.2. Safe Area Insets, Notches & Display Cutouts
- **Aspect Ratios Verified:** 16:9 (720x1280), 18:9 (1080x2160), 19.5:9 (1080x2340), 20:9 (1080x2400).
- **Implementation:**
  `UIResponsive` (`scripts/core/ui_responsive.gd`) queries `DisplayServer.get_display_safe_area()`.
  On modern devices with camera punch-holes or notches, the virtual D-Pad and Jump buttons are padded inward by `insets.left` and `insets.right`.
- **Immersive Mode:**
  `export_presets.cfg` line 43 enables `screen/immersive_mode=true`, hiding Android navigation bars and system status bars for full-screen edge-to-edge gameplay.

### 2.3. Architecture & CPU Support
In [export_presets.cfg](file:///d:/Documents/wrong-way/export_presets.cfg#L33-L36):
```ini
architectures/arm64-v8a=true
architectures/armeabi-v7a=true
architectures/x86_64=false
architectures/x86=false
```
- **ARM64-v8a:** Fully supported (all modern Android devices).
- **ARMeabi-v7a:** Supported (legacy 32-bit budget Android devices).
- **x86 / x86_64:** Disabled. Note: Android emulators running on x86_64 PC hardware require Google Play's ARM native bridge translation layer to run this APK.

### 2.4. Android Permissions & Privacy Compliance
In [export_presets.cfg](file:///d:/Documents/wrong-way/export_presets.cfg#L48-L60):
- `access_network_state=true`: Required for Supabase HTTP requests.
- `access_wifi_state=true`: Required for network connectivity checks.
- All high-risk runtime permissions (Camera, Microphone, Location, External Storage, Phone State) are disabled (`false`).
- **Verdict: PASS.** Excellent privacy posture; requires zero sensitive permissions at runtime.

### 2.5. Android Gradle Build & Native Plugin Failure (BUG-001)
- `gradle_build/use_gradle_build=false`.
- Exporting with Godot's prebuilt APK template strips all Java/Kotlin plugin sources. Consequently:
  - AdMob plugin singletons are not present in DEX bytecode.
  - Google Play Games / Native Google Sign-In singletons are not present.

---

## 3. WINDOWS DESKTOP AUDIT

### 3.1. Keyboard & Mouse Input Mappings
Configured in `project.godot`:
- **Movement:** `A` / `D` or `Left` / `Right` Arrow keys.
- **Jump:** `Space`, `W`, or `Up` Arrow key.
- **Dash:** `Shift` or `J` key.
- **Restart Attempt:** `R` key.
- **Pause Menu:** `Escape` key.
- **Mouse Emulation:** `pointing/emulate_touch_from_mouse=true` enables desktop testers to click on-screen touch buttons or drag level select carousels with the mouse.

### 3.2. Windowing & Display Resolution
- **Base Resolution:** 960x540.
- **Stretch Configuration:** `mode="canvas_items"`, `aspect="expand"`.
- **Fullscreen Toggling:**
  `GameManager.toggle_fullscreen()` (bound to F11 / Enter):
  ```gdscript
  func toggle_fullscreen() -> void:
      var mode = DisplayServer.window_get_mode()
      if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
          DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
      else:
          DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
  ```
- **Focus Loss:** When Alt+Tab is pressed, audio volume is maintained or muted according to OS background audio rules without crashes.

### 3.3. File System & User Data Storage
- On Windows, `user://` maps to:  
  `%APPDATA%\Godot\app_userdata\WRONG WAY\`  
  (typically `C:\Users\<User>\AppData\Roaming\Godot\app_userdata\WRONG WAY\`).
- Save files (`save_data.cfg`, `save_data.cfg.bak`, `player_profile.json`) serialize cleanly with standard Windows file system permissions.

---

## 4. CROSS-PLATFORM COMPATIBILITY MATRIX

| Feature / System | Windows 10/11 | Android Mobile | Discrepancy & Status |
| :--- | :---: | :---: | :--- |
| **Input Controls** | Keyboard & Mouse | Multi-touch Virtual Buttons | **PASS** (Dual input models functional) |
| **Resolution Adaptation** | Windowed / Fullscreen | Adaptive Insets (16:9 to 20:9) | **PASS** (Viewport expands cleanly) |
| **Local Save Storage** | `%APPDATA%` | `/data/data/.../files/` | **PASS** (Atomic .tmp/.bak rotation works on both) |
| **Supabase Cloud Sync** | Functional via HTTPRequest | Functional via HTTPRequest | **PASS** (Identical REST/RPC behavior) |
| **BGM Ambient Audio** | Functional | Functional | **PASS** (Plays smoothly on both) |
| **Procedural SFX Synthesis** | Functional | Functional | **PASS** (In-memory WAV generates on both) |
| **Custom Shaders** | GL Compatibility / D3D11 | GL Compatibility / OpenGLES3 | **PASS** (Compiles cleanly on both) |
| **Google Sign-In** | Desktop OAuth Loopback | Native Google Sign-In Plugin | **FAIL on Android:** Native plugin missing (BUG-008). |
| **AdMob Advertisements** | Mock UI Countdown | Native AdMob Singletons | **FAIL on Android:** Prebuilt APK lacks plugin (BUG-001). |

---

## 5. PLATFORM RECOMMENDATIONS

1. **Android Build Pipeline:**
   Switch `gradle_build/use_gradle_build=true` in `export_presets.cfg` to resolve native AdMob and Google Sign-in dependencies.
2. **Android Back Button Navigation:**
   Implement handling for `NOTIFICATION_WM_GO_BACK_REQUEST` in `_notification()`:
   - In gameplay: opens `PauseModal`.
   - In modals: closes active modal.
   - In main menu: prompts exit confirmation.
3. **Windows Executable Metadata:**
   Windows export preset already configures file version `1.2.0`, icon, company name, and copyright cleanly.

