extends Control

# Wrong Way - Level Select (Campaign Map)
# Advanced Multi-Chapter System using Custom Artwork from assets/images/maps-images:
# - Chapter 1 (1-20): "1.jpg" (Limbo dark forest winding mountain road)
# - Chapter 2 (21-40): "2.jpg" (Winter snow / ice peaks winding road)
# - Circular level buttons (38x38) positioned directly on the painted road centerline
# - Path is visually native to the artwork (no procedural black lines over the art)
# - Clouds appear when next chapter is locked, and vanish when unlocked!
# - Smooth sliding animation between chapters (60fps cubic tween + swipe)
# - TopBar: Chapter 1 shows X / 60, Chapter 2 shows 0 / 55

const UNIFIED_ROAD_POS: Array[Vector2] = [
	Vector2(38, 192),   # 1: Yo'l boshlanishi
	Vector2(117, 218),  # 2: Birinchi pastlik nishabi
	Vector2(163, 330),  # 3: Tik pastga tushish
	Vector2(241, 417),  # 4: Pastki halqa markazi
	Vector2(290, 321),  # 5: Tik ko'tarilish
	Vector2(306, 201),  # 6: Tog' sari burilish
	Vector2(399, 126),  # 7: Cho'qqi nishabi
	Vector2(512, 128),  # 8: Asosiy cho'qqi
	Vector2(496, 224),  # 9: S-yo'lak kirishi
	Vector2(434, 296),  # 10: O'rta halqa chap qulog'i
	Vector2(536, 325),  # 11: O'rta halqadan chiqish
	Vector2(600, 222),  # 12: Tosh ko'prik boshlanishi
	Vector2(691, 141),  # 13: Tosh ko'prik yakuni
	Vector2(806, 128),  # 14: O'ng qoya cho'qqisi
	Vector2(804, 224),  # 15: O'ng nishab
	Vector2(694, 267),  # 16: O'ng ichki qayrilish
	Vector2(673, 376),  # 17: Quyi ichki halqa
	Vector2(765, 396),  # 18: Pastki to'g'ri trassa
	Vector2(848, 318),  # 19: Chiqish nishabi
	Vector2(934, 230),  # 20: 1-bob marrasi / 2-bobga ulanish
]

const CHAPTER_1_POS: Array[Vector2] = UNIFIED_ROAD_POS
const CHAPTER_2_POS: Array[Vector2] = UNIFIED_ROAD_POS
const CHAPTER_3_POS: Array[Vector2] = UNIFIED_ROAD_POS

@onready var chapter_slider: Control = $ChapterSlider
@onready var ch1_view: Control = $ChapterSlider/Chapter1View
@onready var backdrop_ch1: TextureRect = $ChapterSlider/Chapter1View/BackdropCh1
@onready var map_draw1: Control = $ChapterSlider/Chapter1View/MapDraw1
@onready var node_layer1: Control = $ChapterSlider/Chapter1View/NodeLayer1

@onready var boundary_wall: Control = $ChapterSlider/BoundaryWall

@onready var ch2_view: Control = $ChapterSlider/Chapter2View
@onready var backdrop_ch2: TextureRect = $ChapterSlider/Chapter2View/BackdropCh2
@onready var map_draw2: Control = $ChapterSlider/Chapter2View/MapDraw2
@onready var node_layer2: Control = $ChapterSlider/Chapter2View/NodeLayer2

@onready var boundary_wall2: Control = get_node_or_null("ChapterSlider/BoundaryWall2")
@onready var ch3_view: Control = get_node_or_null("ChapterSlider/Chapter3View")
@onready var backdrop_ch3: TextureRect = get_node_or_null("ChapterSlider/Chapter3View/BackdropCh3")
@onready var map_draw3: Control = get_node_or_null("ChapterSlider/Chapter3View/MapDraw3")
@onready var node_layer3: Control = get_node_or_null("ChapterSlider/Chapter3View/NodeLayer3")

@onready var back_btn: Button = $TopBar/BackButton
@onready var title_label: Label = $TopBar/TitleLabel
@onready var total_stars_chip: Label = $TopBar/TotalStarsChip

@onready var side_nav_right: Button = $SideNavRight
@onready var side_nav_left: Button = $SideNavLeft
@onready var btn_ch1: Button = $BottomBar/HBox/BtnCh1
@onready var btn_ch2: Button = $BottomBar/HBox/BtnCh2
@onready var btn_ch3: Button = get_node_or_null("BottomBar/HBox/BtnCh3")
@onready var notice_modal: Node = $NoticeModal

