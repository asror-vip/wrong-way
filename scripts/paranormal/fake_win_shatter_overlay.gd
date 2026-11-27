extends CanvasLayer
class_name FakeWinShatterOverlay

## Ultra-Convincing Shattering-Mirror Fake Victory Screen (Level 12 Paranormal Event)
## Displays an exact visual replica of WinOverlay + real "win" SFX.
## Touching/clicking ANYWHERE (or pressing a key on PC) cracks the screen like a mirror
## from that exact impact point, plays crisp glass shatter SFX, and bursts the entire
## overlay into tumbling, gravity-falling reflective glass shards revealing the live level.

signal shatter_started(impact_pos: Vector2)
signal shatter_finished

enum State { IDLE, SHOWING, CRACKING, SHATTERED, DONE }

const STYLE_WHITE := preload("res://resources/themes/btn_capsule_white.tres")
const STYLE_WHITE_HOV := preload("res://resources/themes/btn_capsule_white_hover.tres")
const STYLE_WHITE_PRESS := preload("res://resources/themes/btn_capsule_white_pressed.tres")
const STYLE_GLASS := preload("res://resources/themes/btn_capsule_glass.tres")
const STYLE_GLASS_HOV := preload("res://resources/themes/btn_capsule_glass_hover.tres")
const STYLE_GLASS_PRESS := preload("res://resources/themes/btn_capsule_glass_pressed.tres")
const STYLE_FOCUS := preload("res://resources/themes/btn_focus_empty.tres")

const CRACK_HOLD_SEC := 0.13
const SHATTER_DURATION_SEC := 1.45
const TOUCH_GRACE_SEC := 0.14
const KEY_GRACE_SEC := 0.22

var state: State = State.IDLE
var last_impact_pos: Vector2 = Vector2(480.0, 270.0)
var _elapsed_in_state: float = 0.0
var _anim_time: float = 0.0

var _root_ctrl: Control = null
var _fake_win_root: Control = null
var _spotlight_fx: Control = null
var _line_accent: Control = null
var _crown_icon: TextureRect = null
var _win_title: Label = null
var _subtitle: Label = null
var _star_box: HBoxContainer = null
var _stats_label: Label = null
var _next_btn: Button = null
var _replay_btn: Button = null
var _map_btn: Button = null
var _home_btn: Button = null
var _fx_canvas: Control = null

var _crack_rays: Array = []      # Array of PackedVector2Array
var _crack_rings: Array = []     # Array of PackedVector2Array
var _shards: Array = []          # Array of Dictionary
var _splinters: Array = []       # Array of Dictionary

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()

