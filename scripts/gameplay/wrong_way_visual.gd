extends Node2D

# Wrong Way — Original Character Visual
# Minimalist rounded cube character with animated expressive eyes.
# No red arrow or horns — clean, charming original aesthetic.

@export var body_color: Color = Color(0.12, 0.11, 0.15, 1.0)
@export var border_color: Color = Color(0.24, 0.22, 0.28, 1.0)
@export var eye_color: Color = Color(0.96, 0.95, 0.98, 1.0)
@export var pupil_color: Color = Color(0.08, 0.07, 0.1, 1.0)

var look_vector: Vector2 = Vector2.ZERO
var is_grounded: bool = true
var is_dead_expr: bool = false

var blink_timer: float = 0.0
var is_blinking: bool = false

func _ready() -> void:
	blink_timer = randf_range(2.0, 4.0)

func _process(delta: float) -> void:
	blink_timer -= delta
	if blink_timer <= 0.0:
		is_blinking = not is_blinking
		blink_timer = 0.12 if is_blinking else randf_range(2.5, 5.0)
		queue_redraw()

func update_visuals(look_dir: Vector2, grounded: bool, dead: bool, _facing: float = 1.0) -> void:
	look_vector = look_vector.lerp(look_dir, 0.25)
	is_grounded = grounded
	is_dead_expr = dead
	queue_redraw()

func _draw() -> void:
	var w = 28.0
	var h = 32.0
	var rect = Rect2(-w / 2.0, -h / 2.0, w, h)
	
	# Clean rounded chassis body
	draw_rect(rect, body_color, true)
	draw_rect(rect, border_color, false, 1.5)
	
	# Expressive eyes
	var eye_y = -h / 2.0 + 13.0
	if is_dead_expr:
		_draw_cross(Vector2(-6.0, eye_y))
		_draw_cross(Vector2(6.0, eye_y))
	elif is_blinking:
		draw_line(Vector2(-9.0, eye_y), Vector2(-3.0, eye_y), eye_color, 2.0)
		draw_line(Vector2(3.0, eye_y), Vector2(9.0, eye_y), eye_color, 2.0)
	else:
		var eye_h = 6.0 if is_grounded else 7.5
		draw_circle(Vector2(-6.0, eye_y), 4.2, eye_color)
		draw_circle(Vector2(6.0, eye_y), 4.2, eye_color)
		
		# Directional pupil tracker
		var pupil_offset = look_vector * 2.0
		pupil_offset.x = clampf(pupil_offset.x, -2.0, 2.0)
		pupil_offset.y = clampf(pupil_offset.y, -1.8, 1.8)
		draw_circle(Vector2(-6.0, eye_y) + pupil_offset, 2.0, pupil_color)
		draw_circle(Vector2(6.0, eye_y) + pupil_offset, 2.0, pupil_color)

func _draw_cross(pos: Vector2) -> void:
	var s = 3.0
	draw_line(pos + Vector2(-s, -s), pos + Vector2(s, s), eye_color, 2.0)
	draw_line(pos + Vector2(-s, s), pos + Vector2(s, -s), eye_color, 2.0)
