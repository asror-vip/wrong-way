extends Control

# Wrong Way - Full-Screen 1v1 Multiplayer Menu
# - Dedicated full-screen hub for competitive play and AI Ghost practice
# - 60 levels across 3 chapters: 1-Bob (Qorong'i O'rmon), 2-Bob (Qorli Cho'qqilar), 3-Bob (Yashil O'rmon)
# - Clean, elegant typography with zero sticker emojis
# - Smooth loading screen before entering gameplay
# - Seamless return from duels back to this lobby

@onready var back_btn: Button = get_node_or_null("TopBar/BackButton")
@onready var my_id_label: Label = get_node_or_null("TopBar/MyIdBar/MyIdLabel")
@onready var copy_id_btn: Button = get_node_or_null("TopBar/MyIdBar/CopyIdBtn")

@onready var tab_lobby_btn: Button = get_node_or_null("MainContainer/NavTabsHBox/TabLobbyBtn")
@onready var tab_online_btn: Button = get_node_or_null("MainContainer/NavTabsHBox/TabOnlineBtn")

@onready var lobby_view: VBoxContainer = get_node_or_null("MainContainer/LobbyView")
@onready var online_view: VBoxContainer = get_node_or_null("MainContainer/OnlineView")

# Lobby View nodes
@onready var player_a_name: Label = get_node_or_null("MainContainer/LobbyView/PlayersHBox/PlayerACard/VBox/NameLabel")
@onready var player_a_tag: Label = get_node_or_null("MainContainer/LobbyView/PlayersHBox/PlayerACard/VBox/TagLabel")
@onready var player_b_name: Label = get_node_or_null("MainContainer/LobbyView/PlayersHBox/PlayerBCard/VBox/NameLabel")
@onready var player_b_tag: Label = get_node_or_null("MainContainer/LobbyView/PlayersHBox/PlayerBCard/VBox/TagLabel")

@onready var btn_ch1: Button = get_node_or_null("MainContainer/LobbyView/NegotiationPanel/VBox/ChapterTabsHBox/BtnCh1")
@onready var btn_ch2: Button = get_node_or_null("MainContainer/LobbyView/NegotiationPanel/VBox/ChapterTabsHBox/BtnCh2")
@onready var btn_ch3: Button = get_node_or_null("MainContainer/LobbyView/NegotiationPanel/VBox/ChapterTabsHBox/BtnCh3")
@onready var level_grid: GridContainer = get_node_or_null("MainContainer/LobbyView/NegotiationPanel/VBox/LevelGridCenter/LevelGrid")

@onready var selected_badge: Label = get_node_or_null("MainContainer/LobbyView/NegotiationPanel/VBox/SelectedLevelCard/HBox/SelectedBadge")
@onready var selected_title: Label = get_node_or_null("MainContainer/LobbyView/NegotiationPanel/VBox/SelectedLevelCard/HBox/SelectedTitle")
@onready var selected_gimmick: Label = get_node_or_null("MainContainer/LobbyView/NegotiationPanel/VBox/SelectedLevelCard/HBox/SelectedGimmick")

@onready var play_bot_btn: Button = get_node_or_null("MainContainer/LobbyView/NegotiationPanel/VBox/ActionsHBox/PlayBotBtn")
@onready var propose_btn: Button = get_node_or_null("MainContainer/LobbyView/NegotiationPanel/VBox/ActionsHBox/ProposeBtn")

@onready var incoming_box: PanelContainer = get_node_or_null("MainContainer/LobbyView/IncomingProposalBox")
@onready var proposal_text: Label = get_node_or_null("MainContainer/LobbyView/IncomingProposalBox/HBox/ProposalLabel")
@onready var reject_btn: Button = get_node_or_null("MainContainer/LobbyView/IncomingProposalBox/HBox/RejectBtn")
@onready var accept_btn: Button = get_node_or_null("MainContainer/LobbyView/IncomingProposalBox/HBox/AcceptBtn")

