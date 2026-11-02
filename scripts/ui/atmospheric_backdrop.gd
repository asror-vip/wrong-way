extends Control

# Wrong Way - Atmospheric Backdrop
# Renders authentic Limbo/Badland landscape art from assets/images:
# - home-img.png for UI interfaces (Main Menu, Level Select, Editor)
# - assets/images/chapter_1/*.png for Chapter 1 gameplay
# - Cold winter sky with active snowfall for Chapter 2 gameplay (no map images)
# - Supports Cinematic Bokeh Blur to separate background from foreground physics

@export var show_menu_cliff: bool = false
@export var show_particles: bool = true
@export var is_ui_background: bool = false
@export var is_map_background: bool = false
@export var blur_amount: float = 0.0

const UI_BG_PATH := "res://assets/images/home-img.png"

const GAMEPLAY_BG_PATHS: Array[String] = [
	"res://assets/images/chapter_1/Screenshot 2026-10-31 190224.png",
	"res://assets/images/chapter_1/Screenshot 2026-10-31 190259.png",
	"res://assets/images/chapter_1/Screenshot 2026-10-31 190308.png",
	"res://assets/images/chapter_1/Screenshot 2026-10-31 190318.png",
	"res://assets/images/chapter_1/Screenshot 2026-10-31 190512.png",
	"res://assets/images/chapter_1/Screenshot 2026-10-31 190521.png",
]

const GAMEPLAY_BG_PATHS_CH2: Array[String] = [
	"res://assets/images/chapter_2/14913cf4-4b76-4b00-97d3-fd321e7b12f2.jpg",
	"res://assets/images/chapter_2/281257b0-a6f0-4433-a6b3-dabe9a85012b.jpg",
	"res://assets/images/chapter_2/659a5502-842f-453f-ba37-e281ad2d5325.jpg",
	"res://assets/images/chapter_2/ae1a37e3-408d-4e17-a007-793431120d9b.jpg",
	"res://assets/images/chapter_2/f3608a69-675c-41a5-aa9e-28516b264682.jpg",
	"res://assets/images/chapter_2/watermarked_img_14303081489371812048.jpg",
]

@onready var bg_texture_rect: TextureRect = get_node_or_null("BgTexture")

var _texture: Texture2D
var _time: float = 0.0
var _particles: Array = []

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	anchors_preset = PRESET_FULL_RECT
	
	if show_particles:
		_init_particles()
		
	# Gameplay fonida o'yinchi chalg'imasligi uchun avtomatik Bokeh Blur (5.5)
	if not is_ui_background and not show_menu_cliff and not is_map_background:
		if blur_amount <= 0.01:
			blur_amount = 2.8
			
	_update_blur_material()
		
	# UI fonini yuklash (Main Menu, Level Select yoki UI bo'limlar)
	if is_ui_background or show_menu_cliff or is_map_background:
		_load_texture(UI_BG_PATH)
	else:
		# Gameplay foni: har 2 darajada alohida rasm
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			if not gm.level_started.is_connected(set_level_background):
				gm.level_started.connect(set_level_background)
			set_level_background(gm.current_level_id)
		else:
			set_level_background(1)

var _current_theme := "forest"

func set_level_background(level_id: int) -> void:
	if level_id <= 20:
		# 1-Bob (1-20): Asl o'yin dizayni saqlanadi (o'rmon qorong'u manzarasi)
		_current_theme = "forest"
		if not GAMEPLAY_BG_PATHS.is_empty():
			var idx: int = ((level_id - 1) / 2) % GAMEPLAY_BG_PATHS.size()
			var path: String = GAMEPLAY_BG_PATHS[idx]
			_load_texture(path)
	elif level_id <= 40:
		# 2-Bob (21-40): Qishki qor va sovuq tog'lar muhiti (Winter Vibe)
		# Foydalanuvchi yuklagan 2-bob rasmlari (assets/images/chapter_2)
		_current_theme = "winter"
		if not GAMEPLAY_BG_PATHS_CH2.is_empty():
			var idx: int = ((level_id - 21) / 2) % GAMEPLAY_BG_PATHS_CH2.size()
			var path: String = GAMEPLAY_BG_PATHS_CH2[idx]
			_load_texture(path)
	else:
		_current_theme = "default"
		_clear_gameplay_texture()
			
	_init_particles()
	_update_blur_material()
	queue_redraw()

func _clear_gameplay_texture() -> void:
	_texture = null
	if bg_texture_rect:
		bg_texture_rect.texture = null
		bg_texture_rect.visible = false

func _update_blur_material() -> void:
	if not bg_texture_rect:
		return
	var mat: ShaderMaterial = bg_texture_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("blur_amount", blur_amount)
		if is_map_background:
			mat.set_shader_parameter("tint_color", Color(0.0, 0.0, 0.0, 0.0))
		elif blur_amount > 0.01:
			if _current_theme == "winter":
				mat.set_shader_parameter("tint_color", Color(0.04, 0.08, 0.16, 0.30))
			else:
				# 1-bob asl gameplay tuman qoplamasi
				mat.set_shader_parameter("tint_color", Color(0.04, 0.05, 0.09, 0.28))
		else:
			mat.set_shader_parameter("tint_color", Color(0.0, 0.0, 0.0, 0.0))

