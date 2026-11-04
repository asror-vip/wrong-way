extends Control

# ProfileModal - Wrong Way Modern Player Identity & Stats Card
# - High-fidelity dark obsidian & glowing glass aesthetic
# - Live Avatar Preview (Hero Frame)
# - Interactive 5-Character SVG Avatar Selector Gallery
# - In-game Campaign Stats (Stars, Unlocked Levels, Personal Best)
# - One-click Player Tag Copy with vector icon
# - Name Customizer with validation

@onready var modal_panel: Panel = get_node_or_null("CenterContainer/Panel")
@onready var close_top_btn: Button = get_node_or_null("CenterContainer/Panel/CloseBtn")
@onready var cancel_btn: Button = get_node_or_null("CenterContainer/Panel/ContentVBox/ActionHBox/CancelBtn")
@onready var save_btn: Button = get_node_or_null("CenterContainer/Panel/ContentVBox/ActionHBox/SaveBtn")

@onready var name_input: LineEdit = get_node_or_null("CenterContainer/Panel/ContentVBox/HeroHBox/InfoVBox/NameEdit")
@onready var tag_label: Label = get_node_or_null("CenterContainer/Panel/ContentVBox/HeroHBox/InfoVBox/TagHBox/TagPanel/TagLabel")
@onready var copy_btn: Button = get_node_or_null("CenterContainer/Panel/ContentVBox/HeroHBox/InfoVBox/TagHBox/CopyBtn")
@onready var auth_label: Label = get_node_or_null("CenterContainer/Panel/ContentVBox/HeroHBox/InfoVBox/TagHBox/AuthLabel")

@onready var avatar_preview: TextureRect = get_node_or_null("CenterContainer/Panel/ContentVBox/HeroHBox/AvatarFrame/AvatarPreview")
@onready var avatar_grid: HBoxContainer = get_node_or_null("CenterContainer/Panel/ContentVBox/AvatarSection/AvatarGrid")

@onready var stars_label: Label = get_node_or_null("CenterContainer/Panel/ContentVBox/StatsHBox/StarsChip/HBox/StarsLabel")
@onready var stars_icon: TextureRect = get_node_or_null("CenterContainer/Panel/ContentVBox/StatsHBox/StarsChip/HBox/Icon")

@onready var levels_label: Label = get_node_or_null("CenterContainer/Panel/ContentVBox/StatsHBox/LevelsChip/HBox/LevelsLabel")
@onready var levels_icon: TextureRect = get_node_or_null("CenterContainer/Panel/ContentVBox/StatsHBox/LevelsChip/HBox/Icon")

@onready var best_label: Label = get_node_or_null("CenterContainer/Panel/ContentVBox/StatsHBox/BestChip/HBox/BestLabel")
@onready var best_icon: TextureRect = get_node_or_null("CenterContainer/Panel/ContentVBox/StatsHBox/BestChip/HBox/Icon")

@onready var toast_label: Label = get_node_or_null("CenterContainer/Panel/ToastLabel")

var selected_avatar_idx: int = 1
const AVATAR_KEYS: Array[String] = ["avatar_player", "avatar_ninja", "avatar_shadow", "avatar_robot", "avatar_pro"]
var avatar_buttons: Array[Button] = []

func _ready() -> void:
	visible = false
	if close_top_btn: close_top_btn.pressed.connect(close)
	if cancel_btn: cancel_btn.pressed.connect(close)
	if save_btn: save_btn.pressed.connect(_on_save_pressed)
	if copy_btn: copy_btn.pressed.connect(_on_copy_tag)
	
	_apply_modal_styles()
	_setup_avatar_buttons()

func open() -> void:
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	if name_input:
		name_input.text = ProfileManager.username
	if tag_label:
		tag_label.text = "#" + ProfileManager.player_tag
		
	selected_avatar_idx = ProfileManager.avatar_index
	if selected_avatar_idx < 1 or selected_avatar_idx > AVATAR_KEYS.size():
		selected_avatar_idx = 1
		
	_update_avatar_preview()
	_refresh_avatar_grid_styles()
	_load_stats()
	
	if auth_label:
		if ProfileManager.auth_provider == "google":
			auth_label.text = "• Google Tasdiqlangan"
			auth_label.add_theme_color_override("font_color", Color(0.38, 0.85, 0.55))
		else:
			auth_label.text = "• Mehmon Hisobi"
			auth_label.add_theme_color_override("font_color", Color(0.55, 0.62, 0.75))
			
	if toast_label:
		toast_label.text = ""

