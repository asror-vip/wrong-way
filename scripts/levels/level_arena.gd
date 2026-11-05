extends BaseLevel
class_name LevelArena

# Universal Level Devil Arena
# Instantiates platforms, traps, player, and exit door dynamically from data (JSON / Supabase)

const TRAP_SCENE_MAP: Dictionary = {
	"sinking_door_floor": "res://scenes/traps/sinking_door_floor.tscn",
	"jumping_spikes": "res://scenes/traps/jumping_spikes.tscn",
	"dodging_platform": "res://scenes/traps/dodging_platform.tscn",
	"falling_ceiling": "res://scenes/traps/falling_ceiling.tscn",
	"control_inverter": "res://scenes/traps/control_inverter.tscn",
	"pop_up_spikes": "res://scenes/traps/pop_up_spikes.tscn",
	"trap_floor": "res://scenes/traps/trap_floor.tscn",
	"crumbling_platform": "res://scenes/traps/crumbling_platform.tscn",
	"fake_door": "res://scenes/traps/fake_door.tscn",
	"spikes": "res://scenes/traps/spikes.tscn",
	"falling_spike": "res://scenes/traps/falling_spike.tscn",
	"spring": "res://scenes/traps/spring.tscn",
	"invisible_block": "res://scenes/traps/invisible_block.tscn",
	"moving_saw": "res://scenes/traps/moving_saw.tscn",
	"circular_saw": "res://scenes/traps/circular_saw.tscn",
	"crusher": "res://scenes/traps/crusher.tscn",
	"laser_beam": "res://scenes/traps/laser_beam.tscn",
	"rolling_boulder": "res://scenes/traps/rolling_boulder.tscn",
	"rotating_spike_ball": "res://scenes/traps/rotating_spike_ball.tscn",
}

@onready var platforms_container: Node2D = $Platforms

var solid_platform_scene = preload("res://scenes/objects/solid_platform.tscn")

