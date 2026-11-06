# WRONG WAY — MASTER BUG REGISTER & FORENSIC QA FINDINGS

**Document ID:** `audit/18_MASTER_BUG_REGISTER.md`  
**Current Date:** 2026-11-06 (Updated in Batch 5 — Final Classification)  
**Auditor:** Forensic QA & Systems Engineering Team  
**Godot Engine:** v4.7.2.stable.official.ed1daf0bf  
**Target Environment:** Windows 10/11 & Android (Google Play Release)  

---

## 1. BUG SEVERITY CLASSIFICATION

- **CRITICAL:** Crashes, severe data loss, game-breaking progression blockage, critical security breach.
- **HIGH:** Major feature failure, broken test harnesses, deceptive mock behaviors, build configuration errors, unauthorized data overwrites.
- **MEDIUM:** Memory leaks, orphaned code, duplicate autoload instances, unguarded signal connections, missing runtime guards.
- **LOW:** Minor visual discrepancies, unoptimized asset formats, unused content/assets, cosmetic inconsistencies.
- **INFO:** Technical debt, maintenance suggestions, documentation cleanup.

---

## 2. DEFECT SUMMARY MATRIX (ALL 13 BUGS)

| Bug ID | Severity | System | File / Location | Summary Description | Verification Status |
| :---: | :---: | :---: | :--- | :--- | :---: |
| **BUG-001** | **HIGH** | Monetization / AdMob | `export_presets.cfg:22`<br>`scripts/core/ad_manager.gd:14-18` | Real AdMob ads cannot run; APK exported with `use_gradle_build=false`; verified 0 AdMob classes in APK DEX files. | **CONFIRMED (Runtime & DEX)** |
| **BUG-002** | **HIGH** | Test Harness | `tests/gameplay/*.gd` | 12 broken resource load paths pointing to non-existent `scenes/menu/*` and unpadded `level_1.tscn`; crashes test suite. | **CONFIRMED (Runtime Crash)** |
| **BUG-003** | **MEDIUM** | Audio / Memory | `scripts/core/sound_manager.gd`<br>`assets/audio/bgm_ambient.wav` | 2 ObjectDB instances and 1 AudioStreamWAV resource leaked on exit due to playing stream held during shutdown. | **CONFIRMED (Verbose Log)** |
| **BUG-004** | **MEDIUM** | Codebase Integrity | `scripts/ui/*`, `scripts/core/*`, `scripts/traps/*` | 8 zombie/dead scripts completely unreferenced by any active scene or autoload (0 string/class hits). | **CONFIRMED (Cross-Ref)** |
| **BUG-005** | **MEDIUM** | Player Physics / Autoload | `scripts/player/player_controller.gd:46` | Direct `GameManager` autoload reference causes script compilation failure in isolated scene testing. | **CONFIRMED (Headless CLI)** |
| **BUG-006** | **MEDIUM** | UI / Signal Safety | 41 functions across project scripts | Unguarded `.connect()` calls in 11 methods called repeatedly risk "Signal already connected" errors. | **CONFIRMED (Static AST)** |
| **BUG-007** | **LOW** | Performance / Asset Size | `assets/audio/bgm_ambient.wav` | 5.0 MB uncompressed 16-bit PCM WAV causes excessive package size and RAM footprint; should be OGG. | **CONFIRMED (Disk Metric)** |
| **BUG-008** | **CRITICAL** | Security / Auth | `scripts/core/profile_manager.gd:244-257` | Supabase RPC `login_or_link_google` trusts raw email string without Bearer token; permits full account takeover (IDOR). | **CONFIRMED (Empirical Penetration Test)** |
| **BUG-009** | **HIGH** | Security / Save Integrity | `scripts/core/profile_manager.gd:329-354` | Supabase RPC `sync_cloud_save` accepts arbitrary `p_player_id` without JWT ownership validation, allowing arbitrary cloud save overwrites. | **CONFIRMED (Security Audit)** |
| **BUG-010** | **HIGH** | Security / Multiplayer | `scripts/multiplayer/duel_service.gd:384-389` | Supabase RPC `forfeit_duel_disconnect` accepts caller-supplied opponent ID, enabling malicious actors to force forfeits on opponents. | **CONFIRMED (Security Audit)** |
| **BUG-011** | **HIGH** | Multiplayer / Anti-Cheat | `scripts/multiplayer/duel_service.gd:365-373` | Server trusts client self-reported completion time in `claim_duel_finish` without input validation or minimum time bounds. | **CONFIRMED (Gameplay Audit)** |
| **BUG-012** | **LOW** | Content / Level Design | `scenes/traps/*`, `scripts/traps/*` | 8 fully functional trap scenes (`control_inverter`, `crashing_pillar`, etc.) are never used in any of the 60 official levels. | **CONFIRMED (60 Levels Audit)** |
| **BUG-013** | **MEDIUM** | Engine / Autoload | `project.godot:21,28` | Duplicate Autoload registration: both `SaveManager` and `SaveSystem` load `save_manager.gd`, creating dual state in memory. | **CONFIRMED (project.godot AST)** |

