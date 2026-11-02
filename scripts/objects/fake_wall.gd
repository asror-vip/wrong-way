extends Node2D
class_name FakeWall

# Level Devil / Wrong Way Trick: Fake Wall (Aldovchi Devor)
# Looks completely solid, but the player can walk straight through it
# to find a secret path or escape an impossible forward trap!

@export var wall_size: Vector2 = Vector2(32, 540)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var is_winter := false
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("is_winter_theme"):
		is_winter = gm.is_winter_theme()

	var base_col := Color("#0d131f") if is_winter else Color("#1c1a22")
	draw_rect(Rect2(0, 0, wall_size.x, wall_size.y), base_col, true)
	if is_winter:
		draw_rect(Rect2(Vector2.ZERO, Vector2(2.5, wall_size.y)), Color(0.49, 0.86, 0.99, 0.6), true)
	else:
		draw_rect(Rect2(0, 0, wall_size.x, 3.0), Color("#342f3a"), true)

