extends Control

# DuelLobbyModal - Wrong Way 1v1 Duel Lobby & Real-Time Negotiation UI
# - Clean, modern competitive UI with glowing glass aesthetics
# - Direct challenge by Player ID (#WW-XXXX) or quick 1-click Friends & Active Players
# - One-click ID copy to easily share with friends
# - Random matchmaking with animated pulse status (no reverse countdown)
# - Real-time mutual zone & level negotiation with [X] and [✓]
# - Synchronized 3-2-1 countdown launch
# - Strictly preserved rounded button shapes across all states (normal, hover, pressed)

signal duel_started(zone_id: int, level_id: int, random_seed: int)

@onready var close_btn: Button = get_node_or_null("Center/Panel/CloseBtn")
@onready var my_id_label: Label = get_node_or_null("Center/Panel/MyIdBar/MyIdLabel")
@onready var copy_id_btn: Button = get_node_or_null("Center/Panel/MyIdBar/CopyIdBtn")

@onready var search_box: VBoxContainer = get_node_or_null("Center/Panel/VBox/SearchBox")
@onready var tag_input: LineEdit = get_node_or_null("Center/Panel/VBox/SearchBox/DirectInviteHBox/TagInput")
@onready var invite_btn: Button = get_node_or_null("Center/Panel/VBox/SearchBox/DirectInviteHBox/InviteBtn")
@onready var random_btn: Button = get_node_or_null("Center/Panel/VBox/SearchBox/RandomBtn")
@onready var search_status: Label = get_node_or_null("Center/Panel/VBox/SearchBox/StatusLabel")
@onready var refresh_friends_btn: Button = get_node_or_null("Center/Panel/VBox/SearchBox/FriendsHeaderHBox/RefreshBtn")
@onready var friends_vbox: VBoxContainer = get_node_or_null("Center/Panel/VBox/SearchBox/FriendsScroll/FriendsVBox")

@onready var lobby_box: VBoxContainer = get_node_or_null("Center/Panel/VBox/LobbyBox")
@onready var player_a_name: Label = get_node_or_null("Center/Panel/VBox/LobbyBox/PlayersHBox/PlayerACard/VBox/NameLabel")
@onready var player_a_tag: Label = get_node_or_null("Center/Panel/VBox/LobbyBox/PlayersHBox/PlayerACard/VBox/TagLabel")
@onready var player_b_name: Label = get_node_or_null("Center/Panel/VBox/LobbyBox/PlayersHBox/PlayerBCard/VBox/NameLabel")
@onready var player_b_tag: Label = get_node_or_null("Center/Panel/VBox/LobbyBox/PlayersHBox/PlayerBCard/VBox/TagLabel")

@onready var proposal_panel: PanelContainer = get_node_or_null("Center/Panel/VBox/LobbyBox/NegotiationPanel")
@onready var zone_select: OptionButton = get_node_or_null("Center/Panel/VBox/LobbyBox/NegotiationPanel/VBox/SelectHBox/ZoneSelect")
@onready var level_select: OptionButton = get_node_or_null("Center/Panel/VBox/LobbyBox/NegotiationPanel/VBox/SelectHBox/LevelSelect")
@onready var propose_btn: Button = get_node_or_null("Center/Panel/VBox/LobbyBox/NegotiationPanel/VBox/SelectHBox/ProposeBtn")

@onready var incoming_box: PanelContainer = get_node_or_null("Center/Panel/VBox/LobbyBox/IncomingProposalBox")
@onready var proposal_text: Label = get_node_or_null("Center/Panel/VBox/LobbyBox/IncomingProposalBox/HBox/ProposalLabel")
@onready var reject_btn: Button = get_node_or_null("Center/Panel/VBox/LobbyBox/IncomingProposalBox/HBox/RejectBtn")
@onready var accept_btn: Button = get_node_or_null("Center/Panel/VBox/LobbyBox/IncomingProposalBox/HBox/AcceptBtn")

@onready var countdown_label: Label = get_node_or_null("Center/Panel/CountdownLabel")

var pending_proposal_id: int = 0
var is_in_lobby: bool = false
var is_matchmaking: bool = false
var mm_dots_timer: float = 0.0
var mm_dots_count: int = 0
var mm_poll_timer: float = 0.0

