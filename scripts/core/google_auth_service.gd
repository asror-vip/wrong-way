extends Node

# GoogleAuthService - Wrong Way Official Cross-Platform Google Authentication
# - Desktop (Windows/Mac/Linux): Opens official Google Sign-In in default browser & receives token via local loopback server
# - Mobile (Android): Connects to native Google Play Games Services v2 / Google Credential Manager bottom sheet
# - Automatic fallback and zero custom fake modals

signal auth_succeeded(user_data: Dictionary)
signal auth_failed(error_message: String)

const LOOPBACK_PORT: int = 8943
const REDIRECT_URI: String = "http://127.0.0.1:8943/callback"

var tcp_server: TCPServer
var is_listening: bool = false
var auth_timeout_timer: SceneTreeTimer
var http_user: HTTPRequest

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	http_user = HTTPRequest.new()
	http_user.name = "GoogleAuthUserHTTP"
	http_user.timeout = 6.0
	add_child(http_user)
	http_user.request_completed.connect(_on_user_info_completed)

func start_google_sign_in() -> void:
	if OS.get_name() == "Android":
		_start_android_sign_in()
	else:
		_start_desktop_oauth()

# -------------------------------------------------------------
# Android Native Google Play Games / Sign-In
# -------------------------------------------------------------
func _start_android_sign_in() -> void:
	print("GoogleAuthService: Android muhitida Google Sign-In ishga tushirilmoqda...")
	
	# 1. Native Android Google Account Chooser (OS darajasidagi haqiqiy tizim oynasi)
	if Engine.has_singleton("WrongWayAccountPicker"):
		var picker = Engine.get_singleton("WrongWayAccountPicker")
		if picker.has_signal("account_picked") and not picker.account_picked.is_connected(_on_android_account_picked):
			picker.account_picked.connect(_on_android_account_picked)
		if picker.has_signal("account_picker_failed") and not picker.account_picker_failed.is_connected(_on_android_account_picker_failed):
			picker.account_picker_failed.connect(_on_android_account_picker_failed)
			
		if picker.has_method("openAccountPicker"):
			picker.openAccountPicker()
			return

	# 2. Google Play Games Services v2
	if Engine.has_singleton("GodotPlayGames"):
		var pgs = Engine.get_singleton("GodotPlayGames")
		if pgs.has_signal("user_authenticated") and not pgs.user_authenticated.is_connected(_on_android_pgs_success):
			pgs.user_authenticated.connect(_on_android_pgs_success)
		if pgs.has_signal("authentication_failed") and not pgs.authentication_failed.is_connected(_on_android_pgs_failed):
			pgs.authentication_failed.connect(_on_android_pgs_failed)
			
		if pgs.has_method("signIn"):
			pgs.signIn()
			return

	# 2. Standart Android Google Sign-In
	if Engine.has_singleton("GoogleSignIn"):
		var gsi = Engine.get_singleton("GoogleSignIn")
		if gsi.has_signal("sign_in_success") and not gsi.sign_in_success.is_connected(_on_android_gsi_success):
			gsi.sign_in_success.connect(_on_android_gsi_success)
		if gsi.has_signal("sign_in_failed") and not gsi.sign_in_failed.is_connected(_on_android_gsi_failed):
			gsi.sign_in_failed.connect(_on_android_gsi_failed)
			
		if gsi.has_method("signIn"):
			gsi.signIn()
			return

	# Agar Android plagin hali o'rnatilmagan bo'lsa
	print("GoogleAuthService: Android tizim plagini topilmadi, ilova ichidagi xavfsiz tizim ishga tushiriladi.")
	auth_failed.emit("Iltimos, ilova ichidagi hisob oynasidan kiring.")

func _on_android_account_picked(acc_email: String, acc_name: String) -> void:
	print("GoogleAuthService: Android tizimidan Google hisobi tanlandi: ", acc_email, " (", acc_name, ")")
	var user_data := {"email": acc_email, "name": acc_name}
	ProfileManager.login_with_google(acc_email, acc_name)
	auth_succeeded.emit(user_data)

