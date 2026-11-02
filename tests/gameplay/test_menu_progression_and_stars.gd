extends SceneTree

# Wrong Way — Menu Flow, Star Rating & Progression Verification Suite
# Tests:
# 1. Title Screen (START, QUIT)
# 2. Home Menu (Record top-right, PLAY, LEADERBOARD, MULTIPLAYER stacked)
# 3. Level Select (Level 1 unlocked, Level 2+ locked)
# 4. Level 1: 0 deaths -> 3 stars ⭐⭐⭐ -> Level 2 unlocks!
# 5. Level 2: Features CrusherTrap
# 6. Low stars: >= 3 deaths -> 1 star ⭐☆☆ -> does not unlock Level 3

func _init() -> void:
	_run_verification.call_deferred()

func _run_verification() -> void:
	print("=== Running Wrong Way Menu Flow & Progression Tests ===")
	
	# Reset save for clean test
	var save_sys = root.get_node_or_null("SaveSystem")
	if save_sys:
		save_sys.unlocked_levels = [1]
		save_sys.level_stars = {}
		save_sys.level_best_times = {}
		save_sys.overall_best_text = "Mavjud emas"
		save_sys.save_progress()
	
	# 1. Title Screen Test
	var title_scene = load("res://scenes/menu/title_screen.tscn")
	assert(title_scene != null, "Title screen scene must exist")
	var title_inst = title_scene.instantiate()
	root.add_child(title_inst)
	if not title_inst.is_node_ready():
		await title_inst.ready
	
	var start_btn = title_inst.get_node_or_null("VBox/StartButton")
	var quit_btn = title_inst.get_node_or_null("VBox/QuitButton")
	assert(start_btn != null, "Title screen must have Start button")
	assert(quit_btn != null, "Title screen must have Quit button")
	print("✔ 1. Title Screen (START, QUIT) verified")
	title_inst.queue_free()
	
	# 2. Home Menu Test
	var home_scene = load("res://scenes/menu/home_menu.tscn")
	assert(home_scene != null, "Home menu scene must exist")
	var home_inst = home_scene.instantiate()
	root.add_child(home_inst)
	if not home_inst.is_node_ready():
		await home_inst.ready
	
	var record_lbl = home_inst.get_node_or_null("TopBar/RecordLabel")
	var play_btn = home_inst.get_node_or_null("VBox/PlayButton")
	var ldb_btn = home_inst.get_node_or_null("VBox/LeaderboardButton")
	var mp_btn = home_inst.get_node_or_null("VBox/MultiplayerButton")
	assert(record_lbl != null, "Home menu must have Top-Right Record label")
	assert(play_btn != null, "Home menu must have Play button")
	assert(ldb_btn != null, "Home menu must have Leaderboard button")
	assert(mp_btn != null, "Home menu must have Multiplayer button")
	print("✔ 2. Home Menu (Top-Right Record, stacked Play/Leaderboard/Multiplayer) verified")
	home_inst.queue_free()
	
	# 3. Level Select Test (Initial state: Level 1 unlocked, Level 2 locked)
	var select_scene = load("res://scenes/menu/level_select.tscn")
	assert(select_scene != null, "Level select scene must exist")
	var select_inst = select_scene.instantiate()
	root.add_child(select_inst)
	if not select_inst.is_node_ready():
		await select_inst.ready
	
	var grid = select_inst.get_node_or_null("ScrollContainer/Margin/LevelGrid")
	assert(grid != null, "Level select grid must exist")
	assert(grid.get_child_count() == 12, "Must display 12 levels")
	
	var btn_lvl1 = grid.get_child(0) as Button
	var btn_lvl2 = grid.get_child(1) as Button
	assert(btn_lvl1.disabled == false, "Level 1 must be unlocked initially")
	assert(btn_lvl2.disabled == true, "Level 2 must be locked initially")
	print("✔ 3. Level Select (Level 1 unlocked, Level 2 locked) verified")
	select_inst.queue_free()
	
	# 4. Level 1 Gameplay & 3 Stars Result
	var lvl1_scene = load("res://scenes/levels/level_1.tscn")
	assert(lvl1_scene != null, "Level 1 scene must exist")
	var lvl1_inst = lvl1_scene.instantiate()
	root.add_child(lvl1_inst)
	if not lvl1_inst.is_node_ready():
		await lvl1_inst.ready
	
	assert(lvl1_inst.session != null, "Level 1 GameSession must be initialized")
	assert(lvl1_inst.finish_gate != null, "Level 1 FinishGate must exist")
	
	# Complete Level 1 with 0 deaths
	lvl1_inst._on_finish_completed()
	assert(lvl1_inst.hud.win_overlay.visible == true, "Win overlay must be visible")
	
	# Check SaveSystem progress
	if save_sys:
		var stars_lvl1 = save_sys.get_level_stars(1)
		assert(stars_lvl1 == 3, "0 deaths must yield 3 stars (got %d)" % stars_lvl1)
		var is_lvl2_unlocked = save_sys.is_level_unlocked(2)
		assert(is_lvl2_unlocked == true, "Level 2 must unlock after earning 3 stars in Level 1")
		print("✔ 4. Level 1 Complete with 0 deaths awarded 3 Stars (⭐⭐⭐) and unlocked Level 2")
	
	lvl1_inst.queue_free()
	
	# 5. Level 2 Gameplay & Crusher Trap
	var lvl2_scene = load("res://scenes/levels/level_2.tscn")
	assert(lvl2_scene != null, "Level 2 scene must exist")
	var lvl2_inst = lvl2_scene.instantiate()
	root.add_child(lvl2_inst)
	if not lvl2_inst.is_node_ready():
		await lvl2_inst.ready
	
	var crusher = lvl2_inst.get_node_or_null("CrusherTrap")
	assert(crusher != null, "Level 2 must contain the CrusherTrap")
	assert(crusher.drop_distance > 0.0, "CrusherTrap must have positive drop_distance")
	print("✔ 5. Level 2 loaded cleanly with CrusherTrap obstacle")
	
	# Simulate 4 deaths in Level 2
	for i in range(4):
		lvl2_inst.session.register_death()
	assert(lvl2_inst.session.deaths == 4, "Deaths must equal 4")
	
	lvl2_inst._on_finish_completed()
	if save_sys:
		var stars_lvl2 = save_sys.get_level_stars(2)
		assert(stars_lvl2 == 1, "4 deaths must yield 1 star (got %d)" % stars_lvl2)
		var is_lvl3_unlocked = save_sys.is_level_unlocked(3)
		assert(is_lvl3_unlocked == false, "Level 3 must remain locked when only 1 star earned in Level 2")
		print("✔ 6. Level 2 with 4 deaths awarded 1 Star (⭐☆☆) and Level 3 remains locked")
	
	lvl2_inst.queue_free()
	
	print("=== All Menu Flow, Star Rating & Progression Tests Passed! ===")
	quit(0)