func _build_ui() -> void:
	_root_ctrl = Control.new()
	_root_ctrl.name = "FakeWinContainer"
	_root_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root_ctrl)

	# --- Exact WinOverlay Replica ---
	_fake_win_root = Control.new()
	_fake_win_root.name = "FakeWinRoot"
	_fake_win_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fake_win_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_ctrl.add_child(_fake_win_root)

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.04, 0.05, 0.07, 0.82)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fake_win_root.add_child(backdrop)

	_spotlight_fx = Control.new()
	_spotlight_fx.name = "SpotlightFX"
	_spotlight_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_spotlight_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spotlight_fx.draw.connect(_on_spotlight_draw)
	_fake_win_root.add_child(_spotlight_fx)

	_crown_icon = TextureRect.new()
	_crown_icon.name = "CrownIcon"
	_crown_icon.custom_minimum_size = Vector2(44, 44)
	_crown_icon.anchor_left = 0.5
	_crown_icon.anchor_right = 0.5
	_crown_icon.offset_left = -22.0
	_crown_icon.offset_top = 85.0
	_crown_icon.offset_right = 22.0
	_crown_icon.offset_bottom = 129.0
	_crown_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_crown_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_crown_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icf = get_node_or_null("/root/IconFactory")
	if icf:
		_crown_icon.texture = icf.get_icon("crown", 1.8)
	_fake_win_root.add_child(_crown_icon)

	_line_accent = Control.new()
	_line_accent.name = "LineAccent"
	_line_accent.custom_minimum_size = Vector2(360, 10)
	_line_accent.anchor_left = 0.5
	_line_accent.anchor_right = 0.5
	_line_accent.offset_left = -180.0
	_line_accent.offset_top = 138.0
	_line_accent.offset_right = 180.0
	_line_accent.offset_bottom = 148.0
	_line_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line_accent.draw.connect(_on_line_accent_draw)
	_fake_win_root.add_child(_line_accent)

	_win_title = Label.new()
	_win_title.name = "WinTitle"
	_win_title.anchor_left = 0.5
	_win_title.anchor_right = 0.5
	_win_title.offset_left = -260.0
	_win_title.offset_top = 150.0
	_win_title.offset_right = 260.0
	_win_title.offset_bottom = 185.0
	_win_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win_title.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0))
	_win_title.add_theme_font_size_override("font_size", 22)
	_win_title.add_theme_constant_override("letter_spacing", 4)
	_win_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fake_win_root.add_child(_win_title)

	_subtitle = Label.new()
	_subtitle.name = "Subtitle"
	_subtitle.anchor_left = 0.5
	_subtitle.anchor_right = 0.5
	_subtitle.offset_left = -200.0
	_subtitle.offset_top = 186.0
	_subtitle.offset_right = 200.0
	_subtitle.offset_bottom = 210.0
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_color_override("font_color", Color(0.80, 0.85, 0.95))
	_subtitle.add_theme_font_size_override("font_size", 14)
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fake_win_root.add_child(_subtitle)

	_star_box = HBoxContainer.new()
	_star_box.name = "StarBox"
	_star_box.anchor_left = 0.5
	_star_box.anchor_right = 0.5
	_star_box.offset_left = -120.0
	_star_box.offset_top = 222.0
	_star_box.offset_right = 120.0
	_star_box.offset_bottom = 276.0
	_star_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_star_box.add_theme_constant_override("separation", 16)
	_star_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fake_win_root.add_child(_star_box)

	if icf:
		for _i in range(3):
			var star_icon: TextureRect = icf.create_texture_rect("star_white", Vector2(44, 44), 1.7)
			_star_box.add_child(star_icon)

	_stats_label = Label.new()
	_stats_label.name = "StatsLabel"
	_stats_label.anchor_left = 0.5
	_stats_label.anchor_right = 0.5
	_stats_label.offset_left = -200.0
	_stats_label.offset_top = 286.0
	_stats_label.offset_right = 200.0
	_stats_label.offset_bottom = 310.0
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.add_theme_color_override("font_color", Color(0.68, 0.74, 0.86))
	_stats_label.add_theme_font_size_override("font_size", 13)
	_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fake_win_root.add_child(_stats_label)

	var btn_row := HBoxContainer.new()
	btn_row.name = "BtnRow"
	btn_row.anchor_left = 0.5
	btn_row.anchor_right = 0.5
	btn_row.offset_left = -180.0
	btn_row.offset_top = 335.0
	btn_row.offset_right = 180.0
	btn_row.offset_bottom = 380.0
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 14)
	btn_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fake_win_root.add_child(btn_row)

	_next_btn = Button.new()
	_next_btn.name = "NextBtn"
	_next_btn.custom_minimum_size = Vector2(175, 44)
	_next_btn.focus_mode = Control.FOCUS_NONE
	_next_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_next_btn.add_theme_color_override("font_color", Color(0.06, 0.07, 0.1))
	_next_btn.add_theme_font_size_override("font_size", 14)
	_next_btn.add_theme_stylebox_override("normal", STYLE_WHITE)
	_next_btn.add_theme_stylebox_override("hover", STYLE_WHITE_HOV)
	_next_btn.add_theme_stylebox_override("pressed", STYLE_WHITE_PRESS)
	_next_btn.add_theme_stylebox_override("focus", STYLE_FOCUS)
	if icf:
		_next_btn.icon = icf.get_icon("play_dark", 0.85)
	btn_row.add_child(_next_btn)

	_replay_btn = Button.new()
	_replay_btn.name = "ReplayBtn"
	_replay_btn.custom_minimum_size = Vector2(140, 44)
	_replay_btn.focus_mode = Control.FOCUS_NONE
	_replay_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_replay_btn.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
	_replay_btn.add_theme_font_size_override("font_size", 14)
	_replay_btn.add_theme_stylebox_override("normal", STYLE_GLASS)
	_replay_btn.add_theme_stylebox_override("hover", STYLE_GLASS_HOV)
	_replay_btn.add_theme_stylebox_override("pressed", STYLE_GLASS_PRESS)
	_replay_btn.add_theme_stylebox_override("focus", STYLE_FOCUS)
	if icf:
		_replay_btn.icon = icf.get_icon("restart", 0.8)
	btn_row.add_child(_replay_btn)

	_map_btn = Button.new()
	_map_btn.name = "MapBtn"
	_map_btn.custom_minimum_size = Vector2(44, 44)
	_map_btn.offset_left = 24.0
	_map_btn.offset_top = 20.0
	_map_btn.offset_right = 68.0
	_map_btn.offset_bottom = 64.0
	_map_btn.focus_mode = Control.FOCUS_NONE
	_map_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_btn.add_theme_stylebox_override("normal", STYLE_FOCUS)
	_map_btn.add_theme_stylebox_override("hover", STYLE_FOCUS)
	_map_btn.add_theme_stylebox_override("pressed", STYLE_FOCUS)
	_map_btn.add_theme_stylebox_override("focus", STYLE_FOCUS)
	_map_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_map_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	if icf:
		_map_btn.icon = icf.get_icon("circle_btn_back", 1.0)
	_fake_win_root.add_child(_map_btn)

	_home_btn = Button.new()
	_home_btn.name = "HomeBtn"
	_home_btn.custom_minimum_size = Vector2(44, 44)
	_home_btn.anchor_left = 1.0
	_home_btn.anchor_right = 1.0
	_home_btn.offset_left = -68.0
	_home_btn.offset_top = 20.0
	_home_btn.offset_right = -24.0
	_home_btn.offset_bottom = 64.0
	_home_btn.focus_mode = Control.FOCUS_NONE
	_home_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home_btn.add_theme_stylebox_override("normal", STYLE_FOCUS)
	_home_btn.add_theme_stylebox_override("hover", STYLE_FOCUS)
	_home_btn.add_theme_stylebox_override("pressed", STYLE_FOCUS)
	_home_btn.add_theme_stylebox_override("focus", STYLE_FOCUS)
	_home_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_home_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	if icf:
		_home_btn.icon = icf.get_icon("circle_btn_home", 1.0)
	_fake_win_root.add_child(_home_btn)

	# --- Mirror Crack & Shattered Shards FX Canvas ---
	_fx_canvas = Control.new()
	_fx_canvas.name = "MirrorShatterFX"
	_fx_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_canvas.draw.connect(_on_fx_draw)
	_root_ctrl.add_child(_fx_canvas)

