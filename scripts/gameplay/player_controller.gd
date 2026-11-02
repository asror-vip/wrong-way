extends CharacterBody2D
# Legacy redirect to scripts/player/player_controller.gd

# Wrong Way — Player Controller
# Authoritative gameplay controller for the runner.
# Config-driven physics without magic numbers, single-press jump buffering, and clean lifecycle signals.

signal jumped
signal landed
signal died
signal respawned
signal finish_entered(target_pos: Vector2)

@export var config: PlayerConfig = null
@export var is_menu_dummy: bool = false

var is_dead: bool = false
var is_finishing: bool = false
var was_on_floor: bool = false
var facing_dir: float = 1.0

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var spawn_position: Vector2 = Vector2.ZERO
var finish_tween: Tween = null

@onready var visual_root: Node2D = $Visuals
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("player")
	if config == null:
		config = preload("res://resources/player_config.tres")
	spawn_position = global_position
	was_on_floor = is_on_floor()

func respawn(at_position: Vector2 = spawn_position) -> void:
	if finish_tween and finish_tween.is_valid():
		finish_tween.kill()
	set_physics_process(true)
	global_position = at_position
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, at_position))
	velocity = Vector2.ZERO
	is_dead = false
	is_finishing = false
	visible = true
	modulate.a = 1.0
	collision_shape.set_deferred("disabled", false)
	if visual_root:
		visual_root.scale = Vector2.ONE
		visual_root.rotation = 0.0
	respawned.emit()

func _physics_process(delta: float) -> void:
	if is_menu_dummy:
		# Menu actor: apply gravity if needed, but ignore user gameplay inputs
		if not is_on_floor():
			velocity.y += (config.gravity if config else 1450.0) * delta
			move_and_slide()
		return

	if is_dead or is_finishing:
		return

	# Floor Tracking & Coyote Timer
	if is_on_floor():
		coyote_timer = config.coyote_time
		if not was_on_floor:
			if visual_root:
				visual_root.scale = Vector2(1.25, 0.75)
			var sm = get_node_or_null("/root/SoundManager")
			if sm and sm.has_method("play_land"):
				sm.play_land()
			landed.emit()
	else:
		coyote_timer -= delta

	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	# Read Input: Jump ONLY buffers on just_pressed, NEVER while held
	var jump_just_pressed := (
		Input.is_action_just_pressed("jump") or
		Input.is_key_pressed(KEY_UP) or
		Input.is_key_pressed(KEY_W) or
		Input.is_key_pressed(KEY_SPACE)
	)
	# Use standard action check as authoritative
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = config.jump_buffer_time

	# Horizontal movement inputs
	var move_input := 0.0
	if Input.is_action_pressed("move_left"):
		move_input -= 1.0
	if Input.is_action_pressed("move_right"):
		move_input += 1.0

	# Jump Execution: Consume jump buffer so holding button NEVER auto-jumps
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = config.jump_velocity
		coyote_timer = 0.0
		jump_buffer_timer = 0.0 # Buffer consumed!
		if visual_root:
			visual_root.scale = Vector2(0.75, 1.35)
		var sm = get_node_or_null("/root/SoundManager")
		if sm and sm.has_method("play_jump"):
			sm.play_jump()
		jumped.emit()

	# Variable Jump Height: Cut upward velocity when jump button is released early
	var jump_held = Input.is_action_pressed("jump")
	if not jump_held and velocity.y < config.min_jump_velocity:
		velocity.y = config.min_jump_velocity

	# Horizontal Acceleration & Deceleration
	if move_input != 0.0:
		facing_dir = signf(move_input)
		velocity.x = move_toward(velocity.x, move_input * config.speed, config.acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, config.friction * delta)

	# Gravity
	if not is_on_floor():
		velocity.y += config.gravity * delta

	was_on_floor = is_on_floor()

	move_and_slide()

	# Void death check
	if global_position.y > config.death_plane_y:
		die()

func _unhandled_input(event: InputEvent) -> void:
	if is_menu_dummy or is_dead or is_finishing:
		return
	# Ensure single press buffer registration
	if event.is_action_pressed("jump") and not event.is_echo():
		jump_buffer_timer = config.jump_buffer_time

func _process(delta: float) -> void:
	if is_finishing:
		return
	if visual_root:
		visual_root.scale = visual_root.scale.lerp(Vector2.ONE, delta * 12.0)
		var visual_node = visual_root.get_node_or_null("WrongWayVisual")
		if visual_node and visual_node.has_method("update_visuals"):
			var look_dir = Vector2(velocity.x / config.speed, clampf(velocity.y / 600.0, -1.0, 1.0))
			visual_node.update_visuals(look_dir, is_on_floor(), is_dead, facing_dir)

func die() -> void:
	if is_dead or is_finishing:
		return
	is_dead = true
	velocity = Vector2.ZERO
	visible = false
	collision_shape.set_deferred("disabled", true)
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_die"):
		sm.play_die()
	
	_spawn_death_burst()
	died.emit()
	
	await get_tree().create_timer(config.respawn_delay).timeout
	if is_instance_valid(self):
		respawn()

func enter_finish(target_pos: Vector2) -> void:
	if is_finishing or is_dead:
		return
	is_finishing = true
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
	
	finish_entered.emit(target_pos)
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_win"):
		sm.play_win()
	
	# Smoothly glide player into the portal doorway and vanish cleanly
	finish_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	finish_tween.tween_property(self, "global_position:x", target_pos.x, 0.20)
	finish_tween.tween_property(self, "global_position:y", target_pos.y + 4.0, 0.20)
	if visual_root:
		finish_tween.tween_property(visual_root, "scale", Vector2(0.1, 0.8), 0.20)
	finish_tween.tween_property(self, "modulate:a", 0.0, 0.20)
	
	await finish_tween.finished
	visible = false

func _spawn_death_burst() -> void:
	var particles_scene = load("res://scenes/gameplay/death_particles.tscn")
	if particles_scene == null:
		particles_scene = load("res://scenes/death_particles.tscn")
	if particles_scene:
		var p = particles_scene.instantiate()
		p.global_position = global_position
		get_parent().add_child(p)
