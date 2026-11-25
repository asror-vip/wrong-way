extends RefCounted

# High-craft stylized procedural art & shader library for Chapter 2 (Frost Peak)
# paranormal events (Levels 21-40). Harmonizes with Wrong Way's dark gothic-glacial
# silhouette aesthetic (#0d131f obsidian slate, #38bdf8 glacial cyan, #f8fafc frost).

const BaseArt := preload("res://scripts/paranormal/paranormal_art.gd")

static var _frost_edge_shader: Shader = null

static func get_frost_vignette_shader() -> Shader:
	if _frost_edge_shader != null:
		return _frost_edge_shader
	_frost_edge_shader = Shader.new()
	_frost_edge_shader.code = """
shader_type canvas_item;

uniform float intensity = 0.0;
uniform float time_sec = 0.0;

float h21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float n2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x),
	           mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 uv = UV - 0.5;
	float edge = length(uv * vec2(1.75, 1.55));
	float ice_n = n2(UV * vec2(18.0, 11.0) + vec2(time_sec * 0.08, -time_sec * 0.05));
	float rim = smoothstep(0.42, 0.98, edge + ice_n * 0.14);
	vec3 col = mix(vec3(0.42, 0.80, 0.98), vec3(0.92, 0.98, 1.0), ice_n);
	COLOR = vec4(col, clamp(rim * intensity * 0.42, 0.0, 0.52));
}
"""
	return _frost_edge_shader

static func _draw_crystal_shard(canvas: CanvasItem, center: Vector2, half_w: float, half_h: float, rot: float, fill: Color, rim: Color) -> void:
	var cs := cos(rot)
	var sn := sin(rot)
	var local := [
		Vector2(0.0, -half_h),
		Vector2(half_w, -half_h * 0.18),
		Vector2(0.0, half_h),
		Vector2(-half_w, -half_h * 0.18),
	]
	var pts := PackedVector2Array()
	for v in local:
		pts.append(center + Vector2(v.x * cs - v.y * sn, v.x * sn + v.y * cs))
	canvas.draw_colored_polygon(pts, fill)
	var loop := PackedVector2Array(pts)
	loop.append(pts[0])
	canvas.draw_polyline(loop, rim, 1.2, true)
	# Facet spine highlight
	canvas.draw_line(pts[0], pts[2], Color(rim.r, rim.g, rim.b, rim.a * 0.55), 0.9, true)

# =========================================================================
# 21. FROST BREATH ECHO (Level 21)
# =========================================================================
static func draw_frost_breath_echo(canvas: CanvasItem, puffs: Array[Dictionary], frozen: bool, timer: float) -> void:
	for i in range(puffs.size()):
		var pf: Dictionary = puffs[i]
		var pos: Vector2 = pf["pos"]
		var life: float = float(pf["life"])
		var r: float = float(pf["r"])
		var a := clampf(life / 2.2, 0.0, 1.0)
		var col := Color(0.74, 0.92, 1.0, a * (0.48 if frozen else 0.34))
		BaseArt.draw_ellipse_filled(canvas, pos, Vector2(r * 1.35, r * 0.85), col)
		if frozen:
			var sp := 0.7 + 0.3 * sin(timer * 4.0 + float(i))
			_draw_crystal_shard(canvas, pos, r * 0.38, r * 0.72, float(i) * 0.6, Color(0.60, 0.88, 1.0, a * 0.55 * sp), Color(0.95, 0.99, 1.0, a * 0.82 * sp))

# =========================================================================
# 22. ICICLE CHIME OMEN (Level 22)
# =========================================================================
static func draw_icicle_chime_omen(canvas: CanvasItem, anchor: Vector2, sway: float, ring_alpha: float, timer: float) -> void:
	# Ornate frosted iron crossbar hanging from ceiling
	var bar_l := anchor + Vector2(-72.0, 0.0)
	var bar_r := anchor + Vector2(72.0, 0.0)
	BaseArt.draw_iron_chain(canvas, Vector2(anchor.x, 48.0), anchor, 9.0)
	canvas.draw_line(bar_l, bar_r, Color(0.08, 0.12, 0.20, 0.94), 5.0, true)
	canvas.draw_line(bar_l, bar_r, Color(0.42, 0.78, 0.98, 0.55), 1.4, true)
	var lengths: Array[float] = [42.0, 62.0, 78.0, 56.0, 38.0]
	var xs: Array[float] = [-56.0, -28.0, 0.0, 28.0, 56.0]
	for i in range(5):
		var top := anchor + Vector2(xs[i], 2.0)
		var ang := sway * (0.85 + float(i % 2) * 0.35) + sin(timer * 2.2 + float(i) * 0.9) * 0.06
		var dir := Vector2(sin(ang), cos(ang))
		var tip := top + dir * lengths[i]
		canvas.draw_line(top, top + dir * 12.0, Color(0.65, 0.86, 0.98, 0.50), 1.0, true)
		var mid := top + dir * (12.0 + (lengths[i] - 12.0) * 0.5)
		var crystal_h := (lengths[i] - 12.0) * 0.5
		var c_fill := Color(0.24, 0.68, 0.96, 0.58 + ring_alpha * 0.28)
		var c_rim := Color(0.88, 0.97, 1.0, 0.78 + ring_alpha * 0.20)
		_draw_crystal_shard(canvas, mid, 5.2, crystal_h, -ang, c_fill, c_rim)
		if ring_alpha > 0.05:
			var rr := 10.0 + (1.0 - ring_alpha) * 44.0
			canvas.draw_arc(tip, rr, 0.0, TAU, 24, Color(0.68, 0.92, 1.0, ring_alpha * 0.34), 1.3, true)

