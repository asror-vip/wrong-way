extends CharacterBody2D
class_name PlayerController

signal died
signal respawned
signal entered_exit
signal screen_wrapped(from_x: float, to_x: float, y_pos: float)

const SPEED: float = 280.0
const DASH_SPEED: float = 660.0
const DASH_DURATION: float = 0.16
const DASH_COOLDOWN: float = 0.40
const JUMP_VELOCITY: float = -560.0
const GRAVITY: float = 1450.0
const MAX_SHORT_JUMP_FALL: float = -500.0

var coyote_timer: float = 0.0
var jump_buffer: float = 0.0
var facing: int = 1
var is_dead: bool = false
var is_entering_door: bool = false
var spawn_position: Vector2
var controls_inverted: bool = false
var active_inverters: Dictionary = {}
var gravity_mult: float = 1.0
var speed_mult: float = 1.0
var jump_mult: float = 1.0
var ice_friction: float = 0.0
var external_wind_x: float = 0.0
var external_force_y: float = 0.0
var screen_wrap_enabled: bool = false
var screen_wrap_y_min: float = 0.0
var screen_wrap_y_max: float = 540.0
var is_invulnerable: bool = false
var invulnerable_timer: float = 0.0

# Genshin Impact uslubidagi bir martalik Dash (Shift) holati
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_dir: float = 1.0
var ghost_trail_timer: float = 0.0

const DashGhostScript = preload("res://scripts/player/dash_ghost.gd")
const DustPuffScript = preload("res://scripts/player/dust_puff.gd")
const DeathParticlesScene = preload("res://scenes/player/death_particles.tscn")
var _ghost_pool: Array[Node2D] = []
var _dust_pool: Array[Node2D] = []
var _was_on_floor: bool = true
var _air_max_fall_speed: float = 0.0
var _run_dust_timer: float = 0.0
var _prev_move_sign: int = 0

@onready var visual: Node2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	if not InputMap.has_action("dash"):
		InputMap.add_action("dash")
	# Shift va J tugmalarining ikkalasi ham Dash uchun to'liq ishlashini kafolatlaymiz
	var has_shift := false
	var has_j := false
	for ev in InputMap.action_get_events("dash"):
		if ev is InputEventKey:
			if ev.keycode == KEY_SHIFT or ev.physical_keycode == KEY_SHIFT:
				has_shift = true
			if ev.keycode == KEY_J or ev.physical_keycode == KEY_J:
				has_j = true
	if not has_shift:
		var ev_shift := InputEventKey.new()
		ev_shift.physical_keycode = KEY_SHIFT
		InputMap.action_add_event("dash", ev_shift)
	if not has_j:
		var ev_j := InputEventKey.new()
		ev_j.physical_keycode = KEY_J
		InputMap.action_add_event("dash", ev_j)

