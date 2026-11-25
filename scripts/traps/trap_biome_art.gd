extends RefCounted

# Wrong Way — Unified 5-Biome Stylized Trap & Architecture Art Library
# Harmonizes with Wrong Way's dark gothic-atmospheric silhouette art direction:
#   Ch 1: Twilight Mist Ruins (Limbo stone, dark iron, moonlit slate)
#   Ch 2: Frost Peak (Packed snow, translucent glacial ice crystals, frost)
#   Ch 3: Emerald Woods (Thorny living vines / shirmoqlar, mossy timber, glowing spores)
#   Ch 4: Golden Canyon (Weathered sandstone, carved desert temple bronze & gold, sand)
#   Ch 5: Inferno Abyss (Cracked volcanic basalt/obsidian, pulsing molten magma, embers)
#
# CRITICAL INVARIANT:
# Idle camouflaged traps (Crusher, FallingCeiling, FallingSpike, TrapFloor,
# CrumblingPlatform, DodgingPlatform) call the EXACT same shared surface/teeth/stalactite
# draw helpers as SolidPlatform, making camouflage leaks impossible.

static func get_chapter(node: Node) -> int:
	if node != null and node.is_inside_tree():
		var gm := node.get_node_or_null("/root/GameManager")
		if gm and gm.has_method("get_current_chapter"):
			return clampi(int(gm.get_current_chapter()), 1, 5)
	return 1

static func get_palette(ch: int) -> Dictionary:
	match ch:
		2: # Frost Peak / Snow
			return {
				"base": Color("#0d131f"),
				"base_hi": Color("#1e293b"),
				"teeth": Color(0.22, 0.74, 0.97, 0.92),
				"teeth_dark": Color("#0369a1"),
				"teeth_hi": Color(0.90, 0.98, 1.0, 0.88),
				"accent": Color("#38bdf8"),
				"bright": Color("#f8fafc"),
				"glow": Color(0.22, 0.74, 0.97, 0.42),
				"crack": Color(0.78, 0.96, 1.0, 0.95),
				"crack_glow": Color(0.22, 0.74, 0.97, 0.42),
			}
		3: # Emerald Woods / Forest
			return {
				"base": Color("#062319"),
				"base_hi": Color("#0f3d2e"),
				"teeth": Color("#166534"),
				"teeth_dark": Color("#0b3b1e"),
				"teeth_hi": Color("#4ade80"),
				"accent": Color("#22c55e"),
				"bright": Color("#bbf7d0"),
				"glow": Color(0.25, 0.90, 0.48, 0.38),
				"crack": Color(0.70, 1.0, 0.80, 0.92),
				"crack_glow": Color(0.22, 0.85, 0.45, 0.40),
			}
		4: # Golden Canyon / Desert
			return {
				"base": Color("#291c14"),
				"base_hi": Color("#442b1c"),
				"teeth": Color("#b45309"),
				"teeth_dark": Color("#78350f"),
				"teeth_hi": Color("#fcd34d"),
				"accent": Color("#f59e0b"),
				"bright": Color("#fef3c7"),
				"glow": Color(0.96, 0.68, 0.14, 0.40),
				"crack": Color(1.0, 0.92, 0.65, 0.92),
				"crack_glow": Color(0.96, 0.62, 0.04, 0.42),
			}
		5: # Inferno Abyss / Volcano
			return {
				"base": Color("#1a0505"),
				"base_hi": Color("#380a0a"),
				"teeth": Color("#7f1d1d"),
				"teeth_dark": Color("#3f0a0a"),
				"teeth_hi": Color("#f97316"),
				"accent": Color("#ef4444"),
				"bright": Color("#fef08a"),
				"glow": Color(0.98, 0.38, 0.08, 0.48),
				"crack": Color(1.0, 0.84, 0.48, 0.96),
				"crack_glow": Color(0.98, 0.36, 0.06, 0.50),
			}
		_: # Ch 1: Twilight Mist Ruins (Limbo)
			return {
				"base": Color("#1c1a22"),
				"base_hi": Color("#342f3a"),
				"teeth": Color("#1c1a22"),
				"teeth_dark": Color("#0e0d12"),
				"teeth_hi": Color(0.55, 0.62, 0.74, 0.58),
				"accent": Color("#64748b"),
				"bright": Color("#e2e8f0"),
				"glow": Color(0.55, 0.65, 0.85, 0.35),
				"crack": Color(0.85, 0.92, 1.0, 0.90),
				"crack_glow": Color(0.55, 0.65, 0.85, 0.35),
			}

static func get_base_color(ch: int) -> Color:
	match ch:
		2: return Color("#0d131f")
		3: return Color("#062319")
		4: return Color("#291c14")
		5: return Color("#1a0505")
		_: return Color("#1c1a22")

static func get_ceiling_teeth_color(ch: int) -> Color:
	match ch:
		2: return Color(0.22, 0.74, 0.97, 0.92)
		3: return Color("#166534")
		4: return Color("#b45309")
		5: return Color("#7f1d1d")
		_: return Color("#1c1a22")

# ==============================================================================
# 1. SHARED CAMOUFLAGE-PARITY RENDERERS (SolidPlatform + Disguised Traps)
# ==============================================================================

static func draw_platform_surface(
	canvas: CanvasItem,
	sx: float,
	sw: float,
	h: float,
	ch: int,
	is_wall_or_ext: bool = false,
	full_width: float = -1.0,
	allow_pillar_frost: bool = false
) -> void:
	if sw <= 0.0 or h <= 0.0:
		return
	var base_col := get_base_color(ch)
	canvas.draw_rect(Rect2(sx, 0.0, sw, h), base_col, true)
	if is_wall_or_ext:
		return

	var check_w := sw if full_width < 0.0 else full_width
	if ch == 2: # Frost Peak snow cap
		var snow_h := 5.5
		if allow_pillar_frost and check_w <= 36.0 and h > 96.0:
			canvas.draw_rect(Rect2(sx, 0.0, minf(sw, 2.5), h), Color(0.49, 0.86, 0.99, 0.6), true)
		else:
			canvas.draw_rect(Rect2(sx, 0.0, sw, snow_h), Color("#f1f5f9"), true)
			canvas.draw_rect(Rect2(sx, 0.0, sw, 2.0), Color("#ffffff"), true)
			canvas.draw_rect(Rect2(sx, snow_h - 1.5, sw, 1.5), Color("#94a3b8"), true)
	elif ch == 3: # Emerald Woods mossy carpet
		canvas.draw_rect(Rect2(sx, 0.0, sw, 4.0), Color("#14532d"), true)
		canvas.draw_rect(Rect2(sx, 4.0, sw, 2.0), Color("#064e3b"), true)
	elif ch == 4: # Golden Canyon sunlit sand layer
		var sand_h := 6.0
		canvas.draw_rect(Rect2(sx, 0.0, sw, sand_h), Color("#fcd34d"), true)
		canvas.draw_rect(Rect2(sx, sand_h - 2.0, sw, 2.0), Color("#d97706"), true)
	elif ch == 5: # Inferno Abyss heated obsidian rim
		canvas.draw_rect(Rect2(sx, 0.0, sw, 3.0), Color("#450a0a"), true)
		canvas.draw_rect(Rect2(sx, 0.0, sw, 1.0), Color("#f97316"), true)
	else: # Chapter 1 Twilight Ruins slate trim
		canvas.draw_rect(Rect2(sx, 0.0, sw, 3.0), Color("#342f3a"), true)

static func draw_ceiling_teeth(canvas: CanvasItem, x1: float, x2: float, bot_y: float, ch: int, tooth_len: float = 13.0) -> void:
	var span := x2 - x1
	if span < 8.0:
		return
	var count := maxi(1, int(round(span / 16.0)))
	var tw := span / float(count)
	var teeth_col := get_ceiling_teeth_color(ch)
	var pal := get_palette(ch)
	var hi_col: Color = pal["teeth_hi"]
	var dark_col: Color = pal["teeth_dark"]

	for i in range(count):
		var tx := x1 + float(i) * tw
		var tip := Vector2(tx + tw * 0.5, bot_y + tooth_len)
		var p_l := Vector2(tx, bot_y)
		var p_r := Vector2(tx + tw, bot_y)
		canvas.draw_colored_polygon(PackedVector2Array([p_l, tip, p_r]), teeth_col)
		# Crisp subtle facet matching each biome without breaking silhouette cleanliness
		if ch == 2:
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(tx + tw * 0.5, bot_y), tip, p_r]), Color(0.05, 0.42, 0.68, 0.45))
			canvas.draw_line(Vector2(tx + tw * 0.25, bot_y + 1.0), tip + Vector2(-0.5, -1.5), Color(1.0, 1.0, 1.0, 0.55), 0.9)
		elif ch == 3:
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(tx + tw * 0.5, bot_y), tip, p_r]), Color(dark_col.r, dark_col.g, dark_col.b, 0.50))
			canvas.draw_line(Vector2(tx + tw * 0.22, bot_y + 1.0), tip + Vector2(0.0, -1.5), Color(hi_col.r, hi_col.g, hi_col.b, 0.30), 0.9)
		elif ch == 4:
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(tx + tw * 0.5, bot_y), tip, p_r]), Color(dark_col.r, dark_col.g, dark_col.b, 0.42))
			canvas.draw_line(Vector2(tx + tw * 0.20, bot_y + 1.0), tip + Vector2(-0.5, -1.5), Color(hi_col.r, hi_col.g, hi_col.b, 0.35), 0.9)
		elif ch == 5:
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(tx + tw * 0.5, bot_y), tip, p_r]), Color(dark_col.r, dark_col.g, dark_col.b, 0.52))
			canvas.draw_line(tip + Vector2(0.0, -4.5), tip, Color(hi_col.r, hi_col.g, hi_col.b, 0.55), 1.1)

