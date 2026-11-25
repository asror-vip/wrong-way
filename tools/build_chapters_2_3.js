// Deterministic builder & static validator for Chapter 2 (Levels 21-40, Frost Peak)
// and Chapter 3 (Levels 41-60, Emerald Woods).
// Preserves Chapter 1 (Levels 1-20) untouched and guarantees 100% parity between
// scenes/levels/level_21.tscn..level_60.tscn and data/levels.json entries 21..60.

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const LEVELS_JSON_PATH = path.join(ROOT, "data", "levels.json");
const SCENES_DIR = path.join(ROOT, "scenes", "levels");

const TRAP_SCENES = {
  spikes: "res://scenes/traps/spikes.tscn",
  pop_up_spikes: "res://scenes/traps/pop_up_spikes.tscn",
  jumping_spikes: "res://scenes/traps/jumping_spikes.tscn",
  trap_floor: "res://scenes/traps/trap_floor.tscn",
  crusher: "res://scenes/traps/crusher.tscn",
  falling_ceiling: "res://scenes/traps/falling_ceiling.tscn",
  falling_spike: "res://scenes/traps/falling_spike.tscn",
  moving_saw: "res://scenes/traps/moving_saw.tscn",
  circular_saw: "res://scenes/traps/circular_saw.tscn",
  rolling_boulder: "res://scenes/traps/rolling_boulder.tscn",
  dodging_platform: "res://scenes/traps/dodging_platform.tscn",
  fake_door: "res://scenes/traps/fake_door.tscn",
  spring: "res://scenes/traps/spring.tscn",
};

const FORBIDDEN_TRAPS = new Set(["laser_beam", "crumbling_platform"]);

function fmtVal(v) {
  if (typeof v === "boolean") return v ? "true" : "false";
  if (typeof v === "number") return Number.isInteger(v) ? `${v}.0` : `${v}`;
  if (Array.isArray(v) && v.length === 2) return `Vector2(${v[0]}, ${v[1]})`;
  if (typeof v === "string") return `"${v}"`;
  return String(v);
}

// Helpers for compact, readable, exact level definitions
const plat = (name, x, y, w, h, extra = {}) => ({ name, x, y, w, h, ...extra });
const fwall = (name, x, y, w, h, fade = false) => ({
  name, x, y, w, h, subtle_crack: false, fade_when_inside: fade,
});
const trap = (type, name, x, y, w, h, params = {}) => ({ type, name, x, y, w, h, params });

