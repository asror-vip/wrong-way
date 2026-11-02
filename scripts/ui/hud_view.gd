extends CanvasLayer
class_name HUDView

# Wrong Way — Reactive HUD & Result View
# Shows level progress, live attempt timer, and star-based result modal (1-3 stars).

signal replay_requested
signal next_level_requested
signal level_select_requested
signal main_menu_requested

@onready var title_label: Label = $TopBar/LevelTitle
@onready var timer_label: Label = $TopBar/StatsBox/TimerLabel
@onready var death_label: Label = $TopBar/StatsBox/DeathLabel
@onready var reset_btn: Button = $TopBar/ResetButton

@onready var win_overlay: Control = $WinOverlay
@onready var win_card: Control = $WinOverlay/CardRoot
@onready var win_title: Label = $WinOverlay/CardRoot/VBox/WinTitle
@onready var win_stars_label: Label = $WinOverlay/CardRoot/VBox/StarsLabel
@onready var win_unlock_status: Label = $WinOverlay/CardRoot/VBox/UnlockStatus
@onready var win_time_chip: Label = $WinOverlay/CardRoot/VBox/StatsBox/TimeChip
@onready var win_death_chip: Label = $WinOverlay/CardRoot/VBox/StatsBox/DeathChip

@onready var win_next_btn: Button = $WinOverlay/CardRoot/VBox/NextButton
@onready var win_replay_btn: Button = $WinOverlay/CardRoot/VBox/SecondaryButtons/ReplayButton
@onready var win_select_btn: Button = $WinOverlay/CardRoot/VBox/SecondaryButtons/SelectButton
@onready var win_menu_btn: Button = $WinOverlay/CardRoot/VBox/SecondaryButtons/MenuButton

@onready var left_btn: Button = $TouchControls/LeftBtn
@onready var right_btn: Button = $TouchControls/RightBtn
@onready var jump_btn: Button = $TouchControls/JumpBtn

# Backward compatibility alias
var win_stats: Label = null

var session_ref: GameSession = null
var current_level_num: int = 1
var last_result_data: Dictionary = {}

func _ready() -> void:
	win_overlay.visible = false
	reset_btn.pressed.connect(_on_reset_pressed)
	if win_replay_btn:
		win_replay_btn.pressed.connect(_on_replay_pressed)
	if win_next_btn:
		win_next_btn.pressed.connect(_on_next_pressed)
	if win_select_btn:
		win_select_btn.pressed.connect(_on_select_pressed)
	if win_menu_btn:
		win_menu_btn.pressed.connect(_on_menu_pressed)
	
	# Mobile / Touch
	left_btn.button_down.connect(func(): Input.action_press("move_left"))
	left_btn.button_up.connect(func(): Input.action_release("move_left"))
	left_btn.mouse_exited.connect(func():
		if not Input.is_key_pressed(KEY_A) and not Input.is_key_pressed(KEY_LEFT):
			Input.action_release("move_left")
	)
	
	right_btn.button_down.connect(func(): Input.action_press("move_right"))
	right_btn.button_up.connect(func(): Input.action_release("move_right"))
	right_btn.mouse_exited.connect(func():
		if not Input.is_key_pressed(KEY_D) and not Input.is_key_pressed(KEY_RIGHT):
			Input.action_release("move_right")
	)
	
	jump_btn.button_down.connect(func(): Input.action_press("jump"))
	jump_btn.button_up.connect(func(): Input.action_release("jump"))
	jump_btn.mouse_exited.connect(func():
		if not Input.is_key_pressed(KEY_W) and not Input.is_key_pressed(KEY_SPACE) and not Input.is_key_pressed(KEY_UP):
			Input.action_release("jump")
	)

func bind_session(session: GameSession, level_num: int = 1) -> void:
	session_ref = session
	current_level_num = level_num
	session.death_recorded.connect(_on_death_recorded)
	session.session_completed.connect(_on_session_completed)
	session.session_started.connect(_on_session_started)
	_on_death_recorded(session.deaths)

func set_level_info(level_name: String) -> void:
	if title_label:
		title_label.text = level_name.to_upper()

func _process(_delta: float) -> void:
	if session_ref and session_ref.is_active:
		var ms = session_ref.get_elapsed_ms()
		var sec = ms / 1000.0
		if timer_label:
			timer_label.text = "%04.2fs" % sec

