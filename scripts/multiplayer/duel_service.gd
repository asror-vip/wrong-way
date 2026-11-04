extends Node

# DuelService - Wrong Way 1v1 Competitive Multiplayer Engine
# - Synchronizes invitations, negotiation proposals, countdowns, and finishes via Supabase
# - Real-time state polling + event distribution
# - Zero race-condition atomic finish integration

signal invitation_received(duel_data: Dictionary, sender_tag: String, sender_name: String)
signal duel_updated(duel_data: Dictionary)
signal proposal_received(proposer_id: String, zone_id: int, level_id: int, proposal_id: int)
signal match_agreed(zone_id: int, level_id: int, seed_num: int)
signal match_started(started_at: String)
signal match_finished(is_victory: bool, winner_id: String)
signal opponent_disconnected_alert(seconds_left: int)

var SUPABASE_URL: String = "https://wcwjobrrwwjfthpflzhg.supabase.co"
var SUPABASE_ANON_KEY: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indjd2pvYnJyd3dqZnRocGZsemhnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM0NzIzNTEsImV4cCI6MjEwOTA0ODM1MX0.16SXhNkvVehgIuNhcGH3l9bDS37mkmbGt12h8F2CyoY"

func _init() -> void:
	if Env:
		SUPABASE_URL = Env.get_supabase_url()
		SUPABASE_ANON_KEY = Env.get_supabase_anon_key()

var active_duel: Dictionary = {}
var active_duel_id: String = ""
var is_polling: bool = false
var poll_timer: float = 0.0
const POLL_INTERVAL: float = 0.85

var last_proposal_id: int = 0
var last_status: String = ""

# Aloqa uzilishi tekshiruvi (10s countdown)
var is_opponent_disconnected: bool = false
var disconnect_countdown: float = 10.0

# AI Ghost / Practice Bot Duel tizimi
var is_bot_duel: bool = false
var bot_target_time_ms: float = 0.0
var bot_timer_active: bool = false
var bot_elapsed_time: float = 0.0

func _ready() -> void:
	# Bosh menyuda turganida ham kelayotgan takliflarni tekshirish uchun fon taymeri
	var bg_timer := Timer.new()
	bg_timer.wait_time = 3.0
	bg_timer.autostart = true
	bg_timer.timeout.connect(_check_pending_invitations)
	add_child(bg_timer)

func _process(delta: float) -> void:
	if is_bot_duel and bot_timer_active and GameManager.is_duel_mode and GameManager.is_level_running:
		bot_elapsed_time += delta * 1000.0
		if bot_elapsed_time >= bot_target_time_ms:
			bot_timer_active = false
			GameManager.is_level_running = false
			match_finished.emit(false, "bot_ghost")

	if is_polling and not active_duel_id.is_empty() and not is_bot_duel:
		poll_timer += delta
		if poll_timer >= POLL_INTERVAL:
			poll_timer = 0.0
			_poll_active_duel()
			
	if is_opponent_disconnected and not active_duel_id.is_empty() and not is_bot_duel:
		disconnect_countdown -= delta
		opponent_disconnected_alert.emit(int(ceil(disconnect_countdown)))
		if disconnect_countdown <= 0.0:
			is_opponent_disconnected = false
			_trigger_forfeit()

# ========================================================
# 1. DO'STNI QIDIRISH VA TAKLIF YUBORISH
# ========================================================
func search_player(tag: String, on_result: Callable) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, code, _h, body):
		http.queue_free()
		if code == 200:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			on_result.call(parsed)
		else:
			on_result.call({"success": false, "message": "Server xatosi: %d" % code})
	)
	var url := SUPABASE_URL + "/rest/v1/rpc/search_player_by_tag"
	var headers := _get_headers()
	var payload := JSON.stringify({"p_player_tag": tag})
	http.request(url, headers, HTTPClient.METHOD_POST, payload)

func fetch_active_players(on_result: Callable) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, code, _h, body):
		http.queue_free()
		if code == 200:
			var arr = JSON.parse_string(body.get_string_from_utf8())
			if arr is Array:
				var filtered: Array = []
				var my_id: String = ProfileManager.player_id
				var my_tag: String = ProfileManager.player_tag
				for p in arr:
					if p is Dictionary:
						var p_id: String = str(p.get("id", ""))
						var p_tag: String = str(p.get("player_tag", ""))
						if p_id != my_id and p_tag != my_tag and not p_tag.is_empty():
							filtered.append(p)
				on_result.call(filtered)
				return
		on_result.call([])
	)
	var url := SUPABASE_URL + "/rest/v1/profiles?select=id,username,player_tag,avatar_url&limit=10&order=updated_at.desc"
	http.request(url, _get_headers(), HTTPClient.METHOD_GET)

