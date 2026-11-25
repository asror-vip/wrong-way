extends RefCounted

# Wrong Way — Seasonal Biome Trap VFX Facade
# Routes trap impacts, shatters, trails, and eruptions into a single pooled
# TrapVFXLayer per level (mobile-safe, zero leaks, clean reset).

const TrapBiomeArt := preload("res://scripts/traps/trap_biome_art.gd")
const TrapVFXLayer := preload("res://scripts/traps/trap_vfx_layer.gd")

const LAYER_NAME := "_TrapBiomeVFXLayer"

static func _find_host(node: Node) -> Node:
	if node == null or not node.is_inside_tree():
		return null
	var cur := node
	while cur != null:
		if cur.has_method("reset_level_traps") or cur.name == "PlaytestWorld" or cur.is_in_group("trap_vfx_host"):
			return cur
		var p := cur.get_parent()
		if p == null or p is Window:
			return cur
		cur = p
	return node.get_parent()

static func get_layer(source: Node) -> Node2D:
	var host := _find_host(source)
	if host == null or not host.is_inside_tree():
		return null
	var existing := host.get_node_or_null(LAYER_NAME) as Node2D
	if existing != null and is_instance_valid(existing):
		if existing.has_method("set_spawn_owner"):
			existing.set_spawn_owner(source.get_instance_id())
		return existing
	var layer: Node2D = TrapVFXLayer.new()
	layer.name = LAYER_NAME
	host.add_child(layer)
	if layer.has_method("set_spawn_owner"):
		layer.set_spawn_owner(source.get_instance_id())
	return layer

static func clear_for(source: Node) -> void:
	if source == null:
		return
	var host := _find_host(source)
	if host == null:
		return
	var existing := host.get_node_or_null(LAYER_NAME)
	if existing != null and is_instance_valid(existing):
		if existing.has_method("clear_owner"):
			existing.clear_owner(source.get_instance_id())
		elif existing.has_method("clear_all"):
			existing.clear_all()

static func clear_level(level_node: Node) -> void:
	if level_node == null:
		return
	var existing := level_node.get_node_or_null(LAYER_NAME)
	if existing != null and is_instance_valid(existing) and existing.has_method("clear_all"):
		existing.clear_all()

static func _mobile_scale(count: int) -> int:
	if OS.has_feature("mobile"):
		return maxi(2, int(round(float(count) * 0.65)))
	return count

# ==============================================================================
# 1. ROLLING BOULDER — SHATTER / BOUNCE / ROLL TRAIL / RUMBLE
# ==============================================================================

