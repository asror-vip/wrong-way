extends Node2D

# Lightweight pooled 2D particle renderer for all seasonal biome trap effects.
# Zero Node allocation per particle; sleeps (_process disabled) whenever empty.

const SHAPE_PUFF := 0
const SHAPE_SNOW_CHUNK := 1
const SHAPE_ICE_SHARD := 2
const SHAPE_LEAF := 3
const SHAPE_VINE_STRAND := 4
const SHAPE_STONE_SHARD := 5
const SHAPE_EMBER := 6
const SHAPE_RING := 7

var _capacity: int = 96
var _cursor: int = 0
var _active_count: int = 0
var _default_owner_id: int = 0

# Structure-of-arrays (fast, zero per-particle dictionary allocations during simulation)
var _alive: PackedByteArray = PackedByteArray()
var _shape: PackedByteArray = PackedByteArray()
var _pos: PackedVector2Array = PackedVector2Array()
var _vel: PackedVector2Array = PackedVector2Array()
var _gravity: PackedFloat32Array = PackedFloat32Array()
var _drag: PackedFloat32Array = PackedFloat32Array()
var _rot: PackedFloat32Array = PackedFloat32Array()
var _rot_vel: PackedFloat32Array = PackedFloat32Array()
var _size: PackedFloat32Array = PackedFloat32Array()
var _end_size: PackedFloat32Array = PackedFloat32Array()
var _age: PackedFloat32Array = PackedFloat32Array()
var _life: PackedFloat32Array = PackedFloat32Array()
var _col: PackedColorArray = PackedColorArray()
var _col2: PackedColorArray = PackedColorArray()
var _owner_id: PackedInt64Array = PackedInt64Array()

func _ready() -> void:
	z_index = 12
	_capacity = 56 if OS.has_feature("mobile") else 96
	_init_pool()
	set_process(false)

func _init_pool() -> void:
	_alive.resize(_capacity)
	_shape.resize(_capacity)
	_pos.resize(_capacity)
	_vel.resize(_capacity)
	_gravity.resize(_capacity)
	_drag.resize(_capacity)
	_rot.resize(_capacity)
	_rot_vel.resize(_capacity)
	_size.resize(_capacity)
	_end_size.resize(_capacity)
	_age.resize(_capacity)
	_life.resize(_capacity)
	_col.resize(_capacity)
	_col2.resize(_capacity)
	_owner_id.resize(_capacity)
	for i in range(_capacity):
		_alive[i] = 0
		_owner_id[i] = 0
	_active_count = 0
	_cursor = 0

func set_spawn_owner(owner_id: int) -> void:
	_default_owner_id = owner_id

func spawn_particle(
	world_pos: Vector2,
	vel: Vector2,
	shape: int,
	col: Color,
	col2: Color,
	start_size: float,
	end_size: float,
	life: float,
	gravity: float = 420.0,
	drag: float = 2.0,
	rot: float = 0.0,
	rot_vel: float = 0.0,
	owner_id: int = 0
) -> void:
	if _alive.size() != _capacity:
		_init_pool()
	var idx := _cursor
	_cursor = (_cursor + 1) % _capacity
	var was_alive := _alive[idx] != 0
	_alive[idx] = 1
	_shape[idx] = shape
	_pos[idx] = to_local(world_pos)
	_vel[idx] = vel
	_gravity[idx] = gravity
	_drag[idx] = drag
	_rot[idx] = rot
	_rot_vel[idx] = rot_vel
	_size[idx] = start_size
	_end_size[idx] = end_size
	_age[idx] = 0.0
	_life[idx] = maxf(0.06, life)
	_col[idx] = col
	_col2[idx] = col2
	_owner_id[idx] = owner_id if owner_id != 0 else _default_owner_id
	if not was_alive:
		_active_count += 1
	if not is_processing():
		set_process(true)
	queue_redraw()

func clear_owner(owner_id: int) -> void:
	if owner_id == 0:
		return
	var alive_now := 0
	for i in range(_alive.size()):
		if _alive[i] == 0:
			continue
		if _owner_id[i] == owner_id:
			_alive[i] = 0
			_owner_id[i] = 0
		else:
			alive_now += 1
	_active_count = alive_now
	if _active_count <= 0:
		set_process(false)
	queue_redraw()

func clear_all() -> void:
	for i in range(_alive.size()):
		_alive[i] = 0
		_owner_id[i] = 0
	_active_count = 0
	_cursor = 0
	set_process(false)
	queue_redraw()

func get_active_count() -> int:
	return _active_count

