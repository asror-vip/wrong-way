extends Control
class_name LeaderboardModal

signal closed

@onready var backdrop: ColorRect = $Backdrop
@onready var card: Panel = $Card
@onready var close_btn: Button = $Card/CloseBtn
@onready var title_label: Label = $Card/TitleRow/TitleLabel
@onready var title_icon_rect: TextureRect = $Card/TitleRow/TitleIcon

@onready var btn_global: Button = $Card/TabRow/BtnGlobal
@onready var btn_friends: Button = $Card/TabRow/BtnFriends

@onready var list_box: VBoxContainer = $Card/ListScroll/ListBox
@onready var my_rank_label: Label = get_node_or_null("Card/MyStatsBar/HBox/RankLabel")
@onready var my_avatar_rect: TextureRect = get_node_or_null("Card/MyStatsBar/HBox/AvatarRect")
@onready var my_name_label: Label = get_node_or_null("Card/MyStatsBar/HBox/VBox/NameLabel")
@onready var my_stats_label: Label = get_node_or_null("Card/MyStatsBar/HBox/VBox/StatsLabel")

var style_white = preload("res://resources/themes/btn_capsule_white.tres")
var style_white_hov = preload("res://resources/themes/btn_capsule_white_hover.tres")
var style_white_press = preload("res://resources/themes/btn_capsule_white_pressed.tres")
var style_glass = preload("res://resources/themes/btn_capsule_glass.tres")
var style_glass_hov = preload("res://resources/themes/btn_capsule_glass_hover.tres")
var style_glass_press = preload("res://resources/themes/btn_capsule_glass_pressed.tres")

enum TabMode { GLOBAL, FRIENDS }
var current_tab: TabMode = TabMode.GLOBAL

var http_request: HTTPRequest = null
var remote_players: Array = []
var is_fetching: bool = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	http_request = HTTPRequest.new()
	http_request.name = "LeaderboardHTTP"
	http_request.timeout = 5.0
	add_child(http_request)
	http_request.request_completed.connect(_on_http_completed)
	
	if close_btn:
		close_btn.icon = IconFactory.get_icon("circle_btn_close", 1.0)
		close_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		close_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		close_btn.pressed.connect(close)
		
	if title_icon_rect:
		title_icon_rect.texture = IconFactory.get_icon("trophy_white", 1.0)
		
	if btn_global:
		btn_global.pressed.connect(func(): _set_tab(TabMode.GLOBAL))
	if btn_friends:
		btn_friends.pressed.connect(func(): _set_tab(TabMode.FRIENDS))
		
	if backdrop:
		backdrop.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				close()
		)
		
	if my_avatar_rect:
		my_avatar_rect.texture = IconFactory.get_icon("avatar_player", 1.0)
		
	LocaleManager.language_changed.connect(_on_language_changed)
	_update_texts()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()

func open() -> void:
	visible = true
	_update_texts()
	_update_tab_buttons()
	_fetch_supabase_leaderboard()
	_refresh_list()
	
	# Smooth entry tween
	if card:
		card.scale = Vector2(0.92, 0.92)
		card.pivot_offset = card.size / 2.0
		var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "scale", Vector2.ONE, 0.20)

func close() -> void:
	SoundManager.play("click")
	visible = false
	closed.emit()

func _on_language_changed(_lang: String) -> void:
	_update_texts()
	if visible:
		_refresh_list()

func _update_texts() -> void:
	if title_label:
		title_label.text = LocaleManager.t("leaderboard_title")
	if btn_global:
		btn_global.text = LocaleManager.t("tab_global")
	if btn_friends:
		btn_friends.text = LocaleManager.t("tab_friends")
		
	var display_name := ProfileManager.username
	if display_name.is_empty() or display_name.to_lower() == "player":
		display_name = LocaleManager.t("player_you")
	else:
		display_name = "%s (%s)" % [display_name, LocaleManager.t("player_you")]
		
	if my_name_label:
		my_name_label.text = display_name
		
	if my_avatar_rect:
		var av_keys := ["avatar_player", "avatar_ninja", "avatar_shadow", "avatar_robot", "avatar_pro"]
		var av_idx := (ProfileManager.avatar_index - 1) % av_keys.size()
		if av_idx < 0: av_idx = 0
		my_avatar_rect.texture = IconFactory.get_icon(av_keys[av_idx], 1.0)

func _set_tab(mode: TabMode) -> void:
	if current_tab == mode:
		return
	SoundManager.play("click")
	current_tab = mode
	_update_tab_buttons()
	_refresh_list()

func _update_tab_buttons() -> void:
	if not btn_global or not btn_friends:
		return
	if current_tab == TabMode.GLOBAL:
		_apply_btn_style(btn_global, true)
		_apply_btn_style(btn_friends, false)
	else:
		_apply_btn_style(btn_global, false)
		_apply_btn_style(btn_friends, true)