static func emit_boulder_shatter(
	source: Node,
	pos: Vector2,
	radius: float,
	dir_x: float,
	ch: int,
	is_bounce: bool = false
) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var rebound := -1.0 if dir_x >= 0.0 else 1.0
	var impact_pt := pos + Vector2(dir_x * radius * 0.55, 0.0)
	var chunk_count := _mobile_scale(10 if is_bounce else 20)
	var puff_count := _mobile_scale(4 if is_bounce else 8)

	match ch:
		2: # Snowball burst! Flying compacted snow chunks, frost crystals & billowy snow cloud
			layer.spawn_particle(
				impact_pt, Vector2.ZERO, TrapVFXLayer.SHAPE_RING,
				Color(0.85, 0.96, 1.0, 0.85), Color.WHITE,
				radius * 0.45, radius * (1.45 if is_bounce else 2.25),
				0.26 if is_bounce else 0.36, 0.0, 0.0
			)
			for i in range(chunk_count):
				var ang := randf_range(-PI * 0.82, PI * 0.42) if rebound > 0.0 else randf_range(PI * 0.58, PI * 1.82)
				if not is_bounce and i % 3 == 0:
					ang = randf_range(-PI, 0.2)
				var spd := randf_range(95.0, 290.0 if not is_bounce else 200.0)
				var vel := Vector2(cos(ang), sin(ang)) * spd + Vector2(rebound * 45.0, -75.0)
				var is_ice := (i % 4 == 0)
				var sh := TrapVFXLayer.SHAPE_ICE_SHARD if is_ice else TrapVFXLayer.SHAPE_SNOW_CHUNK
				var c1 := Color(0.55, 0.88, 1.0, 0.95) if is_ice else Color(0.95, 0.98, 1.0, 0.96)
				var c2 := Color(1.0, 1.0, 1.0, 0.92) if is_ice else Color(0.45, 0.68, 0.88, 0.72)
				layer.spawn_particle(
					pos + Vector2(randf_range(-radius * 0.45, radius * 0.45), randf_range(-radius * 0.45, radius * 0.35)),
					vel, sh, c1, c2,
					randf_range(4.2, 9.2 if not is_bounce else 6.8),
					randf_range(1.2, 2.8),
					randf_range(0.35, 0.68),
					560.0, 1.4, randf_range(0.0, TAU), randf_range(-9.0, 9.0)
				)
			for _j in range(puff_count):
				layer.spawn_particle(
					impact_pt + Vector2(randf_range(-14.0, 14.0), randf_range(-16.0, 14.0)),
					Vector2(rebound * randf_range(25.0, 110.0), randf_range(-95.0, 20.0)),
					TrapVFXLayer.SHAPE_PUFF,
					Color(0.92, 0.97, 1.0, 0.60), Color.WHITE,
					randf_range(8.0, 16.0), randf_range(18.0, 30.0),
					randf_range(0.32, 0.56), -25.0, 3.2
				)

		3: # Vine-wrapped forest sphere bursts into whipping vine ribbons, emerald leaves & spores!
			layer.spawn_particle(
				impact_pt, Vector2.ZERO, TrapVFXLayer.SHAPE_RING,
				Color(0.35, 0.95, 0.52, 0.72), Color.WHITE,
				radius * 0.4, radius * (1.4 if is_bounce else 2.1),
				0.28 if is_bounce else 0.38, 0.0, 0.0
			)
			for i in range(chunk_count):
				var ang := randf_range(-PI * 0.85, PI * 0.35) if rebound > 0.0 else randf_range(PI * 0.65, PI * 1.85)
				if not is_bounce and i % 3 == 0:
					ang = randf_range(-PI, 0.25)
				var spd := randf_range(85.0, 260.0)
				var vel := Vector2(cos(ang), sin(ang)) * spd + Vector2(rebound * 35.0, -70.0)
				var mod3 := i % 3
				if mod3 == 0:
					# Snapping vine strand
					layer.spawn_particle(
						pos + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)),
						vel, TrapVFXLayer.SHAPE_VINE_STRAND,
						Color("#15803d", 0.96), Color("#4ade80", 0.85),
						randf_range(5.5, 9.5), randf_range(3.5, 6.0),
						randf_range(0.38, 0.68), 480.0, 1.8, randf_range(0.0, TAU), randf_range(-11.0, 11.0)
					)
				elif mod3 == 1:
					# Fluttering emerald leaf
					layer.spawn_particle(
						pos + Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0)),
						vel * 0.75, TrapVFXLayer.SHAPE_LEAF,
						Color("#22c55e", 0.95), Color("#bbf7d0", 0.85),
						randf_range(4.5, 7.8), randf_range(3.0, 5.2),
						randf_range(0.45, 0.82), 140.0, 3.2, randf_range(0.0, TAU), randf_range(-12.0, 12.0)
					)
				else:
					# Dark mossy wood/earth chunk
					layer.spawn_particle(
						pos + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)),
						vel, TrapVFXLayer.SHAPE_STONE_SHARD,
						Color("#0a2e20", 0.96), Color("#166534", 0.85),
						randf_range(4.0, 7.2), randf_range(1.6, 3.0),
						randf_range(0.34, 0.60), 620.0, 1.0, randf_range(0.0, TAU), randf_range(-10.0, 10.0)
					)
			for _j in range(puff_count):
				layer.spawn_particle(
					impact_pt + Vector2(randf_range(-12.0, 12.0), randf_range(-14.0, 10.0)),
					Vector2(rebound * randf_range(20.0, 95.0), randf_range(-80.0, -10.0)),
					TrapVFXLayer.SHAPE_EMBER,
					Color("#86efac", 0.92), Color("#22c55e", 0.65),
					randf_range(2.2, 4.0), 0.6, randf_range(0.38, 0.68), -30.0, 2.2
				)

		4: # Golden Canyon Sandstone shatters into warm ochre blocks, bronze sparks & golden sand billow!
			layer.spawn_particle(
				impact_pt, Vector2.ZERO, TrapVFXLayer.SHAPE_RING,
				Color("#fcd34d", 0.78), Color.WHITE,
				radius * 0.4, radius * (1.4 if is_bounce else 2.1),
				0.28, 0.0, 0.0
			)
			for i in range(chunk_count):
				var ang := randf_range(-PI * 0.82, PI * 0.35) if rebound > 0.0 else randf_range(PI * 0.65, PI * 1.82)
				var spd := randf_range(95.0, 275.0)
				var vel := Vector2(cos(ang), sin(ang)) * spd + Vector2(rebound * 40.0, -80.0)
				var is_gold := (i % 5 == 0)
				layer.spawn_particle(
					pos + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)),
					vel, TrapVFXLayer.SHAPE_STONE_SHARD,
					Color("#d97706", 0.96) if is_gold else Color("#78350f", 0.96),
					Color("#fef3c7", 0.90) if is_gold else Color("#f59e0b", 0.75),
					randf_range(3.8, 7.8), randf_range(1.4, 2.8),
					randf_range(0.36, 0.65), 650.0, 1.1, randf_range(0.0, TAU), randf_range(-11.0, 11.0)
				)
			for _j in range(puff_count):
				layer.spawn_particle(
					impact_pt + Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0)),
					Vector2(rebound * randf_range(25.0, 120.0), randf_range(-90.0, 15.0)),
					TrapVFXLayer.SHAPE_PUFF,
					Color("#fcd34d", 0.52), Color("#d97706", 0.40),
					randf_range(9.0, 16.0), randf_range(20.0, 32.0),
					randf_range(0.35, 0.62), -15.0, 3.0
				)

		5: # Magma Volcano Boulder explodes into volcanic basalt shards, lava sparks & fiery shockwave!
			layer.spawn_particle(
				impact_pt, Vector2.ZERO, TrapVFXLayer.SHAPE_RING,
				Color("#f97316", 0.92), Color("#fef08a", 0.90),
				radius * 0.4, radius * (1.6 if is_bounce else 2.5),
				0.28 if is_bounce else 0.36, 0.0, 0.0
			)
			for i in range(chunk_count):
				var ang := randf_range(-PI * 0.85, PI * 0.35) if rebound > 0.0 else randf_range(PI * 0.65, PI * 1.85)
				var spd := randf_range(110.0, 320.0)
				var vel := Vector2(cos(ang), sin(ang)) * spd + Vector2(rebound * 45.0, -90.0)
				if i % 2 == 0:
					layer.spawn_particle(
						pos + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)),
						vel, TrapVFXLayer.SHAPE_STONE_SHARD,
						Color("#1e0707", 0.98), Color("#f97316", 0.95),
						randf_range(4.2, 8.2), randf_range(1.5, 3.0),
						randf_range(0.35, 0.64), 680.0, 0.9, randf_range(0.0, TAU), randf_range(-12.0, 12.0)
					)
				else:
					layer.spawn_particle(
						pos + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)),
						vel * 1.05, TrapVFXLayer.SHAPE_EMBER,
						Color("#fef08a", 0.98), Color("#ef4444", 0.90),
						randf_range(2.6, 5.2), 0.6,
						randf_range(0.35, 0.68), 320.0, 1.6
					)
			for _j in range(puff_count):
				layer.spawn_particle(
					impact_pt + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)),
					Vector2(rebound * randf_range(20.0, 90.0), randf_range(-100.0, -20.0)),
					TrapVFXLayer.SHAPE_PUFF,
					Color(0.22, 0.08, 0.07, 0.58), Color.BLACK,
					randf_range(8.0, 15.0), randf_range(18.0, 28.0),
					randf_range(0.35, 0.60), -45.0, 2.5
				)

		_: # Ch 1: Gothic Obsidian-Slate Shatter + Pale Mist Ring
			layer.spawn_particle(
				impact_pt, Vector2.ZERO, TrapVFXLayer.SHAPE_RING,
				Color(0.76, 0.84, 0.96, 0.72), Color.WHITE,
				radius * 0.4, radius * (1.4 if is_bounce else 2.1),
				0.28, 0.0, 0.0
			)
			for i in range(chunk_count):
				var ang := randf_range(-PI * 0.82, PI * 0.35) if rebound > 0.0 else randf_range(PI * 0.65, PI * 1.82)
				var spd := randf_range(95.0, 270.0)
				var vel := Vector2(cos(ang), sin(ang)) * spd + Vector2(rebound * 40.0, -75.0)
				layer.spawn_particle(
					pos + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)),
					vel, TrapVFXLayer.SHAPE_STONE_SHARD,
					Color("#191b26", 0.96), Color("#64748b", 0.80),
					randf_range(4.0, 8.0), randf_range(1.5, 3.0),
					randf_range(0.34, 0.62), 660.0, 1.0, randf_range(0.0, TAU), randf_range(-11.0, 11.0)
				)
			for _j in range(puff_count):
				layer.spawn_particle(
					impact_pt + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)),
					Vector2(rebound * randf_range(20.0, 95.0), randf_range(-85.0, 10.0)),
					TrapVFXLayer.SHAPE_PUFF,
					Color(0.68, 0.75, 0.88, 0.44), Color.WHITE,
					randf_range(8.0, 14.0), randf_range(18.0, 28.0),
					randf_range(0.32, 0.56), -20.0, 3.0
				)

