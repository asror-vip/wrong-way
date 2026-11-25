extends RefCounted

# High-craft procedural art & shader library for Wrong Way paranormal events.
# Every prop & effect is built with layered silhouettes, bevels, engravings,
# anatomical/architectural detail, and smooth GL Compatibility performance.

static var _eye_shader: Shader = null
static var _lantern_shader: Shader = null
static var _mist_shader: Shader = null

static func get_watching_eye_shader() -> Shader:
	if _eye_shader != null:
		return _eye_shader
	_eye_shader = Shader.new()
	_eye_shader.code = """
shader_type canvas_item;

uniform vec2 look_offset = vec2(0.0, 0.0);
uniform float blink = 0.0;
uniform float dilation = 0.35;
uniform float time_sec = 0.0;
uniform float alert = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 3; i++) {
		v += amp * vnoise(p);
		p = p * 2.07 + vec2(13.1, 7.7);
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 p = (UV - 0.5) * vec2(2.4, 1.5);
	float rx = 0.84;
	float nx = clamp(p.x / rx, -1.0, 1.0);
	float arch_base = max(0.0001, 1.0 - nx * nx);

	float open_k = clamp(1.0 - blink, 0.0, 1.0);
	float y_seam = 0.0;
	float arch_curve = 0.40 * pow(arch_base, 0.72);
	float y_top = mix(y_seam, -arch_curve, open_k);
	float y_bot = mix(y_seam, arch_curve, open_k);

	float in_x = smoothstep(rx + 0.03, rx - 0.015, abs(p.x));
	float d_top = p.y - y_top;
	float d_bot = y_bot - p.y;
	float aperture = in_x * smoothstep(-0.012, 0.014, d_top) * smoothstep(-0.012, 0.014, d_bot) * smoothstep(0.0, 0.04, open_k);

	// Soft smoky gothic aura & dark obsidian almond bevel dissolving cleanly into fog
	float orb_d = length(vec2(p.x * 0.78, p.y * 1.42));
	float edge_fade = smoothstep(1.16, 0.48, orb_d);
	float mist_halo = smoothstep(1.12, 0.25, orb_d) * 0.38 * edge_fade;

	vec3 frame_obsidian = vec3(0.075, 0.075, 0.11);
	vec3 rim_calm = vec3(0.55, 0.64, 0.78);
	vec3 rim_alert = vec3(0.95, 0.36, 0.44);
	vec3 rim_col = mix(rim_calm, rim_alert, alert);

	// Sculpted obsidian almond outer bezel
	float outer_curve = arch_curve + 0.075 * pow(arch_base, 0.55);
	float outer_top = mix(-0.045 * pow(arch_base, 0.55), -outer_curve, open_k);
	float outer_bot = mix(0.045 * pow(arch_base, 0.55), outer_curve, open_k);
	float outer_x = smoothstep(rx + 0.09, rx - 0.01, abs(p.x));
	float bezel = outer_x * smoothstep(-0.015, 0.020, p.y - outer_top) * smoothstep(-0.015, 0.020, outer_bot - p.y);

	float seam_glow = in_x * exp(-pow(p.y / 0.022, 2.0)) * smoothstep(0.35, 0.0, open_k);
	float upper_rim = in_x * exp(-pow(d_top / 0.018, 2.0));
	float lower_rim = in_x * exp(-pow(d_bot / 0.016, 2.0));
	float rim_mask = max(upper_rim, lower_rim);

	vec3 final_col = mix(vec3(0.05, 0.055, 0.085), frame_obsidian, bezel);
	final_col = mix(final_col, rim_col, seam_glow * 0.90);
	float final_alpha = clamp(mist_halo + bezel * 0.88 + seam_glow * 0.75, 0.0, 0.94) * edge_fade;

	if (aperture > 0.001) {
		// Luminous moonlit mist sclera interior (zero fleshy pink or capillaries)
		float radial_c = length(vec2(p.x * 0.92, p.y * 1.45));
		float mist_n = fbm(p * vec2(3.2, 4.0) + vec2(time_sec * 0.14, -time_sec * 0.09));
		vec3 mist_edge = mix(vec3(0.24, 0.27, 0.36), vec3(0.28, 0.14, 0.20), alert * 0.72);
		vec3 mist_mid = mix(vec3(0.84, 0.88, 0.96), vec3(0.90, 0.76, 0.80), alert * 0.38);
		vec3 sclera = mix(mist_mid, mist_edge, smoothstep(0.18, 0.88, radial_c));
		sclera *= (0.86 + 0.22 * mist_n);

		// Subtle inner shadow ring inside the almond frame
		float inner_rim_ao = smoothstep(0.0, 0.14, min(d_top, d_bot));
		sclera *= mix(0.42, 1.0, inner_rim_ao);
		sclera = mix(sclera, rim_col, (1.0 - inner_rim_ao) * alert * 0.35);

		// Stylized Arcane Celestial Tracking Iris
		vec2 ic = look_offset * vec2(0.27, 0.12);
		vec2 dp = p - ic;
		dp.x /= mix(1.0, 0.89, clamp(abs(look_offset.x), 0.0, 1.0));
		float r = length(dp);
		float ang = (r > 0.0001) ? atan(dp.y, dp.x) : 0.0;
		float ir = 0.31;
		float iris_mask = smoothstep(ir + 0.012, ir - 0.012, r);

		vec3 eye_col = sclera;
		if (iris_mask > 0.001) {
			float rn = clamp(r / ir, 0.0, 1.0);
			float rot_ang = ang + time_sec * (0.35 + alert * 0.45);
			float star_rays = 0.5 + 0.5 * cos(rot_ang * 12.0);
			float fine_rays = 0.5 + 0.5 * cos(rot_ang * 24.0 + rn * 4.0);

			vec3 outer_calm = vec3(0.14, 0.22, 0.38);
			vec3 mid_calm = vec3(0.56, 0.78, 0.96);
			vec3 inner_calm = vec3(0.90, 0.96, 1.0);

			vec3 outer_alert = vec3(0.26, 0.05, 0.10);
			vec3 mid_alert = vec3(0.92, 0.26, 0.34);
			vec3 inner_alert = vec3(1.0, 0.74, 0.78);

			vec3 c_outer = mix(outer_calm, outer_alert, alert);
			vec3 c_mid = mix(mid_calm, mid_alert, alert);
			vec3 c_inner = mix(inner_calm, inner_alert, alert);

			vec3 iris_col = mix(c_mid, c_outer, smoothstep(0.35, 0.92, rn));
			iris_col = mix(iris_col, c_inner, smoothstep(0.62, 0.22, rn) * (0.45 + 0.55 * star_rays));
			iris_col *= (0.76 + 0.32 * pow(star_rays, 2.0) + 0.14 * fine_rays);

			// Engraved concentric celestial inner ring & outer obsidian limbal border
			float compass_ring = exp(-pow((rn - 0.56) / 0.032, 2.0));
			iris_col = mix(iris_col, c_inner, compass_ring * 0.70);
			float limbal = smoothstep(0.80, 0.99, rn);
			iris_col = mix(iris_col, vec3(0.04, 0.045, 0.08), limbal * 0.94);

			// Crisp obsidian stylized pupil + hero-style clean specular glints
			float pupil_r = mix(0.095, 0.145, clamp(dilation, 0.0, 1.0)) + sin(time_sec * 3.4) * 0.002;
			float pupil_edge = exp(-pow((r - pupil_r) / 0.012, 2.0));
			iris_col = mix(iris_col, c_inner, pupil_edge * 0.48);
			float pupil_mask = smoothstep(pupil_r + 0.008, pupil_r - 0.008, r);
			iris_col = mix(iris_col, vec3(0.025, 0.025, 0.045), pupil_mask);

			eye_col = mix(eye_col, iris_col, iris_mask);
		}

		// Soft atmospheric upper-lid shadow
		float upper_cast = mix(0.45, 1.0, smoothstep(0.0, 0.18, d_top));
		eye_col *= upper_cast;

		// Stylized crisp geometric catchlights (matching hero eye highlight feel)
		float glint1 = smoothstep(0.046, 0.016, length(p - (ic * 0.65 + vec2(-0.105, -0.095))));
		float glint2 = smoothstep(0.024, 0.008, length(p - (ic * 0.65 + vec2(0.095, 0.075))));
		eye_col += vec3(0.96, 0.98, 1.0) * (glint1 * 0.90 + glint2 * 0.55);

		final_col = mix(final_col, eye_col, aperture);
		final_alpha = max(final_alpha, aperture * 0.96);
	}

	// Crisp obsidian inner contour + luminous accent hairline
	final_col = mix(final_col, frame_obsidian, rim_mask * 0.72);
	final_col = mix(final_col, rim_col, rim_mask * (0.28 + alert * 0.42));
	COLOR = vec4(final_col, clamp(final_alpha, 0.0, 1.0));
}
"""
	return _eye_shader

static func get_lantern_darkness_shader() -> Shader:
	if _lantern_shader != null:
		return _lantern_shader
	_lantern_shader = Shader.new()
	_lantern_shader.code = """
shader_type canvas_item;

uniform vec2 local_size = vec2(1800.0, 1100.0);
uniform vec2 lantern_pos = vec2(500.0, 644.0);
uniform float lantern_radius = 152.0;
uniform float darkness_alpha = 0.96;
uniform float time_sec = 0.0;
uniform float flash_amount = 0.0;

void fragment() {
	vec2 p = UV * local_size;
	vec2 delta = p - lantern_pos;
	float d = length(delta);
	float flicker = 1.0 + sin(time_sec * 17.0) * 0.018 + cos(time_sec * 29.0) * 0.012;
	float r = lantern_radius * flicker;

	float inner_lit = 1.0 - smoothstep(r * 0.16, r * 0.62, d);
	float outer_lit = 1.0 - smoothstep(r * 0.42, r * 1.06, d);
	float lit = clamp(outer_lit * 0.76 + inner_lit * 0.24, 0.0, 1.0);

	// Warm lantern glow tint near center, abyssal blue-black outside, cold flash during thunder
	vec3 dark_col = mix(vec3(0.012, 0.014, 0.028), vec3(0.70, 0.84, 1.0), flash_amount * 0.45);
	float dark_a = darkness_alpha * (1.0 - lit * 0.94);

	// Subtle warm lantern rim bloom right around the player
	float warm_halo = exp(-pow(d / (r * 0.52), 2.0)) * (1.0 - flash_amount * 0.8) * 0.12;
	vec3 col = mix(dark_col, vec3(1.0, 0.78, 0.46), clamp(warm_halo / max(dark_a + warm_halo, 0.001), 0.0, 1.0));
	COLOR = vec4(col, clamp(dark_a + warm_halo * 0.45, 0.0, 0.98));
}
"""
	return _lantern_shader

static func get_mind_flip_mist_shader() -> Shader:
	if _mist_shader != null:
		return _mist_shader
	_mist_shader = Shader.new()
	_mist_shader.code = """
shader_type canvas_item;

uniform vec2 local_size = vec2(896.0, 78.0);
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

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * n2(p);
		p = p * 2.03 + vec2(5.2, 1.3);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 px = UV * local_size;
	float wave = sin(px.x * 0.018 + time_sec * 1.45) * 6.5 + cos(px.x * 0.043 - time_sec * 2.1) * 3.2;
	float y_rel = px.y - (18.0 + wave);
	float surface_mask = smoothstep(-10.0, 16.0, y_rel);
	// Soft ground-contact fade right at the bottom edge so mist hugs the floor naturally
	float floor_fade = smoothstep(local_size.y, local_size.y - 6.0, px.y);

	vec2 uv1 = vec2(px.x * 0.0085 + time_sec * 0.16, px.y * 0.016 - time_sec * 0.06);
	vec2 uv2 = vec2(px.x * 0.016 - time_sec * 0.11, px.y * 0.024 + time_sec * 0.04);
	float cloud = fbm(uv1) * 0.62 + fbm(uv2) * 0.38;

	// Luminous wavy crest right along top boundary of mist
	float crest = exp(-pow(y_rel / 6.0, 2.0)) * (0.58 + 0.42 * cloud);
	float depth_grad = smoothstep(0.0, 1.0, UV.y);

	vec3 deep_col = vec3(0.36, 0.05, 0.16);
	vec3 mid_col = vec3(0.72, 0.13, 0.30);
	vec3 crest_col = vec3(1.0, 0.50, 0.66);

	vec3 col = mix(mid_col, deep_col, depth_grad * 0.58);
	col = mix(col, crest_col, clamp(crest * 1.25 + cloud * 0.24, 0.0, 1.0));
	float alpha = (surface_mask * (0.16 + cloud * 0.22 + depth_grad * 0.14) + crest * 0.36) * floor_fade;
	COLOR = vec4(col, clamp(alpha, 0.0, 0.62));
}
"""
	return _mist_shader

# =========================================================================
# SHARED GEOMETRY HELPERS
# =========================================================================

static func draw_ellipse_filled(canvas: CanvasItem, center: Vector2, rad: Vector2, col: Color, rot: float = 0.0, segs: int = 18) -> void:
	var pts := PackedVector2Array()
	var cr := cos(rot)
	var sr := sin(rot)
	for i in range(segs):
		var th := float(i) * TAU / float(segs)
		var lx := cos(th) * rad.x
		var ly := sin(th) * rad.y
		pts.append(center + Vector2(lx * cr - ly * sr, lx * sr + ly * cr))
	canvas.draw_colored_polygon(pts, col)

static func draw_rounded_box(canvas: CanvasItem, rect: Rect2, radius: float, fill: Color, stroke: Color = Color.TRANSPARENT, stroke_w: float = 0.0) -> void:
	var r := minf(radius, minf(rect.size.x * 0.5, rect.size.y * 0.5))
	var pts := PackedVector2Array()
	var corners := [
		Vector2(rect.end.x - r, rect.position.y + r),
		Vector2(rect.end.x - r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.position.y + r),
	]
	var starts := [-PI * 0.5, 0.0, PI * 0.5, PI]
	for ci in range(4):
		var c: Vector2 = corners[ci]
		var a0: float = starts[ci]
		for si in range(5):
			var ang := a0 + (PI * 0.5) * (float(si) / 4.0)
			pts.append(c + Vector2(cos(ang) * r, sin(ang) * r))
	if fill.a > 0.001:
		canvas.draw_colored_polygon(pts, fill)
	if stroke_w > 0.0 and stroke.a > 0.001:
		var loop := PackedVector2Array(pts)
		loop.append(pts[0])
		canvas.draw_polyline(loop, stroke, stroke_w, true)