func _on_android_account_picker_failed(err_msg: String) -> void:
	print("GoogleAuthService: Android hisob tanlash bekor qilindi: ", err_msg)
	auth_failed.emit(err_msg)

func _on_android_pgs_success(is_auth: bool) -> void:
	if is_auth:
		var pgs = Engine.get_singleton("GodotPlayGames")
		var player_name: String = pgs.getPlayerName() if pgs.has_method("getPlayerName") else "Gamer"
		var player_id: String = pgs.getPlayerId() if pgs.has_method("getPlayerId") else ""
		var email_str := player_id + "@playgames.google.com" if not player_id.is_empty() else "player@playgames.google.com"
		
		print("GoogleAuthService: Play Games muvaffaqiyatli: ", player_name)
		var user_data := {"email": email_str, "name": player_name}
		ProfileManager.login_with_google(email_str, player_name)
		auth_succeeded.emit(user_data)
	else:
		_on_android_pgs_failed(-1)

func _on_android_pgs_failed(err_code: int) -> void:
	print("GoogleAuthService: Android Play Games xatosi: ", err_code)
	auth_failed.emit("Google Play Games xatosi: " + str(err_code))

func _on_android_gsi_success(account_info: Dictionary) -> void:
	var g_email: String = account_info.get("email", "")
	var g_name: String = account_info.get("displayName", "")
	print("GoogleAuthService: Google Sign-In muvaffaqiyatli: ", g_email)
	var user_data := {"email": g_email, "name": g_name}
	ProfileManager.login_with_google(g_email, g_name)
	auth_succeeded.emit(user_data)

func _on_android_gsi_failed(err_msg: String) -> void:
	print("GoogleAuthService: Google Sign-In xatosi: ", err_msg)
	auth_failed.emit(err_msg)

# -------------------------------------------------------------
# Desktop (Windows / Mac / Linux) Official Google Browser OAuth
# -------------------------------------------------------------
func _start_desktop_oauth() -> void:
	_stop_loopback_server()
	
	tcp_server = TCPServer.new()
	var err := tcp_server.listen(LOOPBACK_PORT, "127.0.0.1")
	if err != OK:
		print("GoogleAuthService: Loopback serverni ishga tushirib bo'lmadi (Port %d band). Xato: %d" % [LOOPBACK_PORT, err])
		auth_failed.emit("Lokal serverni ochib bo'lmadi (Port %d band)" % LOOPBACK_PORT)
		return
		
	is_listening = true
	print("GoogleAuthService: Lokal loopback server tinglamoqda: ", REDIRECT_URI)
	
	# Rasmiy Supabase Google OAuth havolasi
	var supabase_url: String = Env.get_supabase_url()
	var auth_url := "%s/auth/v1/authorize?provider=google&redirect_to=%s" % [supabase_url, REDIRECT_URI.uri_encode()]
	
	print("GoogleAuthService: Brauzerda rasmiy Google sahifasi ochilmoqda: ", auth_url)
	OS.shell_open(auth_url)
	
	# 90 soniyalik kutish taymeri
	auth_timeout_timer = get_tree().create_timer(90.0)
	auth_timeout_timer.timeout.connect(func():
		if is_listening:
			_stop_loopback_server()
			auth_failed.emit("Google orqali kirish vaqti tugadi (Timeout)")
	)

func _process(_delta: float) -> void:
	if not is_listening or not tcp_server:
		return
		
	if tcp_server.is_connection_available():
		var peer: StreamPeerTCP = tcp_server.take_connection()
		if peer:
			_handle_http_client(peer)