func _draw_diamond(canvas: Control, center: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(center.x, center.y - r),
		Vector2(center.x + r, center.y),
		Vector2(center.x, center.y + r),
		Vector2(center.x - r, center.y)
	])
	canvas.draw_colored_polygon(pts, col)

func _on_spotlight_draw() -> void:
	if not _spotlight_fx:
		return
	var center_x := _spotlight_fx.size.x * 0.5
	var top_w := 60.0
	var bot_w := 240.0
	var beam_h := 380.0
	_spotlight_fx.draw_colored_polygon(PackedVector2Array([
		Vector2(center_x - top_w, 0.0),
		Vector2(center_x + top_w, 0.0),
		Vector2(center_x + bot_w, beam_h),
		Vector2(center_x - bot_w, beam_h)
	]), Color(0.9, 0.95, 1.0, 0.04))
	_spotlight_fx.draw_colored_polygon(PackedVector2Array([
		Vector2(center_x - 30.0, 0.0),
		Vector2(center_x + 30.0, 0.0),
		Vector2(center_x + 140.0, beam_h - 40.0),
		Vector2(center_x - 140.0, beam_h - 40.0)
	]), Color(0.95, 0.98, 1.0, 0.03))
	var diamonds := [
		Vector2(center_x - 150.0, 160.0), Vector2(center_x + 150.0, 150.0),
		Vector2(center_x - 180.0, 240.0), Vector2(center_x + 180.0, 245.0),
		Vector2(center_x - 130.0, 280.0), Vector2(center_x + 130.0, 285.0)
	]
	for pt in diamonds:
		_draw_diamond(_spotlight_fx, pt, 3.5, Color(1, 1, 1, 0.35))