var style_white = preload("res://resources/themes/btn_capsule_white.tres")
var style_white_hov = preload("res://resources/themes/btn_capsule_white_hover.tres")
var style_glass = preload("res://resources/themes/btn_capsule_glass.tres")
var style_glass_hov = preload("res://resources/themes/btn_capsule_glass_hover.tres")

var current_chapter: int = 1
var is_animating: bool = false
var star_chip_icon: TextureRect

# Jonli interaktiv surish (Continuous Drag & Halfway Snap)
var is_dragging: bool = false
var has_dragged: bool = false
var drag_start_x: float = 0.0
var slider_start_x: float = 0.0
var drag_accum_dist: float = 0.0

func _ready() -> void:
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_method("show_banner"):
		adm.show_banner()
	
	LocaleManager.language_changed.connect(_on_language_changed)
	SoundManager.set_gameplay_mode(false)
	SoundManager.play_music()
	
	_setup_top_bar()
	_setup_nav_connections()
	
	if map_draw1:
		map_draw1.draw.connect(_on_map_draw_ch1)
	if map_draw2:
		map_draw2.draw.connect(_on_map_draw_ch2)
	if map_draw3:
		map_draw3.draw.connect(_on_map_draw_ch3)
	if boundary_wall:
		boundary_wall.draw.connect(_on_boundary_wall_draw)
	if boundary_wall2:
		boundary_wall2.draw.connect(_on_boundary_wall2_draw)
		
	# Boshlang'ich holatda 1, 2 va 3-bob doiralarini yaratish
	_create_nodes_for_chapter(1)
	_create_nodes_for_chapter(2)
	_create_nodes_for_chapter(3)
	
	# Boshlang'ich bobni animatsiyasiz ko'rsatish
	switch_to_chapter(1, false)

func _setup_top_bar() -> void:
	if back_btn:
		back_btn.icon = IconFactory.get_icon("circle_btn_back", 1.0)
		back_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		back_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		back_btn.text = ""
		if not back_btn.pressed.is_connected(_on_back_pressed):
			back_btn.pressed.connect(_on_back_pressed)
	
	if total_stars_chip and star_chip_icon == null:
		star_chip_icon = IconFactory.create_texture_rect("crown_gold", Vector2(16, 16), 0.75)
		star_chip_icon.position = Vector2(8, (total_stars_chip.size.y - 16) / 2.0)
		total_stars_chip.add_child(star_chip_icon)

func _setup_nav_connections() -> void:
	var solid_box := StyleBoxFlat.new()
	solid_box.set_corner_radius_all(22)
	solid_box.bg_color = Color(0.06, 0.08, 0.14, 0.98)
	solid_box.border_color = Color(0.35, 0.45, 0.65, 0.90)
	solid_box.set_border_width_all(1.5)
	solid_box.shadow_color = Color(0, 0, 0, 0.6)
	solid_box.shadow_size = 6
	
	if side_nav_right:
		side_nav_right.add_theme_stylebox_override("normal", solid_box)
		side_nav_right.add_theme_stylebox_override("hover", solid_box)
		side_nav_right.add_theme_stylebox_override("pressed", solid_box)
		side_nav_right.pressed.connect(_on_side_nav_right_pressed)
	if side_nav_left:
		side_nav_left.add_theme_stylebox_override("normal", solid_box)
		side_nav_left.add_theme_stylebox_override("hover", solid_box)
		side_nav_left.add_theme_stylebox_override("pressed", solid_box)
		side_nav_left.pressed.connect(func():
			if current_chapter == 3:
				switch_to_chapter(2, true)
			elif current_chapter == 2:
				switch_to_chapter(1, true)
		)
	if btn_ch1:
		btn_ch1.pressed.connect(func(): switch_to_chapter(1, true))
	if btn_ch2:
		btn_ch2.pressed.connect(func(): switch_to_chapter(2, true))
	if btn_ch3:
		btn_ch3.pressed.connect(func(): switch_to_chapter(3, true))

func _show_notice(title_text: String, message_text: String) -> void:
	if not notice_modal:
		return
	if "title" in notice_modal:
		notice_modal.title = title_text
	if "dialog_text" in notice_modal:
		notice_modal.dialog_text = message_text
	if notice_modal.has_method("popup_centered"):
		notice_modal.popup_centered()
	elif notice_modal.has_method("show"):
		notice_modal.show()