// =========================================================================
// CHAPTER 2: FROST PEAK / SNOW (Levels 21-40)
// =========================================================================
const CHAPTER_2 = [
  // L21: Stepped L->R climb; Frost Breath freezes in mid-air; camouflaged Spring behind spawn skips first gauntlet
  {
    id: 21, chapter: 2, title: "Muzlagan Nafas", gimmick: "frost_breath_echo",
    ceiling_h: 60, player_spawn: [145, 390], door_pos: [870, 290],
    platforms: [
      plat("SnowStart", 0, 390, 340, 150),
      plat("MidTerrace", 410, 340, 220, 200),
      plat("HighSummit", 690, 290, 270, 250),
    ],
    traps: [
      trap("spring", "SpringShortcut", 46, 390, 28, 24, { launch_velocity: -780, trigger_y_min: 330, trigger_y_max: 420 }),
      trap("spikes", "SpikesStart", 230, 358, 48, 32, { slide_offset_x: 42, trigger_distance: 85, trigger_on_jump: true }),
      trap("trap_floor", "TrapGap1", 340, 390, 70, 150, { shake_duration: 0.14, trigger_y_min: 325, trigger_y_max: 425 }),
      trap("pop_up_spikes", "PopUpMid", 495, 340, 44, 32, { warning_time: 0.18, trigger_y_min: 270, trigger_y_max: 375 }),
      trap("falling_spike", "IcicleEnd", 755, 60, 24, 32, { trigger_distance: 280, trigger_y_min: 180, trigger_y_max: 330 }),
      trap("moving_saw", "SawEnd", 825, 274, 32, 32, { radius: 16, patrol_distance: 95, patrol_speed: 130, patrol_axis: [-1, 0], trigger_y_min: 200, trigger_y_max: 330 }),
    ],
    paranormal: { event_type: "frost_breath_echo", trigger_x: 410, trigger_y: 340 },
  },

  // L22: R->L terraced descent; Hanging crystal chimes warn & resonate; high aerial leap-dash shortcut skips mid & low center traps
  {
    id: 22, chapter: 2, title: "Muz Qo'ng'iroqlari", gimmick: "icicle_chime_omen",
    ceiling_h: 56, player_spawn: [855, 225], door_pos: [85, 410],
    platforms: [
      plat("HighStart", 670, 225, 258, 26),
      plat("MidLedge", 355, 315, 245, 24),
      plat("LowFloor", 32, 410, 896, 130),
    ],
    traps: [
      trap("moving_saw", "SawMid", 550, 299, 32, 32, { radius: 16, patrol_distance: 150, patrol_speed: 135, patrol_axis: [-1, 0], trigger_y_min: 230, trigger_y_max: 340 }),
      trap("falling_spike", "IcicleMid", 455, 56, 24, 32, { trigger_distance: 310, pass_through_platforms: false, trigger_y_min: 230, trigger_y_max: 335 }),
      trap("pop_up_spikes", "PopUpLow", 470, 410, 48, 32, { trigger_y_min: 350, trigger_y_max: 455 }),
      trap("rolling_boulder", "SnowballLow", 680, 382, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 255, trigger_distance: 210, trigger_y_min: 350, trigger_y_max: 455 }),
      trap("falling_spike", "IcicleDoor", 230, 56, 24, 32, { trigger_distance: 380, pass_through_platforms: true, stop_min_y: 365, trigger_y_min: 340, trigger_y_max: 455 }),
    ],
    paranormal: { event_type: "icicle_chime_omen", trigger_x: 620, trigger_y: 225 },
  },

  // L23: Black Ice upper gauntlet (slippery ice_friction=0.91); hidden TrapFloor far behind spawn drops to grippy ice-free lower cave + ExitStep1 up through one-way BlackIceExitCap
  {
    id: 23, chapter: 2, title: "Qora Muz", gimmick: "black_ice_glide",
    ceiling_h: 48, player_spawn: [175, 240], door_pos: [865, 240],
    platforms: [
      plat("BlackIceMain", 96, 240, 724, 26),
      plat("BlackIceExitCap", 820, 240, 108, 26, { one_way: true }),
      plat("CaveFloor", 32, 415, 896, 125),
      plat("ExitStep1", 815, 330, 96, 16, { one_way: true }),
    ],
    traps: [
      trap("trap_floor", "TrapBackChute", 32, 240, 64, 26, { shake_duration: 0.10, trigger_y_min: 150, trigger_y_max: 270 }),
      trap("crusher", "CrusherIce1", 345, 6, 56, 42, { target_y: 198, fakeout_first: false, pass_through_platforms: false, trigger_y_min: 140, trigger_y_max: 270 }),
      trap("jumping_spikes", "JumpSpikesIce", 505, 240, 52, 28, { trigger_distance: 85, trigger_y_min: 140, trigger_y_max: 270 }),
      trap("moving_saw", "SawIceEnd", 695, 224, 32, 32, { radius: 16, patrol_distance: 130, patrol_speed: 145, patrol_axis: [-1, 0], trigger_y_min: 140, trigger_y_max: 270 }),
      trap("pop_up_spikes", "PopUpCave", 460, 415, 44, 32, { trigger_y_min: 350, trigger_y_max: 460 }),
    ],
    paranormal: { event_type: "black_ice_glide", param_a: 280 },
  },

  // L24: Frozen Compass points to real upper-right door; FakeDoor on lower-right; concealed FakeWall snowbank behind spawn hides left stair up through one-way UpperLeftCap to upper sky-deck
  {
    id: 24, chapter: 2, title: "Muzlagan Kompas", gimmick: "frozen_compass_needle",
    ceiling_h: 52, player_spawn: [175, 395], door_pos: [865, 220],
    platforms: [
      plat("LowerSnow", 32, 395, 896, 145),
      plat("RightMidStep", 525, 308, 115, 20, { one_way: true }),
      plat("UpperRightDeck", 640, 220, 288, 24),
      plat("UpperLeftCap", 32, 220, 94, 24, { one_way: true }),
      plat("UpperLeftDeck", 126, 220, 279, 24),
      plat("SecretLeftStep", 32, 308, 86, 18, { one_way: true }),
    ],
    fake_walls: [
      fwall("SnowBankCover", 32, 244, 92, 151, true),
    ],
    traps: [
      trap("pop_up_spikes", "PopUpLow1", 340, 395, 48, 32, { trigger_y_min: 330, trigger_y_max: 440 }),
      trap("rolling_boulder", "SnowballLow", 715, 367, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 265, trigger_distance: 200, trigger_y_min: 330, trigger_y_max: 440 }),
      trap("fake_door", "FakeDoorLow", 865, 395, 44, 58, { run_away_distance: 105, trigger_y_min: 330, trigger_y_max: 440 }),
      trap("falling_spike", "IcicleUpper", 745, 52, 24, 32, { trigger_distance: 220, pass_through_platforms: false, trigger_y_min: 140, trigger_y_max: 255 }),
    ],
    paranormal: { event_type: "frozen_compass_needle", target_node_path: "../../Traps/FakeDoorLow" },
  },

  // L25: Aurora Borealis shifts Cyan/Violet phasing Aurora Ice Platforms; high Cyan sky-arch bypasses lower saws & center pillar traps
  {
    id: 25, chapter: 2, title: "Shimol Yog'dusi", gimmick: "aurora_veil_shift",
    ceiling_h: 52, player_spawn: [95, 380], door_pos: [865, 380],
    platforms: [
      plat("CliffLeft", 0, 380, 220, 160),
      plat("CenterPillar", 425, 365, 110, 175),
      plat("CliffRight", 740, 380, 220, 160),
    ],
    traps: [
      trap("pop_up_spikes", "PopUpCenter", 458, 365, 44, 32, { trigger_y_min: 300, trigger_y_max: 410 }),
      trap("falling_spike", "IcicleCenter", 480, 52, 24, 32, { trigger_distance: 360, pass_through_platforms: true, stop_min_y: 325, trigger_y_min: 300, trigger_y_max: 410 }),
      trap("circular_saw", "CircSawLeft", 315, 330, 32, 32, { orbit_radius: 34, orbit_speed: 2.3 }),
      trap("circular_saw", "CircSawRight", 645, 330, 32, 32, { orbit_radius: 34, orbit_speed: -2.3 }),
      trap("moving_saw", "SawRightCliff", 815, 364, 32, 32, { radius: 16, patrol_distance: 70, patrol_speed: 120, patrol_axis: [-1, 0], trigger_y_min: 300, trigger_y_max: 420 }),
    ],
    paranormal: { event_type: "aurora_veil_shift" },
  },

  // L26: Spectral snowdrift wave sweeps R->L across lower floor once triggered; sheltered far-right alcove behind flush AlcoveSnowWall hides a Spring up through Bridge3Cap
  {
    id: 26, chapter: 2, title: "Qor Ko'chkisi", gimmick: "snowdrift_bury",
    ceiling_h: 50, player_spawn: [95, 420], door_pos: [870, 210],
    platforms: [
      plat("ValleyFloor", 32, 420, 896, 120),
      plat("Bridge1", 205, 332, 155, 22),
      plat("Bridge2", 425, 252, 180, 22),
      plat("Bridge3", 675, 210, 155, 24),
      plat("Bridge3Cap", 830, 210, 98, 24, { one_way: true }),
    ],
    fake_walls: [
      fwall("AlcoveSnowWall", 806, 234, 24, 186, true),
    ],
    traps: [
      trap("pop_up_spikes", "PopUpB1", 275, 332, 42, 28, { trigger_y_min: 260, trigger_y_max: 360 }),
      trap("moving_saw", "SawB2", 565, 236, 32, 32, { radius: 16, patrol_distance: 110, patrol_speed: 135, patrol_axis: [-1, 0], trigger_y_min: 170, trigger_y_max: 280 }),
      trap("falling_spike", "IcicleB3", 750, 50, 24, 32, { trigger_distance: 210, pass_through_platforms: false, trigger_y_min: 120, trigger_y_max: 245 }),
      trap("spring", "SpringAlcove", 884, 420, 44, 24, { launch_velocity: -860, trigger_y_min: 360, trigger_y_max: 455 }),
    ],
    paranormal: { event_type: "snowdrift_bury", trigger_x: 560, param_a: 85, param_b: 372 },
  },

  // L27: Giant Ice Mirror reflects player until center crossing -> cracks & swaps ExitDoor from RightBalcony to LeftBalcony; climb LeftBalcony first to trap-skip!
  {
    id: 27, chapter: 2, title: "Muz Oynasidagi Aks", gimmick: "frozen_mirror_twin",
    ceiling_h: 48, player_spawn: [115, 405], door_pos: [845, 255],
    platforms: [
      plat("MirrorFloor", 32, 405, 896, 135),
      plat("LeftStep", 242, 330, 62, 16, { one_way: true }),
      plat("RightStep", 656, 330, 62, 16, { one_way: true }),
      plat("LeftBalcony", 32, 255, 240, 24),
      plat("CenterBridge", 350, 255, 260, 24),
      plat("RightBalcony", 688, 255, 240, 24),
    ],
    traps: [
      trap("crusher", "CrusherLow", 452, 6, 56, 42, { target_y: 363, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 330, trigger_y_max: 450 }),
      trap("jumping_spikes", "JumpLow", 595, 405, 48, 28, { trigger_y_min: 330, trigger_y_max: 450 }),
      trap("moving_saw", "SawLow", 785, 389, 32, 32, { radius: 16, patrol_distance: 115, patrol_speed: 145, patrol_axis: [-1, 0], trigger_y_min: 330, trigger_y_max: 450 }),
      trap("circular_saw", "CircCenter", 480, 200, 32, 32, { orbit_radius: 34, orbit_speed: 2.5 }),
      trap("falling_spike", "IcicleLeft", 185, 48, 24, 32, { trigger_distance: 240, pass_through_platforms: false, trigger_y_min: 160, trigger_y_max: 285 }),
    ],
    paranormal: { event_type: "frozen_mirror_twin", trigger_x: 480, param_a: 115, param_b: 255, target_node_path: "../../ExitDoor" },
  },

  // L28: Sub-zero chill slows player outside 3 hanging warm amber Heat Lanterns; wrought-iron lantern brackets are standable upper sky-shortcut!
  {
    id: 28, chapter: 2, title: "Muzlagan Fonus", gimmick: "frostbite_lantern_pulse",
    ceiling_h: 48, player_spawn: [95, 395], door_pos: [870, 395],
    platforms: [
      plat("Deck1", 32, 395, 280, 145),
      plat("Deck2", 365, 345, 230, 195),
      plat("Deck3", 650, 395, 278, 145),
    ],
    traps: [
      trap("pop_up_spikes", "PopUpD1", 268, 395, 44, 32, { trigger_y_min: 330, trigger_y_max: 440 }),
      trap("crusher", "CrusherD2", 452, 6, 56, 42, { target_y: 303, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 280, trigger_y_max: 390 }),
      trap("rolling_boulder", "SnowballD3", 815, 367, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 250, trigger_distance: 185, trigger_y_min: 330, trigger_y_max: 440 }),
      trap("moving_saw", "SawD3", 755, 379, 32, 32, { radius: 16, patrol_distance: 85, patrol_speed: 130, patrol_axis: [-1, 0], trigger_y_min: 330, trigger_y_max: 440 }),
    ],
    paranormal: { event_type: "frostbite_lantern_pulse", param_a: 122 },
  },

  // L29: R->L 3-story S-climb; 3 jump landings send acoustic shockwaves fracturing the glacier & crystallizing a right-side Ice Shortcut Step right near spawn!
  {
    id: 29, chapter: 2, title: "Muz Yorilishi", gimmick: "shattering_glacier_echo",
    ceiling_h: 48, player_spawn: [860, 410], door_pos: [90, 220],
    platforms: [
      plat("LowerFloor", 32, 410, 896, 130),
      plat("LeftStep", 32, 320, 118, 20, { one_way: true }),
      plat("MidDeck", 195, 315, 550, 22),
      plat("RightStep", 795, 226, 133, 22, { one_way: true }),
      plat("TopDeck", 32, 220, 710, 22),
    ],
    aux_container: {
      name: "GlacierFractureStep",
      platforms: [
        plat("FracStep1", 795, 318, 110, 18, { one_way: true }),
      ],
    },
    traps: [
      trap("crusher", "CrusherLow", 515, 6, 56, 42, { target_y: 368, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 345, trigger_y_max: 455 }),
      trap("moving_saw", "SawLow", 355, 394, 32, 32, { radius: 16, patrol_distance: 120, patrol_speed: 140, patrol_axis: [-1, 0], trigger_y_min: 345, trigger_y_max: 455 }),
      trap("rolling_boulder", "SnowballMid", 685, 287, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 255, trigger_distance: 210, trigger_y_min: 250, trigger_y_max: 345 }),
      trap("jumping_spikes", "JumpMid", 390, 315, 48, 28, { trigger_y_min: 250, trigger_y_max: 345 }),
      trap("pop_up_spikes", "PopUpTop", 420, 220, 44, 32, { trigger_y_min: 140, trigger_y_max: 255 }),
      trap("falling_spike", "IcicleTop", 250, 48, 24, 32, { trigger_distance: 210, pass_through_platforms: false, trigger_y_min: 140, trigger_y_max: 255 }),
    ],
    paranormal: { event_type: "shattering_glacier_echo", aux_node_path: "../../Platforms/GlacierFractureStep" },
  },

  // L30: Reversing Blizzard Whiteout (odd=Right tailwind, even=Left headwind); hidden TrapFloor behind spawn drops into calm wind-sheltered sub-glacier cave + Spring to PeakRight!
  {
    id: 30, chapter: 2, title: "Qor Bo'roni", gimmick: "blizzard_whiteout_gust",
    ceiling_h: 52, player_spawn: [155, 300], door_pos: [865, 300],
    platforms: [
      plat("PeakLeft", 96, 300, 146, 26),
      plat("PeakMid", 345, 280, 260, 26),
      plat("PeakRight", 710, 300, 128, 26),
      plat("PeakRightCap", 838, 300, 90, 20, { one_way: true }),
      plat("CalmSubCave", 32, 430, 896, 110),
    ],
    traps: [
      trap("trap_floor", "TrapBackCave", 32, 300, 64, 26, { shake_duration: 0.10, trigger_y_min: 220, trigger_y_max: 330 }),
      trap("pop_up_spikes", "PopUpMid", 460, 280, 44, 32, { trigger_y_min: 200, trigger_y_max: 315 }),
      trap("falling_spike", "IcicleMid", 535, 52, 24, 32, { trigger_distance: 270, pass_through_platforms: false, trigger_y_min: 200, trigger_y_max: 315 }),
      trap("circular_saw", "CircGap", 655, 245, 32, 32, { orbit_radius: 32, orbit_speed: 2.5 }),
      trap("moving_saw", "SawCave", 495, 414, 32, 32, { radius: 16, patrol_distance: 150, patrol_speed: 140, patrol_axis: [-1, 0], trigger_y_min: 365, trigger_y_max: 470 }),
      trap("spring", "SpringCaveExit", 865, 430, 32, 24, { launch_velocity: -720, trigger_y_min: 370, trigger_y_max: 470 }),
    ],
    paranormal: { event_type: "blizzard_whiteout_gust", param_a: 365 },
  },

  // L31: Every mid-air Dash crystallizes a 3.2s frozen ice-cloud platform beneath player (max 2); chain high dash-clouds over MidSpire hazards!
  {
    id: 31, chapter: 2, title: "To'xtagan Muzlik", gimmick: "frozen_dash_platforms",
    ceiling_h: 52, player_spawn: [95, 360], door_pos: [865, 360],
    platforms: [
      plat("StartSpire", 32, 360, 175, 180),
      plat("MidSpire", 415, 330, 130, 210),
      plat("EndSpire", 750, 360, 178, 180),
    ],
    traps: [
      trap("spikes", "SpikesMid", 456, 298, 48, 32, { trigger_y_min: 260, trigger_y_max: 365 }),
      trap("falling_spike", "IcicleMid", 480, 52, 24, 32, { trigger_distance: 330, pass_through_platforms: false, trigger_y_min: 260, trigger_y_max: 365 }),
      trap("circular_saw", "CircLeft", 310, 315, 32, 32, { orbit_radius: 34, orbit_speed: 2.6 }),
      trap("circular_saw", "CircRight", 650, 315, 32, 32, { orbit_radius: 34, orbit_speed: -2.6 }),
      trap("moving_saw", "SawEnd", 820, 344, 32, 32, { radius: 16, patrol_distance: 65, patrol_speed: 125, patrol_axis: [-1, 0], trigger_y_min: 290, trigger_y_max: 395 }),
    ],
    paranormal: { event_type: "frozen_dash_platforms" },
  },

  // L32: Central Cryo-Updraft Column lifts player to HighRight; hidden far-right corner Spring under HighRightCap launches straight up onto ExitDoor!
  {
    id: 32, chapter: 2, title: "Osmon Muzligi", gimmick: "cryo_updraft_column",
    ceiling_h: 48, player_spawn: [95, 420], door_pos: [865, 200],
    platforms: [
      plat("BottomFloor", 32, 420, 896, 120),
      plat("HighLeft", 32, 200, 340, 24),
      plat("HighRight", 580, 200, 250, 24),
      plat("HighRightCap", 830, 200, 98, 20, { one_way: true }),
    ],
    traps: [
      trap("crusher", "CrusherLow", 240, 6, 56, 42, { target_y: 378, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 340, trigger_y_max: 460 }),
      trap("pop_up_spikes", "PopUpLow", 350, 420, 44, 32, { trigger_y_min: 350, trigger_y_max: 460 }),
      trap("circular_saw", "CircShaft", 480, 295, 32, 32, { orbit_radius: 42, orbit_speed: 2.4 }),
      trap("moving_saw", "SawHigh", 770, 184, 32, 32, { radius: 16, patrol_distance: 140, patrol_speed: 145, patrol_axis: [-1, 0], trigger_y_min: 120, trigger_y_max: 235 }),
      trap("rolling_boulder", "SnowballRight", 745, 392, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 260, trigger_distance: 165, trigger_y_min: 350, trigger_y_max: 460 }),
      trap("spring", "SpringRightChute", 870, 420, 32, 24, { launch_velocity: -870, trigger_y_min: 360, trigger_y_max: 460 }),
    ],
    paranormal: { event_type: "cryo_updraft_column", param_a: 420, param_b: 540 },
  },

  // L33: Cathedral Ice Bell tolls emitting expanding sonic frost ring that gives airborne resonance bounce -> jump-dash across upper gallery chasm!
  {
    id: 33, chapter: 2, title: "Muz Qo'ng'irog'i", gimmick: "frost_bell_shockwave",
    ceiling_h: 48, player_spawn: [115, 420], door_pos: [855, 260],
    platforms: [
      plat("BellFloor", 32, 420, 896, 120),
      plat("LeftStep", 32, 340, 84, 18, { one_way: true }),
      plat("RightStep", 795, 340, 133, 18, { one_way: true }),
      plat("LeftGallery", 32, 260, 288, 24, { one_way: true }),
      plat("RightGallery", 640, 260, 288, 24, { one_way: true }),
    ],
    traps: [
      trap("crusher", "CrusherLow1", 345, 6, 56, 42, { target_y: 378, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 350, trigger_y_max: 460 }),
      trap("pop_up_spikes", "PopUpLow", 495, 420, 48, 32, { trigger_y_min: 350, trigger_y_max: 460 }),
      trap("rolling_boulder", "SnowballLow", 720, 392, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 270, bounce_back_once: true, trigger_distance: 200, trigger_y_min: 350, trigger_y_max: 460 }),
      trap("falling_spike", "IcicleRight", 755, 48, 24, 32, { trigger_distance: 250, pass_through_platforms: false, trigger_y_min: 170, trigger_y_max: 295 }),
      trap("jumping_spikes", "JumpRight", 715, 260, 44, 28, { trigger_y_min: 180, trigger_y_max: 295 }),
    ],
    paranormal: { event_type: "frost_bell_shockwave" },
  },

  // L34: R->L lower run -> Glacial Prism refracts at x<=530 solidifying a Refracted Crystal Step right back on the RIGHT side near spawn -> turn back & climb straight to Door!
  {
    id: 34, chapter: 2, title: "Muz Prizmasi", gimmick: "glacial_prism_split",
    ceiling_h: 48, player_spawn: [860, 415], door_pos: [755, 235],
    platforms: [
      plat("FloorBot", 32, 415, 896, 125),
      plat("MidStepLeft", 32, 325, 118, 20, { one_way: true }),
      plat("UpperDeck", 190, 235, 635, 24),
    ],
    aux_container: {
      name: "RefractedStep",
      platforms: [
        plat("PrismStep1", 790, 325, 108, 18, { one_way: true }),
      ],
    },
    traps: [
      trap("rolling_boulder", "SnowballBot", 640, 387, 56, 56, { boulder_radius: 28, roll_direction: 1, roll_speed: 245, trigger_distance: 175, trigger_y_min: 350, trigger_y_max: 460 }),
      trap("crusher", "CrusherBot", 385, 6, 56, 42, { target_y: 373, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 350, trigger_y_max: 460 }),
      trap("moving_saw", "SawBot", 265, 399, 32, 32, { radius: 16, patrol_distance: 105, patrol_speed: 145, patrol_axis: [-1, 0], trigger_y_min: 350, trigger_y_max: 460 }),
      trap("pop_up_spikes", "PopUpTop", 380, 235, 48, 32, { trigger_y_min: 150, trigger_y_max: 270 }),
      trap("circular_saw", "CircTop", 540, 182, 32, 32, { orbit_radius: 34, orbit_speed: 2.7 }),
      trap("falling_spike", "IcicleTop", 645, 48, 24, 32, { trigger_distance: 220, pass_through_platforms: false, trigger_y_min: 150, trigger_y_max: 270 }),
    ],
    paranormal: { event_type: "glacial_prism_split", trigger_x: 530, aux_node_path: "../../Platforms/RefractedStep" },
  },

  // L35: Permafrost frost-spikes crystallize behind your footsteps (no backtracking!); deliberately jump & hug right wall off TopRun to drop through FakeWall slab straight onto ExitDoor!
  {
    id: 35, chapter: 2, title: "Abadiy Muzlik", gimmick: "permafrost_creep",
    ceiling_h: 48, player_spawn: [85, 195], door_pos: [865, 420],
    platforms: [
      plat("TopRun", 32, 195, 688, 22),
      plat("MidRun", 168, 308, 700, 22),
      plat("BotRun", 32, 420, 896, 120),
    ],
    fake_walls: [
      fwall("MidRightFakeCap", 868, 308, 60, 22, false),
    ],
    traps: [
      trap("pop_up_spikes", "PopUpTop", 365, 195, 44, 28, { trigger_y_min: 115, trigger_y_max: 225 }),
      trap("falling_spike", "IcicleTop", 585, 48, 24, 32, { trigger_distance: 195, pass_through_platforms: false, trigger_y_min: 115, trigger_y_max: 225 }),
      trap("moving_saw", "SawMid", 640, 292, 32, 32, { radius: 16, patrol_distance: 145, patrol_speed: 145, patrol_axis: [-1, 0], trigger_y_min: 235, trigger_y_max: 335 }),
      trap("jumping_spikes", "JumpMid", 365, 308, 48, 28, { trigger_y_min: 235, trigger_y_max: 335 }),
      trap("crusher", "CrusherBot", 425, 6, 56, 42, { target_y: 378, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 355, trigger_y_max: 460 }),
      trap("rolling_boulder", "SnowballBot", 735, 392, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 265, trigger_distance: 190, trigger_y_min: 355, trigger_y_max: 460 }),
    ],
    paranormal: { event_type: "permafrost_creep" },
  },

  // L36: Snow-Cairn Totems reveal 3 hidden Sky Crystal Stones ONLY while airborne; vault high above trap-packed LowCenter!
  {
    id: 36, chapter: 2, title: "Muz Haykallar", gimmick: "sky_cairn_airborne",
    ceiling_h: 48, player_spawn: [95, 390], door_pos: [860, 390],
    platforms: [
      plat("StartLedge", 32, 390, 205, 150),
      plat("LowCenter", 295, 410, 370, 130),
      plat("EndLedge", 725, 390, 203, 150),
    ],
    traps: [
      trap("crusher", "CrusherCenter", 452, 6, 56, 42, { target_y: 368, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 335, trigger_y_max: 455 }),
      trap("pop_up_spikes", "PopUpC1", 345, 410, 44, 32, { trigger_y_min: 345, trigger_y_max: 455 }),
      trap("moving_saw", "SawCenter", 615, 394, 32, 32, { radius: 16, patrol_distance: 115, patrol_speed: 145, patrol_axis: [-1, 0], trigger_y_min: 345, trigger_y_max: 455 }),
      trap("rolling_boulder", "SnowballCenter", 605, 382, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 250, trigger_distance: 175, trigger_y_min: 345, trigger_y_max: 455 }),
    ],
    paranormal: { event_type: "sky_cairn_airborne" },
  },

  // L37: Pulsing Frozen Crystal Heart grants 1.24x high-jump frost surge; LeftPerch (y=302, 123px above CanyonFloor) is ONLY reachable during cyan heartbeat surge!
  {
    id: 37, chapter: 2, title: "Muzlagan Yurak", gimmick: "cryo_heartbeat_surge",
    ceiling_h: 48, player_spawn: [100, 425], door_pos: [90, 215],
    platforms: [
      plat("CanyonFloor", 32, 425, 896, 115),
      plat("LeftSurgePerch", 155, 302, 72, 16, { one_way: true }),
      plat("RightStep", 815, 340, 113, 20, { one_way: true }),
      plat("MidTerrace", 565, 325, 235, 22),
      plat("BridgeMid", 425, 240, 112, 20),
      plat("HighCliff", 32, 215, 340, 24, { one_way: true }),
    ],
    traps: [
      trap("crusher", "CrusherLow", 365, 6, 56, 42, { target_y: 383, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 355, trigger_y_max: 465 }),
      trap("jumping_spikes", "JumpLow", 510, 425, 48, 28, { trigger_y_min: 355, trigger_y_max: 465 }),
      trap("moving_saw", "SawLow", 735, 409, 32, 32, { radius: 16, patrol_distance: 130, patrol_speed: 145, patrol_axis: [-1, 0], trigger_y_min: 355, trigger_y_max: 465 }),
      trap("circular_saw", "CircMid", 480, 185, 32, 32, { orbit_radius: 32, orbit_speed: 2.5 }),
      trap("falling_spike", "IcicleHigh", 250, 48, 24, 32, { trigger_distance: 210, pass_through_platforms: false, trigger_y_min: 130, trigger_y_max: 250 }),
    ],
    paranormal: { event_type: "cryo_heartbeat_surge" },
  },

  // L38: 4 fragile Glacial Ice Panes shatter 0.45s after stepped on across upper chasm; deliberate drop into lower bowl leads to hidden Spring straight up through one-way RightRim!
  {
    id: 38, chapter: 2, title: "Sinuvchi Muzlar", gimmick: "shattering_ice_panes",
    ceiling_h: 48, player_spawn: [95, 250], door_pos: [865, 250],
    platforms: [
      plat("LeftRim", 32, 250, 188, 26),
      plat("RightRim", 740, 250, 188, 26, { one_way: true }),
      plat("BowlFloor", 32, 420, 896, 120),
    ],
    traps: [
      trap("circular_saw", "CircPane1", 355, 200, 32, 32, { orbit_radius: 34, orbit_speed: 2.4 }),
      trap("falling_spike", "IciclePane2", 540, 48, 24, 32, { trigger_distance: 245, pass_through_platforms: false, trigger_y_min: 165, trigger_y_max: 280 }),
      trap("crusher", "CrusherBowl", 385, 6, 56, 42, { target_y: 378, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 350, trigger_y_max: 460 }),
      trap("moving_saw", "SawBowl", 585, 404, 32, 32, { radius: 16, patrol_distance: 130, patrol_speed: 145, patrol_axis: [-1, 0], trigger_y_min: 350, trigger_y_max: 460 }),
      trap("spring", "SpringBowlExit", 760, 420, 32, 24, { launch_velocity: -790, trigger_y_min: 360, trigger_y_max: 460 }),
    ],
    paranormal: { event_type: "shattering_ice_panes" },
  },

  // L39: Towering Wall of Living Ice sweeps Left->Right chasing player across ascending ridges; hidden Spring far behind spawn launches up to HighCatwalk ahead of avalanche!
  {
    id: 39, chapter: 2, title: "Muz Devori", gimmick: "avalanche_wall_chase",
    ceiling_h: 48, player_spawn: [145, 400], door_pos: [870, 230],
    platforms: [
      plat("Ridge1", 32, 400, 245, 140),
      plat("Ridge2", 325, 340, 215, 200),
      plat("Ridge3", 590, 280, 175, 260),
      plat("Summit", 810, 230, 118, 310),
      plat("HighCatwalk", 150, 195, 560, 20, { one_way: true }),
    ],
    traps: [
      trap("spring", "SpringHigh", 46, 400, 28, 24, { launch_velocity: -840, trigger_y_min: 340, trigger_y_max: 435 }),
      trap("pop_up_spikes", "PopUpR2", 420, 340, 44, 32, { trigger_y_min: 270, trigger_y_max: 375 }),
      trap("jumping_spikes", "JumpR3", 650, 280, 44, 28, { trigger_y_min: 210, trigger_y_max: 315 }),
      trap("falling_spike", "IcicleCatwalk", 480, 48, 24, 32, { trigger_distance: 190, pass_through_platforms: false, trigger_y_min: 115, trigger_y_max: 225 }),
      trap("moving_saw", "SawR2", 505, 324, 32, 32, { radius: 16, patrol_distance: 85, patrol_speed: 135, patrol_axis: [-1, 0], trigger_y_min: 270, trigger_y_max: 375 }),
    ],
    paranormal: { event_type: "avalanche_wall_chase", trigger_x: 205, param_a: 112 },
  },

  // L40 (Chapter 2 Finale): Rotating Glacial Frost Crown seals ExitDoor on CrownThrone until awakened at Right Frost Altar OR mid-air Crown Aura jump from LeftLedge!
  {
    id: 40, chapter: 2, title: "Muz Toji", gimmick: "frost_crown_finale",
    ceiling_h: 48, player_spawn: [115, 420], door_pos: [480, 205],
    platforms: [
      plat("SanctumFloor", 32, 420, 896, 120),
      plat("LeftStep", 36, 354, 76, 16, { one_way: true }),
      plat("RightStep", 820, 354, 108, 16, { one_way: true }),
      plat("LeftLedge", 32, 286, 235, 22, { one_way: true }),
      plat("RightLedge", 693, 286, 235, 22, { one_way: true }),
      plat("CrownThrone", 395, 205, 170, 24),
    ],
    traps: [
      trap("crusher", "CrusherLow", 355, 6, 56, 42, { target_y: 378, double_slam: true, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 350, trigger_y_max: 460 }),
      trap("pop_up_spikes", "PopUpLow", 495, 420, 48, 32, { trigger_y_min: 350, trigger_y_max: 460 }),
      trap("moving_saw", "SawLow", 675, 404, 32, 32, { radius: 16, patrol_distance: 130, patrol_speed: 155, patrol_axis: [-1, 0], trigger_y_min: 350, trigger_y_max: 460 }),
      trap("rolling_boulder", "SnowballLow", 775, 392, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 270, bounce_back_once: true, trigger_distance: 195, trigger_y_min: 350, trigger_y_max: 460 }),
      trap("circular_saw", "CircRight", 630, 265, 32, 32, { orbit_radius: 26, orbit_speed: 2.7 }),
      trap("falling_spike", "IcicleRight", 785, 48, 24, 32, { trigger_distance: 280, pass_through_platforms: false, trigger_y_min: 205, trigger_y_max: 320 }),
    ],
    paranormal: { event_type: "frost_crown_finale", trigger_x: 735 },
  },
];

