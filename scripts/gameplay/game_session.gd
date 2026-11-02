extends Node
class_name GameSession

# Wrong Way — GameSession
# Sole authoritative source of truth for an individual attempt's run state.
# Tracks run deaths, timer, completion status, and verified run results.
# Completely replaces any duplicate run state managers.

signal session_started
signal death_recorded(total_deaths: int)
signal checkpoint_updated(checkpoint_id: String)
signal session_completed(result: Dictionary)

var current_level_data: LevelData = null
var is_active: bool = false
var is_completed: bool = false

var start_time_usec: int = 0
var finish_time_usec: int = 0
var elapsed_time_ms: int = 0
var deaths: int = 0
var current_checkpoint: String = "start"

func start_attempt(level_data: LevelData) -> void:
	current_level_data = level_data
	reset_attempt()

func reset_attempt() -> void:
	deaths = 0
	current_checkpoint = "start"
	is_active = true
	is_completed = false
	start_time_usec = Time.get_ticks_usec()
	finish_time_usec = 0
	elapsed_time_ms = 0
	death_recorded.emit(0)
	session_started.emit()

func register_death() -> void:
	if not is_active or is_completed:
		return
	deaths += 1
	death_recorded.emit(deaths)

func set_checkpoint(checkpoint_id: String) -> void:
	if not is_active or is_completed:
		return
	current_checkpoint = checkpoint_id
	checkpoint_updated.emit(checkpoint_id)

func restore_completed_state(result: Dictionary) -> void:
	is_active = false
	is_completed = true
	elapsed_time_ms = result.get("time_ms", 0)
	deaths = result.get("deaths", 0)
	death_recorded.emit(deaths)
	session_completed.emit(result)

func complete_attempt() -> Dictionary:
	if not is_active or is_completed:
		return {}
	
	finish_time_usec = Time.get_ticks_usec()
	elapsed_time_ms = int((finish_time_usec - start_time_usec) / 1000.0)
	is_active = false
	is_completed = true
	
	var result: Dictionary = {
		"level_id": current_level_data.level_id if current_level_data else "zone_01",
		"level_name": current_level_data.level_name if current_level_data else "Zone 01",
		"level_version": current_level_data.level_version if current_level_data else 1,
		"time_ms": elapsed_time_ms,
		"deaths": deaths,
		"completed_at": Time.get_datetime_string_from_system(),
		"verification_status": _verify_run(elapsed_time_ms, deaths)
	}
	
	session_completed.emit(result)
	return result

func get_elapsed_ms() -> int:
	if not is_active:
		return elapsed_time_ms
	var now = Time.get_ticks_usec()
	return int((now - start_time_usec) / 1000.0)

func _verify_run(time_ms: int, run_deaths: int) -> String:
	if time_ms < 500:
		return "SUSPICIOUS_TIME"
	if run_deaths < 0:
		return "INVALID_DEATHS"
	return "VERIFIED"