static func draw_quad_bezier(canvas: CanvasItem, p0: Vector2, p1: Vector2, p2: Vector2, col: Color, width: float, segs: int = 10) -> void:
	var pts := PackedVector2Array()
	for i in range(segs + 1):
		var t := float(i) / float(segs)
		var mt := 1.0 - t
		pts.append(p0 * (mt * mt) + p1 * (2.0 * mt * t) + p2 * (t * t))
	canvas.draw_polyline(pts, col, width, true)

static func draw_iron_chain(canvas: CanvasItem, p_start: Vector2, p_end: Vector2, link_pitch: float = 10.5) -> void:
	var diff := p_end - p_start
	var dist := diff.length()
	if dist < 4.0:
		return
	var dir := diff / dist
	var perp := Vector2(-dir.y, dir.x)
	var count := maxi(2, int(round(dist / link_pitch)))
	var iron_dark := Color(0.11, 0.12, 0.16, 0.94)
	var iron_mid := Color(0.24, 0.26, 0.33, 0.90)
	var iron_hi := Color(0.68, 0.73, 0.84, 0.52)

	# Alternating interlocking forged-iron oval links & edge-on connecting bars
	for k in range(count):
		var u0 := float(k) / float(count)
		var u1 := float(k + 1) / float(count)
		var a := p_start.lerp(p_end, u0)
		var b := p_start.lerp(p_end, u1)
		var mid := (a + b) * 0.5
		var half_l := a.distance_to(b) * 0.62
		if k % 2 == 0:
			# Front-facing elongated oval chain link
			var lpts := PackedVector2Array()
			for si in range(11):
				var th := float(si) * TAU / 10.0
				var lx := cos(th) * 3.1
				var ly := sin(th) * half_l
				lpts.append(mid + perp * lx + dir * ly)
			canvas.draw_polyline(lpts, iron_dark, 2.4, true)
			canvas.draw_polyline(lpts, iron_mid, 1.4, true)
			# Specular metal glint on left outer side of oval link
			canvas.draw_line(mid - perp * 2.6 - dir * (half_l * 0.45), mid - perp * 2.6 + dir * (half_l * 0.35), iron_hi, 0.9, true)
		else:
			# Edge-on interlocking link bar visibly bridging the two oval rings
			var p0 := mid - dir * (half_l * 1.15)
			var p1 := mid + dir * (half_l * 1.15)
			canvas.draw_line(p0, p1, iron_dark, 3.6, true)
			canvas.draw_line(p0, p1, iron_mid, 2.0, true)
			canvas.draw_line(p0 - perp * 0.7, p1 - perp * 0.7, iron_hi, 0.85, true)

# =========================================================================
# 1. PHANTOM FOOTPRINTS (Level 1) — Realistic anatomical sole + toes + dust
# =========================================================================

static func _draw_single_footprint(canvas: CanvasItem, pos: Vector2, facing_right: bool, is_left_foot: bool, col: Color, glow_col: Color) -> void:
	var s := 1.0 if facing_right else -1.0
	var flip_y := -1.0 if is_left_foot else 1.0
	# Soft dusty spectral halo beneath print
	draw_ellipse_filled(canvas, pos + Vector2(0.0, 1.0), Vector2(10.5, 4.2), glow_col)
	# Heel pad (sculpted rounded heel)
	draw_ellipse_filled(canvas, pos + Vector2(-5.2 * s, 0.5 * flip_y), Vector2(3.1, 2.2), col)
	# Arch bridge (narrow curved instep)
	draw_ellipse_filled(canvas, pos + Vector2(-1.4 * s, 0.8 * flip_y), Vector2(2.4, 1.3), Color(col.r, col.g, col.b, col.a * 0.72))
	# Forefoot ball pad
	draw_ellipse_filled(canvas, pos + Vector2(2.8 * s, 0.2 * flip_y), Vector2(3.4, 2.5), col)
	# 5 sculpted toes curving naturally from big toe to pinky
	var toe_offsets := [
		Vector2(6.9, -1.5),
		Vector2(7.4, -0.3),
		Vector2(7.0, 0.8),
		Vector2(6.2, 1.7),
		Vector2(5.1, 2.3),
	]
	var toe_rads := [1.25, 1.0, 0.9, 0.8, 0.68]
	for ti in range(5):
		var off: Vector2 = toe_offsets[ti]
		canvas.draw_circle(pos + Vector2(off.x * s, off.y * flip_y), toe_rads[ti], col)

static func draw_phantom_footprints(canvas: CanvasItem, footprints: Array[Dictionary], trigger_pos: Vector2, timer: float) -> void:
	for i in range(footprints.size()):
		var fp: Dictionary = footprints[i]
		var a := clampf(float(fp["life"]) / 2.4, 0.0, 1.0)
		var p: Vector2 = fp["pos"]
		var dir_x: float = float(fp.get("dir", 1.0))
		var left_f: bool = (i % 2) == 0
		var y_off := 2.0 if left_f else 5.0
		var print_pos := Vector2(p.x, p.y + y_off)
		var col := Color(0.76, 0.90, 1.0, a * 0.62)
		var glow := Color(0.55, 0.78, 1.0, a * 0.16)
		_draw_single_footprint(canvas, print_pos, dir_x >= 0.0, left_f, col, glow)
		# Tiny spectral dust wisp rising off fresh steps
		if a > 0.35:
			var rise := (1.0 - a) * 16.0
			var wx := print_pos.x + sin(timer * 3.0 + float(i) * 1.7) * 2.5
			canvas.draw_circle(Vector2(wx, print_pos.y - 4.0 - rise), 1.4, Color(0.82, 0.93, 1.0, (a - 0.35) * 0.55))

	# Eerie crimson halted pair of phantom footprints right before the hidden trap floor
	var pulse := 0.72 + 0.28 * sin(timer * 3.4)
	var warn_col := Color(0.96, 0.36, 0.48, 0.58 * pulse)
	var warn_glow := Color(0.96, 0.22, 0.36, 0.18 * pulse)
	_draw_single_footprint(canvas, trigger_pos + Vector2(-4.0, 2.0), true, true, warn_col, warn_glow)
	_draw_single_footprint(canvas, trigger_pos + Vector2(2.0, 6.0), true, false, Color(warn_col.r, warn_col.g, warn_col.b, warn_col.a * 0.78), warn_glow)
	# Subtle trembling dust crack ring right at the edge
	var ring_r := 8.0 + fmod(timer * 14.0, 18.0)
	var ring_a := (1.0 - (ring_r - 8.0) / 18.0) * 0.28
	canvas.draw_arc(trigger_pos + Vector2(12.0, 2.0), ring_r, PI, TAU, 16, Color(0.96, 0.42, 0.52, ring_a), 1.2, true)

# =========================================================================
# 2. FROZEN PENDULUM (Level 2) — Ornate Antique Victorian Brass Pendulum
# =========================================================================

static func draw_frozen_pendulum(canvas: CanvasItem, pivot: Vector2, length: float, angle: float, timer: float, triggered: bool) -> void:
	var dir := Vector2(sin(angle), cos(angle))
	var perp := Vector2(cos(angle), -sin(angle))
	var bob := pivot + dir * length

	var brass_dark := Color(0.24, 0.19, 0.12, 0.88)
	var brass_mid := Color(0.64, 0.52, 0.30, 0.88) if not triggered else Color(0.56, 0.70, 0.90, 0.90)
	var brass_hi := Color(0.92, 0.82, 0.56, 0.90) if not triggered else Color(0.84, 0.94, 1.0, 0.94)
	var iron_col := Color(0.14, 0.15, 0.20, 0.92)

	# 1. Soft atmospheric shadow behind rod & bob
	var shadow_off := Vector2(5.0, 6.0)
	canvas.draw_line(pivot + shadow_off, bob + shadow_off, Color(0.0, 0.0, 0.0, 0.26), 5.0, true)
	canvas.draw_circle(bob + shadow_off, 26.0, Color(0.0, 0.0, 0.0, 0.24))

	# 2. Ornate ceiling wall-mount escutcheon plate (anchored cleanly beneath ceiling spikes via forged iron stem)
	canvas.draw_line(Vector2(pivot.x, 62.0), pivot + Vector2(0.0, 2.0), iron_col, 7.0, true)
	canvas.draw_line(Vector2(pivot.x - 1.2, 62.0), pivot + Vector2(-1.2, 2.0), brass_mid, 1.4, true)
	var esc_pts := PackedVector2Array([
		pivot + Vector2(-24.0, -4.0),
		pivot + Vector2(24.0, -4.0),
		pivot + Vector2(19.0, 8.0),
		pivot + Vector2(9.0, 15.0),
		pivot + Vector2(0.0, 20.0),
		pivot + Vector2(-9.0, 15.0),
		pivot + Vector2(-19.0, 8.0),
	])
	canvas.draw_colored_polygon(esc_pts, iron_col)
	var esc_loop := PackedVector2Array(esc_pts)
	esc_loop.append(esc_pts[0])
	canvas.draw_polyline(esc_loop, brass_mid, 1.5, true)
	# Scrollwork wings on escutcheon
	draw_quad_bezier(canvas, pivot + Vector2(-18.0, 2.0), pivot + Vector2(-10.0, 11.0), pivot + Vector2(-4.0, 6.0), brass_hi, 1.2)
	draw_quad_bezier(canvas, pivot + Vector2(18.0, 2.0), pivot + Vector2(10.0, 11.0), pivot + Vector2(4.0, 6.0), brass_hi, 1.2)
	canvas.draw_circle(pivot + Vector2(0.0, 5.0), 5.2, brass_dark)
	canvas.draw_circle(pivot + Vector2(0.0, 5.0), 3.4, brass_mid)
	canvas.draw_circle(pivot + Vector2(-1.0, 4.0), 1.3, brass_hi)

	# 3. Beveled pendulum rod with ornate turned brass collars
	var rod_start := pivot + dir * 10.0
	var rod_end := bob - dir * 24.0
	canvas.draw_line(rod_start - perp * 1.4, rod_end - perp * 1.4, brass_dark, 2.2, true)
	canvas.draw_line(rod_start, rod_end, brass_mid, 2.0, true)
	canvas.draw_line(rod_start + perp * 1.1, rod_end + perp * 1.1, Color(brass_hi.r, brass_hi.g, brass_hi.b, 0.55), 1.0, true)

	# Turned collars along rod
	for frac in [0.22, 0.52, 0.80]:
		var cp := rod_start.lerp(rod_end, frac)
		canvas.draw_line(cp - perp * 5.2, cp + perp * 5.2, brass_dark, 4.5, true)
		canvas.draw_line(cp - perp * 4.4, cp + perp * 4.4, brass_mid, 2.6, true)
		canvas.draw_circle(cp - dir * 4.0, 2.6, brass_mid)
		canvas.draw_circle(cp + dir * 4.0, 2.6, brass_mid)

	# 4. Ornate Victorian sunburst brass pendulum bob
	# Top crown neck & bottom turned finial
	var top_neck := bob - dir * 27.0
	var bot_tip := bob + dir * 34.0
	var finial_pts := PackedVector2Array([
		bob + dir * 23.0 - perp * 5.5,
		bob + dir * 28.0 - perp * 2.4,
		bot_tip,
		bob + dir * 28.0 + perp * 2.4,
		bob + dir * 23.0 + perp * 5.5,
	])
	canvas.draw_colored_polygon(finial_pts, brass_mid)
	canvas.draw_line(bob + dir * 23.0, bot_tip, brass_hi, 1.1, true)
	canvas.draw_circle(top_neck, 4.5, brass_dark)
	canvas.draw_circle(top_neck, 3.0, brass_hi)

	# Multi-layered beveled brass disc
	canvas.draw_circle(bob, 25.5, brass_dark)
	canvas.draw_circle(bob, 23.5, brass_mid)
	canvas.draw_circle(bob, 19.5, Color(0.16, 0.13, 0.10, 0.90) if not triggered else Color(0.11, 0.16, 0.25, 0.92))
	canvas.draw_arc(bob, 19.5, 0.0, TAU, 36, brass_hi, 1.5, true)
	canvas.draw_arc(bob, 24.5, 0.0, TAU, 36, Color(brass_hi.r, brass_hi.g, brass_hi.b, 0.55), 1.1, true)

	# Engraved 12-point sunburst filigree rays inside bob
	for i in range(12):
		var a := float(i) * TAU / 12.0 - angle
		var r_in := 7.5
		var r_out := 17.5 if (i % 2 == 0) else 13.5
		var ray_dir := Vector2(cos(a), sin(a))
		var ray_p := Vector2(-ray_dir.y, ray_dir.x)
		var ray_pts := PackedVector2Array([
			bob + ray_dir * r_in - ray_p * 1.4,
			bob + ray_dir * r_out,
			bob + ray_dir * r_in + ray_p * 1.4,
		])
		canvas.draw_colored_polygon(ray_pts, brass_mid if (i % 2 == 0) else Color(brass_hi.r, brass_hi.g, brass_hi.b, 0.65))

	# Center embossed jewel medallion & specular crescent
	canvas.draw_circle(bob, 7.6, brass_dark)
	canvas.draw_circle(bob, 6.2, brass_mid)
	canvas.draw_circle(bob, 3.6, Color(0.55, 0.18, 0.22, 0.92) if not triggered else Color(0.50, 0.85, 1.0, 0.95))
	canvas.draw_arc(bob, 16.5, -2.5, -0.7, 14, Color(1.0, 0.98, 0.90, 0.52), 1.8, true)
	canvas.draw_circle(bob + Vector2(-1.4, -1.4), 1.3, Color(1.0, 1.0, 1.0, 0.85))

	# Frozen time crystalline rings & ice-shard glint when stopped!
	if triggered:
		var pulse := 0.55 + 0.45 * sin(timer * 3.0)
		canvas.draw_arc(bob, 31.0, 0.0, TAU, 32, Color(0.65, 0.88, 1.0, 0.34 * pulse), 1.5, true)
		canvas.draw_arc(bob, 37.0, 0.4, 2.4, 16, Color(0.80, 0.94, 1.0, 0.24 * pulse), 1.2, true)
		canvas.draw_arc(bob, 37.0, 3.5, 5.5, 16, Color(0.80, 0.94, 1.0, 0.24 * pulse), 1.2, true)
		for k in range(4):
			var ka := float(k) * PI * 0.5 + PI * 0.25
			var kp := bob + Vector2(cos(ka), sin(ka)) * 29.0
			var kd := Vector2(cos(ka), sin(ka))
			canvas.draw_line(kp, kp + kd * 7.0, Color(0.82, 0.95, 1.0, 0.48 * pulse), 1.4, true)

