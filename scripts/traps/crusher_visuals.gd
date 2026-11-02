extends Node2D

# Wrong Way — Crusher Block Visuals
# Seamlessly camouflaged with the ceiling architecture so traps cannot be spotted in advance.

@export var block_color: Color = Color(0.14, 0.13, 0.15, 1.0)
@export var border_color: Color = Color(0.24, 0.22, 0.26, 1.0)

func _draw() -> void:
	var w = 100.0
	var h = 60.0
	
	var parent_trap = get_parent().get_parent()
	if parent_trap and "block_size" in parent_trap:
		w = parent_trap.block_size.x
		h = parent_trap.block_size.y
	
	var rect = Rect2(-w / 2.0, 0, w, h)
	
	# Solid body matching the ceiling and platforms
	draw_rect(rect, block_color, true)
	draw_rect(rect, border_color, false, 2.0)
