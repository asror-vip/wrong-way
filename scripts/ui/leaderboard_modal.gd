extends Control
class_name LeaderboardModal

signal closed

@onready var backdrop: ColorRect = $Backdrop
@onready var card: Panel = $Card
@onready var close_btn: Button = $Card/CloseBtn
@onready var title_label: Label = $Card/TitleRow/TitleLabel
@onready var title_icon_rect: TextureRect = $Card/TitleRow/TitleIcon

@onready var tab_row: HBoxContainer = $Card/TabRow
@onready var btn_global: Button = $Card/TabRow/BtnGlobal
@onready var btn_friends: Button = $Card/TabRow/BtnFriends

@onready var list_scroll: ScrollContainer = $Card/ListScroll
@onready var list_box: VBoxContainer = $Card/ListScroll/ListBox
@onready var my_stats_bar: PanelContainer = $Card/MyStatsBar
@onready var my_rank_label: Label = get_node_or_null("Card/MyStatsBar/HBox/RankLabel")
@onready var my_avatar_rect: TextureRect = get_node_or_null("Card/MyStatsBar/HBox/AvatarRect")
@onready var my_name_label: Label = get_node_or_null("Card/MyStatsBar/HBox/VBox/NameLabel")
@onready var my_stats_label: Label = get_node_or_null("Card/MyStatsBar/HBox/VBox/StatsLabel")

@onready var guest_prompt: Control = get_node_or_null("Card/GuestPrompt")
@onready var guest_icon: TextureRect = get_node_or_null("Card/GuestPrompt/PromptCard/VBox/GuestIcon")
@onready var guest_title: Label = get_node_or_null("Card/GuestPrompt/PromptCard/VBox/GuestTitle")
@onready var guest_desc: Label = get_node_or_null("Card/GuestPrompt/PromptCard/VBox/GuestDesc")
@onready var google_sign_in_btn: Button = get_node_or_null("Card/GuestPrompt/PromptCard/VBox/GoogleSignInBtn")
@onready var guest_status_label: Label = get_node_or_null("Card/GuestPrompt/PromptCard/VBox/GuestStatusLabel")

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
var _entry_tween: Tween = null

# Touch & mouse drag-scroll + momentum state on ListScroll
var _scroll_touch_index: int = -1
var _is_touch_dragging: bool = false
var _is_mouse_dragging: bool = false
var _scroll_last_y: float = 0.0
var _scroll_last_msec: int = 0
var _scroll_pos_f: float = 0.0
var _scroll_velocity_y: float = 0.0

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
	if guest_icon:
		guest_icon.texture = IconFactory.get_icon("trophy_white", 1.2)
	if google_sign_in_btn:
		google_sign_in_btn.icon = IconFactory.get_icon("google", 0.9)
		google_sign_in_btn.pressed.connect(_on_google_sign_in_pressed)
	if list_box:
		list_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if list_scroll:
		list_scroll.gui_input.connect(_on_list_scroll_gui_input)
		
	if not LocaleManager.language_changed.is_connected(_on_language_changed):
		LocaleManager.language_changed.connect(_on_language_changed)
	if GoogleAuthService:
		if not GoogleAuthService.auth_succeeded.is_connected(_on_google_auth_succeeded):
			GoogleAuthService.auth_succeeded.connect(_on_google_auth_succeeded)
		if not GoogleAuthService.auth_failed.is_connected(_on_google_auth_failed):
			GoogleAuthService.auth_failed.connect(_on_google_auth_failed)
	if ProfileManager and not ProfileManager.profile_updated.is_connected(_on_profile_updated):
		ProfileManager.profile_updated.connect(_on_profile_updated)
	_update_texts()

func _exit_tree() -> void:
	if _entry_tween and _entry_tween.is_valid():
		_entry_tween.kill()
	if LocaleManager and LocaleManager.language_changed.is_connected(_on_language_changed):
		LocaleManager.language_changed.disconnect(_on_language_changed)
	if GoogleAuthService:
		if GoogleAuthService.auth_succeeded.is_connected(_on_google_auth_succeeded):
			GoogleAuthService.auth_succeeded.disconnect(_on_google_auth_succeeded)
		if GoogleAuthService.auth_failed.is_connected(_on_google_auth_failed):
			GoogleAuthService.auth_failed.disconnect(_on_google_auth_failed)
	if ProfileManager and ProfileManager.profile_updated.is_connected(_on_profile_updated):
		ProfileManager.profile_updated.disconnect(_on_profile_updated)

