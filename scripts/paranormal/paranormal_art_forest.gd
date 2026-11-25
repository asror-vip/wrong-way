extends RefCounted

# High-craft stylized procedural art & shader library for Chapter 3 (Emerald Woods)
# paranormal events (Levels 41-60). Harmonizes with Wrong Way's dark gothic-sylvan
# silhouette aesthetic (#062319 deep jade, #22c55e emerald glow, #bbf7d0 spore light).

const BaseArt := preload("res://scripts/paranormal/paranormal_art.gd")

static var _wisp_fog_shader: Shader = null

static func get_wisp_fog_shader() -> Shader:
	if _wisp_fog_shader != null:
		return _wisp_fog_shader
	_wisp_fog_shader = Shader.new()
	_wisp_fog_shader.code = """
shader_type canvas_item;

uniform vec2 local_size = vec2(1800.0, 1100.0);
uniform vec2 wisp_pos = vec2(600.0, 620.0);
uniform vec2 player_pos = vec2(520.0, 620.0);
uniform float time_sec = 0.0;

void fragment() {
	vec2 p = UV * local_size;
	float d_wisp = length(p - wisp_pos);
	float d_player = length(p - player_pos);
	float flicker = 1.0 + sin(time_sec * 9.0) * 0.03;
	float lit_wisp = 1.0 - smoothstep(42.0 * flicker, 168.0 * flicker, d_wisp);
	float lit_p = 1.0 - smoothstep(26.0, 96.0, d_player);
	float lit = clamp(max(lit_wisp, lit_p * 0.86), 0.0, 1.0);
	float alpha = 0.90 * (1.0 - lit * 0.94);
	float halo = exp(-pow(d_wisp / 64.0, 2.0)) * 0.16;
	vec3 fog_col = mix(vec3(0.015, 0.055, 0.042), vec3(0.28, 0.95, 0.58), clamp(halo * 2.4, 0.0, 1.0));
	COLOR = vec4(fog_col, clamp(alpha + halo * 0.3, 0.0, 0.94));
}
"""
	return _wisp_fog_shader

static func _draw_leaf(canvas: CanvasItem, pos: Vector2, len_l: float, width_l: float, rot: float, fill: Color, rim: Color) -> void:
	var cs := cos(rot)
	var sn := sin(rot)
	var pts := PackedVector2Array()
	var local := [
		Vector2(0.0, 0.0),
		Vector2(len_l * 0.42, -width_l),
		Vector2(len_l, 0.0),
		Vector2(len_l * 0.42, width_l),
	]
	for v in local:
		pts.append(pos + Vector2(v.x * cs - v.y * sn, v.x * sn + v.y * cs))
	canvas.draw_colored_polygon(pts, fill)
	canvas.draw_line(pts[0], pts[2], rim, 0.9, true)

# =========================================================================
# 41. FIREFLY PATH DECOY (Level 41)
# =========================================================================
static func draw_firefly_decoy(canvas: CanvasItem, center: Vector2, betrayed: bool, timer: float) -> void:
	var count := 12
	for i in range(count):
		var fi := float(i)
		var base_x := lerpf(240.0, 760.0, fi / float(count - 1))
		var base_y := 268.0 + sin(fi * 1.4 + timer * 2.1) * 18.0
		if betrayed:
			base_y -= clampf(sin(timer * 6.0 + fi) * 28.0 + 34.0, 0.0, 70.0)
			base_x += cos(timer * 5.0 + fi * 2.3) * 26.0
		var pos := Vector2(base_x, base_y)
		var pulse := 0.55 + 0.45 * sin(timer * 5.5 + fi * 1.9)
		var col := Color(0.98, 0.30, 0.36, 0.85 * pulse) if betrayed else Color(0.76, 1.0, 0.42, 0.85 * pulse)
		canvas.draw_circle(pos, 7.0 * pulse, Color(col.r, col.g, col.b, 0.18 * pulse))
		canvas.draw_circle(pos, 2.3, col)
	# Two subtle cool-cyan stray fireflies lingering quietly near left edge (ambient depth)
	for k in range(2):
		var p := Vector2(62.0 + float(k) * 14.0, 286.0 + sin(timer * 2.4 + float(k) * 2.0) * 6.0)
		canvas.draw_circle(p, 5.0, Color(0.35, 0.95, 0.72, 0.14))
		canvas.draw_circle(p, 1.8, Color(0.68, 1.0, 0.86, 0.55))

