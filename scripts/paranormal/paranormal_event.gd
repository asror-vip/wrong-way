extends Node2D
class_name ParanormalEvent

const ParanormalArt := preload("res://scripts/paranormal/paranormal_art.gd")
const FrostArt := preload("res://scripts/paranormal/paranormal_art_frost.gd")
const ForestArt := preload("res://scripts/paranormal/paranormal_art_forest.gd")

@export var event_type: String = ""
@export var trigger_x: float = 0.0
@export var trigger_y: float = 0.0
@export var trigger_radius: float = 120.0
@export var param_a: float = 0.0
@export var param_b: float = 0.0
@export var target_node_path: NodePath = NodePath("")
@export var aux_node_path: NodePath = NodePath("")
@export var hint_text: String = ""

var level_ref: Node = null
var player_ref: Node2D = null
var exit_door_ref: Node2D = null

var level_deaths_seen: int = 0
var triggered: bool = false
var timer: float = 0.0
var _fx_timer: float = 0.0

var _bg_layer: Node2D = null
var _mid_layer: Node2D = null
var _fg_layer: Node2D = null
var _uses_bg: bool = false
var _uses_mid: bool = false
var _uses_fg: bool = false

# Shared reusable states across unique event types
var _footprints: Array[Dictionary] = []
var _step_accum: float = 0.0
var _pendulum_angle: float = 0.42
var _eye_blink: float = 0.0
var _eye_idle_blink_cd: float = 3.8
var _eye_look: Vector2 = Vector2.ZERO
var _eye_dilation: float = 0.35
var _eye_alert: float = 0.0
var _eye_rect: ColorRect = null
var _eye_mat: ShaderMaterial = null
var _doppel_dissolve: float = 0.0
var _doppel_dir: float = -1.0
var _blackout_alpha: float = 0.0
var _target_orig_pos: Vector2 = Vector2.ZERO
var _target_orig_cached: bool = false
var _wind_active: bool = false
var _ghost_stones: Array[Dictionary] = []
var _ghost_cycle: float = 0.0
var _ghost_pos: Vector2 = Vector2(90.0, 380.0)
var _ghost_trail: Array[Vector2] = []
var _ghost_trail_accum: float = 0.0
var _fake_door_area: Area2D = null
var _fake_win_phase: int = 0
var _fake_win_timer: float = 0.0
var _dark_rect: ColorRect = null
var _dark_mat: ShaderMaterial = null
var _lightning_alpha: float = 0.95
var _lightning_cycle: float = 0.0
var _lightning_bolt_seed: int = 1
var _cam_tilt_rad: float = 0.0
var _slowmo_active: bool = false
var _slowmo_cycle: float = 0.0
var _slowmo_pulse_r: float = 0.0
var _clock_angle: float = 0.0
var _mist_rect: ColorRect = null
var _mist_mat: ShaderMaterial = null
var _tide_y: float = 540.0
var _tide_started: bool = false
var _monolith_cracked: bool = false
var _monolith_flash: float = 0.0
var _knock_ring: float = 0.0
var _knock_cycle: float = 0.0
var _wrap_shimmer_x: float = 0.0
var _wrap_shimmer_y: float = 340.0
var _chandelier_bar: AnimatableBody2D = null

# Chapter 2 (Frost Peak, L21-L40) & Chapter 3 (Emerald Woods, L41-L60) states
var _frost_rect: ColorRect = null
var _frost_mat: ShaderMaterial = null
var _wisp_fog_rect: ColorRect = null
var _wisp_fog_mat: ShaderMaterial = null
var _breath_puffs: Array[Dictionary] = []
var _chime_ring: float = 0.0
var _chime_sway: float = 0.0
var _ice_sparks: Array[Dictionary] = []
var _compass_angle: float = 0.0
var _aurora_cycle: float = 0.0
var _aurora_cyan: bool = true
var _aurora_plats: Array[Dictionary] = []
var _snow_wave_x: float = 806.0
var _snow_wave_active: bool = false
var _snow_wave_delay: float = 0.0
var _mirror_twin_pos: Vector2 = Vector2(480.0, 380.0)
var _lantern_positions: Array[Vector2] = []
var _stomp_count: int = 0
var _was_grounded_ev: bool = true
var _shock_pos: Vector2 = Vector2.ZERO
var _shock_r: float = 0.0
var _shock_a: float = 0.0
var _blizzard_cycle: float = 0.0
var _blizzard_wind_dir: float = 1.0
var _blizzard_alpha: float = 0.0
var _dash_pads: Array[Dictionary] = []
var _prev_player_dashing: bool = false
var _bell_cycle: float = 0.0
var _bell_ring_r: float = 0.0
var _bell_ring_a: float = 0.0
var _bell_swing: float = 0.0
var _bell_bounced_this_toll: bool = false
var _permafrost_patches: Array[Dictionary] = []
var _last_perma_x: float = -999.0
var _cairn_stones: Array[Dictionary] = []
var _cairn_reveal: float = 0.0
var _cryo_heart_cycle: float = 0.0
var _cryo_surge: bool = false
var _cryo_pulse_r: float = 0.0
var _ice_panes: Array[Dictionary] = []
var _avalanche_x: float = -40.0
var _avalanche_started: bool = false
var _crown_flash: float = 0.0
var _vine_segments: Array[Dictionary] = []
var _totem_cycle: float = 0.0
var _totem_mask: int = 0
var _mushroom_caps: Array[Dictionary] = []
var _owl_cycle: float = 0.0
var _owl_open: bool = false
var _owl_warn: float = 0.0
var _owl_sweep_x: float = 480.0
var _sap_rune_a_lit: bool = false
var _sap_rune_b_lit: bool = false
var _pollen_motes: Array[Dictionary] = []
var _pollen_floating: bool = false
var _stag_cycle: float = 0.0
var _stag_pos: Vector2 = Vector2(140.0, 235.0)
var _stag_pads: Array[Dictionary] = []
var _eclipse_beams: Array[float] = [210.0, 400.0, 590.0, 770.0]
var _fairy_charge: float = 0.0
var _fairy_warp_fx: float = 0.0
var _fairy_cd: float = 0.0
var _willow_perches: Array[Dictionary] = []
var _cicada_raft: AnimatableBody2D = null
var _cicada_pos: Vector2 = Vector2(690.0, 235.0)
var _leyline_above: bool = false
var _stump_cycle: float = 0.0
var _stump_ring: int = 1
var _stump_surge: bool = false
var _stump_steps: Array[Dictionary] = []
var _wisp_pos: Vector2 = Vector2(220.0, 340.0)
var _bamboo_stalks: Array[Dictionary] = []
var _bamboo_gust_pos: Vector2 = Vector2.ZERO
var _bamboo_gust_life: float = 0.0
var _bamboo_gust_dir: float = 1.0
var _bamboo_boost_timer: float = 0.0
var _tremor_cycle: float = 0.0
var _tremor_phase: int = 0
var _tremor_fx: float = 0.0
var _tremor_slabs: Array[Dictionary] = []
var _overgrowth_y: float = 48.0
var _overgrowth_started: bool = false
var _wt_cycle: float = 0.0
var _wt_phase: int = 0
var _wt_pads: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("paranormal")
	_bg_layer = Node2D.new()
	_bg_layer.name = "BgLayer"
	_bg_layer.z_index = -3
	_bg_layer.draw.connect(_draw_bg)
	add_child(_bg_layer)

	_mid_layer = Node2D.new()
	_mid_layer.name = "MidLayer"
	_mid_layer.z_index = 3
	_mid_layer.draw.connect(_draw_mid)
	add_child(_mid_layer)

	_fg_layer = Node2D.new()
	_fg_layer.name = "FgLayer"
	_fg_layer.z_index = 24
	_fg_layer.draw.connect(_draw_fg)
	add_child(_fg_layer)

	_resolve_refs()
	_setup_event()
	reset_event()

func _resolve_refs() -> void:
	if level_ref == null:
		level_ref = get_parent().get_parent() if get_parent() else null
	if player_ref == null and is_inside_tree():
		player_ref = get_tree().get_first_node_in_group("player") as Node2D
	if exit_door_ref == null and level_ref:
		exit_door_ref = level_ref.get_node_or_null("ExitDoor") as Node2D

func _get_target_node() -> Node:
	if target_node_path.is_empty():
		return null
	var n := get_node_or_null(target_node_path)
	if n == null and level_ref:
		n = level_ref.get_node_or_null(target_node_path)
	return n

func _get_aux_node() -> Node:
	if aux_node_path.is_empty():
		return null
	var n := get_node_or_null(aux_node_path)
	if n == null and level_ref:
		n = level_ref.get_node_or_null(aux_node_path)
	return n

func _get_current_chapter() -> int:
	if is_inside_tree():
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("get_current_chapter"):
			return int(gm.get_current_chapter())
	return 1

func _set_subtree_collision(root: Node, enabled: bool) -> void:
	if root == null:
		return
	if root is CollisionShape2D:
		root.set_deferred("disabled", not enabled)
	for c in root.get_children():
		_set_subtree_collision(c, enabled)

func _make_static_oneway(body_name: String, pos: Vector2, sz: Vector2, enabled: bool = true) -> Dictionary:
	var body := StaticBody2D.new()
	body.name = body_name
	body.collision_layer = 1
	body.collision_mask = 2
	body.position = pos
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = sz
	col.shape = rect
	col.position = sz * 0.5
	col.one_way_collision = true
	col.disabled = not enabled
	body.add_child(col)
	add_child(body)
	return {"body": body, "col": col, "pos": pos, "size": sz, "solid": enabled}

func _make_animatable_plat(body_name: String, pos: Vector2, sz: Vector2, one_way: bool = true) -> Dictionary:
	var body := AnimatableBody2D.new()
	body.name = body_name
	body.sync_to_physics = true
	body.collision_layer = 1
	body.collision_mask = 2
	body.position = pos
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = sz
	col.shape = rect
	col.position = sz * 0.5
	col.one_way_collision = one_way
	body.add_child(col)
	add_child(body)
	return {"body": body, "col": col, "pos": pos, "orig_pos": pos, "size": sz}