// =========================================================================
// CHAPTER 3: EMERALD WOODS / FOREST (Levels 41-60)
// =========================================================================
const CHAPTER_3 = [
  // L41: Spirit Fireflies lure player across trapped CanopyMain; concealed TrapFloor behind spawn drops quietly to safe ForestFloor + RootExitStep up through one-way CanopyExitCap
  {
    id: 41, chapter: 3, title: "Aldovchi Chiroqlar", gimmick: "firefly_path_decoy",
    ceiling_h: 52, player_spawn: [175, 305], door_pos: [865, 305],
    platforms: [
      plat("CanopyMain", 96, 305, 724, 24),
      plat("CanopyExitCap", 820, 305, 108, 24, { one_way: true }),
      plat("ForestFloor", 32, 430, 896, 110),
      plat("RootExitStep", 825, 368, 90, 16, { one_way: true }),
    ],
    traps: [
      trap("trap_floor", "TrapMossBack", 32, 305, 64, 24, { shake_duration: 0.10, trigger_y_min: 225, trigger_y_max: 335 }),
      trap("pop_up_spikes", "PopUpCanopy1", 345, 305, 44, 32, { trigger_y_min: 225, trigger_y_max: 335 }),
      trap("falling_spike", "ThornCanopy", 525, 52, 24, 32, { trigger_distance: 280, pass_through_platforms: false, trigger_y_min: 225, trigger_y_max: 335 }),
      trap("moving_saw", "SawCanopy", 730, 289, 32, 32, { radius: 16, patrol_distance: 140, patrol_speed: 140, patrol_axis: [-1, 0], trigger_y_min: 225, trigger_y_max: 335 }),
      trap("pop_up_spikes", "PopUpRoot", 460, 430, 40, 28, { trigger_y_min: 365, trigger_y_max: 470 }),
    ],
    paranormal: { event_type: "firefly_path_decoy", trigger_x: 330 },
  },

  // L42: Living Emerald Vines grow dynamically ahead & wither after 1.75s; jumping straight UP at LeftBough edge awakens high 4th canopy vine above all saws!
  {
    id: 42, chapter: 3, title: "Tirik Chirmovuq", gimmick: "living_vine_bridge",
    ceiling_h: 50, player_spawn: [105, 340], door_pos: [860, 340],
    platforms: [
      plat("LeftBough", 32, 340, 210, 200),
      plat("RightBough", 718, 340, 210, 200),
    ],
    traps: [
      trap("circular_saw", "CircVine1", 395, 305, 32, 32, { orbit_radius: 34, orbit_speed: 2.3 }),
      trap("circular_saw", "CircVine2", 565, 305, 32, 32, { orbit_radius: 34, orbit_speed: -2.3 }),
      trap("falling_spike", "ThornMid", 480, 50, 24, 32, { trigger_distance: 320, pass_through_platforms: true, stop_min_y: 300, trigger_y_min: 270, trigger_y_max: 380 }),
      trap("pop_up_spikes", "PopUpRight", 770, 340, 42, 30, { trigger_y_min: 270, trigger_y_max: 375 }),
    ],
    paranormal: { event_type: "living_vine_bridge" },
  },

  // L43: R->L woodland descent; Carved Totem shifts Calm/Trickster(1.38x)/Wrath(0.72x); Trickster speed-boost jump+dash off UpperGlade reaches HighLeftPerch right over Door!
  {
    id: 43, chapter: 3, title: "Pichirlovchi But", gimmick: "whispering_totem_curse",
    ceiling_h: 48, player_spawn: [860, 225], door_pos: [85, 415],
    platforms: [
      plat("UpperGlade", 610, 225, 318, 24),
      plat("MidGlade", 290, 320, 360, 24),
      plat("LowerGlade", 32, 415, 896, 125),
      plat("HighLeftPerch", 32, 245, 255, 22),
    ],
    traps: [
      trap("pop_up_spikes", "PopUpMid", 460, 320, 44, 32, { trigger_y_min: 250, trigger_y_max: 350 }),
      trap("moving_saw", "SawMid", 595, 304, 32, 32, { radius: 16, patrol_distance: 110, patrol_speed: 140, patrol_axis: [-1, 0], trigger_y_min: 250, trigger_y_max: 350 }),
      trap("rolling_boulder", "VineBoulderLow", 690, 387, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 260, trigger_distance: 215, trigger_y_min: 350, trigger_y_max: 455 }),
      trap("crusher", "CrusherLow", 240, 6, 56, 42, { target_y: 373, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 350, trigger_y_max: 455 }),
    ],
    paranormal: { event_type: "whispering_totem_curse" },
  },

  // L44: Moonlit Pond fills lower basin with buoyant low-gravity water (0.50g); dropping into the pond lets you buoyant-leap cleanly under StoneArch straight onto EastBank!
  {
    id: 44, chapter: 3, title: "Oy Ko'li", gimmick: "moonlit_pond_inversion",
    ceiling_h: 48, player_spawn: [95, 315], door_pos: [860, 315],
    platforms: [
      plat("WestBank", 32, 315, 190, 225),
      plat("StoneArch", 290, 265, 380, 24),
      plat("EastBank", 740, 315, 188, 225),
      plat("PondBed", 222, 415, 518, 125),
    ],
    traps: [
      trap("crusher", "CrusherArch", 452, 6, 56, 42, { target_y: 223, fakeout_first: false, pass_through_platforms: false, trigger_y_min: 170, trigger_y_max: 295 }),
      trap("jumping_spikes", "JumpArch", 355, 265, 48, 28, { trigger_y_min: 185, trigger_y_max: 295 }),
      trap("moving_saw", "SawArch", 635, 249, 32, 32, { radius: 16, patrol_distance: 135, patrol_speed: 140, patrol_axis: [-1, 0], trigger_y_min: 185, trigger_y_max: 295 }),
      trap("falling_spike", "ThornArch", 535, 48, 24, 32, { trigger_distance: 240, pass_through_platforms: false, trigger_y_min: 180, trigger_y_max: 295 }),
    ],
    paranormal: { event_type: "moonlit_pond_inversion", param_a: 378 },
  },

  // L45: Giant Bioluminescent Bounce Mushrooms; two subtle dark-capped Secret Spore Buds behind spawn bounce straight up through one-way LeftBranch -> CanopyExit!
  {
    id: 45, chapter: 3, title: "Zamburug' Sporlari", gimmick: "spore_cloud_bounce",
    ceiling_h: 48, player_spawn: [165, 430], door_pos: [105, 180],
    platforms: [
      plat("HollowFloor", 32, 430, 896, 110),
      plat("LeftBranch", 32, 315, 245, 22, { one_way: true }),
      plat("RightBranch", 515, 250, 413, 22, { one_way: true }),
      plat("CanopyExit", 32, 180, 320, 22, { one_way: true }),
    ],
    traps: [
      trap("pop_up_spikes", "PopUpLow", 380, 430, 48, 32, { trigger_y_min: 365, trigger_y_max: 470 }),
      trap("rolling_boulder", "VineBoulderLow", 650, 402, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 255, trigger_distance: 185, trigger_y_min: 365, trigger_y_max: 470 }),
      trap("moving_saw", "SawRight", 825, 234, 32, 32, { radius: 16, patrol_distance: 140, patrol_speed: 145, patrol_axis: [-1, 0], trigger_y_min: 180, trigger_y_max: 280 }),
      trap("circular_saw", "CircMid", 435, 215, 32, 32, { orbit_radius: 32, orbit_speed: 2.5 }),
      trap("falling_spike", "ThornRight", 685, 48, 24, 32, { trigger_distance: 230, pass_through_platforms: false, trigger_y_min: 170, trigger_y_max: 280 }),
    ],
    paranormal: { event_type: "spore_cloud_bounce" },
  },

  // L46: Giant Forest Owl Sentinel sweeps golden hunt cone over lower clearing (stand still or shelter under roofs!); climbing ONTO ShelterRoofs puts you above gaze cone!
  {
    id: 46, chapter: 3, title: "Boyo'g'li Qo'riqchisi", gimmick: "owl_sentinel_gaze",
    ceiling_h: 48, player_spawn: [95, 405], door_pos: [870, 405],
    platforms: [
      plat("ForestFloor", 32, 405, 896, 135),
      plat("Shelter1Roof", 258, 308, 124, 22, { one_way: true }),
      plat("Shelter2Roof", 558, 308, 124, 22, { one_way: true }),
    ],
    traps: [
      trap("pop_up_spikes", "PopUpMid1", 435, 405, 44, 32, { trigger_y_min: 340, trigger_y_max: 445 }),
      trap("moving_saw", "SawLow2", 795, 389, 32, 32, { radius: 16, patrol_distance: 110, patrol_speed: 135, patrol_axis: [-1, 0], trigger_y_min: 340, trigger_y_max: 445 }),
      trap("falling_spike", "ThornGap", 480, 48, 24, 32, { trigger_distance: 370, pass_through_platforms: true, stop_min_y: 365, trigger_y_min: 340, trigger_y_max: 445 }),
    ],
    paranormal: { event_type: "owl_sentinel_gaze" },
  },

  // L47: Living Sap Runes raise root bridges; jumping straight up above spawn touches hidden mossy Sap Bud B raising LeftRootStep up through one-way UpperCanopy right under ExitDoor!
  {
    id: 47, chapter: 3, title: "Harakatlanuvchi Ildizlar", gimmick: "root_labyrinth_shift",
    ceiling_h: 48, player_spawn: [95, 415], door_pos: [85, 235],
    platforms: [
      plat("FloorBot", 32, 415, 896, 125),
      plat("UpperCanopy", 32, 235, 755, 24, { one_way: true }),
      plat("RightRootLift", 805, 408, 118, 20, { one_way: true }),
    ],
    aux_container: {
      name: "LeftRootShortcut",
      platforms: [
        plat("LeftRootStep", 155, 325, 92, 18, { one_way: true }),
      ],
    },
    traps: [
      trap("crusher", "CrusherLow", 355, 6, 56, 42, { target_y: 373, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 350, trigger_y_max: 460 }),
      trap("jumping_spikes", "JumpLow", 510, 415, 48, 28, { trigger_y_min: 350, trigger_y_max: 460 }),
      trap("moving_saw", "SawLow", 685, 399, 32, 32, { radius: 16, patrol_distance: 115, patrol_speed: 145, patrol_axis: [-1, 0], trigger_y_min: 350, trigger_y_max: 460 }),
      trap("circular_saw", "CircTop", 545, 182, 32, 32, { orbit_radius: 34, orbit_speed: 2.6 }),
      trap("pop_up_spikes", "PopUpTop", 385, 235, 44, 32, { trigger_y_min: 155, trigger_y_max: 270 }),
      trap("falling_spike", "ThornTop", 250, 48, 24, 32, { trigger_distance: 210, pass_through_platforms: false, trigger_y_min: 155, trigger_y_max: 270 }),
    ],
    paranormal: {
      event_type: "root_labyrinth_shift",
      trigger_x: 745, trigger_y: 385, param_a: 95, param_b: 325,
      target_node_path: "../../Platforms/RightRootLift",
      aux_node_path: "../../Platforms/LeftRootShortcut",
    },
  },

  // L48: Dream Pollen slows falling descent (0.56g ONLY when velocity.y > 20) -> paraglider jump+double-dash straight off high Tree1 over Tree2 onto Tree3!
  {
    id: 48, chapter: 3, title: "Gulchang Tushi", gimmick: "pollen_dream_drift",
    ceiling_h: 48, player_spawn: [85, 195], door_pos: [865, 375],
    platforms: [
      plat("Tree1", 32, 195, 170, 26),
      plat("Tree2", 355, 285, 185, 26),
      plat("Tree3", 650, 375, 278, 165),
    ],
    traps: [
      trap("circular_saw", "CircGap1", 275, 285, 32, 32, { orbit_radius: 30, orbit_speed: 2.4 }),
      trap("pop_up_spikes", "PopUpT2", 435, 285, 44, 32, { trigger_y_min: 215, trigger_y_max: 320 }),
      trap("circular_saw", "CircGap2", 595, 365, 32, 32, { orbit_radius: 28, orbit_speed: -2.4 }),
      trap("rolling_boulder", "VineBoulderT3", 825, 347, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 240, trigger_distance: 155, trigger_y_min: 310, trigger_y_max: 415 }),
    ],
    paranormal: { event_type: "pollen_dream_drift" },
  },

  // L49: Ethereal Spirit Stag bounds across ravine blooming 3.2s luminous Hoof-Pads in upper air; ride the Stag's high trail over MidRock traps!
  {
    id: 49, chapter: 3, title: "Ruhiy Bug'u", gimmick: "phantom_stag_guide",
    ceiling_h: 50, player_spawn: [95, 365], door_pos: [865, 365],
    platforms: [
      plat("WestCliff", 32, 365, 190, 175),
      plat("MidRock", 425, 355, 115, 185),
      plat("EastCliff", 745, 365, 183, 175),
    ],
    traps: [
      trap("spikes", "SpikesMid", 460, 323, 44, 32, { trigger_y_min: 285, trigger_y_max: 390 }),
      trap("falling_spike", "ThornMid", 482, 50, 24, 32, { trigger_distance: 330, pass_through_platforms: false, trigger_y_min: 285, trigger_y_max: 390 }),
      trap("circular_saw", "CircLeft", 325, 355, 32, 32, { orbit_radius: 28, orbit_speed: 2.5 }),
      trap("circular_saw", "CircRight", 640, 355, 32, 32, { orbit_radius: 28, orbit_speed: -2.5 }),
      trap("moving_saw", "SawEast", 815, 349, 32, 32, { radius: 16, patrol_distance: 65, patrol_speed: 125, patrol_axis: [-1, 0], trigger_y_min: 300, trigger_y_max: 400 }),
    ],
    paranormal: { event_type: "phantom_stag_guide" },
  },

  // L50: Canopy Eclipse Twilight with 4 swaying Sunbeam Shafts that refresh Dash cooldown instantly -> chain mid-air sunbeam dashes straight across high sky!
  {
    id: 50, chapter: 3, title: "O'rmon Tutilishi", gimmick: "canopy_eclipse_dark",
    ceiling_h: 48, player_spawn: [95, 405], door_pos: [870, 405],
    platforms: [
      plat("FloorLeft", 32, 405, 275, 135),
      plat("MidIsland", 390, 330, 185, 210),
      plat("FloorRight", 665, 405, 263, 135),
    ],
    traps: [
      trap("pop_up_spikes", "PopUpLeft", 225, 405, 44, 32, { trigger_y_min: 340, trigger_y_max: 445 }),
      trap("crusher", "CrusherMid", 454, 6, 56, 42, { target_y: 288, fakeout_first: false, pass_through_platforms: false, trigger_y_min: 255, trigger_y_max: 365 }),
      trap("falling_spike", "ThornRight", 720, 48, 24, 32, { trigger_distance: 375, pass_through_platforms: false, trigger_y_min: 335, trigger_y_max: 445 }),
      trap("rolling_boulder", "VineBoulderRight", 815, 377, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 255, trigger_distance: 175, trigger_y_min: 340, trigger_y_max: 445 }),
    ],
    paranormal: { event_type: "canopy_eclipse_dark" },
  },

  // L51: Twin Fairy Mushroom Rings; pausing 0.42s inside lower Fairy Ring (x=505) teleports directly to upper Fairy Ring right beside ExitDoor (zero accidental trigger while running!)
  {
    id: 51, chapter: 3, title: "Peri Halqasi", gimmick: "fairy_ring_portal",
    ceiling_h: 48, player_spawn: [95, 410], door_pos: [85, 225],
    platforms: [
      plat("LowerFloor", 32, 410, 896, 130),
      plat("MidStep", 805, 318, 123, 20, { one_way: true }),
      plat("UpperCanopy", 32, 225, 760, 24),
    ],
    traps: [
      trap("crusher", "CrusherLow", 315, 6, 56, 42, { target_y: 368, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 345, trigger_y_max: 455 }),
      trap("jumping_spikes", "JumpLow", 645, 410, 48, 28, { trigger_y_min: 345, trigger_y_max: 455 }),
      trap("rolling_boulder", "VineBoulderLow", 775, 382, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 265, trigger_distance: 185, trigger_y_min: 345, trigger_y_max: 455 }),
      trap("circular_saw", "CircTop", 540, 175, 32, 32, { orbit_radius: 34, orbit_speed: 2.6 }),
      trap("moving_saw", "SawTop", 420, 209, 32, 32, { radius: 16, patrol_distance: 130, patrol_speed: 145, patrol_axis: [-1, 0], trigger_y_min: 145, trigger_y_max: 260 }),
      trap("pop_up_spikes", "PopUpTop", 645, 225, 44, 32, { trigger_y_min: 145, trigger_y_max: 260 }),
    ],
    paranormal: { event_type: "fairy_ring_portal", trigger_x: 505, trigger_y: 410, param_a: 185, param_b: 225 },
  },

  // L52: Draping Weeping Willow Curtain conceals hidden upper canopy perches (`y=235`) that part dynamically as you walk through; step up behind spawn (x=42) to enter curtain!
  {
    id: 52, chapter: 3, title: "Majnun Tol Pardasi", gimmick: "weeping_willow_curtain",
    ceiling_h: 48, player_spawn: [155, 405], door_pos: [865, 405],
    platforms: [
      plat("LowerFloor", 32, 405, 896, 135),
      plat("RootStepLeft", 40, 322, 66, 16, { one_way: true }),
    ],
    traps: [
      trap("crusher", "Crusher1", 285, 6, 56, 42, { target_y: 363, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 335, trigger_y_max: 445 }),
      trap("pop_up_spikes", "PopUp1", 405, 405, 48, 32, { trigger_y_min: 335, trigger_y_max: 445 }),
      trap("moving_saw", "SawMid", 565, 389, 32, 32, { radius: 16, patrol_distance: 130, patrol_speed: 150, patrol_axis: [-1, 0], trigger_y_min: 335, trigger_y_max: 445 }),
      trap("crusher", "Crusher2", 645, 6, 56, 42, { target_y: 363, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 335, trigger_y_max: 445 }),
      trap("rolling_boulder", "VineBoulderEnd", 795, 377, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 265, trigger_distance: 190, trigger_y_min: 335, trigger_y_max: 445 }),
    ],
    paranormal: { event_type: "weeping_willow_curtain" },
  },

  // L53: R->L ravine; Luminous Cicada Swarm Raft glides smoothly across upper canopy (`y=238`) carrying player cleanly above CenterStump traps!
  {
    id: 53, chapter: 3, title: "Chigirtka Karvoni", gimmick: "cicada_swarm_raft",
    ceiling_h: 48, player_spawn: [865, 360], door_pos: [85, 360],
    platforms: [
      plat("EastBranch", 745, 360, 183, 180),
      plat("EastPerch", 795, 268, 92, 16, { one_way: true }),
      plat("CenterStump", 415, 385, 130, 155),
      plat("WestBranch", 32, 360, 185, 180),
    ],
    traps: [
      trap("pop_up_spikes", "PopUpStump", 460, 385, 44, 32, { trigger_y_min: 320, trigger_y_max: 420 }),
      trap("falling_spike", "ThornStump", 480, 48, 24, 32, { trigger_distance: 350, pass_through_platforms: true, stop_min_y: 345, trigger_y_min: 315, trigger_y_max: 420 }),
      trap("circular_saw", "CircEast", 640, 340, 32, 32, { orbit_radius: 34, orbit_speed: 2.5 }),
      trap("circular_saw", "CircWest", 315, 340, 32, 32, { orbit_radius: 34, orbit_speed: -2.5 }),
      trap("moving_saw", "SawWest", 196, 344, 32, 32, { radius: 16, patrol_distance: 50, patrol_speed: 120, patrol_axis: [-1, 0], trigger_y_min: 295, trigger_y_max: 395 }),
    ],
    paranormal: { event_type: "cicada_swarm_raft" },
  },

  // L54: Center-start split! Crossing above horizontal Emerald Ley-Line (`y=295`) activates Feather-Canopy Drift (0.62g, 1.15x speed) to glide from LeftTerrace onto HighCrown!
  {
    id: 54, chapter: 3, title: "Moxli Ko'zgu", gimmick: "moss_leyline_gravity",
    ceiling_h: 48, player_spawn: [480, 415], door_pos: [480, 215],
    platforms: [
      plat("FloorMain", 32, 415, 896, 125),
      plat("LeftStep", 180, 366, 72, 16, { one_way: true }),
      plat("RightStep", 708, 366, 72, 16, { one_way: true }),
      plat("LeftTerrace", 32, 315, 175, 22, { one_way: true }),
      plat("RightTerrace", 753, 315, 175, 22, { one_way: true }),
      plat("HighCrown", 280, 215, 400, 24),
    ],
    traps: [
      trap("crusher", "CrusherLeft", 275, 6, 56, 42, { target_y: 373, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 350, trigger_y_max: 455 }),
      trap("pop_up_spikes", "PopUpRight", 615, 415, 48, 32, { trigger_y_min: 350, trigger_y_max: 455 }),
      trap("rolling_boulder", "VineBoulderRight", 815, 387, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 255, trigger_distance: 195, trigger_y_min: 350, trigger_y_max: 455 }),
      trap("circular_saw", "CircRightTop", 640, 170, 32, 32, { orbit_radius: 32, orbit_speed: 2.6 }),
      trap("falling_spike", "ThornCrown", 565, 48, 24, 32, { trigger_distance: 205, pass_through_platforms: false, trigger_y_min: 140, trigger_y_max: 250 }),
    ],
    paranormal: { event_type: "moss_leyline_gravity", param_a: 295 },
  },

  // L55: Ancient Tree Stump expands 5 growth rings; Ring #5 sprouts 2 hidden Root-Steps on sheer left wall straight through one-way TierHigh beside ExitDoor!
  {
    id: 55, chapter: 3, title: "Qadimiy To'nka Halqalari", gimmick: "ancient_stump_rings",
    ceiling_h: 48, player_spawn: [135, 430], door_pos: [90, 210],
    platforms: [
      plat("BaseFloor", 32, 430, 896, 110),
      plat("StepUp1", 820, 372, 108, 16, { one_way: true }),
      plat("TierMid", 335, 315, 593, 22, { one_way: true }),
      plat("StepUp2", 345, 264, 92, 16, { one_way: true }),
      plat("TierHigh", 32, 210, 615, 22, { one_way: true }),
    ],
    traps: [
      trap("pop_up_spikes", "PopUpBase", 385, 430, 48, 32, { trigger_y_min: 365, trigger_y_max: 470 }),
      trap("crusher", "CrusherBase", 555, 6, 56, 42, { target_y: 388, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 365, trigger_y_max: 470 }),
      trap("moving_saw", "SawBase", 745, 414, 32, 32, { radius: 16, patrol_distance: 120, patrol_speed: 145, patrol_axis: [-1, 0], trigger_y_min: 365, trigger_y_max: 470 }),
      trap("rolling_boulder", "VineBoulderMid", 725, 287, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 255, trigger_distance: 215, trigger_y_min: 245, trigger_y_max: 345 }),
      trap("jumping_spikes", "JumpMid", 495, 315, 48, 28, { trigger_y_min: 245, trigger_y_max: 345 }),
      trap("circular_saw", "CircTop", 300, 162, 32, 32, { orbit_radius: 30, orbit_speed: 2.6 }),
    ],
    paranormal: { event_type: "ancient_stump_rings" },
  },

  // L56: Dark Emerald Fog with dynamic Will-o'-the-Wisp Escort Lantern; turning LEFT at spawn makes Wisp illuminate concealed Spring + high log bridge above fog traps!
  {
    id: 56, chapter: 3, title: "O'rmon Ruhi Chirog'i", gimmick: "wisp_lantern_escort",
    ceiling_h: 48, player_spawn: [145, 395], door_pos: [865, 395],
    platforms: [
      plat("FogFloor1", 32, 395, 340, 145),
      plat("FogFloor2", 440, 345, 220, 195),
      plat("FogFloor3", 725, 395, 203, 145),
      plat("HighLogBridge", 130, 225, 640, 18, { one_way: true }),
    ],
    traps: [
      trap("spring", "SpringWispBack", 46, 395, 28, 24, { launch_velocity: -810, trigger_y_min: 335, trigger_y_max: 430 }),
      trap("pop_up_spikes", "PopUpF1", 265, 395, 44, 32, { trigger_y_min: 335, trigger_y_max: 430 }),
      trap("trap_floor", "TrapGap", 372, 395, 68, 145, { shake_duration: 0.14, trigger_y_min: 335, trigger_y_max: 430 }),
      trap("falling_spike", "ThornF2", 545, 48, 24, 32, { trigger_distance: 325, pass_through_platforms: true, stop_min_y: 305, trigger_y_min: 280, trigger_y_max: 380 }),
      trap("moving_saw", "SawF3", 815, 379, 32, 32, { radius: 16, patrol_distance: 85, patrol_speed: 135, patrol_axis: [-1, 0], trigger_y_min: 335, trigger_y_max: 430 }),
    ],
    paranormal: { event_type: "wisp_lantern_escort" },
  },

  // L57: Bending Spirit Bamboo stalks whip back when Dashed past creating a Leaf-Gust Ring -> jump into it to vault straight from Grove1 over Grove2 onto Grove3!
  {
    id: 57, chapter: 3, title: "Ruhiy Bambuk", gimmick: "spirit_bamboo_gust",
    ceiling_h: 48, player_spawn: [95, 420], door_pos: [865, 275],
    platforms: [
      plat("Grove1", 32, 420, 265, 120),
      plat("Grove2", 350, 350, 260, 190),
      plat("Grove3", 675, 275, 253, 265),
    ],
    traps: [
      trap("jumping_spikes", "JumpG2", 445, 350, 48, 28, { trigger_y_min: 305, trigger_y_max: 385 }),
      trap("crusher", "CrusherG2", 495, 6, 56, 42, { target_y: 308, fakeout_first: false, pass_through_platforms: false, trigger_y_min: 305, trigger_y_max: 385 }),
      trap("rolling_boulder", "VineBoulderG3", 815, 247, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 250, trigger_distance: 165, trigger_y_min: 210, trigger_y_max: 310 }),
      trap("pop_up_spikes", "PopUpG3", 755, 275, 44, 32, { trigger_y_min: 210, trigger_y_max: 310 }),
    ],
    paranormal: { event_type: "spirit_bamboo_gust" },
  },

  // L58: Woodland Tremors shift dual Tremor Stone Slabs horizontally every 3.2s; climb WestStep behind spawn onto one-way WestHigh & ride UpperTremorSlab straight to Door!
  {
    id: 58, chapter: 3, title: "Yer Silkinishi", gimmick: "root_tremor_slabs",
    ceiling_h: 48, player_spawn: [135, 385], door_pos: [865, 235],
    platforms: [
      plat("WestGround", 32, 385, 210, 155),
      plat("CenterPillar", 435, 385, 96, 155),
      plat("EastGround", 720, 385, 208, 155),
      plat("WestStep", 40, 310, 68, 16, { one_way: true }),
      plat("WestHigh", 32, 235, 195, 22, { one_way: true }),
      plat("EastStep", 845, 310, 83, 16, { one_way: true }),
      plat("EastHigh", 735, 235, 193, 22, { one_way: true }),
    ],
    traps: [
      trap("pop_up_spikes", "PopUpCenter", 462, 385, 44, 32, { trigger_y_min: 320, trigger_y_max: 420 }),
      trap("falling_spike", "ThornCenter", 482, 48, 24, 32, { trigger_distance: 350, pass_through_platforms: true, stop_min_y: 345, trigger_y_min: 315, trigger_y_max: 420 }),
      trap("moving_saw", "SawEast", 815, 369, 32, 32, { radius: 16, patrol_distance: 85, patrol_speed: 135, patrol_axis: [-1, 0], trigger_y_min: 320, trigger_y_max: 420 }),
      trap("circular_saw", "CircMid", 625, 325, 32, 32, { orbit_radius: 34, orbit_speed: 2.5 }),
    ],
    paranormal: { event_type: "root_tremor_slabs" },
  },

  // L59: Descending Thorny Overgrowth Vines creep down from ceiling forcing top-to-bottom descent; concealed TrapFloor behind spawn drops straight down left shaft to RootBottom!
  {
    id: 59, chapter: 3, title: "Hujumkor Chirmovuq", gimmick: "overgrowth_ceiling_vines",
    ceiling_h: 48, player_spawn: [155, 175], door_pos: [865, 415],
    platforms: [
      plat("CanopyTier1", 96, 175, 696, 20),
      plat("CanopyTier2", 168, 288, 760, 20),
      plat("RootBottom", 32, 415, 896, 125),
    ],
    traps: [
      trap("trap_floor", "TrapDropShaft", 32, 175, 64, 20, { shake_duration: 0.10, trigger_y_min: 100, trigger_y_max: 205 }),
      trap("pop_up_spikes", "PopUpT1", 415, 175, 44, 26, { trigger_y_min: 100, trigger_y_max: 205 }),
      trap("moving_saw", "SawT1", 675, 159, 32, 32, { radius: 16, patrol_distance: 130, patrol_speed: 150, patrol_axis: [-1, 0], trigger_y_min: 100, trigger_y_max: 205 }),
      trap("jumping_spikes", "JumpT2", 525, 288, 48, 28, { trigger_y_min: 220, trigger_y_max: 320 }),
      trap("circular_saw", "CircT2", 345, 240, 32, 32, { orbit_radius: 30, orbit_speed: 2.6 }),
      trap("rolling_boulder", "VineBoulderBot", 745, 387, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 265, trigger_distance: 205, trigger_y_min: 350, trigger_y_max: 455 }),
      trap("pop_up_spikes", "PopUpBot", 455, 415, 48, 32, { trigger_y_min: 350, trigger_y_max: 455 }),
    ],
    paranormal: { event_type: "overgrowth_ceiling_vines", trigger_x: 215, param_a: 32, param_b: 335 },
  },

  // L60 (Chapter 3 Grand Finale): Living World-Tree Heart 3-beat rhythm (Bloom Pads -> Golden Central Updraft -> Slumber); ride central Golden Pulse straight up through one-way SummitCenter onto ExitDoor!
  {
    id: 60, chapter: 3, title: "Hayot Daraxti Yuragi", gimmick: "world_tree_heart_finale",
    ceiling_h: 48, player_spawn: [105, 420], door_pos: [480, 185],
    platforms: [
      plat("SanctumRoot", 32, 420, 896, 120),
      plat("LeftStep", 36, 370, 80, 16, { one_way: true }),
      plat("RightStep", 830, 370, 98, 16, { one_way: true }),
      plat("LeftBough", 32, 315, 220, 22, { one_way: true }),
      plat("RightBough", 708, 315, 220, 22, { one_way: true }),
      plat("SummitLeft", 355, 185, 85, 24, { one_way: true }),
      plat("SummitCenter", 440, 185, 80, 20, { one_way: true }),
      plat("SummitRight", 520, 185, 85, 24, { one_way: true }),
    ],
    traps: [
      trap("crusher", "CrusherLow", 325, 6, 56, 42, { target_y: 378, double_slam: true, fakeout_first: false, pass_through_platforms: true, trigger_y_min: 355, trigger_y_max: 460 }),
      trap("jumping_spikes", "JumpLow", 565, 420, 48, 28, { trigger_y_min: 355, trigger_y_max: 460 }),
      trap("moving_saw", "SawLow", 735, 404, 32, 32, { radius: 16, patrol_distance: 120, patrol_speed: 155, patrol_axis: [-1, 0], trigger_y_min: 355, trigger_y_max: 460 }),
      trap("rolling_boulder", "VineBoulderLow", 785, 392, 56, 56, { boulder_radius: 28, roll_direction: -1, roll_speed: 270, trigger_distance: 195, trigger_y_min: 355, trigger_y_max: 460 }),
      trap("pop_up_spikes", "PopUpRight", 775, 315, 44, 32, { trigger_y_min: 245, trigger_y_max: 345 }),
      trap("falling_spike", "ThornRight", 835, 48, 24, 32, { trigger_distance: 295, pass_through_platforms: false, trigger_y_min: 240, trigger_y_max: 345 }),
      trap("circular_saw", "CircRight", 825, 255, 32, 32, { orbit_radius: 24, orbit_speed: 2.7 }),
    ],
    paranormal: { event_type: "world_tree_heart_finale" },
  },
];