# =========================================================================
# 42. LIVING VINE BRIDGE (Level 42)
# =========================================================================
static func draw_living_vine_bridge(canvas: CanvasItem, segments: Array[Dictionary], timer: float) -> void:
	for seg in segments:
		var grow: float = float(seg["grow"])
		var r := Rect2(seg["pos"], seg["size"])
		var w := r.size.x * clampf(grow, 0.0, 1.0)
		# Dormant root bud node
		canvas.draw_circle(Vector2(r.position.x + 4.0, r.position.y + 8.0), 5.0, Color(0.08, 0.30, 0.18, 0.85))
		canvas.draw_circle(Vector2(r.position.x + 4.0, r.position.y + 8.0), 2.5, Color(0.36, 0.92, 0.54, 0.75))
		if w <= 10.0:
			if w > 3.0:
				canvas.draw_rect(Rect2(r.position, Vector2(w, r.size.y)), Color(0.07, 0.28, 0.16, 0.92), true)
			continue
		var dr := Rect2(r.position, Vector2(w, r.size.y))
		var wilting: bool = bool(seg.get("wilting", false))
		var alpha := (0.55 + 0.45 * absf(sin(timer * 22.0))) if wilting else 1.0
		var box_r := minf(4.5, minf(w * 0.25, r.size.y * 0.35))
		BaseArt.draw_rounded_box(canvas, dr, box_r, Color(0.07, 0.28, 0.16, 0.92 * alpha), Color(0.32, 0.88, 0.50, 0.88 * alpha), 1.6)
		# Woven vine twist & emerald leaves
		var pts := PackedVector2Array()
		var steps := maxi(3, int(w / 16.0))
		for si in range(steps + 1):
			var u := float(si) / float(steps)
			var vx := dr.position.x + u * w
			var vy := dr.position.y + dr.size.y * 0.5 + sin(u * PI * 3.0 + timer * 2.5) * 3.5
			pts.append(Vector2(vx, vy))
		canvas.draw_polyline(pts, Color(0.45, 0.96, 0.58, 0.78 * alpha), 1.6, true)
		if w > 24.0:
			_draw_leaf(canvas, Vector2(dr.end.x - 10.0, dr.position.y + 2.0), 12.0, 4.0, -0.45, Color(0.18, 0.64, 0.34, 0.9 * alpha), Color(0.68, 1.0, 0.78, 0.8 * alpha))

# =========================================================================
# 43. WHISPERING TOTEM CURSE (Level 43)
# =========================================================================
static func draw_whispering_totem(canvas: CanvasItem, base_pos: Vector2, active_mask: int, timer: float) -> void:
	# Towering carved mossy cedar totem pole with 3 glowing masks (0=Calm, 1=Trickster, 2=Wrath)
	var pole := Rect2(base_pos.x - 24.0, base_pos.y - 168.0, 48.0, 168.0)
	BaseArt.draw_rounded_box(canvas, pole, 6.0, Color(0.06, 0.16, 0.12, 0.90), Color(0.22, 0.52, 0.36, 0.55), 1.6)
	var mask_cols := [Color(0.26, 0.92, 0.52), Color(0.76, 0.44, 1.0), Color(0.98, 0.30, 0.36)]
	for i in range(3):
		var my := base_pos.y - 142.0 + float(i) * 52.0
		var lit := (i == active_mask)
		var pulse := (0.78 + 0.22 * sin(timer * 6.0)) if lit else 0.24
		var c: Color = mask_cols[i]
		var mc := Color(c.r, c.g, c.b, pulse)
		var mrect := Rect2(base_pos.x - 28.0, my - 18.0, 56.0, 38.0)
		BaseArt.draw_rounded_box(canvas, mrect, 7.0, Color(0.05, 0.13, 0.10, 0.94), mc, 1.8 if lit else 1.0)
		# Stylized carved eyes & mouth sigil
		canvas.draw_circle(Vector2(base_pos.x - 10.0, my - 4.0), 3.6 if lit else 2.5, mc)
		canvas.draw_circle(Vector2(base_pos.x + 10.0, my - 4.0), 3.6 if lit else 2.5, mc)
		canvas.draw_line(Vector2(base_pos.x - 11.0, my + 9.0), Vector2(base_pos.x + 11.0, my + 9.0), mc, 2.0, true)
		if lit:
			canvas.draw_arc(Vector2(base_pos.x, my), 34.0, 0.0, TAU, 28, Color(c.r, c.g, c.b, 0.26 * pulse), 1.6, true)