func send_invitation(target_tag: String, on_result: Callable) -> void:
	var my_id: String = ProfileManager.player_id
	if my_id.is_empty():
		on_result.call({"success": false, "message": "Avval profilingiz yuklanishi kerak"})
		return
		
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, code, _h, body):
		http.queue_free()
		if code == 200:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Dictionary and parsed.get("success", false):
				var duel: Dictionary = parsed.get("duel", {})
				set_active_duel(duel)
				ProfileManager.add_recent_friend(target_tag)
			on_result.call(parsed)
		else:
			on_result.call({"success": false, "message": "Taklif yuborishda xatolik"})
	)
	var url := SUPABASE_URL + "/rest/v1/rpc/create_duel_invitation"
	var headers := _get_headers()
	var payload := JSON.stringify({
		"p_sender_id": my_id,
		"p_target_tag": target_tag
	})
	http.request(url, headers, HTTPClient.METHOD_POST, payload)

func _check_pending_invitations() -> void:
	if not active_duel_id.is_empty() or ProfileManager.player_id.is_empty():
		return
		
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, code, _h, body):
		http.queue_free()
		if code == 200:
			var arr = JSON.parse_string(body.get_string_from_utf8())
			if arr is Array and arr.size() > 0:
				var d: Dictionary = arr[0]
				var d_id: String = str(d.get("id", ""))
				# Taklif bergan o'yinchi ma'lumotlarini olish
				_fetch_sender_and_emit(d)
	)
	var my_id := ProfileManager.player_id
	var url := SUPABASE_URL + "/rest/v1/duels?player_b_id=eq." + my_id + "&duel_status=eq.INVITATION_PENDING&order=created_at.desc&limit=1"
	http.request(url, _get_headers(), HTTPClient.METHOD_GET)

func _fetch_sender_and_emit(duel_data: Dictionary) -> void:
	var sender_id: String = str(duel_data.get("player_a_id", ""))
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, code, _h, body):
		http.queue_free()
		var sender_tag := "WW-????"
		var sender_name := "Raqib"
		if code == 200:
			var arr = JSON.parse_string(body.get_string_from_utf8())
			if arr is Array and arr.size() > 0:
				sender_tag = str(arr[0].get("player_tag", sender_tag))
				sender_name = str(arr[0].get("username", sender_name))
				ProfileManager.add_recent_friend(sender_tag, sender_name)
		invitation_received.emit(duel_data, sender_tag, sender_name)
	)
	var url := SUPABASE_URL + "/rest/v1/profiles?id=eq." + sender_id
	http.request(url, _get_headers(), HTTPClient.METHOD_GET)

func respond_invitation(duel_id: String, accept: bool, on_result: Callable = Callable()) -> void:
	var my_id := ProfileManager.player_id
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, code, _h, body):
		http.queue_free()
		if code == 200:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if accept and parsed is Dictionary and parsed.get("success", false):
				set_active_duel(parsed.get("duel", {}))
			if on_result.is_valid():
				on_result.call(parsed)
	)
	var url := SUPABASE_URL + "/rest/v1/rpc/respond_duel_invitation"
	var payload := JSON.stringify({
		"p_duel_id": duel_id,
		"p_player_id": my_id,
		"p_accept": accept
	})
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, payload)

# ========================================================
# 1.B RANDOM MATCHMAKING (60s Queue)
# ========================================================
func find_random_match(on_result: Callable) -> void:
	var my_id := ProfileManager.player_id
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, code, _h, body):
		http.queue_free()
		if code == 200:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Dictionary and parsed.get("matched", false):
				set_active_duel(parsed.get("duel", {}))
			on_result.call(parsed)
		else:
			on_result.call({"matched": false, "message": "Server xatosi: %d" % code})
	)
	var url := SUPABASE_URL + "/rest/v1/rpc/find_random_match"
	var payload := JSON.stringify({"p_player_id": my_id})
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, payload)

