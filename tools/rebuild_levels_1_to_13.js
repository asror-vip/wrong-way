// tools/rebuild_levels_1_to_13.js
const fs = require('fs');
const path = require('path');

const jsonPath = path.join(__dirname, '..', 'data', 'levels.json');
const levels = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

function setLevel(id, data) {
  const idx = levels.findIndex(l => l.id === id);
  if (idx !== -1) {
    levels[idx] = Object.assign(levels[idx], data);
    console.log(`Rebuilt Level ${id}: ${levels[idx].title}`);
  }
}

// ====================================================================
// LEVELS 1–5: JUDA OSON (Very Easy / Onboarding)
// ====================================================================

// Level 1: Birinchi tuzoq (Oddiy sakrash va 1 ta ko'rinadigan qulovchi pol)
setLevel(1, {
  title: "Birinchi tuzoq",
  gimmick: "trap_floor",
  player_spawn: [80, 380],
  door_pos: [860, 380],
  door_config: { runaway: false, runaway_offset_x: 0 },
  platforms: [
    { name: "GroundStart", x: 0, y: 380, w: 320, h: 160 },
    { name: "GroundMid", x: 400, y: 380, w: 180, h: 160 },
    { name: "GroundEnd", x: 680, y: 380, w: 280, h: 160 }
  ],
  traps: [
    { name: "SpikesStart", type: "spikes", x: 200, y: 348, w: 48, h: 32, params: {} },
    { name: "TrapFloorMid", type: "trap_floor", x: 580, y: 380, w: 100, h: 160, params: {} }
  ]
});

// Level 2: Arra (1 ta sekin yuruvchi arra, tekis pol)
setLevel(2, {
  title: "Arra",
  gimmick: "moving_saw",
  player_spawn: [80, 380],
  door_pos: [860, 380],
  door_config: { runaway: false, runaway_offset_x: 0 },
  platforms: [
    { name: "GroundFull", x: 0, y: 380, w: 960, h: 160 }
  ],
  traps: [
    { name: "SpikesStart", type: "spikes", x: 280, y: 348, w: 48, h: 32, params: {} },
    { name: "MovingSaw1", type: "moving_saw", x: 560, y: 364, w: 32, h: 32, params: { patrol_distance: 140, patrol_speed: 95, patrol_axis: [-1, 0] } }
  ]
});

// Level 3: Yashirin tikanlar (1 ta kichik bo'shliq va sekin otiluvchi tikan)
setLevel(3, {
  title: "Yashirin tikanlar",
  gimmick: "pop_up_spikes",
  player_spawn: [80, 380],
  door_pos: [860, 380],
  door_config: { runaway: false, runaway_offset_x: 0 },
  platforms: [
    { name: "GroundStart", x: 0, y: 380, w: 380, h: 160 },
    { name: "GroundEnd", x: 450, y: 380, w: 510, h: 160 }
  ],
  traps: [
    { name: "PopUpSpike1", type: "pop_up_spikes", x: 260, y: 380, w: 48, h: 32, params: { trigger_distance: 70, warning_time: 0.7 } },
    { name: "SpikesFinish", type: "spikes", x: 680, y: 348, w: 48, h: 32, params: {} }
  ]
});

// Level 4: Aylanuvchi arra (1 ta aylanuvchi arra o'rtada, oson sakrab o'tiladi)
setLevel(4, {
  title: "Aylanuvchi arra",
  gimmick: "circular_saw",
  player_spawn: [80, 380],
  door_pos: [860, 380],
  door_config: { runaway: false, runaway_offset_x: 0 },
  platforms: [
    { name: "GroundStart", x: 0, y: 380, w: 420, h: 160 },
    { name: "GroundEnd", x: 490, y: 380, w: 470, h: 160 }
  ],
  traps: [
    { name: "SpikesStart", type: "spikes", x: 220, y: 348, w: 48, h: 32, params: {} },
    { name: "CircularSaw1", type: "circular_saw", x: 455, y: 300, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 1.8 } }
  ]
});