# =========================================================================
# 23. BLACK ICE GLIDE (Level 23)
# =========================================================================
static func draw_black_ice_surface(canvas: CanvasItem, rect: Rect2, timer: float, sparks: Array[Dictionary]) -> void:
	# Mirror-obsidian translucent sheen over upper black ice deck
	canvas.draw_rect(Rect2(rect.position.x, rect.position.y - 3.0, rect.size.x, 7.0), Color(0.06, 0.16, 0.28, 0.78), true)
	canvas.draw_line(Vector2(rect.position.x, rect.position.y - 1.5), Vector2(rect.end.x, rect.position.y - 1.5), Color(0.56, 0.90, 1.0, 0.72), 2.0, true)
	# Animated diagonal crystalline shimmer sweep
	var sweep_x := rect.position.x + fmod(timer * 140.0, rect.size.x + 120.0) - 60.0
	for k in range(3):
		var sx := sweep_x - float(k) * 18.0
		if sx >= rect.position.x + 6.0 and sx <= rect.end.x - 16.0:
			canvas.draw_line(Vector2(sx, rect.position.y - 2.0), Vector2(sx + 14.0, rect.position.y + 4.0), Color(0.88, 0.98, 1.0, 0.44 - float(k) * 0.11), 1.6, true)
	for sp in sparks:
		var a := clampf(float(sp["life"]) / 0.45, 0.0, 1.0)
		canvas.draw_circle(sp["pos"], 2.2 * a, Color(0.72, 0.94, 1.0, a * 0.85))

# =========================================================================
# 24. FROZEN COMPASS NEEDLE (Level 24)
# =========================================================================
static func draw_frozen_compass(canvas: CanvasItem, center: Vector2, angle: float, frozen: bool, timer: float) -> void:
	var r := 46.0
	var iron := Color(0.08, 0.11, 0.18, 0.88)
	var rim := Color(0.54, 0.84, 1.0, 0.78) if frozen else Color(0.76, 0.86, 0.96, 0.56)
	canvas.draw_circle(center + Vector2(3.0, 4.0), r + 4.0, Color(0.0, 0.0, 0.0, 0.24))
	canvas.draw_circle(center, r + 3.0, iron)
	canvas.draw_circle(center, r - 3.0, Color(0.05, 0.09, 0.16, 0.86))
	canvas.draw_arc(center, r + 2.0, 0.0, TAU, 36, rim, 1.8, true)
	canvas.draw_arc(center, r - 5.0, 0.0, TAU, 32, Color(rim.r, rim.g, rim.b, 0.34), 1.0, true)
	# 8-point cardinal star engravings
	for i in range(8):
		var a := float(i) * PI * 0.25
		var dir := Vector2(cos(a), sin(a))
		var len_in := r - (16.0 if i % 2 == 0 else 10.0)
		canvas.draw_line(center + dir * len_in, center + dir * (r - 5.0), rim, 1.5 if i % 2 == 0 else 1.0, true)
	# Rotating compass needle pointing to true exit
	var nd := Vector2(cos(angle), sin(angle))
	var np := Vector2(-nd.y, nd.x)
	var tip_front := center + nd * (r - 9.0)
	var tip_back := center - nd * (r - 13.0)
	var front_poly := PackedVector2Array([tip_front, center + np * 5.2, center - np * 5.2])
	var back_poly := PackedVector2Array([tip_back, center + np * 4.4, center - np * 4.4])
	canvas.draw_colored_polygon(back_poly, Color(0.24, 0.32, 0.44, 0.85))
	canvas.draw_colored_polygon(front_poly, Color(0.95, 0.32, 0.44, 0.92) if frozen else Color(0.36, 0.86, 1.0, 0.92))
	canvas.draw_circle(center, 5.2, iron)
	canvas.draw_circle(center, 2.8, Color(0.92, 0.98, 1.0, 0.90))
	if frozen:
		var pulse := 0.55 + 0.45 * sin(timer * 5.0)
		for k in range(6):
			var ka := float(k) * TAU / 6.0 + 0.3
			var kp := center + Vector2(cos(ka), sin(ka)) * (r + 5.0)
			_draw_crystal_shard(canvas, kp, 3.2, 8.5, ka + PI * 0.5, Color(0.40, 0.82, 1.0, 0.62 * pulse), Color(0.92, 0.98, 1.0, 0.84 * pulse))