# =========================================================================
# 3. DEATH TALLY WALL (Level 3) — Carved Stone Tablet & Prisoner Tally Marks
# =========================================================================

static func draw_death_tally_wall(canvas: CanvasItem, origin: Vector2, deaths_seen: int, timer: float, font: Font) -> void:
	# Hanging interlocking wrought-iron chains grounding the antique slate tally tablet to the ceiling
	var slab := Rect2(origin - Vector2(22.0, 38.0), Vector2(216.0, 116.0))
	for sx_v in [slab.position.x + 28.0, slab.end.x - 28.0]:
		var sx: float = float(sx_v)
		var top_p := Vector2(sx, 68.0)
		var bot_p := Vector2(sx, slab.position.y + 4.0)
		draw_iron_chain(canvas, top_p, bot_p, 10.0)
		# Iron mounting ring & bolt on top of slate
		canvas.draw_circle(bot_p + Vector2(0.0, 4.0), 4.6, Color(0.12, 0.13, 0.18, 0.94))
		canvas.draw_circle(bot_p + Vector2(0.0, 4.0), 2.1, Color(0.68, 0.72, 0.82, 0.62))

	# Weathered hanging carved slate tablet with beveled dark shadow & chipped stone edges
	var slab_pts := PackedVector2Array([
		slab.position + Vector2(6.0, 2.0),
		slab.position + Vector2(slab.size.x * 0.48, 0.0),
		slab.position + Vector2(slab.size.x - 5.0, 3.0),
		slab.position + Vector2(slab.size.x, slab.size.y * 0.52),
		slab.position + Vector2(slab.size.x - 4.0, slab.size.y - 2.0),
		slab.position + Vector2(slab.size.x * 0.44, slab.size.y),
		slab.position + Vector2(4.0, slab.size.y - 3.0),
		slab.position + Vector2(0.0, slab.size.y * 0.45),
	])
	var sh_pts := PackedVector2Array()
	for sp in slab_pts:
		sh_pts.append(sp + Vector2(5.0, 6.0))
	canvas.draw_colored_polygon(sh_pts, Color(0.0, 0.0, 0.0, 0.28))
	canvas.draw_colored_polygon(slab_pts, Color(0.10, 0.11, 0.15, 0.76))
	var slab_loop := PackedVector2Array(slab_pts)
	slab_loop.append(slab_pts[0])
	canvas.draw_polyline(slab_loop, Color(0.66, 0.72, 0.84, 0.28), 1.6, true)
	# Inner chiseled border frame
	canvas.draw_rect(slab.grow(-7.0), Color(0.55, 0.60, 0.72, 0.14), false, 1.0)
	# Corner stone fracture details
	canvas.draw_polyline(PackedVector2Array([
		slab.position + Vector2(18.0, 2.0),
		slab.position + Vector2(24.0, 14.0),
		slab.position + Vector2(20.0, 24.0),
	]), Color(0.02, 0.02, 0.03, 0.55), 1.4, true)
	canvas.draw_polyline(PackedVector2Array([
		slab.end - Vector2(28.0, 2.0),
		slab.end - Vector2(36.0, 15.0),
		slab.end - Vector2(31.0, 25.0),
	]), Color(0.02, 0.02, 0.03, 0.55), 1.4, true)

	# Authentic prisoner-scratched tally marks grouped in 5s (4 vertical + 1 diagonal slash)
	var marks := mini(1 + deaths_seen, 20)
	var groove_col := Color(0.02, 0.02, 0.04, 0.65)
	var chalk_col := Color(0.88, 0.90, 0.96, 0.52)
	var red_chalk := Color(0.95, 0.42, 0.48, 0.58)

	for i in range(marks):
		var group_idx := i / 5
		var in_group := i % 5
		var row := group_idx / 2
		var col_g := group_idx % 2
		var gx := origin.x + float(col_g) * 86.0
		var gy := origin.y + float(row) * 38.0
		var is_newest := (i == marks - 1 and deaths_seen > 0)
		var stroke := red_chalk if is_newest else chalk_col

		if in_group < 4:
			var jitter_x := sin(float(i) * 4.3) * 1.4
			var lean := cos(float(i) * 2.7) * 2.2
			var h := 22.0 + sin(float(i) * 6.1) * 2.5
			var p0 := Vector2(gx + float(in_group) * 12.0 + jitter_x, gy)
			var pm := Vector2(p0.x + lean * 0.45 + sin(float(i) * 9.0) * 0.9, gy + h * 0.5)
			var p1 := Vector2(p0.x + lean, gy + h)
			# Carved groove shadow + chalky bright ridge
			canvas.draw_polyline(PackedVector2Array([p0 + Vector2(1.4, 1.0), pm + Vector2(1.4, 1.0), p1 + Vector2(1.4, 1.0)]), groove_col, 2.8, true)
			canvas.draw_polyline(PackedVector2Array([p0, pm, p1]), stroke, 2.1, true)
			# Chipped dust speck below scratch
			canvas.draw_circle(p1 + Vector2(0.5, 3.0), 0.9, Color(stroke.r, stroke.g, stroke.b, stroke.a * 0.45))
		else:
			# Rough diagonal 5th-mark slash crossing the 4 verticals!
			var s0 := Vector2(gx - 6.0, gy + 20.0)
			var sm := Vector2(gx + 18.0, gy + 10.5)
			var s1 := Vector2(gx + 44.0, gy + 2.0)
			canvas.draw_polyline(PackedVector2Array([s0 + Vector2(1.4, 1.4), sm + Vector2(1.4, 1.4), s1 + Vector2(1.4, 1.4)]), groove_col, 3.0, true)
			canvas.draw_polyline(PackedVector2Array([s0, sm, s1]), stroke, 2.3, true)

	# Scratched eerie message after first death
	if deaths_seen > 0 and font:
		var flicker := 0.78 + 0.22 * sin(timer * 5.2)
		var msg := "SEN..." if deaths_seen < 4 else "YANA SEN..."
		canvas.draw_string(font, origin + Vector2(1.5, -13.5), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.02, 0.01, 0.02, 0.65))
		canvas.draw_string(font, origin + Vector2(0.0, -15.0), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.95, 0.42, 0.48, 0.56 * flicker))
		# Scratchy underline
		draw_quad_bezier(canvas, origin + Vector2(-2.0, -11.0), origin + Vector2(36.0, -9.0), origin + Vector2(76.0, -12.0), Color(0.95, 0.42, 0.48, 0.30 * flicker), 1.2)

# =========================================================================
# 4. WATCHING EYE GOTHIC FILIGREE FRAME (Level 4) — Stylized Arcane Sun-Eye
# =========================================================================

static func draw_watching_eye_lashes(canvas: CanvasItem, center: Vector2, blink: float, timer: float, triggered: bool) -> void:
	var rx := 84.0
	var open_k := clampf(1.0 - blink, 0.0, 1.0)
	var accent := Color(0.98, 0.36, 0.45, 0.65) if triggered else Color(0.74, 0.86, 0.98, 0.46)
	var accent_soft := Color(accent.r, accent.g, accent.b, accent.a * 0.42)
	var obsidian := Color(0.06, 0.06, 0.095, 0.90)

	# 1. Seamless multi-ring ambient mist aura harmonizing with background ruins & hero eyes
	var pulse := 0.5 + 0.5 * sin(timer * (4.4 if triggered else 1.9))
	for ring in range(8):
		var frac := float(ring) / 7.0
		var sc := 0.88 + frac * 0.72
		var a := (0.022 if triggered else 0.011) * (0.75 + 0.25 * pulse) * pow(1.0 - frac, 1.5)
		draw_ellipse_filled(canvas, center, Vector2(92.0 * sc, 52.0 * sc), Color(accent.r, accent.g, accent.b, a))

	# 2. Pointed gothic double-contour arch lines matching shader almond curve
	var pts_top_in := PackedVector2Array()
	var pts_bot_in := PackedVector2Array()
	var pts_top_out := PackedVector2Array()
	var pts_bot_out := PackedVector2Array()
	var steps := 24
	for s in range(steps + 1):
		var u := -1.0 + 2.0 * (float(s) / float(steps))
		var arch := maxf(0.0001, 1.0 - u * u)
		var y_arch := 40.0 * pow(arch, 0.72) * open_k
		var y_outer := y_arch + 5.5 * pow(arch, 0.55)
		var x := center.x + u * rx
		pts_top_in.append(Vector2(x, center.y - y_arch))
		pts_bot_in.append(Vector2(x, center.y + y_arch))
		pts_top_out.append(Vector2(x, center.y - y_outer))
		pts_bot_out.append(Vector2(x, center.y + y_outer))

	canvas.draw_polyline(pts_top_out, obsidian, 2.2, true)
	canvas.draw_polyline(pts_bot_out, obsidian, 2.0, true)
	canvas.draw_polyline(pts_top_in, accent, 1.35, true)
	canvas.draw_polyline(pts_bot_in, accent_soft, 1.2, true)

	# 3. Symmetrical celestial sunburst engraving rays (above & below, fading smoothly when blinking)
	var ray_alpha := smoothstep(0.15, 0.85, open_k)
	if ray_alpha > 0.02:
		for side in [-1.0, 1.0]:
			var ray_count := 11 if side < 0.0 else 9
			for i in range(ray_count):
				var frac := float(i) / float(ray_count - 1)
				var u := lerpf(-0.72, 0.72, frac)
				var arch := maxf(0.0001, 1.0 - u * u)
				var y_arch := (40.0 * pow(arch, 0.72) * open_k) + 6.5 * pow(arch, 0.55)
				var base := center + Vector2(u * rx, side * y_arch)
				var is_major := (i % 2 == 0)
				var base_len := (13.0 if is_major else 7.5) if side < 0.0 else (9.5 if is_major else 5.5)
				var ray_len := base_len * (0.62 + 0.58 * arch) * ray_alpha
				var dir_vec := Vector2(u * 0.55, side * 1.0).normalized()
				var tip := base + dir_vec * ray_len
				var col := Color(accent.r, accent.g, accent.b, (0.52 if is_major else 0.30) * ray_alpha)
				canvas.draw_line(base, tip, col, 1.45 if is_major else 1.0, true)
				if is_major and side < 0.0:
					canvas.draw_circle(tip + dir_vec * 2.5, 1.35, Color(accent.r, accent.g, accent.b, 0.60 * ray_alpha))

	# 4. Ornate corner diamond sigils anchored beyond the pointed almond tips
	for sx in [-1.0, 1.0]:
		var drift := sin(timer * 2.2 + sx) * 2.0
		var dc := center + Vector2(sx * 95.0, drift)
		var ds := 4.4
		var d_poly := PackedVector2Array([
			dc + Vector2(0.0, -ds * 1.2),
			dc + Vector2(ds * 0.9, 0.0),
			dc + Vector2(0.0, ds * 1.2),
			dc + Vector2(-ds * 0.9, 0.0),
		])
		var d_outline := PackedVector2Array([d_poly[0], d_poly[1], d_poly[2], d_poly[3], d_poly[0]])
		canvas.draw_colored_polygon(d_poly, obsidian)
		canvas.draw_polyline(d_outline, accent, 1.1, true)
		var tiny_c := dc + Vector2(sx * 10.5, -drift * 0.5)
		canvas.draw_circle(tiny_c, 1.6, accent_soft)

# =========================================================================
# 5. BETRAYING ARROW (Level 5) — Ornate Weathered Wood & Wrought-Iron Sign
# =========================================================================