static func draw_stalactite(
	canvas: CanvasItem,
	center_top: Vector2,
	half_w: float,
	height: float,
	ch: int,
	is_shattered_stump: bool = false
) -> void:
	var teeth_col := get_ceiling_teeth_color(ch)
	var pal := get_palette(ch)
	var dark_col: Color = pal["teeth_dark"]
	var hi_col: Color = pal["teeth_hi"]

	if is_shattered_stump:
		# Lodged fractured stalactite after ground impact (especially dramatic for Ch 2 icicles)
		var base_y := center_top.y + height * 0.45
		var tip := center_top + Vector2(0.0, height)
		var jagged := PackedVector2Array([
			Vector2(center_top.x - half_w * 0.58, base_y + 2.0),
			Vector2(center_top.x - half_w * 0.22, base_y - 4.0),
			Vector2(center_top.x + half_w * 0.14, base_y + 1.0),
			Vector2(center_top.x + half_w * 0.48, base_y - 3.0),
			Vector2(center_top.x + half_w * 0.54, base_y + 4.0),
			tip,
		])
		canvas.draw_colored_polygon(jagged, teeth_col)
		canvas.draw_polyline(jagged, Color(hi_col.r, hi_col.g, hi_col.b, 0.72), 1.1, true)
		if ch == 5:
			canvas.draw_circle(tip + Vector2(0.0, -2.0), 4.5, Color(1.0, 0.45, 0.10, 0.35))
		return

	var p_l := center_top + Vector2(-half_w, 0.0)
	var p_r := center_top + Vector2(half_w, 0.0)
	var tip := center_top + Vector2(0.0, height)

	if ch == 2:
		# Faceted translucent-looking glacial icicle (muz sumalagi)
		var icicle_pts := PackedVector2Array([
			p_l,
			center_top + Vector2(-half_w * 0.58, height * 0.42),
			center_top + Vector2(-half_w * 0.28, height * 0.76),
			tip,
			center_top + Vector2(half_w * 0.30, height * 0.70),
			center_top + Vector2(half_w * 0.62, height * 0.36),
			p_r,
		])
		canvas.draw_colored_polygon(icicle_pts, teeth_col)
		# Deep glacial shadow facet on right side
		canvas.draw_colored_polygon(PackedVector2Array([
			center_top,
			tip,
			center_top + Vector2(half_w * 0.30, height * 0.70),
			center_top + Vector2(half_w * 0.62, height * 0.36),
			p_r,
		]), Color(0.03, 0.38, 0.64, 0.48))
		# Crisp frost-white vertical ridge highlight
		canvas.draw_line(center_top + Vector2(-half_w * 0.34, 2.0), tip + Vector2(-1.2, -3.5), Color(0.95, 0.99, 1.0, 0.78), 1.3)
		canvas.draw_line(center_top + Vector2(-half_w * 0.10, 4.0), center_top + Vector2(-half_w * 0.08, height * 0.55), Color(1.0, 1.0, 1.0, 0.42), 1.0)
	elif ch == 3:
		# Gnarled dark forest thorn-root stalactite
		var thorn_pts := PackedVector2Array([
			p_l,
			center_top + Vector2(-half_w * 0.55, height * 0.38),
			center_top + Vector2(-half_w * 0.36, height * 0.68),
			tip,
			center_top + Vector2(half_w * 0.26, height * 0.64),
			center_top + Vector2(half_w * 0.60, height * 0.32),
			p_r,
		])
		canvas.draw_colored_polygon(thorn_pts, teeth_col)
		canvas.draw_colored_polygon(PackedVector2Array([center_top, tip, center_top + Vector2(half_w * 0.60, height * 0.32), p_r]), Color(dark_col.r, dark_col.g, dark_col.b, 0.54))
		# Subtle vine wrap stripe
		canvas.draw_line(center_top + Vector2(-half_w * 0.52, height * 0.24), center_top + Vector2(half_w * 0.48, height * 0.34), Color(0.28, 0.85, 0.48, 0.38), 1.2)
		canvas.draw_line(center_top + Vector2(-half_w * 0.28, 2.0), tip + Vector2(-0.5, -2.5), Color(hi_col.r, hi_col.g, hi_col.b, 0.34), 1.0)
	elif ch == 4:
		# Layered carved desert canyon sandstone spire
		var sand_pts := PackedVector2Array([
			p_l,
			center_top + Vector2(-half_w * 0.66, height * 0.35),
			center_top + Vector2(-half_w * 0.32, height * 0.72),
			tip,
			center_top + Vector2(half_w * 0.34, height * 0.70),
			center_top + Vector2(half_w * 0.64, height * 0.34),
			p_r,
		])
		canvas.draw_colored_polygon(sand_pts, teeth_col)
		canvas.draw_colored_polygon(PackedVector2Array([center_top, tip, center_top + Vector2(half_w * 0.64, height * 0.34), p_r]), Color(dark_col.r, dark_col.g, dark_col.b, 0.48))
		canvas.draw_line(center_top + Vector2(-half_w * 0.56, height * 0.34), center_top + Vector2(half_w * 0.52, height * 0.34), Color(0.98, 0.82, 0.35, 0.35), 1.0)
		canvas.draw_line(center_top + Vector2(-half_w * 0.36, 2.0), tip + Vector2(-0.8, -3.0), Color(hi_col.r, hi_col.g, hi_col.b, 0.40), 1.1)
	elif ch == 5:
		# Jagged volcanic obsidian stalactite with dark ember core
		var obs_pts := PackedVector2Array([
			p_l,
			center_top + Vector2(-half_w * 0.72, height * 0.32),
			center_top + Vector2(-half_w * 0.30, height * 0.66),
			tip,
			center_top + Vector2(half_w * 0.36, height * 0.62),
			center_top + Vector2(half_w * 0.68, height * 0.28),
			p_r,
		])
		canvas.draw_colored_polygon(obs_pts, teeth_col)
		canvas.draw_colored_polygon(PackedVector2Array([center_top, tip, center_top + Vector2(half_w * 0.68, height * 0.28), p_r]), Color(dark_col.r, dark_col.g, dark_col.b, 0.58))
		canvas.draw_line(center_top + Vector2(0.0, height * 0.42), tip + Vector2(0.0, -2.0), Color(1.0, 0.46, 0.12, 0.58), 1.2)
	else:
		# Ch 1: Sleek dark twilight-stone gothic stalactite (100% dark silhouette parity)
		canvas.draw_colored_polygon(PackedVector2Array([p_l, tip, p_r]), teeth_col)
		canvas.draw_colored_polygon(PackedVector2Array([center_top, tip, p_r]), Color(0.04, 0.04, 0.07, 0.40))
		canvas.draw_line(center_top + Vector2(-half_w * 0.30, 2.0), tip + Vector2(-0.6, -4.0), Color(0.45, 0.50, 0.62, 0.20), 0.9)

static func draw_fracture_cracks(canvas: CanvasItem, w: float, h: float, prog: float, ch: int) -> void:
	if prog <= 0.05:
		return
	var p := clampf(prog, 0.0, 1.0)
	var pal := get_palette(ch)
	var crack_col: Color = pal["crack"]
	var glow_col: Color = pal["crack_glow"]
	crack_col.a *= p
	glow_col.a *= p

	var cx := w * 0.5
	var crack_h := minf(h, 76.0)
	var p0 := Vector2(cx, 0.0)
	var p1 := Vector2(cx - 10.0 * p, crack_h * 0.48)
	var p2 := Vector2(cx + 8.0 * p, crack_h)
	var p3 := Vector2(cx - 24.0 * p, crack_h * 0.78)
	var p4 := Vector2(cx + 4.0, crack_h * 0.30)
	var p5 := Vector2(cx + 22.0 * p, crack_h * 0.62)

	canvas.draw_line(p0, p1, glow_col, 4.2)
	canvas.draw_line(p1, p2, glow_col, 3.6)
	canvas.draw_line(p0, p1, crack_col, 1.8)
	canvas.draw_line(p1, p2, crack_col, 1.6)
	canvas.draw_line(p1, p3, crack_col, 1.2)
	canvas.draw_line(p4, p5, crack_col, 1.2)

	# Biome-specific extra fracture flourishes
	if ch == 2:
		# Crystalline branching ice spider-fractures
		var p6 := Vector2(cx - 18.0 * p, crack_h * 0.22)
		var p7 := Vector2(cx + 16.0 * p, crack_h * 0.85)
		canvas.draw_line(p0 + Vector2(-3.0, 4.0), p6, Color(0.95, 0.99, 1.0, p * 0.85), 1.1)
		canvas.draw_line(p1, p7, Color(0.75, 0.95, 1.0, p * 0.75), 1.0)
	elif ch == 3:
		# Snapping green root tendrils inside split
		canvas.draw_line(p1, p1 + Vector2(-8.0 * p, -6.0 * p), Color(0.25, 0.85, 0.42, p * 0.85), 1.4)
		canvas.draw_line(p4, p4 + Vector2(10.0 * p, -4.0 * p), Color(0.25, 0.85, 0.42, p * 0.85), 1.3)
	elif ch == 5:
		# Glowing white-hot volcanic core seam
		canvas.draw_line(p0, p1, Color(1.0, 0.95, 0.70, p * 0.85), 1.0)
		canvas.draw_line(p1, p2, Color(1.0, 0.78, 0.30, p * 0.80), 0.9)

# ==============================================================================
# 2. ROLLING BOULDER — 5 DISTINCT NATURE-AUTHENTIC FORMS
# ==============================================================================