# =========================================================================
# 25. AURORA VEIL SHIFT (Level 25)
# =========================================================================
static func draw_aurora_veil(canvas: CanvasItem, phase_cyan: bool, phase_prog: float, platforms: Array[Dictionary], timer: float) -> void:
	# Ethereal aurora ribbons across upper sky
	var col_a := Color(0.22, 0.88, 0.84, 0.16) if phase_cyan else Color(0.62, 0.34, 0.96, 0.16)
	var col_b := Color(0.38, 0.96, 1.0, 0.24) if phase_cyan else Color(0.86, 0.50, 1.0, 0.24)
	for band in range(3):
		var pts := PackedVector2Array()
		var base_y := 86.0 + float(band) * 28.0
		for xi in range(25):
			var x := 32.0 + float(xi) * 37.33
			var y := base_y + sin(x * 0.011 + timer * 1.1 + float(band) * 1.6) * 18.0 + cos(x * 0.023 - timer * 0.7) * 7.0
			pts.append(Vector2(x, y))
		canvas.draw_polyline(pts, col_a, 16.0 - float(band) * 3.0, true)
		canvas.draw_polyline(pts, col_b, 2.4, true)
	# Phasing Aurora Ice Platforms
	var blink := 1.0
	if phase_prog > 0.78:
		blink = 0.45 + 0.55 * absf(sin(timer * 24.0))
	for p in platforms:
		var r := Rect2(p["pos"], p["size"])
		var solid: bool = bool(p["solid"])
		var is_cyan: bool = bool(p["cyan_phase"])
		var base_c := Color(0.22, 0.84, 0.98) if is_cyan else Color(0.72, 0.42, 0.98)
		if solid:
			canvas.draw_rect(r.grow(3.0), Color(base_c.r, base_c.g, base_c.b, 0.16 * blink), true)
			BaseArt.draw_rounded_box(canvas, r, 4.0, Color(0.08, 0.18, 0.28, 0.86 * blink), Color(base_c.r, base_c.g, base_c.b, 0.92 * blink), 1.8)
			canvas.draw_line(r.position + Vector2(6.0, 3.0), Vector2(r.end.x - 6.0, r.position.y + 3.0), Color(0.92, 0.99, 1.0, 0.72 * blink), 1.5, true)
		else:
			canvas.draw_rect(r, Color(base_c.r, base_c.g, base_c.b, 0.12), false, 1.2)

# =========================================================================
# 26. SNOWDRIFT BURY (Level 26)
# =========================================================================
static func draw_snowdrift_wave(canvas: CanvasItem, wave_x: float, floor_y: float, top_y: float, active: bool, timer: float) -> void:
	if not active:
		return
	var right_edge := 806.0
	var wave_w := right_edge - wave_x
	if wave_w <= 6.0:
		return
	# Strictly simple non-self-intersecting spectral snowdrift polygon sweeping right -> left up to AlcoveSnowWall
	var poly := PackedVector2Array()
	poly.append(Vector2(right_edge, floor_y + 12.0))
	poly.append(Vector2(wave_x - 10.0, floor_y + 12.0))
	for i in range(1, 9):
		var u := float(i) / 9.0
		var py := lerpf(floor_y + 8.0, top_y + 4.0, u)
		var bulge := sin(u * PI) * 16.0 + sin(timer * 9.0 + u * 5.0) * 3.5
		poly.append(Vector2(wave_x - 4.0 - bulge, py))
	for j in range(11):
		var u := float(j) / 10.0
		var px := lerpf(wave_x + 2.0, right_edge, u)
		var crest := sin(px * 0.045 - timer * 5.5) * 4.5
		poly.append(Vector2(px, top_y + crest))
	canvas.draw_colored_polygon(poly, Color(0.76, 0.91, 0.99, 0.74))
	canvas.draw_polyline(poly, Color(0.95, 0.99, 1.0, 0.90), 2.0, true)
	# Swirling frost mist curls at leading edge
	for k in range(5):
		var cy := lerpf(top_y + 10.0, floor_y - 8.0, float(k) / 4.0)
		var cx := wave_x - 10.0 + sin(timer * 7.0 + float(k) * 1.4) * 8.0
		BaseArt.draw_ellipse_filled(canvas, Vector2(cx, cy), Vector2(16.0, 9.0), Color(0.88, 0.96, 1.0, 0.45))