static func draw_betraying_arrow(canvas: CanvasItem, center: Vector2, triggered: bool, timer: float, font: Font) -> void:
	var sway := sin(timer * (3.6 if triggered else 1.4)) * (0.045 if triggered else 0.018)
	var dir := -1.0 if triggered else 1.0
	var cs := cos(sway)
	var sn := sin(sway)
	var w := 82.0
	var h := 22.0
	var tip_len := 26.0

	# Hanging interlocking wrought-iron chains anchored to the rotated top brackets of the sign
	for sx in [-46.0, 46.0]:
		var local_hook := Vector2(sx, -h - 1.0)
		var rot_hook := Vector2(local_hook.x * cs - local_hook.y * sn, local_hook.x * sn + local_hook.y * cs)
		var top_p := Vector2(center.x + sx, 68.0)
		var bot_p := center + rot_hook
		draw_iron_chain(canvas, top_p, bot_p, 10.5)
		canvas.draw_circle(bot_p, 3.6, Color(0.14, 0.15, 0.20, 0.94))

	# Shaped wooden directional arrow plank (points right before trigger, snaps left after!)
	var local_pts := PackedVector2Array([
		Vector2(-w * dir, -h),
		Vector2((w - tip_len) * dir, -h),
		Vector2(w * dir, 0.0),
		Vector2((w - tip_len) * dir, h),
		Vector2(-w * dir, h),
		Vector2((-w + 7.0) * dir, 6.0),
		Vector2((-w + 2.0) * dir, -3.0),
	])

	# Rotate the entire physical wooden plank, grain, iron straps, rivets, and lettering together!
	canvas.draw_set_transform(center, sway)

	# Drop shadow
	var sh_pts := PackedVector2Array()
	for lp in local_pts:
		sh_pts.append(lp + Vector2(5.0, 6.0))
	canvas.draw_colored_polygon(sh_pts, Color(0.0, 0.0, 0.0, 0.32))

	# Weathered timber plank body
	var wood_fill := Color(0.18, 0.14, 0.12, 0.92) if not triggered else Color(0.20, 0.075, 0.095, 0.94)
	var wood_rim := Color(0.56, 0.62, 0.72, 0.50) if not triggered else Color(0.95, 0.32, 0.42, 0.78)
	canvas.draw_colored_polygon(local_pts, wood_fill)

	# Subtle weathered woodgrain streaks aligned with the rotated plank
	for g in range(-2, 3):
		var gy := float(g) * 7.5
		var ga := Vector2((-w + 14.0) * dir, gy)
		var gb := Vector2((w - tip_len - 4.0) * dir, gy + sin(float(g) * 1.9) * 1.8)
		canvas.draw_line(ga, gb, Color(0.07, 0.05, 0.04, 0.48), 1.1, true)

	# Wrought-iron mounting straps & rivets locked seamlessly onto the rotated plank
	for sx in [-46.0, 46.0]:
		var strap := Rect2(sx - 4.2, -h - 1.0, 8.4, h * 2.0 + 2.0)
		canvas.draw_rect(strap, Color(0.12, 0.13, 0.17, 0.92), true)
		canvas.draw_rect(strap, Color(0.54, 0.60, 0.72, 0.40), false, 1.0)
		canvas.draw_circle(Vector2(sx, -h + 6.0), 1.9, Color(0.76, 0.82, 0.92, 0.62))
		canvas.draw_circle(Vector2(sx, h - 6.0), 1.9, Color(0.76, 0.82, 0.92, 0.62))

	# Outer beveled border
	var loop := PackedVector2Array(local_pts)
	loop.append(local_pts[0])
	canvas.draw_polyline(loop, wood_rim, 1.8, true)

	# Painted typography rotating naturally with the plank
	if font:
		var txt := "← QAYT" if triggered else "OLDINGA →"
		var tx := -38.0 if triggered else -48.0
		var ty := 6.0
		canvas.draw_string(font, Vector2(tx + 1.5, ty + 1.5), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.02, 0.01, 0.02, 0.85))
		var tcol := Color(1.0, 0.38, 0.46, 0.96) if triggered else Color(0.86, 0.90, 0.98, 0.76)
		canvas.draw_string(font, Vector2(tx, ty), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, tcol)

	# Reset transform so dripping crimson streaks fall straight down with gravity from the rotated bottom edge!
	canvas.draw_set_transform(Vector2.ZERO, 0.0)
	if triggered:
		for d_i in range(4):
			var lx := -38.0 + float(d_i) * 24.0
			var anchor := center + Vector2(lx * cs - h * sn, lx * sn + h * cs)
			var dlen := 10.0 + fmod(timer * 14.0 + float(d_i) * 9.0, 18.0)
			canvas.draw_line(anchor + Vector2(0.0, -1.0), anchor + Vector2(0.0, dlen), Color(0.92, 0.16, 0.28, 0.68), 1.9, true)
			canvas.draw_circle(anchor + Vector2(0.0, dlen), 1.8, Color(0.98, 0.24, 0.34, 0.78))

# =========================================================================
# 6. SHADOW DOPPELGANGER & MIRROR SPIRIT (Levels 6 & 9)
# =========================================================================

static func draw_shadow_doppelganger(canvas: CanvasItem, pos: Vector2, dir_x: float, alpha: float, dissolve: float, timer: float, is_mirror_ghost: bool = false) -> void:
	if alpha <= 0.02:
		return
	var breath := sin(timer * 3.1) * 0.035
	var w := 28.0 * (1.0 - breath * 0.5)
	var h := 32.0 * (1.0 + breath)
	var hover := -sin(timer * 2.6) * 2.2

	# Atmospheric eerie rim glow matching player_visual.gd proportions
	var glow_col := Color(0.68, 0.88, 1.0, alpha * 0.14) if is_mirror_ghost else Color(0.75, 0.32, 0.45, alpha * 0.14)
	var center := Vector2(pos.x, pos.y + hover - h * 0.52)
	canvas.draw_circle(center, 27.0, glow_col)
	canvas.draw_circle(center, 18.0, Color(glow_col.r, glow_col.g, glow_col.b, glow_col.a * 1.4))

	# Flowing tattered shadow cloak wisps curling from the base
	var wisp_col := Color(0.74, 0.90, 1.0, alpha * 0.36) if is_mirror_ghost else Color(0.07, 0.06, 0.11, alpha * 0.78)
	for wi in range(5):
		var wx := pos.x - 10.0 + float(wi) * 5.0
		var sway := sin(timer * 4.5 + float(wi) * 1.3) * 4.5
		var tail_len := 7.0 + float(wi % 2) * 4.0 + dissolve * 12.0
		var wpts := PackedVector2Array([
			Vector2(wx - 2.6, pos.y + hover - 4.0),
			Vector2(wx + sway, pos.y + hover + tail_len),
			Vector2(wx + 2.6, pos.y + hover - 4.0),
		])
		canvas.draw_colored_polygon(wpts, wisp_col)

	# Rounded Limbo hero body silhouette with spectral rim outline
	var body_rect := Rect2(pos.x - w * 0.5, pos.y + hover - h, w, h)
	var fill := Color(0.74, 0.88, 1.0, alpha * 0.36) if is_mirror_ghost else Color(0.08, 0.07, 0.12, alpha * 0.92)
	var rim := Color(0.86, 0.95, 1.0, alpha * 0.82) if is_mirror_ghost else Color(0.84, 0.88, 1.0, alpha * 0.62)
	draw_rounded_box(canvas, body_rect, 5.0, fill, rim, 1.7)

	# Subtle top sheen bevel
	canvas.draw_line(
		Vector2(body_rect.position.x + 5.0, body_rect.position.y + 2.2),
		Vector2(body_rect.end.x - 5.0, body_rect.position.y + 2.2),
		Color(1.0, 1.0, 1.0, alpha * 0.30), 1.2, true
	)

	# Expressive glowing Limbo eyes watching the player
	var eye_y := pos.y + hover - h * 0.54
	var look := clampf(dir_x, -1.0, 1.0) * 2.2
	var le := Vector2(pos.x - 5.8, eye_y)
	var re := Vector2(pos.x + 5.8, eye_y)
	var eye_halo := Color(0.80, 0.95, 1.0, alpha * 0.24) if is_mirror_ghost else Color(1.0, 0.42, 0.52, alpha * 0.26)
	canvas.draw_circle(le, 6.8, eye_halo)
	canvas.draw_circle(re, 6.8, eye_halo)
	var sclera := Color(0.95, 0.98, 1.0, alpha * 0.95)
	draw_ellipse_filled(canvas, le, Vector2(4.0, 5.0), sclera)
	draw_ellipse_filled(canvas, re, Vector2(4.0, 5.0), sclera)
	var pupil_col := Color(0.04, 0.04, 0.08, alpha * 0.95)
	canvas.draw_circle(le + Vector2(look, 0.2), 1.9, pupil_col)
	canvas.draw_circle(re + Vector2(look, 0.2), 1.9, pupil_col)
	canvas.draw_circle(le + Vector2(look - 0.6, -0.6), 0.7, Color(1.0, 1.0, 1.0, alpha))
	canvas.draw_circle(re + Vector2(look - 0.6, -0.6), 0.7, Color(1.0, 1.0, 1.0, alpha))

	# Dissolving ash embers & swirling smoke motes when fading away
	if dissolve > 0.02:
		for ei in range(10):
			var seed_f := float(ei) * 1.91
			var ex := pos.x + sin(seed_f * 3.1 + timer * 2.2) * (12.0 + dissolve * 26.0)
			var ey := pos.y - 8.0 - float(ei) * 3.0 - dissolve * (24.0 + fmod(seed_f * 13.0, 32.0))
			var er := lerpf(2.4, 0.8, dissolve)
			var ea := (1.0 - dissolve) * 0.75
			canvas.draw_circle(Vector2(ex, ey), er, Color(0.82, 0.88, 1.0, ea))

# =========================================================================
# 7. BLACKOUT SWAP HANGING LANTERN (Level 7)
# =========================================================================

static func draw_blackout_lantern(canvas: CanvasItem, pivot: Vector2, timer: float, triggered: bool, blackout_alpha: float) -> void:
	var sway := sin(timer * (4.2 if triggered else 1.5)) * (0.12 if triggered else 0.04)
	var rod_len := 54.0
	var lamp := pivot + Vector2(sin(sway), cos(sway)) * rod_len
	var perp := Vector2(cos(sway), -sin(sway))
	var dir := Vector2(sin(sway), cos(sway))

	# Soft multi-layered volumetric light cone with smooth vertical GPU alpha fade (zero hard edges!)
	var light_on := clampf(1.0 - blackout_alpha * 1.4, 0.0, 1.0)
	var flicker := 0.88 + 0.12 * sin(timer * 23.0) * cos(timer * 11.0)
	if light_on > 0.04:
		var rgb := Color(0.98, 0.82, 0.50) if not triggered else Color(0.54, 0.84, 1.0)
		var cone_layers := [
			[1.18, 355.0, 0.032],
			[0.92, 330.0, 0.042],
			[0.64, 295.0, 0.052],
			[0.36, 250.0, 0.056],
		]
		for cl in cone_layers:
			var w_mult: float = cl[0]
			var beam_len: float = cl[1]
			var base_a: float = cl[2] * light_on * flicker
			var top_col := Color(rgb.r, rgb.g, rgb.b, base_a)
			var bot_col := Color(rgb.r, rgb.g, rgb.b, 0.0)
			var cone_pts := PackedVector2Array([
				lamp - perp * (10.5 * w_mult) + dir * 9.0,
				lamp + perp * (10.5 * w_mult) + dir * 9.0,
				lamp + perp * (138.0 * w_mult) + dir * beam_len,
				lamp - perp * (138.0 * w_mult) + dir * beam_len,
			])
			canvas.draw_polygon(cone_pts, PackedColorArray([top_col, top_col, bot_col, bot_col]))

		# Subtle illuminated dust motes drifting lazily inside the lantern beam
		for mi in range(7):
			var mp := fmod(timer * (0.14 + float(mi % 3) * 0.05) + float(mi) * 0.19, 1.0)
			var md := 38.0 + mp * 195.0
			var mx := sin(timer * 1.4 + float(mi) * 2.3) * (14.0 + mp * 48.0)
			var mpos := lamp + dir * md + perp * mx
			var ma := sin(mp * PI) * 0.34 * light_on * flicker
			canvas.draw_circle(mpos, 1.3, Color(rgb.r, rgb.g, rgb.b, ma))

	# Interlocking forged-iron suspension chain + ornate bail ring
	draw_iron_chain(canvas, pivot, lamp - dir * 18.0, 9.5)
	canvas.draw_circle(pivot + Vector2(0.0, 3.0), 4.4, Color(0.16, 0.17, 0.22, 0.94))
	canvas.draw_arc(lamp - dir * 16.0, 3.8, 0.0, TAU, 12, Color(0.45, 0.50, 0.60, 0.72), 1.4, true)

	# Domed wrought-iron lantern hood
	var hood := PackedVector2Array([
		lamp - dir * 14.0 - perp * 5.0,
		lamp - dir * 14.0 + perp * 5.0,
		lamp - dir * 6.0 + perp * 14.0,
		lamp - dir * 6.0 - perp * 14.0,
	])
	canvas.draw_colored_polygon(hood, Color(0.12, 0.13, 0.17, 0.95))
	canvas.draw_line(lamp - dir * 6.0 - perp * 14.0, lamp - dir * 6.0 + perp * 14.0, Color(0.55, 0.60, 0.72, 0.50), 1.4, true)

	# Glass housing & iron cage bars
	var glass_pts := PackedVector2Array([
		lamp - dir * 6.0 - perp * 10.0,
		lamp - dir * 6.0 + perp * 10.0,
		lamp + dir * 14.0 + perp * 7.5,
		lamp + dir * 14.0 - perp * 7.5,
	])
	var glass_col := Color(0.98, 0.85, 0.56, 0.34 * light_on) if not triggered else Color(0.60, 0.88, 1.0, 0.38 * light_on)
	canvas.draw_colored_polygon(glass_pts, glass_col)
	# Vertical protective bars
	for bx in [-9.0, -3.5, 3.5, 9.0]:
		canvas.draw_line(lamp - dir * 6.0 + perp * bx, lamp + dir * 14.0 + perp * (bx * 0.75), Color(0.14, 0.15, 0.20, 0.92), 1.5, true)
	# Bottom brass base cap
	canvas.draw_line(lamp + dir * 14.0 - perp * 8.5, lamp + dir * 14.0 + perp * 8.5, Color(0.24, 0.26, 0.34, 0.92), 3.0, true)

	# Glowing tungsten / spectral filament & aura
	if light_on > 0.05:
		var fil_col := Color(1.0, 0.92, 0.70, 0.92 * light_on) if not triggered else Color(0.76, 0.95, 1.0, 0.95 * light_on)
		canvas.draw_circle(lamp + dir * 3.0, 16.0, Color(fil_col.r, fil_col.g, fil_col.b, 0.16 * light_on * flicker))
		canvas.draw_circle(lamp + dir * 3.0, 4.2, fil_col)
		canvas.draw_circle(lamp + dir * 3.0, 2.0, Color(1.0, 1.0, 1.0, light_on))

	# Electric sparks bursting out right during blackout swap!
	if blackout_alpha > 0.12:
		for si in range(7):
			var sa := float(si) * 0.9 + timer * 12.0
			var slen := 10.0 + fmod(float(si) * 7.3, 18.0) * blackout_alpha
			var sp0 := lamp + dir * 4.0
			var sp1 := sp0 + Vector2(cos(sa), sin(sa)) * slen
			canvas.draw_line(sp0, sp1, Color(1.0, 0.88, 0.55, blackout_alpha * 0.9), 1.6, true)

# =========================================================================
# 8. HAUNTED GUST (Level 8) — Curved Wind Ribbons & Tumbling Silhouette Leaves
# =========================================================================

