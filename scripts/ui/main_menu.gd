extends Control

# Wrong Way - Main Menu Controller
# Reimagined with Dark Atmospheric Silhouette Art Style & Glowing White Glass UI

@onready var game_title_lbl: Label = get_node_or_null("Header/GameLogo")
@onready var best_chip_lbl: Label = get_node_or_null("TopBar/BestBadge/HBox/BestLabel")
@onready var best_crown_icon: TextureRect = get_node_or_null("TopBar/BestBadge/HBox/CrownIcon")
@onready var profile_top_btn: Button = get_node_or_null("TopBar/ProfileTopBtn")
@onready var profile_name_lbl: Label = get_node_or_null("TopBar/ProfileTopBtn/HBox/VBox/ProfileNameLabel")
@onready var profile_tag_lbl: Label = get_node_or_null("TopBar/ProfileTopBtn/HBox/VBox/ProfileTagLabel")
@onready var profile_avatar_rect: TextureRect = get_node_or_null("TopBar/ProfileTopBtn/HBox/ProfileAvatar")
@onready var menu_character: Control = get_node_or_null("MenuCharacter")
@onready var settings_top_btn: Button = get_node_or_null("TopBar/SettingsTopBtn")
@onready var quit_top_btn: Button = get_node_or_null("TopBar/QuitTopBtn")

@onready var play_btn: Button = get_node_or_null("MenuStack/PlayBtn")
@onready var play_btn_label: Label = get_node_or_null("MenuStack/PlayBtn/HBox/PlayLabel")
@onready var play_btn_icon: TextureRect = get_node_or_null("MenuStack/PlayBtn/HBox/PlayIcon")
@onready var play_btn_chevron: TextureRect = get_node_or_null("MenuStack/PlayBtn/HBox/ChevronIcon")

@onready var level_select_btn: Button = get_node_or_null("MenuStack/LevelSelectBtn")
@onready var editor_btn: Button = get_node_or_null("MenuStack/EditorBtn")
@onready var leaderboard_btn: Button = get_node_or_null("MenuStack/LeaderboardBtn")
@onready var multiplayer_btn: Button = get_node_or_null("MenuStack/MultiplayerBtn")

@onready var settings_modal: Control = get_node_or_null("SettingsModal")
@onready var leaderboard_modal: Control = get_node_or_null("LeaderboardModal")
@onready var profile_modal: Control = get_node_or_null("ProfileModal")
@onready var duel_lobby_modal: Control = get_node_or_null("DuelLobbyModal")
@onready var incoming_invite_card: Control = get_node_or_null("IncomingInviteCard")
@onready var invite_text_lbl: Label = get_node_or_null("IncomingInviteCard/HBox/InviteText")
@onready var ad_chip: Control = get_node_or_null("BottomLeft/AdChip")

var pending_invite_duel_id: String = ""

@onready var info_modal: Control = get_node_or_null("InfoModal")
@onready var info_title_icon: TextureRect = get_node_or_null("InfoModal/Card/TitleRow/TitleIcon")
@onready var info_title_label: Label = get_node_or_null("InfoModal/Card/TitleRow/TitleLabel")
@onready var info_desc_label: Label = get_node_or_null("InfoModal/Card/Content/DescLabel")
@onready var info_close_btn: Button = get_node_or_null("InfoModal/Card/CloseBtn")
@onready var info_backdrop: ColorRect = get_node_or_null("InfoModal/Backdrop")

func _ready() -> void:
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_method("hide_banner"):
		adm.hide_banner()
		
	LocaleManager.language_changed.connect(_on_language_changed)
	
	if info_backdrop:
		info_backdrop.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_info_close_pressed()
		)
	
	_setup_icons()
	_update_all_texts()
	_update_record()
	_update_profile_button()
	
	if quit_top_btn and menu_character:
		quit_top_btn.mouse_entered.connect(func():
			if menu_character.has_method("set_sad_emotion"):
				menu_character.set_sad_emotion(true)
		)
		quit_top_btn.mouse_exited.connect(func():
			if menu_character.has_method("set_sad_emotion"):
				menu_character.set_sad_emotion(false)
		)
	
	ProfileManager.profile_updated.connect(func(_d): _update_profile_button())
	ProfileManager.profile_loaded.connect(func(_d): _update_profile_button())
	DuelService.invitation_received.connect(_on_invitation_received)
	
	if duel_lobby_modal:
		duel_lobby_modal.duel_started.connect(_on_duel_started)
		
	SoundManager.set_gameplay_mode(false)
	SoundManager.play_music()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if leaderboard_modal and leaderboard_modal.visible:
				leaderboard_modal.close()
				get_viewport().set_input_as_handled()
				return
			if info_modal and info_modal.visible:
				_on_info_close_pressed()
				get_viewport().set_input_as_handled()
				return

