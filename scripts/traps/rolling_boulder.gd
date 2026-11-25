extends CharacterBody2D
class_name RollingBoulder

const TrapBiomeArt := preload("res://scripts/traps/trap_biome_art.gd")
const TrapBiomeVFX := preload("res://scripts/traps/trap_biome_vfx.gd")

# Wrong Way - Unexpected Event: Rolling Giant Boulder (Qoya Toshi)
# Iconic Limbo-style surprise: Triggers when the player walks past,
# rumbles with screen shake and rolls rapidly to chase or crush the player!

@export var boulder_radius: float = 28.0
@export var roll_speed: float = 380.0
@export var roll_direction: float = 1.0 # 1.0 = o'ngga, -1.0 = chapga
@export var trigger_distance: float = 260.0 # O'yinchi yaqinlashganda
@export var delay_before_roll: float = 0.7
@export var gravity: float = 1200.0
@export var bounce_back_once: bool = false
@export var trigger_y_min: float = -9999.0
@export var trigger_y_max: float = 9999.0

var is_triggered: bool = false
var is_rolling: bool = false
var has_fallen: bool = false
var roll_delay_timer: float = 0.0
var original_pos: Vector2
var roll_rotation: float = 0.0
var _has_bounced: bool = false
var _initial_direction: float = -99.0
var _initial_speed: float = 380.0
var _fade_tween: Tween = null
var _bounce_tween: Tween = null
var _anim_time: float = 0.0
var _trail_accum: float = 0.0
var _rumble_accum: float = 0.0
var _is_shattered: bool = false
var _impact_flash: float = 0.0
var _was_on_floor: bool = true
var _prev_vy: float = 0.0

@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var kill_area: Area2D = $KillArea

func _ready() -> void:
	add_to_group("traps")
	original_pos = global_position
	_initial_direction = roll_direction
	_initial_speed = roll_speed
	
	if col_shape and col_shape.shape is CircleShape2D:
		col_shape.shape.radius = boulder_radius
		
	if kill_area:
		kill_area.body_entered.connect(_on_kill_entered)

func _physics_process(delta: float) -> void:
	if has_fallen:
		return

	_anim_time += delta
	var ch := TrapBiomeArt.get_chapter(self)

	# Qoyaga tushib ketsa
	if global_position.y > 650.0:
		has_fallen = true
		is_rolling = false
		velocity = Vector2.ZERO
		return

	if not is_triggered:
		_check_player_trigger()
		if ch == 5 or ch == 3:
			# Subtle ambient magma pulse / forest spore shimmer even before rolling (throttled)
			_rumble_accum += delta
			if _rumble_accum >= 0.08:
				_rumble_accum = 0.0
				queue_redraw()
		return

	if not is_rolling:
		roll_delay_timer -= delta
		global_position.x = original_pos.x + randf_range(-1.5, 1.5)
		_rumble_accum += delta
		if _rumble_accum >= 0.09:
			_rumble_accum = 0.0
			TrapBiomeVFX.emit_boulder_rumble(self, global_position, boulder_radius, ch)
		queue_redraw()
		if roll_delay_timer <= 0.0:
			global_position.x = original_pos.x
			is_rolling = true
		return
		
	# Gravitatsiya va aylanish
	var pre_on_floor := is_on_floor()
	if not pre_on_floor:
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
		# Harakatlanish paytida vaqti-vaqti bilan yengil silkinish
		if randf() < 0.1:
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_signal("request_screen_shake"):
				gm.request_screen_shake.emit(3.0)
	_prev_vy = velocity.y
			
	velocity.x = roll_direction * roll_speed
	roll_rotation += roll_direction * (roll_speed / boulder_radius) * delta
	
	move_and_slide()
	var now_on_floor := is_on_floor()
	if not _was_on_floor and now_on_floor and _prev_vy > 220.0:
		TrapBiomeVFX.emit_boulder_land(self, global_position, boulder_radius, ch)
		if _bounce_tween and _bounce_tween.is_valid():
			_bounce_tween.kill()
		scale = Vector2(1.14, 0.86)
		_bounce_tween = create_tween()
		_bounce_tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var sm_land = get_node_or_null("/root/SoundManager")
		if sm_land and sm_land.has_method("play_biome_trap"):
			sm_land.play_biome_trap("impact", ch)
		var gm_land = get_node_or_null("/root/GameManager")
		if gm_land and gm_land.has_signal("request_screen_shake"):
			gm_land.request_screen_shake.emit(5.0)
	_was_on_floor = now_on_floor
	_trail_accum += delta
	var trail_step := 0.07 if OS.has_feature("mobile") else 0.045
	if _trail_accum >= trail_step:
		_trail_accum = 0.0
		TrapBiomeVFX.emit_boulder_trail(self, global_position, boulder_radius, roll_direction, is_on_floor(), ch)
	queue_redraw()

	# Devorga yetganda tosh yo'lni to'sib qolmasligi uchun to'xtaydi va biomga xos tarzda yoriladi!
	var wall_in_front := false
	if is_on_wall():
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var normal := collision.get_normal()
			# Normal harakat yo'nalishiga qarama-qarshi bo'lsagina haqiqiy devor hisoblanadi
			if (roll_direction > 0 and normal.x < -0.5) or (roll_direction < 0 and normal.x > 0.5):
				wall_in_front = true
				break

	if wall_in_front and (_has_bounced or absf(global_position.x - original_pos.x) > 60.0):
		if bounce_back_once and not _has_bounced:
			var impact_dir := roll_direction
			_has_bounced = true
			roll_direction = -roll_direction
			roll_speed *= 1.12
			global_position.x += roll_direction * 4.0
			TrapBiomeVFX.emit_boulder_shatter(self, global_position, boulder_radius, impact_dir, ch, true)
			if _bounce_tween and _bounce_tween.is_valid():
				_bounce_tween.kill()
			scale = Vector2(0.84, 1.18)
			_bounce_tween = create_tween()
			_bounce_tween.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			var sm = get_node_or_null("/root/SoundManager")
			if sm and sm.has_method("play_biome_trap"):
				sm.play_biome_trap("impact", ch)
			elif sm and sm.has_method("play"):
				sm.play("trap")
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_signal("request_screen_shake"):
				gm.request_screen_shake.emit(8.0)
			return
		has_fallen = true
		is_rolling = false
		_is_shattered = true
		_impact_flash = 1.0
		velocity = Vector2.ZERO
		if col_shape:
			col_shape.set_deferred("disabled", true)
		if kill_area:
			kill_area.set_deferred("monitoring", false)
			kill_area.set_deferred("monitorable", false)
		TrapBiomeVFX.emit_boulder_shatter(self, global_position, boulder_radius, roll_direction, ch, false)
		var sm_shatter = get_node_or_null("/root/SoundManager")
		if sm_shatter and sm_shatter.has_method("play_biome_trap"):
			sm_shatter.play_biome_trap("boulder_shatter", ch)
		elif sm_shatter and sm_shatter.has_method("play"):
			sm_shatter.play("trap")
		var gm_shatter = get_node_or_null("/root/GameManager")
		if gm_shatter and gm_shatter.has_signal("request_screen_shake"):
			gm_shatter.request_screen_shake.emit(8.0)
		queue_redraw()
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(self, "scale", Vector2(1.22, 0.78), 0.045)
		_fade_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.06)
		_fade_tween.tween_callback(func(): visible = false)
		return
	
	# Qoyaga tushib ketsa
	if global_position.y > 650.0:
		has_fallen = true
		is_rolling = false
		velocity = Vector2.ZERO
		return

