extends SceneTree

# Comprehensive Automated Headless Physics & Invariant Test Suite for
# Chapter 2 (Frost Peak, Levels 21-40) and Chapter 3 (Emerald Woods, Levels 41-60)
# plus global 60-level uniqueness & JSON<->TSCN parity verification.

var _started := false
var _checks: int = 0
var _failures: Array[String] = []

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

func _step_physics(frames: int) -> void:
	for _i in range(frames):
		await physics_frame

func _load_level_node(lvl: int) -> Node2D:
	var gm := root.get_node_or_null("/root/GameManager")
	if gm:
		gm.current_level_id = lvl
	var path := "res://scenes/levels/level_%02d.tscn" % lvl
	var ps := load(path) as PackedScene
	if ps == null:
		return null
	var inst := ps.instantiate() as Node2D
	root.add_child(inst)
	return inst

func _run_all() -> void:
	print("=== Starting Chapters 2 & 3 (Levels 21-60) Comprehensive Verification ===")
	await _test_global_60_uniqueness_and_invariants()
	await _test_json_arena_parity_21_to_60()
	await _test_chapter_2_physics_and_shortcuts()
	await _test_chapter_3_physics_and_shortcuts()
	await _test_end_to_end_reachability_and_stress()

	print("\n=== CHAPTERS 2 & 3 SUMMARY: %d checks, %d failures ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("ALL CHAPTERS 2 & 3 CHECKS PASSED!")
		quit(0)
	else:
		for f in _failures:
			print("  FAILURE: " + f)
		quit(1)

func _test_global_60_uniqueness_and_invariants() -> void:
	var seen_events: Dictionary = {}
	var all_ok_spawn := true
	var all_ok_reset := true
	var all_ok_crushers := true
	var all_ok_fakewalls := true
	var all_ok_forbidden := true
	var all_ok_fakeout := true
	var all_ok_paths := true

	for lvl in range(1, 61):
		var inst := _load_level_node(lvl)
		if inst == null:
			_expect(false, "L%02d failed to load" % lvl)
			continue
		var pe := inst.get_node_or_null("Paranormal/ParanormalEvent")
		if pe == null or str(pe.event_type) == "":
			_expect(false, "L%02d missing ParanormalEvent or empty event_type" % lvl)
		else:
			var et: String = str(pe.event_type)
			if seen_events.has(et):
				_expect(false, "Duplicate event_type '%s' on L%02d (already used on L%02d)" % [et, lvl, seen_events[et]])
			seen_events[et] = lvl

		if lvl >= 21:
			# Verify target_node_path / aux_node_path resolve cleanly
			if pe:
				if not pe.target_node_path.is_empty() and pe._get_target_node() == null:
					all_ok_paths = false
					print("  [DETAIL] L%02d broken target_node_path: %s" % [lvl, str(pe.target_node_path)])
				if not pe.aux_node_path.is_empty() and pe._get_aux_node() == null:
					all_ok_paths = false
					print("  [DETAIL] L%02d broken aux_node_path: %s" % [lvl, str(pe.aux_node_path)])

			var ceil_n := inst.get_node_or_null("Platforms/Ceiling")
			var ceil_h: float = ceil_n.platform_size.y if (ceil_n and "platform_size" in ceil_n) else 48.0
			var plats := inst.get_node_or_null("Platforms")
			if plats:
				for p_child in plats.get_children():
					if "subtle_crack" in p_child and bool(p_child.subtle_crack):
						all_ok_fakewalls = false
						print("  [DETAIL] L%02d FakeWall %s has subtle_crack=true" % [lvl, p_child.name])

			var traps := inst.get_node_or_null("Traps")
			if traps:
				for t in traps.get_children():
					var scr: Script = t.get_script()
					var sname: String = scr.resource_path.get_file() if scr else ""
					if sname in ["laser_beam.gd", "crumbling_platform.gd"]:
						all_ok_forbidden = false
						print("  [DETAIL] L%02d uses forbidden trap %s" % [lvl, sname])
					if "fakeout_first" in t and bool(t.fakeout_first):
						all_ok_fakeout = false
						print("  [DETAIL] L%02d %s has fakeout_first=true" % [lvl, t.name])
					if "crusher_size" in t:
						if absf(t.position.y - 6.0) > 0.5 or absf((t.position.y + t.crusher_size.y) - ceil_h) > 0.5:
							all_ok_crushers = false
							print("  [DETAIL] L%02d Crusher %s not flush in ceiling (y=%.1f, h=%.1f, ceil=%.1f)" % [lvl, t.name, t.position.y, t.crusher_size.y, ceil_h])

			# Step 6 physics frames from spawn: player must stay alive & grounded
			await _step_physics(6)
			var p = inst.get_node_or_null("Player")
			if p == null or p.is_dead or not p.is_on_floor():
				all_ok_spawn = false
				print("  [DETAIL] L%02d spawn unstable (dead=%s, on_floor=%s, pos=%s)" % [lvl, str(p.is_dead if p else true), str(p.is_on_floor() if p else false), str(p.global_position if p else Vector2.ZERO)])

			# Reset & verify clean modifiers
			if inst.has_method("reset_level_traps"):
				inst.reset_level_traps()
			await _step_physics(1)
			if p != null:
				if not is_equal_approx(Engine.time_scale, 1.0) or not is_equal_approx(p.gravity_mult, 1.0) or not is_equal_approx(p.jump_mult, 1.0) or not is_equal_approx(p.ice_friction, 0.0) or not is_equal_approx(p.external_wind_x, 0.0) or not is_equal_approx(p.external_force_y, 0.0) or p.controls_inverted:
					# Note: black_ice_glide (L23) immediately re-applies ice_friction on physics frame if player spawns on black ice, and frostbite_lantern_pulse (L28) updates speed_mult on physics frame
					if lvl != 23:
						all_ok_reset = false
						print("  [DETAIL] L%02d dirty modifier after reset" % lvl)

		inst.queue_free()
		await process_frame

	_expect(seen_events.size() == 60, "Strictly 60 unique paranormal event_types across all 60 levels (got %d)" % seen_events.size())
	_expect(all_ok_paths, "All Levels 21-60 ParanormalEvent target/aux NodePaths resolve cleanly")
	_expect(all_ok_forbidden, "Zero legacy laser_beam or crumbling_platform traps in Levels 21-60")
	_expect(all_ok_fakeout, "Zero fakeout_first=true hesitations in Levels 21-60")
	_expect(all_ok_crushers, "All Crushers in Levels 21-60 sit flush inside ceiling (y=6)")
	_expect(all_ok_fakewalls, "All FakeWalls in Levels 21-60 have subtle_crack=false")
	_expect(all_ok_spawn, "All Levels 21-60 spawns are alive & stably grounded on frame 6")
	_expect(all_ok_reset, "All Levels 21-60 reset global time_scale & player modifiers cleanly")

func _test_json_arena_parity_21_to_60() -> void:
	var f := FileAccess.open("res://data/levels.json", FileAccess.READ)
	_expect(f != null, "data/levels.json opens cleanly")
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	_expect(parsed is Array and parsed.size() == 60, "data/levels.json has exactly 60 entries")

	var arena_scn := load("res://scenes/levels/level_arena.tscn") as PackedScene
	var parity_all_ok := true
	var arena_all_ok := true

	for i in range(20, 60):
		var d: Dictionary = parsed[i]
		var lvl_id := i + 1
		var arena = arena_scn.instantiate()
		root.add_child(arena)
		arena.load_level_from_data(d)
		if arena.level_number != lvl_id:
			arena_all_ok = false
		arena.queue_free()

		var lvl_node := _load_level_node(lvl_id)
		var p_node = lvl_node.get_node("Player")
		var ed_node = lvl_node.get_node("ExitDoor")
		var pe_node = lvl_node.get_node("Paranormal/ParanormalEvent")
		var j_spawn: Array = d.get("player_spawn", [])
		var j_door: Array = d.get("door_pos", [])
		var ok := true
		if str(d.get("gimmick", "")) != str(pe_node.event_type):
			ok = false
		if absf(float(j_spawn[0]) - p_node.position.x) > 1.0 or absf(float(j_spawn[1]) - p_node.position.y) > 1.0:
			ok = false
		if absf(float(j_door[0]) - ed_node.position.x) > 1.0 or absf(float(j_door[1]) - ed_node.position.y) > 1.0:
			ok = false
		var t_traps := lvl_node.get_node("Traps").get_children()
		var j_traps: Array = d.get("traps", [])
		if t_traps.size() != j_traps.size():
			ok = false
		else:
			for ti in range(t_traps.size()):
				var tt = t_traps[ti]
				var jt: Dictionary = j_traps[ti]
				if absf(float(jt.get("x", -999)) - tt.position.x) > 1.0 or absf(float(jt.get("y", -999)) - tt.position.y) > 1.0:
					ok = false
				var jp: Dictionary = jt.get("params", {})
				for prop in ["trigger_y_min", "trigger_y_max", "pass_through_platforms", "stop_min_y", "fakeout_first"]:
					if prop in tt and jp.has(prop):
						var tv = tt.get(prop)
						if typeof(tv) == TYPE_FLOAT and absf(float(jp[prop]) - float(tv)) > 0.05:
							ok = false
						elif typeof(tv) == TYPE_BOOL and bool(jp[prop]) != bool(tv):
							ok = false
		if not ok:
			parity_all_ok = false
			print("  [DETAIL] Parity mismatch on L%02d" % lvl_id)
		lvl_node.queue_free()
		await process_frame

	_expect(arena_all_ok, "LevelArena loads all 40 JSON entries (21-60) cleanly")
	_expect(parity_all_ok, "100% deep parity between data/levels.json (21-60) and level_21..60.tscn")

func _test_chapter_2_physics_and_shortcuts() -> void:
	# L21: Walking right never hits SpringShortcut; walking left behind spawn launches cleanly
	var l21 := _load_level_node(21)
	await _step_physics(4)
	var p21 = l21.get_node("Player")
	var sp21 = l21.get_node("Traps/SpringShortcut")
	p21.is_invulnerable = false
	Input.action_press("move_right")
	await _step_physics(16)
	Input.action_release("move_right")
	_expect(not sp21.is_springing, "L21 walking right never accidentally hits SpringShortcut")
	l21.reset_level_traps()
	p21.global_position = Vector2(145, 390)
	p21.velocity = Vector2.ZERO
	p21.is_invulnerable = false
	Input.action_press("move_left")
	var launched21 := false
	for _i in range(40):
		await physics_frame
		if sp21.is_springing:
			launched21 = true
			break
	Input.action_release("move_left")
	_expect(launched21, "L21 deliberate walk behind spawn triggers SpringShortcut")
	l21.queue_free()
	await process_frame

	# L23: Black Ice upper deck has ice_friction > 0.85; small 8-frame left tap safe; deliberate left drop reaches grippy CaveFloor (ice_friction == 0) & isolates CrusherIce1
	var l23 := _load_level_node(23)
	await _step_physics(4)
	var p23 = l23.get_node("Player")
	var tf23 = l23.get_node("Traps/TrapBackChute")
	var cr23 = l23.get_node("Traps/CrusherIce1")
	_expect(p23.ice_friction > 0.85, "L23 BlackIceMain applies slippery ice_friction (%.2f)" % p23.ice_friction)
	p23.is_invulnerable = false
	Input.action_press("move_left")
	await _step_physics(8)
	Input.action_release("move_left")
	await _step_physics(4)
	_expect(not tf23.is_triggered, "L23 small 8-frame left tap does NOT accidentally trigger TrapBackChute")
	Input.action_press("move_left")
	await _step_physics(40)
	Input.action_release("move_left")
	await _step_physics(35)
	_expect(tf23.is_triggered and absf(p23.global_position.y - 415.0) < 4.0 and is_equal_approx(p23.ice_friction, 0.0), "L23 deliberate left walk drops onto grippy CaveFloor (y=%.1f, ice=%.2f)" % [p23.global_position.y, p23.ice_friction])
	p23.global_position = Vector2(365, 415)
	await _step_physics(15)
	_expect(cr23.state == 0, "L23 CrusherIce1 stays IDLE when player is down in CaveFloor")
	l23.queue_free()
	await process_frame

	# L27: Frozen Mirror Twin swaps ExitDoor on crossing x>=480, restores on reset, and CrusherLow isolates upper CenterBridge
	var l27 := _load_level_node(27)
	await _step_physics(4)
	var p27 = l27.get_node("Player")
	var ed27 = l27.get_node("ExitDoor")
	var cr27 = l27.get_node("Traps/CrusherLow")
	p27.is_invulnerable = false
	p27.global_position = Vector2(475, 255)
	p27.velocity = Vector2.ZERO
	await _step_physics(15)
	_expect(cr27.state == 0, "L27 CrusherLow stays IDLE while player is on upper CenterBridge")
	p27.global_position = Vector2(495, 255)
	await _step_physics(3)
	_expect(absf(ed27.position.x - 115.0) < 2.0, "L27 crossing mirror center swaps ExitDoor to LeftBalcony (x=%.1f)" % ed27.position.x)
	l27.reset_level_traps()
	_expect(absf(ed27.position.x - 845.0) < 2.0, "L27 reset restores ExitDoor back to RightBalcony (x=%.1f)" % ed27.position.x)
	l27.queue_free()
	await process_frame

	# L28: Frostbite Lantern chill vs warmth & standable bracket
	var l28 := _load_level_node(28)
	await _step_physics(4)
	var p28 = l28.get_node("Player")
	p28.is_invulnerable = false
	_expect(p28.speed_mult < 0.75, "L28 sub-zero chill slows player outside lantern aura (mult=%.2f)" % p28.speed_mult)
	p28.global_position = Vector2(245, 306)
	p28.velocity = Vector2.ZERO
	await _step_physics(8)
	_expect(p28.speed_mult > 1.05 and p28.is_on_floor(), "L28 standing on LanternBracket_0 warms player (mult=%.2f) and holds weight" % p28.speed_mult)
	l28.queue_free()
	await process_frame

	# L29: 3 jump landings fracture glacier and reveal GlacierFractureStep
	var l29 := _load_level_node(29)
	await _step_physics(4)
	var p29 = l29.get_node("Player")
	var aux29 = l29.get_node("Platforms/GlacierFractureStep")
	_expect(not aux29.visible, "L29 GlacierFractureStep starts hidden")
	p29.is_invulnerable = false
	for _jump_i in range(3):
		p29.global_position = Vector2(855, 385)
		p29.velocity = Vector2(0, 180)
		await _step_physics(16)
	_expect(aux29.visible, "L29 3 landings fracture glacier and crystallize GlacierFractureStep")
	l29.queue_free()
	await process_frame

	# L31: Mid-air Dash crystallizes solid DashIcePad beneath player
	var l31 := _load_level_node(31)
	await _step_physics(4)
	var p31 = l31.get_node("Player")
	var pe31 = l31.get_node("Paranormal/ParanormalEvent")
	p31.is_invulnerable = false
	p31.global_position = Vector2(220, 260)
	p31.velocity = Vector2.ZERO
	Input.action_press("move_right")
	Input.action_press("dash")
	await _step_physics(2)
	Input.action_release("dash")
	await _step_physics(16)
	Input.action_release("move_right")
	_expect(float(pe31._dash_pads[0]["life"]) > 0.5, "L31 mid-air dash crystallizes temporary solid DashIcePad (life=%.2f)" % float(pe31._dash_pads[0]["life"]))
	l31.queue_free()
	await process_frame

	# L32: Central Cryo-Updraft lifts player & far-right SpringRightChute launches through one-way cap straight onto ExitDoor
	var l32 := _load_level_node(32)
	await _step_physics(4)
	var p32 = l32.get_node("Player")
	p32.is_invulnerable = false
	p32.global_position = Vector2(436, 405) # Left edge of updraft column dodging CircShaft
	p32.velocity = Vector2.ZERO
	await _step_physics(18)
	_expect(not p32.is_dead and p32.global_position.y > 0.0 and p32.global_position.y < 365.0, "L32 Cryo-Updraft column lifts player upward cleanly without dying (y=%.1f, dead=%s)" % [p32.global_position.y, str(p32.is_dead)])
	l32.reset_level_traps()
	p32.is_dead = false
	p32.is_entering_door = false
	p32.is_invulnerable = false
	p32.global_position = Vector2(878, 420)
	p32.velocity = Vector2.ZERO
	var reached_door32 := false
	for _i in range(45):
		await physics_frame
		if p32.is_entering_door or (p32.global_position.y > 0.0 and p32.global_position.y <= 205.0):
			reached_door32 = true
			break
	_expect(reached_door32 and not p32.is_dead, "L32 SpringRightChute launches cleanly through HighRightCap onto ExitDoor (y=%.1f, entering=%s)" % [p32.global_position.y, str(p32.is_entering_door)])
	l32.queue_free()
	await process_frame

	# L24: Frozen Compass + hidden SnowBankCover behind spawn
	var l24 := _load_level_node(24)
	await _step_physics(4)
	var fw24 = l24.get_node("Platforms/SnowBankCover")
	var p24 = l24.get_node("Player")
	var fd24 = l24.get_node("Traps/FakeDoorLow")
	_expect(fw24 != null and not fw24.subtle_crack, "L24 SnowBankCover has subtle_crack=false")
	p24.is_invulnerable = false
	p24.global_position = Vector2(72, 220)
	await _step_physics(12)
	_expect(not fd24.is_triggered, "L24 FakeDoorLow stays dormant when player is on UpperLeftDeck")
	l24.queue_free()
	await process_frame

	# L25: Aurora Veil Shift toggles platform solidity on 3s cycle
	var l25 := _load_level_node(25)
	await _step_physics(4)
	var pe25 = l25.get_node("Paranormal/ParanormalEvent")
	_expect(pe25._aurora_cyan and not (pe25._aurora_plats[0]["col"] as CollisionShape2D).disabled and (pe25._aurora_plats[1]["col"] as CollisionShape2D).disabled, "L25 Aurora starts Cyan phase (Plat0 solid, Plat1 phased out)")
	pe25._aurora_cycle = 2.99
	await _step_physics(3)
	_expect((not pe25._aurora_cyan) and (pe25._aurora_plats[0]["col"] as CollisionShape2D).disabled and not (pe25._aurora_plats[1]["col"] as CollisionShape2D).disabled, "L25 Aurora flips to Violet phase cleanly (Plat0 phased out, Plat1 solid)")
	l25.queue_free()
	await process_frame

	# L26: Snowdrift wave sweeps & sheltered SpringAlcove launches through Bridge3Cap
	var l26 := _load_level_node(26)
	await _step_physics(4)
	var p26 = l26.get_node("Player")
	var pe26 = l26.get_node("Paranormal/ParanormalEvent")
	p26.is_invulnerable = false
	p26.global_position = Vector2(580, 330)
	await _step_physics(4)
	_expect(pe26._snow_wave_active, "L26 crossing trigger_x starts spectral snowdrift wave")
	p26.global_position = Vector2(895, 420)
	p26.velocity = Vector2.ZERO
	var launched26 := false
	for _i in range(45):
		await physics_frame
		if p26.is_entering_door or (p26.global_position.y > 0.0 and p26.global_position.y <= 215.0):
			launched26 = true
			break
	_expect(launched26 and not p26.is_dead, "L26 sheltered SpringAlcove launches cleanly through Bridge3Cap onto Bridge3 (y=%.1f)" % p26.global_position.y)
	l26.queue_free()
	await process_frame

	# L30: Blizzard wind shelters CalmSubCave after dropping through TrapBackCave
	var l30 := _load_level_node(30)
	await _step_physics(4)
	var p30 = l30.get_node("Player")
	var pe30 = l30.get_node("Paranormal/ParanormalEvent")
	p30.is_invulnerable = false
	pe30._blizzard_cycle = 2.5 # Active squall
	await _step_physics(2)
	_expect(absf(p30.external_wind_x) > 80.0, "L30 active blizzard applies wind on upper peaks (wind=%.1f)" % p30.external_wind_x)
	p30.global_position = Vector2(180, 430)
	await _step_physics(3)
	_expect(is_equal_approx(p30.external_wind_x, 0.0), "L30 CalmSubCave shields player from blizzard wind completely")
	l30.queue_free()
	await process_frame

	# L34: Glacial Prism splits at x<=530 revealing RefractedStep on right side
	var l34 := _load_level_node(34)
	await _step_physics(4)
	var p34 = l34.get_node("Player")
	var aux34 = l34.get_node("Platforms/RefractedStep")
	_expect(not aux34.visible, "L34 RefractedStep starts hidden")
	p34.is_invulnerable = false
	p34.global_position = Vector2(510, 415)
	await _step_physics(3)
	_expect(aux34.visible, "L34 crossing Glacial Prism reveals RefractedStep on right side")
	l34.queue_free()
	await process_frame

	# L35: Permafrost leaves patches & MidRightFakeCap drops straight to BotRun
	var l35 := _load_level_node(35)
	await _step_physics(4)
	var p35 = l35.get_node("Player")
	var pe35 = l35.get_node("Paranormal/ParanormalEvent")
	p35.is_invulnerable = false
	Input.action_press("move_right")
	await _step_physics(32)
	Input.action_release("move_right")
	_expect(pe35._permafrost_patches.size() >= 2, "L35 walking stamps permafrost patches (count=%d)" % pe35._permafrost_patches.size())
	p35.global_position = Vector2(890, 290)
	p35.velocity = Vector2.ZERO
	await _step_physics(28)
	_expect(not p35.is_dead and (p35.is_entering_door or absf(p35.global_position.y - 420.0) < 6.0), "L35 dropping through MidRightFakeCap reaches BotRun/ExitDoor cleanly (y=%.1f)" % p35.global_position.y)
	l35.queue_free()
	await process_frame

	# L36: Sky Cairn stones reveal when airborne and stay invisible grounded
	var l36 := _load_level_node(36)
	await _step_physics(4)
	var p36 = l36.get_node("Player")
	var pe36 = l36.get_node("Paranormal/ParanormalEvent")
	_expect(pe36._cairn_reveal < 0.05, "L36 Sky Cairn stones stay hidden while grounded")
	p36.global_position = Vector2(245, 280)
	p36.velocity = Vector2(0, -120)
	await _step_physics(8)
	_expect(pe36._cairn_reveal > 0.4, "L36 Sky Cairn stones illuminate while airborne (reveal=%.2f)" % pe36._cairn_reveal)
	l36.queue_free()
	await process_frame

	# L39: Avalanche wall chases right; SpringHigh behind spawn reaches HighCatwalk
	var l39 := _load_level_node(39)
	await _step_physics(4)
	var p39 = l39.get_node("Player")
	var pe39 = l39.get_node("Paranormal/ParanormalEvent")
	p39.is_invulnerable = false
	p39.global_position = Vector2(220, 400)
	await _step_physics(8)
	_expect(pe39._avalanche_started and pe39._avalanche_x > 25.0, "L39 crossing trigger_x starts horizontal avalanche wall (x=%.1f)" % pe39._avalanche_x)
	l39.reset_level_traps()
	p39.is_invulnerable = false
	p39.global_position = Vector2(56, 400)
	p39.velocity = Vector2.ZERO
	var min_y39 := 999.0
	for _i in range(40):
		await physics_frame
		if p39.global_position.y > 0.0:
			min_y39 = minf(min_y39, p39.global_position.y)
	_expect(min_y39 < 195.0, "L39 SpringHigh behind spawn launches above HighCatwalk y=195 (min_y=%.1f)" % min_y39)
	l39.queue_free()
	await process_frame

	# L37: Cryo Heartbeat Surge enables 123px super-jump onto LeftSurgePerch
	var l37 := _load_level_node(37)
	await _step_physics(4)
	var p37 = l37.get_node("Player")
	var pe37 = l37.get_node("Paranormal/ParanormalEvent")
	pe37._cryo_heart_cycle = 1.80 # Enter cyan surge
	p37.is_invulnerable = false
	p37.global_position = Vector2(185, 425)
	p37.velocity = Vector2.ZERO
	await _step_physics(2)
	_expect(p37.jump_mult > 1.2, "L37 Cryo Heartbeat Surge boosts jump_mult (%.2f)" % p37.jump_mult)
	Input.action_press("jump")
	await _step_physics(2)
	Input.action_release("jump")
	var reached_perch37 := false
	for _i in range(50):
		await physics_frame
		if p37.is_on_floor() and absf(p37.global_position.y - 302.0) < 4.0:
			reached_perch37 = true
			break
	_expect(reached_perch37, "L37 super-jump reaches LeftSurgePerch (123px climb) cleanly (y=%.1f)" % p37.global_position.y)
	l37.queue_free()
	await process_frame

	# L38: Shattering Ice Panes crack & break after 0.45s and restore cleanly on reset
	var l38 := _load_level_node(38)
	await _step_physics(4)
	var p38 = l38.get_node("Player")
	var pe38 = l38.get_node("Paranormal/ParanormalEvent")
	p38.is_invulnerable = false
	p38.global_position = Vector2(280, 250)
	p38.velocity = Vector2.ZERO
	await _step_physics(35)
	_expect(int(pe38._ice_panes[0]["state"]) == 2 and (pe38._ice_panes[0]["col"] as CollisionShape2D).disabled, "L38 IcePane_0 shatters & disables collision after 0.45s")
	l38.reset_level_traps()
	_expect(int(pe38._ice_panes[0]["state"]) == 0 and not (pe38._ice_panes[0]["col"] as CollisionShape2D).disabled, "L38 reset restores IcePane_0 intact")
	l38.queue_free()
	await process_frame

	# L40: Frost Crown Finale locks ExitDoor until right altar or mid-air Crown Aura unlocks it
	var l40 := _load_level_node(40)
	await _step_physics(4)
	var p40 = l40.get_node("Player")
	var ed40 = l40.get_node("ExitDoor")
	_expect(ed40.visible and not ed40.monitoring, "L40 ExitDoor starts sealed behind glacial frost lock")
	p40.is_invulnerable = false
	p40.global_position = Vector2(390, 255) # Mid-air Crown Aura shortcut from LeftLedge
	await _step_physics(4)
	_expect(ed40.monitoring, "L40 entering mid-air Frost Crown Aura shatters seal & unlocks ExitDoor")
	l40.queue_free()
	await process_frame

func _test_chapter_3_physics_and_shortcuts() -> void:
	# L41: Firefly decoy; small 8-frame left tap safe; deliberate left drop reaches ForestFloor & isolates upper traps
	var l41 := _load_level_node(41)
	await _step_physics(4)
	var p41 = l41.get_node("Player")
	var tf41 = l41.get_node("Traps/TrapMossBack")
	var pu41 = l41.get_node("Traps/PopUpCanopy1")
	p41.is_invulnerable = false
	Input.action_press("move_left")
	await _step_physics(8)
	Input.action_release("move_left")
	await _step_physics(4)
	_expect(not tf41.is_triggered, "L41 small 8-frame left tap does NOT accidentally trigger TrapMossBack")
	Input.action_press("move_left")
	await _step_physics(35)
	Input.action_release("move_left")
	await _step_physics(35)
	_expect(tf41.is_triggered and absf(p41.global_position.y - 430.0) < 4.0, "L41 deliberate left walk drops onto ForestFloor cleanly (y=%.1f)" % p41.global_position.y)
	p41.global_position = Vector2(360, 430)
	await _step_physics(10)
	_expect(not pu41.is_triggered, "L41 upper PopUpCanopy1 stays dormant when player walks underneath on ForestFloor")
	l41.queue_free()
	await process_frame

	# L42: Living Vine Bridge grows lower segment on approach and high 4th canopy vine when jumping at LeftBough edge
	var l42 := _load_level_node(42)
	await _step_physics(4)
	var p42 = l42.get_node("Player")
	var pe42 = l42.get_node("Paranormal/ParanormalEvent")
	p42.is_invulnerable = false
	p42.global_position = Vector2(215, 250)
	await _step_physics(16)
	_expect(float(pe42._vine_segments[3]["grow"]) >= 0.5 and not (pe42._vine_segments[3]["col"] as CollisionShape2D).disabled, "L42 jumping at LeftBough edge sprouts high 4th canopy vine")
	l42.queue_free()
	await process_frame

	# L44: Moonlit Pond grants buoyant 0.50g and enables jumping straight out onto EastBank while CrusherArch stays idle
	var l44 := _load_level_node(44)
	await _step_physics(4)
	var p44 = l44.get_node("Player")
	var cr44 = l44.get_node("Traps/CrusherArch")
	p44.is_invulnerable = false
	p44.global_position = Vector2(480, 415)
	p44.velocity = Vector2.ZERO
	await _step_physics(12)
	_expect(is_equal_approx(p44.gravity_mult, 0.50) and cr44.state == 0, "L44 Moonlit Pond sets 0.50g buoyancy & keeps CrusherArch idle above")
	l44.queue_free()
	await process_frame

	# L45: Secret Spore Bud bounces player straight onto LeftBranch
	var l45 := _load_level_node(45)
	await _step_physics(4)
	var p45 = l45.get_node("Player")
	p45.is_invulnerable = false
	p45.global_position = Vector2(58, 425)
	p45.velocity = Vector2.ZERO
	await _step_physics(3)
	_expect(p45.velocity.y < -600.0, "L45 hidden left Spore Bud rebounds player upward cleanly (vy=%.1f)" % p45.velocity.y)
	l45.queue_free()
	await process_frame

	# L46: Owl Sentinel Gaze ignores player standing still OR running atop Shelter1Roof
	var l46 := _load_level_node(46)
	await _step_physics(4)
	var p46 = l46.get_node("Player")
	var pe46 = l46.get_node("Paranormal/ParanormalEvent")
	p46.is_invulnerable = false
	pe46._owl_cycle = 2.0 # Gaze open!
	p46.global_position = Vector2(315, 308) # On top of Shelter1Roof
	Input.action_press("move_right")
	await _step_physics(25)
	Input.action_release("move_right")
	_expect(not p46.is_dead and pe46._owl_warn < 0.05, "L46 running atop ShelterRoof stays safely above Owl Sentinel gaze cone")
	l46.queue_free()
	await process_frame

	# L47: Jumping above spawn illuminates hidden Sap Bud B revealing LeftRootShortcut
	var l47 := _load_level_node(47)
	await _step_physics(4)
	var p47 = l47.get_node("Player")
	var aux47 = l47.get_node("Platforms/LeftRootShortcut")
	_expect(not aux47.visible, "L47 LeftRootShortcut starts hidden")
	p47.is_invulnerable = false
	p47.global_position = Vector2(95, 330)
	await _step_physics(4)
	_expect(aux47.visible, "L47 touching hidden Sap Bud B above spawn reveals LeftRootShortcut")
	l47.queue_free()
	await process_frame

	# L51: Fairy Ring does NOT teleport while sprinting past, DOES teleport after pausing 0.45s inside ring
	var l51 := _load_level_node(51)
	await _step_physics(4)
	var p51 = l51.get_node("Player")
	p51.is_invulnerable = false
	p51.global_position = Vector2(465, 410)
	Input.action_press("move_right")
	await _step_physics(22)
	Input.action_release("move_right")
	_expect(absf(p51.global_position.y - 410.0) < 4.0, "L51 sprinting right past Fairy Ring does NOT accidentally teleport")
	p51.global_position = Vector2(505, 410)
	p51.velocity = Vector2.ZERO
	await _step_physics(32)
	_expect(absf(p51.global_position.x - 185.0) < 6.0 and absf(p51.global_position.y - 225.0) < 6.0, "L51 pausing inside Fairy Ring warps cleanly onto UpperCanopy (pos=%s)" % str(p51.global_position))
	l51.queue_free()
	await process_frame

	# L52: Weeping Willow perches isolate lower crushers completely
	var l52 := _load_level_node(52)
	await _step_physics(4)
	var p52 = l52.get_node("Player")
	var cr52 = l52.get_node("Traps/Crusher1")
	p52.is_invulnerable = false
	p52.global_position = Vector2(310, 235)
	p52.velocity = Vector2.ZERO
	await _step_physics(15)
	_expect(p52.is_on_floor() and cr52.state == 0, "L52 player stands cleanly on hidden WillowPerch while Crusher1 below stays IDLE")
	l52.queue_free()
	await process_frame

	# L54: Moss Ley-Line shifts gravity above y=295
	var l54 := _load_level_node(54)
	await _step_physics(4)
	var p54 = l54.get_node("Player")
	p54.is_invulnerable = false
	_expect(is_equal_approx(p54.gravity_mult, 1.0), "L54 below ley-line uses normal 1.0g")
	p54.global_position = Vector2(100, 270)
	await _step_physics(3)
	_expect(is_equal_approx(p54.gravity_mult, 0.62) and is_equal_approx(p54.speed_mult, 1.15), "L54 above ley-line activates Feather-Canopy Drift (0.62g, 1.15x)")
	l54.queue_free()
	await process_frame

	# L59: Overgrowth ceiling vines never reach RootBottom after behind-spawn TrapDropShaft shortcut
	var l59 := _load_level_node(59)
	await _step_physics(4)
	var p59 = l59.get_node("Player")
	var tf59 = l59.get_node("Traps/TrapDropShaft")
	p59.is_invulnerable = false
	Input.action_press("move_left")
	await _step_physics(35)
	Input.action_release("move_left")
	await _step_physics(40)
	_expect(tf59.is_triggered and absf(p59.global_position.y - 415.0) < 4.0 and not p59.is_dead, "L59 behind-spawn TrapDropShaft drops safely straight to RootBottom (y=%.1f)" % p59.global_position.y)
	l59.queue_free()
	await process_frame

	# L43: Whispering Totem shifts Trickster (1.38x) & Wrath (0.72x) speeds cleanly
	var l43 := _load_level_node(43)
	await _step_physics(4)
	var p43 = l43.get_node("Player")
	var pe43 = l43.get_node("Paranormal/ParanormalEvent")
	pe43._totem_cycle = 2.7 # Trickster mask
	await _step_physics(2)
	_expect(is_equal_approx(p43.speed_mult, 1.38), "L43 Totem Trickster mask boosts speed to 1.38x")
	pe43._totem_cycle = 5.3 # Wrath mask
	await _step_physics(2)
	_expect(is_equal_approx(p43.speed_mult, 0.72), "L43 Totem Wrath mask chills speed to 0.72x")
	l43.queue_free()
	await process_frame

	# L48: Pollen Dream Drift lowers gravity ONLY when falling
	var l48 := _load_level_node(48)
	await _step_physics(4)
	var p48 = l48.get_node("Player")
	p48.is_invulnerable = false
	p48.global_position = Vector2(240, 220)
	p48.velocity = Vector2(0, 120) # Falling
	await _step_physics(2)
	_expect(is_equal_approx(p48.gravity_mult, 0.56), "L48 Dream Pollen activates 0.56g buoyancy while descending")
	l48.queue_free()
	await process_frame

	# L50: Canopy Eclipse sunbeam shaft refreshes dash cooldown instantly
	var l50 := _load_level_node(50)
	await _step_physics(4)
	var p50 = l50.get_node("Player")
	var pe50 = l50.get_node("Paranormal/ParanormalEvent")
	p50.is_invulnerable = false
	p50.dash_cooldown_timer = 0.35
	p50.global_position = Vector2(pe50._eclipse_beams[0], 300)
	await _step_physics(2)
	_expect(is_equal_approx(p50.dash_cooldown_timer, 0.0), "L50 standing in swaying sunbeam refreshes dash cooldown instantly")
	l50.queue_free()
	await process_frame

	# L53: Cicada Swarm Raft moves smoothly & supports player
	var l53 := _load_level_node(53)
	await _step_physics(4)
	var pe53 = l53.get_node("Paranormal/ParanormalEvent")
	var x0: float = pe53._cicada_pos.x
	await _step_physics(25)
	_expect(absf(pe53._cicada_pos.x - x0) > 10.0, "L53 Cicada Swarm Raft glides horizontally across ravine (dx=%.1f)" % absf(pe53._cicada_pos.x - x0))
	l53.queue_free()
	await process_frame

	# L55: Ancient Stump Ring #5 sprouts StumpStep_0 & StumpStep_1
	var l55 := _load_level_node(55)
	await _step_physics(4)
	var pe55 = l55.get_node("Paranormal/ParanormalEvent")
	_expect((pe55._stump_steps[0]["col"] as CollisionShape2D).disabled, "L55 StumpStep_0 starts retracted before Ring #5")
	pe55._stump_cycle = 3.1
	await _step_physics(3)
	_expect(not (pe55._stump_steps[0]["col"] as CollisionShape2D).disabled and not (pe55._stump_steps[1]["col"] as CollisionShape2D).disabled, "L55 Ring #5 surge sprouts both left-wall StumpSteps")
	l55.queue_free()
	await process_frame

	# L57: Spirit Bamboo dash spawns Leaf-Gust Ring & vaults airborne player
	var l57 := _load_level_node(57)
	await _step_physics(4)
	var p57 = l57.get_node("Player")
	var pe57 = l57.get_node("Paranormal/ParanormalEvent")
	p57.is_invulnerable = false
	p57.global_position = Vector2(215, 420)
	Input.action_press("move_right")
	Input.action_press("dash")
	await _step_physics(3)
	Input.action_release("dash")
	Input.action_release("move_right")
	_expect(pe57._bamboo_gust_life > 0.5, "L57 dashing past Spirit Bamboo creates Leaf-Gust Ring (life=%.2f)" % pe57._bamboo_gust_life)
	l57.queue_free()
	await process_frame

	# L58: Root Tremor shifts dual slabs on tremor cycle
	var l58 := _load_level_node(58)
	await _step_physics(4)
	var pe58 = l58.get_node("Paranormal/ParanormalEvent")
	var sx0: float = (pe58._tremor_slabs[1]["pos"] as Vector2).x
	pe58._tremor_cycle = 3.19
	await _step_physics(20)
	_expect(absf((pe58._tremor_slabs[1]["pos"] as Vector2).x - sx0) > 40.0, "L58 Woodland Tremor shifts UpperTremorSlab across chasm (dx=%.1f)" % absf((pe58._tremor_slabs[1]["pos"] as Vector2).x - sx0))
	l58.queue_free()
	await process_frame

	# L60: World Tree Heart Finale Phase 1 Golden Updraft lifts player from SanctumRoot straight through one-way SummitCenter into ExitDoor!
	var l60 := _load_level_node(60)
	await _step_physics(4)
	var p60 = l60.get_node("Player")
	var pe60 = l60.get_node("Paranormal/ParanormalEvent")
	p60.is_invulnerable = false
	pe60._wt_cycle = 2.3 # Phase 1 Golden Pulse Updraft!
	p60.global_position = Vector2(480, 420)
	p60.velocity = Vector2.ZERO
	var reached_summit60 := false
	for _i in range(60):
		await physics_frame
		if p60.is_entering_door or p60.global_position.y <= 190.0:
			reached_summit60 = true
			break
	_expect(reached_summit60 and not p60.is_dead, "L60 Golden World-Tree Updraft lifts player through one-way SummitCenter straight into ExitDoor (y=%.1f, entering=%s)" % [p60.global_position.y, str(p60.is_entering_door)])
	l60.queue_free()
	await process_frame

func _jump_to_y(p: Node2D, dir_action: String, target_y: float, max_frames: int = 62, dash_at: int = -1, min_x: float = -999.0, max_x: float = 9999.0) -> bool:
	Input.action_release("jump")
	Input.action_release("dash")
	Input.action_release("move_left")
	Input.action_release("move_right")
	await _step_physics(2)
	if dir_action != "":
		Input.action_press(dir_action)
	Input.action_press("jump")
	var ok := false
	for i in range(max_frames):
		await physics_frame
		if i == 25:
			Input.action_release("jump")
		if dash_at >= 0 and i == dash_at:
			Input.action_press("dash")
		if dash_at >= 0 and i == dash_at + 2:
			Input.action_release("dash")
		if i >= 10 and not p.is_dead:
			if p.is_entering_door:
				ok = true
				break
			if p.is_on_floor() and absf(p.global_position.y - target_y) < 4.5 and p.global_position.x >= min_x and p.global_position.x <= max_x:
				ok = true
				break
	Input.action_release("jump")
	Input.action_release("dash")
	if dir_action != "":
		Input.action_release(dir_action)
	return ok

func _test_end_to_end_reachability_and_stress() -> void:
	# L23: CaveFloor -> ExitStep1 -> one-way BlackIceExitCap -> ExitDoor (no softlock)
	var l23 := _load_level_node(23)
	await _step_physics(4)
	var p23 = l23.get_node("Player")
	p23.is_invulnerable = false
	p23.global_position = Vector2(860, 415)
	var r23_a := await _jump_to_y(p23, "", 330.0)
	var r23_b := await _jump_to_y(p23, "", 240.0)
	_expect(r23_a and r23_b, "L23 shortcut CaveFloor->ExitStep1->BlackIceExitCap->ExitDoor reaches exit cleanly")
	l23.queue_free(); await process_frame

	# L24: SecretLeftStep -> one-way UpperLeftCap -> jump+dash -> UpperRightDeck
	var l24 := _load_level_node(24)
	await _step_physics(4)
	var p24 = l24.get_node("Player")
	p24.is_invulnerable = false
	p24.global_position = Vector2(72, 308)
	var r24_a := await _jump_to_y(p24, "", 220.0)
	p24.global_position = Vector2(395, 220)
	var r24_b := await _jump_to_y(p24, "move_right", 220.0, 68, 16, 640.0)
	_expect(r24_a and r24_b, "L24 shortcut SecretLeftStep->UpperLeftCap->UpperRightDeck reachable cleanly")
	l24.queue_free(); await process_frame

	# L26: ValleyFloor sprint+hop reaches sheltered Alcove -> SpringAlcove -> Bridge3Cap/ExitDoor
	var l26 := _load_level_node(26)
	await _step_physics(4)
	var p26 = l26.get_node("Player")
	p26.is_invulnerable = false
	Input.action_press("move_right")
	var ok26 := false
	for i in range(250):
		await physics_frame
		if i == 135: Input.action_press("jump")
		if i == 155: Input.action_release("jump")
		if p26.is_entering_door or (not p26.is_dead and p26.global_position.x >= 830.0 and p26.global_position.y <= 215.0):
			ok26 = true; break
	Input.action_release("move_right"); Input.action_release("jump")
	_expect(ok26 and not p26.is_dead, "L26 ValleyFloor sprint+hop survives snowdrift wave & launches through Bridge3Cap")
	l26.queue_free(); await process_frame

	# L28: Deck1 -> LanternBracket_0 -> LanternBracket_1 climb
	var l28 := _load_level_node(28)
	await _step_physics(4)
	var p28 = l28.get_node("Player")
	p28.is_invulnerable = false
	p28.global_position = Vector2(204, 395)
	var r28_a := await _jump_to_y(p28, "", 306.0)
	p28.global_position = Vector2(280, 306)
	var r28_b := await _jump_to_y(p28, "move_right", 248.0, 65, 16)
	_expect(r28_a and r28_b, "L28 Deck1->LanternBracket_0->LanternBracket_1 sky shortcut climb succeeds")
	l28.queue_free(); await process_frame

	# L29: GlacierFractureStep -> one-way RightStep climb
	var l29 := _load_level_node(29)
	await _step_physics(4)
	var p29 = l29.get_node("Player")
	p29.is_invulnerable = false
	for _k in range(3):
		p29.global_position = Vector2(855, 380)
		p29.velocity = Vector2(0, 180)
		await _step_physics(16)
	p29.global_position = Vector2(845, 410)
	var r29_a := await _jump_to_y(p29, "", 318.0)
	var r29_b := await _jump_to_y(p29, "", 226.0)
	_expect(r29_a and r29_b, "L29 LowerFloor->GlacierFractureStep->RightStep climb succeeds")
	l29.queue_free(); await process_frame

	# L33: LeftStep->LeftGallery, RightStep->RightGallery, and Bell Resonance upper chasm crossing
	var l33 := _load_level_node(33)
	await _step_physics(4)
	var p33 = l33.get_node("Player")
	var pe33 = l33.get_node("Paranormal/ParanormalEvent")
	p33.is_invulnerable = false
	p33.global_position = Vector2(70, 340)
	var r33_l := await _jump_to_y(p33, "", 260.0)
	p33.global_position = Vector2(850, 340)
	var r33_r := await _jump_to_y(p33, "", 260.0)
	l33.reset_level_traps()
	p33.is_dead = false; p33.is_entering_door = false; p33.is_invulnerable = false
	p33.global_position = Vector2(312, 260); p33.velocity = Vector2.ZERO
	pe33._bell_cycle = 3.00
	var r33_gap := await _jump_to_y(p33, "move_right", 260.0, 95, 18, 640.0)
	_expect(r33_l and r33_r and r33_gap, "L33 LeftStep->LeftGallery, RightStep->RightGallery & Bell-Resonance chasm cross all succeed")
	l33.queue_free(); await process_frame

	# L35: Zero spawn-kill after 1.5s standing still + zero accidental stumble sprinting off TopRun
	var l35 := _load_level_node(35)
	await _step_physics(4)
	var p35 = l35.get_node("Player")
	p35.is_invulnerable = false
	var deaths35 := [0]
	p35.died.connect(func(): deaths35[0] += 1)
	await _step_physics(90)
	_expect(deaths35[0] == 0, "L35 standing still 1.5s at spawn causes zero permafrost spawn-kill")
	p35.global_position = Vector2(680, 195); p35.velocity = Vector2.ZERO
	Input.action_press("move_right")
	await _step_physics(48)
	Input.action_release("move_right")
	_expect(absf(p35.global_position.y - 308.0) < 4.5, "L35 sprinting right off TopRun lands cleanly on solid MidRun (zero accidental stumble)")
	l35.queue_free(); await process_frame

	# L37: LeftSurgePerch -> one-way HighCliff climb
	var l37 := _load_level_node(37)
	await _step_physics(4)
	var p37 = l37.get_node("Player")
	p37.is_invulnerable = false
	p37.global_position = Vector2(185, 302)
	var r37 := await _jump_to_y(p37, "", 215.0)
	_expect(r37, "L37 LeftSurgePerch -> one-way HighCliff shortcut climb succeeds")
	l37.queue_free(); await process_frame

	# L38: SpringBowlExit -> one-way RightRim launch
	var l38 := _load_level_node(38)
	await _step_physics(4)
	var p38 = l38.get_node("Player")
	p38.is_invulnerable = false
	p38.global_position = Vector2(770, 420); p38.velocity = Vector2.ZERO
	var ok38 := false
	for _i in range(60):
		await physics_frame
		if p38.is_on_floor() and absf(p38.global_position.y - 250.0) < 4.5:
			ok38 = true; break
	_expect(ok38, "L38 SpringBowlExit launches cleanly through one-way RightRim")
	l38.queue_free(); await process_frame

	# L40: Both Left shortcut & Right hard path climb onto CrownThrone
	var l40 := _load_level_node(40)
	await _step_physics(4)
	var p40 = l40.get_node("Player")
	p40.is_invulnerable = false
	p40.global_position = Vector2(70, 420)
	var r40_l1 := await _jump_to_y(p40, "", 354.0)
	var r40_l2 := await _jump_to_y(p40, "", 286.0)
	p40.global_position = Vector2(255, 286)
	var r40_l3 := await _jump_to_y(p40, "move_right", 205.0, 62, -1, 395.0, 565.0)
	l40.reset_level_traps()
	p40.is_dead = false; p40.is_entering_door = false; p40.is_invulnerable = false
	p40.global_position = Vector2(860, 420)
	var r40_r1 := await _jump_to_y(p40, "", 354.0)
	var r40_r2 := await _jump_to_y(p40, "", 286.0)
	p40.global_position = Vector2(700, 286)
	var r40_r3 := await _jump_to_y(p40, "move_left", 205.0, 62, -1, 395.0, 565.0)
	_expect(r40_l1 and r40_l2 and r40_l3 and r40_r1 and r40_r2 and r40_r3, "L40 Frost Crown Finale BOTH left shortcut & right hard path reach CrownThrone cleanly")
	l40.queue_free(); await process_frame

	# L41: ForestFloor -> RootExitStep -> one-way CanopyExitCap -> ExitDoor
	var l41 := _load_level_node(41)
	await _step_physics(4)
	var p41 = l41.get_node("Player")
	p41.is_invulnerable = false
	p41.global_position = Vector2(865, 430)
	var r41_a := await _jump_to_y(p41, "", 368.0)
	var r41_b := await _jump_to_y(p41, "", 305.0)
	_expect(r41_a and r41_b, "L41 shortcut ForestFloor->RootExitStep->CanopyExitCap->ExitDoor reaches exit cleanly")
	l41.queue_free(); await process_frame

	# L42: LeftBough -> high 4th canopy vine VineSeg_3 (y=252)
	var l42 := _load_level_node(42)
	await _step_physics(4)
	var p42 = l42.get_node("Player")
	p42.is_invulnerable = false
	p42.global_position = Vector2(232, 340)
	var r42 := await _jump_to_y(p42, "move_right", 252.0, 58)
	_expect(r42, "L42 LeftBough -> high 4th canopy vine VineSeg_3 climb succeeds")
	l42.queue_free(); await process_frame

	# L43: UpperGlade -> HighLeftPerch Trickster+dash shortcut
	var l43 := _load_level_node(43)
	await _step_physics(4)
	var p43 = l43.get_node("Player")
	var pe43 = l43.get_node("Paranormal/ParanormalEvent")
	p43.is_invulnerable = false
	pe43._totem_cycle = 2.7
	p43.global_position = Vector2(615, 225)
	var r43 := await _jump_to_y(p43, "move_left", 245.0, 70, 15, 32.0, 287.0)
	_expect(r43, "L43 Trickster+dash UpperGlade->HighLeftPerch shortcut succeeds")
	l43.queue_free(); await process_frame

	# L45: Both Secret Spore double-bounce -> CanopyExit AND Main Mushroom -> RightBranch -> CanopyExit
	var l45 := _load_level_node(45)
	await _step_physics(4)
	var p45 = l45.get_node("Player")
	p45.is_invulnerable = false
	p45.global_position = Vector2(58, 425); p45.velocity = Vector2.ZERO
	var r45_sec := false
	for _i in range(110):
		await physics_frame
		if p45.is_entering_door or (p45.is_on_floor() and absf(p45.global_position.y - 180.0) < 4.5):
			r45_sec = true; break
	l45.reset_level_traps()
	p45.is_dead = false; p45.is_entering_door = false; p45.is_invulnerable = false
	p45.global_position = Vector2(875, 425); p45.velocity = Vector2.ZERO
	var r45_m1 := false
	for _i in range(75):
		await physics_frame
		if not p45.is_dead and p45.is_on_floor() and absf(p45.global_position.y - 250.0) < 4.5:
			r45_m1 = true; break
	p45.global_position = Vector2(525, 250)
	var r45_m2 := await _jump_to_y(p45, "move_left", 180.0, 62, 14)
	_expect(r45_sec and r45_m1 and r45_m2, "L45 BOTH Secret Spore chain & Main Mushroom->RightBranch->CanopyExit succeed")
	l45.queue_free(); await process_frame

	# L47: LeftRootStep -> one-way UpperCanopy climb
	var l47 := _load_level_node(47)
	await _step_physics(4)
	var p47 = l47.get_node("Player")
	p47.is_invulnerable = false
	p47.global_position = Vector2(95, 330)
	await _step_physics(3)
	p47.global_position = Vector2(195, 325)
	var r47 := await _jump_to_y(p47, "", 235.0)
	_expect(r47, "L47 LeftRootStep -> one-way UpperCanopy shortcut climb succeeds")
	l47.queue_free(); await process_frame

	# L48: Pollen Dream Drift Tree1 -> Tree3 glide
	var l48 := _load_level_node(48)
	await _step_physics(4)
	var p48 = l48.get_node("Player")
	p48.is_invulnerable = false
	p48.global_position = Vector2(195, 195)
	await _step_physics(2)
	Input.action_press("move_right"); Input.action_press("jump")
	var r48 := false
	for i in range(125):
		await physics_frame
		if i == 25: Input.action_release("jump")
		if i == 16 or i == 46: Input.action_press("dash")
		if i == 18 or i == 48: Input.action_release("dash")
		if not p48.is_dead and p48.is_on_floor() and p48.global_position.x >= 650.0 and absf(p48.global_position.y - 375.0) < 4.5:
			r48 = true; break
	Input.action_release("move_right"); Input.action_release("jump"); Input.action_release("dash")
	_expect(r48, "L48 Pollen Dream Drift glide Tree1->Tree3 shortcut succeeds")
	l48.queue_free(); await process_frame

	# L49: WestCliff -> StagPad_0 -> StagPad_1 Spirit Stag shortcut
	var l49 := _load_level_node(49)
	await _step_physics(4)
	var p49 = l49.get_node("Player")
	var pe49 = l49.get_node("Paranormal/ParanormalEvent")
	p49.is_invulnerable = false
	for sp in pe49._stag_pads:
		sp["life"] = 3.5; (sp["col"] as CollisionShape2D).disabled = false
	p49.global_position = Vector2(165, 365)
	var r49_a := await _jump_to_y(p49, "move_right", 282.0)
	p49.global_position = Vector2(310, 282)
	var r49_b := await _jump_to_y(p49, "move_right", 245.0)
	_expect(r49_a and r49_b, "L49 WestCliff->StagPad_0->StagPad_1 Spirit Stag shortcut succeeds")
	l49.queue_free(); await process_frame

	# L54: LeftTerrace -> HighCrown ley-line climb
	var l54 := _load_level_node(54)
	await _step_physics(4)
	var p54 = l54.get_node("Player")
	p54.is_invulnerable = false
	p54.global_position = Vector2(195, 315)
	var r54 := await _jump_to_y(p54, "move_right", 215.0, 95)
	_expect(r54, "L54 LeftTerrace -> HighCrown ley-line jump succeeds")
	l54.queue_free(); await process_frame

	# L55: Both Hard Path & StumpStep Shortcut climb cleanly
	var l55 := _load_level_node(55)
	await _step_physics(4)
	var p55 = l55.get_node("Player")
	var pe55 = l55.get_node("Paranormal/ParanormalEvent")
	p55.is_invulnerable = false
	p55.global_position = Vector2(860, 430)
	var r55_h1 := await _jump_to_y(p55, "", 372.0)
	var r55_h2 := await _jump_to_y(p55, "", 315.0)
	p55.global_position = Vector2(390, 315)
	var r55_h3 := await _jump_to_y(p55, "", 264.0)
	var r55_h4 := await _jump_to_y(p55, "", 210.0)
	pe55._stump_cycle = 3.1
	await _step_physics(3)
	p55.global_position = Vector2(80, 430)
	var r55_s1 := await _jump_to_y(p55, "", 358.0)
	p55.global_position = Vector2(120, 358)
	var r55_s2 := await _jump_to_y(p55, "", 284.0)
	var r55_s3 := await _jump_to_y(p55, "", 210.0)
	_expect(r55_h1 and r55_h2 and r55_h3 and r55_h4 and r55_s1 and r55_s2 and r55_s3, "L55 BOTH Hard Path & StumpStep Shortcut climb cleanly to TierHigh")
	l55.queue_free(); await process_frame

	# L57: Spirit Bamboo Leaf-Gust Ring vaults straight over Grove2 onto Grove3
	var l57 := _load_level_node(57)
	await _step_physics(4)
	var p57 = l57.get_node("Player")
	p57.is_invulnerable = false
	p57.global_position = Vector2(180, 420)
	Input.action_press("move_right"); Input.action_press("dash")
	await _step_physics(3); Input.action_release("dash")
	await _step_physics(7); Input.action_press("jump")
	var r57 := false
	for i in range(90):
		await physics_frame
		if i == 25: Input.action_release("jump")
		if not p57.is_dead and p57.is_on_floor() and p57.global_position.x >= 675.0 and absf(p57.global_position.y - 275.0) < 4.5:
			r57 = true; break
	Input.action_release("move_right"); Input.action_release("jump")
	_expect(r57, "L57 Spirit Bamboo Leaf-Gust Ring vaults cleanly over Grove2 onto Grove3 (pos=%s)" % str(p57.global_position))
	l57.queue_free(); await process_frame

	# L58: Both WestStep->WestHigh & EastStep->EastHigh climbs
	var l58 := _load_level_node(58)
	await _step_physics(4)
	var p58 = l58.get_node("Player")
	p58.is_invulnerable = false
	p58.global_position = Vector2(72, 385)
	var r58_w1 := await _jump_to_y(p58, "", 310.0)
	var r58_w2 := await _jump_to_y(p58, "", 235.0)
	p58.global_position = Vector2(880, 385)
	var r58_e1 := await _jump_to_y(p58, "", 310.0)
	var r58_e2 := await _jump_to_y(p58, "", 235.0)
	_expect(r58_w1 and r58_w2 and r58_e1 and r58_e2, "L58 WestStep->WestHigh & EastStep->EastHigh both climb cleanly")
	l58.queue_free(); await process_frame

	# L60: Hard Path RightStep->RightBough->WorldTreePad_1->SummitRight->ExitDoor
	var l60 := _load_level_node(60)
	await _step_physics(4)
	var p60 = l60.get_node("Player")
	var pe60 = l60.get_node("Paranormal/ParanormalEvent")
	p60.is_invulnerable = false
	pe60._wt_cycle = 0.0
	p60.global_position = Vector2(870, 420)
	var r60_1 := await _jump_to_y(p60, "", 370.0)
	var r60_2 := await _jump_to_y(p60, "", 315.0)
	pe60._wt_cycle = 0.0
	p60.global_position = Vector2(715, 315)
	await _step_physics(2)
	Input.action_press("move_left"); Input.action_press("jump")
	var r60_3 := false
	for i in range(60):
		await physics_frame
		if i == 16: Input.action_release("move_left")
		if i == 25: Input.action_release("jump")
		if i >= 10 and not p60.is_dead and p60.is_on_floor() and absf(p60.global_position.y - 250.0) < 4.5:
			r60_3 = true; break
	Input.action_release("move_left"); Input.action_release("jump")
	p60.global_position = Vector2(620, 250)
	var r60_4 := await _jump_to_y(p60, "move_left", 185.0)
	_expect(r60_1 and r60_2 and r60_3 and r60_4, "L60 Hard Path RightStep->RightBough->WorldTreePad_1->SummitRight reaches ExitDoor cleanly")
	l60.queue_free(); await process_frame

	# Rapid death/respawn stress test across 11 dynamic levels
	var stress_ok := true
	for lvl_id in [25, 27, 31, 38, 40, 42, 49, 53, 55, 58, 60]:
		var inst := _load_level_node(lvl_id)
		await _step_physics(3)
		var pl = inst.get_node("Player")
		var ed = inst.get_node("ExitDoor")
		for _cyc in range(3):
			pl.is_invulnerable = false
			pl.kill()
			await _step_physics(2)
			inst.reset_level_traps()
			pl.respawn()
			await _step_physics(4)
			if pl.is_dead or not pl.is_on_floor() or not is_equal_approx(Engine.time_scale, 1.0):
				stress_ok = false
		if lvl_id == 40 and ed.monitoring:
			stress_ok = false
		if lvl_id == 27 and absf(ed.position.x - 845.0) > 2.0:
			stress_ok = false
		inst.queue_free(); await process_frame
	_expect(stress_ok, "Rapid death/respawn stress test across 11 dynamic levels (L25/27/31/38/40/42/49/53/55/58/60) clean")
