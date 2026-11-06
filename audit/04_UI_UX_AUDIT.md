# WRONG WAY — PHASE 4: UI/UX & RESPONSIVENESS AUDIT

**Audit Phase:** 04 — UI/UX & Viewport Responsiveness  
**Date:** 2026-11-06  
**Auditor:** Senior UI/UX & Responsive Interface Engineer  
**Engine Baseline:** Godot 4.7.2 (`canvas_items`, `expand`)  
**Base Design Resolution:** 960 × 540 px (16:9)  

---

## 1. ASPECT RATIO MATRIX & VIEWPORT BEHAVIOR

Under Godot's configured stretch settings (`mode = canvas_items`, `aspect = expand`):

| Aspect Ratio | Standard Resolution | Scaled Canvas Dimension | Horizontal Inset Margin | Vertical Inset Margin | UI Adaptability Rating |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **16:9 Standard** | 1920 × 1080 | 960.0 × 540.0 px | 0.0 px | 0.0 px | **OPTIMAL (Base)** |
| **18:9 (2:1)** | 2160 × 1080 | 1080.0 × 540.0 px | +60.0 px / side | 0.0 px | **PASS (Fluid)** |
| **19.5:9 Modern Notch** | 2340 × 1080 | 1170.0 × 540.0 px | +105.0 px / side | 0.0 px | **PASS (Safe Insets)** |
| **20:9 Ultra-wide** | 2400 × 1080 | 1200.0 × 540.0 px | +120.0 px / side | 0.0 px | **PASS (Fluid)** |
| **4:3 Tablet / iPad** | 2048 × 1536 | 960.0 × 720.0 px | 0.0 px | +90.0 px / side | **PASS (Vertical Center)** |

---

## 2. SUBSYSTEM RESPONSIVENESS EVALUATIONS

### 2.1 Safe Area & Camera Notch Handling (`UIResponsive`)
- **Implementation:** [scripts/core/ui_responsive.gd](file:///d:/Documents/wrong-way/scripts/core/ui_responsive.gd).
- **Formula:**
  $$\text{scale}_x = \frac{\text{viewport}_x}{\text{window}_x}, \quad \text{inset}_l = \text{safe.position.x} \times \text{scale}_x$$
- **Verification:**
  - Queries `DisplayServer.get_display_safe_area()`.
  - Computes exact pixel insets for left notch, right gesture bar, and top status bar.
  - Returns `{"left", "right", "top", "bottom"}` in canvas coordinates.
- **Verdict:** **PASS**. Clean mathematical scaling.

---

### 2.2 Gameplay Camera Framing (`Gameplay`)
- **Implementation:** [scripts/levels/gameplay.gd](file:///d:/Documents/wrong-way/scripts/levels/gameplay.gd#L230-L280).
- **Mechanism:**
  - The authored level geometry occupies $960 \times 540$ px.
  - When the screen widens (e.g. 20:9, $1200 \times 540$ px), `gameplay.gd` clamps the Camera2D bounds and adjusts zoom to ensure the full arena remains in the center of the safe area.
  - Prevents physics distortion caused by forced platform stretching.
- **Verdict:** **PASS**.

---

### 2.3 In-Game Touch Controls (`GameHUD`)
- **Implementation:** [scripts/ui/game_hud.gd](file:///d:/Documents/wrong-way/scripts/ui/game_hud.gd#L48-L85).
- **Verification:**
  - Virtual D-Pad (Left / Right buttons) is anchored to bottom-left using:
    $$\text{pos}_x = 24.0 + \text{insets.left}, \quad \text{pos}_y = \text{viewport}_y - 24.0 - \text{btn\_height} - \text{insets.bottom}$$
  - Action buttons (Jump / Dash) are anchored to bottom-right using:
    $$\text{pos}_x = \text{viewport}_x - 24.0 - \text{btn\_width} - \text{insets.right}$$
  - Custom button coordinates saved in `user://save_data.cfg` (`custom_touch_layout`) are validated against screen bounds so buttons never spawn off-screen.
- **Verdict:** **PASS**.

---

### 2.4 Modals, Dialogs & Level Select Grid
- **Level Select:**
  - [scripts/ui/level_select.gd](file:///d:/Documents/wrong-way/scripts/ui/level_select.gd#L118-L119) dynamically calculates centering offsets:
    $$\text{offset}_x = (\text{vp}_x - 960.0) \times 0.5, \quad \text{offset}_y = (\text{vp}_y - 540.0) \times 0.5$$
  - On a 4:3 tablet ($960 \times 720$), the 20-level stage grid stays centered with 90px top/bottom padding instead of stretching or clipping.
- **Modals (`auth_modal`, `settings_modal`, `profile_modal`):**
  - All use `Control.PRESET_CENTER` with explicit `custom_minimum_size`.
  - Clamped within visible viewport bounds.
- **Verdict:** **PASS**.

---

## 3. UI/UX DEFECTS & RISKS IDENTIFIED

| Issue ID | Screen / Component | Description | Severity | Workaround / Fix |
| :---: | :---: | :--- | :---: | :--- |
| **UI-001** | `main_menu.tscn` | Background texture `home-img.png` is fixed 960×540. On 4:3 tablets ($960 \times 720$), letterboxing or background repetition may be visible at extreme margins. | **LOW** | Ensure backdrop color matches obsidian theme background `#080c14`. |
| **UI-002** | `game_hud.tscn` | On devices without touch screens (Windows Desktop), touch buttons stay visible unless user presses keyboard input. | **LOW** | Auto-hide touch buttons when `InputEventKey` is detected. |