func _on_line_accent_draw() -> void:
	if not _line_accent:
		return
	var w := _line_accent.size.x
	var cy := _line_accent.size.y * 0.5
	var cx := w * 0.5
	var col_mid := Color(1, 1, 1, 0.45)
	_line_accent.draw_line(Vector2(20, cy), Vector2(cx - 30, cy), col_mid, 1.0)
	_line_accent.draw_line(Vector2(cx + 30, cy), Vector2(w - 20, cy), col_mid, 1.0)
	_draw_diamond(_line_accent, Vector2(cx, cy), 3.0, Color(1, 1, 1, 0.6))

func open_fake_win(elapsed_sec: int, deaths: int) -> void:
	_crack_rays.clear()
	_crack_rings.clear()
	_shards.clear()
	_splinters.clear()
	_elapsed_in_state = 0.0
	_anim_time = 0.0
	state = State.SHOWING

	var loc = get_node_or_null("/root/LocaleManager")
	if _win_title:
		_win_title.text = loc.t("level_complete") if loc else "LEVEL COMPLETE"
	if _subtitle:
		_subtitle.text = loc.t("great_job") if loc else "Great Job!"
	if _stats_label:
		_stats_label.text = loc.t("win_stats", [maxi(1, elapsed_sec), deaths]) if loc else ""
	if _next_btn:
		_next_btn.text = "  " + (loc.t("btn_next_lvl") if loc else "NEXT LEVEL")
	if _replay_btn:
		_replay_btn.text = "  " + (loc.t("btn_restart") if loc else "Restart")

	if _fake_win_root:
		_fake_win_root.visible = true
		_fake_win_root.position = Vector2.ZERO
		_fake_win_root.modulate.a = 1.0
	visible = true
	if _spotlight_fx: _spotlight_fx.queue_redraw()
	if _line_accent: _line_accent.queue_redraw()
	if _fx_canvas: _fx_canvas.queue_redraw()

	var snd = get_node_or_null("/root/SoundManager")
	if snd:
		snd.play("win")

func reset_overlay() -> void:
	state = State.IDLE
	_elapsed_in_state = 0.0
	_crack_rays.clear()
	_crack_rings.clear()
	_shards.clear()
	_splinters.clear()
	if _fake_win_root:
		_fake_win_root.visible = false
		_fake_win_root.position = Vector2.ZERO
	visible = false
	if _fx_canvas:
		_fx_canvas.queue_redraw()

func _get_canvas_size() -> Vector2:
	if _root_ctrl and _root_ctrl.size.x > 10.0 and _root_ctrl.size.y > 10.0:
		return _root_ctrl.size
	return UIResponsive.get_viewport_size(_root_ctrl)

func _to_canvas_pos(screen_pos: Vector2) -> Vector2:
	if _root_ctrl and _root_ctrl.is_inside_tree():
		return _root_ctrl.get_global_transform_with_canvas().affine_inverse() * screen_pos
	return screen_pos

func _input(event: InputEvent) -> void:
	if state != State.SHOWING:
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			get_viewport().set_input_as_handled()
			if _elapsed_in_state >= TOUCH_GRACE_SEC:
				trigger_shatter(_to_canvas_pos(st.position))
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if event.device == InputEvent.DEVICE_ID_EMULATION:
				return
			get_viewport().set_input_as_handled()
			if _elapsed_in_state >= TOUCH_GRACE_SEC:
				trigger_shatter(_to_canvas_pos(mb.position))
		return

	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			get_viewport().set_input_as_handled()
			if _elapsed_in_state >= KEY_GRACE_SEC:
				var vp := _get_canvas_size()
				trigger_shatter(Vector2(vp.x * 0.5, vp.y * 0.56))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and state == State.SHOWING:
		var vp := _get_canvas_size()
		trigger_shatter(Vector2(vp.x * 0.5, vp.y * 0.50))