# =========================================================================
# 27. FROZEN MIRROR TWIN (Level 27)
# =========================================================================
static func draw_frozen_mirror(canvas: CanvasItem, center: Vector2, twin_pos: Vector2, cracked: bool, crack_flash: float, timer: float) -> void:
	var frame := Rect2(center - Vector2(68.0, 92.0), Vector2(136.0, 184.0))
	# Ornate gothic ice-obsidian arched mirror frame
	BaseArt.draw_rounded_box(canvas, frame.grow(7.0), 18.0, Color(0.07, 0.10, 0.17, 0.92), Color(0.45, 0.80, 0.98, 0.65), 2.0)
	BaseArt.draw_rounded_box(canvas, frame, 14.0, Color(0.11, 0.22, 0.34, 0.62), Color(0.82, 0.95, 1.0, 0.55), 1.2)
	# Diagonal glacial reflection sheen inside glass
	canvas.draw_line(frame.position + Vector2(18.0, 22.0), frame.position + Vector2(56.0, 62.0), Color(0.90, 0.98, 1.0, 0.22), 8.0, true)
	canvas.draw_line(frame.position + Vector2(74.0, 98.0), frame.position + Vector2(114.0, 142.0), Color(0.90, 0.98, 1.0, 0.16), 6.0, true)
	# Reflected frost silhouette inside mirror bounds
	var rx := clampf(twin_pos.x, frame.position.x + 22.0, frame.end.x - 22.0)
	var ry := clampf(twin_pos.y, frame.position.y + 42.0, frame.end.y - 12.0)
	var rcol := Color(0.95, 0.38, 0.48, 0.72) if cracked else Color(0.68, 0.92, 1.0, 0.65)
	BaseArt.draw_rounded_box(canvas, Rect2(rx - 10.0, ry - 26.0, 20.0, 26.0), 5.0, rcol)
	canvas.draw_circle(Vector2(rx - 3.5, ry - 17.0), 2.0, Color(1.0, 1.0, 1.0, 0.92))
	canvas.draw_circle(Vector2(rx + 3.5, ry - 17.0), 2.0, Color(1.0, 1.0, 1.0, 0.92))
	if cracked:
		# Spiderweb ice fractures radiating from mirror center
		var c := center
		var rays: Array[Vector2] = [Vector2(-58, -74), Vector2(54, -66), Vector2(62, 18), Vector2(-52, 68), Vector2(36, 82), Vector2(-60, -8)]
		for rv in rays:
			var mid := c + rv * 0.5 + Vector2(sin(rv.y) * 7.0, cos(rv.x) * 7.0)
			canvas.draw_polyline(PackedVector2Array([c, mid, c + rv]), Color(0.92, 0.98, 1.0, 0.85), 1.6, true)
		if crack_flash > 0.01:
			canvas.draw_rect(frame, Color(0.85, 0.96, 1.0, crack_flash * 0.55), true)

# =========================================================================
# 28. FROSTBITE LANTERN PULSE (Level 28)
# =========================================================================
static func draw_frostbite_lanterns(canvas: CanvasItem, lanterns: Array[Vector2], warm_radius: float, timer: float) -> void:
	for i in range(lanterns.size()):
		var lp: Vector2 = lanterns[i]
		var flicker := 0.92 + 0.08 * sin(timer * 6.5 + float(i) * 2.1)
		var r := warm_radius * flicker
		# Warm layered amber glow halo
		for ring in range(5):
			var frac := float(ring) / 4.0
			var rr := r * (0.28 + frac * 0.72)
			var a := (1.0 - frac) * 0.14
			canvas.draw_circle(lp, rr, Color(1.0, 0.68, 0.28, a))
		# Chain & standable wrought-iron crossbeam bracket right at lp.y
		BaseArt.draw_iron_chain(canvas, Vector2(lp.x, 48.0), lp - Vector2(0.0, 16.0), 9.5)
		var beam := Rect2(lp.x - 44.0, lp.y - 4.0, 88.0, 8.0)
		BaseArt.draw_rounded_box(canvas, beam, 3.0, Color(0.10, 0.13, 0.20, 0.95), Color(0.96, 0.72, 0.36, 0.65), 1.3)
		# Ornate iron lantern housing hanging right below crossbeam
		var body := Rect2(lp.x - 11.0, lp.y + 4.0, 22.0, 26.0)
		BaseArt.draw_rounded_box(canvas, body, 4.0, Color(0.12, 0.14, 0.20, 0.92), Color(0.98, 0.76, 0.40, 0.85), 1.4)
		canvas.draw_circle(lp + Vector2(0.0, 17.0), 6.5 * flicker, Color(1.0, 0.82, 0.42, 0.92))
		canvas.draw_circle(lp + Vector2(0.0, 17.0), 3.0, Color(1.0, 0.98, 0.86, 0.98))

# =========================================================================
# 29. SHATTERING GLACIER ECHO (Level 29)
# =========================================================================
static func draw_glacier_echo(canvas: CanvasItem, stomp_count: int, shock_pos: Vector2, shock_r: float, shock_a: float, fractured: bool, timer: float) -> void:
	# Background carved glacier faultline runes showing 0..3 cracks
	var center := Vector2(780.0, 275.0)
	for i in range(3):
		var lit := i < stomp_count
		var ang := -0.9 + float(i) * 0.9
		var p0 := center + Vector2(cos(ang), sin(ang)) * 14.0
		var p1 := center + Vector2(cos(ang), sin(ang)) * 58.0
		var col := Color(0.45, 0.92, 1.0, 0.82) if lit else Color(0.30, 0.48, 0.66, 0.24)
		canvas.draw_line(p0, p1, col, 2.4 if lit else 1.2, true)
		_draw_crystal_shard(canvas, p1, 4.0, 9.0, ang + PI * 0.5, Color(col.r, col.g, col.b, col.a * 0.6), col)
	if shock_a > 0.01:
		canvas.draw_arc(shock_pos, shock_r, 0.0, TAU, 36, Color(0.62, 0.92, 1.0, shock_a * 0.58), 2.2, true)
		canvas.draw_arc(shock_pos, shock_r * 0.72, 0.0, TAU, 28, Color(0.90, 0.98, 1.0, shock_a * 0.34), 1.2, true)
	if fractured:
		var pulse := 0.7 + 0.3 * sin(timer * 4.2)
		canvas.draw_arc(center, 22.0, 0.0, TAU, 24, Color(0.50, 0.94, 1.0, 0.45 * pulse), 1.6, true)