static func draw_haunted_gust(canvas: CanvasItem, timer: float, wind_active: bool) -> void:
	var spd := 440.0 if wind_active else 95.0
	var base_a := 0.36 if wind_active else 0.13

	# Soft vertically-feathered chilling air sheen across upper wind zone (no hard box seam!)
	if wind_active:
		var g_top := Color(0.68, 0.84, 1.0, 0.045)
		var g_mid := Color(0.68, 0.84, 1.0, 0.060)
		var g_zero := Color(0.68, 0.84, 1.0, 0.0)
		canvas.draw_polygon(
			PackedVector2Array([Vector2(32.0, 70.0), Vector2(928.0, 70.0), Vector2(928.0, 210.0), Vector2(32.0, 210.0)]),
			PackedColorArray([g_top, g_top, g_mid, g_mid])
		)
		canvas.draw_polygon(
			PackedVector2Array([Vector2(32.0, 210.0), Vector2(928.0, 210.0), Vector2(928.0, 298.0), Vector2(32.0, 298.0)]),
			PackedColorArray([g_mid, g_mid, g_zero, g_zero])
		)

	# Graceful sinusoidal wind-current ribbons confined cleanly inside the chamber (x in 36..924)
	for i in range(9):
		var head_x := 916.0 - fmod(timer * spd + float(i) * 112.0, 880.0)
		var base_y := 96.0 + float(i) * 21.5 + sin(timer * 1.8 + float(i)) * 6.0
		var rib_len := 102.0 if wind_active else 46.0
		var pts := PackedVector2Array()
		var segs := 12
		for s in range(segs + 1):
			var u := float(s) / float(segs)
			var x := clampf(head_x + u * rib_len, 36.0, 924.0)
			var wave := sin(u * PI * 2.0 + timer * 6.0 + float(i) * 1.1) * (5.5 if wind_active else 2.2)
			var curl_y := -sin(maxf(0.0, u - 0.72) * PI * 3.2) * (7.5 if wind_active else 2.0)
			pts.append(Vector2(x, base_y + wave + curl_y))
		var edge_fade := clampf(minf((head_x - 36.0) / 55.0, (924.0 - head_x) / 55.0), 0.0, 1.0)
		var ra := base_a * edge_fade
		if ra > 0.01:
			canvas.draw_polyline(pts, Color(0.78, 0.90, 1.0, ra * 0.45), 3.6, true)
			canvas.draw_polyline(pts, Color(0.92, 0.97, 1.0, ra), 1.4, true)

	# Tumbling silhouette leaves / frost petals spinning leftward inside chamber
	for li in range(8):
		var lx := 916.0 - fmod(timer * (spd * 0.88 + float(li % 3) * 35.0) + float(li) * 124.0, 876.0)
		var ly := 102.0 + float(li) * 22.0 + sin(timer * 4.2 + float(li) * 1.9) * 14.0
		var rot := timer * (7.5 if wind_active else 2.4) + float(li) * 1.3
		var cr := cos(rot)
		var sr := sin(rot)
		var leaf_local := [
			Vector2(-6.5, 0.0),
			Vector2(-1.5, -3.2),
			Vector2(5.5, -1.6),
			Vector2(7.0, 0.0),
			Vector2(5.5, 1.6),
			Vector2(-1.5, 3.2),
		]
		var lpts := PackedVector2Array()
		for lp in leaf_local:
			lpts.append(Vector2(lx + lp.x * cr - lp.y * sr, ly + lp.x * sr + lp.y * cr))
		var lfade := clampf(minf((lx - 38.0) / 36.0, (922.0 - lx) / 36.0), 0.0, 1.0)
		var la := (0.62 if wind_active else 0.30) * lfade
		if la > 0.02:
			canvas.draw_colored_polygon(lpts, Color(0.14, 0.16, 0.24, la))
			canvas.draw_line(
				Vector2(lx - 6.0 * cr, ly - 6.0 * sr),
				Vector2(lx + 6.0 * cr, ly + 6.0 * sr),
				Color(0.82, 0.92, 1.0, la * 0.65), 0.9, true
			)

# =========================================================================
# 9. MIRROR GHOST BRIDGE (Level 9) — Ancient Runic Floating Stone Slabs
# =========================================================================

static func draw_mirror_ghost_bridge(canvas: CanvasItem, stones: Array[Dictionary], _ghost_pos: Vector2, _ghost_trail: Array[Vector2], timer: float) -> void:
	for idx in range(stones.size()):
		var s: Dictionary = stones[idx]
		var p: Vector2 = s["pos"]
		var sz: Vector2 = s["size"]
		var glow := float(s["glow"])
		# Completely invisible until the player actually discovers/steps on the stone
		if glow <= 0.01:
			continue
		var hover := sin(timer * 2.2 + float(idx) * 1.8) * 1.2
		var sp := p + Vector2(0.0, hover)

		# Soft multi-ring feathered ethereal aura when illuminated by player's step
		var g_center := sp + Vector2(sz.x * 0.5, sz.y * 0.5)
		for ring in range(4):
			var sc := 0.52 + float(ring) * 0.22
			var ga := glow * 0.068 * (1.0 - float(ring) * 0.20)
			draw_ellipse_filled(canvas, g_center, Vector2(sz.x * 0.72 * sc, sz.y * 1.45 * sc), Color(0.52, 0.84, 1.0, ga))

		# Jagged ancient carved stone underside silhouette
		var stone_pts := PackedVector2Array([
			sp + Vector2(2.0, 0.0),
			sp + Vector2(sz.x - 2.0, 0.0),
			sp + Vector2(sz.x, 4.0),
			sp + Vector2(sz.x - 4.0, sz.y),
			sp + Vector2(sz.x * 0.72, sz.y + 4.5),
			sp + Vector2(sz.x * 0.50, sz.y + 1.5),
			sp + Vector2(sz.x * 0.26, sz.y + 5.0),
			sp + Vector2(5.0, sz.y),
			sp + Vector2(0.0, 4.0),
		])
		var body_a := clampf(glow * 0.88, 0.0, 0.90)
		canvas.draw_colored_polygon(stone_pts, Color(0.14, 0.19, 0.28, body_a))
		# Chiseled top bevel highlight
		canvas.draw_rect(Rect2(sp.x + 2.0, sp.y, sz.x - 4.0, 3.5), Color(0.74, 0.92, 1.0, glow * 0.92), true)
		var loop := PackedVector2Array(stone_pts)
		loop.append(stone_pts[0])
		canvas.draw_polyline(loop, Color(0.68, 0.88, 1.0, glow * 0.85), 1.3, true)

		# Carved glowing arcane rune glyphs along the slab face
		var rune_col := Color(0.84, 0.96, 1.0, glow * 0.95)
		var rx_mid := sp.x + sz.x * 0.5
		var ry_mid := sp.y + sz.y * 0.55
		canvas.draw_polyline(PackedVector2Array([
			Vector2(rx_mid, ry_mid - 4.0), Vector2(rx_mid + 4.5, ry_mid),
			Vector2(rx_mid, ry_mid + 4.0), Vector2(rx_mid - 4.5, ry_mid), Vector2(rx_mid, ry_mid - 4.0)
		]), rune_col, 1.2, true)
		for side_v in [-1.0, 1.0]:
			var side: float = float(side_v)
			var gx: float = rx_mid + side * 18.0
			canvas.draw_line(Vector2(gx, ry_mid - 3.5), Vector2(gx, ry_mid + 3.5), rune_col, 1.1, true)
			canvas.draw_line(Vector2(gx, ry_mid - 2.0), Vector2(gx + side * 4.0, ry_mid + 1.5), rune_col, 1.1, true)

# =========================================================================
# 10. ATTIC KNOCK (Level 10) — Subtle Muffled Ceiling Dust Tremor (No Cracks/Handprint)
# =========================================================================

static func draw_attic_knock(canvas: CanvasItem, _pos: Vector2, knock_ring: float, _timer: float) -> void:
	# Purely atmospheric faint dust falling from the upper attic rafters during a muffled knock;
	# zero cracks, zero handprint, zero rings pointing directly at the hidden wall.
	if knock_ring <= 0.01:
		return
	var fall_t := 1.0 - knock_ring
	for di in range(4):
		var dx := 260.0 + float(di) * 145.0 + sin(float(di) * 2.5) * 18.0
		var dy := 54.0 + fall_t * fall_t * (38.0 + float(di % 2) * 16.0)
		canvas.draw_circle(Vector2(dx, dy), 1.3, Color(0.68, 0.72, 0.80, knock_ring * 0.28))

# =========================================================================
# 11. LOW GRAVITY DRIFT (Level 11) — Levitating Faceted Crystals & Shards
# =========================================================================

static func draw_low_gravity_drift(canvas: CanvasItem, timer: float, triggered: bool) -> void:
	var spd := 72.0 if triggered else 24.0
	# Ascending luminous etheric gravity-wave arcs when active
	if triggered:
		for wi in range(3):
			var wy := 440.0 - fmod(timer * 68.0 + float(wi) * 140.0, 400.0)
			var wa := sin(clampf((440.0 - wy) / 400.0, 0.0, 1.0) * PI) * 0.22
			var pts := PackedVector2Array()
			for xi in range(17):
				var x := 50.0 + float(xi) * 54.0
				pts.append(Vector2(x, wy + sin(float(xi) * 0.65 + timer * 3.0) * 6.0))
			canvas.draw_polyline(pts, Color(0.72, 0.66, 1.0, wa), 1.6, true)

	# Faceted levitating stone fragments & floating crystal shards
	for i in range(14):
		var px := fmod(72.0 + float(i) * 63.0 + sin(timer * 0.8 + float(i)) * 14.0, 860.0) + 40.0
		var py := 430.0 - fmod(timer * (spd + float(i % 4) * 11.0) + float(i) * 41.0, 370.0)
		var rot := timer * (0.9 + float(i % 3) * 0.4) * (1.0 if i % 2 == 0 else -1.0) + float(i)
		var sc := 3.5 + float(i % 4) * 1.4
		var cr := cos(rot)
		var sr := sin(rot)
		var a := 0.56 if triggered else 0.26

		# Soft amethyst aura halo
		canvas.draw_circle(Vector2(px, py), sc * 2.2, Color(0.68, 0.58, 1.0, a * 0.22))

		# Faceted crystal diamond/shard polygon (lit facet + shaded facet)
		var top := Vector2(px + (0.0 * cr - (-sc * 1.4) * sr), py + (0.0 * sr + (-sc * 1.4) * cr))
		var right := Vector2(px + (sc * 0.78 * cr - 0.0 * sr), py + (sc * 0.78 * sr + 0.0 * cr))
		var bot := Vector2(px + (0.0 * cr - (sc * 1.1) * sr), py + (0.0 * sr + (sc * 1.1) * cr))
		var left := Vector2(px + (-sc * 0.78 * cr - 0.0 * sr), py + (-sc * 0.78 * sr + 0.0 * cr))
		canvas.draw_colored_polygon(PackedVector2Array([top, right, bot]), Color(0.56, 0.50, 0.88, a))
		canvas.draw_colored_polygon(PackedVector2Array([top, bot, left]), Color(0.84, 0.80, 1.0, a * 1.15))
		canvas.draw_line(top, bot, Color(1.0, 0.98, 1.0, a * 0.65), 0.9, true)

# =========================================================================
# 12. FAKE WIN GLITCH (Level 12) — Identical ExitDoor + CRT Glitch Shatter
# =========================================================================

static func draw_fake_win_door(canvas: CanvasItem, timer: float, phase: int, chapter: int) -> void:
	var w := 44.0
	var h := 58.0
	var hw := w * 0.5
	var post_w := 5.0
	var lintel_h := 5.5
	var col := Color(1.0, 1.0, 1.0, 1.0)
	if chapter == 2: col = Color(0.85, 0.95, 1.0, 1.0)
	elif chapter == 3: col = Color(0.75, 1.0, 0.85, 1.0)
	elif chapter == 4: col = Color(1.0, 0.9, 0.7, 1.0)
	elif chapter == 5: col = Color(1.0, 0.7, 0.7, 1.0)

	var glitch_x := 0.0
	if phase == 2:
		glitch_x = sin(timer * 95.0) * 8.0
		# Chromatic RGB ghost echoes tearing off the fake door!
		canvas.draw_rect(Rect2(-hw + glitch_x - 7.0, -h, w, h), Color(1.0, 0.14, 0.32, 0.42), true)
		canvas.draw_rect(Rect2(-hw - glitch_x + 7.0, -h, w, h), Color(0.14, 0.92, 1.0, 0.42), true)

	# Inner dark portal cavity
	canvas.draw_rect(Rect2(-hw + post_w + glitch_x * 0.3, -h + lintel_h, w - post_w * 2.0, h - lintel_h), Color("#000000"), true)
	# Left & right frame posts
	canvas.draw_rect(Rect2(-hw + glitch_x * 0.2, -h + lintel_h, post_w, h - lintel_h), col, true)
	canvas.draw_rect(Rect2(hw - post_w - glitch_x * 0.2, -h + lintel_h, post_w, h - lintel_h), col, true)
	# Authentic inner corner chamfers matching ExitDoor._draw()
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-hw + post_w, -h + lintel_h),
		Vector2(-hw + post_w + 4.0, -h + lintel_h),
		Vector2(-hw + post_w, -h + lintel_h + 4.0),
	]), col)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(hw - post_w, -h + lintel_h),
		Vector2(hw - post_w - 4.0, -h + lintel_h),
		Vector2(hw - post_w, -h + lintel_h + 4.0),
	]), col)
	# Lintel + cornice overhang + threshold line
	canvas.draw_rect(Rect2(-hw, -h, w, lintel_h), col, true)
	canvas.draw_rect(Rect2(-hw - 2.0, -h, w + 4.0, 2.5), col, true)
	canvas.draw_line(Vector2(-hw - 2.0, 0.0), Vector2(hw + 2.0, 0.0), col, 2.0)

	# Floating bobbing indicator triangle (▼)
	if phase == 0:
		var tri_y := -(h + 8.0) + sin(timer * 3.5) * 2.5
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(-6.0, tri_y), Vector2(6.0, tri_y), Vector2(0.0, tri_y + 8.0)
		]), col)
	elif phase == 2:
		# Jagged static tear lines slicing through the fake door
		for si in range(5):
			var sy := -h + float(si) * 12.0 + fmod(timer * 120.0, 10.0)
			var sx := sin(timer * 70.0 + float(si) * 2.1) * 14.0
			canvas.draw_rect(Rect2(-hw + sx, sy, w, 3.0), Color(1.0, 0.25, 0.42, 0.85), true)

