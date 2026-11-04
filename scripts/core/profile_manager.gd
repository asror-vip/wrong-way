extends Node

# ProfileManager - Wrong Way Player Identity & Auth System
# - Manages Device UUID, Supabase Player Tag (e.g. WW-4467), Username & Avatar
# - Local caching in user://player_profile.json
# - Seamless background sync with Supabase profiles table via Env configuration

signal profile_loaded(profile_data: Dictionary)
signal profile_updated(profile_data: Dictionary)
signal google_login_finished(success: bool, error_msg: String)

const PROFILE_CACHE_PATH := "user://player_profile.json"
const FRIENDS_CACHE_PATH := "user://saved_friends.json"
const GOOGLE_ACCOUNTS_PATH := "user://google_accounts.json"
const DEVICE_ID_PATH := "user://device_id.txt"

var device_id: String = ""
var player_id: String = ""
var player_tag: String = "WW-0000"
var username: String = "Player"
var avatar_index: int = 1
var auth_provider: String = "guest"
var email: String = ""
var has_chosen_auth: bool = false
var is_ready_online: bool = false
var saved_friends: Array = []

var http_guest: HTTPRequest
var http_google: HTTPRequest
var http_update: HTTPRequest
var http_cloud: HTTPRequest

var id_overlay: CanvasLayer
var id_corner_lbl: Label

func _ready() -> void:
	http_guest = HTTPRequest.new()
	http_guest.name = "ProfileGuestHTTP"
	http_guest.timeout = 6.0
	add_child(http_guest)
	http_guest.request_completed.connect(_on_guest_completed)
	
	http_google = HTTPRequest.new()
	http_google.name = "ProfileGoogleHTTP"
	http_google.timeout = 6.0
	add_child(http_google)
	http_google.request_completed.connect(_on_google_completed)
	
	http_update = HTTPRequest.new()
	http_update.name = "ProfileUpdateHTTP"
	http_update.timeout = 6.0
	add_child(http_update)
	http_update.request_completed.connect(_on_update_completed)

	http_cloud = HTTPRequest.new()
	http_cloud.name = "ProfileCloudHTTP"
	http_cloud.timeout = 6.0
	add_child(http_cloud)
	http_cloud.request_completed.connect(_on_cloud_completed)

	_load_or_create_device_id()
	_load_local_profile()
	_load_saved_friends()
	_setup_corner_id_overlay()
	
	# Agar avval Google bilan kirgan bo'lsa, to'g'ridan-to'g'ri Google profili sinxronlanadi
	if auth_provider == "google" and not email.is_empty():
		login_with_google(email, username)
	else:
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

func get_name_from_email(e: String) -> String:
	var prefix := e.split("@")[0].strip_edges()
	var letters := ""
	for i in range(prefix.length()):
		var ch := prefix[i]
		if not ch.is_valid_int():
			letters += ch
	if letters.length() >= 3:
		return letters.capitalize()
	return prefix.capitalize()

func _apply_profile_dict(data: Dictionary) -> void:
	if data.has("id"): player_id = str(data["id"])
	if data.has("player_tag"): player_tag = str(data["player_tag"])
	
	if data.has("email") and data["email"] != null and typeof(data["email"]) == TYPE_STRING:
		var raw_e: String = str(data["email"]).strip_edges()
		if raw_e != "<null>" and raw_e != "null" and not raw_e.is_empty():
			email = raw_e
		else:
			email = ""
	else:
		email = ""
		
	if data.has("username"):
		var raw_u: String = str(data["username"]).strip_edges()
		if (raw_u.is_empty() or raw_u.to_lower() == "player") and not email.is_empty():
			username = get_name_from_email(email)
		elif not raw_u.is_empty():
			username = raw_u
		else:
			username = "Player"
			
	if data.has("avatar_url"):
		var av: String = str(data["avatar_url"])
		if av.begins_with("av_"):
			avatar_index = av.trim_prefix("av_").to_int()
		else:
			avatar_index = 1
	else:
		avatar_index = 1
		
	if avatar_index < 1 or avatar_index > 5:
		avatar_index = 1
		
	if data.has("auth_provider"): auth_provider = str(data["auth_provider"])
	
	if data.has("has_chosen_auth"):
		has_chosen_auth = bool(data["has_chosen_auth"])
	elif auth_provider == "google" and not email.is_empty():
		has_chosen_auth = true
	elif not player_id.is_empty() and username != "Player":
		has_chosen_auth = true

	# Bulutdan kelgan yutuqlarni lokal saqlash tizimi bilan birlashtirish
	if data.has("save_data") and data["save_data"] is Dictionary:
		var save_sys = get_node_or_null("/root/SaveManager")
		if save_sys and save_sys.has_method("merge_cloud_save"):
			save_sys.merge_cloud_save(data["save_data"])
	
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
		"device_id": device_id,
		"has_chosen_auth": has_chosen_auth
	}

