extends Control
class_name BiomeTransitionPass

# Wrong Way - High-Fantasy Biome Mountain Pass
# Atmospheric mountain pass connecting distinct climate chapters (Forest -> Winter Snow -> Green Forest)
# 6 Cinematic Parallax Layers:
# 1. CanyonBackdrop: Hand-painted styled canyon chasm, distant alpine peaks, and natural rocky mountain ridges
# 2. MistBack: Deep volumetric mist billows in the abyss behind the viaduct
# 3. BridgeAndPillars: Ancient stone viaduct bridge with climate accumulation, monolithic guardian pillars & runic lanterns
# 4. MistFront: Gentle wisps of luminous cloud drifting across the bridge and gorge
# 5. AtmosphericMotes: Drifting snowflakes or floating forest embers/spores
# 6. GateLockCard: Floating obsidian glass badge when the next chapter is locked

@export var pass_index: int = 1 # 1: Forest -> Snow, 2: Snow -> Green Forest

var backdrop_node: Control
var mist_back: ColorRect
var bridge_node: Control
var mist_front: ColorRect
var particles: CPUParticles2D
var lock_card: PanelContainer

var is_unlocked: bool = false
var glow_phase: float = 0.0

const PASS_WIDTH: float = 240.0
const PASS_HEIGHT: float = 540.0

const ROAD_START: Vector2 = Vector2(0, 230)
const ROAD_END: Vector2 = Vector2(240, 192)

func _ready() -> void:
	custom_minimum_size = Vector2(PASS_WIDTH, PASS_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_setup_backdrop()
	_setup_mist_layers()
	_setup_particles()
	_setup_lock_card()
	update_state()

func _process(delta: float) -> void:
	glow_phase += delta * 2.5
	if bridge_node:
		bridge_node.queue_redraw()

func _setup_backdrop() -> void:
	backdrop_node = Control.new()
	backdrop_node.name = "CanyonBackdrop"
	backdrop_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop_node.draw.connect(_on_backdrop_draw)
	add_child(backdrop_node)

func _setup_mist_layers() -> void:
	var shader = preload("res://shaders/fog_transition.gdshader")
	
	# Layer 2: Deep background mist behind bridge (centered in gorge, does not obscure level buttons)
	mist_back = ColorRect.new()
	mist_back.name = "MistBack"
	mist_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mist_back.position = Vector2(-45.0, 0.0)
	mist_back.size = Vector2(PASS_WIDTH + 90.0, PASS_HEIGHT)
	
	var mat_back = ShaderMaterial.new()
	mat_back.shader = shader
	_apply_mist_colors(mat_back, 1.15, 0.045, 0.75)
	mist_back.material = mat_back
	add_child(mist_back)
	
	# Layer 3: Bridge & Guardian Pillars
	bridge_node = Control.new()
	bridge_node.name = "BridgeAndPillars"
	bridge_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bridge_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bridge_node.draw.connect(_on_bridge_draw)
	add_child(bridge_node)
	
	# Layer 4: Foreground soft drifting wisps in front of bridge
	mist_front = ColorRect.new()
	mist_front.name = "MistFront"
	mist_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mist_front.position = Vector2(-35.0, 0.0)
	mist_front.size = Vector2(PASS_WIDTH + 70.0, PASS_HEIGHT)
	
	var mat_front = ShaderMaterial.new()
	mat_front.shader = shader
	_apply_mist_colors(mat_front, 0.75, 0.070, 0.85)
	mist_front.material = mat_front
	add_child(mist_front)

func _apply_mist_colors(mat: ShaderMaterial, density_val: float, speed_val: float, edge_exp: float) -> void:
	mat.set_shader_parameter("density", density_val)
	mat.set_shader_parameter("speed", speed_val)
	mat.set_shader_parameter("edge_fade_exp", edge_exp)
	if pass_index == 1:
		mat.set_shader_parameter("fog_color_left", Color(0.68, 0.76, 0.88, 0.75))
		mat.set_shader_parameter("fog_color_right", Color(0.88, 0.94, 1.00, 0.85))
		mat.set_shader_parameter("glow_color", Color(0.55, 0.82, 1.00, 0.45))
	else:
		mat.set_shader_parameter("fog_color_left", Color(0.85, 0.92, 1.00, 0.75))
		mat.set_shader_parameter("fog_color_right", Color(0.62, 0.88, 0.70, 0.80))
		mat.set_shader_parameter("glow_color", Color(0.48, 0.95, 0.65, 0.40))

func _setup_particles() -> void:
	particles = CPUParticles2D.new()
	particles.name = "AtmosphericMotes"
	particles.position = Vector2(PASS_WIDTH * 0.5, 0)
	particles.amount = 26
	particles.lifetime = 4.2
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(PASS_WIDTH * 0.45, 10.0)
	
	if pass_index == 1:
		# Snowflakes drifting gently from cold snow peaks into forest
		particles.direction = Vector2(-0.40, 1.0)
		particles.spread = 22.0
		particles.gravity = Vector2(0, 14)
		particles.initial_velocity_min = 25.0
		particles.initial_velocity_max = 48.0
		particles.scale_amount_min = 2.0
		particles.scale_amount_max = 3.8
		particles.color = Color(0.92, 0.96, 1.0, 0.78)
	else:
		# Floating emerald spores & summer embers rising
		particles.position = Vector2(PASS_WIDTH * 0.5, PASS_HEIGHT)
		particles.direction = Vector2(-0.20, -1.0)
		particles.spread = 30.0
		particles.gravity = Vector2(0, -8)
		particles.initial_velocity_min = 18.0
		particles.initial_velocity_max = 38.0
		particles.scale_amount_min = 1.8
		particles.scale_amount_max = 3.2
		particles.color = Color(0.65, 1.0, 0.75, 0.70)
		
	add_child(particles)

func _setup_lock_card() -> void:
	lock_card = PanelContainer.new()
	lock_card.name = "GateLockCard"
	var card_w: float = 210.0
	var card_h: float = 68.0
	lock_card.custom_minimum_size = Vector2(card_w, card_h)
	lock_card.size = Vector2(card_w, card_h)
	lock_card.position = Vector2((PASS_WIDTH - card_w) * 0.5, 95.0)
	lock_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.14, 0.94)
	style.border_color = Color(0.40, 0.52, 0.75, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0, 0, 0, 0.70)
	style.shadow_size = 12
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	lock_card.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_card.add_child(vbox)
	
	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hbox)
	
	var lock_icon := IconFactory.create_texture_rect("lock", Vector2(16, 16), 0.8)
	lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(lock_icon)
	
	var lbl_title := Label.new()
	lbl_title.name = "Title"
	lbl_title.add_theme_font_size_override("font_size", 12)
	lbl_title.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	lbl_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(lbl_title)
	
	var lbl_sub := Label.new()
	lbl_sub.name = "Sub"
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.add_theme_font_size_override("font_size", 9)
	lbl_sub.add_theme_color_override("font_color", Color(0.68, 0.75, 0.88))
	lbl_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl_sub)
	
	add_child(lock_card)