func _handle_http_client(peer: StreamPeerTCP) -> void:
	# HTTP so'rov kelishini qisqa kutamiz
	var start_ms := Time.get_ticks_msec()
	while peer.get_status() == StreamPeerTCP.STATUS_CONNECTED and peer.get_available_bytes() == 0:
		if Time.get_ticks_msec() - start_ms > 2000:
			break
		OS.delay_msec(10)
		
	var available := peer.get_available_bytes()
	if available <= 0:
		peer.disconnect_from_host()
		return
		
	var raw_req := peer.get_utf8_string(available)
	var lines := raw_req.split("\r\n")
	if lines.is_empty():
		peer.disconnect_from_host()
		return
		
	var request_line := lines[0] # masalan: GET /callback?code=... HTTP/1.1 yoki GET /callback#...
	print("GoogleAuthService: HTTP so'rov qabul qilindi: ", request_line)
	
	# Brauzerga qaytariladigan nafis HTML sahifa
	var html_body := """<!DOCTYPE html>
<html lang="uz">
<head>
    <meta charset="UTF-8">
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
        }
        .card {
            background: #0f172a;
            border: 1px solid #1e293b;
            box-shadow: 0 20px 40px rgba(0,0,0,0.6);
            border-radius: 20px;
            padding: 40px;
            max-width: 440px;
            text-align: center;
        }
        .icon {
            width: 56px;
            height: 56px;
            margin: 0 auto 20px;
            background: #0284c7;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 26px;
        }
        h1 { font-size: 22px; color: #38bdf8; margin-bottom: 10px; }
        p { font-size: 14px; color: #94a3b8; line-height: 1.5; margin-bottom: 24px; }
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
        <p>Google hisobingiz Wrong Way o'yiniga ulandi. Ushbu brauzer oynasini yopib, o'yinga qaytishingiz mumkin.</p>
        <div class="tag">Wrong Way Game</div>
        <br>
        <button onclick="window.close();" style="margin-top: 18px; padding: 12px 28px; font-size: 15px; background: #0284c7; color: #ffffff; border: none; border-radius: 25px; cursor: pointer; font-weight: 600; box-shadow: 0 4px 15px rgba(2,132,199,0.4);">
            Ilovaga qaytish
        </button>
    </div>
    <script>
        // Fragment (#access_token=...) parametrlarini query qilib qayta yuborish
        if (window.location.hash && window.location.hash.length > 1) {
            window.location.replace('/callback?' + window.location.hash.substring(1));
        } else {
            setTimeout(function() { window.close(); }, 3000);
        }
    </script>
</body>
</html>"""

	var response := "HTTP/1.1 200 OK\r\n"
	response += "Content-Type: text/html; charset=utf-8\r\n"
	response += "Content-Length: %d\r\n" % html_body.to_utf8_buffer().size()
	response += "Connection: close\r\n\r\n"
	response += html_body
	
	peer.put_data(response.to_utf8_buffer())
	
	# URL dagi parametrlarni ajratib olish
	_parse_auth_request(request_line)
	
	# Qisqa tanaffusdan keyin ulanishni yopish
	get_tree().create_timer(0.4).timeout.connect(func():
		peer.disconnect_from_host()
	)

func _parse_auth_request(req_line: String) -> void:
	# Masalan: GET /callback?code=xyz... yoki GET /callback?access_token=xyz...
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
	
	# Agar xatolik bo'lsa
	if query_params.has("error"):
		var err_desc: String = query_params.get("error_description", query_params["error"])
		print("GoogleAuthService: OAuth xatosi: ", err_desc)
		auth_failed.emit(err_desc)
		_stop_loopback_server()
		return
		
	# Supabase Access Token orqali haqiqiy Google profilini olish
	if query_params.has("access_token"):
		var token: String = query_params["access_token"]
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

func _bring_game_window_to_front() -> void:
	if OS.has_feature("pc"):
		DisplayServer.window_request_attention()
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, false)

func _stop_loopback_server() -> void:
	is_listening = false
	if tcp_server:
		tcp_server.stop()
		tcp_server = null
	print("GoogleAuthService: Loopback server to'xtatildi.")
