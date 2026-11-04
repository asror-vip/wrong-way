extends Node

# ProfileManager - Wrong Way Player Identity & Auth System
# - Manages Device UUID, Supabase Player Tag (e.g. WW-4467), Username & Avatar
# - Local caching in user://player_profile.json
# - Seamless background sync with Supabase profiles table

signal profile_loaded(profile_data: Dictionary)
signal profile_updated(profile_data: Dictionary)
signal google_login_finished(success: bool, error_msg: String)

const PROFILE_CACHE_PATH := "user://player_profile.json"
const FRIENDS_CACHE_PATH := "user://saved_friends.json"
const DEVICE_ID_PATH := "user://device_id.txt"

const SUPABASE_URL := "https://wcwjobrrwwjfthpflzhg.supabase.co"
const SUPABASE_ANON_KEY := "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indjd2pvYnJyd3dqZnRocGZsemhnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM0NzIzNTEsImV4cCI6MjEwOTA0ODM1MX0.16SXhNkvVehgIuNhcGH3l9bDS37mkmbGt12h8F2CyoY"

var device_id: String = ""
var player_id: String = ""
var player_tag: String = "WW-0000"
var username: String = "Player"
var avatar_index: int = 1
var auth_provider: String = "guest"
var email: String = ""
var is_ready_online: bool = false
var saved_friends: Array = []

var http_auth: HTTPRequest
var http_update: HTTPRequest

var id_overlay: CanvasLayer
var id_corner_lbl: Label

func _ready() -> void:
	http_auth = HTTPRequest.new()
	http_auth.name = "ProfileAuthHTTP"
	add_child(http_auth)
	http_auth.request_completed.connect(_on_auth_completed)
	
	http_update = HTTPRequest.new()
	http_update.name = "ProfileUpdateHTTP"
	add_child(http_update)
	http_update.request_completed.connect(_on_update_completed)

	_load_or_create_device_id()
	_load_local_profile()
	_load_saved_friends()
	_setup_corner_id_overlay()
	sync_with_supabase()

func _load_or_create_device_id() -> void:
	if FileAccess.file_exists(DEVICE_ID_PATH):
		var f := FileAccess.open(DEVICE_ID_PATH, FileAccess.READ)
		if f:
			device_id = f.get_as_text().strip_edges()
			f.close()
			
	if device_id.is_empty():
		var unique := OS.get_unique_id()
		if unique.is_empty():
			unique = "dev_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 100000)
		device_id = unique
		var f := FileAccess.open(DEVICE_ID_PATH, FileAccess.WRITE)
		if f:
			f.store_string(device_id)
			f.close()

func _load_local_profile() -> void:
	if FileAccess.file_exists(PROFILE_CACHE_PATH):
		var f := FileAccess.open(PROFILE_CACHE_PATH, FileAccess.READ)
		if f:
			var txt := f.get_as_text()
			f.close()
			var parsed = JSON.parse_string(txt)
			if parsed is Dictionary:
				_apply_profile_dict(parsed)

func _apply_profile_dict(data: Dictionary) -> void:
	if data.has("id"): player_id = str(data["id"])
	if data.has("player_tag"): player_tag = str(data["player_tag"])
	if data.has("username"): username = str(data["username"])
	if data.has("email"): email = str(data["email"])
	if data.has("avatar_url"):
		var av: String = str(data["avatar_url"])
		if av.begins_with("av_"):
			avatar_index = av.trim_prefix("av_").to_int()
		else:
			avatar_index = 1
	if data.has("auth_provider"): auth_provider = str(data["auth_provider"])
	
	_update_corner_id_text()
	profile_loaded.emit(get_profile_dict())

func get_profile_dict() -> Dictionary:
	return {
		"id": player_id,
		"player_tag": player_tag,
		"username": username,
		"email": email,
		"avatar_index": avatar_index,
		"avatar_url": "av_" + str(avatar_index),
		"auth_provider": auth_provider,
		"device_id": device_id
	}

func sync_with_supabase() -> void:
	if not http_auth:
		return
	var url := SUPABASE_URL + "/rest/v1/rpc/register_or_login_guest"
	var headers := [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY,
		"Content-Type: application/json"
	]
	var payload := JSON.stringify({
		"p_device_id": device_id,
		"p_username": username,
		"p_avatar_url": "av_" + str(avatar_index)
	})
	http_auth.request(url, headers, HTTPClient.METHOD_POST, payload)

func _on_auth_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var txt := body.get_string_from_utf8()
		var parsed = JSON.parse_string(txt)
		if parsed is Dictionary and parsed.has("id"):
			_apply_profile_dict(parsed)
			_save_local_cache(parsed)
			is_ready_online = true
			print("ProfileManager: Foydalanuvchi tizimga ulandi: ", username, " (", player_tag, ", ", auth_provider, ")")
			profile_updated.emit(get_profile_dict())
			google_login_finished.emit(true, "")
	else:
		print("ProfileManager: Oflayn rejimda davom etilmoqda (HTTP %d)" % response_code)
		google_login_finished.emit(false, "Serverga ulanib bo'lmadi")

