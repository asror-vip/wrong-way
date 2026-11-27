extends Control

# Wrong Way - Game HUD Controller
# Atmospheric Minimalist HUD with Circular Glass Controls & Diamond Header

@onready var top_hud: Control = get_node_or_null("TopHUD")
@onready var pause_btn: Button = get_node_or_null("TopHUD/PauseBtn")
@onready var level_label: Label = get_node_or_null("TopHUD/CenterHeader/HBox/LevelLabel")
@onready var time_icon: TextureRect = get_node_or_null("TopHUD/RightBox/TimeChip/HBox/TimeIcon")
@onready var time_label: Label = get_node_or_null("TopHUD/RightBox/TimeChip/HBox/TimeLabel")
@onready var skull_icon: TextureRect = get_node_or_null("TopHUD/RightBox/DeathsChip/HBox/SkullIcon")
@onready var deaths_label: Label = get_node_or_null("TopHUD/RightBox/DeathsChip/HBox/DeathsLabel")

@onready var left_btn: Button = get_node_or_null("TouchControls/LeftBtn")
@onready var right_btn: Button = get_node_or_null("TouchControls/RightBtn")
@onready var dash_btn: Button = get_node_or_null("TouchControls/DashBtn")
@onready var jump_btn: Button = get_node_or_null("TouchControls/JumpBtn")
@onready var touch_controls: Control = get_node_or_null("TouchControls")

@onready var countdown_box: CenterContainer = get_node_or_null("CountdownBox")
@onready var countdown_label: Label = get_node_or_null("CountdownBox/CountdownLabel")

var current_deaths: int = 0
var _touch_fingers: Dictionary = {}
var _active_touch_actions: Dictionary = {}

# Level 1 Interactive Onboarding Tutorial + TrapFloorMid Toast
var _mobile_mode_override: int = -1
var _tutorial_active: bool = false
var _tutorial_step: int = -1
var _tutorial_pulse_t: float = 0.0
var _tutorial_banner: PanelContainer = null
var _tutorial_badge_panel: PanelContainer = null
var _tutorial_badge_lbl: Label = null
var _tutorial_text_lbl: Label = null
var _tutorial_pulse_overlay: Control = null
var _tutorial_tween: Tween = null

var _trap_toast_panel: PanelContainer = null
var _trap_toast_lbl: Label = null
var _trap_toast_tween: Tween = null
var _trap_toast_shown: bool = false
var _cached_trap_floor: Node = null

func _ready() -> void:
	LocaleManager.language_changed.connect(_on_language_changed)
	GameManager.player_died.connect(_on_player_died)
	GameManager.level_started.connect(_on_level_started)
	GameManager.level_completed.connect(_on_level_completed)
	SaveManager.touch_layout_changed.connect(_apply_custom_touch_layout)
	get_viewport().size_changed.connect(_apply_custom_touch_layout)
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_signal("banner_visibility_changed"):
		adm.banner_visibility_changed.connect(_on_banner_visibility_changed)
	
	_setup_tutorial_ui()
	_apply_custom_touch_layout()
	_setup_icons()
	_update_texts()
	
	if left_btn: _setup_touch_btn(left_btn)
	if right_btn: _setup_touch_btn(right_btn)
	if dash_btn: _setup_touch_btn(dash_btn)
	if jump_btn: _setup_touch_btn(jump_btn)
	_update_touch_visibility()
	_refresh_tutorial_activation()

func _exit_tree() -> void:
	_release_all_touch_actions()
	if _tutorial_tween and _tutorial_tween.is_valid():
		_tutorial_tween.kill()
	if _trap_toast_tween and _trap_toast_tween.is_valid():
		_trap_toast_tween.kill()
	if LocaleManager and LocaleManager.language_changed.is_connected(_on_language_changed):
		LocaleManager.language_changed.disconnect(_on_language_changed)
	if GameManager:
		if GameManager.player_died.is_connected(_on_player_died):
			GameManager.player_died.disconnect(_on_player_died)
		if GameManager.level_started.is_connected(_on_level_started):
			GameManager.level_started.disconnect(_on_level_started)
		if GameManager.level_completed.is_connected(_on_level_completed):
			GameManager.level_completed.disconnect(_on_level_completed)
	if SaveManager and SaveManager.touch_layout_changed.is_connected(_apply_custom_touch_layout):
		SaveManager.touch_layout_changed.disconnect(_apply_custom_touch_layout)
	var vp := get_viewport()
	if vp and vp.size_changed.is_connected(_apply_custom_touch_layout):
		vp.size_changed.disconnect(_apply_custom_touch_layout)
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_signal("banner_visibility_changed") and adm.banner_visibility_changed.is_connected(_on_banner_visibility_changed):
		adm.banner_visibility_changed.disconnect(_on_banner_visibility_changed)

