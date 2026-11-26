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

func _backup_custom_slots() -> Dictionary:
	var backup := {}
	var clm := root.get_node_or_null("/root/CustomLevelManager")
	if clm:
		for i in range(1, 6):
			var p: String = clm.get_slot_path(i)
			if FileAccess.file_exists(p):
				var f := FileAccess.open(p, FileAccess.READ)
				if f:
					backup[p] = f.get_buffer(f.get_length())
					f.close()
	return backup

func _restore_custom_slots(backup: Dictionary) -> void:
	var clm := root.get_node_or_null("/root/CustomLevelManager")
	if clm:
		for i in range(1, 6):
			var p: String = clm.get_slot_path(i)
			if backup.has(p):
				var f := FileAccess.open(p, FileAccess.WRITE)
				if f:
					f.store_buffer(backup[p])
					f.close()
			elif FileAccess.file_exists(p):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p))

func _run_all() -> void:
	var slot_backup := _backup_custom_slots()
	print("=== Starting Level Editor P0+P1 & Playtest Verification ===")

	await _test_editor_layout_and_palette()
	await _test_multi_cell_bounds_and_reload_slot()
	await _test_platform_merge_and_wall_flags()
	await _test_trap_spawning_and_spring_physics()
	await _test_playtest_lifecycle_ad_guard_and_touch_controls()

	_restore_custom_slots(slot_backup)

	print("\n=== SUMMARY: %d checks, %d failures ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("ALL LEVEL EDITOR P0+P1 CHECKS PASSED!")
		quit(0)
	else:
		for f in _failures:
			print("  FAILURE: " + f)
		quit(1)

func _instantiate_editor() -> Control:
	root.size = Vector2i(960, 540)
	var scn := load("res://scenes/editor/level_editor.tscn") as PackedScene
	_expect(scn != null, "level_editor.tscn loads cleanly")
	var ed := scn.instantiate() as Control
	root.add_child(ed)
	return ed

func _test_editor_layout_and_palette() -> void:
	var ed := _instantiate_editor()
	await process_frame
	await process_frame

	# Background stretch_mode = 6 (STRETCH_KEEP_ASPECT_COVERED) for 20:9 phones
	var bg := ed.get_node_or_null("Background") as TextureRect
	_expect(bg != null and bg.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Background uses stretch_mode=6 (KEEP_ASPECT_COVERED)")

	# Initial hover_cell must not highlight (0,0) under TopBar
	_expect(ed.hover_cell == Vector2i(-1, -1), "Initial hover_cell is Vector2i(-1, -1)")

	# Bottom editable row must not overlap BottomPalette
	var grid_bottom_y: float = float((ed.MAX_ROW + 1) * ed.GRID_SIZE)
	var palette_top_y: float = ed.bottom_palette.position.y
	_expect(grid_bottom_y <= palette_top_y, "Editable grid bottom (%.0f) does not overlap BottomPalette top (%.0f)" % [grid_bottom_y, palette_top_y])

	# Tool cards use MOUSE_FILTER_PASS and clipped labels
	var all_cards_pass := true
	var all_labels_clip := true
	for id in ed.tool_cards:
		var btn: Button = ed.tool_cards[id]["btn"]
		var lbl: Label = ed.tool_cards[id]["lbl"]
		if btn.mouse_filter != Control.MOUSE_FILTER_PASS:
			all_cards_pass = false
		if not lbl.clip_text:
			all_labels_clip = false
	_expect(all_cards_pass and ed.tool_cards.size() >= 10, "All BottomPalette tool cards use MOUSE_FILTER_PASS")
	_expect(all_labels_clip, "All BottomPalette tool card labels enable clip_text")

	# Real Viewport touch drag starting directly on a tool card scrolls horizontally and suppresses accidental tool switch
	ed.current_tool = "platform"
	var spikes_btn: Button = ed.tool_cards["spikes"]["btn"]
	var spikes_center: Vector2 = spikes_btn.get_global_rect().get_center()
	var st_down := InputEventScreenTouch.new()
	st_down.index = 0
	st_down.pressed = true
	st_down.position = spikes_center
	root.push_input(st_down)
	var st_drag := InputEventScreenDrag.new()
	st_drag.index = 0
	st_drag.position = spikes_center + Vector2(-120, 0)
	st_drag.relative = Vector2(-120, 0)
	root.push_input(st_drag)
	var st_up := InputEventScreenTouch.new()
	st_up.index = 0
	st_up.pressed = false
	st_up.position = spikes_center + Vector2(-120, 0)
	root.push_input(st_up)
	_expect(ed.palette_scroll.scroll_horizontal > 0, "BottomPalette real Viewport touch drag scrolls horizontally (scroll_horizontal=%d)" % ed.palette_scroll.scroll_horizontal)
	_expect(ed._palette_drag_moved, "BottomPalette drag sets _palette_drag_moved to block same-frame accidental tool tap")

	# Simulate button pressed right after drag (same frame) -> should NOT switch tool
	var erase_btn: Button = ed.tool_cards["erase"]["btn"]
	erase_btn.pressed.emit()
	_expect(ed.current_tool == "platform", "Dragging BottomPalette does not accidentally switch current_tool")

	# Next frame, deferred flag clears so a subsequent click selects tool normally
	await process_frame
	_expect(not ed._palette_drag_moved, "BottomPalette _palette_drag_moved resets on next frame")
	erase_btn.pressed.emit()
	_expect(ed.current_tool == "erase", "Subsequent tap after drag selects tool cleanly")

	ed.queue_free()
	await process_frame

func _test_multi_cell_bounds_and_reload_slot() -> void:
	var clm := root.get_node_or_null("/root/CustomLevelManager")
	var empty_slot := 5
	var empty_path: String = clm.get_slot_path(empty_slot)
	if FileAccess.file_exists(empty_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(empty_path))

	var ed := _instantiate_editor()
	await process_frame

	# Switch to empty slot 5
	ed.current_slot = empty_slot
	ed._load_slot(empty_slot)
	_expect(ed.is_save_mode == true, "Empty slot loads in Save mode")

	# Trigger Reload (ID 99) on empty slot -> must STAY in Save mode!
	var reload_idx := -1
	for i in range(ed.slot_btn.item_count):
		if ed.slot_btn.get_item_id(i) == 99:
			reload_idx = i
			break
	_expect(reload_idx != -1, "Slot dropdown contains Reload (ID 99)")
	ed._on_slot_selected(reload_idx)
	_expect(ed.is_save_mode == true, "Reload (ID 99) on empty slot keeps is_save_mode == true")

	# Save slot 5 -> switches to Load mode; Reload keeps Load mode
	ed._on_save_pressed()
	_expect(FileAccess.file_exists(empty_path) and not ed.is_save_mode, "Saving slot switches button to Load mode")
	ed._on_slot_selected(reload_idx)
	_expect(not ed.is_save_mode, "Reload (ID 99) on saved slot keeps is_save_mode == false")

	# Multi-cell placement bounds
	var cols: int = ed._get_cols()
	ed.current_tool = "door"
	ed.last_placed_cell = Vector2i(-1, -1)
	ed._apply_tool_at_pos(Vector2(4, 2 * 32 + 4)) # gx=0, gy=2 -> clamped to gx=1, gy=3
	_expect(ed.exit_door_pos.x == float(1 * 32 + 16), "Exit door gx=0 clamped to gx=1 (x=%.0f)" % ed.exit_door_pos.x)
	_expect(ed.exit_door_pos.y == float(3 * 32 + 32), "Exit door gy=2 clamped to gy>=3 (y=%.0f)" % ed.exit_door_pos.y)

	ed.last_placed_cell = Vector2i(-1, -1)
	ed._apply_tool_at_pos(Vector2(float((cols - 1) * 32 + 4), 10 * 32 + 4)) # gx=cols-1 -> clamped to cols-2
	_expect(ed.exit_door_pos.x == float((cols - 2) * 32 + 16), "Exit door gx=cols-1 clamped to cols-2")

	ed.current_tool = "player"
	ed.last_placed_cell = Vector2i(-1, -1)
	ed._apply_tool_at_pos(Vector2(4, 10 * 32 + 4)) # gx=0 -> clamped to 1
	_expect(ed.player_spawn.x == float(1 * 32 + 16), "Player spawn gx=0 clamped to gx=1")
	ed.last_placed_cell = Vector2i(-1, -1)
	ed._apply_tool_at_pos(Vector2(float((cols - 1) * 32 + 4), 10 * 32 + 4)) # gx=cols-1 -> clamped to cols-2
	_expect(ed.player_spawn.x == float((cols - 2) * 32 + 16), "Player spawn gx=cols-1 clamped to cols-2")

	ed.current_tool = "fake_door"
	ed.last_placed_cell = Vector2i(-1, -1)
	ed._apply_tool_at_pos(Vector2(4, 2 * 32 + 4))
	_expect(ed.cell_map.has("1_3") and not ed.cell_map.has("0_2"), "Fake door at (0,2) clamped to (1,3)")

	ed.current_tool = "crusher"
	ed.last_placed_cell = Vector2i(-1, -1)
	ed._apply_tool_at_pos(Vector2(float((cols - 1) * 32 + 4), float(ed.MAX_ROW * 32 + 4)))
	var expected_crusher_key := "%d_%d" % [cols - 3, ed.MAX_ROW - 1]
	_expect(ed.cell_map.has(expected_crusher_key), "Crusher at bottom-right corner clamped to %s" % expected_crusher_key)

	# Multi-cell erase: tapping non-anchor cells of crusher (2x2) and fake_door (1x2) removes them cleanly
	ed.current_tool = "erase"
	ed.last_placed_cell = Vector2i(-1, -1)
	ed._apply_tool_at_pos(Vector2(float((cols - 2) * 32 + 4), float(ed.MAX_ROW * 32 + 4))) # bottom-right cell of 2x2 crusher
	_expect(not ed.cell_map.has(expected_crusher_key), "Eraser on bottom-right cell of 2x2 crusher removes crusher anchor %s" % expected_crusher_key)
	ed.last_placed_cell = Vector2i(-1, -1)
	ed._apply_tool_at_pos(Vector2(float(1 * 32 + 4), float(2 * 32 + 4))) # top cell (1,2) of 1x2 fake_door anchored at (1,3)
	_expect(not ed.cell_map.has("1_3"), "Eraser on top cell of 1x2 fake_door removes fake_door anchor 1_3")

	# CustomLevelManager bounds check on load & save
	_expect(not clm.save_custom_level(0, {}) and not clm.save_custom_level(99, {}), "CustomLevelManager.save_custom_level rejects out-of-range slots")
	_expect(clm.load_custom_level(0).has("elements") and clm.load_custom_level(99).has("elements"), "CustomLevelManager.load_custom_level safely falls back for out-of-range slots")

	ed.queue_free()
	await process_frame

func _test_platform_merge_and_wall_flags() -> void:
	var ed := _instantiate_editor()
	await process_frame

	ed.cell_map.clear()
	# Paint horizontal floor RIGHT-TO-LEFT: (8,12), (7,12), (6,12)
	for gx in [8, 7, 6]:
		ed.cell_map["%d_12" % gx] = {"type": "platform", "gx": gx, "gy": 12, "x": gx * 32, "y": 12 * 32}
	# Add vertical stack: (6,11) directly above (6,12) -> (6,12) has_above=true, (7..8,12) has_above=false
	ed.cell_map["6_11"] = {"type": "platform", "gx": 6, "gy": 11, "x": 6 * 32, "y": 11 * 32}

	ed._on_test_pressed()
	await process_frame

	var user_plats: Array = []
	var left_w: Node = null
	var right_w: Node = null
	for c in ed.playtest_world.get_children():
		if c is SolidPlatform:
			if c.name == "LeftWall":
				left_w = c
			elif c.name == "RightWall":
				right_w = c
			elif c.name != "Ceiling":
				user_plats.append(c)

	_expect(left_w != null and left_w.is_extension_or_wall == true, "Auto LeftWall sets is_extension_or_wall=true")
	_expect(right_w != null and right_w.is_extension_or_wall == true, "Auto RightWall sets is_extension_or_wall=true")
	# Expect exactly 3 user platforms: (6,11)[w=32,wall=false], (6,12)[w=32,wall=true], (7..8,12)[w=64,wall=false]
	_expect(user_plats.size() == 3, "Right-to-left platform merge produces zero duplicates & splits vertical stack cleanly (count=%d)" % user_plats.size())
	var found_top_6_11 := false
	var found_under_6_12 := false
	var found_merged_7_8 := false
	for p in user_plats:
		if p.position == Vector2(6 * 32, 11 * 32) and p.platform_size == Vector2(32, 32) and not p.is_extension_or_wall:
			found_top_6_11 = true
		elif p.position == Vector2(6 * 32, 12 * 32) and p.platform_size == Vector2(32, 32) and p.is_extension_or_wall:
			found_under_6_12 = true
		elif p.position == Vector2(7 * 32, 12 * 32) and p.platform_size == Vector2(64, 32) and not p.is_extension_or_wall:
			found_merged_7_8 = true
	_expect(found_top_6_11 and found_under_6_12 and found_merged_7_8, "Merged horizontal span (64px) and vertical stack is_extension_or_wall flags match")

	ed._on_stop_test_pressed()
	_expect(ed.playtest_world.get_child_count() == 0, "_clear_test_world removes children immediately via remove_child before queue_free")

	ed.queue_free()
	await process_frame

func _test_trap_spawning_and_spring_physics() -> void:
	var ed := _instantiate_editor()
	await process_frame

	ed.cell_map.clear()
	# Solid floor across row 12 (gx 2..20)
	for gx in range(2, 21):
		ed.cell_map["%d_12" % gx] = {"type": "platform", "gx": gx, "gy": 12, "x": gx * 32, "y": 12 * 32}

	# Place spring via tool to verify positive bounce_force stored
	ed.current_tool = "spring"
	ed.last_placed_cell = Vector2i(-1, -1)
	ed._apply_tool_at_pos(Vector2(6 * 32 + 8, 11 * 32 + 8))
	_expect(float(ed.cell_map["6_11"].get("bounce_force", 0.0)) > 0.0, "Spring tool stores positive bounce_force")

	# Place crusher at (10, 2) above row-12 floor -> target_y should be 384 - 64 = 320
	ed.cell_map["10_2"] = {"type": "crusher", "gx": 10, "gy": 2, "x": 10 * 32, "y": 2 * 32}
	# Place crusher over open pit at (23, 2) -> target_y reaches bottom of arena
	ed.cell_map["23_2"] = {"type": "crusher", "gx": 23, "gy": 2, "x": 23 * 32, "y": 2 * 32}
	# Place saw, circular_saw, pop_up_spikes, falling, trap_floor (lower row gy=12)
	ed.cell_map["14_9"] = {"type": "saw", "gx": 14, "gy": 9, "x": 14 * 32, "y": 9 * 32, "move_distance": 64.0, "radius": 18.0}
	ed.cell_map["17_8"] = {"type": "circular_saw", "gx": 17, "gy": 8, "x": 17 * 32, "y": 8 * 32, "orbit_radius": 64.0, "saw_radius": 22.0}
	ed.cell_map["8_11"] = {"type": "pop_up_spikes", "gx": 8, "gy": 11, "x": 8 * 32, "y": 11 * 32}
	ed.cell_map["12_3"] = {"type": "falling", "gx": 12, "gy": 3, "x": 12 * 32, "y": 3 * 32, "trigger_distance": 360.0}
	ed.cell_map["21_12"] = {"type": "trap_floor", "gx": 21, "gy": 12, "x": 21 * 32, "y": 12 * 32}

	# Spawn player right next to/on spring at (6, 11) -> feet at (6*32+16, 12*32 = 384)
	ed.player_spawn = Vector2(6 * 32 + 16, 12 * 32)
	ed.exit_door_pos = Vector2(18 * 32 + 16, 12 * 32)

	ed._on_test_pressed()
	await physics_frame
	await physics_frame

	var spring_node: SpringTrap = null
	var floor_crusher: Crusher = null
	var pit_crusher: Crusher = null
	var saw_node: MovingSawTrap = null
	var csaw_node: CircularSawTrap = null
	var popup_node: PopUpSpikesTrap = null
	var falling_node: FallingSpikeTrap = null
	var trap_floor_node: TrapFloor = null
	var player_node: PlayerController = null

	for c in ed.playtest_world.get_children():
		if c is SpringTrap: spring_node = c
		elif c is Crusher:
			if is_equal_approx(c.initial_position.x, 10.0 * 32.0):
				floor_crusher = c
			else:
				pit_crusher = c
		elif c is MovingSawTrap: saw_node = c
		elif c is CircularSawTrap: csaw_node = c
		elif c is PopUpSpikesTrap: popup_node = c
		elif c is FallingSpikeTrap: falling_node = c
		elif c is TrapFloor: trap_floor_node = c
		elif c is PlayerController: player_node = c

	_expect(spring_node != null and spring_node.position == Vector2(6 * 32, 12 * 32), "Spring spawns anchored at y + GRID_SIZE (pos=%s)" % str(spring_node.position if spring_node else Vector2.ZERO))
	_expect(spring_node != null and spring_node.visible_when_idle == true and spring_node.bounce_force > 0.0, "Spring sets visible_when_idle=true and positive bounce_force")
	_expect(player_node != null and player_node.velocity.y < -500.0, "Spring launches player upward in editor playtest (vy=%.1f)" % (player_node.velocity.y if player_node else 0.0))

	_expect(floor_crusher != null and is_equal_approx(floor_crusher.target_y, 320.0), "Crusher above row-12 floor reaches target_y=320.0 (got %.1f)" % (floor_crusher.target_y if floor_crusher else -1.0))
	var expected_pit_y: float = float((ed.MAX_ROW + 1) * ed.GRID_SIZE) - 64.0
	_expect(pit_crusher != null and is_equal_approx(pit_crusher.target_y, expected_pit_y), "Crusher over open pit reaches arena bottom %.1f (got %.1f)" % [expected_pit_y, pit_crusher.target_y if pit_crusher else -1.0])

	_expect(saw_node != null and is_equal_approx(saw_node.radius, 18.0) and is_equal_approx(saw_node.patrol_distance, 64.0), "MovingSawTrap receives radius & patrol_distance properly")
	_expect(csaw_node != null and is_equal_approx(csaw_node.saw_radius, 22.0), "CircularSawTrap receives saw_radius properly")
	_expect(popup_node != null and is_equal_approx(popup_node.max_spike_height, 32.0) and is_equal_approx(popup_node.position.y, 12.0 * 32.0), "PopUpSpikesTrap receives max_spike_height=32 and floor-aligned y")
	_expect(falling_node != null and is_equal_approx(falling_node.trigger_distance, 360.0), "FallingSpikeTrap receives trigger_distance properly")
	_expect(trap_floor_node != null and not trap_floor_node.auto_extend_to_bottom and trap_floor_node.platform_size == Vector2(32, 32), "TrapFloor on lower row stays 32x32 without pillar stretching (size=%s)" % str(trap_floor_node.platform_size if trap_floor_node else Vector2.ZERO))

	# Verify trap reset fires cleanly on GameManager.player_respawned
	if trap_floor_node:
		trap_floor_node.is_triggered = true
		var gm := root.get_node_or_null("/root/GameManager")
		gm.player_respawned.emit()
		_expect(not trap_floor_node.is_triggered, "TrapFloor resets cleanly on GameManager.player_respawned")

	# Live runtime physics: MovingSaw patrols c -> c + (64, 0), Crusher triggers & slams to target_y=320, PopUpSpikes erupts
	if saw_node and floor_crusher and popup_node and player_node:
		var saw_start_x: float = saw_node.start_pos.x
		var saw_max_x: float = saw_node.global_position.x
		player_node.is_invulnerable = false
		player_node.invulnerable_timer = 0.0
		player_node.global_position = Vector2(10.0 * 32.0 + 32.0, 12.0 * 32.0) # under floor_crusher
		var crusher_slammed := false
		for _i in range(40):
			await physics_frame
			saw_max_x = maxf(saw_max_x, saw_node.global_position.x)
			if is_equal_approx(floor_crusher.global_position.y, 320.0):
				crusher_slammed = true
		_expect(saw_max_x >= saw_start_x + 60.0 and saw_max_x <= saw_start_x + 65.0, "MovingSawTrap patrols from start_x to start_x + 64 (max_dx=%.1f)" % (saw_max_x - saw_start_x))
		_expect(crusher_slammed, "Crusher live-triggers and slams down to target_y=320.0 in playtest (y=%.1f)" % floor_crusher.global_position.y)

	ed._on_stop_test_pressed()
	ed.queue_free()
	await process_frame

func _test_playtest_lifecycle_ad_guard_and_touch_controls() -> void:
	var gm := root.get_node_or_null("/root/GameManager")
	var sm := root.get_node_or_null("/root/SaveManager")
	var snd := root.get_node_or_null("/root/SoundManager")
	var loc := root.get_node_or_null("/root/LocaleManager")

	var ed := _instantiate_editor()
	await process_frame

	# 1. Verify 10th-death interstitial ad does NOT trigger in editor mode
	gm.level_deaths = 10
	ed._on_test_pressed()
	await process_frame
	_expect(gm.is_custom_editor_mode == true and snd.is_gameplay_mode == true, "Playtest enables is_custom_editor_mode and SoundManager gameplay mode")
	var player_node := get_first_node_in_group("player") as PlayerController
	_expect(player_node != null, "Playtest spawns PlayerController")
	paused = false
	player_node.respawn()
	_expect(not paused, "10th-death interstitial ad is suppressed in editor mode (tree not paused)")

	# 2. Verify PlaytestUI Touch Controls: Dash button, localization, PC hidden, custom layout/scale, multi-touch + D-pad slide
	_expect(ed.dash_btn != null and ed.jump_btn != null and ed.left_btn != null and ed.right_btn != null, "PlaytestUI has Left, Right, Dash, and Jump touch buttons")
	_expect(not ed.touch_controls.visible, "PlaytestUI TouchControls hidden on desktop PC")

	var prev_lang: String = loc.current_language
	loc.set_language("en")
	_expect(ed.jump_btn.text == "JUMP" and ed.dash_btn.text == "DASH", "PlaytestUI Jump/Dash localized in EN")
	loc.set_language("ru")
	_expect(ed.jump_btn.text == "ПРЫЖОК" and ed.dash_btn.text == "РЫВОК", "PlaytestUI Jump/Dash localized in RU")
	loc.set_language(prev_lang)

	# Custom touch layout & scale
	var prev_scale: float = sm.touch_button_scale
	var prev_layout: Dictionary = sm.custom_touch_layout.duplicate(true)
	sm.touch_button_scale = 1.2
	sm.custom_touch_layout = {"dash": [650.0, 400.0], "jump": [800.0, 400.0]}
	ed._apply_playtest_touch_layout()
	_expect(ed.dash_btn.position == Vector2(650.0, 400.0) and is_equal_approx(ed.dash_btn.size.x, 78.0 * 1.2), "PlaytestUI applies SaveManager custom_touch_layout and touch_button_scale")
	sm.touch_button_scale = prev_scale
	sm.custom_touch_layout = prev_layout
	ed._apply_playtest_touch_layout()

	# Simulate mobile multi-touch + D-pad thumb-slide
	ed.touch_controls.visible = true
	var left_center: Vector2 = ed.left_btn.position + ed.left_btn.size * 0.5
	var right_center: Vector2 = ed.right_btn.position + ed.right_btn.size * 0.5
	var dash_center: Vector2 = ed.dash_btn.position + ed.dash_btn.size * 0.5
	var jump_center: Vector2 = ed.jump_btn.position + ed.jump_btn.size * 0.5

	var t_left := InputEventScreenTouch.new()
	t_left.index = 0
	t_left.pressed = true
	t_left.position = left_center
	ed._input(t_left)

	var t_dash := InputEventScreenTouch.new()
	t_dash.index = 1
	t_dash.pressed = true
	t_dash.position = dash_center
	ed._input(t_dash)

	var t_jump := InputEventScreenTouch.new()
	t_jump.index = 2
	t_jump.pressed = true
	t_jump.position = jump_center
	ed._input(t_jump)

	_expect(Input.is_action_pressed("move_left") and Input.is_action_pressed("dash") and Input.is_action_pressed("jump"), "Multi-touch activates move_left + dash + jump simultaneously")

	# Thumb-slide finger 0 from LeftBtn -> RightBtn
	var d_slide := InputEventScreenDrag.new()
	d_slide.index = 0
	d_slide.position = right_center
	ed._input(d_slide)
	_expect(not Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"), "D-pad thumb-slide transitions move_left -> move_right cleanly")

	# 3. KEY_ESCAPE stops playtest cleanly and releases all touch inputs
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	ed._unhandled_input(esc)
	_expect(not ed.is_testing and not gm.is_custom_editor_mode and not snd.is_gameplay_mode, "KEY_ESCAPE stops playtest and resets editor/gameplay modes")
	_expect(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("dash") and not Input.is_action_pressed("jump"), "Stopping playtest releases all stuck touch inputs")

	# 4. Stale _on_custom_level_completed timer cancelled by session counter
	ed._on_test_pressed()
	ed._on_custom_level_completed() # schedules 1.2s timer for session N
	ed._on_stop_test_pressed() # increments session to N+1
	ed._on_test_pressed() # increments session to N+2
	await create_timer(1.3).timeout
	_expect(ed.is_testing, "Stale _on_custom_level_completed await timer does NOT cancel a newer playtest session")

	# 5. _exit_tree cleans up is_custom_editor_mode, SoundManager gameplay mode & ALL autoload signals (verified via remove_child)
	root.remove_child(ed)
	_expect(not gm.is_custom_editor_mode and not snd.is_gameplay_mode, "LevelEditor _exit_tree resets GameManager.is_custom_editor_mode and SoundManager gameplay mode")
	_expect(
		not loc.language_changed.is_connected(ed._on_language_changed)
		and not gm.custom_player_died.is_connected(ed._on_custom_player_died)
		and not gm.custom_level_completed.is_connected(ed._on_custom_level_completed)
		and not gm.player_respawned.is_connected(ed._on_custom_player_respawned)
		and not sm.touch_layout_changed.is_connected(ed._apply_playtest_touch_layout),
		"LevelEditor _exit_tree disconnects all Autoload signals (verified on valid detached instance)"
	)
	ed.queue_free()
	await process_frame

	# 6. GameManager.go_to_main_menu resets level_deaths = 0
	gm.level_deaths = 10
	gm.go_to_main_menu()
	_expect(gm.level_deaths == 0, "GameManager.go_to_main_menu resets level_deaths to 0")