static func draw_fake_win_glitch_fg(canvas: CanvasItem, phase: int, timer: float, font: Font) -> void:
	if phase == 1 and font:
		# Ceremonial polished victory banner (lulls the player!)
		var box := Rect2(246.0, 92.0, 468.0, 66.0)
		draw_rounded_box(canvas, Rect2(box.position + Vector2(0.0, 5.0), box.size), 8.0, Color(0.0, 0.0, 0.0, 0.45))
		draw_rounded_box(canvas, box, 8.0, Color(0.05, 0.11, 0.14, 0.92), Color(0.42, 0.95, 0.68, 0.92), 2.2)
		draw_rounded_box(canvas, box.grow(-5.0), 5.0, Color.TRANSPARENT, Color(0.42, 0.95, 0.68, 0.30), 1.0)
		# Crisp glowing check-seal medallion on the left
		var mc := Vector2(288.0, 125.0)
		canvas.draw_circle(mc, 16.0, Color(0.24, 0.82, 0.55, 0.22))
		canvas.draw_arc(mc, 14.0, 0.0, TAU, 24, Color(0.55, 1.0, 0.76, 0.95), 2.0, true)
		canvas.draw_polyline(PackedVector2Array([
			mc + Vector2(-6.0, 0.5), mc + Vector2(-1.5, 5.5), mc + Vector2(7.0, -5.0)
		]), Color(0.75, 1.0, 0.86, 1.0), 2.6, true)
		canvas.draw_string(font, Vector2(322.0, 133.0), "DARAJA YAKUNLANDI!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.76, 1.0, 0.86))
	elif phase == 2:
		# Authentic VHS / CRT reality-shatter glitch spanning full overscan (desktop zoom 0.8 + 21:9 mobile)
		var jx := sin(timer * 110.0) * 10.0
		# Subtle dark CRT scanlines across full overscan viewport
		for sy in range(-220, 760, 8):
			canvas.draw_line(Vector2(-380.0, float(sy)), Vector2(1340.0, float(sy)), Color(0.0, 0.0, 0.0, 0.18), 1.0)
		# Chromatic aberration horizontal tear bands spanning full overscan width
		var bands := [
			[128.0, 22.0, Color(1.0, 0.14, 0.30, 0.30)],
			[205.0, 12.0, Color(0.14, 0.94, 1.0, 0.26)],
			[318.0, 32.0, Color(1.0, 0.18, 0.34, 0.24)],
			[390.0, 14.0, Color(0.20, 0.90, 1.0, 0.28)],
		]
		for b in bands:
			var by: float = b[0] + sin(timer * 65.0 + b[0]) * 6.0
			canvas.draw_rect(Rect2(-380.0, by, 1720.0, b[1]), b[2], true)
		# Static snow glitch blocks across overscan
		for bi in range(14):
			var bx := -180.0 + fmod(float(bi) * 113.0 + timer * 530.0, 1240.0)
			var by := -60.0 + fmod(float(bi) * 67.0 + timer * 310.0, 620.0)
			var bw := 24.0 + float(bi % 4) * 18.0
			canvas.draw_rect(Rect2(bx, by, bw, 5.0), Color(0.95, 0.98, 1.0, 0.34), true)
		# Torn corrupted crimson banner
		if font:
			var box := Rect2(280.0 + jx, 92.0, 400.0, 62.0)
			canvas.draw_rect(Rect2(box.position + Vector2(-5.0, 0.0), box.size), Color(0.10, 0.90, 1.0, 0.24), true)
			canvas.draw_rect(Rect2(box.position + Vector2(5.0, 0.0), box.size), Color(1.0, 0.12, 0.26, 0.28), true)
			canvas.draw_rect(box, Color(0.12, 0.02, 0.04, 0.94), true)
			canvas.draw_rect(box, Color(1.0, 0.24, 0.36, 0.95), false, 2.2)
			# Jagged crack splitting the banner
			canvas.draw_polyline(PackedVector2Array([
				box.position + Vector2(120.0, 0.0),
				box.position + Vector2(134.0, 26.0),
				box.position + Vector2(118.0, 44.0),
				box.position + Vector2(128.0, 62.0),
			]), Color(1.0, 0.45, 0.55, 0.85), 2.0, true)
			canvas.draw_string(font, Vector2(396.0 + jx - 2.0, 131.5), "HALI EMAS...", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.20, 0.95, 1.0, 0.55))
			canvas.draw_string(font, Vector2(396.0 + jx + 2.0, 132.5), "HALI EMAS...", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1.0, 0.14, 0.30, 0.65))
			canvas.draw_string(font, Vector2(396.0 + jx, 132.0), "HALI EMAS...", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1.0, 0.86, 0.90, 0.98))

# =========================================================================
# 13. LIGHTNING STORM BOLTS & RAIN (Level 13)
# =========================================================================

static func draw_lightning_storm(canvas: CanvasItem, timer: float, lightning_alpha: float, bolt_seed: int) -> void:
	var flash := clampf((0.88 - lightning_alpha) / 0.82, 0.0, 1.0)
	if flash <= 0.02:
		return

	# Subtle angled storm rain streaks illuminated during thunder flash
	for ri in range(22):
		var rx := fmod(float(ri) * 47.0 + timer * 180.0, 960.0)
		var ry := fmod(float(ri) * 73.0 + timer * 680.0, 460.0) + 48.0
		canvas.draw_line(Vector2(rx, ry), Vector2(rx - 9.0, ry + 26.0), Color(0.75, 0.88, 1.0, flash * 0.24), 1.0, true)

	# Multi-branched sharp fractal jagged lightning bolt streaking across the storm sky
	var start_x := 220.0 + fmod(float(bolt_seed) * 197.0, 520.0)
	# Soft multi-ring atmospheric lightning sky glow radiating from strike origin (no hard oval edge!)
	for gi in range(5):
		var gsc := 0.45 + float(gi) * 0.24
		var ga := flash * 0.042 * (1.0 - float(gi) * 0.16)
		draw_ellipse_filled(canvas, Vector2(start_x, 88.0), Vector2(165.0 * gsc, 82.0 * gsc), Color(0.68, 0.84, 1.0, ga))
	var cur := Vector2(start_x, 48.0)
	var main_pts := PackedVector2Array([cur])
	var branches: Array[PackedVector2Array] = []
	for step in range(15):
		var h1 := sin(float(bolt_seed * 37 + step * 19) * 12.9898) * 43758.5453
		var rnd: float = h1 - floorf(h1)
		var zig: float = (rnd - 0.5) * 58.0
		var dy := 24.0 + fmod(float(step * 13 + bolt_seed * 7), 11.0)
		var nxt := cur + Vector2(zig, dy)
		main_pts.append(nxt)
		if step == 3 or step == 6 or step == 9 or step == 11:
			var bdir := 1.0 if (step + bolt_seed) % 2 == 0 else -1.0
			var b1 := nxt + Vector2(bdir * (18.0 + rnd * 18.0), 19.0)
			var b2 := b1 + Vector2(bdir * (14.0 + (1.0 - rnd) * 16.0), 26.0)
			var b3 := b2 + Vector2(bdir * 10.0, 22.0)
			branches.append(PackedVector2Array([nxt, b1, b2, b3]))
			if step == 6:
				branches.append(PackedVector2Array([b1, b1 + Vector2(-bdir * 12.0, 22.0)]))
		cur = nxt

	# Layered corona + electric cyan glow + incandescent white core
	canvas.draw_polyline(main_pts, Color(0.50, 0.68, 1.0, flash * 0.22), 14.0, true)
	canvas.draw_polyline(main_pts, Color(0.65, 0.88, 1.0, flash * 0.58), 5.0, true)
	canvas.draw_polyline(main_pts, Color(0.97, 0.99, 1.0, flash * 0.98), 2.0, true)
	for br in branches:
		canvas.draw_polyline(br, Color(0.55, 0.80, 1.0, flash * 0.34), 3.6, true)
		canvas.draw_polyline(br, Color(0.95, 0.98, 1.0, flash * 0.78), 1.2, true)

# =========================================================================
# 14. SCREEN WRAP POST-CROSSING SHIMMER (Level 14)
# =========================================================================

static func draw_screen_wrap_shimmer(canvas: CanvasItem, wall_x: float, center_y: float, strength: float) -> void:
	if strength <= 0.01:
		return
	var prog := 1.0 - clampf(strength, 0.0, 1.0)
	var inward := -1.0 if wall_x > 480.0 else 1.0
	var pc := Vector2(wall_x + inward * (2.0 + prog * 14.0), center_y)
	var hh := 28.0 + prog * 22.0
	var a := strength * strength
	# Brief spectral ripple only visible right after emerging from the wall
	draw_ellipse_filled(canvas, pc, Vector2(5.0 + prog * 10.0, hh), Color(0.72, 0.90, 1.0, 0.22 * a))
	canvas.draw_line(Vector2(wall_x + inward * 1.5, center_y - hh * 0.85), Vector2(wall_x + inward * 1.5, center_y + hh * 0.85), Color(0.90, 0.97, 1.0, 0.55 * a), 2.2, true)
	canvas.draw_arc(Vector2(wall_x, center_y), 10.0 + prog * 34.0, -PI * 0.45 if inward > 0.0 else PI * 0.55, PI * 0.45 if inward > 0.0 else PI * 1.45, 16, Color(0.80, 0.94, 1.0, 0.48 * a), 1.6, true)

static func draw_screen_wrap_portals(_canvas: CanvasItem, _y_min: float, _y_max: float, _timer: float) -> void:
	# Intentionally empty: wall portal is completely invisible before crossing
	pass

# =========================================================================
# 15. ROOM TILT VERTIGO CHANDELIER (Level 15)
# =========================================================================

static func get_chandelier_swing(cam_tilt: float, timer: float) -> float:
	return -cam_tilt * 0.72 + sin(timer * 1.7) * 0.02

static func get_chandelier_hub(pivot: Vector2, cam_tilt: float, timer: float) -> Vector2:
	var swing := get_chandelier_swing(cam_tilt, timer)
	return pivot + Vector2(sin(swing), cos(swing)) * 122.0

static func draw_vertigo_chandelier(canvas: CanvasItem, pivot: Vector2, cam_tilt: float, timer: float, triggered: bool) -> void:
	# Physically weighted antique iron chandelier counter-swaying against the tilted room
	var swing := get_chandelier_swing(cam_tilt, timer)
	var chain_len := 122.0
	var dir := Vector2(sin(swing), cos(swing))
	var perp := Vector2(cos(swing), -sin(swing))
	var hub := pivot + dir * chain_len

	var iron := Color(0.14, 0.15, 0.20, 0.88)
	var iron_hi := Color(0.52, 0.56, 0.66, 0.46)

	# Linked interlocking forged-iron ceiling chain
	draw_iron_chain(canvas, pivot, hub - dir * 13.0, 10.0)
	# Central ornate wrought-iron spindle & finial
	canvas.draw_line(hub - dir * 14.0, hub + dir * 24.0, iron, 3.5, true)
	canvas.draw_circle(hub, 5.5, iron)
	canvas.draw_circle(hub + dir * 24.0, 3.2, iron_hi)

	# Scrolled S-curve iron arms + 3 wax candles with flickering flames
	var candle_spots := [
		hub - perp * 50.0 + dir * 4.0,
		hub + dir * 2.0,
		hub + perp * 50.0 + dir * 4.0,
	]
	# Subtle forged-iron horizontal crossbar supporting the candle arms
	canvas.draw_line(candle_spots[0] + dir * 4.0, candle_spots[2] + dir * 4.0, iron, 3.2, true)
	canvas.draw_line(candle_spots[0] + dir * 3.0, candle_spots[2] + dir * 3.0, iron_hi, 1.0, true)
	draw_quad_bezier(canvas, hub + dir * 12.0, hub - perp * 28.0 + dir * 22.0, candle_spots[0] + dir * 6.0, iron, 2.4)
	draw_quad_bezier(canvas, hub + dir * 12.0, hub + perp * 28.0 + dir * 22.0, candle_spots[2] + dir * 6.0, iron, 2.4)
	draw_quad_bezier(canvas, hub + dir * 11.0, hub - perp * 28.0 + dir * 21.0, candle_spots[0] + dir * 5.0, iron_hi, 0.8)
	draw_quad_bezier(canvas, hub + dir * 11.0, hub + perp * 28.0 + dir * 21.0, candle_spots[2] + dir * 5.0, iron_hi, 0.8)

	for idx in range(candle_spots.size()):
		var cp: Vector2 = candle_spots[idx]
		# Wax drip saucer
		canvas.draw_line(cp - perp * 7.5 + dir * 5.0, cp + perp * 7.5 + dir * 5.0, iron, 2.6, true)
		# Wax candle body
		var wax_top := cp - dir * 12.0
		canvas.draw_line(cp + dir * 4.0, wax_top, Color(0.84, 0.80, 0.72, 0.82), 5.0, true)
		# Tiny flickering flame (leans gently with gravity!)
		var fl := 0.85 + 0.15 * sin(timer * 15.0 + float(idx) * 2.1)
		var flame_base := wax_top - dir * 2.0
		var flame_tip := flame_base + Vector2(sin(timer * 9.0 + float(idx)) * 1.4, -9.5 * fl)
		canvas.draw_circle(flame_base + Vector2(0.0, -4.0), 14.0, Color(1.0, 0.72, 0.32, 0.08 * fl))
		canvas.draw_colored_polygon(PackedVector2Array([
			flame_base + Vector2(-2.6, 0.0),
			flame_tip,
			flame_base + Vector2(2.6, 0.0),
		]), Color(1.0, 0.68, 0.24, 0.88))
		canvas.draw_circle(flame_base + Vector2(0.0, -2.5), 1.6, Color(1.0, 0.98, 0.86, 0.95))

	# Subtle dizziness edge vignette arcs in triggered state
	if triggered:
		var pulse := 0.5 + 0.5 * sin(timer * 1.9)
		canvas.draw_arc(hub, 72.0, 0.0, TAU, 36, Color(0.75, 0.84, 1.0, 0.06 * pulse), 1.5, true)

# =========================================================================
# 16. TIME HEARTBEAT SLOW-MO (Level 16) — Gothic Cathedral Clockwork Face
# =========================================================================

