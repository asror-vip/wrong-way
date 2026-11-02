// tools/patch_levels_1_to_13.js
const fs = require('fs');
const path = require('path');

const jsonPath = path.join(__dirname, '..', 'data', 'levels.json');
const levels = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

function updateLevel(id, updater) {
  const idx = levels.findIndex(l => l.id === id);
  if (idx !== -1) {
    updater(levels[idx]);
    console.log(`Updated Level ${id}: ${levels[idx].title}`);
  }
}

// 1. LEVEL 2: Add vertical hazards (ceiling stalactite + pop-up spikes before door)
updateLevel(2, (lvl) => {
  lvl.platforms = [
    { name: "GroundFull", x: 0, y: 380, w: 960, h: 160 },
    { name: "Ceiling", x: 360, y: 0, w: 160, h: 60 }
  ];
  lvl.traps = [
    { name: "SpikesStart", type: "spikes", x: 240, y: 348, w: 64, h: 32, params: {} },
    { name: "StalactiteCeiling", type: "falling_spike", x: 420, y: 60, w: 24, h: 32, params: { trigger_distance: 260, shake_duration: 0.5 } },
    { name: "MovingSaw1", type: "moving_saw", x: 540, y: 364, w: 32, h: 32, params: { patrol_distance: 150, patrol_speed: 130, patrol_axis: [-1, 0] } },
    { name: "MovingSaw2", type: "moving_saw", x: 670, y: 364, w: 32, h: 32, params: { patrol_distance: 130, patrol_speed: 140, patrol_axis: [1, 0] } },
    { name: "PopUpSpikesDoor", type: "pop_up_spikes", x: 760, y: 380, w: 48, h: 32, params: { trigger_distance: 70, warning_time: 0.35 } }
  ];
});

// 2. LEVEL 5: Fix 210px gap by adding safe middle stepping ledge
updateLevel(5, (lvl) => {
  lvl.platforms = [
    { name: "GroundStart", x: 0, y: 380, w: 220, h: 160 },
    { name: "GroundMid", x: 280, y: 380, w: 220, h: 160 },
    { name: "GroundLedge", x: 580, y: 380, w: 40, h: 160 },
    { name: "GroundEnd", x: 700, y: 380, w: 260, h: 160 },
    { name: "Ceiling1", x: 150, y: 0, w: 120, h: 80 }
  ];
  lvl.traps = [
    { name: "Stalactite1", type: "falling_spike", x: 200, y: 80, w: 24, h: 32, params: { trigger_distance: 320, shake_duration: 0.6 } },
    { name: "Crusher1", type: "crusher", x: 360, y: 140, w: 64, h: 64, params: { target_y: 320, wait_at_bottom: 0.8 } },
    { name: "TrapFloor1", type: "trap_floor", x: 500, y: 380, w: 80, h: 160, params: {} },
    { name: "TrapFloor2", type: "trap_floor", x: 620, y: 380, w: 80, h: 160, params: {} },
    { name: "Crusher2", type: "crusher", x: 760, y: 140, w: 64, h: 64, params: { target_y: 320 } },
    { name: "SpikesEnd", type: "spikes", x: 800, y: 348, w: 40, h: 32, params: {} }
  ];
});

// 3. LEVEL 8: Add crumbling ledge and ceiling stalactite for varied obstacles
updateLevel(8, (lvl) => {
  lvl.platforms = [
    { name: "GroundStart", x: 0, y: 380, w: 580, h: 160 },
    { name: "GroundEnd", x: 660, y: 380, w: 300, h: 160 },
    { name: "Ceiling", x: 280, y: 0, w: 140, h: 60 }
  ];
  lvl.traps = [
    { name: "RollingBoulderFront", type: "rolling_boulder", x: 430, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 360, trigger_distance: 260, delay_before_roll: 0.6 } },
    { name: "StalactiteCeiling", type: "falling_spike", x: 330, y: 60, w: 24, h: 32, params: { trigger_distance: 220, shake_duration: 0.5 } },
    { name: "CircularSawMid", type: "circular_saw", x: 530, y: 325, w: 32, h: 32, params: { orbit_radius: 44, orbit_speed: 2.4 } },
    { name: "CrumblingLedge", type: "crumbling_platform", x: 580, y: 380, w: 80, h: 160, params: { crumble_delay: 0.55 } },
    { name: "RollingBoulderBack", type: "rolling_boulder", x: 480, y: 350, w: 56, h: 56, params: { roll_direction: 1, roll_speed: 340, trigger_distance: 160, delay_before_roll: 0.5 } },
    { name: "SpikesFinish", type: "spikes", x: 770, y: 348, w: 48, h: 32, params: {} }
  ];
});

