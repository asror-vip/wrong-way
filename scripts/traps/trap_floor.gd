extends StaticBody2D
class_name TrapFloor

@export var platform_size: Vector2 = Vector2(140, 160)

var initial_position: Vector2
var is_triggered: bool = false
var is_falling: bool = false
var fall_speed: float = 0.0
var shake_timer: float = 0.0

@onready var visual: Node2D = $Visual
@onready var trigger_area: Area2D = $TriggerArea
@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("traps")
	initial_position = global_position
	# Pastdagi tuzoq polini ham ekranning eng pastigacha uzaytiramiz
	if position.y >= 360.0 and (position.y + platform_size.y) < 540.0:
		platform_size.y = 540.0 - position.y
	if col_shape:
		col_shape.shape = RectangleShape2D.new()
		col_shape.shape.size = platform_size
		col_shape.position = platform_size / 2.0
	if trigger_area:
		trigger_area.body_entered.connect(_on_trigger_body_entered)
	elif has_node("AreaTrigger"):
		$AreaTrigger.body_entered.connect(_on_trigger_body_entered)


func _physics_process(delta: float) -> void:
	if is_triggered and not is_falling:
		shake_timer -= delta
		if visual:
			visual.position.x = randf_range(-2.0, 2.0)
		if shake_timer <= 0.0:
			if visual:
				visual.position.x = 0.0
			is_falling = true

	if is_falling:
		# Original: fallSpeed += 3200 * dt
		fall_speed += 3200.0 * delta
		global_position.y += fall_speed * delta

func _on_trigger_body_entered(body: Node2D) -> void:
	if (body is PlayerController or body.is_in_group("player")) and not is_triggered:
		if "is_dead" in body and body.is_dead:
			return
		if "is_invulnerable" in body and body.is_invulnerable:
			return
		is_triggered = true
		shake_timer = 0.4 # GPT timing rule: 0.4s
		var sm = get_node_or_null("/root/SoundManager")
		if sm and sm.has_method("play"):
			sm.play("trap")

func reset_trap() -> void:
	is_triggered = false
	is_falling = false
	fall_speed = 0.0
	shake_timer = 0.0
	global_position = initial_position
	if visual:
		visual.position = Vector2.ZERO
