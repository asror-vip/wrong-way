// tools/generate_all_levels.js
// Master level generator for Wrong Way (Levels 1 to 40)
// Reads data/levels.json and generates scenes/levels/level_01.tscn to level_40.tscn

const fs = require('fs');
const path = require('path');

const TRAP_SCENE_PATHS = {
  sinking_door_floor: "res://scenes/traps/sinking_door_floor.tscn",
  jumping_spikes: "res://scenes/traps/jumping_spikes.tscn",
  dodging_platform: "res://scenes/traps/dodging_platform.tscn",
  falling_ceiling: "res://scenes/traps/falling_ceiling.tscn",
  control_inverter: "res://scenes/traps/control_inverter.tscn",
  pop_up_spikes: "res://scenes/traps/pop_up_spikes.tscn",
  trap_floor: "res://scenes/traps/trap_floor.tscn",
  crumbling_platform: "res://scenes/traps/crumbling_platform.tscn",
  fake_door: "res://scenes/traps/fake_door.tscn",
  spikes: "res://scenes/traps/spikes.tscn",
  falling_spike: "res://scenes/traps/falling_spike.tscn",
  spring: "res://scenes/traps/spring.tscn",
  invisible_block: "res://scenes/traps/invisible_block.tscn",
  moving_saw: "res://scenes/traps/moving_saw.tscn",
  circular_saw: "res://scenes/traps/circular_saw.tscn",
  crusher: "res://scenes/traps/crusher.tscn",
  laser_beam: "res://scenes/traps/laser_beam.tscn",
  rolling_boulder: "res://scenes/traps/rolling_boulder.tscn"
};

function main() {
  const jsonPath = path.join(__dirname, '..', 'data', 'levels.json');
  const LEVELS = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  console.log(`Loaded ${LEVELS.length} levels from data/levels.json`);

  const levelsDir = path.join(__dirname, '..', 'scenes', 'levels');
  if (!fs.existsSync(levelsDir)) fs.mkdirSync(levelsDir, { recursive: true });

  for (const lvl of LEVELS) {
    const numPadded = String(lvl.id).padStart(2, '0');
    const fileName = `level_${numPadded}.tscn`;
    const filePath = path.join(levelsDir, fileName);

    const extResources = [];
    const extResourceMap = new Map();

    function getExtId(type, resPath) {
      if (extResourceMap.has(resPath)) return extResourceMap.get(resPath);
      const id = `${extResources.length + 1}_${type}`;
      extResources.push({ id, resPath });
      extResourceMap.set(resPath, id);
      return id;
    }

    const baseScriptId = getExtId("bl", "res://scripts/levels/base_level.gd");
    const playerId = getExtId("pl", "res://scenes/player/player.tscn");
    const platId = getExtId("sp", "res://scenes/objects/solid_platform.tscn");
    const doorId = getExtId("ed", "res://scenes/objects/exit_door.tscn");

    for (const trap of lvl.traps) {
      const trapPath = TRAP_SCENE_PATHS[trap.type];
      if (!trapPath) throw new Error(`Unknown trap type: ${trap.type}`);
      getExtId("tr", trapPath);
    }

    let tscn = `[gd_scene format=3 uid="uid://level${numPadded}scn"]\n\n`;
    for (const res of extResources) {
      const isScript = res.resPath.endsWith('.gd');
      const kind = isScript ? "Script" : "PackedScene";
      tscn += `[ext_resource type="${kind}" path="${res.resPath}" id="${res.id}"]\n`;
    }

    tscn += `\n[node name="Level${numPadded}" type="Node2D"]\n`;
    tscn += `script = ExtResource("${baseScriptId}")\n`;
    tscn += `level_number = ${lvl.id}\n\n`;

    // Platforms
    tscn += `[node name="Platforms" type="Node2D" parent="."]\n\n`;

    for (const p of lvl.platforms) {
      tscn += `[node name="${p.name}" parent="Platforms" instance=ExtResource("${platId}")]\n`;
      tscn += `position = Vector2(${p.x}, ${p.y})\n`;
      tscn += `platform_size = Vector2(${p.w}, ${p.h})\n\n`;
    }

    // Boundary walls
    tscn += `[node name="WallLeft" parent="Platforms" instance=ExtResource("${platId}")]\n`;
    tscn += `position = Vector2(0, 0)\n`;
    tscn += `platform_size = Vector2(32, 540)\n\n`;

    tscn += `[node name="WallRight" parent="Platforms" instance=ExtResource("${platId}")]\n`;
    tscn += `position = Vector2(928, 0)\n`;
    tscn += `platform_size = Vector2(32, 540)\n\n`;

    // Traps
    tscn += `[node name="Traps" type="Node2D" parent="."]\n\n`;

    for (const trap of lvl.traps) {
      const trapPath = TRAP_SCENE_PATHS[trap.type];
      const trapExtId = extResourceMap.get(trapPath);
      tscn += `[node name="${trap.name}" parent="Traps" instance=ExtResource("${trapExtId}")]\n`;
      tscn += `position = Vector2(${trap.x}, ${trap.y})\n`;

      if (trap.type === "spikes") {
        tscn += `spike_size = Vector2(${trap.w}, ${trap.h})\n`;
      } else if (trap.type === "pop_up_spikes") {
        tscn += `spike_width = ${trap.w}\n`;
        tscn += `max_spike_height = ${trap.h}\n`;
      } else if (trap.type === "trap_floor" || trap.type === "crumbling_platform") {
        tscn += `platform_size = Vector2(${trap.w}, ${trap.h})\n`;
      } else if (trap.type === "crusher") {
        tscn += `crusher_size = Vector2(${trap.w}, ${trap.h})\n`;
      } else if (trap.type === "laser_beam") {
        tscn += `beam_length = ${trap.h}\n`;
      } else if (trap.type === "spring") {
        tscn += `spring_size = Vector2(${trap.w}, ${trap.h})\n`;
      } else if (trap.type === "fake_door") {
        tscn += `door_size = Vector2(${trap.w}, ${trap.h})\n`;
      }

      for (const [k, v] of Object.entries(trap.params)) {
        if (Array.isArray(v)) {
          if (v.length === 2) {
            tscn += `${k} = Vector2(${v[0]}, ${v[1]})\n`;
          }
        } else if (typeof v === "boolean" || typeof v === "number") {
          tscn += `${k} = ${v}\n`;
        } else if (typeof v === "string") {
          tscn += `${k} = "${v}"\n`;
        }
      }
      tscn += `\n`;
    }

    // Exit Door
    tscn += `[node name="ExitDoor" parent="." instance=ExtResource("${doorId}")]\n`;
    tscn += `position = Vector2(${lvl.door_pos[0]}, ${lvl.door_pos[1]})\n\n`;

    // Player
    tscn += `[node name="Player" parent="." instance=ExtResource("${playerId}")]\n`;
    tscn += `position = Vector2(${lvl.player_spawn[0]}, ${lvl.player_spawn[1]})\n`;

    fs.writeFileSync(filePath, tscn, 'utf8');
  }

  console.log(`Generated all ${LEVELS.length} level scenes successfully!`);
}

main();