# Online View nodes
@onready var tag_input: LineEdit = get_node_or_null("MainContainer/OnlineView/DirectInviteHBox/TagInput")
@onready var invite_btn: Button = get_node_or_null("MainContainer/OnlineView/DirectInviteHBox/InviteBtn")
@onready var random_btn: Button = get_node_or_null("MainContainer/OnlineView/RandomBtn")
@onready var search_status: Label = get_node_or_null("MainContainer/OnlineView/StatusLabel")
@onready var refresh_friends_btn: Button = get_node_or_null("MainContainer/OnlineView/FriendsHeaderHBox/RefreshBtn")
@onready var friends_vbox: VBoxContainer = get_node_or_null("MainContainer/OnlineView/FriendsScroll/FriendsVBox")

# Loading Curtain
@onready var loading_curtain: ColorRect = get_node_or_null("LoadingCurtain")

var selected_chapter: int = 1
var selected_level_in_chapter: int = 1
var active_subview: String = "lobby"

var pending_proposal_id: int = 0
var is_matchmaking: bool = false
var mm_dots_timer: float = 0.0
var mm_dots_count: int = 0
var mm_poll_timer: float = 0.0

func _ready() -> void:
	_apply_all_styles()
	
	if back_btn: back_btn.pressed.connect(_on_back_pressed)
	if copy_id_btn: copy_id_btn.pressed.connect(_on_copy_my_id)
	
	if tab_lobby_btn: tab_lobby_btn.pressed.connect(func(): _switch_subview("lobby"))
	if tab_online_btn: tab_online_btn.pressed.connect(func(): _switch_subview("online"))
	
	if btn_ch1: btn_ch1.pressed.connect(func(): _on_chapter_tab_pressed(1))
	if btn_ch2: btn_ch2.pressed.connect(func(): _on_chapter_tab_pressed(2))
	if btn_ch3: btn_ch3.pressed.connect(func(): _on_chapter_tab_pressed(3))
	
	if play_bot_btn: play_bot_btn.pressed.connect(_on_play_bot_pressed)
	if propose_btn: propose_btn.pressed.connect(_on_propose_pressed)
	
	if reject_btn: reject_btn.pressed.connect(_on_reject_pressed)
	if accept_btn: accept_btn.pressed.connect(_on_accept_pressed)
	
	if invite_btn: invite_btn.pressed.connect(_on_invite_pressed)
	if random_btn: random_btn.pressed.connect(_on_random_btn_pressed)
	if refresh_friends_btn: refresh_friends_btn.pressed.connect(_load_and_render_friends)
	
	DuelService.proposal_received.connect(_on_proposal_received)
	DuelService.match_agreed.connect(_on_match_agreed)
	DuelService.duel_updated.connect(_on_duel_updated)
	
	_switch_subview("lobby")
	_setup_level_grid(selected_chapter)
	_update_chapter_tabs()
	_update_selected_level_card()
	_refresh_player_cards()
	
	if my_id_label:
		my_id_label.text = "Sizning ID: #" + ProfileManager.player_tag
		
	if loading_curtain:
		loading_curtain.visible = false

func _on_back_pressed() -> void:
	SoundManager.play("click")
	if is_matchmaking:
		_cancel_matchmaking("Qidiruv bekor qilindi.")
	DuelService.leave_active_duel()
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

func _switch_subview(view_name: String) -> void:
	SoundManager.play("click")
	active_subview = view_name
	if lobby_view: lobby_view.visible = (view_name == "lobby")
	if online_view: online_view.visible = (view_name == "online")
	
	if tab_lobby_btn: _style_button(tab_lobby_btn, "white" if view_name == "lobby" else "glass")
	if tab_online_btn: _style_button(tab_online_btn, "white" if view_name == "online" else "glass")
	
	if view_name == "online":
		_load_and_render_friends()
	else:
		_refresh_player_cards()