# =========================================================================
# 30. BLIZZARD WHITEOUT GUST (Level 30)
# =========================================================================
static func draw_blizzard_whiteout(canvas: CanvasItem, active: bool, wind_dir: float, alpha: float, timer: float) -> void:
	if alpha <= 0.01:
		return
	# Diagonal alpine snowstorm streaks + semi-translucent whiteout veil framed inside arena walls
	canvas.draw_rect(Rect2(32.0, 48.0, 896.0, 492.0), Color(0.76, 0.88, 0.98, alpha * 0.32), true)
	for i in range(42):
		var seed_v := float(i) * 73.17
		var sx := fmod(seed_v * 13.0 + timer * (560.0 * wind_dir), 1040.0)
		if sx < -40.0:
			sx += 1040.0
		var sy := fmod(seed_v * 29.0 + timer * 190.0, 560.0)
		var p0 := Vector2(sx, sy)
		var p1 := p0 + Vector2(wind_dir * 34.0, 11.0)
		canvas.draw_line(p0, p1, Color(0.92, 0.98, 1.0, alpha * 0.56), 1.5, true)
	# Subtle wind-direction chevron banner in top sky
	if active:
		var cx := 480.0
		var cy := 96.0
		for k in range(-1, 2):
			var ox := cx + float(k) * 28.0 + sin(timer * 8.0) * 5.0 * wind_dir
			var pts := PackedVector2Array([
				Vector2(ox - 7.0 * wind_dir, cy - 8.0),
				Vector2(ox + 6.0 * wind_dir, cy),
				Vector2(ox - 7.0 * wind_dir, cy + 8.0),
			])
			canvas.draw_polyline(pts, Color(0.84, 0.96, 1.0, alpha * 0.65), 2.0, true)

# =========================================================================
# 31. FROZEN DASH PLATFORMS (Level 31)
# =========================================================================
static func draw_frozen_dash_platforms(canvas: CanvasItem, pads: Array[Dictionary], timer: float) -> void:
	for pd in pads:
		var life: float = float(pd["life"])
		if life <= 0.0:
			continue
		var r := Rect2(pd["pos"], pd["size"])
		var a := clampf(life / 0.65, 0.0, 1.0)
		if life < 0.85:
			a *= 0.55 + 0.45 * absf(sin(timer * 24.0))
		canvas.draw_rect(r.grow(3.0), Color(0.32, 0.84, 1.0, 0.18 * a), true)
		BaseArt.draw_rounded_box(canvas, r, 5.0, Color(0.12, 0.30, 0.48, 0.88 * a), Color(0.82, 0.97, 1.0, 0.92 * a), 1.6)
		# Hanging micro icicles underneath crystallized dash cloud
		for k in range(3):
			var ix := r.position.x + 14.0 + float(k) * 18.0
			var pts := PackedVector2Array([Vector2(ix - 3.5, r.end.y), Vector2(ix + 3.5, r.end.y), Vector2(ix, r.end.y + 8.0)])
			canvas.draw_colored_polygon(pts, Color(0.68, 0.92, 1.0, 0.72 * a))

# =========================================================================
# 32. CRYO UPDRAFT COLUMN (Level 32)
# =========================================================================
static func draw_cryo_updraft(canvas: CanvasItem, x_min: float, x_max: float, y_top: float, y_bot: float, timer: float) -> void:
	var w := x_max - x_min
	var h := y_bot - y_top
	canvas.draw_rect(Rect2(x_min, y_top, w, h), Color(0.24, 0.76, 0.98, 0.11), true)
	canvas.draw_line(Vector2(x_min, y_top), Vector2(x_min, y_bot), Color(0.50, 0.90, 1.0, 0.34), 1.4, true)
	canvas.draw_line(Vector2(x_max, y_top), Vector2(x_max, y_bot), Color(0.50, 0.90, 1.0, 0.34), 1.4, true)
	for i in range(16):
		var u := fmod(float(i) * 0.19 + timer * 0.72, 1.0)
		var py := lerpf(y_bot - 6.0, y_top + 6.0, u)
		var px := lerpf(x_min + 10.0, x_max - 10.0, 0.5 + 0.42 * sin(float(i) * 2.7 + timer * 2.1))
		var fade := sin(u * PI)
		canvas.draw_line(Vector2(px, py + 14.0), Vector2(px, py - 10.0), Color(0.76, 0.96, 1.0, 0.52 * fade), 1.6, true)
		_draw_crystal_shard(canvas, Vector2(px, py - 10.0), 2.5, 5.0, 0.0, Color(0.45, 0.88, 1.0, 0.58 * fade), Color(0.95, 0.99, 1.0, 0.78 * fade))

