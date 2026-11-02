extends Area2D
class_name FakeDoorTrap

@export var door_size: Vector2 = Vector2(32, 64)
@export var run_away_distance: float = 90.0

var start_pos: Vector2
var is_triggered: bool = false
var pulse_time: float = 0.0

@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("traps")
	start_pos = global_position
	if col_shape:
		col_shape.shape = RectangleShape2D.new()
		col_shape.shape.size = door_size
		col_shape.position = Vector2(0, -door_size.y / 2.0)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()
	
	if not is_triggered:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and is_instance_valid(player):
			if "is_dead" in player and player.is_dead:
				return
			var dist := global_position.distance_to(player.global_position)
			if dist < run_away_distance:
				_run_away(player)

func _run_away(player: Node2D) -> void:
	is_triggered = true
	SoundManager.play("trap")
	
	# O'yinchidan qarama-qarshi tomonga qochib ketish
	var dir_x := 1.0 if global_position.x > player.global_position.x else -1.0
	var target_x := global_position.x + dir_x * 120.0
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "global_position:x", target_x, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", deg_to_rad(dir_x * 15.0), 0.2)
	tween.chain().tween_property(self, "rotation", 0.0, 0.15)

func _draw() -> void:
	var w := door_size.x
	var h := door_size.y
	
	# Poydevor (32px to'rga to'liq tekis mos)
	draw_rect(Rect2(-w / 2.0, -3.0, w, 3.0), Color("#262230"), true)
	draw_rect(Rect2(-w / 2.0, -3.0, w, 1.2), Color("#c084fc"), true)
	
	# Arka ramka
	var r := w / 2.0
	var cy := -(h - r)
	var pts := PackedVector2Array([
		Vector2(r, 0.0),
		Vector2(r, cy),
		Vector2(0, -h),
		Vector2(-r, cy),
		Vector2(-r, 0.0)
	])
	draw_colored_polygon(pts, Color("#181520"))
	# Soxta qizil-binafsha hoshiya
	draw_polyline(pts, Color("#c084fc"), 2.0)
	
	# Ichki portal
	var iw := w - 10.0
	var ih := h - 8.0
	var ir := iw / 2.0
	var icy := -(ih - ir)
	var inner_pts := PackedVector2Array([
		Vector2(ir, 0.0),
		Vector2(ir, icy),
		Vector2(0, -ih),
		Vector2(-ir, icy),
		Vector2(-ir, 0.0)
	])
	draw_colored_polygon(inner_pts, Color("#1e112a"))
	
	# Qizil shaytonona ko'zlar (tuzoq ekanligini sekin fosh qiluvchi)
	var eye_alpha := 0.4 + sin(pulse_time * 4.0) * 0.3
	draw_circle(Vector2(-6, icy), 2.5, Color(0.9, 0.2, 0.2, eye_alpha))
	draw_circle(Vector2(6, icy), 2.5, Color(0.9, 0.2, 0.2, eye_alpha))

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController or body.is_in_group("player"):
		if body.has_method("kill"):
			body.kill()

func reset_trap() -> void:
	global_position = start_pos
	rotation = 0.0
	is_triggered = false

