extends Node

# GoogleAuthService - Wrong Way Official Cross-Platform Google Authentication
# - Android: Uses native Jetpack Credential Manager bottom-sheet modal (GetSignInWithGoogleOption)
#   directly inside the game — NEVER opens Chrome or leaves the game.
# - Desktop (Windows/Mac/Linux): Uses official Supabase Google OAuth in default browser
#   with local loopback callback on 127.0.0.1:8943.

signal auth_succeeded(user_data: Dictionary)
signal auth_failed(error_message: String)

const GOOGLE_WEB_CLIENT_ID := "554448116259-f2l5gs2h2fucpbtbkq87d2j34a963h4i.apps.googleusercontent.com"
const LOOPBACK_PORT: int = 8943
const REDIRECT_URI: String = "http://127.0.0.1:8943/callback"
const REFRESH_TOKEN_PATH := "user://google_refresh_token.txt"

var tcp_server: TCPServer
var is_listening: bool = false
var _stop_requested: bool = false
var _server_thread: Thread = null
var auth_timeout_timer: SceneTreeTimer
var http_user: HTTPRequest
var _net_check_http: HTTPRequest
var _checking_network: bool = false
var _pending_google_user: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	http_user = HTTPRequest.new()
	http_user.name = "GoogleAuthUserHTTP"
	http_user.timeout = 8.0
	add_child(http_user)
	http_user.request_completed.connect(_on_user_info_completed)

	_net_check_http = HTTPRequest.new()
	_net_check_http.name = "GoogleAuthNetCheckHTTP"
	_net_check_http.timeout = 3.5
	add_child(_net_check_http)
	_net_check_http.request_completed.connect(_on_net_check_completed)

func _exit_tree() -> void:
	_stop_loopback_server()

func start_google_sign_in() -> void:
	if _checking_network:
		return
	if _net_check_http == null:
		_proceed_google_sign_in()
		return
	_checking_network = true
	var url := Env.get_supabase_url() + "/rest/v1/"
	var headers := ["apikey: " + Env.get_supabase_anon_key()]
	var err := _net_check_http.request(url, headers, HTTPClient.METHOD_HEAD)
	if err != OK:
		_checking_network = false
		auth_failed.emit("OFFLINE")

func _on_net_check_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_checking_network = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code <= 0:
		auth_failed.emit("OFFLINE")
		return
	_proceed_google_sign_in()

func _proceed_google_sign_in() -> void:
	if OS.get_name() == "Android":
		_start_android_native_google_modal()
	else:
		_start_desktop_browser_oauth()

# -------------------------------------------------------------
# 1. ANDROID NATIVE GOOGLE BOTTOM-SHEET MODAL (Zero Browser)
# -------------------------------------------------------------
func _start_android_native_google_modal() -> void:
	if not Engine.has_singleton("WrongWayAccountPicker"):
		auth_failed.emit("Google Sign-In plagini yuklanmagan.")
		return

	var picker = Engine.get_singleton("WrongWayAccountPicker")
	if picker == null:
		auth_failed.emit("Google Sign-In xizmati topilmadi.")
		return

	if not picker.is_connected("google_sign_in_success", _on_android_google_success):
		picker.connect("google_sign_in_success", _on_android_google_success)
	if not picker.is_connected("google_sign_in_failed", _on_android_google_failed):
		picker.connect("google_sign_in_failed", _on_android_google_failed)

	print("GoogleAuthService: Android native Google modal oynasi ochilmoqda...")
	picker.call("signInWithGoogle", GOOGLE_WEB_CLIENT_ID)

func _on_android_google_success(acc_email: String, acc_name: String, _id_token: String) -> void:
	var clean_email := acc_email.strip_edges().to_lower()
	if clean_email.is_empty() or not clean_email.contains("@"):
		auth_failed.emit("Google hisobidan haqiqiy email olinmadi")
		return
	var clean_name := acc_name.strip_edges()
	if clean_name.is_empty():
		clean_name = ProfileManager.get_name_from_email(clean_email)

	print("GoogleAuthService: Native Google modal muvaffaqiyatli: ", clean_email, " (", clean_name, ")")
	_pending_google_user = {"email": clean_email, "name": clean_name}

	if not ProfileManager.google_login_finished.is_connected(_on_profile_google_sync_done):
		ProfileManager.google_login_finished.connect(_on_profile_google_sync_done, CONNECT_ONE_SHOT)

	ProfileManager.login_with_google(clean_email, clean_name)