func is_mobile_platform() -> bool:
	if _mobile_mode_override == 1:
		return true
	if _mobile_mode_override == 0:
		return false
	return (
		OS.has_feature("android")
		or OS.has_feature("ios")
		or OS.has_feature("mobile")
		or OS.has_feature("web_android")
		or OS.has_feature("web_ios")
	)

func set_mobile_mode_override(mode: int) -> void:
	_mobile_mode_override = mode
	_update_touch_visibility()
	if _tutorial_active and _tutorial_step >= 0:
		_render_tutorial_step(_tutorial_step, false)

func _update_touch_visibility() -> void:
	# Sensorli tugmalar faqat mobil qurilmalarda ko'rsatiladi (PC da doim yashirin).
	var is_mob := is_mobile_platform()
	if touch_controls:
		touch_controls.visible = is_mob
		if not is_mob:
			_release_all_touch_actions()

func _on_banner_visibility_changed(_is_visible: bool) -> void:
	_apply_custom_touch_layout()

func _apply_custom_touch_layout() -> void:
	var def_positions := UIResponsive.get_default_touch_positions(self)
	var insets := UIResponsive.get_safe_insets(self)
	var vp := UIResponsive.get_viewport_size(self)
	var adm = get_node_or_null("/root/AdManager")
	var banner_h: float = adm.get_top_banner_height() \
		if adm and adm.has_method("get_top_banner_height") else 0.0
	if top_hud:
		top_hud.offset_top = banner_h
		top_hud.offset_bottom = banner_h + 56.0
	
	if pause_btn:
		pause_btn.position = Vector2(20.0 + insets["left"], 16.0 + insets["top"])
		
	var right_box: Control = get_node_or_null("TopHUD/RightBox")
	if right_box:
		var rx: float = vp.x - right_box.size.x - 20.0 - float(insets["right"])
		right_box.position = Vector2(rx, 16.0 + float(insets["top"]))

	var sm = get_node_or_null("/root/SaveManager")
	var btn_sc: float = float(sm.touch_button_scale) if sm else 1.0
	var sz_lr := Vector2(82.0, 82.0) * btn_sc
	var sz_dash := Vector2(78.0, 78.0) * btn_sc
	var sz_jump := Vector2(88.0, 88.0) * btn_sc

	if left_btn:
		left_btn.custom_minimum_size = sz_lr
		left_btn.size = sz_lr
	if right_btn:
		right_btn.custom_minimum_size = sz_lr
		right_btn.size = sz_lr
	if dash_btn:
		dash_btn.custom_minimum_size = sz_dash
		dash_btn.size = sz_dash
	if jump_btn:
		jump_btn.custom_minimum_size = sz_jump
		jump_btn.size = sz_jump
	
	if sm and not sm.custom_touch_layout.is_empty():
		if left_btn: left_btn.position = sm.get_touch_pos("left", def_positions["left"])
		if right_btn: right_btn.position = sm.get_touch_pos("right", def_positions["right"])
		if dash_btn: dash_btn.position = sm.get_touch_pos("dash", def_positions["dash"])
		if jump_btn: jump_btn.position = sm.get_touch_pos("jump", def_positions["jump"])
	else:
		if left_btn: left_btn.position = def_positions["left"]
		if right_btn: right_btn.position = def_positions["right"]
		if dash_btn: dash_btn.position = def_positions["dash"]
		if jump_btn: jump_btn.position = def_positions["jump"]
	_position_tutorial_ui(banner_h, float(insets["top"]))

func _process(delta: float) -> void:
	if time_label:
		if GameManager.is_level_running:
			var elapsed_sec: float = (float(Time.get_ticks_msec()) - GameManager.level_start_time) / 1000.0
			time_label.text = "%ds" % int(maxf(elapsed_sec, 0.0))
		elif GameManager.level_timer_ms > 0:
			time_label.text = "%ds" % int(GameManager.level_timer_ms / 1000.0)
	_update_tutorial_runtime(delta)