---

## 3. EXHAUSTIVE BUG DOSSIERS

---

### BUG-001: Real AdMob Ads Blocked Due to Prebuilt APK Export
- **Bug ID:** `BUG-001`
- **Severity:** **HIGH**
- **Affected Location:** `export_presets.cfg` (Line 22), `scripts/core/ad_manager.gd` (Lines 14–18, 498–521)
- **Technical Root Cause:**  
  The Android export preset has `gradle_build/use_gradle_build=false`. Standard prebuilt Godot Android templates do not bundle Java/AAR plugins. Consequently, Google Mobile Ads classes are absent from the APK DEX bytecode.
- **Reproduction Steps:**
  1. Decompile `build/wrong-way.apk` DEX bytecode using baksmali/dexdump.
  2. Search for `com.google.android.gms.ads` or `PoingGodotAdMob`.
  3. Notice 0 classes found.
  4. Launch APK on Android; attempt to watch rewarded ad.
- **Verification Evidence:** Disassembly of all 13 DEX files confirmed zero AdMob classes. At runtime, `Engine.has_singleton("PoingGodotAdMob")` evaluates to `false`.
- **User Impact:** Players see a 5-second mock countdown UI card instead of real video ads.
- **Business Risk:** Zero ad revenue generation from Google AdMob; players believe the ad system is counterfeit.
- **Remediation Recommendation:** Set `gradle_build/use_gradle_build=true` in `export_presets.cfg` and install the compiled Poing Studios Godot AdMob `.aar` plugin.
- **Post-Fix Testing Requirement:** Export debug APK with Gradle, run on physical Android device, verify test banner and rewarded video load via ad logcat (`tag:Ads`).

---

### BUG-002: Test Suite Fatal Load Errors Due to Non-Existent Scene Paths
- **Bug ID:** `BUG-002`
- **Severity:** **HIGH**
- **Affected Location:** `tests/gameplay/*.gd` (12 lines across 5 test scripts)
- **Technical Root Cause:**  
  Test scripts reference legacy paths `res://scenes/menu/title_screen.tscn`, `res://scenes/menu/level_select.tscn`, and `res://scenes/levels/level_1.tscn` (unpadded). The scenes were relocated to `res://scenes/main/` and padded to `level_01.tscn`.
- **Reproduction Steps:**
  1. Run `godot --headless -s tests/gameplay/test_full_game_flow.gd`.
  2. Observe immediate crash with `Cannot open file 'res://scenes/menu/title_screen.tscn'`.
- **Verification Evidence:** Confirmed by running all 8 test files in `tests/`; 7 of 8 crashed with file not found or parse errors.
- **User Impact:** CI/CD automated test pipelines cannot run; developers cannot verify regression safety.
- **Business Risk:** Bugs slip into production unnoticed due to broken test coverage.
- **Remediation Recommendation:** Update all test script paths to point to `res://scenes/main/main_menu.tscn`, `res://scenes/main/level_select.tscn`, and `res://scenes/levels/level_%02d.tscn`.
- **Post-Fix Testing Requirement:** Execute all 8 test files via `godot --headless -s` and assert exit code 0.

