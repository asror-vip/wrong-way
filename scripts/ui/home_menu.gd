extends Control

# Wrong Way — Home Menu
# Top right shows overall best record from SaveManager.
# Center has vertically stacked buttons: PLAY, LEADERBOARD, MULTIPLAYER.

@onready var record_label: Label = $TopBar/RecordLabel
@onready var back_btn: Button = $TopBar/BackButton

@onready var play_btn: Button = $VBox/PlayButton
@onready var multiplayer_btn: Button = $VBox/MultiplayerButton
@onready var leaderboard_btn: Button = $VBox/LeaderboardButton
@onready var settings_btn: Button = $VBox/SettingsButton

@onready var popup_dialog: AcceptDialog = $NoticeDialog

func _ready() -> void:
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_method("show_banner"):
		adm.show_banner()
	back_btn.pressed.connect(_on_back_pressed)
	play_btn.pressed.connect(_on_play_pressed)
	multiplayer_btn.pressed.connect(_on_multiplayer_pressed)
	leaderboard_btn.pressed.connect(_on_leaderboard_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	
	update_best_record()

func update_best_record() -> void:
	var save_sys = get_node_or_null("/root/SaveManager")
	if save_sys and save_sys.has_method("get_overall_best_text"):
		record_label.text = "Oxirgi rekord: %s" % save_sys.get_overall_best_text()
	else:
		record_label.text = "Oxirgi rekord: Mavjud emas"

func _on_back_pressed() -> void:
	_play_click()
	get_tree().change_scene_to_file("res://scenes/menu/title_screen.tscn")

func _on_play_pressed() -> void:
	_play_click()
	var save_sys = get_node_or_null("/root/SaveManager")
	if save_sys:
		save_sys.navigation_source = "home_menu"
		save_sys.should_restore_result_modal = false
		save_sys.pending_result_data = {}
	get_tree().change_scene_to_file("res://scenes/menu/level_select.tscn")

func _on_multiplayer_pressed() -> void:
	_play_click()
	popup_dialog.title = "MULTIPLAYER REJIMI"
	popup_dialog.dialog_text = "1v1 Duel va Online Race rejimi tez orada taqdim etiladi!\n\nHozirda Campaign (Yakkaxon) rejimi to'liq faol."
	popup_dialog.popup_centered()

func _on_leaderboard_pressed() -> void:
	_play_click()
	popup_dialog.title = "GLOBAL REITING"
	popup_dialog.dialog_text = "Hozirgi bosqichda faqat lokal rekordlar yozilmoqda.\n\nSizning eng yaxshi rekordingiz:\n%s" % record_label.text
	popup_dialog.popup_centered()

func _on_settings_pressed() -> void:
	_play_click()
	var sm = get_node_or_null("/root/SoundManager")
	var sound_state = "YONIQ" if (sm and sm.sound_enabled) else "O'CHIQ"
	popup_dialog.title = "SOZLAMALAR"
	popup_dialog.dialog_text = "Ovoz effektlari (SFX): %s\n\nBoshqaruv: A/D (yurish), W/Space (sakrash), R (restart)\n\nVersiya: Wrong Way v1.0" % sound_state
	popup_dialog.popup_centered()

func _play_click() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_click"):
		sm.play_click()
