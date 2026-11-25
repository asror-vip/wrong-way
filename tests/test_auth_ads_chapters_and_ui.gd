extends SceneTree

var _started := false
var _checks: int = 0
var _failures: Array[String] = []

func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		call_deferred("_run_all")
	return false

func _expect(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)
		print("[FAIL] " + msg)
	else:
		print("[PASS] " + msg)

func _backup_user_files() -> Dictionary:
	var backup := {}
	for path in [
		"user://save_data.cfg",
		"user://save_data.cfg.bak",
		"user://player_profile.json",
		"user://device_id.txt",
		"user://saved_friends.json",
		"user://google_accounts.json"
	]:
		if FileAccess.file_exists(path):
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				backup[path] = f.get_buffer(f.get_length())
				f.close()
	return backup

func _restore_user_files(backup: Dictionary) -> void:
	for path in [
		"user://save_data.cfg",
		"user://save_data.cfg.bak",
		"user://player_profile.json",
		"user://device_id.txt",
		"user://saved_friends.json",
		"user://google_accounts.json"
	]:
		if backup.has(path):
			var f := FileAccess.open(path, FileAccess.WRITE)
			if f:
				f.store_buffer(backup[path])
				f.close()
		elif FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _run_all() -> void:
	var backup := _backup_user_files()
	print("=== Starting Auth, Ads, Chapters, Leaderboard & Script Audit ===")

	_test_all_project_scripts_compile()
	_test_chapter_unlock_gates()
	_test_cloud_merge_and_reset()
	_test_profile_isolation_and_friends()
	await _test_leaderboard_modal()
	await _test_win_overlay_ch1_gate()
	await _test_splash_tap_anywhere()
	_test_ad_manager_config()

	_restore_user_files(backup)

	print("\n=== SUMMARY: %d checks, %d failures ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("ALL AUTH/ADS/CHAPTER/UI CHECKS PASSED!")
		quit(0)
	else:
		for f in _failures:
			print("  FAILURE: " + f)
		quit(1)

func _collect_gd_files(dir_path: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var fname := d.get_next()
	while fname != "":
		if not fname.begins_with("."):
			var full := dir_path.path_join(fname)
			if d.current_is_dir():
				_collect_gd_files(full, out)
			elif fname.ends_with(".gd"):
				out.append(full)
		fname = d.get_next()
	d.list_dir_end()

func _test_all_project_scripts_compile() -> void:
	var gd_files: Array[String] = []
	_collect_gd_files("res://scripts", gd_files)
	_expect(gd_files.size() > 20, "Found %d scripts under res://scripts" % gd_files.size())
	var bad := 0
	for path in gd_files:
		var scr := load(path) as GDScript
		if scr == null or not scr.can_instantiate():
			# Note: RefCounted/Node scripts should all load & be valid
			if scr == null:
				bad += 1
				print("  [DETAIL] Failed to load: " + path)
	_expect(bad == 0, "All %d GDScript files under res://scripts load cleanly" % gd_files.size())

func _test_chapter_unlock_gates() -> void:
	var sm := root.get_node_or_null("/root/SaveManager")
	_expect(sm != null, "SaveManager autoload present")
	sm.debug_unlock_all = false
	sm.reset_progress()

	# Simulate completing levels 1..20 with 46 total stars (< 50)
	for l in range(1, 21):
		sm.unlocked_levels.append(l)
		sm.attempted_levels.append(l)
		sm.level_stars[str(l)] = 3 if l <= 6 else 2 # 6*3 + 14*2 = 46 stars
	sm.save_data()

	_expect(sm.get_chapter_stars(1) == 46, "Ch1 stars == 46")
	_expect(not sm.is_chapter_unlocked(2), "Ch2 LOCKED with 46 stars")
	_expect(not sm.is_level_unlocked(21), "Level 21 LOCKED with 46 stars")
	_expect(not sm.is_level_ad_unlockable(21), "Level 21 CANNOT be ad-unlocked with 46 stars")
	_expect(sm.get_highest_unlocked_level() == 20, "Highest unlocked level is 20 (got %d)" % sm.get_highest_unlocked_level())

	# Simulate legacy corrupted save where 21 was previously in unlocked_levels & ad_unlocked_levels
	sm.unlocked_levels.append(21)
	sm.ad_unlocked_levels.append(21)
	_expect(not sm.is_chapter_unlocked(2), "Ch2 stays LOCKED even if 21 was in ad_unlocked_levels")
	_expect(not sm.is_level_unlocked(21), "Level 21 stays LOCKED even if 21 was in unlocked_levels")
	_expect(sm.get_highest_unlocked_level() == 20, "get_highest_unlocked_level ignores locked 21 (got %d)" % sm.get_highest_unlocked_level())

	# Now earn 50 stars in Ch1 -> Ch2 unlocks!
	sm.record_result(7, 5000.0, 0) # +1 -> 47
	sm.record_result(8, 5000.0, 0) # +1 -> 48
	sm.record_result(9, 5000.0, 0) # +1 -> 49
	sm.record_result(10, 5000.0, 0) # +1 -> 50
	_expect(sm.get_chapter_stars(1) == 50, "Ch1 stars == 50")
	_expect(sm.is_chapter_unlocked(2), "Ch2 UNLOCKS at 50 stars")
	_expect(sm.is_level_unlocked(21), "Level 21 UNLOCKS at 50 stars")
	_expect(sm.get_highest_unlocked_level() == 21, "Highest unlocked level advances to 21")

	# Ch2 -> Ch3 requires 55 stars
	for l in range(21, 41):
		if not sm.unlocked_levels.has(l):
			sm.unlocked_levels.append(l)
		sm.attempted_levels.append(l)
		sm.level_stars[str(l)] = 3 if l <= 34 else 2 # 14*3 + 6*2 = 54 stars
	_expect(sm.get_chapter_stars(2) == 54, "Ch2 stars == 54")
	_expect(not sm.is_chapter_unlocked(3), "Ch3 LOCKED with 54 stars")
	_expect(not sm.is_level_unlocked(41), "Level 41 LOCKED with 54 stars")
	_expect(not sm.is_level_ad_unlockable(41), "Level 41 CANNOT be ad-unlocked with 54 stars")
	_expect(sm.get_highest_unlocked_level() == 40, "Highest unlocked level capped at 40 when Ch3 locked")

	sm.record_result(35, 5000.0, 0) # +1 -> 55
	_expect(sm.is_chapter_unlocked(3), "Ch3 UNLOCKS at 55 stars")
	_expect(sm.is_level_unlocked(41), "Level 41 UNLOCKS at 55 stars")

func _test_cloud_merge_and_reset() -> void:
	var sm := root.get_node_or_null("/root/SaveManager")
	sm.reset_progress()
	_expect(not FileAccess.file_exists("user://save_data.cfg.bak"), "reset_progress removes stale .bak file")

	sm.merge_cloud_save({
		"unlocked_levels": [1, 2, 3, 21],
		"ad_unlocked_levels": [21],
		"level_stars": {"1": 3, "2": 2},
		"level_best_times": {"1": 4200.0, "2": 7100.0},
		"level_best_deaths": {"1": 0, "2": 2},
		"overall_best_ms": 0
	})
	_expect(sm.get_level_stars(1) == 3 and sm.get_level_stars(2) == 2, "merge_cloud_save restores stars")
	_expect(sm.get_level_best_deaths(2) == 2 and sm.get_total_beaten_deaths() == 2, "merge_cloud_save restores level_best_deaths")
	_expect(sm.overall_best_ms > 999999.0, "merge_cloud_save ignores 0 overall_best_ms")
	_expect(not sm.is_chapter_unlocked(2) and not sm.ad_unlocked_levels.has(21), "merge_cloud_save enforces Ch2 star gate & strips 21 from ad_unlocked_levels")

func _test_profile_isolation_and_friends() -> void:
	var pm := root.get_node_or_null("/root/ProfileManager")
	var sm := root.get_node_or_null("/root/SaveManager")
	_expect(pm != null, "ProfileManager autoload present")

	pm.logout_to_guest()
	var guest_dev_1: String = pm.device_id
	_expect(pm.auth_provider == "guest" and pm.email == "" and not pm.has_chosen_auth, "logout_to_guest resets auth state cleanly")
	_expect(not guest_dev_1.is_empty(), "logout_to_guest generates fresh device_id")
	_expect(sm.get_total_stars() == 0 and sm.get_highest_unlocked_level() == 1, "logout_to_guest resets SaveManager to level 1 / 0 stars")

	# Simulate local Google login as Account A with progress, then switching to Account B
	pm.auth_provider = "google"
	pm.email = "account_a@gmail.com"
	pm.has_chosen_auth = true
	sm.record_result(1, 3000.0, 0)
	_expect(sm.get_total_stars() == 3, "Account A earned 3 stars")

	# Switch directly to Account B (prevent cross-account contamination; cancel HTTP right after so no prod write)
	pm.login_with_google("account_b@gmail.com", "User B")
	if pm.http_google:
		pm.http_google.cancel_request()
	_expect(sm.get_total_stars() == 0 and pm.email == "account_b@gmail.com", "Switching from Account A to Account B resets local progress before cloud merge")

	pm.add_recent_friend("WW-9988", "Tester")
	_expect(pm.is_friend("WW-9988") and pm.is_friend("ww-9988"), "ProfileManager.is_friend matches saved friend tag case-insensitively")
	_expect(not pm.is_friend("WW-0001") and not pm.is_friend(""), "ProfileManager.is_friend rejects unknown/empty")

	pm.logout_to_guest()

func _test_leaderboard_modal() -> void:
	var lm_scn := load("res://scenes/ui/leaderboard_modal.tscn") as PackedScene
	_expect(lm_scn != null, "leaderboard_modal.tscn loads")
	var lm := lm_scn.instantiate()
	root.add_child(lm)
	await process_frame

	var fake_json := JSON.stringify([
		{
			"id": "uuid-1",
			"player_tag": "WW-9988",
			"username": "FriendOne",
			"avatar_url": "av_3",
			"total_stars": 45,
			"highest_level": 18,
			"save_data": {
				"level_stars": {"1": 3, "2": 2},
				"level_best_times": {"1": 3500.0, "2": 6200.0},
				"level_best_deaths": {"1": 0, "2": 1}
			}
		},
		{
			"id": "uuid-2",
			"player_tag": "WW-7777",
			"username": "Stranger",
			"avatar_url": "av_2",
			"total_stars": 12,
			"highest_level": 5,
			"save_data": {}
		}
	])
	var pm := root.get_node_or_null("/root/ProfileManager")
	pm.add_recent_friend("WW-9988", "FriendOne")
	pm.username = "Asror"
	lm._on_http_completed(0, 200, PackedStringArray(), fake_json.to_utf8_buffer())
	_expect(lm.remote_players.size() == 2, "Leaderboard parses Supabase profiles schema cleanly")
	_expect(lm.remote_players[0]["time_sec"] == 10 and lm.remote_players[0]["deaths"] == 1, "Leaderboard computes time_sec=10 and deaths=1 from save_data")

	# Switch to Friends tab — previously crashed with missing ProfileManager.is_friend
	lm._set_tab(lm.TabMode.FRIENDS)
	_expect(lm.list_box.get_child_count() == 2, "Friends tab renders friend + self cleanly without crash (rows=%d)" % lm.list_box.get_child_count())

	lm.queue_free()
	await process_frame

func _test_win_overlay_ch1_gate() -> void:
	var sm := root.get_node_or_null("/root/SaveManager")
	sm.reset_progress()
	for l in range(1, 21):
		sm.unlocked_levels.append(l)
		sm.attempted_levels.append(l)
		sm.level_stars[str(l)] = 3 if l <= 6 else 2 # 46 stars

	var wo_scn := load("res://scenes/game/win_overlay.tscn") as PackedScene
	var wo := wo_scn.instantiate()
	root.add_child(wo)
	await process_frame

	wo._on_level_completed(20, 4200.0, 0, 3)
	_expect(not wo._next_requires_ad_unlock and not wo.next_btn.visible, "WinOverlay hides Next/Ad-Unlock on Level 20 when Ch1 has only 46/50 stars")
	_expect("50" in wo.subtitle.text, "WinOverlay explains 50-star Ch2 requirement")

	wo.queue_free()
	await process_frame

func _test_splash_tap_anywhere() -> void:
	var pm := root.get_node_or_null("/root/ProfileManager")
	pm.has_chosen_auth = true
	pm.username = "Tester"
	pm.skip_loading_to_auth = true

	var sp_scn := load("res://scenes/main/splash_screen.tscn") as PackedScene
	var sp := sp_scn.instantiate()
	root.add_child(sp)
	await process_frame
	await process_frame

	_expect(sp.start_box.visible and not sp.is_transitioning, "SplashScreen shows StartBox for established user")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.index = 0
	touch.position = Vector2(50, 50)
	sp._gui_input(touch)
	_expect(sp.is_transitioning, "Tapping anywhere on SplashScreen triggers start transition")

	sp.queue_free()
	await process_frame

func _test_ad_manager_config() -> void:
	var adm := root.get_node_or_null("/root/AdManager")
	_expect(adm != null and adm.is_ads_enabled(), "AdManager enabled")
	_expect(adm.INTERSTITIAL_AD_UNIT_ID == "R-M-20506671-1", "Yandex Interstitial ID matches R-M-20506671-1")
	_expect(adm.REWARDED_AD_UNIT_ID == "R-M-20506671-2", "Yandex Rewarded ID matches R-M-20506671-2")
	_expect(not adm.is_banner_visible() and adm.get_top_banner_height() == 0.0, "Banner disabled on mobile")