func _setup_event() -> void:
	var tgt := _get_target_node()
	if tgt and tgt is Node2D and not _target_orig_cached:
		_target_orig_pos = (tgt as Node2D).position
		_target_orig_cached = true

	_uses_bg = event_type in [
		"frozen_pendulum", "death_tally_wall", "watching_eye", "betraying_arrow",
		"shadow_doppelganger", "blackout_swap", "mirror_ghost_bridge", "low_gravity_drift",
		"lightning_darkness", "room_tilt_vertigo", "time_heartbeat_slowmo", "reality_awakening_finale",
		# Chapter 2 (Frost Peak)
		"icicle_chime_omen", "frozen_compass_needle", "aurora_veil_shift", "frozen_mirror_twin",
		"frostbite_lantern_pulse", "shattering_glacier_echo", "cryo_updraft_column",
		"frost_bell_shockwave", "glacial_prism_split", "sky_cairn_airborne",
		"cryo_heartbeat_surge", "frost_crown_finale",
		# Chapter 3 (Emerald Woods)
		"firefly_path_decoy", "whispering_totem_curse", "owl_sentinel_gaze",
		"phantom_stag_guide", "moss_leyline_gravity", "ancient_stump_rings",
		"spirit_bamboo_gust", "root_tremor_slabs", "world_tree_heart_finale",
	]
	_uses_mid = event_type in [
		"phantom_footprints", "attic_knock", "screen_wrap_portal",
		"twin_doors_truth", "reality_awakening_finale",
		# Chapter 2 (Frost Peak)
		"frost_breath_echo", "black_ice_glide", "frozen_dash_platforms",
		"permafrost_creep", "shattering_ice_panes",
		# Chapter 3 (Emerald Woods)
		"living_vine_bridge", "moonlit_pond_inversion", "spore_cloud_bounce",
		"root_labyrinth_shift", "pollen_dream_drift", "fairy_ring_portal",
		"cicada_swarm_raft", "wisp_lantern_escort",
	]
	_uses_fg = event_type in [
		"frozen_pendulum", "blackout_swap", "betraying_arrow", "haunted_gust",
		"fake_win_glitch", "room_tilt_vertigo", "time_heartbeat_slowmo",
		"mind_flip_mist", "rising_shadow_tide", "reality_awakening_finale",
		# Chapter 2 (Frost Peak)
		"frost_breath_echo", "snowdrift_bury", "blizzard_whiteout_gust",
		"avalanche_wall_chase", "frost_crown_finale",
		# Chapter 3 (Emerald Woods)
		"canopy_eclipse_dark", "weeping_willow_curtain", "wisp_lantern_escort",
		"overgrowth_ceiling_vines",
	]

	match event_type:
		"watching_eye":
			if _eye_rect == null:
				_eye_rect = ColorRect.new()
				_eye_rect.name = "WatchingEyeShader"
				_eye_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_eye_rect.show_behind_parent = true
				_eye_rect.position = Vector2(360.0, 103.0)
				_eye_rect.size = Vector2(240.0, 150.0)
				_eye_mat = ShaderMaterial.new()
				_eye_mat.shader = ParanormalArt.get_watching_eye_shader()
				_eye_rect.material = _eye_mat
				_bg_layer.add_child(_eye_rect)
		"mirror_ghost_bridge":
			if _ghost_stones.is_empty():
				var specs := [
					{"pos": Vector2(95, 285), "size": Vector2(72, 16)},
					{"pos": Vector2(275, 205), "size": Vector2(76, 16)},
					{"pos": Vector2(475, 205), "size": Vector2(76, 16)},
					{"pos": Vector2(675, 205), "size": Vector2(76, 16)},
				]
				for i in range(specs.size()):
					var s: Dictionary = specs[i]
					var body := StaticBody2D.new()
					body.name = "GhostStone_%d" % i
					body.collision_layer = 1
					body.collision_mask = 2
					body.position = s["pos"]
					var col := CollisionShape2D.new()
					var rect := RectangleShape2D.new()
					rect.size = s["size"]
					col.shape = rect
					col.position = s["size"] * 0.5
					col.one_way_collision = true
					body.add_child(col)
					add_child(body)
					_ghost_stones.append({"pos": s["pos"], "size": s["size"], "glow": 0.0})
		"room_tilt_vertigo":
			if _chandelier_bar == null:
				_chandelier_bar = AnimatableBody2D.new()
				_chandelier_bar.name = "ChandelierBar"
				_chandelier_bar.sync_to_physics = false
				_chandelier_bar.collision_layer = 1
				_chandelier_bar.collision_mask = 2
				_chandelier_bar.position = Vector2(428.0, 174.0)
				var c_col := CollisionShape2D.new()
				var c_rect := RectangleShape2D.new()
				c_rect.size = Vector2(104.0, 10.0)
				c_col.shape = c_rect
				c_col.position = Vector2(52.0, 5.0)
				c_col.one_way_collision = true
				_chandelier_bar.add_child(c_col)
				add_child(_chandelier_bar)
		"fake_win_glitch":
			if _fake_door_area == null:
				_fake_door_area = Area2D.new()
				_fake_door_area.name = "FakeWinDoor"
				_fake_door_area.collision_layer = 8
				_fake_door_area.collision_mask = 2
				_fake_door_area.position = Vector2(trigger_x, trigger_y)
				var col := CollisionShape2D.new()
				var rect := RectangleShape2D.new()
				rect.size = Vector2(34, 62)
				col.shape = rect
				col.position = Vector2(0, -31)
				_fake_door_area.add_child(col)
				_fake_door_area.draw.connect(_draw_fake_win_door)
				_fake_door_area.body_entered.connect(_on_fake_win_entered)
				add_child(_fake_door_area)
		"lightning_darkness":
			if _dark_rect == null:
				_dark_rect = ColorRect.new()
				_dark_rect.name = "DarknessMask"
				_dark_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_dark_rect.show_behind_parent = true
				_dark_rect.position = Vector2(-420.0, -280.0)
				_dark_rect.size = Vector2(1800.0, 1100.0)
				_dark_mat = ShaderMaterial.new()
				_dark_mat.shader = ParanormalArt.get_lantern_darkness_shader()
				_dark_mat.set_shader_parameter("local_size", Vector2(1800.0, 1100.0))
				_dark_rect.material = _dark_mat
				_fg_layer.add_child(_dark_rect)
		"mind_flip_mist":
			if _mist_rect == null:
				var inv_y := param_a if param_a > 0.0 else 352.0
				var mist_top := inv_y - 18.0
				var mist_h := maxf(48.0, 412.0 - mist_top)
				_mist_rect = ColorRect.new()
				_mist_rect.name = "MindFlipMistShader"
				_mist_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_mist_rect.show_behind_parent = true
				_mist_rect.position = Vector2(32.0, mist_top)
				_mist_rect.size = Vector2(896.0, mist_h)
				_mist_mat = ShaderMaterial.new()
				_mist_mat.shader = ParanormalArt.get_mind_flip_mist_shader()
				_mist_mat.set_shader_parameter("local_size", Vector2(896.0, mist_h))
				_mist_rect.material = _mist_mat
				_fg_layer.add_child(_mist_rect)
		# --- Chapter 2 (Frost Peak) Dynamic Setup ---
		"frost_breath_echo":
			if _frost_rect == null:
				_frost_rect = ColorRect.new()
				_frost_rect.name = "FrostVignetteShader"
				_frost_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_frost_rect.show_behind_parent = true
				_frost_rect.position = Vector2(32.0, 48.0)
				_frost_rect.size = Vector2(896.0, 492.0)
				_frost_mat = ShaderMaterial.new()
				_frost_mat.shader = FrostArt.get_frost_vignette_shader()
				_frost_rect.material = _frost_mat
				_fg_layer.add_child(_frost_rect)
		"aurora_veil_shift":
			if _aurora_plats.is_empty():
				var aspecs := [
					{"pos": Vector2(248, 370), "size": Vector2(146, 18), "cyan": true},
					{"pos": Vector2(566, 370), "size": Vector2(146, 18), "cyan": false},
					{"pos": Vector2(205, 290), "size": Vector2(96, 16), "cyan": true},
					{"pos": Vector2(385, 222), "size": Vector2(190, 16), "cyan": true},
					{"pos": Vector2(655, 290), "size": Vector2(96, 16), "cyan": false},
				]
				for i in range(aspecs.size()):
					var sp: Dictionary = aspecs[i]
					var d := _make_static_oneway("AuroraPlat_%d" % i, sp["pos"], sp["size"], sp["cyan"])
					d["cyan_phase"] = sp["cyan"]
					_aurora_plats.append(d)
		"frostbite_lantern_pulse":
			if _lantern_positions.is_empty():
				_lantern_positions = [Vector2(245.0, 310.0), Vector2(480.0, 252.0), Vector2(715.0, 310.0)]
				for i in range(_lantern_positions.size()):
					var lp: Vector2 = _lantern_positions[i]
					_make_static_oneway("LanternBracket_%d" % i, Vector2(lp.x - 44.0, lp.y - 4.0), Vector2(88.0, 10.0), true)
		"frozen_dash_platforms":
			if _dash_pads.is_empty():
				for i in range(2):
					var d := _make_static_oneway("DashIcePad_%d" % i, Vector2(-500, -500), Vector2(68, 14), false)
					d["life"] = 0.0
					_dash_pads.append(d)
		"sky_cairn_airborne":
			if _cairn_stones.is_empty():
				var cspecs := [
					{"pos": Vector2(215, 300), "size": Vector2(82, 16)},
					{"pos": Vector2(435, 240), "size": Vector2(90, 16)},
					{"pos": Vector2(655, 300), "size": Vector2(82, 16)},
				]
				for i in range(cspecs.size()):
					_cairn_stones.append(_make_static_oneway("SkyCairnStone_%d" % i, cspecs[i]["pos"], cspecs[i]["size"], true))
		"shattering_ice_panes":
			if _ice_panes.is_empty():
				for i in range(4):
					var px := 230.0 + float(i) * 126.0
					var d := _make_static_oneway("IcePane_%d" % i, Vector2(px, 250.0), Vector2(114.0, 18.0), true)
					d["state"] = 0
					d["crack_timer"] = 0.0
					_ice_panes.append(d)
		# --- Chapter 3 (Emerald Woods) Dynamic Setup ---
		"living_vine_bridge":
			if _vine_segments.is_empty():
				var vspecs := [
					{"pos": Vector2(252, 340), "size": Vector2(132, 16), "high": false},
					{"pos": Vector2(414, 340), "size": Vector2(132, 16), "high": false},
					{"pos": Vector2(576, 340), "size": Vector2(132, 16), "high": false},
					{"pos": Vector2(252, 252), "size": Vector2(456, 16), "high": true},
				]
				for i in range(vspecs.size()):
					var d := _make_static_oneway("VineSeg_%d" % i, vspecs[i]["pos"], vspecs[i]["size"], false)
					d["grow"] = 0.0
					d["active_t"] = 0.0
					d["wilting"] = false
					d["high"] = vspecs[i]["high"]
					_vine_segments.append(d)
		"spore_cloud_bounce":
			if _mushroom_caps.is_empty():
				_mushroom_caps = [
					{"pos": Vector2(875, 430), "w": 66.0, "vy": -820.0, "squash": 0.0, "cd": 0.0, "secret": false},
					{"pos": Vector2(58, 430), "w": 46.0, "vy": -670.0, "squash": 0.0, "cd": 0.0, "secret": true},
					{"pos": Vector2(68, 315), "w": 46.0, "vy": -700.0, "squash": 0.0, "cd": 0.0, "secret": true},
				]
		"phantom_stag_guide":
			if _stag_pads.is_empty():
				var sps := [
					{"pos": Vector2(248, 282), "size": Vector2(96, 16)},
					{"pos": Vector2(432, 245), "size": Vector2(96, 16)},
					{"pos": Vector2(616, 282), "size": Vector2(96, 16)},
				]
				for i in range(sps.size()):
					var d := _make_static_oneway("StagPad_%d" % i, sps[i]["pos"], sps[i]["size"], false)
					d["life"] = 0.0
					_stag_pads.append(d)
		"weeping_willow_curtain":
			if _willow_perches.is_empty():
				var wps := [
					{"pos": Vector2(125, 235), "size": Vector2(210, 16)},
					{"pos": Vector2(395, 235), "size": Vector2(210, 16)},
					{"pos": Vector2(655, 235), "size": Vector2(165, 16)},
				]
				for i in range(wps.size()):
					_willow_perches.append(_make_static_oneway("WillowPerch_%d" % i, wps[i]["pos"], wps[i]["size"], true))
		"cicada_swarm_raft":
			if _cicada_raft == null:
				var d := _make_animatable_plat("CicadaRaft", Vector2(650, 238), Vector2(116, 16), true)
				_cicada_raft = d["body"]
				_cicada_pos = Vector2(650, 238)
		"ancient_stump_rings":
			if _stump_steps.is_empty():
				var rspecs := [
					{"pos": Vector2(42, 358), "size": Vector2(82, 16)},
					{"pos": Vector2(115, 284), "size": Vector2(82, 16)},
				]
				for i in range(rspecs.size()):
					_stump_steps.append(_make_static_oneway("StumpStep_%d" % i, rspecs[i]["pos"], rspecs[i]["size"], false))
		"wisp_lantern_escort":
			if _wisp_fog_rect == null:
				_wisp_fog_rect = ColorRect.new()
				_wisp_fog_rect.name = "WispFogMask"
				_wisp_fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_wisp_fog_rect.show_behind_parent = true
				_wisp_fog_rect.position = Vector2(-420.0, -280.0)
				_wisp_fog_rect.size = Vector2(1800.0, 1100.0)
				_wisp_fog_mat = ShaderMaterial.new()
				_wisp_fog_mat.shader = ForestArt.get_wisp_fog_shader()
				_wisp_fog_mat.set_shader_parameter("local_size", Vector2(1800.0, 1100.0))
				_wisp_fog_rect.material = _wisp_fog_mat
				_fg_layer.add_child(_wisp_fog_rect)
		"spirit_bamboo_gust":
			if _bamboo_stalks.is_empty():
				_bamboo_stalks = [
					{"base": Vector2(225, 420), "h": 145.0, "bend": 0.0},
					{"base": Vector2(470, 350), "h": 135.0, "bend": 0.0},
					{"base": Vector2(755, 275), "h": 120.0, "bend": 0.0},
				]
		"root_tremor_slabs":
			if _tremor_slabs.is_empty():
				_tremor_slabs = [
					_make_animatable_plat("TremorSlabLow", Vector2(275, 385), Vector2(130, 20), false),
					_make_animatable_plat("TremorSlabHigh", Vector2(360, 235), Vector2(180, 18), true),
				]
		"world_tree_heart_finale":
			if _wt_pads.is_empty():
				var wts := [
					{"pos": Vector2(255, 250), "size": Vector2(96, 16)},
					{"pos": Vector2(609, 250), "size": Vector2(96, 16)},
				]
				for i in range(wts.size()):
					_wt_pads.append(_make_static_oneway("WorldTreePad_%d" % i, wts[i]["pos"], wts[i]["size"], true))