static func draw_rolling_boulder(
	canvas: CanvasItem,
	radius: float,
	rot: float,
	ch: int,
	pulse_t: float = 0.0,
	impact_flash: float = 0.0
) -> void:
	canvas.draw_set_transform(Vector2.ZERO, rot, Vector2.ONE)
	var r := radius

	match ch:
		2:
			_draw_snowball_boulder(canvas, r, rot, impact_flash)
		3:
			_draw_vine_forest_boulder(canvas, r, pulse_t, impact_flash)
		4:
			_draw_sandstone_canyon_boulder(canvas, r, impact_flash)
		5:
			_draw_magma_volcano_boulder(canvas, r, pulse_t, impact_flash)
		_:
			_draw_limbo_stone_boulder(canvas, r, impact_flash)

	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _draw_snowball_boulder(canvas: CanvasItem, r: float, _rot: float, impact_flash: float) -> void:
	# Chapter 2: Giant Packed Snowball (Qor to'pi) — organic compacted snow with glacial depth
	# Subtle outer cool-frost silhouette glow so it pops against dark frost peaks
	canvas.draw_circle(Vector2.ZERO, r + 2.0, Color(0.55, 0.84, 0.98, 0.18))

	# Organic slightly uneven compacted-snow contour (16 lobes)
	var snow_pts := PackedVector2Array()
	var n := 16
	for i in range(n):
		var ang := float(i) * (TAU / float(n))
		var bump := 1.0 + 0.055 * sin(ang * 3.0 + 0.4) + 0.032 * cos(ang * 5.0 - 0.8)
		snow_pts.append(Vector2(cos(ang), sin(ang)) * (r * bump))
	# Deep glacial-shadow snow body base
	canvas.draw_colored_polygon(snow_pts, Color("#cbd5e1"))

	# Shaded ice-blue lower hemisphere crescent (gives crisp 3D sphere volume)
	var shadow_pts := PackedVector2Array()
	for i in range(9):
		var ang := lerpf(-0.15, PI + 0.25, float(i) / 8.0)
		var bump := 1.0 + 0.045 * sin(ang * 3.0 + 0.4)
		shadow_pts.append(Vector2(cos(ang), sin(ang)) * (r * bump))
	shadow_pts.append(Vector2(-r * 0.45, r * 0.15))
	shadow_pts.append(Vector2(r * 0.20, r * 0.30))
	canvas.draw_colored_polygon(shadow_pts, Color("#7dd3fc", 0.34))

	# Main bright packed-snow core shifted slightly toward light
	canvas.draw_circle(Vector2(-r * 0.10, -r * 0.10), r * 0.84, Color("#eff6ff"))
	canvas.draw_circle(Vector2(-r * 0.22, -r * 0.22), r * 0.56, Color("#ffffff", 0.82))

	# Swirling packed-snow compression ridges (clearly visible rotation when rolling!)
	canvas.draw_arc(Vector2(r * 0.10, r * 0.08), r * 0.62, 0.25, 2.05, 14, Color("#64748b", 0.42), 2.0, true)
	canvas.draw_arc(Vector2(-r * 0.12, -r * 0.08), r * 0.48, -2.6, -0.7, 14, Color("#94a3b8", 0.38), 1.7, true)
	canvas.draw_arc(Vector2(r * 0.04, -r * 0.04), r * 0.30, 0.9, 3.4, 12, Color("#7dd3fc", 0.52), 1.5, true)

	# Embedded small packed frost-snow clumps & gleaming ice flecks
	var flecks := [
		Vector2(-r * 0.42, r * 0.22),
		Vector2(r * 0.38, -r * 0.30),
		Vector2(r * 0.18, r * 0.46),
		Vector2(-r * 0.28, -r * 0.44),
	]
	for idx in range(flecks.size()):
		var fp: Vector2 = flecks[idx]
		var sz := 3.6 if idx % 2 == 0 else 2.8
		var crystal := PackedVector2Array([
			fp + Vector2(0.0, -sz),
			fp + Vector2(sz * 0.85, 0.0),
			fp + Vector2(0.0, sz),
			fp + Vector2(-sz * 0.85, 0.0),
		])
		canvas.draw_colored_polygon(crystal, Color("#38bdf8", 0.72))
		canvas.draw_polyline(crystal, Color("#ffffff", 0.85), 0.9, true)

	# Dark-frost outer crisp outline for clean silhouette readability against any snow backdrop
	var outline := PackedVector2Array(snow_pts)
	outline.append(snow_pts[0])
	canvas.draw_polyline(outline, Color("#1e3a5f", 0.78), 1.8, true)

	if impact_flash > 0.01:
		canvas.draw_circle(Vector2.ZERO, r * 1.06, Color(1.0, 1.0, 1.0, impact_flash * 0.75))

static func _draw_vine_forest_boulder(canvas: CanvasItem, r: float, pulse_t: float, impact_flash: float) -> void:
	# Chapter 3: Vine-Wrapped Mossy Bramble Sphere (Yashil shirmoqlar bilan o'ralgan to'p)
	# 1. Subtle protruding organic bramble thorns & leaf tufts around perimeter
	var thorn_count := 8
	for i in range(thorn_count):
		var ang := float(i) * (TAU / float(thorn_count))
		var dir := Vector2(cos(ang), sin(ang))
		var tang := Vector2(-dir.y, dir.x)
		if i % 2 == 0:
			# Curved botanical thorn
			var b1 := dir * (r - 2.0) - tang * 4.2
			var b2 := dir * (r - 2.0) + tang * 3.2
			var tip := dir * (r + 8.5) + tang * 3.5
			canvas.draw_colored_polygon(PackedVector2Array([b1, tip, b2]), Color("#14532d"))
			canvas.draw_line(b1.lerp(b2, 0.35), tip, Color("#4ade80", 0.65), 1.0)
		else:
			# Sprouting emerald leaf tuft tucked into the vines
			var base_p := dir * (r - 1.5)
			var tip_p := dir * (r + 7.5) - tang * 2.5
			var l_mid := dir * (r + 3.0) - tang * 4.5
			var r_mid := dir * (r + 3.5) + tang * 2.5
			canvas.draw_colored_polygon(PackedVector2Array([base_p, l_mid, tip_p, r_mid]), Color("#15803d"))
			canvas.draw_line(base_p, tip_p, Color("#86efac", 0.70), 0.9)

	# 2. Dark ancient mossy timber/stone core
	canvas.draw_circle(Vector2.ZERO, r, Color("#0a261c"))
	canvas.draw_circle(Vector2(-r * 0.10, -r * 0.10), r * 0.86, Color("#113829"))
	# Bark/moss texture rings
	canvas.draw_arc(Vector2.ZERO, r * 0.72, 0.2, 2.4, 14, Color("#051710", 0.75), 2.2, true)
	canvas.draw_arc(Vector2.ZERO, r * 0.50, -2.5, -0.3, 12, Color("#062319", 0.80), 2.0, true)

	# 3. Crisscrossing thick green thorny vines (shirmoqlar) wrapping tightly around sphere!
	var vine_angles := [0.15, 1.15, 2.15, -0.65]
	for idx in range(vine_angles.size()):
		var va: float = vine_angles[idx]
		var vx := Vector2(cos(va), sin(va))
		var vy := Vector2(-vx.y, vx.x)
		var pts := PackedVector2Array()
		var segs := 10
		for s in range(segs + 1):
			var t := lerpf(-1.0, 1.0, float(s) / float(segs))
			var arc_y := sqrt(maxf(0.0, 1.0 - t * t))
			var wave := sin(t * 4.2 + float(idx) * 1.4) * 0.14
			var offset_perp := (0.28 if idx % 2 == 0 else -0.26) * arc_y + wave * arc_y
			var p := vx * (t * r * 0.96) + vy * (offset_perp * r)
			pts.append(p)
		# Dark shadow under vine
		var shadow_pts := PackedVector2Array()
		for p in pts:
			shadow_pts.append(p + Vector2(1.2, 1.6))
		canvas.draw_polyline(shadow_pts, Color("#03140d", 0.72), 4.6, true)
		# Main vibrant forest vine
		var vine_col := Color("#166534") if idx % 2 == 0 else Color("#15803d")
		canvas.draw_polyline(pts, vine_col, 3.6, true)
		# Bright botanical highlight ridge along vine
		canvas.draw_polyline(pts, Color("#4ade80", 0.58), 1.2, true)

	# 4. Inner small nestled emerald leaves & subtle bioluminescent forest spores
	var glow_p := 0.70 + 0.30 * sin(pulse_t * 4.0)
	var spore_pts := [Vector2(-r * 0.34, -r * 0.18), Vector2(r * 0.32, r * 0.24), Vector2(-r * 0.08, r * 0.38)]
	for sp in spore_pts:
		canvas.draw_circle(sp, 3.4, Color(0.28, 0.95, 0.52, 0.26 * glow_p))
		canvas.draw_circle(sp, 1.6, Color(0.75, 1.0, 0.78, 0.90 * glow_p))

	# Crisp dark-emerald rim outline
	canvas.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color("#4ade80", 0.55), 1.6, true)

	if impact_flash > 0.01:
		canvas.draw_circle(Vector2.ZERO, r * 1.06, Color(0.75, 1.0, 0.80, impact_flash * 0.65))

