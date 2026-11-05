extends StaticBody2D
class_name SolidPlatform

@export var platform_size: Vector2 = Vector2(350, 160)

func _ready() -> void:
	_adapt_to_screen()
	var col = get_node_or_null("CollisionShape2D")
	if col:
		col.shape = RectangleShape2D.new()
		col.shape.size = platform_size
		col.position = platform_size / 2.0
	queue_redraw()

func _adapt_to_screen() -> void:
	var vp_size := get_viewport_rect().size
	var vp_w := maxf(960.0, vp_size.x)
	var vp_h := maxf(540.0, vp_size.y)
	var screen_left := 480.0 - vp_w / 2.0
	var screen_right := 480.0 + vp_w / 2.0
	var screen_top := 270.0 - vp_h / 2.0
	var screen_bottom := 270.0 + vp_h / 2.0

	var p_name := name.to_lower()

	# 1. Shift (Ceiling)
	if p_name.contains("ceiling") or p_name.contains("shift") or (position.y <= 25.0 and platform_size.y < 120.0 and platform_size.x >= 500.0):
		position.x = screen_left - 100.0
		position.y = screen_top - 100.0
		platform_size.x = (screen_right - screen_left) + 200.0
		platform_size.y = (0.0 - screen_top) + 60.0 + 100.0

	# 2. Chap devor (WallLeft)
	elif p_name.contains("wallleft") or (position.x <= 40.0 and platform_size.y > platform_size.x and platform_size.y >= 300.0):
		position.x = screen_left
		position.y = screen_top - 50.0
		platform_size.x = 32.0
		platform_size.y = (screen_bottom - screen_top) + 100.0

	# 3. O'ng devor (WallRight)
	elif p_name.contains("wallright") or ((position.x + platform_size.x) >= 900.0 and platform_size.y > platform_size.x and platform_size.y >= 300.0):
		platform_size.x = 32.0
		position.x = screen_right - platform_size.x
		position.y = screen_top - 50.0
		platform_size.y = (screen_bottom - screen_top) + 100.0

	# 4. Pol va platformalar
	else:
		if position.y >= 260.0:
			if position.x <= 50.0 and platform_size.x > platform_size.y:
				var orig_right: float = position.x + platform_size.x
				position.x = screen_left - 50.0
				platform_size.x = maxf(orig_right - position.x, 100.0)
			if (position.x + platform_size.x) >= 890.0 and platform_size.x > platform_size.y:
				platform_size.x = maxf((screen_right + 50.0) - position.x, 100.0)
			if (position.y + platform_size.y) >= 480.0:
				platform_size.y = maxf(platform_size.y, (screen_bottom + 100.0) - position.y)

func _draw() -> void:
	var is_winter := false
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("is_winter_theme"):
		is_winter = gm.is_winter_theme()

	var base_col := Color("#0d131f") if is_winter else Color("#1c1a22")
	draw_rect(Rect2(Vector2.ZERO, platform_size), base_col, true)

	var p_name := name.to_lower()
	if p_name.contains("ceiling") or p_name.contains("shift") or position.y <= 25.0:
		draw_rect(Rect2(Vector2(0, -300), Vector2(platform_size.x, 300)), base_col, true)
	if p_name.contains("wallleft") or position.x <= 10.0:
		draw_rect(Rect2(Vector2(-300, 0), Vector2(300, platform_size.y)), base_col, true)
	if p_name.contains("wallright") or platform_size.y > 300.0:
		draw_rect(Rect2(Vector2(platform_size.x, 0), Vector2(300, platform_size.y)), base_col, true)
	if (position.y + platform_size.y) >= 480.0:
		draw_rect(Rect2(Vector2(0, platform_size.y), Vector2(platform_size.x, 300)), base_col, true)

	if is_winter:
		var snow_h := 5.5
		if platform_size.x > 36.0:
			draw_rect(Rect2(Vector2.ZERO, Vector2(platform_size.x, snow_h)), Color("#f1f5f9"), true)
			draw_rect(Rect2(Vector2.ZERO, Vector2(platform_size.x, 2.0)), Color("#ffffff"), true)
			draw_rect(Rect2(Vector2(0, snow_h - 1.5), Vector2(platform_size.x, 1.5)), Color("#94a3b8"), true)
			var icicle_step := 32.0
			var num_icicles := int((platform_size.x - 20.0) / icicle_step)
			for i in range(num_icicles):
				var ix := 14.0 + float(i) * icicle_step
				var ilen := 4.0 if (i % 2 == 0) else 6.0
				draw_colored_polygon(PackedVector2Array([
					Vector2(ix - 2.0, snow_h),
					Vector2(ix + 2.0, snow_h),
					Vector2(ix, snow_h + ilen)
				]), Color("#bae6fd"))
		else:
			draw_rect(Rect2(Vector2.ZERO, Vector2(2.5, platform_size.y)), Color(0.49, 0.86, 0.99, 0.6), true)
	else:
		if p_name.contains("ceiling") or p_name.contains("shift") or position.y <= 25.0:
			draw_rect(Rect2(Vector2(0, platform_size.y - 3.0), Vector2(platform_size.x, 3.0)), Color("#342f3a"), true)
		else:
			draw_rect(Rect2(Vector2.ZERO, Vector2(platform_size.x, 3.0)), Color("#342f3a"), true)