func on_player_died() -> void:
	level_deaths_seen += 1
	cleanup_global_effects()

func cleanup_global_effects() -> void:
	Engine.time_scale = 1.0
	_slowmo_active = false
	_cam_tilt_rad = 0.0
	if is_inside_tree() and get_tree().current_scene:
		var cam := get_tree().current_scene.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.rotation = 0.0
			cam.ignore_rotation = true

func reset_event() -> void:
	_resolve_refs()
	cleanup_global_effects()
	triggered = false
	timer = 0.0
	_fx_timer = 0.0
	_footprints.clear()
	_step_accum = 0.0
	_pendulum_angle = 0.42
	_eye_blink = 0.0
	_eye_idle_blink_cd = 3.8
	_eye_look = Vector2.ZERO
	_eye_dilation = 0.35
	_eye_alert = 0.0
	_doppel_dissolve = 0.0
	_doppel_dir = -1.0
	_blackout_alpha = 0.0
	_wind_active = false
	_ghost_cycle = 0.0
	_ghost_trail.clear()
	_ghost_trail_accum = 0.0
	_fake_win_phase = 0
	_fake_win_timer = 0.0
	_lightning_alpha = 0.95
	_lightning_cycle = 0.0
	_lightning_bolt_seed = 1
	_cam_tilt_rad = 0.0
	_slowmo_cycle = 0.0
	_slowmo_pulse_r = 0.0
	_clock_angle = 0.0
	_tide_y = 540.0
	_tide_started = false
	_monolith_cracked = false
	_monolith_flash = 0.0
	_knock_ring = 0.0
	_knock_cycle = 0.0

	# Reset Chapter 2 & 3 states cleanly
	_breath_puffs.clear()
	_chime_ring = 0.0
	_chime_sway = 0.0
	_ice_sparks.clear()
	_compass_angle = 0.0
	_aurora_cycle = 0.0
	_aurora_cyan = true
	_snow_wave_x = 806.0
	_snow_wave_active = false
	_snow_wave_delay = 0.0
	_mirror_twin_pos = Vector2(480.0, 380.0)
	_stomp_count = 0
	_was_grounded_ev = true
	_shock_r = 0.0
	_shock_a = 0.0
	_blizzard_cycle = 0.0
	_blizzard_wind_dir = 1.0
	_blizzard_alpha = 0.0
	_prev_player_dashing = false
	_bell_cycle = 0.0
	_bell_ring_r = 0.0
	_bell_ring_a = 0.0
	_bell_swing = 0.0
	_bell_bounced_this_toll = false
	_permafrost_patches.clear()
	_last_perma_x = -999.0
	_cairn_reveal = 0.0
	_cryo_heart_cycle = 0.0
	_cryo_surge = false
	_cryo_pulse_r = 0.0
	_avalanche_x = -40.0
	_avalanche_started = false
	_crown_flash = 0.0
	_totem_cycle = 0.0
	_totem_mask = 0
	_owl_cycle = 0.0
	_owl_open = false
	_owl_warn = 0.0
	_owl_sweep_x = 480.0
	_sap_rune_a_lit = false
	_sap_rune_b_lit = false
	_pollen_motes.clear()
	_pollen_floating = false
	_stag_cycle = 0.0
	_stag_pos = Vector2(140.0, 235.0)
	_fairy_charge = 0.0
	_fairy_warp_fx = 0.0
	_fairy_cd = 0.0
	_cicada_pos = Vector2(650.0, 238.0)
	_leyline_above = false
	_stump_cycle = 0.0
	_stump_ring = 1
	_stump_surge = false
	_wisp_pos = Vector2(220.0, 340.0)
	_bamboo_gust_life = 0.0
	_bamboo_boost_timer = 0.0
	_tremor_cycle = 0.0
	_tremor_phase = 0
	_tremor_fx = 0.0
	_overgrowth_y = 48.0
	_overgrowth_started = false
	_wt_cycle = 0.0
	_wt_phase = 0

	var tgt := _get_target_node()
	if tgt and tgt is Node2D and _target_orig_cached:
		(tgt as Node2D).position = _target_orig_pos

	var aux := _get_aux_node()
	match event_type:
		"blackout_swap", "reality_awakening_finale", "shattering_glacier_echo", "glacial_prism_split", "root_labyrinth_shift":
			if aux and aux is CanvasItem:
				(aux as CanvasItem).visible = false
				_set_subtree_collision(aux, false)
		"fake_win_glitch":
			if player_ref and is_instance_valid(player_ref) and "is_entering_door" in player_ref:
				player_ref.is_entering_door = false
			if exit_door_ref:
				exit_door_ref.visible = false
				exit_door_ref.set_deferred("monitoring", false)
			if _fake_door_area:
				_fake_door_area.visible = true
				_fake_door_area.set_deferred("monitoring", true)
				_fake_door_area.queue_redraw()
			if aux and aux is CanvasItem:
				(aux as CanvasItem).visible = true
				_set_subtree_collision(aux, true)
		"screen_wrap_portal":
			if player_ref and "screen_wrap_enabled" in player_ref:
				player_ref.screen_wrap_enabled = true
				player_ref.screen_wrap_y_min = param_a if param_a > 0.0 else 255.0
				player_ref.screen_wrap_y_max = param_b if param_b > 0.0 else 425.0
				if player_ref.has_signal("screen_wrapped") and not player_ref.screen_wrapped.is_connected(_on_player_screen_wrapped):
					player_ref.screen_wrapped.connect(_on_player_screen_wrapped)
		"mirror_ghost_bridge":
			for s in _ghost_stones:
				s["glow"] = 0.0
		"room_tilt_vertigo":
			if _chandelier_bar != null and is_instance_valid(_chandelier_bar):
				_chandelier_bar.position = Vector2(428.0, 174.0)
		"aurora_veil_shift":
			for ap in _aurora_plats:
				var is_c: bool = bool(ap["cyan_phase"])
				ap["solid"] = is_c
				(ap["col"] as CollisionShape2D).disabled = not is_c
		"frozen_dash_platforms":
			for dp in _dash_pads:
				dp["life"] = 0.0
				dp["pos"] = Vector2(-500, -500)
				(dp["body"] as StaticBody2D).position = Vector2(-500, -500)
				(dp["col"] as CollisionShape2D).disabled = true
		"shattering_ice_panes":
			for pn in _ice_panes:
				pn["state"] = 0
				pn["crack_timer"] = 0.0
				(pn["col"] as CollisionShape2D).disabled = false
		"frost_crown_finale":
			if exit_door_ref:
				exit_door_ref.visible = true
				exit_door_ref.set_deferred("monitoring", false)
		"living_vine_bridge":
			for vs in _vine_segments:
				vs["grow"] = 0.0
				vs["active_t"] = 0.0
				vs["wilting"] = false
				(vs["col"] as CollisionShape2D).disabled = true
		"spore_cloud_bounce":
			for mc in _mushroom_caps:
				mc["squash"] = 0.0
				mc["cd"] = 0.0
		"phantom_stag_guide":
			for sp in _stag_pads:
				sp["life"] = 0.0
				(sp["col"] as CollisionShape2D).disabled = true
		"cicada_swarm_raft":
			if _cicada_raft and is_instance_valid(_cicada_raft):
				_cicada_raft.position = _cicada_pos
		"ancient_stump_rings":
			for ss in _stump_steps:
				ss["solid"] = false
				(ss["col"] as CollisionShape2D).disabled = true
		"spirit_bamboo_gust":
			for bs in _bamboo_stalks:
				bs["bend"] = 0.0
		"root_tremor_slabs":
			for sl in _tremor_slabs:
				sl["pos"] = sl["orig_pos"]
				(sl["body"] as AnimatableBody2D).position = sl["orig_pos"]
		"world_tree_heart_finale":
			for wp in _wt_pads:
				wp["solid"] = true
				(wp["col"] as CollisionShape2D).disabled = false

	_sync_shader_params()
	_queue_active_redraws()

func _queue_active_redraws() -> void:
	if _uses_bg and _bg_layer:
		_bg_layer.queue_redraw()
	if _uses_mid and _mid_layer:
		_mid_layer.queue_redraw()
	if _uses_fg and _fg_layer:
		_fg_layer.queue_redraw()