func _is_google_signed_in() -> bool:
	return ProfileManager != null \
		and ProfileManager.auth_provider == "google" \
		and not ProfileManager.email.strip_edges().is_empty()

func _update_auth_gate() -> bool:
	var signed_in := _is_google_signed_in()
	if signed_in:
		if guest_prompt: guest_prompt.visible = false
		if tab_row: tab_row.visible = true
		if list_scroll: list_scroll.visible = true
		if my_stats_bar: my_stats_bar.visible = true
	else:
		if is_fetching and http_request:
			http_request.cancel_request()
		is_fetching = false
		_reset_scroll_state()
		if list_box:
			for ch in list_box.get_children():
				list_box.remove_child(ch)
				ch.queue_free()
		if tab_row: tab_row.visible = false
		if list_scroll: list_scroll.visible = false
		if my_stats_bar: my_stats_bar.visible = false
		if guest_prompt: guest_prompt.visible = true
	return signed_in

func _reset_scroll_state() -> void:
	_scroll_touch_index = -1
	_is_touch_dragging = false
	_is_mouse_dragging = false
	_scroll_velocity_y = 0.0
	_scroll_pos_f = float(list_scroll.scroll_vertical) if list_scroll else 0.0

func _get_max_list_scroll() -> float:
	if not list_scroll:
		return 0.0
	var max_from_box := 0.0
	if list_box:
		var content_h: float = maxf(list_box.size.y, list_box.get_combined_minimum_size().y)
		max_from_box = maxf(0.0, content_h - list_scroll.size.y)
	var max_from_bar := 0.0
	var vbar := list_scroll.get_v_scroll_bar()
	if vbar:
		max_from_bar = maxf(0.0, vbar.max_value - vbar.page)
	return maxf(max_from_box, max_from_bar)

func _apply_list_scroll_delta(delta_scroll_y: float) -> void:
	if not list_scroll:
		return
	var max_scroll := _get_max_list_scroll()
	_scroll_pos_f = clampf(_scroll_pos_f + delta_scroll_y, 0.0, max_scroll)
	list_scroll.scroll_vertical = int(round(_scroll_pos_f))

	var now_ms := Time.get_ticks_msec()
	var dt := maxf(float(now_ms - _scroll_last_msec) / 1000.0, 0.016)
	_scroll_last_msec = now_ms
	var instant_vel := clampf(delta_scroll_y / dt, -2400.0, 2400.0)
	_scroll_velocity_y = lerpf(_scroll_velocity_y, instant_vel, 0.45)

func _on_list_scroll_gui_input(event: InputEvent) -> void:
	if not list_scroll or not list_scroll.visible:
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			if _scroll_touch_index == -1:
				_scroll_touch_index = st.index
				_is_touch_dragging = true
				_is_mouse_dragging = false
				_scroll_last_y = st.position.y
				_scroll_last_msec = Time.get_ticks_msec()
				_scroll_pos_f = float(list_scroll.scroll_vertical)
				_scroll_velocity_y = 0.0
				list_scroll.accept_event()
		elif st.index == _scroll_touch_index:
			_scroll_touch_index = -1
			_is_touch_dragging = false
			list_scroll.accept_event()
		return

	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _scroll_touch_index == -1:
			_scroll_touch_index = sd.index
			_is_touch_dragging = true
			_scroll_last_y = sd.position.y - sd.relative.y
			_scroll_last_msec = Time.get_ticks_msec()
			_scroll_pos_f = float(list_scroll.scroll_vertical)
		if sd.index == _scroll_touch_index:
			var dy: float = sd.relative.y if absf(sd.relative.y) > 0.001 else (sd.position.y - _scroll_last_y)
			_scroll_last_y = sd.position.y
			_apply_list_scroll_delta(-dy)
			list_scroll.accept_event()
		return

	# Ignore touch-emulated mouse events to prevent double-scrolling on Android
	if _is_touch_dragging or _scroll_touch_index != -1 or event.device == InputEvent.DEVICE_ID_EMULATION:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_mouse_dragging = true
				_scroll_last_y = mb.position.y
				_scroll_last_msec = Time.get_ticks_msec()
				_scroll_pos_f = float(list_scroll.scroll_vertical)
				_scroll_velocity_y = 0.0
				list_scroll.accept_event()
			else:
				_is_mouse_dragging = false
				list_scroll.accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_velocity_y = 0.0
			_scroll_pos_f = float(list_scroll.scroll_vertical)
	elif event is InputEventMouseMotion and _is_mouse_dragging:
		var mm := event as InputEventMouseMotion
		var dy: float = mm.relative.y if absf(mm.relative.y) > 0.001 else (mm.position.y - _scroll_last_y)
		_scroll_last_y = mm.position.y
		_apply_list_scroll_delta(-dy)
		list_scroll.accept_event()

