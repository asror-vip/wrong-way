extends Area2D
class_name SpringTrap

const TrapBiomeArt := preload("res://scripts/traps/trap_biome_art.gd")
const TrapBiomeVFX := preload("res://scripts/traps/trap_biome_vfx.gd")

@export var spring_size: Vector2 = Vector2(32, 32)
@export var launch_velocity: float = -950.0
@export var bounce_force: float = 0.0
@export var trigger_y_min: float = -9999.0
@export var trigger_y_max: float = 9999.0
@export var visible_when_idle: bool = false

@onready var col_shape: CollisionShape2D = $CollisionShape2D

var is_springing: bool = false
var tw: Tween
var extension: float = 0.0

func _ready() -> void:
	add_to_group("traps")
	if col_shape:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(maxf(spring_size.x - 4.0, 12.0), 22.0)
		col_shape.shape = rect
		# Pol yuzasidan tepaga joylashtiramiz (y in [-22, 0])
		col_shape.position = Vector2(spring_size.x / 2.0, -11.0)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _can_trigger_player(player: Node2D) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if "is_dead" in player and player.is_dead:
		return false
	if "is_invulnerable" in player and player.is_invulnerable:
		return false
	var px: float = player.global_position.x
	var py: float = player.global_position.y
	if py < trigger_y_min or py > trigger_y_max:
		return false
	var min_x: float = global_position.x - 2.0
	var max_x: float = global_position.x + spring_size.x + 2.0
	if px < min_x or px > max_x:
		return false
	var dy: float = py - global_position.y
	return dy >= -20.0 and dy <= 10.0

func _physics_process(_delta: float) -> void:
	if is_springing:
		queue_redraw()
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if _can_trigger_player(player):
		_trigger_launch(player)

func _draw() -> void:
	var draw_ext := extension
	if not is_springing or draw_ext <= 1.0:
		if not visible_when_idle:
			# Tinch holatda (idle) pol ichida hech qanday purjina ko'rinmasligi shart
			return
		draw_ext = 14.0
	elif visible_when_idle:
		draw_ext = maxf(draw_ext, 14.0)
	var ch := TrapBiomeArt.get_chapter(self)
	TrapBiomeArt.draw_spring_mechanism(self, spring_size.x, draw_ext, ch)

func _on_body_entered(body: Node2D) -> void:
	if (body is PlayerController or body.is_in_group("player")) and _can_trigger_player(body):
		_trigger_launch(body)

func _trigger_launch(body: Node2D) -> void:
	if is_springing:
		return
	is_springing = true
	extension = 0.0

	var ch := TrapBiomeArt.get_chapter(self)
	TrapBiomeVFX.emit_spring_burst(self, global_position + Vector2(spring_size.x * 0.5, 0.0), spring_size.x, ch)
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_biome_trap"):
		sm.play_biome_trap("spring", ch)
	elif sm and sm.has_method("play"):
		sm.play("jump")

	var target_vel: float = launch_velocity
	if bounce_force > 0.0 and (launch_velocity == -950.0 or launch_velocity == 0.0):
		target_vel = -absf(bounce_force) * 1.35
	elif launch_velocity == 0.0:
		target_vel = -850.0

	if "velocity" in body:
		body.velocity.y = target_vel
	if body.has_method("apply_impulse"):
		body.apply_impulse(Vector2(0, target_vel))
	if "coyote_timer" in body:
		body.coyote_timer = 0.0
	if "visual" in body and body.visual:
		body.visual.scale = Vector2(0.65, 1.45)

	if tw and tw.is_valid():
		tw.kill()
	tw = create_tween()
	tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	var max_ext := maxf(spring_size.y, 34.0)
	tw.tween_property(self, "extension", max_ext, 0.08)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "extension", max_ext * 1.15, 0.06)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "extension", 0.0, 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tw.finished.connect(func():
		is_springing = false
		extension = 0.0
		queue_redraw()
	)
	queue_redraw()

func reset_trap() -> void:
	if tw and tw.is_valid():
		tw.kill()
	is_springing = false
	extension = 0.0
	queue_redraw()
