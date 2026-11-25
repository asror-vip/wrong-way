extends Node

# GoogleAuthService - Wrong Way Official Cross-Platform Google Authentication
# - Uses official Supabase Google OAuth in the system browser (Chrome on Android,
#   default browser on Windows/Mac/Linux) with a background-threaded local loopback
#   server on 127.0.0.1:8943 so callbacks are received even while the Android app
#   is backgrounded in Chrome.

signal auth_succeeded(user_data: Dictionary)
signal auth_failed(error_message: String)

const LOOPBACK_PORT: int = 8943
const REDIRECT_URI: String = "http://127.0.0.1:8943/callback"
const REFRESH_TOKEN_PATH := "user://google_refresh_token.txt"

var tcp_server: TCPServer
var is_listening: bool = false
var _stop_requested: bool = false
var _server_thread: Thread = null
var auth_timeout_timer: SceneTreeTimer
var http_user: HTTPRequest

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	http_user = HTTPRequest.new()
	http_user.name = "GoogleAuthUserHTTP"
	http_user.timeout = 8.0
	add_child(http_user)
	http_user.request_completed.connect(_on_user_info_completed)

func _exit_tree() -> void:
	_stop_loopback_server()

func start_google_sign_in() -> void:
	_start_browser_oauth()

# -------------------------------------------------------------
# Cross-Platform Official Google Browser OAuth (Android + Desktop)
# -------------------------------------------------------------
func _start_browser_oauth() -> void:
	_stop_loopback_server()

	tcp_server = TCPServer.new()
	var err := tcp_server.listen(LOOPBACK_PORT, "127.0.0.1")
	if err != OK:
		print("GoogleAuthService: Loopback serverni ishga tushirib bo'lmadi (Port %d band). Xato: %d" % [LOOPBACK_PORT, err])
		auth_failed.emit("Lokal serverni ochib bo'lmadi (Port %d band)" % LOOPBACK_PORT)
		return

	is_listening = true
	_stop_requested = false

	# Background thread keeps accepting Chrome's callback even while Android pauses _process()
	_server_thread = Thread.new()
	var t_err := _server_thread.start(_loopback_thread_worker)
	if t_err != OK:
		_server_thread = null

	var supabase_url: String = Env.get_supabase_url()
	var auth_url := "%s/auth/v1/authorize?provider=google&redirect_to=%s" % [supabase_url, REDIRECT_URI.uri_encode()]

	print("GoogleAuthService: Brauzerda rasmiy Google sahifasi ochilmoqda: ", auth_url)
	var open_err := OS.shell_open(auth_url)
	if open_err != OK:
		_stop_loopback_server()
		auth_failed.emit("Brauzerni ochib bo'lmadi (kod: %d)" % open_err)
		return

	# 120 soniyalik kutish taymeri
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
				var handled_final := _handle_http_client_sync(peer)
				if handled_final:
					break
		OS.delay_msec(15)

func _process(_delta: float) -> void:
	# Fallback if Thread could not be started
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
<html lang="uz">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wrong Way — Google Sign-In</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: #080c14;
            color: #f1f5f9;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            padding: 20px;
        }
        .card {
            background: #0f172a;
            border: 1px solid #1e293b;
            box-shadow: 0 20px 40px rgba(0,0,0,0.6);
            border-radius: 20px;
            padding: 36px 28px;
            max-width: 420px;
            width: 100%;
            text-align: center;
        }
        .icon {
            width: 56px;
            height: 56px;
            margin: 0 auto 18px;
            background: #0284c7;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 26px;
        }
        h1 { font-size: 22px; color: #38bdf8; margin-bottom: 10px; }
        p { font-size: 14px; color: #94a3b8; line-height: 1.5; margin-bottom: 22px; }
        .tag {
            display: inline-block;
            background: #1e293b;
            color: #38bdf8;
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="icon">&#10003;</div>
        <h1>Muvaffaqiyatli kirdingiz!</h1>
        <p>Google hisobingiz Wrong Way o'yiniga ulandi. Endi Wrong Way ilovasiga qaytishingiz mumkin.</p>
        <div class="tag">Wrong Way Game</div>
    </div>
    <script>
        if (window.location.hash && window.location.hash.length > 1) {
            window.location.replace('/callback?' + window.location.hash.substring(1));
        } else {
            setTimeout(function() { window.close(); }, 2500);
        }
    </script>
</body>
</html>"""

	var html_bytes := html_body.to_utf8_buffer()
	var response := "HTTP/1.1 200 OK\r\n"
	response += "Content-Type: text/html; charset=utf-8\r\n"
	response += "Content-Length: %d\r\n" % html_bytes.size()
	response += "Connection: close\r\n\r\n"

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

	var query_str := path_and_query.split("?")[1]
	var query_params := {}
	for param in query_str.split("&"):
		var kv := param.split("=")
		if kv.size() == 2:
			query_params[kv[0]] = kv[1].uri_decode()

	print("GoogleAuthService: Callback parametrlari olindi: ", query_params.keys())

	if query_params.has("error"):
		var err_desc: String = query_params.get("error_description", query_params["error"])
		print("GoogleAuthService: OAuth xatosi: ", err_desc)
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

	var user_email := ""
	var user_name := ""
	if query_params.has("user_email"):
		user_email = query_params["user_email"]
	if query_params.has("user_name"):
		user_name = query_params["user_name"]

	if user_email.is_empty():
		print("GoogleAuthService: Callbackda email parametri topilmadi.")
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

func _on_user_info_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_stop_loopback_server()
	if response_code == 200:
		var txt := body.get_string_from_utf8()
		var parsed = JSON.parse_string(txt)
		if parsed is Dictionary and parsed.has("email"):
			var u_email: String = str(parsed["email"]).strip_edges()
			var u_name := ""
			var meta = parsed.get("user_metadata", {})
			if meta is Dictionary:
				u_name = str(meta.get("full_name", meta.get("name", ""))).strip_edges()
			if u_name.is_empty():
				u_name = ProfileManager.get_name_from_email(u_email)

			print("GoogleAuthService: Haqiqiy Google foydalanuvchisi olindi: ", u_email, " (", u_name, ")")
			ProfileManager.login_with_google(u_email, u_name)
			_bring_game_window_to_front()
			auth_succeeded.emit({"email": u_email, "name": u_name})
			return

	print("GoogleAuthService: User info olishda xatolik (HTTP %d)" % response_code)
	_bring_game_window_to_front()
	auth_failed.emit("Google hisob ma'lumotlarini olishda xatolik yuz berdi (HTTP %d)" % response_code)

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
