# WRONG WAY — PHASE 5: PLAYER MOVEMENT & PHYSICS AUDIT

**Audit Phase:** 05 — Player Physics & Kinematics  
**Audit Date:** 2026-11-06  
**Auditor:** Game Physics & Collision Engineer  
**Script Under Audit:** [scripts/player/player_controller.gd](file:///d:/Documents/wrong-way/scripts/player/player_controller.gd)  
**Collision Scene:** [scenes/player/player.tscn](file:///d:/Documents/wrong-way/scenes/player/player.tscn)  

---

## 1. KINEMATIC PARAMETERS & PHYSICAL THRESHOLDS

All values verified directly from `scripts/player/player_controller.gd` lines 8–15:

| Kinematic Property | Value | Physical Unit | Mathematical Formula / Derived Limit |
| :--- | :---: | :---: | :--- |
| **Ground Running Speed (`SPEED`)** | `320.0` | px / s | Uniform horizontal ground velocity |
| **Dash Velocity (`DASH_SPEED`)** | `660.0` | px / s | 2.06× burst multiplier |
| **Dash Duration (`DASH_DURATION`)** | `0.16` | seconds | Burst distance: $660 \times 0.16 = 105.6\text{ px}$ |
| **Dash Cooldown (`DASH_COOLDOWN`)** | `0.40` | seconds | Prevents infinite dash spam |
| **Jump Velocity (`JUMP_VELOCITY`)** | `-560.0` | px / s | Initial upward impulse |
| **Gravity Acceleration (`GRAVITY`)** | `1450.0` | px / s² | Constant downward acceleration |
| **Max Short Jump Cutoff** | `-280.0` | px / s | Velocity clamped upon early jump key release |
| **Terminal Velocity** | `1200.0` | px / s | `minf(velocity.y, 1200.0)` prevents tunnel glitching |
| **Max Theoretical Jump Apex ($h$)** | **`108.14`** | px | $h = \frac{v_0^2}{2g} = \frac{560^2}{2 \times 1450}$ |
| **Air Hang Time ($t_{\text{air}}$)** | **`0.772`** | seconds | $t_{\text{air}} = 2 \times \frac{v_0}{g} = 2 \times \frac{560}{1450}$ |
| **Max Normal Horizontal Jump ($d_{\text{jump}}$)** | **`247.17`** | px | $d_{\text{jump}} = \text{SPEED} \times t_{\text{air}} = 320 \times 0.772$ |
| **Max Horizontal Reach with Dash** | **`352.77`** | px | $d_{\text{total}} = 247.17 + 105.6\text{ px}$ |

---

## 2. ADVANCED GAMEPLAY FEEL & ASSIST MECHANICS

### 2.1 Coyote Time Buffer
- **Implementation:** Line 69–73.
- **Value:** `0.16 seconds` (approx. 10 frames at 60 FPS).
- **Behavior:** When the player runs off a ledge without jumping, `coyote_timer` counts down from `0.16s`. If the jump key is pressed while `coyote_timer > 0.0`, the jump executes successfully in mid-air.
- **Evaluation:** **PASS**. Generous reaction window that prevents frustrating cliff-edge falls.

---

### 2.2 Jump Input Buffering
- **Implementation:** Line 74–76, 109–110.
- **Value:** `0.16 seconds` (approx. 10 frames at 60 FPS).
- **Behavior:** If the player presses the jump key up to 160ms *before* touching the ground, the input is buffered. The moment `is_on_floor()` becomes true, the jump immediately executes.
- **Evaluation:** **PASS**. Eliminates lost inputs upon landing.

---

### 2.3 Variable Jump Height
- **Implementation:** Line 125–126.
- **Behavior:**
  ```gdscript
  if Input.is_action_just_released("jump") and velocity.y < MAX_SHORT_JUMP_FALL:
      velocity.y = MAX_SHORT_JUMP_FALL
  ```
- **Evaluation:** **PASS**. Tapping jump yields a quick hop (~35px apex), while holding jump produces full vertical rise (108px apex).

---

### 2.4 Genshin Impact Style Single-Tap Dash
- **Implementation:** Line 84–102.
- **Rules:**
  - Uses `Input.is_action_just_pressed("dash")`. Holding the key does *not* sustain the dash.
  - Spawns ghost afterimages via `_spawn_dash_ghost()` every 38ms.
  - Cooldown timer (`0.40s`) guarantees player cannot dash continuously.
- **Evaluation:** **PASS**.

---

### 2.5 Spawn Protection / Anti-Camp Invulnerability
- **Implementation:** Line 193–194.
- **Value:** `0.22 seconds` (220ms).
- **Behavior:** Upon respawn, `is_invulnerable = true` for 220ms. Prevents traps located immediately at or near the spawn point from triggering infinite death loops.
- **Evaluation:** **PASS**.

---

## 3. COLLISION GEOMETRY & BOUNDS INTEGRITY

### 3.1 Collision Shape vs Visual Sprite
- **Shape Type:** `RectangleShape2D` (Width = 28px, Height = 32px).
- **Offset:** Center at `(0, -16)`.
- **Character Origin:** Bottom-center `(0, 0)` rests flush with ground platforms.
- **Hitbox Tightness:** 28px width gives 2px forgiveness on each side of standard 32px grid tiles.
- **Evaluation:** **PASS**. Fair hitbox alignment.

---

### 3.2 Collision Layers & Masks
- **Collision Layer:** `Layer 2` (`0010` in binary) — Reserved exclusively for Player.
- **Collision Mask:** `Layer 1 + Layer 3` (Value = 5):
  - `Layer 1`: Solid platforms, boundary walls, ceilings.
  - `Layer 3`: Trap hazards (spikes, saws, boulders, crushers).
- **Evaluation:** **PASS**. Clean physics layer separation.

---

### 3.3 Death Plane
- **Implementation:** Line 140–149.
- **Threshold:** `death_y = maxf(viewport.size.y, 540.0) + 210.0` (typically 750.0 px).
- **Behavior:** Falling into endless pits automatically triggers `kill()` and scene respawn without requiring invisible trigger volumes in every level.
- **Evaluation:** **PASS**.

---

## 4. DEFECTS & BLOCKERS IDENTIFIED IN PHYSICS TESTING

### DEF-PHYS-001: Autoload Dependency Blocks Standalone Testing (BUG-005)
- **File:** `scripts/player/player_controller.gd` (Line 46).
- **Code:**
  ```gdscript
  if is_dead or is_entering_door or GameManager.is_countdown_active:
  ```
- **Runtime Error during Headless Test:**
  ```
  SCRIPT ERROR: Trying to assign value of type 'CharacterBody2D' to a variable of type 'player_controller.gd'.
     at: _init (res://tests/test_player_dash.gd:9)
  ```
- **Impact:** Standalone unit tests (`tests/test_player_dash.gd`) fail because `player_controller.gd` cannot compile without `GameManager` in the Autoload tree.