func _setup_icons() -> void:
	if pause_btn:
		pause_btn.icon = IconFactory.get_icon("circle_btn_pause", 1.0)
		pause_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pause_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	if time_icon:
		time_icon.texture = IconFactory.get_icon("timer_white", 0.8)
	if skull_icon:
		skull_icon.texture = IconFactory.get_icon("skull_white", 0.8)
	if left_btn:
		left_btn.icon = IconFactory.get_icon("circle_btn_left", 1.25)
		left_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		left_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	if right_btn:
		right_btn.icon = IconFactory.get_icon("circle_btn_right", 1.25)
		right_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	if dash_btn:
		dash_btn.icon = IconFactory.get_icon("circle_btn_dash", 1.20)
		dash_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dash_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	if jump_btn:
		jump_btn.icon = IconFactory.get_icon("circle_btn_jump", 1.30)
		jump_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		jump_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER

func _on_language_changed(_lang: String) -> void:
	_update_texts()
	if _tutorial_active and _tutorial_step >= 0:
		_render_tutorial_step(_tutorial_step, false)
	if _trap_toast_lbl and _trap_toast_panel and _trap_toast_panel.visible:
		_trap_toast_lbl.text = LocaleManager.t("tut_trap_floor_toast")

func _on_level_started(_level_id: int) -> void:
	current_deaths = GameManager.level_deaths
	_cached_trap_floor = null
	_update_texts()
	_update_deaths_display()
	_refresh_tutorial_activation()

func _on_level_completed(_lvl: int, _time_ms: float, _deaths: int, _stars: int) -> void:
	_set_tutorial_visible(false)

func _update_texts() -> void:
	if level_label:
		if GameManager.is_duel_mode:
			level_label.text = "DUEL · DARAJA %d" % GameManager.current_level_id
		else:
			level_label.text = LocaleManager.t("level_header", [GameManager.current_level_id])
	_update_deaths_display()

func start_duel_countdown() -> void:
	if not countdown_box or not countdown_label:
		GameManager.is_countdown_active = false
		GameManager.is_level_running = true
		DuelService.start_match()
		return
		
	countdown_box.visible = true
	GameManager.is_countdown_active = true
	GameManager.is_level_running = false
	
	for count in [3, 2, 1]:
		countdown_label.text = str(count)
		countdown_label.scale = Vector2(1.6, 1.6)
		var tw := create_tween()
		tw.tween_property(countdown_label, "scale", Vector2.ONE, 0.35)
		SoundManager.play("click")
		await get_tree().create_timer(0.85).timeout
		
	countdown_label.text = "START!"
	countdown_label.scale = Vector2(1.6, 1.6)
	var tw2 := create_tween()
	tw2.tween_property(countdown_label, "scale", Vector2.ONE, 0.35)
	SoundManager.play("win")
	await get_tree().create_timer(0.45).timeout
	countdown_box.visible = false
	
	GameManager.is_countdown_active = false
	GameManager.is_level_running = true
	GameManager.level_start_time = Time.get_ticks_msec()
	DuelService.start_match()

func _on_player_died(deaths_count: int) -> void:
	current_deaths = deaths_count
	_update_deaths_display()

func _update_deaths_display() -> void:
	if deaths_label:
		deaths_label.text = "%d" % current_deaths

func _setup_touch_btn(btn: Button) -> void:
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.focus_mode = Control.FOCUS_NONE

func _input(event: InputEvent) -> void:
	if not touch_controls or not touch_controls.visible or get_tree().paused:
		if not _active_touch_actions.is_empty():
			_release_all_touch_actions()
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			var act := _get_touch_action_at(st.position)
			if not act.is_empty():
				_touch_fingers[st.index] = act
				_sync_touch_actions()
		elif _touch_fingers.has(st.index):
			_touch_fingers.erase(st.index)
			_sync_touch_actions()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _touch_fingers.has(sd.index):
			var cur_act := str(_touch_fingers[sd.index])
			if cur_act == "move_left" or cur_act == "move_right":
				var new_act := _get_touch_action_at(sd.position)
				if (new_act == "move_left" or new_act == "move_right") \
						and new_act != cur_act:
					_touch_fingers[sd.index] = new_act
					_sync_touch_actions()