func _refresh_player_cards() -> void:
	var d: Dictionary = DuelService.active_duel
	var my_id := ProfileManager.player_id
	var pa_id: String = str(d.get("player_a_id", ""))
	var pb_id: String = str(d.get("player_b_id", ""))
	
	if player_a_name:
		player_a_name.text = ProfileManager.username
		player_a_tag.text = "#" + ProfileManager.player_tag
		
	if player_b_name:
		if DuelService.is_bot_duel or pb_id == "bot_ghost" or d.is_empty():
			player_b_name.text = "AI Ghost Bot"
			player_b_tag.text = "Mashg'ulot Raqibi"
			if propose_btn: propose_btn.visible = false
			if play_bot_btn: play_bot_btn.visible = true
		else:
			player_b_name.text = "Raqib" if pa_id == my_id else ProfileManager.username
			player_b_tag.text = "Ulangan"
			if propose_btn: propose_btn.visible = true
			if play_bot_btn: play_bot_btn.visible = true

# -------------------------------------------------------------
# Boblar va Darajalar Tanlash
# -------------------------------------------------------------
func _on_chapter_tab_pressed(chapter: int) -> void:
	SoundManager.play("click")
	selected_chapter = chapter
	_update_chapter_tabs()
	_setup_level_grid(chapter)
	_update_selected_level_card()

func _update_chapter_tabs() -> void:
	if btn_ch1: _style_button(btn_ch1, "white" if selected_chapter == 1 else "glass")
	if btn_ch2: _style_button(btn_ch2, "white" if selected_chapter == 2 else "glass")
	if btn_ch3: _style_button(btn_ch3, "white" if selected_chapter == 3 else "glass")

func _setup_level_grid(chapter: int) -> void:
	if not level_grid:
		return
		
	for child in level_grid.get_children():
		child.queue_free()
		
	var start_lvl := (chapter - 1) * 20 + 1
	var end_lvl := chapter * 20
	
	for lvl in range(start_lvl, end_lvl + 1):
		var lvl_in_ch := ((lvl - 1) % 20) + 1
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(70, 34)
		btn.text = "%d" % lvl
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 13)
		
		var is_selected := (chapter == selected_chapter and lvl_in_ch == selected_level_in_chapter)
		_style_level_button(btn, is_selected)
		
		btn.pressed.connect(func():
			_on_level_selected(chapter, lvl_in_ch)
		)
		
		level_grid.add_child(btn)

func _on_level_selected(chapter: int, lvl_in_ch: int) -> void:
	SoundManager.play("click")
	selected_chapter = chapter
	selected_level_in_chapter = lvl_in_ch
	
	if level_grid:
		var children = level_grid.get_children()
		for i in range(children.size()):
			var b = children[i] as Button
			if b:
				var is_sel := ((i + 1) == lvl_in_ch)
				_style_level_button(b, is_sel)
				
	_update_selected_level_card()

func _update_selected_level_card() -> void:
	var actual_level := (selected_chapter - 1) * 20 + selected_level_in_chapter
	var l_data: Dictionary = {}
	var ldb = get_node_or_null("/root/LevelDatabase")
	if ldb and ldb.has_method("get_level"):
		l_data = ldb.get_level(actual_level)
		
	var title_str: String = str(l_data.get("title", "%d-Daraja" % actual_level))
	
	if selected_badge:
		selected_badge.text = "%d-BOB · DARAJA %d" % [selected_chapter, actual_level]
		
	if selected_title:
		selected_title.text = "Nomi: " + title_str
		
	if selected_gimmick:
		match selected_chapter:
			1: selected_gimmick.text = "Qorong'i O'rmon"
			2: selected_gimmick.text = "Qorli Cho'qqilar"
			3: selected_gimmick.text = "Yashil O'rmon"

