extends Area2D
class_name Crusher

const TrapBiomeArt := preload("res://scripts/traps/trap_biome_art.gd")
const TrapBiomeVFX := preload("res://scripts/traps/trap_biome_vfx.gd")

@export var crusher_size: Vector2 = Vector2(64, 64)
@export var target_y: float = 325.0
@export var trigger_distance: float = 60.0
@export var returns_up: bool = true
@export var wait_at_bottom: float = 0.7
@export var rise_speed: float = 140.0
@export var retrigger_delay: float = 0.8
@export var fakeout_first: bool = false
@export var double_slam: bool = false
@export var trigger_y_min: float = -9999.0
@export var trigger_y_max: float = 9999.0
@export var pass_through_platforms: bool = false
@export var fall_accel: float = 5400.0

enum State { IDLE, FAKEOUT_PAUSE, FALLING, WAITING_BOTTOM, RISING, COOLDOWN }
var state: State = State.IDLE

var initial_position: Vector2
var speed: float = 0.0
var timer: float = 0.0
var player_ref: Node2D = null
var has_crushed: bool = false
var chain_slack: float = 0.0
var sway_phase: float = 0.0
var was_in_trigger_zone: bool = false
var squash_tween: Tween = null
var _did_fakeout: bool = false
var _did_double_slam: bool = false
var _rising_to_half: bool = false
var _fast_fall: bool = false
var _fakeout_phase: int = 0
var _fakeout_timer: float = 0.0

var is_triggered: bool:
	get: return state != State.IDLE
var is_falling: bool:
	get: return state == State.FALLING

@onready var col_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