static func emit_boulder_trail(
	source: Node,
	pos: Vector2,
	radius: float,
	dir_x: float,
	on_floor: bool,
	ch: int
) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var back := -1.0 if dir_x >= 0.0 else 1.0
	var foot := pos + Vector2(back * radius * 0.45, radius * 0.82)

	match ch:
		2: # Snow spray & powder wake
			if on_floor:
				layer.spawn_particle(
					foot,
					Vector2(back * randf_range(35.0, 95.0), randf_range(-85.0, -25.0)),
					TrapVFXLayer.SHAPE_SNOW_CHUNK,
					Color(0.95, 0.98, 1.0, 0.90), Color(0.50, 0.76, 0.95, 0.65),
					randf_range(3.0, 5.5), 1.0, randf_range(0.22, 0.42), 360.0, 2.2
				)
			layer.spawn_particle(
				pos + Vector2(randf_range(-radius * 0.6, radius * 0.6), randf_range(-radius * 0.6, radius * 0.5)),
				Vector2(back * randf_range(15.0, 50.0), randf_range(-35.0, 10.0)),
				TrapVFXLayer.SHAPE_PUFF,
				Color(0.90, 0.97, 1.0, 0.45), Color.WHITE,
				randf_range(3.5, 6.0), randf_range(7.0, 11.0), randf_range(0.20, 0.36), -15.0, 3.0
			)
		3: # Shedding fluttering emerald leaves & forest spores
			layer.spawn_particle(
				pos + Vector2(back * randf_range(4.0, radius * 0.7), randf_range(-radius * 0.5, radius * 0.6)),
				Vector2(back * randf_range(25.0, 80.0), randf_range(-70.0, -15.0)),
				TrapVFXLayer.SHAPE_LEAF,
				Color("#22c55e", 0.92), Color("#bbf7d0", 0.80),
				randf_range(3.8, 6.2), randf_range(2.4, 4.0), randf_range(0.38, 0.68),
				90.0, 3.4, randf_range(0.0, TAU), randf_range(-10.0, 10.0)
			)
			if on_floor:
				layer.spawn_particle(
					foot, Vector2(back * randf_range(20.0, 55.0), randf_range(-40.0, -10.0)),
					TrapVFXLayer.SHAPE_EMBER,
					Color("#86efac", 0.85), Color("#16a34a", 0.60),
					2.4, 0.5, 0.34, -25.0, 2.5
				)
		4: # Golden canyon sand-dust cloud & pebbles
			if on_floor:
				layer.spawn_particle(
					foot, Vector2(back * randf_range(35.0, 105.0), randf_range(-70.0, -15.0)),
					TrapVFXLayer.SHAPE_PUFF,
					Color("#fcd34d", 0.48), Color("#d97706", 0.35),
					randf_range(4.5, 8.0), randf_range(10.0, 16.0), randf_range(0.24, 0.44), -12.0, 3.0
				)
				layer.spawn_particle(
					foot, Vector2(back * randf_range(45.0, 110.0), randf_range(-90.0, -30.0)),
					TrapVFXLayer.SHAPE_STONE_SHARD,
					Color("#92400e", 0.90), Color("#fcd34d", 0.70),
					randf_range(2.2, 4.0), 0.8, 0.32, 540.0, 1.0, randf_range(0.0, TAU), randf_range(-9.0, 9.0)
				)
		5: # Rising glowing embers & volcanic ash
			layer.spawn_particle(
				pos + Vector2(randf_range(-radius * 0.6, radius * 0.6), randf_range(-radius * 0.4, radius * 0.7)),
				Vector2(back * randf_range(25.0, 90.0), randf_range(-105.0, -35.0)),
				TrapVFXLayer.SHAPE_EMBER,
				Color("#fef08a", 0.95), Color("#f97316", 0.85),
				randf_range(2.2, 4.2), 0.5, randf_range(0.28, 0.55), -55.0, 2.0
			)
			if on_floor:
				layer.spawn_particle(
					foot, Vector2(back * randf_range(25.0, 75.0), randf_range(-55.0, -15.0)),
					TrapVFXLayer.SHAPE_PUFF,
					Color(0.22, 0.08, 0.07, 0.50), Color.BLACK,
					4.5, 11.0, 0.32, -35.0, 2.6
				)
		_: # Ch 1: Stone chips & gothic mist
			if on_floor:
				layer.spawn_particle(
					foot, Vector2(back * randf_range(30.0, 85.0), randf_range(-75.0, -20.0)),
					TrapVFXLayer.SHAPE_STONE_SHARD,
					Color("#232736", 0.92), Color("#64748b", 0.70),
					randf_range(2.2, 4.0), 0.8, 0.30, 560.0, 1.0, randf_range(0.0, TAU), randf_range(-8.0, 8.0)
				)
				layer.spawn_particle(
					foot, Vector2(back * randf_range(15.0, 55.0), randf_range(-35.0, -8.0)),
					TrapVFXLayer.SHAPE_PUFF,
					Color(0.66, 0.74, 0.86, 0.36), Color.WHITE,
					4.0, 9.5, 0.28, -14.0, 3.0
				)

