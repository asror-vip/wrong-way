# WRONG WAY — PHASE 9: TRAP & HAZARD SYSTEMS AUDIT

**Document ID:** `audit/09_TRAP_SYSTEM_AUDIT.md`  
**Classification:** Physics Collision, Hazard Mechanics & State Reset Verification  
**Audit Date:** 2026-11-06  
**Auditor:** Senior Physics & Gameplay Mechanics Engineer  
**Files Audited:**
- All 20 trap scenes in `scenes/traps/*.tscn`
- All 22 scripts in `scripts/traps/*.gd`
- [scripts/levels/base_level.gd](file:///d:/Documents/wrong-way/scripts/levels/base_level.gd)
- [scripts/player/player_controller.gd](file:///d:/Documents/wrong-way/scripts/player/player_controller.gd)

---

## 1. EXECUTIVE SUMMARY & ARCHITECTURAL DISCONNECT

A comprehensive code and scene audit of all 20 trap types was conducted. The investigation revealed an acute architectural divergence:

1. **Orphaned Base Class Architecture:**  
   The codebase contains [scripts/traps/trap_base.gd](file:///d:/Documents/wrong-way/scripts/traps/trap_base.gd), a formal 76-line universal trap base class defining an enum `State { IDLE, ARMED, ACTIVE, RESET }` and lifecycle signals. **Not a single one of the 20 concrete trap implementations extends `TrapBase`**. Every trap script directly inherits from raw Godot engine classes (`Area2D`, `AnimatableBody2D`, `StaticBody2D`, `CharacterBody2D`).
2. **Dead Script:**  
   `scripts/traps/crusher_visuals.gd` is completely unreferenced by any scene or resource.
3. **8 Unused Trap Types in Level Progression:**  
   Of the 20 trap scenes created, **only 12 are actually deployed across the 60 levels**. 8 complete trap implementations (including `control_inverter`, `crashing_pillar`, `dodging_platform`, `falling_ceiling`, `invisible_block`, `jumping_spikes`, `rotating_spike_ball`, `sinking_door_floor`) have **0 instances** in any official campaign level.
4. **Active Hazard Count:**  
   A total of **481 trap instances** are distributed across the 60 levels, ranging from 2 traps in Level 1 to 28 traps in Level 60.

---

## 2. COMPLETE INVENTORY OF ALL 20 TRAP TYPES

| # | Trap Identifier | Script Path | Godot Base Class | Total in 60 Levels | Collision Type | Lethality Mode | Reset Supported? |
| :-: | :--- | :--- | :--- | :-: | :--- | :--- | :---: |
| 1 | `falling_spike` | `scripts/traps/falling_spike.gd` | `Area2D` | **80** | Proximity raycast + fall | Instant kill on hit | Yes (`reset_trap`) |
| 2 | `pop_up_spikes` | `scripts/traps/pop_up_spikes.gd` | `Area2D` | **52** | Timed / proximity spring | Instant kill when extended | Yes (`reset_trap`) |
| 3 | `circular_saw` | `scripts/traps/circular_saw.gd` | `Area2D` | **51** | Continuous rotation | Instant kill on contact | Yes (`reset_trap`) |
| 4 | `laser_beam` | `scripts/traps/laser_beam.gd` | `Area2D` | **48** | Periodic pulse beam | Instant kill when active | Yes (`reset_trap`) |
| 5 | `trap_floor` | `scripts/traps/trap_floor.gd` | `StaticBody2D` | **47** | Stepped-on collapse | Causes death plane fall | Yes (`reset_trap`) |
| 6 | `rolling_boulder`| `scripts/traps/rolling_boulder.gd`| `CharacterBody2D`| **46** | Kinematic roll + gravity | Instant kill on contact | Yes (`reset_trap`) |
| 7 | `crusher` | `scripts/traps/crusher.gd` | `Area2D` | **45** | Vertical crushing cycle | Instant kill on crush | Yes (`reset_trap`) |
| 8 | `spikes` | `scripts/traps/spikes.gd` | `Area2D` | **33** | Static floor/wall hazard | Instant kill on touch | Yes (`reset_trap`) |
| 9 | `moving_saw` | `scripts/traps/moving_saw.gd` | `Area2D` | **31** | Waypoint patrol saw | Instant kill on touch | Yes (`reset_trap`) |
| 10| `fake_door` | `scripts/traps/fake_door.gd` | `Area2D` | **23** | Deceptive exit replica | Instant kill on enter | Yes (`reset_trap`) |
| 11| `spring` | `scripts/traps/spring.gd` | `Area2D` | **23** | Launch pad into hazards | Kinetic push (optional kill) | Yes (`reset_trap`) |
| 12| `crumbling_platform`| `scripts/traps/crumbling_platform.gd`| `StaticBody2D` | **2** | Delayed disintegration | Causes death plane fall | Yes (`reset_trap`) |
| 13| `control_inverter`| `scripts/traps/control_inverter.gd`| `Area2D` | **0 (Unused)** | Trigger zone | Inverts player controls | Yes (`reset_trap`) |
| 14| `crashing_pillar`| `scripts/traps/crashing_pillar.gd`| `AnimatableBody2D`| **0 (Unused)** | Heavy vertical smash | Instant kill / squish | Yes (`reset_trap`) |
| 15| `dodging_platform`| `scripts/traps/dodging_platform.gd`| `AnimatableBody2D`| **0 (Unused)** | Flees when player nears | Causes missed jumps | Yes (`reset_trap`) |
| 16| `falling_ceiling`| `scripts/traps/falling_ceiling.gd`| `AnimatableBody2D`| **0 (Unused)** | Ceiling drop trap | Instant crush | Yes (`reset_trap`) |
| 17| `invisible_block`| `scripts/traps/invisible_block.gd`| `StaticBody2D` | **0 (Unused)** | Hidden mid-air block | Head bump into pit | Yes (`reset_trap`) |
| 18| `jumping_spikes` | `scripts/traps/jumping_spikes.gd` | `Area2D` | **0 (Unused)** | Vertical hopping spikes | Instant kill | Yes (`reset_trap`) |
| 19| `rotating_spike_ball`| `scripts/traps/rotating_spike_ball.gd`| `Area2D` | **0 (Unused)** | Pendulum / orbital chain | Instant kill | Yes (`reset_trap`) |
| 20| `sinking_door_floor`| `scripts/traps/sinking_door_floor.gd`| `StaticBody2D` | **0 (Unused)** | Floor sinks at exit | Blocks access | Yes (`reset_trap`) |

---

## 3. TRAP LIFECYCLE & STATE RESET VERIFICATION

### 3.1. How Traps Reset on Player Death
The game implements a reliable reset pipeline coordinated by `BaseLevel` (`scripts/levels/base_level.gd`):

1. **Player Death Event:**
   - In `PlayerController.kill()`: `died.emit()` is fired; player is relocated to `(-9999, -9999)` and deactivated.
   - In `BaseLevel._on_player_died()`:
     ```gdscript
     if traps_container:
         traps_container.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
     ```
     Freezes all ongoing trap animations and physics immediately upon death so traps do not continue moving while player is in ragdoll/death state.
2. **Player Respawn Event:**
   - 340ms after death, `PlayerController.respawn()` is called: restores position to `spawn_position` and emits `respawned`.
   - In `BaseLevel._on_player_respawned()`:
     ```gdscript
     func reset_level_traps() -> void:
         if exit_door:
             exit_door.reset_door()
         if traps_container:
             for trap in traps_container.get_children():
                 if trap.has_method("reset_trap"):
                     trap.reset_trap()
         get_tree().call_group("traps", "reset_trap")
     ```
   - All 481 traps reset their positions, rotation angles, velocities, and timers back to their initial state.
   - `traps_container.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)` unfreezes trap physics.

### 3.2. Spawn Kill Protection Window
- In `PlayerController.respawn()` (line 194):
  ```gdscript
  is_invulnerable = true
  invulnerable_timer = 0.22 # 220ms spawn protection
  ```
- All lethal traps check:
  ```gdscript
  if "is_invulnerable" in body and body.is_invulnerable:
      return
  ```
- **Finding:** This 220ms invulnerability window prevents spawn-lock loops where a lingering hazard or falling debris kills the player the instant they respawn.

---

## 4. COLLISION SHAPE & TIMING EDGE CASES

1. **`falling_spike.gd` Trigger Offset:**
   - Detects player via `dx < 32.0` and `dy > 0.0 and dy < trigger_distance`.
   - If a player dashes across the trigger zone at `DASH_SPEED = 660 px/s` (covering 32px in ~48ms), the spike will trigger behind the player, rewarding momentum and fast reflexes.
2. **`crusher.gd` Hitbox Safety:**
   - Uses an `Area2D` with down-stroke interpolation.
   - When reaching maximum extension, it holds for `hold_duration = 0.4s` before returning.
   - Resets accurately via `reset_trap()` without desynchronizing cycle phases.
3. **`fake_door.gd` Deception Mechanics:**
   - Exact visual replica of `exit_door.tscn`.
   - Upon player touch, instead of triggering `level_completed`, it plays `"trap"` audio, reveals spikes/demon eye, and calls `body.kill()`.
   - Perfectly functional and resets cleanly.

---

## 5. TECHNICAL DEBT & CLEANUP RECOMMENDATIONS

1. **Delete Dead Script:** Delete [scripts/traps/crusher_visuals.gd](file:///d:/Documents/wrong-way/scripts/traps/crusher_visuals.gd) (0 usages across codebase).
2. **Resolve `TrapBase` Orphan Architecture:** Either refactor active traps to formally inherit from `TrapBase` or remove `TrapBase` to eliminate confusing dead abstractions.
3. **Deploy Unused Traps in Level Updates:** The 8 unused trap types (`control_inverter`, `crashing_pillar`, `dodging_platform`, etc.) represent fully functional gameplay content. They should either be integrated into future Chapter expansions or exposed in the Level Editor catalog.