func _ready() -> void:
	visible = false
	_apply_all_styles()
	
	if close_btn: close_btn.pressed.connect(_on_leave_lobby)
	if copy_id_btn: copy_id_btn.pressed.connect(_on_copy_my_id)
	if invite_btn: invite_btn.pressed.connect(_on_invite_pressed)
	if random_btn: random_btn.pressed.connect(_on_random_btn_pressed)
	if refresh_friends_btn: refresh_friends_btn.pressed.connect(_load_and_render_friends)
	if propose_btn: propose_btn.pressed.connect(_on_propose_pressed)
	if reject_btn: reject_btn.pressed.connect(_on_reject_pressed)
	if accept_btn: accept_btn.pressed.connect(_on_accept_pressed)
	
	_setup_options()
	
	DuelService.proposal_received.connect(_on_proposal_received)
	DuelService.match_agreed.connect(_on_match_agreed)
	DuelService.match_started.connect(_on_match_started)
	DuelService.duel_updated.connect(_on_duel_updated)

func open() -> void:
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	if my_id_label:
		my_id_label.text = "Sizning ID: #" + ProfileManager.player_tag
		
	if tag_input:
		tag_input.text = ""
		
	is_in_lobby = not DuelService.active_duel_id.is_empty()
	_update_view_state()
	
	if not is_in_lobby:
		_load_and_render_friends()

func _update_view_state() -> void:
	if search_box: search_box.visible = not is_in_lobby
	if lobby_box: lobby_box.visible = is_in_lobby
	if incoming_box: incoming_box.visible = false
	if countdown_label: countdown_label.visible = false
	
	if is_in_lobby:
		_refresh_player_cards()

func _setup_options() -> void:
	if zone_select:
		zone_select.clear()
		zone_select.add_item("1-Bob: Qorong'i O'rmon", 1)
		zone_select.add_item("2-Bob: Qorli Cho'qqilar", 2)
		
	if level_select:
		level_select.clear()
		for i in range(1, 21):
			level_select.add_item("%d-Daraja" % i, i)

func _refresh_player_cards() -> void:
	var d := DuelService.active_duel
	if d.is_empty():
		return
	var my_id := ProfileManager.player_id
	var pa_id: String = str(d.get("player_a_id", ""))
	
	if player_a_name:
		player_a_name.text = ProfileManager.username if pa_id == my_id else "Raqib"
		player_a_tag.text = ProfileManager.player_tag if pa_id == my_id else ""
	if player_b_name:
		player_b_name.text = "Raqib" if pa_id == my_id else ProfileManager.username
		player_b_tag.text = "" if pa_id == my_id else ProfileManager.player_tag

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

