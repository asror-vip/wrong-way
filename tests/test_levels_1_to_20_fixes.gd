extends SceneTree

# Automated headless physics & behavioral test suite for Levels 1-20 fixes:
# - Level 14 invisible wall portal & bidirectional wrap
# - Universal vertical floor-zone filtering across all active traps
# - Ceiling-hidden crushers (10, 16, 18, 20) vs upper-floor crusher (17)
# - Zero fakeout_first hesitation across Levels 1-20
# - FallingSpike pass_through_platforms
# - DodgingPlatform returns_to_origin & betray_on_land
# - Hidden shortcuts (Levels 9-20): zero accidental stumbles & physical reachability
# - data/levels.json sync with LevelArena

var _started := false
var _failures: Array[String] = []
var _checks: int = 0

func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run_all()
	return false

func _expect(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)
		print("[FAIL] " + msg)
	else:
		print("[PASS] " + msg)

func _load_level_node(lvl: int) -> Node2D:
	var path := "res://scenes/levels/level_%02d.tscn" % lvl
	var ps := load(path) as PackedScene
	if ps == null:
		return null
	var inst := ps.instantiate() as Node2D
	root.add_child(inst)
	return inst

func _step_physics(frames: int) -> void:
	for _i in range(frames):
		await physics_frame