func _style_level_button(btn: Button, is_selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 6.0
	normal.content_margin_right = 6.0
	normal.content_margin_top = 4.0
	normal.content_margin_bottom = 4.0
	
	var hover := StyleBoxFlat.new()
	hover.set_corner_radius_all(10)
	hover.content_margin_left = 6.0
	hover.content_margin_right = 6.0
	hover.content_margin_top = 4.0
	hover.content_margin_bottom = 4.0
	
	if is_selected:
		normal.bg_color = Color(0.12, 0.24, 0.38, 0.95)
		normal.border_color = Color(0.22, 0.74, 0.97, 1.0)
		normal.set_border_width_all(2)
		normal.shadow_color = Color(0.22, 0.74, 0.97, 0.4)
		normal.shadow_size = 4
		btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		
		hover.bg_color = Color(0.16, 0.30, 0.46, 1.0)
		hover.border_color = Color(0.40, 0.85, 1.0, 1.0)
		hover.set_border_width_all(2)
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	else:
		normal.bg_color = Color(0.08, 0.11, 0.17, 0.85)
		normal.border_color = Color(0.22, 0.30, 0.45, 0.5)
		normal.set_border_width_all(1)
		btn.add_theme_color_override("font_color", Color(0.80, 0.88, 0.96, 0.9))
		
		hover.bg_color = Color(0.12, 0.18, 0.28, 0.95)
		hover.border_color = Color(0.38, 0.74, 0.97, 0.85)
		hover.set_border_width_all(1)
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
		
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", normal)

# -------------------------------------------------------------
# O'yinni Boshlash (Loading Screen + Scene Launch)
# -------------------------------------------------------------
func _on_play_bot_pressed() -> void:
	SoundManager.play("click")
	DuelService.setup_bot_duel(selected_chapter, selected_level_in_chapter)
	var actual_level := (selected_chapter - 1) * 20 + selected_level_in_chapter
	_launch_game_with_loading(actual_level, randi() % 999999)

func _launch_game_with_loading(actual_level: int, seed_num: int) -> void:
	if loading_curtain:
		loading_curtain.visible = true
		loading_curtain.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(loading_curtain, "modulate:a", 1.0, 0.35)
		await tw.finished
		await get_tree().create_timer(0.25).timeout
		
	GameManager.start_duel_game(actual_level, seed_num)

# -------------------------------------------------------------
# Online Raqibga Taklif Yuborish (Negotiation)
# -------------------------------------------------------------
func _on_propose_pressed() -> void:
	SoundManager.play("click")
	DuelService.propose_level(selected_chapter, selected_level_in_chapter)

func _on_proposal_received(_proposer_id: String, zone_id: int, level_id: int, proposal_id: int) -> void:
	pending_proposal_id = proposal_id
	if incoming_box and proposal_text:
		var actual_lvl: int = (zone_id - 1) * 20 + level_id
		var l_data: Dictionary = {}
		var ldb = get_node_or_null("/root/LevelDatabase")
		if ldb and ldb.has_method("get_level"):
			l_data = ldb.get_level(actual_lvl)
		var title_str: String = str(l_data.get("title", "%d-Daraja" % actual_lvl))
		
		proposal_text.text = "Raqib taklifi: %d-Bob · %d-Daraja (\"%s\")" % [zone_id, actual_lvl, title_str]
		incoming_box.visible = true
		SoundManager.play("win")

func _on_accept_pressed() -> void:
	SoundManager.play("click")
	if pending_proposal_id > 0:
		DuelService.respond_proposal(pending_proposal_id, true)
		incoming_box.visible = false

func _on_reject_pressed() -> void:
	SoundManager.play("click")
	if pending_proposal_id > 0:
		DuelService.respond_proposal(pending_proposal_id, false)
		incoming_box.visible = false

func _on_match_agreed(zone_id: int, level_id: int, random_seed: int) -> void:
	if incoming_box: incoming_box.visible = false
	var actual_level := (zone_id - 1) * 20 + level_id
	_launch_game_with_loading(actual_level, random_seed)

func _on_duel_updated(data: Dictionary) -> void:
	var status: String = str(data.get("duel_status", ""))
	if status == "LOBBY":
		_refresh_player_cards()

# -------------------------------------------------------------
# Qidiruv va Taklif Yuborish
# -------------------------------------------------------------
func _on_invite_pressed() -> void:
	if not tag_input:
		return
	var tag := tag_input.text.strip_edges().to_upper()
	if tag.begins_with("#"):
		tag = tag.trim_prefix("#")
	if tag.is_empty():
		_set_search_status("Iltimos, do'stingiz ID sini kiriting (masalan WW-1234)")
		return
		
	_send_direct_invite(tag, tag)

func _send_direct_invite(tag: String, display_name: String) -> void:
	_set_search_status("Taklif yuborilmoqda: %s..." % display_name)
	DuelService.send_invitation(tag, func(res: Dictionary):
		if res.get("success", false):
			_set_search_status("Taklif yuborildi! Raqib kutilmoqda...")
			_switch_subview("lobby")
		else:
			_set_search_status(res.get("message", "Taklif yuborib bo'lmadi"))
	)

func _on_random_btn_pressed() -> void:
	if is_matchmaking:
		_cancel_matchmaking("Qidiruv bekor qilindi.")
		return
		
	is_matchmaking = true
	mm_poll_timer = 0.0
	mm_dots_timer = 0.0
	mm_dots_count = 0
	if random_btn:
		random_btn.text = "Qidiruvni bekor qilish"
	_set_search_status("Navbatga ulanmoqda...")
	
	DuelService.find_random_match(func(res: Dictionary):
		if res.get("matched", false):
			_on_matched_success()
	)

func _on_matched_success() -> void:
	is_matchmaking = false
	if random_btn:
		random_btn.text = "Tasodifiy Raqib Qidirish"
	_set_search_status("Raqib topildi! Lobbiyga ulanmoqda...")
	_switch_subview("lobby")

func _cancel_matchmaking(reason: String) -> void:
	is_matchmaking = false
	DuelService.cancel_matchmaking()
	if random_btn:
		random_btn.text = "Tasodifiy Raqib Qidirish"
	_set_search_status(reason)

func _process(delta: float) -> void:
	if is_matchmaking:
		mm_poll_timer += delta
		mm_dots_timer += delta
		
		if mm_dots_timer >= 0.4:
			mm_dots_timer = 0.0
			mm_dots_count = (mm_dots_count + 1) % 4
			var dots := ".".repeat(mm_dots_count)
			if search_status:
				search_status.text = "Onlayn raqib qidirilmoqda" + dots
				
		if mm_poll_timer >= 1.5:
			mm_poll_timer = 0.0
			DuelService.poll_match_status(func(res: Dictionary):
				if res.get("matched", false):
					_on_matched_success()
			)

func _set_search_status(msg: String) -> void:
	if search_status:
		search_status.text = msg

func _on_copy_my_id() -> void:
	DisplayServer.clipboard_set(ProfileManager.player_tag)
	if copy_id_btn:
		copy_id_btn.text = "Olingan!"
		var tw := create_tween()
		tw.tween_interval(1.5)
		tw.tween_callback(func():
			if copy_id_btn:
				copy_id_btn.text = "Nusxa"
		)
	_set_search_status("ID xotiraga nusxalandi: #" + ProfileManager.player_tag)

# -------------------------------------------------------------
# Do'stlar va Faol O'yinchilar Ro'yxati
# -------------------------------------------------------------
func _load_and_render_friends() -> void:
	if not friends_vbox:
		return
		
	for child in friends_vbox.get_children():
		child.queue_free()
		
	var loading_lbl := Label.new()
	loading_lbl.text = "O'yinchilar ro'yxati yangilanmoqda..."
	loading_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.75))
	loading_lbl.add_theme_font_size_override("font_size", 12)
	friends_vbox.add_child(loading_lbl)
	
	DuelService.fetch_active_players(func(active_list: Array):
		if not is_inside_tree() or not friends_vbox:
			return
		for child in friends_vbox.get_children():
			child.queue_free()
			
		var local_friends: Array = ProfileManager.get_saved_friends()
		var combined_map: Dictionary = {}
		
		for f in local_friends:
			if f is Dictionary:
				var t: String = str(f.get("player_tag", "")).strip_edges().to_upper()
				if not t.is_empty() and t != ProfileManager.player_tag:
					combined_map[t] = {
						"tag": t,
						"name": str(f.get("username", t)),
						"is_friend": true
					}
					
		for p in active_list:
			if p is Dictionary:
				var t: String = str(p.get("player_tag", "")).strip_edges().to_upper()
				if not t.is_empty() and t != ProfileManager.player_tag and not combined_map.has(t):
					combined_map[t] = {
						"tag": t,
						"name": str(p.get("username", t)),
						"is_friend": false
					}
					
		if combined_map.is_empty():
			var empty_lbl := Label.new()
			empty_lbl.text = "Hozircha faol o'yinchilar yo'q. ID kiriting yoki AI Ghost duelini sinab ko'ring!"
			empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.75))
			empty_lbl.add_theme_font_size_override("font_size", 12)
			friends_vbox.add_child(empty_lbl)
			return
			
		for t_key in combined_map.keys():
			var item: Dictionary = combined_map[t_key]
			_create_friend_card(item["tag"], item["name"], item["is_friend"])
	)

