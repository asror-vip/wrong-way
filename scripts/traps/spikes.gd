extends Area2D
class_name SpikesTrap

const TrapBiomeArt := preload("res://scripts/traps/trap_biome_art.gd")
const TrapBiomeVFX := preload("res://scripts/traps/trap_biome_vfx.gd")

@export var spike_size: Vector2 = Vector2(32, 32)
@export var slide_offset_x: float = 0.0
@export var second_slide_offset_x: float = 0.0
@export var second_slide_delay: float = 0.26
@export var trigger_distance: float = 95.0
@export var slide_duration: float = 0.20
@export var trigger_on_jump: bool = false
@export var trigger_y_min: float = -9999.0
@export var trigger_y_max: float = 9999.0

var original_pos: Vector2
var is_triggered: bool = false
var slide_tween: Tween = null

@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("traps")
	original_pos = position
	if col_shape:
		col_shape.shape = RectangleShape2D.new()
		col_shape.shape.size = Vector2(spike_size.x - 4.0, spike_size.y - 4.0)
		col_shape.position = Vector2(spike_size.x / 2.0, (spike_size.y + 4.0) / 2.0)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if absf(slide_offset_x) > 1.0 and not is_triggered:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and is_instance_valid(player):
			var p_dead: bool = "is_dead" in player and player.is_dead
			var p_inv: bool = "is_invulnerable" in player and player.is_invulnerable
			if not p_dead and not p_inv:
				var py: float = player.global_position.y
				if py < trigger_y_min or py > trigger_y_max:
					return
				var dx := absf(player.global_position.x - (global_position.x + spike_size.x * 0.5))
				var dy := absf(py - global_position.y)
				var y_ok := true
				if trigger_y_min <= -9000.0 and trigger_y_max >= 9000.0:
					y_ok = dy < 95.0
				if dx <= trigger_distance and y_ok:
					var can_trigger := true
					if trigger_on_jump:
						can_trigger = ("velocity" in player and player.velocity.y < -50.0) or (player.global_position.y < global_position.y - 8.0)
					if can_trigger:
						is_triggered = true
						var ch := TrapBiomeArt.get_chapter(self)
						TrapBiomeVFX.emit_spike_slide(self, global_position + Vector2(spike_size.x * 0.5, spike_size.y), spike_size.x, slide_offset_x, ch)
						var sm = get_node_or_null("/root/SoundManager")
						if sm and sm.has_method("play_biome_trap"):
							sm.play_biome_trap("trigger", ch)
						elif sm and sm.has_method("play"):
							sm.play("trap")
						if slide_tween and slide_tween.is_valid():
							slide_tween.kill()
						scale = Vector2(1.18, 0.82)
						slide_tween = create_tween()
						slide_tween.tween_property(self, "position:x", original_pos.x + slide_offset_x, slide_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
						slide_tween.parallel().tween_property(self, "scale", Vector2.ONE, slide_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
						if absf(second_slide_offset_x) > 1.0:
							slide_tween.tween_interval(second_slide_delay)
							slide_tween.tween_callback(func():
								var ch2 := TrapBiomeArt.get_chapter(self)
								TrapBiomeVFX.emit_spike_slide(self, global_position + Vector2(spike_size.x * 0.5, spike_size.y), spike_size.x, second_slide_offset_x, ch2)
								var snd = get_node_or_null("/root/SoundManager")
								if snd and snd.has_method("play_biome_trap"):
									snd.play_biome_trap("trigger", ch2)
								elif snd and snd.has_method("play"):
									snd.play("trap")
								scale = Vector2(1.14, 0.86)
							)
							slide_tween.tween_property(self, "position:x", original_pos.x + slide_offset_x + second_slide_offset_x, slide_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
							slide_tween.parallel().tween_property(self, "scale", Vector2.ONE, slide_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	var ch := TrapBiomeArt.get_chapter(self)
	TrapBiomeArt.draw_floor_spikes(self, spike_size.x, spike_size.y, ch, spike_size.y, 0.0, false)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController or body.is_in_group("player"):
		if "is_dead" in body and body.is_dead:
			return
		if "is_invulnerable" in body and body.is_invulnerable:
			return
		if body.has_method("kill"):
			body.kill()

func reset_trap() -> void:
	if slide_tween and slide_tween.is_valid():
		slide_tween.kill()
	is_triggered = false
	position = original_pos
	scale = Vector2.ONE
	queue_redraw()
