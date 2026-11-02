extends CharacterBody2D
class_name PlayerController

signal died
signal respawned
signal entered_exit

const SPEED: float = 320.0
const JUMP_VELOCITY: float = -560.0
const GRAVITY: float = 1450.0
const MAX_SHORT_JUMP_FALL: float = -280.0

var coyote_timer: float = 0.0
var jump_buffer: float = 0.0
var facing: int = 1
var is_dead: bool = false
var is_entering_door: bool = false
var spawn_position: Vector2
var controls_inverted: bool = false
var is_invulnerable: bool = false
var invulnerable_timer: float = 0.0

@onready var visual: Node2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position

func _physics_process(delta: float) -> void:
	if is_dead or is_entering_door:
		return

	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
		if invulnerable_timer <= 0.0:
			is_invulnerable = false

	# Coyote Time & Jump Buffer
	if is_on_floor():
		coyote_timer = 0.16
	else:
		coyote_timer -= delta

	if jump_buffer > 0.0:
		jump_buffer -= delta

	# Gorizontal harakat
	var move_dir := Input.get_axis("move_left", "move_right")
	if controls_inverted:
		move_dir = -move_dir
	if move_dir != 0:
		facing = signi(int(move_dir))
		velocity.x = move_dir * SPEED
	else:
		velocity.x = 0.0

	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.16

	# Sakrash
	if jump_buffer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0
		jump_buffer = 0.0
		if visual:
			visual.scale = Vector2(0.75, 1.35)
		SoundManager.play("jump")

	# Sakrash tugmasi erta qo'yib yuborilganda pastga tortish
	if Input.is_action_just_released("jump") and velocity.y < MAX_SHORT_JUMP_FALL:
		velocity.y = MAX_SHORT_JUMP_FALL

	# Gravitatsiya va shaklni asl holatiga qaytarish (lerp)
	velocity.y += GRAVITY * delta
	if visual:
		visual.scale = visual.scale.lerp(Vector2.ONE, delta * 10.0)

	move_and_slide()
	if visual:
		visual.queue_redraw()

	# Original: player.y > H + 50 (540 + 50 = 590)
	if global_position.y > 590.0:
		kill()

func kill() -> void:
	if is_dead or is_entering_door or is_invulnerable:
		return
	is_dead = true
	velocity = Vector2.ZERO
	SoundManager.play("die")
	GameManager.record_death()
	died.emit()
	
	visible = false
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	_spawn_particles()
	
	# O'lik gavdani xaritadagi tuzoqlar zonasidan chetga olamiz
	global_position = Vector2(-9999, -9999)
	
	# Original: setTimeout(() => resetPlayer(), 340)
	await get_tree().create_timer(0.34).timeout
	if is_instance_valid(self):
		respawn()

func die() -> void:
	kill()

func respawn(at_position: Vector2 = spawn_position) -> void:
	global_position = at_position
	velocity = Vector2.ZERO
	is_dead = false
	is_entering_door = false
	controls_inverted = false
	is_invulnerable = true
	invulnerable_timer = 0.22 # 220ms spawn protection (takroriy o'limni oldini oladi)
	coyote_timer = 0.0
	jump_buffer = 0.0
	visible = true
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if visual:
		visual.scale = Vector2.ONE
	respawned.emit()

func enter_door(target_pos: Vector2) -> void:
	if is_entering_door or is_dead:
		return
	is_entering_door = true
	velocity = Vector2.ZERO
	entered_exit.emit()
	
	# Original animatsiya: o'lcham 0 ga qarab kichrayib markazga tortiladi
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", target_pos, 0.18)
	if visual:
		tween.tween_property(visual, "scale", Vector2.ZERO, 0.18)
	await tween.finished
	visible = false

func enter_finish(target_pos: Vector2) -> void:
	enter_door(target_pos)

func _spawn_particles() -> void:
	var p_scene: PackedScene = load("res://scenes/player/death_particles.tscn")
	if p_scene:
		var p: CPUParticles2D = p_scene.instantiate()
		p.global_position = global_position - Vector2(0, 16)
		get_parent().add_child(p)