func _ready() -> void:
	add_to_group("traps")
	z_index = 1
	initial_position = global_position
	if col_shape:
		col_shape.shape = RectangleShape2D.new()
		col_shape.shape.size = crusher_size + Vector2(0, 8)
		col_shape.position = (crusher_size + Vector2(0, 8)) / 2.0
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			if has_crushed:
				return
			if player_ref == null and is_inside_tree():
				player_ref = get_tree().get_first_node_in_group("player") as Node2D
			if player_ref != null and is_instance_valid(player_ref):
				if "is_dead" in player_ref and player_ref.is_dead:
					return
				var player_y: float = player_ref.global_position.y
				if player_y < trigger_y_min or player_y > trigger_y_max:
					was_in_trigger_zone = false
					return
				if trigger_y_min <= -9000.0 and trigger_y_max >= 9000.0:
					if player_y < global_position.y or player_y > (target_y + crusher_size.y + 36.0):
						was_in_trigger_zone = false
						return
				var crusher_center_x := global_position.x + crusher_size.x / 2.0
				var player_center_x: float = player_ref.global_position.x
				var dist_x: float = absf(player_center_x - crusher_center_x)
				if dist_x < trigger_distance:
					var is_under := player_center_x >= global_position.x and \
						player_center_x <= (global_position.x + crusher_size.x)
					var p_vel_x: float = player_ref.velocity.x \
						if "velocity" in player_ref else 0.0
					var is_moving_towards := false
					if player_center_x < crusher_center_x and p_vel_x > 1.0:
						is_moving_towards = true
					elif player_center_x > crusher_center_x and p_vel_x < -1.0:
						is_moving_towards = true
					
					if is_under or is_moving_towards or not was_in_trigger_zone:
						if pass_through_platforms:
							z_index = 2
						if fakeout_first and not _did_fakeout:
							_did_fakeout = true
							state = State.FAKEOUT_PAUSE
							_fakeout_phase = 0
							_fakeout_timer = 0.28
							speed = 240.0
							chain_slack = 0.0
							if squash_tween and squash_tween.is_valid():
								squash_tween.kill()
							scale = Vector2(0.96, 1.05)
							queue_redraw()
							var ch_fo := TrapBiomeArt.get_chapter(self)
							TrapBiomeVFX.emit_ceiling_detach(self, global_position + Vector2(0.0, crusher_size.y), crusher_size.x, ch_fo)
							var sm = get_node_or_null("/root/SoundManager")
							if sm and sm.has_method("play_biome_trap"):
								sm.play_biome_trap("trigger", ch_fo)
							elif sm and sm.has_method("play"):
								sm.play("trap")
							var save_mgr = get_node_or_null("/root/SaveManager")
							if save_mgr == null or save_mgr.shake_enabled:
								var gm = get_node_or_null("/root/GameManager")
								if gm and gm.has_signal("request_screen_shake"):
									gm.request_screen_shake.emit(4.0)
						else:
							state = State.FALLING
							speed = 280.0
							chain_slack = 0.0
							if squash_tween and squash_tween.is_valid():
								squash_tween.kill()
							scale = Vector2(0.94, 1.08)
							queue_redraw()
							var ch_fl := TrapBiomeArt.get_chapter(self)
							TrapBiomeVFX.emit_ceiling_detach(self, global_position + Vector2(0.0, crusher_size.y), crusher_size.x, ch_fl)
							var sm = get_node_or_null("/root/SoundManager")
							if sm and sm.has_method("play_biome_trap"):
								sm.play_biome_trap("trigger", ch_fl)
							elif sm and sm.has_method("play"):
								sm.play("trap")
					was_in_trigger_zone = true
				else:
					was_in_trigger_zone = false
		
		State.FAKEOUT_PAUSE:
			if _fakeout_phase == 0:
				speed += 2400.0 * delta
				global_position.y += speed * delta
				queue_redraw()
				var fakeout_y := minf(initial_position.y + 24.0, target_y)
				if global_position.y >= fakeout_y:
					global_position.y = fakeout_y
					speed = 0.0
					_fakeout_phase = 1
					_fakeout_timer = 0.28
			else:
				_fakeout_timer -= delta
				if _fakeout_timer <= 0.0:
					state = State.FALLING
					speed = 280.0
					_fast_fall = true
					if squash_tween and squash_tween.is_valid():
						squash_tween.kill()
					scale = Vector2(0.94, 1.08)
					queue_redraw()
		
		State.FALLING:
			speed += (fall_accel * 1.4 if _fast_fall else fall_accel) * delta
			global_position.y += speed * delta
			queue_redraw()
			for b in get_overlapping_bodies():
				_on_body_entered(b)
			var p: Node2D = player_ref
			if (p == null or not is_instance_valid(p)) and is_inside_tree():
				p = get_tree().get_first_node_in_group("player") as Node2D
			if p != null and is_instance_valid(p):
				var p_dead: bool = "is_dead" in p and p.is_dead
				var p_invuln: bool = "is_invulnerable" in p and p.is_invulnerable
				if not p_dead and not p_invuln:
					var px: float = p.global_position.x
					var py: float = p.global_position.y
					if px + 8.0 >= global_position.x and px - 8.0 <= (global_position.x + crusher_size.x):
						if py >= global_position.y and py <= (global_position.y + crusher_size.y + 12.0):
							_on_body_entered(p)
			if global_position.y >= target_y:
				global_position.y = target_y
				_fast_fall = false
				if squash_tween and squash_tween.is_valid():
					squash_tween.kill()
				scale = Vector2(1.10, 0.90)
				squash_tween = create_tween()
				squash_tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				var ch_slam := TrapBiomeArt.get_chapter(self)
				TrapBiomeVFX.emit_slam_impact(self, global_position + Vector2(crusher_size.x * 0.5, crusher_size.y + 8.0), crusher_size.x, ch_slam)
				var snd_slam = get_node_or_null("/root/SoundManager")
				if snd_slam and snd_slam.has_method("play_biome_trap"):
					snd_slam.play_biome_trap("slam", ch_slam)
				var sm = get_node_or_null("/root/SaveManager")
				if sm == null or sm.shake_enabled:
					var gm = get_node_or_null("/root/GameManager")
					if gm and gm.has_signal("request_screen_shake"):
						gm.request_screen_shake.emit(8.0)
				if double_slam and not _did_double_slam:
					_did_double_slam = true
					_rising_to_half = true
					state = State.WAITING_BOTTOM
					timer = 0.18
					chain_slack = 1.0
					sway_phase = 0.0
					queue_redraw()
				elif returns_up:
					state = State.WAITING_BOTTOM
					timer = wait_at_bottom
					chain_slack = 1.0
					sway_phase = 0.0
					queue_redraw()
				else:
					has_crushed = true
					state = State.IDLE
					queue_redraw()
		
		State.WAITING_BOTTOM:
			timer -= delta
			sway_phase += delta * 12.0
			queue_redraw()
			if timer <= 0.0:
				state = State.RISING
				chain_slack = 0.0
				queue_redraw()
		
		State.RISING:
			chain_slack = 0.0
			if _rising_to_half:
				global_position.y -= rise_speed * 2.2 * delta
				queue_redraw()
				var half_y := initial_position.y + (target_y - initial_position.y) * 0.45
				if global_position.y <= half_y:
					global_position.y = half_y
					_rising_to_half = false
					state = State.FALLING
					speed = 280.0
					if squash_tween and squash_tween.is_valid():
						squash_tween.kill()
					scale = Vector2(0.94, 1.08)
					queue_redraw()
					var ch_ds := TrapBiomeArt.get_chapter(self)
					var sm = get_node_or_null("/root/SoundManager")
					if sm and sm.has_method("play_biome_trap"):
						sm.play_biome_trap("trigger", ch_ds)
					elif sm and sm.has_method("play"):
						sm.play("trap")
			else:
				global_position.y -= rise_speed * delta
				queue_redraw()
				if global_position.y <= initial_position.y:
					global_position.y = initial_position.y
					z_index = 1
					if retrigger_delay > 0.0:
						state = State.COOLDOWN
						timer = retrigger_delay
					else:
						state = State.IDLE
					queue_redraw()
		
		State.COOLDOWN:
			timer -= delta
			if timer <= 0.0:
				state = State.IDLE
				queue_redraw()

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
	if squash_tween and squash_tween.is_valid():
		squash_tween.kill()
	state = State.IDLE
	speed = 0.0
	timer = 0.0
	has_crushed = false
	chain_slack = 0.0
	sway_phase = 0.0
	was_in_trigger_zone = false
	_did_fakeout = false
	_did_double_slam = false
	_rising_to_half = false
	_fast_fall = false
	_fakeout_phase = 0
	_fakeout_timer = 0.0
	scale = Vector2.ONE
	z_index = 1
	global_position = initial_position
	queue_redraw()

