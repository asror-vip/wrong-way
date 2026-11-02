extends Area2D

# Wrong Way — Pop-up Spike Trap
# Stays hidden underground and snaps upward when player approaches!

@export var trigger_distance_x: float = 140.0
@export var pop_speed: float = 800.0
@export var pop_height: float = 26.0

var initial_y: float = 0.0
var target_y: float = 0.0
var is_popped: bool = false
var is_triggered: bool = false

var player_ref: Node2D = null

@onready var visuals: Node2D = $Visuals
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("traps")
	body_entered.connect(_on_body_entered)
	initial_y = position.y
	target_y = initial_y - pop_height
	position.y = initial_y

func reset_trap() -> void:
	position.y = initial_y
	is_popped = false
	is_triggered = false

func _physics_process(delta: float) -> void:
	if not is_triggered:
		if player_ref == null:
			player_ref = get_tree().get_first_node_in_group("player") as Node2D
		
		if player_ref and is_instance_valid(player_ref):
			if "is_dead" in player_ref and player_ref.is_dead:
				return
			var dx = absf(global_position.x - player_ref.global_position.x)
			if dx < trigger_distance_x:
				trigger_pop()

	if is_triggered and not is_popped:
		position.y = move_toward(position.y, target_y, pop_speed * delta)
		if is_equal_approx(position.y, target_y):
			is_popped = true

func trigger_pop() -> void:
	if is_triggered:
		return
	is_triggered = true
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_trap"):
		sm.play_trap()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("die"):
		body.die()