func _create_friend_card(tag: String, uname: String, is_friend: bool) -> void:
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.07, 0.10, 0.16, 0.85)
	card_style.border_color = Color(0.20, 0.30, 0.45, 0.50)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(12)
	card_style.content_margin_left = 12.0
	card_style.content_margin_right = 12.0
	card_style.content_margin_top = 6.0
	card_style.content_margin_bottom = 6.0
	card.add_theme_stylebox_override("panel", card_style)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)
	
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 1)
	
	var name_lbl := Label.new()
	name_lbl.text = uname
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	vbox.add_child(name_lbl)
	
	var tag_lbl := Label.new()
	tag_lbl.text = "#" + tag + (" · Do'st" if is_friend else " · Onlayn")
	tag_lbl.add_theme_font_size_override("font_size", 10)
	tag_lbl.add_theme_color_override("font_color", Color(0.38, 0.74, 0.97))
	vbox.add_child(tag_lbl)
	
	hbox.add_child(vbox)
	
	var invite_btn_card := Button.new()
	invite_btn_card.text = "Chaqirish"
	invite_btn_card.custom_minimum_size = Vector2(95, 28)
	invite_btn_card.add_theme_font_size_override("font_size", 11)
	_style_button(invite_btn_card, "chip")
	
	invite_btn_card.pressed.connect(func():
		_send_direct_invite(tag, uname)
	)
	hbox.add_child(invite_btn_card)
	
	friends_vbox.add_child(card)

