extends Area2D
class_name LaserBeamTrap

const TrapBiomeArt := preload("res://scripts/traps/trap_biome_art.gd")
const TrapBiomeVFX := preload("res://scripts/traps/trap_biome_vfx.gd")

@export var beam_length: float = 160.0
@export var active_time: float = 1.6
@export var inactive_time: float = 1.4
@export var is_vertical: bool = true

var timer: float = 0.0
var is_active: bool = true
var pulse_phase: float = 0.0
var _charge_ratio: float = 0.0
var _mote_accum: float = 0.0

@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("traps")
	_update_shape()
	body_entered.connect(_on_body_entered)

func _update_shape() -> void:
	if not col_shape:
		return
	var rect_shape := RectangleShape2D.new()
	if is_vertical:
		rect_shape.size = Vector2(8, beam_length)
		col_shape.position = Vector2(0, beam_length / 2.0)
	else:
		rect_shape.size = Vector2(beam_length, 8)
		col_shape.position = Vector2(beam_length / 2.0, 0)
	col_shape.shape = rect_shape

func _physics_process(delta: float) -> void:
	timer += delta
	pulse_phase += delta * 10.0
	
	var cycle := maxf(0.05, active_time + inactive_time)
	var current_t := fmod(timer, cycle)
	var new_active := (current_t < active_time)
	var ch := TrapBiomeArt.get_chapter(self)

	if not new_active:
		var remain := cycle - current_t
		_charge_ratio = clampf(1.0 - (remain / 0.28), 0.0, 1.0)
	else:
		_charge_ratio = 0.0
	
	if new_active != is_active:
		is_active = new_active
		if col_shape:
			col_shape.set_deferred("disabled", not is_active)
		if is_active:
			var sm = get_node_or_null("/root/SoundManager")
			if sm and sm.has_method("play_biome_trap"):
				sm.play_biome_trap("beam", ch)
			elif sm and sm.has_method("play"):
				sm.play("trap")

	if is_active:
		_mote_accum += delta
		var mote_step := 0.26 if OS.has_feature("mobile") else 0.14
		if _mote_accum >= mote_step:
			_mote_accum = 0.0
			var end_pt := global_position + (Vector2(0.0, beam_length) if is_vertical else Vector2(beam_length, 0.0))
			TrapBiomeVFX.emit_beam_mote(self, global_position, end_pt, ch)
			
	queue_redraw()

func _draw() -> void:
	var ch := TrapBiomeArt.get_chapter(self)
	TrapBiomeArt.draw_laser_hazard(self, beam_length, is_vertical, is_active, pulse_phase, _charge_ratio, ch)

func _on_body_entered(body: Node2D) -> void:
	if is_active and (body is PlayerController or body.is_in_group("player")):
		if "is_dead" in body and body.is_dead:
			return
		if "is_invulnerable" in body and body.is_invulnerable:
			return
		if body.has_method("kill"):
			body.kill()

func reset_trap() -> void:
	timer = 0.0
	is_active = true
	_charge_ratio = 0.0
	_mote_accum = 0.0
	if col_shape:
		col_shape.disabled = false
	queue_redraw()