// 4. LEVEL 9: Trap floor placed directly in front of the door (player must jump across to enter door)
updateLevel(9, (lvl) => {
  lvl.door_pos = [890, 380];
  lvl.platforms = [
    { name: "GroundStart", x: 0, y: 380, w: 380, h: 160 },
    { name: "GroundMid", x: 380, y: 380, w: 240, h: 160 },
    { name: "GroundEnd", x: 620, y: 380, w: 120, h: 160 },
    { name: "GroundDoor", x: 840, y: 380, w: 120, h: 160 },
    { name: "Ceiling", x: 300, y: 0, w: 200, h: 60 }
  ];
  lvl.traps = [
    { name: "PopUpSpike1", type: "pop_up_spikes", x: 160, y: 380, w: 32, h: 32, params: { trigger_distance: 70, warning_time: 0.3 } },
    { name: "PopUpSpike2", type: "pop_up_spikes", x: 200, y: 380, w: 32, h: 32, params: { trigger_distance: 70, warning_time: 0.5 } },
    { name: "PopUpSpike3", type: "pop_up_spikes", x: 240, y: 380, w: 32, h: 32, params: { trigger_distance: 70, warning_time: 0.7 } },
    { name: "PopUpSpike4", type: "pop_up_spikes", x: 280, y: 380, w: 32, h: 32, params: { trigger_distance: 70, warning_time: 0.9 } },
    { name: "MovingSawBack", type: "moving_saw", x: 340, y: 364, w: 32, h: 32, params: { patrol_distance: 130, patrol_speed: 140, patrol_axis: [-1, 0] } },
    { name: "StalactiteMid", type: "falling_spike", x: 420, y: 60, w: 24, h: 32, params: { trigger_distance: 300, shake_duration: 0.5 } },
    { name: "CrusherMid", type: "crusher", x: 520, y: 140, w: 64, h: 64, params: { target_y: 320 } },
    { name: "RollingBoulderFront", type: "rolling_boulder", x: 720, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 340, trigger_distance: 240 } },
    { name: "TrapFloorBeforeDoor", type: "trap_floor", x: 740, y: 380, w: 100, h: 160, params: {} }
  ];
});

// 5. LEVEL 10: Fake door falls into ground and vanishes; saw pops up from below when approaching real door!
updateLevel(10, (lvl) => {
  lvl.door_pos = [870, 380];
  lvl.platforms = [
    { name: "GroundStart", x: 0, y: 380, w: 460, h: 160 },
    { name: "GroundEnd", x: 460, y: 380, w: 500, h: 160 }
  ];
  lvl.traps = [
    { name: "SpikesStart", type: "spikes", x: 190, y: 348, w: 48, h: 32, params: {} },
    { name: "FakeDoorTrap", type: "fake_door", x: 380, y: 380, w: 32, h: 64, params: { run_away_distance: 95 } },
    { name: "PopUpSpikesBehind", type: "pop_up_spikes", x: 420, y: 380, w: 56, h: 32, params: { trigger_distance: 80, warning_time: 0.45 } },
    { name: "Laser1", type: "laser_beam", x: 580, y: 220, w: 8, h: 160, params: { active_time: 1.4, inactive_time: 1.2 } },
    { name: "Laser2", type: "laser_beam", x: 690, y: 220, w: 8, h: 160, params: { active_time: 1.2, inactive_time: 1.4 } },
    { name: "DoorSurpriseSaw", type: "moving_saw", x: 800, y: 415, w: 32, h: 32, params: { radius: 18, patrol_distance: 60, patrol_speed: 360, patrol_axis: [0, -1], trigger_distance: 110 } }
  ];
});

