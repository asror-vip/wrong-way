extends Control

# Wrong Way - Atmospheric Backdrop
# Renders authentic Limbo/Badland landscape art from assets/images:
# - home-img.png for UI interfaces (Main Menu, Level Select, Editor)
# - Chapter 1: twilight_mist_01..06.png (Qorong'u tumanli o'rmon)
# - Chapter 2: frost_peak_01..06.jpg (Qorli muz cho'qqilari)
# - Chapter 3: emerald_woods_01..06.png (Zumrad chakalakzor)
# - Chapter 4: golden_canyon_01..06.png (Oltin vodiy)
# - Chapter 5: inferno_abyss_01..06.png (Olovli tublik)
# - Supports Cinematic Bokeh Blur to separate background from foreground physics

@export var show_menu_cliff: bool = false
@export var show_particles: bool = true
@export var is_ui_background: bool = false
@export var is_map_background: bool = false
@export var blur_amount: float = 0.0

const UI_BG_PATH := "res://assets/images/home-img.png"

const GAMEPLAY_BG_PATHS_CH1: Array[String] = [
	"res://assets/images/chapter_1/twilight_mist_01.png",
	"res://assets/images/chapter_1/twilight_mist_02.png",
	"res://assets/images/chapter_1/twilight_mist_03.png",
	"res://assets/images/chapter_1/twilight_mist_04.png",
	"res://assets/images/chapter_1/twilight_mist_05.png",
	"res://assets/images/chapter_1/twilight_mist_06.png",
]

const GAMEPLAY_BG_PATHS_CH2: Array[String] = [
	"res://assets/images/chapter_2/frost_peak_01.jpg",
	"res://assets/images/chapter_2/frost_peak_02.jpg",
	"res://assets/images/chapter_2/frost_peak_03.jpg",
	"res://assets/images/chapter_2/frost_peak_04.jpg",
	"res://assets/images/chapter_2/frost_peak_05.jpg",
	"res://assets/images/chapter_2/frost_peak_06.jpg",
]

const GAMEPLAY_BG_PATHS_CH3: Array[String] = [
	"res://assets/images/chapter_3/emerald_woods_01.png",
	"res://assets/images/chapter_3/emerald_woods_02.png",
	"res://assets/images/chapter_3/emerald_woods_03.png",
	"res://assets/images/chapter_3/emerald_woods_04.png",
	"res://assets/images/chapter_3/emerald_woods_05.png",
	"res://assets/images/chapter_3/emerald_woods_06.png",
]

const GAMEPLAY_BG_PATHS_CH4: Array[String] = [
	"res://assets/images/chapter_4/golden_canyon_01.png",
	"res://assets/images/chapter_4/golden_canyon_02.png",
	"res://assets/images/chapter_4/golden_canyon_03.png",
	"res://assets/images/chapter_4/golden_canyon_04.png",
	"res://assets/images/chapter_4/golden_canyon_05.png",
	"res://assets/images/chapter_4/golden_canyon_06.png",
]