function generateTscn(L) {
  const extPaths = [
    ["Script", "res://scripts/levels/base_level.gd", "1_bl"],
    ["PackedScene", "res://scenes/player/player.tscn", "2_pl"],
    ["PackedScene", "res://scenes/objects/solid_platform.tscn", "3_sp"],
    ["PackedScene", "res://scenes/objects/exit_door.tscn", "4_ed"],
  ];
  const pathToId = new Map();
  let nextId = 5;
  const ensureExt = (type, resPath, suffix) => {
    if (pathToId.has(resPath)) return pathToId.get(resPath);
    const id = `${nextId}_${suffix}`;
    nextId++;
    extPaths.push([type, resPath, id]);
    pathToId.set(resPath, id);
    return id;
  };

  if (L.fake_walls && L.fake_walls.length > 0) {
    ensureExt("PackedScene", "res://scenes/objects/fake_wall.tscn", "fw");
  }
  for (const t of L.traps) {
    ensureExt("PackedScene", TRAP_SCENES[t.type], t.type.slice(0, 2));
  }
  const peId = ensureExt("PackedScene", "res://scenes/objects/paranormal_event.tscn", "pe");

  const lines = [];
  lines.push(`[gd_scene format=3 uid="uid://level${String(L.id).padStart(2, "0")}scn"]`);
  lines.push("");
  for (const [type, resPath, id] of extPaths) {
    lines.push(`[ext_resource type="${type}" path="${resPath}" id="${id}"]`);
  }
  lines.push("");
  lines.push(`[node name="Level${String(L.id).padStart(2, "0")}" type="Node2D"]`);
  lines.push(`script = ExtResource("1_bl")`);
  lines.push(`level_number = ${L.id}`);
  lines.push("");
  lines.push(`[node name="Platforms" type="Node2D" parent="."]`);
  lines.push("");
  lines.push(`[node name="Ceiling" parent="Platforms" instance=ExtResource("3_sp")]`);
  lines.push(`position = Vector2(0, 0)`);
  lines.push(`platform_size = Vector2(960, ${L.ceiling_h})`);
  lines.push("");

  for (const p of L.platforms) {
    lines.push(`[node name="${p.name}" parent="Platforms" instance=ExtResource("3_sp")]`);
    lines.push(`position = Vector2(${p.x}, ${p.y})`);
    lines.push(`platform_size = Vector2(${p.w}, ${p.h})`);
    if (p.one_way) lines.push(`one_way = true`);
    lines.push("");
  }

  if (L.fake_walls) {
    const fwId = pathToId.get("res://scenes/objects/fake_wall.tscn");
    for (const fw of L.fake_walls) {
      lines.push(`[node name="${fw.name}" parent="Platforms" instance=ExtResource("${fwId}")]`);
      lines.push(`position = Vector2(${fw.x}, ${fw.y})`);
      lines.push(`wall_size = Vector2(${fw.w}, ${fw.h})`);
      lines.push(`subtle_crack = ${fw.subtle_crack ? "true" : "false"}`);
      lines.push(`fade_when_inside = ${fw.fade_when_inside ? "true" : "false"}`);
      lines.push("");
    }
  }

  if (L.aux_container) {
    lines.push(`[node name="${L.aux_container.name}" type="Node2D" parent="Platforms"]`);
    lines.push("");
    for (const ap of L.aux_container.platforms) {
      lines.push(`[node name="${ap.name}" parent="Platforms/${L.aux_container.name}" instance=ExtResource("3_sp")]`);
      lines.push(`position = Vector2(${ap.x}, ${ap.y})`);
      lines.push(`platform_size = Vector2(${ap.w}, ${ap.h})`);
      if (ap.one_way) lines.push(`one_way = true`);
      lines.push("");
    }
  }

  lines.push(`[node name="WallLeft" parent="Platforms" instance=ExtResource("3_sp")]`);
  lines.push(`position = Vector2(0, 0)`);
  lines.push(`platform_size = Vector2(32, 540)`);
  lines.push("");
  lines.push(`[node name="WallRight" parent="Platforms" instance=ExtResource("3_sp")]`);
  lines.push(`position = Vector2(928, 0)`);
  lines.push(`platform_size = Vector2(32, 540)`);
  lines.push("");

  lines.push(`[node name="Traps" type="Node2D" parent="."]`);
  lines.push("");
  for (const t of L.traps) {
    const tid = pathToId.get(TRAP_SCENES[t.type]);
    lines.push(`[node name="${t.name}" parent="Traps" instance=ExtResource("${tid}")]`);
    lines.push(`position = Vector2(${t.x}, ${t.y})`);
    // Size mapping identical to LevelArena & Chapter 1 scenes
    if (t.type === "spikes") lines.push(`spike_size = Vector2(${t.w}, ${t.h})`);
    else if (t.type === "pop_up_spikes") {
      lines.push(`spike_width = ${fmtVal(t.w)}`);
      lines.push(`max_spike_height = ${fmtVal(t.h)}`);
    } else if (t.type === "jumping_spikes") {
      lines.push(`spike_width = ${fmtVal(t.w)}`);
      lines.push(`spike_height = ${fmtVal(t.h)}`);
    } else if (t.type === "trap_floor" || t.type === "dodging_platform") {
      lines.push(`platform_size = Vector2(${t.w}, ${t.h})`);
    } else if (t.type === "crusher") {
      lines.push(`crusher_size = Vector2(${t.w}, ${t.h})`);
    } else if (t.type === "falling_ceiling") {
      lines.push(`ceiling_size = Vector2(${t.w}, ${t.h})`);
    } else if (t.type === "spring") {
      lines.push(`spring_size = Vector2(${t.w}, ${t.h})`);
    } else if (t.type === "fake_door") {
      lines.push(`door_size = Vector2(${t.w}, ${t.h})`);
    }

    for (const [k, v] of Object.entries(t.params || {})) {
      if (t.type === "pop_up_spikes" && k === "max_spike_height") continue;
      if (t.type === "jumping_spikes" && k === "spike_height") continue;
      lines.push(`${k} = ${fmtVal(v)}`);
    }
    lines.push("");
  }

  lines.push(`[node name="ExitDoor" parent="." instance=ExtResource("4_ed")]`);
  lines.push(`position = Vector2(${L.door_pos[0]}, ${L.door_pos[1]})`);
  if (L.door_config && L.door_config.runaway) {
    lines.push(`runaway_enabled = true`);
    lines.push(`runaway_offset_x = ${fmtVal(L.door_config.runaway_offset_x || -180)}`);
  }
  lines.push("");
  lines.push(`[node name="Player" parent="." instance=ExtResource("2_pl")]`);
  lines.push(`position = Vector2(${L.player_spawn[0]}, ${L.player_spawn[1]})`);
  lines.push("");
  lines.push(`[node name="Paranormal" type="Node2D" parent="."]`);
  lines.push("");
  lines.push(`[node name="ParanormalEvent" parent="Paranormal" instance=ExtResource("${peId}")]`);
  lines.push(`event_type = "${L.paranormal.event_type}"`);
  if (L.paranormal.trigger_x !== undefined) lines.push(`trigger_x = ${fmtVal(L.paranormal.trigger_x)}`);
  if (L.paranormal.trigger_y !== undefined) lines.push(`trigger_y = ${fmtVal(L.paranormal.trigger_y)}`);
  if (L.paranormal.param_a !== undefined) lines.push(`param_a = ${fmtVal(L.paranormal.param_a)}`);
  if (L.paranormal.param_b !== undefined) lines.push(`param_b = ${fmtVal(L.paranormal.param_b)}`);
  if (L.paranormal.target_node_path) lines.push(`target_node_path = NodePath("${L.paranormal.target_node_path}")`);
  if (L.paranormal.aux_node_path) lines.push(`aux_node_path = NodePath("${L.paranormal.aux_node_path}")`);

  return lines.join("\n") + "\n";
}