static func _draw_gear(canvas: CanvasItem, center: Vector2, r_outer: float, r_inner: float, teeth: int, rot: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var step := TAU / float(teeth)
	for i in range(teeth):
		var a0 := rot + float(i) * step
		var a1 := a0 + step * 0.22
		var a2 := a0 + step * 0.52
		var a3 := a0 + step * 0.74
		pts.append(center + Vector2(cos(a0), sin(a0)) * r_inner)
		pts.append(center + Vector2(cos(a1), sin(a1)) * r_outer)
		pts.append(center + Vector2(cos(a2), sin(a2)) * r_outer)
		pts.append(center + Vector2(cos(a3), sin(a3)) * r_inner)
	var loop := PackedVector2Array(pts)
	loop.append(pts[0])
	canvas.draw_polyline(loop, col, 1.3, true)
	canvas.draw_arc(center, r_inner * 0.52, 0.0, TAU, 18, col, 1.2, true)
	for s in range(4):
		var sa := rot + float(s) * PI * 0.5
		canvas.draw_line(center + Vector2(cos(sa), sin(sa)) * (r_inner * 0.22), center + Vector2(cos(sa), sin(sa)) * (r_inner * 0.52), col, 1.2, true)

static func draw_cathedral_clockwork(canvas: CanvasItem, center: Vector2, clock_angle: float, slowmo_active: bool) -> void:
	var R := 118.0
	var tint := Color(0.58, 0.84, 1.0, 0.34) if slowmo_active else Color(0.76, 0.72, 0.62, 0.22)
	var hi := Color(0.78, 0.94, 1.0, 0.52) if slowmo_active else Color(0.88, 0.84, 0.74, 0.30)

	# Dark translucent clock dial face
	canvas.draw_circle(center, R, Color(0.05, 0.06, 0.10, 0.34 if slowmo_active else 0.24))

	# 3 interlocking antique clockwork gears slowly turning behind the dial
	_draw_gear(canvas, center + Vector2(-42.0, 26.0), 34.0, 28.0, 12, clock_angle * 0.8, Color(tint.r, tint.g, tint.b, tint.a * 0.75))
	_draw_gear(canvas, center + Vector2(36.0, -24.0), 42.0, 35.0, 14, -clock_angle * 0.65, Color(tint.r, tint.g, tint.b, tint.a * 0.75))
	_draw_gear(canvas, center + Vector2(12.0, 44.0), 24.0, 19.0, 10, clock_angle * 1.15, Color(tint.r, tint.g, tint.b, tint.a * 0.65))

	# Ornate double bezel & chapter ring
	canvas.draw_arc(center, R, 0.0, TAU, 56, hi, 2.2, true)
	canvas.draw_arc(center, R - 8.0, 0.0, TAU, 56, tint, 1.2, true)
	canvas.draw_arc(center, R - 26.0, 0.0, TAU, 48, Color(tint.r, tint.g, tint.b, tint.a * 0.65), 1.0, true)

	# 12 sculpted hour markers + 48 minute ticks
	for i in range(60):
		var a := float(i) * TAU / 60.0 - PI * 0.5
		var d := Vector2(cos(a), sin(a))
		if i % 5 == 0:
			var is_card := (i % 15 == 0)
			var p_out := center + d * (R - 9.0)
			var p_in := center + d * (R - (24.0 if is_card else 19.0))
			canvas.draw_line(p_out, p_in, hi, 2.6 if is_card else 1.7, true)
			if is_card:
				# Diamond filigree ornament at 12, 3, 6, 9
				var perp := Vector2(-d.y, d.x)
				var mid := center + d * (R - 16.5)
				canvas.draw_colored_polygon(PackedVector2Array([
					mid + d * 4.5, mid + perp * 3.2, mid - d * 4.5, mid - perp * 3.2
				]), hi)
		else:
			canvas.draw_line(center + d * (R - 9.0), center + d * (R - 13.0), Color(tint.r, tint.g, tint.b, tint.a * 0.55), 1.0, true)

	# Ornate cathedral spade minute hand & hour hand
	var min_a := clock_angle * 0.55 - PI * 0.5
	var hr_a := clock_angle * 0.08 - PI * 0.2
	var sec_a := clock_angle * 2.4 - PI * 0.5

	for hand_spec in [[hr_a, 62.0, 4.2, hi], [min_a, 92.0, 3.0, hi]]:
		var ha: float = hand_spec[0]
		var hl: float = hand_spec[1]
		var hw: float = hand_spec[2]
		var hcol: Color = hand_spec[3]
		var hd := Vector2(cos(ha), sin(ha))
		var hp := Vector2(-hd.y, hd.x)
		var hpts := PackedVector2Array([
			center - hd * 14.0,
			center + hd * (hl * 0.72) + hp * hw,
			center + hd * hl,
			center + hd * (hl * 0.72) - hp * hw,
		])
		canvas.draw_colored_polygon(hpts, hcol)
		# Ornate open ring near hand tip
		canvas.draw_arc(center + hd * (hl * 0.65), hw * 1.5, 0.0, TAU, 12, hcol, 1.3, true)

	# Slender sweep second hand with crescent counterweight
	var sd := Vector2(cos(sec_a), sin(sec_a))
	canvas.draw_line(center - sd * 20.0, center + sd * (R - 14.0), Color(0.95, 0.42, 0.48, 0.58 if slowmo_active else 0.34), 1.4, true)
	canvas.draw_circle(center, 6.5, hi)
	canvas.draw_circle(center, 3.0, Color(0.08, 0.10, 0.16, 0.90))

static func draw_slowmo_fg(canvas: CanvasItem, center: Vector2, slowmo_active: bool, pulse_r: float) -> void:
	if not slowmo_active:
		return
	# Cool temporal vignette wash covering full overscan + double harmonic heartbeat rings
	canvas.draw_rect(Rect2(-420.0, -280.0, 1800.0, 1100.0), Color(0.10, 0.20, 0.44, 0.16), true)
	var fade := clampf(1.0 - pulse_r / 760.0, 0.0, 1.0)
	canvas.draw_arc(center, pulse_r, 0.0, TAU, 56, Color(0.58, 0.86, 1.0, 0.56 * fade), 3.2, true)
	if pulse_r > 38.0:
		canvas.draw_arc(center, pulse_r - 36.0, 0.0, TAU, 48, Color(0.76, 0.94, 1.0, 0.32 * fade), 1.6, true)

# =========================================================================
# 17. TWIN DOORS TRUTH (Level 17) — Inverted Watery Mirror Reflection
# =========================================================================

static func draw_twin_doors_reflection(canvas: CanvasItem, door_pos: Vector2, timer: float, fx_timer: float, fake_door_pos: Vector2) -> void:
	# Shimmering moonlit water puddle glaze right on the sill of the true door
	var sill_pulse := 0.72 + 0.28 * sin(timer * 3.0)
	draw_ellipse_filled(canvas, door_pos + Vector2(0.0, 1.5), Vector2(30.0, 4.0), Color(0.68, 0.88, 1.0, 0.26 * sill_pulse))
	canvas.draw_line(door_pos + Vector2(-24.0, 1.0), door_pos + Vector2(24.0, 1.0), Color(0.88, 0.96, 1.0, 0.48 * sill_pulse), 1.5, true)

	# Ethereal inverted watery mirror reflection hanging below the 26px island (y = door_pos.y + 26..88)
	var top_y := door_pos.y + 26.0
	var hw := 22.0
	var ref_h := 54.0
	# Rippling sliced horizontal reflection of the real doorway posts, lintel, & inverted triangle
	var slices := 12
	for si in range(slices):
		var u0 := float(si) / float(slices)
		var u1 := float(si + 1) / float(slices)
		var y0 := top_y + u0 * ref_h
		var sh := (u1 - u0) * ref_h
		var ripple_x := sin(timer * 4.2 + float(si) * 0.85) * (1.8 + u0 * 3.5)
		var alpha := (1.0 - u0 * 0.78) * 0.42
		var col := Color(0.72, 0.90, 1.0, alpha)
		# Dark inverted portal cavity
		canvas.draw_rect(Rect2(door_pos.x - hw + 5.0 + ripple_x, y0, (hw - 5.0) * 2.0, sh), Color(0.05, 0.08, 0.16, alpha * 0.65), true)
		# Left & right frame post reflections
		canvas.draw_rect(Rect2(door_pos.x - hw + ripple_x, y0, 5.0, sh), col, true)
		canvas.draw_rect(Rect2(door_pos.x + hw - 5.0 + ripple_x, y0, 5.0, sh), col, true)
		if si == slices - 1:
			# Inverted bottom lintel bar
			canvas.draw_rect(Rect2(door_pos.x - hw - 2.0 + ripple_x, y0, hw * 2.0 + 4.0, 4.5), col, true)

	# Inverted shimmering indicator triangle (▲) beneath reflection
	var tri_y := top_y + ref_h + 12.0 - sin(timer * 3.5) * 2.0
	var tri_rx := sin(timer * 4.2 + 9.0) * 3.0
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(door_pos.x - 6.0 + tri_rx, tri_y),
		Vector2(door_pos.x + 6.0 + tri_rx, tri_y),
		Vector2(door_pos.x + tri_rx, tri_y - 8.0),
	]), Color(0.76, 0.94, 1.0, 0.34 * sill_pulse))

	# Shattering glitch shards around FakeDoorRight when triggered!
	if fx_timer > 0.01 and fake_door_pos != Vector2.ZERO:
		var prog := clampf(1.0 - fx_timer / 0.45, 0.0, 1.0)
		var sa := (1.0 - prog) * 0.90
		for k in range(10):
			var ang := float(k) * TAU / 10.0 + 0.3
			var dist := 16.0 + prog * 68.0
			var sp := fake_door_pos + Vector2(0.0, -28.0) + Vector2(cos(ang), sin(ang)) * dist
			var sz := 6.0 * (1.0 - prog * 0.5)
			canvas.draw_colored_polygon(PackedVector2Array([
				sp + Vector2(0.0, -sz),
				sp + Vector2(sz * 0.8, sz * 0.5),
				sp + Vector2(-sz * 0.7, sz * 0.7),
			]), Color(1.0, 0.28, 0.40, sa))

# =========================================================================
# 18. MIND FLIP MIST SIGILS (Level 18) — Ornate Mirror-Compass Arcane Sigils
# =========================================================================

static func draw_mind_flip_sigils(canvas: CanvasItem, inv_y: float, timer: float) -> void:
	# Undulating billowing mist crest line
	var crest_pts := PackedVector2Array()
	for i in range(46):
		var x := 32.0 + float(i) * (896.0 / 45.0)
		var y := inv_y + sin(x * 0.018 + timer * 1.45) * 6.5 + cos(x * 0.043 - timer * 2.1) * 3.2
		crest_pts.append(Vector2(x, y))
	canvas.draw_polyline(crest_pts, Color(1.0, 0.42, 0.58, 0.52), 2.2, true)
	canvas.draw_polyline(crest_pts, Color(1.0, 0.76, 0.84, 0.28), 5.0, true)

	# 4 drifting ornate inverted-control arcane compass medallions (← ◈ →) floating cleanly inside mist band
	for i in range(4):
		var sx := 64.0 + fmod(float(i) * 224.0 + timer * 26.0, 832.0)
		var sy := inv_y + 28.0 + sin(timer * 1.9 + float(i) * 1.6) * 6.0
		var flip_scale := cos(timer * 1.8 + float(i) * 1.5)
		var c := Vector2(sx, sy)
		var col := Color(1.0, 0.58, 0.68, 0.44)
		var soft := Color(1.0, 0.34, 0.48, 0.20)
		# Delicate etched outer medallion circle
		canvas.draw_arc(c, 18.0, 0.0, TAU, 24, soft, 1.3, true)
		canvas.draw_arc(c, 14.0, timer + float(i), timer + float(i) + PI * 1.3, 18, col, 1.1, true)
		# Ornate double-headed horizontal flip arrow gently rotating in 3D perspective
		var hw := 12.0 * absf(flip_scale) + 4.0
		canvas.draw_line(c + Vector2(-hw, 0.0), c + Vector2(hw, 0.0), col, 1.8, true)
		# Left & right sculpted arrowheads
		canvas.draw_colored_polygon(PackedVector2Array([
			c + Vector2(-hw - 4.0, 0.0), c + Vector2(-hw + 2.0, -4.0), c + Vector2(-hw + 2.0, 4.0)
		]), col)
		canvas.draw_colored_polygon(PackedVector2Array([
			c + Vector2(hw + 4.0, 0.0), c + Vector2(hw - 2.0, -4.0), c + Vector2(hw - 2.0, 4.0)
		]), col)
		# Center arcane diamond
		canvas.draw_colored_polygon(PackedVector2Array([
			c + Vector2(0.0, -3.5), c + Vector2(3.5, 0.0), c + Vector2(0.0, 3.5), c + Vector2(-3.5, 0.0)
		]), Color(1.0, 0.80, 0.86, 0.56))

# =========================================================================
# 19. RISING SHADOW TIDE (Level 19) — Living Abyssal Ink & Reaching Hands
# =========================================================================