func poll_match_status(on_result: Callable) -> void:
	var my_id := ProfileManager.player_id
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, code, _h, body):
		http.queue_free()
		if code == 200:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Dictionary and parsed.get("matched", false):
				set_active_duel(parsed.get("duel", {}))
			on_result.call(parsed)
		else:
			on_result.call({"matched": false})
	)
	var url := SUPABASE_URL + "/rest/v1/rpc/check_match_status"
	var payload := JSON.stringify({"p_player_id": my_id})
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, payload)

func cancel_matchmaking() -> void:
	var my_id := ProfileManager.player_id
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, _c, _h, _b): http.queue_free())
	var url := SUPABASE_URL + "/rest/v1/rpc/cancel_matchmaking"
	var payload := JSON.stringify({"p_player_id": my_id})
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, payload)

# ========================================================
# 2. LOBBY VA KELISHUV (NEGOTIATION)
# ========================================================
func propose_level(zone_id: int, level_id: int, on_result: Callable = Callable()) -> void:
	if active_duel_id.is_empty():
		return
	var my_id := ProfileManager.player_id
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, code, _h, body):
		http.queue_free()
		if code == 200:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if on_result.is_valid(): on_result.call(parsed)
	)
	var url := SUPABASE_URL + "/rest/v1/rpc/propose_duel_level"
	var payload := JSON.stringify({
		"p_duel_id": active_duel_id,
		"p_proposer_id": my_id,
		"p_zone_id": zone_id,
		"p_level_id": level_id
	})
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, payload)

func respond_proposal(proposal_id: int, accept: bool, on_result: Callable = Callable()) -> void:
	if active_duel_id.is_empty():
		return
	var my_id := ProfileManager.player_id
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, code, _h, body):
		http.queue_free()
		if code == 200:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if on_result.is_valid(): on_result.call(parsed)
	)
	var url := SUPABASE_URL + "/rest/v1/rpc/respond_duel_proposal"
	var payload := JSON.stringify({
		"p_duel_id": active_duel_id,
		"p_responder_id": my_id,
		"p_proposal_id": proposal_id,
		"p_accept": accept
	})
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, payload)

# ========================================================
# 2.B AI GHOST / PRACTICE BOT DUEL
# ========================================================
func setup_bot_duel(zone_id: int, level_id: int) -> void:
	is_bot_duel = true
	bot_timer_active = false
	bot_elapsed_time = 0.0
	var actual_lvl: int = (zone_id - 1) * 20 + level_id
	
	# Har bir daraja uchun raqobatbardosh, lekin yutsa bo'ladigan bot vaqti
	var base_sec: float = 11.5 + (float(actual_lvl) * 0.22)
	var bot_sec: float = base_sec + randf_range(-0.8, 1.8)
	bot_target_time_ms = bot_sec * 1000.0
	
	active_duel = {
		"id": "bot_session_local",
		"player_a_id": ProfileManager.player_id,
		"player_b_id": "bot_ghost",
		"selected_zone_id": zone_id,
		"selected_level_id": level_id,
		"random_seed": randi() % 999999,
		"duel_status": "LOBBY"
	}
	active_duel_id = "bot_session_local"
	is_polling = false
	duel_updated.emit(active_duel)

func start_bot_match_timer() -> void:
	if is_bot_duel:
		bot_timer_active = true
		bot_elapsed_time = 0.0

func start_match() -> void:
	if is_bot_duel:
		start_bot_match_timer()
		return
	if active_duel_id.is_empty():
		return
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, _c, _h, _b): http.queue_free())
	var url := SUPABASE_URL + "/rest/v1/rpc/start_duel_match"
	var payload := JSON.stringify({"p_duel_id": active_duel_id})
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, payload)

# ========================================================
# 3. ATOMIK G'OLIBLIKNI ANIQLASH (CLAIM FINISH)
# ========================================================
func claim_finish(completion_ms: float, deaths: int, on_result: Callable = Callable()) -> void:
	if is_bot_duel:
		bot_timer_active = false
		GameManager.is_level_running = false
		var won: bool = (completion_ms <= bot_target_time_ms)
		match_finished.emit(won, ProfileManager.player_id if won else "bot_ghost")
		if on_result.is_valid():
			on_result.call({"success": true, "result": "VICTORY" if won else "DEFEAT"})
		return
	if active_duel_id.is_empty():
		return
	var my_id := ProfileManager.player_id
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, code, _h, body):
		http.queue_free()
		if code == 200:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			var is_win: bool = (parsed.get("result", "") == "VICTORY")
			var winner: String = str(parsed.get("winner_id", my_id))
			match_finished.emit(is_win, winner)
			if on_result.is_valid(): on_result.call(parsed)
	)
	var url := SUPABASE_URL + "/rest/v1/rpc/claim_duel_finish"
	var payload := JSON.stringify({
		"p_duel_id": active_duel_id,
		"p_player_id": my_id,
		"p_completion_time_ms": completion_ms,
		"p_deaths": deaths
	})
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, payload)