function toJsonEntry(L) {
  return {
    id: L.id,
    chapter: L.chapter,
    title: L.title,
    gimmick: L.gimmick,
    player_spawn: L.player_spawn,
    door_pos: L.door_pos,
    door_config: L.door_config || { runaway: false, runaway_offset_x: 0 },
    platforms: L.platforms.map((p) => {
      const obj = { name: p.name, x: p.x, y: p.y, w: p.w, h: p.h };
      if (p.one_way) obj.one_way = true;
      return obj;
    }),
    traps: L.traps.map((t) => {
      const params = { ...(t.params || {}) };
      if (t.type === "pop_up_spikes") params.max_spike_height = t.h;
      if (t.type === "jumping_spikes") params.spike_height = t.h;
      return {
        name: t.name,
        type: t.type,
        x: t.x,
        y: t.y,
        w: t.w,
        h: t.h,
        params,
      };
    }),
  };
}

function validateAll(existingCh1, newLevels) {
  const errors = [];
  const gimmicks = new Set();
  for (const c1 of existingCh1) gimmicks.add(c1.gimmick);

  for (const L of newLevels) {
    if (gimmicks.has(L.gimmick)) errors.push(`L${L.id}: duplicate gimmick '${L.gimmick}'`);
    gimmicks.add(L.gimmick);
    if (L.gimmick !== L.paranormal.event_type) errors.push(`L${L.id}: gimmick mismatch`);

    for (const t of L.traps) {
      if (FORBIDDEN_TRAPS.has(t.type)) errors.push(`L${L.id}: forbidden trap '${t.type}'`);
      if (!TRAP_SCENES[t.type]) errors.push(`L${L.id}: unknown trap '${t.type}'`);
      if (t.params && t.params.fakeout_first === true) errors.push(`L${L.id}: ${t.name} has fakeout_first=true`);
      if (t.type === "crusher") {
        if (t.y !== 6 || t.y + t.h !== L.ceiling_h) {
          errors.push(`L${L.id}: crusher ${t.name} not flush in ceiling (y=${t.y}, h=${t.h}, ceil=${L.ceiling_h})`);
        }
      }
    }
    for (const fw of L.fake_walls || []) {
      if (fw.subtle_crack !== false) errors.push(`L${L.id}: FakeWall ${fw.name} has subtle_crack != false`);
    }

    // Spawn & door must stand cleanly on a platform
    const hasSupport = ([px, py]) =>
      L.platforms.some((p) => px >= p.x && px <= p.x + p.w && Math.abs(py - p.y) <= 2);
    if (!hasSupport(L.player_spawn)) errors.push(`L${L.id}: player_spawn ${L.player_spawn} has no floor support`);
    if (!hasSupport(L.door_pos)) errors.push(`L${L.id}: door_pos ${L.door_pos} has no floor support`);

    // Prevent MovingSaw from overlapping ExitDoor or player_spawn
    for (const t of L.traps) {
      if (t.type === "moving_saw") {
        const r = (t.params && t.params.radius) || 16;
        const ax = ((t.params && t.params.patrol_axis) || [1, 0])[0];
        const dist = (t.params && t.params.patrol_distance) || 0;
        const x1 = Math.min(t.x, t.x + ax * dist);
        const x2 = Math.max(t.x, t.x + ax * dist);
        if (L.door_pos[0] >= x1 - r - 18 && L.door_pos[0] <= x2 + r + 18 && Math.abs(L.door_pos[1] - (t.y + r)) < 35) {
          errors.push(`L${L.id}: MovingSaw ${t.name} patrols into ExitDoor!`);
        }
        if (L.player_spawn[0] >= x1 - r - 18 && L.player_spawn[0] <= x2 + r + 18 && Math.abs(L.player_spawn[1] - (t.y + r)) < 35) {
          errors.push(`L${L.id}: MovingSaw ${t.name} patrols into player_spawn!`);
        }
      }
    }

    // Prevent blocked one-way climb steps directly beneath solid non-one-way ceilings
    const allPlats = [...L.platforms, ...((L.aux_container && L.aux_container.platforms) || [])];
    for (const p of allPlats) {
      if (!p.one_way) continue;
      for (const above of L.platforms) {
        if (above === p || above.one_way) continue;
        if (above.y < p.y && p.y - above.y <= 110) {
          const ovL = Math.max(p.x, above.x);
          const ovR = Math.min(p.x + p.w, above.x + above.w);
          if (ovR > ovL) {
            const stick = Math.max(Math.max(0, above.x - p.x), Math.max(0, p.x + p.w - (above.x + above.w)));
            const headroom = p.y - (above.y + above.h);
            // Allow if it's purely a side-step to a different platform with >= 70px headroom (e.g. L29 LeftStep -> MidDeck)
            if (headroom < 70 && stick < 26) {
              errors.push(`L${L.id}: one-way ${p.name} blocked under solid ${above.name} (stick=${stick}, headroom=${headroom})`);
            }
          }
        }
      }
    }
  }

  if (gimmicks.size !== 60) errors.push(`Expected 60 unique gimmicks across 1..60, got ${gimmicks.size}`);
  return errors;
}

