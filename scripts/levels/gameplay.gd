extends Node2D

@onready var level_holder: Node2D = $LevelHolder
@onready var camera: Camera2D = $Camera2D

var shake_intensity: float = 0.0

func _ready() -> void:
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_method("hide_banner"):
		adm.hide_banner()
	GameManager.request_screen_shake.connect(_on_screen_shake)
	GameManager.level_started.connect(_load_level)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_load_level(GameManager.current_level_id)
	
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.should_restore_result_modal and not sm.pending_result_data.is_empty():
		sm.should_restore_result_modal = false
		GameManager.is_level_running = false
		var win_overlay = get_node_or_null("CanvasLayer/WinOverlay")
		if win_overlay and win_overlay.has_method("restore_result"):
			win_overlay.restore_result(sm.pending_result_data)
		if level_holder:
			level_holder.process_mode = Node.PROCESS_MODE_DISABLED
	elif GameManager.is_duel_mode:
		var hud = get_node_or_null("CanvasLayer/GameHUD")
		if hud and hud.has_method("start_duel_countdown"):
			hud.start_duel_countdown()

func _on_viewport_size_changed() -> void:
	_adapt_level_to_viewport()

func _process(delta: float) -> void:
	if shake_intensity > 0.0:
		shake_intensity = maxf(0.0, shake_intensity - delta * 25.0)
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_intensity
	else:
		camera.offset = Vector2.ZERO

func _on_screen_shake(intensity: float) -> void:
	shake_intensity = intensity

var level_arena_scene = preload("res://scenes/levels/level_arena.tscn")
static var _level_cache: Dictionary = {}

func reload_to_level(lvl: int) -> void:
	get_tree().paused = false
	var win_overlay = get_node_or_null("CanvasLayer/WinOverlay")
	if win_overlay:
		win_overlay.visible = false
	var pause_modal = get_node_or_null("CanvasLayer/PauseModal")
	if pause_modal:
		pause_modal.visible = false
		
	GameManager.current_level_id = lvl
	GameManager.level_deaths = 0
	GameManager.level_timer_ms = 0.0
	GameManager.level_start_time = Time.get_ticks_msec()
	GameManager.is_level_running = true
	
	_load_level(lvl)
	GameManager.level_started.emit(lvl)

func _load_level(lvl: int) -> void:
	if level_holder:
		level_holder.process_mode = Node.PROCESS_MODE_INHERIT
	for child in level_holder.get_children():
		child.queue_free()
		
	# 1. Asosiy va eng aniq sozlangan sahna (.tscn) kesh orqali tezkor yuklanadi
	var path := "res://scenes/levels/level_%02d.tscn" % lvl
	var lvl_res: PackedScene = null
	if _level_cache.has(path):
		lvl_res = _level_cache[path]
	elif ResourceLoader.exists(path):
		lvl_res = load(path)
		if lvl_res:
			_level_cache[path] = lvl_res

	var inst: Node2D = null
	if lvl_res:
		inst = lvl_res.instantiate()
		level_holder.add_child(inst)
	else:
		# 2. Agar sahna fayli topilmasa, LevelDatabase dan dinamik arena yuklanadi
		var ldb = get_node_or_null("/root/LevelDatabase")
		if ldb and ldb.has_method("has_level") and ldb.has_level(lvl):
			var arena = level_arena_scene.instantiate()
			level_holder.add_child(arena)
			arena.load_level_from_data(ldb.get_level(lvl))
			inst = arena

	if inst:
		_adapt_level_to_viewport(inst)