static func emit_boulder_land(source: Node, pos: Vector2, radius: float, ch: int) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var foot := pos + Vector2(0.0, radius * 0.88)
	var cnt := _mobile_scale(8)
	for i in range(cnt):
		var side := -1.0 if i < cnt / 2 else 1.0
		var p := foot + Vector2(side * randf_range(4.0, radius * 0.7), randf_range(-3.0, 2.0))
		var vel := Vector2(side * randf_range(55.0, 165.0), randf_range(-105.0, -25.0))
		_spawn_biome_debris_unit(layer, p, vel, ch, 0.90)

static func emit_boulder_rumble(source: Node, pos: Vector2, radius: float, ch: int) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var pt := pos + Vector2(randf_range(-radius * 0.7, radius * 0.7), randf_range(-radius * 0.2, radius * 0.7))
	match ch:
		2:
			layer.spawn_particle(pt, Vector2(randf_range(-25.0, 25.0), randf_range(-25.0, 25.0)), TrapVFXLayer.SHAPE_SNOW_CHUNK, Color(0.95, 0.98, 1.0, 0.85), Color("#7dd3fc", 0.6), 3.0, 1.0, 0.28, 220.0, 2.0)
		3:
			layer.spawn_particle(pt, Vector2(randf_range(-30.0, 30.0), randf_range(-40.0, 10.0)), TrapVFXLayer.SHAPE_LEAF, Color("#22c55e", 0.90), Color("#bbf7d0", 0.8), 4.0, 2.5, 0.42, 80.0, 3.0, randf_range(0.0, TAU), randf_range(-8.0, 8.0))
		4:
			layer.spawn_particle(pt, Vector2(randf_range(-20.0, 20.0), randf_range(10.0, 40.0)), TrapVFXLayer.SHAPE_PUFF, Color("#fcd34d", 0.55), Color("#d97706", 0.4), 3.2, 6.5, 0.30, 120.0, 2.0)
		5:
			layer.spawn_particle(pt, Vector2(randf_range(-30.0, 30.0), randf_range(-80.0, -25.0)), TrapVFXLayer.SHAPE_EMBER, Color("#fef08a", 0.95), Color("#f97316", 0.85), 2.5, 0.5, 0.35, -45.0, 2.0)
		_:
			layer.spawn_particle(pt, Vector2(randf_range(-25.0, 25.0), randf_range(-20.0, 30.0)), TrapVFXLayer.SHAPE_STONE_SHARD, Color("#242938", 0.9), Color("#64748b", 0.7), 2.6, 0.9, 0.28, 380.0, 1.2)