func _draw() -> void:
	var ch := TrapBiomeArt.get_chapter(self)
	var w := crusher_size.x
	var h := crusher_size.y

	# Shiftgacha bo'lgan masofaga qarab biomga mos osma zanjir/shirmoq chizish
	# (tinch holatda shift ichida MUTLAQO ko'rinmaydi — 100% kamuflyaj!)
	var chain_x := w / 2.0
	var moved_down := global_position.y - initial_position.y
	var chain_h := maxf(0.0, global_position.y) if moved_down > 2.0 else 0.0
	if chain_h > 4.0:
		var sway_ratio := clampf(timer / maxf(wait_at_bottom, 0.1), 0.0, 1.0)
		TrapBiomeArt.draw_crusher_tether(self, chain_x, chain_h, ch, state == State.WAITING_BOTTOM, sway_ratio, sway_phase)

	# Asosiy ezuvchi blok korpusi (Y >= 0 qirqiladi)
	var top_clip := maxf(0.0, -global_position.y)
	var body_h := h - top_clip
	if body_h > 0.0:
		var body_col := TrapBiomeArt.get_base_color(ch)
		draw_rect(Rect2(0.0, top_clip, w, body_h), body_col, true)
		# Biom tafsilotlari faqat ezuvchi shiftdan ajralib tusha boshlagandagina paydo bo'ladi
		var reveal := clampf((moved_down - 10.0) / 30.0, 0.0, 1.0)
		TrapBiomeArt.draw_crusher_active_detail(self, w, h, top_clip, reveal, ch)

	# Tishlar: shift tikanlari bilan 100% bir xil shared helper!
	TrapBiomeArt.draw_ceiling_teeth(self, 0.0, w, h, ch, 13.0)