func close() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	await tween.finished
	visible = false

func _apply_modal_styles() -> void:
	# Close button - circular stylebox
	if close_top_btn:
		close_top_btn.custom_minimum_size = Vector2(36, 36)
		close_top_btn.size = Vector2(36, 36)
		close_top_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		close_top_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		
		var c_norm := StyleBoxFlat.new()
		c_norm.set_corner_radius_all(18)
		c_norm.corner_detail = 16
		c_norm.bg_color = Color(0.09, 0.12, 0.18, 0.8)
		c_norm.border_color = Color(0.30, 0.40, 0.55, 0.6)
		c_norm.set_border_width_all(1)
		
		var c_hov := c_norm.duplicate() as StyleBoxFlat
		c_hov.bg_color = Color(0.15, 0.20, 0.30, 0.95)
		c_hov.border_color = Color(0.38, 0.74, 0.97, 0.95)
		
		close_top_btn.add_theme_stylebox_override("normal", c_norm)
		close_top_btn.add_theme_stylebox_override("hover", c_hov)
		close_top_btn.add_theme_stylebox_override("pressed", c_norm)
		close_top_btn.add_theme_stylebox_override("focus", c_norm)
		close_top_btn.add_theme_font_size_override("font_size", 14)
		close_top_btn.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
		
	# Copy button icon (icon only, no box/frame)
	if copy_btn:
		copy_btn.text = ""
		copy_btn.flat = true
		copy_btn.focus_mode = Control.FOCUS_NONE
		var empty_sb := StyleBoxEmpty.new()
		copy_btn.add_theme_stylebox_override("normal", empty_sb)
		copy_btn.add_theme_stylebox_override("hover", empty_sb)
		copy_btn.add_theme_stylebox_override("pressed", empty_sb)
		copy_btn.add_theme_stylebox_override("focus", empty_sb)
		copy_btn.icon = IconFactory.get_icon("copy", 0.75)
		copy_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		copy_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		
	# Name input style
	if name_input:
		var n_norm := StyleBoxFlat.new()
		n_norm.bg_color = Color(0.06, 0.08, 0.13, 0.9)
		n_norm.border_color = Color(0.24, 0.34, 0.48, 0.65)
		n_norm.set_border_width_all(1)
		n_norm.set_corner_radius_all(10)
		n_norm.content_margin_left = 12
		n_norm.content_margin_right = 12
		
		var n_foc := n_norm.duplicate() as StyleBoxFlat
		n_foc.border_color = Color(0.38, 0.74, 0.97, 0.95)
		n_foc.shadow_color = Color(0.38, 0.74, 0.97, 0.25)
		n_foc.shadow_size = 4
		
		name_input.add_theme_stylebox_override("normal", n_norm)
		name_input.add_theme_stylebox_override("focus", n_foc)
		
	# Stats icons
	if stars_icon:
		stars_icon.texture = IconFactory.get_icon("star_gold", 0.85)
	if levels_icon:
		levels_icon.texture = IconFactory.get_icon("map", 0.85)
	if best_icon:
		best_icon.texture = IconFactory.get_icon("trophy_white", 0.85)

func _setup_avatar_buttons() -> void:
	if not avatar_grid:
		return
		
	for child in avatar_grid.get_children():
		child.queue_free()
	avatar_buttons.clear()
	
	for i in range(AVATAR_KEYS.size()):
		var idx: int = i + 1
		var av_key: String = AVATAR_KEYS[i]
		
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(56, 56)
		btn.size = Vector2(56, 56)
		btn.focus_mode = Control.FOCUS_NONE
		btn.icon = IconFactory.get_icon(av_key, 0.9)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		
		btn.pressed.connect(func():
			selected_avatar_idx = idx
			_update_avatar_preview()
			_refresh_avatar_grid_styles()
			var sm = get_node_or_null("/root/SoundManager")
			if sm and sm.has_method("play"):
				sm.play("click")
		)
		
		avatar_grid.add_child(btn)
		avatar_buttons.append(btn)
		
	_refresh_avatar_grid_styles()