func _sync_shader_params() -> void:
	if _eye_mat:
		_eye_mat.set_shader_parameter("look_offset", _eye_look / 11.0)
		_eye_mat.set_shader_parameter("blink", _eye_blink)
		_eye_mat.set_shader_parameter("dilation", _eye_dilation)
		_eye_mat.set_shader_parameter("time_sec", timer)
		_eye_mat.set_shader_parameter("alert", _eye_alert)
	if _mist_mat:
		_mist_mat.set_shader_parameter("time_sec", timer)
	if _frost_mat:
		_frost_mat.set_shader_parameter("intensity", 1.0 if triggered else 0.35)
		_frost_mat.set_shader_parameter("time_sec", timer)
	if _wisp_fog_mat:
		var fog_origin := _wisp_fog_rect.position if _wisp_fog_rect else Vector2(-420.0, -280.0)
		_wisp_fog_mat.set_shader_parameter("wisp_pos", _wisp_pos - global_position - fog_origin)
		if player_ref != null and is_instance_valid(player_ref):
			_wisp_fog_mat.set_shader_parameter("player_pos", player_ref.global_position - Vector2(0.0, 16.0) - global_position - fog_origin)
		_wisp_fog_mat.set_shader_parameter("time_sec", timer)
	if _dark_mat:
		var dark_origin := _dark_rect.position if _dark_rect else Vector2(-420.0, -280.0)
		if player_ref != null and is_instance_valid(player_ref):
			var lpos := player_ref.global_position - Vector2(0.0, 16.0) - global_position - dark_origin
			_dark_mat.set_shader_parameter("lantern_pos", lpos)
		var flash_amt := clampf((0.88 - _lightning_alpha) / 0.82, 0.0, 1.0)
		_dark_mat.set_shader_parameter("darkness_alpha", _lightning_alpha)
		_dark_mat.set_shader_parameter("time_sec", timer)
		_dark_mat.set_shader_parameter("flash_amount", flash_amt)

func _play_sfx(sfx_name: String) -> void:
	if not is_inside_tree():
		return
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play"):
		sm.play(sfx_name)

func _shake(intensity: float) -> void:
	if not is_inside_tree():
		return
	var sm = get_node_or_null("/root/SaveManager")
	if sm and "shake_enabled" in sm and not sm.shake_enabled:
		return
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("request_screen_shake"):
		gm.request_screen_shake.emit(intensity)

