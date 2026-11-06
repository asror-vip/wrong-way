# WRONG WAY — MASTER BUG REGISTER & FORENSIC QA FINDINGS

**Document ID:** `audit/18_MASTER_BUG_REGISTER.md`  
**Current Date:** 2026-11-06  
**Auditor:** Forensic QA & Systems Engineering Team  
**Godot Engine:** v4.7.2.stable.official.ed1daf0bf  
**Target Environment:** Windows 10/11 & Android (Google Play Release)  

---

## 1. BUG SEVERITY CLASSIFICATION

- **CRITICAL:** Crashes, severe data loss, game-breaking progression blockage, critical security breach.
- **HIGH:** Major feature failure, broken test harnesses, deceptive mock behaviors, build configuration errors.
- **MEDIUM:** Memory leaks, orphaned code, unguarded signal connections, missing runtime guards.
- **LOW:** Minor visual discrepancies, unoptimized asset formats, cosmetic inconsistencies.
- **INFO:** Technical debt, maintenance suggestions, documentation cleanup.

---

## 2. DEFECT SUMMARY MATRIX

| Bug ID | Severity | System | File / Location | Summary Description | Status |
| :---: | :---: | :---: | :---: | :--- | :---: |
| **BUG-001** | **HIGH** | Monetization / AdMob | `export_presets.cfg:22`<br>`scripts/core/ad_manager.gd:14-18` | Real AdMob ads cannot run; APK exported with `use_gradle_build=false`; mock 5s timer deception. | **OPEN** |
| **BUG-002** | **HIGH** | Test Harness | `tests/gameplay/*.gd` | 12 broken resource load paths pointing to non-existent `scenes/menu/*` and unpadded `level_1.tscn`. | **OPEN** |
| **BUG-003** | **MEDIUM** | Audio / Memory | `scripts/core/sound_manager.gd`<br>`assets/audio/bgm_ambient.wav` | 2 ObjectDB instances and 1 AudioStreamWAV resource leaked on exit. | **OPEN** |
| **BUG-004** | **MEDIUM** | Codebase Integrity | `scripts/ui/*`, `scripts/core/*`, `scripts/traps/*` | 8 zombie/dead scripts completely unreferenced by any active scene or autoload. | **OPEN** |
| **BUG-005** | **MEDIUM** | Player Physics / Autoload | `scripts/player/player_controller.gd:46` | Direct `GameManager` autoload reference causes script compilation failure in isolated scene testing. | **OPEN** |
| **BUG-006** | **MEDIUM** | UI / Signal Safety | 41 functions across project scripts | Unguarded `.connect()` calls in methods called multiple times risk "Signal already connected" errors. | **OPEN** |
| **BUG-007** | **LOW** | Performance / Asset Size | `assets/audio/bgm_ambient.wav` | 17.5 MB uncompressed 16-bit PCM WAV causes excessive RAM usage on mobile devices; should be OGG. | **OPEN** |

---

## 3. IN-DEPTH BUG REPORTS WITH FORENSIC EVIDENCE

---

### BUG-001: Real AdMob Ads Blocked Due to Prebuilt APK Export & Legacy API Calls
- **Severity:** **HIGH**
- **System:** Monetization & Export Pipeline
- **Files Affected:**
  - `export_presets.cfg` (Line 22)
  - `scripts/core/ad_manager.gd` (Lines 14–18, 402–460, 498–521)
  - `addons/admob/internal/exporters/android/export_plugin.gd` (Lines 160–164)
- **Forensic Evidence:**
  1. `export_presets.cfg` line 22 states: `gradle_build/use_gradle_build=false`.
  2. Godot Android export plugin emits:
     ```
     ERROR: AdMob Android Export Error: 'Use Gradle Build' must be enabled in the Android export preset. Prebuilt APK export is not supported by the Poing AdMob plugin.
     ```
  3. `scripts/core/ad_manager.gd` line 15 explicitly notes:
     `# 1) Haqiqiy AdMob plaginini (GodotAdMob yoki PoingGodotAdMob) loyihaga o'rnatish shart — hozir loyihada native plagin YO'Q...`
  4. At runtime on Android, `Engine.has_singleton("PoingGodotAdMob")` is null.
  5. `AdManager` falls back to its local mock timer:
     ```gdscript
     var rewarded_duration_sec: float = 5.0
     rewarded_claim_btn.text = "Reklamani oxirigacha ko'ring (5s)"
     ```
  6. Methods called in `ad_manager.gd` (`admob.load_banner`, `admob.show_rewarded_video`) belong to legacy Godot 3 GodotAdMob, whereas the installed plugin is Poing Godot AdMob Next-Gen (`MobileAds`, `RewardedAdLoader`).
- **Reproduction:**
  Launch the exported APK on any Android device without Gradle build. Tap "Mukofotli reklama" in level select. An in-game black card with a 5-second countdown timer appears instead of a Google video ad.
- **Root Cause:**
  Previous developer/agent exported the app in Prebuilt mode and falsely assumed the 5-second mock timer was real Google AdMob ads.
- **Suggested Resolution:**
  1. Extract `android_source.zip` into `res://android/build/`.
  2. Set `gradle_build/use_gradle_build=true` in `export_presets.cfg`.
  3. Refactor `ad_manager.gd` to use the official Poing Godot AdMob API (`MobileAds.initialize()`, `RewardedAdLoader`, `AdView`).

---

### BUG-002: Test Suite Fatal Load Errors Due to Non-Existent Scene Paths
- **Severity:** **HIGH**
- **System:** Automated QA Test Suite
- **Files Affected:**
  - `tests/gameplay/test_ad_system.gd` (Lines 47, 77)
  - `tests/gameplay/test_full_game_flow.gd` (Lines 13, 23, 33)
  - `tests/gameplay/test_menu_progression_and_stars.gd` (Lines 28, 43, 62, 81, 106)
  - `tests/gameplay/test_navigation_context.gd` (Lines 23, 36)
