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

func _ready() -> void:
	LocaleManager.language_changed.connect(_on_language_changed)
	GameManager.player_died.connect(_on_player_died)
	GameManager.level_started.connect(_on_level_started)
	SaveManager.touch_layout_changed.connect(_apply_custom_touch_layout)
	get_viewport().size_changed.connect(_apply_custom_touch_layout)
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_signal("banner_visibility_changed"):
		adm.banner_visibility_changed.connect(_on_banner_visibility_changed)
	
	_apply_custom_touch_layout()
	_setup_icons()
	_update_texts()
	
	if left_btn: _setup_touch_btn(left_btn)
	if right_btn: _setup_touch_btn(right_btn)
	if dash_btn: _setup_touch_btn(dash_btn)
	if jump_btn: _setup_touch_btn(jump_btn)
	_update_touch_visibility()

func _exit_tree() -> void:
	_release_all_touch_actions()

func _update_touch_visibility() -> void:
	# Sensorli tugmalar faqat mobil qurilmalarda ko'rsatiladi (PC da doim yashirin).
	var is_mob := (
		OS.has_feature("android")
		or OS.has_feature("ios")
		or OS.has_feature("mobile")
		or OS.has_feature("web_android")
		or OS.has_feature("web_ios")
	)
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

func _process(_delta: float) -> void:
	if time_label:
		if GameManager.is_level_running:
			var elapsed_sec: float = (float(Time.get_ticks_msec()) - GameManager.level_start_time) / 1000.0
			time_label.text = "%ds" % int(maxf(elapsed_sec, 0.0))
		elif GameManager.level_timer_ms > 0:
			time_label.text = "%ds" % int(GameManager.level_timer_ms / 1000.0)

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

func _on_level_started(_level_id: int) -> void:
	current_deaths = GameManager.level_deaths
	_update_texts()
	_update_deaths_display()

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
