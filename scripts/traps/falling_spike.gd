extends Area2D
class_name FallingSpikeTrap

@export var trigger_distance: float = 300.0
@export var fall_speed: float = 650.0
@export var shake_duration: float = 0.6

var is_triggered: bool = false
var is_falling: bool = false
var velocity_y: float = 0.0
var shake_timer: float = 0.0
var original_pos: Vector2

@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("traps")
	original_pos = global_position
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not is_triggered:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and is_instance_valid(player):
			if "is_dead" in player and player.is_dead:
				return
			if "is_invulnerable" in player and player.is_invulnerable:
				return
			var dx: float = abs(player.global_position.x - global_position.x)
			var dy: float = player.global_position.y - global_position.y
			if dx < 32.0 and dy > 0.0 and dy < trigger_distance:
				_trigger()
	elif not is_falling:
		shake_timer -= delta
		global_position.x = original_pos.x + randf_range(-2.0, 2.0)
		if shake_timer <= 0.0:
			global_position.x = original_pos.x
			is_falling = true
	else:
		velocity_y += 1800.0 * delta
		global_position.y += velocity_y * delta
		
		# Pastga tushib ekrandan chiqsa yoki qattiq polga ursa
		if global_position.y > 600.0:
			is_falling = false
			visible = false
			if col_shape:
				col_shape.set_deferred("disabled", true)

func _trigger() -> void:
	is_triggered = true
	shake_timer = shake_duration
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play"):
		sm.play("trap")

func _draw() -> void:
	var is_winter := false
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("is_winter_theme"):
		is_winter = gm.is_winter_theme()

	var pts := PackedVector2Array([
		Vector2(-16, 0),
		Vector2(16, 0),
		Vector2(0, 32)
	])

	if is_winter:
		# Muz osilmasi (Falling icicle)
		draw_colored_polygon(pts, Color(0.22, 0.74, 0.97, 0.92))
		# Tepasidagi qor qatlami
		draw_line(Vector2(-16, 1), Vector2(16, 1), Color("#ffffff"), 3.0)
		# Kristall yaltirash
		var inner_pts := PackedVector2Array([
			Vector2(-7, 3),
			Vector2(7, 3),
			Vector2(0, 26)
		])
		draw_colored_polygon(inner_pts, Color("#e0f2fe"))
		draw_line(Vector2(-16, 0), Vector2(0, 32), Color("#ffffff"), 1.5)
		draw_line(Vector2(16, 0), Vector2(0, 32), Color("#0284c7"), 1.2)
	else:
		draw_colored_polygon(pts, Color("#e11d48"))
		var inner_pts := PackedVector2Array([
			Vector2(-8, 2),
			Vector2(8, 2),
			Vector2(0, 26)
		])
		draw_colored_polygon(inner_pts, Color("#fb7185"))
		draw_polyline(pts, Color("#881337"), 2.0)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController or body.is_in_group("player"):
		if "is_dead" in body and body.is_dead:
			return
		if "is_invulnerable" in body and body.is_invulnerable:
			return
		if body.has_method("kill"):
			body.kill()
	elif is_falling and body is StaticBody2D:
		SoundManager.play("trap")
		is_falling = false
		visible = false
		if col_shape:
			col_shape.set_deferred("disabled", true)

func reset_trap() -> void:
	global_position = original_pos
	is_triggered = false
	is_falling = false
	velocity_y = 0.0
	shake_timer = 0.0
	visible = true
	if col_shape:
		col_shape.set_deferred("disabled", false)
