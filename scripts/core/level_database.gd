extends Node

# LevelDatabase - Data-driven Level System (Supabase-integrated)
# 1. Local fallback from res://data/levels.json or user://levels_cache.json
# 2. Asynchronous background sync from Supabase REST API ('levels' table)
# 3. Transparent caching: if online, updates with the latest Supabase level data!

signal levels_synced_from_cloud(count: int)

const CACHE_FILE_PATH := "user://levels_cache.json"

var _levels_cache: Dictionary = {}
var is_loaded: bool = false
var http_sync: HTTPRequest

func _ready() -> void:
	load_local_levels()
	_init_supabase_sync()

func load_local_levels() -> void:
	_levels_cache.clear()
	
	# 1. Asosiy manba - loyihadagi res://data/levels.json
	var file_path := "res://data/levels.json"
	if FileAccess.file_exists(file_path):
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_text := file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(json_text)
			if parsed is Array:
				_populate_cache(parsed)
				
	# 2. Agar user keshida to'liqroq ma'lumot bo'lsa (faqat kamida 60 ta bo'lsa)
	if FileAccess.file_exists(CACHE_FILE_PATH):
		var u_file := FileAccess.open(CACHE_FILE_PATH, FileAccess.READ)
		if u_file:
			var u_text := u_file.get_as_text()
			u_file.close()
			var u_parsed = JSON.parse_string(u_text)
			if u_parsed is Array and u_parsed.size() >= 60:
				_populate_cache(u_parsed)
			else:
				# Eski keshni butunlay tozalab tashlaymiz
				DirAccess.remove_absolute(CACHE_FILE_PATH)
			
	is_loaded = true
	print("LevelDatabase: %d ta daraja muvaffaqiyatli yuklandi!" % _levels_cache.size())

func _populate_cache(items: Array) -> void:
	for item in items:
		if item is Dictionary and item.has("id"):
			var lvl_id: int = int(item["id"])
			_levels_cache[lvl_id] = item

func _init_supabase_sync() -> void:
	http_sync = HTTPRequest.new()
	http_sync.name = "SupabaseLevelSync"
	add_child(http_sync)
	http_sync.request_completed.connect(_on_sync_completed)
	
	# Backgroundda Supabase'dan eng so'nggi darajalarni olish
	fetch_from_supabase()

func fetch_from_supabase() -> void:
	if not http_sync:
		return
	var url := Env.get_supabase_url() + "/rest/v1/levels?select=*&order=id.asc"
	var anon_key := Env.get_supabase_anon_key()
	var headers := [
		"apikey: " + anon_key,
		"Authorization: Bearer " + anon_key
	]
	var err := http_sync.request(url, headers)
	if err != OK:
		print("LevelDatabase: Supabase so'rovida xatolik: ", err)

func _on_sync_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json_str := body.get_string_from_utf8()
		var parsed = JSON.parse_string(json_str)
		# Faqatgina Supabase'da kamida 60 ta to'liq daraja bo'lgandagina keshlaymiz
		if parsed is Array and parsed.size() >= 60:
			_populate_cache(parsed)
			# Keshga saqlash
			var save_file := FileAccess.open(CACHE_FILE_PATH, FileAccess.WRITE)
			if save_file:
				save_file.store_string(json_str)
				save_file.close()
			print("LevelDatabase: Supabase'dan %d ta daraja yangilandi va keshlandi!" % parsed.size())
			levels_synced_from_cloud.emit(parsed.size())
		else:
			print("LevelDatabase: Supabase'dagi darajalar soni kam (%d < 60), lokal 60 ta daraja saqlab qolindi." % (parsed.size() if parsed is Array else 0))
	else:
		print("LevelDatabase: Supabase sinxronizatsiyasi o'tkazib yuborildi (Offline/Status: %d)" % response_code)

func get_level(level_id: int) -> Dictionary:
	if not is_loaded:
		load_local_levels()
	return _levels_cache.get(level_id, {})

func has_level(level_id: int) -> bool:
	if not is_loaded:
		load_local_levels()
	return _levels_cache.has(level_id)

func get_all_levels() -> Array:
	if not is_loaded:
		load_local_levels()
	return _levels_cache.values()