func update_state() -> void:
	if pass_index == 1:
		is_unlocked = SaveManager.is_chapter_unlocked(2)
	else:
		is_unlocked = SaveManager.is_chapter_unlocked(3)
		
	if lock_card:
		lock_card.visible = not is_unlocked
		var lbl_title: Label = lock_card.get_node_or_null("VBox/HBox/Title")
		var lbl_sub: Label = lock_card.get_node_or_null("VBox/Sub")
		if pass_index == 1:
			if lbl_title: lbl_title.text = "2-BOB QULFLANGAN"
			if lbl_sub: lbl_sub.text = "1-bobni (20-darajani) yakunlang"
		else:
			if lbl_title: lbl_title.text = "3-BOB QULFLANGAN"
			if lbl_sub: lbl_sub.text = "2-bobni (40-darajani) yakunlang"
			
	if backdrop_node:
		backdrop_node.queue_redraw()
	if bridge_node:
		bridge_node.queue_redraw()

func _on_backdrop_draw() -> void:
	if not backdrop_node: return
	
	# 1. Distant mountain peaks in the chasm (soft misty silhouettes)
	var peak_pts_far := PackedVector2Array([
		Vector2(20, 240), Vector2(70, 150), Vector2(115, 195),
		Vector2(160, 130), Vector2(205, 185), Vector2(250, 140),
		Vector2(270, 250), Vector2(270, 320), Vector2(20, 320)
	])
	backdrop_node.draw_colored_polygon(peak_pts_far, Color(0.10, 0.14, 0.22, 0.55))
	
	# Mid-ground alpine ridges
	var peak_pts_mid := PackedVector2Array([
		Vector2(45, 270), Vector2(95, 175), Vector2(140, 220),
		Vector2(185, 165), Vector2(225, 240), Vector2(225, 340), Vector2(45, 340)
	])
	var mid_col := Color(0.13, 0.18, 0.26, 0.70) if pass_index == 1 else Color(0.08, 0.16, 0.12, 0.70)
	backdrop_node.draw_colored_polygon(peak_pts_mid, mid_col)
	
	# 3. Left Mountain Ridge (Seamlessly blends from Chapter 1's dark forest)
	var left_cliff := PackedVector2Array([
		Vector2(-20, 0), Vector2(70, 0),
		Vector2(55, 75), Vector2(78, 150),
		Vector2(50, 225), Vector2(75, 320),
		Vector2(45, 410), Vector2(68, 490), Vector2(55, 540), Vector2(-20, 540)
	])
	backdrop_node.draw_colored_polygon(left_cliff, Color(0.07, 0.09, 0.14, 1.0))
	
	# Cliff ledge shading lines
	backdrop_node.draw_line(Vector2(70, 0), Vector2(55, 75), Color(0.16, 0.22, 0.30, 0.75), 2.0)
	backdrop_node.draw_line(Vector2(55, 75), Vector2(78, 150), Color(0.16, 0.22, 0.30, 0.75), 2.0)
	backdrop_node.draw_line(Vector2(78, 150), Vector2(50, 225), Color(0.16, 0.22, 0.30, 0.75), 2.0)
	backdrop_node.draw_line(Vector2(50, 225), Vector2(75, 320), Color(0.16, 0.22, 0.30, 0.75), 2.0)
	backdrop_node.draw_line(Vector2(75, 320), Vector2(45, 410), Color(0.16, 0.22, 0.30, 0.75), 2.0)
	
	# Pine tree silhouettes on left ridge
	_draw_pine_tree(backdrop_node, Vector2(50, 70), 16, Color(0.05, 0.07, 0.10, 0.90))
	_draw_pine_tree(backdrop_node, Vector2(65, 145), 20, Color(0.05, 0.07, 0.10, 0.90))
	_draw_pine_tree(backdrop_node, Vector2(60, 315), 18, Color(0.05, 0.07, 0.10, 0.90))
	
	# 4. Right Mountain Ridge (Seamlessly blends into Chapter 2 snow or Chapter 3 forest)
	var right_cliff := PackedVector2Array([
		Vector2(260, 0), Vector2(170, 0),
		Vector2(190, 75), Vector2(162, 150),
		Vector2(192, 225), Vector2(165, 320),
		Vector2(195, 410), Vector2(172, 490), Vector2(185, 540), Vector2(260, 540)
	])
	var right_cliff_col := Color(0.12, 0.18, 0.26, 1.0) if pass_index == 1 else Color(0.07, 0.15, 0.10, 1.0)
	backdrop_node.draw_colored_polygon(right_cliff, right_cliff_col)
	
	var r_edge_col := Color(0.28, 0.38, 0.50, 0.75) if pass_index == 1 else Color(0.15, 0.32, 0.18, 0.75)
	backdrop_node.draw_line(Vector2(170, 0), Vector2(190, 75), r_edge_col, 2.0)
	backdrop_node.draw_line(Vector2(190, 75), Vector2(162, 150), r_edge_col, 2.0)
	backdrop_node.draw_line(Vector2(162, 150), Vector2(192, 225), r_edge_col, 2.0)
	backdrop_node.draw_line(Vector2(192, 225), Vector2(165, 320), r_edge_col, 2.0)
	
	# Natural organic snow drift slopes (Pass 1)
	if pass_index == 1:
		var snow_top := PackedVector2Array([
			Vector2(260, 0), Vector2(170, 0), Vector2(180, 40),
			Vector2(210, 60), Vector2(260, 50)
		])
		backdrop_node.draw_colored_polygon(snow_top, Color(0.85, 0.92, 0.98, 0.85))
		
		# Snow-dusted pine on right
		_draw_pine_tree(backdrop_node, Vector2(185, 68), 18, Color(0.18, 0.24, 0.32, 0.90))
		_draw_pine_tree(backdrop_node, Vector2(175, 220), 20, Color(0.18, 0.24, 0.32, 0.90))
	else:
		# Lush moss & foliage on right (Pass 2)
		var moss_top := PackedVector2Array([
			Vector2(260, 0), Vector2(170, 0), Vector2(182, 45),
			Vector2(215, 65), Vector2(260, 52)
		])
		backdrop_node.draw_colored_polygon(moss_top, Color(0.16, 0.38, 0.20, 0.85))
		
		_draw_pine_tree(backdrop_node, Vector2(185, 68), 18, Color(0.10, 0.26, 0.14, 0.90))
		_draw_pine_tree(backdrop_node, Vector2(175, 220), 20, Color(0.12, 0.30, 0.16, 0.90))