# =========================================================================
# 33. FROST BELL SHOCKWAVE (Level 33)
# =========================================================================
static func draw_frost_bell(canvas: CanvasItem, pivot: Vector2, swing: float, ring_r: float, ring_a: float, timer: float) -> void:
	BaseArt.draw_iron_chain(canvas, Vector2(pivot.x, 48.0), pivot, 9.0)
	canvas.draw_set_transform(pivot, swing)
	# Ornate gothic bronze-and-frost cathedral bell silhouette
	var bell_pts := PackedVector2Array([
		Vector2(-12.0, 4.0), Vector2(12.0, 4.0),
		Vector2(20.0, 26.0), Vector2(30.0, 52.0),
		Vector2(36.0, 62.0), Vector2(-36.0, 62.0),
		Vector2(-30.0, 52.0), Vector2(-20.0, 26.0),
	])
	canvas.draw_colored_polygon(bell_pts, Color(0.11, 0.17, 0.27, 0.94))
	var loop := PackedVector2Array(bell_pts)
	loop.append(bell_pts[0])
	canvas.draw_polyline(loop, Color(0.56, 0.88, 1.0, 0.80), 1.8, true)
	# Engraved frost filigree band + clapper
	canvas.draw_line(Vector2(-24.0, 48.0), Vector2(24.0, 48.0), Color(0.78, 0.95, 1.0, 0.60), 1.5, true)
	canvas.draw_circle(Vector2(0.0, 65.0), 6.2, Color(0.42, 0.84, 1.0, 0.92))
	canvas.draw_set_transform(Vector2.ZERO, 0.0)
	if ring_a > 0.01:
		var bc := pivot + Vector2(0.0, 58.0)
		canvas.draw_arc(bc, ring_r, 0.0, TAU, 48, Color(0.55, 0.90, 1.0, ring_a * 0.62), 3.0, true)
		canvas.draw_arc(bc, maxf(4.0, ring_r - 12.0), 0.0, TAU, 40, Color(0.92, 0.98, 1.0, ring_a * 0.34), 1.4, true)

# =========================================================================
# 34. GLACIAL PRISM SPLIT (Level 34)
# =========================================================================
static func draw_glacial_prism(canvas: CanvasItem, center: Vector2, activated: bool, timer: float) -> void:
	var rot := timer * (1.25 if activated else 0.55)
	# Refracted light beams
	var beam_a := 0.26 if activated else 0.12
	var cols := [Color(0.28, 0.88, 1.0, beam_a), Color(0.64, 0.50, 1.0, beam_a), Color(0.32, 0.96, 0.78, beam_a)]
	for i in range(3):
		var ang := -0.45 + float(i) * 0.45 + sin(timer * 0.8) * 0.06
		var end_p := center + Vector2(cos(ang), sin(ang)) * 340.0
		canvas.draw_line(center, end_p, cols[i], 10.0 - float(i) * 2.0, true)
	# Floating hexagonal obsidian-ice prism crystal
	var hover := Vector2(0.0, sin(timer * 2.4) * 5.0)
	_draw_crystal_shard(canvas, center + hover, 22.0, 36.0, sin(rot) * 0.14, Color(0.14, 0.36, 0.56, 0.84), Color(0.84, 0.97, 1.0, 0.92))
	_draw_crystal_shard(canvas, center + hover, 10.0, 22.0, -sin(rot) * 0.18, Color(0.46, 0.88, 1.0, 0.52), Color(1.0, 1.0, 1.0, 0.86))

# =========================================================================
# 35. PERMAFROST CREEP (Level 35)
# =========================================================================
static func draw_permafrost_patches(canvas: CanvasItem, patches: Array[Dictionary], timer: float) -> void:
	for pt in patches:
		var pos: Vector2 = pt["pos"]
		var age: float = float(pt["age"])
		var lethal: bool = bool(pt["lethal"])
		var grow := clampf(age / 1.1, 0.0, 1.0)
		var col := Color(0.40, 0.88, 1.0, 0.88) if lethal else Color(0.55, 0.82, 0.96, 0.45 * grow)
		canvas.draw_rect(Rect2(pos.x - 16.0, pos.y - 3.0, 32.0, 5.0), col, true)
		var h := (18.0 if lethal else 10.0 * grow)
		for k in range(-1, 2):
			var sx := pos.x + float(k) * 10.0
			var sh := h * (1.0 if k == 0 else 0.72)
			var tri := PackedVector2Array([Vector2(sx - 4.5, pos.y), Vector2(sx + 4.5, pos.y), Vector2(sx, pos.y - sh)])
			canvas.draw_colored_polygon(tri, Color(0.24, 0.72, 0.98, 0.86) if lethal else Color(0.45, 0.76, 0.96, 0.38))
			if lethal:
				canvas.draw_line(Vector2(sx, pos.y - sh), Vector2(sx, pos.y), Color(0.95, 0.99, 1.0, 0.78), 1.0, true)