func _process(delta: float) -> void:
	if _active_count <= 0:
		set_process(false)
		return
	var alive_now := 0
	for i in range(_capacity):
		if _alive[i] == 0:
			continue
		var a := _age[i] + delta
		if a >= _life[i]:
			_alive[i] = 0
			continue
		_age[i] = a
		var v := _vel[i]
		v.y += _gravity[i] * delta
		var d := _drag[i]
		if d > 0.0:
			var damp := maxf(0.0, 1.0 - d * delta)
			v *= damp
		_vel[i] = v
		_pos[i] = _pos[i] + v * delta
		_rot[i] = _rot[i] + _rot_vel[i] * delta
		alive_now += 1
	_active_count = alive_now
	queue_redraw()
	if _active_count <= 0:
		set_process(false)

func _draw() -> void:
	if _active_count <= 0:
		return
	for i in range(_capacity):
		if _alive[i] == 0:
			continue
		var t := clampf(_age[i] / _life[i], 0.0, 1.0)
		var ease_out := 1.0 - pow(1.0 - t, 2.0)
		var sz := lerpf(_size[i], _end_size[i], ease_out)
		if sz <= 0.2:
			continue
		var fade := 1.0 - pow(t, 1.35)
		var c := _col[i]
		c.a *= fade
		var c2 := _col2[i]
		c2.a *= fade
		var p := _pos[i]
		var r := _rot[i]
		var sh := _shape[i]

		match sh:
			SHAPE_SNOW_CHUNK:
				# Soft layered snow clump with cool frost shadow underside
				draw_circle(p + Vector2(0.8, 1.0), sz * 0.96, c2)
				draw_circle(p, sz, c)
				if sz > 3.0:
					draw_circle(p + Vector2(-sz * 0.25, -sz * 0.25), sz * 0.45, Color(1.0, 1.0, 1.0, c.a * 0.8))
			SHAPE_ICE_SHARD:
				var ca := cos(r)
				var sa := sin(r)
				var fwd := Vector2(ca, sa)
				var side := Vector2(-sa, ca)
				var pts := PackedVector2Array([
					p + fwd * (sz * 1.45),
					p + side * (sz * 0.58),
					p - fwd * (sz * 1.10),
					p - side * (sz * 0.58),
				])
				draw_colored_polygon(pts, c)
				draw_polyline(pts, c2, 0.9, true)
			SHAPE_LEAF:
				var ca := cos(r)
				var sa := sin(r)
				var fwd := Vector2(ca, sa)
				var side := Vector2(-sa, ca)
				var pts := PackedVector2Array([
					p - fwd * (sz * 1.15),
					p + side * (sz * 0.55),
					p + fwd * (sz * 1.25),
					p - side * (sz * 0.55),
				])
				draw_colored_polygon(pts, c)
				draw_line(p - fwd * (sz * 0.85), p + fwd * (sz * 0.95), c2, 0.9)
			SHAPE_VINE_STRAND:
				var ca := cos(r)
				var sa := sin(r)
				var fwd := Vector2(ca, sa)
				var side := Vector2(-sa, ca)
				var pts := PackedVector2Array([
					p - fwd * (sz * 1.5),
					p - fwd * (sz * 0.4) + side * (sz * 0.45),
					p + fwd * (sz * 0.5) - side * (sz * 0.35),
					p + fwd * (sz * 1.5) + side * (sz * 0.20),
				])
				draw_polyline(pts, c, maxf(1.4, sz * 0.34), true)
				draw_polyline(pts, c2, 0.9, true)
			SHAPE_STONE_SHARD:
				var ca := cos(r)
				var sa := sin(r)
				var fwd := Vector2(ca, sa)
				var side := Vector2(-sa, ca)
				var pts := PackedVector2Array([
					p + fwd * (sz * 1.15) - side * (sz * 0.25),
					p + fwd * (sz * 0.30) + side * (sz * 0.90),
					p - fwd * (sz * 1.00) + side * (sz * 0.40),
					p - fwd * (sz * 0.85) - side * (sz * 0.78),
				])
				draw_colored_polygon(pts, c)
				draw_line(pts[0], pts[1], c2, 1.0)
			SHAPE_EMBER:
				draw_circle(p, sz * 1.75, Color(c2.r, c2.g, c2.b, c2.a * 0.38))
				draw_circle(p, sz, c)
			SHAPE_RING:
				var width := lerpf(2.6, 0.5, t)
				draw_arc(p, sz, 0.0, TAU, 24, c, width, true)
			_: # SHAPE_PUFF
				draw_circle(p, sz, c)
