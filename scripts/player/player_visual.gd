extends Node2D

# Wrong Way - Expressive Living Player Visual
# - Soft atmospheric rim-glow & crisp luminous outline so the hero pops on any biome
# - Breathing idle animation, run lean/bob, cute animated feet
# - Expressive eyes: random blinking, velocity-tracked pupils with specular glints,
#   dash determination, panic O_O when an active trap is nearby, happy ^^ at exit door

@onready var controller: CharacterBody2D = get_parent()

var _time: float = 0.0
var _run_phase: float = 0.0
var _current_tilt: float = 0.0
var _current_pupil: Vector2 = Vector2.ZERO

# Blinking
var _is_blinking: bool = false
var _blink_timer: float = 2.8
var _blink_left: float = 0.0

# Expressions & FX
var _panic_level: float = 0.0
var _panic_scan_timer: float = 0.0
var _near_active_danger: bool = false
var _spawn_flash: float = 0.0
var _dash_glow: float = 0.0

func _ready() -> void:
	_blink_timer = randf_range(2.2, 4.4)

func trigger_spawn_flash() -> void:
	_spawn_flash = 1.0

func _process(delta: float) -> void:
	_time += delta
	if _spawn_flash > 0.0:
		_spawn_flash = maxf(0.0, _spawn_flash - delta * 4.0)

	var vel := Vector2.ZERO
	var on_floor := true
	var facing_dir := 1
	var is_dashing := false
	var is_entering := false

	if controller:
		if "velocity" in controller:
			vel = controller.velocity
		if controller.has_method("is_on_floor"):
			on_floor = controller.is_on_floor()
		if "facing" in controller:
			facing_dir = controller.facing
		if "is_dashing" in controller:
			is_dashing = controller.is_dashing
		if "is_entering_door" in controller:
			is_entering = controller.is_entering_door

	# Dash glow pulse
	var target_dash_glow := 1.0 if is_dashing else 0.0
	_dash_glow = move_toward(_dash_glow, target_dash_glow, delta * 8.0)

	# Run cycle & body tilt
	var speed_ratio := clampf(absf(vel.x) / 280.0, 0.0, 1.5)
	if on_floor and absf(vel.x) > 15.0:
		_run_phase += delta * 15.5 * maxf(0.7, speed_ratio)
	else:
		_run_phase = fmod(_run_phase, TAU)

	var target_tilt := 0.0
	if is_dashing:
		target_tilt = signf(vel.x) * 0.22 if absf(vel.x) > 10.0 else float(facing_dir) * 0.22
	elif on_floor:
		target_tilt = clampf(vel.x / 280.0, -1.0, 1.0) * 0.11
	else:
		target_tilt = clampf(vel.x / 280.0, -1.0, 1.0) * 0.08 + clampf(vel.y / 900.0, -0.06, 0.06) * float(facing_dir)
	_current_tilt = lerpf(_current_tilt, target_tilt, minf(1.0, delta * 16.0))
	rotation = _current_tilt

	# Periodic lightweight active-danger scan (never spoils hidden camouflaged traps)
	_panic_scan_timer -= delta
	if _panic_scan_timer <= 0.0:
		_panic_scan_timer = 0.10
		_near_active_danger = _check_nearby_active_danger()

	var fast_fall_panic := (not on_floor and vel.y > 460.0)
	var target_panic := 1.0 if (_near_active_danger or fast_fall_panic) and not is_entering and not is_dashing else 0.0
	_panic_level = move_toward(_panic_level, target_panic, delta * 10.0)

	# Blinking (skip during panic, dash, or victory)
	if _panic_level > 0.2 or is_dashing or is_entering:
		_is_blinking = false
	else:
		if _is_blinking:
			_blink_left -= delta
			if _blink_left <= 0.0:
				_is_blinking = false
				_blink_timer = randf_range(2.4, 4.8)
		else:
			_blink_timer -= delta
			if _blink_timer <= 0.0:
				_is_blinking = true
				_blink_left = 0.11

	# Velocity-tracked pupil offset
	var look_x := float(facing_dir) * 2.0
	if absf(vel.x) > 30.0:
		look_x = signf(vel.x) * 2.4
	var look_y := 0.0
	if not on_floor:
		if vel.y < -80.0:
			look_y = -2.2
		elif vel.y > 120.0:
			look_y = clampf((vel.y - 120.0) / 360.0, 0.4, 2.3)
	var target_pupil := Vector2(look_x, look_y)
	_current_pupil = _current_pupil.lerp(target_pupil, minf(1.0, delta * 18.0))

	queue_redraw()

