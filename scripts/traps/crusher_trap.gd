extends TrapBase
class_name CrusherTrap

# Wrong Way — Crusher Trap
# Heavy overhead obstacle camouflaged seamlessly in the ceiling.
# Slams directly into the floor foundation, crushing runners underneath,
# and becomes a solid obstacle platform once grounded.

@export var block_size: Vector2 = Vector2(100.0, 60.0)
@export var drop_distance: float = 380.0
@export var ground_y: float = 460.0
@export var trigger_distance_x: float = 130.0
@export var drop_speed: float = 1500.0

var initial_pos: Vector2 = Vector2.ZERO
var target_pos_y: float = 0.0
var has_impacted: bool = false
var player_ref: Node2D = null

@onready var anim_body: AnimatableBody2D = $AnimBody
@onready var body_collision: CollisionShape2D = $AnimBody/CollisionShape2D
@onready var kill_area: Area2D = $AnimBody/KillArea
@onready var kill_collision: CollisionShape2D = $AnimBody/KillArea/CollisionShape2D
@onready var visuals: Node2D = $AnimBody/Visuals

func _setup_trap() -> void:
	trap_id = "trap_crusher"
	initial_pos = position
	
	if drop_distance > 0.0:
		target_pos_y = initial_pos.y + drop_distance
	else:
		target_pos_y = ground_y - block_size.y
		drop_distance = target_pos_y - initial_pos.y
	
	has_impacted = false
	
	# Synchronize physical collision box with block_size
	if body_collision:
		var rect = RectangleShape2D.new()
		rect.size = block_size
		body_collision.shape = rect
		body_collision.position = Vector2(0, block_size.y / 2.0)
	
	# Synchronize lethal bottom edge
	if kill_collision:
		var kill_rect = RectangleShape2D.new()
		kill_rect.size = Vector2(maxf(block_size.x - 4.0, 10.0), 18.0)
		kill_collision.shape = kill_rect
		kill_collision.position = Vector2(0, block_size.y - 9.0)
	
	if kill_area:
		if not kill_area.body_entered.is_connected(_on_kill_entered):
			kill_area.body_entered.connect(_on_kill_entered)
	
	if visuals:
		visuals.queue_redraw()

func _physics_process(delta: float) -> void:
	if current_state == State.IDLE:
		_check_runner_proximity()
	elif current_state == State.ARMED:
		_shake_warning()
	elif current_state == State.ACTIVE:
		_perform_drop(delta)

func _check_runner_proximity() -> void:
	if player_ref == null:
		player_ref = get_tree().get_first_node_in_group("player") as Node2D
	
	if player_ref and is_instance_valid(player_ref):
		if "is_dead" in player_ref and player_ref.is_dead:
			return
		
		var px = player_ref.global_position.x
		var dx = global_position.x - px
		# Trigger when runner approaches from the left within trigger range
		if dx > 0 and dx < trigger_distance_x:
			trigger_trap()

func _on_trap_armed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_trap"):
		sm.play_trap()

func _shake_warning() -> void:
	if visuals:
		visuals.position.x = randf_range(-3.0, 3.0)
		visuals.position.y = randf_range(-1.0, 1.0)

func _on_trap_activated() -> void:
	if visuals:
		visuals.position = Vector2.ZERO

func _perform_drop(delta: float) -> void:
	position.y = move_toward(position.y, target_pos_y, drop_speed * delta)
	if is_equal_approx(position.y, target_pos_y):
		position.y = target_pos_y
		if not has_impacted:
			has_impacted = true
			var sm = get_node_or_null("/root/SoundManager")
			if sm and sm.has_method("play_land"):
				sm.play_land()
			var p = get_parent()
			if p and p.has_method("trigger_shake"):
				p.trigger_shake(8.0)

func _on_kill_entered(body: Node2D) -> void:
	# Lethal while in downward flight before resting on the ground
	if current_state == State.ACTIVE and not has_impacted:
		if body.is_in_group("player") and body.has_method("die"):
			body.die()

func _on_trap_reset() -> void:
	set_physics_process(true)
	has_impacted = false
	current_state = State.IDLE
	position = initial_pos
	if visuals:
		visuals.position = Vector2.ZERO