# ==============================================================================
# 2. CRUSHER / FALLING CEILING — DETACH & SLAM IMPACT
# ==============================================================================

static func emit_ceiling_detach(source: Node, top_left: Vector2, width: float, ch: int) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var cnt := _mobile_scale(6)
	for i in range(cnt):
		var px := top_left.x + randf_range(4.0, maxf(8.0, width - 4.0))
		var p := Vector2(px, top_left.y + randf_range(0.0, 10.0))
		var vel := Vector2(randf_range(-30.0, 30.0), randf_range(15.0, 70.0))
		_spawn_biome_debris_unit(layer, p, vel, ch, 0.75)

static func emit_slam_impact(source: Node, center_bottom: Vector2, width: float, ch: int) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var cnt := _mobile_scale(12)
	var half_w := maxf(16.0, width * 0.48)
	for i in range(cnt):
		var side := -1.0 if i < cnt / 2 else 1.0
		var p := center_bottom + Vector2(side * randf_range(half_w * 0.25, half_w), randf_range(-4.0, 2.0))
		var vel := Vector2(side * randf_range(70.0, 210.0), randf_range(-115.0, -20.0))
		_spawn_biome_debris_unit(layer, p, vel, ch, 1.05)

# ==============================================================================
# 3. STALACTITE (FallingSpikeTrap) — SHAKE & GROUND IMPACT (ICICLE SHATTER!)
# ==============================================================================

static func emit_stalactite_shake(source: Node, pos: Vector2, ch: int) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var p := pos + Vector2(randf_range(-8.0, 8.0), randf_range(2.0, 14.0))
	_spawn_biome_debris_unit(layer, p, Vector2(randf_range(-20.0, 20.0), randf_range(25.0, 70.0)), ch, 0.65)