# =========================================================================
# 44. MOONLIT POND INVERSION (Level 44)
# =========================================================================
static func draw_moonlit_pond(canvas: CanvasItem, x_min: float, x_max: float, surface_y: float, floor_y: float, player_pos: Vector2, timer: float) -> void:
	var w := x_max - x_min
	var h := floor_y - surface_y + 12.0
	canvas.draw_rect(Rect2(x_min, surface_y, w, h), Color(0.04, 0.26, 0.22, 0.44), true)
	# Rippling moonlit water surface
	var surf := PackedVector2Array()
	for i in range(28):
		var u := float(i) / 27.0
		var x := lerpf(x_min, x_max, u)
		var y := surface_y + sin(x * 0.032 + timer * 2.8) * 2.6 + cos(x * 0.065 - timer * 1.9) * 1.2
		surf.append(Vector2(x, y))
	canvas.draw_polyline(surf, Color(0.56, 1.0, 0.84, 0.76), 2.2, true)
	# Moon reflection shimmer column & floating lily pads
	var mx := (x_min + x_max) * 0.5
	for k in range(5):
		var ry := surface_y + 10.0 + float(k) * 8.0
		var rw := 32.0 - float(k) * 4.5 + sin(timer * 3.0 + float(k)) * 4.0
		canvas.draw_line(Vector2(mx - rw, ry), Vector2(mx + rw, ry), Color(0.76, 1.0, 0.90, 0.28 - float(k) * 0.04), 2.0, true)
	if player_pos.x >= x_min and player_pos.x <= x_max and player_pos.y >= surface_y - 4.0:
		var r := 8.0 + fmod(timer * 24.0, 26.0)
		var a := (1.0 - (r - 8.0) / 26.0) * 0.55
		BaseArt.draw_ellipse_filled(canvas, Vector2(player_pos.x, surface_y + 2.0), Vector2(r, r * 0.28), Color(0.62, 1.0, 0.84, a))

# =========================================================================
# 45. SPORE CLOUD BOUNCE (Level 45)
# =========================================================================
static func draw_spore_mushrooms(canvas: CanvasItem, caps: Array[Dictionary], timer: float) -> void:
	for cap in caps:
		var pos: Vector2 = cap["pos"]
		var w: float = float(cap["w"])
		var squash: float = float(cap["squash"])
		var sx := 1.0 + squash * 0.28
		var sy := 1.0 - squash * 0.26
		var is_secret: bool = bool(cap.get("secret", false))
		var stem_col := Color(0.10, 0.24, 0.18, 0.92)
		var cap_col := Color(0.10, 0.42, 0.26, 0.92) if is_secret else Color(0.16, 0.68, 0.38, 0.94)
		var glow_col := Color(0.42, 1.0, 0.66, 0.24 if is_secret else 0.42)
		# Stem
		canvas.draw_rect(Rect2(pos.x - w * 0.16, pos.y - 16.0 * sy, w * 0.32, 16.0 * sy), stem_col, true)
		# Bioluminescent dome cap
		var cap_c := Vector2(pos.x, pos.y - 16.0 * sy)
		BaseArt.draw_ellipse_filled(canvas, cap_c, Vector2(w * 0.55 * sx, 13.0 * sy), glow_col)
		BaseArt.draw_ellipse_filled(canvas, cap_c, Vector2(w * 0.48 * sx, 10.0 * sy), cap_col)
		canvas.draw_arc(cap_c, w * 0.32 * sx, PI, TAU, 16, Color(0.78, 1.0, 0.86, 0.72), 1.4, true)
		# Rising spore motes when bounced
		if squash > 0.05:
			for k in range(5):
				var sx_p := pos.x + sin(float(k) * 2.1 + timer * 6.0) * (w * 0.5)
				var sy_p := pos.y - 22.0 - (1.0 - squash) * 34.0 - float(k) * 5.0
				canvas.draw_circle(Vector2(sx_p, sy_p), 2.2, Color(0.68, 1.0, 0.78, squash * 0.85))