func trigger_shatter(impact_pos: Vector2) -> void:
	if state != State.SHOWING:
		return
	var vp := _get_canvas_size()
	last_impact_pos = Vector2(
		clampf(impact_pos.x, 12.0, maxf(12.0, vp.x - 12.0)),
		clampf(impact_pos.y, 12.0, maxf(12.0, vp.y - 12.0))
	)
	state = State.CRACKING
	_elapsed_in_state = 0.0

	_build_mirror_fracture(last_impact_pos, vp)

	var snd = get_node_or_null("/root/SoundManager")
	if snd:
		snd.play("mirror_shatter")
	var sm = get_node_or_null("/root/SaveManager")
	var gm = get_node_or_null("/root/GameManager")
	if gm and (sm == null or sm.shake_enabled):
		gm.request_screen_shake.emit(11.0)
	if _fx_canvas:
		_fx_canvas.queue_redraw()

func _build_mirror_fracture(impact: Vector2, vp: Vector2) -> void:
	_crack_rays.clear()
	_crack_rings.clear()
	_shards.clear()
	_splinters.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = int(impact.x * 31.0 + impact.y * 97.0) ^ 0x5A3F19

	var max_dist := maxf(
		maxf(impact.distance_to(Vector2(0, 0)), impact.distance_to(Vector2(vp.x, 0))),
		maxf(impact.distance_to(Vector2(0, vp.y)), impact.distance_to(Vector2(vp.x, vp.y)))
	) + 48.0

	var ray_count := 12
	var ray_angles: Array[float] = []
	for i in range(ray_count):
		var base_ang := (TAU * float(i)) / float(ray_count)
		ray_angles.append(base_ang + rng.randf_range(-0.16, 0.16))
	ray_angles.sort()

	var ring_radii: Array[float] = [44.0, 122.0, 265.0, max_dist]
	# Grid of fracture vertices: vertices[ring_idx][ray_idx]
	var ring_verts: Array = []
	for r_idx in range(ring_radii.size()):
		var r_base: float = ring_radii[r_idx]
		var verts_for_ring: Array[Vector2] = []
		for i in range(ray_count):
			var ang: float = ray_angles[i]
			var jitter_r: float = r_base * rng.randf_range(0.84, 1.18) if r_idx < ring_radii.size() - 1 else r_base
			var jitter_a: float = rng.randf_range(-0.07, 0.07)
			verts_for_ring.append(impact + Vector2(cos(ang + jitter_a), sin(ang + jitter_a)) * jitter_r)
		ring_verts.append(verts_for_ring)

	# 1. Primary radial spiderweb fracture lines
	for i in range(ray_count):
		var pts := PackedVector2Array([impact])
		for r_idx in range(ring_radii.size()):
			pts.append(ring_verts[r_idx][i])
		_crack_rays.append(pts)

	# 2. Concentric cross-cracks
	for r_idx in range(ring_radii.size() - 1):
		var ring_pts := PackedVector2Array()
		for i in range(ray_count):
			ring_pts.append(ring_verts[r_idx][i])
		ring_pts.append(ring_verts[r_idx][0])
		_crack_rings.append(ring_pts)

	# 3. Shattered mirror shards from every radial wedge
	var ui_center_rect := Rect2(vp.x * 0.5 - 220.0, 80.0, 440.0, 310.0)
	for r_idx in range(ring_radii.size()):
		for i in range(ray_count):
			var next_i := (i + 1) % ray_count
			var poly := PackedVector2Array()
			if r_idx == 0:
				poly = PackedVector2Array([impact, ring_verts[0][i], ring_verts[0][next_i]])
			else:
				poly = PackedVector2Array([
					ring_verts[r_idx - 1][i],
					ring_verts[r_idx][i],
					ring_verts[r_idx][next_i],
					ring_verts[r_idx - 1][next_i]
				])

			var centroid := Vector2.ZERO
			for p in poly:
				centroid += p
			centroid /= float(poly.size())

			# Skip outer shards completely outside viewport
			if centroid.x < -120.0 or centroid.x > vp.x + 120.0 or centroid.y < -120.0 or centroid.y > vp.y + 120.0:
				continue

			var local_pts := PackedVector2Array()
			for p in poly:
				local_pts.append(p - centroid)

			var out_dir := (centroid - impact).normalized()
			if out_dir.length_squared() < 0.01:
				out_dir = Vector2.UP
			var dist := centroid.distance_to(impact)
			var impulse := lerpf(390.0, 145.0, clampf(dist / 420.0, 0.0, 1.0)) * rng.randf_range(0.75, 1.25)
			var vel := out_dir * impulse + Vector2(rng.randf_range(-55.0, 55.0), -rng.randf_range(65.0, 195.0))

			var overlaps_ui := ui_center_rect.has_point(centroid)
			var base_shade := rng.randf_range(0.05, 0.11)
			var fill_col := Color(base_shade, base_shade + 0.02, base_shade + 0.06, 0.88)
			if overlaps_ui:
				fill_col = Color(base_shade + 0.06, base_shade + 0.09, base_shade + 0.14, 0.90)

			_shards.append({
				"pos": centroid,
				"local_pts": local_pts,
				"vel": vel,
				"rot": 0.0,
				"rot_vel": rng.randf_range(-6.8, 6.8),
				"glint_phase": rng.randf_range(0.0, TAU),
				"glint_speed": rng.randf_range(6.0, 13.0),
				"fill_col": fill_col,
				"overlaps_ui": overlaps_ui
			})

	# 4. Crisp sparkling glass micro-splinters spraying from impact point
	for _s in range(26):
		var a := rng.randf_range(0.0, TAU)
		var spd := rng.randf_range(160.0, 520.0)
		_splinters.append({
			"pos": impact + Vector2(cos(a), sin(a)) * rng.randf_range(2.0, 14.0),
			"vel": Vector2(cos(a) * spd, sin(a) * spd - rng.randf_range(40.0, 160.0)),
			"size": rng.randf_range(2.5, 6.5),
			"rot": rng.randf_range(0.0, TAU),
			"rot_vel": rng.randf_range(-14.0, 14.0),
			"life": rng.randf_range(0.55, 1.15)
		})