func _on_profile_google_sync_done(success: bool, err_msg: String) -> void:
	var user_data := _pending_google_user.duplicate()
	_pending_google_user.clear()
	if success:
		auth_succeeded.emit(user_data)
	else:
		# Even if Supabase RPC timed out offline, local Google identity was applied;
		# inform caller cleanly so user isn't stuck if online sync failed.
		if not user_data.is_empty() and ProfileManager.auth_provider == "google":
			auth_succeeded.emit(user_data)
		else:
			auth_failed.emit(err_msg if not err_msg.is_empty() else "Server bilan sinxronlashda xatolik")

func _on_android_google_failed(err_code: String, err_msg: String) -> void:
	print("GoogleAuthService: Android native Google xato [%s]: %s" % [err_code, err_msg])
	if err_code == "CANCELED":
		auth_failed.emit("Kirish bekor qilindi")
	elif err_code == "NO_CREDENTIAL":
		auth_failed.emit("Qurilmada Google hisobi topilmadi")
	else:
		auth_failed.emit(err_msg)

# -------------------------------------------------------------
# 2. DESKTOP BROWSER OAUTH (Windows / Mac / Linux only)
# -------------------------------------------------------------
func _start_desktop_browser_oauth() -> void:
	_stop_loopback_server()

	tcp_server = TCPServer.new()
	var err := tcp_server.listen(LOOPBACK_PORT, "127.0.0.1")
	if err != OK:
		auth_failed.emit("Lokal serverni ochib bo'lmadi (Port %d band)" % LOOPBACK_PORT)
		return

	is_listening = true
	_stop_requested = false

	_server_thread = Thread.new()
	var t_err := _server_thread.start(_loopback_thread_worker)
	if t_err != OK:
		_server_thread = null

	var supabase_url: String = Env.get_supabase_url()
	var auth_url := "%s/auth/v1/authorize?provider=google&redirect_to=%s" % [supabase_url, REDIRECT_URI.uri_encode()]

	var open_err := OS.shell_open(auth_url)
	if open_err != OK:
		_stop_loopback_server()
		auth_failed.emit("Brauzerni ochib bo'lmadi (kod: %d)" % open_err)
		return

	auth_timeout_timer = get_tree().create_timer(120.0, true)
	auth_timeout_timer.timeout.connect(func():
		if is_listening:
			_stop_loopback_server()
			auth_failed.emit("Google orqali kirish vaqti tugadi (Timeout)")
	)

func _loopback_thread_worker() -> void:
	while not _stop_requested and tcp_server != null:
		if tcp_server.is_connection_available():
			var peer: StreamPeerTCP = tcp_server.take_connection()
			if peer != null:
				if _handle_http_client_sync(peer):
					break
		OS.delay_msec(15)

func _process(_delta: float) -> void:
	if _server_thread != null or not is_listening or tcp_server == null:
		return
	if tcp_server.is_connection_available():
		var peer: StreamPeerTCP = tcp_server.take_connection()
		if peer != null:
			_handle_http_client_sync(peer)

func _handle_http_client_sync(peer: StreamPeerTCP) -> bool:
	var start_ms := Time.get_ticks_msec()
	while peer.get_status() == StreamPeerTCP.STATUS_CONNECTED and peer.get_available_bytes() == 0:
		if Time.get_ticks_msec() - start_ms > 2500 or _stop_requested:
			break
		OS.delay_msec(10)

	var available := peer.get_available_bytes()
	if available <= 0:
		peer.disconnect_from_host()
		return false

	var raw_req := peer.get_utf8_string(available)
	var lines := raw_req.split("\r\n")
	if lines.is_empty():
		peer.disconnect_from_host()
		return false

	var request_line := lines[0]
	var has_query := request_line.contains("?")

	var html_body := """<!DOCTYPE html>
<html lang="uz"><head><meta charset="UTF-8"><title>Wrong Way — Google Sign-In</title>
<style>body{background:#080c14;color:#f1f5f9;font-family:sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}.card{background:#0f172a;border:1px solid #1e293b;border-radius:20px;padding:36px;max-width:420px;text-align:center}h1{color:#38bdf8;margin:0 0 10px}p{color:#94a3b8;font-size:14px}</style>
</head><body><div class="card"><h1>Muvaffaqiyatli kirdingiz!</h1><p>Endi o'yinga qaytishingiz mumkin.</p></div>
<script>if(window.location.hash&&window.location.hash.length>1){window.location.replace('/callback?'+window.location.hash.substring(1));}else{setTimeout(function(){window.close();},2500);}</script>
</body></html>"""

	var html_bytes := html_body.to_utf8_buffer()
	var response := "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % html_bytes.size()
	peer.put_data(response.to_utf8_buffer())
	peer.put_data(html_bytes)
	OS.delay_msec(120)
	peer.disconnect_from_host()

	if has_query:
		call_deferred("_parse_auth_request", request_line)
		return true
	return false

