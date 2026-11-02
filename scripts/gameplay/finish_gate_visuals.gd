extends Node2D

# Wrong Way — Finish Gate Visuals
# Sleek geometric portal with illuminated neon accents and status beacon.

@export var frame_color: Color = Color(0.12, 0.11, 0.15, 1.0)
@export var inside_color: Color = Color(0.18, 0.16, 0.22, 1.0)
@export var beacon_color: Color = Color(0.35, 0.95, 0.55, 1.0) # Active green beacon

func _draw() -> void:
	var w = 44.0
	var h = 64.0
	var half_w = w / 2.0
	
	# Outer frame
	var points = PackedVector2Array()
	points.append(Vector2(-half_w, h / 2.0))
	points.append(Vector2(-half_w, -h / 2.0 + half_w))
	var segments = 16
	for i in range(segments + 1):
		var angle = PI + (float(i) / float(segments)) * PI
		var pt = Vector2(cos(angle) * half_w, -h / 2.0 + half_w + sin(angle) * half_w)
		points.append(pt)
	points.append(Vector2(half_w, h / 2.0))
	draw_colored_polygon(points, frame_color)
	
	# Bevel / glow border
	draw_polyline(points, Color(0.26, 0.24, 0.3, 1.0), 2.0)
	
	# Inner portal depth
	var inner_w = half_w - 5.0
	var inner_h = h - 6.0
	var inner_points = PackedVector2Array()
	inner_points.append(Vector2(-inner_w, h / 2.0))
	inner_points.append(Vector2(-inner_w, -inner_h / 2.0 + inner_w + 3.0))
	for i in range(segments + 1):
		var angle = PI + (float(i) / float(segments)) * PI
		var pt = Vector2(cos(angle) * inner_w, -inner_h / 2.0 + inner_w + 3.0 + sin(angle) * inner_w)
		inner_points.append(pt)
	inner_points.append(Vector2(inner_w, h / 2.0))
	draw_colored_polygon(inner_points, inside_color)
	
	# Overhead Status Beacon / Arrow
	draw_circle(Vector2(0, -h / 2.0 + 14.0), 3.5, beacon_color)
	# Downward arrival indicator
	var arrow = PackedVector2Array([
		Vector2(-4.0, -h / 2.0 + 20.0),
		Vector2(0.0, -h / 2.0 + 25.0),
		Vector2(4.0, -h / 2.0 + 20.0)
	])
	draw_polyline(arrow, beacon_color, 1.8)