# =========================================================================
# 46. OWL SENTINEL GAZE (Level 46)
# =========================================================================
static func draw_owl_sentinel(canvas: CanvasItem, perch: Vector2, gaze_open: bool, warning: float, sweep_x: float, timer: float) -> void:
	# Stylized gothic giant forest owl silhouette perched on canopy branch
	canvas.draw_line(perch + Vector2(-64.0, 26.0), perch + Vector2(64.0, 26.0), Color(0.05, 0.14, 0.10, 0.94), 6.0, true)
	var body := PackedVector2Array([
		perch + Vector2(-24.0, 24.0), perch + Vector2(-30.0, -4.0),
		perch + Vector2(-22.0, -28.0), perch + Vector2(-28.0, -40.0),
		perch + Vector2(-12.0, -32.0), perch + Vector2(12.0, -32.0),
		perch + Vector2(28.0, -40.0), perch + Vector2(22.0, -28.0),
		perch + Vector2(30.0, -4.0), perch + Vector2(24.0, 24.0),
	])
	canvas.draw_colored_polygon(body, Color(0.04, 0.12, 0.09, 0.95))
	var loop := PackedVector2Array(body)
	loop.append(body[0])
	canvas.draw_polyline(loop, Color(0.32, 0.74, 0.48, 0.58), 1.5, true)
	# Luminous amber/crimson owl eyes
	var eye_c := Color(1.0, 0.28, 0.34, 0.96) if warning > 0.05 else (Color(1.0, 0.82, 0.28, 0.96) if gaze_open else Color(0.28, 0.56, 0.42, 0.45))
	for sx in [-10.0, 10.0]:
		var ec := perch + Vector2(sx, -18.0)
		if gaze_open:
			canvas.draw_circle(ec, 5.8, eye_c)
			canvas.draw_circle(ec, 2.4, Color(0.04, 0.05, 0.06, 0.96))
		else:
			canvas.draw_line(ec - Vector2(5.0, 0.0), ec + Vector2(5.0, 0.0), eye_c, 2.0, true)
	# Sweeping golden sentinel gaze cone across lower clearing (y=310..405)
	if gaze_open:
		var cone_col := Color(1.0, 0.26, 0.32, 0.24 + warning * 0.22) if warning > 0.05 else Color(0.98, 0.84, 0.34, 0.17)
		var cone := PackedVector2Array([
			perch + Vector2(0.0, -14.0),
			Vector2(sweep_x - 115.0, 405.0),
			Vector2(sweep_x + 115.0, 405.0),
		])
		canvas.draw_colored_polygon(cone, cone_col)
		canvas.draw_line(perch + Vector2(0.0, -14.0), Vector2(sweep_x - 115.0, 405.0), Color(cone_col.r, cone_col.g, cone_col.b, 0.52), 1.4, true)
		canvas.draw_line(perch + Vector2(0.0, -14.0), Vector2(sweep_x + 115.0, 405.0), Color(cone_col.r, cone_col.g, cone_col.b, 0.52), 1.4, true)

# =========================================================================
# 47. ROOT LABYRINTH SHIFT (Level 47)
# =========================================================================
static func draw_sap_runes(canvas: CanvasItem, rune_a: Vector2, lit_a: bool, rune_b: Vector2, lit_b: bool, timer: float) -> void:
	for pair in [[rune_a, lit_a, true], [rune_b, lit_b, false]]:
		var p: Vector2 = pair[0]
		var lit: bool = bool(pair[1])
		var main_r: bool = bool(pair[2])
		var pulse := 0.72 + 0.28 * sin(timer * 4.0)
		var a := (0.90 if lit else (0.55 if main_r else 0.24)) * pulse
		var col := Color(0.32, 1.0, 0.62, a) if lit else Color(0.24, 0.78, 0.48, a)
		canvas.draw_circle(p, 16.0 if lit else 11.0, Color(col.r, col.g, col.b, a * 0.22))
		var d := 9.0 if main_r else 6.5
		var poly := PackedVector2Array([p + Vector2(0, -d), p + Vector2(d * 0.75, 0), p + Vector2(0, d), p + Vector2(-d * 0.75, 0)])
		canvas.draw_colored_polygon(poly, Color(0.06, 0.22, 0.14, 0.88))
		var loop := PackedVector2Array(poly)
		loop.append(poly[0])
		canvas.draw_polyline(loop, col, 1.8, true)

# =========================================================================
# 48. POLLEN DREAM DRIFT (Level 48)
# =========================================================================
static func draw_pollen_drift(canvas: CanvasItem, motes: Array[Dictionary], floating: bool, timer: float) -> void:
	# Ambient golden-emerald dream pollen throughout clearing
	for i in range(18):
		var px := fmod(float(i) * 59.0 + timer * 18.0 + sin(timer + float(i)) * 14.0, 920.0) + 20.0
		var py := fmod(float(i) * 37.0 + timer * 22.0, 440.0) + 60.0
		var a := 0.26 + 0.18 * sin(timer * 3.0 + float(i))
		canvas.draw_circle(Vector2(px, py), 2.1, Color(0.76, 1.0, 0.46, a))
	for m in motes:
		var a := clampf(float(m["life"]) / 0.85, 0.0, 1.0)
		canvas.draw_circle(m["pos"], 4.2 * a, Color(0.68, 1.0, 0.48, a * 0.30))
		canvas.draw_circle(m["pos"], 2.0 * a, Color(0.92, 1.0, 0.70, a * 0.85))
	if floating:
		canvas.draw_rect(Rect2(32.0, 48.0, 896.0, 492.0), Color(0.45, 0.96, 0.56, 0.045), true)