static func emit_stalactite_impact(source: Node, pos: Vector2, ch: int) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var cnt := _mobile_scale(12 if ch == 2 else 8)
	if ch == 2:
		# Crisp glacial icicle shatter burst!
		layer.spawn_particle(
			pos, Vector2.ZERO, TrapVFXLayer.SHAPE_RING,
			Color(0.70, 0.94, 1.0, 0.85), Color.WHITE,
			4.0, 26.0, 0.24, 0.0, 0.0
		)
		for i in range(cnt):
			var ang := randf_range(-PI * 0.92, -PI * 0.08)
			var spd := randf_range(75.0, 235.0)
			var is_snow := (i % 3 == 0)
			layer.spawn_particle(
				pos + Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 2.0)),
				Vector2(cos(ang), sin(ang)) * spd,
				TrapVFXLayer.SHAPE_SNOW_CHUNK if is_snow else TrapVFXLayer.SHAPE_ICE_SHARD,
				Color(0.94, 0.98, 1.0, 0.92) if is_snow else Color(0.35, 0.84, 1.0, 0.96),
				Color("#7dd3fc", 0.72) if is_snow else Color.WHITE,
				randf_range(3.2, 6.2), 1.0, randf_range(0.28, 0.56),
				560.0, 1.3, randf_range(0.0, TAU), randf_range(-12.0, 12.0)
			)
		return

	for i in range(cnt):
		var ang := randf_range(-PI * 0.90, -PI * 0.10)
		var spd := randf_range(65.0, 185.0)
		_spawn_biome_debris_unit(layer, pos + Vector2(randf_range(-6.0, 6.0), -2.0), Vector2(cos(ang), sin(ang)) * spd, ch, 0.90)

# ==============================================================================
# 4. FLOOR SPIKES / POP-UP / JUMPING / SPRING / CRUMBLE / DODGE / SAW / DOOR
# ==============================================================================

static func emit_spike_erupt(source: Node, base_center: Vector2, width: float, ch: int) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var cnt := _mobile_scale(7)
	var hw := maxf(8.0, width * 0.45)
	for _i in range(cnt):
		var p := base_center + Vector2(randf_range(-hw, hw), randf_range(-2.0, 2.0))
		var vel := Vector2(randf_range(-65.0, 65.0), randf_range(-165.0, -55.0))
		_spawn_biome_debris_unit(layer, p, vel, ch, 0.82)

static func emit_spike_slide(source: Node, base_center: Vector2, width: float, slide_dir: float, ch: int) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var cnt := _mobile_scale(6)
	var back := -1.0 if slide_dir >= 0.0 else 1.0
	for _i in range(cnt):
		var p := base_center + Vector2(randf_range(-width * 0.35, width * 0.35), randf_range(-4.0, 2.0))
		var vel := Vector2(back * randf_range(40.0, 130.0), randf_range(-75.0, -15.0))
		_spawn_biome_debris_unit(layer, p, vel, ch, 0.78)

static func emit_spring_burst(source: Node, base_center: Vector2, width: float, ch: int) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var pal := TrapBiomeArt.get_palette(ch)
	var ring_col: Color = pal["accent"]
	layer.spawn_particle(
		base_center + Vector2(0.0, -6.0), Vector2(0.0, -35.0),
		TrapVFXLayer.SHAPE_RING,
		Color(ring_col.r, ring_col.g, ring_col.b, 0.82), Color.WHITE,
		width * 0.25, width * 0.95, 0.24, 0.0, 0.0
	)
	var cnt := _mobile_scale(10)
	for _i in range(cnt):
		var p := base_center + Vector2(randf_range(-width * 0.4, width * 0.4), randf_range(-6.0, 0.0))
		var vel := Vector2(randf_range(-75.0, 75.0), randf_range(-220.0, -90.0))
		_spawn_biome_debris_unit(layer, p, vel, ch, 0.90)

static func emit_crumble_debris(source: Node, top_left: Vector2, size: Vector2, ch: int, heavy: bool = false) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var cnt := _mobile_scale(10 if heavy else 3)
	for _i in range(cnt):
		var p := top_left + Vector2(randf_range(4.0, maxf(8.0, size.x - 4.0)), randf_range(0.0, minf(size.y, 18.0)))
		var vel := Vector2(randf_range(-55.0, 55.0), randf_range(-65.0, 35.0) if heavy else randf_range(10.0, 55.0))
		_spawn_biome_debris_unit(layer, p, vel, ch, 0.92 if heavy else 0.72)