static func _draw_sandstone_canyon_boulder(canvas: CanvasItem, r: float, impact_flash: float) -> void:
	# Chapter 4: Carved Golden Canyon Sandstone Sun-Relic Sphere
	# Faceted weathered sandstone polygon
	var poly := PackedVector2Array()
	var n := 12
	for i in range(n):
		var ang := float(i) * (TAU / float(n))
		var jitter := 1.0 + 0.04 * cos(ang * 4.0)
		poly.append(Vector2(cos(ang), sin(ang)) * (r * jitter))
	canvas.draw_colored_polygon(poly, Color("#5c2d0c"))
	canvas.draw_circle(Vector2(-r * 0.08, -r * 0.08), r * 0.86, Color("#7c3a10"))

	# Eroded sandstone strata bands
	canvas.draw_line(Vector2(-r * 0.76, -r * 0.34), Vector2(r * 0.74, -r * 0.28), Color("#9a4a16", 0.75), 3.0)
	canvas.draw_line(Vector2(-r * 0.82, r * 0.12), Vector2(r * 0.80, r * 0.18), Color("#451a03", 0.75), 2.6)
	canvas.draw_line(Vector2(-r * 0.60, r * 0.52), Vector2(r * 0.58, r * 0.48), Color("#b45309", 0.65), 2.2)

	# Carved ancient bronze/gold canyon temple ring & geometric sun-spokes
	canvas.draw_arc(Vector2.ZERO, r * 0.66, 0.0, TAU, 24, Color("#d97706"), 3.0, true)
	canvas.draw_arc(Vector2.ZERO, r * 0.66, 0.0, TAU, 24, Color("#fcd34d", 0.75), 1.1, true)
	for i in range(6):
		var ang := float(i) * (TAU / 6.0)
		var p1 := Vector2(cos(ang), sin(ang)) * (r * 0.30)
		var p2 := Vector2(cos(ang), sin(ang)) * (r * 0.92)
		canvas.draw_line(p1, p2, Color("#451a03"), 3.2)
		canvas.draw_line(p1, p2, Color("#f59e0b", 0.80), 1.2)
		# Small bronze rim stud
		canvas.draw_circle(Vector2(cos(ang), sin(ang)) * (r * 0.90), 2.4, Color("#fcd34d"))

	# Sun-relic centerpiece
	canvas.draw_circle(Vector2.ZERO, r * 0.28, Color("#451a03"))
	canvas.draw_circle(Vector2.ZERO, r * 0.18, Color("#f59e0b"))
	canvas.draw_rect(Rect2(-3.0, -3.0, 6.0, 6.0), Color("#fef3c7"), true)

	# Outer rim
	var outline := PackedVector2Array(poly)
	outline.append(poly[0])
	canvas.draw_polyline(outline, Color("#fcd34d", 0.75), 1.8, true)

	if impact_flash > 0.01:
		canvas.draw_circle(Vector2.ZERO, r * 1.06, Color(1.0, 0.92, 0.65, impact_flash * 0.65))

static func _draw_magma_volcano_boulder(canvas: CanvasItem, r: float, pulse_t: float, impact_flash: float) -> void:
	# Chapter 5: Cracked Volcanic Basalt & Molten Magma Sphere
	var pulse := 0.78 + 0.22 * sin(pulse_t * 6.5)

	# Soft fiery heat-halo rim
	canvas.draw_circle(Vector2.ZERO, r + 4.0, Color(0.98, 0.32, 0.06, 0.22 * pulse))

	# Jagged volcanic obsidian-basalt outer rock silhouette
	var rock_pts := PackedVector2Array()
	var n := 16
	for i in range(n):
		var ang := float(i) * (TAU / float(n))
		var jag := 1.0 + (0.075 if i % 2 == 0 else -0.045) + 0.035 * sin(ang * 3.0 + 0.5)
		rock_pts.append(Vector2(cos(ang), sin(ang)) * (r * jag))
	canvas.draw_colored_polygon(rock_pts, Color("#180607"))
	canvas.draw_circle(Vector2(-r * 0.08, -r * 0.08), r * 0.80, Color("#2b0a0c"))

	# Organic zig-zagging molten magma fissures branching across cracked volcanic basalt
	var cracks := [
		[Vector2(-r * 0.78, -r * 0.22), Vector2(-r * 0.42, -r * 0.34), Vector2(-r * 0.14, -r * 0.06), Vector2(r * 0.26, -r * 0.24), Vector2(r * 0.68, -r * 0.44)],
		[Vector2(-r * 0.14, -r * 0.06), Vector2(r * 0.14, r * 0.18), Vector2(r * 0.44, r * 0.12), Vector2(r * 0.72, r * 0.36)],
		[Vector2(r * 0.14, r * 0.18), Vector2(-r * 0.12, r * 0.48), Vector2(-r * 0.48, r * 0.68)],
		[Vector2(-r * 0.42, -r * 0.34), Vector2(-r * 0.24, -r * 0.78)],
	]
	for seg_arr in cracks:
		var pts := PackedVector2Array(seg_arr)
		canvas.draw_polyline(pts, Color(0.95, 0.22, 0.03, 0.58 * pulse), 5.4, true)
		canvas.draw_polyline(pts, Color(0.99, 0.48, 0.08, 0.92 * pulse), 2.6, true)
		canvas.draw_polyline(pts, Color(1.0, 0.90, 0.46, 0.94 * pulse), 1.1, true)

	# Glowing molten magma core peeking through center fracture
	canvas.draw_circle(Vector2(-r * 0.06, r * 0.02), r * 0.22, Color(0.98, 0.32, 0.05, 0.78 * pulse))
	canvas.draw_circle(Vector2(-r * 0.06, r * 0.02), r * 0.11, Color(1.0, 0.88, 0.40, 0.95 * pulse))

	# Scorched basalt rim highlight
	var outline := PackedVector2Array(rock_pts)
	outline.append(rock_pts[0])
	canvas.draw_polyline(outline, Color(0.98, 0.40, 0.10, 0.68 * pulse), 1.6, true)

	if impact_flash > 0.01:
		canvas.draw_circle(Vector2.ZERO, r * 1.10, Color(1.0, 0.78, 0.35, impact_flash * 0.80))

static func _draw_limbo_stone_boulder(canvas: CanvasItem, r: float, impact_flash: float) -> void:
	# Chapter 1: Sleek Gothic Twilight Obsidian-Slate Runed Boulder (Refined Limbo craft)
	# Sculpted angular dark-iron studs (compact & grounded, zero stray whiskers)
	var num_spurs := 8
	for i in range(num_spurs):
		var ang := float(i) * (TAU / float(num_spurs))
		var dir := Vector2(cos(ang), sin(ang))
		var tang := Vector2(-dir.y, dir.x)
		var b1 := dir * (r - 2.5) - tang * 5.2
		var b2 := dir * (r - 2.5) + tang * 5.2
		var tip := dir * (r + 7.5)
		canvas.draw_colored_polygon(PackedVector2Array([b1, tip, b2]), Color("#1e1b29"))
		canvas.draw_colored_polygon(PackedVector2Array([dir * (r - 2.5), tip, b2]), Color("#0d0c14", 0.65))
		canvas.draw_line(b1.lerp(tip, 0.25), b1.lerp(tip, 0.85), Color(0.55, 0.65, 0.80, 0.48), 1.0)

	# Faceted dark obsidian-slate sphere
	var poly := PackedVector2Array()
	var n := 14
	for i in range(n):
		var ang := float(i) * (TAU / float(n))
		var facet := 1.0 + 0.03 * sin(ang * 5.0)
		poly.append(Vector2(cos(ang), sin(ang)) * (r * facet))
	canvas.draw_colored_polygon(poly, Color("#11131c"))
	canvas.draw_circle(Vector2(-r * 0.10, -r * 0.10), r * 0.84, Color("#1a1e2c"))

	# Recessed weathered gothic iron cross-straps
	canvas.draw_line(Vector2(-r * 0.90, 0.0), Vector2(r * 0.90, 0.0), Color("#0b0d14"), 4.2)
	canvas.draw_line(Vector2(0.0, -r * 0.90), Vector2(0.0, r * 0.90), Color("#0b0d14"), 4.2)
	canvas.draw_line(Vector2(-r * 0.86, -1.0), Vector2(r * 0.86, -1.0), Color("#475569", 0.55), 1.0)
	canvas.draw_line(Vector2(-1.0, -r * 0.86), Vector2(-1.0, r * 0.86), Color("#475569", 0.55), 1.0)

	# Chiseled slate cracks
	canvas.draw_line(Vector2(-r * 0.55, -r * 0.35), Vector2(r * 0.14, -r * 0.14), Color("#07080d"), 2.2)
	canvas.draw_line(Vector2(r * 0.14, -r * 0.14), Vector2(r * 0.56, -r * 0.48), Color("#07080d"), 1.8)
	canvas.draw_line(Vector2(r * 0.14, -r * 0.14), Vector2(-r * 0.10, r * 0.54), Color("#07080d"), 2.0)

	# Central forged iron hub with subtle pale-moonlight core
	canvas.draw_circle(Vector2.ZERO, 6.2, Color("#2c3549"))
	canvas.draw_circle(Vector2.ZERO, 3.0, Color("#cbd5e1"))

	# Crisp moonlit stone rim
	canvas.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(0.45, 0.55, 0.70, 0.78), 1.8, true)
	canvas.draw_arc(Vector2.ZERO, r - 4.0, -PI * 0.75, -PI * 0.20, 14, Color(0.70, 0.80, 0.95, 0.36), 1.4, true)

	if impact_flash > 0.01:
		canvas.draw_circle(Vector2.ZERO, r * 1.06, Color(0.85, 0.92, 1.0, impact_flash * 0.65))

# ==============================================================================
# 3. FLOOR SPIKES / POP-UP SPIKES / JUMPING SPIKES — 5-BIOME CRAFT
# ==============================================================================

