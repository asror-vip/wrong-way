extends Node2D
class_name FakeWall

# Level Devil / Wrong Way Trick: Fake Wall (Aldovchi Devor)
# Looks completely solid, but the player can walk straight through it
# to find a secret path or escape an impossible forward trap!

@export var wall_size: Vector2 = Vector2(32, 540)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, wall_size.x, wall_size.y), Color("#18181b"), true)
	draw_rect(Rect2(0, 0, wall_size.x, wall_size.y), Color("#27272a"), false, 1.0)