func _get_touch_action_at(screen_pos: Vector2) -> String:
	var local_pos := get_global_transform_with_canvas().affine_inverse() * screen_pos
	var pad := 16.0
	if jump_btn and Rect2(jump_btn.position, jump_btn.size).grow(pad).has_point(local_pos):
		return "jump"
	if dash_btn and Rect2(dash_btn.position, dash_btn.size).grow(pad).has_point(local_pos):
		return "dash"
	if left_btn and Rect2(left_btn.position, left_btn.size).grow(pad).has_point(local_pos):
		return "move_left"
	if right_btn and Rect2(right_btn.position, right_btn.size).grow(pad).has_point(local_pos):
		return "move_right"
	return ""

func _sync_touch_actions() -> void:
	var next_actions: Dictionary = {}
	for act in _touch_fingers.values():
		next_actions[str(act)] = true

	for act in _active_touch_actions.keys():
		if not next_actions.has(act):
			Input.action_release(str(act))

	for act in next_actions.keys():
		if not _active_touch_actions.has(act):
			Input.action_press(str(act))

	_active_touch_actions = next_actions

func _release_all_touch_actions() -> void:
	_touch_fingers.clear()
	for act in _active_touch_actions.keys():
		Input.action_release(str(act))
	_active_touch_actions.clear()

func _on_pause_btn_pressed() -> void:
	SoundManager.play("click")
	var parent_canvas = get_parent()
	if parent_canvas:
		var pause_modal = parent_canvas.get_node_or_null("PauseModal")
		if pause_modal and pause_modal.has_method("open_pause"):
			pause_modal.open_pause()
			return
	var pause_node = get_tree().current_scene.find_child("PauseModal", true, false)
	if pause_node and pause_node.has_method("open_pause"):
		pause_node.open_pause()

# -------------------------------------------------------------
# Level 1 Interactive First-Time Onboarding Tutorial + Trap Toast
# -------------------------------------------------------------
func _setup_tutorial_ui() -> void:
	# Pulsing touch-button highlight overlay (non-blocking)
	_tutorial_pulse_overlay = Control.new()
	_tutorial_pulse_overlay.name = "TutorialPulseOverlay"
	_tutorial_pulse_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tutorial_pulse_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_pulse_overlay.visible = false
	add_child(_tutorial_pulse_overlay)
	_tutorial_pulse_overlay.draw.connect(_on_tutorial_pulse_draw)

	# Non-blocking top-center onboarding hint pill
	var banner_anchor := CenterContainer.new()
	banner_anchor.name = "TutorialBannerAnchor"
	banner_anchor.anchor_left = 0.0
	banner_anchor.anchor_right = 1.0
	banner_anchor.anchor_top = 0.0
	banner_anchor.anchor_bottom = 0.0
	banner_anchor.offset_top = 60.0
	banner_anchor.offset_bottom = 104.0
	banner_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner_anchor)

	_tutorial_banner = PanelContainer.new()
	_tutorial_banner.name = "TutorialBanner"
	_tutorial_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_banner.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.14, 0.84)
	sb.border_color = Color(0.22, 0.74, 0.97, 0.72)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	sb.shadow_size = 8
	sb.content_margin_left = 14.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 7.0
	sb.content_margin_bottom = 7.0
	_tutorial_banner.add_theme_stylebox_override("panel", sb)
	banner_anchor.add_child(_tutorial_banner)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	_tutorial_banner.add_child(hbox)

	_tutorial_badge_panel = PanelContainer.new()
	_tutorial_badge_panel.name = "KeyBadge"
	_tutorial_badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = Color(0.12, 0.24, 0.38, 0.95)
	badge_sb.border_color = Color(0.38, 0.82, 1.0, 0.90)
	badge_sb.set_border_width_all(1)
	badge_sb.set_corner_radius_all(7)
	badge_sb.content_margin_left = 8.0
	badge_sb.content_margin_right = 8.0
	badge_sb.content_margin_top = 2.0
	badge_sb.content_margin_bottom = 2.0
	_tutorial_badge_panel.add_theme_stylebox_override("panel", badge_sb)
	hbox.add_child(_tutorial_badge_panel)

	_tutorial_badge_lbl = Label.new()
	_tutorial_badge_lbl.name = "BadgeLbl"
	_tutorial_badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_badge_lbl.add_theme_font_size_override("font_size", 11)
	_tutorial_badge_lbl.add_theme_color_override("font_color", Color(0.76, 0.95, 1.0))
	_tutorial_badge_panel.add_child(_tutorial_badge_lbl)

	_tutorial_text_lbl = Label.new()
	_tutorial_text_lbl.name = "HintLbl"
	_tutorial_text_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_text_lbl.add_theme_font_size_override("font_size", 13)
	_tutorial_text_lbl.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	hbox.add_child(_tutorial_text_lbl)

	# Bonus #3: Playful Level 1 TrapFloorMid Toast (non-blocking)
	var toast_anchor := CenterContainer.new()
	toast_anchor.name = "TrapToastAnchor"
	toast_anchor.anchor_left = 0.0
	toast_anchor.anchor_right = 1.0
	toast_anchor.anchor_top = 0.0
	toast_anchor.anchor_bottom = 0.0
	toast_anchor.offset_top = 108.0
	toast_anchor.offset_bottom = 148.0
	toast_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_anchor)

	_trap_toast_panel = PanelContainer.new()
	_trap_toast_panel.name = "TrapToast"
	_trap_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trap_toast_panel.visible = false
	var t_sb := StyleBoxFlat.new()
	t_sb.bg_color = Color(0.16, 0.05, 0.08, 0.90)
	t_sb.border_color = Color(0.97, 0.44, 0.44, 0.85)
	t_sb.set_border_width_all(1)
	t_sb.set_corner_radius_all(14)
	t_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
	t_sb.shadow_size = 8
	t_sb.content_margin_left = 16.0
	t_sb.content_margin_right = 16.0
	t_sb.content_margin_top = 7.0
	t_sb.content_margin_bottom = 7.0
	_trap_toast_panel.add_theme_stylebox_override("panel", t_sb)
	toast_anchor.add_child(_trap_toast_panel)

	_trap_toast_lbl = Label.new()
	_trap_toast_lbl.name = "TrapToastLbl"
	_trap_toast_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trap_toast_lbl.add_theme_font_size_override("font_size", 13)
	_trap_toast_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.90))
	_trap_toast_panel.add_child(_trap_toast_lbl)

