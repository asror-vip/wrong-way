extends Node2D
class_name BaseLevel

const TrapBiomeVFX := preload("res://scripts/traps/trap_biome_vfx.gd")

@export var level_number: int = 1

@onready var player: Node2D = get_node_or_null("Player")
@onready var exit_door: Node2D = get_node_or_null("ExitDoor")
@onready var traps_container: Node2D = get_node_or_null("Traps")
@onready var paranormal_container: Node2D = get_node_or_null("Paranormal")

func _get_paranormal_nodes() -> Array[Node]:
	var out: Array[Node] = []
	var seen: Dictionary = {}
	if paranormal_container == null:
		paranormal_container = get_node_or_null("Paranormal")
	if paranormal_container:
		for c in paranormal_container.get_children():
			seen[c] = true
			out.append(c)
	if is_inside_tree():
		for p in get_tree().get_nodes_in_group("paranormal"):
			if not seen.has(p) and (p == self or is_ancestor_of(p)):
				seen[p] = true
				out.append(p)
	return out

func _ready() -> void:
	if player == null:
		player = get_node_or_null("Player")
	if exit_door == null:
		exit_door = get_node_or_null("ExitDoor")
	if traps_container == null:
		traps_container = get_node_or_null("Traps")
	if paranormal_container == null:
		paranormal_container = get_node_or_null("Paranormal")
	
	if traps_container:
		for trap in traps_container.get_children():
			if "player_ref" in trap:
				trap.player_ref = player

	for ev in _get_paranormal_nodes():
		if "level_ref" in ev:
			ev.level_ref = self
		if "player_ref" in ev:
			ev.player_ref = player
		if "exit_door_ref" in ev:
			ev.exit_door_ref = exit_door
				
	if player and player.has_signal("died") and not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
	if player and player.has_signal("respawned"):
		if not player.respawned.is_connected(_on_player_respawned):
			player.respawned.connect(_on_player_respawned)
	
	# Mark level attempted for ad logic
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("record_level_attempt"):
		sm.record_level_attempt(level_number)

	# Barcha 60 ta darajada tepada tikanli shift bo'lishini ta'minlash
	var platforms = get_node_or_null("Platforms")
	if platforms:
		var has_ceiling := false
		for p in platforms.get_children():
			if p is SolidPlatform:
				var is_c: bool = p.name.to_lower().contains("ceiling") or (
					p.global_position.y <= 30.0 and p.platform_size.x >= 200.0
					and not p.name.to_lower().contains("wall")
				)
				if is_c:
					has_ceiling = true
					break
		if not has_ceiling:
			var sp_scn = load("res://scenes/objects/solid_platform.tscn")
			if sp_scn:
				var c = sp_scn.instantiate()
				c.name = "Ceiling"
				c.position = Vector2(0, 0)
				c.platform_size = Vector2(960, 70)
				c.has_ceiling_teeth = true
				platforms.add_child(c)

func _on_player_died() -> void:
	if traps_container:
		traps_container.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	for ev in _get_paranormal_nodes():
		if ev.has_method("on_player_died"):
			ev.on_player_died()

func _on_player_respawned() -> void:
	if traps_container:
		traps_container.process_mode = Node.PROCESS_MODE_INHERIT
	reset_level_traps()

func reset_level_traps() -> void:
	TrapBiomeVFX.clear_level(self)
	if exit_door and exit_door.has_method("reset_door"):
		exit_door.reset_door()
	# Dublikat reset chaqiruvlarining oldini olish uchun yagona to'plamdan foydalanamiz
	var unique_traps: Dictionary = {}
	if traps_container:
		for trap in traps_container.get_children():
			if trap.has_method("reset_trap"):
				unique_traps[trap] = true
	var tree := get_tree()
	if tree:
		for trap in tree.get_nodes_in_group("traps"):
			if trap.has_method("reset_trap"):
				unique_traps[trap] = true
	for trap in unique_traps.keys():
		trap.reset_trap()
	if player:
		if player.has_method("clear_paranormal_modifiers"):
			player.clear_paranormal_modifiers()
		elif player.has_method("clear_inverter_zones"):
			player.clear_inverter_zones()
	for ev in _get_paranormal_nodes():
		if ev.has_method("reset_event"):
			ev.reset_event()

func _exit_tree() -> void:
	Engine.time_scale = 1.0
	var tree := get_tree()
	if tree and tree.current_scene:
		var cam := tree.current_scene.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.rotation = 0.0
	for ev in _get_paranormal_nodes():
		if ev.has_method("cleanup_global_effects"):
			ev.cleanup_global_effects()

func restart_attempt() -> void:
	reset_level_traps()
	if player:
		player.respawn()

func reset_attempt() -> void:
	restart_attempt()