func load_level_from_data(data: Dictionary) -> void:
	if data.is_empty():
		push_error("LevelArena: Bo'sh ma'lumot uzatildi!")
		return
		
	level_number = int(data.get("id", 1))
	
	# 1. Platformalarni tozalash va qayta yaratish
	if platforms_container:
		for child in platforms_container.get_children():
			child.queue_free()
			
		# Chap va o'ng chegaraviy devorlar (ekrandan chiqib ketmaslik uchun)
		_spawn_boundary_walls()
		
		var plats = data.get("platforms", [])
		for p in plats:
			var plat_inst = solid_platform_scene.instantiate()
			plat_inst.position = Vector2(float(p.get("x", 0)), float(p.get("y", 0)))
			if "platform_size" in plat_inst:
				plat_inst.platform_size = Vector2(float(p.get("w", 100)), float(p.get("h", 100)))
			platforms_container.add_child(plat_inst)

	# 2. Tuzoqlarni tozalash va faqat Level Devil uslubidagi tuzoqlarni yuklash
	if traps_container:
		for child in traps_container.get_children():
			child.queue_free()
			
		var traps_data = data.get("traps", [])
		for t in traps_data:
			var trap_type: String = str(t.get("type", ""))
			if not TRAP_SCENE_MAP.has(trap_type):
				push_warning("LevelArena: Noma'lum tuzoq turi: %s" % trap_type)
				continue
				
			var scene_path: String = TRAP_SCENE_MAP[trap_type]
			if not ResourceLoader.exists(scene_path):
				push_warning("LevelArena: Tuzoq sahnasi topilmadi: %s" % scene_path)
				continue
				
			var t_scene = load(scene_path)
			var trap_inst: Node2D = t_scene.instantiate()
			trap_inst.position = Vector2(float(t.get("x", 0)), float(t.get("y", 0)))
			
			var trap_w = float(t.get("w", 64))
			var trap_h = float(t.get("h", 64))
			if "platform_size" in trap_inst:
				trap_inst.platform_size = Vector2(trap_w, trap_h)
			if "ceiling_size" in trap_inst:
				trap_inst.ceiling_size = Vector2(trap_w, trap_h)
			if "spike_size" in trap_inst:
				trap_inst.spike_size = Vector2(trap_w, trap_h)
			if "spike_width" in trap_inst:
				trap_inst.spike_width = trap_w
			if "spring_size" in trap_inst:
				trap_inst.spring_size = Vector2(trap_w, trap_h)
			if "crusher_size" in trap_inst:
				trap_inst.crusher_size = Vector2(trap_w, trap_h)
			if "beam_length" in trap_inst and trap_h > 0:
				trap_inst.beam_length = trap_h
				
			# Qo'shimcha parametrlar (params)
			var params = t.get("params", {})
			for k in params:
				var v = params[k]
				if k == "dodge_offset" and v is Array and v.size() >= 2:
					trap_inst.set(k, Vector2(float(v[0]), float(v[1])))
				elif k in trap_inst:
					trap_inst.set(k, v)
					
			if "player_ref" in trap_inst and player:
				trap_inst.player_ref = player
				
			traps_container.add_child(trap_inst)

	# 3. O'yinchi pozitsiyasini o'rnatish
	if player:
		var spawn_arr = data.get("player_spawn", [120, 380])
		var spawn_pos := Vector2(120, 380)
		if spawn_arr is Array and spawn_arr.size() >= 2:
			spawn_pos = Vector2(float(spawn_arr[0]), float(spawn_arr[1]))
		elif spawn_arr is Vector2:
			spawn_pos = spawn_arr
		player.spawn_position = spawn_pos
		player.position = spawn_pos
		player.respawn(spawn_pos)

	# 4. Chiqish eshigi pozitsiyasi va konfiguratsiyasi
	if exit_door:
		var door_arr = data.get("door_pos", [850, 380])
		var door_pos := Vector2(850, 380)
		if door_arr is Array and door_arr.size() >= 2:
			door_pos = Vector2(float(door_arr[0]), float(door_arr[1]))
		elif door_arr is Vector2:
			door_pos = door_arr
		exit_door.position = door_pos
		exit_door.initial_x = door_pos.x
		exit_door.initial_y = door_pos.y
		
		# Qochuvchi eshik (Level Devil Runaway Door)
		var door_cfg = data.get("door_config", {})
		if "runaway_enabled" in exit_door:
			exit_door.runaway_enabled = bool(door_cfg.get("runaway", false))
			exit_door.runaway_offset_x = float(door_cfg.get("runaway_offset_x", -180.0))
			if door_cfg.has("runaway_distance"):
				exit_door.runaway_distance = float(door_cfg["runaway_distance"])
			elif door_cfg.has("trigger_distance"):
				exit_door.runaway_distance = float(door_cfg["trigger_distance"])
			else:
				exit_door.runaway_distance = 160.0
				
		if exit_door.has_method("reset_door"):
			exit_door.reset_door()

	# O'yinchi va tuzoqlar referensini qayta ulash
	_wire_traps_and_player()

func _spawn_boundary_walls() -> void:
	# Chap devor
	var left_wall = solid_platform_scene.instantiate()
	left_wall.name = "WallLeft"
	left_wall.position = Vector2(0, 0)
	if "platform_size" in left_wall:
		left_wall.platform_size = Vector2(32, 540)
	platforms_container.add_child(left_wall)
	
	# O'ng devor
	var right_wall = solid_platform_scene.instantiate()
	right_wall.name = "WallRight"
	right_wall.position = Vector2(928, 0)
	if "platform_size" in right_wall:
		right_wall.platform_size = Vector2(32, 540)
	platforms_container.add_child(right_wall)

func _wire_traps_and_player() -> void:
	if traps_container and player:
		for trap in traps_container.get_children():
			if "player_ref" in trap:
				trap.player_ref = player
				
	if player and player.has_signal("died") and not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
	if player and player.has_signal("respawned") and not player.respawned.is_connected(_on_player_respawned):
		player.respawned.connect(_on_player_respawned)