# =========================================================================
# 49. PHANTOM STAG GUIDE (Level 49)
# =========================================================================
static func draw_phantom_stag(canvas: CanvasItem, stag_pos: Vector2, pads: Array[Dictionary], timer: float) -> void:
	# Ethereal translucent silver-emerald Spirit Stag leaping across the ravine
	var p := stag_pos
	var body_c := Color(0.54, 1.0, 0.76, 0.34)
	var rim_c := Color(0.84, 1.0, 0.90, 0.78)
	var torso := PackedVector2Array([
		p + Vector2(-22.0, -8.0), p + Vector2(18.0, -14.0),
		p + Vector2(24.0, -2.0), p + Vector2(-18.0, 4.0),
	])
	canvas.draw_colored_polygon(torso, body_c)
	# Graceful neck, head & branching antlers
	canvas.draw_line(p + Vector2(16.0, -10.0), p + Vector2(28.0, -28.0), rim_c, 4.0, true)
	canvas.draw_circle(p + Vector2(31.0, -30.0), 5.0, rim_c)
	canvas.draw_polyline(PackedVector2Array([p + Vector2(28.0, -34.0), p + Vector2(22.0, -48.0), p + Vector2(15.0, -54.0)]), rim_c, 1.8, true)
	canvas.draw_polyline(PackedVector2Array([p + Vector2(24.0, -44.0), p + Vector2(30.0, -52.0)]), rim_c, 1.5, true)
	# Bounding legs
	var stride := sin(timer * 9.0) * 8.0
	canvas.draw_line(p + Vector2(14.0, -2.0), p + Vector2(24.0 + stride, 16.0), rim_c, 2.2, true)
	canvas.draw_line(p + Vector2(-16.0, 2.0), p + Vector2(-24.0 - stride, 16.0), rim_c, 2.2, true)
	# Blooming hoof platforms
	for pd in pads:
		var life: float = float(pd["life"])
		if life <= 0.0:
			continue
		var r := Rect2(pd["pos"], pd["size"])
		var a := clampf(life / 0.7, 0.0, 1.0)
		BaseArt.draw_rounded_box(canvas, r, 5.0, Color(0.10, 0.40, 0.26, 0.84 * a), Color(0.68, 1.0, 0.82, 0.94 * a), 1.6)
		canvas.draw_line(r.position + Vector2(8.0, 3.0), Vector2(r.end.x - 8.0, r.position.y + 3.0), Color(0.92, 1.0, 0.94, 0.78 * a), 1.4, true)

# =========================================================================
# 50. CANOPY ECLIPSE DARK (Level 50)
# =========================================================================
static func draw_canopy_eclipse(canvas: CanvasItem, beam_xs: Array[float], beam_w: float, timer: float) -> void:
	# Deep emerald eclipse twilight framed cleanly inside arena walls
	canvas.draw_rect(Rect2(32.0, 48.0, 896.0, 492.0), Color(0.015, 0.05, 0.038, 0.46), true)
	# Swaying radiant jade-gold sunbeam shafts piercing the canopy
	for i in range(beam_xs.size()):
		var bx := beam_xs[i]
		var poly := PackedVector2Array([
			Vector2(bx - beam_w * 0.40, 48.0),
			Vector2(bx + beam_w * 0.40, 48.0),
			Vector2(bx + beam_w * 0.62, 460.0),
			Vector2(bx - beam_w * 0.62, 460.0),
		])
		canvas.draw_colored_polygon(poly, Color(0.58, 1.0, 0.68, 0.14))
		canvas.draw_line(Vector2(bx, 48.0), Vector2(bx, 460.0), Color(0.84, 1.0, 0.78, 0.12), 6.0, true)

# =========================================================================
# 51. FAIRY RING PORTAL (Level 51)
# =========================================================================
static func draw_fairy_rings(canvas: CanvasItem, ring_a: Vector2, ring_b: Vector2, charge: float, warp_fx: float, timer: float) -> void:
	for idx in range(2):
		var c := ring_a if idx == 0 else ring_b
		var pulse := 0.7 + 0.3 * sin(timer * 3.8 + float(idx))
		var col := Color(0.42, 1.0, 0.68, 0.65 * pulse)
		BaseArt.draw_ellipse_filled(canvas, c + Vector2(0.0, -2.0), Vector2(28.0, 7.0), Color(0.24, 0.88, 0.52, 0.16 + (charge * 0.35 if idx == 0 else 0.0)))
		# Tiny stylized mushrooms encircling the ring
		for m in range(6):
			var mx := c.x + lerpf(-24.0, 24.0, float(m) / 5.0)
			var my := c.y - 2.0 + sin(float(m) * 1.3) * 2.0
			canvas.draw_line(Vector2(mx, my), Vector2(mx, my - 5.0), Color(0.75, 0.96, 0.82, 0.7), 1.6, true)
			BaseArt.draw_ellipse_filled(canvas, Vector2(mx, my - 6.0), Vector2(4.2, 2.4), col)
		if idx == 0 and charge > 0.02:
			canvas.draw_arc(c + Vector2(0.0, -18.0), 22.0, -PI * 0.5, -PI * 0.5 + TAU * charge, 24, Color(0.68, 1.0, 0.82, 0.92), 2.4, true)
		if warp_fx > 0.02:
			var r := 12.0 + (1.0 - warp_fx) * 44.0
			canvas.draw_arc(c + Vector2(0.0, -18.0), r, 0.0, TAU, 28, Color(0.60, 1.0, 0.80, warp_fx * 0.85), 2.2, true)

