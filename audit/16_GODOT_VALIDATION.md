# WRONG WAY — PHASE 16: STATIC ANALYSIS & GODOT ENGINE VALIDATION

**Document ID:** `audit/16_GODOT_VALIDATION.md`  
**Classification:** AST Code Inspection, Dependency Graphs & Engine Conformance Review  
**Audit Date:** 2026-11-06  
**Godot Engine Version:** Godot v4.7.2.stable.official.ed1daf0bf  
**Renderer Target:** GL Compatibility (OpenGL ES 3.0 / DirectX 11)  
**Total Scripts Audited:** 238 GDScripts (81 Project, 157 Addon)  
**Total Scenes Audited:** 123 `.tscn` Scenes (105 Project, 18 Addon)  

---

## 1. STATIC CODE & COMPILATION VALIDATION

### 1.1. GDScript Parsing & Compilation Analysis
All 238 scripts were analyzed against Godot 4.7.2 language specifications.
- **Project Production Scripts (`scripts/`):**
  - **100% Parsing Pass:** All 81 project scripts parse without syntax errors.
  - **Standalone Compilation Caveat (BUG-005):** In isolated headless CLI execution (`godot --headless -s`), scripts that reference Autoload singletons as bare global identifiers (e.g. `GameManager`, `SoundManager` in `player_controller.gd` and `exit_door.gd`) fail compilation because the standalone script runner replaces the engine SceneTree and omits Autoload singletons.
- **Test Scripts (`tests/`):**
  - `tests/gameplay/test_session_and_player.gd`: Fails parsing with `Parse Error: Identifier "GameSession" not declared in current scope`.
  - `tests/gameplay/test_menu_progression_and_stars.gd`: Fails static type checking: assigns untyped `Array` to typed `Array[int]` (`unlocked_levels`).

### 1.2. Godot 4.7.2 API & Deprecation Review
- **Callable Syntax:** Project universally uses modern Godot 4 `Callable(self, "method")` and lambda syntax `func(): ...`. Zero legacy Godot 3 `funcref` or string-based `connect("signal", self, "method")` calls exist.
- **Typed Collections:** Arrays and Dictionaries utilize typed signatures (e.g. `Array[int]`, `PackedVector2Array`, `PackedStringArray`).
- **Tween Architecture:** Uses modern `create_tween()` exclusively; zero legacy `Tween` node instantiations.
- **Rendering Shaders:** Both custom shaders (`bokeh_blur.gdshader` and `fog_transition.gdshader`) use valid Godot 4 `shader_type canvas_item;` specifications with GL Compatibility support.

---

## 2. SCENE & RESOURCE DEPENDENCY GRAPH

### 2.1. Scene External Resource (`ext_resource`) Validation
An automated AST scan of all 123 `.tscn` scene files evaluated every `[ext_resource]` declaration against the physical disk:
- **Total `ext_resource` Links Scanned:** 542 links
- **Broken Scene Links:** **0 broken links (100% Valid)**
- Every referenced script, texture, audio file, font, and child scene exists on disk at the declared path.

### 2.2. Code-Level `load()` & `preload()` Reference Validation
Scanning all 238 scripts for string-based resource loading identified 12 broken paths:
- **Production Scripts (`scripts/`):** **0 broken paths.** All dynamic and static loads resolve to valid resources.
- **Test Scripts (`tests/`):** **12 broken paths (BUG-002).**
  - 6 references to non-existent `res://scenes/menu/title_screen.tscn` and `res://scenes/menu/level_select.tscn`.
  - 6 references to unpadded level files `res://scenes/levels/level_1.tscn` and `level_2.tscn` (actual files are padded: `level_01.tscn`, `level_02.tscn`).

---

## 3. AUTOLOAD & SINGLETON INTEGRITY

### 3.1. Autoload Configuration Matrix (`project.godot`)
```ini
[autoload]
SaveManager="*res://scripts/core/save_manager.gd"
LocaleManager="*res://scripts/core/locale_manager.gd"
IconFactory="*res://scripts/core/icon_factory.gd"
SoundManager="*res://scripts/core/sound_manager.gd"
GameManager="*res://scripts/core/game_manager.gd"
AdManager="*res://scripts/core/ad_manager.gd"
CustomLevelManager="*res://scripts/editor/custom_level_manager.gd"
SaveSystem="*res://scripts/core/save_manager.gd"        <-- DUPLICATE AUTOLOAD (BUG-013)
LevelDatabase="*res://scripts/core/level_database.gd"
ProfileManager="*res://scripts/core/profile_manager.gd"
DuelService="*res://scripts/multiplayer/duel_service.gd"
GoogleAuthService="*res://scripts/core/google_auth_service.gd"
```