func _process(delta: float) -> void:
	if not visible or not list_scroll or not list_scroll.visible:
		return
	if _is_touch_dragging or _is_mouse_dragging:
		return
	if absf(_scroll_velocity_y) > 8.0:
		var max_scroll := _get_max_list_scroll()
		var next_pos := clampf(_scroll_pos_f + _scroll_velocity_y * delta, 0.0, max_scroll)
		_scroll_pos_f = next_pos
		list_scroll.scroll_vertical = int(round(_scroll_pos_f))
		if next_pos <= 0.0 or next_pos >= max_scroll:
			_scroll_velocity_y = 0.0
		else:
			var decel := absf(_scroll_velocity_y) * minf(1.0, delta * 7.5) + 60.0 * delta
			_scroll_velocity_y = move_toward(_scroll_velocity_y, 0.0, decel)
	else:
		_scroll_velocity_y = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()

func open() -> void:
	visible = true
	_reset_scroll_state()
	if list_scroll:
		list_scroll.scroll_vertical = 0
		_scroll_pos_f = 0.0
	if google_sign_in_btn:
		google_sign_in_btn.disabled = false
	if guest_status_label:
		guest_status_label.text = ""
		guest_status_label.visible = false
	_update_texts()
	_update_tab_buttons()
	if _update_auth_gate():
		_fetch_supabase_leaderboard()
		_refresh_list()
	
	# Smooth entry tween
	if card:
		if _entry_tween and _entry_tween.is_valid():
			_entry_tween.kill()
		card.scale = Vector2(0.92, 0.92)
		card.pivot_offset = card.size / 2.0
		_entry_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_entry_tween.tween_property(card, "scale", Vector2.ONE, 0.20)

func close() -> void:
	SoundManager.play("click")
	_reset_scroll_state()
	visible = false
	closed.emit()

func _on_google_sign_in_pressed() -> void:
	SoundManager.play("click")
	if google_sign_in_btn:
		google_sign_in_btn.disabled = true
	if guest_status_label:
		guest_status_label.text = LocaleManager.t("leaderboard_google_connecting")
		guest_status_label.add_theme_color_override("font_color", Color("#38bdf8"))
		guest_status_label.visible = true
	if GoogleAuthService:
		GoogleAuthService.start_google_sign_in()

func _on_google_auth_succeeded(_user_data: Dictionary) -> void:
	if google_sign_in_btn:
		google_sign_in_btn.disabled = false
	if guest_status_label:
		guest_status_label.text = ""
		guest_status_label.visible = false
	_update_texts()
	if visible and _update_auth_gate():
		_fetch_supabase_leaderboard()
		_refresh_list()

func _on_google_auth_failed(error_message: String) -> void:
	if google_sign_in_btn:
		google_sign_in_btn.disabled = false
	if visible and guest_status_label:
		guest_status_label.text = error_message
		guest_status_label.add_theme_color_override("font_color", Color("#f87171"))
		guest_status_label.visible = not error_message.strip_edges().is_empty()

func _on_profile_updated(_profile_data: Dictionary) -> void:
	_update_texts()
	if visible:
		if _update_auth_gate():
			if remote_players.is_empty() and not is_fetching:
				_fetch_supabase_leaderboard()
			_refresh_list()

func _on_language_changed(_lang: String) -> void:
	_update_texts()
	if visible and _is_google_signed_in():
		_refresh_list()

