extends SceneTree

# Wrong Way — Ad System (Banner + Rewarded Ad) Verification
# Tests:
# 1. AdManager autoload initialization & banner visibility
# 2. Level 2 has NO ad icon before Level 1 is attempted
# 3. After attempting Level 1 without 2 stars, Level 2 becomes ad-unlockable (shows ad icon)
# 4. Level 3 remains locked without ad icon until Level 2 is attempted
# 5. Watching rewarded ad unlocks Level 2 permanently
# 6. Gameplay level hides banner; win overlay restores banner

func _init() -> void:
	_run_verification.call_deferred()

func _run_verification() -> void:
	print("=== Running Ad System (Banner & Rewarded Unlock) Verification ===")
	
	var adm = root.get_node_or_null("AdManager")
	assert(adm != null, "AdManager must be registered as autoload singleton")
	assert(adm.is_banner_visible() == true, "Banner should be visible by default in menus")
	print("✔ 1. AdManager autoload initialized with top banner")
	
	var save_sys = root.get_node_or_null("SaveSystem")
	assert(save_sys != null, "SaveSystem must exist")
	
	# Reset save for clean test
	save_sys.unlocked_levels = [1]
	save_sys.ad_unlocked_levels = []
	save_sys.attempted_levels = []
	save_sys.level_stars = {}
	save_sys.level_best_times = {}
	save_sys.save_progress()
	
	# 2. Before Level 1 is attempted:
	assert(save_sys.is_level_unlocked(1) == true, "Level 1 must be unlocked")
	assert(save_sys.is_level_unlocked(2) == false, "Level 2 must be locked")
	assert(save_sys.is_level_ad_unlockable(2) == false, "Level 2 must NOT have ad icon before Level 1 is attempted")
	print("✔ 2. Level 2 has NO ad icon initially (clean player state)")
	
	# 3. Player attempts Level 1 (e.g. enters level, fails/dies or gets 1 star):
	save_sys.record_level_attempt(1)
	assert(save_sys.is_level_ad_unlockable(2) == true, "Level 2 must now be ad-unlockable after attempting Level 1")
	assert(save_sys.is_level_ad_unlockable(3) == false, "Level 3 must still NOT have ad icon (only Level 2)")
	print("✔ 3. Level 2 now shows '🎬 Ochish' ad icon after struggling on Level 1")
	
	# 4. Check LevelSelect UI rendering:
	var select_scene = load("res://scenes/menu/level_select.tscn")
	var select_inst = select_scene.instantiate()
	root.add_child(select_inst)
	if not select_inst.is_node_ready():
		await select_inst.ready
	
	var grid = select_inst.get_node_or_null("ScrollContainer/Margin/LevelGrid")
	assert(grid != null, "Level grid must exist")
	var btn_lvl1 = grid.get_child(0) as Button
	var btn_lvl2 = grid.get_child(1) as Button
	var btn_lvl3 = grid.get_child(2) as Button
	
	assert(btn_lvl1.disabled == false, "Level 1 must be enabled")
	assert("LEVEL 1" in btn_lvl1.text, "Level 1 button text verified")
	
	assert(btn_lvl2.disabled == false, "Level 2 ad-unlock button must be clickable")
	assert("🎬 Ochish" in btn_lvl2.text, "Level 2 button must display '🎬 Ochish' ad icon (got '%s')" % btn_lvl2.text)
	
	assert(btn_lvl3.disabled == true, "Level 3 button must be locked")
	assert("🔒 Qulf" in btn_lvl3.text, "Level 3 button must display '🔒 Qulf'")
	print("✔ 4. LevelSelect UI displays Level 2 with '🎬 Ochish' and Level 3 with '🔒 Qulf'")
	select_inst.queue_free()
	
	# 5. Player watches rewarded ad to unlock Level 2:
	save_sys.unlock_level_via_ad(2)
	assert(save_sys.is_level_unlocked(2) == true, "Level 2 must now be unlocked via ad")
	assert(save_sys.is_level_ad_unlockable(2) == false, "Level 2 is now unlocked, so ad icon is removed")
	print("✔ 5. Rewarded ad watched: Level 2 permanently unlocked")
	
	# 6. Check banner hiding during gameplay and showing in HUD win overlay:
	var lvl1_scene = load("res://scenes/levels/level_1.tscn")
	var lvl1_inst = lvl1_scene.instantiate()
	root.add_child(lvl1_inst)
	if not lvl1_inst.is_node_ready():
		await lvl1_inst.ready
	
	assert(adm.is_banner_visible() == false, "Banner must be hidden during active gameplay")
	
	# Complete level -> Win modal appears -> Banner returns
	lvl1_inst._on_finish_completed()
	assert(adm.is_banner_visible() == true, "Banner must be visible when Victory modal appears")
	print("✔ 6. Banner hides during gameplay and shows on Victory modal")
	lvl1_inst.queue_free()
	
	print("=== All Ad System Tests Passed Successfully! ===")
	quit(0)