func _physics_process(delta: float) -> void:
	_resolve_refs()
	var real_delta := delta / maxf(Engine.time_scale, 0.05)
	timer += delta
	if _fx_timer > 0.0:
		_fx_timer = maxf(0.0, _fx_timer - real_delta)

	var p := player_ref
	var p_valid: bool = p != null and is_instance_valid(p) and not ("is_dead" in p and bool(p.is_dead))

	match event_type:
		"phantom_footprints":
			_step_accum += delta
			if p_valid and p.has_method("is_on_floor") and p.is_on_floor() and absf(p.velocity.x) > 40.0 and _step_accum >= 0.14:
				_step_accum = 0.0
				_footprints.append({
					"pos": p.global_position,
					"life": 2.4,
					"dir": signf(p.velocity.x) if absf(p.velocity.x) > 1.0 else 1.0,
				})
				if _footprints.size() > 18:
					_footprints.remove_at(0)
			for i in range(_footprints.size() - 1, -1, -1):
				_footprints[i]["life"] -= delta
				if _footprints[i]["life"] <= 0.0:
					_footprints.remove_at(i)
		"frozen_pendulum":
			if not triggered:
				_pendulum_angle = sin(timer * 2.1) * 0.48
				if p_valid and p.global_position.x >= trigger_x:
					triggered = true
					_blackout_alpha = 0.25
					_play_sfx("flicker")
			else:
				_blackout_alpha = maxf(0.0, _blackout_alpha - delta * 1.4)
		"death_tally_wall":
			pass
		"watching_eye":
			var eye_center := Vector2(480.0, 178.0)
			if p_valid:
				var to_p := p.global_position - Vector2(0, 16) - eye_center
				var dist := to_p.length()
				var dir := to_p.normalized() if dist > 0.001 else Vector2.ZERO
				_eye_look = _eye_look.lerp(dir * 11.0, minf(1.0, delta * 8.0))
				var target_dil := clampf(1.0 - (dist - 120.0) / 360.0, 0.25, 0.92)
				_eye_dilation = lerpf(_eye_dilation, target_dil, minf(1.0, delta * 5.0))
				if not triggered and p.global_position.x >= trigger_x:
					triggered = true
					_eye_blink = 1.0
					_play_sfx("flicker")
			_eye_alert = lerpf(_eye_alert, 1.0 if triggered else 0.0, minf(1.0, delta * 4.0))
			_eye_idle_blink_cd -= delta
			if _eye_idle_blink_cd <= 0.0 and _eye_blink <= 0.01:
				_eye_blink = 0.92
				_eye_idle_blink_cd = 4.6
			_eye_blink = maxf(0.0, _eye_blink - delta * 3.8)
		"betraying_arrow":
			if not triggered and p_valid and p.global_position.x >= trigger_x:
				triggered = true
				_blackout_alpha = 0.55
				_play_sfx("flicker")
			_blackout_alpha = maxf(0.0, _blackout_alpha - delta * 3.2)
		"shadow_doppelganger":
			if p_valid and not triggered:
				var dist := p.global_position.distance_to(Vector2(trigger_x, trigger_y))
				if dist < 215.0:
					triggered = true
					_doppel_dir = 1.0
					_play_sfx("whisper_boom")
			if triggered:
				_doppel_dissolve = minf(1.0, _doppel_dissolve + delta * 1.35)
		"blackout_swap":
			if not triggered and p_valid and p.global_position.x >= trigger_x:
				triggered = true
				_blackout_alpha = 1.0
				_play_sfx("flicker")
				_play_sfx("whisper_boom")
				var tgt := _get_target_node()
				if tgt and tgt is Node2D:
					(tgt as Node2D).position = Vector2(param_a, param_b)
				var aux := _get_aux_node()
				if aux and aux is CanvasItem:
					(aux as CanvasItem).visible = true
					_set_subtree_collision(aux, true)
			elif triggered and _blackout_alpha > 0.0:
				_blackout_alpha = maxf(0.0, _blackout_alpha - delta * 3.4)
		"haunted_gust":
			var phase := fmod(timer, 3.6)
			var now_wind := phase >= 2.0
			if now_wind and not _wind_active:
				_play_sfx("flicker")
			_wind_active = now_wind
			if p_valid and "external_wind_x" in p:
				p.external_wind_x = -88.0 if (_wind_active and p.global_position.y <= 292.0) else 0.0
		"mirror_ghost_bridge":
			# Invisible ghost bridge: stones remain 100% hidden until the player actually touches/lands on them
			for s in _ghost_stones:
				var sp: Vector2 = s["pos"]
				var sz: Vector2 = s["size"]
				var touching := false
				if p_valid:
					var px: float = p.global_position.x
					var py: float = p.global_position.y
					if px >= (sp.x - 14.0) and px <= (sp.x + sz.x + 14.0) and py >= (sp.y - 14.0) and py <= (sp.y + sz.y + 10.0):
						touching = true
				if touching:
					s["glow"] = 1.0
				else:
					s["glow"] = maxf(0.0, float(s["glow"]) - delta * 1.35)
			_ghost_trail.clear()
		"attic_knock":
			_knock_cycle += delta
			if _knock_cycle >= 4.2:
				_knock_cycle = 0.0
				_knock_ring = 1.0
				_play_sfx("land")
			_knock_ring = maxf(0.0, _knock_ring - delta * 1.1)
		"low_gravity_drift":
			if not triggered and p_valid and p.global_position.x <= trigger_x:
				triggered = true
				if "gravity_mult" in p:
					p.gravity_mult = 0.56
				_play_sfx("reverse_chime")
				_fx_timer = 0.8
		"fake_win_glitch":
			if _fake_door_area and _fake_door_area.visible:
				_fake_door_area.queue_redraw()
			if _fake_win_phase == 1:
				_fake_win_timer += delta
				if _fake_win_timer >= 0.55:
					_fake_win_phase = 2
					_fake_win_timer = 0.0
					_play_sfx("glitch")
					_shake(9.0)
			elif _fake_win_phase == 2:
				_fake_win_timer += delta
				if _fake_win_timer >= 0.44:
					_fake_win_phase = 3
					if _fake_door_area:
						_fake_door_area.visible = false
						_fake_door_area.set_deferred("monitoring", false)
					if p_valid and "is_entering_door" in p:
						p.is_entering_door = false
					elif player_ref and is_instance_valid(player_ref) and "is_entering_door" in player_ref:
						player_ref.is_entering_door = false
					if exit_door_ref:
						exit_door_ref.visible = true
						exit_door_ref.set_deferred("monitoring", true)
						exit_door_ref.queue_redraw()
					_play_sfx("whisper_boom")
		"lightning_darkness":
			_lightning_cycle += delta
			if _lightning_cycle >= 3.0:
				_lightning_cycle = 0.0
				_lightning_alpha = 0.06
				_lightning_bolt_seed += 1
				_play_sfx("thunder")
			else:
				_lightning_alpha = minf(0.96, _lightning_alpha + delta * 2.2)
		"screen_wrap_portal":
			if p_valid and "screen_wrap_enabled" in p:
				if not p.screen_wrap_enabled:
					p.screen_wrap_enabled = true
					p.screen_wrap_y_min = param_a if param_a > 0.0 else 255.0
					p.screen_wrap_y_max = param_b if param_b > 0.0 else 425.0
				if p.has_signal("screen_wrapped") and not p.screen_wrapped.is_connected(_on_player_screen_wrapped):
					p.screen_wrapped.connect(_on_player_screen_wrapped)
		"room_tilt_vertigo":
			if not triggered and p_valid and p.global_position.x >= trigger_x:
				triggered = true
				_play_sfx("whisper_boom")
			if triggered:
				_cam_tilt_rad = deg_to_rad(sin(timer * 0.95) * 7.2)
				if is_inside_tree() and get_tree().current_scene:
					var cam := get_tree().current_scene.get_node_or_null("Camera2D") as Camera2D
					if cam:
						cam.ignore_rotation = false
						cam.rotation = _cam_tilt_rad
			if _chandelier_bar != null and is_instance_valid(_chandelier_bar):
				var hub := ParanormalArt.get_chandelier_hub(Vector2(480.0, 48.0), _cam_tilt_rad, timer)
				_chandelier_bar.position = Vector2(hub.x - 52.0, hub.y + 4.0)
		"time_heartbeat_slowmo":
			_slowmo_cycle += real_delta
			_clock_angle += delta * 1.15
			if p_valid:
				if not _slowmo_active and _slowmo_cycle >= 2.85:
					_slowmo_active = true
					_slowmo_cycle = 0.0
					_slowmo_pulse_r = 12.0
					Engine.time_scale = 0.44
					_play_sfx("reverse_chime")
				elif _slowmo_active:
					_slowmo_pulse_r += real_delta * 620.0
					if _slowmo_cycle >= 1.38:
						_slowmo_active = false
						_slowmo_cycle = 0.0
						Engine.time_scale = 1.0
			elif Engine.time_scale != 1.0:
				Engine.time_scale = 1.0
				_slowmo_active = false
		"twin_doors_truth":
			if not triggered:
				var tgt := _get_target_node()
				if tgt and "is_triggered" in tgt and tgt.is_triggered:
					triggered = true
					_fx_timer = 0.45
					_play_sfx("glitch")
					_shake(6.0)
		"mind_flip_mist":
			if p_valid:
				var inv_y := param_a if param_a > 0.0 else 352.0
				if p.global_position.y > inv_y:
					if p.has_method("add_inverter_zone"):
						p.add_inverter_zone(self)
				else:
					if p.has_method("remove_inverter_zone"):
						p.remove_inverter_zone(self)
		"rising_shadow_tide":
			if not _tide_started and p_valid:
				if p.global_position.x >= trigger_x or p.global_position.y <= trigger_y:
					_tide_started = true
					_play_sfx("whisper_boom")
			if _tide_started and p_valid:
				var rise_speed := param_a if param_a > 0.0 else 31.0
				var min_y := param_b if param_b > 0.0 else 220.0
				_tide_y = maxf(min_y, _tide_y - rise_speed * delta)
				if p.global_position.y > _tide_y + 10.0 and p.has_method("kill"):
					p.kill()
		"reality_awakening_finale":
			if not triggered and p_valid and p.global_position.x >= trigger_x:
				triggered = true
				_monolith_cracked = true
				_monolith_flash = 1.0
				_play_sfx("thunder")
				_play_sfx("whisper_boom")
				_shake(10.0)
				var aux := _get_aux_node()
				if aux and aux is CanvasItem:
					(aux as CanvasItem).visible = true
					(aux as CanvasItem).modulate = Color(0.54, 0.58, 0.68, 0.34)
					_set_subtree_collision(aux, true)
			_monolith_flash = maxf(0.0, _monolith_flash - delta * 2.8)
		# =============================================================
		# CHAPTER 2: FROST PEAK (Levels 21-40)
		# =============================================================
		"frost_breath_echo":
			_step_accum += delta
			if p_valid and _step_accum >= 0.24:
				_step_accum = 0.0
				var dir_f := float(p.facing) if "facing" in p else 1.0
				_breath_puffs.append({
					"pos": p.global_position + Vector2(dir_f * 14.0, -24.0),
					"vel": Vector2(dir_f * 26.0, -14.0),
					"life": 2.2,
					"r": 5.5,
				})
				if _breath_puffs.size() > 16:
					_breath_puffs.remove_at(0)
			if not triggered and p_valid and p.global_position.x >= trigger_x:
				triggered = true
				_play_sfx("biome_frost_snap")
			for i in range(_breath_puffs.size() - 1, -1, -1):
				if not triggered:
					_breath_puffs[i]["pos"] += _breath_puffs[i]["vel"] * delta
					_breath_puffs[i]["r"] = float(_breath_puffs[i]["r"]) + delta * 3.0
				_breath_puffs[i]["life"] = float(_breath_puffs[i]["life"]) - delta * (0.45 if triggered else 1.0)
				if float(_breath_puffs[i]["life"]) <= 0.0:
					_breath_puffs.remove_at(i)
		"icicle_chime_omen":
			_chime_ring = maxf(0.0, _chime_ring - delta * 1.3)
			_chime_sway = lerpf(_chime_sway, sin(timer * 1.9) * 0.10, minf(1.0, delta * 3.0))
			if not triggered and p_valid and p.global_position.x <= trigger_x:
				triggered = true
				_chime_ring = 1.0
				_chime_sway = 0.38
				_play_sfx("biome_frost_snap")
		"black_ice_glide":
			if p_valid and "ice_friction" in p:
				var ice_max_y := param_a if param_a > 0.0 else 285.0
				var on_black_ice: bool = p.global_position.y <= ice_max_y
				p.ice_friction = 0.91 if on_black_ice else 0.0
				if on_black_ice and p.is_on_floor() and absf(p.velocity.x) > 90.0:
					_step_accum += delta
					if _step_accum >= 0.06:
						_step_accum = 0.0
						_ice_sparks.append({"pos": p.global_position + Vector2(randf_range(-6.0, 6.0), -1.0), "life": 0.45})
						if _ice_sparks.size() > 14:
							_ice_sparks.remove_at(0)
			for i in range(_ice_sparks.size() - 1, -1, -1):
				_ice_sparks[i]["life"] = float(_ice_sparks[i]["life"]) - delta
				if float(_ice_sparks[i]["life"]) <= 0.0:
					_ice_sparks.remove_at(i)
		"frozen_compass_needle":
			var compass_c := Vector2(480.0, 148.0)
			if not triggered:
				var target_p := exit_door_ref.global_position if exit_door_ref else Vector2(865.0, 220.0)
				var desired := (target_p - compass_c).angle()
				_compass_angle = lerp_angle(_compass_angle, desired + sin(timer * 2.2) * 0.04, minf(1.0, delta * 5.0))
				var tgt := _get_target_node()
				if tgt and "is_triggered" in tgt and tgt.is_triggered:
					triggered = true
					_play_sfx("biome_ice_shatter")
					_shake(5.0)
			else:
				var target_p2 := exit_door_ref.global_position if exit_door_ref else Vector2(865.0, 220.0)
				_compass_angle = (target_p2 - compass_c).angle()
		"aurora_veil_shift":
			_aurora_cycle += delta
			if _aurora_cycle >= 3.0:
				_aurora_cycle = 0.0
				_aurora_cyan = not _aurora_cyan
				_play_sfx("biome_frost_snap")
				for ap in _aurora_plats:
					var is_s: bool = (bool(ap["cyan_phase"]) == _aurora_cyan)
					ap["solid"] = is_s
					(ap["col"] as CollisionShape2D).disabled = not is_s
		"snowdrift_bury":
			if not _snow_wave_active and p_valid and p.global_position.x >= trigger_x:
				_snow_wave_active = true
				_snow_wave_x = 806.0
				_snow_wave_delay = 0.55
				_play_sfx("biome_snow_burst")
				_shake(5.0)
			if _snow_wave_active:
				if _snow_wave_delay > 0.0:
					_snow_wave_delay = maxf(0.0, _snow_wave_delay - delta)
				else:
					var wave_spd := param_a if param_a > 0.0 else 85.0
					_snow_wave_x = maxf(32.0, _snow_wave_x - wave_spd * delta)
					var top_y := param_b if param_b > 0.0 else 372.0
					if p_valid and p.global_position.x >= _snow_wave_x + 8.0 and p.global_position.x < 806.0 and p.global_position.y > top_y + 12.0:
						if p.has_method("kill"):
							p.kill()
		"frozen_mirror_twin":
			if p_valid:
				if not triggered:
					_mirror_twin_pos = Vector2(960.0 - p.global_position.x, p.global_position.y)
					if p.global_position.x >= trigger_x:
						triggered = true
						_fx_timer = 0.65
						_play_sfx("biome_ice_shatter")
						_shake(7.0)
						var tgt := _get_target_node()
						if tgt and tgt is Node2D:
							(tgt as Node2D).position = Vector2(param_a if param_a > 0.0 else 115.0, param_b if param_b > 0.0 else 255.0)
				else:
					_mirror_twin_pos.x = lerpf(_mirror_twin_pos.x, 425.0, minf(1.0, delta * 2.2))
		"frostbite_lantern_pulse":
			if p_valid and "speed_mult" in p:
				var warm_r := param_a if param_a > 0.0 else 118.0
				var is_warm := false
				for lp in _lantern_positions:
					if p.global_position.distance_to(lp) <= warm_r:
						is_warm = true
						break
				p.speed_mult = 1.12 if is_warm else 0.68
		"shattering_glacier_echo":
			if _shock_a > 0.0:
				_shock_r += delta * 340.0
				_shock_a = maxf(0.0, _shock_a - delta * 1.9)
			if p_valid:
				var on_fl: bool = p.has_method("is_on_floor") and p.is_on_floor()
				if on_fl and not _was_grounded_ev:
					_stomp_count += 1
					_shock_pos = p.global_position
					_shock_r = 10.0
					_shock_a = 1.0
					_play_sfx("biome_frost_snap")
					if not triggered and _stomp_count >= 3:
						triggered = true
						_play_sfx("biome_ice_shatter")
						_shake(7.0)
						var aux := _get_aux_node()
						if aux and aux is CanvasItem:
							(aux as CanvasItem).visible = true
							(aux as CanvasItem).modulate = Color(0.70, 0.94, 1.0, 0.85)
							_set_subtree_collision(aux, true)
				_was_grounded_ev = on_fl
		"blizzard_whiteout_gust":
			_blizzard_cycle += delta
			var phase := fmod(_blizzard_cycle, 4.2)
			var is_squall := phase >= 2.0
			var cycle_idx := int(floor(_blizzard_cycle / 4.2))
			_blizzard_wind_dir = 1.0 if (cycle_idx % 2 == 0) else -1.0
			_blizzard_alpha = lerpf(_blizzard_alpha, 1.0 if is_squall else 0.0, minf(1.0, delta * 5.0))
			if is_squall and not _wind_active:
				_play_sfx("biome_snow_burst")
			_wind_active = is_squall
			if p_valid and "external_wind_x" in p:
				var shelter_y := param_a if param_a > 0.0 else 365.0
				p.external_wind_x = (_blizzard_wind_dir * 125.0) if (_wind_active and p.global_position.y < shelter_y) else 0.0
		"frozen_dash_platforms":
			for dp in _dash_pads:
				if float(dp["life"]) > 0.0:
					dp["life"] = maxf(0.0, float(dp["life"]) - delta)
					if float(dp["life"]) <= 0.0:
						(dp["col"] as CollisionShape2D).disabled = true
			if p_valid and "is_dashing" in p:
				var now_dashing: bool = bool(p.is_dashing)
				if _prev_player_dashing and not now_dashing and not p.is_on_floor():
					# Crystallize a solid frozen ice-cloud pad right beneath the player!
					var slot: Dictionary = _dash_pads[0]
					if float(_dash_pads[0]["life"]) > float(_dash_pads[1]["life"]):
						slot = _dash_pads[1]
					var new_pos := Vector2(clampf(p.global_position.x - 34.0, 40.0, 852.0), clampf(p.global_position.y + 3.0, 96.0, 480.0))
					slot["pos"] = new_pos
					slot["life"] = 3.2
					(slot["body"] as StaticBody2D).position = new_pos
					(slot["col"] as CollisionShape2D).disabled = false
					_play_sfx("biome_frost_snap")
				_prev_player_dashing = now_dashing
		"cryo_updraft_column":
			if p_valid and "external_force_y" in p:
				var xmin := param_a if param_a > 0.0 else 420.0
				var xmax := param_b if param_b > 0.0 else 540.0
				var in_col: bool = p.global_position.x >= xmin and p.global_position.x <= xmax and p.global_position.y >= 95.0
				p.external_force_y = -2650.0 if in_col else 0.0
		"frost_bell_shockwave":
			_bell_cycle += delta
			_bell_swing = lerpf(_bell_swing, 0.0, minf(1.0, delta * 2.5))
			if _bell_cycle >= 3.2:
				_bell_cycle = 0.0
				_bell_ring_r = 16.0
				_bell_ring_a = 1.0
				_bell_swing = 0.28
				_bell_bounced_this_toll = false
				_play_sfx("whisper_boom")
				_play_sfx("biome_frost_snap")
			if _bell_ring_a > 0.0:
				_bell_ring_r += delta * 390.0
				_bell_ring_a = maxf(0.0, _bell_ring_a - delta * 0.95)
				if p_valid and not _bell_bounced_this_toll and not p.is_on_floor():
					var dist := p.global_position.distance_to(Vector2(480.0, 148.0))
					if absf(dist - _bell_ring_r) <= 68.0:
						_bell_bounced_this_toll = true
						p.velocity.y = minf(p.velocity.y, -490.0)
		"glacial_prism_split":
			if not triggered and p_valid and p.global_position.x <= trigger_x:
				triggered = true
				_play_sfx("biome_frost_snap")
				_shake(5.0)
				var aux := _get_aux_node()
				if aux and aux is CanvasItem:
					(aux as CanvasItem).visible = true
					(aux as CanvasItem).modulate = Color(0.56, 0.90, 1.0, 0.78)
					_set_subtree_collision(aux, true)
		"permafrost_creep":
			if p_valid and p.is_on_floor():
				if not triggered:
					if p.global_position.x >= 135.0 or p.global_position.y > 220.0:
						triggered = true
						_last_perma_x = p.global_position.x
				elif absf(p.global_position.x - _last_perma_x) >= 38.0:
					_last_perma_x = p.global_position.x
					_permafrost_patches.append({"pos": p.global_position, "age": 0.0, "lethal": false})
					if _permafrost_patches.size() > 14:
						_permafrost_patches.remove_at(0)
			for pt in _permafrost_patches:
				pt["age"] = float(pt["age"]) + delta
				if float(pt["age"]) >= 1.10:
					pt["lethal"] = true
					if p_valid:
						var pp: Vector2 = pt["pos"]
						if absf(p.global_position.x - pp.x) <= 13.0 and absf(p.global_position.y - pp.y) <= 10.0:
							if p.has_method("kill"):
								p.kill()
		"sky_cairn_airborne":
			var airborne: bool = p_valid and p.has_method("is_on_floor") and not p.is_on_floor()
			_cairn_reveal = lerpf(_cairn_reveal, 1.0 if airborne else 0.0, minf(1.0, delta * 9.0))
		"cryo_heartbeat_surge":
			_cryo_heart_cycle += delta
			var cyc := fmod(_cryo_heart_cycle, 3.0)
			var now_surge := cyc >= 1.75
			if now_surge and not _cryo_surge:
				_cryo_pulse_r = 20.0
				_play_sfx("biome_frost_snap")
			_cryo_surge = now_surge
			if _cryo_surge:
				_cryo_pulse_r += delta * 340.0
			if p_valid and "jump_mult" in p:
				p.jump_mult = 1.24 if _cryo_surge else 1.0
		"shattering_ice_panes":
			for pn in _ice_panes:
				var st: int = int(pn["state"])
				if st == 0 and p_valid and p.is_on_floor():
					var pos_p: Vector2 = pn["pos"]
					var sz_p: Vector2 = pn["size"]
					if p.global_position.x >= pos_p.x - 10.0 and p.global_position.x <= pos_p.x + sz_p.x + 10.0 and absf(p.global_position.y - pos_p.y) <= 6.0:
						pn["state"] = 1
						pn["crack_timer"] = 0.45
						_play_sfx("biome_frost_snap")
				elif st == 1:
					pn["crack_timer"] = float(pn["crack_timer"]) - delta
					if float(pn["crack_timer"]) <= 0.0:
						pn["state"] = 2
						(pn["col"] as CollisionShape2D).disabled = true
						_play_sfx("biome_ice_shatter")
		"avalanche_wall_chase":
			if not _avalanche_started and p_valid and p.global_position.x >= trigger_x:
				_avalanche_started = true
				_avalanche_x = 24.0
				_play_sfx("biome_snow_burst")
				_shake(6.0)
			if _avalanche_started:
				var spd := param_a if param_a > 0.0 else 112.0
				_avalanche_x = minf(930.0, _avalanche_x + spd * delta)
				if p_valid and p.global_position.x < _avalanche_x + 4.0 and p.has_method("kill"):
					p.kill()
		"frost_crown_finale":
			if not triggered and p_valid:
				var at_right_altar: bool = p.global_position.x >= (trigger_x if trigger_x > 0.0 else 730.0)
				var at_crown_aura: bool = absf(p.global_position.x - 480.0) <= 115.0 and p.global_position.y <= 290.0
				if at_right_altar or at_crown_aura:
					triggered = true
					_crown_flash = 1.0
					_play_sfx("thunder")
					_play_sfx("biome_ice_shatter")
					_shake(9.0)
					if exit_door_ref:
						exit_door_ref.set_deferred("monitoring", true)
						if "reset_cooldown" in exit_door_ref:
							exit_door_ref.reset_cooldown = 0.02
			_crown_flash = maxf(0.0, _crown_flash - delta * 2.5)
		# =============================================================
		# CHAPTER 3: EMERALD WOODS (Levels 41-60)
		# =============================================================
		"firefly_path_decoy":
			if not triggered and p_valid and p.global_position.x >= trigger_x and p.global_position.y <= 330.0:
				triggered = true
				_play_sfx("biome_vine_whip")
		"living_vine_bridge":
			for vs in _vine_segments:
				var pos_v: Vector2 = vs["pos"]
				var is_high: bool = bool(vs["high"])
				var near_bud := false
				if p_valid:
					if is_high:
						near_bud = (p.global_position.x >= 175.0 and p.global_position.x <= 320.0 and p.global_position.y <= 295.0)
					else:
						near_bud = (p.global_position.x >= pos_v.x - 135.0 and p.global_position.x <= pos_v.x + float((vs["size"] as Vector2).x) + 30.0 and p.global_position.y >= 280.0)
				if near_bud and float(vs["grow"]) < 1.0 and not bool(vs["wilting"]):
					var grow_rate := 6.5 if is_high else 4.8
					vs["grow"] = minf(1.0, float(vs["grow"]) + delta * grow_rate)
					if float(vs["grow"]) >= 0.42:
						(vs["col"] as CollisionShape2D).disabled = false
					if float(vs["grow"]) >= 1.0:
						vs["active_t"] = 2.8 if is_high else 1.85
						_play_sfx("biome_vine_whip")
				elif float(vs["active_t"]) > 0.0:
					vs["active_t"] = float(vs["active_t"]) - delta
					vs["wilting"] = float(vs["active_t"]) <= 0.55
					if float(vs["active_t"]) <= 0.0:
						vs["grow"] = 0.0
						vs["wilting"] = false
						(vs["col"] as CollisionShape2D).disabled = true
		"whispering_totem_curse":
			_totem_cycle += delta
			var new_mask := int(floor(_totem_cycle / 2.6)) % 3
			if new_mask != _totem_mask:
				_totem_mask = new_mask
				_play_sfx("biome_vine_whip")
			if p_valid and "speed_mult" in p:
				if _totem_mask == 1:
					p.speed_mult = 1.38
				elif _totem_mask == 2:
					p.speed_mult = 0.72
				else:
					p.speed_mult = 1.0
		"moonlit_pond_inversion":
			if p_valid and "gravity_mult" in p and "speed_mult" in p:
				var surf_y := param_a if param_a > 0.0 else 378.0
				var in_pond: bool = p.global_position.x >= 210.0 and p.global_position.x <= 750.0 and p.global_position.y >= surf_y
				p.gravity_mult = 0.50 if in_pond else 1.0
				p.speed_mult = 0.88 if in_pond else 1.0
		"spore_cloud_bounce":
			for mc in _mushroom_caps:
				mc["squash"] = maxf(0.0, float(mc["squash"]) - delta * 2.8)
				mc["cd"] = maxf(0.0, float(mc["cd"]) - delta)
				if p_valid and float(mc["cd"]) <= 0.0:
					var mp: Vector2 = mc["pos"]
					var hw: float = float(mc["w"]) * 0.54
					if absf(p.global_position.x - mp.x) <= hw and p.global_position.y >= mp.y - 26.0 and p.global_position.y <= mp.y + 8.0 and p.velocity.y >= -40.0:
						p.velocity.y = float(mc["vy"])
						mc["squash"] = 1.0
						mc["cd"] = 0.25
						_play_sfx("biome_vine_whip")
		"owl_sentinel_gaze":
			_owl_cycle += delta
			var phase := fmod(_owl_cycle, 3.4)
			var now_open := phase >= 1.85
			if now_open and not _owl_open:
				_play_sfx("flicker")
			_owl_open = now_open
			_owl_sweep_x = 480.0 + sin(timer * 1.45) * 265.0
			var spotted := false
			if _owl_open and p_valid and p.global_position.y > 312.0:
				var under_s1: bool = p.global_position.x >= 254.0 and p.global_position.x <= 386.0
				var under_s2: bool = p.global_position.x >= 554.0 and p.global_position.x <= 686.0
				if not under_s1 and not under_s2 and absf(p.global_position.x - _owl_sweep_x) <= 112.0:
					if absf(p.velocity.x) > 28.0 or not p.is_on_floor():
						spotted = true
			if spotted:
				_owl_warn = minf(1.0, _owl_warn + delta * 2.3)
				if _owl_warn >= 1.0 and p_valid and p.has_method("kill"):
					_play_sfx("glitch")
					p.kill()
			else:
				_owl_warn = maxf(0.0, _owl_warn - delta * 4.0)
		"root_labyrinth_shift":
			if p_valid:
				var rune_a := Vector2(trigger_x if trigger_x > 0.0 else 735.0, trigger_y if trigger_y > 0.0 else 385.0)
				var rune_b := Vector2(param_a if param_a > 0.0 else 95.0, param_b if param_b > 0.0 else 325.0)
				if not _sap_rune_a_lit and p.global_position.distance_to(rune_a) <= 48.0:
					_sap_rune_a_lit = true
					_play_sfx("biome_vine_whip")
					_shake(5.0)
				if not _sap_rune_b_lit and p.global_position.distance_to(rune_b) <= 44.0:
					_sap_rune_b_lit = true
					_play_sfx("biome_vine_whip")
					var aux := _get_aux_node()
					if aux and aux is CanvasItem:
						(aux as CanvasItem).visible = true
						(aux as CanvasItem).modulate = Color(0.50, 0.96, 0.66, 0.90)
						_set_subtree_collision(aux, true)
			var tgt := _get_target_node() as Node2D
			if tgt and _sap_rune_a_lit:
				tgt.position = tgt.position.lerp(Vector2(_target_orig_pos.x, _target_orig_pos.y - 95.0), minf(1.0, delta * 5.0))
		"pollen_dream_drift":
			if p_valid and "gravity_mult" in p:
				var falling: bool = (not p.is_on_floor()) and p.velocity.y > 20.0
				_pollen_floating = falling
				p.gravity_mult = 0.56 if falling else 1.0
				if falling:
					_step_accum += delta
					if _step_accum >= 0.06:
						_step_accum = 0.0
						_pollen_motes.append({"pos": p.global_position + Vector2(randf_range(-10.0, 10.0), -6.0), "life": 0.85})
						if _pollen_motes.size() > 16:
							_pollen_motes.remove_at(0)
			for i in range(_pollen_motes.size() - 1, -1, -1):
				_pollen_motes[i]["life"] = float(_pollen_motes[i]["life"]) - delta
				if float(_pollen_motes[i]["life"]) <= 0.0:
					_pollen_motes.remove_at(i)
		"phantom_stag_guide":
			_stag_cycle = fmod(_stag_cycle + delta, 5.4)
			var u := _stag_cycle / 5.4
			var sx := lerpf(90.0, 870.0, u)
			var sy := 278.0 - absf(sin(u * PI * 3.0)) * 52.0
			_stag_pos = Vector2(sx, sy)
			for sp in _stag_pads:
				var p_center := (sp["pos"] as Vector2) + (sp["size"] as Vector2) * 0.5
				if absf(sx - p_center.x) <= 28.0:
					if float(sp["life"]) <= 0.1:
						_play_sfx("biome_vine_whip")
					sp["life"] = 3.2
					(sp["col"] as CollisionShape2D).disabled = false
				elif float(sp["life"]) > 0.0:
					sp["life"] = maxf(0.0, float(sp["life"]) - delta)
					if float(sp["life"]) <= 0.0:
						(sp["col"] as CollisionShape2D).disabled = true
		"canopy_eclipse_dark":
			var bases := [210.0, 400.0, 590.0, 770.0]
			for i in range(4):
				_eclipse_beams[i] = bases[i] + sin(timer * 1.05 + float(i) * 1.4) * 38.0
			if p_valid and "dash_cooldown_timer" in p:
				for bx in _eclipse_beams:
					if absf(p.global_position.x - bx) <= 44.0:
						p.dash_cooldown_timer = 0.0
						break
		"fairy_ring_portal":
			_fairy_warp_fx = maxf(0.0, _fairy_warp_fx - delta * 2.2)
			_fairy_cd = maxf(0.0, _fairy_cd - delta)
			var ring_a := Vector2(trigger_x if trigger_x > 0.0 else 505.0, trigger_y if trigger_y > 0.0 else 410.0)
			var ring_b := Vector2(param_a if param_a > 0.0 else 185.0, param_b if param_b > 0.0 else 225.0)
			if p_valid and _fairy_cd <= 0.0:
				var in_ring: bool = absf(p.global_position.x - ring_a.x) <= 28.0 and absf(p.global_position.y - ring_a.y) <= 12.0 and absf(p.velocity.x) < 25.0 and p.is_on_floor()
				if in_ring:
					_fairy_charge = minf(1.0, _fairy_charge + delta / 0.42)
					if _fairy_charge >= 1.0:
						p.global_position = ring_b
						p.velocity = Vector2.ZERO
						_fairy_charge = 0.0
						_fairy_warp_fx = 1.0
						_fairy_cd = 1.2
						triggered = true
						_play_sfx("portal")
				else:
					_fairy_charge = maxf(0.0, _fairy_charge - delta * 3.0)
		"weeping_willow_curtain":
			pass
		"cicada_swarm_raft":
			if _cicada_raft and is_instance_valid(_cicada_raft):
				var u := 0.5 + 0.5 * sin(timer * 0.92 + PI * 0.5)
				_cicada_pos = Vector2(lerpf(195.0, 645.0, u), 238.0)
				_cicada_raft.position = _cicada_pos
		"moss_leyline_gravity":
			if p_valid and "gravity_mult" in p and "speed_mult" in p:
				var line_y := param_a if param_a > 0.0 else 295.0
				_leyline_above = p.global_position.y <= line_y
				p.gravity_mult = 0.62 if _leyline_above else 1.0
				p.speed_mult = 1.15 if _leyline_above else 1.0
		"ancient_stump_rings":
			_stump_cycle = fmod(_stump_cycle + delta, 6.4)
			var new_r := mini(5, 1 + int(floor(_stump_cycle / 0.72)))
			var now_surge := _stump_cycle >= 3.0
			if now_surge and not _stump_surge:
				_play_sfx("biome_vine_whip")
				for ss in _stump_steps:
					ss["solid"] = true
					(ss["col"] as CollisionShape2D).disabled = false
			elif not now_surge and _stump_surge:
				for ss in _stump_steps:
					ss["solid"] = false
					(ss["col"] as CollisionShape2D).disabled = true
			_stump_ring = new_r
			_stump_surge = now_surge
		"wisp_lantern_escort":
			if p_valid:
				var fdir := float(p.facing) if "facing" in p else 1.0
				var desired := p.global_position + Vector2(fdir * 96.0, -44.0 + sin(timer * 3.0) * 8.0)
				if fdir < 0.0 and p.global_position.x < 170.0:
					desired = Vector2(56.0, 345.0)
				_wisp_pos = _wisp_pos.lerp(desired, minf(1.0, delta * 4.2))
		"spirit_bamboo_gust":
			_bamboo_gust_life = maxf(0.0, _bamboo_gust_life - delta)
			if _bamboo_boost_timer > 0.0:
				_bamboo_boost_timer = maxf(0.0, _bamboo_boost_timer - delta)
				if p_valid and "speed_mult" in p:
					p.speed_mult = 1.65 if _bamboo_boost_timer > 0.0 else 1.0
			for bs in _bamboo_stalks:
				var base: Vector2 = bs["base"]
				var target_b := sin(timer * 1.6 + base.x * 0.01) * 0.12
				if p_valid and absf(p.global_position.x - base.x) < 58.0 and absf(p.global_position.y - base.y) < 95.0:
					target_b = clampf((p.global_position.x - base.x) / 55.0, -0.85, 0.85)
					if "is_dashing" in p and bool(p.is_dashing) and _bamboo_gust_life <= 0.15:
						var gdir := signf(p.velocity.x if absf(p.velocity.x) > 1.0 else 1.0)
						_bamboo_gust_pos = base + Vector2(108.0 * gdir, -52.0)
						_bamboo_gust_life = 1.6
						_bamboo_gust_dir = gdir
						_play_sfx("biome_vine_whip")
				bs["bend"] = lerpf(float(bs["bend"]), target_b, minf(1.0, delta * 7.0))
			if _bamboo_gust_life > 0.05 and p_valid:
				if p.global_position.distance_to(_bamboo_gust_pos) <= 58.0 and not p.is_on_floor():
					p.velocity.y = -785.0
					_bamboo_boost_timer = 0.85
					if "speed_mult" in p:
						p.speed_mult = 1.72
					_bamboo_gust_life = 0.0
					_play_sfx("jump")
		"root_tremor_slabs":
			_tremor_fx = maxf(0.0, _tremor_fx - delta * 2.2)
			_tremor_cycle += delta
			if _tremor_cycle >= 3.2:
				_tremor_cycle = 0.0
				_tremor_phase = 1 - _tremor_phase
				_tremor_fx = 1.0
				_play_sfx("biome_vine_snap")
				_shake(5.5)
			if _tremor_slabs.size() >= 2:
				var low_t: Vector2 = (_tremor_slabs[0]["orig_pos"] as Vector2) + (Vector2(110.0, 0.0) if _tremor_phase == 1 else Vector2.ZERO)
				var high_t: Vector2 = (_tremor_slabs[1]["orig_pos"] as Vector2) + (Vector2(180.0, 0.0) if _tremor_phase == 1 else Vector2(-95.0, 0.0))
				_tremor_slabs[0]["pos"] = (_tremor_slabs[0]["pos"] as Vector2).lerp(low_t, minf(1.0, delta * 4.5))
				_tremor_slabs[1]["pos"] = (_tremor_slabs[1]["pos"] as Vector2).lerp(high_t, minf(1.0, delta * 4.5))
				(_tremor_slabs[0]["body"] as AnimatableBody2D).position = _tremor_slabs[0]["pos"]
				(_tremor_slabs[1]["body"] as AnimatableBody2D).position = _tremor_slabs[1]["pos"]
		"overgrowth_ceiling_vines":
			if not _overgrowth_started and p_valid and p.global_position.x >= trigger_x:
				_overgrowth_started = true
				_overgrowth_y = 52.0
				_play_sfx("biome_vine_snap")
				_shake(5.0)
			if _overgrowth_started:
				var spd := param_a if param_a > 0.0 else 32.0
				var max_y := param_b if param_b > 0.0 else 335.0
				_overgrowth_y = minf(max_y, _overgrowth_y + spd * delta)
				if p_valid and (p.global_position.y - 26.0) < _overgrowth_y and p.has_method("kill"):
					p.kill()
		"world_tree_heart_finale":
			_wt_cycle = fmod(_wt_cycle + delta, 5.6)
			var new_p := 0 if _wt_cycle < 2.2 else (1 if _wt_cycle < 3.8 else 2)
			if new_p != _wt_phase:
				_wt_phase = new_p
				if _wt_phase == 1:
					_play_sfx("whisper_boom")
				elif _wt_phase == 0:
					_play_sfx("biome_vine_whip")
				for wp in _wt_pads:
					var s_ok: bool = (_wt_phase == 0)
					wp["solid"] = s_ok
					(wp["col"] as CollisionShape2D).disabled = not s_ok
			if p_valid and "speed_mult" in p and "external_force_y" in p:
				p.speed_mult = 1.12 if _wt_phase == 0 else 1.0
				var in_trunk: bool = (_wt_phase == 1) and p.global_position.x >= 435.0 and p.global_position.x <= 525.0 and p.global_position.y >= 135.0
				p.external_force_y = -2050.0 if in_trunk else 0.0

	_sync_shader_params()
	_queue_active_redraws()