func _trigger_forfeit() -> void:
	if active_duel_id.is_empty():
		return
	var opponent_id := get_opponent_id()
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, _c, _h, _b):
		http.queue_free()
		match_finished.emit(true, ProfileManager.player_id)
	)
	var url := SUPABASE_URL + "/rest/v1/rpc/forfeit_duel_disconnect"
	var payload := JSON.stringify({
		"p_duel_id": active_duel_id,
		"p_disconnected_id": opponent_id
	})
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, payload)

# ========================================================
# 4. AKTIV DUELNI POLING QILISH
# ========================================================
func set_active_duel(duel_data: Dictionary) -> void:
	active_duel = duel_data
	active_duel_id = str(duel_data.get("id", ""))
	last_status = str(duel_data.get("duel_status", ""))
	last_proposal_id = int(duel_data.get("proposal_id", 0))
	is_polling = not active_duel_id.is_empty()
	poll_timer = 0.0

func leave_active_duel() -> void:
	active_duel.clear()
	active_duel_id = ""
	is_polling = false
	is_opponent_disconnected = false
	is_bot_duel = false
	bot_timer_active = false

func _poll_active_duel() -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, code, _h, body):
		http.queue_free()
		if code == 200:
			var arr = JSON.parse_string(body.get_string_from_utf8())
			if arr is Array and arr.size() > 0:
				_process_duel_update(arr[0])
	)
	var url := SUPABASE_URL + "/rest/v1/duels?id=eq." + active_duel_id
	http.request(url, _get_headers(), HTTPClient.METHOD_GET)

func _process_duel_update(data: Dictionary) -> void:
	active_duel = data
	duel_updated.emit(data)
	
	var status: String = str(data.get("duel_status", ""))
	var p_id: int = int(data.get("proposal_id", 0))
	var p_status: String = str(data.get("proposal_status", ""))
	var proposed_by: String = str(data.get("proposed_by", ""))
	var my_id := ProfileManager.player_id
	
	# Yangi taklif kelgan bo'lsa va uni raqib taklif qilgan bo'lsa
	if p_id > last_proposal_id and p_status == "PENDING" and proposed_by != my_id:
		last_proposal_id = p_id
		var z: int = int(data.get("selected_zone_id", 1))
		var l: int = int(data.get("selected_level_id", 1))
		proposal_received.emit(proposed_by, z, l, p_id)
		
	# Ikkala o'yinchi kelishgan bo'lsa (AGREED)
	if status == "AGREED" and last_status != "AGREED":
		last_status = "AGREED"
		var z: int = int(data.get("selected_zone_id", 1))
		var l: int = int(data.get("selected_level_id", 1))
		var s: int = int(data.get("random_seed", 0))
		match_agreed.emit(z, l, s)
		
	# O'yin boshlangan bo'lsa (RUNNING)
	if status == "RUNNING" and last_status != "RUNNING":
		last_status = "RUNNING"
		match_started.emit(str(data.get("started_at", "")))
		
	# O'yin yakunlangan bo'lsa (COMPLETED yoki FORFEITED)
	if status in ["COMPLETED", "FORFEITED"] and last_status not in ["COMPLETED", "FORFEITED"]:
		last_status = status
		var winner: String = str(data.get("winner_id", ""))
		var is_win: bool = (winner == my_id)
		match_finished.emit(is_win, winner)

func get_opponent_id() -> String:
	if is_bot_duel:
		return "bot_ghost"
	var my_id := ProfileManager.player_id
	var pa: String = str(active_duel.get("player_a_id", ""))
	var pb: String = str(active_duel.get("player_b_id", ""))
	return pb if pa == my_id else pa

func _get_headers() -> PackedStringArray:
	return PackedStringArray([
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY,
		"Content-Type: application/json"
	])