func _apply_btn_style(btn: Button, is_active: bool) -> void:
	if is_active:
		btn.add_theme_stylebox_override("normal", style_white)
		btn.add_theme_stylebox_override("hover", style_white_hov)
		btn.add_theme_stylebox_override("pressed", style_white_press)
		btn.add_theme_color_override("font_color", Color(0.08, 0.08, 0.12))
	else:
		btn.add_theme_stylebox_override("normal", style_glass)
		btn.add_theme_stylebox_override("hover", style_glass_hov)
		btn.add_theme_stylebox_override("pressed", style_glass_press)
		btn.add_theme_color_override("font_color", Color(0.85, 0.88, 0.94))

# Sort rule requested:
# 1. Total Stars (DESC - most stars always ranks higher)
# 2. Total Time in seconds (ASC - lowest time ranks higher)
# 3. Total Deaths (ASC - fewer deaths ranks higher)
func _sort_players(a: Dictionary, b: Dictionary) -> bool:
	var a_stars: int = a.get("stars", 0)
	var b_stars: int = b.get("stars", 0)
	if a_stars != b_stars:
		return a_stars > b_stars
		
	var a_time: int = a.get("time_sec", 0)
	var b_time: int = b.get("time_sec", 0)
	if a_time != b_time:
		return a_time < b_time
		
	var a_deaths: int = a.get("deaths", 0)
	var b_deaths: int = b.get("deaths", 0)
	return a_deaths < b_deaths

func _fetch_supabase_leaderboard() -> void:
	if is_fetching or not http_request:
		return
	is_fetching = true
	var url := Env.get_supabase_url() + "/rest/v1/profiles?select=id,username,avatar_index,stars,time_sec,deaths&order=stars.desc,time_sec.asc&limit=50"
	var headers := [
		"apikey: " + Env.get_supabase_anon_key(),
		"Authorization: Bearer " + Env.get_supabase_anon_key()
	]
	http_request.request(url, headers, HTTPClient.METHOD_GET)

func _on_http_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	is_fetching = false
	if response_code == 200:
		var txt := body.get_string_from_utf8()
		var parsed = JSON.parse_string(txt)
		if parsed is Array:
			remote_players.clear()
			var av_keys := ["avatar_player", "avatar_ninja", "avatar_shadow", "avatar_robot", "avatar_pro"]
			for row in parsed:
				if row is Dictionary:
					var p_id: String = str(row.get("id", ""))
					# O'z profilimizni lokal holatda pastda qo'shamiz
					if p_id == ProfileManager.player_id:
						continue
					var a_idx: int = int(row.get("avatar_index", 1)) - 1
					if a_idx < 0 or a_idx >= av_keys.size(): a_idx = 0
					var u_name: String = str(row.get("username", "O'yinchi"))
					remote_players.append({
						"id": p_id,
						"name": u_name,
						"avatar": av_keys[a_idx],
						"stars": int(row.get("stars", 0)),
						"time_sec": int(row.get("time_sec", 0)),
						"deaths": int(row.get("deaths", 0)),
						"is_me": false
					})
			_refresh_list()

func _refresh_list() -> void:
	if not list_box:
		return
	for ch in list_box.get_children():
		ch.queue_free()
		
	# Live Player Stats
	var my_stars: int = SaveManager.get_total_stars()
	var my_time: int = SaveManager.get_total_beaten_time_sec()
	var my_deaths: int = SaveManager.get_total_beaten_deaths()
	
	var my_display_name := ProfileManager.username
	if my_display_name.is_empty() or my_display_name.to_lower() == "player":
		my_display_name = LocaleManager.t("player_you")
	else:
		my_display_name = "%s (%s)" % [my_display_name, LocaleManager.t("player_you")]
		
	var av_keys := ["avatar_player", "avatar_ninja", "avatar_shadow", "avatar_robot", "avatar_pro"]
	var av_idx := (ProfileManager.avatar_index - 1) % av_keys.size()
	if av_idx < 0: av_idx = 0
	var my_avatar: String = av_keys[av_idx]
	
	var my_data := {
		"name": my_display_name,
		"avatar": my_avatar,
		"stars": my_stars,
		"time_sec": my_time,
		"deaths": my_deaths,
		"is_me": true
	}
	
	var raw_list: Array = []
	if current_tab == TabMode.GLOBAL:
		raw_list = remote_players.duplicate(true)
	else:
		# Do'stlar ro'yxati
		for p in remote_players:
			if ProfileManager.is_friend(p.get("id", "")):
				raw_list.append(p)
		
	raw_list.append(my_data)
	raw_list.sort_custom(_sort_players)
	
	var my_rank: int = 1
	for idx in range(raw_list.size()):
		var player_data: Dictionary = raw_list[idx]
		var rank: int = idx + 1
		if player_data.get("is_me", false):
			my_rank = rank
		var row: Control = _build_row(rank, player_data)
		list_box.add_child(row)
		
	# Update pinned bottom stats bar
	if my_rank_label:
		my_rank_label.text = "#%d" % my_rank
		if my_rank == 1:
			my_rank_label.add_theme_color_override("font_color", Color("#facc15"))
		elif my_rank == 2:
			my_rank_label.add_theme_color_override("font_color", Color("#e2e8f0"))
		elif my_rank == 3:
			my_rank_label.add_theme_color_override("font_color", Color("#f59e0b"))
		else:
			my_rank_label.add_theme_color_override("font_color", Color("#38bdf8"))
			
	if my_stats_label:
		my_stats_label.text = "%d yulduz   •   %ds   •   %d o'lim" % [my_stars, my_time, my_deaths]