func _on_side_nav_right_pressed() -> void:
	if current_chapter == 1:
		switch_to_chapter(2, true)
	elif current_chapter == 2:
		switch_to_chapter(3, true)

func _input(event: InputEvent) -> void:
	if is_animating:
		return
		
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				is_dragging = true
				has_dragged = false
				drag_start_x = mb.position.x
				slider_start_x = chapter_slider.position.x
				drag_accum_dist = 0.0
			else:
				if is_dragging:
					is_dragging = false
					if has_dragged:
						_finish_drag()
						get_viewport().set_input_as_handled()
						
	elif event is InputEventMouseMotion and is_dragging:
		var mm := event as InputEventMouseMotion
		var dx: float = mm.position.x - drag_start_x
		drag_accum_dist += absf(mm.relative.x)
		if drag_accum_dist > 8.0:
			has_dragged = true
			
		if has_dragged:
			var target_x: float = slider_start_x + dx
			target_x = clampf(target_x, -2160.0 - 50.0, 50.0)
			chapter_slider.position.x = target_x
			_update_realtime_drag_feedback(target_x)
			get_viewport().set_input_as_handled()
			
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			is_dragging = true
			has_dragged = false
			drag_start_x = st.position.x
			slider_start_x = chapter_slider.position.x
			drag_accum_dist = 0.0
		else:
			if is_dragging:
				is_dragging = false
				if has_dragged:
					_finish_drag()
					get_viewport().set_input_as_handled()
					
	elif event is InputEventScreenDrag and is_dragging:
		var sd := event as InputEventScreenDrag
		var dx: float = sd.position.x - drag_start_x
		drag_accum_dist += absf(sd.relative.x)
		if drag_accum_dist > 8.0:
			has_dragged = true
			
		if has_dragged:
			var target_x: float = slider_start_x + dx
			target_x = clampf(target_x, -2160.0 - 50.0, 50.0)
			chapter_slider.position.x = target_x
			_update_realtime_drag_feedback(target_x)
			get_viewport().set_input_as_handled()

func _update_realtime_drag_feedback(slider_x: float) -> void:
	var target_ch: int = 1
	if slider_x <= -1620.0:
		target_ch = 3
	elif slider_x <= -540.0:
		target_ch = 2
	else:
		target_ch = 1
	if btn_ch1 and btn_ch2:
		_set_btn_active(btn_ch1, target_ch == 1)
		_set_btn_active(btn_ch2, target_ch == 2)
		if btn_ch3: _set_btn_active(btn_ch3, target_ch == 3)
	if title_label:
		var title_key := "chapter_1_title"
		if target_ch == 2: title_key = "chapter_2_title"
		elif target_ch == 3: title_key = "chapter_3_title"
		title_label.text = "< ◇ ── " + LocaleManager.t(title_key).to_upper() + " ── ◇ >"

func _finish_drag() -> void:
	var slider_x := chapter_slider.position.x
	if slider_x <= -1620.0:
		switch_to_chapter(3, true)
	elif slider_x <= -540.0:
		switch_to_chapter(2, true)
	else:
		switch_to_chapter(1, true)

func switch_to_chapter(target_chapter: int, animated: bool = true) -> void:
	current_chapter = target_chapter
	var target_x: float = 0.0
	if current_chapter == 2:
		target_x = -1080.0
	elif current_chapter == 3:
		target_x = -2160.0
	
	_update_top_bar_data()
	_update_nav_buttons()
	
	if not animated:
		chapter_slider.position.x = target_x
		if boundary_wall: boundary_wall.queue_redraw()
		if boundary_wall2: boundary_wall2.queue_redraw()
		if map_draw1: map_draw1.queue_redraw()
		if map_draw2: map_draw2.queue_redraw()
		if map_draw3: map_draw3.queue_redraw()
		return
		
	# Silliq kinematik animatsiya: 60fps cubic tween
	is_animating = true
	SoundManager.play("click")
	
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(chapter_slider, "position:x", target_x, 0.38)
	tw.finished.connect(func():
		is_animating = false
		if boundary_wall: boundary_wall.queue_redraw()
		if boundary_wall2: boundary_wall2.queue_redraw()
		if map_draw1: map_draw1.queue_redraw()
		if map_draw2: map_draw2.queue_redraw()
		if map_draw3: map_draw3.queue_redraw()
	)