func _physics_process(delta: float) -> void:
	if is_dead or is_entering_door or GameManager.is_countdown_active:
		velocity = Vector2.ZERO
		return

	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
		if invulnerable_timer <= 0.0:
			is_invulnerable = false

	# Dash taymerlari va sharpali qoldiq (ghost afterimage)
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if is_dashing:
		dash_timer -= delta
		ghost_trail_timer -= delta
		if ghost_trail_timer <= 0.0:
			ghost_trail_timer = 0.038
			_spawn_dash_ghost()
		if dash_timer <= 0.0:
			is_dashing = false

	# Coyote Time & Jump Buffer
	if is_on_floor():
		coyote_timer = 0.16
	else:
		coyote_timer -= delta

	if jump_buffer > 0.0:
		jump_buffer -= delta

	# Gorizontal harakat
	var move_dir := Input.get_axis("move_left", "move_right")
	if controls_inverted:
		move_dir = -move_dir

	# Dash faollashtirish (Faqat bir marta bosilganda - Genshin Impact uslubida)
	# QAT'IY QOIDA: is_action_just_pressed ishlatiladi,
	# shuning uchun Shift bosib turilsa tez yururmaydi!
	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer <= 0.0:
		var target_dir := move_dir
		if target_dir == 0.0:
			target_dir = float(facing)
		dash_dir = target_dir
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		ghost_trail_timer = 0.0
		_spawn_dash_ghost()
		_spawn_dash_dust(dash_dir)
		if visual:
			visual.scale = Vector2(1.40, 0.70)
		if is_inside_tree():
			var sm = get_node_or_null("/root/SoundManager")
			if sm and sm.has_method("play"):
				sm.play("dash")

	if is_dashing:
		velocity.x = dash_dir * DASH_SPEED
	elif ice_friction > 0.01 and is_on_floor():
		var target_vx := move_dir * SPEED * speed_mult + external_wind_x
		if move_dir != 0:
			var new_sign_i := signi(int(move_dir))
			if _prev_move_sign != 0 and new_sign_i != _prev_move_sign:
				_spawn_skid_dust(_prev_move_sign)
			_prev_move_sign = new_sign_i
			facing = new_sign_i
		else:
			_prev_move_sign = 0
		var ice_accel := (1.0 - clampf(ice_friction, 0.0, 0.96)) * 28.0
		velocity.x = lerpf(velocity.x, target_vx, minf(1.0, delta * ice_accel))
	elif move_dir != 0:
		var new_sign := signi(int(move_dir))
		if is_on_floor() and _prev_move_sign != 0 and new_sign != _prev_move_sign:
			_spawn_skid_dust(_prev_move_sign)
		_prev_move_sign = new_sign
		facing = new_sign
		velocity.x = move_dir * SPEED * speed_mult + external_wind_x
	else:
		_prev_move_sign = 0
		velocity.x = external_wind_x

	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.16

	# Sakrash
	if jump_buffer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY * jump_mult
		coyote_timer = 0.0
		jump_buffer = 0.0
		_spawn_jump_dust()
		if visual:
			visual.scale = Vector2(0.74, 1.36)
		if is_inside_tree():
			var sm = get_node_or_null("/root/SoundManager")
			if sm and sm.has_method("play"):
				sm.play("jump")

	# Sakrash tugmasi erta qo'yib yuborilganda pastga tortish (faqat klaviaturada;
	# mobilda har bir sakrash bosilganda to'liq balandlikka sakraydi)
	var is_mob := (
		OS.has_feature("android")
		or OS.has_feature("ios")
		or OS.has_feature("mobile")
	)
	var short_cut_vy := MAX_SHORT_JUMP_FALL * jump_mult
	if not is_mob and Input.is_action_just_released("jump") \
			and velocity.y < short_cut_vy:
		velocity.y = short_cut_vy

	# Gravitatsiya va shaklni asl holatiga qaytarish (lerp)
	var net_accel_y := GRAVITY * gravity_mult
	if external_force_y < 0.0:
		if velocity.y > -480.0:
			net_accel_y += external_force_y
	else:
		net_accel_y += external_force_y
	velocity.y += net_accel_y * delta
	# Terminal velocity (yorib o'tishni oldini olish)
	velocity.y = minf(velocity.y, 1200.0)

	if not is_on_floor():
		_air_max_fall_speed = maxf(_air_max_fall_speed, velocity.y)

	if visual:
		visual.scale = visual.scale.lerp(Vector2.ONE, minf(1.0, delta * 12.5))

	move_and_slide()

	if screen_wrap_enabled and global_position.y >= screen_wrap_y_min and global_position.y <= screen_wrap_y_max:
		if global_position.x <= 18.0:
			var from_x := global_position.x
			global_position.x = 914.0
			screen_wrapped.emit(from_x, global_position.x, global_position.y)
			_spawn_respawn_ring()
			if is_inside_tree():
				var sm_wrap = get_node_or_null("/root/SoundManager")
				if sm_wrap and sm_wrap.has_method("play"):
					sm_wrap.play("portal")
		elif global_position.x >= 942.0:
			var from_x := global_position.x
			global_position.x = 46.0
			screen_wrapped.emit(from_x, global_position.x, global_position.y)
			_spawn_respawn_ring()
			if is_inside_tree():
				var sm_wrap2 = get_node_or_null("/root/SoundManager")
				if sm_wrap2 and sm_wrap2.has_method("play"):
					sm_wrap2.play("portal")

	# Qo'nish (landing) effekti: pachoqlanish, chang buluti va yumshoq ovoz
	var now_on_floor := is_on_floor()
	if now_on_floor and not _was_on_floor:
		var hard_land := _air_max_fall_speed > 260.0
		if visual:
			visual.scale = Vector2(1.28, 0.74) if hard_land else Vector2(1.15, 0.86)
		_spawn_land_dust(hard_land)
		if is_inside_tree():
			var sm = get_node_or_null("/root/SoundManager")
			if sm and sm.has_method("play"):
				sm.play("land")
		_air_max_fall_speed = 0.0
	elif now_on_floor:
		_air_max_fall_speed = 0.0
		if absf(velocity.x) > 100.0 and not is_dashing:
			_run_dust_timer -= delta
			if _run_dust_timer <= 0.0:
				_run_dust_timer = 0.16
				_spawn_run_dust()
		else:
			_run_dust_timer = 0.04
	_was_on_floor = now_on_floor

	if visual:
		visual.queue_redraw()

	# O'lim tekisligi config'dan o'qiladi yoki 960x540 arena tubiga moslanadi
	var death_y: float = 536.0
	var trap_cfg = get_node_or_null("/root/TrapConfig")
	if trap_cfg and "death_plane_y" in trap_cfg:
		death_y = float(trap_cfg.death_plane_y)

	if global_position.y > death_y:
		kill()

