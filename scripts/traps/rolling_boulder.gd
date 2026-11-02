extends CharacterBody2D
class_name RollingBoulder

# Wrong Way - Unexpected Event: Rolling Giant Boulder (Qoya Toshi)
# Iconic Limbo-style surprise: Triggers when the player walks past,
# rumbles with screen shake and rolls rapidly to chase or crush the player!

@export var boulder_radius: float = 28.0
@export var roll_speed: float = 380.0
@export var roll_direction: float = 1.0 # 1.0 = o'ngga, -1.0 = chapga
@export var trigger_distance: float = 260.0 # O'yinchi yaqinlashganda
@export var gravity: float = 1200.0

var is_triggered: bool = false
var original_pos: Vector2
var roll_rotation: float = 0.0

@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var kill_area: Area2D = $KillArea

func _ready() -> void:
	add_to_group("traps")
	original_pos = global_position
	
	if col_shape and col_shape.shape is CircleShape2D:
		col_shape.shape.radius = boulder_radius
		
	if kill_area:
		kill_area.body_entered.connect(_on_kill_entered)

func _physics_process(delta: float) -> void:
	if not is_triggered:
		_check_player_trigger()
		return
		
	# Gravitatsiya va aylanish
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
		# Harakatlanish paytida vaqti-vaqti bilan yengil silkinish
		if randf() < 0.1:
			GameManager.request_screen_shake.emit(3.0)
			
	velocity.x = roll_direction * roll_speed
	roll_rotation += roll_direction * (roll_speed / boulder_radius) * delta
	
	move_and_slide()
	queue_redraw()
	
	# Qoyaga tushib ketsa
	if global_position.y > 650.0:
		is_triggered = false
		velocity = Vector2.ZERO

func _check_player_trigger() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
		
	var dist: float = global_position.distance_to(player.global_position)
	if dist <= trigger_distance:
		trigger_boulder()

func trigger_boulder() -> void:
	if is_triggered:
		return
	is_triggered = true
	SoundManager.play("trap")
	GameManager.request_screen_shake.emit(12.0)
	
	# Boshlang'ich silkinish
	var tw := create_tween()
	tw.tween_property(self, "position:y", position.y - 4.0, 0.06)
	tw.tween_property(self, "position:y", position.y, 0.06)

func _on_kill_entered(body: Node2D) -> void:
	if is_triggered and (body is PlayerController or body.is_in_group("player")):
		if body.has_method("kill"):
			body.kill()
		elif body.has_method("die"):
			body.die()

func reset_trap() -> void:
	is_triggered = false
	global_position = original_pos
	velocity = Vector2.ZERO
	roll_rotation = 0.0
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, roll_rotation, Vector2.ONE)
	
	# 1. Asosiy obsidian qoya toshi tanasi
	draw_circle(Vector2.ZERO, boulder_radius, Color(0.08, 0.10, 0.15, 1.0))
	# Qoya xoshiyasi
	draw_arc(Vector2.ZERO, boulder_radius, -PI, PI, 32, Color(0.28, 0.36, 0.48, 0.85), 2.0)
	
	# 2. Ichki tosh qatlamlari va yoriqlari (Limbo silhouette rock cracks)
	draw_line(Vector2(-16, -10), Vector2(4, -4), Color(0.03, 0.04, 0.07, 0.95), 2.5)
	draw_line(Vector2(4, -4), Vector2(16, -14), Color(0.03, 0.04, 0.07, 0.95), 2.0)
	draw_line(Vector2(4, -4), Vector2(0, 15), Color(0.03, 0.04, 0.07, 0.95), 2.2)
	draw_line(Vector2(0, 15), Vector2(-12, 18), Color(0.03, 0.04, 0.07, 0.95), 1.8)
	
	# Nozik tosh yorug'lik aksi
	draw_arc(Vector2.ZERO, boulder_radius - 4.0, -PI * 0.7, -PI * 0.2, 16, Color(0.40, 0.50, 0.65, 0.40), 1.5)