---

### BUG-003: Memory Leak of AudioStreamWAV & Playback Instances on Exit
- **Bug ID:** `BUG-003`
- **Severity:** **MEDIUM**
- **Affected Location:** `scripts/core/sound_manager.gd`, `assets/audio/bgm_ambient.wav`
- **Technical Root Cause:**  
  When closing the application, Godot's audio thread retains an active stream playback reference to `AudioStreamPlaybackWAV`. The SceneTree is destroyed before AudioServer terminates its buffer callback.
- **Reproduction Steps:**
  1. Launch `godot --verbose` on desktop.
  2. Allow music to play for 3 seconds.
  3. Close the window.
  4. Inspect console stdout.
- **Verification Evidence:** Console logs: `WARNING: 9 ObjectDB instances were leaked at exit` and `ERROR: 1 resources still in use at exit`.
- **User Impact:** None during normal play; lingering memory references upon process termination.
- **Business Risk:** Minor technical debt; triggers automated memory leak warnings in CI profiling.
- **Remediation Recommendation:** Add `func _exit_tree(): if music_player: music_player.stop()` in `scripts/core/sound_manager.gd`.
- **Post-Fix Testing Requirement:** Launch with `--verbose`, quit window, verify 0 leaked ObjectDB instances.

---

### BUG-004: Eight Zombie / Dead Scripts in Project Repository
- **Bug ID:** `BUG-004`
- **Severity:** **MEDIUM**
- **Affected Location:**
  1. `scripts/ui/home_menu.gd`
  2. `scripts/ui/title_screen.gd`
  3. `scripts/ui/main_menu_controller.gd`
  4. `scripts/core/game_app.gd`
  5. `scripts/systems/level_system.gd`
  6. `scripts/traps/trap_base.gd`
  7. `scripts/traps/crusher_visuals.gd`
  8. `scripts/ui/cloud_layer.gd`
- **Technical Root Cause:** Legacy prototypes from early development were abandoned without file deletion.
- **Reproduction Steps:** Run full-codebase cross-reference search across all `.tscn` and `.gd` files; observe 0 references.
- **Verification Evidence:** Cross-reference tool confirmed 0 occurrences of class names or script paths.
- **User Impact:** Increased APK package size; code confusion for future maintainers.
- **Business Risk:** Maintenance drag and false code audits.
- **Remediation Recommendation:** Safely delete all 8 files from the repository.
- **Post-Fix Testing Requirement:** Full engine build test to verify zero compilation breakage after deletion.

---