// Level 5: Ezuvchi (1 ta sekin ezuvchi, ritmi aniq va o'tish juda oson)
setLevel(5, {
  title: "Ezuvchi",
  gimmick: "crusher",
  player_spawn: [80, 380],
  door_pos: [860, 380],
  door_config: { runaway: false, runaway_offset_x: 0 },
  platforms: [
    { name: "GroundStart", x: 0, y: 380, w: 460, h: 160 },
    { name: "GroundEnd", x: 530, y: 380, w: 430, h: 160 }
  ],
  traps: [
    { name: "Crusher1", type: "crusher", x: 300, y: 140, w: 64, h: 64, params: { target_y: 320, wait_at_bottom: 1.2 } },
    { name: "SpikesEnd", type: "spikes", x: 680, y: 348, w: 48, h: 32, params: {} }
  ]
});

// ====================================================================
// LEVELS 6–13: HAR XIL TUZOQLAR & ASABNI BUZADIGAN TROLL KOMBINATSIYALAR
// ====================================================================

// Level 6: Lazer yo'lagi (Lazerlar + Otiluvchi tikanlar + Tuzoq pol)
setLevel(6, {
  title: "Lazer yo‘lagi",
  gimmick: "laser_hazards",
  player_spawn: [80, 380],
  door_pos: [880, 380],
  door_config: { runaway: false, runaway_offset_x: 0 },
  platforms: [
    { name: "GroundStart", x: 0, y: 380, w: 340, h: 160 },
    { name: "GroundMid", x: 420, y: 380, w: 220, h: 160 },
    { name: "GroundEnd", x: 720, y: 380, w: 240, h: 160 }
  ],
  traps: [
    { name: "Laser1", type: "laser_beam", x: 220, y: 220, w: 8, h: 160, params: { active_time: 1.4, inactive_time: 1.2 } },
    { name: "TrapFloorStart", type: "trap_floor", x: 300, y: 380, w: 40, h: 160, params: {} },
    { name: "Laser2", type: "laser_beam", x: 450, y: 220, w: 8, h: 160, params: { active_time: 1.1, inactive_time: 1.4 } },
    { name: "PopUpSpikesMid", type: "pop_up_spikes", x: 520, y: 380, w: 56, h: 32, params: { trigger_distance: 75, warning_time: 0.35 } },
    { name: "StalactiteMid", type: "falling_spike", x: 580, y: 60, w: 24, h: 32, params: { trigger_distance: 220, shake_duration: 0.4 } },
    { name: "Laser3", type: "laser_beam", x: 780, y: 220, w: 8, h: 160, params: { active_time: 1.3, inactive_time: 1.3 } }
  ]
});

// Level 7: Stalaktitlar va Qulovchi Shift (Tepadan ham, pastdan ham hujum)
setLevel(7, {
  title: "Stalaktitlar",
  gimmick: "falling_stalactites",
  player_spawn: [80, 380],
  door_pos: [880, 380],
  door_config: { runaway: false, runaway_offset_x: 0 },
  platforms: [
    { name: "GroundStart", x: 0, y: 380, w: 420, h: 160 },
    { name: "GroundMid", x: 500, y: 380, w: 220, h: 160 },
    { name: "GroundEnd", x: 800, y: 380, w: 160, h: 160 },
    { name: "Ceiling", x: 100, y: 0, w: 700, h: 60 }
  ],
  traps: [
    { name: "Stalactite1", type: "falling_spike", x: 180, y: 60, w: 24, h: 32, params: { trigger_distance: 280, shake_duration: 0.35 } },
    { name: "Stalactite2", type: "falling_spike", x: 280, y: 60, w: 24, h: 32, params: { trigger_distance: 260, shake_duration: 0.45 } },
    { name: "PopUpSpikesEdge", type: "pop_up_spikes", x: 380, y: 380, w: 40, h: 32, params: { trigger_distance: 70, warning_time: 0.3 } },
    { name: "MovingSawInGap", type: "moving_saw", x: 460, y: 370, w: 32, h: 32, params: { radius: 16, patrol_distance: 40, patrol_speed: 130, patrol_axis: [0, -1] } },
    { name: "Stalactite3", type: "falling_spike", x: 560, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.4 } },
    { name: "CrumblingLedge", type: "crumbling_platform", x: 660, y: 380, w: 60, h: 160, params: { crumble_delay: 0.5 } },
    { name: "Stalactite4", type: "falling_spike", x: 680, y: 60, w: 24, h: 32, params: { trigger_distance: 220, shake_duration: 0.3 } },
    { name: "SpikesEnd", type: "spikes", x: 820, y: 348, w: 40, h: 32, params: {} }
  ]
});