# -------------------------------------------------------------
# Tugmalar Dizayni (Capsule & Solid Styling)
# -------------------------------------------------------------
func _apply_all_styles() -> void:
	if back_btn:
		back_btn.icon = IconFactory.get_icon("arrow_left", 0.9)
		back_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		back_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	if copy_id_btn: _style_button(copy_id_btn, "chip")
	if play_bot_btn: _style_button(play_bot_btn, "white")
	if propose_btn: _style_button(propose_btn, "glass")
	if reject_btn: _style_button(reject_btn, "danger")
	if accept_btn: _style_button(accept_btn, "white")
	if invite_btn: _style_button(invite_btn, "white")
	if random_btn: _style_button(random_btn, "glass")
	if refresh_friends_btn: _style_button(refresh_friends_btn, "chip")
	
	if tag_input:
		var norm := StyleBoxFlat.new()
		norm.bg_color = Color(0.06, 0.08, 0.13, 0.95)
		norm.border_color = Color(0.25, 0.35, 0.5, 0.65)
		norm.set_border_width_all(1)
		norm.set_corner_radius_all(19)
		norm.content_margin_left = 16.0
		norm.content_margin_right = 16.0
		norm.content_margin_top = 8.0
		norm.content_margin_bottom = 8.0
		
		var foc := norm.duplicate() as StyleBoxFlat
		foc.border_color = Color(0.38, 0.74, 0.97, 0.95)
		foc.set_border_width_all(1)
		
		tag_input.add_theme_stylebox_override("normal", norm)
		tag_input.add_theme_stylebox_override("focus", foc)