func _on_player_screen_wrapped(_from_x: float, to_x: float, y_pos: float) -> void:
	triggered = true
	_fx_timer = 0.45
	_wrap_shimmer_x = 928.0 if to_x > 480.0 else 32.0
	_wrap_shimmer_y = y_pos - 16.0
	_queue_active_redraws()

func _on_fake_win_entered(body: Node2D) -> void:
	if _fake_win_phase != 0:
		return
	if body is PlayerController and not ("is_dead" in body and body.is_dead):
		_fake_win_phase = 1
		_fake_win_timer = 0.0
		body.is_entering_door = true
		body.velocity = Vector2.ZERO
		_play_sfx("win")

func _draw_fake_win_door() -> void:
	if _fake_door_area == null or not _fake_door_area.visible:
		return
	ParanormalArt.draw_fake_win_door(_fake_door_area, timer, _fake_win_phase, _get_current_chapter())

func _draw_bg() -> void:
	var font := ThemeDB.fallback_font
	match event_type:
		"frozen_pendulum":
			ParanormalArt.draw_frozen_pendulum(_bg_layer, Vector2(480.0, 92.0), 188.0, _pendulum_angle, timer, triggered)
		"death_tally_wall":
			ParanormalArt.draw_death_tally_wall(_bg_layer, Vector2(400.0, 188.0), level_deaths_seen, timer, font)
		"watching_eye":
			ParanormalArt.draw_watching_eye_lashes(_bg_layer, Vector2(480.0, 178.0), _eye_blink, timer, triggered)
		"betraying_arrow":
			ParanormalArt.draw_betraying_arrow(_bg_layer, Vector2(480.0, 212.0), triggered, timer, font)
		"shadow_doppelganger":
			var pos := Vector2(trigger_x, trigger_y) - Vector2(0.0, _doppel_dissolve * 36.0)
			ParanormalArt.draw_shadow_doppelganger(_bg_layer, pos, _doppel_dir, (1.0 - _doppel_dissolve) * 0.88, _doppel_dissolve, timer, false)
		"blackout_swap":
			ParanormalArt.draw_blackout_lantern(_bg_layer, Vector2(480.0, 70.0), timer, triggered, _blackout_alpha)
		"mirror_ghost_bridge":
			ParanormalArt.draw_mirror_ghost_bridge(_bg_layer, _ghost_stones, _ghost_pos, _ghost_trail, timer)
		"low_gravity_drift":
			ParanormalArt.draw_low_gravity_drift(_bg_layer, timer, triggered)
		"lightning_darkness":
			ParanormalArt.draw_lightning_storm(_bg_layer, timer, _lightning_alpha, _lightning_bolt_seed)
		"room_tilt_vertigo":
			ParanormalArt.draw_vertigo_chandelier(_bg_layer, Vector2(480.0, 48.0), _cam_tilt_rad, timer, triggered)
		"time_heartbeat_slowmo":
			ParanormalArt.draw_cathedral_clockwork(_bg_layer, Vector2(480.0, 242.0), _clock_angle, _slowmo_active)
		"reality_awakening_finale":
			ParanormalArt.draw_obsidian_monolith(_bg_layer, Vector2(480.0, 260.0), timer, _monolith_cracked, font)
		# Chapter 2 (Frost Peak) BG
		"icicle_chime_omen":
			FrostArt.draw_icicle_chime_omen(_bg_layer, Vector2(480.0, 96.0), _chime_sway, _chime_ring, timer)
		"frozen_compass_needle":
			FrostArt.draw_frozen_compass(_bg_layer, Vector2(480.0, 148.0), _compass_angle, triggered, timer)
		"aurora_veil_shift":
			FrostArt.draw_aurora_veil(_bg_layer, _aurora_cyan, _aurora_cycle / 3.0, _aurora_plats, timer)
		"frozen_mirror_twin":
			FrostArt.draw_frozen_mirror(_bg_layer, Vector2(480.0, 295.0), _mirror_twin_pos, triggered, _fx_timer, timer)
		"frostbite_lantern_pulse":
			FrostArt.draw_frostbite_lanterns(_bg_layer, _lantern_positions, param_a if param_a > 0.0 else 118.0, timer)
		"shattering_glacier_echo":
			FrostArt.draw_glacier_echo(_bg_layer, _stomp_count, _shock_pos, _shock_r, _shock_a, triggered, timer)
		"cryo_updraft_column":
			FrostArt.draw_cryo_updraft(_bg_layer, param_a if param_a > 0.0 else 420.0, param_b if param_b > 0.0 else 540.0, 85.0, 420.0, timer)
		"frost_bell_shockwave":
			FrostArt.draw_frost_bell(_bg_layer, Vector2(480.0, 90.0), _bell_swing, _bell_ring_r, _bell_ring_a, timer)
		"glacial_prism_split":
			FrostArt.draw_glacial_prism(_bg_layer, Vector2(480.0, 195.0), triggered, timer)
		"sky_cairn_airborne":
			FrostArt.draw_sky_cairns(_bg_layer, [365.0, 480.0, 595.0], 410.0, _cairn_stones, _cairn_reveal, timer)
		"cryo_heartbeat_surge":
			FrostArt.draw_cryo_heart(_bg_layer, Vector2(480.0, 230.0), _cryo_surge, _cryo_pulse_r, timer)
		"frost_crown_finale":
			var dpos := exit_door_ref.global_position if exit_door_ref else Vector2(480.0, 195.0)
			FrostArt.draw_frost_crown_finale(_bg_layer, Vector2(480.0, 128.0), dpos, triggered, 0.0, timer)
		# Chapter 3 (Emerald Woods) BG
		"firefly_path_decoy":
			ForestArt.draw_firefly_decoy(_bg_layer, Vector2(480.0, 270.0), triggered, timer)
		"whispering_totem_curse":
			ForestArt.draw_whispering_totem(_bg_layer, Vector2(480.0, 415.0), _totem_mask, timer)
		"owl_sentinel_gaze":
			ForestArt.draw_owl_sentinel(_bg_layer, Vector2(480.0, 124.0), _owl_open, _owl_warn, _owl_sweep_x, timer)
		"phantom_stag_guide":
			ForestArt.draw_phantom_stag(_bg_layer, _stag_pos, _stag_pads, timer)
		"moss_leyline_gravity":
			ForestArt.draw_moss_leyline(_bg_layer, param_a if param_a > 0.0 else 295.0, _leyline_above, timer)
		"ancient_stump_rings":
			ForestArt.draw_stump_rings(_bg_layer, Vector2(480.0, 268.0), _stump_ring, _stump_surge, _stump_steps, timer)
		"spirit_bamboo_gust":
			ForestArt.draw_spirit_bamboo(_bg_layer, _bamboo_stalks, _bamboo_gust_pos, _bamboo_gust_life, timer)
		"root_tremor_slabs":
			ForestArt.draw_tremor_slabs(_bg_layer, _tremor_slabs, _tremor_fx, timer)
		"world_tree_heart_finale":
			ForestArt.draw_world_tree_heart(_bg_layer, Vector2(480.0, 275.0), _wt_phase, _wt_pads, timer)