// Level 8: Tikanli shar (Shar + Orqadan keluvchi shar + Aylanuvchi arra + Uvalanuvchi pol)
setLevel(8, {
  title: "Tikanli shar",
  gimmick: "rolling_boulder",
  player_spawn: [80, 380],
  door_pos: [890, 380],
  door_config: { runaway: false, runaway_offset_x: 0 },
  platforms: [
    { name: "GroundStart", x: 0, y: 380, w: 360, h: 160 },
    { name: "GroundMid", x: 440, y: 380, w: 240, h: 160 },
    { name: "GroundEnd", x: 760, y: 380, w: 200, h: 160 },
    { name: "Ceiling", x: 240, y: 0, w: 200, h: 60 }
  ],
  traps: [
    { name: "RollingBoulderFront", type: "rolling_boulder", x: 420, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 360, trigger_distance: 260, delay_before_roll: 0.5 } },
    { name: "Stalactite1", type: "falling_spike", x: 300, y: 60, w: 24, h: 32, params: { trigger_distance: 220, shake_duration: 0.4 } },
    { name: "CircularSawMid", type: "circular_saw", x: 520, y: 325, w: 32, h: 32, params: { orbit_radius: 42, orbit_speed: 2.3 } },
    { name: "CrumblingLedge", type: "crumbling_platform", x: 600, y: 380, w: 80, h: 160, params: { crumble_delay: 0.5 } },
    { name: "RollingBoulderBack", type: "rolling_boulder", x: 460, y: 350, w: 56, h: 56, params: { roll_direction: 1, roll_speed: 340, trigger_distance: 160, delay_before_roll: 0.4 } },
    { name: "PopUpSpikesDoor", type: "pop_up_spikes", x: 790, y: 380, w: 48, h: 32, params: { trigger_distance: 70, warning_time: 0.35 } }
  ]
});

// Level 9: Ikki tomondan xavf & Eshik oldidagi tuzoq pol
// Eshik mustahkam [840..960] polida va orqasida devor bor. Tuzoq pol aynan eshikdan oldinda!
setLevel(9, {
  title: "Ikki tomondan xavf",
  gimmick: "dual_hazard",
  player_spawn: [80, 380],
  door_pos: [890, 380],
  door_config: { runaway: false, runaway_offset_x: 0 },
  platforms: [
    { name: "GroundStart", x: 0, y: 380, w: 340, h: 160 },
    { name: "GroundMid", x: 420, y: 380, w: 240, h: 160 },
    { name: "GroundDoor", x: 840, y: 380, w: 120, h: 160 },
    { name: "Ceiling", x: 280, y: 0, w: 240, h: 60 }
  ],
  traps: [
    { name: "PopUpSpike1", type: "pop_up_spikes", x: 160, y: 380, w: 32, h: 32, params: { trigger_distance: 70, warning_time: 0.3 } },
    { name: "PopUpSpike2", type: "pop_up_spikes", x: 210, y: 380, w: 32, h: 32, params: { trigger_distance: 70, warning_time: 0.5 } },
    { name: "MovingSawChase", type: "moving_saw", x: 300, y: 364, w: 32, h: 32, params: { patrol_distance: 140, patrol_speed: 150, patrol_axis: [-1, 0] } },
    { name: "CrusherMid", type: "crusher", x: 480, y: 140, w: 68, h: 64, params: { target_y: 320 } },
    { name: "StalactiteMid", type: "falling_spike", x: 580, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.4 } },
    { name: "RollingBoulderFront", type: "rolling_boulder", x: 700, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 340, trigger_distance: 240 } },
    // ESHIKDAN OLDINROQDA TUSHIB KETUVCHI POL:
    { name: "TrapFloorBeforeDoor", type: "trap_floor", x: 750, y: 380, w: 90, h: 160, params: {} }
  ]
});