func kill() -> void:
	if is_dead or is_entering_door or is_invulnerable:
		return
	is_dead = true
	clear_paranormal_modifiers()
	is_dashing = false
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	velocity = Vector2.ZERO
	if is_inside_tree():
		var sm = get_node_or_null("/root/SoundManager")
		if sm and sm.has_method("play"):
			sm.play("die")
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("record_death"):
			gm.record_death()
	died.emit()
	
	visible = false
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	_spawn_particles()
	
	# O'lik gavdani xaritadagi tuzoqlar zonasidan chetga olamiz
	global_position = Vector2(-9999, -9999)
	
	# O'yin pauza qilinganda taymer to'xtab turishi uchun false (process_always = false) qo'shildi
	await get_tree().create_timer(0.34, false).timeout
	if is_instance_valid(self):
		respawn()

func die() -> void:
	kill()

func respawn(at_position: Vector2 = spawn_position) -> void:
	global_position = at_position
	velocity = Vector2.ZERO
	is_dead = false
	is_dashing = false
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	is_entering_door = false
	clear_paranormal_modifiers()
	is_invulnerable = true
	invulnerable_timer = 0.22 # 220ms spawn protection (takroriy o'limni oldini oladi)
	coyote_timer = 0.0
	jump_buffer = 0.0
	visible = true
	_was_on_floor = true
	_air_max_fall_speed = 0.0
	_prev_move_sign = 0
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if visual:
		visual.scale = Vector2(0.38, 1.48)
		visual.rotation = 0.0
		if visual.has_method("trigger_spawn_flash"):
			visual.trigger_spawn_flash()
	_spawn_respawn_ring()
	respawned.emit()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		if gm.has_signal("player_respawned"):
			gm.player_respawned.emit()

		# Qayta tirilgandan SO'NG (xavfsiz holatda) 10-chi o'lim reklamasini ko'rsatamiz (faqat ads yoqilganda)
		if gm.level_deaths > 0 and gm.level_deaths % 10 == 0:
			var adm = get_node_or_null("/root/AdManager")
			if adm and adm.has_method("is_ads_enabled") and bool(adm.is_ads_enabled()) and adm.has_method("show_interstitial_ad"):
				get_tree().paused = true
				adm.show_interstitial_ad(func():
					get_tree().paused = false
				)

func add_inverter_zone(zone: Node) -> void:
	active_inverters[zone] = true
	controls_inverted = true

func remove_inverter_zone(zone: Node) -> void:
	active_inverters.erase(zone)
	controls_inverted = not active_inverters.is_empty()

func clear_inverter_zones() -> void:
	active_inverters.clear()
	controls_inverted = false

func clear_paranormal_modifiers() -> void:
	clear_inverter_zones()
	gravity_mult = 1.0
	speed_mult = 1.0
	jump_mult = 1.0
	ice_friction = 0.0
	external_wind_x = 0.0
	external_force_y = 0.0
	screen_wrap_enabled = false
	screen_wrap_y_min = 0.0
	screen_wrap_y_max = 540.0

func enter_door(target_pos: Vector2) -> void:
	if is_entering_door or is_dead:
		return
	is_entering_door = true
	velocity = Vector2.ZERO
	entered_exit.emit()
	
	# Original animatsiya: o'lcham 0 ga qarab kichrayib markazga tortiladi
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", target_pos, 0.18)
	if visual:
		tween.tween_property(visual, "scale", Vector2.ZERO, 0.18)
	await tween.finished
	visible = false

func enter_finish(target_pos: Vector2) -> void:
	enter_door(target_pos)

func _spawn_particles() -> void:
	if DeathParticlesScene:
		var p: CPUParticles2D = DeathParticlesScene.instantiate()
		p.global_position = global_position - Vector2(0, 16)
		get_parent().add_child(p)

