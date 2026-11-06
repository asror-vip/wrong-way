# WRONG WAY — COMPREHENSIVE REMEDIATION ROADMAP

**Document ID:** `audit/REMEDIATION_ROADMAP.md`  
**Classification:** Engineering Action Plan, Dependency Sequencing & Regression Protocols  
**Audit Date:** 2026-11-06  
**Auditor:** Lead Systems Architect & Principal QA Engineer  
**Policy:** Zero automatic code modifications applied during audit. This roadmap defines the exact remediation sequence for post-audit implementation.

---

## 1. REMEDIATION SPRINT OVERVIEW & DEPENDENCY GRAPH

Remediation is organized into 5 sequential sprints ordered by security severity, release-blocking status, and technical dependencies:

```
[Sprint 1: Critical Security & Backend Auth]
 (BUG-008, BUG-009, BUG-013)
        │
        ▼
[Sprint 2: Android Build Pipeline & Real AdMob]
 (BUG-001, UMP Consent)
        │
        ▼
[Sprint 3: Automated Test Suite Restoration]
 (BUG-002, BUG-005)
        │
        ▼
[Sprint 4: Signal Safety & Codebase Hygiene]
 (BUG-006, BUG-004, BUG-003)
        │
        ▼
[Sprint 5: Asset Optimization & Release Certification]
 (BUG-007, BUG-012, Final QA Sign-Off)
```

---

## 2. DETAILED SPRINT BREAKDOWN

---

### SPRINT 1: CRITICAL SECURITY & BACKEND IDENTITY (BLOCKING)
**Primary Focus:** Eliminate IDOR account takeover and unauthenticated cloud save corruption.