func set_custom_texture_path(path: String) -> void:
	_load_texture(path)
	_update_blur_material()

func _load_texture(path: String) -> void:
	if ResourceLoader.exists(path):
		_texture = load(path)
		if bg_texture_rect:
			bg_texture_rect.texture = _texture
			bg_texture_rect.visible = true
		queue_redraw()

func _init_particles() -> void:
	_particles.clear()
	var count := 65 if _current_theme == "winter" else 25
	for i in range(count):
		if _current_theme == "winter":
			# Qor parchalari (yuqoridan pastga silliq tushadi)
			_particles.append({
				"x": randf_range(0, 960),
				"y": randf_range(0, 540),
				"sz": randf_range(1.2, 3.4),
				"speed": randf_range(35.0, 85.0),
				"alpha": randf_range(0.45, 0.95),
				"offset": randf_range(0, TAU)
			})
		else:
			# 1-Bob: Havoda suzuvchi spora va chang zarrachalari
			_particles.append({
				"x": randf_range(0, 960),
				"y": randf_range(50, 480),
				"sz": randf_range(1.2, 2.5),
				"speed": randf_range(6.0, 18.0),
				"alpha": randf_range(0.2, 0.6),
				"offset": randf_range(0, TAU)
			})

func _process(delta: float) -> void:
	_time += delta
	if show_particles:
		for p in _particles:
			if _current_theme == "winter":
				# Qor pastga tushishi
				p.y += delta * p.speed
				if p.y > 540.0:
					p.y = -10.0
					p.x = randf_range(0, 960)
			else:
				# 1-bob chang yuqoriga suzishi
				p.y -= delta * p.speed
				if p.y < 30.0:
					p.y = 510.0
					p.x = randf_range(0, 960)
		queue_redraw()

func _draw() -> void:
	var w: float = size.x if size.x > 0 else 960.0
	var h: float = size.y if size.y > 0 else 540.0

	if _current_theme == "winter" and (bg_texture_rect == null or not bg_texture_rect.visible):
		# Qishki sovuq tun osmoni va tog'lar silueti (O'yinga maps imagelari umuman kirmaydi)
		draw_rect(Rect2(0, 0, w, h), Color("#060b14"), true)
		var sky_glow := PackedVector2Array([
			Vector2(0, 160), Vector2(w, 160), Vector2(w, h), Vector2(0, h)
		])
		draw_colored_polygon(sky_glow, Color(0.06, 0.12, 0.22, 0.55))
		
		# Uzoqdagi qorli tog'lar
		var far_pts := PackedVector2Array([
			Vector2(0, 360), Vector2(120, 280), Vector2(250, 320),
			Vector2(390, 230), Vector2(520, 300), Vector2(680, 240),
			Vector2(820, 310), Vector2(960, 270), Vector2(960, 540), Vector2(0, 540)
		])
		draw_colored_polygon(far_pts, Color("#0c1524"))
		draw_colored_polygon(PackedVector2Array([Vector2(360, 255), Vector2(390, 230), Vector2(420, 255)]), Color(0.40, 0.65, 0.95, 0.35))
		draw_colored_polygon(PackedVector2Array([Vector2(655, 265), Vector2(680, 240), Vector2(705, 265)]), Color(0.40, 0.65, 0.95, 0.35))
		
		# Yaqindagi qorong'u qoyalar
		var near_pts := PackedVector2Array([
			Vector2(0, 430), Vector2(170, 370), Vector2(340, 420),
			Vector2(530, 350), Vector2(710, 400), Vector2(860, 340),
			Vector2(960, 390), Vector2(960, 540), Vector2(0, 540)
		])
		draw_colored_polygon(near_pts, Color("#080e18"))
		draw_rect(Rect2(0, 380, w, 160), Color(0.22, 0.74, 0.97, 0.06), true)
	elif bg_texture_rect == null:
		if _texture:
			draw_texture_rect(_texture, Rect2(0, 0, w, h), false)
			if is_map_background:
				draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.06, 0.10, 0.55), true)
		else:
			draw_rect(Rect2(0, 0, w, h), Color(0.08, 0.10, 0.16), true)

	# Zarrachalar (1-bobda spora changi, 2-bobda haqiqiy qor yog'ishi!)
	if show_particles:
		for p in _particles:
			var px: float = p.x + sin(_time * 1.5 + p.offset) * (14.0 if _current_theme == "winter" else 10.0)
			if _current_theme == "winter":
				draw_circle(Vector2(px, p.y), p.sz + 1.2, Color(0.55, 0.85, 1.0, p.alpha * 0.28))
				draw_circle(Vector2(px, p.y), p.sz, Color(1.0, 1.0, 1.0, p.alpha))
			else:
				var c := Color(0.85, 0.90, 1.0, p.alpha * (0.8 + 0.2 * sin(_time * 2.0 + p.offset)))
				draw_circle(Vector2(px, p.y), p.sz, c)