## Har qanday ekran o'lchami (mobil 20:9, 19.5:9, 18:9, 16:9 va desktop 16:10, 21:9) uchun
## o'yin maydonini qora hoshiyalarsiz, to'liq ekranga moslashtiruvchi universal adapter
func _adapt_level_to_viewport(level_node: Node2D = null) -> void:
	if level_node == null:
		if level_holder and level_holder.get_child_count() > 0:
			level_node = level_holder.get_child(0)
		else:
			return

	if not is_instance_valid(level_node):
		return

	var vp_size := get_viewport_rect().size
	var vp_w := maxf(960.0, vp_size.x)
	var vp_h := maxf(540.0, vp_size.y)

	var screen_left := 480.0 - vp_w / 2.0
	var screen_right := 480.0 + vp_w / 2.0
	var screen_top := 270.0 - vp_h / 2.0
	var screen_bottom := 270.0 + vp_h / 2.0

	var platforms := level_node.find_children("*", "StaticBody2D", true, false)
	for plat in platforms:
		if not is_instance_valid(plat) or not ("platform_size" in plat):
			continue

		var p_name := plat.name.to_lower()
		var p_size: Vector2 = plat.platform_size
		var p_pos: Vector2 = plat.position

		# 1. SHIFT (Ceiling) - ekranning yuqori chetiga to'liq yopishgan va chapdan o'nggacha
		if p_name.contains("ceiling") or p_name.contains("shift") or (p_pos.y <= 25.0 and p_size.y < 120.0 and p_size.x >= 500.0):
			plat.position.x = screen_left - 100.0
			plat.position.y = screen_top - 100.0
			plat.platform_size.x = (screen_right - screen_left) + 200.0
			plat.platform_size.y = (0.0 - screen_top) + 60.0 + 100.0
			_update_platform_collision(plat)

		# 2. CHAP DEVOR (WallLeft) - ekranning eng chap qirrasiga
		elif p_name.contains("wallleft") or (p_pos.x <= 40.0 and p_size.y > p_size.x and p_size.y >= 300.0):
			plat.position.x = screen_left
			plat.position.y = screen_top - 50.0
			plat.platform_size.x = 32.0
			plat.platform_size.y = (screen_bottom - screen_top) + 100.0
			_update_platform_collision(plat)

		# 3. O'NG DEVOR (WallRight) - ekranning eng o'ng qirrasiga
		elif p_name.contains("wallright") or ((p_pos.x + p_size.x) >= 900.0 and p_size.y > p_size.x and p_size.y >= 300.0):
			plat.platform_size.x = 32.0
			plat.position.x = screen_right - plat.platform_size.x
			plat.position.y = screen_top - 50.0
			plat.platform_size.y = (screen_bottom - screen_top) + 100.0
			_update_platform_collision(plat)

		# 4. POL (Floor / Ground platforms)
		else:
			var is_floor_height: bool = (p_pos.y >= 260.0)
			var touched := false

			# Agar chap devorga tutash pol bo'lsa (GroundStart / GroundFull)
			if is_floor_height and p_pos.x <= 50.0 and p_size.x > p_size.y:
				var orig_right: float = p_pos.x + p_size.x
				plat.position.x = screen_left - 50.0
				plat.platform_size.x = maxf(orig_right - plat.position.x, 100.0)
				touched = true

			# Agar o'ng devorga tutash pol bo'lsa (GroundEnd / GroundDoor / GroundFull)
			if is_floor_height and (p_pos.x + p_size.x) >= 890.0 and p_size.x > p_size.y:
				plat.platform_size.x = maxf((screen_right + 50.0) - plat.position.x, 100.0)
				touched = true

			# Agar pastki pol bo'lsa, ekran ostigacha chuqurlashtiramiz
			if (plat.position.y + plat.platform_size.y) >= 480.0:
				plat.platform_size.y = maxf(plat.platform_size.y, (screen_bottom + 100.0) - plat.position.y)
				touched = true

			if touched:
				_update_platform_collision(plat)

func _update_platform_collision(plat: Node2D) -> void:
	var col = plat.get_node_or_null("CollisionShape2D")
	if col and col.shape is RectangleShape2D:
		col.shape.size = plat.platform_size
		col.position = plat.platform_size / 2.0
	plat.queue_redraw()
