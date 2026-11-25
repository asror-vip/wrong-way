extends Area2D
class_name CircularSawTrap

const TrapBiomeArt := preload("res://scripts/traps/trap_biome_art.gd")
const TrapBiomeVFX := preload("res://scripts/traps/trap_biome_vfx.gd")

@export var orbit_radius: float = 64.0 # 2x katak radiusi
@export var orbit_speed: float = 2.4
@export var saw_radius: float = 16.0 # 32px diametr
@export var clockwise: bool = true
@export var start_angle_deg: float = 0.0

var current_angle: float = 0.0
var spin_angle: float = 0.0
var blade_offset: Vector2 = Vector2.ZERO
var _anim_time: float = 0.0
var _spark_accum: float = 0.0

@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("traps")
	current_angle = deg_to_rad(start_angle_deg)
	_update_blade_position()
	if col_shape:
		var circle := CircleShape2D.new()
		circle.radius = saw_radius - 1.0
		col_shape.shape = circle
		col_shape.position = blade_offset
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var dir := 1.0 if clockwise else -1.0
	_anim_time += delta
	current_angle += orbit_speed * dir * delta
	spin_angle += 16.0 * dir * delta
	
	_update_blade_position()
	if col_shape:
		col_shape.position = blade_offset
	_spark_accum += delta
	var spark_step := 0.34 if OS.has_feature("mobile") else 0.22
	if _spark_accum >= spark_step:
		_spark_accum = 0.0
		TrapBiomeVFX.emit_saw_spark(self, global_position + blade_offset, saw_radius, TrapBiomeArt.get_chapter(self), false)
	queue_redraw()

func _update_blade_position() -> void:
	if orbit_radius > 0.0:
		blade_offset = Vector2(cos(current_angle), sin(current_angle)) * orbit_radius
	else:
		blade_offset = Vector2.ZERO

func _draw() -> void:
	var ch := TrapBiomeArt.get_chapter(self)
	if orbit_radius > 0.0:
		TrapBiomeArt.draw_saw_tether(self, Vector2.ZERO, blade_offset, orbit_radius, ch)
	TrapBiomeArt.draw_saw_blade(self, blade_offset, saw_radius, spin_angle, ch, _anim_time)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController or body.is_in_group("player"):
		if "is_dead" in body and body.is_dead:
			return
		if "is_invulnerable" in body and body.is_invulnerable:
			return
		if body.has_method("kill"):
			body.kill()

func reset_trap() -> void:
	current_angle = deg_to_rad(start_angle_deg)
	_spark_accum = 0.0
	_update_blade_position()
	if col_shape:
		col_shape.position = blade_offset
	queue_redraw()