# =========================================================================
# 36. SKY CAIRN AIRBORNE (Level 36)
# =========================================================================
static func draw_sky_cairns(canvas: CanvasItem, cairn_xs: Array[float], floor_y: float, stones: Array[Dictionary], reveal_alpha: float, timer: float) -> void:
	# Three carved obsidian-snow cairn totems in background
	for i in range(cairn_xs.size()):
		var bx := cairn_xs[i]
		var widths := [36.0, 28.0, 20.0, 12.0]
		var cy := floor_y
		for s in range(4):
			var w: float = widths[s]
			var h := 14.0
			cy -= h
			BaseArt.draw_rounded_box(canvas, Rect2(bx - w * 0.5, cy, w, h + 1.0), 4.0, Color(0.08, 0.12, 0.19, 0.84), Color(0.48, 0.82, 0.98, 0.28 + reveal_alpha * 0.45), 1.2)
		# Glowing rune eye on top stone
		var eye_col := Color(0.42, 0.92, 1.0, 0.30 + reveal_alpha * 0.68)
		canvas.draw_circle(Vector2(bx, cy + 6.0), 3.0, eye_col)
	# Hidden sky crystal stepping stones visible ONLY while airborne!
	if reveal_alpha > 0.02:
		for st in stones:
			var r := Rect2(st["pos"], st["size"])
			BaseArt.draw_rounded_box(canvas, r, 4.0, Color(0.14, 0.36, 0.54, 0.72 * reveal_alpha), Color(0.80, 0.96, 1.0, 0.88 * reveal_alpha), 1.6)
			canvas.draw_line(r.position + Vector2(6.0, 3.0), Vector2(r.end.x - 6.0, r.position.y + 3.0), Color(1.0, 1.0, 1.0, 0.65 * reveal_alpha), 1.3, true)

# =========================================================================
# 37. CRYO HEARTBEAT SURGE (Level 37)
# =========================================================================
static func draw_cryo_heart(canvas: CanvasItem, center: Vector2, surge_active: bool, pulse_r: float, timer: float) -> void:
	var sc := 1.12 if surge_active else (1.0 + 0.04 * sin(timer * 3.5))
	var fill := Color(0.28, 0.84, 1.0, 0.76) if surge_active else Color(0.12, 0.24, 0.38, 0.72)
	var rim := Color(0.92, 0.99, 1.0, 0.94) if surge_active else Color(0.46, 0.78, 0.96, 0.55)
	# Sculpted faceted crystal heart silhouette
	var hpts := PackedVector2Array([
		center + Vector2(0.0, 42.0 * sc),
		center + Vector2(34.0 * sc, 4.0 * sc),
		center + Vector2(28.0 * sc, -26.0 * sc),
		center + Vector2(10.0 * sc, -34.0 * sc),
		center + Vector2(0.0, -16.0 * sc),
		center + Vector2(-10.0 * sc, -34.0 * sc),
		center + Vector2(-28.0 * sc, -26.0 * sc),
		center + Vector2(-34.0 * sc, 4.0 * sc),
	])
	canvas.draw_colored_polygon(hpts, fill)
	var loop := PackedVector2Array(hpts)
	loop.append(hpts[0])
	canvas.draw_polyline(loop, rim, 2.0, true)
	canvas.draw_line(center + Vector2(0.0, -16.0 * sc), center + Vector2(0.0, 40.0 * sc), Color(rim.r, rim.g, rim.b, 0.55), 1.2, true)
	if surge_active:
		canvas.draw_arc(center, pulse_r, 0.0, TAU, 40, Color(0.55, 0.94, 1.0, clampf(1.0 - pulse_r / 420.0, 0.0, 0.65)), 2.5, true)

# =========================================================================
# 38. SHATTERING ICE PANES (Level 38)
# =========================================================================
static func draw_shattering_ice_panes(canvas: CanvasItem, panes: Array[Dictionary], timer: float) -> void:
	for pn in panes:
		var state: int = int(pn["state"]) # 0=intact, 1=cracking, 2=shattered
		if state == 2:
			continue
		var r := Rect2(pn["pos"], pn["size"])
		var shake := Vector2.ZERO
		if state == 1:
			shake = Vector2(sin(timer * 55.0) * 2.2, cos(timer * 48.0) * 1.2)
		var dr := Rect2(r.position + shake, r.size)
		BaseArt.draw_rounded_box(canvas, dr, 3.0, Color(0.18, 0.46, 0.68, 0.78), Color(0.84, 0.97, 1.0, 0.92), 1.6)
		canvas.draw_line(dr.position + Vector2(6.0, 4.0), Vector2(dr.end.x - 6.0, dr.position.y + 4.0), Color(0.96, 0.99, 1.0, 0.72), 1.4, true)
		if state == 1:
			var cx := dr.position.x + dr.size.x * 0.5
			var cy := dr.position.y + dr.size.y * 0.5
			canvas.draw_polyline(PackedVector2Array([Vector2(cx - 24.0, dr.position.y), Vector2(cx, cy), Vector2(cx + 22.0, dr.end.y)]), Color(1.0, 1.0, 1.0, 0.95), 1.6, true)
			canvas.draw_polyline(PackedVector2Array([Vector2(cx + 12.0, dr.position.y), Vector2(cx, cy), Vector2(cx - 14.0, dr.end.y)]), Color(0.60, 0.92, 1.0, 0.90), 1.3, true)

