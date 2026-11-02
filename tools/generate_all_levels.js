// tools/generate_all_levels.js
// Generates data/levels.json and scenes/levels/level_01.tscn to level_20.tscn
// strictly following the GPT game design specification.

const fs = require('fs');
const path = require('path');

const LEVELS = [
  {
    id: 1,
    chapter: 1,
    title: "Birinchi tuzoq",
    gimmick: "trap_floor",
    player_spawn: [80, 380],
    door_pos: [860, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 300, h: 160 },
      { name: "GroundMid", x: 420, y: 380, w: 140, h: 160 },
      { name: "GroundEnd", x: 680, y: 380, w: 280, h: 160 }
    ],
    traps: [
      { name: "SpikesStart", type: "spikes", x: 200, y: 348, w: 64, h: 32, params: {} },
      { name: "TrapFloorMid", type: "trap_floor", x: 560, y: 380, w: 120, h: 160, params: {} },
      { name: "SpikesEnd", type: "spikes", x: 760, y: 348, w: 48, h: 32, params: {} }
    ]
  },
  {
    id: 2,
    chapter: 1,
    title: "Arra",
    gimmick: "moving_saw",
    player_spawn: [80, 380],
    door_pos: [860, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundFull", x: 0, y: 380, w: 960, h: 160 }
    ],
    traps: [
      { name: "SpikesMid", type: "spikes", x: 260, y: 348, w: 80, h: 32, params: {} },
      { name: "MovingSaw1", type: "moving_saw", x: 560, y: 364, w: 32, h: 32, params: { patrol_distance: 160.0, patrol_speed: 130.0, patrol_axis: [-1, 0] } },
      { name: "MovingSaw2", type: "moving_saw", x: 680, y: 364, w: 32, h: 32, params: { patrol_distance: 140.0, patrol_speed: 130.0, patrol_axis: [1, 0] } },
      { name: "SpikesDoor", type: "spikes", x: 780, y: 348, w: 48, h: 32, params: {} }
    ]
  },
  {
    id: 3,
    chapter: 1,
    title: "Yashirin tikanlar",
    gimmick: "pop_up_spikes",
    player_spawn: [80, 380],
    door_pos: [860, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 220, h: 160 },
      { name: "GroundMid", x: 340, y: 380, w: 320, h: 160 },
      { name: "GroundEnd", x: 740, y: 380, w: 220, h: 160 }
    ],
    traps: [
      { name: "TrapFloorStart", type: "trap_floor", x: 220, y: 380, w: 120, h: 160, params: {} },
      { name: "PopUpSpike1", type: "pop_up_spikes", x: 420, y: 380, w: 48, h: 32, params: { trigger_distance: 85.0, warning_time: 0.45 } },
      { name: "PopUpSpike2", type: "pop_up_spikes", x: 560, y: 380, w: 48, h: 32, params: { trigger_distance: 70.0, warning_time: 0.65 } },
      { name: "SpikesFinish", type: "spikes", x: 780, y: 348, w: 48, h: 32, params: {} }
    ]
  },
  {
    id: 4,
    chapter: 1,
    title: "Aylanuvchi arra",
    gimmick: "circular_saw",
    player_spawn: [80, 380],
    door_pos: [860, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 260, h: 160 },
      { name: "GroundMid", x: 340, y: 380, w: 260, h: 160 },
      { name: "GroundEnd", x: 710, y: 380, w: 250, h: 160 },
      { name: "CeilingCorridor", x: 720, y: 240, w: 120, h: 40 }
    ],
    traps: [
      { name: "SpikesStart", type: "spikes", x: 180, y: 348, w: 48, h: 32, params: {} },
      { name: "CircularSaw1", type: "circular_saw", x: 460, y: 310, w: 32, h: 32, params: { orbit_radius: 52.0, orbit_speed: 2.2 } },
      { name: "TrapFloorMid", type: "trap_floor", x: 600, y: 380, w: 110, h: 160, params: {} },
      { name: "CircularSaw2", type: "circular_saw", x: 770, y: 330, w: 32, h: 32, params: { orbit_radius: 34.0, orbit_speed: 2.8 } }
    ]
  },
  {
    id: 5,
    chapter: 1,
    title: "Ezuvchi",
    gimmick: "crusher",
    player_spawn: [80, 380],
    door_pos: [860, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 220, h: 160 },
      { name: "GroundMid", x: 280, y: 380, w: 200, h: 160 },
      { name: "GroundEnd", x: 690, y: 380, w: 270, h: 160 },
      { name: "Ceiling1", x: 150, y: 0, w: 120, h: 80 }
    ],
    traps: [
      { name: "Stalactite1", type: "falling_spike", x: 200, y: 80, w: 24, h: 32, params: { trigger_distance: 320.0, shake_duration: 0.6 } },
      { name: "Crusher1", type: "crusher", x: 360, y: 140, w: 64, h: 64, params: { target_y: 320.0, wait_at_bottom: 0.8 } },
      { name: "TrapFloor1", type: "trap_floor", x: 480, y: 380, w: 70, h: 160, params: {} },
      { name: "TrapFloor2", type: "trap_floor", x: 550, y: 380, w: 70, h: 160, params: {} },
      { name: "TrapFloor3", type: "trap_floor", x: 620, y: 380, w: 70, h: 160, params: {} },
      { name: "Crusher2", type: "crusher", x: 750, y: 140, w: 64, h: 64, params: { target_y: 320.0 } },
      { name: "SpikesEnd", type: "spikes", x: 780, y: 348, w: 40, h: 32, params: {} }
    ]
  },
  {
    id: 6,
    chapter: 1,
    title: "Lazer yo‘lagi",
    gimmick: "laser_beam",
    player_spawn: [80, 380],
    door_pos: [860, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 260, h: 160 },
      { name: "GroundMid", x: 260, y: 380, w: 280, h: 160 },
      { name: "GroundEnd", x: 660, y: 380, w: 300, h: 160 }
    ],
    traps: [
      { name: "Laser1", type: "laser_beam", x: 240, y: 220, w: 8, h: 160, params: { active_time: 1.6, inactive_time: 1.4 } },
      { name: "Laser2", type: "laser_beam", x: 380, y: 220, w: 8, h: 160, params: { active_time: 1.2, inactive_time: 1.8 } },
      { name: "PopUpSpikesMid", type: "pop_up_spikes", x: 470, y: 380, w: 50, h: 32, params: { trigger_distance: 75.0, warning_time: 0.45 } },
      { name: "TrapFloorMid", type: "trap_floor", x: 540, y: 380, w: 120, h: 160, params: {} },
      { name: "Laser3", type: "laser_beam", x: 780, y: 220, w: 8, h: 160, params: { active_time: 1.4, inactive_time: 1.5 } }
    ]
  },
  {
    id: 7,
    chapter: 1,
    title: "Stalaktitlar",
    gimmick: "falling_spike",
    player_spawn: [80, 380],
    door_pos: [860, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 480, h: 160 },
      { name: "GroundEnd", x: 660, y: 380, w: 300, h: 160 },
      { name: "Ceiling", x: 100, y: 0, w: 600, h: 60 }
    ],
    traps: [
      { name: "Stalactite1", type: "falling_spike", x: 180, y: 60, w: 24, h: 32, params: { trigger_distance: 320.0, shake_duration: 0.2 } },
      { name: "Stalactite2", type: "falling_spike", x: 290, y: 60, w: 24, h: 32, params: { trigger_distance: 240.0, shake_duration: 0.5 } },
      { name: "Stalactite3", type: "falling_spike", x: 400, y: 60, w: 24, h: 32, params: { trigger_distance: 160.0, shake_duration: 0.6 } },
      { name: "SpikesFloor", type: "spikes", x: 440, y: 348, w: 40, h: 32, params: {} },
      { name: "TrapFloorMid", type: "trap_floor", x: 540, y: 380, w: 120, h: 160, params: {} },
      { name: "Stalactite4", type: "falling_spike", x: 600, y: 60, w: 24, h: 32, params: { trigger_distance: 300.0, shake_duration: 0.4 } }
    ]
  },
  {
    id: 8,
    chapter: 1,
    title: "Tikanli shar",
    gimmick: "rolling_boulder",
    player_spawn: [80, 380],
    door_pos: [860, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundFull", x: 0, y: 380, w: 960, h: 160 }
    ],
    traps: [
      { name: "RollingBoulderFront", type: "rolling_boulder", x: 440, y: 350, w: 56, h: 56, params: { roll_direction: -1.0, roll_speed: 360.0, trigger_distance: 260.0, delay_before_roll: 0.7 } },
      { name: "CircularSawMid", type: "circular_saw", x: 560, y: 325, w: 32, h: 32, params: { orbit_radius: 46.0, orbit_speed: 2.4 } },
      { name: "RollingBoulderBack", type: "rolling_boulder", x: 480, y: 350, w: 56, h: 56, params: { roll_direction: 1.0, roll_speed: 340.0, trigger_distance: 160.0, delay_before_roll: 0.6 } },
      { name: "SpikesFinish", type: "spikes", x: 760, y: 348, w: 50, h: 32, params: {} }
    ]
  },
  {
    id: 9,
    chapter: 1,
    title: "Ikki tomondan xavf",
    gimmick: "dual_hazard",
    player_spawn: [80, 380],
    door_pos: [880, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 380, h: 160 },
      { name: "GroundMid", x: 380, y: 380, w: 260, h: 160 },
      { name: "GroundEnd", x: 640, y: 380, w: 320, h: 160 },
      { name: "Ceiling", x: 300, y: 0, w: 200, h: 60 }
    ],
    traps: [
      { name: "PopUpSpike1", type: "pop_up_spikes", x: 160, y: 380, w: 32, h: 32, params: { trigger_distance: 70.0, warning_time: 0.3 } },
      { name: "PopUpSpike2", type: "pop_up_spikes", x: 200, y: 380, w: 32, h: 32, params: { trigger_distance: 70.0, warning_time: 0.5 } },
      { name: "PopUpSpike3", type: "pop_up_spikes", x: 240, y: 380, w: 32, h: 32, params: { trigger_distance: 70.0, warning_time: 0.7 } },
      { name: "PopUpSpike4", type: "pop_up_spikes", x: 280, y: 380, w: 32, h: 32, params: { trigger_distance: 70.0, warning_time: 0.9 } },
      { name: "MovingSawBack", type: "moving_saw", x: 340, y: 364, w: 32, h: 32, params: { patrol_distance: 130.0, patrol_speed: 140.0, patrol_axis: [-1, 0] } },
      { name: "StalactiteMid", type: "falling_spike", x: 420, y: 60, w: 24, h: 32, params: { trigger_distance: 300.0, shake_duration: 0.5 } },
      { name: "CrusherMid", type: "crusher", x: 520, y: 140, w: 64, h: 64, params: { target_y: 320.0 } },
      { name: "RollingBoulderFront", type: "rolling_boulder", x: 840, y: 350, w: 56, h: 56, params: { roll_direction: -1.0, roll_speed: 340.0, trigger_distance: 260.0 } }
    ]
  },
  {
    id: 10,
    chapter: 1,
    title: "Soxta eshik",
    gimmick: "fake_door",
    player_spawn: [80, 380],
    door_pos: [860, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 460, h: 160 },
      { name: "GroundEnd", x: 500, y: 380, w: 460, h: 160 }
    ],
    traps: [
      { name: "SpikesStart", type: "spikes", x: 200, y: 348, w: 48, h: 32, params: {} },
      { name: "FakeDoorTrap", type: "fake_door", x: 400, y: 380, w: 32, h: 64, params: { run_away_distance: 90.0 } },
      { name: "PopUpSpikesBehind", type: "pop_up_spikes", x: 440, y: 380, w: 60, h: 32, params: { trigger_distance: 80.0, warning_time: 0.45 } },
      { name: "Laser1", type: "laser_beam", x: 620, y: 220, w: 8, h: 160, params: { active_time: 1.5, inactive_time: 1.3 } },
      { name: "Laser2", type: "laser_beam", x: 740, y: 220, w: 8, h: 160, params: { active_time: 1.3, inactive_time: 1.5 } }
    ]
  },
  {
    id: 11,
    chapter: 1,
    title: "Arra va stalaktit",
    gimmick: "saw_stalactite",
    player_spawn: [80, 380],
    door_pos: [860, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 320, h: 160 },
      { name: "GroundEnd", x: 560, y: 380, w: 400, h: 160 },
      { name: "TunnelCeiling", x: 0, y: 140, w: 960, h: 40 }
    ],
    traps: [
      { name: "MovingSawFront", type: "moving_saw", x: 240, y: 364, w: 32, h: 32, params: { patrol_distance: 140.0, patrol_speed: 130.0, patrol_axis: [-1, 0] } },
      { name: "Stalactite1", type: "falling_spike", x: 340, y: 180, w: 24, h: 32, params: { trigger_distance: 220.0, shake_duration: 0.3 } },
      { name: "Stalactite2", type: "falling_spike", x: 390, y: 180, w: 24, h: 32, params: { trigger_distance: 200.0, shake_duration: 0.6 } },
      { name: "TrapFloorMid", type: "trap_floor", x: 420, y: 380, w: 140, h: 160, params: {} },
      { name: "MovingSawBack", type: "moving_saw", x: 600, y: 364, w: 32, h: 32, params: { patrol_distance: 140.0, patrol_speed: 140.0, patrol_axis: [1, 0] } },
      { name: "SpikesDoor", type: "spikes", x: 760, y: 348, w: 48, h: 32, params: {} }
    ]
  },
  {
    id: 12,
    chapter: 1,
    title: "Lazer va tikanli shar",
    gimmick: "laser_boulder",
    player_spawn: [80, 380],
    door_pos: [880, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 700, h: 160 },
      { name: "GroundEnd", x: 800, y: 380, w: 160, h: 160 }
    ],
    traps: [
      { name: "Laser1", type: "laser_beam", x: 220, y: 220, w: 8, h: 160, params: { active_time: 1.4, inactive_time: 1.4 } },
      { name: "Laser2", type: "laser_beam", x: 340, y: 220, w: 8, h: 160, params: { active_time: 1.6, inactive_time: 1.2 } },
      { name: "Laser3", type: "laser_beam", x: 460, y: 220, w: 8, h: 160, params: { active_time: 1.2, inactive_time: 1.6 } },
      { name: "RollingBoulder", type: "rolling_boulder", x: 680, y: 350, w: 56, h: 56, params: { roll_direction: -1.0, roll_speed: 360.0, trigger_distance: 250.0 } },
      { name: "PopUpSpikesPath", type: "pop_up_spikes", x: 560, y: 380, w: 50, h: 32, params: { trigger_distance: 80.0, warning_time: 0.4 } },
      { name: "TrapFloorEnd", type: "trap_floor", x: 700, y: 380, w: 100, h: 160, params: {} },
      { name: "LaserFinal", type: "laser_beam", x: 810, y: 220, w: 8, h: 160, params: { active_time: 1.3, inactive_time: 1.5 } }
    ]
  },
  {
    id: 13,
    chapter: 1,
    title: "Ezuvchilar",
    gimmick: "crushers_gauntlet",
    player_spawn: [80, 380],
    door_pos: [860, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 460, h: 160 },
      { name: "GroundEnd", x: 720, y: 380, w: 240, h: 160 },
      { name: "Ceiling", x: 360, y: 0, w: 200, h: 60 }
    ],
    traps: [
      { name: "Crusher1", type: "crusher", x: 180, y: 140, w: 70, h: 64, params: { target_y: 320.0 } },
      { name: "Crusher2", type: "crusher", x: 320, y: 140, w: 70, h: 64, params: { target_y: 320.0 } },
      { name: "Stalactite1", type: "falling_spike", x: 420, y: 60, w: 24, h: 32, params: { trigger_distance: 280.0, shake_duration: 0.4 } },
      { name: "Stalactite2", type: "falling_spike", x: 470, y: 60, w: 24, h: 32, params: { trigger_distance: 260.0, shake_duration: 0.5 } },
      { name: "SpikesFloor", type: "spikes", x: 510, y: 348, w: 50, h: 32, params: {} },
      { name: "TrapFloor1", type: "trap_floor", x: 560, y: 380, w: 80, h: 160, params: {} },
      { name: "TrapFloor2", type: "trap_floor", x: 640, y: 380, w: 80, h: 160, params: {} }
    ]
  },
  {
    id: 14,
    chapter: 1,
    title: "Aylanuvchi arra sinovi",
    gimmick: "saw_trial",
    player_spawn: [80, 380],
    door_pos: [860, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 260, h: 160 },
      { name: "GroundMid", x: 260, y: 380, w: 280, h: 160 },
      { name: "GroundIsland", x: 580, y: 380, w: 130, h: 160 },
      { name: "GroundEnd", x: 800, y: 380, w: 160, h: 160 }
    ],
    traps: [
      { name: "CircularSaw1", type: "circular_saw", x: 200, y: 320, w: 32, h: 32, params: { orbit_radius: 40.0, orbit_speed: 2.2 } },
      { name: "CircularSaw2A", type: "circular_saw", x: 350, y: 315, w: 32, h: 32, params: { orbit_radius: 45.0, orbit_speed: 2.5 } },
      { name: "CircularSaw2B", type: "circular_saw", x: 440, y: 315, w: 32, h: 32, params: { orbit_radius: 45.0, orbit_speed: 2.5, clockwise: false } },
      { name: "SpikesMid", type: "spikes", x: 520, y: 348, w: 40, h: 32, params: {} },
      { name: "MovingSawCorridor", type: "moving_saw", x: 630, y: 364, w: 32, h: 32, params: { patrol_distance: 120.0, patrol_speed: 140.0, patrol_axis: [-1, 0] } },
      { name: "TrapFloorEnd", type: "trap_floor", x: 710, y: 380, w: 90, h: 160, params: {} },
      { name: "CircularSawEnd", type: "circular_saw", x: 755, y: 310, w: 32, h: 32, params: { orbit_radius: 32.0, orbit_speed: 3.0 } }
    ]
  },
  {
    id: 15,
    chapter: 1,
    title: "Prujina",
    gimmick: "spring_launch",
    player_spawn: [70, 420],
    door_pos: [860, 280],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "LowerStart", x: 0, y: 420, w: 200, h: 120 },
      { name: "HighTier", x: 240, y: 240, w: 280, h: 40 },
      { name: "MidLanding", x: 520, y: 400, w: 180, h: 140 },
      { name: "FinalLedge", x: 740, y: 280, w: 220, h: 260 },
      { name: "Ceiling", x: 200, y: 0, w: 340, h: 50 }
    ],
    traps: [
      { name: "Spring1", type: "spring", x: 160, y: 388, w: 32, h: 32, params: { launch_velocity: -880.0 } },
      { name: "Stalactite1", type: "falling_spike", x: 320, y: 50, w: 24, h: 32, params: { trigger_distance: 220.0, shake_duration: 0.4 } },
      { name: "Stalactite2", type: "falling_spike", x: 420, y: 50, w: 24, h: 32, params: { trigger_distance: 200.0, shake_duration: 0.5 } },
      { name: "RollingBoulderMid", type: "rolling_boulder", x: 660, y: 370, w: 56, h: 56, params: { roll_direction: -1.0, roll_speed: 360.0, trigger_distance: 220.0 } },
      { name: "Spring2", type: "spring", x: 610, y: 368, w: 32, h: 32, params: { launch_velocity: -900.0 } },
      { name: "PopUpSpikesFinal", type: "pop_up_spikes", x: 780, y: 280, w: 50, h: 32, params: { trigger_distance: 75.0, warning_time: 0.4 } }
    ]
  },
  {
    id: 16,
    chapter: 1,
    title: "Yolg‘on yo‘l",
    gimmick: "fake_path",
    player_spawn: [80, 380],
    door_pos: [870, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 240, h: 160 },
      { name: "GroundMid", x: 340, y: 380, w: 240, h: 160 },
      { name: "GroundEnd", x: 620, y: 380, w: 340, h: 160 }
    ],
    traps: [
      { name: "FakeDoorFront", type: "fake_door", x: 260, y: 380, w: 32, h: 64, params: { run_away_distance: 90.0 } },
      { name: "TrapFloorUnder", type: "trap_floor", x: 240, y: 380, w: 100, h: 160, params: {} },
      { name: "LaserCorridor", type: "laser_beam", x: 420, y: 220, w: 8, h: 160, params: { active_time: 1.4, inactive_time: 1.4 } },
      { name: "MovingSawLeft", type: "moving_saw", x: 540, y: 364, w: 32, h: 32, params: { patrol_distance: 120.0, patrol_speed: 130.0, patrol_axis: [-1, 0] } },
      { name: "MovingSawRight", type: "moving_saw", x: 660, y: 364, w: 32, h: 32, params: { patrol_distance: 120.0, patrol_speed: 130.0, patrol_axis: [1, 0] } },
      { name: "BigCrusher", type: "crusher", x: 760, y: 140, w: 80, h: 64, params: { target_y: 320.0 } }
    ]
  },
  {
    id: 17,
    chapter: 1,
    title: "Tikanli yo‘lak",
    gimmick: "spike_trail",
    player_spawn: [80, 380],
    door_pos: [860, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 460, h: 160 },
      { name: "GroundEnd", x: 660, y: 380, w: 300, h: 160 },
      { name: "Ceiling", x: 350, y: 0, w: 180, h: 60 }
    ],
    traps: [
      { name: "PopUpSpike1", type: "pop_up_spikes", x: 180, y: 380, w: 40, h: 32, params: { trigger_distance: 80.0, warning_time: 0.4 } },
      { name: "PopUpSpike2", type: "pop_up_spikes", x: 260, y: 380, w: 40, h: 32, params: { trigger_distance: 70.0, warning_time: 0.7 } },
      { name: "RollingBoulderBack", type: "rolling_boulder", x: 80, y: 350, w: 56, h: 56, params: { roll_direction: 1.0, roll_speed: 340.0, trigger_distance: 220.0, delay_before_roll: 0.5 } },
      { name: "CircularSawMid", type: "circular_saw", x: 370, y: 320, w: 32, h: 32, params: { orbit_radius: 44.0, orbit_speed: 2.6 } },
      { name: "StalactiteMid", type: "falling_spike", x: 430, y: 60, w: 24, h: 32, params: { trigger_distance: 280.0, shake_duration: 0.4 } },
      { name: "TrapFloor1", type: "trap_floor", x: 480, y: 380, w: 90, h: 160, params: {} },
      { name: "TrapFloor2", type: "trap_floor", x: 570, y: 380, w: 90, h: 160, params: {} }
    ]
  },
  {
    id: 18,
    chapter: 1,
    title: "Tuzoq kombinatsiyasi",
    gimmick: "trap_combo",
    player_spawn: [80, 380],
    door_pos: [880, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 220, h: 160 },
      { name: "GroundMid", x: 380, y: 380, w: 200, h: 160 },
      { name: "GroundEnd", x: 580, y: 380, w: 380, h: 160 }
    ],
    traps: [
      { name: "Laser1", type: "laser_beam", x: 180, y: 220, w: 8, h: 160, params: { active_time: 1.5, inactive_time: 1.3 } },
      { name: "TrapFloor1", type: "trap_floor", x: 220, y: 380, w: 80, h: 160, params: {} },
      { name: "TrapFloor2", type: "trap_floor", x: 300, y: 380, w: 80, h: 160, params: {} },
      { name: "SpikesFloor", type: "spikes", x: 410, y: 348, w: 40, h: 32, params: {} },
      { name: "CrusherMid", type: "crusher", x: 480, y: 140, w: 64, h: 64, params: { target_y: 320.0 } },
      { name: "RollingBoulderMid", type: "rolling_boulder", x: 650, y: 350, w: 56, h: 56, params: { roll_direction: -1.0, roll_speed: 340.0, trigger_distance: 220.0 } },
      { name: "CircularSawMid", type: "circular_saw", x: 710, y: 320, w: 32, h: 32, params: { orbit_radius: 40.0, orbit_speed: 2.4 } },
      { name: "FakeDoorBeforeEnd", type: "fake_door", x: 780, y: 380, w: 32, h: 64, params: { run_away_distance: 90.0 } }
    ]
  },
  {
    id: 19,
    chapter: 1,
    title: "Oxirgi sinov",
    gimmick: "penultimate_trial",
    player_spawn: [80, 380],
    door_pos: [890, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 300, h: 160 },
      { name: "GroundMid", x: 300, y: 380, w: 300, h: 160 },
      { name: "GroundEnd", x: 600, y: 380, w: 360, h: 160 },
      { name: "Ceiling", x: 240, y: 0, w: 200, h: 60 }
    ],
    traps: [
      { name: "Laser1", type: "laser_beam", x: 160, y: 220, w: 8, h: 160, params: { active_time: 1.4, inactive_time: 1.4 } },
      { name: "Laser2", type: "laser_beam", x: 230, y: 220, w: 8, h: 160, params: { active_time: 1.6, inactive_time: 1.2 } },
      { name: "MovingSawChase", type: "moving_saw", x: 80, y: 364, w: 32, h: 32, params: { patrol_distance: 180.0, patrol_speed: 160.0, patrol_axis: [1, 0] } },
      { name: "Stalactite1", type: "falling_spike", x: 310, y: 60, w: 24, h: 32, params: { trigger_distance: 280.0, shake_duration: 0.4 } },
      { name: "Stalactite2", type: "falling_spike", x: 370, y: 60, w: 24, h: 32, params: { trigger_distance: 260.0, shake_duration: 0.5 } },
      { name: "Crusher1", type: "crusher", x: 420, y: 140, w: 64, h: 64, params: { target_y: 320.0 } },
      { name: "Crusher2", type: "crusher", x: 510, y: 140, w: 64, h: 64, params: { target_y: 320.0 } },
      { name: "PopUpSpikesMid", type: "pop_up_spikes", x: 570, y: 380, w: 40, h: 32, params: { trigger_distance: 80.0, warning_time: 0.4 } },
      { name: "RollingBoulderEnd", type: "rolling_boulder", x: 780, y: 350, w: 56, h: 56, params: { roll_direction: -1.0, roll_speed: 360.0, trigger_distance: 240.0 } },
      { name: "CircularSawEnd", type: "circular_saw", x: 700, y: 320, w: 32, h: 32, params: { orbit_radius: 42.0, orbit_speed: 2.5 } },
      { name: "FakeDoorPrePortal", type: "fake_door", x: 800, y: 380, w: 32, h: 64, params: { run_away_distance: 90.0 } }
    ]
  },
  {
    id: 20,
    chapter: 1,
    title: "WRONG WAY: Final",
    gimmick: "grand_finale",
    player_spawn: [60, 380],
    door_pos: [895, 380],
    door_config: { runaway: false, runaway_offset_x: 0.0 },
    platforms: [
      { name: "Tier1Spawn", x: 0, y: 380, w: 200, h: 160 },
      { name: "Tier2Mid", x: 200, y: 380, w: 230, h: 160 },
      { name: "Tier3SpringPit", x: 430, y: 440, w: 80, h: 100 },
      { name: "Tier4SkyLedge", x: 520, y: 240, w: 180, h: 30 },
      { name: "Tier5Final", x: 700, y: 380, w: 260, h: 160 },
      { name: "Ceiling", x: 150, y: 0, w: 150, h: 60 }
    ],
    traps: [
      { name: "PopUpSpikesStart", type: "pop_up_spikes", x: 120, y: 380, w: 48, h: 32, params: { trigger_distance: 80.0, warning_time: 0.4 } },
      { name: "MovingSawChase", type: "moving_saw", x: 30, y: 364, w: 32, h: 32, params: { patrol_distance: 180.0, patrol_speed: 160.0, patrol_axis: [1, 0] } },
      { name: "Stalactite1", type: "falling_spike", x: 210, y: 60, w: 24, h: 32, params: { trigger_distance: 280.0, shake_duration: 0.4 } },
      { name: "Stalactite2", type: "falling_spike", x: 260, y: 60, w: 24, h: 32, params: { trigger_distance: 260.0, shake_duration: 0.5 } },
      { name: "Crusher1", type: "crusher", x: 240, y: 150, w: 50, h: 64, params: { target_y: 320.0 } },
      { name: "Crusher2", type: "crusher", x: 300, y: 150, w: 50, h: 64, params: { target_y: 320.0 } },
      { name: "Crusher3", type: "crusher", x: 360, y: 150, w: 50, h: 64, params: { target_y: 320.0 } },
      { name: "LaserPitGate", type: "laser_beam", x: 410, y: 220, w: 8, h: 160, params: { active_time: 1.4, inactive_time: 1.4 } },
      { name: "SpringLauncher", type: "spring", x: 450, y: 408, w: 32, h: 32, params: { launch_velocity: -950.0 } },
      { name: "CircularSawSkyA", type: "circular_saw", x: 560, y: 200, w: 32, h: 32, params: { orbit_radius: 36.0, orbit_speed: 2.8 } },
      { name: "CircularSawSkyB", type: "circular_saw", x: 640, y: 200, w: 32, h: 32, params: { orbit_radius: 36.0, orbit_speed: 2.8, clockwise: false } },
      { name: "RollingBoulderDescent", type: "rolling_boulder", x: 750, y: 350, w: 56, h: 56, params: { roll_direction: -1.0, roll_speed: 360.0, trigger_distance: 240.0 } },
      { name: "TrapFloorFinal", type: "trap_floor", x: 750, y: 380, w: 70, h: 160, params: {} },
      { name: "PopUpSpikesFinal", type: "pop_up_spikes", x: 820, y: 380, w: 40, h: 32, params: { trigger_distance: 70.0, warning_time: 0.4 } },
      { name: "FakeDoorGrand", type: "fake_door", x: 845, y: 380, w: 32, h: 64, params: { run_away_distance: 80.0 } }
    ]
  }
];

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
  console.log("Generating data/levels.json and scenes/levels/level_XX.tscn...");

  // 1. Write data/levels.json
  const jsonPath = path.join(__dirname, '..', 'data', 'levels.json');
  fs.writeFileSync(jsonPath, JSON.stringify(LEVELS, null, 2), 'utf8');
  console.log(`Saved ${LEVELS.length} levels to data/levels.json`);

  // 2. Generate each level_XX.tscn
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
    console.log(`Generated ${fileName}`);
  }

  console.log("All 20 level scenes and JSON data generated successfully!");
}

main();