static func emit_dodge_whoosh(source: Node, center: Vector2, size: Vector2, move_dir: Vector2, ch: int) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var back := -move_dir.normalized() if move_dir.length_squared() > 0.01 else Vector2.LEFT
	var cnt := _mobile_scale(7)
	for _i in range(cnt):
		var p := center + Vector2(randf_range(-size.x * 0.35, size.x * 0.35), randf_range(-size.y * 0.35, size.y * 0.35))
		var vel := back * randf_range(40.0, 120.0) + Vector2(randf_range(-25.0, 25.0), randf_range(-40.0, 20.0))
		_spawn_biome_debris_unit(layer, p, vel, ch, 0.80)

static func emit_saw_spark(source: Node, pos: Vector2, radius: float, ch: int, burst: bool = false) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var cnt := _mobile_scale(8 if burst else 1)
	for _i in range(cnt):
		var ang := randf_range(0.0, TAU)
		var p := pos + Vector2(cos(ang), sin(ang)) * (radius * 0.85)
		var tang := Vector2(-sin(ang), cos(ang))
		var vel := (tang * randf_range(50.0, 140.0)) + Vector2(cos(ang), sin(ang)) * (randf_range(60.0, 150.0) if burst else randf_range(18.0, 55.0))
		match ch:
			2:
				layer.spawn_particle(p, vel, TrapVFXLayer.SHAPE_ICE_SHARD, Color("#7dd3fc", 0.90), Color.WHITE, 3.0 if burst else 2.2, 0.6, 0.28, 140.0, 2.5, ang, 8.0)
			3:
				layer.spawn_particle(p, vel * 0.8, TrapVFXLayer.SHAPE_LEAF if burst else TrapVFXLayer.SHAPE_EMBER, Color("#4ade80", 0.90), Color("#bbf7d0", 0.85), 4.0 if burst else 2.0, 0.8, 0.36, 70.0, 3.0, ang, 9.0)
			4:
				layer.spawn_particle(p, vel, TrapVFXLayer.SHAPE_EMBER, Color("#fef3c7", 0.90), Color("#f59e0b", 0.80), 2.4 if burst else 1.8, 0.4, 0.26, 220.0, 2.0)
			5:
				layer.spawn_particle(p, vel, TrapVFXLayer.SHAPE_EMBER, Color("#fef08a", 0.96), Color("#ef4444", 0.90), 3.0 if burst else 2.1, 0.5, 0.32, 120.0, 1.8)
			_:
				layer.spawn_particle(p, vel, TrapVFXLayer.SHAPE_EMBER, Color("#e2e8f0", 0.85), Color("#94a3b8", 0.70), 2.2 if burst else 1.6, 0.4, 0.24, 240.0, 2.2)

static func emit_door_vanish(source: Node, pos: Vector2, door_size: Vector2, ch: int) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var cnt := _mobile_scale(9)
	for _i in range(cnt):
		var p := pos + Vector2(randf_range(-door_size.x * 0.45, door_size.x * 0.45), randf_range(-door_size.y * 0.35, 0.0))
		var vel := Vector2(randf_range(-55.0, 55.0), randf_range(-80.0, -15.0))
		_spawn_biome_debris_unit(layer, p, vel, ch, 0.85)

static func emit_beam_mote(source: Node, start_pos: Vector2, end_pos: Vector2, ch: int) -> void:
	var layer := get_layer(source)
	if layer == null:
		return
	var p := start_pos.lerp(end_pos, randf())
	var vel := Vector2(randf_range(-24.0, 24.0), randf_range(-42.0, -12.0))
	match ch:
		2:
			layer.spawn_particle(p, vel, TrapVFXLayer.SHAPE_ICE_SHARD, Color("#7dd3fc", 0.85), Color.WHITE, 2.4, 0.5, 0.30, 40.0, 2.0, randf_range(0.0, TAU), 6.0)
		3:
			layer.spawn_particle(p, vel, TrapVFXLayer.SHAPE_EMBER, Color("#86efac", 0.88), Color("#22c55e", 0.70), 2.2, 0.5, 0.38, -20.0, 2.0)
		4:
			layer.spawn_particle(p, vel, TrapVFXLayer.SHAPE_EMBER, Color("#fef3c7", 0.88), Color("#f59e0b", 0.75), 2.0, 0.4, 0.30, -15.0, 2.2)
		5:
			layer.spawn_particle(p, vel * 1.4, TrapVFXLayer.SHAPE_EMBER, Color("#fef08a", 0.95), Color("#f97316", 0.88), 2.4, 0.5, 0.34, -55.0, 1.8)
		_:
			layer.spawn_particle(p, vel, TrapVFXLayer.SHAPE_EMBER, Color("#fca5a5", 0.82), Color("#ef4444", 0.68), 2.0, 0.4, 0.28, -18.0, 2.2)

# ==============================================================================
# INTERNAL HELPER: SINGLE BIOME-AUTHENTIC DEBRIS PARTICLE
# ==============================================================================