func _refresh_avatar_grid_styles() -> void:
	for i in range(avatar_buttons.size()):
		var btn: Button = avatar_buttons[i]
		var idx: int = i + 1
		var is_selected: bool = (idx == selected_avatar_idx)
		
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(14)
		style.corner_detail = 12
		
		if is_selected:
			style.bg_color = Color(0.12, 0.20, 0.32, 0.95)
			style.border_color = Color(0.38, 0.74, 0.97, 1.0)
			style.set_border_width_all(2)
			style.shadow_color = Color(0.38, 0.74, 0.97, 0.45)
			style.shadow_size = 6
		else:
			style.bg_color = Color(0.06, 0.09, 0.14, 0.75)
			style.border_color = Color(0.20, 0.28, 0.42, 0.5)
			style.set_border_width_all(1)
			
		var style_hov := style.duplicate() as StyleBoxFlat
		if not is_selected:
			style_hov.bg_color = Color(0.10, 0.15, 0.24, 0.9)
			style_hov.border_color = Color(0.38, 0.74, 0.97, 0.7)
			
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style_hov)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("focus", style)

func _update_avatar_preview() -> void:
	if avatar_preview:
		var key_idx := (selected_avatar_idx - 1) % AVATAR_KEYS.size()
		if key_idx < 0: key_idx = 0
		var av_key := AVATAR_KEYS[key_idx]
		avatar_preview.texture = IconFactory.get_icon(av_key, 1.0)

func _load_stats() -> void:
	var save_sys = get_node_or_null("/root/SaveSystem")
	if not save_sys:
		save_sys = get_node_or_null("/root/SaveManager")
	if save_sys:
		if stars_label and save_sys.has_method("get_total_stars"):
			stars_label.text = "%d Yulduz" % save_sys.get_total_stars()
		if levels_label:
			var cur_lvl: int = 1
			if save_sys.has_method("get_highest_completed_level"):
				cur_lvl = save_sys.get_highest_completed_level()
			elif save_sys.has_method("get_highest_unlocked_level"):
				cur_lvl = save_sys.get_highest_unlocked_level()
			if cur_lvl <= 0:
				cur_lvl = 1
			levels_label.text = "%d-Daraja" % cur_lvl
		if best_label and save_sys.has_method("get_overall_best_text"):
			var best_str: String = save_sys.get_overall_best_text()
			if best_str != "Mavjud emas" and not best_str.is_empty():
				var time_part := best_str.split(" ")[0]
				best_label.text = time_part + " Rekord"
			else:
				best_label.text = "Rekord: —"

func _on_copy_tag() -> void:
	DisplayServer.clipboard_set(ProfileManager.player_tag)
	if copy_btn:
		copy_btn.text = ""
		copy_btn.icon = IconFactory.get_icon("check", 0.75)
		var tw := create_tween()
		tw.tween_interval(1.2)
		tw.tween_callback(func():
			if copy_btn:
				copy_btn.text = ""
				copy_btn.icon = IconFactory.get_icon("copy", 0.75)
		)
	_show_toast("ID nusxalandi: #" + ProfileManager.player_tag)

func _on_save_pressed() -> void:
	if not name_input:
		return
	var new_name := name_input.text.strip_edges()
	if new_name.is_empty():
		_show_toast("Ism bo'sh bo'lishi mumkin emas!")
		return
		
	ProfileManager.update_profile(new_name, selected_avatar_idx)
	_show_toast("Profil muvaffaqiyatli saqlandi!")
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play"):
		sm.play("click")
		
	await get_tree().create_timer(0.55).timeout
	close()

func _show_toast(msg: String) -> void:
	if toast_label:
		toast_label.text = msg
		toast_label.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_property(toast_label, "modulate:a", 0.0, 2.0)
