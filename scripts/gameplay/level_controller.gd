extends Node2D
class_name LevelController

# Wrong Way — Level Controller
# Manages scene nodes, orchestrates GameSession lifecycle, and routes clean events.
# Does NOT maintain duplicate run state; delegates entirely to GameSession.

@export var level_number: int = 1
@export var level_data: LevelData = null

var session: GameSession = null
var player: PlayerController = null
var finish_gate: FinishGate = null
var hud: HUDView = null
var camera: Camera2D = null

var shake_intensity: float = 0.0

func _ready() -> void:
	if level_data == null:
		var default_data_path = "res://resources/level_data/zone_%02d.tres" % level_number
		if ResourceLoader.exists(default_data_path):
			level_data = load(default_data_path)
		else:
			level_data = preload("res://resources/level_data/zone_01.tres")
	
	player = get_node_or_null("Player") as PlayerController
	finish_gate = get_node_or_null("FinishGate") as FinishGate
	if finish_gate == null:
		finish_gate = get_node_or_null("Door") as FinishGate
	hud = get_node_or_null("HUD") as HUDView
	if hud == null:
		hud = get_node_or_null("UI") as HUDView
	camera = get_node_or_null("Camera2D") as Camera2D
	
	# Instantiate Authoritative GameSession
	session = GameSession.new()
	add_child(session)
	
	if hud:
		hud.bind_session(session, level_number)
		hud.set_level_info(level_data.level_name)
		hud.replay_requested.connect(restart_attempt)
	
	if player:
		player.add_to_group("player")
		player.died.connect(_on_player_died)
	
	if finish_gate:
		finish_gate.finish_completed.connect(_on_finish_completed)
	
	# Always hide ad banner during active gameplay
	var adm = get_node_or_null("/root/AdManager")
	if adm and adm.has_method("hide_banner"):
		adm.hide_banner()
	
	# Mark level as attempted for progression & ad unlock logic
	var save_sys = get_node_or_null("/root/SaveSystem")
	if save_sys and save_sys.has_method("record_level_attempt"):
		save_sys.record_level_attempt(level_number)
	
	# Start initial attempt or restore completed result modal if returning from map
	if save_sys and save_sys.should_restore_result_modal and save_sys.return_level_num == level_number:
		save_sys.should_restore_result_modal = false
		if player and finish_gate:
			player.global_position = finish_gate.global_position
			player.visible = false
			player.set_physics_process(false)
		if finish_gate and finish_gate.has_method("hide_for_completed"):
			finish_gate.hide_for_completed()
		elif finish_gate:
			finish_gate.visible = false
		
		var restore_data = save_sys.pending_result_data
		if restore_data.is_empty():
			var best_time = save_sys.level_best_times.get(str(level_number), 5000)
			restore_data = {
				"time_ms": best_time,
				"deaths": 0,
				"level_id": level_data.level_id if level_data else "zone_01",
				"level_name": level_data.level_name if level_data else "Zone 01"
			}
		session.restore_completed_state(restore_data)
	else:
		# Start initial attempt
		session.start_attempt(level_data)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			restart_attempt()

func _process(delta: float) -> void:
	# Camera shake decay
	if shake_intensity > 0.0 and camera:
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_intensity = move_toward(shake_intensity, 0.0, delta * 30.0)
	elif camera and camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

func trigger_shake(intensity: float = 8.0) -> void:
	shake_intensity = intensity

func _on_player_died() -> void:
	trigger_shake(9.0)
	session.register_death()
	# Reset all level traps so obstacles re-arm
	get_tree().call_group("traps", "reset_trap")
	if finish_gate:
		finish_gate.reset_gate()

func _on_finish_completed() -> void:
	session.complete_attempt()

func restart_attempt() -> void:
	var save_sys = get_node_or_null("/root/SaveSystem")
	if save_sys:
		save_sys.should_restore_result_modal = false
	
	# In-place clean reset of session, player, traps, gate, and HUD
	session.reset_attempt()
	if player:
		player.respawn()
	get_tree().call_group("traps", "reset_trap")
	if finish_gate:
		finish_gate.reset_gate()
	if hud and hud.win_overlay:
		hud.win_overlay.visible = false
	
	# When running as the active scene, reload to guarantee a 100% fresh environment
	if get_tree() and get_tree().current_scene == self:
		get_tree().reload_current_scene()