func _run_all() -> void:
	print("=== Starting Levels 1-20 Comprehensive Verification ===")
	await _test_all_20_load_and_no_fakeout()
	await _test_level_14_invisible_portal()
	await _test_level_17_no_accidental_fall_and_basement_isolation()
	await _test_level_18_no_accidental_win_and_ceiling_crusher()
	await _test_level_19_no_accidental_spring_and_chimney_launch()
	await _test_ceiling_crushers_10_16_20()
	await _test_level_09_invisible_ghost_bridge()
	await _test_level_11_low_gravity_glide()
	await _test_level_13_high_stones_and_falling_spike_pass_through()
	await _test_level_15_chandelier_shortcut_and_bowl_isolation()
	await _test_level_16_dodging_platform_isolation_and_return()
	await _test_level_06_dodging_betrayal()
	await _test_level_20_monolith_trigger_and_subtle_stairs()
	await _test_level_04_10_12_15_extra_edge_cases()
	await _test_universal_vertical_filters_all_traps()
	await _test_json_arena_sync_1_to_20()

	print("\n=== SUMMARY: %d checks, %d failures ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("ALL CHECKS PASSED!")
		quit(0)
	else:
		for f in _failures:
			print("  FAILURE: " + f)
		quit(1)

func _test_all_20_load_and_no_fakeout() -> void:
	for lvl in range(1, 21):
		var inst := _load_level_node(lvl)
		_expect(inst != null, "L%02d instantiates cleanly" % lvl)
		if inst == null:
			continue
		var traps := inst.get_node_or_null("Traps")
		if traps:
			for t in traps.get_children():
				if "fakeout_first" in t:
					_expect(t.fakeout_first == false, "L%02d %s has fakeout_first == false" % [lvl, t.name])
		inst.queue_free()
		await process_frame

func _test_level_14_invisible_portal() -> void:
	var inst := _load_level_node(14)
	await _step_physics(4)
	var fw_l = inst.get_node_or_null("Platforms/FakeWallLeftPortal")
	var fw_r = inst.get_node_or_null("Platforms/FakeWallRightPortal")
	var pe = inst.get_node_or_null("Paranormal/ParanormalEvent")
	var p = inst.get_node_or_null("Player")

	_expect(fw_l != null and fw_l.subtle_crack == false and fw_l.fade_when_inside == false, "L14 FakeWallLeftPortal has no crack & no fade")
	_expect(fw_r != null and fw_r.subtle_crack == false and fw_r.fade_when_inside == false, "L14 FakeWallRightPortal has no crack & no fade")
	var wb_l = inst.get_node_or_null("Platforms/WallLeftBot")
	var wb_r = inst.get_node_or_null("Platforms/WallRightBot")
	_expect(fw_l.position.y + fw_l.wall_size.y >= wb_l.position.y and fw_r.position.y + fw_r.wall_size.y >= wb_r.position.y, "L14 FakeWall portals overlap WallLeftBot/WallRightBot with zero trim seam")
	_expect(pe != null and pe._fx_timer == 0.0, "L14 portal has zero VFX shimmer before crossing")
	_expect(p != null and p.screen_wrap_enabled == true, "L14 player has screen_wrap_enabled")

	# Simulate holding move_left from spawn (135, 380) until wrapped to right side
	p.is_invulnerable = false
	Input.action_press("move_left")
	var wrapped_right := false
	for _i in range(60):
		await physics_frame
		if p.global_position.x > 850.0:
			wrapped_right = true
			break
	Input.action_release("move_left")
	_expect(wrapped_right, "L14 walking left through invisible left wall wraps player to right side (x=%.1f)" % p.global_position.x)
	_expect(pe._fx_timer > 0.0, "L14 brief warp shimmer activates ONLY after crossing (fx_timer=%.2f)" % pe._fx_timer)

	# Now simulate holding move_right through right wall to wrap back to left side
	Input.action_press("move_right")
	var wrapped_left := false
	for _i in range(40):
		await physics_frame
		if p.global_position.x < 100.0:
			wrapped_left = true
			break
	Input.action_release("move_right")
	_expect(wrapped_left, "L14 walking right through invisible right wall wraps player back to left side (x=%.1f)" % p.global_position.x)

	inst.queue_free()
	await process_frame

func _test_level_17_no_accidental_fall_and_basement_isolation() -> void:
	var inst := _load_level_node(17)
	await _step_physics(4)
	var p = inst.get_node_or_null("Player")
	var cr = inst.get_node_or_null("Traps/CrusherLeft")
	var pu = inst.get_node_or_null("Traps/PopUpLeft")
	var ms = inst.get_node_or_null("Traps/MovingSawLeft")
	var fd = inst.get_node_or_null("Traps/FakeDoorRight")
	var rb = inst.get_node_or_null("Traps/RollingBoulderDecoy")
	var fh = inst.get_node_or_null("Platforms/FakeHole")
	_expect(fh != null and fh.subtle_crack == false, "L17 FakeHole has no crack")

	# Walk left from spawn (500, 340) for 22 frames: must STAY on upper deck y=340!
	p.is_invulnerable = false
	Input.action_press("move_left")
	await _step_physics(22)
	Input.action_release("move_left")
	_expect(absf(p.global_position.y - 340.0) < 4.0 and p.global_position.x < 440.0, "L17 walking left from spawn stays on solid upper deck (pos=%s)" % str(p.global_position))

	# Reset and place player on BasementFloor underneath ALL upper-floor traps
	inst.reset_level_traps()
	p.global_position = Vector2(280.0, 440.0)
	p.velocity = Vector2.ZERO
	p.is_invulnerable = false
	await _step_physics(25)
	_expect(cr.state == 0, "L17 CrusherLeft stays IDLE when player is on BasementFloor (state=%d)" % cr.state)
	p.global_position = Vector2(230.0, 440.0)
	await _step_physics(20)
	_expect(not pu.is_triggered, "L17 PopUpLeft stays dormant when player is on BasementFloor")
	p.global_position = Vector2(855.0, 440.0)
	await _step_physics(20)
	_expect(not fd.is_triggered, "L17 FakeDoorRight stays dormant when player is on BasementFloor")
	p.global_position = Vector2(700.0, 440.0)
	await _step_physics(20)
	_expect(not rb.is_triggered, "L17 RollingBoulderDecoy stays dormant when player is on BasementFloor")

	# Place player on LeftGauntletDeck (y=340) under CrusherLeft -> must trigger and stop at target_y=298
	p.global_position = Vector2(305.0, 340.0)
	p.is_invulnerable = false
	await _step_physics(2)
	_expect(cr.state != 0, "L17 CrusherLeft triggers when player is on upper deck")
	p.global_position = Vector2(450.0, 340.0) # step aside
	await _step_physics(40)
	_expect(cr.global_position.y <= 300.0, "L17 CrusherLeft stops on upper deck target_y=298 (y=%.1f)" % cr.global_position.y)

	# Verify walking right past FakeDoorRight drops player cleanly through FakeHole (843..928) onto BasementFloor (y=440)
	inst.reset_level_traps()
	# Simulate boulder already rolled past player (disabled/out of the way)
	rb.has_fallen = true
	rb.global_position = Vector2(300.0, 312.0)
	rb.col_shape.disabled = true
	rb.kill_area.monitoring = false
	await physics_frame
	p.global_position = Vector2(760.0, 340.0)
	p.velocity = Vector2.ZERO
	p.is_invulnerable = false
	Input.action_press("move_right")
	var dropped_to_basement := false
	for _i in range(60):
		await physics_frame
		if absf(p.global_position.y - 440.0) < 4.0:
			dropped_to_basement = true
			break
	Input.action_release("move_right")
	_expect(dropped_to_basement and not p.is_dead, "L17 walking past FakeDoorRight drops player cleanly through FakeHole onto BasementFloor (pos=%s, dead=%s)" % [str(p.global_position), str(p.is_dead)])
	_expect(ms != null, "L17 MovingSawLeft present")

	# Verify full basement shortcut exit climb FIRST on clean state:
	# BasementFloor -> walk cleanly under BasementStep -> jump up through one-way BasementStep (y=392) -> jump to LeftDoorIsland -> ExitDoor
	inst.reset_level_traps()
	p.is_dead = false
	p.is_entering_door = false
	p.is_invulnerable = false
	p.global_position = Vector2(215.0, 440.0)
	p.velocity = Vector2.ZERO
	await _step_physics(2)
	Input.action_press("move_left")
	await _step_physics(16) # walk cleanly under BasementStep (440 - 406 = 34px > 32px)
	var walked_under: bool = (not p.is_dead) and float(p.global_position.x) > 32.0 and float(p.global_position.x) < 175.0
	Input.action_release("move_left")
	_expect(walked_under, "L17 player walks cleanly under BasementStep without forehead block (x=%.1f)" % p.global_position.x)

	p.global_position = Vector2(165.0, 440.0)
	p.velocity = Vector2.ZERO
	await _step_physics(2)
	Input.action_press("jump")
	await _step_physics(2)
	Input.action_release("jump")
	var climbed_bstep := false
	for _i in range(45):
		await physics_frame
		if p.is_on_floor() and absf(p.global_position.y - 392.0) < 4.0:
			climbed_bstep = true
			break
	_expect(climbed_bstep and not p.is_dead, "L17 player climbs from BasementFloor onto one-way BasementStep (pos=%s)" % str(p.global_position))

	p.global_position = Vector2(158.0, 392.0)
	p.velocity = Vector2.ZERO
	await _step_physics(2)
	Input.action_press("move_left")
	Input.action_press("jump")
	await _step_physics(2)
	Input.action_release("jump")
	var climbed_island := false
	for _i in range(45):
		await physics_frame
		if p.is_entering_door or (p.is_on_floor() and absf(p.global_position.y - 340.0) < 4.0 and p.global_position.x <= 132.0):
			climbed_island = true
			break
	Input.action_release("move_left")
	_expect(climbed_island and not p.is_dead, "L17 player climbs from BasementStep onto LeftDoorIsland & enters ExitDoor (pos=%s, entering=%s)" % [str(p.global_position), str(p.is_entering_door)])

	# Verify hard-path jump over PopUpLeft (225..269) & 82px gap onto LeftDoorIsland (simulating passing CrusherLeft during cooldown)
	inst.queue_free()
	await process_frame
	var inst17b := _load_level_node(17)
	await _step_physics(4)
	var p17b = inst17b.get_node_or_null("Player")
	var cr17b = inst17b.get_node_or_null("Traps/CrusherLeft")
	cr17b.state = 5 # COOLDOWN after player baited CrusherLeft
	cr17b.timer = 1.0
	p17b.is_invulnerable = false
	p17b.global_position = Vector2(305.0, 340.0)
	p17b.velocity = Vector2.ZERO
	await _step_physics(1)
	Input.action_press("move_left")
	Input.action_press("jump")
	await _step_physics(2)
	Input.action_release("jump")
	var cleared_hard_gap := false
	for _i in range(55):
		await physics_frame
		if p17b.is_entering_door or (p17b.is_on_floor() and absf(p17b.global_position.y - 340.0) < 4.0 and p17b.global_position.x <= 132.0):
			cleared_hard_gap = true
			break
	Input.action_release("move_left")
	_expect(cleared_hard_gap and not p17b.is_dead, "L17 hard-path jump over PopUpLeft & gap onto LeftDoorIsland reachable cleanly (pos=%s, dead=%s)" % [str(p17b.global_position), str(p17b.is_dead)])

	inst17b.queue_free()
	await process_frame

func _test_level_18_no_accidental_win_and_ceiling_crusher() -> void:
	var inst := _load_level_node(18)
	await _step_physics(4)
	var p = inst.get_node_or_null("Player")
	var cr = inst.get_node_or_null("Traps/CrusherLow")
	var tf = inst.get_node_or_null("Traps/TrapFloorShortcut")

	_expect(cr.global_position.y + cr.crusher_size.y == 48.0, "L18 CrusherLow flush in ceiling (bot=%.1f)" % (cr.global_position.y + cr.crusher_size.y))
	_expect(cr.pass_through_platforms == true, "L18 CrusherLow has pass_through_platforms=true")

	# Walk right from spawn (145, 225) to x~380 (avoiding PopUpUp at 440), then test standing right over CrusherLow at x=495
	p.is_invulnerable = false
	Input.action_press("move_right")
	await _step_physics(30)
	Input.action_release("move_right")
	_expect(absf(p.global_position.y - 225.0) < 4.0, "L18 walking right from spawn stays on upper floor (pos=%s)" % str(p.global_position))
	_expect(not tf.is_triggered, "L18 TrapFloorShortcut does NOT trigger when walking right from spawn")
	p.global_position = Vector2(515.0, 225.0)
	p.velocity = Vector2.ZERO
	await _step_physics(20)
	_expect(not p.is_dead and cr.state == 0, "L18 CrusherLow stays IDLE when player is right above it on UpperRunMain (dead=%s, state=%d)" % [str(p.is_dead), cr.state])

	# Now place player on LowerFloor (y=410) under CrusherLow -> MUST trigger & drop through UpperRunMain to y=368!
	p.global_position = Vector2(495.0, 410.0)
	p.velocity = Vector2.ZERO
	await _step_physics(2)
	_expect(cr.state == 2, "L18 CrusherLow triggers when player is on LowerFloor (state=%d)" % cr.state)
	p.global_position = Vector2(820.0, 410.0)
	var reached_lower := false
	for _i in range(40):
		await physics_frame
		if cr.global_position.y >= 367.0:
			reached_lower = true
			break
	_expect(reached_lower, "L18 CrusherLow passes through UpperRunMain and reaches lower floor target_y=368 (y=%.1f)" % cr.global_position.y)

	# Test small 8-frame accidental nudge left from spawn (180, 225): must NOT reveal TrapFloorShortcut!
	inst.reset_level_traps()
	p.global_position = Vector2(180.0, 225.0)
	p.velocity = Vector2.ZERO
	p.is_invulnerable = false
	Input.action_press("move_left")
	await _step_physics(8)
	Input.action_release("move_left")
	await _step_physics(3)
	_expect(not tf.is_triggered, "L18 small 8-frame tap left from spawn does NOT accidentally trigger TrapFloorShortcut (x=%.1f)" % p.global_position.x)

	# Test deliberate shortcut behind spawn: walk left from (180, 225) onto TrapFloorShortcut (32..96)
	Input.action_press("move_left")
	await _step_physics(26)
	Input.action_release("move_left")
	await _step_physics(40)
	_expect(tf.is_triggered and absf(p.global_position.y - 410.0) < 4.0, "L18 deliberately walking left behind spawn triggers TrapFloorShortcut and drops onto LowerFloor (y=%.1f)" % p.global_position.y)

	inst.queue_free()
	await process_frame

func _test_level_19_no_accidental_spring_and_chimney_launch() -> void:
	var inst := _load_level_node(19)
	await _step_physics(4)
	var p = inst.get_node_or_null("Player")
	var sp = inst.get_node_or_null("Traps/SpringShortcut")

	# Walk right from spawn (230, 435): must NOT hit SpringShortcut!
	p.is_invulnerable = false
	Input.action_press("move_right")
	await _step_physics(25)
	Input.action_release("move_right")
	_expect(not sp.is_springing and absf(p.global_position.y - 435.0) < 4.0, "L19 walking right from spawn does NOT hit SpringShortcut (pos=%s)" % str(p.global_position))

	# Walk left behind spawn into SpringShortcut (146, 435) and RELEASE move_left immediately upon trigger -> must launch cleanly above Tier4 (y=171) with zero Tier2 headbonk!
	inst.reset_level_traps()
	p.global_position = Vector2(230.0, 435.0)
	p.velocity = Vector2.ZERO
	p.is_invulnerable = false
	Input.action_press("move_left")
	var min_y := 999.0
	var triggered_x := -1.0
	for _i in range(70):
		await physics_frame
		min_y = minf(min_y, p.global_position.y)
		if sp.is_springing and triggered_x < 0.0:
			triggered_x = p.global_position.x
			Input.action_release("move_left")
	Input.action_release("move_left")
	_expect(min_y < 171.0, "L19 walking left behind spawn into SpringShortcut (trig_x=%.1f) launches cleanly above Tier4 y=171 even after releasing left (min_y=%.1f)" % [triggered_x, min_y])

	inst.queue_free()
	await process_frame

func _test_ceiling_crushers_10_16_20() -> void:
	var cfgs := [
		{"lvl": 10, "node": "Traps/CrusherLower", "up_pos": Vector2(588.0, 225.0), "low_pos": Vector2(588.0, 410.0)},
		{"lvl": 16, "node": "Traps/CrusherLower", "up_pos": Vector2(703.0, 232.0), "low_pos": Vector2(703.0, 410.0)},
		{"lvl": 20, "node": "Traps/Crusher1", "up_pos": Vector2(364.0, 230.0), "low_pos": Vector2(364.0, 410.0)},
	]
	for cfg in cfgs:
		var inst := _load_level_node(cfg["lvl"])
		await _step_physics(4)
		var p = inst.get_node_or_null("Player")
		var cr = inst.get_node_or_null(cfg["node"])
		_expect(cr.global_position.y + cr.crusher_size.y == 48.0, "L%02d %s flush in ceiling" % [cfg["lvl"], cr.name])
		_expect(cr.pass_through_platforms == true, "L%02d %s pass_through_platforms=true" % [cfg["lvl"], cr.name])

		# Upper floor test: must NOT trigger
		p.is_invulnerable = false
		p.global_position = cfg["up_pos"]
		p.velocity = Vector2.ZERO
		await _step_physics(20)
		_expect(cr.state == 0, "L%02d %s stays IDLE when player is on upper deck" % [cfg["lvl"], cr.name])

		# Lower floor test: MUST trigger and pass through upper deck to y=368
		p.global_position = cfg["low_pos"]
		await _step_physics(2)
		_expect(cr.state == 2, "L%02d %s triggers when player is on lower floor" % [cfg["lvl"], cr.name])
		p.global_position = Vector2(860.0, 410.0)
		var hit_low := false
		for _i in range(45):
			await physics_frame
			if cr.global_position.y >= 367.0:
				hit_low = true
				break
		_expect(hit_low, "L%02d %s passes through upper deck to target_y=368 (y=%.1f)" % [cfg["lvl"], cr.name, cr.global_position.y])
		inst.queue_free()
		await process_frame

func _test_level_09_invisible_ghost_bridge() -> void:
	var inst := _load_level_node(9)
	await _step_physics(6)
	var pe = inst.get_node_or_null("Paranormal/ParanormalEvent")
	var p = inst.get_node_or_null("Player")
	var pu = inst.get_node_or_null("Traps/PopUpMid")

	var all_hidden := true
	for s in pe._ghost_stones:
		if float(s["glow"]) > 0.0:
			all_hidden = false
	_expect(all_hidden and pe._ghost_stones.size() == 4, "L09 all 4 ghost stones start 100% invisible (glow==0)")

	# Normal main-path running jump over Spikes1 (215..259) from x=180 must NEVER accidentally hit any GhostStone!
	p.is_invulnerable = false
	Input.action_press("move_right")
	var jumped_s1 := false
	var hit_ghost_accidental := false
	for _i in range(65):
		await physics_frame
		if not jumped_s1 and p.global_position.x >= 180.0:
			jumped_s1 = true
			Input.action_press("jump")
			await _step_physics(2)
			Input.action_release("jump")
		if jumped_s1 and not p.is_dead and p.is_on_floor():
			if p.global_position.y < 350.0:
				hit_ghost_accidental = true
			break
	Input.action_release("move_right")
	_expect(not hit_ghost_accidental and not p.is_dead, "L09 normal jump over Spikes1 does NOT accidentally land on any GhostStone (pos=%s)" % str(p.global_position))

	# Deliberately jumping near spawn (125, 380) discovers GhostStone_0 (95..167, y=285) -> GhostStone_1 (275..351, y=205)
	p.global_position = Vector2(125.0, 380.0)
	p.velocity = Vector2.ZERO
	await _step_physics(2)
	Input.action_press("jump")
	await _step_physics(2)
	Input.action_release("jump")
	var landed_g0 := false
	for _i in range(45):
		await physics_frame
		if p.is_on_floor() and absf(p.global_position.y - 285.0) < 4.0:
			landed_g0 = true
			break
	_expect(landed_g0, "L09 deliberate jump near spawn lands on GhostStone_0 (pos=%s)" % str(p.global_position))

	# Jump GhostStone_0 -> GhostStone_1 (275..351, y=205) without dash
	Input.action_press("move_right")
	Input.action_press("jump")
	await _step_physics(2)
	Input.action_release("jump")
	var landed_g1 := false
	for _i in range(50):
		await physics_frame
		if p.is_on_floor() and absf(p.global_position.y - 205.0) < 4.0 and p.global_position.x >= 270.0:
			landed_g1 = true
			break
	Input.action_release("move_right")
	_expect(landed_g1, "L09 GhostStone_0 -> GhostStone_1 reachable cleanly without dash (pos=%s)" % str(p.global_position))

	# Stand on GhostStone_2 (475..551, y=205) right above PopUpMid (535, 380): stone lights up, PopUpMid stays dormant!
	inst.reset_level_traps()
	p.is_invulnerable = false
	p.global_position = Vector2(510.0, 205.0)
	p.velocity = Vector2.ZERO
	await _step_physics(12)
	_expect(float(pe._ghost_stones[2]["glow"]) > 0.5, "L09 GhostStone_2 illuminates when player stands on it")
	_expect(float(pe._ghost_stones[0]["glow"]) == 0.0 and float(pe._ghost_stones[1]["glow"]) == 0.0 and float(pe._ghost_stones[3]["glow"]) == 0.0, "L09 untouched ghost stones stay 100% invisible")
	_expect(not pu.is_triggered, "L09 PopUpMid does NOT trigger when player is up on ghost bridge")

	inst.queue_free()
	await process_frame

func _test_level_11_low_gravity_glide() -> void:
	var inst := _load_level_node(11)
	await _step_physics(4)
	_expect(inst.get_node_or_null("Platforms/SkyStone") == null, "L11 obvious SkyStone removed")
	_expect(inst.get_node_or_null("Platforms/HighLeftLedge") == null, "L11 obvious HighLeftLedge removed")
	var p = inst.get_node_or_null("Player")
	var pe = inst.get_node_or_null("Paranormal/ParanormalEvent")
	var fs = inst.get_node_or_null("Traps/FallingSpikeLeft")

	p.is_invulnerable = false
	p.global_position = Vector2(710.0, 220.0)
	await _step_physics(3)
	_expect(pe.triggered and p.gravity_mult < 0.6, "L11 low_gravity_drift activates properly (g=%.2f)" % p.gravity_mult)

	Input.action_press("move_left")
	Input.action_press("jump")
	await _step_physics(2)
	Input.action_release("jump")
	await _step_physics(6)
	Input.action_press("dash")
	await _step_physics(2)
	Input.action_release("dash")
	await _step_physics(32)
	Input.action_press("dash")
	await _step_physics(2)
	Input.action_release("dash")
	var landed := false
	for _i in range(85):
		await physics_frame
		if p.is_on_floor() and p.global_position.y >= 408.0:
			landed = true
			break
	Input.action_release("move_left")
	_expect(landed and not p.is_dead and p.global_position.x < 245.0, "L11 low-gravity jump + double-dash glide clears all traps onto BottomLeftRun (pos=%s, dead=%s)" % [str(p.global_position), str(p.is_dead)])
	_expect(not fs.is_triggered, "L11 FallingSpikeLeft stays dormant during high low-gravity glide")

	inst.queue_free()
	await process_frame

func _test_level_13_high_stones_and_falling_spike_pass_through() -> void:
	var inst := _load_level_node(13)
	await _step_physics(4)
	var p = inst.get_node_or_null("Player")
	var fs = inst.get_node_or_null("Traps/FallingSpikeValley1")
	var pu = inst.get_node_or_null("Traps/PopUpValley1")

	# High stone jump test from CliffLeft (195, 280) to AirStone1 (330..386, y=188)
	p.is_invulnerable = false
	p.global_position = Vector2(195.0, 280.0)
	Input.action_press("move_right")
	Input.action_press("jump")
	await _step_physics(2)
	Input.action_release("jump")
	var landed_stone1 := false
	for _i in range(45):
		await physics_frame
		if p.is_on_floor() and absf(p.global_position.y - 188.0) < 4.0 and p.global_position.x >= 325.0:
			landed_stone1 = true
			break
	Input.action_release("move_right")
	_expect(landed_stone1, "L13 CliffLeft -> AirStone1 (330, 188) physically reachable without dash (pos=%s)" % str(p.global_position))
	_expect(not pu.is_triggered and not fs.is_triggered, "L13 valley traps do NOT trigger while player is on high AirStone1")

	# Place player in valley (420, 425) -> FallingSpikeValley1 triggers and grounds at y~399
	p.global_position = Vector2(420.0, 425.0)
	await _step_physics(2)
	_expect(fs.is_triggered, "L13 FallingSpikeValley1 triggers when player is in valley")
	p.global_position = Vector2(260.0, 425.0)
	await _step_physics(55)
	_expect(fs.is_grounded and fs.global_position.y >= 390.0, "L13 FallingSpikeValley1 impacts ValleyFloor cleanly (y=%.1f)" % fs.global_position.y)

	inst.queue_free()
	await process_frame

func _test_level_15_chandelier_shortcut_and_bowl_isolation() -> void:
	var inst := _load_level_node(15)
	await _step_physics(4)
	_expect(inst.get_node_or_null("Platforms/DisguisedCenterLedge") == null, "L15 blatant DisguisedCenterLedge removed")
	var pe = inst.get_node_or_null("Paranormal/ParanormalEvent")
	var bar = pe.get_node_or_null("ChandelierBar")
	_expect(bar != null, "L15 standable ChandelierBar exists")
	var p = inst.get_node_or_null("Player")
	var rb = inst.get_node_or_null("Traps/RollingBoulderBowl")
	var pu = inst.get_node_or_null("Traps/PopUpBowl")

	# Jump + dash right from BalconyLeft edge (198, 240) onto ChandelierBar (428..532, y=174)
	p.is_invulnerable = false
	p.global_position = Vector2(198.0, 240.0)
	Input.action_press("move_right")
	Input.action_press("jump")
	await _step_physics(2)
	Input.action_release("jump")
	await _step_physics(8)
	Input.action_press("dash")
	await _step_physics(2)
	Input.action_release("dash")
	var landed_chandelier := false
	for _i in range(45):
		await physics_frame
		if p.is_on_floor() and absf(p.global_position.y - 174.0) < 4.0 and p.global_position.x >= 420.0 and p.global_position.x <= 540.0:
			landed_chandelier = true
			break
	Input.action_release("move_right")
	_expect(landed_chandelier, "L15 BalconyLeft -> ChandelierBar reachable via jump+dash (pos=%s)" % str(p.global_position))
	_expect(not rb.is_triggered and not pu.is_triggered, "L15 bowl traps do NOT trigger while player is up on chandelier")

	# Now jump from ChandelierBar (525, 174) to BalconyRight (745, 240) without dash!
	p.global_position = Vector2(525.0, 174.0)
	p.velocity = Vector2.ZERO
	await _step_physics(2)
	Input.action_press("move_right")
	Input.action_press("jump")
	await _step_physics(2)
	Input.action_release("jump")
	var landed_right := false
	for _i in range(60):
		await physics_frame
		if p.is_on_floor() and absf(p.global_position.y - 240.0) < 4.0 and p.global_position.x >= 740.0:
			landed_right = true
			break
	Input.action_release("move_right")
	_expect(landed_right, "L15 ChandelierBar -> BalconyRight reachable via clean jump (pos=%s)" % str(p.global_position))

	# Verify ChandelierBar dynamically tracks drawn swinging chandelier during active camera tilt (<1px drift)
	p.global_position = Vector2(190.0, 240.0)
	await _step_physics(90)
	var swing_v: float = -float(pe._cam_tilt_rad) * 0.72 + sin(float(pe.timer) * 1.7) * 0.02
	var drawn_hub := Vector2(480.0, 48.0) + Vector2(sin(swing_v), cos(swing_v)) * 122.0
	var bar_center_x: float = bar.position.x + 52.0
	var drift_x: float = absf(drawn_hub.x - bar_center_x)
	_expect(drift_x < 1.5, "L15 ChandelierBar tracks swaying chandelier tightly during room tilt (drift=%.2f px)" % drift_x)

	inst.queue_free()
	await process_frame

func _test_level_16_dodging_platform_isolation_and_return() -> void:
	var inst := _load_level_node(16)
	await _step_physics(4)
	var p = inst.get_node_or_null("Player")
	var dp = inst.get_node_or_null("Traps/DodgingShortcut")

	p.is_invulnerable = false
	Input.action_press("move_right")
	await _step_physics(25)
	Input.action_release("move_right")
	_expect(not dp.is_triggered, "L16 DodgingShortcut does NOT trigger from LowerFloor")

	p.global_position = Vector2(95.0, 325.0)
	await _step_physics(20)
	_expect(dp.is_triggered and dp.position.x > 130.0, "L16 DodgingShortcut dodges to x=147 when approached at its level (x=%.1f)" % dp.position.x)

	p.global_position = Vector2(300.0, 410.0)
	await _step_physics(120)
	_expect(not dp.is_triggered and absf(dp.position.x - 32.0) < 2.0, "L16 DodgingShortcut returns cleanly to origin instead of staying stuck halfway (x=%.1f)" % dp.position.x)

	inst.queue_free()
	await process_frame

func _test_level_06_dodging_betrayal() -> void:
	var inst := _load_level_node(6)
	await _step_physics(4)
	var p = inst.get_node_or_null("Player")
	var dp = inst.get_node_or_null("Traps/DodgingMid")

	p.is_invulnerable = false
	p.global_position = Vector2(410.0, 380.0)
	await _step_physics(20)
	_expect(dp.is_triggered and dp._dodge_finished, "L06 DodgingMid completes initial dodge cleanly")
	p.global_position = Vector2(530.0, 380.0)
	await _step_physics(40)
	_expect(dp._betray_triggered and dp.position.y > 540.0, "L06 DodgingMid betrays and drops cleanly off-screen (y=%.1f)" % dp.position.y)

	inst.queue_free()
	await process_frame

func _test_level_20_monolith_trigger_and_subtle_stairs() -> void:
	var inst := _load_level_node(20)
	await _step_physics(4)
	var p = inst.get_node_or_null("Player")
	var pe = inst.get_node_or_null("Paranormal/ParanormalEvent")
	var stairs = inst.get_node_or_null("Platforms/SpectralStairs")

	p.is_invulnerable = false
	p.global_position = Vector2(280.0, 410.0)
	await _step_physics(6)
	_expect(not pe.triggered and not stairs.visible, "L20 monolith does NOT crack early at x=280")

	p.global_position = Vector2(465.0, 410.0)
	await _step_physics(6)
	_expect(pe.triggered and stairs.visible and stairs.modulate.a <= 0.40, "L20 monolith cracks at x>=450 and reveals subtle shadowy stairs (alpha=%.2f)" % stairs.modulate.a)

	inst.queue_free()
	await process_frame

func _test_level_04_10_12_15_extra_edge_cases() -> void:
	# L04 FallingCeiling1 must slam directly into FALLING (state==2), never FAKEOUT_PAUSE (state==1)
	var inst04 := _load_level_node(4)
	await _step_physics(4)
	var p04 = inst04.get_node_or_null("Player")
	var fc04 = inst04.get_node_or_null("Traps/FallingCeiling1")
	p04.is_invulnerable = false
	p04.global_position = Vector2(460.0, 380.0)
	await _step_physics(2)
	_expect(fc04.state == 2, "L04 FallingCeiling1 enters FALLING directly without FAKEOUT_PAUSE (state=%d)" % fc04.state)
	inst04.queue_free()
	await process_frame

	# L10 FakeWallCover has subtle_crack==false & AtticStep->UpperDeck is reachable
	var inst10 := _load_level_node(10)
	await _step_physics(4)
	var fw10 = inst10.get_node_or_null("Platforms/FakeWallCover")
	var p10 = inst10.get_node_or_null("Player")
	_expect(fw10 != null and fw10.subtle_crack == false, "L10 FakeWallCover has subtle_crack == false")
	p10.is_invulnerable = false
	p10.global_position = Vector2(75.0, 318.0)
	await _step_physics(2)
	Input.action_press("move_right")
	Input.action_press("jump")
	await _step_physics(2)
	Input.action_release("jump")
	var reached_upper10 := false
	for _i in range(45):
		await physics_frame
		if p10.is_on_floor() and absf(p10.global_position.y - 225.0) < 4.0:
			reached_upper10 = true
			break
	Input.action_release("move_right")
	_expect(reached_upper10, "L10 AtticStep -> UpperDeck shortcut climb works (pos=%s)" % str(p10.global_position))
	inst10.queue_free()
	await process_frame

	# L12 FakeWallLeftNotch has subtle_crack==false, PopUpUpper stays dormant underneath, and disabled ExitDoor produces zero errors past reset_cooldown
	var inst12 := _load_level_node(12)
	await _step_physics(4)
	var fw12 = inst12.get_node_or_null("Platforms/FakeWallLeftNotch")
	var p12 = inst12.get_node_or_null("Player")
	var pu12 = inst12.get_node_or_null("Traps/PopUpUpper")
	var ed12 = inst12.get_node_or_null("ExitDoor")
	_expect(fw12 != null and fw12.subtle_crack == false, "L12 FakeWallLeftNotch has subtle_crack == false")
	p12.is_invulnerable = false
	p12.global_position = Vector2(470.0, 410.0)
	await _step_physics(30) # passes exit_door reset_cooldown (0.40s) while monitoring==false
	_expect(not pu12.is_triggered, "L12 PopUpUpper stays dormant when player walks on LowerFloor underneath")
	_expect(ed12 != null and not ed12.monitoring, "L12 real ExitDoor remains hidden/non-monitoring cleanly before fake win glitch")
	inst12.queue_free()
	await process_frame

	# L15 FallingSpikeBowl2 (pass_through_platforms=false) stays dormant when player walks UNDER BowlStepRight (y=415),
	# and ONLY triggers when player climbs ONTO BowlStepRight (y=330 -> impacts at y~304)
	var inst15 := _load_level_node(15)
	await _step_physics(4)
	var p15 = inst15.get_node_or_null("Player")
	var fs15 = inst15.get_node_or_null("Traps/FallingSpikeBowl2")
	p15.is_invulnerable = false
	p15.global_position = Vector2(690.0, 415.0)
	p15.velocity = Vector2.ZERO
	await _step_physics(15)
	_expect(not fs15.is_triggered, "L15 FallingSpikeBowl2 stays DORMANT when player is under BowlStepRight on BowlFloor (y=415)")
	p15.global_position = Vector2(690.0, 330.0)
	await _step_physics(2)
	_expect(fs15.is_triggered, "L15 FallingSpikeBowl2 triggers for player on BowlStepRight")
	p15.global_position = Vector2(560.0, 415.0)
	await _step_physics(55)
	_expect(fs15.is_grounded and absf(fs15.global_position.y - 304.0) < 6.0, "L15 FallingSpikeBowl2 (pass_through=false) impacts BowlStepRight at y~304 (y=%.1f)" % fs15.global_position.y)
	inst15.queue_free()
	await process_frame

func _test_universal_vertical_filters_all_traps() -> void:
	# Verify every single active trap scene exports trigger_y_min and trigger_y_max
	var trap_scenes := [
		"res://scenes/traps/crusher.tscn",
		"res://scenes/traps/falling_ceiling.tscn",
		"res://scenes/traps/falling_spike.tscn",
		"res://scenes/traps/moving_saw.tscn",
		"res://scenes/traps/rolling_boulder.tscn",
		"res://scenes/traps/spikes.tscn",
		"res://scenes/traps/pop_up_spikes.tscn",
		"res://scenes/traps/jumping_spikes.tscn",
		"res://scenes/traps/dodging_platform.tscn",
		"res://scenes/traps/fake_door.tscn",
		"res://scenes/traps/trap_floor.tscn",
		"res://scenes/traps/spring.tscn",
		"res://scenes/traps/crumbling_platform.tscn",
	]
	for path in trap_scenes:
		var ps := load(path) as PackedScene
		var inst := ps.instantiate()
		_expect(("trigger_y_min" in inst) and ("trigger_y_max" in inst), "Trap %s exports trigger_y_min & trigger_y_max" % path.get_file())
		inst.queue_free()
	await process_frame

	# Verify DodgingPlatform default bounds protect against upper-floor triggering (110px above)
	var dp_ps := load("res://scenes/traps/dodging_platform.tscn") as PackedScene
	var dp = dp_ps.instantiate()
	dp.position = Vector2(200.0, 380.0)
	dp.trigger_distance = 130.0
	root.add_child(dp)
	var p_scn := load("res://scenes/player/player.tscn") as PackedScene
	var p = p_scn.instantiate()
	p.position = Vector2(245.0, 270.0)
	root.add_child(p)
	p.is_invulnerable = false
	await _step_physics(4)
	_expect(not dp.is_triggered, "DodgingPlatform default vertical bounds ignore player on upper floor 110px above")
	dp.queue_free()
	p.queue_free()
	await process_frame

func _test_json_arena_sync_1_to_20() -> void:
	var f := FileAccess.open("res://data/levels.json", FileAccess.READ)
	_expect(f != null, "data/levels.json opens cleanly")
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	_expect(parsed is Array and parsed.size() >= 20, "data/levels.json parses with >=20 entries")
	var arena_scn := load("res://scenes/levels/level_arena.tscn") as PackedScene
	for i in range(20):
		var d: Dictionary = parsed[i]
		var arena = arena_scn.instantiate()
		root.add_child(arena)
		arena.load_level_from_data(d)
		_expect(arena.level_number == i + 1, "LevelArena loads JSON level %02d cleanly" % (i + 1))
		arena.queue_free()

		# Deep parity check between data/levels.json and scenes/levels/level_XX.tscn
		var lvl_node := _load_level_node(i + 1)
		var p_node = lvl_node.get_node("Player")
		var ed_node = lvl_node.get_node("ExitDoor")
		var j_spawn: Array = d.get("player_spawn", [])
		var j_door: Array = d.get("door_pos", [])
		var parity_ok := true
		if absf(float(j_spawn[0]) - p_node.position.x) > 1.0 or absf(float(j_spawn[1]) - p_node.position.y) > 1.0:
			parity_ok = false
		if absf(float(j_door[0]) - ed_node.position.x) > 1.0 or absf(float(j_door[1]) - ed_node.position.y) > 1.0:
			parity_ok = false
		var t_traps := lvl_node.get_node("Traps").get_children()
		var j_traps: Array = d.get("traps", [])
		if t_traps.size() != j_traps.size():
			parity_ok = false
		else:
			for ti in range(t_traps.size()):
				var tt = t_traps[ti]
				var jt: Dictionary = j_traps[ti]
				if absf(float(jt.get("x", -999)) - tt.position.x) > 1.0 or absf(float(jt.get("y", -999)) - tt.position.y) > 1.0:
					parity_ok = false
				var jp: Dictionary = jt.get("params", {})
				for prop in ["trigger_y_min", "trigger_y_max", "pass_through_platforms", "stop_min_y", "returns_to_origin", "fakeout_first"]:
					if prop in tt:
						var tv = tt.get(prop)
						var non_def: bool = (
							(prop == "trigger_y_min" and float(tv) > -9000.0)
							or (prop == "trigger_y_max" and float(tv) < 9000.0)
							or (prop == "pass_through_platforms" and bool(tv))
							or (prop == "stop_min_y" and float(tv) > 0.0)
							or (prop == "returns_to_origin" and bool(tv))
						)
						if non_def and not jp.has(prop):
							parity_ok = false
						elif jp.has(prop):
							if typeof(tv) == TYPE_FLOAT and absf(float(jp[prop]) - float(tv)) > 0.05:
								parity_ok = false
							elif typeof(tv) == TYPE_BOOL and bool(jp[prop]) != bool(tv):
								parity_ok = false
		_expect(parity_ok, "JSON L%02d matches level_%02d.tscn spawn, door, trap positions & params" % [i + 1, i + 1])
		lvl_node.queue_free()
		await process_frame