# =========================================================================
# 52. WEEPING WILLOW CURTAIN (Level 52)
# =========================================================================
static func draw_willow_curtain(canvas: CanvasItem, player_pos: Vector2, timer: float) -> void:
	# Graceful dark-emerald weeping willow strands draping from ceiling to y=268, parting dynamically around player!
	var count := 28
	for i in range(count):
		var bx := lerpf(64.0, 896.0, float(i) / float(count - 1))
		var length := 185.0 + sin(float(i) * 2.3) * 34.0
		var sway := sin(timer * 1.45 + float(i) * 0.65) * 10.0
		var push := 0.0
		if player_pos.y <= 275.0:
			var dx := bx - player_pos.x
			if absf(dx) < 62.0:
				push = signf(dx if absf(dx) > 0.5 else 1.0) * (62.0 - absf(dx)) * 0.75
		var p0 := Vector2(bx, 48.0)
		var p1 := Vector2(bx + sway * 0.5 + push * 0.6, 48.0 + length * 0.55)
		var p2 := Vector2(bx + sway + push, 48.0 + length)
		BaseArt.draw_quad_bezier(canvas, p0, p1, p2, Color(0.05, 0.20, 0.14, 0.78), 3.4, 8)
		BaseArt.draw_quad_bezier(canvas, p0, p1, p2, Color(0.24, 0.68, 0.42, 0.42), 1.1, 8)
		if i % 2 == 0:
			_draw_leaf(canvas, p1, 10.0, 3.2, 1.35, Color(0.08, 0.34, 0.22, 0.82), Color(0.38, 0.86, 0.54, 0.55))
			_draw_leaf(canvas, p2, 11.0, 3.4, 1.55, Color(0.08, 0.34, 0.22, 0.82), Color(0.38, 0.86, 0.54, 0.55))

# =========================================================================
# 53. CICADA SWARM RAFT (Level 53)
# =========================================================================
static func draw_cicada_swarm(canvas: CanvasItem, raft_pos: Vector2, raft_size: Vector2, timer: float) -> void:
	var r := Rect2(raft_pos, raft_size)
	BaseArt.draw_rounded_box(canvas, r, 6.0, Color(0.08, 0.28, 0.18, 0.88), Color(0.56, 1.0, 0.64, 0.88), 1.8)
	# Buzzing emerald-gold cicada wings hovering around the raft
	for i in range(10):
		var u := float(i) / 9.0
		var cx := lerpf(r.position.x + 6.0, r.end.x - 6.0, u)
		var cy := r.position.y + r.size.y * 0.5 + sin(timer * 18.0 + float(i) * 1.7) * 4.5
		canvas.draw_circle(Vector2(cx, cy), 4.5, Color(0.45, 1.0, 0.58, 0.22))
		canvas.draw_circle(Vector2(cx, cy), 2.1, Color(0.86, 1.0, 0.62, 0.90))

# =========================================================================
# 54. MOSS LEY-LINE GRAVITY (Level 54)
# =========================================================================
static func draw_moss_leyline(canvas: CanvasItem, line_y: float, player_above: bool, timer: float) -> void:
	# Glowing horizontal emerald ley-line across chamber
	var pts := PackedVector2Array()
	for i in range(33):
		var x := lerpf(32.0, 928.0, float(i) / 32.0)
		var y := line_y + sin(x * 0.025 + timer * 2.4) * 3.5
		pts.append(Vector2(x, y))
	var glow_a := 0.30 if player_above else 0.14
	canvas.draw_polyline(pts, Color(0.32, 0.96, 0.58, glow_a), 9.0, true)
	canvas.draw_polyline(pts, Color(0.76, 1.0, 0.84, 0.72 if player_above else 0.42), 1.8, true)
	if player_above:
		canvas.draw_rect(Rect2(32.0, 48.0, 896.0, line_y - 48.0), Color(0.24, 0.92, 0.54, 0.06), true)