func _update_texts() -> void:
	if title_label:
		title_label.text = LocaleManager.t("leaderboard_title")
	if btn_global:
		btn_global.text = LocaleManager.t("tab_global")
	if btn_friends:
		btn_friends.text = LocaleManager.t("tab_friends")
	if guest_title:
		guest_title.text = LocaleManager.t("leaderboard_guest_title")
	if guest_desc:
		guest_desc.text = LocaleManager.t("leaderboard_guest_desc")
	if google_sign_in_btn:
		google_sign_in_btn.text = " " + LocaleManager.t("leaderboard_google_login_btn")
		
	var display_name := ProfileManager.username
	var you_str := LocaleManager.t("player_you")
	if display_name.is_empty() or display_name.to_lower() == "player" or display_name.to_lower() == you_str.to_lower() or display_name.to_lower() == "siz":
		display_name = you_str
	else:
		display_name = "%s (%s)" % [display_name, you_str]
		
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
	_reset_scroll_state()
	if list_scroll:
		list_scroll.scroll_vertical = 0
		_scroll_pos_f = 0.0
	_update_tab_buttons()
	if _is_google_signed_in():
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
	if not _is_google_signed_in():
		return
	if is_fetching or not http_request:
		return
	is_fetching = true
	var url := Env.get_supabase_url() + "/rest/v1/profiles?select=id,player_tag,username,avatar_url,total_stars,highest_level,save_data&order=total_stars.desc,highest_level.desc&limit=50"
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
					var p_tag: String = str(row.get("player_tag", ""))
					# O'z profilimizni lokal holatda pastda qo'shamiz
					if (not ProfileManager.player_id.is_empty() and p_id == ProfileManager.player_id) \
							or (not ProfileManager.player_tag.is_empty() and p_tag == ProfileManager.player_tag):
						continue
					var av_str: String = str(row.get("avatar_url", "av_1"))
					var a_idx: int = (av_str.trim_prefix("av_").to_int() - 1) if av_str.begins_with("av_") else 0
					if a_idx < 0 or a_idx >= av_keys.size():
						a_idx = 0
					var u_name: String = str(row.get("username", "O'yinchi"))
					var sd = row.get("save_data", {})
					var stars_val: int = int(row.get("total_stars", 0))
					var total_time_sec: int = 0
					var total_deaths: int = 0
					if sd is Dictionary:
						if stars_val == 0 and sd.has("total_stars"):
							stars_val = int(sd.get("total_stars", 0))
						var l_stars = sd.get("level_stars", {})
						var l_times = sd.get("level_best_times", {})
						var l_deaths = sd.get("level_best_deaths", {})
						if l_times is Dictionary:
							for k in l_times.keys():
								var t_ms: float = float(l_times[k])
								if t_ms > 0.0 and t_ms < 999999000.0:
									total_time_sec += maxi(1, int(round(t_ms / 1000.0)))
						if l_deaths is Dictionary and l_stars is Dictionary:
							for k in l_deaths.keys():
								if int(l_stars.get(str(k), 0)) > 0:
									total_deaths += int(l_deaths[k])
					remote_players.append({
						"id": p_id,
						"player_tag": p_tag,
						"name": u_name,
						"avatar": av_keys[a_idx],
						"stars": stars_val,
						"time_sec": total_time_sec,
						"deaths": total_deaths,
						"is_me": false
					})
			if _is_google_signed_in():
				_refresh_list()

func _refresh_list() -> void:
	if not list_box:
		return
	for ch in list_box.get_children():
		list_box.remove_child(ch)
		ch.queue_free()

	if not _is_google_signed_in():
		_update_auth_gate()
		return
		
	# Live Player Stats
	var my_stars: int = SaveManager.get_total_stars()
	var my_time: int = SaveManager.get_total_beaten_time_sec()
	var my_deaths: int = SaveManager.get_total_beaten_deaths()
	
	var my_display_name := ProfileManager.username.strip_edges()
	var my_you_str := LocaleManager.t("player_you")
	if my_display_name.is_empty() or my_display_name.to_lower() == "player" or my_display_name.to_lower() == my_you_str.to_lower() or my_display_name.to_lower() == "siz":
		my_display_name = my_you_str
	else:
		my_display_name = "%s (%s)" % [my_display_name, my_you_str]
		
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
	var friends_count: int = 0
	if current_tab == TabMode.GLOBAL:
		raw_list = remote_players.duplicate(true)
	else:
		# Do'stlar ro'yxati
		for p in remote_players:
			var p_tag := str(p.get("player_tag", ""))
			var p_id := str(p.get("id", ""))
			if ProfileManager.is_friend(p_tag) or ProfileManager.is_friend(p_id):
				raw_list.append(p)
				friends_count += 1
		
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

	if current_tab == TabMode.FRIENDS and friends_count == 0:
		list_box.add_child(_build_empty_friends_card())
		
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

func _set_ignore_mouse_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_ignore_mouse_recursive(child)

func _build_empty_friends_card() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 68)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.16, 0.65)
	style.border_color = Color(0.22, 0.28, 0.40, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)

	var lbl := Label.new()
	lbl.text = LocaleManager.t("leaderboard_friends_empty")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color("#94a3b8"))
	panel.add_child(lbl)

	_set_ignore_mouse_recursive(panel)
	return panel

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
		name_lbl.text = player_name
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
	
	_set_ignore_mouse_recursive(row)
	return row