func _build_row(rank: int, data: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 56)
	
	var is_me: bool = data.get("is_me", false)
	
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	
	if is_me:
		style.bg_color = Color(0.10, 0.20, 0.32, 0.90)
		style.border_color = Color("#38bdf8")
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.shadow_color = Color(0.22, 0.74, 0.97, 0.25)
		style.shadow_size = 6
	else:
		style.bg_color = Color(0.08, 0.10, 0.15, 0.75)
		style.border_color = Color(0.20, 0.25, 0.35, 0.50)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
	
	style.content_margin_left = 10.0
	style.content_margin_right = 12.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	row.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)
	
	# Left: Avatar container with rank decoration on top
	var avatar_box := Control.new()
	avatar_box.custom_minimum_size = Vector2(40, 44)
	avatar_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Base Avatar
	var avatar_icon: TextureRect = IconFactory.create_texture_rect(data.get("avatar", "avatar_player"), Vector2(34, 34), 1.0)
	avatar_icon.position = Vector2(3, 8)
	avatar_box.add_child(avatar_icon)
	
	# Rank decorations on top of avatar:
	# 1-o'rin: sariq toj (crown_gold)
	# 2-o'rin: 2 ta yulduzcha (star_gold)
	# 3-o'rin: 1 ta yulduzcha (star_gold)
	if rank == 1:
		var crown_icon := IconFactory.create_texture_rect("crown_gold", Vector2(20, 20), 0.8)
		crown_icon.position = Vector2(10, -5)
		avatar_box.add_child(crown_icon)
	elif rank == 2:
		var star_box := HBoxContainer.new()
		star_box.custom_minimum_size = Vector2(26, 12)
		star_box.position = Vector2(7, -3)
		star_box.add_theme_constant_override("separation", 2)
		star_box.alignment = BoxContainer.ALIGNMENT_CENTER
		var s1 := IconFactory.create_texture_rect("star_gold", Vector2(11, 11), 0.45)
		var s2 := IconFactory.create_texture_rect("star_gold", Vector2(11, 11), 0.45)
		star_box.add_child(s1)
		star_box.add_child(s2)
		avatar_box.add_child(star_box)
	elif rank == 3:
		var s_icon := IconFactory.create_texture_rect("star_gold", Vector2(13, 13), 0.55)
		s_icon.position = Vector2(13, -3)
		avatar_box.add_child(s_icon)
		
	hbox.add_child(avatar_box)
	
	# Center: Name and results row underneath
	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.alignment = BoxContainer.ALIGNMENT_CENTER
	info_box.add_theme_constant_override("separation", 2)
	
	var name_lbl := Label.new()
	var player_name: String = data.get("name", "Player")
	if is_me:
		name_lbl.text = "%s (SIZ)" % player_name
		name_lbl.add_theme_color_override("font_color", Color("#38bdf8"))
	else:
		name_lbl.text = player_name
		name_lbl.add_theme_color_override("font_color", Color("#f8fafc"))
	name_lbl.add_theme_font_size_override("font_size", 14)
	info_box.add_child(name_lbl)
	
	var stats_lbl := Label.new()
	var stars: int = data.get("stars", 0)
	var time_sec: int = data.get("time_sec", 0)
	var deaths: int = data.get("deaths", 0)
	stats_lbl.text = "%d yulduz   •   %ds   •   %d o'lim" % [stars, time_sec, deaths]
	stats_lbl.add_theme_font_size_override("font_size", 12)
	stats_lbl.add_theme_color_override("font_color", Color("#94a3b8") if not is_me else Color("#bae6fd"))
	info_box.add_child(stats_lbl)
	
	hbox.add_child(info_box)
	
	# Right: Rank Number
	var rank_lbl := Label.new()
	rank_lbl.text = "#%d" % rank
	rank_lbl.custom_minimum_size = Vector2(36, 0)
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rank_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if rank == 1:
		rank_lbl.add_theme_color_override("font_color", Color("#facc15")) # Gold
		rank_lbl.add_theme_font_size_override("font_size", 16)
	elif rank == 2:
		rank_lbl.add_theme_color_override("font_color", Color("#e2e8f0")) # Silver
		rank_lbl.add_theme_font_size_override("font_size", 15)
	elif rank == 3:
		rank_lbl.add_theme_color_override("font_color", Color("#f59e0b")) # Bronze
		rank_lbl.add_theme_font_size_override("font_size", 15)
	else:
		rank_lbl.add_theme_color_override("font_color", Color("#64748b")) # Slate
		rank_lbl.add_theme_font_size_override("font_size", 13)
	hbox.add_child(rank_lbl)
	
	return row

