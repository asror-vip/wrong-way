extends Node2D

func _draw() -> void:
	var target = get_parent()
	if target and not ("platform_width" in target) and target.get_parent():
		if "platform_width" in target.get_parent():
			target = target.get_parent()
	
	var w = 160.0
	var h = 240.0
	var col = Color(0.14, 0.13, 0.15, 1.0)
	
	if target and "platform_width" in target:
		w = target.platform_width
		h = target.platform_height
		if "platform_color" in target:
			col = target.platform_color
	
	var rect = Rect2(-w / 2.0, 0, w, h)
	draw_rect(rect, col, true)
	# Subtle top border line
	draw_line(Vector2(-w / 2.0, 0), Vector2(w / 2.0, 0), Color(0.24, 0.22, 0.26, 1.0), 2.0)