func _draw_pine_tree(target: Control, pos: Vector2, height: float, col: Color) -> void:
	var w: float = height * 0.42
	var pts := PackedVector2Array([
		Vector2(pos.x, pos.y - height),
		Vector2(pos.x + w, pos.y),
		Vector2(pos.x - w, pos.y)
	])
	target.draw_colored_polygon(pts, col)
	var pts2 := PackedVector2Array([
		Vector2(pos.x, pos.y - height * 0.60),
		Vector2(pos.x + w * 1.2, pos.y + height * 0.30),
		Vector2(pos.x - w * 1.2, pos.y + height * 0.30)
	])
	target.draw_colored_polygon(pts2, col)

func _on_bridge_draw() -> void:
	if not bridge_node: return
	
	# 1. Ancient Stone Viaduct Bridge
	var p0 := ROAD_START
	var p1 := Vector2(120, 222)
	var p2 := ROAD_END
	
	var road_w: float = 24.0
	
	# Calculate curve points spanning slightly beyond [0, 240] so ends anchor into rock cliffs
	var steps: int = 30
	var pts_top: Array[Vector2] = []
	var pts_bot: Array[Vector2] = []
	
	for i in range(steps + 1):
		# t from -0.08 to 1.08 (extends into adjacent cliffs seamlessly)
		var t: float = lerp(-0.08, 1.08, float(i) / float(steps))
		var pt := (1.0 - t) * (1.0 - t) * p0 + 2.0 * (1.0 - t) * t * p1 + t * t * p2
		pts_top.append(pt - Vector2(0, road_w * 0.5))
		pts_bot.append(pt + Vector2(0, road_w * 0.5))
		
	# Stone masonry support arches under the bridge
	var arch_pts := PackedVector2Array([
		Vector2(55, 228), Vector2(85, 260), Vector2(120, 282), Vector2(155, 252), Vector2(185, 210)
	])
	for i in range(arch_pts.size() - 1):
		bridge_node.draw_line(arch_pts[i], arch_pts[i + 1], Color(0.16, 0.20, 0.28, 0.90), 5.0)
		
	# Foundation piers descending into the deep gorge mist
	bridge_node.draw_line(Vector2(85, 260), Vector2(85, 335), Color(0.12, 0.15, 0.22, 0.80), 5.5)
	bridge_node.draw_line(Vector2(155, 252), Vector2(155, 330), Color(0.12, 0.15, 0.22, 0.80), 5.5)
	
	# Bridge underside depth polygon
	var deck_poly := PackedVector2Array()
	for pt in pts_top: deck_poly.append(pt)
	for i in range(pts_bot.size() - 1, -1, -1): deck_poly.append(pts_bot[i] + Vector2(0, 6.0))
	bridge_node.draw_colored_polygon(deck_poly, Color(0.09, 0.11, 0.16, 0.98))
	
	# Bridge road surface (matches dark stone road in map art)
	var road_poly := PackedVector2Array()
	for pt in pts_top: road_poly.append(pt)
	for i in range(pts_bot.size() - 1, -1, -1): road_poly.append(pts_bot[i])
	bridge_node.draw_colored_polygon(road_poly, Color(0.15, 0.18, 0.25, 1.0))
	
	# Subtle stone paving flagstone lines across the road
	for i in range(2, steps - 1, 3):
		bridge_node.draw_line(pts_top[i], pts_bot[i], Color(0.11, 0.13, 0.18, 0.65), 1.0)
	
	# Guardrail edges (stone coping)
	for i in range(steps):
		bridge_node.draw_line(pts_top[i], pts_top[i + 1], Color(0.35, 0.44, 0.58, 0.92), 1.8)
		bridge_node.draw_line(pts_bot[i], pts_bot[i + 1], Color(0.11, 0.14, 0.20, 0.95), 2.0)
		
	# Climate Transition accumulation on bridge:
	if pass_index == 1:
		# Snow accumulation on the right half of the bridge
		var snow_start := int(steps * 0.45)
		for i in range(snow_start, steps):
			var frac := float(i - snow_start) / float(steps - snow_start)
			var snow_alpha := 0.20 + 0.70 * frac
			bridge_node.draw_line(pts_top[i] - Vector2(0, 1.0), pts_top[i + 1] - Vector2(0, 1.0), Color(0.88, 0.94, 1.0, snow_alpha), 2.0)
			if i % 2 == 0:
				bridge_node.draw_line(pts_bot[i] - Vector2(0, 2.0), pts_bot[i + 1] - Vector2(0, 2.0), Color(0.82, 0.90, 0.98, snow_alpha * 0.5), 2.2)
	else:
		# Green moss & flora on the right half of the bridge
		var moss_start := int(steps * 0.45)
		for i in range(moss_start, steps):
			var frac := float(i - moss_start) / float(steps - moss_start)
			var moss_alpha := 0.25 + 0.70 * frac
			bridge_node.draw_line(pts_top[i] - Vector2(0, 1.0), pts_top[i + 1] - Vector2(0, 1.0), Color(0.24, 0.52, 0.28, moss_alpha), 2.0)
			if i % 3 == 0:
				bridge_node.draw_circle(pts_top[i] - Vector2(0, 2.0), 2.0, Color(0.38, 0.82, 0.42, moss_alpha))
		
	# Weathered dashed ivory centerline on the bridge (matching map artwork)
	for i in range(1, steps - 1, 2):
		var t_mid: float = lerp(-0.08, 1.08, (float(i) + 0.4) / float(steps))
		var center_pt := (1.0 - t_mid) * (1.0 - t_mid) * p0 + 2.0 * (1.0 - t_mid) * t_mid * p1 + t_mid * t_mid * p2
		var t_next: float = lerp(-0.08, 1.08, (float(i) + 1.2) / float(steps))
		var next_pt := (1.0 - t_next) * (1.0 - t_next) * p0 + 2.0 * (1.0 - t_next) * t_next * p1 + t_next * t_next * p2
		bridge_node.draw_line(center_pt, next_pt, Color(0.86, 0.90, 0.96, 0.50), 1.5)
		
	# 2. Guardian Monolith Pillars at x = 120
	var gx: float = 120.0
	var gy: float = 210.0
	
	# Left Pillar
	bridge_node.draw_rect(Rect2(gx - 32, gy - 65, 12, 60), Color(0.14, 0.18, 0.25, 0.98))
	bridge_node.draw_rect(Rect2(gx - 34, gy - 70, 16, 6), Color(0.26, 0.34, 0.46, 0.98))
	
	# Right Pillar
	var r_col := Color(0.20, 0.26, 0.36, 0.98) if pass_index == 1 else Color(0.12, 0.22, 0.16, 0.98)
	bridge_node.draw_rect(Rect2(gx + 20, gy - 75, 12, 60), r_col)
	bridge_node.draw_rect(Rect2(gx + 18, gy - 80, 16, 6), Color(0.75, 0.86, 0.96, 0.98) if pass_index == 1 else Color(0.26, 0.38, 0.28, 0.98))
	
	# Connecting lintel arch
	var lintel := PackedVector2Array([
		Vector2(gx - 34, gy - 70), Vector2(gx + 34, gy - 80),
		Vector2(gx + 34, gy - 74), Vector2(gx - 34, gy - 64)
	])
	bridge_node.draw_colored_polygon(lintel, Color(0.22, 0.30, 0.42, 0.98))
	
	# Glowing runic lanterns / crystals
	var pulse: float = 0.78 + 0.22 * sin(glow_phase)
	var lantern_color := Color(0.35, 0.80, 1.0, 0.95 * pulse) if pass_index == 1 else Color(0.35, 0.95, 0.60, 0.95 * pulse)
	if not is_unlocked:
		lantern_color = Color(0.95, 0.75, 0.25, 0.95 * pulse)
		
	# Left lantern
	bridge_node.draw_circle(Vector2(gx - 26, gy - 40), 4.5, lantern_color)
	bridge_node.draw_circle(Vector2(gx - 26, gy - 40), 12.0, Color(lantern_color.r, lantern_color.g, lantern_color.b, 0.30 * pulse))
	
	# Right lantern
	bridge_node.draw_circle(Vector2(gx + 26, gy - 50), 4.5, lantern_color)
	bridge_node.draw_circle(Vector2(gx + 26, gy - 50), 12.0, Color(lantern_color.r, lantern_color.g, lantern_color.b, 0.30 * pulse))
	
	# Warding magical energy barrier when locked
	if not is_unlocked:
		var barrier_poly := PackedVector2Array([
			Vector2(gx - 20, gy - 65), Vector2(gx + 20, gy - 75),
			Vector2(gx + 20, gy), Vector2(gx - 20, gy)
		])
		bridge_node.draw_colored_polygon(barrier_poly, Color(0.95, 0.70, 0.20, 0.20 * pulse))
		bridge_node.draw_line(Vector2(gx - 20, gy - 65), Vector2(gx + 20, gy - 75), Color(0.95, 0.80, 0.30, 0.70 * pulse), 1.5)
