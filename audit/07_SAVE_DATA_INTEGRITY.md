# WRONG WAY — PHASE 7: SAVE SYSTEM & DATA INTEGRITY AUDIT

**Document ID:** `audit/07_SAVE_DATA_INTEGRITY.md`  
**Classification:** Persistence Layer, Progression Integrity & State Synchronization Review  
**Audit Date:** 2026-11-06  
**Auditor:** Senior Database & Systems Architect  
**Files Audited:**
- [scripts/core/save_manager.gd](file:///d:/Documents/wrong-way/scripts/core/save_manager.gd)
- [scripts/core/profile_manager.gd](file:///d:/Documents/wrong-way/scripts/core/profile_manager.gd)
- [scripts/core/game_manager.gd](file:///d:/Documents/wrong-way/scripts/core/game_manager.gd)
- [scripts/ui/level_select.gd](file:///d:/Documents/wrong-way/scripts/ui/level_select.gd)
- [scripts/ui/win_overlay.gd](file:///d:/Documents/wrong-way/scripts/ui/win_overlay.gd)

---

## 1. PERSISTENCE ARCHITECTURE OVERVIEW

The application utilizes a hybrid local/cloud persistence model:
1. **Local Persistent Storage:** Managed by `SaveManager` (`scripts/core/save_manager.gd`), serializing game state to Godot's `ConfigFile` format at `user://save_data.cfg`.
2. **Cloud Synchronization:** Managed by `ProfileManager` (`scripts/core/profile_manager.gd`), synchronizing the dictionary payload returned by `SaveManager.get_save_payload()` to Supabase PostgreSQL table `profiles.save_data`.

```
[Local Game Event] (e.g. Level Complete)
        │
        ▼
SaveManager.record_result(lvl, time_ms, deaths)
        │
        ├──> Update in-memory Dictionaries (level_stars, best_times, unlocked_levels)
        ├──> _write_config_atomic() ──> user://save_data.cfg.tmp ──> user://save_data.cfg.bak ──> user://save_data.cfg
        │
        └──> ProfileManager.sync_save_to_cloud()
                     │
                     ▼
             POST /rest/v1/rpc/sync_cloud_save
```

---

## 2. DISK PERSISTENCE & WRITE ATOMICITY AUDIT

### 2.1. Atomic Write Implementation (`_write_config_atomic`)
- **Location:** [scripts/core/save_manager.gd:89-106](file:///d:/Documents/wrong-way/scripts/core/save_manager.gd#L89-L106)
- **Code Inspection:**
  ```gdscript
  func _write_config_atomic(config: ConfigFile) -> void:
      var tmp_path := SAVE_PATH + ".tmp"
      var bak_path := SAVE_PATH + ".bak"
      var err := config.save(tmp_path)
      if err != OK:
          push_error("SaveManager: saqlashda xatolik (kod %d): %s" % [err, tmp_path])
          return
      var abs_save := ProjectSettings.globalize_path(SAVE_PATH)
      var abs_tmp := ProjectSettings.globalize_path(tmp_path)
      var abs_bak := ProjectSettings.globalize_path(bak_path)
      if FileAccess.file_exists(SAVE_PATH):
          DirAccess.copy_absolute(abs_save, abs_bak)
      var ren_err := DirAccess.rename_absolute(abs_tmp, abs_save)
      if ren_err != OK:
          push_error("SaveManager: atomik o'zgartirishda xatolik (kod %d)" % ren_err)
  ```
- **Strengths:**
  1. **Torn Write Prevention:** Code writes to `.tmp` first. If power is severed or process is killed during `config.save()`, the primary `save_data.cfg` is not truncated.
  2. **Backup Rotation:** Existing `save_data.cfg` is copied to `.bak` prior to renaming `.tmp`.
  3. **Fallback Recovery:** In `load_data()` (lines 40-42):
     ```gdscript
     var err := config.load(SAVE_PATH)
     if err != OK:
         err = config.load(SAVE_PATH + ".bak")
     ```
     If the main file is corrupted, the engine automatically rolls back to `.bak`.
- **Vulnerabilities / Edge Cases:**
  1. **Non-Atomic Windows Replace:** On Windows Win32 API, `MoveFileExW` without `MOVEFILE_REPLACE_EXISTING` fails if the destination already exists. In Godot `DirAccess.rename_absolute()`, behavior on Windows when destination exists can return an error (`ERR_ALREADY_EXISTS`) on certain Windows versions unless the target file is removed first. If `rename_absolute` fails, the new save remains trapped in `.tmp`.
  2. **No Cleanup of Stale `.tmp`:** If an error occurs, `.tmp` remains orphaned on disk indefinitely.

---

## 3. PROGRESSION LOGIC & UNLOCK RULES AUDIT

### 3.1. Level Star Rating Calculation
- **Location:** [scripts/core/save_manager.gd:144-150](file:///d:/Documents/wrong-way/scripts/core/save_manager.gd#L144-L150)
- **Rules:**
  - 0 Deaths = **3 Stars**
  - 1 or 2 Deaths = **2 Stars**
  - 3+ Deaths = **1 Star**

### 3.2. Level Unlock Threshold (CRITICAL PROGRESSION DESIGN)
- **Location:** [scripts/core/save_manager.gd:169-173](file:///d:/Documents/wrong-way/scripts/core/save_manager.gd#L169-L173)
  ```gdscript
  if stars >= 2:
      var next_lvl := lvl + 1
      if next_lvl <= 60 and not unlocked_levels.has(next_lvl):
          unlocked_levels.append(next_lvl)
  ```
- **Nuance & Impact:**
  - If a player beats a level with **3 or more deaths (1 star)**, the next level is **NOT unlocked**.
  - In `scripts/ui/win_overlay.gd` line 205:
    ```gdscript
    next_btn.visible = (last_stars >= 2 and last_lvl < 60)
    ```
    The "Next Level" button is completely hidden from the victory screen!
  - **Verdict:** This is strict arcade design: a player cannot stumble through the game with high death counts; they must either achieve at least 2 stars (<= 2 deaths) OR unlock the next level using an Ad reward.

### 3.3. Ad-Reward Unlock Mechanics
- **Location:** [scripts/core/save_manager.gd:271-295](file:///d:/Documents/wrong-way/scripts/core/save_manager.gd#L271-L295)
- **Three Guard Conditions:**
  1. **Strict Sequence:** Can only unlock the *immediate next locked level* (`lvl == first_locked`). Players cannot skip ahead to level 50 from level 5.
  2. **Prior Attempt Required:** The player must have attempted the previous level at least once (`attempted_levels.has(lvl - 1)`).
  3. **Skip-One Pacing (Cheriz):** At least one level between ad-unlocked levels must be beaten normally (`(lvl - last_ad_unlocked_level) >= 2`).
- **Data Integrity Evaluation:** Fully validated. The state variables (`ad_unlocked_levels`, `attempted_levels`, `last_ad_unlocked_level`) are properly serialized into the `[progress]` section of `save_data.cfg`.

---

## 4. CHAPTER TRANSITIONS & BOUNDARY AUDIT

The game divides 60 levels into 3 Chapters:
- **Chapter 1:** Levels 1 to 20 (Theme: Deep Night Forest)
- **Chapter 2:** Levels 21 to 40 (Theme: Winter Snow & Ice Peaks)
- **Chapter 3:** Levels 41 to 60 (Theme: Volcanic Underworld / Dark Citadel)

### 4.1. Chapter Unlock Verification (`is_chapter_unlocked`)
- **Location:** [scripts/core/save_manager.gd:431-440](file:///d:/Documents/wrong-way/scripts/core/save_manager.gd#L431-L440)
  ```gdscript
  func is_chapter_unlocked(chapter: int) -> bool:
      if debug_unlock_all:
          return true
      if chapter == 1:
          return true
      elif chapter == 2:
          return is_level_completed(20) or unlocked_levels.has(21) or ad_unlocked_levels.has(21)
      elif chapter == 3:
          return is_level_completed(40) or unlocked_levels.has(41) or ad_unlocked_levels.has(41)
      return false
  ```

### 4.2. Chapter 2 Boundary: Level 20 -> 21
- When Level 20 is completed with 2+ stars:
  - `unlocked_levels` appends 21.
  - `is_chapter_unlocked(2)` evaluates to `true`.
  - Chapter 2 map is unlocked and clouds disperse in `level_select.gd`.
- When Level 20 is completed with 1 star:
  - `level_stars["20"] = 1` -> `is_level_completed(20)` is `true`.
  - `is_chapter_unlocked(2)` evaluates to `true`.
  - HOWEVER, Level 21 itself is NOT in `unlocked_levels`. When the player enters Chapter 2, Level 21 appears locked with a padlock, requiring either Level 20 replay (2 stars) or Ad-unlock.

### 4.3. Chapter 3 Boundary: Level 40 -> 41
- When Level 40 is completed with 2+ stars:
  - `unlocked_levels` appends 41.
  - `is_chapter_unlocked(3)` evaluates to `true`.
  - Chapter 3 map unlocks correctly.
- When Level 40 is completed with 1 star:
  - Same behavior: Chapter 3 opens, but Level 41 requires Ad-unlock or 2 stars on Level 40.

### 4.4. Game Completion: Level 60
- When Level 60 is completed:
  - `next_lvl = 61`. Because `next_lvl <= 60` is false, `unlocked_levels` does not append 61.
  - `next_btn.visible` in `win_overlay.gd` evaluates to `false` (`last_lvl < 60` is false).
  - The player sees victory stars, best time, and options to return to Map or Main Menu.
  - No out-of-bounds error occurs.

---

## 5. CLOUD SYNCHRONIZATION & CONFLICT RESOLUTION

### 5.1. Conflict Resolution Engine (`merge_cloud_save`)
- **Location:** [scripts/core/save_manager.gd:195-250](file:///d:/Documents/wrong-way/scripts/core/save_manager.gd#L195-L250)
- **Merge Logic Analysis:**
  | Field | Conflict Strategy | Implementation Detail | Risk Assessment |
  | :--- | :--- | :--- | :--- |
  | `unlocked_levels` | **Mathematical Union** | `for lvl in c_unlocked: if not unlocked.has(lvl): append(lvl)` | **Safe:** Levels unlocked on either device remain unlocked. |
  | `level_stars` | **Max Value** | `if cloud_stars > local_stars: local = cloud` | **Safe:** Highest stars earned on either device are preserved. |
  | `level_best_times` | **Min Value** | `if cloud_time < local_time: local = cloud` | **Safe:** Fastest completion time wins. |
  | `overall_best_ms` | **Min Value** | `if cloud_ob < local_ob: local = cloud` | **Safe:** Record speedrun preserved. |
  | `settings` | **Local Priority** | Settings are omitted from cloud payload | **Safe:** Device-specific controls and volumes not overwritten. |

### 5.2. Multi-Device Concurrency & Divergence
- **Scenario:** Player plays Level 1-10 on Device A (Offline) and Level 11-15 on Device B (Offline).
- **Result upon reconnection:** Both devices merge via union and max. Device A receives unlocks 11-15; Device B receives unlocks 1-10. Neither device loses progression.
- **Flaw in Cloud Deletion:** If a user intentionally resets their local save via `reset_progress()`, their local save is cleared, but upon next cloud sync, `merge_cloud_save` will resurrect all cloud levels because it performs an additive union! There is currently no `tombstone` or save version timestamp to allow a user to reset their cloud save.

---

## 6. EDGE CASE RESILIENCE TABLE

| Edge Case Scenario | System Behavior | Data Integrity Result |
| :--- | :--- | :---: |
| **Sudden App Crash during Write** | `.tmp` file aborted; `.bak` and previous `.cfg` intact. | **PASS (Zero Loss)** |
| **Disk Full during Save** | `config.save(tmp_path)` returns error; aborts before touching `.cfg`. | **PASS (Graceful Fail)** |
| **Immediate Force-Quit after Win** | `record_result()` calls `save_data()` synchronously before scene change. | **PASS (Immediate Sync)** |
| **Offline Play for all 60 Levels** | Game functions 100% offline; queues cloud sync when online. | **PASS (Offline First)** |
| **Supabase Network Timeout / 500** | Client ignores HTTP error; local save remains source of truth. | **PASS (Resilient)** |
| **Intentional Progress Reset** | Local reset succeeds, but cloud sync re-downloads old progress. | **FAIL (Sticky Cloud Save)** |
| **Non-Editor `debug_unlock_all`** | Forcibly overridden to `false` if `not OS.has_feature("editor")`. | **PASS (Tamper Proof)** |

---

## 7. RECOMMENDATIONS FOR SAVE ENGINE

1. **Add Delete/Reset Cloud RPC:** Implement an explicit `reset_player_cloud_save` RPC so users can truly restart their progress across devices.
2. **Add Monotonic Save Timestamp:** Include `save_version` (integer) and `updated_at` (ISO timestamp) in `save_data.cfg` to allow true three-way merges rather than purely additive unions.
3. **Windows Rename Safety:** Explicitly remove existing destination file before `rename_absolute` to avoid Windows Win32 file collision lockups:
   ```gdscript
   if FileAccess.file_exists(SAVE_PATH):
       DirAccess.remove_absolute(abs_save)
   DirAccess.rename_absolute(abs_tmp, abs_save)
   ```