func login_with_google(google_email: String, display_name: String = "") -> void:
	if not http_auth:
		return
	var url := SUPABASE_URL + "/rest/v1/rpc/login_or_link_google"
	var headers := [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY,
		"Content-Type: application/json"
	]
	var payload := JSON.stringify({
		"p_device_id": device_id,
		"p_email": google_email.strip_edges().to_lower(),
		"p_username": display_name.strip_edges() if not display_name.is_empty() else username,
		"p_avatar_url": "av_" + str(avatar_index)
	})
	http_auth.request(url, headers, HTTPClient.METHOD_POST, payload)

func logout_to_guest() -> void:
	auth_provider = "guest"
	email = ""
	_save_local_cache(get_profile_dict())
	profile_updated.emit(get_profile_dict())
	sync_with_supabase()

func update_profile(new_name: String, new_avatar_idx: int) -> void:
	username = new_name.strip_edges()
	avatar_index = new_avatar_idx
	var av_url := "av_" + str(avatar_index)
	
	var cur := get_profile_dict()
	_save_local_cache(cur)
	profile_updated.emit(cur)
	
	if is_ready_online and not player_id.is_empty():
		var url := SUPABASE_URL + "/rest/v1/profiles?id=eq." + player_id
		var headers := [
			"apikey: " + SUPABASE_ANON_KEY,
			"Authorization: Bearer " + SUPABASE_ANON_KEY,
			"Content-Type: application/json",
			"Prefer: return=minimal"
		]
		var payload := JSON.stringify({
			"username": username,
			"avatar_url": av_url,
			"updated_at": Time.get_datetime_string_from_system(true) + "Z"
		})
		http_update.request(url, headers, HTTPClient.METHOD_PATCH, payload)

func _on_update_completed(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if response_code in [200, 204]:
		print("ProfileManager: Profil Supabase'da yangilandi!")

func _save_local_cache(data: Dictionary) -> void:
	var f := FileAccess.open(PROFILE_CACHE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

# -------------------------------------------------------------
# Do'stlar va So'nggi Raqiblar (Quick Friends System)
# -------------------------------------------------------------
func _load_saved_friends() -> void:
	if FileAccess.file_exists(FRIENDS_CACHE_PATH):
		var f := FileAccess.open(FRIENDS_CACHE_PATH, FileAccess.READ)
		if f:
			var txt := f.get_as_text()
			f.close()
			var parsed = JSON.parse_string(txt)
			if parsed is Array:
				saved_friends = parsed

func save_friends_cache() -> void:
	var f := FileAccess.open(FRIENDS_CACHE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(saved_friends))
		f.close()

func add_recent_friend(tag: String, friend_name: String = "", av_url: String = "") -> void:
	var clean_tag := tag.strip_edges().to_upper()
	if clean_tag.is_empty() or clean_tag == player_tag:
		return
	for i in range(saved_friends.size() - 1, -1, -1):
		var item = saved_friends[i]
		if item is Dictionary and item.get("player_tag", "") == clean_tag:
			saved_friends.remove_at(i)
	saved_friends.insert(0, {
		"player_tag": clean_tag,
		"username": friend_name if not friend_name.is_empty() else clean_tag,
		"avatar_url": av_url
	})
	if saved_friends.size() > 12:
		saved_friends.resize(12)
	save_friends_cache()

func get_saved_friends() -> Array:
	return saved_friends

# -------------------------------------------------------------
# Doimiy Pastki O'ng Burchakdagi Player ID (Hamma sahifada)
# -------------------------------------------------------------
func _setup_corner_id_overlay() -> void:
	id_overlay = CanvasLayer.new()
	id_overlay.name = "PersistentIDOverlay"
	id_overlay.layer = 125
	add_child(id_overlay)
	
	id_corner_lbl = Label.new()
	id_corner_lbl.name = "CornerPlayerIDLabel"
	id_corner_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	id_corner_lbl.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	id_corner_lbl.anchor_left = 1.0
	id_corner_lbl.anchor_top = 1.0
	id_corner_lbl.anchor_right = 1.0
	id_corner_lbl.anchor_bottom = 1.0
	id_corner_lbl.offset_left = -110.0
	id_corner_lbl.offset_top = -26.0
	id_corner_lbl.offset_right = -12.0
	id_corner_lbl.offset_bottom = -8.0
	id_corner_lbl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	id_corner_lbl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	id_corner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	id_corner_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	id_corner_lbl.add_theme_font_size_override("font_size", 10)
	id_corner_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85, 0.40))
	
	_update_corner_id_text()
	id_overlay.add_child(id_corner_lbl)

func _update_corner_id_text() -> void:
	if id_corner_lbl:
		id_corner_lbl.text = player_tag

