extends StaticBody2D
# Reference to SolidPlatform

@export var platform_size: Vector2 = Vector2(350, 160)

func _ready() -> void:
	# Chap devor (ekran chap chegarasiga to'liq yopishgan va y=0 dan 540 gacha)
	if name.begins_with("WallLeft") or (position.x <= 50.0 and platform_size.y > platform_size.x):
		position.x = 0.0
		position.y = 0.0
		platform_size.x = 32.0
		platform_size.y = 540.0
	# O'ng devor (ekran o'ng chegarasiga x=928..960 to'liq yopishgan va y=0 dan 540 gacha)
	elif name.begins_with("WallRight") or ((position.x + platform_size.x) >= 890.0 and platform_size.y > platform_size.x):
		position.x = 928.0
		position.y = 0.0
		platform_size.x = 32.0
		platform_size.y = 540.0
	else:
		# Agar chap platforma/pol bo'lsa, x=0 dan boshlab qoplaymiz
		if position.x <= 40.0:
			platform_size.x += position.x
			position.x = 0.0
		# Agar o'ng platforma/pol bo'lsa, x=960 gacha yetkazamiz
		if (position.x + platform_size.x) >= 900.0:
			platform_size.x = 960.0 - position.x
		# Agar pastki pol bo'lsa, y=540 gacha to'liq qoplaymiz
		if position.y >= 350.0:
			platform_size.y = 540.0 - position.y
		
	var col = get_node_or_null("CollisionShape2D")
	if col:
		col.shape = RectangleShape2D.new()
		col.shape.size = platform_size
		col.position = platform_size / 2.0
	queue_redraw()

func _draw() -> void:
	var is_winter := false
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("is_winter_theme"):
		is_winter = gm.is_winter_theme()

	var base_col := Color("#0c111c") if is_winter else Color("#0a0b10")
	draw_rect(Rect2(Vector2.ZERO, platform_size), base_col, true)
	
	# Har qanday telefon ekranida (hatto ultra-keng 20:9 bo'lsa ham) chetlarda oraliq qolmasligi uchun
	if (position.x + platform_size.x) >= 950.0:
		draw_rect(Rect2(Vector2(platform_size.x, 0), Vector2(400, platform_size.y + 100)), base_col, true)
	if position.x <= 0.0:
		draw_rect(Rect2(Vector2(-400, 0), Vector2(400, platform_size.y + 100)), base_col, true)
	if (position.y + platform_size.y) >= 530.0:
		draw_rect(Rect2(Vector2(0, platform_size.y), Vector2(platform_size.x, 200)), base_col, true)
		
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
		draw_rect(Rect2(Vector2.ZERO, Vector2(platform_size.x, 2.0)), Color("#262e3e"), true)