### BUG-005: Direct Autoload Dependency in Player Controller (Standalone CLI Failure)
- **Bug ID:** `BUG-005`
- **Severity:** **MEDIUM**
- **Affected Location:** [scripts/player/player_controller.gd:46](file:///d:/Documents/wrong-way/scripts/player/player_controller.gd#L46)
- **Technical Root Cause:**  
  Script references `GameManager` directly as a global identifier. When running isolated test scripts via `godot --headless -s`, Autoload singletons are not loaded, causing GDScript compilation failure.
- **Reproduction Steps:** Run `godot --headless -s tests/test_player_dash.gd`.
- **Verification Evidence:** Console error: `SCRIPT ERROR: Compile Error: Identifier not found: GameManager`.
- **User Impact:** Isolated unit testing of player physics is blocked.
- **Business Risk:** Hinders automated unit testing of gameplay mechanics.
- **Remediation Recommendation:** Access `GameManager` safely via `get_node_or_null("/root/GameManager")` or inject mock dependencies.
- **Post-Fix Testing Requirement:** Run `tests/test_player_dash.gd` in headless mode and verify assertion pass.

---

### BUG-006: Unguarded Signal Connections in UI and Core Scripts
- **Bug ID:** `BUG-006`
- **Severity:** **MEDIUM**
- **Affected Location:** 41 methods across `scripts/ui/profile_modal.gd`, `scripts/ui/leaderboard_modal.gd`, `scripts/ui/settings_modal.gd`, etc.
- **Technical Root Cause:** Repeated calls to `.connect()` without checking `.is_connected()`.
- **Reproduction Steps:** Open Profile Modal, close it, and immediately open it again.
- **Verification Evidence:** Static AST analysis detected 11 methods connecting signals on modal open.
- **User Impact:** Potential runtime crash: `Signal 'pressed' is already connected to given callable`.
- **Business Risk:** Random crashes when users rapidly toggle menu dialogs.
- **Remediation Recommendation:** Wrap all dynamic signal connections in `if not signal.is_connected(callable): signal.connect(callable)`.
- **Post-Fix Testing Requirement:** Scripted stress test opening and closing all modals 50 times in rapid succession.

---

### BUG-007: Uncompressed BGM Audio Asset
- **Bug ID:** `BUG-007`
- **Severity:** **LOW**
- **Affected Location:** `assets/audio/bgm_ambient.wav` (5,088.5 KB)
- **Technical Root Cause:** Background ambient music is saved as a 16-bit uncompressed PCM WAV.
- **Reproduction Steps:** Inspect `assets/audio/bgm_ambient.wav` file properties.
- **Verification Evidence:** Disk metric confirms 5.08 MB.
- **User Impact:** Slower initial game download and ~5 MB extra RAM usage on low-end phones.
- **Business Risk:** Increased download abandonment rate on metered cellular networks.
- **Remediation Recommendation:** Convert to 128kbps OGG Vorbis (`bgm_ambient.ogg`, ~1.2 MB).
- **Post-Fix Testing Requirement:** Verify seamless background music playback and looping on Android and Windows.

---

### BUG-008: Supabase Account Takeover via Unvalidated Raw Email String (IDOR)
- **Bug ID:** `BUG-008`
- **Severity:** **CRITICAL**
- **Affected Location:** [scripts/core/profile_manager.gd:244-257](file:///d:/Documents/wrong-way/scripts/core/profile_manager.gd#L244-L257)
- **Technical Root Cause:**  
  `POST /rest/v1/rpc/login_or_link_google` accepts a bare email string (`p_email`) and maps the caller's device ID to that account with the public anon key. No Google OAuth token is verified.
- **Reproduction Steps:**
  Execute curl request with spoofed device ID and target email:
  ```bash
  curl -X POST "https://wcwjobrrwwjfthpflzhg.supabase.co/rest/v1/rpc/login_or_link_google" \
    -H "apikey: <ANON_KEY>" \
    -H "Authorization: Bearer <ANON_KEY>" \
    -H "Content-Type: application/json" \
    -d '{"p_device_id":"fake_device_99","p_email":"victim@gmail.com","p_username":"Hacker"}'
  ```
- **Verification Evidence:** Server returns HTTP 200 OK with target player's UUID, full save data, and updates device mapping.
- **User Impact:** Any player's account and cloud save can be stolen by anyone who knows their email address.
- **Business Risk:** Severe security breach; violation of Google Play Developer Policy and GDPR regulations.
- **Remediation Recommendation:** Enforce Supabase Auth `signInWithIdToken` and require verified Bearer JWT tokens in PostgreSQL RPCs (`auth.uid()`).
- **Post-Fix Testing Requirement:** Dispatch unauthenticated POST to RPC and verify server returns HTTP 401 Unauthorized.

---

### BUG-009: Arbitrary Cloud Save Overwrite via `sync_cloud_save` RPC
- **Bug ID:** `BUG-009`
- **Severity:** **HIGH**
- **Affected Location:** [scripts/core/profile_manager.gd:329-354](file:///d:/Documents/wrong-way/scripts/core/profile_manager.gd#L329-L354)
- **Technical Root Cause:** The RPC accepts `p_player_id` as an input parameter and performs an update without checking caller identity.
- **Reproduction Steps:** Send POST to `sync_cloud_save` with another user's UUID and empty save data.
- **Verification Evidence:** Server updates target profile record with HTTP 200 OK.
- **User Impact:** Malicious actors can wipe or corrupt any player's progression.
- **Business Risk:** Mass player progress loss leading to negative store reviews.
- **Remediation Recommendation:** Remove `p_player_id` parameter; extract caller ID strictly from `auth.uid()`.
- **Post-Fix Testing Requirement:** Attempt to update save data for a mismatched UUID; verify rejection with 403 Forbidden.

---

### BUG-010: Unauthorized Match Forfeiture via `forfeit_duel_disconnect` RPC
- **Bug ID:** `BUG-010`
- **Severity:** **HIGH**
- **Affected Location:** [scripts/multiplayer/duel_service.gd:384-389](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L384-L389)
- **Technical Root Cause:** Client submits opponent's ID claiming they disconnected; server accepts claim without server-side ping verification.
- **Reproduction Steps:** During active duel, send POST to `forfeit_duel_disconnect` passing opponent's UUID.
- **Verification Evidence:** Server immediately awards victory to the caller and sets match status to `FORFEITED`.
- **User Impact:** Unfair losses for legitimate players.
- **Business Risk:** Competitive multiplayer integrity ruined.
- **Remediation Recommendation:** Server must verify 3 missed heartbeat pings before executing a forfeit.
- **Post-Fix Testing Requirement:** Verify match remains active if opponent is sending regular heartbeats.

---

### BUG-011: Client-Dictated Competitive Duel Finish Time
- **Bug ID:** `BUG-011`
- **Severity:** **HIGH**
- **Affected Location:** [scripts/multiplayer/duel_service.gd:365-373](file:///d:/Documents/wrong-way/scripts/multiplayer/duel_service.gd#L365-L373)
- **Technical Root Cause:** Server trusts client self-reported `p_completion_time_ms` with zero anti-cheat or theoretical time minimum checks.
- **Reproduction Steps:** Call `claim_duel_finish` passing `completion_time_ms: 10.0`.
- **Verification Evidence:** Server immediately records 10ms victory.
- **User Impact:** Players encounter impossible cheat times in duels.
- **Business Risk:** Leaderboard and multiplayer abandonment.
- **Remediation Recommendation:** Store minimum theoretical completion times per level; reject claims below threshold.
- **Post-Fix Testing Requirement:** Send 10ms finish claim; verify rejection.

---

### BUG-012: Eight Complete Trap Types Unused in Official Campaign Levels
- **Bug ID:** `BUG-012`
- **Severity:** **LOW**
- **Affected Location:** `scenes/traps/*.tscn`, `scripts/traps/*.gd`
- **Technical Root Cause:** 8 traps were built and scripted, but never instantiated in any of the 60 levels.
- **Reproduction Steps:** Scan all 60 level scenes; observe 0 instances of `control_inverter`, `crashing_pillar`, `dodging_platform`, `falling_ceiling`, `invisible_block`, `jumping_spikes`, `rotating_spike_ball`, `sinking_door_floor`.
- **Verification Evidence:** AST catalog confirmed 481 total traps across 60 levels, all from the remaining 12 trap types.
- **User Impact:** Missed gameplay variety.
- **Business Risk:** Wasted development investment.
- **Remediation Recommendation:** Incorporate unused traps into Level Editor or future Chapter updates.
- **Post-Fix Testing Requirement:** Verify unused traps instantiate and function cleanly in custom editor levels.

---

### BUG-013: Duplicate Autoload Registration (`SaveSystem` & `SaveManager`)
- **Bug ID:** `BUG-013`
- **Severity:** **MEDIUM**
- **Affected Location:** `project.godot` (Lines 21 and 28)
- **Technical Root Cause:** `SaveManager` and `SaveSystem` both register `res://scripts/core/save_manager.gd` in `[autoload]`.
- **Reproduction Steps:** Inspect `project.godot` lines 21 and 28; observe dual declarations.
- **Verification Evidence:** At runtime, two root nodes (`/root/SaveManager` and `/root/SaveSystem`) exist simultaneously in memory.
- **User Impact:** Double memory usage for save state; risk of desynchronized progression if code accesses `SaveSystem`.
- **Business Risk:** Data divergence and hard-to-trace save bugs.
- **Remediation Recommendation:** Delete line 28 (`SaveSystem="*res://scripts/core/save_manager.gd"`) from `project.godot`.
- **Post-Fix Testing Requirement:** Boot engine, verify only `/root/SaveManager` exists in root tree.
