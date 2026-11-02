extends StaticBody2D
class_name SolidPlatform

@export var platform_size: Vector2 = Vector2(350, 160)

func _ready() -> void:
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

	var base_col := Color("#0d131f") if is_winter else Color("#1c1a22")
	draw_rect(Rect2(Vector2.ZERO, platform_size), base_col, true)

	if is_winter:
		# Yerda qor qatlami (Snow layer on ground/platforms)
		var snow_h := 5.5
		if platform_size.x > 36.0:
			# Asosiy toza qor qoplami
			draw_rect(Rect2(Vector2.ZERO, Vector2(platform_size.x, snow_h)), Color("#f1f5f9"), true)
			# Qorning yaltiroq ustki qatlami
			draw_rect(Rect2(Vector2.ZERO, Vector2(platform_size.x, 2.0)), Color("#ffffff"), true)
			# Qor ostidagi sovuq soya
			draw_rect(Rect2(Vector2(0, snow_h - 1.5), Vector2(platform_size.x, 1.5)), Color("#94a3b8"), true)
			
			# Qirralardan osilib turgan kichik muz donalari (Icicles)
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
			# Tik devor uchun muz qirovi
			draw_rect(Rect2(Vector2.ZERO, Vector2(2.5, platform_size.y)), Color(0.49, 0.86, 0.99, 0.6), true)
	else:
		draw_rect(Rect2(Vector2.ZERO, Vector2(platform_size.x, 3.0)), Color("#342f3a"), true)
