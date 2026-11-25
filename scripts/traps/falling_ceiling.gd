extends AnimatableBody2D
class_name FallingCeiling

const TrapBiomeArt := preload("res://scripts/traps/trap_biome_art.gd")
const TrapBiomeVFX := preload("res://scripts/traps/trap_biome_vfx.gd")

# Level Devil Trap: Falling Ceiling (Kutilmagan Shift Qulashi)
# Camouflaged flush inside the spiky ceiling with matching teeth,
# drops rapidly onto the floor when approached, waits briefly, then rises back up.

@export var ceiling_size: Vector2 = Vector2(160, 40)
var platform_size: Vector2:
	get: return ceiling_size
	set(v): ceiling_size = v
@export var slam_distance_y: float = 310.0
@export var trigger_distance_x: float = 90.0
@export var fall_accel: float = 4800.0
@export var wait_at_bottom: float = 0.65
@export var rise_speed: float = 180.0
@export var retrigger_delay: float = 0.8
@export var fakeout_first: bool = false
@export var double_slam: bool = false
@export var trigger_y_min: float = -9999.0
@export var trigger_y_max: float = 9999.0
@export var pass_through_platforms: bool = false
@export var target_floor_y: float = 380.0

enum State { IDLE, FAKEOUT_PAUSE, FALLING, WAITING_BOTTOM, RISING, COOLDOWN }
var state: State = State.IDLE

var original_pos: Vector2
var target_y: float = 340.0
var fall_speed: float = 0.0
var state_timer: float = 0.0
var squash_tween: Tween = null
var _body_kill_disabled: bool = false
var _did_fakeout: bool = false
var _did_double_slam: bool = false
var _rising_to_half: bool = false
var _fast_fall: bool = false
var _fakeout_phase: int = 0
var _fakeout_timer: float = 0.0

@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var kill_area: Area2D = $KillArea