func _position_tutorial_ui(banner_h: float, top_inset: float) -> void:
	var base_y := banner_h + top_inset + 60.0
	var b_anchor := get_node_or_null("TutorialBannerAnchor") as Control
	if b_anchor:
		b_anchor.offset_top = base_y
		b_anchor.offset_bottom = base_y + 44.0
	var t_anchor := get_node_or_null("TrapToastAnchor") as Control
	if t_anchor:
		t_anchor.offset_top = base_y + 48.0
		t_anchor.offset_bottom = base_y + 88.0

func _should_show_tutorial() -> bool:
	if GameManager == null:
		return false
	if GameManager.current_level_id != 1:
		return false
	if GameManager.is_duel_mode or GameManager.is_custom_editor_mode:
		return false
	var sm = get_node_or_null("/root/SaveManager")
	if sm and "tutorial_completed" in sm and bool(sm.tutorial_completed):
		return false
	return true

func _refresh_tutorial_activation() -> void:
	var active := _should_show_tutorial()
	_tutorial_active = active
	if active:
		_tutorial_step = -1
		evaluate_tutorial_for_x(80.0)
	else:
		_set_tutorial_visible(false)

func _set_tutorial_visible(vis: bool) -> void:
	_tutorial_active = vis
	if _tutorial_banner:
		_tutorial_banner.visible = vis
	if _tutorial_pulse_overlay:
		_tutorial_pulse_overlay.visible = vis and is_mobile_platform()

func is_tutorial_active() -> bool:
	return _tutorial_active and _tutorial_banner != null and _tutorial_banner.visible

func get_tutorial_step() -> int:
	return _tutorial_step

func is_trap_toast_visible() -> bool:
	return _trap_toast_panel != null and _trap_toast_panel.visible

func evaluate_tutorial_for_x(px: float) -> void:
	if not _tutorial_active:
		return
	var step := 0
	if px >= 700.0:
		step = 3
	elif px >= 290.0:
		step = 2
	elif px >= 155.0:
		step = 1
	else:
		step = 0
	if step != _tutorial_step:
		_tutorial_step = step
		_render_tutorial_step(step, true)