func _update_top_bar_data() -> void:
	if title_label:
		var title_key := "chapter_1_title"
		if current_chapter == 2:
			title_key = "chapter_2_title"
		elif current_chapter == 3:
			title_key = "chapter_3_title"
		title_label.text = "< ◇ ── " + LocaleManager.t(title_key).to_upper() + " ── ◇ >"
		
	if total_stars_chip:
		var ch_stars := SaveManager.get_chapter_stars(current_chapter)
		total_stars_chip.text = "     %d / 60" % ch_stars

func _update_nav_buttons() -> void:
	if side_nav_right:
		side_nav_right.visible = (current_chapter < 3)
		if current_chapter == 1:
			side_nav_right.text = "2-BOB ▶"
		elif current_chapter == 2:
			side_nav_right.text = "3-BOB ▶"
	if side_nav_left:
		side_nav_left.visible = (current_chapter > 1)
		if current_chapter == 2:
			side_nav_left.text = "◀ 1-BOB"
		elif current_chapter == 3:
			side_nav_left.text = "◀ 2-BOB"
		
	if btn_ch1 and btn_ch2:
		_set_btn_active(btn_ch1, current_chapter == 1)
		_set_btn_active(btn_ch2, current_chapter == 2)
		if btn_ch3:
			_set_btn_active(btn_ch3, current_chapter == 3)

func _set_btn_active(btn: Button, active: bool) -> void:
	if active:
		btn.add_theme_stylebox_override("normal", style_white)
		btn.add_theme_stylebox_override("hover", style_white_hov)
		btn.add_theme_color_override("font_color", Color(0.08, 0.08, 0.12))
	else:
		btn.add_theme_stylebox_override("normal", style_glass)
		btn.add_theme_stylebox_override("hover", style_glass_hov)
		btn.add_theme_color_override("font_color", Color(0.85, 0.88, 0.94))

func _on_language_changed(_lang: String) -> void:
	_update_top_bar_data()
	_create_nodes_for_chapter(1)
	_create_nodes_for_chapter(2)
	_create_nodes_for_chapter(3)