static func draw_floor_spikes(
	canvas: CanvasItem,
	w: float,
	h: float,
	ch: int,
	base_y: float = 32.0,
	tip_y: float = 0.0,
	draw_plinth: bool = false
) -> void:
	if absf(base_y - tip_y) < 1.5 or w < 4.0:
		return
	var pal := get_palette(ch)
	var count := maxi(1, int(roundf(w / 16.0)))
	var step := w / float(count)
	var dir_up := -1.0 if tip_y < base_y else 1.0
	var actual_h := absf(base_y - tip_y)

	# Optional biome plinth bar (for JumpingSpikes or mounted floor spikes)
	if draw_plinth:
		var bar_y := base_y if dir_up < 0.0 else base_y - 3.5
		canvas.draw_rect(Rect2(0.0, bar_y, w, 3.5), pal["base"], true)
		var bar_hi: Color = pal["teeth_hi"]
		canvas.draw_rect(Rect2(0.0, bar_y, w, 1.2), Color(bar_hi.r, bar_hi.g, bar_hi.b, 0.55), true)

	for i in range(count):
		var x0 := float(i) * step
		var x1 := x0 + step * 0.5
		var x2 := x0 + step

		if ch == 2:
			# Glacial Ice Crystal Spikes
			var mid_y := lerpf(base_y, tip_y, 0.55)
			var pts := PackedVector2Array([
				Vector2(x0 + 0.5, base_y),
				Vector2(x0 + step * 0.24, mid_y),
				Vector2(x1, tip_y),
				Vector2(x2 - step * 0.24, mid_y),
				Vector2(x2 - 0.5, base_y),
			])
			canvas.draw_colored_polygon(pts, Color(0.22, 0.74, 0.97, 0.92))
			# Shaded glacial right facet
			canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(x1, base_y),
				Vector2(x1, tip_y),
				Vector2(x2 - step * 0.24, mid_y),
				Vector2(x2 - 0.5, base_y),
			]), Color(0.03, 0.36, 0.62, 0.45))
			canvas.draw_polyline(pts, Color(0.92, 0.98, 1.0, 0.85), 1.1, true)
			canvas.draw_line(Vector2(x0 + step * 0.38, base_y + dir_up * 2.0), Vector2(x1 - 0.6, tip_y - dir_up * 3.0), Color(1.0, 1.0, 1.0, 0.72), 1.1)
		elif ch == 3:
			# Organic Curved Forest Bramble Thorns (Yashil tikanli shirmoqlar)
			var lean := (step * 0.12) if (i % 2 == 0) else (-step * 0.12)
			var tip := Vector2(x1 + lean, tip_y)
			var ctrl_l := Vector2(x0 + step * 0.22 + lean * 0.35, lerpf(base_y, tip_y, 0.52))
			var ctrl_r := Vector2(x2 - step * 0.22 + lean * 0.55, lerpf(base_y, tip_y, 0.48))
			var pts := PackedVector2Array([
				Vector2(x0 + 0.6, base_y),
				ctrl_l,
				tip,
				ctrl_r,
				Vector2(x2 - 0.6, base_y),
			])
			canvas.draw_colored_polygon(pts, Color("#14532d"))
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x1, base_y), tip, ctrl_r, Vector2(x2 - 0.6, base_y)]), Color("#072a16", 0.58))
			canvas.draw_polyline(pts, Color("#4ade80", 0.82), 1.1, true)
			# Small mossy vine tuft at base
			if actual_h > 10.0:
				canvas.draw_circle(Vector2(x0 + step * 0.5, base_y + dir_up * 2.0), 2.2, Color("#166534"))
		elif ch == 4:
			# Chiseled Sandstone & Gilded Bronze Desert Spear-Spikes
			var mid_y := lerpf(base_y, tip_y, 0.42)
			var pts := PackedVector2Array([
				Vector2(x0 + 0.5, base_y),
				Vector2(x0 + step * 0.26, mid_y),
				Vector2(x1, tip_y),
				Vector2(x2 - step * 0.26, mid_y),
				Vector2(x2 - 0.5, base_y),
			])
			canvas.draw_colored_polygon(pts, Color("#78350f"))
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x1, base_y), Vector2(x1, tip_y), Vector2(x2 - step * 0.26, mid_y), Vector2(x2 - 0.5, base_y)]), Color("#451a03", 0.55))
			# Gilded spear tip accent
			canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(x0 + step * 0.34, lerpf(base_y, tip_y, 0.64)),
				Vector2(x1, tip_y),
				Vector2(x2 - step * 0.34, lerpf(base_y, tip_y, 0.64)),
			]), Color("#d97706", 0.85))
			canvas.draw_polyline(pts, Color("#fcd34d", 0.82), 1.1, true)
		elif ch == 5:
			# Jagged Volcanic Obsidian Glass & Superheated Magma-Tipped Spikes
			var mid_y := lerpf(base_y, tip_y, 0.50)
			var pts := PackedVector2Array([
				Vector2(x0 + 0.4, base_y),
				Vector2(x0 + step * 0.20, mid_y),
				Vector2(x1, tip_y),
				Vector2(x2 - step * 0.22, mid_y - dir_up * 2.0),
				Vector2(x2 - 0.4, base_y),
			])
			canvas.draw_colored_polygon(pts, Color("#2a0808"))
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x1, base_y), Vector2(x1, tip_y), Vector2(x2 - 0.4, base_y)]), Color("#120303", 0.62))
			# Molten superheated tip glow
			canvas.draw_line(Vector2(x1, lerpf(base_y, tip_y, 0.45)), Vector2(x1, tip_y), Color("#f97316", 0.90), 1.8)
			canvas.draw_line(Vector2(x1, lerpf(base_y, tip_y, 0.72)), Vector2(x1, tip_y), Color("#fef08a", 0.92), 1.0)
			canvas.draw_polyline(pts, Color("#ef4444", 0.78), 1.0, true)
		else:
			# Ch 1: Gothic Forged Dark-Iron / Slate Spikes
			var pts := PackedVector2Array([
				Vector2(x0, base_y),
				Vector2(x1, tip_y),
				Vector2(x2, base_y),
			])
			canvas.draw_colored_polygon(pts, Color("#1c1a22"))
			# Subtle gothic metallic facet bevel
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x1, base_y), Vector2(x1, tip_y), Vector2(x2, base_y)]), Color("#0d0c12", 0.55))
			canvas.draw_line(Vector2(x0 + 1.4, base_y + dir_up * 1.0), Vector2(x1, tip_y - dir_up * 1.5), Color(0.55, 0.62, 0.74, 0.42), 1.0)

# ==============================================================================
# 4. SAW BLADES & TETHERS (MovingSaw + CircularSaw) — 5-BIOME CRAFT
# ==============================================================================

static func draw_saw_tether(
	canvas: CanvasItem,
	origin: Vector2,
	blade_offset: Vector2,
	orbit_radius: float,
	ch: int
) -> void:
	if orbit_radius <= 0.0:
		return
	var pal := get_palette(ch)
	var links := maxi(3, int(orbit_radius / 14.0))

	if ch == 2:
		# Frozen ice-chain tether
		canvas.draw_line(origin, blade_offset, Color("#0c4a6e"), 3.0)
		canvas.draw_line(origin, blade_offset, Color("#7dd3fc", 0.65), 1.1)
		for i in range(1, links):
			var p := origin.lerp(blade_offset, float(i) / float(links))
			canvas.draw_circle(p, 3.6, Color("#0f172a"))
			canvas.draw_circle(p, 2.0, Color("#bae6fd"))
		canvas.draw_circle(origin, 6.5, Color("#0f172a"))
		canvas.draw_circle(origin, 4.0, Color("#0284c7"))
		canvas.draw_circle(origin, 1.8, Color("#f0f9ff"))
	elif ch == 3:
		# Braided living thorny vine tether with tiny leaves!
		var dir := blade_offset - origin
		var perp := Vector2(-dir.y, dir.x).normalized()
		var pts := PackedVector2Array()
		var segs := maxi(6, links * 2)
		for i in range(segs + 1):
			var t := float(i) / float(segs)
			var wave := sin(t * PI * 3.0) * 2.2 * sin(t * PI)
			pts.append(origin.lerp(blade_offset, t) + perp * wave)
		canvas.draw_polyline(pts, Color("#064e3b"), 4.0, true)
		canvas.draw_polyline(pts, Color("#22c55e", 0.75), 1.5, true)
		for i in range(1, links):
			var t := float(i) / float(links)
			var p := origin.lerp(blade_offset, t)
			var side := 1.0 if i % 2 == 0 else -1.0
			var leaf_tip := p + perp * (5.5 * side)
			canvas.draw_colored_polygon(PackedVector2Array([p - dir.normalized() * 2.0, leaf_tip, p + dir.normalized() * 2.0]), Color("#16a34a"))
		canvas.draw_circle(origin, 6.5, Color("#062319"))
		canvas.draw_circle(origin, 3.8, Color("#166534"))
		canvas.draw_circle(origin, 1.8, Color("#86efac"))
	elif ch == 4:
		# Ancient bronze desert temple chain
		canvas.draw_line(origin, blade_offset, Color("#451a03"), 3.0)
		canvas.draw_line(origin, blade_offset, Color("#f59e0b", 0.65), 1.0)
		for i in range(1, links):
			var p := origin.lerp(blade_offset, float(i) / float(links))
			canvas.draw_circle(p, 3.6, Color("#78350f"))
			canvas.draw_circle(p, 1.8, Color("#fcd34d"))
		canvas.draw_circle(origin, 6.5, Color("#291c14"))
		canvas.draw_circle(origin, 4.0, Color("#b45309"))
		canvas.draw_rect(Rect2(origin.x - 1.8, origin.y - 1.8, 3.6, 3.6), Color("#fef3c7"), true)
	elif ch == 5:
		# Glowing forged magma-iron chain
		canvas.draw_line(origin, blade_offset, Color("#1a0505"), 3.6)
		canvas.draw_line(origin, blade_offset, Color("#ea580c", 0.75), 1.3)
		for i in range(1, links):
			var p := origin.lerp(blade_offset, float(i) / float(links))
			canvas.draw_circle(p, 3.8, Color("#450a0a"))
			canvas.draw_circle(p, 1.8, Color("#fb923c"))
		canvas.draw_circle(origin, 6.5, Color("#1a0505"))
		canvas.draw_circle(origin, 4.0, Color("#991b1b"))
		canvas.draw_circle(origin, 1.8, Color("#fef08a"))
	else:
		# Ch 1: Gothic forged iron chain
		canvas.draw_line(origin, blade_offset, Color("#1e293b"), 2.8)
		for i in range(1, links):
			var p := origin.lerp(blade_offset, float(i) / float(links))
			canvas.draw_circle(p, 3.5, Color("#334155"))
			canvas.draw_circle(p, 1.5, Color("#64748b"))
		canvas.draw_circle(origin, 6.2, pal["base"])
		canvas.draw_circle(origin, 3.6, Color("#475569"))
		canvas.draw_circle(origin, 1.5, Color("#cbd5e1"))