func _check_nearby_active_danger() -> bool:
	if not controller or not is_inside_tree():
		return false
	var p_pos := controller.global_position - Vector2(0.0, 16.0)
	var traps := get_tree().get_nodes_in_group("traps")
	for t in traps:
		if not is_instance_valid(t) or not (t is Node2D):
			continue
		if not t.visible:
			continue
		var dist_sq := p_pos.distance_squared_to(t.global_position)
		if dist_sq > 92.0 * 92.0:
			continue
		# React only to visibly active / moving threats (never spoil dormant hidden traps)
		if "is_triggered" in t and not bool(t.get("is_triggered")):
			continue
		if "triggered" in t and not bool(t.get("triggered")):
			continue
		if "is_active" in t and not bool(t.get("is_active")):
			continue
		if "state" in t:
			var st = t.get("state")
			if st is int and st == 0:
				continue
			if st is String and (st == "idle" or st == "waiting"):
				continue
		return true
	return false

func _get_biome_accent() -> Color:
	var ch := 1
	if is_inside_tree():
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("get_current_chapter"):
			ch = gm.get_current_chapter()
	match ch:
		2:
			return Color(0.45, 0.85, 1.0, 1.0) # Muz moviy
		3:
			return Color(0.42, 0.96, 0.68, 1.0) # Zumrad o'rmon
		4:
			return Color(1.0, 0.80, 0.40, 1.0) # Oltin sahro
		5:
			return Color(1.0, 0.46, 0.36, 1.0) # Lava
		_:
			return Color(0.76, 0.86, 1.0, 1.0) # Limbo kumush-oq

func _draw() -> void:
	var vel := Vector2.ZERO
	var on_floor := true
	var is_dashing := false
	var is_entering := false
	if controller:
		if "velocity" in controller:
			vel = controller.velocity
		if controller.has_method("is_on_floor"):
			on_floor = controller.is_on_floor()
		if "is_dashing" in controller:
			is_dashing = controller.is_dashing
		if "is_entering_door" in controller:
			is_entering = controller.is_entering_door

	var accent := _get_biome_accent()
	var is_running := on_floor and absf(vel.x) > 20.0
	var breath := sin(_time * 3.1) * 0.028 if not is_running else 0.0
	var run_bob := -absf(sin(_run_phase)) * 2.0 if is_running else 0.0

	var w: float = 28.0 * (1.0 - breath * 0.5)
	var h: float = 32.0 * (1.0 + breath)
	var base_y := run_bob

	# 1. Soft radial rim-glow behind character (ensures instant figure-ground pop)
	var glow_center := Vector2(0.0, base_y - h * 0.52)
	var glow_boost := 1.0 + _dash_glow * 0.85 + _spawn_flash * 1.1
	draw_circle(glow_center, 27.0, Color(accent.r, accent.g, accent.b, 0.055 * glow_boost))
	draw_circle(glow_center, 19.5, Color(accent.r, accent.g, accent.b, 0.095 * glow_boost))

	# 2. Ground contact shadow when on floor
	if on_floor:
		_draw_ellipse(Vector2(0.0, 0.5), Vector2(w * 0.46, 2.6), Color(0.0, 0.0, 0.0, 0.40))

	# 3. Cute animated running feet nubs
	var foot_col := Color("#16141c")
	var foot_rim := Color(accent.r, accent.g, accent.b, 0.35)
	if is_running:
		var stride := sin(_run_phase) * 4.5
		var lift_l := maxf(0.0, -cos(_run_phase)) * 3.0
		var lift_r := maxf(0.0, cos(_run_phase)) * 3.0
		_draw_rounded_rect(Rect2(-8.0 + stride - 3.0, -4.0 - lift_l, 6.0, 4.5), 2.0, foot_col, foot_rim, 1.0)
		_draw_rounded_rect(Rect2(8.0 - stride - 3.0, -4.0 - lift_r, 6.0, 4.5), 2.0, foot_col, foot_rim, 1.0)

	# 4. Rounded silhouette body + luminous rim outline
	var body_rect := Rect2(-w * 0.5, base_y - h, w, h)
	var body_fill := Color("#181620").lerp(Color(0.85, 0.94, 1.0), _spawn_flash * 0.55)
	var rim_col := Color(accent.r, accent.g, accent.b, 0.52).lerp(Color(0.95, 0.99, 1.0, 0.95), maxf(_dash_glow, _spawn_flash))
	var rim_width := lerpf(1.6, 2.3, maxf(_dash_glow, _spawn_flash))
	_draw_rounded_rect(body_rect, 4.5, body_fill, rim_col, rim_width)

	# Subtle top highlight bevel (gives tactile depth like MenuCharacter)
	draw_line(
		Vector2(body_rect.position.x + 5.0, body_rect.position.y + 2.0),
		Vector2(body_rect.end.x - 5.0, body_rect.position.y + 2.0),
		Color(1.0, 1.0, 1.0, 0.24),
		1.2,
		true
	)

	# 5. Expressive eyes
	var eye_y := base_y - h * 0.54
	var eye_scale := 1.0 + _panic_level * 0.18
	var eye_rx := 4.4 * eye_scale
	var eye_ry := 5.5 * eye_scale
	if is_dashing:
		eye_ry *= 0.72
	var left_eye := Vector2(-6.0, eye_y)
	var right_eye := Vector2(6.0, eye_y)

	# Subtle glowing eye aura (Limbo-inspired iconic readability!)
	var eye_glow := Color(1.0, 1.0, 1.0, 0.14 + _dash_glow * 0.18)
	draw_circle(left_eye, 7.2, eye_glow)
	draw_circle(right_eye, 7.2, eye_glow)

	if is_entering:
		_draw_happy_eye(left_eye)
		_draw_happy_eye(right_eye)
	elif _is_blinking:
		draw_line(left_eye - Vector2(4.2, 0.0), left_eye + Vector2(4.2, 0.0), Color.WHITE, 2.0, true)
		draw_line(right_eye - Vector2(4.2, 0.0), right_eye + Vector2(4.2, 0.0), Color.WHITE, 2.0, true)
	else:
		_draw_ellipse(left_eye, Vector2(eye_rx, eye_ry), Color(0.98, 0.99, 1.0, 1.0))
		_draw_ellipse(right_eye, Vector2(eye_rx, eye_ry), Color(0.98, 0.99, 1.0, 1.0))

		# Pupils shrink slightly during cartoon panic O_O
		var p_rad := lerpf(2.15, 1.45, _panic_level)
		var jitter := Vector2.ZERO
		if _panic_level > 0.3:
			jitter = Vector2(sin(_time * 55.0) * 0.45, cos(_time * 47.0) * 0.45) * _panic_level
		var p_left := left_eye + _current_pupil + jitter
		var p_right := right_eye + _current_pupil + jitter
		draw_circle(p_left, p_rad, Color("#0d0c12"))
		draw_circle(p_right, p_rad, Color("#0d0c12"))

		# Crisp specular glints in pupils
		draw_circle(p_left + Vector2(-0.7, -0.7), 0.72, Color.WHITE)
		draw_circle(p_right + Vector2(-0.7, -0.7), 0.72, Color.WHITE)

		# Determined brows during dash
		if _dash_glow > 0.2:
			var bcol := Color(0.95, 0.98, 1.0, 0.9 * _dash_glow)
			draw_line(left_eye + Vector2(-4.5, -5.8), left_eye + Vector2(3.8, -3.5), bcol, 1.7, true)
			draw_line(right_eye + Vector2(-3.8, -3.5), right_eye + Vector2(4.5, -5.8), bcol, 1.7, true)
		elif _panic_level > 0.25:
			# Raised worried eyebrows during panic
			var pcol := Color(0.95, 0.97, 1.0, 0.85 * _panic_level)
			draw_line(left_eye + Vector2(-4.2, -7.2), left_eye + Vector2(3.5, -9.0), pcol, 1.5, true)
			draw_line(right_eye + Vector2(-3.5, -9.0), right_eye + Vector2(4.2, -7.2), pcol, 1.5, true)