func _create_nodes_for_chapter(chapter: int) -> void:
	var container: Control = null
	if chapter == 1:
		container = node_layer1
	elif chapter == 2:
		container = node_layer2
	elif chapter == 3:
		container = node_layer3
		
	if not container:
		return
		
	for child in container.get_children():
		child.queue_free()

	var positions := CHAPTER_1_POS
	if chapter == 2:
		positions = CHAPTER_2_POS
	elif chapter == 3:
		positions = CHAPTER_3_POS

	var start_lvl := 1
	if chapter == 2:
		start_lvl = 21
	elif chapter == 3:
		start_lvl = 41

	var max_unlocked: int = 1
	for lvl in SaveManager.unlocked_levels:
		if lvl > max_unlocked:
			max_unlocked = lvl

	for i in range(20):
		var lvl := start_lvl + i
		var pos: Vector2 = positions[i]
		var unlocked := SaveManager.is_level_unlocked(lvl)
		var stars: int = SaveManager.level_stars.get(str(lvl), 0)
		var is_active_target := (lvl == max_unlocked)
		
		# Dumaloq tugma (36x36 diametrli doira, radius 18)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(36, 36)
		btn.size = Vector2(36, 36)
		btn.position = pos - Vector2(18, 18)
		btn.focus_mode = Control.FOCUS_NONE
		
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(18)
		
		if unlocked:
			if is_active_target:
				style.bg_color = Color(0.10, 0.22, 0.38, 0.96)
				style.border_color = Color("#38bdf8")
				style.set_border_width_all(2)
				style.shadow_color = Color(0.22, 0.74, 0.97, 0.50)
				style.shadow_size = 8
			else:
				style.bg_color = Color(0.06, 0.10, 0.18, 0.92)
				style.border_color = Color(0.35, 0.45, 0.62, 0.85)
				style.set_border_width_all(1.5)
				style.shadow_color = Color(0, 0, 0, 0.50)
				style.shadow_size = 4
				
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("pressed", style)
			
			btn.text = str(lvl)
			btn.add_theme_font_size_override("font_size", 15)
			btn.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
			
			# Dumaloq doira TEPASIDA kattaroq 3 ta yulduzcha
			var star_box := HBoxContainer.new()
			star_box.alignment = BoxContainer.ALIGNMENT_CENTER
			star_box.custom_minimum_size = Vector2(36, 12)
			star_box.size = Vector2(36, 12)
			star_box.position = pos + Vector2(-18, -32) # Doira tepasida
			star_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			star_box.add_theme_constant_override("separation", 2)
			
			for s in range(3):
				var star_key := "star_gold" if s < stars else "star_dim"
				var star_icon := IconFactory.create_texture_rect(star_key, Vector2(10, 10), 0.52)
				star_box.add_child(star_icon)
			container.add_child(star_box)
			
			btn.pressed.connect(func(): _on_level_btn_pressed(lvl))
		else:
			var can_ad_unlock := SaveManager.is_level_ad_unlockable(lvl)
			if can_ad_unlock:
				style.bg_color = Color(0.12, 0.10, 0.16, 0.90)
				style.border_color = Color("#eab308")
				style.set_border_width_all(1.5)
				style.shadow_color = Color(0.92, 0.70, 0.03, 0.25)
				style.shadow_size = 5
				
				btn.add_theme_stylebox_override("normal", style)
				btn.add_theme_stylebox_override("hover", style)
				btn.add_theme_stylebox_override("pressed", style)
				
				btn.text = str(lvl)
				btn.add_theme_font_size_override("font_size", 14)
				btn.add_theme_color_override("font_color", Color(0.98, 0.85, 0.40))
				
				var ad_badge := IconFactory.create_texture_rect("video_ad", Vector2(13, 13), 0.55)
				ad_badge.position = pos + Vector2(9, -17)
				ad_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
				container.add_child(ad_badge)
				
				btn.pressed.connect(func():
					SoundManager.play("click")
					var adm = get_node_or_null("/root/AdManager")
					if adm and adm.has_method("show_rewarded_ad"):
						adm.show_rewarded_ad(func():
							SaveManager.unlock_level_via_ad(lvl)
							_create_nodes_for_chapter(current_chapter)
						)
					else:
						SaveManager.unlock_level_via_ad(lvl)
						_create_nodes_for_chapter(current_chapter)
				)
			else:
				style.bg_color = Color(0.04, 0.05, 0.08, 0.82)
				style.border_color = Color(0.20, 0.25, 0.35, 0.50)
				style.set_border_width_all(1)
				
				btn.add_theme_stylebox_override("normal", style)
				btn.add_theme_stylebox_override("hover", style)
				btn.add_theme_stylebox_override("pressed", style)
				
				btn.text = str(lvl)
				btn.add_theme_font_size_override("font_size", 14)
				btn.add_theme_color_override("font_color", Color(0.45, 0.50, 0.60))
				
				var lock_badge := IconFactory.create_texture_rect("lock", Vector2(12, 12), 0.50)
				lock_badge.position = pos + Vector2(9, -17)
				lock_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
				container.add_child(lock_badge)
				
				btn.pressed.connect(func():
					SoundManager.play("click")
					var info: Dictionary = SaveManager.get_lock_reason_dialog(lvl)
					var t: String = info.get("title", "Qulflangan")
					var m: String = info.get("text", "Bu daraja hozircha ochilmagan.")
					_show_notice(t, m)
				)
				
		container.add_child(btn)

func _on_level_btn_pressed(lvl: int) -> void:
	SoundManager.play("click")
	SaveManager.should_restore_result_modal = false
	SaveManager.navigation_source = "home_menu"
	
	var level_scene_path := "res://scenes/levels/level_%02d.tscn" % lvl
	if lvl > 60 and not ResourceLoader.exists(level_scene_path):
		_show_notice("DARJA: %d" % lvl, "Yangi darajalar tez kunda navbatdagi katta yangilanishda taqdim etiladi!")
		return
		
	var already_beaten := SaveManager.is_level_completed(lvl)
	if already_beaten:
		var adm = get_node_or_null("/root/AdManager")
		if adm and adm.has_method("show_rewarded_ad"):
			adm.show_rewarded_ad(func():
				GameManager.start_game(lvl)
			)
		else:
			GameManager.start_game(lvl)
	else:
		GameManager.start_game(lvl)

# -------------------------------------------------------------
# Boblar Bulutlari (Ochilmaganda ko'rinadi, ochilganda yo'qoladi)
# -------------------------------------------------------------
func _on_map_draw_ch1() -> void:
	var ch2_unlocked: bool = SaveManager.is_chapter_unlocked(2)
	if not ch2_unlocked:
		_draw_clouds_right_canvas(map_draw1)

