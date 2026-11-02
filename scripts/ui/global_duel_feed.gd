extends Control

# GlobalDuelFeed - Animated Live Rotating Duel Feed
# - Displays recent competitive victory events
# - Sleek capsule cards with top drop-in fade and smooth exit
# - Continuous rotation cycle through recent duels
# - Responsive, non-intrusive UI placed near main menu top-right

const SUPABASE_URL := "https://wcwjobrrwwjfthpflzhg.supabase.co"
const SUPABASE_ANON_KEY := "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indjd2pvYnJyd3dqZnRocGZsemhnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM0NzIzNTEsImV4cCI6MjEwOTA0ODM1MX0.16SXhNkvVehgIuNhcGH3l9bDS37mkmbGt12h8F2CyoY"

@onready var container: VBoxContainer = $FeedContainer

var feed_items: Array = []
var current_feed_idx: int = 0
var cycle_timer: float = 0.0
const CYCLE_INTERVAL: float = 4.2
var fetch_timer: float = 0.0
const FETCH_INTERVAL: float = 18.0

# Baza bo'sh bo'lganda yoki oflaynda aylanib turish uchun namunaviy duellar
const DEFAULT_SAMPLE_DUELS: Array = [
	{
		"winner_name": "AlphaPlayer",
		"loser_name": "BetaRacer",
		"zone_id": 1,
		"level_id": 20
	},
	{
		"winner_name": "ShadowNinja",
		"loser_name": "SpeedRunner",
		"zone_id": 1,
		"level_id": 15
	},
	{
		"winner_name": "Champion",
		"loser_name": "GhostHunter",
		"zone_id": 2,
		"level_id": 5
	}
]

func _ready() -> void:
	if container:
		container.add_theme_constant_override("separation", 8)
		
	feed_items = DEFAULT_SAMPLE_DUELS.duplicate()
	fetch_feed()
	# Birinchi kartani darhol ko'rsatish
	_show_next_card()

func _process(delta: float) -> void:
	cycle_timer += delta
	if cycle_timer >= CYCLE_INTERVAL:
		cycle_timer = 0.0
		_show_next_card()
		
	fetch_timer += delta
	if fetch_timer >= FETCH_INTERVAL:
		fetch_timer = 0.0
		fetch_feed()

func fetch_feed() -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_res, code, _h, body):
		http.queue_free()
		if code == 200:
			var txt: String = body.get_string_from_utf8()
			var parsed = JSON.parse_string(txt)
			if parsed is Array and parsed.size() > 0:
				feed_items = parsed
				current_feed_idx = current_feed_idx % feed_items.size()
	)
	var url := SUPABASE_URL + "/rest/v1/rpc/get_global_duel_feed"
	var headers := PackedStringArray([
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY,
		"Content-Type: application/json"
	])
	var payload := JSON.stringify({"p_limit": 6})
	http.request(url, headers, HTTPClient.METHOD_POST, payload)

func _show_next_card() -> void:
	if not container or feed_items.is_empty():
		return
		
	# Maksimal 1 ta faol karta (WRONG WAY sarlavhasi ustida bittalab silliq aylanib turadi)
	if container.get_child_count() >= 1:
		for old_child in container.get_children():
			var oldest: Control = old_child as Control
			if oldest and is_instance_valid(oldest) and not oldest.is_queued_for_deletion():
				_animate_card_exit(oldest)
				
	if current_feed_idx < 0 or current_feed_idx >= feed_items.size():
		current_feed_idx = 0
		
	var item = feed_items[current_feed_idx]
	current_feed_idx = (current_feed_idx + 1) % feed_items.size()
	
	if item is Dictionary:
		_add_animated_feed_card(item)

func _add_animated_feed_card(data: Dictionary) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(250, 32)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.14, 0.88)
	style.border_color = Color(0.24, 0.45, 0.72, 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 5
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	card.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Crown Icon
	var crown := IconFactory.create_texture_rect("crown_gold", Vector2(14, 14), 0.8)
	crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(crown)
	
	# Winner
	var winner_name: String = str(data.get("winner_name", "G'olib"))
	var win_lbl := Label.new()
	win_lbl.text = winner_name
	win_lbl.add_theme_font_size_override("font_size", 12)
	win_lbl.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	hbox.add_child(win_lbl)
	
	# Separator Indicator
	var arrow_lbl := Label.new()
	arrow_lbl.text = "▸"
	arrow_lbl.add_theme_font_size_override("font_size", 11)
	arrow_lbl.add_theme_color_override("font_color", Color(0.38, 0.74, 0.97))
	hbox.add_child(arrow_lbl)
	
	# Loser
	var loser_name: String = str(data.get("loser_name", "Raqib"))
	var lose_lbl := Label.new()
	lose_lbl.text = loser_name
	lose_lbl.add_theme_font_size_override("font_size", 11)
	lose_lbl.add_theme_color_override("font_color", Color(0.68, 0.74, 0.85))
	hbox.add_child(lose_lbl)
	
	# Level badge
	var z: int = int(data.get("zone_id", 1))
	var l: int = int(data.get("level_id", 1))
	var lvl_lbl := Label.new()
	lvl_lbl.text = "(Z%d·L%d)" % [z, l]
	lvl_lbl.add_theme_font_size_override("font_size", 10)
	lvl_lbl.add_theme_color_override("font_color", Color(0.40, 0.75, 1.0, 0.9))
	hbox.add_child(lvl_lbl)
	
	card.add_child(hbox)
	container.add_child(card)
	
	# Silliq yuqoridan tushish (uncha baland emas: -10px) va tiniqlashish animatsiyasi
	card.modulate.a = 0.0
	card.position.y = -10.0
	
	var tw := create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(card, "position:y", 0.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Belgilangan vaqtdan so'ng o'z-o'zidan xiralashib yo'qolish
	var exit_tw := create_tween()
	exit_tw.tween_interval(3.6)
	exit_tw.tween_callback(func():
		if is_instance_valid(card) and not card.is_queued_for_deletion():
			_animate_card_exit(card)
	)

func _animate_card_exit(card: Control) -> void:
	if not is_instance_valid(card) or card.is_queued_for_deletion():
		return
	var tw := create_tween()
	tw.tween_property(card, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(card, "position:y", card.position.y + 6.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		if is_instance_valid(card):
			card.queue_free()
	)
