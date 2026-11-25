extends Area2D
class_name MovingSawTrap

const TrapBiomeArt := preload("res://scripts/traps/trap_biome_art.gd")
const TrapBiomeVFX := preload("res://scripts/traps/trap_biome_vfx.gd")

@export var radius: float = 16.0 # 32px diametr
@export var patrol_distance: float = 64.0 # 2x katak
@export var patrol_speed: float = 120.0
@export var patrol_axis: Vector2 = Vector2.RIGHT
@export var trigger_distance: float = 0.0 # Agar > 0 bo'lsa, o'yinchi yaqinlashganda otilib chiqadi
@export var one_shot_boomerang: bool = false
@export var trigger_y_min: float = -9999.0
@export var trigger_y_max: float = 9999.0
@export var max_trigger_dy: float = 95.0

var start_pos: Vector2
var patrol_t: float = 0.0
var rotation_angle: float = 0.0
var moving_forward: bool = true
var is_triggered: bool = false
var boomerang_done: bool = false
var pause_timer: float = 0.0
var pop_tween: Tween = null
var _anim_time: float = 0.0
var _spark_accum: float = 0.0

@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("traps")
	start_pos = global_position
	if col_shape:
		var circle := CircleShape2D.new()
		circle.radius = radius - 1.0
		col_shape.shape = circle
		col_shape.position = Vector2.ZERO
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if trigger_distance > 0.0 and not is_triggered:
		if col_shape and not col_shape.disabled:
			col_shape.disabled = true
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and is_instance_valid(player):
			if "is_dead" in player and player.is_dead:
				return
			var py: float = player.global_position.y
			if py < trigger_y_min or py > trigger_y_max:
				return
			if trigger_y_min <= -9000.0 and trigger_y_max >= 9000.0:
				if absf(py - global_position.y) > max_trigger_dy:
					return
			var dx: float = player.global_position.x - global_position.x
			var should_trigger: bool = false
			# Agar arra o'ngga (orqadan quvuvchi) bo'lsa (patrol_axis.x > 0):
			# O'yinchi yetarlicha oldinga (dx >= trigger_distance) o'tganda orqadan chiqadi
			if patrol_axis.x > 0.1:
				if dx >= trigger_distance:
					should_trigger = true
			# Agar arra chapga (oldindan keluvchi) bo'lsa (patrol_axis.x < -0.1):
			# O'yinchi unga yetarlicha yaqinlashganda oldindan chiqadi
			elif patrol_axis.x < -0.1:
				if dx <= 0.0 and absf(dx) <= trigger_distance:
					should_trigger = true
			else:
				var dist: float = absf(dx)
				if dist < trigger_distance:
					should_trigger = true

			if should_trigger:
				is_triggered = true
				if col_shape:
					col_shape.disabled = false
				if pop_tween and pop_tween.is_valid():
					pop_tween.kill()
				scale = Vector2(0.2, 0.2)
				pop_tween = create_tween()
				pop_tween.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				var ch_trig := TrapBiomeArt.get_chapter(self)
				TrapBiomeVFX.emit_saw_spark(self, global_position, radius, ch_trig, true)
				var sm = get_node_or_null("/root/SoundManager")
				if sm and sm.has_method("play_biome_trap"):
					sm.play_biome_trap("trigger", ch_trig)
				elif sm and sm.has_method("play"):
					sm.play("trap")
		return

	if col_shape and col_shape.disabled:
		col_shape.disabled = false

	_anim_time += delta
	rotation_angle += delta * (4.0 if boomerang_done else 14.0)
	if not boomerang_done:
		_spark_accum += delta
		var spark_step := 0.28 if OS.has_feature("mobile") else 0.16
		if _spark_accum >= spark_step:
			_spark_accum = 0.0
			TrapBiomeVFX.emit_saw_spark(self, global_position, radius, TrapBiomeArt.get_chapter(self), false)
	
	if patrol_distance > 0.0 and not boomerang_done:
		if pause_timer > 0.0:
			pause_timer -= delta
		else:
			if moving_forward:
				patrol_t += (patrol_speed * delta) / patrol_distance
				if patrol_t >= 1.0:
					patrol_t = 1.0
					moving_forward = false
					if one_shot_boomerang:
						pause_timer = 0.08
			else:
				var ret_speed := patrol_speed * 1.25 if one_shot_boomerang else patrol_speed
				patrol_t -= (ret_speed * delta) / patrol_distance
				if patrol_t <= 0.0:
					patrol_t = 0.0
					if one_shot_boomerang:
						boomerang_done = true
					else:
						moving_forward = true
		global_position = start_pos + patrol_axis.normalized() * (patrol_distance * patrol_t)
		
	queue_redraw()

func reset_trap() -> void:
	if pop_tween and pop_tween.is_valid():
		pop_tween.kill()
	is_triggered = false
	boomerang_done = false
	pause_timer = 0.0
	_spark_accum = 0.0
	patrol_t = 0.0
	moving_forward = true
	scale = Vector2.ONE
	global_position = start_pos
	if trigger_distance > 0.0 and col_shape:
		col_shape.disabled = true
	queue_redraw()

func _draw() -> void:
	if trigger_distance > 0.0 and not is_triggered:
		return
	var ch := TrapBiomeArt.get_chapter(self)
	TrapBiomeArt.draw_saw_blade(self, Vector2.ZERO, radius, rotation_angle, ch, _anim_time)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController or body.is_in_group("player"):
		if "is_dead" in body and body.is_dead:
			return
		if "is_invulnerable" in body and body.is_invulnerable:
			return
		if body.has_method("kill"):
			body.kill()