func _on_map_draw_ch2() -> void:
	var ch2_unlocked: bool = SaveManager.is_chapter_unlocked(2)
	if not ch2_unlocked:
		_draw_clouds_left_canvas(map_draw2)
	var ch3_unlocked: bool = SaveManager.is_chapter_unlocked(3)
	if not ch3_unlocked:
		_draw_clouds_right_canvas(map_draw2)

func _on_map_draw_ch3() -> void:
	var ch3_unlocked: bool = SaveManager.is_chapter_unlocked(3)
	if not ch3_unlocked:
		_draw_clouds_left_canvas(map_draw3)

# -------------------------------------------------------------
# Boblararo Tumanli Chegara / Bo'shliq (Mystic Fog & Void Boundary)
# -------------------------------------------------------------
func _on_boundary_wall_draw() -> void:
	if not boundary_wall:
		return
	var ch2_unlocked: bool = SaveManager.is_chapter_unlocked(2)
	_draw_boundary_canvas(boundary_wall, ch2_unlocked)

func _on_boundary_wall2_draw() -> void:
	if not boundary_wall2:
		return
	var ch3_unlocked: bool = SaveManager.is_chapter_unlocked(3)
	_draw_boundary_canvas(boundary_wall2, ch3_unlocked)

func _draw_boundary_canvas(canvas: Control, next_unlocked: bool) -> void:
	var w: float = canvas.size.x # 120 px
	var h: float = canvas.size.y # 540 px
	var seam_x: float = w * 0.5   # 60 px (markaziy chegaraviy chiziq)
	
	# 1. Chegaradagi qorong'i bo'shliq / chasm foni
	canvas.draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.05, 0.08, 0.98))
	
	# 2. Uzilgan yo'l cheti (Left edge x=0..38)
	var broken_left := PackedVector2Array([
		Vector2(0, 235), Vector2(28, 238), Vector2(38, 252),
		Vector2(25, 270), Vector2(0, 275)
	])
	canvas.draw_colored_polygon(broken_left, Color(0.08, 0.10, 0.14, 0.95))
	canvas.draw_line(Vector2(28, 238), Vector2(38, 252), Color(0.25, 0.32, 0.45, 0.8), 2.0)
	canvas.draw_line(Vector2(38, 252), Vector2(25, 270), Color(0.25, 0.32, 0.45, 0.8), 2.0)
	canvas.draw_circle(Vector2(45, 250), 3.0, Color(0.18, 0.22, 0.30, 0.8))
	canvas.draw_circle(Vector2(48, 260), 2.0, Color(0.15, 0.18, 0.25, 0.7))
	
	# 3. Keyingi bobning boshlanish qirrasi (Right edge x=82..120)
	var next_ledge := PackedVector2Array([
		Vector2(120, 185), Vector2(92, 192), Vector2(82, 208),
		Vector2(95, 222), Vector2(120, 225)
	])
	canvas.draw_colored_polygon(next_ledge, Color(0.12, 0.16, 0.22, 0.95))
	canvas.draw_line(Vector2(92, 192), Vector2(82, 208), Color(0.70, 0.82, 0.92, 0.7), 2.0)
	canvas.draw_line(Vector2(82, 208), Vector2(95, 222), Color(0.70, 0.82, 0.92, 0.7), 2.0)
	
	# 4. Qatlamli quyuq tabiiy tuman va bulutlar
	for step in range(12):
		var alpha: float = 0.07 * (step + 1)
		canvas.draw_rect(Rect2(step * 5.0, 0, 5.0, h), Color(0.04, 0.06, 0.10, alpha))
		canvas.draw_rect(Rect2(w - (step + 1) * 5.0, 0, 5.0, h), Color(0.05, 0.08, 0.13, alpha))
		
	var fog_centers: Array[Vector2] = [
		Vector2(50, 40), Vector2(70, 90), Vector2(40, 150),
		Vector2(65, 210), Vector2(45, 270), Vector2(75, 330),
		Vector2(50, 390), Vector2(70, 450), Vector2(55, 510)
	]
	for fc in fog_centers:
		canvas.draw_circle(fc, 65.0, Color(0.05, 0.07, 0.11, 0.65))
		canvas.draw_circle(fc + Vector2(-8, 6), 50.0, Color(0.06, 0.09, 0.15, 0.50))
		canvas.draw_circle(fc + Vector2(10, -7), 38.0, Color(0.08, 0.12, 0.19, 0.35))

	# 5. Agar keyingi bob qulflangan bo'lsa: Tuman orasida sokin qulf belgisi
	if not next_unlocked:
		var lock_y: float = 270.0
		canvas.draw_circle(Vector2(seam_x, lock_y), 20.0, Color(0.03, 0.04, 0.06, 0.70))
		canvas.draw_rect(Rect2(seam_x - 8, lock_y - 4, 16, 14), Color(0.75, 0.60, 0.20, 0.85))
		canvas.draw_arc(Vector2(seam_x, lock_y - 6), 6.0, -PI, 0, 16, Color(0.85, 0.72, 0.30, 0.90), 2.5)
		canvas.draw_circle(Vector2(seam_x, lock_y + 3), 2.0, Color(0.1, 0.1, 0.1, 0.9))