func _draw_mid() -> void:
	match event_type:
		"phantom_footprints":
			ParanormalArt.draw_phantom_footprints(_mid_layer, _footprints, Vector2(trigger_x, trigger_y), timer)
		"attic_knock":
			ParanormalArt.draw_attic_knock(_mid_layer, Vector2(trigger_x, trigger_y), _knock_ring, timer)
		"screen_wrap_portal":
			# Completely invisible before crossing; only show a brief warp shimmer after crossing
			if _fx_timer > 0.0:
				ParanormalArt.draw_screen_wrap_shimmer(_mid_layer, _wrap_shimmer_x, _wrap_shimmer_y, clampf(_fx_timer / 0.45, 0.0, 1.0))
		"twin_doors_truth":
			if exit_door_ref:
				var tgt := _get_target_node() as Node2D
				var fake_pos := tgt.global_position if tgt else Vector2.ZERO
				ParanormalArt.draw_twin_doors_reflection(_mid_layer, exit_door_ref.global_position, timer, _fx_timer, fake_pos)
		"reality_awakening_finale":
			pass
		# Chapter 2 (Frost Peak) MID
		"frost_breath_echo":
			FrostArt.draw_frost_breath_echo(_mid_layer, _breath_puffs, triggered, timer)
		"black_ice_glide":
			var ice_rect := Rect2(32.0, 240.0, 896.0, 24.0)
			if level_ref:
				var tf := level_ref.get_node_or_null("Traps/TrapBackChute")
				if tf and "is_falling" in tf and bool(tf.is_falling):
					ice_rect = Rect2(96.0, 240.0, 832.0, 24.0)
			FrostArt.draw_black_ice_surface(_mid_layer, ice_rect, timer, _ice_sparks)
		"frozen_dash_platforms":
			FrostArt.draw_frozen_dash_platforms(_mid_layer, _dash_pads, timer)
		"permafrost_creep":
			FrostArt.draw_permafrost_patches(_mid_layer, _permafrost_patches, timer)
		"shattering_ice_panes":
			FrostArt.draw_shattering_ice_panes(_mid_layer, _ice_panes, timer)
		# Chapter 3 (Emerald Woods) MID
		"living_vine_bridge":
			ForestArt.draw_living_vine_bridge(_mid_layer, _vine_segments, timer)
		"moonlit_pond_inversion":
			var ppos := player_ref.global_position if (player_ref and is_instance_valid(player_ref)) else Vector2(-999, -999)
			ForestArt.draw_moonlit_pond(_mid_layer, 222.0, 740.0, param_a if param_a > 0.0 else 378.0, 415.0, ppos, timer)
		"spore_cloud_bounce":
			ForestArt.draw_spore_mushrooms(_mid_layer, _mushroom_caps, timer)
		"root_labyrinth_shift":
			var ra := Vector2(trigger_x if trigger_x > 0.0 else 735.0, trigger_y if trigger_y > 0.0 else 385.0)
			var rb := Vector2(param_a if param_a > 0.0 else 95.0, param_b if param_b > 0.0 else 325.0)
			ForestArt.draw_sap_runes(_mid_layer, ra, _sap_rune_a_lit, rb, _sap_rune_b_lit, timer)
		"pollen_dream_drift":
			ForestArt.draw_pollen_drift(_mid_layer, _pollen_motes, _pollen_floating, timer)
		"fairy_ring_portal":
			var r_a := Vector2(trigger_x if trigger_x > 0.0 else 505.0, trigger_y if trigger_y > 0.0 else 410.0)
			var r_b := Vector2(param_a if param_a > 0.0 else 185.0, param_b if param_b > 0.0 else 225.0)
			ForestArt.draw_fairy_rings(_mid_layer, r_a, r_b, _fairy_charge, _fairy_warp_fx, timer)
		"cicada_swarm_raft":
			ForestArt.draw_cicada_swarm(_mid_layer, _cicada_pos, Vector2(116.0, 16.0), timer)
		"wisp_lantern_escort":
			ForestArt.draw_wisp_orb(_mid_layer, _wisp_pos, timer)

