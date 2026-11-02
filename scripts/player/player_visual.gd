extends Node2D

@onready var controller: CharacterBody2D = get_parent()

func _draw() -> void:
	var w: float = 28.0
	var h: float = 32.0
	var rect := Rect2(-w / 2.0, -h, w, h)
	
	# Chassis (tana)
	draw_rect(rect, Color("#1c1a20"), true)
	draw_rect(rect, Color("#342f3a"), false, 1.5)
	
	# Ko'zlar
	var eye_y := -h * 0.52
	var eye_radius := Vector2(4.2, 5.2)
	var left_eye_center := Vector2(-6.0, eye_y)
	var right_eye_center := Vector2(6.0, eye_y)
	
	# Oq qism
	_draw_ellipse(left_eye_center, eye_radius, Color.WHITE)
	_draw_ellipse(right_eye_center, eye_radius, Color.WHITE)
	
	# Qorachiq
	var facing_dir := 1
	if controller and "facing" in controller:
		facing_dir = controller.facing
	var shift := float(facing_dir) * 1.8
	draw_circle(left_eye_center + Vector2(shift, 0.0), 2.0, Color("#111014"))
	draw_circle(right_eye_center + Vector2(shift, 0.0), 2.0, Color("#111014"))

func _draw_ellipse(center: Vector2, r: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var segs := 16
	for i in range(segs):
		var th := float(i) * 2.0 * PI / float(segs)
		points.append(center + Vector2(cos(th) * r.x, sin(th) * r.y))
	draw_colored_polygon(points, color)