func _setup_icons() -> void:
	if best_crown_icon:
		best_crown_icon.texture = IconFactory.get_icon("crown_gold", 0.85)
	if settings_top_btn:
		settings_top_btn.icon = IconFactory.get_icon("circle_btn_gear", 1.0)
		settings_top_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		settings_top_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	if quit_top_btn:
		quit_top_btn.icon = IconFactory.get_icon("circle_btn_quit", 1.0)
		quit_top_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quit_top_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	if play_btn_icon:
		play_btn_icon.texture = IconFactory.get_icon("play_dark", 0.9)
	if play_btn_chevron:
		play_btn_chevron.texture = IconFactory.get_icon("chevron_right", 0.8)
		
	if level_select_btn:
		level_select_btn.icon = IconFactory.get_icon("level_select", 0.85)
	if editor_btn:
		editor_btn.icon = IconFactory.get_icon("wrench", 0.85)
	if leaderboard_btn:
		leaderboard_btn.icon = IconFactory.get_icon("trophy_white", 0.85)
	if multiplayer_btn:
		multiplayer_btn.icon = IconFactory.get_icon("users_white", 0.85)
	if info_close_btn:
		info_close_btn.icon = IconFactory.get_icon("circle_btn_close", 1.0)
		info_close_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_close_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	var decline_btn: Button = get_node_or_null("IncomingInviteCard/HBox/DeclineBtn")
	if decline_btn:
		decline_btn.icon = IconFactory.get_icon("close", 0.75)
	var accept_btn: Button = get_node_or_null("IncomingInviteCard/HBox/AcceptBtn")
	if accept_btn:
		accept_btn.icon = IconFactory.get_icon("check", 0.75)

func _on_language_changed(_lang: String) -> void:
	_update_all_texts()

func _update_all_texts() -> void:
	if game_title_lbl:
		game_title_lbl.text = LocaleManager.t("game_title")
	if play_btn_label:
		play_btn_label.text = LocaleManager.t("btn_play")
	if level_select_btn:
		level_select_btn.text = "   " + LocaleManager.t("btn_level_select")
	if editor_btn:
		editor_btn.text = "   " + LocaleManager.t("btn_editor")
	if leaderboard_btn:
		leaderboard_btn.text = "   " + LocaleManager.t("btn_leaderboard")
	if multiplayer_btn:
		multiplayer_btn.text = "   " + LocaleManager.t("btn_multiplayer")
	_update_record()

func _update_record() -> void:
	if best_chip_lbl:
		var stars: int = SaveManager.get_total_stars()
		if stars > 0:
			best_chip_lbl.text = "Best: %d" % stars
		else:
			best_chip_lbl.text = "Best: 1"

func _on_play_pressed() -> void:
	SoundManager.play("click")
	var target_lvl: int = SaveManager.get_highest_unlocked_level()
	GameManager.start_game(target_lvl)

func _on_level_select_pressed() -> void:
	SoundManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main/level_select.tscn")

func _on_editor_pressed() -> void:
	SoundManager.play("click")
	get_tree().change_scene_to_file("res://scenes/editor/level_editor.tscn")

func _on_leaderboard_pressed() -> void:
	SoundManager.play("click")
	if leaderboard_modal and leaderboard_modal.has_method("open"):
		leaderboard_modal.open()

func _update_profile_button() -> void:
	if profile_top_btn:
		profile_top_btn.text = ""
		profile_top_btn.icon = null
		if profile_name_lbl:
			profile_name_lbl.text = ProfileManager.username
		if profile_tag_lbl:
			profile_tag_lbl.text = ProfileManager.player_tag
		if profile_avatar_rect:
			var av_keys := ["avatar_player", "avatar_ninja", "avatar_shadow", "avatar_robot", "avatar_pro"]
			var av_idx := (ProfileManager.avatar_index - 1) % av_keys.size()
			if av_idx < 0:
				av_idx = 0
			profile_avatar_rect.texture = IconFactory.get_icon(av_keys[av_idx], 0.9)

func _on_profile_pressed() -> void:
	SoundManager.play("click")
	if profile_modal and profile_modal.has_method("open"):
		profile_modal.open()

func _on_multiplayer_pressed() -> void:
	SoundManager.play("click")
	if duel_lobby_modal and duel_lobby_modal.has_method("open"):
		duel_lobby_modal.open()

func _on_duel_started(zone_id: int, level_id: int, random_seed: int) -> void:
	print("MainMenu: 1v1 Duel boshlanmoqda! Zona: ", zone_id, " Daraja: ", level_id, " Seed: ", random_seed)
	GameManager.start_duel_game(level_id, random_seed)

func _on_invitation_received(duel_data: Dictionary, sender_tag: String, sender_name: String) -> void:
	pending_invite_duel_id = str(duel_data.get("id", ""))
	if incoming_invite_card and invite_text_lbl:
		invite_text_lbl.text = "%s (%s) sizni 1v1 duelga chaqirdi!" % [sender_name, sender_tag]
		incoming_invite_card.visible = true
		SoundManager.play("win")

func _on_invite_accepted() -> void:
	SoundManager.play("click")
	if incoming_invite_card: incoming_invite_card.visible = false
	if not pending_invite_duel_id.is_empty():
		DuelService.respond_invitation(pending_invite_duel_id, true)
		if duel_lobby_modal and duel_lobby_modal.has_method("open"):
			duel_lobby_modal.open()

func _on_invite_declined() -> void:
	SoundManager.play("click")
	if incoming_invite_card: incoming_invite_card.visible = false
	if not pending_invite_duel_id.is_empty():
		DuelService.respond_invitation(pending_invite_duel_id, false)
		pending_invite_duel_id = ""

func _on_info_close_pressed() -> void:
	SoundManager.play("click")
	if info_modal:
		info_modal.visible = false

func _on_settings_pressed() -> void:
	SoundManager.play("click")
	if settings_modal and settings_modal.has_method("open"):
		settings_modal.open()

func _on_quit_pressed() -> void:
	SoundManager.play("click")
	get_tree().quit()
