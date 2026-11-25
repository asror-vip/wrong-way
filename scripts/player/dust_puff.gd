extends Node2D

# Lightweight pooled dust / impact puff for jumps, landings, skids, dashes, and respawns.
var _vel: Vector2 = Vector2.ZERO
var _radius: float = 4.0
var _color: Color = Color(0.86, 0.91, 1.0, 0.65)
var _age: float = 0.0
var _lifetime: float = 0.24
var _active: bool = false
var _is_ring: bool = false
var _ring_max_radius: float = 22.0

func _ready() -> void:
	visible = false
	set_process(false)

func spawn(
	pos: Vector2,
	vel: Vector2,
	radius: float = 4.5,
	col: Color = Color(0.88, 0.92, 1.0, 0.65),
	life: float = 0.24,
	is_ring: bool = false,
	ring_max_r: float = 24.0
) -> void:
	global_position = pos
	_vel = vel
	_radius = radius
	_color = col
	_age = 0.0
	_lifetime = maxf(0.05, life)
	_is_ring = is_ring
	_ring_max_radius = ring_max_r
	_active = true
	visible = true
	set_process(true)
	queue_redraw()

func is_active() -> bool:
	return _active

func _process(delta: float) -> void:
	if not _active:
		return
	_age += delta
	if _age >= _lifetime:
		_active = false
		visible = false
		set_process(false)
		return
	global_position += _vel * delta
	_vel = _vel.lerp(Vector2(0.0, -14.0), delta * 6.5)
	queue_redraw()

func _draw() -> void:
	if not _active:
		return
	var t := clampf(_age / _lifetime, 0.0, 1.0)
	var ease_out := 1.0 - pow(1.0 - t, 2.0)
	var alpha := _color.a * (1.0 - t)
	if _is_ring:
		var r := lerpf(_radius, _ring_max_radius, ease_out)
		var width := lerpf(2.2, 0.6, t)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color(_color.r, _color.g, _color.b, alpha), width, true)
	else:
		var r := _radius * lerpf(1.0, 0.2, ease_out)
		draw_circle(Vector2.ZERO, r, Color(_color.r, _color.g, _color.b, alpha))
