const fs = require('fs');
const path = require('path');

const levelsPath = path.join(__dirname, '..', 'data', 'levels.json');
const existingLevels = JSON.parse(fs.readFileSync(levelsPath, 'utf8'));

// Filter out any level >= 41 if running multiple times
const baseLevels = existingLevels.filter(l => l.id <= 40);

const CHAPTER_3_LEVELS = [
  // --- 41–45: Kutilmagan xavflar ---
  {
    id: 41,
    chapter: 3,
    title: "The Quiet Hall",
    gimmick: "quiet_hall",
    player_spawn: [70, 380],
    door_pos: [890, 380],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 520, h: 160 },
      { name: "GroundEnd", x: 600, y: 380, w: 360, h: 160 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 60 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "FakeDoorMid", type: "fake_door", x: 340, y: 380, w: 32, h: 64, params: { run_away_distance: 90 } },
      { name: "PopUpSpike1", type: "pop_up_spikes", x: 380, y: 380, w: 36, h: 32, params: { trigger_distance: 75, warning_time: 0.25 } },
      { name: "PopUpSpike2", type: "pop_up_spikes", x: 425, y: 380, w: 36, h: 32, params: { trigger_distance: 75, warning_time: 0.35 } },
      { name: "PopUpSpike3", type: "pop_up_spikes", x: 470, y: 380, w: 36, h: 32, params: { trigger_distance: 75, warning_time: 0.45 } },
      { name: "TrapFloorMid", type: "trap_floor", x: 520, y: 380, w: 80, h: 160, params: { shake_duration: 0.18 } },
      { name: "Stalactite1", type: "falling_spike", x: 660, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "Stalactite2", type: "falling_spike", x: 740, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "ChasingSaw", type: "moving_saw", x: 550, y: 364, w: 32, h: 32, params: { patrol_distance: 280, patrol_speed: 180, patrol_axis: [1, 0], trigger_distance: 180 } }
    ]
  },
  {
    id: 42,
    chapter: 3,
    title: "Rolling Ambush",
    gimmick: "rolling_ambush",
    player_spawn: [70, 380],
    door_pos: [890, 380],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 780, h: 160 },
      { name: "GroundEnd", x: 850, y: 380, w: 110, h: 160 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "SpikesStart", type: "spikes", x: 180, y: 348, w: 48, h: 32, params: {} },
      { name: "RollingBoulderFront", type: "rolling_boulder", x: 440, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 300, trigger_distance: 220 } },
      { name: "RollingBoulderBack", type: "rolling_boulder", x: 120, y: 350, w: 56, h: 56, params: { roll_direction: 1, roll_speed: 280, trigger_distance: 200 } },
      { name: "CircularSawMid", type: "circular_saw", x: 570, y: 325, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 2.2 } },
      { name: "RollingBoulderFast", type: "rolling_boulder", x: 740, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 460, trigger_distance: 220 } },
      { name: "TrapFloorFinish", type: "trap_floor", x: 780, y: 380, w: 70, h: 160, params: { shake_duration: 0.18 } }
    ]
  },
  {
    id: 43,
    chapter: 3,
    title: "Ceiling Has Eyes",
    gimmick: "ceiling_eyes",
    player_spawn: [70, 380],
    door_pos: [890, 380],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 320, h: 160 },
      { name: "GroundMid", x: 390, y: 380, w: 260, h: 160 },
      { name: "GroundEnd", x: 720, y: 380, w: 240, h: 160 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 60 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "Stalactite1", type: "falling_spike", x: 180, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "Stalactite2", type: "falling_spike", x: 430, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "Stalactite3", type: "falling_spike", x: 480, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "PopUpSpike1", type: "pop_up_spikes", x: 530, y: 380, w: 48, h: 32, params: { trigger_distance: 75, warning_time: 0.35 } },
      { name: "Stalactite4", type: "falling_spike", x: 580, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "PopUpSpike2", type: "pop_up_spikes", x: 760, y: 380, w: 48, h: 32, params: { trigger_distance: 75, warning_time: 0.35 } },
      { name: "CrusherFinal", type: "crusher", x: 800, y: 140, w: 68, h: 64, params: { target_y: 320 } }
    ]
  },
  {
    id: 44,
    chapter: 3,
    title: "The Saw Trap",
    gimmick: "saw_trap",
    player_spawn: [70, 380],
    door_pos: [890, 380],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "BridgeStart", x: 0, y: 380, w: 380, h: 160 },
      { name: "BridgeEnd", x: 460, y: 380, w: 500, h: 160 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 60 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "MovingSawMid", type: "moving_saw", x: 280, y: 364, w: 32, h: 32, params: { patrol_distance: 75, patrol_speed: 140, patrol_axis: [1, 0] } },
      { name: "BridgeTrapFloor", type: "trap_floor", x: 380, y: 380, w: 80, h: 160, params: { shake_duration: 0.18 } },
      { name: "ChasingSawBehind", type: "moving_saw", x: 180, y: 364, w: 32, h: 32, params: { patrol_distance: 280, patrol_speed: 175, patrol_axis: [1, 0], trigger_distance: 220 } },
      { name: "SpikesAhead", type: "spikes", x: 530, y: 348, w: 48, h: 32, params: {} },
      { name: "StalactiteAboveSpikes", type: "falling_spike", x: 554, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "CircularSaw1", type: "circular_saw", x: 700, y: 325, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 2.2 } },
      { name: "CircularSaw2", type: "circular_saw", x: 770, y: 325, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: -2.2 } }
    ]
  },
  {
    id: 45,
    chapter: 3,
    title: "Not Every Gap Is Safe",
    gimmick: "gap_hazards",
    player_spawn: [70, 380],
    door_pos: [895, 380],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "Platform1", x: 0, y: 380, w: 180, h: 160 },
      { name: "Platform3", x: 290, y: 380, w: 120, h: 160 },
      { name: "Platform4", x: 470, y: 380, w: 140, h: 160 },
      { name: "PlatformSpring", x: 640, y: 380, w: 60, h: 160 },
      { name: "PlatformSaw", x: 730, y: 380, w: 90, h: 160 },
      { name: "GroundDoor", x: 890, y: 380, w: 70, h: 160 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 60 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "TrapFloor2", type: "trap_floor", x: 190, y: 380, w: 80, h: 160, params: { shake_duration: 0.18 } },
      { name: "SpikesPlatform3", type: "spikes", x: 326, y: 348, w: 48, h: 32, params: {} },
      { name: "StalactitePlatform4", type: "falling_spike", x: 535, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "SpringGap", type: "spring", x: 650, y: 380, w: 40, h: 16, params: { bounce_force: 580 } },
      { name: "CircularSawPlatform", type: "circular_saw", x: 775, y: 330, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 2.4 } },
      { name: "TrapFloorFinal", type: "trap_floor", x: 820, y: 380, w: 70, h: 160, params: { shake_duration: 0.18 } }
    ]
  },

  // --- 46–50: Aldov va murakkab puzzle ---
  {
    id: 46,
    chapter: 3,
    title: "The Door Puzzle",
    gimmick: "door_puzzle",
    player_spawn: [70, 380],
    door_pos: [890, 380],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 320, h: 160 },
      { name: "GroundMid", x: 400, y: 380, w: 220, h: 160 },
      { name: "GroundDoor", x: 680, y: 380, w: 280, h: 160 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 60 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "FakeDoor1", type: "fake_door", x: 200, y: 380, w: 32, h: 64, params: { run_away_distance: 85 } },
      { name: "PopUpSpikesDoor1", type: "pop_up_spikes", x: 200, y: 380, w: 48, h: 32, params: { trigger_distance: 85, warning_time: 0.28 } },
      { name: "TrapFloorDoor2", type: "trap_floor", x: 320, y: 380, w: 80, h: 160, params: { shake_duration: 0.18 } },
      { name: "FakeDoor2", type: "fake_door", x: 330, y: 380, w: 32, h: 64, params: { run_away_distance: 85 } },
      { name: "FakeDoor3", type: "fake_door", x: 480, y: 380, w: 32, h: 64, params: { run_away_distance: 85 } },
      { name: "StalactiteDoor3", type: "falling_spike", x: 480, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "LaserRealHall", type: "laser_beam", x: 650, y: 220, w: 8, h: 160, params: { active_time: 1.3, inactive_time: 1.3 } },
      { name: "CircularSawRealHall", type: "circular_saw", x: 770, y: 330, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 2.2 } }
    ]
  },
  {
    id: 47,
    chapter: 3,
    title: "Double Crusher",
    gimmick: "double_crusher",
    player_spawn: [70, 380],
    door_pos: [890, 380],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundFull", x: 0, y: 380, w: 960, h: 160 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 60 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "Crusher1", type: "crusher", x: 200, y: 140, w: 68, h: 64, params: { target_y: 320, trigger_distance: 70, wait_at_bottom: 0.6 } },
      { name: "Crusher2", type: "crusher", x: 340, y: 140, w: 68, h: 64, params: { target_y: 320, trigger_distance: 70, wait_at_bottom: 0.6 } },
      { name: "Stalactite1", type: "falling_spike", x: 470, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "Stalactite2", type: "falling_spike", x: 530, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "Stalactite3", type: "falling_spike", x: 590, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "SpikesUnderCrusher3", type: "spikes", x: 740, y: 348, w: 64, h: 32, params: {} },
      { name: "Crusher3", type: "crusher", x: 740, y: 140, w: 68, h: 64, params: { target_y: 320 } }
    ]
  },
  {
    id: 48,
    chapter: 3,
    title: "The Long Laser",
    gimmick: "long_laser",
    player_spawn: [70, 380],
    door_pos: [890, 380],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundFull", x: 0, y: 380, w: 960, h: 160 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "LaserFast", type: "laser_beam", x: 180, y: 220, w: 8, h: 160, params: { active_time: 0.8, inactive_time: 0.8 } },
      { name: "LaserLong", type: "laser_beam", x: 290, y: 220, w: 8, h: 160, params: { active_time: 2.4, inactive_time: 1.0 } },
      { name: "LaserTrap3", type: "laser_beam", x: 390, y: 220, w: 8, h: 160, params: { active_time: 1.4, inactive_time: 1.2 } },
      { name: "PopUpSpikesPostLaser", type: "pop_up_spikes", x: 480, y: 380, w: 56, h: 32, params: { trigger_distance: 75, warning_time: 0.35 } },
      { name: "RollingBoulderMid", type: "rolling_boulder", x: 620, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 340, trigger_distance: 220 } },
      { name: "LaserAfterBoulder", type: "laser_beam", x: 700, y: 220, w: 8, h: 160, params: { active_time: 1.2, inactive_time: 1.2 } },
      { name: "LaserDoorQuick", type: "laser_beam", x: 810, y: 220, w: 8, h: 160, params: { active_time: 1.8, inactive_time: 0.7 } }
    ]
  },
  {
    id: 49,
    chapter: 3,
    title: "The Underground Route",
    gimmick: "underground_route",
    player_spawn: [70, 230],
    door_pos: [890, 230],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "UpperStart", x: 0, y: 230, w: 160, h: 30 },
      { name: "LowerGround", x: 180, y: 380, w: 540, h: 160 },
      { name: "UpperEnd", x: 750, y: 230, w: 210, h: 30 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 50 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "TrapFloorDrop", type: "trap_floor", x: 160, y: 230, w: 80, h: 30, params: { shake_duration: 0.18 } },
      { name: "CircularSaw1", type: "circular_saw", x: 280, y: 330, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 2.2 } },
      { name: "CircularSaw2", type: "circular_saw", x: 370, y: 330, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: -2.2 } },
      { name: "StalactiteUnder1", type: "falling_spike", x: 440, y: 50, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "StalactiteUnder2", type: "falling_spike", x: 500, y: 50, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "RollingBoulderLower", type: "rolling_boulder", x: 620, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 340, trigger_distance: 220 } },
      { name: "SpringToUpper", type: "spring", x: 670, y: 380, w: 40, h: 16, params: { bounce_force: 620 } },
      { name: "FakeDoorUpper", type: "fake_door", x: 810, y: 230, w: 32, h: 64, params: { run_away_distance: 85 } }
    ]
  },
  {
    id: 50,
    chapter: 3,
    title: "Halfway to Hell",
    gimmick: "halfway_hell",
    player_spawn: [60, 380],
    door_pos: [900, 230],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundLower", x: 0, y: 380, w: 560, h: 160 },
      { name: "GroundSpring", x: 640, y: 380, w: 70, h: 160 },
      { name: "UpperBridge", x: 680, y: 230, w: 280, h: 30 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 50 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "PopUp1", type: "pop_up_spikes", x: 130, y: 380, w: 32, h: 32, params: { trigger_distance: 70, warning_time: 0.25 } },
      { name: "PopUp2", type: "pop_up_spikes", x: 165, y: 380, w: 32, h: 32, params: { trigger_distance: 70, warning_time: 0.3 } },
      { name: "PopUp3", type: "pop_up_spikes", x: 200, y: 380, w: 32, h: 32, params: { trigger_distance: 70, warning_time: 0.35 } },
      { name: "PopUp4", type: "pop_up_spikes", x: 235, y: 380, w: 32, h: 32, params: { trigger_distance: 70, warning_time: 0.4 } },
      { name: "PopUp5", type: "pop_up_spikes", x: 270, y: 380, w: 32, h: 32, params: { trigger_distance: 70, warning_time: 0.45 } },
      { name: "BoulderFront", type: "rolling_boulder", x: 420, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 320, trigger_distance: 220 } },
      { name: "BoulderBack", type: "rolling_boulder", x: 100, y: 350, w: 56, h: 56, params: { roll_direction: 1, roll_speed: 280, trigger_distance: 200 } },
      { name: "CrusherMid", type: "crusher", x: 470, y: 140, w: 68, h: 64, params: { target_y: 320 } },
      { name: "CircularSawMid", type: "circular_saw", x: 530, y: 330, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 2.2 } },
      { name: "TrapFloorMid", type: "trap_floor", x: 560, y: 380, w: 80, h: 160, params: { shake_duration: 0.18 } },
      { name: "SpringToSky", type: "spring", x: 655, y: 380, w: 40, h: 16, params: { bounce_force: 620 } },
      { name: "StalactiteSky1", type: "falling_spike", x: 710, y: 50, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "StalactiteSky2", type: "falling_spike", x: 750, y: 50, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "StalactiteSky3", type: "falling_spike", x: 790, y: 50, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "LaserHall", type: "laser_beam", x: 810, y: 80, w: 8, h: 150, params: { active_time: 1.2, inactive_time: 1.2 } },
      { name: "FakeDoorSky", type: "fake_door", x: 840, y: 230, w: 32, h: 64, params: { run_away_distance: 85 } },
      { name: "SpikesFinal", type: "spikes", x: 865, y: 198, w: 28, h: 32, params: {} }
    ]
  },

  // --- 51–55: Expert Zone ---
  {
    id: 51,
    chapter: 3,
    title: "One Chance",
    gimmick: "one_chance",
    player_spawn: [70, 380],
    door_pos: [890, 380],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 180, h: 160 },
      { name: "GroundPostTraps", x: 440, y: 380, w: 520, h: 160 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 60 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "TrapFloor1", type: "trap_floor", x: 180, y: 380, w: 80, h: 160, params: { shake_duration: 0.18 } },
      { name: "TrapFloor2", type: "trap_floor", x: 260, y: 380, w: 80, h: 160, params: { shake_duration: 0.18 } },
      { name: "TrapFloor3", type: "trap_floor", x: 340, y: 380, w: 100, h: 160, params: { shake_duration: 0.18 } },
      { name: "ChasingSawBehind", type: "moving_saw", x: 120, y: 364, w: 32, h: 32, params: { patrol_distance: 360, patrol_speed: 180, patrol_axis: [1, 0], trigger_distance: 200 } },
      { name: "LaserAhead", type: "laser_beam", x: 540, y: 220, w: 8, h: 160, params: { active_time: 1.2, inactive_time: 1.2 } },
      { name: "Stalactite1", type: "falling_spike", x: 640, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "Stalactite2", type: "falling_spike", x: 710, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "RollingBoulderDoor", type: "rolling_boulder", x: 800, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 340, trigger_distance: 220 } }
    ]
  },
  {
    id: 52,
    chapter: 3,
    title: "The Upper Trap",
    gimmick: "upper_trap",
    player_spawn: [70, 380],
    door_pos: [895, 230],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 230, h: 160 },
      { name: "UpperLedge1", x: 230, y: 230, w: 240, h: 30 },
      { name: "GroundLowerMid", x: 440, y: 380, w: 280, h: 160 },
      { name: "UpperExit", x: 750, y: 230, w: 210, h: 30 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 50 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "Spring1", type: "spring", x: 175, y: 380, w: 40, h: 16, params: { bounce_force: 600 } },
      { name: "CircularSawUpper1", type: "circular_saw", x: 290, y: 190, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 2.2 } },
      { name: "CircularSawUpper2", type: "circular_saw", x: 370, y: 190, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: -2.2 } },
      { name: "StalactiteUpper", type: "falling_spike", x: 420, y: 50, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "TrapFloorUpperDrop", type: "trap_floor", x: 470, y: 230, w: 80, h: 30, params: { shake_duration: 0.18 } },
      { name: "BoulderLowerWaiting", type: "rolling_boulder", x: 610, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 340, trigger_distance: 220 } },
      { name: "Spring2", type: "spring", x: 680, y: 380, w: 40, h: 16, params: { bounce_force: 600 } },
      { name: "LaserExitHall", type: "laser_beam", x: 810, y: 80, w: 8, h: 150, params: { active_time: 1.2, inactive_time: 1.2 } }
    ]
  },
  {
    id: 53,
    chapter: 3,
    title: "The Rolling Corridor",
    gimmick: "rolling_corridor",
    player_spawn: [70, 380],
    door_pos: [890, 380],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundFull", x: 0, y: 380, w: 960, h: 160 },
      { name: "UpperDropLedge", x: 440, y: 240, w: 100, h: 30 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 60 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "BoulderFront1", type: "rolling_boulder", x: 330, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 300, trigger_distance: 220 } },
      { name: "BoulderBack2", type: "rolling_boulder", x: 120, y: 350, w: 56, h: 56, params: { roll_direction: 1, roll_speed: 280, trigger_distance: 200 } },
      { name: "BoulderDropLedge", type: "rolling_boulder", x: 470, y: 210, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 320, trigger_distance: 200 } },
      { name: "SpikesBetween", type: "spikes", x: 410, y: 348, w: 48, h: 32, params: {} },
      { name: "CircularSawMid", type: "circular_saw", x: 570, y: 330, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 2.2 } },
      { name: "StalactiteMid", type: "falling_spike", x: 660, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "OpposingBoulder1", type: "rolling_boulder", x: 740, y: 350, w: 56, h: 56, params: { roll_direction: 1, roll_speed: 320, trigger_distance: 220 } },
      { name: "OpposingBoulder2", type: "rolling_boulder", x: 860, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 320, trigger_distance: 220 } }
    ]
  },
  {
    id: 54,
    chapter: 3,
    title: "Trapped Between",
    gimmick: "trapped_between",
    player_spawn: [110, 380],
    door_pos: [890, 380],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundFull", x: 0, y: 380, w: 960, h: 160 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 60 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "SawFromLeft", type: "moving_saw", x: 30, y: 364, w: 32, h: 32, params: { patrol_distance: 220, patrol_speed: 140, patrol_axis: [1, 0], trigger_distance: 120 } },
      { name: "CrusherFromRight", type: "crusher", x: 240, y: 140, w: 68, h: 64, params: { target_y: 320, trigger_distance: 70 } },
      { name: "BoulderBehind", type: "rolling_boulder", x: 180, y: 350, w: 56, h: 56, params: { roll_direction: 1, roll_speed: 290, trigger_distance: 190 } },
      { name: "LaserAhead", type: "laser_beam", x: 450, y: 220, w: 8, h: 160, params: { active_time: 1.2, inactive_time: 1.2 } },
      { name: "PopUpSpikesLaser", type: "pop_up_spikes", x: 510, y: 380, w: 48, h: 32, params: { trigger_distance: 75, warning_time: 0.35 } },
      { name: "StalactiteJump", type: "falling_spike", x: 580, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "CircularSawFinal", type: "circular_saw", x: 780, y: 330, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 2.4 } }
    ]
  },
  {
    id: 55,
    chapter: 3,
    title: "The Hidden Exit",
    gimmick: "hidden_exit",
    player_spawn: [70, 380],
    door_pos: [890, 380],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 360, h: 160 },
      { name: "GroundMid", x: 440, y: 380, w: 230, h: 160 },
      { name: "GroundEnd", x: 730, y: 380, w: 230, h: 160 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 60 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "FakeDoor1", type: "fake_door", x: 220, y: 380, w: 32, h: 64, params: { run_away_distance: 85 } },
      { name: "LaserBehindFake1", type: "laser_beam", x: 290, y: 220, w: 8, h: 160, params: { active_time: 1.3, inactive_time: 1.3 } },
      { name: "FakeDoor2", type: "fake_door", x: 370, y: 380, w: 32, h: 64, params: { run_away_distance: 85 } },
      { name: "TrapFloor2", type: "trap_floor", x: 360, y: 380, w: 80, h: 160, params: { shake_duration: 0.18 } },
      { name: "FakeDoor3", type: "fake_door", x: 520, y: 380, w: 32, h: 64, params: { run_away_distance: 85 } },
      { name: "CircularSawRoom", type: "circular_saw", x: 580, y: 330, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 2.2 } },
      { name: "FakeDoor4", type: "fake_door", x: 710, y: 380, w: 32, h: 64, params: { run_away_distance: 85 } },
      { name: "PopUpSpikesFinal", type: "pop_up_spikes", x: 760, y: 380, w: 48, h: 32, params: { trigger_distance: 75, warning_time: 0.35 } },
      { name: "StalactiteFinal", type: "falling_spike", x: 820, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } }
    ]
  },

  // --- 56–60: Final Expert Challenge ---
  {
    id: 56,
    chapter: 3,
    title: "No Escape",
    gimmick: "no_escape",
    player_spawn: [70, 380],
    door_pos: [895, 380],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 270, h: 160 },
      { name: "GroundLowerMid", x: 350, y: 380, w: 250, h: 160 },
      { name: "GroundEnd", x: 670, y: 380, w: 290, h: 160 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 60 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "SpikesStart", type: "spikes", x: 180, y: 348, w: 48, h: 32, params: {} },
      { name: "FastChasingSaw", type: "moving_saw", x: 30, y: 364, w: 32, h: 32, params: { patrol_distance: 260, patrol_speed: 210, patrol_axis: [1, 0], trigger_distance: 160 } },
      { name: "TrapFloorMid", type: "trap_floor", x: 270, y: 380, w: 80, h: 160, params: { shake_duration: 0.18 } },
      { name: "StalactiteDrop", type: "falling_spike", x: 310, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "RollingBoulderPit", type: "rolling_boulder", x: 440, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 340, trigger_distance: 220 } },
      { name: "LaserHall", type: "laser_beam", x: 560, y: 220, w: 8, h: 160, params: { active_time: 1.2, inactive_time: 1.2 } },
      { name: "CircularSaw1", type: "circular_saw", x: 700, y: 325, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 2.2 } },
      { name: "CircularSaw2", type: "circular_saw", x: 760, y: 325, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: -2.2 } },
      { name: "CrusherFinish", type: "crusher", x: 820, y: 140, w: 68, h: 64, params: { target_y: 320 } }
    ]
  },
  {
    id: 57,
    chapter: 3,
    title: "The Trap Factory",
    gimmick: "trap_factory",
    player_spawn: [70, 380],
    door_pos: [895, 380],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 740, h: 160 },
      { name: "GroundDoor", x: 820, y: 380, w: 140, h: 160 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 60 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "Crusher1", type: "crusher", x: 180, y: 140, w: 68, h: 64, params: { target_y: 320, trigger_distance: 64 } },
      { name: "Crusher2", type: "crusher", x: 260, y: 140, w: 68, h: 64, params: { target_y: 320, trigger_distance: 64 } },
      { name: "Stalactite1", type: "falling_spike", x: 350, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "Stalactite2", type: "falling_spike", x: 400, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "PopUpSpikes1", type: "pop_up_spikes", x: 470, y: 380, w: 48, h: 32, params: { trigger_distance: 75, warning_time: 0.3 } },
      { name: "PopUpSpikes2", type: "pop_up_spikes", x: 520, y: 380, w: 48, h: 32, params: { trigger_distance: 75, warning_time: 0.35 } },
      { name: "CircularSaw1", type: "circular_saw", x: 600, y: 330, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 2.2 } },
      { name: "CircularSaw2", type: "circular_saw", x: 660, y: 330, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: -2.2 } },
      { name: "ChasingBoulder", type: "rolling_boulder", x: 560, y: 350, w: 56, h: 56, params: { roll_direction: 1, roll_speed: 310, trigger_distance: 200 } },
      { name: "LaserCombo", type: "laser_beam", x: 730, y: 220, w: 8, h: 160, params: { active_time: 1.2, inactive_time: 1.2 } },
      { name: "TrapFloorCombo", type: "trap_floor", x: 740, y: 380, w: 80, h: 160, params: { shake_duration: 0.18 } }
    ]
  },
  {
    id: 58,
    chapter: 3,
    title: "The Wrong Jump",
    gimmick: "wrong_jump",
    player_spawn: [70, 380],
    door_pos: [895, 230],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 200, h: 160 },
      { name: "UpperLedge1", x: 200, y: 220, w: 230, h: 30 },
      { name: "LowerPath", x: 430, y: 380, w: 400, h: 160 },
      { name: "UpperFinish", x: 840, y: 230, w: 120, h: 30 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 50 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "SpringStart", type: "spring", x: 140, y: 380, w: 40, h: 16, params: { bounce_force: 610 } },
      { name: "SpikesUpper1", type: "spikes", x: 230, y: 188, w: 48, h: 32, params: {} },
      { name: "StalactiteUpper1", type: "falling_spike", x: 310, y: 50, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "StalactiteUpper2", type: "falling_spike", x: 360, y: 50, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "LaserLower", type: "laser_beam", x: 500, y: 220, w: 8, h: 160, params: { active_time: 1.2, inactive_time: 1.2 } },
      { name: "BoulderIncoming", type: "rolling_boulder", x: 630, y: 350, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 340, trigger_distance: 220 } },
      { name: "CircularSawBlock", type: "circular_saw", x: 720, y: 330, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 2.2 } },
      { name: "SpringFinish", type: "spring", x: 790, y: 380, w: 40, h: 16, params: { bounce_force: 610 } }
    ]
  },
  {
    id: 59,
    chapter: 3,
    title: "The Last Mistakes",
    gimmick: "last_mistakes",
    player_spawn: [70, 380],
    door_pos: [905, 380],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 380, w: 160, h: 160 },
      { name: "PlatformSpikesMid", x: 220, y: 380, w: 80, h: 160 },
      { name: "GroundMidFinal", x: 370, y: 380, w: 590, h: 160 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 60 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      { name: "TrapFloor1", type: "trap_floor", x: 160, y: 380, w: 60, h: 160, params: { shake_duration: 0.18 } },
      { name: "SpikesMid1", type: "spikes", x: 240, y: 348, w: 48, h: 32, params: {} },
      { name: "TrapFloor2", type: "trap_floor", x: 300, y: 380, w: 70, h: 160, params: { shake_duration: 0.18 } },
      { name: "RearBoulder", type: "rolling_boulder", x: 120, y: 350, w: 56, h: 56, params: { roll_direction: 1, roll_speed: 290, trigger_distance: 200 } },
      { name: "FrontCrusher", type: "crusher", x: 420, y: 140, w: 68, h: 64, params: { target_y: 320 } },
      { name: "StalactiteBehindCrusher", type: "falling_spike", x: 480, y: 60, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "Laser1", type: "laser_beam", x: 560, y: 220, w: 8, h: 160, params: { active_time: 1.1, inactive_time: 1.3 } },
      { name: "Laser2", type: "laser_beam", x: 630, y: 220, w: 8, h: 160, params: { active_time: 1.3, inactive_time: 1.1 } },
      { name: "TwinSaw1", type: "moving_saw", x: 700, y: 364, w: 32, h: 32, params: { patrol_distance: 60, patrol_speed: 150, patrol_axis: [1, 0] } },
      { name: "TwinSaw2", type: "moving_saw", x: 750, y: 364, w: 32, h: 32, params: { patrol_distance: 60, patrol_speed: 150, patrol_axis: [-1, 0] } },
      { name: "FakeDoorTrap", type: "fake_door", x: 800, y: 380, w: 32, h: 64, params: { run_away_distance: 85 } },
      { name: "PopUpSpikesFinal", type: "pop_up_spikes", x: 845, y: 380, w: 48, h: 32, params: { trigger_distance: 75, warning_time: 0.3 } }
    ]
  },
  {
    id: 60,
    chapter: 3,
    title: "THE FINAL NIGHTMARE",
    gimmick: "final_nightmare",
    player_spawn: [60, 420],
    door_pos: [890, 420],
    door_config: { runaway: false, runaway_offset_x: 0 },
    platforms: [
      { name: "GroundStart", x: 0, y: 420, w: 210, h: 120 },
      { name: "GroundMain", x: 280, y: 420, w: 680, h: 120 },
      { name: "UpperLaserLedge", x: 550, y: 210, w: 330, h: 30 },
      { name: "MidRunway", x: 140, y: 310, w: 350, h: 30 },
      { name: "SkyCrusherLedge", x: 220, y: 130, w: 140, h: 30 },
      { name: "Ceiling", x: 0, y: 0, w: 960, h: 50 },
      { name: "WallLeft", x: 0, y: 0, w: 32, h: 540 },
      { name: "WallRight", x: 928, y: 0, w: 32, h: 540 }
    ],
    traps: [
      // 1-qism — The Beginning
      { name: "Spikes1", type: "spikes", x: 130, y: 388, w: 48, h: 32, params: {} },
      { name: "TrapFloor1", type: "trap_floor", x: 210, y: 420, w: 70, h: 120, params: { shake_duration: 0.18 } },
      { name: "ChasingSaw1", type: "moving_saw", x: 30, y: 404, w: 32, h: 32, params: { patrol_distance: 220, patrol_speed: 160, patrol_axis: [1, 0], trigger_distance: 120 } },
      { name: "PopUp1", type: "pop_up_spikes", x: 290, y: 420, w: 48, h: 32, params: { trigger_distance: 75, warning_time: 0.3 } },
      // 2-qism — The Ceiling
      { name: "Stalactite1", type: "falling_spike", x: 350, y: 50, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "Stalactite2", type: "falling_spike", x: 400, y: 50, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "Stalactite3", type: "falling_spike", x: 450, y: 50, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "Crusher1", type: "crusher", x: 490, y: 140, w: 68, h: 64, params: { target_y: 360, wait_at_bottom: 0.6 } },
      { name: "Crusher2", type: "crusher", x: 580, y: 140, w: 68, h: 64, params: { target_y: 360, wait_at_bottom: 0.6 } },
      // 3-qism — The Rolling Death
      { name: "FrontBoulder", type: "rolling_boulder", x: 780, y: 390, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 320, trigger_distance: 220 } },
      { name: "RearBoulder", type: "rolling_boulder", x: 580, y: 390, w: 56, h: 56, params: { roll_direction: 1, roll_speed: 280, trigger_distance: 180 } },
      { name: "CircularSawPart3", type: "circular_saw", x: 700, y: 370, w: 32, h: 32, params: { orbit_radius: 36, orbit_speed: 2.2 } },
      { name: "SpringPart3", type: "spring", x: 830, y: 420, w: 40, h: 16, params: { bounce_force: 660, launch_velocity: -920 } },
      // 4-qism — The Laser Hall
      { name: "Laser1", type: "laser_beam", x: 760, y: 70, w: 8, h: 140, params: { active_time: 1.1, inactive_time: 1.2 } },
      { name: "Laser2", type: "laser_beam", x: 700, y: 70, w: 8, h: 140, params: { active_time: 1.3, inactive_time: 1.0 } },
      { name: "Laser3", type: "laser_beam", x: 640, y: 70, w: 8, h: 140, params: { active_time: 1.0, inactive_time: 1.3 } },
      { name: "StalactiteLaser", type: "falling_spike", x: 590, y: 50, w: 24, h: 32, params: { trigger_distance: 240, shake_duration: 0.35 } },
      { name: "TrapFloorUpperLedge", type: "trap_floor", x: 490, y: 210, w: 60, h: 30, params: { shake_duration: 0.18 } },
      // 5-qism — The Wrong Exit
      { name: "FakeDoorGrand", type: "fake_door", x: 380, y: 310, w: 32, h: 64, params: { run_away_distance: 85 } },
      { name: "CircularSaw5A", type: "circular_saw", x: 340, y: 260, w: 32, h: 32, params: { orbit_radius: 32, orbit_speed: 2.2 } },
      { name: "CircularSaw5B", type: "circular_saw", x: 280, y: 260, w: 32, h: 32, params: { orbit_radius: 32, orbit_speed: -2.2 } },
      { name: "FastSawChase5", type: "moving_saw", x: 440, y: 294, w: 32, h: 32, params: { patrol_distance: 250, patrol_speed: 200, patrol_axis: [-1, 0], trigger_distance: 180 } },
      { name: "PopUpSpikes5A", type: "pop_up_spikes", x: 250, y: 310, w: 32, h: 32, params: { trigger_distance: 75, warning_time: 0.25 } },
      { name: "PopUpSpikes5B", type: "pop_up_spikes", x: 215, y: 310, w: 32, h: 32, params: { trigger_distance: 75, warning_time: 0.3 } },
      { name: "PopUpSpikes5C", type: "pop_up_spikes", x: 180, y: 310, w: 32, h: 32, params: { trigger_distance: 75, warning_time: 0.35 } },
      // 6-qism — Final Escape
      { name: "FinalSpring", type: "spring", x: 150, y: 310, w: 40, h: 16, params: { bounce_force: 660, launch_velocity: -920 } },
      { name: "GiantCrusher", type: "crusher", x: 280, y: 50, w: 68, h: 64, params: { target_y: 130, wait_at_bottom: 0.5 } },
      { name: "FinalRollingBoulder", type: "rolling_boulder", x: 720, y: 390, w: 56, h: 56, params: { roll_direction: -1, roll_speed: 340, trigger_distance: 240 } }
    ]
  }
];

const allLevels = baseLevels.concat(CHAPTER_3_LEVELS);
fs.writeFileSync(levelsPath, JSON.stringify(allLevels, null, 2), 'utf8');

console.log(`Successfully built all 60 levels! Total: ${allLevels.length} levels.`);
