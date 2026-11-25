extends Area2D
class_name JumpingSpikes

const TrapBiomeArt := preload("res://scripts/traps/trap_biome_art.gd")
const TrapBiomeVFX := preload("res://scripts/traps/trap_biome_vfx.gd")

# Level Devil Trap: Jumping Spikes (Sakrovchi Tikanlar)
# Floor spikes that look innocent, but as soon as the player jumps over them,
# they spring into the air to catch the player mid-air!

@export var spike_width: float = 64.0
@export var spike_height: float = 28.0
@export var trigger_distance: float = 80.0
@export var jump_speed: float = -620.0
@export var fall_gravity: float = 1800.0
@export var lunge_speed_x: float = 0.0
@export var trigger_y_min: float = -9999.0
@export var trigger_y_max: float = 9999.0

var original_pos: Vector2
var is_triggered: bool = false
var velocity_y: float = 0.0
var current_x: float = 0.0
var current_y: float = 0.0
var pop_tween: Tween = null

@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("traps")
	original_pos = position
	current_x = position.x
	current_y = position.y
	
	if col_shape:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(spike_width, spike_height)
		col_shape.shape = rect
		col_shape.position = Vector2(spike_width / 2.0, -spike_height / 2.0)
		
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not is_triggered:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and is_instance_valid(player):
			if "is_dead" in player and player.is_dead:
				return
			if "is_invulnerable" in player and player.is_invulnerable:
				return
			var py: float = player.global_position.y
			if py < trigger_y_min or py > trigger_y_max:
				return
			var center_x: float = global_position.x + spike_width / 2.0
			var dist_x: float = abs(player.global_position.x - center_x)
			var dist_y: float = global_position.y - py
			
			# O'yinchi yaqinlashib havoga sakraganda tikanlar yuqoriga otiladi!
			if dist_x < trigger_distance and dist_y > 10.0 and dist_y < 140.0:
				trigger_jump()
	else:
		var was_airborne: bool = current_y < original_pos.y or velocity_y < 0.0
		velocity_y += fall_gravity * delta
		current_y += velocity_y * delta
		if current_y >= original_pos.y:
			var just_landed := was_airborne and velocity_y > 120.0
			current_y = original_pos.y
			velocity_y = 0.0
			if just_landed:
				var ch_land := TrapBiomeArt.get_chapter(self)
				TrapBiomeVFX.emit_spike_slide(self, global_position + Vector2(spike_width * 0.5, 0.0), spike_width, 1.0, ch_land)
		elif was_airborne or current_y < original_pos.y:
			current_x += lunge_speed_x * delta
			position.x = current_x
		position.y = current_y
		for b in get_overlapping_bodies():
			_on_body_entered(b)
		
	queue_redraw()

func trigger_jump() -> void:
	if is_triggered:
		return
	is_triggered = true
	velocity_y = jump_speed
	var ch := TrapBiomeArt.get_chapter(self)
	TrapBiomeVFX.emit_spike_erupt(self, global_position + Vector2(spike_width * 0.5, 0.0), spike_width, ch)
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_biome_trap"):
		sm.play_biome_trap("spring", ch)
	elif sm and sm.has_method("play"):
		sm.play("trap")
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("request_screen_shake"):
		gm.request_screen_shake.emit(6.0)
	if pop_tween and pop_tween.is_valid():
		pop_tween.kill()
	scale = Vector2(0.84, 1.24)
	pop_tween = create_tween()
	pop_tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController or body.is_in_group("player"):
		if "is_dead" in body and body.is_dead:
			return
		if "is_invulnerable" in body and body.is_invulnerable:
			return
		if body.has_method("kill"):
			body.kill()
		elif body.has_method("die"):
			body.die()

func reset_trap() -> void:
	if pop_tween and pop_tween.is_valid():
		pop_tween.kill()
	is_triggered = false
	velocity_y = 0.0
	current_x = original_pos.x
	current_y = original_pos.y
	position = original_pos
	scale = Vector2.ONE
	queue_redraw()

func _draw() -> void:
	var ch := TrapBiomeArt.get_chapter(self)
	TrapBiomeArt.draw_floor_spikes(self, spike_width, spike_height, ch, -3.0, -spike_height, true)