static func _spawn_biome_debris_unit(layer: Node2D, p: Vector2, vel: Vector2, ch: int, scale_k: float) -> void:
	match ch:
		2: # Snow & ice splinters
			var is_ice := randf() < 0.35
			layer.spawn_particle(
				p, vel,
				TrapVFXLayer.SHAPE_ICE_SHARD if is_ice else TrapVFXLayer.SHAPE_SNOW_CHUNK,
				Color("#7dd3fc", 0.92) if is_ice else Color(0.95, 0.98, 1.0, 0.92),
				Color.WHITE if is_ice else Color(0.48, 0.72, 0.92, 0.72),
				randf_range(3.2, 6.2) * scale_k, 1.0,
				randf_range(0.28, 0.55), 420.0 if is_ice else 280.0, 1.8,
				randf_range(0.0, TAU), randf_range(-10.0, 10.0)
			)
		3: # Emerald leaves, moss chunks & glowing spores
			var roll := randf()
			if roll < 0.55:
				layer.spawn_particle(
					p, vel * 0.8, TrapVFXLayer.SHAPE_LEAF,
					Color("#22c55e", 0.94), Color("#bbf7d0", 0.85),
					randf_range(4.0, 6.8) * scale_k, 2.2,
					randf_range(0.38, 0.72), 110.0, 3.2,
					randf_range(0.0, TAU), randf_range(-11.0, 11.0)
				)
			elif roll < 0.80:
				layer.spawn_particle(
					p, vel, TrapVFXLayer.SHAPE_VINE_STRAND,
					Color("#15803d", 0.94), Color("#4ade80", 0.82),
					randf_range(4.2, 6.8) * scale_k, 2.5,
					randf_range(0.32, 0.56), 420.0, 1.8,
					randf_range(0.0, TAU), randf_range(-9.0, 9.0)
				)
			else:
				layer.spawn_particle(
					p, vel * 0.55, TrapVFXLayer.SHAPE_EMBER,
					Color("#86efac", 0.92), Color("#22c55e", 0.70),
					randf_range(2.2, 3.6) * scale_k, 0.5,
					randf_range(0.38, 0.65), -25.0, 2.4
				)
		4: # Golden canyon sand puff & sandstone chips
			if randf() < 0.52:
				layer.spawn_particle(
					p, vel * 0.7, TrapVFXLayer.SHAPE_PUFF,
					Color("#fcd34d", 0.50), Color("#d97706", 0.35),
					randf_range(5.0, 9.5) * scale_k, randf_range(11.0, 18.0) * scale_k,
					randf_range(0.28, 0.52), -12.0, 3.0
				)
			else:
				layer.spawn_particle(
					p, vel, TrapVFXLayer.SHAPE_STONE_SHARD,
					Color("#92400e", 0.95), Color("#fcd34d", 0.80),
					randf_range(3.0, 5.8) * scale_k, 1.0,
					randf_range(0.30, 0.56), 540.0, 1.2,
					randf_range(0.0, TAU), randf_range(-10.0, 10.0)
				)
		5: # Volcanic embers & dark basalt chunks
			if randf() < 0.58:
				layer.spawn_particle(
					p, vel * 0.9, TrapVFXLayer.SHAPE_EMBER,
					Color("#fef08a", 0.96), Color("#f97316", 0.88),
					randf_range(2.4, 4.4) * scale_k, 0.5,
					randf_range(0.30, 0.58), 110.0, 1.8
				)
			else:
				layer.spawn_particle(
					p, vel, TrapVFXLayer.SHAPE_STONE_SHARD,
					Color("#1f0707", 0.96), Color("#f97316", 0.90),
					randf_range(3.2, 6.2) * scale_k, 1.0,
					randf_range(0.30, 0.55), 580.0, 1.0,
					randf_range(0.0, TAU), randf_range(-11.0, 11.0)
				)
		_: # Ch 1: Gothic slate rock shards & twilight mist puff
			if randf() < 0.45:
				layer.spawn_particle(
					p, vel * 0.65, TrapVFXLayer.SHAPE_PUFF,
					Color(0.70, 0.78, 0.90, 0.40), Color.WHITE,
					randf_range(4.5, 8.5) * scale_k, randf_range(10.0, 16.0) * scale_k,
					randf_range(0.26, 0.48), -15.0, 3.0
				)
			else:
				layer.spawn_particle(
					p, vel, TrapVFXLayer.SHAPE_STONE_SHARD,
					Color("#1e202c", 0.95), Color("#64748b", 0.75),
					randf_range(3.0, 5.8) * scale_k, 1.0,
					randf_range(0.28, 0.54), 560.0, 1.1,
					randf_range(0.0, TAU), randf_range(-10.0, 10.0)
				)
