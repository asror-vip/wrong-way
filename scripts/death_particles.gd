extends CPUParticles2D

func _ready() -> void:
	emitting = true
	# Auto remove after particles finish
	await get_tree().create_timer(lifetime + 0.2).timeout
	queue_free()