func _draw_fg() -> void:
	var font := ThemeDB.fallback_font
	match event_type:
		"frozen_pendulum", "blackout_swap", "betraying_arrow":
			if _blackout_alpha > 0.01:
				_fg_layer.draw_rect(Rect2(-420.0, -280.0, 1800.0, 1100.0), Color(0.01, 0.01, 0.02, _blackout_alpha), true)
		"haunted_gust":
			ParanormalArt.draw_haunted_gust(_fg_layer, timer, _wind_active)
		"fake_win_glitch":
			ParanormalArt.draw_fake_win_glitch_fg(_fg_layer, _fake_win_phase, timer, font)
		"room_tilt_vertigo":
			if absf(_cam_tilt_rad) > 0.001:
				# Outer wall-colored overscan borders prevent non-rotating backdrop from peeking at tilted corners on 16:9 mobile
				var ch := _get_current_chapter()
				var wall_col := Color("#1c1a22")
				if ch == 2: wall_col = Color("#0d131f")
				elif ch == 3: wall_col = Color("#062319")
				elif ch == 4: wall_col = Color("#291c14")
				elif ch == 5: wall_col = Color("#1a0505")
				_fg_layer.draw_rect(Rect2(-320.0, -240.0, 1600.0, 244.0), wall_col, true)
				_fg_layer.draw_rect(Rect2(-320.0, 536.0, 1600.0, 260.0), wall_col, true)
				_fg_layer.draw_rect(Rect2(-320.0, -240.0, 324.0, 1040.0), wall_col, true)
				_fg_layer.draw_rect(Rect2(956.0, -240.0, 324.0, 1040.0), wall_col, true)
		"time_heartbeat_slowmo":
			ParanormalArt.draw_slowmo_fg(_fg_layer, Vector2(480.0, 270.0), _slowmo_active, _slowmo_pulse_r)
		"mind_flip_mist":
			var inv_y := param_a if param_a > 0.0 else 352.0
			ParanormalArt.draw_mind_flip_sigils(_fg_layer, inv_y, timer)
		"rising_shadow_tide":
			ParanormalArt.draw_rising_shadow_tide(_fg_layer, _tide_y, timer)
		"reality_awakening_finale":
			if _monolith_flash > 0.01:
				_fg_layer.draw_rect(Rect2(-420.0, -280.0, 1800.0, 1100.0), Color(0.95, 0.28, 0.38, _monolith_flash * 0.36), true)
		# Chapter 2 (Frost Peak) FG
		"frost_breath_echo":
			pass
		"snowdrift_bury":
			FrostArt.draw_snowdrift_wave(_fg_layer, _snow_wave_x, 420.0, param_b if param_b > 0.0 else 366.0, _snow_wave_active, timer)
		"blizzard_whiteout_gust":
			FrostArt.draw_blizzard_whiteout(_fg_layer, _wind_active, _blizzard_wind_dir, _blizzard_alpha, timer)
		"avalanche_wall_chase":
			FrostArt.draw_avalanche_wall(_fg_layer, _avalanche_x, _avalanche_started, timer)
		"frost_crown_finale":
			if _crown_flash > 0.01:
				_fg_layer.draw_rect(Rect2(-420.0, -280.0, 1800.0, 1100.0), Color(0.62, 0.92, 1.0, _crown_flash * 0.34), true)
		# Chapter 3 (Emerald Woods) FG
		"canopy_eclipse_dark":
			ForestArt.draw_canopy_eclipse(_fg_layer, _eclipse_beams, 86.0, timer)
		"weeping_willow_curtain":
			var ppos_w := player_ref.global_position if (player_ref and is_instance_valid(player_ref)) else Vector2(-999, -999)
			ForestArt.draw_willow_curtain(_fg_layer, ppos_w, timer)
		"wisp_lantern_escort":
			pass
		"overgrowth_ceiling_vines":
			ForestArt.draw_overgrowth_vines(_fg_layer, _overgrowth_y, _overgrowth_started, timer)