func _render_tutorial_step(step: int, animate: bool) -> void:
	if not _tutorial_banner or not _tutorial_text_lbl:
		return
	var is_mob := is_mobile_platform()
	var key := ""
	var badge := ""
	match step:
		0:
			key = "tut_step_move_mobile" if is_mob else "tut_step_move_pc"
			badge = "1/4" if is_mob else "A / D"
		1:
			key = "tut_step_jump_mobile" if is_mob else "tut_step_jump_pc"
			badge = "2/4" if is_mob else "SPACE"
		2:
			key = "tut_step_dash_mobile" if is_mob else "tut_step_dash_pc"
			badge = "3/4" if is_mob else "SHIFT"
		_:
			key = "tut_step_door"
			badge = "★ ★"

	_tutorial_text_lbl.text = LocaleManager.t(key)
	if _tutorial_badge_lbl:
		_tutorial_badge_lbl.text = badge
	_tutorial_banner.visible = true
	if _tutorial_pulse_overlay:
		_tutorial_pulse_overlay.visible = is_mob and step < 3
		_tutorial_pulse_overlay.queue_redraw()

	if animate:
		if _tutorial_tween and _tutorial_tween.is_valid():
			_tutorial_tween.kill()
		_tutorial_banner.modulate.a = 0.0
		_tutorial_tween = create_tween()
		_tutorial_tween.tween_property(_tutorial_banner, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _update_tutorial_runtime(delta: float) -> void:
	if not _tutorial_active:
		return
	if not GameManager.is_level_running or GameManager.current_level_id != 1:
		return

	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p != null and is_instance_valid(p):
		if not ("is_dead" in p and p.is_dead):
			evaluate_tutorial_for_x(p.global_position.x)

	# Bonus #3: Detect first trigger of Level 1's hidden TrapFloorMid
	if not _trap_toast_shown:
		if _cached_trap_floor == null or not is_instance_valid(_cached_trap_floor):
			for tr in get_tree().get_nodes_in_group("traps"):
				if tr.name == "TrapFloorMid":
					_cached_trap_floor = tr
					break
		if _cached_trap_floor != null and is_instance_valid(_cached_trap_floor):
			if ("is_triggered" in _cached_trap_floor and bool(_cached_trap_floor.is_triggered)) \
					or ("is_falling" in _cached_trap_floor and bool(_cached_trap_floor.is_falling)):
				show_trap_floor_toast()

	if _tutorial_pulse_overlay and _tutorial_pulse_overlay.visible:
		_tutorial_pulse_t += delta * 2.6
		_tutorial_pulse_overlay.queue_redraw()

func show_trap_floor_toast() -> void:
	if _trap_toast_shown or not _trap_toast_panel or not _trap_toast_lbl:
		return
	_trap_toast_shown = true
	_trap_toast_lbl.text = LocaleManager.t("tut_trap_floor_toast")
	_trap_toast_panel.visible = true
	_trap_toast_panel.modulate.a = 0.0
	if _trap_toast_tween and _trap_toast_tween.is_valid():
		_trap_toast_tween.kill()
	_trap_toast_tween = create_tween()
	_trap_toast_tween.tween_property(_trap_toast_panel, "modulate:a", 1.0, 0.16)
	_trap_toast_tween.tween_interval(1.5)
	_trap_toast_tween.tween_property(_trap_toast_panel, "modulate:a", 0.0, 0.32)
	_trap_toast_tween.tween_callback(func():
		if _trap_toast_panel:
			_trap_toast_panel.visible = false
	)

func _on_tutorial_pulse_draw() -> void:
	if not _tutorial_pulse_overlay or not _tutorial_active or not is_mobile_platform():
		return
	var targets: Array[Control] = []
	match _tutorial_step:
		0:
			if left_btn: targets.append(left_btn)
			if right_btn: targets.append(right_btn)
		1:
			if jump_btn: targets.append(jump_btn)
		2:
			if dash_btn: targets.append(dash_btn)
		_:
			return

	var phase := fmod(_tutorial_pulse_t, 1.0)
	var ring_alpha := (1.0 - phase) * 0.85
	var glow_alpha := 0.40 + 0.25 * sin(_tutorial_pulse_t * TAU)

	for btn in targets:
		var center := btn.position + btn.size * 0.5
		var base_r := minf(btn.size.x, btn.size.y) * 0.5
		_tutorial_pulse_overlay.draw_arc(center, base_r + 3.0, 0.0, TAU, 40, Color(0.22, 0.82, 1.0, glow_alpha), 2.5, true)
		_tutorial_pulse_overlay.draw_arc(center, base_r + 4.0 + phase * 18.0, 0.0, TAU, 40, Color(0.38, 0.90, 1.0, ring_alpha), 2.2, true)