func _process(delta: float) -> void:
	if state == State.IDLE or state == State.DONE:
		return

	_elapsed_in_state += delta

	if state == State.SHOWING:
		_anim_time += delta * 2.0
		if _crown_icon:
			_crown_icon.position.y = 85.0 + sin(_anim_time) * 3.5
		return

	if state == State.CRACKING:
		if _fake_win_root:
			_fake_win_root.position = Vector2(randf_range(-3.5, 3.5), randf_range(-3.5, 3.5))
		if _fx_canvas:
			_fx_canvas.queue_redraw()
		if _elapsed_in_state >= CRACK_HOLD_SEC:
			state = State.SHATTERED
			_elapsed_in_state = 0.0
			if _fake_win_root:
				_fake_win_root.visible = false
				_fake_win_root.position = Vector2.ZERO
			shatter_started.emit(last_impact_pos)
			if _fx_canvas:
				_fx_canvas.queue_redraw()
		return

	if state == State.SHATTERED:
		var gravity := 1780.0
		for sh in _shards:
			sh["vel"] = (sh["vel"] as Vector2) + Vector2(0.0, gravity * delta)
			sh["pos"] = (sh["pos"] as Vector2) + (sh["vel"] as Vector2) * delta
			sh["rot"] = float(sh["rot"]) + float(sh["rot_vel"]) * delta
			sh["glint_phase"] = float(sh["glint_phase"]) + float(sh["glint_speed"]) * delta
		for sp in _splinters:
			sp["vel"] = (sp["vel"] as Vector2) + Vector2(0.0, 1400.0 * delta)
			sp["pos"] = (sp["pos"] as Vector2) + (sp["vel"] as Vector2) * delta
			sp["rot"] = float(sp["rot"]) + float(sp["rot_vel"]) * delta
			sp["life"] = maxf(0.0, float(sp["life"]) - delta)
		if _fx_canvas:
			_fx_canvas.queue_redraw()
		if _elapsed_in_state >= SHATTER_DURATION_SEC:
			state = State.DONE
			visible = false
			shatter_finished.emit()