func _parse_auth_request(req_line: String) -> void:
	var parts := req_line.split(" ")
	if parts.size() < 2:
		return
	var path_and_query: String = parts[1]
	if not path_and_query.contains("?"):
		return
	_parse_auth_query(path_and_query.split("?")[1])

func _parse_auth_query(query_str: String) -> void:
	var query_params := {}
	for param in query_str.split("&"):
		var kv := param.split("=")
		if kv.size() == 2:
			query_params[kv[0]] = kv[1].uri_decode()

	if query_params.has("error"):
		var err_desc: String = query_params.get("error_description", query_params["error"])
		_stop_loopback_server()
		auth_failed.emit(err_desc)
		return

	if query_params.has("access_token"):
		var token: String = query_params["access_token"]
		if query_params.has("refresh_token"):
			_store_refresh_token(str(query_params["refresh_token"]))
		_stop_loopback_server()
		_fetch_supabase_user(token)
		return

	var user_email: String = query_params.get("user_email", "")
	var user_name: String = query_params.get("user_name", "")
	if user_email.is_empty():
		_stop_loopback_server()
		auth_failed.emit("Google hisob ma'lumotlari topilmadi.")
		return

	_stop_loopback_server()
	ProfileManager.login_with_google(user_email, user_name)
	auth_succeeded.emit({"email": user_email, "name": user_name})

func _fetch_supabase_user(access_token: String) -> void:
	if not http_user:
		return
	var url := Env.get_supabase_url() + "/auth/v1/user"
	var anon_key := Env.get_supabase_anon_key()
	var headers := [
		"apikey: " + anon_key,
		"Authorization: Bearer " + access_token
	]
	http_user.request(url, headers, HTTPClient.METHOD_GET)

func _on_user_info_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_stop_loopback_server()
	if result != HTTPRequest.RESULT_SUCCESS or response_code <= 0:
		_bring_game_window_to_front()
		auth_failed.emit("OFFLINE")
		return
	if response_code == 200:
		var parsed = JSON.parse_string(body.get_string_from_utf8())
		if parsed is Dictionary and parsed.has("email"):
			var u_email: String = str(parsed["email"]).strip_edges()
			var u_name := ""
			var meta = parsed.get("user_metadata", {})
			if meta is Dictionary:
				u_name = str(meta.get("full_name", meta.get("name", ""))).strip_edges()
			if u_name.is_empty():
				u_name = ProfileManager.get_name_from_email(u_email)
			ProfileManager.login_with_google(u_email, u_name)
			_bring_game_window_to_front()
			auth_succeeded.emit({"email": u_email, "name": u_name})
			return

	_bring_game_window_to_front()
	auth_failed.emit("Google hisob ma'lumotlarini olishda xatolik (HTTP %d)" % response_code)

func _store_refresh_token(token: String) -> void:
	if token.is_empty():
		return
	var f := FileAccess.open(REFRESH_TOKEN_PATH, FileAccess.WRITE)
	if f:
		f.store_string(token)
		f.close()

func _bring_game_window_to_front() -> void:
	if OS.has_feature("pc"):
		DisplayServer.window_request_attention()
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, false)

func _stop_loopback_server() -> void:
	_stop_requested = true
	is_listening = false
	if _server_thread != null and _server_thread.is_started():
		_server_thread.wait_to_finish()
	_server_thread = null
	if tcp_server != null:
		tcp_server.stop()
		tcp_server = null