static func draw_saw_blade(
	canvas: CanvasItem,
	pos: Vector2,
	r: float,
	spin: float,
	ch: int,
	pulse_t: float = 0.0
) -> void:
	if ch == 2:
		# Ch 2: Crystalline Glacial Frost-Star / Ice-Crystal Saw
		var teeth := 8
		var inner_r := r * 0.62
		var pts := PackedVector2Array()
		var step := TAU / float(teeth)
		for i in range(teeth):
			var a0 := spin + float(i) * step
			var a1 := a0 + step * 0.50
			pts.append(pos + Vector2(cos(a0), sin(a0)) * inner_r)
			pts.append(pos + Vector2(cos(a1), sin(a1)) * r)
		canvas.draw_colored_polygon(pts, Color(0.22, 0.74, 0.97, 0.94))
		var out_pts := PackedVector2Array(pts)
		out_pts.append(pts[0])
		canvas.draw_polyline(out_pts, Color("#ffffff", 0.90), 1.3, true)
		# Inner snowflake filigree spokes
		for i in range(4):
			var a := spin + float(i) * (PI * 0.5)
			var d := Vector2(cos(a), sin(a)) * (r * 0.82)
			canvas.draw_line(pos - d, pos + d, Color(0.92, 0.99, 1.0, 0.60), 1.0)
		canvas.draw_circle(pos, inner_r * 0.80, Color("#0f172a"))
		canvas.draw_circle(pos, inner_r * 0.56, Color("#0284c7"))
		canvas.draw_circle(pos, 3.6, Color("#1e293b"))
		canvas.draw_circle(pos, 1.8, Color("#f0f9ff"))
	elif ch == 3:
		# Ch 3: Whirling Thorny Bramble Wheel (Aylanuvchi tikanli shirmoq g'ildiragi)
		var teeth := 8
		var inner_r := r * 0.66
		var pts := PackedVector2Array()
		var step := TAU / float(teeth)
		for i in range(teeth):
			var a0 := spin + float(i) * step
			var a1 := a0 + step * 0.68 # Swept organic thorn hook
			var a2 := a0 + step * 0.86
			pts.append(pos + Vector2(cos(a0), sin(a0)) * inner_r)
			pts.append(pos + Vector2(cos(a1), sin(a1)) * r)
			pts.append(pos + Vector2(cos(a2), sin(a2)) * inner_r)
		canvas.draw_colored_polygon(pts, Color("#15803d"))
		var out_pts := PackedVector2Array(pts)
		out_pts.append(pts[0])
		canvas.draw_polyline(out_pts, Color("#4ade80", 0.90), 1.2, true)
		# Braided dark-wood vine ring + glowing spore core
		canvas.draw_circle(pos, inner_r * 0.92, Color("#082016"))
		canvas.draw_arc(pos, inner_r * 0.72, 0.0, TAU, 20, Color("#166534"), 2.4, true)
		canvas.draw_circle(pos, inner_r * 0.42, Color("#14532d"))
		var p_glow := 0.75 + 0.25 * sin(pulse_t * 6.0)
		canvas.draw_circle(pos, 3.4, Color(0.55, 1.0, 0.65, 0.90 * p_glow))
	elif ch == 4:
		# Ch 4: Ancient 6-Blade Golden Canyon Sun-Chakram
		var teeth := 6
		var inner_r := r * 0.72
		var pts := PackedVector2Array()
		var step := TAU / float(teeth)
		for i in range(teeth):
			var a0 := spin + float(i) * step
			var a1 := a0 + step * 0.58
			var a2 := a0 + step * 0.92
			pts.append(pos + Vector2(cos(a0), sin(a0)) * inner_r)
			pts.append(pos + Vector2(cos(a1), sin(a1)) * r)
			pts.append(pos + Vector2(cos(a2), sin(a2)) * inner_r)
		canvas.draw_colored_polygon(pts, Color("#b45309"))
		var out_pts := PackedVector2Array(pts)
		out_pts.append(pts[0])
		canvas.draw_polyline(out_pts, Color("#fcd34d", 0.92), 1.4, true)
		canvas.draw_circle(pos, inner_r * 0.84, Color("#3a1905"))
		canvas.draw_arc(pos, inner_r * 0.62, 0.0, TAU, 18, Color("#d97706"), 2.0, true)
		canvas.draw_circle(pos, 4.2, Color("#78350f"))
		canvas.draw_rect(Rect2(pos.x - 2.0, pos.y - 2.0, 4.0, 4.0), Color("#fef3c7"), true)
	elif ch == 5:
		# Ch 5: Serrated Volcanic Obsidian & Molten Lava Buzz-Wheel
		var teeth := 10
		var inner_r := r * 0.68
		var pts := PackedVector2Array()
		var step := TAU / float(teeth)
		for i in range(teeth):
			var a0 := spin + float(i) * step
			var a1 := a0 + step * 0.45
			var a2 := a0 + step * 0.82
			pts.append(pos + Vector2(cos(a0), sin(a0)) * inner_r)
			pts.append(pos + Vector2(cos(a1), sin(a1)) * r)
			pts.append(pos + Vector2(cos(a2), sin(a2)) * inner_r)
		var p_glow := 0.80 + 0.20 * sin(pulse_t * 8.0)
		canvas.draw_circle(pos, r + 2.0, Color(0.98, 0.30, 0.06, 0.20 * p_glow))
		canvas.draw_colored_polygon(pts, Color("#2a0707"))
		var out_pts := PackedVector2Array(pts)
		out_pts.append(pts[0])
		canvas.draw_polyline(out_pts, Color("#f97316", 0.95), 1.5, true)
		canvas.draw_circle(pos, inner_r * 0.88, Color("#140404"))
		canvas.draw_arc(pos, inner_r * 0.64, 0.0, TAU, 20, Color("#ef4444"), 2.4, true)
		canvas.draw_circle(pos, inner_r * 0.38, Color("#ea580c"))
		canvas.draw_circle(pos, 2.8, Color("#fef08a"))
	else:
		# Ch 1: Gothic Forged Iron Saw Blade
		var teeth := 8
		var inner_r := r * 0.70
		var pts := PackedVector2Array()
		var step := TAU / float(teeth)
		for i in range(teeth):
			var a0 := spin + float(i) * step
			var a1 := a0 + step * 0.48
			var a2 := a0 + step * 0.82
			pts.append(pos + Vector2(cos(a0), sin(a0)) * inner_r)
			pts.append(pos + Vector2(cos(a1), sin(a1)) * r)
			pts.append(pos + Vector2(cos(a2), sin(a2)) * inner_r)
		canvas.draw_colored_polygon(pts, Color("#94a3b8"))
		var out_pts := PackedVector2Array(pts)
		out_pts.append(pts[0])
		canvas.draw_polyline(out_pts, Color("#f1f5f9", 0.92), 1.1, true)
		canvas.draw_circle(pos, inner_r * 0.84, Color("#334155"))
		canvas.draw_circle(pos, inner_r * 0.62, Color("#b91c1c"))
		canvas.draw_circle(pos, inner_r * 0.42, Color("#1e293b"))
		canvas.draw_circle(pos, 3.6, Color("#0f172a"))
		canvas.draw_circle(pos, 1.6, Color("#e2e8f0"))

# ==============================================================================
# 5. CRUSHER / FALLING CEILING — BIOME TETHER & POST-DETACH DETAIL
# ==============================================================================

static func draw_crusher_tether(
	canvas: CanvasItem,
	chain_x: float,
	chain_h: float,
	ch: int,
	is_waiting: bool,
	sway_ratio: float,
	sway_phase: float
) -> void:
	if chain_h <= 4.0:
		return

	if ch == 3:
		# Ch 3: Braided living emerald vine tether (shirmoqlar) with tiny leaves!
		var segs := maxi(5, int(chain_h / 10.0))
		var vine_pts := PackedVector2Array()
		for i in range(segs + 1):
			var progress := float(i) / float(segs)
			var cy := -progress * chain_h
			var ox := 0.0
			if is_waiting:
				ox = sin(progress * PI) * (5.0 * sway_ratio + 1.5) + sin(progress * PI * 2.0 + sway_phase) * (3.5 * sway_ratio)
			var braid := sin(progress * chain_h * 0.22) * 1.8
			vine_pts.append(Vector2(chain_x + ox + braid, cy))
		canvas.draw_polyline(vine_pts, Color("#064e3b"), 5.0, true)
		canvas.draw_polyline(vine_pts, Color("#15803d"), 3.0, true)
		canvas.draw_polyline(vine_pts, Color("#4ade80", 0.62), 1.1, true)
		for i in range(1, segs, 2):
			var vp := vine_pts[i]
			var side := 1.0 if ((i / 2) % 2 == 0) else -1.0
			canvas.draw_colored_polygon(PackedVector2Array([
				vp,
				vp + Vector2(side * 6.5, -2.5),
				vp + Vector2(side * 2.0, -5.5),
			]), Color("#16a34a"))
		canvas.draw_circle(Vector2(chain_x, 0.0), 5.0, Color("#14532d"))
		canvas.draw_circle(Vector2(chain_x, -chain_h), 4.5, Color("#14532d"))
		return

	# Chain colors per biome (Ch 1 iron, Ch 2 frosted ice-chain, Ch 4 bronze, Ch 5 magma-iron)
	var link_outer := Color("#1a2230")
	var link_inner := Color("#2a3548")
	var ring_col := Color("#262e3e")
	var hole_col := Color("#0c0e14")
	if ch == 2:
		link_outer = Color("#38bdf8", 0.85)
		link_inner = Color("#e0f2fe", 0.85)
		ring_col = Color("#0284c7")
		hole_col = Color("#0f172a")
	elif ch == 4:
		link_outer = Color("#92400e")
		link_inner = Color("#fcd34d", 0.82)
		ring_col = Color("#b45309")
		hole_col = Color("#291c14")
	elif ch == 5:
		link_outer = Color("#7f1d1d")
		link_inner = Color("#fb923c", 0.90)
		ring_col = Color("#991b1b")
		hole_col = Color("#1a0505")

	var link_spacing := 12.0
	var current_y := 0.0
	while current_y > -chain_h:
		var progress := clampf(-current_y / chain_h, 0.0, 1.0)
		var offset_x := 0.0
		if is_waiting:
			var sag := sin(progress * PI) * (5.0 * sway_ratio + 1.5)
			var ripple := sin(progress * PI * 2.0 + sway_phase) * (3.5 * sway_ratio)
			offset_x = sag + ripple

		canvas.draw_rect(Rect2(chain_x + offset_x - 3.0, current_y - 10.0, 6.0, 10.0), link_outer, false, 1.8)
		canvas.draw_line(
			Vector2(chain_x + offset_x, current_y - 10.0),
			Vector2(chain_x + offset_x, current_y - 12.0),
			link_inner,
			1.5
		)
		current_y -= link_spacing

	canvas.draw_circle(Vector2(chain_x, 0.0), 5.0, ring_col)
	canvas.draw_circle(Vector2(chain_x, 0.0), 2.5, hole_col)
	canvas.draw_circle(Vector2(chain_x, -chain_h), 4.5, ring_col)