func _on_fx_draw() -> void:
	if not _fx_canvas:
		return

	if state == State.CRACKING:
		var prog := clampf(_elapsed_in_state / CRACK_HOLD_SEC, 0.0, 1.0)
		# Crisp white-cyan impact flash right at finger/click point
		var flash_r := lerpf(16.0, 110.0, prog)
		_fx_canvas.draw_circle(last_impact_pos, flash_r, Color(0.85, 0.96, 1.0, (1.0 - prog) * 0.42))
		_fx_canvas.draw_circle(last_impact_pos, 10.0, Color(1.0, 1.0, 1.0, 0.95))

		# Spiderweb fracture lines
		for ray in _crack_rays:
			var pts := ray as PackedVector2Array
			_fx_canvas.draw_polyline(pts, Color(0.75, 0.94, 1.0, 0.55), 3.4, true)
			_fx_canvas.draw_polyline(pts, Color(1.0, 1.0, 1.0, 0.96), 1.5, true)
		for ring in _crack_rings:
			var rpts := ring as PackedVector2Array
			_fx_canvas.draw_polyline(rpts, Color(0.86, 0.96, 1.0, 0.78), 1.3, true)
		return

	if state == State.SHATTERED:
		var fade := 1.0 - maxf(0.0, (_elapsed_in_state - 0.95) / 0.50)
		fade = clampf(fade, 0.0, 1.0)

		# Brief fading starburst at impact epicenter
		if _elapsed_in_state < 0.22:
			var ba := (1.0 - _elapsed_in_state / 0.22) * 0.55
			_fx_canvas.draw_circle(last_impact_pos, 26.0 + _elapsed_in_state * 180.0, Color(0.85, 0.96, 1.0, ba))

		# Tumbling reflective glass/mirror shards
		for sh in _shards:
			var center: Vector2 = sh["pos"]
			var rot: float = float(sh["rot"])
			var local_pts: PackedVector2Array = sh["local_pts"]
			var cs := cos(rot)
			var sn := sin(rot)
			# Simulated 3D tumble foreshortening along one axis
			var tilt := 0.55 + 0.45 * absf(cos(float(sh["glint_phase"]) * 0.5))

			var world_pts := PackedVector2Array()
			world_pts.resize(local_pts.size())
			for idx in range(local_pts.size()):
				var lp := Vector2(local_pts[idx].x, local_pts[idx].y * tilt)
				world_pts[idx] = center + Vector2(lp.x * cs - lp.y * sn, lp.x * sn + lp.y * cs)

			var glint := pow(maxf(0.0, sin(float(sh["glint_phase"]))), 3.0)
			var base_col: Color = sh["fill_col"]
			var col := Color(
				lerpf(base_col.r, 0.88, glint * 0.72),
				lerpf(base_col.g, 0.96, glint * 0.76),
				lerpf(base_col.b, 1.00, glint * 0.80),
				base_col.a * fade
			)
			_fx_canvas.draw_colored_polygon(world_pts, col)

			# Crisp frosty mirror edge highlight
			var outline := PackedVector2Array(world_pts)
			outline.append(world_pts[0])
			var edge_alpha := (0.65 + glint * 0.35) * fade
			_fx_canvas.draw_polyline(outline, Color(0.84, 0.95, 1.0, edge_alpha), 1.5, true)

			# Specular diagonal reflection glint across mirror facet
			if world_pts.size() >= 3 and (glint > 0.25 or bool(sh["overlaps_ui"])):
				var mid_a := world_pts[0].lerp(world_pts[1], 0.35)
				var mid_b := world_pts[1].lerp(world_pts[2], 0.65)
				_fx_canvas.draw_line(mid_a, mid_b, Color(1.0, 1.0, 1.0, (0.28 + glint * 0.55) * fade), 1.6, true)

		# Sparkling glass dust micro-splinters
		for sp in _splinters:
			var life: float = float(sp["life"])
			if life <= 0.0:
				continue
			var pos: Vector2 = sp["pos"]
			var sz: float = float(sp["size"])
			var a: float = clampf(life * 1.4, 0.0, 1.0) * fade
			var r: float = float(sp["rot"])
			var pts := PackedVector2Array([
				pos + Vector2(cos(r), sin(r)) * sz,
				pos + Vector2(cos(r + 2.1), sin(r + 2.1)) * sz * 0.65,
				pos + Vector2(cos(r + 4.2), sin(r + 4.2)) * sz * 0.85
			])
			_fx_canvas.draw_colored_polygon(pts, Color(0.92, 0.98, 1.0, a))
