extends SceneTree

const OfflineOverlayScript := preload("res://scripts/ui/offline_overlay.gd")
const FakeWinOverlayScript := preload("res://scripts/paranormal/fake_win_shatter_overlay.gd")

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
	print("=== Starting Boost Features & Shattering-Mirror Fake Win Audit ===")

	_test_icons_sounds_and_locales()
	await _test_offline_overlays()
	await _test_settings_mobile_desktop_separation()
	await _test_control_customizer_overhaul()
	await _test_level1_tutorial_and_trap_toast()
	await _test_main_menu_double_back_exit()
	await _test_shattering_mirror_fake_victory()
	_test_huawei_store_pack_assets()

	_restore_user_files(backup)

	print("\n=== BOOST SUMMARY: %d checks, %d failures ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("ALL BOOST FEATURE CHECKS PASSED!")
		quit(0)
	else:
		for f in _failures:
			print("  FAILURE: " + f)
		quit(1)

func _test_icons_sounds_and_locales() -> void:
	var icf := root.get_node_or_null("/root/IconFactory")
	var snd := root.get_node_or_null("/root/SoundManager")
	var loc := root.get_node_or_null("/root/LocaleManager")

	_expect(icf != null and icf.get_icon("wifi_off", 1.5) != null, "IconFactory provides crisp wifi_off SVG texture")
	_expect(icf != null and icf.get_icon("restart_dark", 1.0) != null, "IconFactory provides restart_dark SVG texture")
	_expect(snd != null and snd.players.has("mirror_shatter"), "SoundManager registers procedural mirror_shatter SFX")
	var ms_player := snd.players.get("mirror_shatter") as AudioStreamPlayer
	var ms_wav := ms_player.stream as AudioStreamWAV if ms_player else null
	_expect(ms_wav != null and ms_wav.data.size() > 16000, "mirror_shatter WAV has non-empty 16-bit audio buffer (%d bytes)" % (ms_wav.data.size() if ms_wav else 0))

	var req_keys := [
		"offline_title", "offline_desc", "btn_retry",
		"controls_title_mobile", "controls_desc_mobile",
		"controls_title_desktop", "controls_desc_desktop",
		"customizer_size", "exit_press_again",
		"tut_step_move_mobile", "tut_step_move_pc",
		"tut_step_jump_mobile", "tut_step_jump_pc",
		"tut_step_dash_mobile", "tut_step_dash_pc",
		"tut_step_door", "tut_trap_floor_toast"
	]
	var prev_lang: String = loc.current_language
	var missing := 0
	for lang in ["uz", "ru", "en", "tr"]:
		loc.current_language = lang
		for k in req_keys:
			var val: String = loc.t(k)
			if val == k or val.strip_edges().is_empty():
				missing += 1
				print("  [DETAIL] Missing '%s' in '%s'" % [k, lang])
	loc.current_language = prev_lang
	_expect(missing == 0, "All 4 languages (uz/ru/en/tr) define all %d new Boost locale keys" % req_keys.size())

func _test_offline_overlays() -> void:
	_expect(OfflineOverlayScript.is_network_error("OFFLINE"), "OfflineOverlay classifies OFFLINE as network error")
	_expect(OfflineOverlayScript.is_network_error("HTTP 0 connection timeout"), "OfflineOverlay classifies timeout/HTTP 0 as network error")
	_expect(not OfflineOverlayScript.is_network_error("Kirish bekor qilindi"), "OfflineOverlay does NOT classify user cancel as network error")
	_expect(not OfflineOverlayScript.is_network_error("Google orqali kirish vaqti tugadi (Timeout)"), "OfflineOverlay does NOT classify OAuth abandonment timeout as offline")
	_expect(not OfflineOverlayScript.is_network_error(""), "OfflineOverlay does NOT classify empty string as network error")

	var pm := root.get_node_or_null("/root/ProfileManager")
	var gas := root.get_node_or_null("/root/GoogleAuthService")

	# GoogleAuthService network check failure emits OFFLINE
	var gas_err_box := [""]
	var cb := func(err: String): gas_err_box[0] = err
	gas.auth_failed.connect(cb)
	gas._on_net_check_completed(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())
	gas.auth_failed.disconnect(cb)
	_expect(gas_err_box[0] == "OFFLINE", "GoogleAuthService emits OFFLINE when network probe fails")

	# 1. LeaderboardModal offline overlay on failed HTTP & retry
	root.size = Vector2i(960, 540)
	var lm := (load("res://scenes/ui/leaderboard_modal.tscn") as PackedScene).instantiate()
	root.add_child(lm)
	await process_frame
	pm.auth_provider = "google"
	pm.email = "offline_test@gmail.com"
	pm.username = "OfflineTester"
	lm.open()
	if lm.http_request:
		lm.http_request.cancel_request()
		lm.is_fetching = false
	await process_frame

	lm._on_http_completed(HTTPRequest.RESULT_CANT_RESOLVE, 0, PackedStringArray(), PackedByteArray())
	_expect(lm.offline_overlay != null and lm.offline_overlay.visible, "LeaderboardModal shows frosted OfflineOverlay on network failure")
	_expect(lm.offline_overlay.icon_rect.texture != null, "OfflineOverlay renders wifi_off icon texture")

	# Retry hides overlay and initiates fresh fetch
	lm.offline_overlay._on_retry_pressed()
	_expect(not lm.offline_overlay.visible, "Clicking Retry on Leaderboard OfflineOverlay hides overlay")
	if lm.http_request:
		lm.http_request.cancel_request()
		lm.is_fetching = false

	# Guest Google Sign-In offline failure shows OfflineOverlay on LeaderboardModal
	pm.logout_to_guest()
	lm.open()
	await process_frame
	gas.auth_failed.emit("OFFLINE")
	_expect(lm.offline_overlay.visible, "LeaderboardModal shows OfflineOverlay when Google Sign-In fails offline")

	# Closing LeaderboardModal cancels in-flight fetch and ignores late HTTP failure callbacks
	lm.is_fetching = true
	lm.close()
	_expect(not lm.is_fetching, "LeaderboardModal.close() resets is_fetching so reopen fetches cleanly")
	lm._on_http_completed(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())
	_expect(not lm.offline_overlay.visible, "Late HTTP failure while LeaderboardModal is closed does NOT show OfflineOverlay")
	lm.queue_free()
	await process_frame

	# 2. SplashScreen offline overlay on Google Sign-In offline failure
	pm.has_chosen_auth = false
	pm.skip_loading_to_auth = true
	var sp := (load("res://scenes/main/splash_screen.tscn") as PackedScene).instantiate()
	root.add_child(sp)
	await process_frame
	sp._on_google_pressed()
	if gas._net_check_http:
		gas._net_check_http.cancel_request()
		gas._checking_network = false
	gas.auth_failed.emit("OFFLINE")
	_expect(sp.offline_overlay != null and sp.offline_overlay.visible, "SplashScreen shows OfflineOverlay on offline Google Sign-In failure")
	sp.offline_overlay._on_close_pressed()
	_expect(not sp.offline_overlay.visible, "SplashScreen OfflineOverlay dismisses cleanly via Close button")
	_expect(sp.auth_hint != null and not sp.auth_hint.text.contains("tanlang"), "Dismissing SplashScreen OfflineOverlay restores default auth_hint text")
	sp.queue_free()
	await process_frame

	# 3. ProfileModal offline overlay on Google Sign-In offline failure
	var pr := (load("res://scenes/ui/profile_modal.tscn") as PackedScene).instantiate()
	root.add_child(pr)
	await process_frame
	pr.open()
	gas.auth_failed.emit("OFFLINE")
	_expect(pr.offline_overlay != null and pr.offline_overlay.visible, "ProfileModal shows OfflineOverlay on offline Google Sign-In failure")
	pr.queue_free()
	await process_frame

func _test_settings_mobile_desktop_separation() -> void:
	var loc := root.get_node_or_null("/root/LocaleManager")
	var prev_lang: String = loc.current_language
	var sm_modal := (load("res://scenes/main/settings_modal.tscn") as PackedScene).instantiate()
	root.add_child(sm_modal)
	await process_frame
	sm_modal.open()

	# Mobile mode across all 4 languages: ZERO keyboard shortcuts, Customize Controls visible
	sm_modal.set_mobile_mode_override(1)
	var mob_clean := true
	for lang in ["uz", "ru", "en", "tr"]:
		loc.current_language = lang
		sm_modal._update_ui_texts()
		var desc: String = sm_modal.controls_desc.text
		if desc.contains("A / D") or desc.contains("Space") or desc.contains("Shift") or desc.contains("F11") or desc.contains("Esc"):
			mob_clean = false
			print("  [DETAIL] Mobile Settings leaked keyboard shortcut in %s: %s" % [lang, desc])
		if not sm_modal.customize_controls_btn.visible:
			mob_clean = false
	_expect(mob_clean, "SettingsModal in mobile mode hides ALL keyboard shortcuts & shows Customize Controls across all 4 languages")

	# Desktop mode across all 4 languages: shows keyboard shortcuts, Customize Controls hidden
	sm_modal.set_mobile_mode_override(0)
	var desk_clean := true
	for lang in ["uz", "ru", "en", "tr"]:
		loc.current_language = lang
		sm_modal._update_ui_texts()
		var desc: String = sm_modal.controls_desc.text
		if not desc.contains("A / D") or not desc.contains("Shift") or not desc.contains("F11"):
			desk_clean = false
			print("  [DETAIL] Desktop Settings missing keyboard shortcuts in %s: %s" % [lang, desc])
		if sm_modal.customize_controls_btn.visible:
			desk_clean = false
	_expect(desk_clean, "SettingsModal in desktop mode shows keyboard shortcuts & hides Customize Controls across all 4 languages")

	# Android Back closes SettingsModal when ControlCustomizer is hidden
	sm_modal.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_expect(not sm_modal.visible, "NOTIFICATION_WM_GO_BACK_REQUEST closes SettingsModal cleanly")

	loc.current_language = prev_lang
	sm_modal.queue_free()
	await process_frame

func _test_control_customizer_overhaul() -> void:
	var sm := root.get_node_or_null("/root/SaveManager")
	var loc := root.get_node_or_null("/root/LocaleManager")
	var prev_lang: String = loc.current_language

	sm.save_touch_layout({"left": Vector2(60, 410), "right": Vector2(170, 410), "dash": Vector2(720, 410), "jump": Vector2(830, 410)}, 1.15)

	root.size = Vector2i(960, 540)
	var cc := (load("res://scenes/ui/control_customizer.tscn") as PackedScene).instantiate()
	root.add_child(cc)
	await process_frame
	cc.open()
	await process_frame
	await process_frame

	# 1. Verify TopBar zero overlap across all 4 languages and narrow/wide viewports
	var no_overlap := true
	var size_loc_ok := true
	for vp_sz in [Vector2i(960, 540), Vector2i(800, 450), Vector2i(1180, 540)]:
		root.size = vp_sz
		cc.size = Vector2(vp_sz)
		for lang in ["uz", "ru", "en", "tr"]:
			loc.current_language = lang
			cc._update_texts()
			await process_frame
			var r_title: Rect2 = cc.title_box.get_global_rect()
			var r_size: Rect2 = cc.size_box.get_global_rect()
			var r_btn: Rect2 = cc.btn_box.get_global_rect()
			if r_title.intersects(r_size) or r_size.intersects(r_btn) or r_title.intersects(r_btn):
				no_overlap = false
				print("  [DETAIL] TopBar overlap at %s/%s: title=%s size=%s btn=%s" % [vp_sz, lang, r_title, r_size, r_btn])
			if cc.size_title_lbl.text != loc.t("customizer_size"):
				size_loc_ok = false
	root.size = Vector2i(960, 540)
	cc.size = Vector2(960, 540)
	await process_frame
	_expect(no_overlap, "ControlCustomizer TopBar (TitleBox / SizeBox / BtnBox) has ZERO overlap across all 4 languages & widths")
	_expect(size_loc_ok, "ControlCustomizer 'Size:' label is localized via LocaleManager across all 4 languages")

	# 2. Fast global touch drag + clamping + emulated mouse suppression
	var start_center: Vector2 = cc.drag_left.position + cc.drag_left.size * 0.5
	var st_down := InputEventScreenTouch.new()
	st_down.index = 2
	st_down.pressed = true
	st_down.position = start_center
	root.push_input(st_down)
	_expect(cc.dragging_node == cc.drag_left and cc._drag_finger_index == 2, "ControlCustomizer starts finger-indexed touch drag cleanly")

	# Emulated mouse motion while finger is dragging must be ignored
	var emu_mm := InputEventMouseMotion.new()
	emu_mm.device = InputEvent.DEVICE_ID_EMULATION
	emu_mm.position = Vector2(500, 200)
	root.push_input(emu_mm)
	_expect(cc.drag_left.position.distance_to(Vector2(60, 410)) < 2.0, "ControlCustomizer ignores touch-emulated mouse events during touch drag")

	# Ultra-fast jump far outside top/left bounds -> stays clamped inside safe area below TopBar
	var st_drag := InputEventScreenDrag.new()
	st_drag.index = 2
	st_drag.position = Vector2(-200.0, -100.0)
	root.push_input(st_drag)
	_expect(cc.drag_left.position.x >= 10.0 and cc.drag_left.position.y >= 64.0, "Fast drag clamps DragLeft strictly within safe bounds below TopBar (pos=%s)" % cc.drag_left.position)

	# Drag to valid spot (320, 260) and release
	var st_drag2 := InputEventScreenDrag.new()
	st_drag2.index = 2
	st_drag2.position = Vector2(360.0, 300.0)
	root.push_input(st_drag2)
	var st_up := InputEventScreenTouch.new()
	st_up.index = 2
	st_up.pressed = false
	st_up.position = Vector2(360.0, 300.0)
	root.push_input(st_up)
	_expect(cc.dragging_node == null and cc.drag_left.position.x > 250.0, "ControlCustomizer completes fast drag & releases cleanly")

	# 3. Reset must NOT overwrite SaveManager before Save! Close discards unsaved Reset
	cc._on_reset_pressed()
	_expect(is_equal_approx(sm.touch_button_scale, 1.15) and not sm.custom_touch_layout.is_empty(), "Reset button previews defaults WITHOUT prematurely writing to SaveManager")
	cc.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_expect(not cc.visible, "NOTIFICATION_WM_GO_BACK_REQUEST closes ControlCustomizer")
	_expect(is_equal_approx(sm.touch_button_scale, 1.15) and sm.get_touch_pos("left", Vector2.ZERO).distance_to(Vector2(60, 410)) < 1.0, "Canceling after Reset preserves previously saved touch layout & scale")

	# 4. Open again, Reset, and Save -> persists clean defaults
	cc.open()
	cc._on_reset_pressed()
	cc._on_save_pressed()
	_expect(not cc.visible and is_equal_approx(sm.touch_button_scale, 1.0) and sm.custom_touch_layout.is_empty(), "Saving after Reset persists default touch layout & scale=1.0")

	# 5. Overlapping widgets pick visually top-most (highest child index) widget
	cc.open()
	cc.drag_left.position = cc.drag_jump.position
	cc.move_child(cc.drag_left, cc.get_child_count() - 1)
	if cc.top_bar:
		cc.move_child(cc.top_bar, cc.get_child_count() - 1)
	var picked_top: Control = cc._pick_widget_at(cc.drag_left.position + cc.drag_left.size * 0.5)
	_expect(picked_top == cc.drag_left, "ControlCustomizer picks visually top-most widget when buttons overlap")

	# 6. ESC closes ControlCustomizer
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	root.push_input(esc)
	await process_frame
	_expect(not cc.visible, "KEY_ESCAPE closes ControlCustomizer")

	loc.current_language = prev_lang
	cc.queue_free()
	await process_frame

func _test_level1_tutorial_and_trap_toast() -> void:
	var sm := root.get_node_or_null("/root/SaveManager")
	var gm := root.get_node_or_null("/root/GameManager")
	var loc := root.get_node_or_null("/root/LocaleManager")
	var prev_lang: String = loc.current_language

	sm.reset_progress()
	_expect(not sm.tutorial_completed, "SaveManager.tutorial_completed defaults to false after reset_progress()")

	gm.current_level_id = 1
	gm.is_duel_mode = false
	gm.is_custom_editor_mode = false
	gm.is_level_running = true

	var hud := (load("res://scenes/game/game_hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame

	_expect(hud.is_tutorial_active() and hud.get_tutorial_step() == 0, "Level 1 activates interactive onboarding tutorial at step 0 (Move)")
	_expect(hud._tutorial_banner.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Tutorial banner is non-blocking (MOUSE_FILTER_IGNORE)")

	# Desktop PC mode checks all 4 position thresholds
	hud.set_mobile_mode_override(0)
	hud.evaluate_tutorial_for_x(100.0)
	_expect(hud.get_tutorial_step() == 0 and hud._tutorial_badge_lbl.text == "A / D" and not hud._tutorial_pulse_overlay.visible, "Desktop Step 0 (x<155): Move hint + [A / D] badge, no mobile pulse")
	hud.evaluate_tutorial_for_x(165.0)
	_expect(hud.get_tutorial_step() == 1 and hud._tutorial_badge_lbl.text == "SPACE", "Desktop Step 1 (x>=155): Jump hint + [SPACE] badge")
	hud.evaluate_tutorial_for_x(310.0)
	_expect(hud.get_tutorial_step() == 2 and hud._tutorial_badge_lbl.text == "SHIFT", "Desktop Step 2 (x>=290): Dash hint + [SHIFT] badge")
	hud.evaluate_tutorial_for_x(720.0)
	_expect(hud.get_tutorial_step() == 3 and hud._tutorial_text_lbl.text == loc.t("tut_step_door"), "Desktop Step 3 (x>=700): 2-star unlock rule near door")

	# Mobile mode shows pulsing touch rings for steps 0..2 and hides on step 3
	hud.set_mobile_mode_override(1)
	hud.evaluate_tutorial_for_x(100.0)
	_expect(hud._tutorial_pulse_overlay.visible and hud._tutorial_text_lbl.text == loc.t("tut_step_move_mobile"), "Mobile Step 0 shows touch pulsing overlay + mobile Move text")
	hud.evaluate_tutorial_for_x(720.0)
	_expect(not hud._tutorial_pulse_overlay.visible, "Mobile Step 3 near door hides button pulse overlay")

	# Bonus #3: Real Level 1 TrapFloorMid automatically triggers playful toast on first fall
	loc.current_language = "uz"
	var lvl1 := (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(lvl1)
	await physics_frame
	var trap_mid := lvl1.get_node_or_null("Traps/TrapFloorMid")
	_expect(trap_mid != null, "Level 1 contains Traps/TrapFloorMid node")
	if trap_mid:
		trap_mid.is_triggered = true
		hud._update_tutorial_runtime(0.016)
	_expect(hud.is_trap_toast_visible() and hud._trap_toast_lbl.text == loc.t("tut_trap_floor_toast"), "Level 1 TrapFloorMid trigger automatically renders localized playful toast")
	lvl1.queue_free()
	await process_frame

	# Completing Level 1 persists tutorial_completed = true and hides tutorial
	sm.record_result(1, 5200.0, 0)
	_expect(sm.tutorial_completed, "Beating Level 1 sets SaveManager.tutorial_completed = true")
	sm.load_data()
	_expect(sm.tutorial_completed, "SaveManager.tutorial_completed persists across load_data()")

	hud._on_level_started(1)
	_expect(not hud.is_tutorial_active(), "Level 1 tutorial stays hidden once tutorial_completed == true")

	loc.current_language = prev_lang
	hud.queue_free()
	await process_frame

func _test_main_menu_double_back_exit() -> void:
	_expect(not is_quit_on_go_back(), "SceneTree.is_quit_on_go_back() is disabled so Android Back never force-quits app")
	var loc := root.get_node_or_null("/root/LocaleManager")
	var mm := (load("res://scenes/main/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(mm)
	await process_frame
	mm._suppress_quit_for_test = true

	var exit_count := [0]
	mm.exit_confirmed.connect(func(): exit_count[0] += 1)

	# When a modal is open, Android Back must NOT show exit toast or quit
	mm.settings_modal.open()
	mm.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_expect(exit_count[0] == 0 and not mm._exit_toast_panel.visible, "MainMenu ignores double-back exit when SettingsModal is open")
	mm.settings_modal.close()

	# 1st Back press with no modal open shows toast and does NOT exit
	mm.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_expect(exit_count[0] == 0 and mm._exit_toast_panel.visible and mm._exit_toast_lbl.text == loc.t("exit_press_again"), "1st Android Back on MainMenu shows localized exit toast without quitting")

	# If >2s elapsed, another Back press resets timer and does NOT exit
	mm._last_back_press_ms = Time.get_ticks_msec() - 2500
	mm.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_expect(exit_count[0] == 0 and mm._exit_toast_panel.visible, "Back press after >2s window resets toast without quitting")

	# 2nd Back press within 2s confirms exit!
	mm.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_expect(exit_count[0] == 1, "2nd Android Back within 2 seconds confirms exit")

	mm.queue_free()
	await process_frame

func _test_shattering_mirror_fake_victory() -> void:
	var loc := root.get_node_or_null("/root/LocaleManager")
	var lvl12 := (load("res://scenes/levels/level_12.tscn") as PackedScene).instantiate()
	root.add_child(lvl12)
	for _i in range(4):
		await physics_frame

	var pe := lvl12.get_node_or_null("Paranormal/ParanormalEvent")
	var p := lvl12.get_node_or_null("Player")
	var ed := lvl12.get_node_or_null("ExitDoor")
	_expect(pe != null and pe._fake_win_overlay != null, "Level 12 ParanormalEvent instantiates FakeWinShatterOverlay")
	_expect(ed != null and not ed.visible and not ed.monitoring, "Before fake win, Level 12 real ExitDoor is hidden & non-monitoring")

	# Trigger fake victory by entering FakeWinDoor
	p.is_invulnerable = false
	pe._on_fake_win_entered(p)
	await process_frame
	var ov = pe._fake_win_overlay
	_expect(ov.visible and ov.state == FakeWinOverlayScript.State.SHOWING, "Entering FakeWinDoor opens ultra-convincing FakeWinShatterOverlay")
	_expect(p.is_entering_door, "Player is cleanly paused while viewing FakeWinShatterOverlay")
	_expect(ov._win_title.text == loc.t("level_complete"), "FakeWinShatterOverlay title matches real WinOverlay localized title")
	_expect(ov._star_box.get_child_count() == 3, "FakeWinShatterOverlay displays 3 glowing white stars")
	_expect(ov._next_btn.visible and ov._replay_btn.visible, "FakeWinShatterOverlay shows Next & Replay buttons identical to WinOverlay")

	# Must NOT auto-glitch away while player admires it
	ov._process(0.65)
	_expect(ov.state == FakeWinOverlayScript.State.SHOWING and ov._fake_win_root.visible, "FakeWinShatterOverlay stays convincing until player actually touches screen")

	# Verify GameHUD releases held touch controls and blocks touch bleed-through while FakeWinShatterOverlay is open
	var hud := (load("res://scenes/game/game_hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	hud.set_mobile_mode_override(1)
	hud._touch_fingers[0] = "move_right"
	hud._sync_touch_actions()
	hud._process(0.016)
	_expect(hud._active_touch_actions.is_empty(), "GameHUD immediately releases held touch actions when FakeWinShatterOverlay is showing")
	var bleed_tap := InputEventScreenTouch.new()
	bleed_tap.index = 1
	bleed_tap.pressed = true
	bleed_tap.position = hud.jump_btn.position + hud.jump_btn.size * 0.5
	hud._input(bleed_tap)
	_expect(hud._active_touch_actions.is_empty(), "GameHUD blocks touch bleed-through onto Jump/Move buttons while FakeWinShatterOverlay is showing")
	hud.queue_free()
	await process_frame

	# Touch ANYWHERE on screen (empty top-left area, NOT a button!) via real Viewport push_input
	var tap_pos := Vector2(180.0, 140.0)
	var st := InputEventScreenTouch.new()
	st.index = 0
	st.pressed = true
	st.position = tap_pos
	root.push_input(st)

	_expect(ov.state == FakeWinOverlayScript.State.CRACKING and ov.is_blocking_input(), "Touching anywhere on screen cracks FakeWinShatterOverlay immediately & keeps blocking input")
	_expect(ov.last_impact_pos.distance_to(tap_pos) < 2.0, "Mirror fracture epicenter matches exact touch point (%s)" % ov.last_impact_pos)
	_expect(ov._crack_rays.size() >= 10 and ov._shards.size() >= 20, "Mirror shatter builds spiderweb crack rays (%d) & tumbling shards (%d)" % [ov._crack_rays.size(), ov._shards.size()])
	var uvs_ok := true
	for sh in ov._shards:
		var uvs: PackedVector2Array = sh.get("uvs", PackedVector2Array())
		var lpts: PackedVector2Array = sh["local_pts"]
		if uvs.size() != lpts.size():
			uvs_ok = false
			break
		for uv in uvs:
			if uv.x < -0.001 or uv.x > 1.001 or uv.y < -0.001 or uv.y > 1.001:
				uvs_ok = false
				break
	_expect(uvs_ok, "Every shattered mirror shard has normalized [0..1] viewport-clipped UVs matching its polygon vertices")

	# Step past crack hold -> shards explode, fake win UI hides, player released, real ExitDoor revealed!
	ov._process(0.18)
	await physics_frame
	_expect(ov.state == FakeWinOverlayScript.State.SHATTERED and not ov._fake_win_root.visible, "After crack flash, FakeWinRoot disappears into flying mirror shards")
	_expect(not p.is_entering_door, "Player is immediately freed to play when mirror shatters")
	_expect(ed.visible and ed.monitoring, "Real ExitDoor on upper deck becomes visible & monitoring after shatter")
	_expect(not pe._fake_door_area.visible, "FakeWinDoor disappears after mirror shatter")

	# Verify gravity pulls tumbling shards downward
	var y_before: float = ov._shards[0]["pos"].y
	for _f in range(15):
		ov._process(0.03)
	var y_after: float = ov._shards[0]["pos"].y
	_expect(y_after > y_before + 30.0, "Shattered glass shards accelerate downward with gravity (dy=%.1f)" % (y_after - y_before))

	# Clean reset on death/restart
	pe.reset_event()
	await physics_frame
	_expect(ov.state == FakeWinOverlayScript.State.IDLE and not ov.visible and not ed.visible and pe._fake_door_area.visible, "reset_event() cleanly resets FakeWinShatterOverlay, hides real ExitDoor, and restores FakeWinDoor")

	lvl12.queue_free()
	await process_frame

func _test_huawei_store_pack_assets() -> void:
	var icon_img := Image.new()
	var ierr := icon_img.load(ProjectSettings.globalize_path("res://store_assets/huawei_icon_512x512.png"))
	_expect(ierr == OK and icon_img.get_width() == 512 and icon_img.get_height() == 512, "Huawei AppGallery icon is valid 512x512 PNG")

	var shots := [
		"res://store_assets/screenshots/01_main_menu.png",
		"res://store_assets/screenshots/02_chapter1_twilight_mist.png",
		"res://store_assets/screenshots/03_chapter1_mirror_shatter.png",
		"res://store_assets/screenshots/04_chapter2_frost_peak.png",
		"res://store_assets/screenshots/05_chapter3_emerald_woods.png"
	]
	var shots_ok := true
	for s in shots:
		var img := Image.new()
		if img.load(ProjectSettings.globalize_path(s)) != OK or img.get_width() != 1920 or img.get_height() != 1080:
			shots_ok = false
			print("  [DETAIL] Invalid screenshot: " + s)
	_expect(shots_ok, "All 5 Huawei AppGallery screenshots exist and are exact 1920x1080 PNGs")

	var listing := FileAccess.get_file_as_string("res://store_assets/huawei_store_listing.md")
	_expect(listing.contains("en-US") and listing.contains("ru-RU") and listing.contains("uz-UZ"), "huawei_store_listing.md contains English, Russian, and Uzbek store copy")

	var privacy := FileAccess.get_file_as_string("res://store_assets/privacy_policy.html")
	_expect(privacy.contains("Google Sign-In") and privacy.contains("Supabase") and privacy.contains("Yandex Mobile Ads"), "privacy_policy.html covers Google Sign-In, Supabase, and Yandex Mobile Ads")