// Level 10: Soxta eshik va Kutilmagan arra
// Soxta eshik yaqinlashganda yerga qulab g'oyib bo'ladi, haqiqiy eshikka yaqinlashganda esa pastdan arra otilib chiqadi!
setLevel(10, {
  title: "Soxta eshik",
  gimmick: "fake_door",
  player_spawn: [80, 380],
  door_pos: [880, 380],
  door_config: { runaway: false, runaway_offset_x: 0 },
  platforms: [
    { name: "GroundStart", x: 0, y: 380, w: 420, h: 160 },
    { name: "GroundMid", x: 480, y: 380, w: 240, h: 160 },
    { name: "GroundEnd", x: 780, y: 380, w: 180, h: 160 }
  ],
  traps: [
    { name: "SpikesStart", type: "spikes", x: 180, y: 348, w: 48, h: 32, params: {} },
    // Soxta eshik (yerga qulaydi)
    { name: "FakeDoorTrap", type: "fake_door", x: 340, y: 380, w: 32, h: 64, params: { run_away_distance: 95 } },
    { name: "PopUpSpikesBehind", type: "pop_up_spikes", x: 380, y: 380, w: 56, h: 32, params: { trigger_distance: 80, warning_time: 0.4 } },
    { name: "Laser1", type: "laser_beam", x: 540, y: 220, w: 8, h: 160, params: { active_time: 1.3, inactive_time: 1.2 } },
    { name: "Laser2", type: "laser_beam", x: 650, y: 220, w: 8, h: 160, params: { active_time: 1.2, inactive_time: 1.3 } },
    // Haqiqiy eshik oldidagi arra (pastdan otilib chiqadi!)
    { name: "DoorSurpriseSaw", type: "moving_saw", x: 820, y: 415, w: 32, h: 32, params: { radius: 18, patrol_distance: 60, patrol_speed: 360, patrol_axis: [0, -1], trigger_distance: 110 } }
  ]
});

// Level 11: Arra va stalaktit (Tunneldagi xavfli to'siqlar)
setLevel(11, {
  title: "Arra va stalaktit",
  gimmick: "saw_stalactite",
  player_spawn: [80, 380],
  door_pos: [880, 380],
  door_config: { runaway: false, runaway_offset_x: 0 },
  platforms: [
    { name: "GroundStart", x: 0, y: 380, w: 320, h: 160 },
    { name: "GroundMid", x: 400, y: 380, w: 240, h: 160 },
    { name: "GroundEnd", x: 720, y: 380, w: 240, h: 160 },
    { name: "TunnelCeiling", x: 0, y: 140, w: 960, h: 40 }
  ],
  traps: [
    { name: "MovingSawFront", type: "moving_saw", x: 220, y: 364, w: 32, h: 32, params: { patrol_distance: 130, patrol_speed: 130, patrol_axis: [-1, 0] } },
    { name: "Stalactite1", type: "falling_spike", x: 300, y: 180, w: 24, h: 32, params: { trigger_distance: 220, shake_duration: 0.35 } },
    { name: "MovingSawGap", type: "moving_saw", x: 360, y: 370, w: 32, h: 32, params: { radius: 16, patrol_distance: 40, patrol_speed: 130, patrol_axis: [0, -1] } },
    { name: "CrusherMid", type: "crusher", x: 480, y: 180, w: 64, h: 64, params: { target_y: 320 } },
    { name: "Stalactite2", type: "falling_spike", x: 580, y: 180, w: 24, h: 32, params: { trigger_distance: 200, shake_duration: 0.5 } },
    { name: "TrapFloorMid", type: "trap_floor", x: 640, y: 380, w: 80, h: 160, params: {} },
    { name: "PopUpSpikesDoor", type: "pop_up_spikes", x: 790, y: 380, w: 48, h: 32, params: { trigger_distance: 75, warning_time: 0.4 } }
  ]
});

