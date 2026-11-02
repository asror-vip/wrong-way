extends Area2D
class_name SpringTrap

@export var spring_size: Vector2 = Vector2(32, 32)
@export var launch_velocity: float = -950.0

@onready var col_shape: CollisionShape2D = $CollisionShape2D

var is_springing: bool = false
var compression: float = 1.0

func _ready() -> void:
	add_to_group("traps")
	if col_shape:
		col_shape.shape = RectangleShape2D.new()
		col_shape.shape.size = spring_size
		col_shape.position = spring_size / 2.0
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _draw() -> void:
	var is_winter := false
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("is_winter_theme"):
		is_winter = gm.is_winter_theme()

	var w := spring_size.x
	var h := spring_size.y * compression
	var y_top := spring_size.y - h
	
	# Poydevor (32x4)
	draw_rect(Rect2(0, spring_size.y - 4, w, 4), Color("#1e1b24"), true)
	if is_winter:
		draw_rect(Rect2(0, spring_size.y - 4, w, 2.0), Color("#ffffff"), true)
	else:
		draw_rect(Rect2(0, spring_size.y - 4, w, 1.5), Color("#475569"), true)
	
	# Prujina spiral halqalari
	var coils := 4
	var coil_h := (h - 8.0) / float(coils)
	for i in range(coils):
		var cy := spring_size.y - 4.0 - float(i) * coil_h - coil_h / 2.0
		draw_line(Vector2(5, cy), Vector2(w - 5, cy - coil_h * 0.45), Color("#94a3b8"), 2.5)
		draw_line(Vector2(w - 5, cy - coil_h * 0.45), Vector2(5, cy - coil_h * 0.9), Color("#64748b"), 2.5)
		
	# Yuqori sakrash yostig'i (Top pad)
	if is_winter:
		draw_rect(Rect2(2, y_top, w - 4, 7), Color("#38bdf8"), true)
		draw_rect(Rect2(4, y_top + 1, w - 8, 2), Color("#e0f2fe"), true)
	else:
		draw_rect(Rect2(2, y_top, w - 4, 7), Color("#f59e0b"), true)
		draw_rect(Rect2(4, y_top + 1, w - 8, 2), Color("#fef08a"), true)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController or body.is_in_group("player"):
		_trigger_launch(body)

func _trigger_launch(body: Node2D) -> void:
	if is_springing:
		return
	is_springing = true
	SoundManager.play("jump")
	
	if "velocity" in body:
		body.velocity.y = launch_velocity
	if body.has_method("apply_impulse"):
		body.apply_impulse(Vector2(0, launch_velocity))
		
	# Siqilish va sakrash animatsiyasi
	var tw := create_tween()
	tw.tween_property(self, "compression", 0.45, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "compression", 1.25, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "compression", 1.0, 0.15)
	await tw.finished
	is_springing = false

func _process(_delta: float) -> void:
	if is_springing:
		queue_redraw()

func reset_trap() -> void:
	is_springing = false
	compression = 1.0
	queue_redraw()