func _check_player_trigger() -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if not player or not is_instance_valid(player):
		return
	if "is_dead" in player and player.is_dead:
		return
		
	var py: float = player.global_position.y
	if py < trigger_y_min or py > trigger_y_max:
		return
	var dx: float = player.global_position.x - global_position.x
	var dy: float = absf(py - global_position.y)
	if trigger_y_min <= -9000.0 and trigger_y_max >= 9000.0 and dy > 95.0:
		return
		
	if roll_direction > 0:
		# Orqadan quvuvchi arra/tosh: Faqat o'yinchi oldinga yetarlicha yurganidagina ishga tushadi
		if dx >= trigger_distance:
			trigger_boulder()
	else:
		# Oldindan keluvchi tosh: o'yinchi yaqinlashganda
		if dx <= 0.0 and absf(dx) <= trigger_distance:
			trigger_boulder()
		elif absf(dx) <= 60.0:
			trigger_boulder()

func trigger_boulder() -> void:
	if is_triggered:
		return
	is_triggered = true
	is_rolling = false
	roll_delay_timer = delay_before_roll
	var ch := TrapBiomeArt.get_chapter(self)
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_biome_trap"):
		sm.play_biome_trap("trigger", ch)
	elif sm and sm.has_method("play"):
		sm.play("trap")
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("request_screen_shake"):
		gm.request_screen_shake.emit(10.0)

func _on_kill_entered(body: Node2D) -> void:
	if is_triggered and (body is PlayerController or body.is_in_group("player")):
		if body.has_method("kill"):
			body.kill()
		elif body.has_method("die"):
			body.die()

func reset_trap() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	if _bounce_tween and _bounce_tween.is_valid():
		_bounce_tween.kill()
	if _is_shattered:
		TrapBiomeVFX.clear_for(self)
	has_fallen = false
	is_triggered = false
	is_rolling = false
	_is_shattered = false
	_impact_flash = 0.0
	_was_on_floor = true
	_prev_vy = 0.0
	_trail_accum = 0.0
	_rumble_accum = 0.0
	roll_delay_timer = 0.0
	_has_bounced = false
	if _initial_direction != -99.0:
		roll_direction = _initial_direction
	roll_speed = _initial_speed
	global_position = original_pos
	velocity = Vector2.ZERO
	roll_rotation = 0.0
	scale = Vector2.ONE
	modulate.a = 1.0
	visible = true
	if col_shape:
		col_shape.set_deferred("disabled", false)
	if kill_area:
		kill_area.set_deferred("monitoring", true)
		kill_area.set_deferred("monitorable", true)
	queue_redraw()

func _draw() -> void:
	var ch := TrapBiomeArt.get_chapter(self)
	TrapBiomeArt.draw_rolling_boulder(self, boulder_radius, roll_rotation, ch, _anim_time, _impact_flash)