static func _draw_reaching_hand(canvas: CanvasItem, base: Vector2, reach: float, sway: float, scale_h: float, col: Color, rim_col: Color) -> void:
	if reach <= 0.06:
		return
	var h := reach * 48.0 * scale_h
	var palm := base + Vector2(sway, -h)

	# Guaranteed non-self-intersecting convex/monotone tapered forearm rising from abyssal ink
	if h >= 6.0:
		var wrist := base + Vector2(sway * 0.45, -h * 0.56)
		var palm_base := base + Vector2(sway * 0.92, -h * 0.88)
		var arm_pts := PackedVector2Array([
			base + Vector2(-9.2 * scale_h, 6.0),
			wrist + Vector2(-4.4 * scale_h, 0.0),
			palm_base + Vector2(-6.0 * scale_h, 0.0),
			palm_base + Vector2(6.0 * scale_h, 0.0),
			wrist + Vector2(4.4 * scale_h, 0.0),
			base + Vector2(9.2 * scale_h, 6.0),
		])
		canvas.draw_colored_polygon(arm_pts, col)
		# Rim highlight along left forearm contour
		canvas.draw_polyline(PackedVector2Array([arm_pts[0], arm_pts[1], arm_pts[2]]), Color(rim_col.r, rim_col.g, rim_col.b, rim_col.a * 0.65), 1.0, true)

	# Contoured shadowy palm with thumb heel pad
	draw_ellipse_filled(canvas, palm, Vector2(6.8 * scale_h, 5.8 * scale_h), col)
	draw_ellipse_filled(canvas, palm + Vector2(-4.2 * scale_h, 2.0 * scale_h), Vector2(3.6 * scale_h, 3.0 * scale_h), col)

	# 5 slender articulated clutching fingers (tapered base-to-tip phalanges)
	var f_specs := [
		[-0.92, 11.5, 0.46, -1.0],
		[-0.42, 17.0, 0.16, -2.5],
		[0.02, 19.2, 0.02, -3.2],
		[0.44, 16.4, -0.16, -2.5],
		[0.84, 12.6, -0.38, -1.2],
	]
	for fs in f_specs:
		var spread: float = fs[0]
		var flen: float = fs[1] * scale_h * (0.58 + 0.42 * reach)
		var curl: float = fs[2]
		var y_off: float = fs[3] * scale_h
		var f0 := palm + Vector2(spread * 6.4 * scale_h, y_off)
		var f1 := f0 + Vector2(spread * flen * 0.50, -flen * 0.56)
		var f2 := f1 + Vector2((spread * 0.30 + curl) * flen * 0.46, -flen * 0.42)
		canvas.draw_line(f0, f1, col, 3.0 * scale_h, true)
		canvas.draw_line(f1, f2, col, 1.9 * scale_h, true)
		canvas.draw_circle(f2, 1.0 * scale_h, col)
		canvas.draw_polyline(PackedVector2Array([f0, f1, f2]), rim_col, 0.85, true)

static func draw_rising_shadow_tide(canvas: CanvasItem, tide_y: float, timer: float) -> void:
	if tide_y >= 539.0:
		return
	var segs := 36
	var x_start := 32.0
	var x_end := 928.0
	var dx := (x_end - x_start) / float(segs)

	# 1. Back dark-violet rolling surge wave
	var back_pts := PackedVector2Array()
	for i in range(segs + 1):
		var x := x_start + float(i) * dx
		var wy := tide_y - 7.0 + sin(timer * 3.1 + float(i) * 0.48) * 6.0 + cos(timer * 2.0 - float(i) * 0.3) * 3.0
		back_pts.append(Vector2(x, wy))
	var back_poly := PackedVector2Array(back_pts)
	back_poly.append(Vector2(x_end, 620.0))
	back_poly.append(Vector2(x_start, 620.0))
	canvas.draw_colored_polygon(back_poly, Color(0.10, 0.03, 0.14, 0.62))

	# 2. Reaching shadowy hands emerging organically from behind the main crest!
	for hi in range(6):
		var hx := 110.0 + float(hi) * 150.0 + sin(timer * 0.9 + float(hi) * 2.1) * 18.0
		var cycle := sin(timer * 1.85 + float(hi) * 1.35)
		var reach := clampf((cycle + 0.25) / 1.25, 0.0, 1.0)
		var sway := sin(timer * 3.2 + float(hi) * 2.4) * 7.0
		var sc := 0.85 + float(hi % 3) * 0.14
		_draw_reaching_hand(
			canvas,
			Vector2(hx, tide_y + 4.0),
			reach,
			sway,
			sc,
			Color(0.03, 0.015, 0.055, 0.92),
			Color(0.80, 0.28, 0.48, 0.42 * reach)
		)

	# 3. Main abyssal ink body with vertical depth gradient
	var front_pts := PackedVector2Array()
	for i in range(segs + 1):
		var x := x_start + float(i) * dx
		var wy := tide_y + sin(timer * 4.8 + float(i) * 0.56) * 5.2 + cos(timer * 3.1 + float(i) * 0.95) * 2.4
		front_pts.append(Vector2(x, wy))
	var main_poly := PackedVector2Array(front_pts)
	main_poly.append(Vector2(x_end, 620.0))
	main_poly.append(Vector2(x_start, 620.0))
	canvas.draw_colored_polygon(main_poly, Color(0.025, 0.012, 0.045, 0.93))

	# Glowing eerie crimson-violet bioluminescent foam ridge along crest
	canvas.draw_polyline(front_pts, Color(0.68, 0.18, 0.38, 0.48), 6.0, true)
	canvas.draw_polyline(front_pts, Color(0.95, 0.44, 0.62, 0.85), 2.0, true)

	# Rising dark ink droplets & crimson embers
	for ei in range(12):
		var ex := 60.0 + float(ei) * 78.0 + sin(timer * 2.4 + float(ei) * 1.7) * 14.0
		var phase := fmod(timer * (0.45 + float(ei % 3) * 0.12) + float(ei) * 0.23, 1.0)
		var ey := tide_y - phase * 48.0
		var ea := sin(phase * PI) * 0.72
		canvas.draw_circle(Vector2(ex, ey), 2.0 * (1.0 - phase * 0.5), Color(0.92, 0.36, 0.54, ea))

# =========================================================================
# 20. REALITY AWAKENING FINALE (Level 20) — Ancient Faceted Obsidian Monolith
# =========================================================================

static func draw_obsidian_monolith(canvas: CanvasItem, center: Vector2, timer: float, cracked: bool, font: Font) -> void:
	var hover := sin(timer * 1.6) * 3.0
	var mc := center + Vector2(0.0, hover)
	var pulse := 0.65 + 0.35 * sin(timer * (4.5 if cracked else 2.2))

	# Soft multi-ring ritual aura behind monolith (smooth gradient, no hard oval rim)
	var aura_rgb := Color(0.95, 0.24, 0.36) if cracked else Color(0.54, 0.72, 1.0)
	for ri in range(5):
		var sc := 0.55 + float(ri) * 0.22
		var ra := (0.048 if cracked else 0.030) * pulse * (1.0 - float(ri) * 0.16)
		draw_ellipse_filled(canvas, mc + Vector2(0.0, -30.0), Vector2(88.0 * sc, 138.0 * sc), Color(aura_rgb.r, aura_rgb.g, aura_rgb.b, ra))

	# Stepped carved stone ritual plinth at bottom
	var plinth_y := center.y + 148.0
	canvas.draw_rect(Rect2(center.x - 66.0, plinth_y, 132.0, 14.0), Color(0.06, 0.06, 0.09, 0.88), true)
	canvas.draw_rect(Rect2(center.x - 50.0, plinth_y - 10.0, 100.0, 10.0), Color(0.09, 0.09, 0.14, 0.90), true)
	canvas.draw_line(Vector2(center.x - 50.0, plinth_y - 10.0), Vector2(center.x + 50.0, plinth_y - 10.0), Color(0.70, 0.78, 0.94, 0.28), 1.4, true)

	# 3D Faceted Obsidian Obelisk Shaft (Left lit bevel, dark center face, right shadow facet)
	var top_pt := mc + Vector2(0.0, -162.0)
	var shoulder_l := mc + Vector2(-46.0, -96.0)
	var shoulder_r := mc + Vector2(46.0, -96.0)
	var inner_l := mc + Vector2(-24.0, -82.0)
	var inner_r := mc + Vector2(24.0, -82.0)
	var base_l := mc + Vector2(-34.0, 134.0)
	var base_r := mc + Vector2(34.0, 134.0)
	var base_il := mc + Vector2(-18.0, 134.0)
	var base_ir := mc + Vector2(18.0, 134.0)

	# Left lit obsidian facet
	canvas.draw_colored_polygon(PackedVector2Array([top_pt, inner_l, base_il, base_l, shoulder_l]), Color(0.13, 0.13, 0.20, 0.88))
	# Center deep obsidian face
	canvas.draw_colored_polygon(PackedVector2Array([top_pt, inner_r, base_ir, base_il, inner_l]), Color(0.06, 0.055, 0.095, 0.92))
	# Right shadow obsidian facet
	canvas.draw_colored_polygon(PackedVector2Array([top_pt, shoulder_r, base_r, base_ir, inner_r]), Color(0.035, 0.032, 0.06, 0.92))

	# Crisp chiseled facet bevel lines
	var edge_col := Color(0.98, 0.36, 0.46, 0.78) if cracked else Color(0.74, 0.84, 0.98, 0.38)
	var outline := PackedVector2Array([top_pt, shoulder_r, base_r, base_l, shoulder_l, top_pt])
	canvas.draw_polyline(outline, edge_col, 2.0, true)
	canvas.draw_polyline(PackedVector2Array([top_pt, inner_l, base_il]), Color(edge_col.r, edge_col.g, edge_col.b, edge_col.a * 0.55), 1.2, true)
	canvas.draw_polyline(PackedVector2Array([top_pt, inner_r, base_ir]), Color(edge_col.r, edge_col.g, edge_col.b, edge_col.a * 0.40), 1.2, true)

	# Carved sacred Third-Eye Seal prominently in the upper open hall above UpperBalcony
	var seal_c := mc + Vector2(0.0, -86.0)
	var rune_col := Color(1.0, 0.48, 0.56, 0.85 * pulse) if cracked else Color(0.74, 0.88, 1.0, 0.52 * pulse)
	canvas.draw_arc(seal_c, 22.0, 0.0, TAU, 32, Color(rune_col.r, rune_col.g, rune_col.b, rune_col.a * 0.55), 1.3, true)
	# Almond carved eye glyph inside the monolith crown
	var eye_top := PackedVector2Array()
	var eye_bot := PackedVector2Array()
	for ei in range(13):
		var u := -1.0 + 2.0 * (float(ei) / 12.0)
		var ey := 9.5 * (1.0 - u * u)
		eye_top.append(seal_c + Vector2(u * 17.0, -ey))
		eye_bot.append(seal_c + Vector2(u * 17.0, ey))
	canvas.draw_polyline(eye_top, rune_col, 1.8, true)
	canvas.draw_polyline(eye_bot, rune_col, 1.8, true)
	canvas.draw_circle(seal_c, 5.2, rune_col)
	canvas.draw_circle(seal_c, 2.2, Color(0.04, 0.03, 0.06, 0.95))

	# Vertical engraved ancient rune column visible in lower hall (below UpperBalcony)
	for ri in range(4):
		var ry := mc.y + 38.0 + float(ri) * 22.0
		canvas.draw_polyline(PackedVector2Array([
			Vector2(mc.x - 8.0, ry), Vector2(mc.x, ry - 6.0), Vector2(mc.x + 8.0, ry), Vector2(mc.x, ry + 6.0), Vector2(mc.x - 8.0, ry)
		]), Color(rune_col.r, rune_col.g, rune_col.b, rune_col.a * 0.7), 1.3, true)

	# Orbiting levitating obsidian rock shards around the monolith
	for oi in range(6):
		var oa := timer * (0.9 if cracked else 0.42) + float(oi) * TAU / 6.0
		var ox := mc.x + cos(oa) * (66.0 + float(oi % 2) * 14.0)
		var oy := mc.y - 60.0 + sin(oa) * 22.0 + float(oi % 3) * 24.0
		var sz := 5.0 + float(oi % 2) * 2.5
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(ox, oy - sz), Vector2(ox + sz * 0.7, oy), Vector2(ox, oy + sz * 0.8), Vector2(ox - sz * 0.6, oy - sz * 0.2)
		]), Color(0.12, 0.12, 0.18, 0.85))
		canvas.draw_circle(Vector2(ox, oy), 1.4, rune_col)

	# Blazing jagged obsidian magma fracture fissures & smooth gradient volumetric light shafts when awakened!
	if cracked:
		var cracks := [
			PackedVector2Array([
				mc + Vector2(-24.0, -118.0), mc + Vector2(-11.0, -98.0), mc + Vector2(-16.0, -86.0),
				mc + Vector2(-3.0, -70.0), mc + Vector2(10.0, -54.0), mc + Vector2(4.0, -34.0),
				mc + Vector2(15.0, -12.0), mc + Vector2(2.0, 18.0), mc + Vector2(-8.0, 44.0),
				mc + Vector2(6.0, 72.0), mc + Vector2(17.0, 102.0),
			]),
			PackedVector2Array([
				mc + Vector2(22.0, -104.0), mc + Vector2(12.0, -84.0), mc + Vector2(16.0, -68.0),
				mc + Vector2(5.0, -48.0), mc + Vector2(-12.0, -18.0), mc + Vector2(-6.0, 10.0),
				mc + Vector2(-17.0, 38.0), mc + Vector2(-4.0, 68.0), mc + Vector2(-14.0, 118.0),
			]),
			PackedVector2Array([mc + Vector2(-3.0, -70.0), mc + Vector2(-22.0, -62.0), mc + Vector2(-34.0, -50.0)]),
			PackedVector2Array([mc + Vector2(4.0, -34.0), mc + Vector2(24.0, -24.0), mc + Vector2(36.0, -10.0)]),
			PackedVector2Array([mc + Vector2(-8.0, 44.0), mc + Vector2(-24.0, 56.0)]),
			PackedVector2Array([mc + Vector2(6.0, 72.0), mc + Vector2(23.0, 82.0)]),
		]
		# Smooth GPU vertex-colored volumetric light shafts piercing outward from the awakened seal
		for bi in range(6):
			var ba := -2.35 + float(bi) * 0.78 + sin(timer * 0.6 + float(bi)) * 0.05
			var bdir := Vector2(cos(ba), sin(ba))
			var bperp := Vector2(-bdir.y, bdir.x)
			var c_inner := Color(1.0, 0.36, 0.46, 0.14 * pulse)
			var c_outer := Color(1.0, 0.28, 0.40, 0.0)
			canvas.draw_polygon(
				PackedVector2Array([
					seal_c - bperp * 4.0,
					seal_c + bperp * 4.0,
					seal_c + bdir * 195.0 + bperp * 26.0,
					seal_c + bdir * 195.0 - bperp * 26.0,
				]),
				PackedColorArray([c_inner, c_inner, c_outer, c_outer])
			)
		for cr in cracks:
			canvas.draw_polyline(cr, Color(1.0, 0.22, 0.34, 0.34), 8.5, true)
			canvas.draw_polyline(cr, Color(1.0, 0.62, 0.44, 0.86), 3.0, true)
			canvas.draw_polyline(cr, Color(1.0, 0.96, 0.84, 0.98), 1.2, true)
	elif font:
		canvas.draw_string(font, Vector2(center.x - 56.0, center.y - 168.0), "SO'NGGI SINOV", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.84, 0.90, 1.0, 0.36))