// 6. LEVEL 11: Fair 80px gaps with solid middle step and popup spikes
updateLevel(11, (lvl) => {
  lvl.platforms = [
    { name: "GroundStart", x: 0, y: 380, w: 340, h: 160 },
    { name: "GroundMid", x: 420, y: 380, w: 60, h: 160 },
    { name: "GroundEnd", x: 560, y: 380, w: 400, h: 160 },
    { name: "TunnelCeiling", x: 0, y: 140, w: 960, h: 40 }
  ];
  lvl.traps = [
    { name: "MovingSawFront", type: "moving_saw", x: 240, y: 364, w: 32, h: 32, params: { patrol_distance: 140, patrol_speed: 130, patrol_axis: [-1, 0] } },
    { name: "Stalactite1", type: "falling_spike", x: 340, y: 180, w: 24, h: 32, params: { trigger_distance: 220, shake_duration: 0.3 } },
    { name: "Stalactite2", type: "falling_spike", x: 390, y: 180, w: 24, h: 32, params: { trigger_distance: 200, shake_duration: 0.6 } },
    { name: "TrapFloorMid", type: "trap_floor", x: 480, y: 380, w: 80, h: 160, params: {} },
    { name: "MovingSawBack", type: "moving_saw", x: 600, y: 364, w: 32, h: 32, params: { patrol_distance: 140, patrol_speed: 140, patrol_axis: [1, 0] } },
    { name: "PopUpSpikesDoor", type: "pop_up_spikes", x: 730, y: 380, w: 48, h: 32, params: { trigger_distance: 75, warning_time: 0.4 } },
    { name: "SpikesDoor", type: "spikes", x: 810, y: 348, w: 40, h: 32, params: {} }
  ];
});

// 7. LEVEL 13: Smooth 80px jump gaps and rich varied trap gauntlet (crushers, stalactite, saw in gap, popup spikes, trap floor, laser, rolling boulder)
updateLevel(13, (lvl) => {
  lvl.title = "Ezuvchilar va Qopqonlar";
  lvl.door_pos = [890, 380];
  lvl.player_spawn = [70, 380];
  lvl.platforms = [
    { name: "GroundStart", x: 0, y: 380, w: 280, h: 160 },
    { name: "GroundMid", x: 360, y: 380, w: 220, h: 160 },
    { name: "GroundEnd", x: 660, y: 380, w: 300, h: 160 },
    { name: "Ceiling1", x: 130, y: 0, w: 160, h: 60 },
    { name: "Ceiling2", x: 390, y: 0, w: 160, h: 60 }
  ];
  lvl.traps = [
    { name: "Crusher1", type: "crusher", x: 170, y: 140, w: 68, h: 64, params: { target_y: 320 } },
    { name: "Stalactite1", type: "falling_spike", x: 240, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.4 } },
    { name: "MovingSawInGap", type: "moving_saw", x: 320, y: 370, w: 32, h: 32, params: { radius: 16, patrol_distance: 40, patrol_speed: 130, patrol_axis: [0, -1] } },
    { name: "PopUpSpikesMid", type: "pop_up_spikes", x: 400, y: 380, w: 48, h: 32, params: { trigger_distance: 75, warning_time: 0.4 } },
    { name: "Crusher2", type: "crusher", x: 470, y: 140, w: 68, h: 64, params: { target_y: 320 } },
    { name: "TrapFloorEnd", type: "trap_floor", x: 530, y: 380, w: 50, h: 160, params: {} },
    { name: "LaserBeamGap", type: "laser_beam", x: 615, y: 220, w: 8, h: 160, params: { active_time: 1.3, inactive_time: 1.3 } },
    { name: "RollingBoulderFinal", type: "rolling_boulder", x: 840, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 320, trigger_distance: 200 } }
  ];
});

fs.writeFileSync(jsonPath, JSON.stringify(levels, null, 2), 'utf8');
console.log('Successfully updated data/levels.json!');
