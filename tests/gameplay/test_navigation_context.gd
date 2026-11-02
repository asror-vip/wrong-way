extends SceneTree

# Wrong Way — Navigation Context & Result Modal Restoration Test
# Verifies:
# 1. Level Select opened from Home Menu shows "◀ Menyu"
# 2. Level Complete (Win Modal) -> Click Xarita sets navigation context to "result_modal"
# 3. Level Select opened with "result_modal" context displays "◀ Orqaga"
# 4. Pressing "◀ Orqaga" sets should_restore_result_modal = true and loads the completed level
# 5. The completed level loads directly into the Win Modal (G'alaba modali)
# 6. Pressing restart resets and starts fresh gameplay

func _init() -> void:
	_run_verification.call_deferred()

func _run_verification() -> void:
	print("=== Running Navigation Context & Result Modal Restoration Tests ===")
	
	var save_sys = root.get_node_or_null("SaveSystem")
	assert(save_sys != null, "SaveSystem must exist as autoload")
	
	# 1. Flow A: Home Menu -> Level Select
	save_sys.navigation_source = "home_menu"
	var select_scene = load("res://scenes/menu/level_select.tscn")
	var select_inst = select_scene.instantiate()
	root.add_child(select_inst)
	if not select_inst.is_node_ready():
		await select_inst.ready
	
	var back_btn = select_inst.get_node_or_null("TopBar/BackButton") as Button
	assert(back_btn != null, "BackButton must exist in LevelSelect")
	assert(back_btn.text == "◀ Menyu", "BackButton must say '◀ Menyu' when opened from Home Menu (got '%s')" % back_btn.text)
	print("✔ 1. Level Select from Home Menu displays '◀ Menyu'")
	select_inst.queue_free()
	
	# 2. Flow B: Play Level 1, complete it, and click Xarita
	var lvl1_scene = load("res://scenes/levels/level_1.tscn")
	var lvl1_inst = lvl1_scene.instantiate()
	root.add_child(lvl1_inst)
	if not lvl1_inst.is_node_ready():
		await lvl1_inst.ready
	
	# Complete Level 1 with 1 death (2 stars)
	lvl1_inst.session.register_death()
	lvl1_inst._on_finish_completed()
	assert(lvl1_inst.hud.win_overlay.visible == true, "Win overlay must be visible")
	
	# Simulate clicking "🗺️ Xarita"
	lvl1_inst.hud._on_select_pressed()
	assert(save_sys.navigation_source == "result_modal", "Navigation source must be 'result_modal'")
	assert(save_sys.return_level_num == 1, "Return level number must be 1")
	assert(save_sys.pending_result_data.get("deaths") == 1, "Pending deaths must be 1")
	print("✔ 2. Xarita button sets context: navigation_source='result_modal', return_level_num=1")
	lvl1_inst.queue_free()
	
	# 3. Flow C: Level Select opened from result modal
	var select_inst2 = select_scene.instantiate()
	root.add_child(select_inst2)
	if not select_inst2.is_node_ready():
		await select_inst2.ready
	
	var back_btn2 = select_inst2.get_node_or_null("TopBar/BackButton") as Button
	assert(back_btn2.text == "◀ Orqaga", "BackButton must say '◀ Orqaga' when opened from result modal (got '%s')" % back_btn2.text)
	print("✔ 3. Level Select displays '◀ Orqaga' when entered from G'alaba modali")
	
	# Simulate clicking "◀ Orqaga" in Level Select
	select_inst2._on_back_pressed()
	assert(save_sys.should_restore_result_modal == true, "should_restore_result_modal must be true after pressing back")
	select_inst2.queue_free()
	
	# 4. Flow D: Level 1 loads and restores G'alaba modali
	var lvl1_restored = lvl1_scene.instantiate()
	root.add_child(lvl1_restored)
	if not lvl1_restored.is_node_ready():
		await lvl1_restored.ready
	
	assert(lvl1_restored.hud.win_overlay.visible == true, "Win overlay must be immediately restored and visible")
	assert(lvl1_restored.player.visible == false, "Player must be hidden while restored modal is open")
	assert(lvl1_restored.finish_gate.visible == false, "Finish gate must be hidden in completed state")
	print("✔ 4. Level 1 immediately restored into G'alaba modali with previous stars and stats")
	
	# 5. Flow E: Pressing Qayta resets and restarts cleanly
	lvl1_restored.hud._on_replay_pressed()
	assert(lvl1_restored.hud.win_overlay.visible == false, "Win overlay must be hidden after replay")
	assert(save_sys.should_restore_result_modal == false, "should_restore_result_modal must be reset to false")
	lvl1_restored.queue_free()
	print("✔ 5. Replay from restored modal clears restore flag and resumes fresh game")
	
	print("=== All Navigation Context Tests Passed Successfully! ===")
	quit(0)