- **Forensic Evidence:**
  The test files attempt to load:
  - `res://scenes/menu/title_screen.tscn` -> **DOES NOT EXIST** (Actual: `res://scenes/main/splash_screen.tscn`)
  - `res://scenes/menu/home_menu.tscn` -> **DOES NOT EXIST** (Actual: `res://scenes/main/main_menu.tscn`)
  - `res://scenes/menu/level_select.tscn` -> **DOES NOT EXIST** (Actual: `res://scenes/ui/level_select.tscn`)
  - `res://scenes/levels/level_1.tscn` -> **DOES NOT EXIST** (Actual: `res://scenes/levels/level_01.tscn`)
  - `res://scenes/levels/level_2.tscn` -> **DOES NOT EXIST** (Actual: `res://scenes/levels/level_02.tscn`)
- **Impact:**
  Running any of these test scripts immediately crashes with a null resource exception.
- **Suggested Resolution:**
  Update test scripts with zero-padded level names (`level_01.tscn`, `level_02.tscn`) and valid scene paths (`res://scenes/ui/*`).

---

### BUG-003: Memory Leak of AudioStreamWAV & AudioStreamPlayback Instances
- **Severity:** **MEDIUM**
- **System:** Audio Engine & Resource Cleanup
- **Files Affected:**
  - `scripts/core/sound_manager.gd`
  - `assets/audio/bgm_ambient.wav`
- **Forensic Evidence:**
  Godot 4.7.2 `--verbose` startup and quit logs report:
  ```
  Leaked instance: AudioStreamWAV:9223372079368242806 - Reference count: 1
  Leaked instance: AudioStreamPlaybackWAV:9223372082371364621 - Reference count: 1
  Resource still in use: res://assets/audio/bgm_ambient.wav (AudioStreamWAV)
  WARNING: 2 ObjectDB instances were leaked at exit
  ERROR: 1 resources still in use at exit
  ```
- **Root Cause:**
  `SoundManager` retains an active stream playback on its background audio player without calling `stop()` or releasing the `stream` resource during node cleanup / notification `NOTIFICATION_PREDELETE`.
- **Suggested Resolution:**
  In `sound_manager.gd`, implement `_notification(what)` to stop music players and set `stream = null` when `NOTIFICATION_PREDELETE` or application exit occurs.

---

### BUG-004: Eight Zombie / Dead Scripts in Project Repository
- **Severity:** **MEDIUM**
- **System:** Code Quality & Repository Cleanliness
- **Files Affected:**
  1. `scripts/ui/home_menu.gd`
  2. `scripts/ui/title_screen.gd`
  3. `scripts/ui/main_menu_controller.gd`
  4. `scripts/core/game_app.gd`
  5. `scripts/systems/level_system.gd`
  6. `scripts/traps/trap_base.gd`
  7. `scripts/traps/crusher_visuals.gd`
  8. `scripts/ui/cloud_layer.gd`
- **Forensic Evidence:**
  Node.js cross-reference scanner confirmed 0 scene bindings, 0 autoload registrations, and 0 active runtime instantiations for all 8 files.
- **Impact:**
  Misleads developers and AI agents into optimizing or modifying code that has no effect on the running game.
- **Suggested Resolution:**
  Deprecate or safely archive these files into `tools/archive/` or remove them once the audit report is fully verified.

---

### BUG-005: Direct Autoload Dependency in Player Controller
- **Severity:** **MEDIUM**
- **System:** Player Movement & Unit Testing
- **File Affected:** `scripts/player/player_controller.gd` (Line 46)
- **Forensic Evidence:**
  ```gdscript
  if is_dead or is_entering_door or GameManager.is_countdown_active:
  ```
  When running a headless test script (`tests/audit_all_levels.gd`), Godot throws:
  ```
  SCRIPT ERROR: Compile Error: Identifier not found: GameManager
  at: GDScript::reload (res://scripts/player/player_controller.gd:46)
  ```
- **Root Cause:**
  Code assumes `GameManager` is always globally bound in every execution context, failing during headless or unit-test execution.
- **Suggested Resolution:**
  Guard with `Engine.has_singleton` or check `get_node_or_null("/root/GameManager")`.

---

### BUG-006: Unguarded Signal Connections Across Core and UI Systems
- **Severity:** **MEDIUM**
- **System:** Signal Architecture & Event Bus
- **Locations:** 41 functions identified in `audit/function_audit_data.json`
- **Forensic Evidence:**
  `button.pressed.connect(...)` called in functions that can execute multiple times without an `if not button.pressed.is_connected(...)` safeguard.
- **Impact:**
  Re-entering menus or resetting modals can trigger fatal `Signal already connected` Godot errors.
- **Suggested Resolution:**
  Ensure all dynamic `.connect()` calls check `.is_connected()` or use `CONNECT_ONE_SHOT`.

---

### BUG-007: Uncompressed 17.5 MB WAV File Used for Background Audio
- **Severity:** **LOW**
- **System:** Memory & Package Size
- **File Affected:** `assets/audio/bgm_ambient.wav` (17,458,564 bytes)
- **Forensic Evidence:**
  A 17.5 MB uncompressed PCM WAV is loaded into memory at startup. When compressed to OGG Vorbis at 128 kbps, the same audio track is under 1.5 MB (an 11x reduction in RAM and disk footprint).
- **Suggested Resolution:**
  Convert `bgm_ambient.wav` to `bgm_ambient.ogg` and update `SoundManager` audio stream path.