func _on_session_started() -> void:
	_release_all_touch_actions()
	win_overlay.visible = false
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_method("hide_banner"):
		adm.hide_banner()
	if death_label:
		death_label.text = "O'LIMLAR: 0"
	if timer_label:
		timer_label.text = "00.00s"

func _release_all_touch_actions() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")

func _on_death_recorded(total_deaths: int) -> void:
	if death_label:
		death_label.text = "O'LIMLAR: %d" % total_deaths

func _on_session_completed(result: Dictionary) -> void:
	_release_all_touch_actions()
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_method("show_banner"):
		adm.show_banner()
	last_result_data = result.duplicate()
	win_overlay.visible = true
	win_overlay.modulate.a = 0.0
	
	if win_card:
		win_card.scale = Vector2(0.85, 0.85)
		win_card.pivot_offset = win_card.size / 2.0
	
	var time_ms = result.get("time_ms", 0)
	var time_sec = float(time_ms) / 1000.0
	var d = result.get("deaths", 0)
	
	if win_title:
		win_title.text = "%d-DARAJA YAKUNLANDI!" % current_level_num
	
	# Save progress and calculate stars
	var save_sys = get_node_or_null("/root/SaveSystem")
	var stars = 1
	if save_sys and save_sys.has_method("record_level_result"):
		stars = save_sys.record_level_result(current_level_num, time_ms, d)
	else:
		stars = 3 if d == 0 else (2 if d <= 2 else 1)
	
	match stars:
		3:
			win_stars_label.text = "★★★"
			win_unlock_status.text = "Mukammal natija! Keyingi daraja ochildi!"
			win_unlock_status.add_theme_color_override("font_color", Color(0.28, 0.88, 0.45, 1.0))
		2:
			win_stars_label.text = "★★☆"
			win_unlock_status.text = "Yaxshi natija! Keyingi daraja ochildi!"
			win_unlock_status.add_theme_color_override("font_color", Color(0.38, 0.82, 0.52, 1.0))
		_:
			win_stars_label.text = "★☆☆"
			win_unlock_status.text = "Keyingi daraja uchun kamida 2 ta yulduz oling!"
			win_unlock_status.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45, 1.0))
	
	if win_time_chip:
		win_time_chip.text = "%0.2f soniya" % time_sec
	if win_death_chip:
		win_death_chip.text = "%d ta o'lim" % d
	
	# Next level button enabled only if >= 2 stars
	if win_next_btn:
		win_next_btn.visible = (stars >= 2)
	
	# Smooth modal entrance with bouncy card punch
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(win_overlay, "modulate:a", 1.0, 0.22)
	if win_card:
		tween.tween_property(win_card, "scale", Vector2.ONE, 0.25)

func _on_reset_pressed() -> void:
	_play_click()
	replay_requested.emit()

func _on_replay_pressed() -> void:
	_play_click()
	win_overlay.visible = false
	replay_requested.emit()

func _on_next_pressed() -> void:
	_play_click()
	next_level_requested.emit()
	var next_path = "res://scenes/levels/level_%d.tscn" % (current_level_num + 1)
	if ResourceLoader.exists(next_path):
		get_tree().change_scene_to_file(next_path)
	else:
		get_tree().change_scene_to_file("res://scenes/menu/level_select.tscn")

func _on_select_pressed() -> void:
	_play_click()
	level_select_requested.emit()
	var save_sys = get_node_or_null("/root/SaveSystem")
	if save_sys:
		save_sys.navigation_source = "result_modal"
		save_sys.return_level_num = current_level_num
		save_sys.pending_result_data = last_result_data.duplicate()
		save_sys.should_restore_result_modal = false
	get_tree().change_scene_to_file("res://scenes/menu/level_select.tscn")

func _on_menu_pressed() -> void:
	_play_click()
	main_menu_requested.emit()
	var save_sys = get_node_or_null("/root/SaveSystem")
	if save_sys:
		save_sys.navigation_source = "home_menu"
		save_sys.should_restore_result_modal = false
		save_sys.pending_result_data = {}
	get_tree().change_scene_to_file("res://scenes/menu/home_menu.tscn")

func _play_click() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_click"):
		sm.play_click()