static func draw_crusher_active_detail(
	canvas: CanvasItem,
	w: float,
	h: float,
	top_clip: float,
	reveal_alpha: float,
	ch: int
) -> void:
	# Strictly zero draw when idle (reveal_alpha <= 0.01) to keep ceiling camouflage 100% airtight!
	if reveal_alpha <= 0.01:
		return
	var a := clampf(reveal_alpha, 0.0, 1.0)
	var body_h := h - top_clip
	if body_h <= 8.0:
		return

	var inset := Rect2(4.0, top_clip + 4.0, maxf(2.0, w - 8.0), maxf(2.0, body_h - 8.0))
	match ch:
		2: # Glacial frost bevel & crystalline corner sheen
			canvas.draw_rect(inset, Color(0.45, 0.85, 0.99, 0.32 * a), false, 1.4)
			var cx := w * 0.5
			var cy := top_clip + body_h * 0.5
			var ice_crack := PackedVector2Array([
				Vector2(w * 0.22, top_clip + 6.0),
				Vector2(cx - 5.0, cy - 3.0),
				Vector2(cx + 6.0, cy + 5.0),
				Vector2(w * 0.72, h - 8.0),
			])
			canvas.draw_polyline(ice_crack, Color(0.75, 0.96, 1.0, 0.36 * a), 1.2, true)
			canvas.draw_line(Vector2(cx - 5.0, cy - 3.0), Vector2(w * 0.26, h - 10.0), Color(0.50, 0.88, 1.0, 0.28 * a), 1.0)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(4.0, top_clip + 4.0), Vector2(14.0, top_clip + 4.0), Vector2(4.0, top_clip + 14.0)]), Color(0.65, 0.92, 1.0, 0.24 * a))
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(w - 4.0, top_clip + 4.0), Vector2(w - 14.0, top_clip + 4.0), Vector2(w - 4.0, top_clip + 14.0)]), Color(0.65, 0.92, 1.0, 0.24 * a))
		3: # Curved living forest vines with small leaves creeping across mossy stone
			canvas.draw_rect(inset, Color(0.18, 0.62, 0.35, 0.32 * a), false, 1.3)
			var vpts := PackedVector2Array([
				Vector2(4.0, top_clip + body_h * 0.26),
				Vector2(w * 0.32, top_clip + body_h * 0.44),
				Vector2(w * 0.66, top_clip + body_h * 0.34),
				Vector2(w - 4.0, top_clip + body_h * 0.64),
			])
			canvas.draw_polyline(vpts, Color(0.08, 0.38, 0.20, 0.75 * a), 3.0, true)
			canvas.draw_polyline(vpts, Color(0.28, 0.85, 0.46, 0.55 * a), 1.2, true)
			var l1 := vpts[1]
			var l2 := vpts[2]
			canvas.draw_colored_polygon(PackedVector2Array([l1, l1 + Vector2(-5.0, -5.0), l1 + Vector2(2.0, -6.0)]), Color(0.16, 0.68, 0.34, 0.72 * a))
			canvas.draw_colored_polygon(PackedVector2Array([l2, l2 + Vector2(5.0, 5.0), l2 + Vector2(-2.0, 6.0)]), Color(0.16, 0.68, 0.34, 0.72 * a))
		4: # Carved ancient desert temple brackets & strata
			canvas.draw_rect(inset, Color(0.95, 0.75, 0.28, 0.36 * a), false, 1.5)
			canvas.draw_rect(Rect2(8.0, top_clip + 8.0, maxf(2.0, w - 16.0), maxf(2.0, body_h - 16.0)), Color(0.85, 0.55, 0.14, 0.24 * a), false, 1.0)
			canvas.draw_line(Vector2(6.0, top_clip + body_h * 0.50), Vector2(w - 6.0, top_clip + body_h * 0.50), Color(0.95, 0.72, 0.24, 0.30 * a), 1.2)
		5: # Forked glowing molten basalt fissures
			canvas.draw_rect(inset, Color(0.96, 0.32, 0.08, 0.36 * a), false, 1.4)
			var cx := w * 0.5
			var cy := top_clip + body_h * 0.5
			var lava_pts := PackedVector2Array([
				Vector2(cx - w * 0.28, top_clip + 6.0),
				Vector2(cx - w * 0.08, cy - 5.0),
				Vector2(cx + w * 0.06, cy + 4.0),
				Vector2(cx + w * 0.24, h - 6.0),
			])
			canvas.draw_polyline(lava_pts, Color(0.96, 0.26, 0.05, 0.45 * a), 4.0, true)
			canvas.draw_polyline(lava_pts, Color(0.99, 0.54, 0.10, 0.78 * a), 1.8, true)
			canvas.draw_line(lava_pts[1], Vector2(cx + w * 0.24, top_clip + body_h * 0.30), Color(0.99, 0.48, 0.10, 0.62 * a), 1.3)
		_: # Ch 1: Gothic chamfered iron frame & 4 corner rivets
			canvas.draw_rect(inset, Color(0.42, 0.48, 0.60, 0.28 * a), false, 1.2)
			var rv := Color(0.55, 0.62, 0.74, 0.42 * a)
			canvas.draw_circle(Vector2(8.0, top_clip + 8.0), 1.6, rv)
			canvas.draw_circle(Vector2(w - 8.0, top_clip + 8.0), 1.6, rv)
			if body_h > 24.0:
				canvas.draw_circle(Vector2(8.0, h - 8.0), 1.6, rv)
				canvas.draw_circle(Vector2(w - 8.0, h - 8.0), 1.6, rv)

# ==============================================================================
# 6. SPRING LAUNCHER (Hidden when Idle — Biome-Authentic Eruption)
# ==============================================================================