const GAMEPLAY_BG_PATHS_CH5: Array[String] = [
	"res://assets/images/chapter_5/inferno_abyss_01.png",
	"res://assets/images/chapter_5/inferno_abyss_02.png",
	"res://assets/images/chapter_5/inferno_abyss_03.png",
	"res://assets/images/chapter_5/inferno_abyss_04.png",
	"res://assets/images/chapter_5/inferno_abyss_05.png",
	"res://assets/images/chapter_5/inferno_abyss_06.png",
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
		
	# Gameplay fonida o'yinchi chalg'imasligi uchun avtomatik Bokeh Blur (2.8)
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

var _current_theme := "twilight_mist"

func set_level_background(level_id: int) -> void:
	if level_id <= 20:
		# 1-Bob (1-20): Tumanli qorong'u o'rmon
		_current_theme = "twilight_mist"
		if not GAMEPLAY_BG_PATHS_CH1.is_empty():
			var idx: int = ((level_id - 1) / 2) % GAMEPLAY_BG_PATHS_CH1.size()
			_load_texture(GAMEPLAY_BG_PATHS_CH1[idx])
	elif level_id <= 40:
		# 2-Bob (21-40): Qorli muz cho'qqilari
		_current_theme = "frost_peak"
		if not GAMEPLAY_BG_PATHS_CH2.is_empty():
			var idx: int = ((level_id - 21) / 2) % GAMEPLAY_BG_PATHS_CH2.size()
			_load_texture(GAMEPLAY_BG_PATHS_CH2[idx])
	elif level_id <= 60:
		# 3-Bob (41-60): Zumrad chakalakzor va qasr zallari
		_current_theme = "emerald_woods"
		if not GAMEPLAY_BG_PATHS_CH3.is_empty():
			var idx: int = ((level_id - 41) / 2) % GAMEPLAY_BG_PATHS_CH3.size()
			_load_texture(GAMEPLAY_BG_PATHS_CH3[idx])
	elif level_id <= 80:
		# 4-Bob (61-80): Oltin kanyon va quyoshli xarobalar
		_current_theme = "golden_canyon"
		if not GAMEPLAY_BG_PATHS_CH4.is_empty():
			var idx: int = ((level_id - 61) / 2) % GAMEPLAY_BG_PATHS_CH4.size()
			_load_texture(GAMEPLAY_BG_PATHS_CH4[idx])
	elif level_id <= 100:
		# 5-Bob (81-100): Olovli vulqon tubligi
		_current_theme = "inferno_abyss"
		if not GAMEPLAY_BG_PATHS_CH5.is_empty():
			var idx: int = ((level_id - 81) / 2) % GAMEPLAY_BG_PATHS_CH5.size()
			_load_texture(GAMEPLAY_BG_PATHS_CH5[idx])
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
			match _current_theme:
				"frost_peak":
					mat.set_shader_parameter("tint_color", Color(0.04, 0.08, 0.16, 0.30))
				"emerald_woods":
					mat.set_shader_parameter("tint_color", Color(0.02, 0.06, 0.04, 0.28))
				"golden_canyon":
					mat.set_shader_parameter("tint_color", Color(0.12, 0.08, 0.03, 0.26))
				"inferno_abyss":
					mat.set_shader_parameter("tint_color", Color(0.14, 0.04, 0.02, 0.32))
				_:
					# 1-bob tuman qoplamasi
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
	var count := 65 if _current_theme == "frost_peak" else 28
	for i in range(count):
		match _current_theme:
			"frost_peak":
				# Qor parchalari
				_particles.append({
					"x": randf_range(0, 960),
					"y": randf_range(0, 540),
					"sz": randf_range(1.2, 3.4),
					"speed": randf_range(35.0, 85.0),
					"alpha": randf_range(0.45, 0.95),
					"offset": randf_range(0, TAU)
				})
			"inferno_abyss":
				# Olovli cho'g' va uchqunlar (tezroq yuqoriga uchadi)
				_particles.append({
					"x": randf_range(0, 960),
					"y": randf_range(100, 540),
					"sz": randf_range(1.4, 3.2),
					"speed": randf_range(25.0, 65.0),
					"alpha": randf_range(0.4, 0.9),
					"offset": randf_range(0, TAU)
				})
			"golden_canyon":
				# Oltin chang va quyosh nurlari zarrachalari
				_particles.append({
					"x": randf_range(0, 960),
					"y": randf_range(40, 500),
					"sz": randf_range(1.2, 2.6),
					"speed": randf_range(8.0, 20.0),
					"alpha": randf_range(0.3, 0.7),
					"offset": randf_range(0, TAU)
				})
			"emerald_woods":
				# Yashil o'rmon sporalari
				_particles.append({
					"x": randf_range(0, 960),
					"y": randf_range(40, 500),
					"sz": randf_range(1.4, 2.8),
					"speed": randf_range(7.0, 20.0),
					"alpha": randf_range(0.3, 0.75),
					"offset": randf_range(0, TAU)
				})
			_:
				# 1-Bob: Havoda suzuvchi tuman sporalari
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
			if _current_theme == "frost_peak":
				p.y += delta * p.speed
				if p.y > 540.0:
					p.y = -10.0
					p.x = randf_range(0, 960)
			else:
				p.y -= delta * p.speed
				if p.y < 20.0:
					p.y = 520.0
					p.x = randf_range(0, 960)
		queue_redraw()

func _draw() -> void:
	var w: float = size.x if size.x > 0 else 960.0
	var h: float = size.y if size.y > 0 else 540.0

	if _current_theme == "frost_peak" and (bg_texture_rect == null or not bg_texture_rect.visible):
		draw_rect(Rect2(0, 0, w, h), Color("#060b14"), true)
	elif bg_texture_rect == null:
		if _texture:
			draw_texture_rect(_texture, Rect2(0, 0, w, h), false)
			if is_map_background:
				draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.06, 0.10, 0.55), true)
		else:
			draw_rect(Rect2(0, 0, w, h), Color(0.08, 0.10, 0.16), true)

	# Zarrachalar (Har bir bobning o'ziga xos vizual effekti)
	if show_particles:
		for p in _particles:
			var px: float = p.x + sin(_time * 1.5 + p.offset) * (14.0 if _current_theme == "frost_peak" else 8.0)
			match _current_theme:
				"frost_peak":
					draw_circle(Vector2(px, p.y), p.sz + 1.2, Color(0.55, 0.85, 1.0, p.alpha * 0.28))
					draw_circle(Vector2(px, p.y), p.sz, Color(1.0, 1.0, 1.0, p.alpha))
				"inferno_abyss":
					# Olovli uchqun
					var pulse := 0.7 + 0.3 * sin(_time * 4.0 + p.offset)
					draw_circle(Vector2(px, p.y), p.sz + 1.2, Color(0.95, 0.25, 0.08, p.alpha * 0.35 * pulse))
					draw_circle(Vector2(px, p.y), p.sz, Color(1.0, 0.65, 0.20, p.alpha * pulse))
				"golden_canyon":
					# Oltin zarracha
					var pulse := 0.8 + 0.2 * sin(_time * 2.0 + p.offset)
					draw_circle(Vector2(px, p.y), p.sz + 0.8, Color(0.95, 0.75, 0.25, p.alpha * 0.25))
					draw_circle(Vector2(px, p.y), p.sz, Color(1.0, 0.88, 0.50, p.alpha * pulse))
				"emerald_woods":
					# Yashil o'rmon sporasi
					var pulse := 0.8 + 0.2 * sin(_time * 2.5 + p.offset)
					draw_circle(Vector2(px, p.y), p.sz + 0.8, Color(0.40, 0.85, 0.35, p.alpha * 0.22))
					draw_circle(Vector2(px, p.y), p.sz, Color(0.65, 0.95, 0.55, p.alpha * pulse))
				_:
					# Tumanli o'rmon
					var c := Color(0.85, 0.90, 1.0, p.alpha * (0.8 + 0.2 * sin(_time * 2.0 + p.offset)))
					draw_circle(Vector2(px, p.y), p.sz, c)
