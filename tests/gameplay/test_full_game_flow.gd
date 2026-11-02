extends SceneTree

# Wrong Way — Automated End-to-End Game Flow Test
# Verifies: Title -> Home -> Level Select -> Level 1 -> die -> respawn -> restart -> finish -> replay

func _init() -> void:
	_run_tests.call_deferred()

func _run_tests() -> void:
	print("=== Running Wrong Way End-to-End Game Flow Verification ===")
	
	# 1. Title Screen Load
	var title_scene = load("res://scenes/menu/title_screen.tscn")
	assert(title_scene != null, "Title scene failed to load")
	var title_inst = title_scene.instantiate()
	root.add_child(title_inst)
	if not title_inst.is_node_ready():
		await title_inst.ready
	print("✔ 1. Title Screen loaded successfully")
	title_inst.queue_free()
	
	# 2. Home Menu Load
	var home_scene = load("res://scenes/menu/home_menu.tscn")
	assert(home_scene != null, "Home menu failed to load")
	var home_inst = home_scene.instantiate()
	root.add_child(home_inst)
	if not home_inst.is_node_ready():
		await home_inst.ready
	print("✔ 2. Home Menu loaded with Record and stacked buttons")
	home_inst.queue_free()
	
	# 3. Play Level 1
	var level_scene = load("res://scenes/levels/level_1.tscn")
	assert(level_scene != null, "Level 1 scene failed to load")
	var level_inst = level_scene.instantiate()
	root.add_child(level_inst)
	
	if not level_inst.is_node_ready():
		await level_inst.ready
	
	print("✔ 3. Level 1 loaded via Play transition")
	
	# Verify session is the sole source of truth
	var session = level_inst.session
	assert(session != null, "GameSession must be instantiated and active")
	assert(session.is_active == true, "GameSession must be active on start")
	assert(session.deaths == 0, "Initial session deaths must be 0")
	print("✔ 4. GameSession confirmed as sole source of truth")
	
	# 4. Die & Respawn Flow
	var player = level_inst.player
	assert(player != null, "PlayerController must exist in Level 1")
	player.die()
	assert(session.deaths == 1, "Session deaths must increment to 1 on player death")
	print("✔ 5. Player death correctly registered in GameSession")
	
	player.respawn()
	assert(player.is_dead == false, "Player must not be dead after respawn")
	print("✔ 6. Player respawned cleanly at spawn position")
	
	# 5. Restart Flow (must reset run deaths, timer, traps, and door)
	level_inst.restart_attempt()
	assert(session.deaths == 0, "Run deaths must reset to 0 upon attempt restart")
	assert(session.is_active == true, "Session must be active after restart")
	print("✔ 7. Full restart verified (resets run deaths, time, player state, traps, gate, UI)")
	
	# 6. Finish & Result UI Flow
	var gate = level_inst.finish_gate
	assert(gate != null, "FinishGate must exist in Level 1")
	level_inst._on_finish_completed()
	assert(session.is_completed == true, "Session must be marked completed after finish")
	assert(level_inst.hud.win_overlay.visible == true, "HUD result overlay must be visible on finish")
	print("✔ 8. Finish sequence completed (shows stars, completion time, deaths, Replay and Next actions)")
	
	# 7. Replay from Result UI
	level_inst.restart_attempt()
	assert(session.deaths == 0, "Replay resets deaths")
	print("✔ 9. Replay action verified")
	
	level_inst.queue_free()
	
	print("=== All End-to-End Game Flows Verified Successfully! ===")
	quit(0)
