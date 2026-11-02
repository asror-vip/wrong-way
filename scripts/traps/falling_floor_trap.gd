extends TrapBase
class_name FallingFloorTrap

# Wrong Way — Falling Floor Trap
# Implements TrapBase lifecycle.
# Camouflaged seamlessly with normal ground platforms.
# Drops unexpectedly when a runner steps onto it or leaps across.

@export var platform_width: float = 160.0
@export var platform_height: float = 240.0
@export var platform_color: Color = Color(0.14, 0.13, 0.15, 1.0)
@export var jump_detect_x: float = 425.0

var initial_pos: Vector2 = Vector2.ZERO
var fall_velocity: float = 0.0

@onready var anim_body: AnimatableBody2D = $AnimBody
@onready var collision_shape: CollisionShape2D = $AnimBody/CollisionShape2D
@onready var visuals: Node2D = $AnimBody/Visuals

var player_ref: Node2D = null

func _setup_trap() -> void:
	trap_id = "trap_falling_floor"
	initial_pos = position
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect = collision_shape.shape.duplicate()
		rect.size = Vector2(platform_width, platform_height)
		collision_shape.shape = rect
		collision_shape.position = Vector2(0, platform_height / 2.0)
	
	if visuals:
		visuals.queue_redraw()

func _physics_process(delta: float) -> void:
	if current_state == State.IDLE:
		_check_player_triggers()
	elif current_state == State.ARMED:
		_shake_visuals()
	elif current_state == State.ACTIVE:
		_fall_down(delta)

func _check_player_triggers() -> void:
	if player_ref == null:
		player_ref = get_tree().get_first_node_in_group("player") as Node2D
	
	if player_ref and is_instance_valid(player_ref):
		if "is_dead" in player_ref and player_ref.is_dead:
			return
		
		var px = player_ref.global_position.x
		var py = player_ref.global_position.y
		var my_left = global_position.x - platform_width / 2.0
		var my_right = global_position.x + platform_width / 2.0
		
		# Trigger when runner steps near or jumps onto/over the trap segment
		if px >= my_left - 15.0 and px <= my_right:
			if py >= global_position.y - 120.0 and py <= global_position.y + 120.0:
				trigger_trap()

func _on_trap_armed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_trap"):
		sm.play_trap()

func _shake_visuals() -> void:
	if visuals:
		visuals.position.x = randf_range(-2.5, 2.5)
		visuals.position.y = randf_range(-1.5, 1.5)

func _on_trap_activated() -> void:
	if visuals:
		visuals.position = Vector2.ZERO

func _fall_down(delta: float) -> void:
	var grav = config.speed if config else 3800.0
	fall_velocity += grav * delta
	position.y += fall_velocity * delta
	if position.y > initial_pos.y + 600.0:
		set_physics_process(false)

func _on_trap_reset() -> void:
	set_physics_process(true)
	position = initial_pos
	fall_velocity = 0.0
	current_state = State.IDLE
	if visuals:
		visuals.position = Vector2.ZERO