# -------------------------------------------------------------
# Supabase Guest Sync
# -------------------------------------------------------------
func sync_with_supabase() -> void:
	if not http_guest:
		return
	if http_guest.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_guest.cancel_request()
		
	var url: String = Env.get_supabase_url() + "/rest/v1/rpc/register_or_login_guest"
	var anon_key: String = Env.get_supabase_anon_key()
	var headers := [
		"apikey: " + anon_key,
		"Authorization: Bearer " + anon_key,
		"Content-Type: application/json"
	]
	var payload := JSON.stringify({
		"p_device_id": device_id,
		"p_username": username,
		"p_avatar_url": "av_" + str(avatar_index)
	})
	http_guest.request(url, headers, HTTPClient.METHOD_POST, payload)

func _on_guest_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var txt := body.get_string_from_utf8()
		var parsed = JSON.parse_string(txt)
		if parsed is Dictionary and parsed.has("id"):
			_apply_profile_dict(parsed)
			_save_local_cache(get_profile_dict())
			is_ready_online = true
			print("ProfileManager: Mehmon sifatida ulandi: ", username, " (", player_tag, ")")
			profile_updated.emit(get_profile_dict())
			sync_save_to_cloud()
	else:
		print("ProfileManager: Mehmon oflayn rejimda (HTTP %d)" % response_code)

# -------------------------------------------------------------
# Supabase Google Login / Link
# -------------------------------------------------------------
func login_with_google(google_email: String, display_name: String = "") -> void:
	if not http_google:
		return
	var clean_email := google_email.strip_edges().to_lower()
	if clean_email.is_empty() or clean_email == "<null>" or clean_email == "null" or not clean_email.contains("@"):
		print("ProfileManager: Noto'g'ri email bilan Google kirish bekor qilindi: ", clean_email)
		return
		
	var clean_name := display_name.strip_edges()
	if clean_name.is_empty() or clean_name.to_lower() == "player":
		clean_name = get_name_from_email(clean_email)
		
	username = clean_name
	email = clean_email
	auth_provider = "google"
	has_chosen_auth = true
	_save_local_cache(get_profile_dict())
	profile_updated.emit(get_profile_dict())
	
	add_known_google_account(clean_email, clean_name)
	
	print("ProfileManager: Google orqali kirish so'rovi yuborilmoqda: ", clean_email, " (", clean_name, ")")
	
	var url: String = Env.get_supabase_url() + "/rest/v1/rpc/login_or_link_google"
	var anon_key: String = Env.get_supabase_anon_key()
	var headers := [
		"apikey: " + anon_key,
		"Authorization: Bearer " + anon_key,
		"Content-Type: application/json"
	]
	var payload := JSON.stringify({
		"p_device_id": device_id,
		"p_email": clean_email,
		"p_username": clean_name,
		"p_avatar_url": "av_" + str(avatar_index)
	})
	http_google.request(url, headers, HTTPClient.METHOD_POST, payload)

func _on_google_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var txt := body.get_string_from_utf8()
	print("ProfileManager: Google javob keldi (HTTP %d)" % response_code)
	if response_code == 200:
		var parsed = JSON.parse_string(txt)
		if parsed is Dictionary and parsed.has("id"):
			has_chosen_auth = true
			_apply_profile_dict(parsed)
			_save_local_cache(get_profile_dict())
			is_ready_online = true
			print("ProfileManager: Google hisobi muvaffaqiyatli ulandi! Name: ", username, " Email: ", email, " Tag: ", player_tag)
			
			# Bulutli saqlash sinxronlash
			if parsed.has("save_data") and parsed["save_data"] is Dictionary:
				var save_sys = get_node_or_null("/root/SaveManager")
				if save_sys and save_sys.has_method("merge_cloud_save"):
					save_sys.merge_cloud_save(parsed["save_data"])
			sync_save_to_cloud()
			
			profile_updated.emit(get_profile_dict())
			google_login_finished.emit(true, "")
			return
			
	print("ProfileManager: Google xatolik: ", txt)
	google_login_finished.emit(false, "Serverga ulanishda xatolik (HTTP %d)" % response_code)

func logout_to_guest() -> void:
	auth_provider = "guest"
	email = ""
	username = "Player"
	avatar_index = 1
	has_chosen_auth = false
	_save_local_cache(get_profile_dict())
	profile_updated.emit(get_profile_dict())
	sync_with_supabase()

func save_profile() -> void:
	_save_local_cache(get_profile_dict())
	profile_updated.emit(get_profile_dict())

