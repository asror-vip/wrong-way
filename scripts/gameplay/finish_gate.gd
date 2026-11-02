extends Area2D
class_name FinishGate

# Wrong Way — Finish Gate
# Authoritative level exit point.
# Handles entry validation, runner absorption, and sinking gate animation.

signal finish_completed

var initial_position: Vector2
var is_sinking: bool = false
var reset_cooldown: float = 0.0
var active_tween: Tween = null

@onready var visuals: Node2D = $Visuals
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	initial_position = position
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if reset_cooldown > 0.0:
		reset_cooldown -= delta

func reset_gate() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	is_sinking = false
	position = initial_position
	modulate.a = 1.0
	visible = true
	reset_cooldown = 0.40 # Ignore physics overlap events for 0.40s after reset/respawn
	if collision_shape:
		collision_shape.set_deferred("disabled", false)

func hide_for_completed() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	is_sinking = true
	visible = false
	modulate.a = 0.0
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

func _on_body_entered(body: Node2D) -> void:
	if is_sinking or reset_cooldown > 0.0:
		return
	if (body is PlayerController or body.is_in_group("player")) and body.has_method("enter_finish"):
		if ("is_dead" in body and body.is_dead) or ("is_finishing" in body and body.is_finishing):
			return
		
		# Validation: Runner MUST physically be right at the door frame (< 50px away)
		# Prevents phantom collision overlap triggers upon respawn/teleport across the map
		if body.global_position.distance_to(global_position) > 50.0:
			return
		
		is_sinking = true
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		
		# 1. Player enters gate doorway and vanishes
		body.enter_finish(global_position)
		
		# Brief pause while player is absorbed into the portal
		await get_tree().create_timer(0.20).timeout
		
		# 2. Gate smoothly sinks down into the foundation and fades out cleanly
		var sm = get_node_or_null("/root/SoundManager")
		if sm and sm.has_method("play_trap"):
			sm.play_trap()
		
		active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		active_tween.tween_property(self, "position:y", initial_position.y + 65.0, 0.35)
		active_tween.tween_property(self, "modulate:a", 0.0, 0.35)
		
		await active_tween.finished
		visible = false
		
		# Impact feedback when gate fully sinks
		if sm and sm.has_method("play_land"):
			sm.play_land()
		
		var p = get_parent()
		if p and p.has_method("trigger_shake"):
			p.trigger_shake(4.0)
		
		await get_tree().create_timer(0.12).timeout
		
		# 3. Complete finish sequence & trigger win modal
		finish_completed.emit()