func _ready() -> void:
	add_to_group("traps")
	z_index = 1
	sync_to_physics = false
	if position.y >= 65.0 and position.y <= 75.0:
		position.y = 70.0 - ceiling_size.y
	original_pos = position
	target_y = minf(original_pos.y + slam_distance_y, target_floor_y - ceiling_size.y)

	if col_shape:
		var rect := RectangleShape2D.new()
		rect.size = ceiling_size
		col_shape.shape = rect
		col_shape.position = ceiling_size / 2.0

	if kill_area:
		var k_shape = kill_area.get_node_or_null("CollisionShape2D")
		if k_shape:
			var k_rect := RectangleShape2D.new()
			k_rect.size = Vector2(ceiling_size.x - 4.0, 14.0)
			k_shape.shape = k_rect
			k_shape.position = Vector2(ceiling_size.x / 2.0, ceiling_size.y)
		kill_area.body_entered.connect(_on_kill_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
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
					if py > (target_y + ceiling_size.y + 36.0):
						return
				var center_x: float = global_position.x + ceiling_size.x / 2.0
				var dist_x: float = absf(player.global_position.x - center_x)
				var dist_y: float = py - global_position.y
				if dist_x < trigger_distance_x and dist_y > 0.0 and dist_y < 420.0:
					trigger_slam()

		State.FAKEOUT_PAUSE:
			if _fakeout_phase == 0:
				fall_speed += 2400.0 * delta
				position.y += fall_speed * delta
				queue_redraw()
				var fakeout_y := minf(original_pos.y + 22.0, target_y)
				if position.y >= fakeout_y:
					position.y = fakeout_y
					fall_speed = 0.0
					_fakeout_phase = 1
					_fakeout_timer = 0.28
					queue_redraw()
			else:
				_fakeout_timer -= delta
				if _fakeout_timer <= 0.0:
					state = State.FALLING
					fall_speed = 320.0
					_fast_fall = true
					if squash_tween and squash_tween.is_valid():
						squash_tween.kill()
					scale = Vector2(0.95, 1.07)

		State.FALLING:
			var accel := fall_accel * 1.35 if _fast_fall else fall_accel
			fall_speed += accel * delta
			position.y += fall_speed * delta
			queue_redraw()
			if kill_area:
				for b in kill_area.get_overlapping_bodies():
					_on_kill_entered(b)
			var p := get_tree().get_first_node_in_group("player") as Node2D
			if p != null and is_instance_valid(p):
				var p_dead: bool = "is_dead" in p and p.is_dead
				var p_inv: bool = "is_invulnerable" in p and p.is_invulnerable
				if not p_dead and not p_inv:
					var px: float = p.global_position.x
					var py: float = p.global_position.y
					if px + 8.0 >= global_position.x and px - 8.0 <= (global_position.x + ceiling_size.x):
						if py >= global_position.y and py <= (global_position.y + ceiling_size.y + 12.0):
							_on_kill_entered(p)
			if position.y >= target_y:
				position.y = target_y
				fall_speed = 0.0
				_fast_fall = false
				if double_slam and not _did_double_slam:
					_did_double_slam = true
					_rising_to_half = true
					state = State.WAITING_BOTTOM
					state_timer = 0.18
				else:
					state = State.WAITING_BOTTOM
					state_timer = wait_at_bottom
				_play_squash_impact()
				var ch_slam := TrapBiomeArt.get_chapter(self)
				TrapBiomeVFX.emit_slam_impact(self, global_position + Vector2(ceiling_size.x * 0.5, ceiling_size.y + 8.0), ceiling_size.x, ch_slam)
				var snd_slam = get_node_or_null("/root/SoundManager")
				if snd_slam and snd_slam.has_method("play_biome_trap"):
					snd_slam.play_biome_trap("slam", ch_slam)
				var gm = get_node_or_null("/root/GameManager")
				if gm and gm.has_signal("request_screen_shake"):
					gm.request_screen_shake.emit(8.0)
				queue_redraw()

		State.WAITING_BOTTOM:
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.RISING

		State.RISING:
			if _rising_to_half:
				position.y -= rise_speed * 2.2 * delta
				queue_redraw()
				var half_y := original_pos.y + (target_y - original_pos.y) * 0.45
				if position.y <= half_y:
					position.y = half_y
					_rising_to_half = false
					state = State.FALLING
					fall_speed = 320.0
					if squash_tween and squash_tween.is_valid():
						squash_tween.kill()
					scale = Vector2(0.95, 1.07)
					queue_redraw()
					var ch_ds := TrapBiomeArt.get_chapter(self)
					var sm = get_node_or_null("/root/SoundManager")
					if sm and sm.has_method("play_biome_trap"):
						sm.play_biome_trap("trigger", ch_ds)
					elif sm and sm.has_method("play"):
						sm.play("trap")
			else:
				position.y -= rise_speed * delta
				queue_redraw()
				if position.y <= original_pos.y:
					position.y = original_pos.y
					z_index = 1
					state = State.COOLDOWN if retrigger_delay > 0.0 else State.IDLE
					state_timer = retrigger_delay
					queue_redraw()

		State.COOLDOWN:
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.IDLE

func trigger_slam() -> void:
	if state != State.IDLE:
		return
	if pass_through_platforms:
		z_index = 2
	if fakeout_first and not _did_fakeout:
		_did_fakeout = true
		state = State.FAKEOUT_PAUSE
		_fakeout_phase = 0
		_fakeout_timer = 0.28
		fall_speed = 240.0
		if squash_tween and squash_tween.is_valid():
			squash_tween.kill()
		scale = Vector2(0.96, 1.05)
		var ch_fo := TrapBiomeArt.get_chapter(self)
		TrapBiomeVFX.emit_ceiling_detach(self, global_position + Vector2(0.0, ceiling_size.y), ceiling_size.x, ch_fo)
		var sm = get_node_or_null("/root/SoundManager")
		if sm and sm.has_method("play_biome_trap"):
			sm.play_biome_trap("trigger", ch_fo)
		elif sm and sm.has_method("play"):
			sm.play("trap")
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_signal("request_screen_shake"):
			gm.request_screen_shake.emit(4.0)
		return
	state = State.FALLING
	fall_speed = 320.0
	if squash_tween and squash_tween.is_valid():
		squash_tween.kill()
	scale = Vector2(0.95, 1.07)
	var ch_tr := TrapBiomeArt.get_chapter(self)
	TrapBiomeVFX.emit_ceiling_detach(self, global_position + Vector2(0.0, ceiling_size.y), ceiling_size.x, ch_tr)
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_biome_trap"):
		sm.play_biome_trap("trigger", ch_tr)
	elif sm and sm.has_method("play"):
		sm.play("trap")
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("request_screen_shake"):
		gm.request_screen_shake.emit(6.0)

func _play_squash_impact() -> void:
	if squash_tween and squash_tween.is_valid():
		squash_tween.kill()
	scale = Vector2(1.10, 0.90)
	squash_tween = create_tween()
	squash_tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_kill_entered(body: Node2D) -> void:
	if state == State.FALLING and (body is PlayerController or body.is_in_group("player")):
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
	fall_speed = 0.0
	state_timer = 0.0
	_did_fakeout = false
	_did_double_slam = false
	_rising_to_half = false
	_fast_fall = false
	_fakeout_phase = 0
	_fakeout_timer = 0.0
	position = original_pos
	scale = Vector2.ONE
	z_index = 1
	if is_inside_tree():
		PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, global_transform)
	queue_redraw()

func _draw() -> void:
	var ch := TrapBiomeArt.get_chapter(self)
	var base_col := TrapBiomeArt.get_base_color(ch)
	var w := ceiling_size.x
	var h := ceiling_size.y
	draw_rect(Rect2(0.0, 0.0, w, h), base_col, true)

	# Biom tafsilotlari faqat qulash boshlangandan keyin paydo bo'ladi (idle holatda 100% kamuflyaj!)
	var moved_down := position.y - original_pos.y
	var reveal := clampf((moved_down - 10.0) / 28.0, 0.0, 1.0)
	TrapBiomeArt.draw_crusher_active_detail(self, w, h, 0.0, reveal, ch)

	# Shift tikanlari bilan 100% bir xil ko'rinishdagi tishlar (kamuflyaj)
	TrapBiomeArt.draw_ceiling_teeth(self, 0.0, w, h, ch, 13.0)