# -------------------------------------------------------------
# Bulutli Yutuqlar Sinxronizatsiyasi (Cloud Save)
# -------------------------------------------------------------
func sync_save_to_cloud() -> void:
	if not is_ready_online or player_id.is_empty():
		return
	if not http_cloud:
		return
	if http_cloud.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
		
	var save_sys = get_node_or_null("/root/SaveManager")
	if not save_sys or not save_sys.has_method("get_save_payload"):
		return
		
	var payload_dict: Dictionary = save_sys.get_save_payload()
	var total_stars: int = save_sys.get_total_stars()
	var highest_lvl: int = save_sys.get_highest_unlocked_level()
	
	var url: String = Env.get_supabase_url() + "/rest/v1/rpc/sync_cloud_save"
	var anon_key: String = Env.get_supabase_anon_key()
	var headers := [
		"apikey: " + anon_key,
		"Authorization: Bearer " + anon_key,
		"Content-Type: application/json"
	]
	var body := JSON.stringify({
		"p_player_id": player_id,
		"p_save_data": payload_dict,
		"p_total_stars": total_stars,
		"p_highest_level": highest_lvl
	})
	http_cloud.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_cloud_completed(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if response_code in [200, 204]:
		print("ProfileManager: Yutuqlar bulutga muvaffaqiyatli saqlandi!")

func get_known_google_accounts() -> Array:
	var accounts: Array = []
	if FileAccess.file_exists(GOOGLE_ACCOUNTS_PATH):
		var f := FileAccess.open(GOOGLE_ACCOUNTS_PATH, FileAccess.READ)
		if f:
			var txt := f.get_as_text()
			f.close()
			var parsed = JSON.parse_string(txt)
			if parsed is Array:
				accounts = parsed

	# Haqiqiy Google hisobini tizimdan aniqlash
	var real_email := ""
	var real_name := ""
	
	var git_out := []
	if OS.execute("git", ["config", "user.email"], git_out) == 0 and not git_out.is_empty():
		var e := str(git_out[0]).strip_edges().to_lower()
		if e.contains("@"):
			real_email = e
			
	var name_out := []
	if OS.execute("git", ["config", "user.name"], name_out) == 0 and not name_out.is_empty():
		var n := str(name_out[0]).strip_edges()
		if not n.is_empty():
			real_name = n.capitalize()
			
	if real_email.is_empty():
		real_email = "asror8471@gmail.com"
	if real_name.is_empty():
		real_name = "Asror"
		
	var has_real := false
	for acc in accounts:
		if acc is Dictionary and acc.get("email", "").to_lower() == real_email:
			has_real = true
			break
			
	if not has_real:
		accounts.insert(0, {
			"email": real_email,
			"name": real_name,
			"avatar": "av_1"
		})
		
	if not email.is_empty() and email != real_email and email.contains("@"):
		var found_saved := false
		for acc in accounts:
			if acc is Dictionary and acc.get("email", "").to_lower() == email.to_lower():
				found_saved = true
				break
		if not found_saved:
			accounts.append({
				"email": email,
				"name": username if not username.is_empty() else "Google Player",
				"avatar": "av_" + str(avatar_index)
			})
			
	return accounts

func add_known_google_account(acc_email: String, acc_name: String = "") -> void:
	if acc_email.is_empty():
		return
	var clean_email := acc_email.strip_edges().to_lower()
	var accounts := get_known_google_accounts()
	
	for i in range(accounts.size() - 1, -1, -1):
		var item = accounts[i]
		if item is Dictionary and item.get("email", "").to_lower() == clean_email:
			accounts.remove_at(i)
			
	var display := acc_name if not acc_name.is_empty() else clean_email.split("@")[0].capitalize()
	accounts.insert(0, {
		"email": clean_email,
		"name": display,
		"avatar": "av_" + str(avatar_index)
	})
	
	if accounts.size() > 5:
		accounts.resize(5)
		
	var f := FileAccess.open(GOOGLE_ACCOUNTS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(accounts))
		f.close()

# -------------------------------------------------------------
# Profil tahrirlash (Ism va Avatar)
# -------------------------------------------------------------
func update_profile(new_name: String, new_avatar_idx: int) -> void:
	username = new_name.strip_edges()
	avatar_index = new_avatar_idx
	var av_url := "av_" + str(avatar_index)
	
	var cur := get_profile_dict()
	_save_local_cache(cur)
	profile_updated.emit(cur)
	
	if is_ready_online and not player_id.is_empty():
		var url: String = Env.get_supabase_url() + "/rest/v1/profiles?id=eq." + player_id
		var anon_key: String = Env.get_supabase_anon_key()
		var headers := [
			"apikey: " + anon_key,
			"Authorization: Bearer " + anon_key,
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