# =========================================================================
# 55. ANCIENT STUMP RINGS (Level 55)
# =========================================================================
static func draw_stump_rings(canvas: CanvasItem, center: Vector2, active_ring: int, surge: bool, steps: Array[Dictionary], timer: float) -> void:
	for r_idx in range(1, 6):
		var rad := 26.0 + float(r_idx) * 24.0
		var lit := r_idx <= active_ring
		var col := Color(0.56, 1.0, 0.68, 0.62) if surge else (Color(0.30, 0.86, 0.50, 0.42) if lit else Color(0.14, 0.34, 0.24, 0.18))
		canvas.draw_arc(center, rad, 0.0, TAU, 40, col, 2.2 if (lit or surge) else 1.2, true)
	for st in steps:
		if not bool(st["solid"]):
			continue
		var r := Rect2(st["pos"], st["size"])
		BaseArt.draw_rounded_box(canvas, r, 4.0, Color(0.08, 0.32, 0.18, 0.92), Color(0.56, 1.0, 0.68, 0.92), 1.8)

# =========================================================================
# 56. WISP LANTERN ESCORT (Level 56)
# =========================================================================
static func draw_wisp_orb(canvas: CanvasItem, wisp_pos: Vector2, timer: float) -> void:
	var pulse := 0.88 + 0.12 * sin(timer * 6.0)
	canvas.draw_circle(wisp_pos, 18.0 * pulse, Color(0.34, 0.96, 0.62, 0.22))
	canvas.draw_circle(wisp_pos, 9.0 * pulse, Color(0.58, 1.0, 0.74, 0.58))
	canvas.draw_circle(wisp_pos, 4.2, Color(0.94, 1.0, 0.92, 0.96))
	# Delicate trailing wisp tail
	var tail := wisp_pos + Vector2(sin(timer * 5.0) * 6.0, 12.0)
	BaseArt.draw_quad_bezier(canvas, wisp_pos, wisp_pos + Vector2(0.0, 7.0), tail, Color(0.52, 1.0, 0.72, 0.58), 2.4, 6)

# =========================================================================
# 57. SPIRIT BAMBOO GUST (Level 57)
# =========================================================================
static func draw_spirit_bamboo(canvas: CanvasItem, stalks: Array[Dictionary], gust_pos: Vector2, gust_life: float, timer: float) -> void:
	for st in stalks:
		var base: Vector2 = st["base"]
		var h: float = float(st["h"])
		var bend: float = float(st["bend"])
		var top := base + Vector2(bend * 34.0, -h)
		var mid := base + Vector2(bend * 14.0, -h * 0.5)
		BaseArt.draw_quad_bezier(canvas, base, mid, top, Color(0.06, 0.26, 0.16, 0.92), 6.0, 8)
		BaseArt.draw_quad_bezier(canvas, base, mid, top, Color(0.36, 0.90, 0.52, 0.65), 1.8, 8)
		_draw_leaf(canvas, top, 16.0, 4.5, -0.35 + bend * 0.4, Color(0.18, 0.68, 0.36, 0.90), Color(0.72, 1.0, 0.80, 0.85))
		_draw_leaf(canvas, mid, 14.0, 4.0, 0.45 + bend * 0.4, Color(0.16, 0.60, 0.32, 0.85), Color(0.68, 1.0, 0.78, 0.75))
	if gust_life > 0.02:
		var a := clampf(gust_life / 1.4, 0.0, 1.0)
		var r := 22.0 + sin(timer * 10.0) * 3.0
		canvas.draw_arc(gust_pos, r, 0.0, TAU, 28, Color(0.56, 1.0, 0.70, a * 0.85), 2.8, true)
		canvas.draw_arc(gust_pos, r * 0.62, 0.0, TAU, 20, Color(0.90, 1.0, 0.84, a * 0.55), 1.4, true)

# =========================================================================
# 58. ROOT TREMOR SLABS (Level 58)
# =========================================================================
static func draw_tremor_slabs(canvas: CanvasItem, slabs: Array[Dictionary], quake_fx: float, timer: float) -> void:
	# Glowing subterranean root fissures pulsing during tremor
	if quake_fx > 0.02:
		for k in range(4):
			var fx := 140.0 + float(k) * 210.0
			canvas.draw_polyline(PackedVector2Array([Vector2(fx, 540.0), Vector2(fx + 14.0, 470.0), Vector2(fx - 10.0, 410.0)]), Color(0.42, 1.0, 0.62, quake_fx * 0.75), 2.4, true)
	for sl in slabs:
		var r := Rect2(sl["pos"], sl["size"])
		BaseArt.draw_rounded_box(canvas, r, 4.0, Color(0.06, 0.22, 0.15, 0.95), Color(0.38, 0.92, 0.56, 0.88), 1.8)
		canvas.draw_line(r.position + Vector2(8.0, 4.0), Vector2(r.end.x - 8.0, r.position.y + 4.0), Color(0.76, 1.0, 0.84, 0.58), 1.5, true)