func _spawn_dash_ghost() -> void:
	if not is_inside_tree() or not get_parent():
		return

	var ghost: Node2D = null

	# Hovuzdan bo'sh (yashiringan) sharpani qidiramiz
	for g in _ghost_pool:
		if is_instance_valid(g) and not g.visible:
			ghost = g
			break

	# Agar topilmasa va hovuzda 8 tadan kam bo'lsa, yangi yaratamiz
	if ghost == null:
		if _ghost_pool.size() < 8:
			ghost = Node2D.new()
			ghost.set_script(DashGhostScript)
			get_parent().add_child(ghost)
			_ghost_pool.append(ghost)
		else:
			return

	# Ota tuguni o'zgargan bo'lsa to'g'rilaymiz
	if ghost.get_parent() != get_parent():
		ghost.reparent(get_parent())

	ghost.global_position = global_position
	if visual:
		ghost.scale = visual.scale

	if ghost.has_method("play_effect"):
		ghost.play_effect()

func _get_dust_color() -> Color:
	var ch := 1
	if is_inside_tree():
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("get_current_chapter"):
			ch = gm.get_current_chapter()
	match ch:
		2:
			return Color(0.75, 0.92, 1.0, 0.72) # Qor uchquni
		3:
			return Color(0.72, 0.96, 0.80, 0.65) # O'rmon changi
		4:
			return Color(1.0, 0.88, 0.64, 0.70) # Sahro qumi
		5:
			return Color(1.0, 0.62, 0.45, 0.70) # Kul/cho'g'
		_:
			return Color(0.86, 0.90, 0.98, 0.68) # Yorqin tuman changi

func _spawn_dust(
	pos: Vector2,
	vel: Vector2,
	radius: float = 4.2,
	col: Color = Color(0.88, 0.92, 1.0, 0.68),
	life: float = 0.24,
	is_ring: bool = false,
	ring_max_r: float = 24.0
) -> void:
	if not is_inside_tree() or not get_parent():
		return
	var puff: Node2D = null
	for d in _dust_pool:
		if is_instance_valid(d) and d.has_method("is_active") and not d.is_active():
			puff = d
			break
	if puff == null:
		if _dust_pool.size() < 22:
			puff = Node2D.new()
			puff.set_script(DustPuffScript)
			puff.z_index = 4
			get_parent().add_child(puff)
			_dust_pool.append(puff)
		else:
			return
	if puff.get_parent() != get_parent():
		puff.reparent(get_parent())
	puff.spawn(pos, vel, radius, col, life, is_ring, ring_max_r)

func _spawn_jump_dust() -> void:
	var col := _get_dust_color()
	for i in range(4):
		var side := -1.0 if i < 2 else 1.0
		var vx := side * randf_range(28.0, 72.0)
		var vy := randf_range(-24.0, 6.0)
		_spawn_dust(global_position + Vector2(side * randf_range(2.0, 8.0), -2.0), Vector2(vx, vy), randf_range(3.2, 5.0), col, 0.22)

func _spawn_land_dust(hard_land: bool) -> void:
	var col := _get_dust_color()
	var count := 6 if hard_land else 4
	var speed_mult := 1.25 if hard_land else 0.85
	for i in range(count):
		var side := -1.0 if (i % 2 == 0) else 1.0
		var vx := side * randf_range(40.0, 95.0) * speed_mult
		var vy := randf_range(-34.0, -6.0) * speed_mult
		_spawn_dust(global_position + Vector2(side * randf_range(3.0, 10.0), -2.0), Vector2(vx, vy), randf_range(3.4, 5.4), col, 0.26)

func _spawn_run_dust() -> void:
	var col := _get_dust_color()
	col.a *= 0.72
	var behind := -float(facing)
	_spawn_dust(
		global_position + Vector2(behind * 9.0, -2.5),
		Vector2(behind * randf_range(18.0, 42.0), randf_range(-24.0, -8.0)),
		randf_range(2.6, 4.0),
		col,
		0.18
	)

func _spawn_skid_dust(old_dir: int) -> void:
	var col := _get_dust_color()
	for i in range(3):
		_spawn_dust(
			global_position + Vector2(float(old_dir) * 8.0, -2.0),
			Vector2(float(old_dir) * randf_range(36.0, 78.0), randf_range(-34.0, -10.0)),
			randf_range(3.0, 4.4),
			col,
			0.22
		)

func _spawn_dash_dust(dir_x: float) -> void:
	var col := Color(0.76, 0.92, 1.0, 0.80)
	for i in range(5):
		_spawn_dust(
			global_position + Vector2(-dir_x * 10.0, randf_range(-26.0, -4.0)),
			Vector2(-dir_x * randf_range(65.0, 130.0), randf_range(-26.0, 26.0)),
			randf_range(3.0, 4.8),
			col,
			0.22
		)

func _spawn_respawn_ring() -> void:
	var col := _get_dust_color()
	col.a = 0.85
	_spawn_dust(global_position + Vector2(0.0, -16.0), Vector2.ZERO, 6.0, col, 0.28, true, 28.0)
