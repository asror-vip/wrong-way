extends AnimatableBody2D
class_name DodgingPlatform

const TrapBiomeArt := preload("res://scripts/traps/trap_biome_art.gd")
const TrapBiomeVFX := preload("res://scripts/traps/trap_biome_vfx.gd")

# Level Devil Trap: Dodging Platform (Qochuvchi Platforma)
# Looks like a safe stepping stone over a deadly gap.
# As soon as the player jumps towards it, it slides away rapidly!

@export var platform_size: Vector2 = Vector2(90, 36)
@export var dodge_offset: Vector2 = Vector2(130.0, 0.0) # O'ngga yoki pastga qochish
@export var trigger_distance: float = 85.0
@export var dodge_duration: float = 0.22
@export var betray_on_land: bool = false
@export var betray_delay: float = 0.20
@export var betray_offset: Vector2 = Vector2(0.0, 240.0)
@export var trigger_y_min: float = -9999.0
@export var trigger_y_max: float = 9999.0
@export var returns_to_origin: bool = false
@export var return_delay: float = 1.4

var original_pos: Vector2
var is_triggered: bool = false
var tween: Tween
var _dodge_finished: bool = false
var _betray_triggered: bool = false
var _is_returning: bool = false
var _return_timer: float = 0.0
var _betray_crack: float = 0.0

@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("traps")
	sync_to_physics = false
	original_pos = position
	
	if col_shape:
		var rect := RectangleShape2D.new()
		rect.size = platform_size
		col_shape.shape = rect
		col_shape.position = platform_size / 2.0

func _physics_process(delta: float) -> void:
	if not is_triggered and not _is_returning:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and is_instance_valid(player):
			if "is_dead" in player and player.is_dead:
				return
			if "is_invulnerable" in player and player.is_invulnerable:
				return
			var py: float = player.global_position.y
			if py < trigger_y_min or py > trigger_y_max:
				return
			if trigger_y_min <= -9000.0 and trigger_y_max >= 9000.0:
				if py > (global_position.y + 32.0) or py < (global_position.y - 95.0):
					return
			var center: Vector2 = global_position + platform_size / 2.0
			var dist: float = player.global_position.distance_to(center)
			if dist < trigger_distance:
				trigger_dodge()
	elif _dodge_finished and not _betray_triggered and not _is_returning:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and is_instance_valid(player):
			if "is_dead" in player and player.is_dead:
				return
			if "is_invulnerable" in player and player.is_invulnerable:
				return
			var px: float = player.global_position.x
			var py: float = player.global_position.y
			var on_top := px >= global_position.x - 4.0 and px <= global_position.x + platform_size.x + 4.0 and py >= global_position.y - 12.0 and py <= global_position.y + 12.0
			if betray_on_land and on_top:
				_trigger_betrayal()
			elif returns_to_origin:
				var center: Vector2 = global_position + platform_size / 2.0
				var dist: float = player.global_position.distance_to(center)
				if not on_top and (dist > trigger_distance * 1.45 or py > global_position.y + 45.0):
					_return_timer += delta
					if _return_timer >= return_delay:
						_return_to_origin()
				else:
					_return_timer = 0.0

func _return_to_origin() -> void:
	if _is_returning or _betray_triggered:
		return
	_is_returning = true
	_return_timer = 0.0
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position", original_pos, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		_is_returning = false
		is_triggered = false
		_dodge_finished = false
	)

func trigger_dodge() -> void:
	if is_triggered:
		return
	is_triggered = true
	var ch := TrapBiomeArt.get_chapter(self)
	TrapBiomeVFX.emit_dodge_whoosh(self, global_position + platform_size * 0.5, platform_size, dodge_offset, ch)
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_biome_trap"):
		sm.play_biome_trap("trigger", ch)
	elif sm and sm.has_method("play"):
		sm.play("trap")
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("request_screen_shake"):
		gm.request_screen_shake.emit(4.0)
	
	if tween and tween.is_valid():
		tween.kill()
	scale = Vector2(1.14, 0.86)
	tween = create_tween()
	var target := original_pos + dodge_offset
	tween.tween_property(self, "position", target, dodge_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, dodge_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _dodge_finished = true)

func _trigger_betrayal() -> void:
	if _betray_triggered:
		return
	_betray_triggered = true
	if tween and tween.is_valid():
		tween.kill()
	var start_pos := position
	var target_pos := start_pos + betray_offset
	var delay := minf(betray_delay, 0.22)
	tween = create_tween()
	if delay > 0.0:
		tween.tween_method(func(v: float):
			_betray_crack = v
			position.x = start_pos.x + sin(v * PI * 6.0) * 2.5
			queue_redraw()
		, 0.0, 1.0, delay)
	tween.tween_callback(func():
		position.x = start_pos.x
		_betray_crack = 1.0
		queue_redraw()
		var ch_b := TrapBiomeArt.get_chapter(self)
		TrapBiomeVFX.emit_crumble_debris(self, global_position, platform_size, ch_b, true)
		var sm = get_node_or_null("/root/SoundManager")
		if sm and sm.has_method("play_biome_trap"):
			sm.play_biome_trap("crumble", ch_b)
		elif sm and sm.has_method("play"):
			sm.play("trap")
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_signal("request_screen_shake"):
			gm.request_screen_shake.emit(4.0)
	)
	tween.tween_property(self, "position", target_pos, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func reset_trap() -> void:
	if tween and tween.is_valid():
		tween.kill()
	is_triggered = false
	_dodge_finished = false
	_betray_triggered = false
	_is_returning = false
	_return_timer = 0.0
	_betray_crack = 0.0
	position = original_pos
	scale = Vector2.ONE
	if is_inside_tree():
		PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, global_transform)
	queue_redraw()

func _draw() -> void:
	var ch := TrapBiomeArt.get_chapter(self)
	TrapBiomeArt.draw_platform_surface(self, 0.0, platform_size.x, platform_size.y, ch, false)
	TrapBiomeArt.draw_fracture_cracks(self, platform_size.x, platform_size.y, _betray_crack, ch)