func _draw_clouds_right_canvas(canvas: Control) -> void:
	if not canvas: return
	for x_step in range(10):
		var alpha: float = 0.08 * (x_step + 1)
		var rx: float = 830.0 + x_step * 13.0
		canvas.draw_rect(Rect2(rx, 0, 13, 540), Color(0.04, 0.06, 0.10, alpha))
		
	var cloud_centers_back: Array[Vector2] = [
		Vector2(875, 40), Vector2(905, 120), Vector2(870, 200),
		Vector2(915, 280), Vector2(875, 360), Vector2(925, 440), Vector2(885, 520)
	]
	for c in cloud_centers_back:
		canvas.draw_circle(c, 70.0, Color(0.05, 0.07, 0.12, 0.88))
		
	var cloud_centers_mid: Array[Vector2] = [
		Vector2(900, 20), Vector2(940, 95), Vector2(895, 175),
		Vector2(950, 255), Vector2(905, 335), Vector2(955, 415), Vector2(920, 495)
	]
	for c in cloud_centers_mid:
		canvas.draw_circle(c, 58.0, Color(0.07, 0.10, 0.18, 0.94))
		
	var cloud_centers_front: Array[Vector2] = [
		Vector2(935, 60), Vector2(965, 140), Vector2(930, 220),
		Vector2(970, 300), Vector2(940, 380), Vector2(975, 460)
	]
	for c in cloud_centers_front:
		canvas.draw_circle(c, 50.0, Color(0.10, 0.15, 0.24, 0.98))
		canvas.draw_arc(c, 50.0, -PI, PI, 32, Color(0.28, 0.40, 0.58, 0.35), 1.5)

func _draw_clouds_left_canvas(canvas: Control) -> void:
	if not canvas: return
	for x_step in range(10):
		var alpha: float = 0.08 * (10 - x_step)
		var rx: float = x_step * 13.0
		canvas.draw_rect(Rect2(rx, 0, 13, 540), Color(0.04, 0.06, 0.10, alpha))
		
	var cloud_centers_back: Array[Vector2] = [
		Vector2(85, 40), Vector2(55, 120), Vector2(90, 200),
		Vector2(45, 280), Vector2(85, 360), Vector2(35, 440), Vector2(75, 520)
	]
	for c in cloud_centers_back:
		canvas.draw_circle(c, 70.0, Color(0.05, 0.07, 0.12, 0.88))
		
	var cloud_centers_mid: Array[Vector2] = [
		Vector2(60, 20), Vector2(20, 95), Vector2(65, 175),
		Vector2(10, 255), Vector2(55, 335), Vector2(5, 415), Vector2(40, 495)
	]
	for c in cloud_centers_mid:
		canvas.draw_circle(c, 58.0, Color(0.07, 0.10, 0.18, 0.94))
		
	var cloud_centers_front: Array[Vector2] = [
		Vector2(25, 60), Vector2(-5, 140), Vector2(30, 220),
		Vector2(-10, 300), Vector2(20, 380), Vector2(-15, 460)
	]
	for c in cloud_centers_front:
		canvas.draw_circle(c, 50.0, Color(0.10, 0.15, 0.24, 0.98))
		canvas.draw_arc(c, 50.0, -PI, PI, 32, Color(0.28, 0.40, 0.58, 0.35), 1.5)

func _on_back_pressed() -> void:
	SoundManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