### 3.2. Critical Autoload Finding (BUG-013)
- **Defect:** `SaveManager` and `SaveSystem` both register `res://scripts/core/save_manager.gd`.
- **Impact:** At engine startup, Godot instantiates **two independent instances** of `save_manager.gd` in the root tree (`/root/SaveManager` and `/root/SaveSystem`). Both instances independently load and parse `user://save_data.cfg`.
- If any script writes to `SaveSystem` instead of `SaveManager`, state divergence and unsynchronized progression occurs.
- **Recommendation:** Remove `SaveSystem` from `project.godot` line 28.

---

## 4. SIGNAL SAFETY & RUNTIME RISKS

### 4.1. Unguarded Signal Connections (BUG-006)
Static analysis cataloged 41 signal connections across project scripts. 11 methods called repeatedly connect signals without guarding against duplicate connections:
- **Files Affected:** `scripts/ui/profile_modal.gd`, `scripts/ui/leaderboard_modal.gd`, `scripts/ui/settings_modal.gd`, `scripts/multiplayer/duel_lobby_modal.gd`.
- **Runtime Risk:** When a user opens, closes, and re-opens a modal, repeated `.connect()` calls crash the GDScript runtime:
  `SCRIPT ERROR: Signal 'pressed' is already connected to given callable.`
- **Remediation:** Guard all dynamic connections with `if not signal.is_connected(callable): signal.connect(callable)`.

---

## 5. ORPHAN RESOURCES & TECHNICAL DEBT

### 5.1. Eight Dead / Zombie Scripts (BUG-004)
The following 8 scripts have 0 usages across any active scene or autoload:
1. `scripts/ui/home_menu.gd`
2. `scripts/ui/title_screen.gd`
3. `scripts/ui/main_menu_controller.gd`
4. `scripts/core/game_app.gd`
5. `scripts/systems/level_system.gd`
6. `scripts/traps/trap_base.gd`
7. `scripts/traps/crusher_visuals.gd`
8. `scripts/ui/cloud_layer.gd`

### 5.2. Eight Unused Trap Scenes (BUG-012)
`control_inverter.tscn`, `crashing_pillar.tscn`, `dodging_platform.tscn`, `falling_ceiling.tscn`, `invisible_block.tscn`, `jumping_spikes.tscn`, `rotating_spike_ball.tscn`, `sinking_door_floor.tscn` have 0 instances in any official level.

---

## 6. EXPORT CONFIGURATION & PACKAGING AUDIT

### 6.1. Android Preset (`export_presets.cfg:1-60`)
- **Strengths:** Immersive mode enabled; only 2 non-sensitive permissions requested (`ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`); ARM64 and ARMv7 architectures enabled.
- **Critical Failure (BUG-001):** `gradle_build/use_gradle_build=false`. Prebuilt template omits Android Java plugin source files, completely disabling AdMob and Google Play Games.

### 6.2. Windows Desktop Preset (`export_presets.cfg:200-260`)
- **Strengths:** Embedded PCK (`binary_format/embed_pck=true`), x86_64 architecture, full company and copyright metadata, clean executable generation at `build/windows/WrongWay.exe`.
- **Verdict: PASS.**

---

## 7. ENGINE VALIDATION SUMMARY

| Validation Domain | Scope | Status | Notes |
| :--- | :--- | :---: | :--- |
| **GDScript Syntax** | 81 Production Scripts | **PASS** | 100% parse cleanly in Godot 4.7.2. |
| **Scene Resource Links** | 123 Scene Files | **PASS** | 542 / 542 `ext_resource` links exist on disk. |
| **Script Resource Loads** | Production Scripts | **PASS** | Zero broken `load()` paths in production. |
| **Script Resource Loads** | Test Harness Scripts | **FAIL** | 12 broken paths to missing menu scenes (BUG-002). |
| **Autoload Registry** | 12 Registered Nodes | **FAIL** | Duplicate `SaveSystem` and `SaveManager` (BUG-013). |
| **Signal Idempotency** | 41 Signal Connections | **WARN** | 11 dynamic connections lack `is_connected()` guard (BUG-006). |
| **Android Packaging** | Gradle & Plugins | **FAIL** | `use_gradle_build=false` blocks AdMob classes (BUG-001). |
| **Windows Packaging** | x86_64 Executable | **PASS** | Embedded PCK and metadata verified. |