// Level 12: Lazer va tikanli shar (Lazerlar + Kutilmagan tosh shar + Aylanuvchi arra)
setLevel(12, {
  title: "Lazer va tikanli shar",
  gimmick: "laser_boulder",
  player_spawn: [80, 380],
  door_pos: [880, 380],
  door_config: { runaway: false, runaway_offset_x: 0 },
  platforms: [
    { name: "GroundStart", x: 0, y: 380, w: 340, h: 160 },
    { name: "GroundMid", x: 420, y: 380, w: 260, h: 160 },
    { name: "GroundEnd", x: 760, y: 380, w: 200, h: 160 }
  ],
  traps: [
    { name: "Laser1", type: "laser_beam", x: 200, y: 220, w: 8, h: 160, params: { active_time: 1.4, inactive_time: 1.2 } },
    { name: "Laser2", type: "laser_beam", x: 300, y: 220, w: 8, h: 160, params: { active_time: 1.2, inactive_time: 1.4 } },
    { name: "RollingBoulder", type: "rolling_boulder", x: 500, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 340, trigger_distance: 240 } },
    { name: "PopUpSpikesPath", type: "pop_up_spikes", x: 550, y: 380, w: 48, h: 32, params: { trigger_distance: 75, warning_time: 0.35 } },
    { name: "CircularSawMid", type: "circular_saw", x: 640, y: 325, w: 32, h: 32, params: { orbit_radius: 40, orbit_speed: 2.2 } },
    { name: "LaserFinal", type: "laser_beam", x: 710, y: 220, w: 8, h: 160, params: { active_time: 1.3, inactive_time: 1.3 } },
    { name: "TrapFloorEnd", type: "trap_floor", x: 760, y: 380, w: 60, h: 160, params: {} }
  ]
});

// Level 13: Asabni buzuvchi ezuvchilar va qopqonlar (Barcha masofalar 80px, boyitilgan qiziqarli tuzoqlar)
setLevel(13, {
  title: "Ezuvchilar va Qopqonlar",
  gimmick: "crushers_gauntlet",
  player_spawn: [70, 380],
  door_pos: [890, 380],
  door_config: { runaway: false, runaway_offset_x: 0 },
  platforms: [
    { name: "GroundStart", x: 0, y: 380, w: 260, h: 160 },
    { name: "GroundMid1", x: 340, y: 380, w: 200, h: 160 },
    { name: "GroundMid2", x: 620, y: 380, w: 180, h: 160 },
    { name: "GroundDoor", x: 800, y: 380, w: 160, h: 160 },
    { name: "Ceiling1", x: 120, y: 0, w: 160, h: 60 },
    { name: "Ceiling2", x: 380, y: 0, w: 160, h: 60 }
  ],
  traps: [
    // 1. Birinchi ezuvchi
    { name: "Crusher1", type: "crusher", x: 160, y: 140, w: 68, h: 64, params: { target_y: 320 } },
    // 2. Kutilmagan stalaktit
    { name: "Stalactite1", type: "falling_spike", x: 220, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
    // 3. Oraliq 80px bo'shliqda harakatlanuvchi arra
    { name: "MovingSawInGap", type: "moving_saw", x: 300, y: 370, w: 32, h: 32, params: { radius: 16, patrol_distance: 40, patrol_speed: 130, patrol_axis: [0, -1] } },
    // 4. O'rta polga chiqqanda otiluvchi tikan
    { name: "PopUpSpikesMid", type: "pop_up_spikes", x: 380, y: 380, w: 48, h: 32, params: { trigger_distance: 75, warning_time: 0.4 } },
    // 5. Ikkinchi ezuvchi
    { name: "Crusher2", type: "crusher", x: 460, y: 140, w: 68, h: 64, params: { target_y: 320 } },
    // 6. O'rta pol cheti qulovchi pol
    { name: "TrapFloorEnd", type: "trap_floor", x: 500, y: 380, w: 40, h: 160, params: {} },
    // 7. Ikkinchi oraliqda vaqtga asoslangan lazer
    { name: "LaserBeamGap", type: "laser_beam", x: 580, y: 220, w: 8, h: 160, params: { active_time: 1.3, inactive_time: 1.3 } },
    // 8. Keyingi platformada aylanuvchi arra
    { name: "CircularSawMid2", type: "circular_saw", x: 670, y: 330, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 2.2 } },
    // 9. Finishga yaqinlashganda oldindan keluvchi tikanli shar!
    { name: "RollingBoulderFinal", type: "rolling_boulder", x: 860, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 320, trigger_distance: 220 } }
  ]
});

fs.writeFileSync(jsonPath, JSON.stringify(levels, null, 2), 'utf8');
console.log('Successfully rebuilt levels 1-13 in data/levels.json!');
