extends Node2D

var lifetime: float = 0.22
var _tween: Tween

func _ready() -> void:
	play_effect()

func play_effect() -> void:
	modulate.a = 1.0
	show()
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(hide)

func _draw() -> void:
	var w: float = 28.0
	var h: float = 32.0
	var rect := Rect2(-w / 2.0, -h, w, h)
	var r := 4.5
	var pts := PackedVector2Array()
	var corners := [
		Vector2(rect.end.x - r, rect.position.y + r),
		Vector2(rect.end.x - r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.position.y + r),
	]
	var start_angles := [-PI * 0.5, 0.0, PI * 0.5, PI]
	for ci in range(4):
		var c: Vector2 = corners[ci]
		var a0: float = start_angles[ci]
		for si in range(4):
			var ang := a0 + (PI * 0.5) * (float(si) / 3.0)
			pts.append(c + Vector2(cos(ang) * r, sin(ang) * r))
	draw_colored_polygon(pts, Color(0.68, 0.86, 1.0, 0.34))
	var outline := PackedVector2Array(pts)
	outline.append(pts[0])
	draw_polyline(outline, Color(0.95, 0.99, 1.0, 0.62), 1.4, true)
	# Subtle afterimage eyes
	var eye_y := -h * 0.54
	draw_circle(Vector2(-6.0, eye_y), 3.0, Color(1.0, 1.0, 1.0, 0.45))
	draw_circle(Vector2(6.0, eye_y), 3.0, Color(1.0, 1.0, 1.0, 0.45))
