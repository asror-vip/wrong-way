extends Node2D

@export var color: Color = Color(0.14, 0.13, 0.15, 1.0)
@export var count: int = 1
@export var width: float = 30.0
@export var height: float = 24.0

func _draw() -> void:
	var total_w = width * count
	var start_x = -total_w / 2.0
	
	for i in range(count):
		var x1 = start_x + i * width
		var x2 = x1 + width / 2.0
		var x3 = x1 + width
		
		var tri = PackedVector2Array([
			Vector2(x1, 0),
			Vector2(x2, -height),
			Vector2(x3, 0)
		])
		draw_colored_polygon(tri, color)
		
		# Edge highlight
		draw_line(Vector2(x1, 0), Vector2(x2, -height), Color(0.24, 0.22, 0.26, 1.0), 1.2)