static func draw_spring_mechanism(canvas: CanvasItem, w: float, extension: float, ch: int) -> void:
	if extension <= 1.0:
		return
	var h := extension
	var y_top := -h
	var base_col := get_base_color(ch)

	# Floor-anchored socket base
	canvas.draw_rect(Rect2(0.0, -3.0, w, 4.0), base_col, true)

	if ch == 2:
		# Ch 2: Glacial Ice-Crystal Piston Geyser
		var coils := 4
		var coil_h := maxf(2.0, (h - 6.0) / float(coils))
		for i in range(coils):
			var cy0 := -3.0 - float(i) * coil_h
			var cy1 := cy0 - coil_h * 0.5
			var cy2 := cy0 - coil_h
			canvas.draw_line(Vector2(5.0, cy0), Vector2(w - 5.0, cy1), Color("#38bdf8"), 2.6)
			canvas.draw_line(Vector2(w - 5.0, cy1), Vector2(5.0, cy2), Color("#bae6fd"), 2.2)
		# Frosted glacier launch slab
		canvas.draw_rect(Rect2(1.0, y_top - 6.0, w - 2.0, 6.5), Color("#0ea5e9"), true)
		canvas.draw_rect(Rect2(2.0, y_top - 6.0, w - 4.0, 3.0), Color("#f0f9ff"), true)
		canvas.draw_line(Vector2(2.0, y_top), Vector2(w - 2.0, y_top), Color("#0369a1"), 1.2)
	elif ch == 3:
		# Ch 3: Elastic Coiled Living Vines + Springy Mossy Mushroom Cap
		var segs := 10
		var vine_l := PackedVector2Array()
		var vine_r := PackedVector2Array()
		for i in range(segs + 1):
			var t := float(i) / float(segs)
			var cy := -3.0 - t * maxf(2.0, h - 6.0)
			var amp := (w * 0.34)
			var cx := w * 0.5
			vine_l.append(Vector2(cx + sin(t * PI * 4.0) * amp, cy))
			vine_r.append(Vector2(cx - sin(t * PI * 4.0) * amp, cy))
		canvas.draw_polyline(vine_l, Color("#15803d"), 2.8, true)
		canvas.draw_polyline(vine_r, Color("#22c55e"), 2.2, true)
		# Curved mossy/mushroom cap pad
		var cap := PackedVector2Array([
			Vector2(0.0, y_top + 1.0),
			Vector2(w * 0.16, y_top - 6.0),
			Vector2(w * 0.50, y_top - 8.0),
			Vector2(w * 0.84, y_top - 6.0),
			Vector2(w, y_top + 1.0),
		])
		canvas.draw_colored_polygon(cap, Color("#16a34a"))
		canvas.draw_polyline(cap, Color("#86efac", 0.90), 1.3, true)
		canvas.draw_circle(Vector2(w * 0.34, y_top - 4.0), 1.8, Color("#dcfce7"))
		canvas.draw_circle(Vector2(w * 0.66, y_top - 3.5), 1.5, Color("#dcfce7"))
	elif ch == 4:
		# Ch 4: Ancient Gilded Bronze Temple Piston
		var coils := 4
		var coil_h := maxf(2.0, (h - 6.0) / float(coils))
		for i in range(coils):
			var cy0 := -3.0 - float(i) * coil_h
			var cy1 := cy0 - coil_h * 0.5
			var cy2 := cy0 - coil_h
			canvas.draw_line(Vector2(4.0, cy0), Vector2(w - 4.0, cy1), Color("#d97706"), 2.6)
			canvas.draw_line(Vector2(w - 4.0, cy1), Vector2(4.0, cy2), Color("#92400e"), 2.4)
		# Sun-etched gold launch plate
		canvas.draw_rect(Rect2(1.5, y_top - 6.0, w - 3.0, 6.0), Color("#b45309"), true)
		canvas.draw_rect(Rect2(2.5, y_top - 6.0, w - 5.0, 2.5), Color("#fcd34d"), true)
		canvas.draw_rect(Rect2(w * 0.5 - 3.0, y_top - 4.5, 6.0, 3.0), Color("#fef3c7"), true)
	elif ch == 5:
		# Ch 5: Superheated Volcanic Magma Piston
		var coils := 4
		var coil_h := maxf(2.0, (h - 6.0) / float(coils))
		for i in range(coils):
			var cy0 := -3.0 - float(i) * coil_h
			var cy1 := cy0 - coil_h * 0.5
			var cy2 := cy0 - coil_h
			canvas.draw_line(Vector2(4.0, cy0), Vector2(w - 4.0, cy1), Color("#ea580c"), 2.6)
			canvas.draw_line(Vector2(w - 4.0, cy1), Vector2(4.0, cy2), Color("#991b1b"), 2.4)
		# Fiery obsidian-magma launch plate
		canvas.draw_rect(Rect2(1.0, y_top - 6.5, w - 2.0, 6.5), Color("#450a0a"), true)
		canvas.draw_rect(Rect2(2.5, y_top - 6.0, w - 5.0, 3.0), Color("#ef4444"), true)
		canvas.draw_rect(Rect2(5.0, y_top - 5.5, w - 10.0, 1.6), Color("#fef08a"), true)
	else:
		# Ch 1: Sleek Gothic Forged Iron Coil + Warm Lantern-Amber Plate
		var coils := 4
		var coil_h := maxf(2.0, (h - 6.0) / float(coils))
		for i in range(coils):
			var cy0 := -3.0 - float(i) * coil_h
			var cy1 := cy0 - coil_h * 0.5
			var cy2 := cy0 - coil_h
			canvas.draw_line(Vector2(4.0, cy0), Vector2(w - 4.0, cy1), Color("#64748b"), 2.4)
			canvas.draw_line(Vector2(w - 4.0, cy1), Vector2(4.0, cy2), Color("#334155"), 2.4)
		canvas.draw_rect(Rect2(2.0, y_top - 5.5, w - 4.0, 6.0), Color("#f59e0b"), true)
		canvas.draw_rect(Rect2(4.0, y_top - 5.5, w - 8.0, 2.0), Color("#fef08a"), true)

# ==============================================================================
# 7. BIOME ENERGY / HAZARD BEAM (LaserBeamTrap)
# ==============================================================================

static func draw_laser_hazard(
	canvas: CanvasItem,
	beam_length: float,
	is_vertical: bool,
	is_active: bool,
	pulse_phase: float,
	charge_ratio: float,
	ch: int
) -> void:
	var pal := get_palette(ch)
	var end_pt := Vector2(0.0, beam_length) if is_vertical else Vector2(beam_length, 0.0)
	var perp := Vector2(1.0, 0.0) if is_vertical else Vector2(0.0, 1.0)
	var dir := Vector2(0.0, 1.0) if is_vertical else Vector2(1.0, 0.0)

	# 1. Biome-crafted emitter housing
	var base_col: Color = pal["base"]
	var hi_col: Color = pal["base_hi"]
	if ch == 2:
		# Faceted Ice Crystal Emitter
		var crystal := PackedVector2Array([
			-perp * 9.0 - dir * 4.0,
			perp * 9.0 - dir * 4.0,
			perp * 6.5 + dir * 6.0,
			dir * 10.5,
			-perp * 6.5 + dir * 6.0,
		])
		canvas.draw_colored_polygon(crystal, Color("#0f172a"))
		canvas.draw_polyline(crystal, Color("#7dd3fc", 0.85), 1.4, true)
	elif ch == 3:
		# Mossy Forest Spore Pod Emitter
		canvas.draw_circle(Vector2.ZERO, 9.5, Color("#062319"))
		canvas.draw_circle(Vector2.ZERO, 6.5, Color("#14532d"))
		# Small flanking leaf sepals
		canvas.draw_colored_polygon(PackedVector2Array([-perp * 6.0, -perp * 12.0 + dir * 4.0, -perp * 3.0 + dir * 6.0]), Color("#166534"))
		canvas.draw_colored_polygon(PackedVector2Array([perp * 6.0, perp * 12.0 + dir * 4.0, perp * 3.0 + dir * 6.0]), Color("#166534"))
	elif ch == 4:
		# Gilded Desert Sun-Mirror Sconce
		var box := PackedVector2Array([
			-perp * 9.5 - dir * 5.0,
			perp * 9.5 - dir * 5.0,
			perp * 7.5 + dir * 7.0,
			-perp * 7.5 + dir * 7.0,
		])
		canvas.draw_colored_polygon(box, Color("#291c14"))
		canvas.draw_polyline(box, Color("#d97706"), 1.6, true)
	elif ch == 5:
		# Volcanic Obsidian Furnace Vent Nozzle
		var vent := PackedVector2Array([
			-perp * 10.0 - dir * 4.0,
			perp * 10.0 - dir * 4.0,
			perp * 6.5 + dir * 8.0,
			-perp * 6.5 + dir * 8.0,
		])
		canvas.draw_colored_polygon(vent, Color("#1a0505"))
		canvas.draw_polyline(vent, Color("#ea580c", 0.85), 1.5, true)
	else:
		# Ch 1: Gothic Carved Stone Sconce
		canvas.draw_circle(Vector2.ZERO, 9.2, base_col)
		canvas.draw_circle(Vector2.ZERO, 6.0, hi_col)
		canvas.draw_arc(Vector2.ZERO, 9.2, 0.0, TAU, 20, Color("#475569", 0.70), 1.2, true)

	# 2. Beam colors per biome
	var glow_col := Color(1.0, 0.20, 0.30, 0.36)
	var core_col := Color(1.0, 0.42, 0.50, 0.82)
	var em_col := Color("#ef4444")
	var white_core := Color(1.0, 0.96, 0.96, 0.95)
	if ch == 2:
		glow_col = Color(0.18, 0.78, 1.0, 0.38)
		core_col = Color(0.45, 0.92, 1.0, 0.86)
		em_col = Color("#38bdf8")
		white_core = Color(0.94, 0.99, 1.0, 0.96)
	elif ch == 3:
		glow_col = Color(0.22, 0.95, 0.42, 0.36)
		core_col = Color(0.45, 1.0, 0.56, 0.84)
		em_col = Color("#22c55e")
		white_core = Color(0.88, 1.0, 0.90, 0.92)
	elif ch == 4:
		glow_col = Color(1.0, 0.74, 0.16, 0.38)
		core_col = Color(1.0, 0.88, 0.40, 0.86)
		em_col = Color("#f59e0b")
		white_core = Color(1.0, 0.98, 0.86, 0.96)
	elif ch == 5:
		glow_col = Color(1.0, 0.32, 0.06, 0.44)
		core_col = Color(1.0, 0.56, 0.14, 0.90)
		em_col = Color("#f97316")
		white_core = Color(1.0, 0.96, 0.72, 0.98)

	if is_active:
		var glow_w := 10.5 + sin(pulse_phase) * 2.2
		canvas.draw_line(Vector2.ZERO, end_pt, glow_col, glow_w)
		canvas.draw_line(Vector2.ZERO, end_pt, core_col, 4.2)

		# Biome-specific animated inner filament along the beam
		if ch == 2 or ch == 3 or ch == 5:
			var segs := maxi(6, int(beam_length / 22.0))
			var wave_pts := PackedVector2Array()
			var amp := 2.4 if ch == 3 else (2.0 if ch == 5 else 1.8)
			var freq := 0.16 if ch == 3 else 0.24
			for i in range(segs + 1):
				var t := float(i) / float(segs)
				var along := t * beam_length
				var env := sin(t * PI)
				var w_off := sin(along * freq - pulse_phase * 1.4) * amp * env
				wave_pts.append(dir * along + perp * w_off)
			canvas.draw_polyline(wave_pts, white_core, 1.7, true)
		else:
			canvas.draw_line(Vector2.ZERO, end_pt, white_core, 1.6)

		# Impact flare at beam tip & bright emitter core
		canvas.draw_circle(end_pt, 5.2 + sin(pulse_phase * 1.5) * 1.2, glow_col)
		canvas.draw_circle(end_pt, 2.2, white_core)
		canvas.draw_circle(Vector2.ZERO, 4.5, em_col)
		canvas.draw_circle(Vector2.ZERO, 2.0, white_core)
	else:
		var warn := clampf(charge_ratio, 0.0, 1.0)
		var idle_a := lerpf(0.14, 0.42, warn)
		canvas.draw_line(Vector2.ZERO, end_pt, Color(glow_col.r, glow_col.g, glow_col.b, idle_a), lerpf(1.8, 3.0, warn))
		canvas.draw_circle(Vector2.ZERO, lerpf(3.0, 4.8, warn), Color(em_col.r, em_col.g, em_col.b, lerpf(0.38, 0.90, warn)))
