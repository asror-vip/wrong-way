extends StaticBody2D

# Wrong Way — Solid Ground Platform

@export var platform_width: float = 200.0
@export var platform_height: float = 40.0
@export var platform_color: Color = Color(0.14, 0.13, 0.15, 1.0)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visuals: Node2D = $Visuals

func _ready() -> void:
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect_shape = collision_shape.shape.duplicate()
		rect_shape.size = Vector2(platform_width, platform_height)
		collision_shape.shape = rect_shape
		collision_shape.position = Vector2(0, platform_height / 2.0)
	
	if visuals:
		visuals.queue_redraw()
