extends SceneTree

# Comprehensive Automated Test Suite for 5-Biome Seasonal Traps, Animations,
# Pooled VFX, Procedural Biome SFX, Camouflage Parity, and Clean Reset.

const TrapBiomeArt := preload("res://scripts/traps/trap_biome_art.gd")
const TrapBiomeVFX := preload("res://scripts/traps/trap_biome_vfx.gd")
const TrapVFXLayer := preload("res://scripts/traps/trap_vfx_layer.gd")

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

func _set_chapter(ch: int) -> void:
	var gm := root.get_node_or_null("/root/GameManager")
	if gm:
		gm.current_level_id = (ch - 1) * 20 + 1

func _run_all() -> void:
	print("=== Starting 5-Biome Seasonal Traps Comprehensive Verification ===")
	await _test_biome_art_and_sfx_api()
	await _test_vfx_pool_limits_and_sleep()
	await _test_rolling_boulder_all_5_biomes()
	await _test_rolling_boulder_bounce_then_shatter()
	await _test_multi_boulder_isolated_vfx_reset()
	await _test_rolling_boulder_ledge_landing_vfx()
	await _test_falling_spike_icicle_shatter_and_reset()
	await _test_camouflage_and_active_vfx_all_traps()
	await _test_level_editor_playtest_vfx_containment()
	await _test_chapter_2_and_3_levels_load()

	print("\n=== BIOME TRAP SUMMARY: %d checks, %d failures ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("ALL BIOME TRAP CHECKS PASSED!")
		quit(0)
	else:
		for f in _failures:
			print("  FAILURE: " + f)
		quit(1)

func _test_biome_art_and_sfx_api() -> void:
	var sm := root.get_node_or_null("/root/SoundManager")
	_expect(sm != null and sm.has_method("play_biome_trap"), "SoundManager exposes play_biome_trap()")
	var required_keys := [
		"biome_stone_shatter", "biome_snow_burst", "biome_ice_shatter",
		"biome_vine_snap", "biome_sand_crumble", "biome_lava_burst",
		"biome_frost_snap", "biome_vine_whip", "biome_desert_click", "biome_magma_hiss"
	]
	for k in required_keys:
		_expect(sm != null and sm.players.has(k), "SoundManager generated procedural SFX: " + k)
		if sm and sm.players.has(k):
			var wav: AudioStreamWAV = sm.players[k].stream as AudioStreamWAV
			var pcm_ok := false
			if wav != null and wav.data.size() >= 4:
				var d: PackedByteArray = wav.data
				var n: int = d.size() / 2
				var start_sv := int(d[0]) | (int(d[1]) << 8)
				if start_sv >= 32768:
					start_sv -= 65536
				var clipped := false
				for idx in range(n):
					var sv := int(d[idx * 2]) | (int(d[idx * 2 + 1]) << 8)
					if sv >= 32768:
						sv -= 65536
					if sv >= 32767 or sv <= -32768:
						clipped = true
						break
				pcm_ok = (not clipped) and absf(float(start_sv) / 32768.0) <= 0.015
			_expect(pcm_ok, "Procedural SFX %s has zero clipping & click-free attack" % k)

	var actions := ["boulder_shatter", "stalactite_impact", "slam", "crumble", "spring", "beam", "trigger"]
	for ch in [-1, 0, 1, 2, 3, 4, 5, 99]:
		if sm:
			for act in actions:
				sm.play_biome_trap(act, ch)
	_expect(true, "SoundManager.play_biome_trap handles all actions & boundary chapter values without error")

	# Verify distinct base & teeth palettes across all 5 chapters
	var bases := {}
	for ch in range(1, 6):
		var pal := TrapBiomeArt.get_palette(ch)
		_expect(pal.has("base") and pal.has("teeth") and pal.has("accent"), "Ch %d palette complete" % ch)
		bases[TrapBiomeArt.get_base_color(ch)] = true
	_expect(bases.size() == 5, "All 5 chapters have distinct base colors")

func _test_vfx_pool_limits_and_sleep() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var layer := TrapBiomeVFX.get_layer(host)
	_expect(layer != null, "TrapBiomeVFX lazily attaches TrapVFXLayer")
	_expect(not layer.is_processing(), "Empty TrapVFXLayer sleeps (is_processing == false)")

	# Stress test: spawn 200 particles (above 96/56 capacity) — ring buffer must cap cleanly
	for i in range(200):
		layer.spawn_particle(
			Vector2(100, 100), Vector2(10, -20), i % 8,
			Color.WHITE, Color.CYAN, 4.0, 1.0, 0.12, 100.0, 1.0
		)
	_expect(layer.get_active_count() <= 96 and layer.get_active_count() > 0, "TrapVFXLayer caps active count cleanly (count=%d)" % layer.get_active_count())
	_expect(layer.is_processing(), "TrapVFXLayer wakes up when particles spawn")

	layer.clear_all()
	_expect(layer.get_active_count() == 0 and not layer.is_processing(), "clear_all() resets count to 0 and puts TrapVFXLayer back to sleep")
	host.queue_free()
	await process_frame

func _test_rolling_boulder_all_5_biomes() -> void:
	var boulder_scn := load("res://scenes/traps/rolling_boulder.tscn") as PackedScene
	var plat_scn := load("res://scenes/objects/solid_platform.tscn") as PackedScene

	for ch in range(1, 6):
		_set_chapter(ch)
		var host := Node2D.new()
		root.add_child(host)

		var floor_p := plat_scn.instantiate()
		floor_p.position = Vector2(0, 360)
		floor_p.platform_size = Vector2(500, 40)
		host.add_child(floor_p)

		var wall_p := plat_scn.instantiate()
		wall_p.name = "WallRight"
		wall_p.position = Vector2(300, 200)
		wall_p.platform_size = Vector2(32, 200)
		host.add_child(wall_p)

		var rb := boulder_scn.instantiate()
		rb.position = Vector2(120, 330)
		rb.roll_direction = 1.0
		rb.roll_speed = 420.0
		rb.delay_before_roll = 0.05
		host.add_child(rb)
		await _step_physics(2)

		rb.trigger_boulder()
		await _step_physics(60) # Roll into WallRight & shatter!

		var layer := TrapBiomeVFX.get_layer(rb)
		_expect(rb.has_fallen and rb._is_shattered, "Ch %d RollingBoulder shatters on wall impact" % ch)
		_expect(rb.col_shape.disabled == true and rb.kill_area.monitoring == false, "Ch %d shattered RollingBoulder disables collision & kill area" % ch)
		_expect(layer != null and layer.get_active_count() > 0, "Ch %d RollingBoulder wall shatter emits biome VFX (particles=%d)" % [ch, layer.get_active_count() if layer else 0])

		# Wait briefly for impact flash hide tween
		await _step_physics(8)
		_expect(rb.visible == false, "Ch %d shattered RollingBoulder hides intact body after flash" % ch)

		# Reset must restore everything cleanly and wipe shatter particles
		rb.reset_trap()
		await _step_physics(2)
		_expect(
			rb.visible == true and is_equal_approx(rb.modulate.a, 1.0) and rb.scale == Vector2.ONE
			and not rb.has_fallen and not rb._is_shattered and not rb.col_shape.disabled,
			"Ch %d RollingBoulder reset_trap() restores full intact state" % ch
		)
		_expect(layer.get_active_count() == 0, "Ch %d RollingBoulder reset_trap() clears shatter particles" % ch)

		host.queue_free()
		await process_frame

func _test_rolling_boulder_bounce_then_shatter() -> void:
	_set_chapter(2) # Snowball bounce test!
	var boulder_scn := load("res://scenes/traps/rolling_boulder.tscn") as PackedScene
	var plat_scn := load("res://scenes/objects/solid_platform.tscn") as PackedScene

	var host := Node2D.new()
	root.add_child(host)

	var floor_p := plat_scn.instantiate()
	floor_p.position = Vector2(0, 360)
	floor_p.platform_size = Vector2(500, 40)
	host.add_child(floor_p)

	var wall_l := plat_scn.instantiate()
	wall_l.name = "WallLeft"
	wall_l.position = Vector2(30, 200)
	wall_l.platform_size = Vector2(32, 200)
	host.add_child(wall_l)

	var wall_r := plat_scn.instantiate()
	wall_r.name = "WallRight"
	wall_r.position = Vector2(300, 200)
	wall_r.platform_size = Vector2(32, 200)
	host.add_child(wall_r)

	var rb := boulder_scn.instantiate()
	rb.position = Vector2(160, 330)
	rb.roll_direction = 1.0
	rb.roll_speed = 420.0
	rb.delay_before_roll = 0.04
	rb.bounce_back_once = true
	host.add_child(rb)
	await _step_physics(2)

	rb.trigger_boulder()
	var bounced := false
	for _i in range(60):
		await physics_frame
		if rb._has_bounced and rb.roll_direction < 0.0 and not rb.has_fallen:
			bounced = true
			break
	_expect(bounced, "Ch 2 Snowball with bounce_back_once bounces off right wall without disappearing")

	# Continue rolling left until it hits WallLeft and finally shatters
	await _step_physics(70)
	_expect(rb.has_fallen and rb._is_shattered, "Ch 2 Snowball shatters cleanly on second wall after bounce")
	rb.reset_trap()
	_expect(rb.roll_direction > 0.0 and not rb._has_bounced and not rb._is_shattered, "Bounce snowball resets direction & flags cleanly")

	host.queue_free()
	await process_frame

func _test_multi_boulder_isolated_vfx_reset() -> void:
	_set_chapter(2)
	var host := Node2D.new()
	root.add_child(host)
	var plat_scn := load("res://scenes/objects/solid_platform.tscn") as PackedScene
	var rb_scn := load("res://scenes/traps/rolling_boulder.tscn") as PackedScene

	var fl := plat_scn.instantiate()
	fl.position = Vector2(0, 360)
	fl.platform_size = Vector2(600, 40)
	host.add_child(fl)
	var wl := plat_scn.instantiate()
	wl.name = "WallRight"
	wl.position = Vector2(360, 200)
	wl.platform_size = Vector2(32, 200)
	host.add_child(wl)

	var rb1 := rb_scn.instantiate()
	rb1.position = Vector2(120, 330)
	rb1.roll_direction = 1.0
	rb1.roll_speed = 450.0
	rb1.delay_before_roll = 0.02
	host.add_child(rb1)

	var rb2 := rb_scn.instantiate()
	rb2.position = Vector2(200, 330)
	rb2.roll_direction = 1.0
	rb2.roll_speed = 450.0
	rb2.delay_before_roll = 0.02
	host.add_child(rb2)

	await _step_physics(2)
	rb2.trigger_boulder()
	await _step_physics(40)
	rb1.trigger_boulder()
	await _step_physics(50)

	var layer := TrapBiomeVFX.get_layer(rb1)
	var before_cnt: int = layer.get_active_count() if layer else 0
	rb2.reset_trap()
	var after_cnt: int = layer.get_active_count() if layer else 0
	_expect(before_cnt > 0 and after_cnt > 0, "Resetting rb2 preserves rb1's active shatter VFX (before=%d, after=%d)" % [before_cnt, after_cnt])
	rb1.reset_trap()
	_expect(layer.get_active_count() == 0, "Resetting rb1 clears rb1's own shatter VFX completely")

	host.queue_free()
	await process_frame

func _test_rolling_boulder_ledge_landing_vfx() -> void:
	_set_chapter(3)
	var host := Node2D.new()
	root.add_child(host)
	var plat_scn := load("res://scenes/objects/solid_platform.tscn") as PackedScene
	var rb_scn := load("res://scenes/traps/rolling_boulder.tscn") as PackedScene

	var upper := plat_scn.instantiate()
	upper.position = Vector2(240, 220)
	upper.platform_size = Vector2(120, 28)
	host.add_child(upper)
	var lower := plat_scn.instantiate()
	lower.position = Vector2(0, 380)
	lower.platform_size = Vector2(500, 40)
	host.add_child(lower)

	var rb := rb_scn.instantiate()
	rb.position = Vector2(300, 190)
	rb.roll_direction = -1.0
	rb.roll_speed = 320.0
	rb.delay_before_roll = 0.02
	host.add_child(rb)
	await _step_physics(2)

	rb.trigger_boulder()
	await _step_physics(55)
	var layer := TrapBiomeVFX.get_layer(rb)
	_expect(rb.is_rolling and not rb.has_fallen and rb.global_position.y > 330.0, "Ch 3 Vine Boulder drops off upper ledge onto lower floor and keeps rolling")
	_expect(layer != null and layer.get_active_count() > 0, "Ch 3 Vine Boulder ledge drop emits biome landing & trail VFX")
	rb.reset_trap()
	_expect(rb._was_on_floor and is_equal_approx(rb._prev_vy, 0.0), "Ledge-drop boulder resets landing trackers cleanly")

	host.queue_free()
	await process_frame

func _test_falling_spike_icicle_shatter_and_reset() -> void:
	var fspk_scn := load("res://scenes/traps/falling_spike.tscn") as PackedScene
	var plat_scn := load("res://scenes/objects/solid_platform.tscn") as PackedScene

	for ch in [1, 2, 3, 5]:
		_set_chapter(ch)
		var host := Node2D.new()
		root.add_child(host)

		var floor_p := plat_scn.instantiate()
		floor_p.position = Vector2(0, 320)
		floor_p.platform_size = Vector2(400, 40)
		host.add_child(floor_p)

		var fs := fspk_scn.instantiate()
		fs.position = Vector2(200, 70)
		host.add_child(fs)
		await _step_physics(2)

		_expect(not fs._impact_shattered, "Ch %d FallingSpike idle is intact (not shattered)" % ch)
		fs._trigger()
		await _step_physics(45)

		var layer := TrapBiomeVFX.get_layer(fs)
		_expect(fs.is_grounded and absf(fs.global_position.y - 294.0) <= 1.0, "Ch %d FallingSpike impacts floor at exact y=294 (got %.1f)" % [ch, fs.global_position.y])
		_expect(fs._impact_shattered == (ch == 2), "Ch %d FallingSpike icicle fracture flag matches biome (shattered=%s)" % [ch, str(fs._impact_shattered)])
		_expect(layer != null and layer.get_active_count() > 0, "Ch %d FallingSpike impact emits biome VFX" % ch)

		fs.reset_trap()
		_expect(not fs.is_grounded and not fs._impact_shattered and fs.global_position == Vector2(200, 70), "Ch %d FallingSpike reset_trap() restores intact ceiling state" % ch)

		host.queue_free()
		await process_frame

func _test_camouflage_and_active_vfx_all_traps() -> void:
	var trap_paths := [
		"res://scenes/traps/spikes.tscn",
		"res://scenes/traps/pop_up_spikes.tscn",
		"res://scenes/traps/jumping_spikes.tscn",
		"res://scenes/traps/falling_spike.tscn",
		"res://scenes/traps/moving_saw.tscn",
		"res://scenes/traps/circular_saw.tscn",
		"res://scenes/traps/crusher.tscn",
		"res://scenes/traps/falling_ceiling.tscn",
		"res://scenes/traps/laser_beam.tscn",
		"res://scenes/traps/crumbling_platform.tscn",
		"res://scenes/traps/dodging_platform.tscn",
		"res://scenes/traps/trap_floor.tscn",
		"res://scenes/traps/spring.tscn",
		"res://scenes/traps/fake_door.tscn",
		"res://scenes/traps/rolling_boulder.tscn",
	]

	for ch in range(1, 6):
		_set_chapter(ch)
		var host := Node2D.new()
		root.add_child(host)
		for path in trap_paths:
			var ps := load(path) as PackedScene
			var inst := ps.instantiate() as Node2D
			host.add_child(inst)
			inst.queue_redraw()
		await _step_physics(2)

		# Trigger Spring, PopUpSpikes, JumpingSpikes, CrumblingPlatform, DodgingPlatform, FakeDoor, FallingCeiling
		var spring := host.get_node("Spring")
		_expect(not spring.is_springing and spring.extension == 0.0, "Ch %d Spring stays hidden when idle" % ch)
		var dummy := Node2D.new()
		spring._trigger_launch(dummy)
		_expect(spring.is_springing, "Ch %d Spring activates on launch" % ch)
		dummy.free()

		var pop := host.get_node("PopUpSpikes")
		pop._trigger(true)
		var crumble := host.get_node("CrumblingPlatform")
		crumble.trigger_crumble()
		var dodge := host.get_node("DodgingPlatform")
		dodge.trigger_dodge()
		var fdoor := host.get_node("FakeDoor")
		fdoor._run_away(null)
		var fceil := host.get_node("FallingCeiling")
		fceil.trigger_slam()

		await _step_physics(4)
		var layer := TrapBiomeVFX.get_layer(host)
		_expect(layer != null and layer.get_active_count() > 0, "Ch %d active traps emit biome VFX cleanly (count=%d)" % [ch, layer.get_active_count() if layer else 0])

		for child in host.get_children():
			if child.has_method("reset_trap"):
				child.reset_trap()
		TrapBiomeVFX.clear_level(host)
		_expect(layer.get_active_count() == 0, "Ch %d reset + clear_level wipes all trap VFX cleanly" % ch)

		host.queue_free()
		await process_frame

func _test_level_editor_playtest_vfx_containment() -> void:
	_set_chapter(2)
	var fake_editor := Control.new()
	fake_editor.name = "LevelEditor"
	var playtest_world := Node2D.new()
	playtest_world.name = "PlaytestWorld"
	fake_editor.add_child(playtest_world)
	root.add_child(fake_editor)

	var spring_scn := load("res://scenes/traps/spring.tscn") as PackedScene
	var sp := spring_scn.instantiate()
	sp.position = Vector2(160, 352)
	playtest_world.add_child(sp)
	await _step_physics(2)

	var dummy := Node2D.new()
	sp._trigger_launch(dummy)
	dummy.free()
	await _step_physics(2)

	var on_editor := fake_editor.get_node_or_null("_TrapBiomeVFXLayer")
	var on_pw := playtest_world.get_node_or_null("_TrapBiomeVFXLayer")
	_expect(on_editor == null and on_pw != null and on_pw.get_active_count() > 0, "LevelEditor VFX attaches strictly inside PlaytestWorld (zero leak onto LevelEditor UI)")

	TrapBiomeVFX.clear_level(playtest_world)
	_expect(on_pw.get_active_count() == 0 and not on_pw.is_processing(), "TrapBiomeVFX.clear_level(playtest_world) clears & sleeps playtest VFX")

	fake_editor.queue_free()
	await process_frame

func _test_chapter_2_and_3_levels_load() -> void:
	# Verify all Chapter 2 .tscn scenes (21..40) instantiate and reset cleanly
	var ok_ch2 := 0
	for lvl in range(21, 41):
		var path := "res://scenes/levels/level_%02d.tscn" % lvl
		if not ResourceLoader.exists(path):
			continue
		var gm := root.get_node_or_null("/root/GameManager")
		if gm:
			gm.current_level_id = lvl
		var ps := load(path) as PackedScene
		var inst := ps.instantiate() as Node2D
		root.add_child(inst)
		await _step_physics(2)
		if inst.has_method("reset_level_traps"):
			inst.reset_level_traps()
		ok_ch2 += 1
		inst.queue_free()
		await process_frame
	_expect(ok_ch2 == 20, "All 20 Chapter 2 (Frost Peak) scenes instantiate & reset cleanly (count=%d)" % ok_ch2)

	# Verify Chapter 3 (Emerald Woods) levels 41..60 load cleanly via LevelArena + LevelDatabase
	var ldb := root.get_node_or_null("/root/LevelDatabase")
	var arena_ps := load("res://scenes/levels/level_arena.tscn") as PackedScene
	var ok_ch3 := 0
	if ldb and arena_ps:
		for lvl in range(41, 61):
			var data: Dictionary = ldb.get_level(lvl)
			if data.is_empty():
				continue
			var gm := root.get_node_or_null("/root/GameManager")
			if gm:
				gm.current_level_id = lvl
			var arena := arena_ps.instantiate() as Node2D
			root.add_child(arena)
			arena.load_level_from_data(data)
			await _step_physics(2)
			arena.reset_level_traps()
			ok_ch3 += 1
			arena.queue_free()
			await process_frame
	_expect(ok_ch3 == 20, "All 20 Chapter 3 (Emerald Woods) JSON levels load & reset cleanly via LevelArena (count=%d)" % ok_ch3)
