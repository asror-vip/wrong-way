# WRONG WAY — PHASE 15: AUTOMATED TESTING & TEST SUITE AUDIT

**Document ID:** `audit/15_AUTOMATED_TEST_REPORT.md`  
**Classification:** Automated Test Harness Execution, QA Framework & Combinatoric Verification  
**Audit Date:** 2026-11-06  
**Auditor:** Senior QA Automation & Test Harness Engineer  
**Godot Engine Version:** Godot v4.7.2.stable.official.ed1daf0bf  
**Execution Environment:** Headless Godot Console CLI (`--headless -s`)  
**Raw Test Suite Results:** [audit/existing_test_suite_results.json](file:///d:/Documents/wrong-way/audit/existing_test_suite_results.json)  
**Structured Test Matrix:** [audit/TEST_CASES.csv](file:///d:/Documents/wrong-way/audit/TEST_CASES.csv)  

---

## 1. EXECUTIVE TEST SUITE SUMMARY

A full execution and diagnostic evaluation of all automated test scripts in the `tests/` directory was performed using the official Godot 4.7.2 headless console harness.

The audit revealed severe degradation in the legacy automated testing infrastructure:
- **Total Existing Test Scripts in Repository:** 8 scripts
- **Successfully Passed:** **1 / 8 (12.5%)**
- **Failed or Crashed:** **7 / 8 (87.5%)**

### Root Causes of Test Suite Failures:
1. **Broken Resource Paths (BUG-002):** Multiple tests attempt to load scenes from `res://scenes/menu/title_screen.tscn` or `res://scenes/menu/level_select.tscn`, which were moved or renamed to `res://scenes/main/main_menu.tscn` and `res://scenes/main/level_select.tscn`.
2. **Missing Autoload Injection (BUG-005):** Running standalone scripts via `godot --headless -s` replaces the SceneTree and does not initialize Autoload singletons (`GameManager`, `SoundManager`), causing immediate compilation failures in `test_player_dash.gd` and `render_level_06.gd`.
3. **References to Non-Existent Classes:** `test_session_and_player.gd` references `GameSession`, a class that was refactored or deleted from the active codebase.

---

## 2. DETAILED BREAKDOWN OF THE 8 REPOSITORY TEST SCRIPTS

| Test Script | Target System | Execution Mode | Exit Code | Status | Root Cause / Forensic Error |
| :--- | :--- | :---: | :---: | :---: | :--- |
| [tests/audit_all_levels.gd](file:///d:/Documents/wrong-way/tests/audit_all_levels.gd) | Level Design (1-60) | Headless CLI | 0 | **PASS** | Validated player spawn and exit door presence across all 60 level scenes. |
| [tests/test_player_dash.gd](file:///d:/Documents/wrong-way/tests/test_player_dash.gd) | Player Dash Burst | Headless CLI | 1 | **CRASH** | Compilation failed: `Identifier not found: GameManager` (BUG-005). |
| [tests/render_level_06.gd](file:///d:/Documents/wrong-way/tests/render_level_06.gd) | Level 6 Trap Rendering | Headless CLI | 1 | **CRASH** | Compilation failed on `GameManager` and `SoundManager` identifiers. |
| [tests/gameplay/test_ad_system.gd](file:///d:/Documents/wrong-way/tests/gameplay/test_ad_system.gd) | Monetization | Headless CLI | 1 | **FAIL** | `Assertion failed: Banner should be visible by default in menus`. |
| [tests/gameplay/test_full_game_flow.gd](file:///d:/Documents/wrong-way/tests/gameplay/test_full_game_flow.gd) | End-to-End Game Flow | Headless CLI | 1 | **CRASH** | `ERROR: Cannot open file 'res://scenes/menu/title_screen.tscn'` (BUG-002). |
| [tests/gameplay/test_menu_progression_and_stars.gd](file:///d:/Documents/wrong-way/tests/gameplay/test_menu_progression_and_stars.gd) | Progression & Stars | Headless CLI | 1 | **FAIL** | `Invalid assignment of property 'unlocked_levels' with type Array on typed Array[int]`. |
| [tests/gameplay/test_navigation_context.gd](file:///d:/Documents/wrong-way/tests/gameplay/test_navigation_context.gd) | Navigation / Modals | Headless CLI | 1 | **CRASH** | `ERROR: Cannot open file 'res://scenes/menu/level_select.tscn'` (BUG-002). |
| [tests/gameplay/test_session_and_player.gd](file:///d:/Documents/wrong-way/tests/gameplay/test_session_and_player.gd) | Game Session Model | Headless CLI | 1 | **CRASH** | `Parse Error: Identifier "GameSession" not declared in current scope`. |

---

## 3. MASTER STRUCTURED TEST MATRIX SUMMARY (55 TEST CASES)

In addition to evaluating the 8 repository scripts, our audit team established and executed a comprehensive 55-test scenario matrix documented in [audit/TEST_CASES.csv](file:///d:/Documents/wrong-way/audit/TEST_CASES.csv).

### Execution Statistics:
```
Total Test Cases Executed: 55
├── PASS (Passed Cleanly):      44 (80.0%)
├── FAIL (Confirmed Defect):    10 (18.2%)
└── BLOCKED (Harness Blocker):   1 ( 1.8%)
```

### Distribution by Subsystem:
- **Player Physics & Kinematics:** 10 Tests (9 PASS, 1 BLOCKED)
- **Trap Mechanics & Resets:** 11 Tests (8 PASS, 3 FAIL)
- **Progression & Save Integrity:** 9 Tests (9 PASS)
- **Authentication & Security:** 9 Tests (6 PASS, 3 FAIL)
- **Multiplayer & Duel Systems:** 4 Tests (2 PASS, 2 FAIL)
- **Monetization & Ad System:** 2 Tests (1 PASS, 1 FAIL)
- **UI/UX & Resolution:** 3 Tests (3 PASS)
- **All 60 Levels Runtime:** 4 Tests (4 PASS)
- **Test Harness Infrastructure:** 3 Tests (1 PASS, 2 FAIL)

---

## 4. 1,000-SCENARIO COMBINATORIC VALIDATION BLUEPRINT

To satisfy enterprise QA standards for a physics-based precision platformer, a 1,000-scenario combinatoric test suite should evaluate system intersections across varied inputs, timings, and environmental states.

```
[COMBINATORIC INPUT PARAMETERS]
├─ Velocity X (Run/Dash):   [-660, -320, 0, 320, 660] (5 states)
├─ Grounded / In-Air:       [Floor, Wall, Free-Fall, Ledge-Exit] (4 states)
├─ Coyote Window State:     [0ms, 80ms, 160ms, 200ms] (4 states)
├─ Jump Buffer State:       [0ms, 80ms, 160ms, 240ms] (4 states)
├─ Dash Cooldown State:     [0ms, 200ms, 400ms] (3 states)
├─ Invulnerability Window:  [Active (0-220ms), Inactive] (2 states)
└─ Active Trap Intersected: [Spike, Crusher, Saw, Laser, Boulder, None] (6 states)

Total Mathematical Combinations: 5 * 4 * 4 * 4 * 3 * 2 * 6 = 11,520 States
Target Selected Test Subsets: 1,000 Deterministic Permutations
```

### Recommended Test Architecture for Godot 4:
1. **Adopt GUT (Godot Unit Test) Framework:**
   Install `addons/gut/` to provide proper test runners, mocking utilities, signal assertions (`assert_signal_emitted`), and parameterized test cases (`params: [...]`).
2. **Implement Autoload-Safe Test Harness:**
   Instead of launching test scripts via raw `-s` flags, create a `test_runner.tscn` scene that boots the engine with all Autoloads active before executing test suites.
3. **Repair Broken Resource Paths:**
   Batch update all legacy `res://scenes/menu/` references to point to their modern locations (`res://scenes/main/`).
4. **Fix Type Rigidity in Progression Tests:**
   Replace raw `Array` assignments to `unlocked_levels` with typed arrays: `Array([1], TYPE_INT, "", null)`.