# -------------------------------------------------------------
# Tugmalarning hover va bosilganda shaklini saqlash (Capsule Styling)
# -------------------------------------------------------------
func _apply_all_styles() -> void:
	if invite_btn: _style_button(invite_btn, "white")
	if random_btn:
		_style_button(random_btn, "glass")
		random_btn.icon = IconFactory.get_icon("lightning", 0.85)
	if close_btn: _style_button(close_btn, "circle")
	if copy_id_btn:
		_style_button(copy_id_btn, "chip")
		copy_id_btn.icon = IconFactory.get_icon("copy", 0.75)
	if refresh_friends_btn:
		_style_button(refresh_friends_btn, "chip")
		refresh_friends_btn.icon = IconFactory.get_icon("refresh", 0.75)
	if propose_btn: _style_button(propose_btn, "white")
	if reject_btn:
		_style_button(reject_btn, "danger")
		reject_btn.icon = IconFactory.get_icon("close", 0.75)
	if accept_btn:
		_style_button(accept_btn, "white")
		accept_btn.icon = IconFactory.get_icon("check", 0.75)
	
	if tag_input:
		var norm := StyleBoxFlat.new()
		norm.bg_color = Color(0.06, 0.08, 0.13, 0.95)
		norm.border_color = Color(0.25, 0.35, 0.5, 0.65)
		norm.set_border_width_all(1)
		norm.set_corner_radius_all(20)
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
	var r: int = 20
	if variant == "chip":
		r = 12
	elif variant == "circle":
		r = 18
		
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
		hover.shadow_color = Color(1.0, 0.20, 0.20, 0.25)
		hover.shadow_size = 4
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
		
	elif variant == "circle":
		normal.content_margin_left = 0.0
		normal.content_margin_right = 0.0
		normal.content_margin_top = 0.0
		normal.content_margin_bottom = 0.0
		normal.corner_detail = 16
		hover.content_margin_left = 0.0
		hover.content_margin_right = 0.0
		hover.content_margin_top = 0.0
		hover.content_margin_bottom = 0.0
		hover.corner_detail = 16
		pressed.content_margin_left = 0.0
		pressed.content_margin_right = 0.0
		pressed.content_margin_top = 0.0
		pressed.content_margin_bottom = 0.0
		pressed.corner_detail = 16
		
		normal.bg_color = Color(0.09, 0.12, 0.18, 0.8)
		normal.border_color = Color(0.30, 0.40, 0.55, 0.6)
		normal.set_border_width_all(1)
		btn.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0, 1.0))
		
		hover.bg_color = Color(0.15, 0.20, 0.30, 0.95)
		hover.border_color = Color(0.38, 0.74, 0.97, 0.95)
		hover.set_border_width_all(1)
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
		
		pressed.bg_color = Color(0.06, 0.08, 0.12, 0.9)
		pressed.set_border_width_all(1)
		
		btn.custom_minimum_size = Vector2(36, 36)
		btn.size = Vector2(36, 36)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.add_theme_font_size_override("font_size", 14)
		
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", normal)

# -------------------------------------------------------------
# Do'stlar va Faol O'yinchilar Ro'yxati (1-Click Tezkor Chaqirish)
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
		
		# 1. Avval saqlangan mahalliy do'stlar
		for f in local_friends:
			if f is Dictionary:
				var t: String = str(f.get("player_tag", "")).strip_edges().to_upper()
				if not t.is_empty() and t != ProfileManager.player_tag:
					combined_map[t] = {
						"tag": t,
						"name": str(f.get("username", t)),
						"is_friend": true
					}
					
		# 2. Keyin Supabase'dagi boshqa faol o'yinchilar
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
			empty_lbl.text = "Hozircha do'stlar yo'q. ID kiriting yoki o'z ID raqamingizni do'stingizga yuboring!"
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
	
	# Icon
	var icon := IconFactory.create_texture_rect("users_white", Vector2(16, 16), 0.75)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon)
	
	# Name & Tag VBox
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
	
	# Quick Invite Button
	var invite_btn_card := Button.new()
	invite_btn_card.text = "Chaqirish"
	invite_btn_card.icon = IconFactory.get_icon("swords", 0.75)
	invite_btn_card.custom_minimum_size = Vector2(95, 28)
	invite_btn_card.add_theme_font_size_override("font_size", 11)
	_style_button(invite_btn_card, "chip")
	
	invite_btn_card.pressed.connect(func():
		_send_direct_invite(tag, uname)
	)
	hbox.add_child(invite_btn_card)
	
	friends_vbox.add_child(card)

func _on_copy_my_id() -> void:
	DisplayServer.clipboard_set(ProfileManager.player_tag)
	if copy_id_btn:
		copy_id_btn.text = "Olingan!"
		copy_id_btn.icon = IconFactory.get_icon("check", 0.75)
		var tw := create_tween()
		tw.tween_interval(1.5)
		tw.tween_callback(func():
			if copy_id_btn:
				copy_id_btn.text = "Nusxa"
				copy_id_btn.icon = IconFactory.get_icon("copy", 0.75)
		)
	_set_search_status("ID xotiraga nusxalandi: #" + ProfileManager.player_tag)

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
		_set_search_status("Iltimos, do'stingiz ID sini kiriting (masalan WW-4821)")
		return
		
	_send_direct_invite(tag, tag)