# =========================================================================
# 59. OVERGROWTH CEILING VINES (Level 59)
# =========================================================================
static func draw_overgrowth_vines(canvas: CanvasItem, vine_y: float, started: bool, timer: float) -> void:
	if not started or vine_y <= 54.0:
		return
	var poly := PackedVector2Array([Vector2(0.0, 0.0), Vector2(960.0, 0.0), Vector2(960.0, vine_y)])
	for i in range(24, -1, -1):
		var px := float(i) * 40.0
		var tooth := 12.0 + sin(timer * 6.0 + float(i) * 1.4) * 6.0 + (10.0 if i % 2 == 0 else 0.0)
		poly.append(Vector2(px, vine_y + tooth))
	canvas.draw_colored_polygon(poly, Color(0.04, 0.19, 0.11, 0.86))
	canvas.draw_polyline(poly, Color(0.36, 0.92, 0.52, 0.90), 2.2, true)
	# Crimson thorn highlights along advancing bottom crest
	for k in range(12):
		var tx := 40.0 + float(k) * 80.0
		var ty := vine_y + 12.0
		var tri := PackedVector2Array([Vector2(tx - 5.0, ty), Vector2(tx + 5.0, ty), Vector2(tx, ty + 14.0)])
		canvas.draw_colored_polygon(tri, Color(0.92, 0.28, 0.36, 0.86))

# =========================================================================
# 60. WORLD TREE HEART FINALE (Level 60)
# =========================================================================
static func draw_world_tree_heart(canvas: CanvasItem, center: Vector2, phase: int, pads: Array[Dictionary], timer: float) -> void:
	# Colossal World Tree trunk silhouette & glowing roots
	canvas.draw_rect(Rect2(center.x - 42.0, 48.0, 84.0, 420.0), Color(0.04, 0.13, 0.09, 0.56), true)
	var phase_col := Color(0.30, 0.96, 0.56) if phase == 0 else (Color(1.0, 0.84, 0.32) if phase == 1 else Color(0.18, 0.48, 0.34))
	# Glowing ley-roots radiating down trunk
	for sx in [-28.0, 0.0, 28.0]:
		var pts := PackedVector2Array([
			center + Vector2(sx * 0.5, -18.0),
			center + Vector2(sx, 70.0),
			center + Vector2(sx * 2.2, 160.0),
		])
		canvas.draw_polyline(pts, Color(phase_col.r, phase_col.g, phase_col.b, 0.48), 2.4, true)
	# Pulsing World Tree Heart core
	var beat := 1.0 + 0.10 * sin(timer * (7.0 if phase == 1 else 3.2))
	canvas.draw_circle(center, 46.0 * beat, Color(phase_col.r, phase_col.g, phase_col.b, 0.16))
	canvas.draw_circle(center, 26.0 * beat, Color(0.05, 0.18, 0.12, 0.92))
	canvas.draw_arc(center, 26.0 * beat, 0.0, TAU, 36, Color(phase_col.r, phase_col.g, phase_col.b, 0.94), 2.6, true)
	canvas.draw_circle(center, 11.0 * beat, Color(phase_col.r, phase_col.g, phase_col.b, 0.88))
	# Golden Pulse Updraft column during Phase 1 (440..520)
	if phase == 1:
		canvas.draw_rect(Rect2(440.0, 140.0, 80.0, 285.0), Color(1.0, 0.86, 0.36, 0.14), true)
		for k in range(8):
			var u := fmod(float(k) * 0.17 + timer * 0.9, 1.0)
			var py := lerpf(420.0, 160.0, u)
			var px := 480.0 + sin(float(k) * 2.3 + timer * 4.0) * 24.0
			canvas.draw_line(Vector2(px, py + 12.0), Vector2(px, py - 10.0), Color(1.0, 0.92, 0.54, sin(u * PI) * 0.72), 2.0, true)
	# Blooming Blossom Pads (active during Phase 0 Bloom!)
	for pd in pads:
		var r := Rect2(pd["pos"], pd["size"])
		var solid: bool = bool(pd["solid"])
		if solid:
			BaseArt.draw_rounded_box(canvas, r, 6.0, Color(0.10, 0.42, 0.24, 0.90), Color(0.62, 1.0, 0.74, 0.94), 1.8)
			canvas.draw_line(r.position + Vector2(8.0, 3.0), Vector2(r.end.x - 8.0, r.position.y + 3.0), Color(0.95, 1.0, 0.92, 0.78), 1.4, true)
		else:
			canvas.draw_rect(r, Color(0.32, 0.76, 0.48, 0.14), false, 1.2)
