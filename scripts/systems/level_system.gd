extends Node
class_name LevelSystem

# Wrong Way — Level System
# Handles level loading, version validation, and connects GameSession to level instances.

signal level_loaded(data: LevelData)
signal level_completed(result: Dictionary)

var current_level_data: LevelData = null
var current_session: GameSession = null

func _ready() -> void:
	current_session = GameSession.new()
	add_child(current_session)

func load_level(level_data: LevelData) -> void:
	current_level_data = level_data
	if ResourceLoader.exists(level_data.scene_path):
		get_tree().change_scene_to_file(level_data.scene_path)
		await get_tree().create_timer(0.05).timeout
		current_session.start_attempt(level_data)
		level_loaded.emit(level_data)
	else:
		push_error("Wrong Way: Scene path does not exist: %s" % level_data.scene_path)

func restart_current_attempt() -> void:
	if current_level_data:
		load_level(current_level_data)