func _style_button(btn: Button, variant: String) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	var r: int = 18
	if variant == "chip":
		r = 12
		
	var normal := StyleBoxFlat.new()
	normal.set_corner_radius_all(r)
	normal.content_margin_left = 16.0
	normal.content_margin_right = 16.0
	normal.content_margin_top = 6.0
	normal.content_margin_bottom = 6.0
	
	var hover := StyleBoxFlat.new()
	hover.set_corner_radius_all(r)
	hover.content_margin_left = 16.0
	hover.content_margin_right = 16.0
	hover.content_margin_top = 6.0
	hover.content_margin_bottom = 6.0
	
	var pressed := StyleBoxFlat.new()
	pressed.set_corner_radius_all(r)
	pressed.content_margin_left = 16.0
	pressed.content_margin_right = 16.0
	pressed.content_margin_top = 6.0
	pressed.content_margin_bottom = 6.0
	
	if variant == "white":
		normal.bg_color = Color(0.96, 0.98, 1.0, 1.0)
		btn.add_theme_color_override("font_color", Color(0.08, 0.10, 0.15, 1.0))
		
		hover.bg_color = Color(1.0, 1.0, 1.0, 1.0)
		hover.border_color = Color(0.38, 0.74, 0.97, 0.95)
		hover.set_border_width_all(1)
		hover.shadow_color = Color(0.38, 0.74, 0.97, 0.35)
		hover.shadow_size = 4
		btn.add_theme_color_override("font_hover_color", Color(0.04, 0.06, 0.10, 1.0))
		
		pressed.bg_color = Color(0.80, 0.84, 0.90, 1.0)
		btn.add_theme_color_override("font_pressed_color", Color(0.05, 0.08, 0.12, 1.0))
		
	elif variant == "glass":
		normal.bg_color = Color(0.08, 0.12, 0.18, 0.85)
		normal.border_color = Color(0.25, 0.35, 0.50, 0.6)
		normal.set_border_width_all(1)
		btn.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0, 1.0))
		
		hover.bg_color = Color(0.12, 0.18, 0.28, 0.95)
		hover.border_color = Color(0.38, 0.74, 0.97, 0.95)
		hover.set_border_width_all(1)
		hover.shadow_color = Color(0.38, 0.74, 0.97, 0.30)
		hover.shadow_size = 4
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
		
		pressed.bg_color = Color(0.06, 0.09, 0.14, 0.9)
		pressed.border_color = Color(0.20, 0.30, 0.45, 0.7)
		pressed.set_border_width_all(1)
		btn.add_theme_color_override("font_pressed_color", Color(0.80, 0.85, 0.95, 1.0))
		
	elif variant == "danger":
		normal.bg_color = Color(0.18, 0.08, 0.10, 0.85)
		normal.border_color = Color(0.60, 0.20, 0.25, 0.6)
		normal.set_border_width_all(1)
		btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 1.0))
		
		hover.bg_color = Color(0.26, 0.10, 0.12, 0.95)
		hover.border_color = Color(1.0, 0.30, 0.35, 0.90)
		hover.set_border_width_all(1)
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.60, 0.60, 1.0))
		
		pressed.bg_color = Color(0.12, 0.05, 0.07, 0.9)
		pressed.set_border_width_all(1)
		
	elif variant == "chip":
		normal.bg_color = Color(0.10, 0.15, 0.24, 0.85)
		normal.border_color = Color(0.28, 0.42, 0.62, 0.70)
		normal.set_border_width_all(1)
		btn.add_theme_color_override("font_color", Color(0.40, 0.75, 1.0, 1.0))
		
		hover.bg_color = Color(0.16, 0.26, 0.40, 0.95)
		hover.border_color = Color(0.38, 0.74, 0.97, 0.95)
		hover.set_border_width_all(1)
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
		
		pressed.bg_color = Color(0.08, 0.12, 0.18, 0.9)
		pressed.set_border_width_all(1)
		
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", normal)