#### Task 1.1: Refactor Supabase RPC `login_or_link_google` (BUG-008)
- **Target:** Supabase PostgreSQL Database & [scripts/core/profile_manager.gd](file:///d:/Documents/wrong-way/scripts/core/profile_manager.gd#L244)
- **Action:**
  1. On Android client: configure Google Sign-In plugin to request Google OAuth ID Token (`id_token`).
  2. Exchange Google ID token with Supabase Auth: `POST /auth/v1/token?grant_type=id_token`.
  3. Store returned authenticated user session JWT.
  4. In PostgreSQL: rewrite `login_or_link_google` to verify `auth.uid() = id`.
- **Dependencies:** None.
- **Technical Risk:** Low (purely backend and auth wrapper).
- **Regression Test Protocol:** Send unauthenticated raw email curl request; verify HTTP 401 Unauthorized rejection.

#### Task 1.2: Protect `sync_cloud_save` with `auth.uid()` (BUG-009)
- **Target:** Supabase PostgreSQL Database & [scripts/core/profile_manager.gd](file:///d:/Documents/wrong-way/scripts/core/profile_manager.gd#L329)
- **Action:**
  1. Remove `p_player_id` from RPC parameter signature.
  2. In SQL: extract player ID strictly via `v_user_id := auth.uid();`.
  3. Pass caller session JWT in HTTP `Authorization: Bearer <user_jwt>`.
- **Dependencies:** Requires Task 1.1 (caller must hold valid session JWT).
- **Technical Risk:** Medium.
- **Regression Test Protocol:** Attempt to update save data for a mismatched UUID; assert server rejection with 403 Forbidden.

#### Task 1.3: Eliminate Duplicate Autoload `SaveSystem` (BUG-013)
- **Target:** `project.godot` (Line 28)
- **Action:** Remove line `SaveSystem="*res://scripts/core/save_manager.gd"`. Update any remaining references in test files to use `SaveManager`.
- **Dependencies:** None.
- **Technical Risk:** Extremely Low.
- **Regression Test Protocol:** Launch game, inspect Remote SceneTree; verify only `/root/SaveManager` exists.

---

### SPRINT 2: ANDROID BUILD PIPELINE & REAL ADMOB (BLOCKING)
**Primary Focus:** Enable real Google Mobile Ads in compiled APK and satisfy Google Play ad policies.

#### Task 2.1: Enable Gradle Build & Integrate AdMob AAR Plugin (BUG-001)
- **Target:** [export_presets.cfg](file:///d:/Documents/wrong-way/export_presets.cfg#L22), `android/build/`
- **Action:**
  1. Set `gradle_build/use_gradle_build=true` in `export_presets.cfg`.
  2. Install Godot Android Build Template (`Project -> Install Android Build Template`).
  3. Place compiled Poing Studios AdMob `.aar` plugin and `.gdap` config into `android/plugins/`.
  4. Enable plugin in Android export preset.
- **Dependencies:** Android SDK and Gradle installed on build machine.
- **Technical Risk:** Medium (requires clean Gradle build setup).
- **Regression Test Protocol:** Disassemble new APK with `dexdump`; verify presence of `com.google.android.gms.ads` classes. Test rewarded video ad delivery on physical Android device.

#### Task 2.2: Add Google UMP Consent Dialog Integration
- **Target:** [scripts/core/ad_manager.gd](file:///d:/Documents/wrong-way/scripts/core/ad_manager.gd#L34)
- **Action:** Implement User Messaging Platform (UMP) consent request on first app launch for European (EEA/UK) users prior to initializing AdMob.
- **Dependencies:** Task 2.1.
- **Technical Risk:** Low.
- **Regression Test Protocol:** Test with European geo-location mock; verify CMP consent dialog appears on first launch.

---

### SPRINT 3: AUTOMATED TEST SUITE RESTORATION (BLOCKING)
**Primary Focus:** Fix broken scene paths and Autoload dependencies so test harness passes 100%.

#### Task 3.1: Update Obsolete Scene Paths in Test Scripts (BUG-002)
- **Target:** `tests/gameplay/*.gd`
- **Action:**
  Replace:
  - `res://scenes/menu/title_screen.tscn` -> `res://scenes/main/main_menu.tscn`
  - `res://scenes/menu/home_menu.tscn` -> `res://scenes/main/main_menu.tscn`
  - `res://scenes/menu/level_select.tscn` -> `res://scenes/main/level_select.tscn`
  - `res://scenes/levels/level_1.tscn` -> `res://scenes/levels/level_01.tscn`
  - `res://scenes/levels/level_2.tscn` -> `res://scenes/levels/level_02.tscn`
- **Dependencies:** None.
- **Technical Risk:** Zero (test files only).
- **Regression Test Protocol:** Execute `godot --headless -s tests/gameplay/test_full_game_flow.gd`; assert exit code 0.

#### Task 3.2: Resolve Standalone Autoload Compilation in Tests (BUG-005)
- **Target:** [scripts/player/player_controller.gd:46](file:///d:/Documents/wrong-way/scripts/player/player_controller.gd#L46), `tests/test_player_dash.gd`
- **Action:** In `player_controller.gd`, wrap direct `GameManager` references in safe lookups:
  ```gdscript
  var gm = get_node_or_null("/root/GameManager")
  if gm and gm.has_method("record_death"): gm.record_death()
  ```
- **Dependencies:** None.
- **Technical Risk:** Zero.
- **Regression Test Protocol:** Run `godot --headless -s tests/test_player_dash.gd`; assert clean pass.

---

### SPRINT 4: SIGNAL SAFETY & CODE HYGIENE (QUALITY)
**Primary Focus:** Prevent signal crash loops and clean up dead files.

#### Task 4.1: Guard Repeated Signal Connections (BUG-006)
- **Target:** `scripts/ui/profile_modal.gd`, `leaderboard_modal.gd`, `settings_modal.gd`
- **Action:** Wrap all dynamic `.connect()` calls in:
  ```gdscript
  if not btn.pressed.is_connected(callable):
      btn.pressed.connect(callable)
  ```
- **Dependencies:** None.
- **Technical Risk:** Zero.
- **Regression Test Protocol:** Scripted automated UI loop toggling modals 50 times without runtime errors.

#### Task 4.2: Delete 8 Zombie / Dead Scripts (BUG-004)
- **Target:** Delete:
  - `scripts/ui/home_menu.gd`
  - `scripts/ui/title_screen.gd`
  - `scripts/ui/main_menu_controller.gd`
  - `scripts/core/game_app.gd`
  - `scripts/systems/level_system.gd`
  - `scripts/traps/trap_base.gd`
  - `scripts/traps/crusher_visuals.gd`
  - `scripts/ui/cloud_layer.gd`
- **Dependencies:** None.
- **Technical Risk:** Zero (verified 0 references across project).
- **Regression Test Protocol:** Project export test to verify zero compilation breakage.

#### Task 4.3: Implement Clean AudioServer Flush on Exit (BUG-003)
- **Target:** [scripts/core/sound_manager.gd](file:///d:/Documents/wrong-way/scripts/core/sound_manager.gd)
- **Action:** Add `_notification(what)` hook:
  ```gdscript
  func _notification(what: int) -> void:
      if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_WM_CLOSE_REQUEST:
          if music_player:
              music_player.stop()
  ```
- **Dependencies:** None.
- **Technical Risk:** Zero.
- **Regression Test Protocol:** Launch with `--verbose`, close window, verify 0 leaked ObjectDB instances.

---

### SPRINT 5: ASSET OPTIMIZATION & RELEASE CERTIFICATION
**Primary Focus:** Package shrinkage and final QA sign-off.

#### Task 5.1: Convert BGM to OGG Vorbis (BUG-007)
- **Target:** `assets/audio/bgm_ambient.wav` (5.0 MB)
- **Action:** Re-encode to `bgm_ambient.ogg` (~1.2 MB at 128 kbps). Update `sound_manager.gd:82` path.
- **Dependencies:** None.
- **Technical Risk:** Zero.
- **Regression Test Protocol:** Verify background music plays and loops continuously on Windows and Android.

#### Task 5.2: Final Certification Sign-Off
- **Target:** Full QA execution across all 12 domains in `audit/19_FINAL_QUALITY_GATE.md`.
- **Action:** Verify all 5 blocking gates achieve **PASS**.
- **Certification Outcome:** Update status to **RELEASE READY**.