function main() {
  const currentJson = JSON.parse(fs.readFileSync(LEVELS_JSON_PATH, "utf8"));
  const ch1 = currentJson.slice(0, 20);
  if (ch1.length !== 20 || ch1[0].id !== 1 || ch1[19].id !== 20) {
    throw new Error("Expected first 20 entries of data/levels.json to be Chapter 1 (1..20)");
  }

  const allNew = [...CHAPTER_2, ...CHAPTER_3];
  const errs = validateAll(ch1, allNew);
  if (errs.length > 0) {
    console.error("VALIDATION FAILED:\n" + errs.join("\n"));
    process.exit(1);
  }

  // Write .tscn files 21..60
  for (const L of allNew) {
    const outPath = path.join(SCENES_DIR, `level_${String(L.id).padStart(2, "0")}.tscn`);
    fs.writeFileSync(outPath, generateTscn(L), "utf8");
  }

  // Update data/levels.json keeping entries 1..20 untouched
  const merged = [...ch1, ...allNew.map(toJsonEntry)];
  fs.writeFileSync(LEVELS_JSON_PATH, JSON.stringify(merged, null, 2) + "\n", "utf8");

  console.log(`SUCCESS: Generated ${allNew.length} scenes (level_21..level_60.tscn) & updated data/levels.json (60 unique paranormal events).`);
}

main();