# =========================================================================
# 39. AVALANCHE WALL CHASE (Level 39)
# =========================================================================
static func draw_avalanche_wall(canvas: CanvasItem, wall_x: float, started: bool, timer: float) -> void:
	if not started or wall_x <= 0.0:
		return
	var poly := PackedVector2Array([Vector2(-20.0, 0.0), Vector2(wall_x, 0.0)])
	for i in range(18):
		var py := float(i) * (540.0 / 17.0)
		var spike := 14.0 + sin(timer * 9.0 + float(i) * 1.7) * 9.0 + (12.0 if i % 2 == 0 else -4.0)
		poly.append(Vector2(wall_x + spike, py))
	poly.append(Vector2(-20.0, 540.0))
	canvas.draw_colored_polygon(poly, Color(0.08, 0.22, 0.36, 0.82))
	canvas.draw_polyline(poly, Color(0.68, 0.94, 1.0, 0.92), 2.4, true)
	# Swirling snow gust along advancing ice face
	for k in range(8):
		var fy := fmod(float(k) * 72.0 + timer * 90.0, 520.0)
		var fx := wall_x + 18.0 + sin(timer * 6.0 + float(k)) * 10.0
		BaseArt.draw_ellipse_filled(canvas, Vector2(fx, fy), Vector2(12.0, 5.5), Color(0.86, 0.96, 1.0, 0.42))

# =========================================================================
# 40. FROST CROWN FINALE (Level 40)
# =========================================================================
static func draw_frost_crown_finale(canvas: CanvasItem, center: Vector2, door_pos: Vector2, unlocked: bool, flash: float, timer: float) -> void:
	# Colossal obsidian & glacial ice crown hovering above central throne
	var hover := Vector2(0.0, sin(timer * 2.0) * 5.0)
	var c := center + hover
	var base_c := Color(0.32, 0.88, 1.0, 0.85) if unlocked else Color(0.14, 0.28, 0.44, 0.86)
	var rim_c := Color(0.95, 0.99, 1.0, 0.96) if unlocked else Color(0.54, 0.86, 1.0, 0.78)
	var crown_pts := PackedVector2Array([
		c + Vector2(-46.0, 14.0), c + Vector2(-54.0, -14.0),
		c + Vector2(-28.0, -2.0), c + Vector2(-18.0, -32.0),
		c + Vector2(0.0, -12.0), c + Vector2(0.0, -44.0),
		c + Vector2(0.0, -12.0), c + Vector2(18.0, -32.0),
		c + Vector2(28.0, -2.0), c + Vector2(54.0, -14.0),
		c + Vector2(46.0, 14.0),
	])
	canvas.draw_colored_polygon(crown_pts, base_c)
	var loop := PackedVector2Array(crown_pts)
	loop.append(crown_pts[0])
	canvas.draw_polyline(loop, rim_c, 2.0, true)
	# 6 orbiting ice shards around crown
	for i in range(6):
		var a := timer * (1.6 if unlocked else 0.75) + float(i) * TAU / 6.0
		var sp := c + Vector2(cos(a) * 68.0, sin(a) * 24.0)
		_draw_crystal_shard(canvas, sp, 4.5, 11.0, a + PI * 0.5, base_c, rim_c)
	# Frost seal crystal cage over ExitDoor while locked
	if not unlocked:
		var dc := door_pos + Vector2(0.0, -29.0)
		var pulse := 0.72 + 0.28 * sin(timer * 4.5)
		canvas.draw_arc(dc, 34.0, 0.0, TAU, 32, Color(0.45, 0.88, 1.0, 0.65 * pulse), 2.4, true)
		canvas.draw_line(dc - Vector2(20.0, 22.0), dc + Vector2(20.0, 22.0), Color(0.84, 0.96, 1.0, 0.75 * pulse), 2.0, true)
		canvas.draw_line(dc - Vector2(-20.0, 22.0), dc + Vector2(-20.0, 22.0), Color(0.84, 0.96, 1.0, 0.75 * pulse), 2.0, true)
	if flash > 0.01:
		canvas.draw_rect(Rect2(-420.0, -280.0, 1800.0, 1100.0), Color(0.62, 0.92, 1.0, flash * 0.34), true)