func _draw_ellipse(center: Vector2, r: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var segs := 16
	for i in range(segs):
		var th := float(i) * TAU / float(segs)
		points.append(center + Vector2(cos(th) * r.x, sin(th) * r.y))
	draw_colored_polygon(points, color)

func _draw_happy_eye(c: Vector2) -> void:
	var pts := PackedVector2Array()
	var segs := 8
	var r := 4.4
	for i in range(segs + 1):
		var th := PI + float(i) * PI / float(segs)
		pts.append(c + Vector2(cos(th) * r, sin(th) * 2.8))
	draw_polyline(pts, Color.WHITE, 2.2, true)

func _draw_rounded_rect(rect: Rect2, radius: float, fill: Color, stroke: Color, stroke_w: float) -> void:
	var r := minf(radius, minf(rect.size.x * 0.5, rect.size.y * 0.5))
	var pts := PackedVector2Array()
	var corners := [
		Vector2(rect.end.x - r, rect.position.y + r),
		Vector2(rect.end.x - r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.position.y + r),
	]
	var start_angles := [-PI * 0.5, 0.0, PI * 0.5, PI]
	var segs := 4
	for ci in range(4):
		var c: Vector2 = corners[ci]
		var a0: float = start_angles[ci]
		for si in range(segs + 1):
			var ang := a0 + (PI * 0.5) * (float(si) / float(segs))
			pts.append(c + Vector2(cos(ang) * r, sin(ang) * r))
	draw_colored_polygon(pts, fill)
	if stroke_w > 0.0:
		var outline := PackedVector2Array(pts)
		outline.append(pts[0])
		draw_polyline(outline, stroke, stroke_w, true)