func _send_direct_invite(tag: String, display_name: String) -> void:
	_set_search_status("Taklif yuborilmoqda: %s..." % display_name)
	DuelService.send_invitation(tag, func(res: Dictionary):
		if res.get("success", false):
			is_in_lobby = true
			_set_search_status("Taklif yuborildi! Raqib kutilmoqda...")
			_update_view_state()
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
		random_btn.icon = IconFactory.get_icon("close", 0.75)
	_set_search_status("Navbatga ulanmoqda...")
	
	DuelService.find_random_match(func(res: Dictionary):
		if res.get("matched", false):
			_on_matched_success()
	)

func _on_matched_success() -> void:
	is_matchmaking = false
	if random_btn:
		random_btn.text = "Tasodifiy Raqib Qidirish"
		random_btn.icon = IconFactory.get_icon("lightning", 0.85)
	is_in_lobby = true
	_set_search_status("Raqib topildi! Lobbiyga ulanmoqda...")
	_update_view_state()

func _cancel_matchmaking(reason: String) -> void:
	is_matchmaking = false
	DuelService.cancel_matchmaking()
	if random_btn:
		random_btn.text = "Tasodifiy Raqib Qidirish"
		random_btn.icon = IconFactory.get_icon("lightning", 0.85)
	_set_search_status(reason)

func _set_search_status(msg: String) -> void:
	if search_status:
		search_status.text = msg

# -------------------------------------------------------------
# Zona va Daraja Kelishuvi (Negotiation)
# -------------------------------------------------------------
func _on_propose_pressed() -> void:
	var z_idx := zone_select.get_selected_id()
	var l_idx := level_select.get_selected_id()
	_set_search_status("Taklif yuborilmoqda: %d-Bob, %d-Daraja..." % [z_idx, l_idx])
	DuelService.propose_level(z_idx, l_idx)

func _on_proposal_received(_proposer_id: String, zone_id: int, level_id: int, proposal_id: int) -> void:
	pending_proposal_id = proposal_id
	if incoming_box and proposal_text:
		var actual_lvl: int = level_id if zone_id == 1 else (level_id + 20)
		var is_unlocked: bool = SaveManager.is_level_unlocked(actual_lvl)
		
		if is_unlocked:
			proposal_text.text = "Raqib taklifi: %d-Bob · %d-Daraja" % [zone_id, level_id]
			proposal_text.add_theme_color_override("font_color", Color(0.95, 0.98, 1, 1))
		else:
			proposal_text.text = "Raqib taklifi: %d-Bob · %d-Daraja  (Qulflangan)" % [zone_id, level_id]
			proposal_text.add_theme_color_override("font_color", Color(1.0, 0.85, 0.40, 1))
			
		incoming_box.visible = true

func _on_accept_pressed() -> void:
	if pending_proposal_id > 0:
		DuelService.respond_proposal(pending_proposal_id, true)
		incoming_box.visible = false

func _on_reject_pressed() -> void:
	if pending_proposal_id > 0:
		DuelService.respond_proposal(pending_proposal_id, false)
		incoming_box.visible = false

func _on_match_agreed(zone_id: int, level_id: int, random_seed: int) -> void:
	if incoming_box: incoming_box.visible = false
	if proposal_panel: proposal_panel.visible = false
	_start_countdown_sequence(zone_id, level_id, random_seed)

func _start_countdown_sequence(zone_id: int, level_id: int, random_seed: int) -> void:
	if not countdown_label:
		return
	countdown_label.visible = true
	
	for count in [3, 2, 1]:
		countdown_label.text = str(count)
		countdown_label.scale = Vector2(1.5, 1.5)
		var tw := create_tween()
		tw.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.35)
		SoundManager.play("click")
		await get_tree().create_timer(0.9).timeout
		
	countdown_label.text = "START!"
	SoundManager.play("win")
	await get_tree().create_timer(0.4).timeout
	
	DuelService.start_match()
	duel_started.emit(zone_id, level_id, random_seed)
	visible = false

func _on_match_started(_started_at: String) -> void:
	pass

func _on_duel_updated(data: Dictionary) -> void:
	var status: String = str(data.get("duel_status", ""))
	if status == "LOBBY":
		is_in_lobby = true
		_update_view_state()

func _on_leave_lobby() -> void:
	if is_matchmaking:
		_cancel_matchmaking("Qidiruv bekor qilindi.")
	DuelService.leave_active_duel()
	visible = false
