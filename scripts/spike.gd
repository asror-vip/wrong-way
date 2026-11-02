extends Area2D

# Wrong Way — Deadly Spike Hazard

@export var spike_count: int = 1
@export var spike_width: float = 30.0
@export var spike_height: float = 24.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("die"):
		body.die()
