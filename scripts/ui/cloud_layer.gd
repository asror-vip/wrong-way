extends Control
class_name CloudLayer

# CloudLayer: Animated fluffy cloud bank along the bottom edge of the level select map.
# Teases upcoming worlds and creates a dreamy game-world boundary below level 20.

var anim_time: float = 0.0

# Pre-computed cloud puff positions
var back_puffs: Array[Vector3] = []  # Vector3(x, base_y, radius)
var mid_puffs: Array[Vector3] = []
var front_puffs: Array[Vector3] = []

@onready var notice_label: Label = Label.new()
@onready var badge_panel: Panel = Panel.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(960, 100)
	
	_generate_cloud_puffs()
	_setup_coming_soon_badge()
	
	LocaleManager.language_changed.connect(_on_language_changed)
	_update_badge_text()


func _generate_cloud_puffs() -> void:
	# Orqa qatlam bulutlari (to'qroq krem)
	var x: float = -30.0
	while x <= 990.0:
		var r := randf_range(45.0, 65.0)
		back_puffs.append(Vector3(x, 50.0, r))
		x += randf_range(40.0, 60.0)
		
	# O'rta qatlam bulutlari
	x = -20.0
	while x <= 980.0:
		var r := randf_range(38.0, 56.0)
		mid_puffs.append(Vector3(x, 60.0, r))
		x += randf_range(35.0, 55.0)

	# Old qatlam bulutlari (oppoq va yorqin)
	x = -15.0
	while x <= 975.0:
		var r := randf_range(32.0, 48.0)
		front_puffs.append(Vector3(x, 70.0, r))
		x += randf_range(30.0, 45.0)

func _setup_coming_soon_badge() -> void:
	badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_panel.custom_minimum_size = Vector2(230, 28)
	badge_panel.size = Vector2(230, 28)
	badge_panel.position = Vector2(365, 62)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.20, 0.18, 0.24, 0.85)
	style.border_color = Color(0.38, 0.35, 0.44, 0.9)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	badge_panel.add_theme_stylebox_override("panel", style)
	
	notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_label.custom_minimum_size = Vector2(230, 28)
	notice_label.size = Vector2(230, 28)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice_label.add_theme_font_size_override("font_size", 12)
	notice_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.95))
	
	badge_panel.add_child(notice_label)
	add_child(badge_panel)

func _on_language_changed(_lang: String) -> void:
	_update_badge_text()

func _update_badge_text() -> void:
	var cur := LocaleManager.current_language
	match cur:
		"ru": notice_label.text = "Новые миры скоро..."
		"en": notice_label.text = "New worlds coming soon..."
		"tr": notice_label.text = "Yeni dünyalar yakında..."
		_: notice_label.text = "Yangi dunyolar tez kunda..."

func _process(delta: float) -> void:
	anim_time += delta
	# Sekin nafas oluvchi suzish effekti
	if badge_panel:
		badge_panel.position.y = 62.0 + sin(anim_time * 1.8) * 2.5
	queue_redraw()

func _draw() -> void:
	# 1. Orqa bulut qatlami
	var col_back := Color(0.85, 0.81, 0.74, 0.82)
	for i in range(back_puffs.size()):
		var p = back_puffs[i]
		var dy := sin(anim_time * 1.2 + i * 0.4) * 3.0
		draw_circle(Vector2(p.x, p.y + dy), p.z, col_back)

	# 2. O'rta bulut qatlami
	var col_mid := Color(0.92, 0.89, 0.83, 0.90)
	for i in range(mid_puffs.size()):
		var p = mid_puffs[i]
		var dy := cos(anim_time * 1.5 + i * 0.5) * 3.5
		draw_circle(Vector2(p.x, p.y + dy), p.z, col_mid)

	# 3. Old asosiy oq bulut qatlami
	var col_front := Color(0.97, 0.95, 0.91, 0.97)
	for i in range(front_puffs.size()):
		var p = front_puffs[i]
		var dy := sin(anim_time * 1.7 + i * 0.6) * 2.5
		draw_circle(Vector2(p.x, p.y + dy), p.z, col_front)

	# 4. Pastki qismni to'liq qoplovchi qatlam
	draw_rect(Rect2(-50.0, 75.0, 1060.0, 150.0), col_front, true)
