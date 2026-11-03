extends Node2D

var lifetime: float = 0.20

func _ready() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(queue_free)

func _draw() -> void:
	var w: float = 28.0
	var h: float = 32.0
	var rect := Rect2(-w / 2.0, -h, w, h)
	# Oq/havorang shaffof sharpashimon qoldiq (afterimage ghost)
	draw_rect(rect, Color(0.75, 0.85, 1.0, 0.38), true)
	draw_rect(rect, Color(1.0, 1.0, 1.0, 0.55), false, 1.2)

